"""The game's tables as the sim uses them: faces, dice, enemies, moves, fights, the hero, the
effect constants and the few engine numbers (tray size, bag size, re-rolls), all read from
the .tsp files by tsp.py. A content set is a list of directories, earlier ones first: the
proposal (tools/sim/proposal) over game/content.
"""

import os
import re

import tsp

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
GAME = os.path.join(REPO, "game")
PROPOSAL = os.path.join(HERE, "proposal")


class Face:
    """A row of the faces or moves table."""

    __slots__ = ("row", "name", "text", "effect", "amount", "cost", "aim", "upgrade")

    def __init__(self, row, d):
        self.row = row
        self.name = d.get("name", "")  # an enemy move (the proposal's ac.Move) has none of
        self.text = d["text"]  # name, cost and upgrade
        self.effect = d["effect"]
        self.amount = d["amount"]
        self.cost = d.get("cost", 0)
        self.aim = d["aim"]
        self.upgrade = d.get("upgrade", tsp.NOTHING)


class Kind:
    """An enemy kind. The proposal adds calls (the kind its summon brings), then (what it
    becomes when beaten: the possum getting up, the boss's next phase) and stall (it skips its
    move after taking this much in one of the hero's turns); the game's own enemies have none."""

    __slots__ = ("row", "name", "hp", "ward", "first", "count", "calls", "then", "stall")

    def __init__(self, row, d):
        self.row = row
        self.name = d["name"]
        self.hp = d["hp"]
        self.ward = d["ward"]
        self.first = d["first_move"]
        self.count = d["move_count"]
        self.calls = d.get("calls", tsp.NOTHING)
        self.then = d.get("then", tsp.NOTHING)
        self.stall = d.get("stall", 0)


class Fight:
    """A fight: its enemies, the two dice it offers after, whether a nap follows it (heal or
    upgrade), and the fight the player may take instead (the proposal's elite doors)."""

    __slots__ = ("enemies", "offers", "nap", "other", "zone")

    def __init__(self, d, offers):
        self.enemies = [s["enemy"] for s in d["spots"][: d["count"]]]
        self.offers = offers
        self.nap = d.get("nap", False)
        self.other = d.get("other", tsp.NOTHING)
        self.zone = d.get("zone", "")


class Rules:
    def __init__(self, dirs):
        c = tsp.Content(dirs + [GAME])
        faces = c.module("content/faces")
        enemies = c.module("content/enemies")
        effects = c.module("content/effects")
        enc = c.module("content/encounters")
        statuses = c.module("content/statuses")
        state = c.module("state")
        self.faces = [Face(i, d) for i, d in enumerate(faces.consts["FACES"])]
        self.face_row = {k: v for k, v in faces.consts.items() if isinstance(v, int)}
        self.start_dice = [d["faces"] for d in faces.consts["STARTING_DICE"]]
        self.die_names = {}
        for d in faces.consts["STARTING_DICE"]:
            self.die_names[tuple(d["faces"])] = d["name"]
        self.kinds = [Kind(i, d) for i, d in enumerate(enemies.consts["ENEMIES"])]
        moves = enemies.consts.get("MOVES") or c.module("content/moves").consts["MOVES"]
        self.moves = [Face(i, d) for i, d in enumerate(moves)]
        self.hero_hp = enc.consts["HERO"]["hp"]
        # the dice a fight offers: the game has one pair for every fight (OFFER_DICE); the
        # proposal a table of dice (DICE) and each fight's pair (FIGHT_OFFERS)
        dice_table = enc.consts.get("DICE") or enc.consts["OFFER_DICE"]
        for d in dice_table:
            self.die_names[tuple(d["faces"])] = d["name"]
        pairs = enc.consts.get("FIGHT_OFFERS")
        fights = enc.consts["FIGHTS"]
        self.fights = []
        for i, f in enumerate(fights):
            pair = pairs[i] if pairs else [0, 1]
            self.fights.append(Fight(f, [dice_table[k]["faces"] for k in pair]))
        self.fight_count = enc.consts["FIGHT_COUNT"]
        self.fx = effects.consts
        self.most_mana = effects.consts["MOST_MANA"]
        self.hand = state.consts["HAND"]
        self.bag_most = state.consts["BAG_MOST"]
        self.die_faces = state.consts["DIE_FACES"]
        self.nap_heal = enc.consts.get("NAP_HEAL", 0)
        junk = enc.consts.get("JUNK_DIE")
        self.junk_die = dice_table[junk]["faces"] if junk is not None else None
        # engine literals, read from the engine source so they are not retyped
        self.rerolls = tsp.number_after(
            os.path.join(GAME, "battle/turn.tsp"), r"\(set state\.rerolls (\d+)\)"
        )
        self.status_names = statuses.enums["Status"]
        self.proposal = any(os.path.abspath(d) == PROPOSAL for d in dirs)
        self.swap = self.proposal  # a new die into a full bag takes a die's place
        self.upgrade = "type" if self.proposal else "single"  # see rewards.upgrade_options
        self.variant = {}  # variants.apply's parts

    def die_name(self, faces):
        return self.die_names.get(tuple(faces), "DIE")

    def face_names(self, faces):
        return " ".join(self.faces[r].name for r in faces)


def load(which, variant=""):
    """'game' for game/content alone, 'proposal' for the proposal over it; variant: see
    variants.py"""
    import variants

    if which == "proposal":
        rules = Rules([PROPOSAL, os.path.join(GAME, "content")])
    else:
        rules = Rules([os.path.join(GAME, "content")])
    return variants.apply(rules, variant)


def check_engine(rules):
    """The engine rules the sim copies by hand (rules.py), checked against the source where a
    grep can: if one of these fails the engine changed and rules.py needs a look."""
    with open(os.path.join(GAME, "battle/bag.tsp")) as f:
        bag = f.read()
    with open(os.path.join(GAME, "content/statuses.tsp")) as f:
        statuses = f.read()
    problems = []
    if "(& (random.byte) 7)" not in bag:
        problems.append("bag.draw_one no longer draws with a random 0-7 until below n")
    if not re.search(r"\(set d \(>> d 1\)\)", statuses):
        problems.append("statuses.dealt no longer halves for wet")
    return problems
