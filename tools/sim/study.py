"""The comparisons in docs/balance.md, one line a variant: win rates by policy, where runs end,
hit points at the last fight, turns a fight, and what the winners ended with.

    python3 tools/sim/study.py bagsize     # starting bags of 5-8 dice (the bag model)
    python3 tools/sim/study.py upgrades    # single-face, type and type-in-bag upgrades
    python3 tools/sim/study.py heal        # tuna faces and heal tension, both models
    python3 tools/sim/study.py items       # the item model's own choices
    python3 tools/sim/study.py tricks      # +1 against x2: which trick won runs held, by fight

Strong runs are slow (a few a second on 8 processes); --runs sets them, greedy and random
take three times as many.
"""

import argparse
from collections import Counter

import content
import report
import run

STUDIES = {
    "bagsize": [
        ("game", ""), ("game", "bag=10,extra=plain"), ("game", "bag=10,extra=plain+lint"),
        ("game", "bag=10,extra=plain+lint+wand"),
        ("bag", ""), ("bag", "bag=10"), ("bag", "bag=10,extra=plain"),
        ("bag", "bag=10,extra=plain+lint"), ("bag", "bag=10,extra=plain+lint+wand"),
    ],
    "upgrades": [
        ("bag", "upgrade=single"), ("bag", ""), ("bag", "anytype"), ("bag", "upgrade=typebag"),
        ("proposal", ""), ("proposal", "itembound"), ("proposal", "twodoor"),
    ],
    "heal": [
        ("bag", ""), ("bag", "tunaup=0"), ("bag", "tuna=1"), ("bag", "tuna=0,offerheal=0"),
        ("proposal", ""), ("proposal", "food"),
    ],
    "items": [
        ("proposal", ""), ("proposal", "base=1"), ("proposal", "start=TIMES"),
        ("proposal", "start=COPYCAT"), ("proposal", "nocharms"), ("proposal", "itembound"),
        ("proposal", "twodoor"), ("proposal", "food"),
    ],
}


def line(which, variant, pname, results, rules):
    s = report.summary(rules, results)
    deaths = s["deaths"]
    n = len(results)
    ended = sorted(deaths.items())
    median = None
    total = 0
    for f, c in ended:
        total += c
        if total * 2 >= n and median is None:
            median = f
    last = [r["fights"][-1] for r in results if len(r["fights"]) == rules.fight_count]
    hp_last = sum(x["hp_in"] for x in last) / max(1, len(last))
    won = [r for r in results if r["won"]]
    turns = [x["turns"] for r in results for x in r["fights"] if x["won"]]
    bag = Counter(r["bag"] for r in (won or results))
    return "%-9s %-28s %-7s won %3.0f%%  died at fight %-3s  hp at last fight %4.1f  turns %.1f  dice %s" % (
        which, variant or "-", pname, 100 * s["win"], median or "-", hp_last,
        sum(turns) / max(1, len(turns)),
        " ".join("%d:%.0f%%" % (k, 100 * v / max(1, len(won or results))) for k, v in sorted(bag.items())))


def picks_of(results, kinds):
    c = Counter()
    won = [r for r in results if r["won"]]
    for r in won:
        for _, t in r["picks"]:
            for k in kinds:
                if t.startswith(k) or ("+1" in t and k in t):
                    c[k] += 1
    return won, c


def tricks(runs):
    """which trick the won runs ended with, and how the strong player's picks went by fight"""
    for pname in ("greedy", "strong"):
        results = run.run_many("proposal", "", pname, runs * (3 if pname == "greedy" else 1))
        won = [r for r in results if r["won"]] or results
        end = Counter()
        for r in won:
            trick = r["kit"].split(", ")[5].rstrip("+")
            end[trick] += 1
        print("%s: %d runs, %d won; the trick at the end: %s" % (
            pname, len(results), len([r for r in results if r["won"]]),
            ", ".join("%s %.0f%%" % (k, 100 * v / len(won)) for k, v in end.most_common())))
        per = {}
        for r in won:
            for f, t in r["picks"]:
                for k in ("PLUS ONE", "TIMES TWO", "COPYCAT", "CATNIP", "KNEAD", "+1 TRICK"):
                    if t.startswith(k):
                        per.setdefault(f, Counter())[k] += 1
        for f in sorted(per):
            print("  after fight %2d: %s" % (f, ", ".join(
                "%s %.0f%%" % (k, 100 * v / len(won)) for k, v in per[f].most_common())))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("study", choices=sorted(list(STUDIES) + ["tricks"]))
    ap.add_argument("--runs", type=int, default=96)
    ap.add_argument("--policies", default="random,greedy,strong")
    a = ap.parse_args()
    if a.study == "tricks":
        tricks(a.runs)
        return
    for which, variant in STUDIES[a.study]:
        rules = content.load(which, variant)
        for pname in a.policies.split(","):
            n = a.runs if pname == "strong" else 3 * a.runs
            results = run.run_many(which, variant, pname, n)
            print(line(which, variant, pname, results, rules), flush=True)


if __name__ == "__main__":
    main()
