#!/usr/bin/env python3
"""How people play Catwiz, from the anonymous play records (tools/phone/catwiz.json "telemetry",
Tisple's web/telemetry.js) the VPS keeps (tools/telemetry/receiver.py): plain tables of sessions
and play time, how far runs get, deaths, quits, fight lengths and picks.

    python3 tools/telemetry/report.py                  fetch over ssh, every record
    python3 tools/telemetry/report.py --file x.jsonl   a copy already here
    --since 2026-11-03   posts from that day (UTC) on
    --via pages,phone    only from those origins ("test" is a test page's)
    --build TEXT         only builds containing TEXT
    --save x.jsonl       keep the fetched copy

A session is a browser tab (its sid); a run is from run_start to run_end, a quit or the next
run_start. Seconds are wall seconds (t, the page's clock); "game s" are the emulated machine's,
which stop while the page is hidden. Names come from the game's source (content/enemies.tsp,
encounters.tsp, the catalog by tools/sim/catalog.py) as this checkout has them: records from an
older build may name a reordered row wrong.
"""

import argparse
import json
import os
import re
import statistics
import subprocess
import sys
from collections import Counter, defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
HOST = "root@45.77.123.14"
KEY = os.path.expanduser("~/.ssh/gauche_roomd_ed25519")
REMOTE = "/var/lib/catwiz-telemetry/events.jsonl"

PHASES = ["rolling", "player", "acting", "enemies", "won", "lost", "reward", "start"]
STEPS = ["cards", "charms", "rest", "door"]  # state.Pick
PAGES = ["none", "bag", "rules", "log", "won"]
NOTHING = 255
UP = 128


# ---- names, from the game's source

def source(path):
    with open(os.path.join(REPO, "game", "content", path)) as f:
        return f.read()


def enemy_names():
    text = source("enemies.tsp")
    table = text[text.index("(const ENEMIES"):]
    return [n.title() for n in re.findall(r':name "([^"]*)"', table)]


def fight_rows():
    """each fight row's zone and enemies (their kinds), as encounters.tsp FIGHTS has them"""
    text = source("encounters.tsp")
    table = text[text.index("(const FIGHTS"):]
    rows = []
    for part in table.split("(make Fight")[1:]:
        zone = re.search(r":zone Zone\.(\w+)", part).group(1)
        count = int(re.search(r":count (\d+)", part).group(1))
        enemies = re.findall(r":enemy en\.(\w+)", part)[:count]
        rows.append((zone, enemies))
    return rows


def catalog_names():
    sys.path.insert(0, os.path.join(REPO, "tools", "sim"))
    try:
        import catalog
        return ({r["id"]: r["name"] for r in catalog.faces()},
                {r["id"]: r["name"] for r in catalog.charms()})
    except Exception as err:  # names are a help, not a need
        print(f"(no catalog names: {err})", file=sys.stderr)
        return {}, {}


ENEMIES = enemy_names()
FIGHTS = fight_rows()
FACES, CHARMS = catalog_names()


def enemy(kind):
    return ENEMIES[kind] if 0 <= kind < len(ENEMIES) else f"#{kind}"


def fight_name(row):
    if 0 <= row < len(FIGHTS):
        zone, _ = FIGHTS[row]
        return f"{row} {zone}"
    return f"{row} ?"


def face(c):
    return FACES.get(c, f"face {c}")


# ---- reading

def fetch(args):
    if args.file:
        with open(args.file) as f:
            return f.read()
    out = subprocess.run(["ssh", "-i", KEY, "-o", "BatchMode=yes", HOST,
                          f"cat {REMOTE} 2>/dev/null || true"],
                         capture_output=True, text=True, check=True).stdout
    if args.save:
        with open(args.save, "w") as f:
            f.write(out)
    return out


def sessions_from(text, args):
    """sid -> its records in order, each with load, where, build"""
    vias = set(args.via.split(",")) if args.via else None
    by_sid = defaultdict(list)
    for line in text.splitlines():
        try:
            post = json.loads(line)
        except ValueError:
            continue
        if args.since and post.get("at", "") < args.since:
            continue
        if vias and post.get("via") not in vias:
            continue
        if args.build and args.build not in post.get("build", ""):
            continue
        for rec in post["recs"]:
            rec = dict(rec, load=post["load"], where=post["where"], build=post["build"],
                       seq=post["seq"])
            by_sid[post["sid"]].append(rec)
    for recs in by_sid.values():
        recs.sort(key=lambda r: (r["load"], r["t"], r["seq"]))
    return by_sid


# ---- tables

def table(title, head, rows):
    print(f"\n{title}")
    if not rows:
        print("  (none)")
        return
    rows = [[str(x) for x in r] for r in rows]
    widths = [max(len(head[i]), *(len(r[i]) for r in rows)) for i in range(len(head))]
    line = lambda r: "  " + "  ".join(x.rjust(w) if i else x.ljust(w)
                                      for i, (x, w) in enumerate(zip(r, widths)))
    print(line(head))
    print("  " + "  ".join("-" * w for w in widths))
    for r in rows:
        print(line(r))


def med(xs):
    return f"{statistics.median(xs):.0f}" if xs else "-"


def mean(xs):
    return f"{statistics.mean(xs):.1f}" if xs else "-"


def minutes(s):
    return f"{s / 60:.1f}"


def runs_of(recs):
    """the runs of a session: {end (run_end rec or None), quit (rec or None), fights:
    [(fight_start, fight_end or None)], picks}"""
    runs = []
    run = None
    fight = None
    last_pre = None
    for i, r in enumerate(recs):
        if e_is_echo(r, last_pre):
            continue
        if r["e"] == "pick":
            last_pre = r.get("pre")
        e = r["e"]
        if e == "run_start":
            run = {"fights": [], "picks": [], "end": None, "quit": None, "load": r["load"]}
            runs.append(run)
            fight = None
            continue
        if run and r["load"] != run["load"]:
            run = None  # a reload: that run went with the page it was on (its quit is there)
        if run is None:
            continue
        if e == "fight_start":
            fight = [r, None]
            run["fights"].append(fight)
        elif e == "fight_end" and fight:
            fight[1] = r
        elif e == "pick":
            run["picks"].append(r)
        elif e == "run_end":
            run["end"] = r
            run = None
        elif e == "quit" and not any(x["e"] == "back" for x in recs[i + 1:]):
            run["quit"] = r
    return runs


def e_is_echo(r, last_pre):
    """a pick that repeats the one before it: as the next reward starts, the game clears its
    fresh flag a few frames before it sets the step (battle/reward step), so the last step taken
    shows again for a moment and its end fires once more, the same offer and pick"""
    return r["e"] == "pick" and last_pre is not None and r.get("pre") == last_pre


def report(by_sid):
    all_runs = [run for recs in by_sid.values() for run in runs_of(recs)]

    # sessions, runs and play time
    rows = []
    for where in sorted({r["where"] for recs in by_sid.values() for r in recs}) + ["all"]:
        sids = [s for s, recs in by_sid.items() if where == "all" or recs[0]["where"] == where]
        wall, game = [], []
        for s in sids:
            last = {}
            for r in by_sid[s]:
                last[r["load"]] = r
            wall.append(sum(r["t"] for r in last.values()))
            game.append(sum(r["gt"] for r in last.values()))
        runs = [run for s in sids for run in runs_of(by_sid[s])]
        rows.append([where, len(sids), sum(len({r["load"] for r in by_sid[s]}) for s in sids),
                     len(runs), sum(1 for r in runs if r["end"] and r["end"]["v"]["run_won"]),
                     minutes(sum(wall)), med([w / 60 for w in wall]) if wall else "-",
                     minutes(sum(game))])
    table("Sessions, runs and play time (minutes)",
          ["where", "sessions", "loads", "runs", "won", "wall min", "median", "game min"], rows)

    # runs by how far they got
    far = defaultdict(Counter)
    for run in all_runs:
        stage = max((f[0]["v"]["stage"] for f in run["fights"]), default=-1)
        if run["end"]:
            how = "won" if run["end"]["v"]["run_won"] else "died"
        elif run["quit"]:
            how = "quit"
        else:
            how = "open"
        far[stage][how] += 1
    rows = []
    for stage in sorted(far):
        c = far[stage]
        rows.append(["before a fight" if stage < 0 else f"fight {stage + 1}", sum(c.values()),
                     c["died"], c["quit"], c["won"], c["open"]])
    table("Runs by the furthest fight", ["reached", "runs", "died", "quit", "won", "no end yet"], rows)

    # deaths by fight and enemy
    fights = defaultdict(lambda: [0, 0])
    killers = Counter()
    for run in all_runs:
        for start, end in run["fights"]:
            key = (start["v"]["stage"], start["v"]["fight"])
            fights[key][0] += 1
            if end and not end["v"]["won"]:
                fights[key][1] += 1
                v = end["v"]
                for i in range(1, 4):
                    if v["alive"][i]:
                        killers[enemy(v["kinds"][i])] += 1
    rows = []
    for (stage, row), (n, died) in sorted(fights.items()):
        names = ", ".join(enemy_label(row))
        rows.append([f"{stage + 1}", fight_name(row), names, n, died, f"{100 * died / n:.0f}%"])
    table("Deaths by fight", ["fight", "row zone", "enemies", "fought", "died", "rate"], rows)
    table("Enemies standing when she died", ["enemy", "deaths"], killers.most_common())

    # quits by screen
    quits = Counter()
    for recs in by_sid.values():
        last = recs[-1]
        if last["e"] != "quit":
            quits["(no quit sent: still open, or lost)"] += 1
            continue
        quits[where_quit(last.get("v"))] += 1
    table("Where sessions ended (the last quit)", ["screen", "sessions"], quits.most_common())

    # fight length
    lengths = defaultdict(lambda: ([], [], [], 0))
    for run in all_runs:
        for start, end in run["fights"]:
            if not end:
                continue
            key = (start["v"]["stage"], start["v"]["fight"])
            turns, wall, game, won = lengths[key]
            turns.append(end["v"]["turn"])
            wall.append(end["t"] - start["t"])
            game.append(end["gt"] - start["gt"])
            lengths[key] = (turns, wall, game, won + (1 if end["v"]["won"] else 0))
    rows = []
    for (stage, row), (turns, wall, game, won) in sorted(lengths.items()):
        rows.append([stage + 1, fight_name(row), len(turns), won, med(turns), mean(turns),
                     med(wall), med(game)])
    table("Fight length (finished fights)",
          ["fight", "row zone", "fights", "won", "turns med", "mean", "wall s med", "game s med"], rows)

    # picks
    offered = defaultdict(Counter)
    taken = defaultdict(Counter)
    passed = Counter()
    for run in all_runs:
        for p in run["picks"]:
            step, choices, took = pick_taken(p)
            if step is None:
                continue
            for c in choices:
                offered[step][c] += 1
            if took is None:
                passed[step] += 1
            else:
                taken[step][took] += 1
    for k, step in enumerate(STEPS):
        if not offered[step] and not passed[step]:
            continue
        rows = []
        for c, n in sorted(offered[step].items(), key=lambda kv: (-taken[step][kv[0]], -kv[1])):
            rows.append([c, n, taken[step][c], f"{100 * taken[step][c] / n:.0f}%"])
        rows.append(["(skipped)", "", passed[step], ""])
        table(f"Picks: {step}", ["choice", "offered", "taken", "rate"], rows)


def enemy_label(row):
    if 0 <= row < len(FIGHTS):
        return [n.lower() for n in FIGHTS[row][1]]
    return []


def where_quit(v):
    if not v:
        return "loading (the game not running yet)"
    if v["screen"] == 0:
        return "title"
    phase = PHASES[v["phase"]] if v["phase"] < len(PHASES) else "?"
    at = f"fight {v['stage'] + 1}"
    if v["page"] not in (0, 4) and phase != "reward":
        return f"{at}: page {PAGES[v['page']]}"
    if phase == "reward":
        return f"after {at}: {STEPS[v['step']] if v['step'] < len(STEPS) else '?'}"
    if phase == "start":
        return f"{at}: loading it"
    if phase in ("won", "lost") or v["page"] == 4:
        return f"{at}: {'run won' if v['page'] == 4 else phase}"
    return f"{at}: in the fight"


def same(a, b, key):
    return a.get(key) == b.get(key)


def pick_taken(p):
    """(step, offered names, taken name or None) of a pick record: what was taken is told by
    what changed between the step's start (entry) and its end (v)"""
    pre, entry, v = p.get("pre"), p.get("entry"), p["v"]
    if not pre or not entry:
        return None, [], None
    step = STEPS[pre["step"]] if pre["step"] < len(STEPS) else "?"
    n = pre["choices"]
    offer, slots = pre["offer"][:n], pre["offer_slot"][:n]
    picked = pre["picked"] if pre["picked"] < n else None
    if step == "cards":
        names = [f"+1 level, slot {s + 1}" if c >= UP else face(c) for c, s in zip(offer, slots)]
        changed = not (same(entry, v, "items") and same(entry, v, "levels"))
        return step, names, names[picked] if changed and picked is not None else None
    if step == "charms":
        names = [CHARMS.get(c, f"charm {c}") for c in offer]
        changed = not same(entry, v, "charms")
        return step, names, names[picked] if changed and picked is not None else None
    if step == "rest":
        # the rest: she heals to full as it starts, then +1 on a face (or a skip)
        names = [f"slot {s + 1}" for s in slots]
        changed = not same(entry, v, "levels")
        return step, names, names[picked] if changed and picked is not None else None
    if step == "door":
        names = [fight_name(c) for c in offer]
        took = fight_name(v["fight"]) if v["fight"] in offer else None
        return step, names, took
    return None, [], None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--file")
    parser.add_argument("--save")
    parser.add_argument("--since")
    parser.add_argument("--via")
    parser.add_argument("--build")
    args = parser.parse_args()
    by_sid = sessions_from(fetch(args), args)
    if not by_sid:
        print("no records")
        return
    report(by_sid)


if __name__ == "__main__":
    main()
