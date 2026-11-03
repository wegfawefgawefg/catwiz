#!/usr/bin/env python3
"""Makes, renders and checks a batch of generated songs for the owner to hear.

    python3 tools/music/gen/audition.py --out ~/Coding/GameDev/catwiz/tools/music/renders/gen \
        riff:4 riff:9 drift:1 ...
    python3 tools/music/gen/audition.py --survey riff 1 30     # sizes and choices, no renders

Each piece's .song goes to tools/music/songs/gen/ (or --songs), its 60 s render to --out, and
a notes.txt beside the renders says per piece its seed and the rules it was made by (the
song's header), its size, its hook's recurrence and the render's levels.
"""

import argparse
import contextlib
import io
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import check    # noqa: E402
import gen      # noqa: E402
import songtext as st  # noqa: E402


def survey(style, a, b):
    for seed in range(a, b + 1):
        s = gen.make(style, seed)
        p = s.p
        print("%-6s %3d  %3d bytes  %s" % (style, seed, s.bytes(), s.notes[1][5:90]))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("pieces", nargs="*", help="style:seed or style:seed:made")
    ap.add_argument("--out", default=os.path.join(st.MUSIC, "renders", "gen"))
    ap.add_argument("--songs", default=os.path.join(st.MUSIC, "songs", "gen"))
    ap.add_argument("--seconds", type=float, default=60)
    ap.add_argument("--survey", nargs=3)
    args = ap.parse_args()
    if args.survey:
        survey(args.survey[0], int(args.survey[1]), int(args.survey[2]))
        return 0
    os.makedirs(args.out, exist_ok=True)
    os.makedirs(args.songs, exist_ok=True)
    notes = []
    ok = True
    for piece in args.pieces:
        bits = piece.split(":")
        style, seed = bits[0], int(bits[1])
        motif = bits[2] if len(bits) > 2 else None
        s = gen.make(style, seed, motif)
        path = os.path.join(args.songs, s.name + ".song")
        s.write(path)
        subprocess.run([sys.executable, os.path.join(st.MUSIC, "listen.py"), "--seconds",
                        str(args.seconds), "--out", args.out, path], check=True,
                       capture_output=True)
        ogg = os.path.join(args.out, s.name + ".ogg")
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            ok &= check.song_report(path, args.seconds)
            ok &= check.print_audio(ogg, check.audio_report(ogg))
        report = buf.getvalue()
        print(report, end="")
        hook = [l.strip() for l in report.splitlines() if l.strip().startswith("hook on voice")]
        level = [l for l in report.splitlines() if l.startswith(os.path.basename(ogg)[:20])]
        notes.append("%s.ogg  (%s seed %d%s)\n%s\n  %s\n  %s\n" % (
            s.name, style, seed, ", a made hook" if motif == "made" else "",
            "\n".join("  " + l for l in s.notes[1:6] if l),
            "; ".join(hook), level[0].split(None, 1)[1] if level else ""))
    with open(os.path.join(args.out, "notes.txt"), "w") as f:
        f.write("Generated songs, 60 s each (tools/music/gen; the .song files in "
                "tools/music/songs/gen).\n\n" + "\n".join(notes))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
