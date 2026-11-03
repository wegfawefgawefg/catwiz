#!/usr/bin/env python3
"""A timed scene heard without the game: a song (or none) with sound effects at given ticks,
played by Tisple's own Mockingboard player on the emulated card, saved as stereo audio.

    python3 tools/music/scene.py tools/music/sfx/scene_middle.scene
    python3 tools/music/scene.py --out /tmp/x.ogg --hard a.scene

Two kinds of effect:

  cue   one of the game's effects (a tune.effect in game/sound/card_fx.tsp, or a .fx file's
        one-lane effect) started with mb.effect on a voice with a priority, from the scene's
        program at that tick: exactly as the game plays it today, one at a time, in line.
  rich  an effect of several lanes at once (a .fx file's (rich ...)), or a song's opening (a
        stinger). The player plays one effect at a time, so these are laid into the song
        itself: the scene is written out as one long song, a "tape", each voice's patterns
        the music where no effect holds the voice and the effect's lanes where one does.
        The music on a voice an effect takes goes on silently and comes back mid-note at
        the level it has faded to, as the player's own lent voices do.

A scene file, one line each (; to the end of a line is a comment):

    song tools/music/songs/b_nightgarden.song   ; a .song file, or game/sound/songs.tsp:BATTLE
    length 60s                                  ; or ticks: length 3600
    effects game/sound/card_fx.tsp              ; where cues are found (tune.effect lines)
    rich tools/music/sfx/rich.fx                ; where rich effects are found
    lanes L1=2 L2=1 L3=0 R1=5 R2=4 R3=3         ; a rich effect's lane names to voices
    at 1s rich roll                             ; a rich effect at 1 s
    at +40 cue zap 2 1                          ; a cue 40 ticks after the line before
    at +40 rich zap 3                           ; a rich effect, priority 3 (default 1)
    at 10s tune game/sound/songs.tsp:WON        ; a song's opening (up to its loop), as lanes

A rich lane holds its voice from its first sound (a lane starting with a rest leaves the music
on it playing until then). One that comes while another holds the voice cuts it off if its priority is as high
or higher, and is left out otherwise. Times are ticks (1/60 s) or seconds with an s.

The two chips are rendered apart (the left chip's voices, then the right's: their noise and
envelope are their own, so nothing between them is lost) and joined as stereo, with a little
of each side in the other as two speakers in a room give (--hard for none).
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
DEFAULT_LANES = {"L1": 2, "L2": 1, "L3": 0, "R1": 5, "R2": 4, "R3": 3}
CHUNK = 240  # a tape pattern's bytes at most (the player reads 255)

# ---- the text format (lib/mockingboard_song.tsp)

NOTE_RE = re.compile(r"^([a-g])(#?)([1-8])$")


def token_bytes(tok):
    return {"n": 2, "h": 4}.get(tok[0], 1)


def effect_bytes(text):
    return sum(token_bytes(t) for t in text.split()) + 1


def strip_comments(text):
    # ; to the end of a line, outside strings
    out = []
    for line in text.split("\n"):
        q = False
        for i, c in enumerate(line):
            if c == '"':
                q = not q
            elif c == ";" and not q:
                line = line[:i]
                break
        out.append(line)
    return "\n".join(out)


def parse_song_body(body):
    """patterns {name: text}, voices {v: (order, loop_at)}"""
    body = strip_comments(body)
    patterns = {}
    for m in re.finditer(r'\(pattern\s+(\S+)\s+"([^"]*)"\s*\)', body, re.S):
        patterns[m.group(1)] = " ".join(m.group(2).split())
    voices = {}
    for m in re.finditer(r"\(voice\s+(\d+)([^()]*)\)", body):
        words = m.group(2).split()
        loop_at = 0
        order = []
        for w in words:
            if w == "loop":
                loop_at = len(order)
            else:
                order.append(w)
        voices[int(m.group(1))] = (order, loop_at)
    return patterns, voices


def balanced(text, start):
    depth = 0
    q = False
    for i in range(start, len(text)):
        c = text[i]
        if c == '"':
            q = not q
        elif not q and c == "(":
            depth += 1
        elif not q and c == ")":
            depth -= 1
            if depth == 0:
                return text[start:i + 1]
    raise SystemExit("unbalanced parens at %d" % start)


def load_song(ref):
    """a .song file's body, or file.tsp:NAME for a (tune.song NAME ...) in a source file"""
    path, _, name = ref.partition(":")
    with open(os.path.join(REPO, path) if not os.path.isabs(path) else path) as f:
        text = f.read()
    if not name:
        return parse_song_body(text)
    text = strip_comments(text)
    m = re.search(r"\(tune\.song\s+" + re.escape(name) + r"\s", text)
    if not m:
        raise SystemExit("no (tune.song %s ...) in %s" % (name, path))
    return parse_song_body(balanced(text, m.start()))


def load_effects(path):
    with open(os.path.join(REPO, path)) as f:
        text = strip_comments(f.read())
    return {m.group(1): " ".join(m.group(2).split())
            for m in re.finditer(r'\(tune\.effect\s+(\S+)\s+"([^"]*)"', text, re.S)}


def load_rich(path):
    """(rich name "what it is" (lane L1 "text") ...) and (cue name "text"), as
    {name: {"what": str, "lanes": [(lane, text)]}}"""
    with open(os.path.join(REPO, path)) as f:
        text = strip_comments(f.read())
    rich = {}
    for m in re.finditer(r"\((rich|cue)\s+(\S+)", text):
        block = balanced(text, m.start())
        what = re.match(r'\((?:rich|cue)\s+\S+\s+"([^"]*)"', block, re.S)
        lanes = [(l.group(1), " ".join(l.group(2).split()))
                 for l in re.finditer(r'\(lane\s+(\S+)\s+"([^"]*)"\s*\)', block, re.S)]
        if m.group(1) == "cue":
            lanes = [("cue", " ".join(re.findall(r'"([^"]*)"', block)[-1].split()))]
        rich[m.group(2)] = {"what": what.group(1) if what else "", "lanes": lanes,
                            "kind": m.group(1)}
    return rich


# ---- a voice as the player plays it: each sound with the state it plays in

class Sound:
    __slots__ = ("t", "dur", "kind", "note", "vol", "k", "m", "n", "n_set", "h_set")

    def __init__(self, **kw):
        for k, v in kw.items():
            setattr(self, k, v)

    def end(self):
        return self.t + self.dur


def sounds_of(patterns_iter, t0, t_end, state=None):
    """the sounds of a stream of pattern texts from tick t0, until t_end. state: the voice's
    l vol k m (vol an int, or "hS:P" for the hardware envelope)"""
    st = dict(state or {"l": 8, "vol": 12, "k": 0, "m": 1})
    n = None
    out = []
    t = t0
    n_set = h_set = False
    for text in patterns_iter:
        for tok in text.split():
            c = tok[0]
            if tok in ("r", "-") or NOTE_RE.match(tok):
                kind = "r" if tok == "r" else "-" if tok == "-" else "n"
                out.append(Sound(t=t, dur=st["l"], kind=kind, note=tok if kind == "n" else None,
                                 vol=st["vol"], k=st["k"], m=st["m"], n=n, n_set=n_set,
                                 h_set=h_set))
                n_set = h_set = False
                t += st["l"]
                if t >= t_end:
                    return out
            elif c == "l":
                st["l"] = int(tok[1:])
            elif c == "v":
                st["vol"] = int(tok[1:])
            elif c == "k":
                st["k"] = int(tok[1:])
            elif c == "m":
                st["m"] = int(tok[1:])
            elif c == "n":
                n = int(tok[1:])
                n_set = True
            elif c == "h":
                st["vol"] = tok
                h_set = True
            else:
                raise SystemExit("unknown token " + tok)
    return out


def song_voice_stream(patterns, order, loop_at):
    i = 0
    while True:
        yield patterns[order[i]]
        i += 1
        if i == len(order):
            i = loop_at


def stream_length(texts, state=None):
    s = sounds_of(iter(texts), 0, 10 ** 9, state)
    return s[-1].end() if s else 0


# ---- the tape: each voice's segments, music and effects, as the player's text

FX_START = {"l": 1, "vol": 15, "k": 0, "m": 1}


def level_at(attack, t):
    """the level a note attacked as attack has faded to at tick t"""
    if isinstance(attack.vol, str):
        return attack.vol
    if attack.k == 0:
        return attack.vol
    return max(0, attack.vol - (t - attack.t) // attack.k)


def slice_sounds(sounds, a, b):
    """the sounds that play in [a, b), as (sound, dur, reattack_vol) with the first re-attacked
    when it began before a (or is a tie at a)"""
    out = []
    attack = None
    for s in sounds:
        if s.kind == "n":
            attack = s
        elif s.kind == "r":
            attack = None
        if s.end() <= a:
            continue
        if s.t >= b:
            break
        start = max(s.t, a)
        dur = min(s.end(), b) - start
        if start > s.t or (s.kind == "-" and not out):
            if attack is None or s.kind == "r":
                out.append((s, dur, "rest"))
            else:
                out.append((s, dur, ("re", attack, level_at(attack, start))))
        else:
            out.append((s, dur, None))
    return out


class Emitter:
    """a voice's text from its segments, with as few commands as the player needs"""

    def __init__(self):
        self.toks = []
        self.t = 0
        self.cur = {}

    def rest_until(self, t):
        while self.t < t:
            d = min(64, t - self.t)
            self.length(d)
            self.toks.append("r")
            self.t += d

    def length(self, d):
        if self.cur.get("l") != d:
            self.toks.append("l%d" % d)
            self.cur["l"] = d

    def cmd(self, key, value, force=False):
        if force or self.cur.get(key) != value:
            if key == "vol":
                self.toks.append(value if isinstance(value, str) else "v%d" % value)
            else:
                self.toks.append("%s%d" % (key, value))
            self.cur[key] = value

    def segment(self, items):
        """items from slice_sounds; a segment starts with the voice's whole state"""
        first = True
        for s, dur, how in items:
            if how == "rest":
                kind, note = "r", None
            elif how is not None:
                kind, note = "n", how[1].note
            else:
                kind, note = s.kind, s.note
            if kind != "r":
                if first and s.n is not None:
                    self.toks.append("n%d" % s.n)
                elif s.n_set:
                    self.toks.append("n%d" % s.n)
                if how is not None and how != "rest":
                    lev = how[2]
                    self.cmd("vol", lev, force=first or isinstance(lev, str))
                else:
                    self.cmd("vol", s.vol, force=first or (s.h_set and isinstance(s.vol, str)))
                self.cmd("k", s.k, force=first)
                self.cmd("m", s.m, force=first)
                first = False
            elif s.n_set and s.n is not None:
                self.toks.append("n%d" % s.n)
            # the sound, in pieces of at most 64 ticks
            while dur > 0:
                d = min(64, dur)
                self.length(d)
                self.toks.append(kind if kind != "n" else note)
                if kind == "n":
                    kind = "-"
                dur -= d
                self.t += d

    def patterns(self):
        """the text cut into patterns of at most CHUNK bytes, each ending on a sound"""
        out, cur, size = [], [], 0
        for tok in self.toks:
            cur.append(tok)
            size += token_bytes(tok)
            if size >= CHUNK - 8 and (tok in ("r", "-") or NOTE_RE.match(tok)):
                out.append(" ".join(cur))
                cur, size = [], 0
        if cur:
            if not any(t in ("r", "-") or NOTE_RE.match(t) for t in cur):
                cur.append("r")
            out.append(" ".join(cur))
        return out


def resolve(at, base, last):
    at = at.strip()
    rel = at.startswith("+")
    if rel:
        at = at[1:]
    t = round(float(at[:-1]) * 60) if at.endswith("s") else int(at)
    return (last + t) if rel else t


def parse_scene(path):
    sc = {"song": None, "length": 3600, "effects": {}, "rich": {}, "lanes": dict(DEFAULT_LANES),
          "cues": [], "claims": []}
    last = 0
    raw = []
    with open(path) as f:
        for line in f:
            line = line.split(";")[0].strip()
            if not line:
                continue
            w = line.split()
            if w[0] == "song":
                sc["song"] = load_song(w[1])
            elif w[0] == "length":
                sc["length"] = resolve(w[1], 0, 0)
            elif w[0] == "effects":
                sc["effects"].update(load_effects(w[1]))
            elif w[0] == "rich":
                sc["rich"].update(load_rich(w[1]))
            elif w[0] == "lanes":
                for kv in w[1:]:
                    k, v = kv.split("=")
                    sc["lanes"][k] = int(v)
            elif w[0] == "at":
                last = resolve(w[1], 0, last)
                raw.append((last, w[2:]))
            else:
                raise SystemExit("%s: what is %r" % (path, line))
    for t, w in raw:
        if w[0] == "cue":
            name, voice = w[1], int(w[2])
            prio = int(w[3]) if len(w) > 3 else 1
            text = sc["effects"].get(name)
            if text is None and name in sc["rich"] and sc["rich"][name]["kind"] == "cue":
                text = sc["rich"][name]["lanes"][0][1]
            if text is None:
                raise SystemExit("no effect " + name)
            sc["cues"].append((t, name, text, voice, prio))
        elif w[0] == "rich":
            name = w[1]
            prio = int(w[2]) if len(w) > 2 else 1
            if name not in sc["rich"]:
                raise SystemExit("no rich effect " + name)
            for lane, text in sc["rich"][name]["lanes"]:
                v = sc["lanes"][lane] if lane in sc["lanes"] else int(lane)
                sc["claims"].append((t, v, [text], prio, FX_START))
        elif w[0] == "tune":
            pats, voices = load_song(w[1])
            prio = int(w[2]) if len(w) > 2 else 2
            for v, (order, loop_at) in voices.items():
                intro = order[:loop_at] if loop_at else order
                sc["claims"].append((t, v, [pats[p] for p in intro], prio, None))
        else:
            raise SystemExit("at: cue, rich or tune, not " + w[0])
    return sc


def tape(sc):
    """each voice's pattern texts for the whole scene"""
    L = sc["length"]
    music = {}
    if sc["song"]:
        pats, voices = sc["song"]
        for v, (order, loop_at) in voices.items():
            music[v] = sounds_of(song_voice_stream(pats, order, loop_at), 0, L)
    out = {}
    for v in range(6):
        # the effect windows on this voice, in time: a later one cuts the one before if its
        # priority is as high, and is left out otherwise
        wins = []
        for t, cv, texts, prio, state in sorted((c for c in sc["claims"] if c[1] == v),
                                                key=lambda c: c[0]):
            snd = sounds_of(iter(texts), t, L, state)
            # a lane that starts with a rest takes its voice only from its first sound (the
            # music plays on until then)
            while snd and snd[0].kind == "r":
                snd.pop(0)
            if not snd:
                continue
            t = snd[0].t
            end = snd[-1].end()
            if wins and wins[-1][1] > t:
                if prio >= wins[-1][2]:
                    wins[-1][1] = t
                else:
                    continue
            wins.append([t, end, prio, snd])
        if v not in music and not wins:
            continue
        em = Emitter()
        cursor = 0
        bed = music.get(v, [])
        for a, b, _, snd in wins:
            if a > cursor:
                if bed:
                    em.segment(slice_sounds(bed, cursor, a))
                em.rest_until(a)
            em.segment(slice_sounds(snd, a, b))
            em.rest_until(b)
            cursor = b
        if bed and cursor < L:
            em.segment(slice_sounds(bed, cursor, L))
        em.rest_until(L)
        out[v] = em.patterns()
    return out


# ---- the program

PROGRAM = """(import mockingboard mb)
(import mockingboard_song tune)
(tune.song music
%(song)s)
%(effects)s
(const CUES u8 %(n)d)
(let when (array u16 %(m)d) (make (array u16 %(m)d) %(when)s))
(let which (array (ptr u8) %(m)d) (make (array (ptr u8) %(m)d) %(which)s))
(let on_voice (array u8 %(m)d) (make (array u8 %(m)d) %(voice)s))
(let rank (array u8 %(m)d) (make (array u8 %(m)d) %(prio)s))
(let ticks u16 0)
(fn irq () void :interrupt
    (mb.service)
    (set ticks (+ ticks 1)))
(fn main () void
    (mb.init)
    (sei)
    (set ticks 0)
    (mb.play (addr_of (at music 0)))
    (let i u8 0)
    (while (< i CUES)
        (sei)
        (let now u16 ticks)
        (cli)
        (if (>= now (at when i))
            (do
                (mb.effect (at which i) (at on_voice i) (at rank i))
                (set i (+ i 1)))))
    (while true))
"""


def song_text(voice_patterns, only):
    lines = ['(pattern quiet "l64 r")']
    names = {}
    voices = []
    for v in sorted(voice_patterns):
        if v not in only:
            continue
        order = []
        for text in voice_patterns[v]:
            if text not in names:
                names[text] = "p%d" % len(names)
                lines.append('(pattern %s "%s")' % (names[text], text))
            order.append(names[text])
        voices.append("(voice %d %s loop quiet)" % (v, " ".join(order)))
    if not voices:
        voices.append("(voice %d quiet)" % min(only))
    return "\n".join(lines + voices)


def plain_song_text(song, only):
    pats, voices = song
    used = set()
    vl = []
    for v, (order, loop_at) in sorted(voices.items()):
        if v not in only:
            continue
        used.update(order)
        words = list(order)
        if loop_at:
            words.insert(loop_at, "loop")
        vl.append("(voice %d %s)" % (v, " ".join(words)))
    pl = ['(pattern %s "%s")' % (n, t) for n, t in pats.items() if n in used]
    if not vl:
        pl.append('(pattern quiet "l64 r")')
        vl.append("(voice %d quiet)" % min(only))
    return "\n".join(pl + vl)


def render_chip(sc, only, work, tag, use_tape):
    if use_tape:
        song = song_text(sc["tape"], only)
    elif sc["song"]:
        song = plain_song_text(sc["song"], only)
    else:
        song = song_text({}, only)
    cues = [c for c in sc["cues"] if c[3] in only]
    texts = {}
    for _, name, text, _, _ in cues:
        texts.setdefault(name, text)
    effects = "\n".join('(tune.effect fx_%s "%s")' % (n, t) for n, t in texts.items())
    m = max(1, len(cues))
    pad = lambda xs, z: " ".join(xs) if xs else z
    prog = PROGRAM % {
        "song": song, "effects": effects, "n": len(cues), "m": m,
        "when": pad([str(c[0]) for c in cues], "0"),
        "which": pad(["(addr_of (at fx_%s 0))" % c[1] for c in cues], "(as (ptr u8) 0)"),
        "voice": pad([str(c[3]) for c in cues], "0"),
        "prio": pad([str(c[4]) for c in cues], "0"),
    }
    src = os.path.join(work, tag + ".tsp")
    with open(src, "w") as f:
        f.write(prog)
    wav = os.path.join(work, tag + ".wav")
    r = subprocess.run([TISPLE, "run", src, "--mockingboard", "4", "--rom", ROM,
                        "--frames", str(sc["length"] + 30), "--wav", wav],
                       capture_output=True, text=True)
    if r.returncode != 0 or not os.path.exists(wav):
        raise SystemExit("%s:\n%s%s" % (src, r.stdout, r.stderr))
    return wav


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("scene")
    ap.add_argument("--out")
    ap.add_argument("--hard", action="store_true", help="no bleed between the sides")
    ap.add_argument("--keep", help="a folder to keep the programs and wavs in")
    ap.add_argument("--tape", action="store_true", help="lay the song out as a tape even with "
                    "no rich effects (to check the tape against the song)")
    args = ap.parse_args()
    sc = parse_scene(args.scene)
    use_tape = bool(sc["claims"]) or args.tape
    if use_tape:
        sc["tape"] = tape(sc)
        size = 12 + 4 + sum(2 * len(p) + 4 + sum(effect_bytes(t) for t in p)
                            for p in sc["tape"].values())
        print("tape: %d bytes over %d voices" % (size, len(sc["tape"])))
    name = os.path.splitext(os.path.basename(args.scene))[0]
    out = args.out or os.path.join(HERE, "renders", "sfx", name + ".ogg")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    work_ctx = tempfile.TemporaryDirectory() if not args.keep else None
    work = args.keep or work_ctx.name
    os.makedirs(work, exist_ok=True)
    left = render_chip(sc, {0, 1, 2}, work, name + "_left", use_tape)
    right = render_chip(sc, {3, 4, 5}, work, name + "_right", use_tape)
    bleed = 0.0 if args.hard else 0.3
    pan = "pan=stereo|c0=c0+%g*c1|c1=c1+%g*c0" % (bleed, bleed)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", left, "-i", right,
                    "-filter_complex", "[0][1]amerge=inputs=2," + pan,
                    "-c:a", "libvorbis", "-q:a", "6", out], check=True)
    if args.keep:
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", left, "-i", right,
                        "-filter_complex", "[0][1]amerge=inputs=2," + pan,
                        os.path.join(work, name + ".wav")], check=True)
    print("%-24s %5.1f s  %s" % (name, sc["length"] / 60.0, out))


if __name__ == "__main__":
    sys.exit(main())
