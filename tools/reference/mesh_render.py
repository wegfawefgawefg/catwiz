# exports chosen meshes from the owner's Dog Witch copy to OBJ (data/extracted, out of git) and
# renders each as a flat-shaded preview with a small z-buffer rasteriser, for silhouette reference.
import math, sys, numpy as np, UnityPy
from PIL import Image

root = "/media/vega/mdot2b/SteamLibrary/steamapps/common/DOG WITCH/DOG WITCH_Data"
WANT = sys.argv[1:] or ["Musho_Body", "Musho_Hat", "bat", "headBullDog_Default", "bulldogL_ear", "BasicHat"]
out_dir = "data/extracted/meshes"

def load_obj(text):
    v, f = [], []
    for line in text.splitlines():
        p = line.split()
        if not p:
            continue
        if p[0] == "v":
            v.append([float(x) for x in p[1:4]])
        elif p[0] == "f":
            idx = [int(q.split("/")[0]) - 1 for q in p[1:]]
            for k in range(1, len(idx) - 1):
                f.append([idx[0], idx[k], idx[k + 1]])
    return np.array(v), np.array(f)

def render(v, f, size=256, yaw=0.0, pitch=0.25):
    cy, sy, cp, sp = math.cos(yaw), math.sin(yaw), math.cos(pitch), math.sin(pitch)
    r = np.array([[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]]) @ np.array([[1, 0, 0], [0, cp, -sp], [0, sp, cp]])
    p = (v - v.mean(0)) @ r.T
    scale = (size * 0.9) / max(np.ptp(p[:, 0]), np.ptp(p[:, 1]))
    sx = p[:, 0] * scale + size / 2
    sy2 = -p[:, 1] * scale + size / 2
    z = p[:, 2]
    img = np.zeros((size, size), np.float32)
    zb = np.full((size, size), -1e9)
    light = np.array([0.4, 0.6, 0.7]); light /= np.linalg.norm(light)
    for a, b, c in f:
        n = np.cross(p[b] - p[a], p[c] - p[a])
        ln = np.linalg.norm(n)
        if ln == 0:
            continue
        shade = 0.25 + 0.75 * abs(np.dot(n / ln, light))
        xs, ys = np.array([sx[a], sx[b], sx[c]]), np.array([sy2[a], sy2[b], sy2[c]])
        x0, x1 = int(max(0, xs.min())), int(min(size - 1, xs.max())) + 1
        y0, y1 = int(max(0, ys.min())), int(min(size - 1, ys.max())) + 1
        if x1 <= x0 or y1 <= y0:
            continue
        gx, gy = np.meshgrid(np.arange(x0, x1) + 0.5, np.arange(y0, y1) + 0.5)
        d = (ys[1] - ys[2]) * (xs[0] - xs[2]) + (xs[2] - xs[1]) * (ys[0] - ys[2])
        if abs(d) < 1e-9:
            continue
        w0 = ((ys[1] - ys[2]) * (gx - xs[2]) + (xs[2] - xs[1]) * (gy - ys[2])) / d
        w1 = ((ys[2] - ys[0]) * (gx - xs[2]) + (xs[0] - xs[2]) * (gy - ys[2])) / d
        w2 = 1 - w0 - w1
        inside = (w0 >= 0) & (w1 >= 0) & (w2 >= 0)
        zz = w0 * z[a] + w1 * z[b] + w2 * z[c]
        sub = zb[y0:y1, x0:x1]
        hit = inside & (zz > sub)
        sub[hit] = zz[hit]
        img[y0:y1, x0:x1][hit] = shade
    return Image.fromarray((img * 255).astype(np.uint8))

tiles = []
for fname in ["resources.assets", "sharedassets2.assets"]:
    env = UnityPy.load(f"{root}/{fname}")
    for o in env.objects:
        if o.type.name != "Mesh":
            continue
        m = o.read()
        if m.m_Name not in WANT or any(t[0] == m.m_Name for t in tiles):
            continue
        obj = m.export()
        open(f"{out_dir}/{m.m_Name}.obj", "w").write(obj)
        v, f = load_obj(obj)
        print(m.m_Name, len(v), "verts", len(f), "tris")
        tiles.append((m.m_Name, render(v, f)))
sheet = Image.new("L", (256 * len(tiles), 256), 40)
for i, (_, im) in enumerate(tiles):
    sheet.paste(im, (i * 256, 0))
sheet.save("mockup/out/mesh_sheet.png")
