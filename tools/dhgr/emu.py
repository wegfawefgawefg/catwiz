# pictures through Tisple's own Apple IIe, headless: a 256-byte stub at $1F00 copies the aux
# half up to aux memory and turns on double hi-res, full screen, page 1; the main half loads
# straight to $2000. Screenshots in the flat colour look and the NTSC look (the real target),
# plus a luma picture for the value check and contact sheets.
#
# never opens a window: `tisple machine` with --frames and --screenshot runs without one.

import os
import subprocess

import dhgr

TISPLE = os.environ.get("TISPLE", "/media/vega/mdot2b/Coding2/LangDev/tisple/build/tisple")

# $1F00: STA $C005 (write aux); copy $4000-$5FFF to aux $2000-$3FFF through ($FA),Y and
# ($FC),Y; STA $C004 (write main); 80VID on; graphics, full screen, page 1, hi-res, AN3 off
# (double hi-res on); then loop forever.
STUB = bytes([
    0x8D, 0x05, 0xC0,              # sta $c005
    0xA9, 0x00, 0x85, 0xFA, 0x85, 0xFC,
    0xA9, 0x40, 0x85, 0xFB,
    0xA9, 0x20, 0x85, 0xFD,
    0xA2, 0x20, 0xA0, 0x00,
    0xB1, 0xFA, 0x91, 0xFC, 0xC8, 0xD0, 0xF9,
    0xE6, 0xFB, 0xE6, 0xFD, 0xCA, 0xD0, 0xF2,
    0x8D, 0x04, 0xC0,              # sta $c004
    0x8D, 0x0D, 0xC0,              # sta $c00d: 80 columns
    0xAD, 0x50, 0xC0, 0xAD, 0x52, 0xC0, 0xAD, 0x54, 0xC0, 0xAD, 0x57, 0xC0,
    0xAD, 0x5E, 0xC0,              # an3 off: double hi-res
    0x4C, 0x38, 0x1F,              # jmp to itself
])
assert STUB[0x38:0x3B] == bytes([0x4C, 0x38, 0x1F])


def shoot(main, aux, png, look="color"):
    # one screenshot of the pages; look: color, ntsc or mono
    os.makedirs(os.path.dirname(png), exist_ok=True)
    blob = STUB + bytes(0x100 - len(STUB)) + main + aux
    bin_path = png[:-4] + ".bin"
    with open(bin_path, "wb") as f:
        f.write(blob)
    args = [TISPLE, "machine", bin_path, "--origin", "0x1F00", "--frames", "20", "--screenshot", png]
    if look != "color":
        args.append("--" + look)
    r = subprocess.run(args, capture_output=True, text=True)
    os.remove(bin_path)
    if r.returncode != 0:
        raise SystemExit("tisple machine failed:\n" + r.stdout + r.stderr)
    small(png)
    return png


def small(png):
    # the emulator writes its pictures unpacked; packed they are a tenth of the size
    from PIL import Image
    Image.open(png).convert("RGB").save(png, optimize=True)


def show(px, out, name, looks=("color", "ntsc"), lines=None):
    # a picture of 140 x 192 colour pixels (and lines of text dots) through the emulator;
    # checks the round trip
    main, aux = dhgr.to_pages(px, lines)
    back = dhgr.from_pages(main, aux)
    for y in range(dhgr.H):
        if lines and y in lines:
            continue
        for x in range(dhgr.W):
            assert back[y][x] == (px[y][x] or 0), (name, x, y)
    paths = {}
    for look in looks:
        paths[look] = shoot(main, aux, os.path.join(out, "%s_%s.png" % (name, look)), look)
    return paths


def flat(px, path, scale=(4, 2), grey=False):
    # our own flat render (no emulator): fast, for sprite sheets
    from PIL import Image
    h, w = len(px), len(px[0])
    im = Image.new("RGB", (w, h))
    for y in range(h):
        for x in range(w):
            v = px[y][x]
            if v is None:
                im.putpixel((x, y), (40, 40, 48))
            else:
                im.putpixel((x, y), (dhgr.LUMA[v],) * 3 if grey else dhgr.RGB[v])
    im = im.resize((w * scale[0], h * scale[1]), Image.NEAREST)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    im.save(path)
    return path


def grey_of(png, out):
    # the emulator's picture as luma: the read with the hue taken away
    from PIL import Image
    Image.open(png).convert("L").save(out, optimize=True)
    return out


def sheet(cells, cols, path, label_h=26):
    # cells: (label, png path) row by row, all on one dark sheet
    from PIL import Image, ImageDraw, ImageFont
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 16)
    except OSError:
        font = ImageFont.load_default()
    ims = [(lab, Image.open(p).convert("RGB")) for lab, p in cells]
    w = max(i.size[0] for _, i in ims)
    h = max(i.size[1] for _, i in ims)
    pad = 10
    rows = (len(ims) + cols - 1) // cols
    out = Image.new("RGB", (cols * (w + pad) + pad, rows * (h + label_h + pad) + pad), (24, 24, 28))
    d = ImageDraw.Draw(out)
    for k, (lab, i) in enumerate(ims):
        x = pad + (k % cols) * (w + pad)
        y = pad + (k // cols) * (h + label_h + pad)
        d.text((x, y + 4), lab, fill=(230, 230, 230), font=font)
        out.paste(i, (x, y + label_h))
    out.save(path, optimize=True)
    return path
