"""Riffology, after Peter Langston's Ballblazer music (Lucasfilm, 1984): a lead stitched from a
library of one-bar riffs over a chord progression, a bass and drums. Langston's lead chose its
riffs on the fly; here the choice keeps a phrase structure so the tune stays hummable:

  A phrase (4 bars)  call | answer | the call again on the 3rd chord | cadence
                     the call is a riff of the Catwiz motif (or a hook made by rules in its
                     manner); the 3rd bar repeats it, or grows it (its leap an octave)
  B phrase (4 bars)  a contrasting riff | another | the first again | a turn back home
  the form           AABA, ABAB or AABB; the first A ends open, the later ones home

Every distinct (riff, chord) is a pattern; the order lists do the repeating, so a 16-bar song
fits the game's 395 bytes. What a song costs is measured as it is made; over 395, the plan
gets plainer in a fixed order (fewer pad notes, no fills, a plainer bass, no pad, no echo)
until it fits.
"""

import random

import songtext as st
import theory as th
from songtext import Ev, rest

GROOVES = {
    "rock": "K.S.KKS.",
    "backbeat": "K.S.K.S.",
    "skip": "K.S..KS.",
    "half": "K...S...",
    "gallop": "KKS.KKS.",
    "push": "K.SK.KS.",
}
FILL = "K.S.SSSs"  # s: two 16th snares

BASS = ["half", "bounce", "pump", "octaves", "walk", "drive"]
PAD = ["guide", "long", "stabs"]


def plan(seed, motif=None):
    """every choice the seed makes, made up front (so a plainer version of the same song makes
    the same choices)"""
    rng = random.Random(seed)
    p = {"seed": seed}
    p["mode"] = rng.choice(["minor", "minor", "dorian", "major", "lydian", "minor"])
    p["key"] = rng.randrange(12)
    p["eighth"] = rng.choice([10, 12, 12, 13, 14, 15, 16])
    progs = th.PROGRESSIONS[p["mode"]]
    p["A"] = rng.choice(progs["A"])
    p["B"] = rng.choice(progs["B"])
    p["form"] = rng.choice(["AABA", "AABA", "ABAB", "AABB"])
    p["motif"] = motif or rng.choice(["catwiz", "catwiz", "made"])
    if p["motif"] == "made":
        p["call"], p["tail"] = th.make_hook(rng)
        p["call_name"] = "a made hook"
    else:
        name = rng.choice(["motif", "motif", "motif_late", "twitch_turn", "motif_drive",
                           "motif_up3"])
        p["call"], p["call_name"] = th.CALLS[name], name
        p["tail"] = None
    p["grow"] = rng.random() < 0.5 and p["call_name"] in ("motif", "motif_late", "motif_drive")
    p["answer"] = rng.choice(["tail", "tail"] + list(th.ANSWERS))
    p["cad_open"] = rng.choice(["open", "lead_in"])
    p["cad_home"] = rng.choice(["home", "twitch_home"])
    p["bridge1"] = rng.choice(list(th.BRIDGES))
    p["bridge2"] = rng.choice([k for k in list(th.BRIDGES) + list(th.ANSWERS) if k != p["bridge1"]])
    p["turn"] = rng.choice(list(th.TURNS))
    p["lead_k"] = rng.choice([2, 3, 3, 4, 5])
    p["bass"] = rng.choice(BASS)
    p["bass_k"] = rng.choice([3, 4, 5])
    p["pad"] = rng.choice(PAD)
    p["groove"] = rng.choice(list(GROOVES))
    p["echo"] = rng.choice([1.0, 1.5, 2.0])
    p["kick"] = rng.choice([5, 7, 9])  # F1, G1, A1
    return p


def riff_notes(p, riff, ch, prev, lo, hi):
    return th.realise(riff, ch, prev, p["key"], p["mode"], lo, hi, p["eighth"])


def to_evs(notes, vol=None, k=None):
    out = []
    for pitch, n in notes:
        if pitch is None:
            out.append(rest(n))
        elif pitch == "t":
            out.append(Ev(None, n, tie=True))
        else:
            out.append(Ev(pitch, n, vol=vol, k=k))
    return out


def lead_bars(p, letter, which):
    """the lead's four bars of a phrase: [(riff name, notes)], and the phrase's chords"""
    prog = p[letter]
    chords = [th.chord(p["key"], p["mode"], d, q) for d, q in prog]
    t0 = 36 + p["key"]
    if t0 < 43:
        t0 += 12
    lo, hi = t0 - 7, t0 + 16
    bars = []
    prev = t0
    if letter == "A":
        call = p["call"]
        call3 = th.CALLS["motif_oct"] if p["grow"] else call
        ans = p["tail"] or th.ANSWERS[p["answer"]]
        cad = th.CADENCES[p["cad_open"] if which == 0 else p["cad_home"]]
        riffs = [("call", call), ("answer", ans), ("call", call3), ("cadence", cad)]
    else:
        b1 = th.BRIDGES[p["bridge1"]]
        b2 = th.BRIDGES.get(p["bridge2"]) or th.ANSWERS[p["bridge2"]]
        riffs = [("bridge", b1), ("bridge2", b2), ("bridge", b1), ("turn", th.TURNS[p["turn"]])]
        prev = t0 + 4
    for (role, riff), ch in zip(riffs, chords):
        assert abs(sum(d for _, d in riff) - 8) < 1e-9, (role, riff)
        notes = riff_notes(p, riff, ch, prev, lo, hi)
        for pitch, _ in notes:
            if isinstance(pitch, int):
                prev = pitch
        bars.append((role, notes))
    return bars, chords


def bass_bar(p, style, ch, nxt):
    e = p["eighth"]
    root = th.nearest(ch[0], 12, "~", 7, 18)
    fifth = root + 7 if root + 7 <= 26 else root - 5
    third = root + ((ch[1][1] - ch[0]) % 12)
    octave = root + 12
    if style == "half":
        seq = [(root, 4), (fifth, 4)]
    elif style == "bounce":
        seq = [(root, 3), (fifth, 3), (root, 2)]
    elif style == "pump":
        seq = [(root, 1)] * 8
    elif style == "octaves":
        seq = [(root, 1), (octave, 1)] * 4
    elif style == "walk":
        nroot = th.nearest(nxt[0], 12, "~", 7, 18)
        seq = [(root, 2), (third, 2), (fifth, 2), (nroot - 1 if nroot > root else nroot + 1, 2)]
    else:  # drive
        seq = [(root, 2), (root, 1), (fifth, 1), (root, 2), (octave, 1), (fifth, 1)]
    return [Ev(n, d * e, vol=p["mix"]["bass"], k=p["bass_k"]) for n, d in seq]


def pad_bar(p, style, ch, vol):
    e = p["eighth"]
    tones = [th.nearest(pc, 34, "~", 28, 42) for pc in ch[1]]
    third, fifth = tones[1], tones[2]
    if style == "guide":
        sev = th.nearest(th.tone_pc(ch, 3), third, "+", 28, 44)
        return [Ev(third, 4 * e, vol=vol, k=12), Ev(sev if sev - third < 9 else fifth, 4 * e, vol=vol, k=12)]
    if style == "stabs":
        return [rest(e), Ev(third, e, vol=vol, k=2), rest(e), Ev(fifth, e, vol=vol, k=2)] * 2
    return [Ev(third, 8 * e, vol=vol, k=15)]


def drum_bar(p, pattern, plain=False):
    e = p["eighth"]
    out = []
    kick = p["kick"]
    first_snare = True
    for c in pattern:
        if c == "K":
            out.append(Ev(kick, e, vol=p["mix"]["drums"] + 1, k=1, m=1))
        elif c == "S":
            out.append(Ev(36, e, vol=p["mix"]["drums"], k=1, m=2, noise=5 if first_snare else None))
            first_snare = False
        elif c == "s":
            h = e // 2
            out.append(Ev(36, h, vol=p["mix"]["drums"], k=1, m=2, noise=5 if first_snare else None))
            out.append(Ev(36, e - h, vol=p["mix"]["drums"] - 2, k=1, m=2))
            first_snare = False
        else:
            out[-1].dur += e
    return out


MIX = {"bass": 11, "pad": 7, "echo": 5, "drums": 11, "hats": 6}
SIDE = {"bass": 0, "echo": 0, "hats": 0, "lead": 1, "drums": 1, "pad": 1}
RANGE = {"bass": (10, 13), "pad": (5, 10), "echo": (4, 8), "drums": (9, 12), "hats": (4, 7)}


def build(seed, level=0, motif=None, mix=None):
    p = plan(seed, motif)
    p["mix"] = dict(mix or MIX)
    s = st.Song("riff_%d" % seed)
    e = p["eighth"]
    bar = 8 * e
    pad_style = p["pad"] if level < 1 else "long"
    fills = level < 2
    bass_style = p["bass"] if level < 3 else "half"
    pad_on = level < 4
    echo_on = level < 5
    if level >= 6:
        return None
    phrases = []  # (letter, which)
    seen_a = 0
    for c in p["form"]:
        if c == "A":
            phrases.append(("A", min(seen_a, 1)))
            seen_a += 1
        else:
            phrases.append(("B", 0))
    if p["form"] == "AABB":
        phrases[-1] = ("B", 0)
    lead, bass, pad, drums = [], [], [], []
    lead_desc = []
    pad_vol = p["mix"]["pad"]
    for pi, (letter, which) in enumerate(phrases):
        bars, chords = lead_bars(p, letter, which)
        for bi, (role, notes) in enumerate(bars):
            name = s.pattern("%s%s_%d" % (letter.lower(), "" if letter == "B" else str(which + 1),
                                          bi + 1),
                             _lead_evs(notes, p["lead_k"]), home={})
            lead.append(name)
            if role == "call":
                s.hooks.setdefault(name, []).append(0)
        lead_desc.append(letter + ("'" if which else ""))
        nxt_chords = chords[1:] + [chords[0]]
        for bi, ch in enumerate(chords):
            bass.append(s.pattern("bs_%s" % th.KEYS[ch[0]].replace("#", "s"),
                                  bass_bar(p, bass_style, ch, nxt_chords[bi]), home={}))
            if pad_on:
                pad.append(s.pattern("p_%s" % th.KEYS[ch[0]].replace("#", "s"),
                                     pad_bar(p, pad_style, ch, pad_vol), home={}))
            last = bi == 3 and (pi % 2 == 1)
            drums.append(s.pattern("fill" if (last and fills) else "groove",
                                   drum_bar(p, FILL if (last and fills) else GROOVES[p["groove"]]),
                                   home={}))
    # left: bass, the echo, hats (noise: alone on the left chip); right: the lead, drums (the
    # snare's noise alone on the right chip), the pad. 2 and 5 are lent to the effects
    s.voice(0, bass)
    if pad_on:
        s.voice(5, pad)
    s.voice(3, lead)
    s.voice(4, drums)
    hv = p["mix"]["hats"]
    hats = s.pattern("hats", [Ev(36, e, vol=hv, k=1, m=2, noise=1), Ev(36, e, vol=hv - 3, k=1, m=2)],
                     home={})
    s.voice(2, [hats])
    if echo_on:
        delay = int(round(p["echo"] * e))
        s.voice(1, [s.pattern("in_echo", [Ev(None, delay, vol=p["mix"]["echo"])], home={})] + lead, 1)
    s.drop_unused()
    s.merge_runs()
    s.check()
    s.p = p
    s.level = level
    s.loop_ticks = len(phrases) * 4 * bar
    s.notes = header(p, phrases, lead_desc, s, level, pad_style, bass_style, pad_on, echo_on, fills)
    return s


def _lead_evs(notes, k):
    evs = to_evs(notes)
    for ev in evs:
        if ev.pitch is not None:
            ev.k = k
            break
    return evs


def header(p, phrases, lead_desc, s, level, pad_style, bass_style, pad_on, echo_on, fills):
    keyname = th.note_word(p["key"], p["key"], p["mode"])
    ch = lambda prog: " ".join(th.chord_name(p["key"], p["mode"], d, q) for d, q in prog)  # noqa
    e = p["eighth"]
    bars = len(phrases) * 4
    lines = [
        "gen/%s: made by tools/music/gen (riffology), seed %d. Do not hand-edit; make again."
        % (s.name, p["seed"]),
        "Key: %s %s. Tempo: an 8th is %d ticks (quarter = %d bpm), a bar %d ticks."
        % (keyname, p["mode"], e, round(60 * st.TICK_HZ / (2 * e)), 8 * e),
        "Form: %s, %d bars, %d ticks (%.1f s) before it repeats."
        % (" ".join(lead_desc), bars, bars * 8 * e, bars * 8 * e / st.TICK_HZ),
        "  A  %s   call (%s) | answer (%s) | call%s | cadence (%s, then %s)"
        % (ch(p["A"]), p["call_name"], "the hook's tail" if p["tail"] else p["answer"],
           " grown an octave" if p["grow"] else "", p["cad_open"], p["cad_home"]),
        "  B  %s   %s | %s | %s | turn (%s)" % (ch(p["B"]), p["bridge1"], p["bridge2"],
                                                p["bridge1"], p["turn"]),
        "Plainer by %d step%s to fit." % (level, "" if level == 1 else "s") if level else
        "Nothing made plainer to fit.",
        "",
        "Left (chip 1): bass, the echo, hats. Right (chip 2): the lead, drums, the pad.",
        "voice 0  bass: %s, k%d" % (bass_style, p["bass_k"]),
    ]
    if echo_on:
        lines.append("voice 1  the lead's echo, %g 8ths late and soft, on the other side"
                     % p["echo"])
    lines += [
        "voice 2  hats, 8ths (noise, alone on the left chip; lent to the hero's effects)",
        "voice 3  the lead, k%d; its patterns set no volume, so the echo shares them" % p["lead_k"],
        "voice 4  drums: %s%s (the snare's noise alone on the right chip)"
        % (p["groove"], ", a fill every 8th bar" if fills else ""),
    ]
    if pad_on:
        lines.append("voice 5  pad: %s (lent to the enemies' effects)" % pad_style)
    lines.append("Size: %d bytes." % s.bytes())
    return lines


VOICE_PART = {0: "bass", 1: "echo", 2: "hats", 3: "lead", 4: "drums", 5: "pad"}


def balance(build_fn, mix, ticks):
    """volumes that bring the two sides within about 1 dB, by songtext.power (a step is 3 dB,
    so power doubles): each part's power is measured once at the default mix and scaled"""
    import itertools
    import math
    s = build_fn(mix)
    pw = {VOICE_PART[v]: st.power(s, v, ticks) for v in s.voices}
    best = None
    names = [n for n in RANGE if n in pw]
    for combo in itertools.product(*[range(RANGE[n][0], RANGE[n][1] + 1) for n in names]):
        side = [0.0, 0.0]
        for n, vol in zip(names, combo):
            side[SIDE[n]] += pw[n] * 2.0 ** (vol - mix[n])
        side[1] += pw.get("lead", 0)
        if not side[0] or not side[1]:
            continue
        bal = abs(10 * math.log10(side[0] / side[1]))
        moved = sum(abs(vol - mix[n]) for n, vol in zip(names, combo))
        score = max(bal, 0.75) + 0.15 * moved
        if best is None or score < best[0]:
            best = (score, dict(mix, **dict(zip(names, combo))))
    return best[1]


def make(seed, motif=None):
    """the song for a seed, as plain as it has to be to fit, balanced left and right"""
    for level in range(6):
        s = build(seed, level, motif)
        if s.bytes() > st.PLAYING:
            continue
        mix = balance(lambda m: build(seed, level, motif, m), MIX, s.loop_ticks)
        s2 = build(seed, level, motif, mix)
        if s2.bytes() <= st.PLAYING:
            return s2
        return s
    raise SystemExit("seed %d: no plan fits %d bytes" % (seed, st.PLAYING))
