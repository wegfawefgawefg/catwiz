"""The numbers a batch of runs gives: per fight (reached, won, hit points in, lost and healed,
turns), how far runs get, and what the winners took and played."""

import re
from collections import Counter


def pick_kind(text):
    """a reward in words, folded: which die or item came in, which face or slot went up"""
    text = re.sub(r" \(for .*\)", "", text)
    text = re.sub(r" for .*", "", text)
    text = re.sub(r"^upgrade [^:]*: ", "upgrade ", text)
    text = re.sub(r"^nap: upgrade [^:]*: ", "nap: upgrade ", text)
    text = re.sub(r" \(.*\)$", "", text)
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
        k = max(1, len(won))
        rows.append({
            "reached": len(here) / n,
            "won": len(won) / len(here),
            "hp_in": sum(x["hp_in"] for x in here) / len(here),
            "lost": sum(x["lost"] for x in won) / k,
            "healed": sum(x["healed"] for x in won) / k,
            "net": sum(x["hp_in"] - x["hp_out"] for x in won) / k,
            "turns": sum(x["turns"] for x in won) / k,
            "turns_max": max([x["turns"] for x in won] or [0]),
        })
    deaths = Counter(len(r["fights"]) for r in results if not r["won"])
    wins = [r for r in results if r["won"]]
    return {"rows": rows, "deaths": deaths, "win": len(wins) / n,
            "hp_end": sum(r["fights"][-1]["hp_out"] for r in wins) / max(1, len(wins))}


def base_runs(results):
    wins = [r for r in results if r["won"]]
    return wins if wins else results


def print_report(rules, pname, results, seconds, by_fight=False):
    n = len(results)
    s = summary(rules, results)
    print("\n%s: %d runs in %.1f s (%.0f runs/s)" % (pname, n, seconds, n / max(seconds, 1e-9)))
    print("fight  reached  won    hp in  hp lost  healed  net  turns (max)")
    for f, row in enumerate(s["rows"]):
        if row is None:
            print("%5d  -" % (f + 1))
            continue
        print("%5d  %6.0f%%  %4.0f%%  %5.1f  %7.1f  %6.1f  %4.1f  %5.1f (%d)" % (
            f + 1, 100 * row["reached"], 100 * row["won"], row["hp_in"], row["lost"],
            row["healed"], row["net"], row["turns"], row["turns_max"]))
    print("runs won: %.0f%%, hp at the end of won runs %.1f" % (100 * s["win"], s["hp_end"]))
    selfs = sum(1 for r in results if any(x["self_hits"] for x in r["fights"]))
    if selfs:
        print("runs where zoomies outlasted the enemies and hit the cat: %.0f%%" % (100 * selfs / n))
    base = base_runs(results)
    which = "won" if any(r["won"] for r in results) else "all"
    sizes = Counter(r["bag"] for r in base)
    print("dice at the end (%s runs): %s" % (which, ", ".join(
        "%d: %.0f%%" % (k, 100 * v / len(base)) for k, v in sorted(sizes.items()))))
    lost = sorted(s["deaths"].items())
    print("runs lost in fight: " + ", ".join("%d: %.0f%%" % (k, 100 * v / n) for k, v in lost))
    picks = Counter()
    for r in base:
        for p in set(pick_kind(t) for _, t in r["picks"]):
            picks[p] += 1
    if picks:
        print("taken in %s runs (share of runs):" % which)
        for p, c in picks.most_common(16):
            print("  %3.0f%%  %s" % (100 * c / len(base), p))
    if by_fight:
        print("taken, fight by fight (%s runs):" % which)
        per = {}
        for r in base:
            for f, t in r["picks"]:
                per.setdefault(f, Counter())[pick_kind(t)] += 1
        for f in sorted(per):
            print("  after %2d: %s" % (f, ", ".join(
                "%s %.0f%%" % (k, 100 * v / len(base)) for k, v in per[f].most_common(6))))
    key = "faces" if any(r.get("faces") for r in results) else "use"
    use = {}
    for r in results:
        for name, (seen, played) in r[key].items():
            u = use.setdefault(name, [0, 0])
            u[0] += seen
            u[1] += played
    print("%s played when rolled:" % ("faces" if key == "faces" else "dice"))
    for name, (seen, played) in sorted(use.items(), key=lambda x: -x[1][1] / max(1, x[1][0])):
        print("  %3.0f%%  %s (%d)" % (100 * played / max(1, seen), name, seen))
