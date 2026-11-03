"""The .song text for generated music: notes, patterns from note lists, a song's patterns and
order lists, its byte size (listen.py's song_bytes is the reference: every song is checked
against it), and a check that what the player will play is what was meant.

A pitch is an int, 0 = C1 (the player's note 0), 12 = C2 ... 95 = B8. A part is a list of
Ev: a note (pitch), a rest (None) or a tie, a length in ticks, and the voice settings it wants
(vol, k, m, noise; None: whatever the voice has).
"""

import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
MUSIC = os.path.dirname(HERE)
sys.path.insert(0, MUSIC)
import listen  # noqa: E402
import scene   # noqa: E402

PLAYING = listen.PLAYING  # the game's song buffer, 395 bytes
LOUDEST = 13              # the game fades songs in from 13 steps down: no volume above 13
NAMES = ["c", "c#", "d", "d#", "e", "f", "f#", "g", "g#", "a", "a#", "b"]
TICK_HZ = 1020484 / 17030.0  # the card's tick, 59.92 a second


def note_name(p):
    if not 0 <= p <= 95:
        raise ValueError("pitch %d is off the player's notes (C1-B8)" % p)
    return "%s%d" % (NAMES[p % 12], 1 + p // 12)


def parse_note(name):
    m = re.match(r"^([a-g])(#?)([1-8])$", name)
    return NAMES.index(m.group(1) + m.group(2)) + 12 * (int(m.group(3)) - 1)


def freq(p):
    return 440.0 * 2 ** ((p - 45) / 12.0)


def token_bytes(tok):
    return {"n": 2, "h": 4, "w": 4, "p": 2, "s": 2, "t": 3}.get(tok[0], 1)


def text_bytes(text):
    return sum(token_bytes(t) for t in text.split()) + 1


class Ev:
    __slots__ = ("pitch", "dur", "tie", "vol", "k", "m", "noise")

    def __init__(self, pitch, dur, tie=False, vol=None, k=None, m=None, noise=None):
        self.pitch, self.dur, self.tie = pitch, dur, tie
        self.vol, self.k, self.m, self.noise = vol, k, m, noise

    def __repr__(self):
        what = "-" if self.tie else "r" if self.pitch is None else note_name(self.pitch)
        return "%s:%d" % (what, self.dur)


def rest(d):
    return Ev(None, d)


def ticks(evs):
    return sum(e.dur for e in evs)


def pieces(d):
    """a sound's length in lengths the player has (1-64): equal pieces where they divide it
    (80 is 40 40, so the next note may need no new length), else 64s and the rest"""
    if d <= 64:
        return [d]
    n = -(-d // 64)
    for k in range(n, n + 4):
        if d % k == 0:
            return [d // k] * k
    return [64] * (d // 64) + ([d % 64] if d % 64 else [])


def emit(evs, home=None):
    """a pattern's text. home: the settings the voice has when the pattern starts (and must
    have again at its end: anything changed is put back), as {"vol", "k", "m"}; a key missing
    from home is left as the pattern leaves it. The first length is always written."""
    home = dict(home or {})
    st = dict(home)
    st["l"] = None
    toks = []
    for e in evs:
        if True:  # a rest may carry settings too (an echo's opening rest sets its volume)
            if e.m is not None and st.get("m") != e.m:
                toks.append("m%d" % e.m)
                st["m"] = e.m
            if e.noise is not None and not e.tie:
                toks.append("n%d" % e.noise)
            if e.vol is not None and st.get("vol") != e.vol:
                toks.append("v%d" % e.vol)
                st["vol"] = e.vol
            if e.k is not None and st.get("k") != e.k:
                toks.append("k%d" % e.k)
                st["k"] = e.k
        first = True
        for c in pieces(e.dur):
            if st["l"] != c:
                toks.append("l%d" % c)
                st["l"] = c
            if e.pitch is None and not e.tie:
                toks.append("r")
            elif e.tie or not first:
                toks.append("-")
            else:
                toks.append(note_name(e.pitch))
            first = False
    for key, t in (("vol", "v"), ("k", "k"), ("m", "m")):
        if key in home and st.get(key) != home[key]:
            toks.append("%s%d" % (t, home[key]))
    if not any(t in ("r", "-") or scene.NOTE_RE.match(t) for t in toks):
        toks.append("l1")
        toks.append("r")
    return " ".join(toks)


def tidy(text):
    """drops commands that change nothing (once the pattern itself has set that setting) and
    ones overwritten before the next sound; n and h are kept (other voices share them)"""
    out = []
    known = {}
    pending = {}  # key -> (index in out, the setting before it)
    for tok in text.split():
        if tok in ("r", "-") or scene.NOTE_RE.match(tok):
            out.append(tok)
            pending = {}
            continue
        key = tok[0] if tok[0] in "lvkm" else None
        if key is None:
            out.append(tok)
            continue
        if key in pending:
            idx, prev = pending.pop(key)
            out[idx] = None
            if prev is None:
                known.pop(key, None)
            else:
                known[key] = prev
        if known.get(key) == tok:
            continue
        pending[key] = (len(out), known.get(key))
        out.append(tok)
        known[key] = tok
    return " ".join(t for t in out if t is not None)


class Song:
    """patterns by name (the same text is one pattern), each voice's order list, and the parts
    each pattern was made from (to check the text plays them)"""

    def __init__(self, name):
        self.name = name
        self.pats = {}        # name -> text
        self.evs = {}         # name -> [Ev], what the text was made from
        self.by_text = {}
        self.voices = {}      # v -> [order, loop_at]
        self.notes = []       # header comment lines
        self.hooks = {}       # pattern name -> ticks into it where the hook starts

    def pattern(self, hint, evs, home=None):
        text = " ".join(emit(evs, home).split())
        if text in self.by_text:
            return self.by_text[text]
        name = hint
        i = 2
        while name in self.pats:
            name = "%s%d" % (hint, i)
            i += 1
        self.pats[name] = text
        self.evs[name] = list(evs)
        self.by_text[text] = name
        return name

    def voice(self, v, order, loop_at=0):
        self.voices[v] = [list(order), loop_at]

    def drop_unused(self):
        used = {p for o, _ in self.voices.values() for p in o}
        for n in list(self.pats):
            if n not in used:
                del self.by_text[self.pats[n]]
                del self.pats[n]
                del self.evs[n]

    def merge_runs(self):
        """joins patterns that always play one after the other (a always followed by b, b
        always after a, in every voice, never across a loop): two order bytes and an end
        byte saved each time, and often a length"""
        while True:
            follow, before = {}, {}
            for order, loop_at in self.voices.values():
                n = len(order)
                for i, p in enumerate(order):
                    nxt = order[i + 1] if i + 1 < n and i + 1 != loop_at else None
                    prv = order[i - 1] if i > 0 and i != loop_at else None
                    follow.setdefault(p, set()).add(nxt)
                    before.setdefault(p, set()).add(prv)
            pair = None
            for a, fs in follow.items():
                if len(fs) != 1:
                    continue
                b = next(iter(fs))
                if b is None or b == a or before.get(b) != {a}:
                    continue
                text = tidy(self.pats[a] + " " + self.pats[b])
                if text_bytes(text) > 250:
                    continue
                pair = (a, b, text)
                break
            if not pair:
                return
            a, b, text = pair
            if b in self.hooks:
                self.hooks.setdefault(a, [])
                self.hooks[a] += [ticks(self.evs[a]) + t for t in self.hooks.pop(b)]
            del self.by_text[self.pats[a]]
            del self.by_text[self.pats[b]]
            self.pats[a] = text
            self.evs[a] = self.evs[a] + self.evs[b]
            self.by_text[text] = a
            del self.pats[b]
            del self.evs[b]
            for vo in self.voices.values():
                order, loop_at = vo
                new, nl, i = [], loop_at, 0
                while i < len(order):
                    new.append(order[i])
                    if order[i] == a:
                        if i + 1 < loop_at:
                            nl -= 1
                        i += 2
                    else:
                        i += 1
                vo[0], vo[1] = new, nl

    def body(self):
        lines = []
        for n, t in self.pats.items():
            line = '(pattern %s "%s")' % (n, t)
            if len(line) > 96:
                line = '(pattern %s\n    "%s")' % (n, t)
            lines.append(line)
        for v in sorted(self.voices):
            order, loop_at = self.voices[v]
            words = list(order)
            if loop_at:
                words.insert(loop_at, "loop")
            line = "(voice %d %s)" % (v, " ".join(words))
            while len(line) > 96:
                cut = line.rfind(" ", 0, 96)
                lines.append(line[:cut])
                line = "    " + line[cut + 1:]
            lines.append(line)
        return "\n".join(lines) + "\n"

    def text(self):
        head = [("; " + l) if l else ";" for l in self.notes]
        if self.hooks:
            head.append("; hook: " + " ".join("%s@%d" % (n, t) for n in sorted(self.hooks)
                                              for t in sorted(set(self.hooks[n]))))
        return "\n".join(head) + "\n" + self.body()

    def bytes(self):
        return listen.song_bytes(self.body())

    def my_bytes(self):
        """the size from the format as worked out here, to check listen.py's"""
        size = 12
        for t in self.pats.values():
            size += text_bytes(t)
        for order, _ in self.voices.values():
            size += 2 * len(order) + 4
        return size

    def cycle(self, v):
        """a voice's ticks: its intro (up to the loop) and its loop"""
        order, loop_at = self.voices[v]
        lens = [ticks(self.evs[p]) for p in order]
        return sum(lens[:loop_at]), sum(lens[loop_at:])

    def stream(self, v, upto):
        """the events voice v plays in its first upto ticks, from the order list"""
        order, loop_at = self.voices[v]
        out, t, i = [], 0, 0
        while t < upto:
            for e in self.evs[order[i]]:
                out.append(e)
                t += e.dur
            i += 1
            if i == len(order):
                i = loop_at
        return out

    def check(self, upto=7200):
        """the text plays what the parts meant on every voice: pitches, times, volume and
        decay; listen.py's size agrees with ours; no pattern over 255 bytes"""
        if self.bytes() != self.my_bytes():
            raise SystemExit("%s: listen.py says %d bytes, we say %d" %
                             (self.name, self.bytes(), self.my_bytes()))
        for n, t in self.pats.items():
            if text_bytes(t) > 255:
                raise SystemExit("%s: pattern %s is %d bytes" % (self.name, n, text_bytes(t)))
        body = self.body()
        for v in self.voices:
            got = played(body, v, upto)
            want = meant(self.stream(v, upto), upto)
            for a, b in zip(got, want):
                if a[0] >= upto - 64:
                    break
                same = a[0] == b[0] and a[2] == b[2]
                if same and a[2] is not None:
                    same = (a[3], a[4], a[5]) == (b[3], b[4], b[5])
                if not same:
                    raise SystemExit("%s voice %d: plays %s where %s was meant" %
                                     (self.name, v, a, b))

    def write(self, path):
        with open(path, "w") as f:
            f.write(self.text())


def played(body, v, upto):
    """what the player plays on voice v in the first upto ticks, as scene.py reads the text:
    [(tick, dur, pitch or None, vol, k, m)], ties joined to their notes, rests together"""
    pats, voices = scene.parse_song_body(body)
    order, loop_at = voices[v]
    out = []
    for s in scene.sounds_of(scene.song_voice_stream(pats, order, loop_at), 0, upto):
        if s.kind == "-" and out and out[-1][2] is not None:
            out[-1] = out[-1][:1] + (out[-1][1] + s.dur,) + out[-1][2:]
        elif s.kind == "r" and out and out[-1][2] is None:
            out[-1] = out[-1][:1] + (out[-1][1] + s.dur,) + out[-1][2:]
        else:
            p = parse_note(s.note) if s.kind == "n" else None
            out.append((s.t, s.dur, p, s.vol, s.k, s.m))
    return out


def meant(evs, upto):
    """the same from a voice's events laid end to end, from play's l8 v12 k0 m1"""
    out = []
    t = 0
    st = {"vol": 12, "k": 0, "m": 1}
    for e in evs:
        if t >= upto:
            break
        for key in ("vol", "k", "m"):
            if getattr(e, key) is not None:
                st[key] = getattr(e, key)
        if e.tie and out and out[-1][2] is not None:
            out[-1] = out[-1][:1] + (out[-1][1] + e.dur,) + out[-1][2:]
        elif e.pitch is None and not e.tie:
            if out and out[-1][2] is None:
                out[-1] = out[-1][:1] + (out[-1][1] + e.dur,) + out[-1][2:]
            else:
                out.append((t, e.dur, None, st["vol"], st["k"], st["m"]))
        else:
            out.append((t, e.dur, e.pitch, st["vol"], st["k"], st["m"]))
        t += e.dur
    return out


def power(song, v, upto):
    """voice v's mean power over its first upto ticks, the chip's 3 dB steps (15 is 1.0): for
    balancing the two sides before rendering"""
    total = 0.0
    for t, d, p, vol, k, m in played(song.body(), v, upto):
        if p is None or m == 0:
            continue
        if isinstance(vol, str):
            total += d * 0.5
            continue
        lev = vol
        for i in range(d):
            if k and i and i % k == 0:
                lev -= 1
            if lev <= 0:
                break
            total += 2.0 ** (lev - 15)
    return total / upto


def balance_db(song, upto):
    """left (voices 0-2) over right (3-5), in dB, by power()"""
    import math
    side = [0.0, 0.0]
    for v in song.voices:
        side[0 if v < 3 else 1] += power(song, v, upto)
    if not side[0] or not side[1]:
        return float("inf")
    return 10 * math.log10(side[0] / side[1])


def stream_ticks(text):
    """a pattern's ticks from its text (a pattern that does not start with a length takes the
    voice's; 8 is play's)"""
    n = 0
    l = 8
    for tok in text.split():
        if tok[0] == "l":
            l = int(tok[1:])
        elif tok in ("r", "-") or scene.NOTE_RE.match(tok):
            n += l
    return n
