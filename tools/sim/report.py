"""The numbers a batch of runs gives: per fight (reached, won, hit points in and lost, turns),
how far runs get, and what the winners' bags and rewards were."""

import re
from collections import Counter


def pick_kind(text):
    """a reward in words, folded: which die came in, which face was upgraded"""
    text = re.sub(r" for .*", "", text)
    text = re.sub(r"^upgrade [^:]*: ", "upgrade ", text)
    text = re.sub(r"^nap: upgrade [^:]*: ", "nap: upgrade ", text)
    text = re.sub(r"heal to \d+", "heal", text)
    return text


def summary(rules, results):
    n = len(results)
    rows = []
    for f in range(rules.fight_count):
        here = [r["fights"][f] for r in results if len(r["fights"]) > f]
        if not here:
            rows.append(None)
            continue
        won = [x for x in here if x["won"]]
        rows.append({
            "reached": len(here) / n,
            "won": len(won) / len(here),
            "hp_in": sum(x["hp_in"] for x in here) / len(here),
            "lost": sum(x["lost"] for x in won) / max(1, len(won)),
            "net": sum(x["hp_in"] - x["hp_out"] for x in won) / max(1, len(won)),
            "turns": sum(x["turns"] for x in won) / max(1, len(won)),
            "turns_max": max([x["turns"] for x in won] or [0]),
        })
    deaths = Counter(len(r["fights"]) for r in results if not r["won"])
    wins = [r for r in results if r["won"]]
    return {"rows": rows, "deaths": deaths, "win": len(wins) / n,
            "hp_end": sum(r["fights"][-1]["hp_out"] for r in wins) / max(1, len(wins))}


def print_report(rules, pname, results, seconds):
    n = len(results)
    s = summary(rules, results)
    print("\n%s: %d runs in %.1f s (%.0f runs/s)" % (pname, n, seconds, n / max(seconds, 1e-9)))
    print("fight  reached  won    hp in  hp lost  net  turns (max)")
    for f, row in enumerate(s["rows"]):
        if row is None:
            print("%5d  -" % (f + 1))
            continue
        print("%5d  %6.0f%%  %4.0f%%  %5.1f  %7.1f  %4.1f  %5.1f (%d)" % (
            f + 1, 100 * row["reached"], 100 * row["won"], row["hp_in"], row["lost"], row["net"],
            row["turns"], row["turns_max"]))
    print("runs won: %.0f%%, hp at the end of won runs %.1f" % (100 * s["win"], s["hp_end"]))
    lost = sorted(s["deaths"].items())
    print("runs lost in fight: " + ", ".join("%d: %.0f%%" % (k, 100 * v / n) for k, v in lost))
    wins = [r for r in results if r["won"]]
    base = wins if wins else results
    picks = Counter()
    for r in base:
        for p in set(pick_kind(x) for x in r["picks"]):
            picks[p] += 1
    if picks:
        print("rewards in %s runs (share of runs taking it):" % ("won" if wins else "all"))
        for p, c in picks.most_common(12):
            print("  %3.0f%%  %s" % (100 * c / len(base), p))
    use = {}
    for r in results:
        for name, (seen, played) in r["use"].items():
            u = use.setdefault(name, [0, 0])
            u[0] += seen
            u[1] += played
    print("dice played when in the tray:")
    for name, (seen, played) in sorted(use.items(), key=lambda x: -x[1][1] / max(1, x[1][0])):
        print("  %3.0f%%  %s (%d turns)" % (100 * played / max(1, seen), name, seen))
