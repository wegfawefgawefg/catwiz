"""The player's two additions for music that follows the fight, made at run time on fresh copies
of Tisple's lib/mockingboard.tsp and lib/mockingboard_player.tsp put beside a program (an
import finds the program's folder before lib/), so Tisple itself is not changed; and what they
cost, measured by building the same small program with and without them.

    python3 tools/music/adaptive/player_patch.py      # the code bytes, both ways to layers

README.md here has what each addition does.
"""

import os
import re
import subprocess
import sys
import tempfile

TISPLE_DIR = os.environ.get("TISPLE_DIR", os.path.expanduser("~/Coding/LangDev/tisple"))
TISPLE = os.path.join(TISPLE_DIR, "build", "tisple")
LIB = os.path.join(TISPLE_DIR, "lib")

PLAYER_EDITS = [
    ("(let stale (array bool 6))",
     """(let stale (array bool 6))

; adaptive (Catwiz tools/music/adaptive): each voice's layer, its own steps down on top of
; hush's (0 as written, 15 silent), a step every 4 ticks toward layer_to; and the order list
; each voice takes at the end of the pattern it plays (0: none)
(let layer (array u8 6))
(let layer_to (array u8 6))
(let layers_moving bool false)
(let layer_clock u8 0)
(let next_order (array (ptr u8) 6))"""),
    ("    (set l (- l (>> hush 2)))",
     "    (set l (- l (+ (>> hush 2) (at layer s))))"),
    ("""    (let o (ptr u8) (at order v))
    (let off u16 (word o))""",
     """    (let o (ptr u8) (at order v))
    (let c (ptr u8) (at next_order v))
    (if (!= (as u16 c) 0)
        (do
            (set o c)
            (set (at next_order v) (as (ptr u8) 0))))
    (let off u16 (word o))"""),
    ("""        (if (and (!= line_count 0) (or cut (not fx_on)))
            (start_effect))""",
     """        (if layers_moving
            (do
                (set layer_clock (+ layer_clock 1))
                (if (= (& layer_clock 3) 0)
                    (do
                        (set layers_moving false)
                        (for v u8 0 VOICES
                            (let l u8 (at layer v))
                            (let t u8 (at layer_to v))
                            (if (!= l t)
                                (do
                                    (if (< l t)
                                        (set l (+ l 1))
                                        (set l (- l 1)))
                                    (set (at layer v) l)
                                    (set (at stale v) true)
                                    (set any_stale true)
                                    (if (!= l t)
                                        (set layers_moving true)))))))))
        (if (and (!= line_count 0) (or cut (not fx_on)))
            (start_effect))"""),
]

MAIN_EDITS = [
    ("""        (set (at player.mix v) 1)
        ; a silent voice goes quiet now; the others with their first note""",
     """        (set (at player.mix v) 1)
        (set (at player.next_order v) (as (ptr u8) 0))
        (set (at player.layer v) (at player.layer_to v))
        ; a silent voice goes quiet now; the others with their first note"""),
    ("""; whether the fade has got where it goes""",
     """; a voice's layer toward to steps down (0 as the song has it, 15 silent), a step every 4
; ticks from the next on (adaptive: tools/music/adaptive in Catwiz)
(fn layer ((v u8) (to u8)) void
    (sei)
    (set (at player.layer_to v) to)
    (set player.layers_moving true)
    (cli))

; each voice takes section k's order list when its pattern ends: the table of six u16 offsets
; at 12 * k in the song playing (the header is section 0; an offset of 0 leaves the voice be)
(fn section ((k u8)) void
    (if (not found)
        (return))
    (sei)
    (let song (ptr u8) player.song)
    (let t (ptr u8) (+ song (* (as u16 k) 12)))
    (for v u8 0 player.VOICES
        (let off u16 (header_word (+ t (<< v 1))))
        (if (!= off 0)
            (set (at player.next_order v) (+ song off))))
    (cli))

; whether the fade has got where it goes"""),
]


# the cheaper way to layers, for cost: no ramp in the tick, mb.layer sets the level at once
# (the game would step it from its own loop, or change a layer only where a cut is fine)
INSTANT_LAYER = """(fn layer ((v u8) (to u8)) void
    (sei)
    (set (at player.layer_to v) to)
    (set (at player.layer v) to)
    (set (at player.stale v) true)
    (set player.any_stale true)
    (cli))"""


def edits_for(instant):
    player = [e for e in PLAYER_EDITS if not (instant and "(set layer_clock" in e[1])]
    main = []
    for old, new in MAIN_EDITS:
        if instant:
            new = re.sub(r"\(fn layer .*?\(cli\)\)", lambda m: INSTANT_LAYER, new, count=1,
                         flags=re.S)
        main.append((old, new))
    return player, main


def patched_lib(work, instant=False):
    player, main = edits_for(instant)
    for name, edits in (("mockingboard_player.tsp", player), ("mockingboard.tsp", main)):
        with open(os.path.join(LIB, name)) as f:
            text = f.read()
        for old, new in edits:
            if text.count(old) != 1:
                raise SystemExit("%s: the text to change is not there once (Tisple changed?):\n%s"
                                 % (name, old))
            text = text.replace(old, new)
        with open(os.path.join(work, name), "w") as f:
            f.write(text)


# ---- what the additions cost: the same programs built with and without them

COST_PROGRAM = """(import mockingboard mb)
(import mockingboard_song tune)
(tune.song music
    (pattern a "l16 v12 k4 d5 a5 r")
    (voice 0 a))
(fn irq () void :interrupt
    (mb.service))
(fn main () void
    (mb.init)
    (mb.play (addr_of (at music 0)))
%s
    (while true))
"""


def build_size(src_text, patched, instant=False):
    with tempfile.TemporaryDirectory() as work:
        if patched:
            patched_lib(work, instant)
        src = os.path.join(work, "p.tsp")
        with open(src, "w") as f:
            f.write(src_text)
        r = subprocess.run([TISPLE, "build", src, "-o", os.path.join(work, "p.bin")],
                           capture_output=True, text=True)
        m = re.search(r"code (\d+), data (\d+)", r.stdout + r.stderr)
        if not m:
            raise SystemExit(r.stdout + r.stderr)
        return int(m.group(1)), int(m.group(2))


def cost():
    rows = [("stock player", "", False, False)]
    for instant in (False, True):
        how = "instant layers" if instant else "layers that ramp"
        rows += [
            ("%s, nothing called" % how, "", True, instant),
            ("%s, calling mb.layer" % how, "    (mb.layer 1 15)", True, instant),
            ("%s, calling mb.section" % how, "    (mb.section 1)", True, instant),
            ("%s, calling both" % how, "    (mb.layer 1 15)\n    (mb.section 1)", True, instant),
        ]
    print("code bytes of a small program playing a song (Tisple's build, 'code N'):")
    base = None
    for label, calls, patched, instant in rows:
        code, data = build_size(COST_PROGRAM % calls, patched, instant)
        if base is None:
            base = code
            print("  %-42s %5d" % (label, code))
        else:
            print("  %-42s %5d  +%d" % (label, code, code - base))
    print("their lets: layer, layer_to, next_order 24 bytes (and 2 more with the ramp)")



if __name__ == "__main__":
    sys.exit(cost())
