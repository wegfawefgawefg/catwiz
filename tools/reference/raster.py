# a small numpy z-buffer rasteriser for prefab parts (unity_assets.py Part objects).
#
# view: the object turns by yaw about its vertical axis, then a camera looks at it from pitch
# degrees above, with a vertical field of view fov (0 = orthographic). the picture is fitted to a
# pixel height, rendered ss times larger and box-filtered down, so edges are antialiased.
#
# small triangles are rasterised many at a time: every triangle whose bounding box fits in an
# s x s tile is tested against all s*s pixel centres of its tile in one numpy pass, and the
# nearest fragment per pixel wins. this keeps 400k-triangle forest meshes to a few seconds.

import math

import numpy as np

from unity_assets import linear_to_srgb, srgb_to_linear

LIGHT = np.array([-0.45, 0.65, -0.6])  # towards the light, camera space: upper left, in front
AMBIENT = 0.55


class View:
    def __init__(self, yaw=0.0, pitch=8.0, fov=12.0):
        self.yaw, self.pitch, self.fov = yaw, pitch, fov


class Frame:
    # what one render produced, at the final pixel size
    def __init__(self, rgb, alpha, part_id, depth, names):
        self.rgb = rgb            # (h, w, 3) linear rgb, premultiplied by alpha
        self.alpha = alpha        # (h, w) coverage 0..1
        self.part_id = part_id    # (h, w) int, -1 where empty
        self.depth = depth        # (h, w) camera depth, inf where empty
        self.names = names        # part index -> part path


def camera_space(points, centre, view):
    # object turn about its own centre, then the camera's pitch
    p = points - centre
    a = math.radians(view.yaw)
    x = p[:, 0] * math.cos(a) + p[:, 2] * math.sin(a)
    z = -p[:, 0] * math.sin(a) + p[:, 2] * math.cos(a)
    y = p[:, 1]
    b = math.radians(view.pitch)
    up = (0.0, math.cos(b), math.sin(b))
    fwd = (0.0, -math.sin(b), math.cos(b))
    return np.stack([x, y * up[1] + z * up[2], y * fwd[1] + z * fwd[2]], 1)


def project(cam, view):
    # (n, 3) camera space -> screen-plane x, y (world units at the object's centre) and depth
    if view.fov <= 0:
        return cam[:, 0], cam[:, 1], cam[:, 2]
    span = max(np.ptp(cam[:, 1]), np.ptp(cam[:, 0]), 1e-6)
    dist = span / (2 * math.tan(math.radians(view.fov) / 2)) + np.ptp(cam[:, 2])
    z = cam[:, 2] + dist
    return cam[:, 0] * dist / z, cam[:, 1] * dist / z, z


def gather(parts):
    verts, tris, colours, uvs, owner = [], [], [], [], []
    base = 0
    for i, p in enumerate(parts):
        verts.append(p.verts)
        tris.append(p.tris + base)
        colours.append(p.colours)
        uvs.append(p.uvs if p.uvs is not None else np.full((len(p.verts), 2), np.nan))
        owner.append(np.full(len(p.tris), i))
        base += len(p.verts)
    return (np.concatenate(verts), np.concatenate(tris), np.concatenate(colours),
            np.concatenate(uvs), np.concatenate(owner))


def rasterise(sx, sy, sz, tris, w, h):
    # sz must be linear in screen space with larger meaning nearer: 1/depth for perspective,
    # -depth for orthographic. returns per-pixel winning triangle (-1 none), its screen-space
    # barycentrics (h, w, 2) and the winning sz (-inf where empty).
    best_z = np.full(h * w, -np.inf)
    best_t = np.full(h * w, -1, np.int64)
    best_b = np.zeros((h * w, 2))
    x, y, z = sx[tris], sy[tris], sz[tris]
    x0 = np.clip(np.ceil(x.min(1) - 0.5), 0, w).astype(np.int64)
    x1 = np.clip(np.floor(x.max(1) - 0.5), -1, w - 1).astype(np.int64)
    y0 = np.clip(np.ceil(y.min(1) - 0.5), 0, h).astype(np.int64)
    y1 = np.clip(np.floor(y.max(1) - 0.5), -1, h - 1).astype(np.int64)
    bw, bh = x1 - x0 + 1, y1 - y0 + 1
    area = (y[:, 1] - y[:, 2]) * (x[:, 0] - x[:, 2]) + (x[:, 2] - x[:, 1]) * (y[:, 0] - y[:, 2])
    keep = (bw > 0) & (bh > 0) & (np.abs(area) > 1e-12)
    size = np.maximum(bw, bh)
    tile = 1
    while keep.any():
        group = np.nonzero(keep & (size <= tile))[0]
        keep[group] = False
        if len(group):
            offs = np.arange(tile * tile)
            ox, oy = offs % tile, offs // tile
            step = max(1, 4_000_000 // (tile * tile))
            for s in range(0, len(group), step):
                t = group[s:s + step]
                fragments(t, ox, oy, x, y, z, x0, y0, bw, bh, area, w, best_z, best_t, best_b)
        tile *= 2
    return best_t.reshape(h, w), best_b.reshape(h, w, 2), best_z.reshape(h, w)


def fragments(t, ox, oy, x, y, z, x0, y0, bw, bh, area, w, best_z, best_t, best_b):
    px = x0[t, None] + ox[None, :]
    py = y0[t, None] + oy[None, :]
    valid = (ox[None, :] < bw[t, None]) & (oy[None, :] < bh[t, None])
    cx, cy = px + 0.5, py + 0.5
    xa, xb, xc = x[t, 0, None], x[t, 1, None], x[t, 2, None]
    ya, yb, yc = y[t, 0, None], y[t, 1, None], y[t, 2, None]
    d = area[t, None]
    w0 = ((yb - yc) * (cx - xc) + (xc - xb) * (cy - yc)) / d
    w1 = ((yc - ya) * (cx - xc) + (xa - xc) * (cy - yc)) / d
    w2 = 1 - w0 - w1
    inside = valid & (w0 >= -1e-9) & (w1 >= -1e-9) & (w2 >= -1e-9)
    if not inside.any():
        return
    ti = np.broadcast_to(t[:, None], inside.shape)[inside]
    pix = (py * w + px)[inside]
    zz = (w0 * z[t, 0, None] + w1 * z[t, 1, None] + w2 * z[t, 2, None])[inside]
    b0, b1 = w0[inside], w1[inside]
    order = np.lexsort((-zz, pix))
    pix_s = pix[order]
    first = np.r_[True, pix_s[1:] != pix_s[:-1]]
    sel = order[first]
    pix, zz = pix[sel], zz[sel]
    nearer = zz > best_z[pix]
    pix, sel, zz = pix[nearer], sel[nearer], zz[nearer]
    best_z[pix] = zz
    best_t[pix] = ti[sel]
    best_b[pix, 0] = b0[sel]
    best_b[pix, 1] = b1[sel]


def sample_texture(tex, uv):
    th, tw = tex.shape[:2]
    u = np.mod(uv[:, 0], 1.0)
    v = np.mod(uv[:, 1], 1.0)
    col = np.minimum((u * tw).astype(np.int64), tw - 1)
    row = np.minimum(((1 - v) * th).astype(np.int64), th - 1)
    return tex[row, col]


def render(parts, view, height=None, scale=None, ss=4, margin=2, lit=True):
    # one object framed by its bounds. height: picture height in pixels (the object fills it
    # less margin), or scale: pixels per world unit at the object's centre, so several objects
    # keep their relative sizes.
    verts, tris, colours, uvs, owner = gather(parts)
    lo, hi = verts.min(0), verts.max(0)
    cam = camera_space(verts, (lo + hi) / 2, view)
    px, py, depth = project(cam, view)
    if scale is None:
        scale = (height - 2 * margin) / max(np.ptp(py), 1e-6)
    w = int(math.ceil(np.ptp(px) * scale)) + 2 * margin
    h = int(math.ceil(np.ptp(py) * scale)) + 2 * margin
    sx = ((px - px.min()) * scale + margin) * ss
    sy = ((py.max() - py) * scale + margin) * ss
    return draw(parts, cam, sx, sy, depth, tris, colours, uvs, owner, w, h, ss, lit, None, view.fov > 0)


def render_camera(parts, eye, pitch, fov, w, h, ss=3, lit=True, fog=None, near=0.5):
    # a fixed camera like the game's: at eye (world), looking along +z, tilted down by pitch
    # degrees, vertical field of view fov. fog: (linear rgb, exp2 density) or None.
    verts, tris, colours, uvs, owner = gather(parts)
    cam = camera_space(verts, np.asarray(eye, dtype=np.float64), View(0, pitch, fov))
    cam, tris, colours, uvs, owner = clip_near(cam, tris, colours, uvs, owner, near)
    f = (h / 2) / math.tan(math.radians(fov) / 2)
    sx = (w / 2 + cam[:, 0] / cam[:, 2] * f) * ss
    sy = (h / 2 - cam[:, 1] / cam[:, 2] * f) * ss
    return draw(parts, cam, sx, sy, cam[:, 2], tris, colours, uvs, owner, w, h, ss, lit, fog, True)


def clip_near(cam, tris, colours, uvs, owner, near):
    # drops triangles behind the camera and cuts the ones that cross the near plane
    behind = cam[tris, 2] < near
    count = behind.sum(1)
    keep = count == 0
    cross = np.nonzero((count > 0) & (count < 3))[0]
    new_v, new_c, new_u, new_t, new_o = [], [], [], [], []
    base = len(cam)
    for t in cross:
        idx = tris[t]
        poly = []
        for k in range(3):
            a, b = idx[k], idx[(k + 1) % 3]
            if cam[a, 2] >= near:
                poly.append((cam[a], colours[a], uvs[a]))
            if (cam[a, 2] >= near) != (cam[b, 2] >= near):
                s = (near - cam[a, 2]) / (cam[b, 2] - cam[a, 2])
                poly.append((cam[a] + s * (cam[b] - cam[a]), colours[a] + s * (colours[b] - colours[a]),
                             uvs[a] + s * (uvs[b] - uvs[a])))
        first = base + len(new_v)
        for v, c, u in poly:
            new_v.append(v)
            new_c.append(c)
            new_u.append(u)
        for k in range(1, len(poly) - 1):
            new_t.append((first, first + k, first + k + 1))
            new_o.append(owner[t])
    tris, owner = tris[keep], owner[keep]
    if new_t:
        cam = np.vstack([cam, new_v])
        colours = np.vstack([colours, new_c])
        uvs = np.vstack([uvs, new_u])
        tris = np.vstack([tris, np.array(new_t)])
        owner = np.concatenate([owner, new_o])
    return cam, tris, colours, uvs, owner


def draw(parts, cam, sx, sy, depth, tris, colours, uvs, owner, w, h, ss, lit, fog, perspective):
    # under perspective 1/depth is what stays linear across the screen, and attributes need
    # the matching correction, or big triangles near the camera smear and sort wrongly
    key = 1.0 / depth if perspective else -depth
    best_t, bary, best_key = rasterise(sx, sy, key, tris, w * ss, h * ss)
    hit = best_t >= 0
    t = best_t[hit]
    tv = tris[t]
    b0, b1 = bary[hit, 0], bary[hit, 1]
    b2 = 1 - b0 - b1
    if perspective:
        q0, q1, q2 = b0 * key[tv[:, 0]], b1 * key[tv[:, 1]], b2 * key[tv[:, 2]]
        total = q0 + q1 + q2
        b0, b1, b2 = q0 / total, q1 / total, q2 / total
    zbuf = np.full(best_t.shape, np.inf)
    zbuf[hit] = 1.0 / best_key[hit] if perspective else -best_key[hit]
    col = b0[:, None] * colours[tv[:, 0]] + b1[:, None] * colours[tv[:, 1]] + b2[:, None] * colours[tv[:, 2]]
    part = owner[t]
    for i, p in enumerate(parts):
        if p.texture is None:
            continue
        sel = part == i
        uv = b0[sel, None] * uvs[tv[sel, 0]] + b1[sel, None] * uvs[tv[sel, 1]] + b2[sel, None] * uvs[tv[sel, 2]]
        col[sel] *= sample_texture(p.texture, uv)
    if lit:
        col *= face_light(cam, tris, t)[:, None]
    if fog is not None:
        fog_rgb, density = fog
        keep = np.exp(-(density * zbuf[hit]) ** 2)[:, None]
        col = col * keep + np.asarray(fog_rgb) * (1 - keep)
    big = np.zeros((h * ss, w * ss, 3))
    big[hit] = col
    rgb = big.reshape(h, ss, w, ss, 3).mean((1, 3))
    alpha = hit.astype(np.float64).reshape(h, ss, w, ss).mean((1, 3))
    ids = np.full(best_t.shape, -1)
    ids[hit] = part
    c = ss // 2
    return Frame(rgb, alpha, ids[c::ss, c::ss], zbuf[c::ss, c::ss], [p.path for p in parts])


def face_light(cam, tris, t):
    a, b, c = cam[tris[t, 0]], cam[tris[t, 1]], cam[tris[t, 2]]
    n = np.cross(b - a, c - a)
    n /= np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-12)
    n *= np.where(n[:, 2:3] > 0, -1.0, 1.0)  # two-sided: face the camera
    light = LIGHT / np.linalg.norm(LIGHT)
    return AMBIENT + (1 - AMBIENT) * np.maximum(0.0, n @ light)


def to_image_array(frame, background=(0, 0, 0)):
    # sRGB uint8 picture composited over a background: an sRGB 0..255 colour, or an (h, w, 3)
    # linear rgb array such as sky_gradient()
    bg = np.asarray(background, dtype=np.float64)
    if bg.ndim == 1:
        bg = srgb_to_linear(bg / 255.0)
    lin = frame.rgb + (1 - frame.alpha[..., None]) * bg
    return (linear_to_srgb(lin) * 255 + 0.5).astype(np.uint8)


def sky_gradient(w, h, pitch, fov, horizon, zenith, power=0.6):
    # linear rgb sky for render_camera: horizon colour at eye level, zenith colour straight up
    f = (h / 2) / math.tan(math.radians(fov) / 2)
    rows = np.arange(h) + 0.5
    elevation = np.degrees(np.arctan((h / 2 - rows) / f)) - pitch
    t = np.clip(elevation / 90.0, 0, 1) ** power
    col = np.asarray(horizon) * (1 - t[:, None]) + np.asarray(zenith) * t[:, None]
    return np.broadcast_to(col[:, None, :], (h, w, 3)).copy()
