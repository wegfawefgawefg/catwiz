# frame costs, measured on Tisple's cycle-exact IIe: builds the game with WAIT_FOR_BLANK false,
# so the main loop runs flat out, boots it, presses the keys given, and reads the loop counter
# (state.ticks) at two moments. Cycles a frame = cycles between them / passes between them.
#
# run: python3 tools/measure.py "1000f:RETURN" 1100 1400
#      keys as for tisple machine, then the two frames to measure between, then any number of
#      "file|old|new" edits to the copy it builds, to try something out; MB=4 puts a
#      Mockingboard in slot 4, so the music plays while it measures

import os
import re
import subprocess
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
TISPLE = os.environ.get("TISPLE", os.path.expanduser("~/Coding/LangDev/tisple/build/tisple"))
BUILD = os.path.join(ROOT, "build", "measure")
CYCLES_PER_FRAME = 17030


def build(changes):
    # changes: "file|old|new" edits to try something out without touching game/
    src = os.path.join(BUILD, "game")
    subprocess.run(["rm", "-rf", src], check=True)
    subprocess.run(["cp", "-r", os.path.join(ROOT, "game"), src], check=True)
    for change in changes:
        name, old, new = change.split("|")
        path = os.path.join(src, name)
        text = open(path).read()
        if old not in text:
            sys.exit("not in %s: %s" % (name, old))
        open(path, "w").write(text.replace(old, new))
    if not os.environ.get("VSYNC"):
        screen = os.path.join(src, "draw", "screen.tsp")
        text = open(screen).read().replace("(const WAIT_FOR_BLANK bool true)", "(const WAIT_FOR_BLANK bool false)")
        open(screen, "w").write(text)
    disk = os.path.join(BUILD, "measure.dsk")
    listing = subprocess.run([TISPLE, "build", "main.tsp", "--origin", "0x8000", "--disk", disk, "--asm"],
                             cwd=src, capture_output=True, text=True, check=True).stdout
    # the counter is state.ticks; its address from an access to it in the listing
    m = re.search(r"INC \$([0-9A-F]{2,4})  ; state\.ticks\s", listing)
    if not m:
        sys.exit("no INC state.ticks in the listing")
    return disk, int(m.group(1), 16)


def ticks_at(disk, keys, frame, address):
    card = ["--mockingboard", os.environ["MB"]] if os.environ.get("MB") else []
    out = subprocess.run([TISPLE, "machine", "--disk", disk, "--frames", str(frame), "--keys", keys,
                          "--peek", "0x%04X:2" % address] + card, capture_output=True, text=True, check=True).stdout
    m = re.search(r"peek \$[0-9A-F]+: [0-9A-F]{2} [0-9A-F]{2}  \(u16 (\d+)\)", out)
    if not m:
        sys.exit("no peek in: " + out)
    return int(m.group(1))


def main():
    os.makedirs(BUILD, exist_ok=True)
    keys, start, end = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
    disk, address = build(sys.argv[4:])
    a = ticks_at(disk, keys, start, address)
    b = ticks_at(disk, keys, end, address)
    passes = b - a
    cycles = (end - start) * CYCLES_PER_FRAME
    print("frames %d to %d: %d passes, %d cycles a pass (%.2f vblanks)" % (
        start, end, passes, cycles // max(passes, 1), cycles / max(passes, 1) / CYCLES_PER_FRAME))


main()
