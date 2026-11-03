"""Drifting loops, night garden's trick (tools/music/songs/b_nightgarden.song): a slow
progression on the bass and a pad, and over it parts whose loops are of unrelated lengths, so
they land somewhere new each time round and the whole repeats only after hours.

  the bed     bass and pad on the progression (each chord a bar or two), the pad a pulse
              behind the bass, every note left to ring out
  the hook    the lead, locked to the progression so it always sits on the same chords:
              the motif (or a hook made in its manner) on the first two chords, a rest, the
              hook again and an answer; its loop is two times round the chords
  the drift   a bell playing short phrases with long gaps, only notes that sit on every chord
              (no minor ninth over any chord tone), its loop a length in pulses that shares
              no factor with the progression's; its echo, later and softer; crickets or drops
              on a loop of their own (a prime number of ticks)

The drifting parts are sparse, as seasoning: no ostinato phasing against another.
"""

import math
import random

import songtext as st
import theory as th
from songtext import Ev, rest

PROGS = {
    "lydian": [[(0, ""), (1, ""), (5, "m"), (4, "")], [(0, "maj7"), (1, ""), (0, "maj7"), (5, "m")],
               [(0, ""), (1, ""), (4, ""), (5, "m")]],
    "dorian": [[(0, "m"), (3, ""), (0, "m"), (6, "")], [(0, "m7"), (2, ""), (3, ""), (0, "m")]],
    "major": [[(0, "maj7"), (5, "m"), (3, "maj7"), (4, "")], [(0, ""), (3, ""), (1, "m"), (4, "sus4")]],
    "minor": [[(0, "m"), (5, ""), (2, ""), (6, "")], [(0, "m"), (3, "m"), (5, ""), (6, "")]],
}


def plan(seed, motif=None):
    rng = random.Random(seed)
    p = {"seed": seed}
    p["mode"] = rng.choice(["lydian", "lydian", "dorian", "major", "minor"])
    p["key"] = rng.randrange(12)
    p["eighth"] = rng.choice([16, 18, 20, 22])
    p["prog"] = rng.choice(PROGS[p["mode"]])
    p["prog2"] = rng.choice(th.PROGRESSIONS[p["mode"]]["B"])
    p["chord_bars"] = rng.choice([1, 2, 2])
    p["motif"] = motif or rng.choice(["catwiz", "catwiz", "made"])
    if p["motif"] == "made":
        p["call"], p["tail"] = th.make_hook(rng)
    else:
        p["call"] = th.CALLS[rng.choice(["motif", "motif", "motif_late", "motif_up3"])]
        p["tail"] = th.ANSWERS["tail"][:2] + [(th.R, 4)]
    p["answer"] = rng.choice(["run", "twitch_echo", "arp", "reply"])
    p["texture"] = rng.choice(["crickets", "drops", "crickets"])
    p["bell_phrases"] = rng.choice([2, 3, 3])
    p["bell_seed"] = rng.randrange(1 << 30)
    p["echo_delay"] = rng.choice([30, 40, 45])
    p["lead_k"] = rng.choice([4, 5, 6])
    return p


def safe_tones(p, chords):
    """the scale's pitch classes that are no minor ninth over a tone of any chord"""
    sc = [(p["key"] + i) % 12 for i in th.SCALES[p["mode"]]]
    out = []
    for pc in sc:
        if all((pc - t) % 12 != 1 for ch in chords for t in ch[1]):
            out.append(pc)
    return out


def coprime_length(rng, base, lo, hi, avoid):
    """a length in pulses in lo..hi sharing no factor with any of avoid"""
    cands = [n for n in range(lo, hi + 1) if all(math.gcd(n, a) == 1 for a in avoid)]
    return rng.choice(cands)


def build(seed, motif=None, mix=None, long=True):
    """long: eight chords (the progression, then a contrasting four), the hook on the 1st and
    5th; else four, the hook twice round them"""
    p = plan(seed, motif)
    p["long"] = long
    mix = dict(mix or {"bass": 12, "pad": 10, "lead": 12, "bell": 10, "echo": 5, "tex": 8})
    p["mix"] = mix
    rng = random.Random(p["bell_seed"])
    s = st.Song("drift_%d" % seed)
    e = p["eighth"]
    cb = p["chord_bars"]
    chord_ticks = 8 * e * cb
    prog = p["prog"] + (p["prog2"] if long else [])
    chords = [th.chord(p["key"], p["mode"], d, q) for d, q in prog]
    P = len(chords) * chord_ticks           # the progression, in ticks
    pulses = P // e                          # and in pulses

    # the bed: bass (root, then the fifth halfway), the pad a pulse behind, each note left to
    # ring (k15: 150 ticks from v10 to silence); a chord longer than that strikes each twice
    bass, pad = [], []
    for ch in chords:
        root = th.nearest(ch[0], 12, "~", 7, 18)
        fifth = root + 7
        lo_t = th.nearest(ch[1][1], 34, "~", 30, 42)
        hi_t = th.nearest(th.tone_pc(ch, 3) if len(ch[1]) > 3 else ch[1][2], lo_t, "+", 30, 47)
        strikes = 2 if chord_ticks // 2 <= 120 else 4
        d = chord_ticks // strikes
        bs = [Ev([root, fifth][i % 2], d, vol=mix["bass"], k=15) for i in range(strikes)]
        pd = [Ev([lo_t, hi_t][i % 2], d, vol=mix["pad"], k=15) for i in range(strikes)]
        bass.append(s.pattern("bs_%s" % th.KEYS[ch[0]].replace("#", "s"), bs))
        pad.append(s.pattern("pd_%s" % th.KEYS[ch[0]].replace("#", "s"), pd))
    s.voice(0, bass)
    s.voice(1, [s.pattern("in_pad", [rest(e)])] + pad, 1)

    # the hook, locked to the chords: hook on 1-2, rest on 3-4, hook, answer on 3-4
    t0 = 36 + p["key"]
    if t0 < 43:
        t0 += 12
    lo, hi = t0 - 7, t0 + 14

    def phrase(riffs, chs, name, hook=False):
        evs, prev = [], t0
        for riff, ch in zip(riffs, chs):
            notes = th.realise(riff, ch, prev, p["key"], p["mode"], lo, hi, e)
            for q, n in notes:
                if isinstance(q, int):
                    prev = q
                    evs.append(Ev(q, n, vol=mix["lead"], k=p["lead_k"]))
                elif q == "t":
                    evs.append(Ev(None, n, tie=True))
                else:
                    evs.append(rest(n))
            if cb == 2:
                evs.append(rest(8 * e))  # a bar of air after each
        nm = s.pattern(name, evs)
        if hook:
            s.hooks.setdefault(nm, []).append(0)
        return nm

    hook = phrase([p["call"], p["tail"]], chords[:2], "hook", hook=True)
    gap = s.pattern("gap", [rest(2 * chord_ticks)])
    if long:
        hook2 = phrase([p["call"], p["tail"]], chords[4:6], "hook", hook=True)
        ans = phrase([th.ANSWERS[p["answer"]], th.CADENCES["home"]], chords[6:8], "answer")
        s.voice(3, [hook, gap, hook2, ans])
        lead_ticks = P
    else:
        ans = phrase([th.ANSWERS[p["answer"]], th.CADENCES["home"]], chords[2:4], "answer")
        s.voice(3, [hook, gap, hook, ans])
        lead_ticks = 2 * P

    # the bell: phrases of the safe notes, each a few notes then a long gap; its loop a number
    # of pulses sharing no factor with the progression's
    safe = safe_tones(p, chords)
    if len(safe) < 3:
        safe = sorted(set(safe) | {chords[0][1][0], chords[0][1][2]})
    p["safe"] = safe
    total = coprime_length(rng, e, int(pulses * 1.3), int(pulses * 1.9), [pulses, 2 * pulses])
    lens = []
    left = total
    for i in range(p["bell_phrases"]):
        n = left if i == p["bell_phrases"] - 1 else left // (p["bell_phrases"] - i) + rng.randrange(-3, 4)
        lens.append(n)
        left -= n
    bell_pats = []
    for i, n in enumerate(lens):
        evs = []
        notes = rng.choice([2, 3, 3, 4])
        used = 0
        prev = 60 + p["key"]
        if prev > 70:
            prev -= 12
        for j in range(notes):
            pc = rng.choice(safe)
            q = th.nearest(pc, prev + rng.choice([-3, 2, 4]), "~", 55, 71)
            d = rng.choice([1, 1, 2]) if j < notes - 1 else rng.choice([2, 3])
            evs.append(Ev(q, d * e, vol=mix["bell"], k=8))
            used += d
            prev = q
        evs.append(rest((n - used) * e))
        bell_pats.append(s.pattern("bell_%s" % "abc"[i], evs))
    s.voice(4, [s.pattern("in_bell", [rest(3 * e)])] + bell_pats, 1)
    s.voice(5, [s.pattern("in_echo", [Ev(None, 3 * e + p["echo_delay"], vol=mix["echo"], k=8)])] +
            bell_pats, 1)

    # crickets (tone and noise, high, chirps of one-tick pulses) or drops (single high plinks),
    # on a loop of a prime number of ticks near 15 s
    primes = [n for n in range(800, 1000) if all(n % d for d in range(2, 32))]
    tl = rng.choice(primes)
    tv = mix["tex"]
    if p["texture"] == "crickets":
        chirp = []
        for _ in range(4):
            chirp += [Ev(84, 1, vol=tv, k=0, m=3), rest(1)]
        evs = [x for x in chirp]
        evs[0] = Ev(84, 1, vol=tv, k=0, m=3, noise=1)
        evs += [rest(29)] + chirp + [rest(29)] + chirp
        used = st.ticks(evs)
        evs.append(rest(tl - used))
    else:
        evs = []
        used = 0
        for j in range(3):
            q = th.nearest(rng.choice(safe), 79, "~", 76, 86)
            evs.append(Ev(q, 3, vol=tv, k=1, m=1))
            gap_t = rng.choice([40, 70, 110])
            evs.append(rest(gap_t))
            used += 3 + gap_t
        evs.append(rest(tl - used))
    s.voice(2, [s.pattern("in_tex", [rest(e * 5 + 17)]), s.pattern(p["texture"], evs)], 1)

    s.drop_unused()
    s.merge_runs()
    s.check(upto=lead_ticks + 600)
    s.p = p
    s.loop_ticks = lead_ticks
    s.notes = header(p, s, chords, P, total, tl)
    return s


def header(p, s, chords, P, bell_pulses, tl):
    keyname = th.note_word(p["key"], p["key"], p["mode"])
    e = p["eighth"]
    period = 1
    for v in s.voices:
        a, b = s.cycle(v)
        if b:
            period = period * b // math.gcd(period, b)
    hrs = period / st.TICK_HZ / 3600
    names = " ".join(th.chord_name(p["key"], p["mode"], d, q)
                     for d, q in p["prog"] + (p["prog2"] if p["long"] else []))
    safe = " ".join(th.note_word(x, p["key"], p["mode"]) for x in p["safe"])
    return [
        "gen/%s: made by tools/music/gen (drifting loops), seed %d. Do not hand-edit; make again."
        % (s.name, p["seed"]),
        "Key: %s %s: %s, %d bar%s a chord. A pulse (an 8th) is %d ticks (quarter = %d bpm)."
        % (keyname, p["mode"], names, p["chord_bars"], "" if p["chord_bars"] == 1 else "s", e,
           round(60 * st.TICK_HZ / (2 * e))),
        "Loops: the chords %d ticks (%.1f s)%s; the bell %d pulses "
        "(%d ticks); the %s %d ticks (a prime)." % (P, P / st.TICK_HZ,
                                                  "" if p["long"] else ", the hook twice round them",
                                                  bell_pulses,
                                                  bell_pulses * e, p["texture"], tl),
        "The whole repeats after %s." % ("%.1f hours" % hrs if hrs >= 1 else "%.0f s" % (hrs * 3600)),
        "The bell's notes, none a minor ninth over any chord tone: %s." % safe,
        "",
        "voice 0  bass: the root, then the fifth, left to ring (k15)",
        "voice 1  pad: the chord's third and its seventh (or fifth), a pulse behind the bass",
        "voice 2  %s on their own loop (lent to the hero's effects)" % p["texture"],
        "voice 3  the hook: %s on the first two chords, a rest, the hook%s, an answer (%s)"
        % ("the Catwiz motif" if p["motif"] == "catwiz" else "a hook made by rules",
           " on the 5th and 6th" if p["long"] else "", p["answer"]),
        "voice 4  a bell, %d phrases with long gaps, drifting" % p["bell_phrases"],
        "voice 5  the bell's echo, %d ticks later and soft (lent to the enemies' effects)"
        % p["echo_delay"],
        "Size: %d bytes." % s.bytes(),
    ]


SIDE = {0: "bass", 1: "pad", 2: "tex", 3: "lead", 4: "bell", 5: "echo"}
RANGE = {"bass": (10, 13), "pad": (8, 12), "tex": (6, 10), "lead": (11, 13), "bell": (9, 12),
         "echo": (4, 7)}


def make(seed, motif=None):
    import itertools
    long = True
    s = build(seed, motif, long=long)
    if s.bytes() > st.PLAYING:
        long = False
        s = build(seed, motif, long=long)
    if s.bytes() > st.PLAYING:
        raise SystemExit("drift seed %d: %d bytes" % (seed, s.bytes()))
    mix = s.p["mix"]
    pw = {SIDE[v]: st.power(s, v, s.loop_ticks) for v in s.voices}
    best = None
    names = list(RANGE)
    for combo in itertools.product(*[range(RANGE[n][0], RANGE[n][1] + 1) for n in names]):
        side = [0.0, 0.0]
        for n, vol in zip(names, combo):
            v = [k for k, x in SIDE.items() if x == n][0]
            side[0 if v < 3 else 1] += pw[n] * 2.0 ** (vol - mix[n])
        bal = abs(10 * math.log10(side[0] / side[1]))
        moved = sum(abs(vol - mix[n]) for n, vol in zip(names, combo))
        score = max(bal, 0.75) + 0.15 * moved
        if best is None or score < best[0]:
            best = (score, dict(zip(names, combo)))
    s2 = build(seed, motif, best[1], long=long)
    return s2 if s2.bytes() <= st.PLAYING else s
