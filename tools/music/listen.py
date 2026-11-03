#!/usr/bin/env python3
"""Songs as data, heard without the game: each .song file is the body of a tune.song (its
patterns and voices, in lib/mockingboard_song's text), played by Tisple's own Mockingboard
player on the emulated card and saved as audio. What it plays is what the Apple plays, and the
text goes into game/sound/songs.tsp as it is.

    python3 tools/music/listen.py tools/music/songs/*.song           # 60 s each, to renders/
    python3 tools/music/listen.py --seconds 90 --out /tmp/x a.song

It plays with mb.service_bends, so the w p s t commands (vibrato, glide, slide, detune: Tisple's
docs/mockingboard.md) sound; a song without them plays as the game plays it. Each song's size in
bytes is printed: the game plays a song from a buffer of PLAYING bytes
(game/sound/sound.tsp, 395 now), so one bigger than that needs the buffer to grow. Needs an
Apple rom for the card's interrupt (~/.local/share/tisple/roms/Apple2e.rom; never committed).
"""

import argparse
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
TISPLE = os.environ.get("TISPLE", os.path.expanduser("~/Coding/LangDev/tisple/build/tisple"))
ROM = os.path.expanduser("~/.local/share/tisple/roms/Apple2e.rom")
PLAYING = 395

PROGRAM = """(import mockingboard mb)
(import mockingboard_song tune)
(tune.song music
%s)
(fn irq () void :interrupt
    (mb.service_bends))
(fn main () void
    (mb.init)
    (mb.play (addr_of (at music 0)))
    (while true))
"""

def song_bytes(body):
    # the song's size as lib/mockingboard_song lays it out: a 12-byte header; each voice's
    # order list (2 bytes a pattern, then $0000 and the loop's offset); each pattern's tokens
    # (n 2 bytes, h 4, the rest 1) and its end byte
    text = re.sub(r";[^\n]*", "", body)
    size = 12
    for m in re.finditer(r'\(pattern\s+\S+\s+"([^"]*)"\s*\)', text, re.S):
        for tok in m.group(1).split():
            size += {"n": 2, "h": 4, "w": 4, "p": 2, "s": 2, "t": 3}.get(tok[0], 1)
        size += 1
    for m in re.finditer(r"\(voice\s+\d+([^()]*)\)", text):
        names = [w for w in m.group(1).split() if w != "loop"]
        size += 2 * len(names) + 4
    return size


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("songs", nargs="+")
    ap.add_argument("--seconds", type=float, default=60)
    ap.add_argument("--out", default=os.path.join(HERE, "renders"))
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)
    with tempfile.TemporaryDirectory() as work:
        for song in args.songs:
            name = os.path.splitext(os.path.basename(song))[0]
            prog = os.path.join(work, "song.tsp")
            with open(song) as f:
                body = f.read()
            with open(prog, "w") as f:
                f.write(PROGRAM % body)
            size = song_bytes(body)
            wav = os.path.join(work, name + ".wav")
            frames = str(int(args.seconds * 60))
            r = subprocess.run([TISPLE, "run", prog, "--mockingboard", "4", "--rom", ROM,
                                "--frames", frames, "--wav", wav], capture_output=True, text=True)
            if r.returncode != 0 or not os.path.exists(wav):
                raise SystemExit(song + ":\n" + r.stdout + r.stderr)
            ogg = os.path.join(args.out, name + ".ogg")
            subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis",
                            "-q:a", "5", ogg], check=True)
            fits = "fits" if size <= PLAYING else "over the game's %d" % PLAYING
            if re.search(r'"[^"]*(^|\s)[wpst][+-]?\d', body):
                fits += "; uses w p s t: the game plays those only with mb.service_bends, about 950 bytes it lacks"
            print("%-24s %5d bytes (%s)  %s" % (name, size, fits, ogg))


if __name__ == "__main__":
    sys.exit(main())
