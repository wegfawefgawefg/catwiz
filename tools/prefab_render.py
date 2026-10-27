# renders Dog Witch prefabs from the owner's install as reference for hi-res redraws: each
# character in the battle's front three-quarter view, flat coloured with simple light, plus a
# silhouette/ID mask (one colour per part, black outline), at the pixel sizes a 280x192 screen
# would use. also a whole forest battle from a camera like the game's.
#
# run:  tools/.venv/bin/python tools/prefab_render.py            all targets + contact sheet
#       tools/.venv/bin/python tools/prefab_render.py musho dog   just those
#       tools/.venv/bin/python tools/prefab_render.py --describe Musho   print a prefab's tree
#       tools/.venv/bin/python tools/prefab_render.py --yaws Musho      turn strip, to pick yaw
# writes mockup/out/prefabs/*.png and mockup/out/prefab_sheet.png (gitignored: derived art).

import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
import raster  # noqa: E402
import unity_assets as ua  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = os.path.join(ROOT, "mockup", "out", "prefabs")
SHEET = os.path.join(ROOT, "mockup", "out", "prefab_sheet.png")
REFERENCE = os.path.expanduser("~/Coding/Ideas/dogwitch-reference")

# pixels per world unit. GAME: what the battle camera gives on a 192-line screen (the dog is
# about a quarter of the height, as in the screenshots). MOCKUP: the size mockup/battle_forest.py
# draws the dog at (about 90 lines with the hat).
GAME_SCALE = 2.47
MOCKUP_SCALE = 4.6

# the battle camera: level2's Main Camera x, height and fov, moved in until the dog is a quarter
# of the screen like the screenshots, and tilted to put the horizon where they have it.
CAMERA_EYE = (-5.94, 10.0, -92.0)
CAMERA_PITCH = 7.0
CAMERA_FOV = 50.6
# level2's RenderSettings fog colour; the forest sky material's horizon and top colours (sRGB)
FOG = (0.59, 0.64, 0.48)
SKY_TOP = (0.79, 0.86, 0.64)
FOG_DENSITY = 0.0016

DOG_SKIP = ("Head_Panting", "Head_Barking", "Tongue", "BarkLines", "Closed_Eyes")


class Target:
    def __init__(self, key, root, yaw=0.0, skip=(), force=(), note=""):
        self.key, self.root, self.yaw, self.skip, self.force, self.note = key, root, yaw, skip, force, note


TARGETS = [
    Target("dog", "Player_DOGWITCH", 30, DOG_SKIP, ("Head_Default",), "level2 scene; kingCharles head, classic hat"),
    Target("musho", "Musho", 15),
    Target("bwat", "Bwat", -20),
    Target("leafy", "Leafy", 20),
    Target("big_bad_tree", "EnemyMinions.BigBadTree", 15),
    Target("bad_bee", "BadBee", -25, ("wings_0_0", "wings_0_8", "wings_1")),
    Target("jack_rabbit", "JackRabbit", 15),
]
SCENERY = ["forest_trees", "forest_tree", "forest_ground", "forest_battle"]

MASK_COLOURS = [(230, 80, 70), (80, 170, 230), (240, 200, 60), (120, 200, 90), (190, 110, 220),
                (250, 150, 60), (70, 210, 190), (230, 120, 170), (150, 150, 240), (200, 220, 120),
                (160, 100, 60), (100, 120, 140), (255, 255, 255), (60, 140, 90)]
MASK_BG = (128, 128, 128)


def target_parts(env, t):
    return ua.prefab_parts(env, ua.find_root(env, t.root), t.skip, t.force)


def forest_parts(env, spin=180.0):
    # the forest disc is a ring of trees with a gap; the game turns it as you travel. spin it so
    # trees stand behind the battle instead of the gap.
    root = ua.find_root(env, "ForestEnvironment")
    centre = ua.local_matrix(ua.transform_of(root))[:3, 3]
    parts = ua.prefab_parts(env, root)
    return ua.moved(parts, ua.yaw_about(centre, spin))


def mask_image(frame):
    # one flat colour per part, a black line outside the silhouette and dark lines where parts meet
    ids = frame.part_id
    h, w = ids.shape
    img = np.zeros((h, w, 3), np.uint8)
    img[:] = MASK_BG
    for i in range(len(frame.names)):
        img[ids == i] = MASK_COLOURS[i % len(MASK_COLOURS)]
    inside = ids >= 0
    pad = np.pad(ids, 1, constant_values=-1)
    near = [pad[1:-1, :-2], pad[1:-1, 2:], pad[:-2, 1:-1], pad[2:, 1:-1]]
    outline = ~inside & np.any([n >= 0 for n in near], axis=0)
    img[outline] = (0, 0, 0)
    zpad = np.pad(frame.depth, 1, constant_values=np.inf)
    znear = [zpad[1:-1, :-2], zpad[1:-1, 2:], zpad[:-2, 1:-1], zpad[2:, 1:-1]]
    seam = np.zeros_like(inside)
    for n, z in zip(near, znear):
        seam |= inside & (n >= 0) & (n != ids) & (frame.depth > z)
    img[seam] = (40, 40, 40)
    return img


def flat_image(frame, background=MASK_BG):
    return raster.to_image_array(frame, background)


def save(img, name):
    path = os.path.join(OUT, name)
    Image.fromarray(img).save(path)
    return path


def render_target(env, t):
    parts = target_parts(env, t)
    view = raster.View(yaw=t.yaw, pitch=CAMERA_PITCH, fov=12)
    out = {"parts": [p.path.split("/")[-1] + (" (clear)" if p.transparent else "") for p in parts]}
    for size, scale in (("game", GAME_SCALE), ("mockup", MOCKUP_SCALE)):
        frame = raster.render(parts, view, scale=scale)
        out[size] = flat_image(frame)
        out[size + "_mask"] = mask_image(frame)
        save(out[size], f"{t.key}_{size}.png")
        save(out[size + "_mask"], f"{t.key}_{size}_mask.png")
    detail = raster.render(parts, view, height=240)
    out["detail"] = flat_image(detail)
    save(out["detail"], f"{t.key}_detail.png")
    return out


def render_scenery(env, key, forest):
    view = raster.View(yaw=20, pitch=CAMERA_PITCH, fov=12)
    if key == "forest_battle":
        return render_battle(env, forest)
    if key == "forest_trees":
        # an arc of the ring behind the battle
        parts = ua.cropped(forest, (-90, -1, 40), (90, 80, 110))
    elif key == "forest_tree":
        parts = ua.cropped(forest, (-14, -1, 55), (10, 80, 110))
    else:
        # the ground cover between the trees (mushrooms, grass) on a cut of the floor disc
        parts = ua.cropped(forest, (8, -1, 30), (36, 3, 110))
    out = {"parts": sorted({p.name for p in parts})}
    frame = raster.render(parts, view, scale=GAME_SCALE if key != "forest_tree" else MOCKUP_SCALE)
    out["game"] = flat_image(frame)
    out["game_mask"] = mask_image(frame)
    save(out["game"], f"{key}.png")
    save(out["game_mask"], f"{key}_mask.png")
    detail = raster.render(parts, view, height=240)
    out["detail"] = flat_image(detail)
    save(out["detail"], f"{key}_detail.png")
    return out


def battle_parts(env, forest):
    # PersistantEnvironment's mountain is left out: its base shows as a purple rim on the
    # horizon because the game recolours it per biome at run time, which we can't read
    parts = list(forest)
    parts += ua.prefab_parts(env, ua.find_root(env, "Player_DOGWITCH"), DOG_SKIP, ("Head_Default",))
    parts += ua.prefab_parts(env, ua.find_root(env, "EnemyMinions.Mushos"))
    return parts


def render_battle(env, forest):
    # the first forest fight (three mushos, as EnemyMinions.Mushos lays them out) at 280x192 and
    # at 960x540, sky and fog approximated from the scene's settings
    parts = battle_parts(env, forest)
    fog = (ua.srgb_to_linear(FOG), FOG_DENSITY)
    out = {"parts": ["ForestEnvironment", "Player_DOGWITCH", "EnemyMinions.Mushos"]}
    for key, (w, h) in (("game", (280, 192)), ("detail", (960, 540))):
        frame = raster.render_camera(parts, CAMERA_EYE, CAMERA_PITCH, CAMERA_FOV, w, h, ss=3, fog=fog)
        sky = raster.sky_gradient(w, h, CAMERA_PITCH, CAMERA_FOV, ua.srgb_to_linear(FOG), ua.srgb_to_linear(SKY_TOP))
        out[key] = raster.to_image_array(frame, sky)
        save(out[key], f"forest_battle_{w}x{h}.png")
        if key == "game":
            out["game_mask"] = mask_image(frame)
            save(out["game_mask"], "forest_battle_280x192_mask.png")
    return out


def zoom(img, k):
    return np.asarray(Image.fromarray(img).resize((img.shape[1] * k, img.shape[0] * k), Image.NEAREST))


def contact_sheet(results):
    # one row per target: game size and mockup size (flat and mask, zoomed 2x so pixels show),
    # then a big smooth render; the reference screenshots along the top
    rows = []
    refs = [f for f in ("01-battle-desert.jpg", "06-battle-mountain.png", "07-dog-closeup.jpg")
            if os.path.exists(os.path.join(REFERENCE, f))]
    if refs:
        ims = [Image.open(os.path.join(REFERENCE, f)).convert("RGB") for f in refs]
        ims = [im.resize((im.width * 300 // im.height, 300)) for im in ims]
        strip = Image.new("RGB", (sum(i.width for i in ims) + 10 * len(ims), 330), (30, 30, 30))
        x = 0
        for im in ims:
            strip.paste(im, (x, 24))
            x += im.width + 10
        ImageDraw.Draw(strip).text((4, 6), "reference screenshots (the real game)", fill=(255, 255, 255))
        rows.append(strip)
    for key, res in results.items():
        tiles = []
        for k, zoom_by in (("game", 2), ("game_mask", 2), ("mockup", 2), ("mockup_mask", 2), ("detail", 1)):
            if k in res:
                tiles.append((k, Image.fromarray(zoom(res[k], zoom_by))))
        hgt = max(t.height for _, t in tiles) + 40
        row = Image.new("RGB", (sum(t.width for _, t in tiles) + 16 * len(tiles) + 8, hgt), (30, 30, 30))
        d = ImageDraw.Draw(row)
        d.text((4, 4), f"{key}: " + ", ".join(res["parts"])[:230], fill=(255, 255, 255))
        x = 4
        for label, t in tiles:
            row.paste(t, (x, 36))
            d.text((x, 22), label + (" x2" if label != "detail" else ""), fill=(180, 180, 180))
            x += t.width + 16
        rows.append(row)
    sheet = Image.new("RGB", (max(r.width for r in rows), sum(r.height for r in rows)), (30, 30, 30))
    y = 0
    for r in rows:
        sheet.paste(r, (0, y))
        y += r.height
    sheet.save(SHEET)
    return SHEET


def yaw_strip(env, root_name):
    parts = ua.prefab_parts(env, ua.find_root(env, root_name))
    tiles = [Image.fromarray(flat_image(raster.render(parts, raster.View(yaw=y, pitch=CAMERA_PITCH), height=160)))
             for y in range(-90, 91, 30)]
    strip = Image.new("RGB", (sum(t.width + 8 for t in tiles), 180), (30, 30, 30))
    x = 0
    for y, t in zip(range(-90, 91, 30), tiles):
        strip.paste(t, (x, 20))
        ImageDraw.Draw(strip).text((x + 2, 4), f"yaw {y}", fill=(255, 255, 255))
        x += t.width + 8
    path = os.path.join(OUT, f"yaws_{root_name}.png")
    strip.save(path)
    print(path)


def main(args):
    os.makedirs(OUT, exist_ok=True)
    env = ua.load_env()
    if args[:1] == ["--describe"]:
        print(ua.describe(ua.find_root(env, args[1])))
        return
    if args[:1] == ["--yaws"]:
        yaw_strip(env, args[1])
        return
    want = args or [t.key for t in TARGETS] + SCENERY
    results = {}
    for t in TARGETS:
        if t.key in want:
            results[t.key] = render_target(env, t)
            print(t.key, t.root, "parts:", ", ".join(results[t.key]["parts"]))
    forest = None
    for key in SCENERY:
        if key in want:
            forest = forest if forest is not None else forest_parts(env)
            results[key] = render_scenery(env, key, forest)
            print(key, "parts:", ", ".join(results[key]["parts"]))
    print(contact_sheet(results))


if __name__ == "__main__":
    main(sys.argv[1:])
