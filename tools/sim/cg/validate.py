"""Checks the catalog sim against the real game, step by step. It builds a test copy of the game
(a scratch folder: the repo's game/ with its starting faces, a charm held from the start, the
first fight and the seed changed, battle.tsp's and items.tsp's test switches), boots it in
Tisple's machine headless with the Mockingboard (never a window), and plays it key by key. At
every step (a die played, a paw flip's turn, a re-roll, the turn's end with the enemies' turn
and the next roll) it reads the machine's whole battle state (build/catwiz.vars.json gives the
addresses), has the sim (catwiz-check) take the same step from that state with the game's own
random numbers (lib/random's xorshift from the machine's seed), and compares the state after:
hit points, who stands, every stack, the dice, the re-rolls, the turn's flags and the seed.

    python3 tools/sim/cg/validate.py --kit "COIN FLIP,THICK FUR,STAR,MANA BURN,LEECH,HAT TRICK"
    python3 tools/sim/cg/validate.py --suite            the cards of docs/sim-explore.md

A mismatch prints both states' differing fields and the step; --keep leaves the build.
"""

import argparse
import json
import os
import random
import re
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
SIM = os.path.dirname(HERE)
REPO = os.path.dirname(os.path.dirname(SIM))
sys.path.insert(0, SIM)
import catalog  # noqa: E402

TISPLE = os.path.expanduser(os.environ.get("TISPLE", "~/Coding/LangDev/tisple/build/tisple"))
ROMS = os.path.expanduser("~/.local/share/tisple/roms")
CHECK = os.path.join(HERE, "catwiz-check")
SLOTS = ["wand", "fluff", "star", "book", "curse", "trick"]
PHASE = {"rolling": 0, "player": 1, "acting": 2, "enemies": 3, "won": 4, "lost": 5,
         "reward": 6, "start": 7}

# the machine's state: (field for catwiz-check, the let's name in vars.json, how many)
PEEKS = [
    ("items", "state.items", 6), ("levels", "state.levels", 6),
    ("held_n", "content/charms.held_n", 1), ("ids", "content/items.ids", 20),
    ("charm_counts", "state.charms", 4), ("kind_amount", "content/charms.kind_amount", 29),
    ("kind_count", "content/charms.kind_count", 29), ("mana_most", "state.mana_most", 1),
    ("hp", "state.actors.hp", 4), ("max_hp", "state.actors.max_hp", 4),
    ("alive", "state.actors.alive", 4), ("kind", "state.actors.kind", 4),
    ("move", "state.actors.move", 4), ("moves_made", "state.actors.moves_made", 4),
    ("stacks", "state.stacks", 120), ("dice_n", "state.dice_n", 1),
    ("face_of", "state.face_of", 6), ("hand", "state.hand", 6), ("played", "state.played", 6),
    ("held", "state.held", 6), ("clogged", "state.clogged", 6), ("rerolls", "state.rerolls", 1),
    ("rerolled", "state.rerolled", 1), ("combo", "state.combo", 6),
    ("last_face", "state.last_face", 1), ("last_on", "state.last_on", 1),
    ("last_played", "state.last_played", 1), ("wand_on", "state.wand_on", 1),
    ("back_due", "state.back_due", 1), ("booked", "state.booked", 1),
    ("lucky", "state.lucky", 1), ("nap_die", "state.nap_die", 1),
    ("refreshes", "state.refreshes", 1), ("risen", "state.risen", 1),
    ("target", "state.target", 1), ("three", "content/effects.three", 1),
    ("counts", "content/effects.counts", 1), ("blocked", "content/hooks.blocked", 1),
    ("lost", "battle/hit.lost", 1), ("echo_next", "content/play.echo_next", 1),
    ("mimicked_v", "content/play.mimicked_v", 1), ("fight_extra", "content/foes.fight_extra", 1),
    ("kept", "state.kept", 1), ("spent4", "state.spent", 4), ("seed", "random.seed", 2),
    ("phase", "state.phase", 1), ("end_wait", "state.end_wait", 1),
    ("selected", "state.selected", 1), ("turn", "state.turn", 1), ("fight", "state.fight", 1),
]
# compared after a step (the rest are inputs, or change only between fights)
COMPARE = ["hp", "max_hp", "alive", "kind", "move", "moves_made", "stacks", "face_of", "hand",
           "played", "held", "clogged", "rerolls", "rerolled", "combo", "last_face", "last_on",
           "booked", "refreshes", "kept", "spent", "seed_lo", "seed_hi", "target"]
STATUS = None


def statuses():
    text = open(os.path.join(REPO, "game", "content", "statuses.tsp")).read()
    text = re.sub(r";[^\n]*", "", text)
    body = text[text.index("(enum Status (") + len("(enum Status ("):]
    return body[: body.index(")")].split()


def build(work, kit, charm, stage, seed):
    """the test copy: the repo's game/ with the kit, the charm, the first fight and the seed"""
    if os.path.exists(work):
        shutil.rmtree(work)
    os.makedirs(work)
    shutil.copytree(os.path.join(REPO, "game"), os.path.join(work, "game"))
    shutil.copy(os.path.join(REPO, "tisple.project"), work)
    os.makedirs(os.path.join(work, "build"))
    items = os.path.join(work, "game", "content", "items.tsp")
    text = open(items).read()
    start = text.index("(const STARTING_ITEMS")
    ids = list(re.finditer(r"\(catalog\.id \w+\)", text[start:]))[:6]
    for k, m in reversed(list(enumerate(ids))):
        a, b = start + m.start(), start + m.end()
        text = text[:a] + "(catalog.id %s)" % kit[k] + text[b:]
    open(items, "w").write(text)
    bt = os.path.join(work, "game", "battle", "battle.tsp")
    text = open(bt).read()
    text = text.replace("(const START_STAGE u8 0)", "(const START_STAGE u8 %d)" % stage)
    text = text.replace("(const START_FIGHT u8 0)", "(const START_FIGHT u8 %d)" % stage)
    if charm:
        text = text.replace("(const START_CHARM u8 state.NOTHING)",
                            "(const START_CHARM u8 %d)" % charm)
    text = text.replace("(const SEED u16 0)", "(const SEED u16 %d)" % seed)
    open(bt, "w").write(text)
    r = subprocess.run([TISPLE, "build"], cwd=work, capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError("the test build failed:\n" + r.stdout[-2000:] + r.stderr[-2000:])
    return json.load(open(os.path.join(work, "build", "catwiz.vars.json")))["vars"]


class Machine:
    def __init__(self, work, vars_):
        self.work = work
        self.vars = vars_
        self.frame = 0
        self.snap = None
        self.calls = 0

    def run(self, frames, keys=()):
        """frames more from where it stands, keys pressed a few frames apart; then the state"""
        self.calls += 1
        frames = max(frames, 6 * len(keys) + 4)  # every key pressed within this run
        out = os.path.join(self.work, "s%d.snap" % (self.calls % 2))
        cmd = [TISPLE, "machine", "--disk", os.path.join(self.work, "build", "catwiz.dsk"),
               "--disk2", os.path.join(self.work, "build", "catwiz2.dsk"),
               "--frames", str(frames), "--save-snapshot", out,
               "--rom", os.path.join(ROMS, "Apple2e_Enhanced.rom"), "--mockingboard", "5"]
        if self.snap:
            cmd += ["--load-snapshot", self.snap]
        if keys:
            cmd += ["--keys", ",".join("%df:%s" % (self.frame + 2 + 6 * i, k)
                                       for i, k in enumerate(keys))]
        for _, name, n in PEEKS:
            cmd += ["--peek", "%d:%d" % (self.vars[name]["at"], n)]
        text = subprocess.run(cmd, capture_output=True, text=True).stdout
        self.frame += frames
        self.snap = out
        rows = [r for r in text.splitlines() if r.startswith("peek ")]
        m = {}
        for (field, _, n), row in zip(PEEKS, rows):
            m[field] = [int(x, 16) for x in row.split(":")[1].split("(")[0].split()][:n]
        return m

    def read(self, frames):
        """the state after frames more, read when two frames running agree: a peek reads the
        memory switched in, and the drawing code switches aux memory in (RAMRD, ALTZP)"""
        m = self.run(frames)
        for _ in range(12):
            m2 = self.run(1)
            same = all(m2[k] == m[k] for k in m if k != "end_wait")
            if same and (m["phase"][0] != PHASE["player"] or sane(m)):
                return m
            m = m2
        return {**m, "phase": [255]}  # not steady: no phase a test waits for

    def wait(self, test, step=4, most=3000):
        m = self.read(step)
        n = step
        while not test(m):
            m = self.read(step)
            n += step
            if n > most:
                raise RuntimeError("the machine never got there (phase %d)" % m["phase"][0])
        return m


def sane(m):
    return (all(a in (0, 1) for a in m["alive"]) and m["alive"][0] == 1 or m["phase"][0] == 5) \
        and m["phase"][0] <= 7 and m["dice_n"][0] in (5, 6) and all(p in (0, 1) for p in m["played"])


def to_check(m):
    """the machine's state as catwiz-check's input lines"""
    d = dict(m)
    held = d["held_n"][0]
    d["charm_ids"] = (d["ids"][7:7 + held] + [0] * 4)[:4]
    d["spent"] = [sum(1 << h for h in range(4) if d["spent4"][h])]
    d["hat_id"] = [d["ids"][19]]
    d["seed_lo"] = [d["seed"][0]]
    d["seed_hi"] = [d["seed"][1]]
    d["played"] = [1 if x else 0 for x in d["played"]]
    d["clogged"] = [1 if x else 0 for x in d["clogged"]]
    out = []
    for k, v in d.items():
        if k in ("ids", "spent4", "seed", "phase", "end_wait", "selected", "turn", "fight"):
            continue
        out.append("%s %s" % (k, " ".join(map(str, v))))
    return out


def sim_step(m, action):
    lines = to_check(m) + ["action " + action]
    r = subprocess.run([CHECK], input="\n".join(lines) + "\n", capture_output=True, text=True)
    s = {}
    for row in r.stdout.splitlines():
        parts = row.split()
        s[parts[0]] = parts[1:] if parts[0] == "result" else [int(x) for x in parts[1:]]
    return s


def machine_as_check(m):
    d = {}
    for row in to_check(m):
        parts = row.split()
        d[parts[0]] = [int(x) for x in parts[1:]]
    return d


def differences(s, m, dice_n):
    out = []
    names = STATUS
    alive = m["alive"]
    for k in COMPARE:
        a, b = s[k], m[k]
        if k == "stacks":
            for i in range(120):
                who = 0 if i < 51 else 1 + (i - 51) // 23
                if who and not alive[who] and not s["alive"][who]:
                    continue
                st = i if who == 0 else (i - 51) % 23
                if a[i] != b[i]:
                    out.append("stack %s of %d: sim %d game %d" % (names[st], who, a[i], b[i]))
            continue
        if k in ("face_of", "hand", "played", "held", "clogged"):
            a, b = a[:dice_n] if k != "clogged" else a, b[:dice_n] if k != "clogged" else b
        if k in ("move", "moves_made", "kind", "hp", "max_hp"):
            a = [x for i, x in enumerate(a) if alive[i] or i == 0]
            b = [x for i, x in enumerate(b) if alive[i] or i == 0]
        if a != b:
            out.append("%s: sim %s game %s" % (k, a, b))
    return out


def play_keys(d, t, aim, hat, selected):
    """the keys that play die d (0-5) on enemy t: the die picked (unless it is), then the
    enemy's letter, or RETURN for her own and a hit-all (a paw flip turns a die picked again,
    so the die is never pressed twice); a hat trick's target is picked first, with no die"""
    digit = str(d + 1)
    letter = "ZXC"[t - 1] if t else None
    pick = [] if selected == d else [digit]
    if hat:
        return ["ESC", letter, digit, "RETURN"]
    if aim == "foe":
        return pick + [letter]
    return pick + ["RETURN"]


def run_check(kit, charm, stage, seed, steps, rng, keep, verbose, tested):
    faces = catalog.faces()
    by_const = {f["const"]: f for f in faces}
    by_name = {f["name"]: f for f in faces}
    kit_consts = [by_name[n]["const"] if n in by_name else n for n in kit]
    charm_const = None  # its catalog id: battle.tsp has no catalog import
    if charm:
        cs = {c["name"]: c["id"] for c in catalog.charms()}
        charm_const = cs[charm]
    work = os.path.join(tempfile.gettempdir(), "catwiz-validate-%d" % os.getpid())
    vars_ = build(work, kit_consts, charm_const, stage, seed)
    mc = Machine(work, vars_)
    m = mc.run(950)
    m = mc.run(10, ["RETURN"])
    m = mc.wait(lambda m: m["phase"][0] == PHASE["player"], step=20, most=4000)
    result = {"steps": 0, "mismatch": 0, "plays": {}, "notes": []}
    ids = {}
    for _ in range(steps):
        if m["phase"][0] != PHASE["player"]:
            break
        dice_n = m["dice_n"][0]
        kit_ids = m["items"]
        rows = m["hand"]
        playable = []
        for d in range(dice_n):
            if m["played"][d] or m["held"][d] != 255:
                continue
            r = rows[d]
            if r >= 6:
                continue
            f = faces[kit_ids[r]]
            mana = m["stacks"][STATUS.index("mana")]
            if f["slot"] == "book" and "hp" not in f["tags"] and mana < f["cost"]:
                continue
            if "hp" in f["tags"] and m["hp"][0] <= f["cost"]:
                continue
            playable.append((d, f))
        flip = m["stacks"][STATUS.index("flip")] > 0
        if m["end_wait"][0] > 0:
            action, keys = "end", []
        elif flip and playable and rng.random() < 0.5:
            d = rng.choice(playable)[0]
            action = "flip %d" % d
            keys = ([] if m["selected"][0] == d else [str(d + 1)]) + [str(d + 1)]
        elif playable and rng.random() < 0.85:
            pref = [p for p in playable if p[1]["name"] in tested] or playable
            d, f = rng.choice(pref)
            enemies = [i for i in (1, 2, 3) if m["alive"][i]]
            t = rng.choice(enemies)
            action = "play %d %d" % (d, t)
            keys = play_keys(d, t, f["aim"], f["name"] == "HAT TRICK", m["selected"][0])
            result["plays"][f["name"]] = result["plays"].get(f["name"], 0) + 1
        elif m["rerolls"][0] > 0 and m["stacks"][STATUS.index("allin")] == 0 and rng.random() < 0.6:
            action, keys = "reroll", ["R"]
        else:
            action, keys = "end", ["E"]
        s = sim_step(m, action)
        before_phase = m["phase"][0]
        if keys:
            mc.run(1, keys)
        if action.startswith("flip"):
            m2 = mc.read(8)
        else:
            if action == "end" and not keys:
                mc.wait(lambda x: x["phase"][0] != PHASE["player"], step=2, most=400)
            m2 = mc.wait(lambda x: x["phase"][0] in (PHASE["player"], PHASE["won"], PHASE["lost"],
                                                     PHASE["reward"]), step=4, most=3000)
        result["steps"] += 1
        mm = machine_as_check(m2)
        diffs = differences(s, mm, dice_n)
        res = s["result"][0]
        ph = m2["phase"][0]
        if res == "won" and ph not in (PHASE["won"], PHASE["reward"]):
            diffs.append("result: sim won, game phase %d" % ph)
        if res == "lost" and ph != PHASE["lost"]:
            diffs.append("result: sim lost, game phase %d" % ph)
        if res == "none" and ph != PHASE["player"]:
            diffs.append("result: sim goes on, game phase %d" % ph)
        if res != "none" and not diffs:
            diffs = []
        if diffs and res != "none":
            # the fight is over and both say so: the ending's drawing leaves aux memory switched
            # in, so the rest of the machine's memory is not read
            diffs = [x for x in diffs if x.startswith("result")]
        if verbose or diffs:
            print("  step %d (turn %d): %s %s" % (result["steps"], m["turn"][0], action,
                                                   "ok" if not diffs else "MISMATCH"))
        if diffs:
            result["mismatch"] += 1
            for x in diffs[:12]:
                print("     ", x)
        m = m2
        if ph != PHASE["player"]:
            break
    if not keep:
        shutil.rmtree(work, ignore_errors=True)
    return result


SUITE = [
    # (the kit, a charm, the first fight, the cards under test)
    (["SCRATCH THE ITCH", "THICK FUR", "MOON TIDE", "THUNDER PURR", "FLEA COMB", "STONE CAT"],
     None, 0, ["SCRATCH THE ITCH", "MOON TIDE", "THUNDER PURR", "FLEA COMB", "STONE CAT"]),
    (["PUDDLE SPLASH", "PUFFED UP", "OVERFLOW", "RAIN CLOUD", "DRENCHED", "ALL IN"],
     "RAIN BOOTS", 0, ["PUDDLE SPLASH", "PUFFED UP", "OVERFLOW", "RAIN CLOUD", "ALL IN"]),
    (["LOVE BITE", "CATNAP", "FORTIFY", "SHIELD BASH", "LEECH", "LAST STAND"],
     None, 1, ["LOVE BITE", "CATNAP", "SHIELD BASH", "LEECH", "LAST STAND"]),
    (["MOONBEAM", "MIRROR FUR", "RATTLE", "MANA BURN", "MANA LEECH", "SPELL ECHO"],
     "CHEAP TRICK", 0, ["MOONBEAM", "MANA BURN", "MANA LEECH", "SPELL ECHO"]),
    (["CALM PAW", "FLEA COLLAR", "PURR", "SNOWBALL", "TRIPLE HEX", "SHARPEN CLAWS"],
     "ECHO", 1, ["CALM PAW", "FLEA COLLAR", "SNOWBALL", "TRIPLE HEX", "SHARPEN CLAWS"]),
    (["COIN FLIP", "HAIRBALL WALL", "STAR CLUSTER", "BLOOD MOON", "SPOOK", "HAT TRICK"],
     None, 0, ["COIN FLIP", "HAIRBALL WALL", "BLOOD MOON", "SPOOK", "HAT TRICK"]),
    (["CHAIN BOUNCE", "LUCKY PAW", "SUNBEAM", "FRESH ROLL", "RED DOT", "PAW FLIP"],
     "PORCUPINE", 1, ["CHAIN BOUNCE", "FRESH ROLL", "RED DOT", "PAW FLIP"]),
    (["GRUDGE", "CARDBOARD BOX", "FLEA MARKET", "LULLABY", "HYPNOTIZE", "HISS"],
     "THICK SKIN", 1, ["GRUDGE", "LULLABY", "HYPNOTIZE", "HISS"]),
    (["BOX SLAM", "WARM BLANKET", "BRIGHT STAR", "LASER SHOW", "CATNIP BOMB", "DOUBLE OR NOTHING"],
     "HUNGER", 1, ["BOX SLAM", "LASER SHOW", "CATNIP BOMB", "DOUBLE OR NOTHING"]),
    (["FEATHER TOY", "THICK FUR", "LITTER STAR", "MIMIC", "GLARE", "COPYCAT"],
     "MOMENTUM", 2, ["FEATHER TOY", "MIMIC", "GLARE", "COPYCAT"]),
]


def main():
    global STATUS
    STATUS = statuses()
    ap = argparse.ArgumentParser()
    ap.add_argument("--kit", help="six faces' names, comma-separated, wand to trick")
    ap.add_argument("--charm")
    ap.add_argument("--stage", type=int, default=0)
    ap.add_argument("--seed", type=int, default=4242)
    ap.add_argument("--steps", type=int, default=60)
    ap.add_argument("--suite", action="store_true")
    ap.add_argument("--seeds", type=int, default=1, help="runs a kit, seeds seed, seed+1, ...")
    ap.add_argument("--keep", action="store_true")
    ap.add_argument("--verbose", action="store_true")
    a = ap.parse_args()
    cases = SUITE if a.suite else [(a.kit.split(","), a.charm, a.stage, a.kit.split(","))]
    total = {"steps": 0, "mismatch": 0}
    plays = {}
    for kit, charm, stage, tested in cases:
        for k in range(a.seeds):
            seed = a.seed + 17 * k
            print("kit %s; charm %s; fight %d; seed %d" % (", ".join(kit), charm, stage + 1, seed))
            r = run_check(kit, charm, stage, seed, a.steps, random.Random(seed), a.keep,
                          a.verbose, tested)
            total["steps"] += r["steps"]
            total["mismatch"] += r["mismatch"]
            for n, c in r["plays"].items():
                plays[n] = plays.get(n, 0) + c
            print("  %d steps, %d mismatched" % (r["steps"], r["mismatch"]))
    print("all: %d steps, %d mismatched" % (total["steps"], total["mismatch"]))
    print("plays:", ", ".join("%s %d" % kv for kv in sorted(plays.items())))


if __name__ == "__main__":
    main()
