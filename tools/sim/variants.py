"""Rule variants to compare against, on top of a content set: run.py --variant "a,b=c,...".

    bag=N            the bag holds N dice at most (the game: BAG_MOST, 6)
    extra=a+b        start with these weak dice too (EXTRA_DICE below), for bigger bags
    spell=NAME       the starting star die's spell face (its 4th) is face NAME instead
    upgrade=KIND     single (one face of one die: the game today), type (+1 to every face of a
                     type, all run: the proposal) or typebag (every face of a type in the bag
                     one step up its upgrade row)
    noswap           a new die into a full bag is refused (the game today) instead of swapped
    dogwitch         the Dog Witch shape: no bag; five identical dice whose six faces are six
                     item slots (SLOTS); a reward upgrades a slot (every die at once), swaps the
                     spell or curse slot, or takes a charm (CHARMS)

The extra dice and the slots are the sim's own experiment dice, named from the content's face
constants; the charms are played by rules.py (Battle charms).
"""

EXTRA_DICE = {
    # a plain die: the basics at their lowest, and one lint
    "plain": ("PLAIN DIE", ["WAND_2", "WAND_2", "FLUFF_2", "FLUFF_2", "TUNA_2", "LINT"]),
    # a die that is mostly lint
    "lint": ("LINT DIE", ["LINT", "LINT", "LINT", "LINT", "WAND_2", "FLUFF_2"]),
    # a plain wand die
    "wand": ("PLAIN WAND DIE", ["WAND_2", "WAND_2", "WAND_2", "WAND_2", "WAND_2", "LINT"]),
}

# the dogwitch variant's item slots, in face order: wand, fluff, tuna, star, spell, curse
SLOTS = ["WAND_2", "FLUFF_2", "TUNA_2", "STAR", "ZOOMIES", "HISS"]

# charms: (name, what it does). rules.Battle reads them by name
CHARMS = [
    ("pocket", "one more re-roll a turn"),
    ("nightlight", "start each fight with 2 mana"),
    ("fishbone", "4 more hit points at most (and 4 back)"),
    ("bell", "a ward pip at the start of each fight"),
    ("pillow", "shield 2 at the start of each turn"),
]


def row(rules, name):
    # the game's content names some faces differently from the proposal's (gem is star)
    aliases = {"FLUFF_2": "KIBBLE_2", "TUNA_2": "BONE_2", "STAR": "GEM", "STAR_2": "GEM_2"}
    if name in rules.face_row:
        return rules.face_row[name]
    return rules.face_row[aliases[name]]


def apply(rules, spec):
    """rules changed by the variant spec (a string), in place; gives the list of its parts"""
    rules.variant = {}
    if not spec:
        return rules
    for part in spec.split(","):
        key, _, value = part.partition("=")
        rules.variant[key] = value
        if key == "bag":
            rules.bag_most = int(value)
        elif key == "extra":
            for name in value.split("+"):
                die_name, faces = EXTRA_DICE[name]
                rows = [row(rules, f) for f in faces]
                rules.start_dice.append(rows)
                rules.die_names[tuple(rows)] = die_name
            rules.bag_most = max(rules.bag_most, len(rules.start_dice))
        elif key == "spell":
            star = list(rules.start_dice[3])
            star[3] = row(rules, value)
            rules.start_dice[3] = star
            rules.die_names[tuple(star)] = "STAR DIE"
        elif key == "upgrade":
            rules.upgrade = value  # single, type or typebag: rewards.upgrade_options
        elif key == "noswap":
            rules.swap = False
        elif key == "dogwitch":
            slots = [row(rules, f) for f in SLOTS]
            rules.start_dice = [slots] * rules.hand
            rules.die_names[tuple(slots)] = "ITEM DIE"
            rules.bag_most = rules.hand
        else:
            raise ValueError("no such variant: " + key)
    return rules
