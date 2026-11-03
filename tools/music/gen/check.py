#!/usr/bin/env python3
"""Checks for songs and renders that need no ears.

    python3 tools/music/gen/check.py song A.song [B.song ...]   # size, hook recurrence, cycles
    python3 tools/music/gen/check.py audio A.ogg [B.ogg ...]    # silence, clipping, balance
    python3 tools/music/gen/check.py pitch A.song [--voice 3]   # one voice rendered alone,
                                                                # its pitch against its notes

song: the size by listen.py's song_bytes against the game's 395; each voice's intro and loop
in ticks and when the whole song repeats (their common multiple); the hook's patterns (the
"; hook:" line the generator writes) and where they start in the lead's order list over the
first 60 s, with the longest gap between two.

audio: each side's level (RMS, dBFS), the peak, samples at full scale (clipping), the share
of half-seconds below -45 dBFS after the first second and the longest such stretch (silence),
and left over right in dB.

pitch: renders the voice alone (its order list only) through listen.py, finds each note of
at least 8 ticks in the render (the spectrum's peak in the note's middle, refined by its
neighbours) and compares it with the note the song says, in cents.
"""

import math
import os
import re
import subprocess
import sys
import tempfile

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import songtext as st  # noqa: E402
import scene           # noqa: E402

RATE = 44100


def decode(path):
    raw = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", path, "-f", "f32le", "-ac", "2",
                          "-ar", str(RATE), "-"], capture_output=True, check=True).stdout
    return np.frombuffer(raw, dtype=np.float32).reshape(-1, 2)


def db(x):
    return 20 * math.log10(max(x, 1e-9))


def audio_report(path):
    a = decode(path)
    rms = [float(np.sqrt(np.mean(a[:, c].astype(np.float64) ** 2))) for c in (0, 1)]
    peak = float(np.max(np.abs(a)))
    clipped = int(np.sum(np.abs(a) >= 0.999))
    mono = a.mean(axis=1)
    win = RATE // 2
    n = len(mono) // win
    levels = [db(float(np.sqrt(np.mean(mono[i * win:(i + 1) * win] ** 2)))) for i in range(n)]
    quiet = [l < -45 for l in levels[2:]]
    longest = run = 0
    for q in quiet:
        run = run + 1 if q else 0
        longest = max(longest, run)
    r = {
        "seconds": len(a) / RATE,
        "left_db": db(rms[0]), "right_db": db(rms[1]),
        "balance_db": db(rms[0]) - db(rms[1]),
        "peak_db": db(peak), "clipped": clipped,
        "quiet_share": sum(quiet) / max(1, len(quiet)), "longest_quiet_s": longest * 0.5,
    }
    return r


def print_audio(path, r):
    flags = []
    if r["clipped"]:
        flags.append("CLIPS")
    if r["quiet_share"] > 0.25 or r["longest_quiet_s"] > 4:
        flags.append("QUIET")
    if abs(r["balance_db"]) > 3:
        flags.append("UNBALANCED")
    print("%-28s L %6.1f  R %6.1f  L-R %+5.1f dB  peak %6.1f dBFS  clipped %d  quiet %3.0f%% "
          "(longest %.1f s)  %s" % (os.path.basename(path), r["left_db"], r["right_db"],
                                    r["balance_db"], r["peak_db"], r["clipped"],
                                    100 * r["quiet_share"], r["longest_quiet_s"],
                                    " ".join(flags) or "ok"))
    return not flags


def song_lengths(body):
    pats, voices = scene.parse_song_body(body)
    plen = {n: st.stream_ticks(t) for n, t in pats.items()}
    return pats, voices, plen


def song_report(path, seconds=60):
    with open(path) as f:
        text = f.read()
    size = st.listen.song_bytes(text)
    pats, voices, plen = song_lengths(text)
    m = re.search(r"^; hook: (.*)$", text, re.M)
    hooks = {}  # pattern -> ticks into it where the hook starts
    for w in (m.group(1).split() if m else []):
        name, _, at = w.partition("@")
        hooks.setdefault(name, []).append(int(at or 0))
    print("%s: %d bytes (%s)" % (os.path.basename(path), size,
                                 "fits" if size <= st.PLAYING else "OVER %d" % st.PLAYING))
    period = 1
    for v, (order, loop_at) in sorted(voices.items()):
        intro = sum(plen[p] for p in order[:loop_at])
        loop = sum(plen[p] for p in order[loop_at:])
        if loop:
            period = period * loop // math.gcd(period, loop)
        print("  voice %d  intro %5d  loop %6d ticks (%.1f s)" % (v, intro, loop, loop / st.TICK_HZ))
    hrs = period / st.TICK_HZ / 3600
    print("  the whole repeats every %d ticks: %s" % (
        period, "%.1f s" % (period / st.TICK_HZ) if hrs < 1 else "%.1f hours" % hrs))
    ok = size <= st.PLAYING
    if hooks:
        upto = int(seconds * st.TICK_HZ)
        for v, (order, loop_at) in sorted(voices.items()):
            if not any(p in hooks for p in order):
                continue
            starts = []
            t = 0
            i = 0
            while t < upto:
                p = order[i]
                for at in hooks.get(p, []):
                    starts.append(t + at)
                t += plen[p]
                i += 1
                if i == len(order):
                    i = loop_at
            starts = sorted(s for s in starts if s < upto)
            gaps = [b - a for a, b in zip(starts, starts[1:])]
            first = starts[0] / st.TICK_HZ if starts else None
            longest = max(gaps) / st.TICK_HZ if gaps else None
            print("  hook on voice %d (%s): %d times in %d s, first at %.1f s, longest gap %s" % (
                v, " ".join(sorted(set(p for p in order if p in hooks))), len(starts), seconds,
                first if first is not None else -1,
                "%.1f s" % longest if longest is not None else "-"))
            if len(starts) < 3 or (longest or 0) > 25:
                print("    HOOK TOO RARE")
                ok = False
    elif "; hook:" not in text:
        print("  (no hook line)")
    return ok


def pitch_report(path, voice=3, seconds=30):
    """renders voice alone and compares each note's pitch with the song's"""
    with open(path) as f:
        text = f.read()
    pats, voices = scene.parse_song_body(text)
    order, loop_at = voices[voice]
    words = list(order)
    if loop_at:
        words.insert(loop_at, "loop")
    body = "\n".join('(pattern %s "%s")' % (n, t) for n, t in pats.items() if n in order)
    body += "\n(voice %d %s)\n" % (voice, " ".join(words))
    with tempfile.TemporaryDirectory() as work:
        song = os.path.join(work, "solo.song")
        with open(song, "w") as f:
            f.write(body)
        subprocess.run([sys.executable, os.path.join(st.MUSIC, "listen.py"), "--seconds",
                        str(seconds), "--out", work, song], check=True, capture_output=True)
        a = decode(os.path.join(work, "solo.ogg"))
    sig = a[:, 0 if voice < 3 else 1].astype(np.float64)
    upto = int(seconds * st.TICK_HZ) - 60
    notes = [x for x in st.played(body, voice, upto) if x[2] is not None and x[1] >= 8]
    # where the song starts in the render (the machine's start comes first): the lag that best
    # lines the render's attacks (where its level jumps) up with the notes' starts, 10 ms steps
    hop = RATE // 100
    env = np.sqrt(np.convolve(sig ** 2, np.ones(hop) / hop, "same")[::hop])
    rise = np.maximum(0.0, np.diff(env, prepend=env[0]))
    starts = np.zeros(len(env))
    for t, d, p, vol, k, m in st.played(body, voice, upto):
        if p is not None:
            i = int(round(t / st.TICK_HZ * 100))
            starts[i:i + 2] = 1.0
    # the program starts the song about 30 ms in (init, then play): look no further than
    # 120 ms, so a voice of even notes cannot line up a note late
    best = (-1e9, 0)
    span = len(env) - 200
    for lag in range(0, 13):
        score = float(np.dot(rise[lag:lag + span], starts[:span]))
        if score > best[0]:
            best = (score, lag)
    t0 = best[1] / 100.0
    errs = []
    for t, d, p, vol, k, m in notes:
        if m != 1:
            continue
        mid = t0 + (t + min(d, 16) / 2.0) / st.TICK_HZ
        n = 4096
        c = int(mid * RATE)
        seg = sig[max(0, c - n // 2):c + n // 2]
        if len(seg) < n or np.sqrt(np.mean(seg ** 2)) < 1e-4:
            continue
        spec = np.abs(np.fft.rfft(seg * np.hanning(n), 4 * n))
        fr = np.fft.rfftfreq(4 * n, 1.0 / RATE)
        want = st.freq(p)
        # the fundamental: the strongest bin within nearly an octave either side (a wrong note shows)
        band = (fr > want / 1.9) & (fr < want * 1.9)
        i = int(np.argmax(np.where(band, spec, 0)))
        if 0 < i < len(spec) - 1:
            y0, y1, y2 = np.log(spec[i - 1:i + 2] + 1e-12)
            i = i + 0.5 * (y0 - y2) / (y0 - 2 * y1 + y2)
        got = i * RATE / (4 * n)
        errs.append((t / st.TICK_HZ, st.note_name(p), want, got, 1200 * math.log2(got / want)))
    if not errs:
        print("no notes to check")
        return False
    cents = np.array([e[4] for e in errs])
    within = np.mean(np.abs(cents) < 25)
    print("%s voice %d: %d notes checked, %.0f%% within 25 cents, median %+.1f cents, worst %+.0f"
          % (os.path.basename(path), voice, len(errs), 100 * within, np.median(cents),
             cents[np.argmax(np.abs(cents))]))
    for e in errs[:12]:
        print("   %6.2f s  %-4s want %7.1f Hz  got %7.1f Hz  %+6.1f cents" % e)
    return within > 0.9


def main():
    if len(sys.argv) < 3:
        raise SystemExit(__doc__)
    what, args = sys.argv[1], sys.argv[2:]
    ok = True
    if what == "song":
        for a in args:
            ok &= song_report(a)
    elif what == "audio":
        for a in args:
            ok &= print_audio(a, audio_report(a))
    elif what == "pitch":
        voice = 3
        if "--voice" in args:
            i = args.index("--voice")
            voice = int(args[i + 1])
            del args[i:i + 2]
        for a in args:
            ok &= pitch_report(a, voice)
    else:
        raise SystemExit(__doc__)
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
