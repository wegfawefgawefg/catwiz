#!/usr/bin/env python3
"""Songs written by rules from a seed.

    python3 tools/music/gen/gen.py riff 7                  # tools/music/songs/gen/riff_7.song
    python3 tools/music/gen/gen.py drift 3 --out /tmp/x.song
    python3 tools/music/gen/gen.py riff 7 --motif made     # a hook made by rules, not the motif

Styles: riff (riffology: riffs of the motif stitched over chords in AABA phrases; riffology.py)
and drift (drifting loops of unrelated lengths over a progression, a hook locked to the chords;
drift.py). Every song fits the game's 395 bytes (riff makes a plan plainer until it does) and
is checked against what the player reads (songtext.Song.check). The header says what the seed
chose; the "; hook:" line names the patterns that state the hook, for check.py.
"""

import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import drift       # noqa: E402
import riffology   # noqa: E402

STYLES = {"riff": riffology.make, "drift": drift.make}


def make(style, seed, motif=None):
    return STYLES[style](seed, motif)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("style", choices=sorted(STYLES))
    ap.add_argument("seed", type=int)
    ap.add_argument("--motif", choices=["catwiz", "made"])
    ap.add_argument("--out")
    args = ap.parse_args()
    s = make(args.style, args.seed, args.motif)
    out = args.out or os.path.join(os.path.dirname(HERE), "songs", "gen", s.name + ".song")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    s.write(out)
    print("%-16s %4d bytes  %s" % (s.name, s.bytes(), out))


if __name__ == "__main__":
    sys.exit(main())
