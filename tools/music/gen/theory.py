"""Keys, chords, progressions, and the Catwiz motif as chord-relative riffs.

A riff is a list of steps (pitch spec, length in 8ths). A pitch spec is resolved against the
chord it plays over and the note before it:
  ("c", i, dir)  chord tone i (0 root, 1 third, 2 fifth, 3 seventh, 4 the root an octave up),
                 dir "+" the nearest above the note before, "-" below, "~" the nearest
  ("s", k)       k steps along the key's scale from the note before
  ("x", k)       k semitones from the note before (the twitch: x-1 then x+1)
  ("r",)         a rest
  ("t",)         a tie: the note before goes on
"""

SCALES = {
    "major": [0, 2, 4, 5, 7, 9, 11],
    "minor": [0, 2, 3, 5, 7, 8, 10],
    "dorian": [0, 2, 3, 5, 7, 9, 10],
    "lydian": [0, 2, 4, 6, 7, 9, 11],
    "mixolydian": [0, 2, 4, 5, 7, 9, 10],
}
KEYS = ["c", "c#", "d", "d#", "e", "f", "f#", "g", "g#", "a", "a#", "b"]
FLAT = {"c#": "Db", "d#": "Eb", "g#": "Ab", "a#": "Bb", "f#": "F#"}

# chord qualities, semitones from the root
QUAL = {
    "": [0, 4, 7], "m": [0, 3, 7], "dim": [0, 3, 6], "7": [0, 4, 7, 10], "m7": [0, 3, 7, 10],
    "maj7": [0, 4, 7, 11], "sus4": [0, 5, 7], "sus2": [0, 2, 7],
}

# progressions: (degree 0-6 of the key's scale, quality), four chords a phrase. A: the verse,
# B: a contrasting phrase that turns back home
PROGRESSIONS = {
    "minor": {
        "A": [[(0, "m"), (5, ""), (2, ""), (6, "")],      # i VI III VII
              [(0, "m"), (3, "m"), (6, ""), (2, "")],     # i iv VII III
              [(0, "m"), (5, ""), (3, "m"), (4, "")],     # i VI iv V
              [(0, "m"), (6, ""), (5, ""), (4, "")]],     # i VII VI V (the andalusian)
        "B": [[(5, ""), (6, ""), (0, "m"), (0, "m")],     # VI VII i i
              [(3, "m"), (4, "m"), (5, ""), (4, "")],     # iv v VI V
              [(5, ""), (2, ""), (6, ""), (4, "7")]],     # VI III VII V7
    },
    "major": {
        "A": [[(0, ""), (4, ""), (5, "m"), (3, "")],      # I V vi IV
              [(0, ""), (5, "m"), (3, ""), (4, "")],      # I vi IV V
              [(0, ""), (3, ""), (5, "m"), (4, "")],      # I IV vi V
              [(0, ""), (2, "m"), (3, ""), (4, "")]],     # I iii IV V
        "B": [[(3, ""), (4, ""), (2, "m"), (5, "m")],     # IV V iii vi
              [(5, "m"), (3, ""), (0, ""), (4, "")],      # vi IV I V
              [(3, ""), (0, ""), (1, "m"), (4, "7")]],    # IV I ii V7
    },
    "dorian": {
        "A": [[(0, "m"), (3, ""), (0, "m"), (3, "")],     # i IV i IV
              [(0, "m"), (6, ""), (3, ""), (0, "m")],     # i VII IV i
              [(0, "m"), (2, ""), (3, ""), (6, "")]],     # i III IV VII
        "B": [[(2, ""), (3, ""), (6, ""), (4, "m")],      # III IV VII v
              [(6, ""), (3, ""), (5, "dim"), (0, "m")]],
    },
    "lydian": {
        "A": [[(0, ""), (1, ""), (0, ""), (1, "")],       # I II I II (D, E/D)
              [(0, ""), (1, ""), (5, "m"), (4, "")],      # I II vi V
              [(0, "maj7"), (1, ""), (2, "m"), (4, "")]],
        "B": [[(5, "m"), (4, ""), (1, ""), (1, "")],
              [(4, ""), (5, "m"), (1, ""), (0, "")]],
    },
}

# where a mode's V is borrowed major (the leading tone), for minor and dorian cadences
RAISE_V = {"minor", "dorian"}


def chord(key_pc, mode, deg, qual):
    """(root pitch class, [pitch classes of the chord's tones]) of degree deg in the key"""
    root = (key_pc + SCALES[mode][deg]) % 12
    q = QUAL[qual]
    return root, [(root + i) % 12 for i in q]


FLATS = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"]
SHARPS = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
RELATIVE_MAJOR = {"major": 0, "minor": 3, "dorian": 10, "lydian": 7, "mixolydian": 5}


def uses_flats(key_pc, mode):
    """whether the key is written with flats (F, Bb, Eb, Ab, Db major and their modes)"""
    return (key_pc + RELATIVE_MAJOR[mode]) % 12 in (5, 10, 3, 8, 1)


def note_word(pc, key_pc, mode):
    return (FLATS if uses_flats(key_pc, mode) else SHARPS)[pc % 12]


def chord_name(key_pc, mode, deg, qual):
    root = (key_pc + SCALES[mode][deg]) % 12
    return note_word(root, key_pc, mode) + qual


def nearest(pc, prev, dirn, lo, hi):
    """the pitch of class pc nearest prev: above it (+), below (-) or either (~), then kept in
    lo..hi by octaves"""
    base = prev - ((prev - pc) % 12)  # the pc at or below prev
    if dirn == "+":
        p = base + 12 if base <= prev else base
        if p == prev:
            p += 12
    elif dirn == "-":
        p = base if base < prev else base - 12
    else:
        up = base + 12
        p = base if prev - base <= up - prev else up
    while p > hi:
        p -= 12
    while p < lo:
        p += 12
    return p


def scale_step(p, k, key_pc, mode):
    """k steps along the scale from p (a note off the scale goes first to the scale)"""
    sc = [(key_pc + i) % 12 for i in SCALES[mode]]
    step = 1 if k > 0 else -1
    for _ in range(abs(k)):
        p += step
        while p % 12 not in sc:
            p += step
    return p


def tone_pc(ch, i):
    root, pcs = ch
    if i == 4:
        return root
    if i == 3:
        return pcs[3] if len(pcs) > 3 else (root + 10) % 12 if (pcs[1] - root) % 12 == 3 else (root + 11) % 12
    return pcs[min(i, len(pcs) - 1)]


def realise(riff, ch, prev, key_pc, mode, lo, hi, eighth):
    """a riff's notes over chord ch from the note before (prev): [(pitch or None or "t",
    ticks)]. A "~" chord tone is the nearest one inside lo..hi; "+" and "-" keep their
    direction. Then the riff moves by an octave, whole, if that puts it better in range
    (so a step down stays a step down), weighing the jump from prev"""
    def walk(start):
        out = []
        p = start
        for spec, d in riff:
            n = int(round(d * eighth))
            if spec[0] == "r":
                out.append((None, n))
                continue
            if spec[0] == "t":
                out.append(("t", n))
                continue
            if spec[0] == "c":
                i, dirn = spec[1], spec[2]
                if i == 4:
                    p = nearest(tone_pc(ch, 0), p, "+", -99, 999)
                elif dirn == "~":
                    p = nearest(tone_pc(ch, i), p, "~", lo, hi)
                else:
                    p = nearest(tone_pc(ch, i), p, dirn, -99, 999)
            elif spec[0] == "s":
                p = scale_step(p, spec[1], key_pc, mode)
            elif spec[0] == "x":
                p = p + spec[1]
            out.append((p, n))
        return out

    best = None
    for shift in (0, 12, -12):
        out = walk(prev + shift)
        ps = [q for q, _ in out if isinstance(q, int)]
        if not ps:
            return out
        outside = sum(max(0, lo - q) + max(0, q - hi) for q in ps)
        score = 10 * outside + abs(ps[0] - prev) + (1 if shift else 0)
        if best is None or score < best[0]:
            best = (score, out)
    return best[1]


C = lambda i, d="~": ("c", i, d)  # noqa: E731
S = lambda k: ("s", k)            # noqa: E731
X = lambda k: ("x", k)            # noqa: E731
R = ("r",)
T = ("t",)

# THE CATWIZ MOTIF: 1 5 #4 5 3 | 2 1, rhythm 1 3 1 1 2 | 1 3 (8ths; tools/music/songs/d_motif)
# its riffs, each a bar of 8 8ths, by what they do in a phrase
CALLS = {
    "motif": [(C(0), 1), (C(2, "+"), 3), (X(-1), 1), (X(1), 1), (C(1, "-"), 2)],
    "motif_oct": [(C(0), 1), (C(4, "+"), 3), (X(-1), 1), (X(1), 1), (C(2, "-"), 2)],
    "motif_late": [(R, 1), (C(0), 1), (C(2, "+"), 2), (X(-1), 1), (X(1), 1), (C(1, "-"), 2)],
    "twitch_turn": [(C(2), 2), (X(-1), 1), (X(1), 1), (C(1, "-"), 1), (C(2, "+"), 1), (C(0, "-"), 2)],
    "motif_drive": [(C(0), 0.5), (C(0), 0.5), (C(2, "+"), 2), (X(-1), 1), (X(1), 1), (C(1, "-"), 1),
                    (C(2, "+"), 2)],
    "motif_up3": [(C(1), 1), (C(4, "+"), 3), (X(-1), 1), (X(1), 1), (C(2, "-"), 2)],
}
# the King's: the motif upside down, 1 4(down a fifth) #4 4 b6 | b7 1
KING = [(C(0), 1), (X(-7), 3), (X(1), 1), (X(-1), 1), (X(3), 2)]
KING_TAIL = [(X(2), 1), (X(2), 3), (R, 4)]

ANSWERS = {
    "tail": [(S(-1), 1), (C(0, "~"), 3), (R, 2), (C(2, "~"), 1), (C(1, "~"), 1)],
    "run": [(C(2), 1), (S(-1), 1), (S(-1), 1), (S(-1), 1), (C(0, "~"), 2), (R, 2)],
    "twitch_echo": [(C(2), 1), (X(-1), 1), (X(1), 2), (C(1, "-"), 2), (C(0, "-"), 2)],
    "arp": [(C(0), 1), (C(1, "+"), 1), (C(2, "+"), 1), (C(4, "+"), 3), (R, 2)],
    "reply": [(R, 2), (C(2), 1), (X(-1), 1), (X(1), 1), (C(1, "-"), 1), (C(0, "-"), 2)],
    "skip": [(C(1), 1), (C(2, "+"), 1), (R, 1), (C(1, "-"), 1), (C(0, "-"), 2), (S(1), 2)],
}
CADENCES = {
    "home": [(S(-1), 1), (C(0, "-"), 5), (R, 2)],
    "open": [(C(2), 2), (C(1, "-"), 2), (C(2, "+"), 4)],
    "lead_in": [(C(0), 3), (R, 1), (C(1, "~"), 1), (C(2, "+"), 1), (X(-1), 1), (X(1), 1)],
    "twitch_home": [(C(2), 1), (X(-1), 1), (X(1), 2), (C(0, "-"), 4)],
}
BRIDGES = {
    "long": [(C(1), 4), (C(2, "+"), 4)],
    "sync": [(C(2), 3), (C(1, "-"), 3), (C(0, "-"), 2)],
    "sweep": [(C(4), 2), (C(3, "-"), 2), (C(2, "-"), 2), (C(1, "-"), 2)],
    "climb": [(C(0), 1), (C(1, "+"), 1), (C(2, "+"), 2), (S(1), 2), (C(2, "-"), 2)],
    "twitch_hold": [(C(2), 1), (X(-1), 1), (X(1), 6)],
}
TURNS = {
    "twitch_up": [(C(0), 2), (C(1, "+"), 2), (C(2, "+"), 1), (X(-1), 1), (X(1), 2)],
    "fall": [(C(4), 1), (C(2, "-"), 1), (C(1, "-"), 1), (C(0, "-"), 1), (R, 4)],
    "hold5": [(C(2), 6), (X(-1), 1), (X(1), 1)],
}


def make_hook(rng):
    """a new hook in the motif's manner, from rules: a pickup, a leap up (a fifth, sixth or
    octave) held long, a chromatic flick below it and back (the twitch), then down to a chord
    tone; its tail steps home. Returns (call, tail) riffs."""
    leap = rng.choice([("c", 2, "+"), ("c", 4, "+"), ("c", 1, "+")])
    rhythm = rng.choice([[1, 3, 1, 1, 2], [2, 2, 1, 1, 2], [1, 2, 1, 2, 2], [1, 3, 0.5, 0.5, 3]])
    flick = rng.choice([[X(-1), X(1)], [X(1), X(-1)], [S(-1), S(1)]])
    land = rng.choice([x for x in [C(1, "-"), C(0, "-"), S(-2)] if x[:2] != leap[:2]])
    call = [(C(0), rhythm[0]), (leap, rhythm[1]), (flick[0], rhythm[2]), (flick[1], rhythm[3]),
            (land, rhythm[4])]
    tail = rng.choice([
        [(S(-1), 1), (C(0, "-"), 3), (R, 4)],
        [(S(1), 1), (S(-2), 1), (C(0, "~"), 2), (R, 4)],
        [(S(-1), 2), (S(-1), 2), (C(0, "~"), 4)],
    ])
    return call, tail
