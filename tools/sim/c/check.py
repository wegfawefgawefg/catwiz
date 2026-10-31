"""Checks the C sim against the Python sim run by run: both play the same seeds with the same
player, and every run's line (each fight's hit points left, turns and hit points lost, and
every pick) must be the same. The C sim takes Python's random numbers (rng.c), so a
difference is a rule or a player that differs.

    python3 tools/sim/c/check.py --player greedy --runs 300
    python3 tools/sim/c/check.py --player strong --runs 40 --seed 3

It prints the first runs that differ and a count.
"""

import argparse
import multiprocessing
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))

import run  # noqa: E402
import report  # noqa: E402


def line(args):
    seed, pname, variant = args
    r = run.one_run(("proposal", variant, pname, seed, False))
    parts = ["%d %d %d |" % (seed, 1 if r["won"] else 0, len(r["fights"]))]
    for x in r["fights"]:
        parts.append(" %d:%d:%d:%d:%d" % (x["index"], 1 if x["won"] else 0, x["hp_out"],
                                          x["turns"], x["lost"]))
    parts.append(" |")
    for f, t in r["picks"]:
        parts.append(" %d:%s;" % (f, report.pick_kind(t)))
    return "".join(parts)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--player", default="greedy")
    ap.add_argument("--runs", type=int, default=200)
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--toe-fix", action="store_true")
    ap.add_argument("--mult-cap", type=int, default=0)
    a = ap.parse_args()
    cmd = [os.path.join(HERE, "catwiz-sim"), "--player", a.player, "--runs", str(a.runs),
           "--seed", str(a.seed), "--dump"] + (["--toe-fix"] if a.toe_fix else [])
    variant = []
    if a.toe_fix:
        variant.append("toefix")
    if a.mult_cap:
        cmd += ["--mult-cap", str(a.mult_cap)]
        variant.append("multcap=%d" % a.mult_cap)
    c_lines = subprocess.run(cmd, capture_output=True, text=True, check=True).stdout.split("\n")
    seeds = [a.seed * 100000 + n for n in range(a.runs)]
    with multiprocessing.Pool(8) as pool:
        py_lines = pool.map(line, [(s, a.player, ",".join(variant)) for s in seeds],
                            chunksize=1)
    bad = 0
    for n, p in enumerate(py_lines):
        c = c_lines[n] if n < len(c_lines) else ""
        if c.strip() != p.strip():
            bad += 1
            if bad <= 3:
                print("differs:\n  py %s\n  c  %s" % (p, c))
    print("%s: %d runs, %d differ" % (a.player, a.runs, bad))


if __name__ == "__main__":
    main()
