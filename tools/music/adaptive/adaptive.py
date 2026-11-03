#!/usr/bin/env python3
"""Music that follows the fight, heard without the game: an adaptive song (.asong) played by
Tisple's Mockingboard player with two small additions, through a scripted fight (.timeline),
rendered to stereo audio.

    python3 tools/music/adaptive/adaptive.py render tools/music/adaptive/elite_fight.timeline
    python3 tools/music/adaptive/adaptive.py render --out DIR a.timeline b.timeline
    python3 tools/music/adaptive/adaptive.py size tools/music/adaptive/battle.asong
    python3 tools/music/adaptive/adaptive.py cost      # what the additions cost, built both ways

The additions (README.md here has them in full; player_patch.py makes them, at run time, on
fresh copies of Tisple's lib/mockingboard.tsp and lib/mockingboard_player.tsp put beside the
program: an import finds the program's folder before lib/), so Tisple itself is not changed:

  layers    each voice's level is its own steps down (0-15) on top of the song's fade;
            (mb.layer v steps) sets where it goes, and the tick moves it a step every 4 ticks
            (about 3 dB, as a fade's), so a part comes in or goes out over up to 1 s; play
            starts each voice at its layer's target (set the first state's, then play)
  sections  (mb.section k): each voice takes section k's order list at its next pattern's
            end. Section k's table is 12 bytes at 12 * k in the song, the header being
            section 0: one u16 a voice, the offset of its new order list, 0 for "go on as
            you are"

The .asong text is a .song (patterns, the voice lines: section 0), then
    (section name (voice v pattern ...) ...)   a section's lists, each looping on itself
    (state name section l0 l1 l2 l3 l4 l5)     what the game would ask for together
Lists the same in two places are one list in the bytes.

A .timeline, one line each (; comments):
    song tools/music/adaptive/battle.asong
    length 90s
    at 0s state calm          ; the state's section (if it changes) and its six layers
    at 20s cue zap 2 1        ; one of the game's effects (game/sound/card_fx.tsp) on a voice
    at 85s fade               ; the music out over 1 s, as a song change does
    at 15s note enemy low     ; words for the timeline's note, nothing played
"""

import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
MUSIC = os.path.dirname(HERE)
REPO = os.path.dirname(os.path.dirname(MUSIC))
sys.path.insert(0, MUSIC)
sys.path.insert(0, HERE)
import scene  # noqa: E402
from player_patch import TISPLE, patched_lib  # noqa: E402

ROM = os.path.expanduser("~/.local/share/tisple/roms/Apple2e.rom")
PLAYING = 395
TICK_HZ = 1020484 / 17030.0

# ---- the bytes (lib/mockingboard_song's format, docs/mockingboard.md)

NOTES = ["c", "c#", "d", "d#", "e", "f", "f#", "g", "g#", "a", "a#", "b"]


def pattern_bytes(text):
    out = []
    for tok in text.split():
        m = scene.NOTE_RE.match(tok)
        if m:
            out.append(NOTES.index(m.group(1) + m.group(2)) + 12 * (int(m.group(3)) - 1))
        elif tok == "r":
            out.append(0x60)
        elif tok == "-":
            out.append(0x61)
        elif tok[0] == "l":
            if not 1 <= int(tok[1:]) <= 64:
                raise SystemExit("%s: a length is 1-64 ticks" % tok)
            out.append(0x7F + int(tok[1:]))
        elif tok[0] == "v":
            out.append(0xC0 + int(tok[1:]))
        elif tok[0] == "k":
            out.append(0xD0 + int(tok[1:]))
        elif tok[0] == "m":
            out.append(0xE0 + int(tok[1:]))
        elif tok[0] == "n":
            out += [0xE4, int(tok[1:])]
        elif tok[0] == "h":
            s, per = tok[1:].split(":")
            out += [0xE5, int(s), int(per) & 0xFF, int(per) >> 8]
        else:
            raise SystemExit("token %r: not in an adaptive song (no w p s t: the game has "
                             "no bends)" % tok)
    out.append(0xFF)
    if len(out) > 255:
        raise SystemExit("a pattern of %d bytes" % len(out))
    return out


def parse_asong(path):
    with open(path) as f:
        text = scene.strip_comments(f.read())
    sections = [("start", None)]
    states = {}
    plain = text
    for m in list(re.finditer(r"\(section\s+(\S+)", text)):
        block = scene.balanced(text, m.start())
        plain = plain.replace(block, "")
        _, voices = scene.parse_song_body(block)
        sections.append((m.group(1), voices))
    for m in re.finditer(r"\(state\s+(\S+)\s+(\S+)((?:\s+\d+){6})\s*\)", plain):
        states[m.group(1)] = (m.group(2), [int(x) for x in m.group(3).split()])
    plain = re.sub(r"\(state[^)]*\)", "", plain)
    pats, voices = scene.parse_song_body(plain)
    sections[0] = ("start", voices)
    return pats, sections, states


def assemble(pats, sections):
    """the song's bytes: section 0's table (the header), the other sections' tables, the
    order lists (each distinct list once), the patterns. Returns (bytes, lists' offsets)"""
    n_tables = len(sections)
    lists = []  # (tuple(order), loop_at)
    for _, voices in sections:
        for v, (order, loop_at) in voices.items():
            key = (tuple(order), loop_at)
            if key not in lists:
                lists.append(key)
    in_lists = {p for order, _ in lists for p in order}
    used = [p for p in pats if p in in_lists]  # in the order written, as tune.song lays them
    at = 12 * n_tables
    list_at = {}
    for key in lists:
        list_at[key] = at
        at += 2 * len(key[0]) + 4
    pat_at = {}
    pat_bytes = {}
    for p in used:
        pat_bytes[p] = pattern_bytes(pats[p])
        pat_at[p] = at
        at += len(pat_bytes[p])
    out = []
    w = lambda x: out.extend([x & 0xFF, x >> 8])  # noqa: E731
    for _, voices in sections:
        for v in range(6):
            if v in voices:
                order, loop_at = voices[v]
                w(list_at[(tuple(order), loop_at)])
            else:
                w(0)
    for key in lists:
        order, loop_at = key
        for p in order:
            w(pat_at[p])
        w(0)
        w(list_at[key] + 2 * loop_at)
    for p in used:
        out += pat_bytes[p]
    assert len(out) == at
    return out


def section_lengths(pats, sections):
    """each section's lists in ticks (a pattern with no length of its own takes the one before
    it in the list), to check they line up"""
    out = []
    for name, voices in sections:
        lens = {}
        for v, (order, loop_at) in voices.items():
            l = 8
            ls = []
            for p in order:
                tick = 0
                for tok in pats[p].split():
                    if tok[0] == "l":
                        l = int(tok[1:])
                    elif tok in ("r", "-") or scene.NOTE_RE.match(tok):
                        tick += l
                ls.append(tick)
            lens[v] = ls
        out.append((name, lens))
    return out


def breakdown(pats, sections):
    """bytes by section: its table, the lists and patterns it brings first"""
    seen_l, seen_p = set(), set()
    rows = []
    for name, voices in sections:
        b = 12
        for v, (order, loop_at) in voices.items():
            key = (tuple(order), loop_at)
            if key not in seen_l:
                seen_l.add(key)
                b += 2 * len(order) + 4
            for p in order:
                if p not in seen_p:
                    seen_p.add(p)
                    b += len(pattern_bytes(pats[p]))
        rows.append((name, b))
    return rows


def size_report(path):
    pats, sections, states = parse_asong(path)
    b = assemble(pats, sections)
    print("%s: %d bytes (%s), %d sections, %d states" % (
        os.path.basename(path), len(b), "fits" if len(b) <= PLAYING else "OVER %d" % PLAYING,
        len(sections), len(states)))
    bd = dict(breakdown(pats, sections))
    for name, lens in section_lengths(pats, sections):
        print("  %-8s %3d bytes  %s" % (name, bd[name], "  ".join(
            "v%d %s" % (v, "+".join(str(x) for x in ls)) for v, ls in sorted(lens.items()))))
    return len(b) <= PLAYING


# ---- a timeline as a program

PROGRAM = """(import mockingboard mb)
(import mockingboard_song tune)
(let music (array u8 %(n)d) (make (array u8 %(n)d) %(bytes)s))
%(effects)s
(const EVENTS u8 %(m)d)
(let when (array u16 %(m)d) (make (array u16 %(m)d) %(when)s))
(let kind (array u8 %(m)d) (make (array u8 %(m)d) %(kind)s))
(let arg (array u8 %(m)d) (make (array u8 %(m)d) %(arg)s))
(let arg2 (array u8 %(m)d) (make (array u8 %(m)d) %(arg2)s))
(let sound (array (ptr u8) %(m)d) (make (array (ptr u8) %(m)d) %(sound)s))
(let ticks u16 0)
(fn irq () void :interrupt
    (mb.service)
    (set ticks (+ ticks 1)))
(fn main () void
    (mb.init)
    (let i u8 0)
    ; the first state's layers before play, which starts each voice at its layer's target
    (while (and (< i EVENTS) (and (= (at when i) 0) (= (at kind i) 1)))
        (mb.layer (at arg i) (at arg2 i))
        (set i (+ i 1)))
    (sei)
    (set ticks 0)
    (mb.play (addr_of (at music 0)))
    (while (< i EVENTS)
        (sei)
        (let now u16 ticks)
        (cli)
        (if (>= now (at when i))
            (do
                (let k u8 (at kind i))
                (if (= k 0)
                    (mb.section (at arg i)))
                (if (= k 1)
                    (mb.layer (at arg i) (at arg2 i)))
                (if (= k 2)
                    (mb.effect (at sound i) (at arg i) (at arg2 i)))
                (if (= k 3)
                    (mb.fade 15))
                (set i (+ i 1)))))
    (while true))
"""


def parse_timeline(path):
    tl = {"song": None, "length": 5400, "events": [], "notes": []}
    last = 0
    with open(path) as f:
        for line in f:
            raw = line.rstrip("\n")
            line = raw.split(";")[0].strip()
            if not line:
                continue
            w = line.split()
            if w[0] == "song":
                tl["song"] = os.path.join(REPO, w[1])
            elif w[0] == "length":
                tl["length"] = scene.resolve(w[1], 0, 0)
            elif w[0] == "at":
                last = scene.resolve(w[1], 0, last)
                tl["events"].append((last, w[2:]))
            else:
                raise SystemExit("%s: what is %r" % (path, raw))
    return tl


def timeline_program(tl):
    pats, sections, states = parse_asong(tl["song"])
    names = [n for n, _ in sections]
    body = assemble(pats, sections)
    fx = scene.load_effects("game/sound/card_fx.tsp")
    ev = []  # (tick, kind, arg, arg2, sound)
    used_fx = []
    current = "main"
    notes = []
    for t, w in tl["events"]:
        if w[0] == "state":
            sec, layers = states[w[1]]
            if sec != current:
                ev.append((t, 0, names.index(sec), 0, None))
                current = sec
            for v, l in enumerate(layers):
                ev.append((t, 1, v, l, None))
            notes.append((t, "state " + w[1] + " (" + sec + ")"))
        elif w[0] == "section":
            ev.append((t, 0, names.index(w[1]), 0, None))
            current = w[1]
        elif w[0] == "layer":
            ev.append((t, 1, int(w[1]), int(w[2]), None))
        elif w[0] == "cue":
            if w[1] not in fx:
                raise SystemExit("no effect " + w[1])
            if w[1] not in used_fx:
                used_fx.append(w[1])
            ev.append((t, 2, int(w[2]), int(w[3]) if len(w) > 3 else 1, w[1]))
        elif w[0] == "fade":
            ev.append((t, 3, 0, 0, None))
            notes.append((t, "fade out"))
        elif w[0] == "note":
            notes.append((t, " ".join(w[1:])))
        else:
            raise SystemExit("at: state, section, layer, cue, fade or note, not " + w[0])
    ev.sort(key=lambda e: e[0])
    m = max(1, len(ev))
    join = lambda xs, z: " ".join(xs) if xs else z  # noqa: E731
    prog = PROGRAM % {
        "n": len(body), "bytes": " ".join(str(b) for b in body),
        "effects": "\n".join('(tune.effect fx_%s "%s")' % (n, fx[n]) for n in used_fx),
        "m": m,
        "when": join([str(e[0]) for e in ev], "0"),
        "kind": join([str(e[1]) for e in ev], "9"),
        "arg": join([str(e[2]) for e in ev], "0"),
        "arg2": join([str(e[3]) for e in ev], "0"),
        "sound": join(["(addr_of (at fx_%s 0))" % e[4] if e[4] else "(as (ptr u8) 0)" for e in ev],
                      "(as (ptr u8) 0)"),
    }
    return prog, len(body), notes


def render(path, out=None):
    tl = parse_timeline(path)
    prog, size, notes = timeline_program(tl)
    name = os.path.splitext(os.path.basename(path))[0]
    out = out or os.path.join(MUSIC, "renders", "adaptive", name + ".ogg")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with tempfile.TemporaryDirectory() as work:
        patched_lib(work)
        src = os.path.join(work, "fight.tsp")
        with open(src, "w") as f:
            f.write(prog)
        wav = os.path.join(work, "fight.wav")
        r = subprocess.run([TISPLE, "run", src, "--mockingboard", "4", "--rom", ROM,
                            "--frames", str(tl["length"]), "--wav", wav],
                           capture_output=True, text=True)
        if r.returncode != 0 or not os.path.exists(wav):
            raise SystemExit(src + ":\n" + r.stdout + r.stderr)
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis",
                        "-q:a", "5", out], check=True)
    print("%-20s song %d bytes, %.0f s  %s" % (name, size, tl["length"] / 60.0, out))
    for t, what in notes:
        print("   %d:%02d  %s" % (t // 3600, (t // 60) % 60, what))
    return out


def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    what = sys.argv[1]
    if what == "render":
        args = sys.argv[2:]
        out_dir = None
        if "--out" in args:
            i = args.index("--out")
            out_dir = args[i + 1]
            del args[i:i + 2]
        for p in args:
            name = os.path.splitext(os.path.basename(p))[0]
            render(p, os.path.join(out_dir, name + ".ogg") if out_dir else None)
    elif what == "size":
        ok = all([size_report(p) for p in sys.argv[2:]])
        return 0 if ok else 1
    elif what == "cost":
        import player_patch
        player_patch.cost()
    else:
        raise SystemExit(__doc__)
    return 0


if __name__ == "__main__":
    sys.exit(main())
