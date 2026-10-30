"""Checks the sim against the real game: boots build/catwiz.dsk in Tisple's machine headless
(never a window), plays fights 1 and 2 key by key, and after every die, re-roll and enemy
turn compares the machine's memory (hit points, statuses, mana, who stands) with the sim fed
the same dice. Separately it predicts the machine's own dice from its random seed
(random.byte's xorshift), to check the bag and the rolls too.

    python3 tools/sim/validate.py                 # 6 runs, greedy and random players
    python3 tools/sim/validate.py --starts 1000,1017 --policy random --verbose

It builds the disk with a listing into a scratch folder (addresses of the state come from the
listing, so a rebuild that moves them is fine). It takes the Mockingboard (an Apple rom from
~/.local/share/tisple/roms): without the card the speaker's noise effects draw random bytes
too, and the dice prediction would drift (the rules check does not care).
"""

import argparse
import os
import random
import re
import subprocess
import sys
import tempfile

import content
import policy as po
import rules as ru
from rules import Battle, HERO, NOTHING

TISPLE = os.path.expanduser(os.environ.get("TISPLE", "~/Coding/LangDev/tisple/build/tisple"))
ROMS = os.path.expanduser("~/.local/share/tisple/roms")
PHASES = ["rolling", "player", "acting", "enemies", "won", "lost", "reward"]
FIELDS = ["alive", "kind", "figure", "hp", "max_hp", "col", "home", "lift", "move", "moves_made"]
NAMES = ["phase", "hand", "played", "rerolls", "target", "turn", "fight", "bag", "end_wait",
         "screen", "hitstop", "selected", "picked"]


class XorShift:
    """lib/random.tsp: 16-bit xorshift 7, 9, 8"""

    def __init__(self, seed):
        self.seed = seed

    def byte(self):
        s = self.seed
        s ^= (s << 7) & 0xFFFF
        s ^= s >> 9
        s ^= (s << 8) & 0xFFFF
        self.seed = s
        return s & 0xFF


class Machine:
    def __init__(self, disk, listing, work, card):
        self.disk = disk
        self.work = work
        self.frame = 0
        self.snap = None
        self.card = card
        self.addr = {}
        for line in open(listing):
            m = re.search(r"\$([0-9A-F]{2,4})(?:,[XY])?\s+; (state\.[a-z_]+|random\.seed)\s", line)
            if m and m.group(2) not in self.addr:
                self.addr[m.group(2)] = int(m.group(1), 16)
        self.addr["state.actors"] = 0x0680
        self.addr["state.stacks"] = 0x0600
        self.addr["state.dice"] = 0x0708
        self.addr["state.in_draw"] = 0x072C
        self.addr["state.tray_die"] = 0x0732
        self.calls = 0

    def run(self, frames, key=None):
        """frames more frames from where it stands, key pressed at once; then its memory"""
        self.calls += 1
        out_snap = os.path.join(self.work, "s%d.snap" % (self.calls % 2))
        cmd = [TISPLE, "machine", "--disk", self.disk, "--frames", str(frames),
               "--save-snapshot", out_snap]
        if self.card:
            cmd += ["--rom", os.path.join(ROMS, "Apple2e_Enhanced.rom"),
                    "--disk-rom", os.path.join(ROMS, "DISK2.rom"), "--mockingboard", "4"]
        if self.snap:
            cmd += ["--load-snapshot", self.snap]
        if key is not None:
            cmd += ["--keys", "%df:%s" % (self.frame + 1, key)]
        peeks = [("state.actors", 40), ("state.stacks", 64), ("state.dice", 36),
                 ("state.in_draw", 6), ("state.tray_die", 5), ("random.seed", 2)]
        for name in NAMES:
            peeks.append(("state." + name, 5 if name in ("hand", "played") else 1))
        for name, n in peeks:
            cmd += ["--peek", "0x%04X:%d" % (self.addr[name], n)]
        text = subprocess.run(cmd, capture_output=True, text=True).stdout
        self.frame += frames
        self.snap = out_snap
        rows = [r for r in text.splitlines() if r.startswith("peek ")]
        mem = {}
        for (name, n), row in zip(peeks, rows):
            bytes_ = [int(x, 16) for x in row.split(":")[1].split("(")[0].split()]
            mem[name.split(".")[1]] = bytes_[:n]
        a = mem["actors"]
        m = {"actors": {f: a[4 * i: 4 * i + 4] for i, f in enumerate(FIELDS)}}
        m["stacks"] = [mem["stacks"][16 * w: 16 * w + 16] for w in range(4)]
        m["seed"] = mem["seed"][0] | (mem["seed"][1] << 8)
        for k in ("dice", "in_draw", "tray_die", "hand", "played"):
            m[k] = mem[k]
        for k in NAMES:
            if k not in ("hand", "played"):
                m[k] = mem[k][0]
        m["phase"] = PHASES[m["phase"]] if m["phase"] < len(PHASES) else m["phase"]
        return m

    def until(self, test, step=6, most=3000):
        m = self.run(step)
        n = step
        while not test(m):
            m = self.run(step)
            n += step
            if n > most:
                raise RuntimeError("the machine never got there (phase %s)" % m["phase"])
        return m


def waiting_for_hero(m):
    return m["phase"] == "player" and m["end_wait"] == 0 and m["hitstop"] == 0


def settled(m):
    return waiting_for_hero(m) or m["phase"] in ("won", "lost", "reward")


class Check:
    def __init__(self, verbose):
        self.verbose = verbose
        self.compared = 0
        self.bad = []
        self.rng_ok = 0
        self.rng_bad = 0
        self.self_hits = 0  # zoomies outlasting the enemies and hitting the cat

    def compare(self, what, b, m):
        """the sim's battle b against the machine's memory m"""
        self.compared += 1
        diffs = []
        for i in range(4):
            alive = bool(m["actors"]["alive"][i])
            if alive != b.alive[i]:
                diffs.append("actor %d alive: game %s (hp %d, phase %s) sim %s (hp %d)" % (
                    i, alive, m["actors"]["hp"][i], m["phase"], b.alive[i], b.hp[i]))
                continue
            if not alive:
                continue
            if m["actors"]["hp"][i] != b.hp[i]:
                diffs.append("actor %d hp: game %d sim %d" % (i, m["actors"]["hp"][i], b.hp[i]))
            for s in range(11):
                if m["stacks"][i][s] != b.st[i][s]:
                    diffs.append("actor %d %s: game %d sim %d" % (
                        i, ru.STATUSES[s], m["stacks"][i][s], b.st[i][s]))
            if i > 0 and m["actors"]["move"][i] != b.move[i]:
                diffs.append("actor %d move: game %d sim %d" % (i, m["actors"]["move"][i], b.move[i]))
        if diffs:
            self.bad.append((what, diffs))
            print("MISMATCH after %s: %s" % (what, "; ".join(diffs)))
        elif self.verbose:
            print("  ok after %s: hp %s" % (what, [b.hp[i] if b.alive[i] else "-" for i in range(4)]))

    def dice(self, what, predicted, m, slots):
        same = all(predicted[s] == m["hand"][s] for s in slots)
        if same:
            self.rng_ok += 1
        else:
            self.rng_bad += 1
            print("dice differ after %s: predicted %s, game %s" % (
                what, [predicted[s] for s in slots], [m["hand"][s] for s in slots]))


def load_turn(b, m):
    """the machine's new tray into the sim (start_round, but the machine's dice)"""
    b.tray = list(m["tray_die"])
    b.hand = list(m["hand"])
    b.played = [bool(x) for x in m["played"]]
    b.in_draw = [bool(x) for x in m["in_draw"][: len(b.dice)]]
    b.target = m["target"]


def predict_deal(b, seed):
    c = b.clone()
    c.exact = True
    c.rng = XorShift(seed)
    c.turn -= 1
    c.start_round()
    return c


def keys_for(b, s, t):
    face = b.R.faces[b.hand[s]]
    k = str(s + 1)
    if face.aim == "foe":
        return [k, "ZXC"[t - 1]]
    return [k, k]


def play_game(start, pname, rules, check, card, work, disk, listing, seed):
    mach = Machine(disk, listing, work, card)
    mach.run(start)
    m = mach.run(2, "RETURN")
    prng = random.Random(seed)
    pol = po.POLICIES[pname](rules, prng)
    fight = 0
    while True:
        m = mach.until(waiting_for_hero)
        dice = [m["dice"][6 * d: 6 * d + 6] for d in range(m["bag"])]
        kinds = [m["actors"]["kind"][i] for i in range(1, 4) if m["actors"]["alive"][i]]
        b = Battle(rules, dice, m["actors"]["hp"][0], kinds, None)
        b.turn = 1
        b.rerolls = rules.rerolls
        load_turn(b, m)
        check.compare("fight %d start" % (fight + 1), b, m)
        while True:
            # the policy picks on a copy; the sim and the machine both carry it out. After a
            # re-roll it picks again with the new dice
            moves = plan_turn(pol, b)
            if moves and moves[-1] == "reroll":
                moves_again = True
            else:
                moves_again = False
            for mv in moves:
                seed_before = m["seed"]
                if mv == "reroll":
                    pred = b.clone()
                    pred.exact = True
                    pred.rng = XorShift(seed_before)
                    pred.reroll()
                    left = m["rerolls"]
                    if check.verbose:
                        print("    before R: phase %s end_wait %d rerolls %d played %s hand %s mana %d" % (
                            m["phase"], m["end_wait"], m["rerolls"], m["played"], m["hand"],
                            m["stacks"][0][8]))
                    mach.run(1, "R")
                    mach.until(lambda x: x["rerolls"] < left, step=1)
                    # the dice have rolled (the turn may be about to end by itself)
                    m = mach.until(lambda x: x["phase"] != "rolling", step=2)
                    slots = [s for s in range(rules.hand) if not b.played[s]]
                    check.dice("re-roll", pred.hand, m, slots)
                    b.rerolls -= 1
                    b.hand = list(m["hand"])
                    check.compare("re-roll", b, m)
                    continue
                s, t = mv
                name = rules.faces[b.hand[s]].name
                # each key waits until the game has taken it: a key pressed before the last
                # was read would replace it
                k1, k2 = keys_for(b, s, t)
                mach.run(1, k1)
                mach.until(lambda x: x["selected"] == s, step=1)
                mach.run(1, k2)
                m = mach.until(lambda x: x["played"][s] or x["phase"] != "player", step=1)
                hits = b.self_hits
                b.play(s, t)
                check.self_hits += b.self_hits - hits
                m = mach.until(lambda x: x["phase"] != "acting" and x["hitstop"] == 0)
                if m["phase"] in ("won", "lost"):
                    m = mach.run(2)  # past the song's copy from aux: see below
                check.compare("%s on %s" % (name, t), b, m)
                if b.result is not None:
                    break
            if moves_again and b.result is None:
                continue
            if b.result is None:
                seed_before = m["seed"]
                if m["phase"] == "player" and m["end_wait"] == 0:
                    mach.run(1, "E")
                    mach.until(lambda x: x["phase"] != "player", step=1)
                b.end_turn()
                m = mach.until(settled)
                if m["phase"] in ("won", "lost"):
                    # the end of a fight starts a song, copied in from aux memory with aux
                    # switched in for reading: a peek in that copy reads aux. A frame later
                    # it is done (seen once: the cat read as 0 hp in a won fight)
                    m = mach.run(2)
                if b.result is None:
                    pred = predict_deal(b, seed_before)
                    b.turn += 1
                    st = b.st[HERO]
                    st[ru.SHIELD] = 0
                    st[ru.BOX] = 0
                    b.rerolls = rules.rerolls
                    load_turn(b, m)
                    check.dice("deal, turn %d" % b.turn, pred.hand, m, range(rules.hand))
                    if pred.tray != b.tray:
                        print("tray differs: predicted %s, game %s" % (pred.tray, b.tray))
                check.compare("enemies' turn %d" % (b.turn - 1), b, m)

            if b.result is not None:
                break
        game_result = "won" if m["phase"] in ("won", "reward") else m["phase"]
        if game_result != b.result:
            check.bad.append(("result", ["game %s sim %s" % (game_result, b.result)]))
            print("RESULT differs: game %s sim %s" % (game_result, b.result))
        print("  start %d fight %d: %s in %d turns, hero hp %d" % (
            start, fight + 1, b.result, b.turn, b.hp[HERO]))
        if b.result != "won" or fight + 1 >= rules.fight_count:
            return
        # the reward: the second new die (the gold wand die), as the run's reward
        m = mach.until(lambda x: x["phase"] == "reward", step=10)
        mach.run(1, "2")
        mach.until(lambda x: x["picked"] == 1, step=1)
        mach.run(1, "2")
        mach.until(lambda x: x["phase"] != "reward", step=1)
        fight += 1


def plan_turn(pol, b):
    """the policy's turn played on a copy, read back as its moves; one move at a time is
    re-planned on the real state, so the copy only lends the choice of the first"""
    moves = []
    c = b.clone()
    c.rng = po.SampleRng(random.Random(len(moves)))
    record = []
    orig_play = c.play
    orig_reroll = c.reroll

    def play(s, t=None):
        record.append((s, t))
        orig_play(s, t)

    def reroll():
        record.append("reroll")
        orig_reroll()

    c.play = play
    c.reroll = reroll
    pol.turn(c)
    # up to the first re-roll: after it the copy's dice are made up
    for mv in record:
        moves.append(mv)
        if mv == "reroll":
            break
    return moves


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--starts", default="1000,1009,1023,1040,1066,1101")
    ap.add_argument("--policy", default="greedy,random")
    ap.add_argument("--no-card", action="store_true")
    ap.add_argument("--verbose", action="store_true")
    ap.add_argument("--first-seed", type=int, default=0)
    a = ap.parse_args()
    rules = content.load("game")
    work = tempfile.mkdtemp(prefix="catwiz-validate-")
    disk = os.path.join(work, "catwiz.dsk")
    listing = os.path.join(work, "catwiz.asm")
    with open(listing, "w") as f:
        subprocess.run([TISPLE, "build", "--disk", disk, "--asm"], cwd=content.REPO, stdout=f,
                       check=True)
    check = Check(a.verbose)
    pols = a.policy.split(",")
    for n, start in enumerate(int(x) for x in a.starts.split(",")):
        pname = pols[n % len(pols)]
        print("start frame %d, %s player" % (start, pname))
        play_game(start, pname, rules, check, not a.no_card, work, disk, listing,
                  a.first_seed + n)
    print("\n%d comparisons, %d mismatched; dice predicted from the seed: %d right, %d wrong" % (
        check.compared, len(check.bad), check.rng_ok, check.rng_bad))
    print("zoomies that hit the cat after the last enemy fell: %d" % check.self_hits)
    sys.exit(1 if check.bad else 0)


if __name__ == "__main__":
    main()
