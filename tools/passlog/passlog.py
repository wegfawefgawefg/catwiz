# a log of every pass of the main loop: a copy of the game counting, per pass, the frames it
# took and the drawing it did, in rings at $BF00 (the zero page save area, which a game that
# never returns does not read again); boots it with the keys given and prints the passes between two frames.
#
# run: python3 tools/passlog/passlog.py "700f:RETURN,1300f:1,1310f:Z" 1290 1500
# columns: the pass, its frames (by the card's clock: the card is in), the phase (and the
# action's source), bytes restored (each memory), sprite rows drawn, hud pixel rows written,
# text lines drawn, whole pages copied; LOOKS=1 the sprite rows by look instead

import os
import subprocess
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
TISPLE = os.environ.get("TISPLE", "tisple")
BUILD = os.path.join(ROOT, "build", "passlog")
LOOKS = os.environ.get("LOOKS") is not None  # LOOKS=1: sprite rows by look instead
RING = 0xBF20  # 7 rings of 32 bytes, by pass & 31, and the pass (its low byte) at $BF00: the zero page save, which the game never reads back

COUNT = """    (let lp_{n} (ptr u8) (as (ptr u8) (+ 0x{addr:X} (as u16 (& (load (as (ptr u8) 0xBF00)) 31)))))
    (store lp_{n} (+ (load lp_{n}) {amount}))
"""


def count(n, ring, amount):
    return COUNT.format(n=n, addr=RING + ring * 32, amount=amount)


def patch(path, old, new):
    text = open(path).read()
    if old not in text:
        sys.exit("not in %s: %s" % (path, old))
    open(path, "w").write(text.replace(old, new, 1))


def build():
    src = os.path.join(BUILD, "game")
    subprocess.run(["rm", "-rf", src], check=True)
    os.makedirs(BUILD, exist_ok=True)
    subprocess.run(["cp", "-r", os.path.join(ROOT, "game"), src], check=True)
    g = lambda f: os.path.join(src, f)
    # ring 0: frames; 1: phase; 2: restored bytes / 32; 3: sprite rows / 4; 4: hud rows;
    # 5: text lines; 6: whole pages; the pass's own slots are cleared when it starts
    clear = "".join("    (store (as (ptr u8) (+ 0x%X (as u16 (& (load (as (ptr u8) 0xBF00)) 31)))) 0)\n"
                    % (RING + r * 32) for r in range(2, 7))
    patch(g("main.tsp"), "        (let steps u8 (steps_due))\n",
          "        (store (as (ptr u8) 0xBF00) (as u8 state.ticks))\n        (let steps u8 (steps_due))\n" + clear +
          "    (store (as (ptr u8) (+ 0x%X (as u16 (& (load (as (ptr u8) 0xBF00)) 31)))) (| (as u8 state.phase) (<< (as u8 state.act_source) 4)))\n" % (RING + 32))
    patch(g("main.tsp"), "    (set counted now)\n",
          "    (set counted now)\n    (store (as (ptr u8) (+ 0x%X (as u16 (& (load (as (ptr u8) 0xBF00)) 31)))) gone)\n" % RING)
    patch(g("draw/scene.tsp"), "(fn restore_box ((page u8) (col u8) (top u8) (cols u8) (rows u8)) void\n",
          "(fn restore_box ((page u8) (col u8) (top u8) (cols u8) (rows u8)) void\n" +
          count("r", 2, "(as u8 (>> (* (as u16 cols) (as u16 rows)) 5))"))
    if LOOKS:
        # by look: 3 the hero, 4 the first enemy, 5 the second, 6 every other look (rows / 4)
        patch(g("draw/scene.tsp"), "(fn draw_look ((page u8) (i u8) (rows u8)) void\n",
              "(fn draw_look ((page u8) (i u8) (rows u8)) void\n"
              "    (let ring_d u8 6)\n"
              "    (if (< i 3)\n        (set ring_d (+ i 3)))\n"
              "    (let lp_d (ptr u8) (as (ptr u8) (+ (+ 0x%X (* (as u16 ring_d) 32)) (as u16 (& (load (as (ptr u8) 0xBF00)) 31)))))\n"
              "    (store lp_d (+ (load lp_d) (>> rows 2)))\n" % RING)
    else:
        patch(g("draw/scene.tsp"), "(fn draw_look ((page u8) (i u8) (rows u8)) void\n",
              "(fn draw_look ((page u8) (i u8) (rows u8)) void\n" + count("d", 3, "(>> rows 2)"))
        patch(g("draw/pix.tsp"), "(fn write ((page u8) (y u8)) void\n",
              "(fn write ((page u8) (y u8)) void\n" + count("w", 4, "1"))
        patch(g("draw/text.tsp"), "    (let y u8 (+ TOP (<< r 3)))\n",
              "    (let y u8 (+ TOP (<< r 3)))\n" + count("t", 5, "1"))
        patch(g("draw/screen.tsp"), "(fn copy_page ((from u8) (to u8)) void\n",
              "(fn copy_page ((from u8) (to u8)) void\n" + count("p", 6, "1"))
    disk = os.path.join(BUILD, "passlog.dsk")
    listing = subprocess.run([TISPLE, "build", "main.tsp", "--origin", "0x8000", "--disk", disk, "--asm"],
                             cwd=src, capture_output=True, text=True, check=True).stdout
    return disk


def read(disk, keys, frame):
    # the pass and the rings at frame, or None when the run stopped with aux memory switched in
    # for reading (the pass at $BDFF then does not match the counter)
    out = subprocess.run([TISPLE, "machine", "--disk", disk, "--mockingboard", "4", "--frames", str(frame),
                          "--keys", keys, "--peek", "0x06E2:2", "--peek", "0xBF00:%d" % (RING - 0xBF00 + 7 * 32)],
                         capture_output=True, text=True, check=True).stdout
    peeks = [[int(x, 16) for x in line.split(":", 1)[1].split("(")[0].split()]
             for line in out.split("\n") if line.startswith("peek")]
    t = peeks[0][0] | peeks[0][1] << 8
    if t == 0 or peeks[1][0] != (t & 0xFF):
        return None
    return t, peeks[1][RING - 0xBF00:]


PHASES = ["roll", "player", "act", "enemies", "won", "lost", "reward"]
SOURCES = ["face", "move", "meow"]


def main():
    keys, start, end = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
    disk = build()
    # read the rings every 24 passes' worth of frames would miss passes when they are short;
    # read at end, then step back while passes remain (each read gives the last 31 passes)
    rows = {}
    frame = end
    while frame > start and (not rows or min(rows) > 0):
        got = read(disk, keys, frame)
        if got is None:
            frame -= 1
            continue
        t, rings = got
        # the pass now (t) is still going; pass p took the frames the pass after it counted
        back_frames = 0
        for p in range(t - 1, max(t - 31, 0), -1):
            slot = p & 31
            took = rings[(p + 1) & 31]
            if p not in rows:
                rows[p] = [took] + [rings[r * 32 + slot] for r in range(1, 7)]
            back_frames += took
        frame -= max(back_frames, 1)
    if LOOKS:
        print("pass frames phase        restored   hero  enemy1 enemy2 others (sprite rows)")
    else:
        print("pass frames phase        restored sprite-rows hud-rows text pages")
    for p in sorted(rows):
        took, ph, rest, spr, hud, txt, pages = rows[p]
        phase = PHASES[ph & 15] if (ph & 15) < len(PHASES) else str(ph)
        if phase in ("act", "enemies"):
            phase += "/" + SOURCES[ph >> 4] if (ph >> 4) < 3 else ""
        if LOOKS:
            print("%4d %5d  %-13s %7d %6d %6d %6d %6d" % (p, took, phase, rest * 32, spr * 4, hud * 4,
                                                          txt * 4, pages * 4))
        else:
            print("%4d %5d  %-13s %7d %6d %6d %4d %4d" % (p, took, phase,
                                                         rest * 32, spr * 4, hud, txt, pages))


main()
