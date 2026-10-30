"""The game's tables as the sim uses them: faces, dice, enemies, moves, fights, the hero, the
effect constants and the few engine numbers (tray size, bag size, re-rolls), all read from
the .tsp files by tsp.py. A content set is a list of directories, earlier ones first:

    game      game/content: the game today (a bag of dice)
    proposal  tools/sim/proposal over game/content: the item-slot model, fights 1-10 and the
              boss (five identical dice whose faces are six item slots)
    bag       tools/sim/proposal_bag over game/content: the same fights in the bag model, kept
              to compare
"""

import os
import re

import tsp

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
GAME = os.path.join(REPO, "game")
DIRS = {
    "game": [],
    "proposal": [os.path.join(HERE, "proposal")],
    "bag": [os.path.join(HERE, "proposal_bag")],
}
SLOTS = ["wand", "fluff", "star", "book", "curse", "trick", "food", "junk"]


def slot_index(slot):
    """the face a slot's item sits on: the sixth holds tricks, or food (a variant)"""
    return 5 if slot == "food" else SLOTS.index(slot)


class Face:
    """A row of the faces, items or moves table. An item (the item model) adds slot and step
    (its number grows by step a level)."""

    __slots__ = ("row", "name", "text", "effect", "amount", "cost", "aim", "upgrade", "slot",
                 "step", "combo", "combo_n")

    def __init__(self, row, d):
        self.row = row
        self.name = d.get("name", "")  # an enemy move (the proposal's ac.Move) has none of
        self.text = d["text"]  # name, cost and upgrade
        self.effect = d["effect"]
        self.amount = d["amount"]
        self.cost = d.get("cost", 0)
        self.aim = d["aim"]
        self.upgrade = d.get("upgrade", tsp.NOTHING)
        self.slot = d.get("slot")
        self.step = d.get("step", 0)
        self.combo = d.get("combo", "none")
        self.combo_n = d.get("combo_n", 0)


class Kind:
    """An enemy kind. The proposals add calls (the kind its summon brings), then (what it
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
    """A fight: its enemies, its reward (the bag model: two dice; the item model: three
    cards), whether a nap follows it, the fight the player may take instead (the elite doors),
    the type upgrade it offers (the bag proposal) and the charms it offers (the item model)."""

    __slots__ = ("enemies", "offers", "nap", "other", "zone", "upgrade", "cards", "charms")

    def __init__(self, d):
        self.enemies = [s["enemy"] for s in d["spots"][: d["count"]]]
        self.offers = []
        self.nap = d.get("nap", False)
        self.other = d.get("other", tsp.NOTHING)
        self.zone = d.get("zone", "")
        self.upgrade = None
        self.cards = []
        self.charms = []


class Rules:
    def __init__(self, dirs):
        c = tsp.Content(dirs + [GAME])
        self.model = "items" if c.path("content/items") else "bag"
        enemies = c.module("content/enemies")
        effects = c.module("content/effects")
        enc = c.module("content/encounters")
        state = c.module("state")
        self.die_names = {}
        self.hand = state.consts["HAND"]
        if self.model == "items":
            items = c.module("content/items")
            self.faces = [Face(i, d) for i, d in enumerate(items.consts["ITEMS"])]
            self.face_row = {k: v for k, v in items.consts.items() if isinstance(v, int)}
            self.start_items = list(items.consts["STARTING_ITEMS"])
            self.item_most = items.consts["ITEM_MOST"]
            self.junk_row = self.face_row.get("HAIRBALL")
            self.start_dice = [self.start_items] * self.hand
        else:
            faces = c.module("content/faces")
            self.faces = [Face(i, d) for i, d in enumerate(faces.consts["FACES"])]
            self.face_row = {k: v for k, v in faces.consts.items() if isinstance(v, int)}
            self.start_dice = [d["faces"] for d in faces.consts["STARTING_DICE"]]
            for d in faces.consts["STARTING_DICE"]:
                self.die_names[tuple(d["faces"])] = d["name"]
        self.kinds = [Kind(i, d) for i, d in enumerate(enemies.consts["ENEMIES"])]
        moves = enemies.consts.get("MOVES") or c.module("content/moves").consts["MOVES"]
        self.moves = [Face(i, d) for i, d in enumerate(moves)]
        self.hero_hp = enc.consts["HERO"]["hp"]
        self.fights = [Fight(f) for f in enc.consts["FIGHTS"]]
        self.fight_count = enc.consts["FIGHT_COUNT"]
        self.nap_heal = enc.consts.get("NAP_HEAL", 0)
        self.junk_die = None
        if self.model == "items":
            self.charm_table = enc.consts["CHARMS"]
            self.charm_row = {k[6:]: v for k, v in enc.consts.items() if k.startswith("CHARM_")}
            for i, f in enumerate(self.fights):
                f.cards = list(enc.consts["FIGHT_CARDS"][i])
                f.charms = [k for k in enc.consts["FIGHT_CHARMS"][i] if k != tsp.NOTHING]
            self.die_names[tuple(self.start_items)] = "ITEM DIE"
        else:
            # the game: one pair of dice for every fight (OFFER_DICE); the bag proposal a
            # table of dice (DICE), each fight's pair (FIGHT_OFFERS) and type (FIGHT_UPGRADES)
            dice_table = enc.consts.get("DICE") or enc.consts["OFFER_DICE"]
            for d in dice_table:
                self.die_names[tuple(d["faces"])] = d["name"]
            pairs = enc.consts.get("FIGHT_OFFERS")
            ups = enc.consts.get("FIGHT_UPGRADES")
            for i, f in enumerate(self.fights):
                pair = pairs[i] if pairs else [0, 1]
                f.offers = [list(dice_table[k]["faces"]) for k in pair]
                f.upgrade = ups[i] if ups else None
            junk = enc.consts.get("JUNK_DIE")
            if junk is not None:
                self.junk_die = dice_table[junk]["faces"]
        self.type_most = enc.consts.get("TYPE_MOST", 3)
        self.fx = effects.consts
        self.most_mana = effects.consts["MOST_MANA"]
        self.bag_most = state.consts["BAG_MOST"]
        self.die_faces = state.consts["DIE_FACES"]
        # engine literals, read from the engine source so they are not retyped
        self.rerolls = tsp.number_after(
            os.path.join(GAME, "battle/turn.tsp"), r"\(set state\.rerolls (\d+)\)"
        )
        self.proposal = len(dirs) > 1  # a proposal over the game's content
        self.swap = self.proposal  # the bag model: a new die into a full bag takes a die's place
        self.upgrade = "type" if self.proposal else "single"  # see rewards.upgrade_options
        self.variant = {}  # variants.apply's parts
        self.no_type_up = set()  # face types that take no type upgrade
        self.levels = "slot"  # the item model: levels belong to the slot (or "item")

    def die_name(self, faces):
        return self.die_names.get(tuple(faces), "DIE")

    def face_names(self, faces):
        return " ".join(self.faces[r].name for r in faces)


def load(which, variant=""):
    """a content set by name (see the top), with a variant (variants.py)"""
    import variants

    rules = Rules(DIRS[which] + [os.path.join(GAME, "content")])
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
