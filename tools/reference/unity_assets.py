# reads prefabs out of the owner's Dog Witch install: finds a root GameObject by name, walks its
# Transform tree and returns every visible mesh part in world space with its colours.
#
# what the game's data looks like (Unity 2022, URP, IL2CPP):
# - characters and enemies live in the Addressables bundles (encounters_*, defaultlocalgroup_*);
#   catalog.bin names the current ones, older hashes sit next to them unused. the player is in
#   level2, its dog head/ears/eyes come from sharedassets2.
# - most parts use "Shader Graphs/LitVertexColor": the colour is in the mesh's vertex colours.
#   a few use URP Lit/Unlit with _BaseColor/_Color and maybe a _BaseMap/_MainTex texture.
# - many enemies are skinned (SkinnedMeshRenderer); those are posed with the prefab's own bone
#   transforms, which is the rest pose the prefab was saved in, not an animation frame.

import numpy as np
import UnityPy

GAME = "/media/vega/mdot2b/SteamLibrary/steamapps/common/DOG WITCH/DOG WITCH_Data/"
AA = GAME + "StreamingAssets/aa/StandaloneWindows64/"
# searched in this order when a name exists in more than one file
FILES = [
    AA + "encounters_assets_all_8c8456869f4fbe3d10b3ac285baf823f.bundle",
    AA + "defaultlocalgroup_assets_all_41e70c5296b9ee35ae33b6cdaf21f851.bundle",
    AA + "duplicateassetisolation_assets_all_e86ef9ca38026f720abb30b19f238a76.bundle",
    AA + "37f219c36af1c6e6d86a429783472b28_unitybuiltinassets_1753930966e372b7ea0f52b87c96a715.bundle",
    GAME + "level2",
    GAME + "sharedassets2.assets",
    GAME + "resources.assets",
    GAME + "globalgamemanagers.assets",
]
COLOUR_KEYS = ("_BaseColor", "_Color", "Color_F23AE9B1")
TEXTURE_KEYS = ("_BaseMap", "_MainTex", "_Texture2D", "_MainTexture", "Texture2D_")


class Part:
    # one drawable: a submesh with one material, already in world space
    def __init__(self, name, path, verts, tris, colours, uvs, texture, material, shader, transparent=False):
        self.name = name          # GameObject name
        self.path = path          # slash path from the prefab root
        self.verts = verts        # (n, 3) world positions
        self.tris = tris          # (m, 3) vertex indices
        self.colours = colours    # (n, 3) linear rgb 0..1, vertex colour times material colour
        self.uvs = uvs            # (n, 2) or None
        self.texture = texture    # (h, w, 3) float rgb 0..1 or None
        self.material = material
        self.shader = shader
        self.transparent = transparent  # a see-through material (bee wings): drawn opaque here


def load_env():
    return UnityPy.load(*FILES)


def find_roots(env, name):
    # every root GameObject called name, in FILES order
    found = []
    for obj in env.objects:
        if obj.type.name != "GameObject":
            continue
        go = obj.read()
        if go.m_Name != name:
            continue
        tf = transform_of(go)
        if tf is not None and tf.m_Father.path_id == 0:
            found.append(go)
    return sorted(found, key=lambda go: source_rank(go.object_reader))


def source_file(obj):
    # the game file an object came from: a bundle's path, or the serialized file's own name
    f = obj.assets_file
    while getattr(f, "parent", None) is not None and hasattr(f.parent, "parent"):
        f = f.parent
    return getattr(f, "name", "?").split("/")[-1]


def source_rank(obj):
    names = [f.split("/")[-1] for f in FILES]
    name = source_file(obj)
    return names.index(name) if name in names else len(names)


def find_root(env, name):
    roots = find_roots(env, name)
    if not roots:
        raise KeyError(f"no root GameObject named {name!r}")
    return roots[0]


def components(go):
    out = []
    for entry in go.m_Component:
        ptr = entry.component if hasattr(entry, "component") else entry[1]
        try:
            out.append(ptr.read())
        except Exception:
            pass
    return out


def component(go, type_name):
    for c in components(go):
        if c.object_reader.type.name == type_name:
            return c
    return None


def transform_of(go):
    return component(go, "Transform") or component(go, "RectTransform")


def local_matrix(tf):
    p, q, s = tf.m_LocalPosition, tf.m_LocalRotation, tf.m_LocalScale
    x, y, z, w = q.x, q.y, q.z, q.w
    rot = np.array([
        [1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
        [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
        [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)],
    ])
    m = np.eye(4)
    m[:3, :3] = rot * np.array([s.x, s.y, s.z])
    m[:3, 3] = [p.x, p.y, p.z]
    return m


def walk(root_go, force=()):
    # yields (GameObject, world matrix, path, active, Transform) for the root and every
    # descendant. the root keeps its saved rotation and scale; the renderer frames by bounds,
    # so its saved position does not matter. a node is active only if all its parents are;
    # names in force count as active (alternate heads, faces) whatever the prefab saved.
    stack = [(root_go, np.eye(4), "", True)]
    while stack:
        go, parent, path, parent_active = stack.pop()
        tf = transform_of(go)
        world = parent @ local_matrix(tf)
        active = parent_active and (bool(go.m_IsActive) or go.m_Name in force)
        here = f"{path}/{go.m_Name}" if path else go.m_Name
        yield go, world, here, active, tf
        for child in reversed(tf.m_Children):
            try:
                child_tf = child.read()
            except Exception:
                continue
            stack.append((child_tf.m_GameObject.read(), world, here, active))


def mesh_arrays(mesh):
    from UnityPy.helpers.MeshHelper import MeshHandler
    h = MeshHandler(mesh)
    h.process()
    verts = np.array(h.m_Vertices, dtype=np.float64).reshape(-1, 3)
    n = len(verts)
    colours = np.ones((n, 3))
    if h.m_Colors and len(h.m_Colors) == n:
        colours = np.array(h.m_Colors, dtype=np.float64)[:, :3]
        if colours.max() > 1.5:
            colours /= 255.0  # UNorm8 colour channels come back as 0..255
    uvs = None
    if h.m_UV0 and len(h.m_UV0) == n:
        uvs = np.array(h.m_UV0, dtype=np.float64)[:, :2]
    weights = indices = None
    if h.m_BoneWeights and len(h.m_BoneWeights) == n:
        weights = np.array(h.m_BoneWeights, dtype=np.float64)
        indices = np.array(h.m_BoneIndices, dtype=np.int64)
    submeshes = [np.array(t, dtype=np.int64).reshape(-1, 3) for t in h.get_triangles()]
    return verts, colours, uvs, submeshes, weights, indices


TEXTURE_CACHE = {}


def texture_pixels(tex):
    key = (tex.object_reader.assets_file.name, tex.object_reader.path_id)
    if key not in TEXTURE_CACHE:
        img = tex.image.convert("RGB")
        if img.width * img.height > 512 * 512:
            img = img.resize((512, 512 * img.height // img.width))
        # textures are sRGB; keep everything in linear until the end
        TEXTURE_CACHE[key] = srgb_to_linear(np.asarray(img, dtype=np.float64) / 255.0)
    return TEXTURE_CACHE[key]


def srgb_to_linear(c):
    c = np.asarray(c, dtype=np.float64)
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def linear_to_srgb(c):
    c = np.clip(np.asarray(c, dtype=np.float64), 0, 1)
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * c ** (1 / 2.4) - 0.055)


def material_info(mat):
    # returns (linear rgb tint, texture or None, shader name, uses vertex colour, transparent)
    shader = "?"
    try:
        sh = mat.m_Shader.read()
        shader = sh.m_ParsedForm.m_Name if getattr(sh, "m_ParsedForm", None) else sh.m_Name
    except Exception:
        pass
    props = mat.m_SavedProperties
    colours = {k: v for k, v in props.m_Colors}
    vertex_colour = "VertexColor" in shader
    tint = np.ones(3)
    if not vertex_colour:
        for key in COLOUR_KEYS:
            if key in colours:
                c = colours[key]
                tint = srgb_to_linear([c.r, c.g, c.b])  # material colours are stored in sRGB
                break
    texture = None
    for key, env in props.m_TexEnvs:
        if not env.m_Texture.path_id or not any(key.startswith(t) for t in TEXTURE_KEYS):
            continue
        try:
            texture = texture_pixels(env.m_Texture.read())
            break
        except Exception:
            pass
    keywords = getattr(mat, "m_ValidKeywords", None) or getattr(mat, "m_ShaderKeywords", None) or []
    if isinstance(keywords, str):
        keywords = keywords.split()
    transparent = "_SURFACE_TYPE_TRANSPARENT" in keywords
    return tint, texture, shader, vertex_colour, transparent


def skin(verts, weights, indices, bones, bind_poses):
    # linear blend skinning with the bones' current world matrices
    out = np.zeros_like(verts)
    homo = np.c_[verts, np.ones(len(verts))]
    for b, (bone, bind) in enumerate(zip(bones, bind_poses)):
        w = (weights * (indices == b)).sum(1)
        if not w.any():
            continue
        out += w[:, None] * (homo @ (bone @ bind).T)[:, :3]
    return out


def bind_pose_matrix(m):
    if hasattr(m, "e00"):
        return np.array([[getattr(m, f"e{r}{c}") for c in range(4)] for r in range(4)])
    return np.array(m, dtype=np.float64).reshape(4, 4)


def renderer_parts(go, world, path, worlds_by_tf, force=()):
    mf = component(go, "MeshFilter")
    mr = component(go, "MeshRenderer")
    smr = component(go, "SkinnedMeshRenderer")
    renderer = smr or mr
    if renderer is None or not (getattr(renderer, "m_Enabled", True) or go.m_Name in force):
        return []
    try:
        mesh = (smr.m_Mesh if smr else mf.m_Mesh).read()
    except Exception:
        return []
    verts, vcol, uvs, submeshes, weights, indices = mesh_arrays(mesh)
    if smr is not None and weights is not None and smr.m_Bones:
        bones = []
        for ptr in smr.m_Bones:
            key = (ptr.path_id,)
            bones.append(worlds_by_tf.get(key, world))
        bind = [bind_pose_matrix(m) for m in mesh.m_BindPose]
        if len(bind) == len(bones):
            verts = skin(verts, weights, indices, bones, bind)
        else:
            verts = (np.c_[verts, np.ones(len(verts))] @ world.T)[:, :3]
    else:
        verts = (np.c_[verts, np.ones(len(verts))] @ world.T)[:, :3]
    vcol = srgb_to_linear(vcol)  # vertex colours are authored in sRGB
    parts = []
    for i, tris in enumerate(submeshes):
        if not len(tris) or i >= len(renderer.m_Materials):
            continue
        try:
            mat = renderer.m_Materials[i].read()
        except Exception:
            continue
        tint, texture, shader, uses_vc, transparent = material_info(mat)
        if "Particles" in shader or "Additive" in shader or texture is not None and uvs is None:
            continue
        colours = (vcol if uses_vc else np.ones_like(vcol)) * tint
        parts.append(Part(go.m_Name, path, verts, tris, colours, uvs if texture is not None else None,
                          texture, mat.m_Name, shader, transparent))
    return parts


def prefab_parts(env, root_go, skip=(), force=()):
    # every visible part of the prefab; names in skip (or under them) are left out
    nodes = list(walk(root_go, force))
    worlds_by_tf = {(tf.object_reader.path_id,): world for _, world, _, _, tf in nodes}
    parts = []
    for go, world, path, active, _ in nodes:
        if not active or any(f"/{s}" in f"/{path}" for s in skip):
            continue
        parts += renderer_parts(go, world, path, worlds_by_tf, force)
    return parts


def describe(root_go):
    # an indented listing of the prefab, for finding part names
    lines = []
    for go, _, path, active, _ in walk(root_go):
        kinds = [c.object_reader.type.name for c in components(go)]
        kinds = [k for k in kinds if k in ("MeshFilter", "SkinnedMeshRenderer", "Animator")]
        depth = path.count("/")
        lines.append("  " * depth + go.m_Name + ("" if active else " (inactive)") + (f" [{','.join(kinds)}]" if kinds else ""))
    return "\n".join(lines)


def moved(parts, matrix):
    # the same parts under an extra world transform (4x4), e.g. to spin an environment disc
    out = []
    for p in parts:
        v = (np.c_[p.verts, np.ones(len(p.verts))] @ matrix.T)[:, :3]
        out.append(Part(p.name, p.path, v, p.tris, p.colours, p.uvs, p.texture, p.material, p.shader, p.transparent))
    return out


def yaw_about(point, degrees):
    # 4x4 turn about the vertical axis through point (Unity's sense: +z towards +x)
    a = np.radians(degrees)
    m = np.eye(4)
    m[0, 0], m[0, 2], m[2, 0], m[2, 2] = np.cos(a), np.sin(a), -np.sin(a), np.cos(a)
    t = np.eye(4)
    t[:3, 3] = point
    back = np.eye(4)
    back[:3, 3] = -np.asarray(point)
    return t @ m @ back


def cropped(parts, lo, hi):
    # only the triangles whose centre lies in the world box lo..hi: one tree out of a forest mesh
    lo, hi = np.asarray(lo), np.asarray(hi)
    out = []
    for p in parts:
        centre = p.verts[p.tris].mean(1)
        keep = np.all((centre >= lo) & (centre <= hi), axis=1)
        if not keep.any():
            continue
        used, tris = np.unique(p.tris[keep], return_inverse=True)
        uvs = p.uvs[used] if p.uvs is not None else None
        out.append(Part(p.name, p.path, p.verts[used], tris.reshape(-1, 3), p.colours[used], uvs, p.texture,
                        p.material, p.shader, p.transparent))
    return out
