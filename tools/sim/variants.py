"""Rule variants to compare against, on top of a content set: run.py --variant "a,b=c,...".

    bag=N            the bag holds N dice at most (the game: BAG_MOST, 6)
    extra=a+b        start with these weak dice too (EXTRA_DICE below), for bigger bags
    spell=NAME       the starting star die's spell face (its 4th) is face NAME instead
    upgrade=KIND     single (one face of one die: the game today), type (+1 to every face of a
                     type, all run: the proposal) or typebag (every face of a type in the bag
                     one step up its upgrade row)
    tuna=N           the starting bag keeps its first N tuna (heal) faces, the rest are fluff
    tunaup=0         tuna faces take no type upgrade
    offerheal=0      the offered dice's tuna faces are fluff of the same number
    nolives          the offered dice's nine lives faces are cardboard boxes
    anytype          a type upgrade may be any type, not only the fight's (FIGHT_UPGRADES)
    noswap           a new die into a full bag is refused (the game today) instead of swapped

the item model (--content proposal):
    itembound        levels stay with the item (a new item in a slot starts at +0), not the slot
    twodoor          a reward is: new item (one of the fight's item cards) or a level on any slot
    food             the sixth slot is food (TUNA: heal #), not tricks; trick cards are levels on it
    start=NAME       the sixth slot starts with item NAME (TIMES, ...)
    base=N           every item's number starts N more (the owner's base of 1, against 2)
    nocharms         no charms after the day's end and the elites

The extra dice and the food items are the sim's own experiment content, named from the
content's face constants.
"""

EXTRA_DICE = {
    # a plain die: the basics at their lowest, and one lint
    "plain": ("PLAIN DIE", ["WAND_2", "WAND_2", "FLUFF_2", "FLUFF_2", "TUNA_2", "LINT"]),
    # a die that is mostly lint
    "lint": ("LINT DIE", ["LINT", "LINT", "LINT", "LINT", "WAND_2", "FLUFF_2"]),
    # a plain wand die
    "wand": ("PLAIN WAND DIE", ["WAND_2", "WAND_2", "WAND_2", "WAND_2", "WAND_2", "LINT"]),
}

import content


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
        elif key == "tuna":
            keep = int(value)
            for d in range(len(rules.start_dice)):
                die = list(rules.start_dice[d])
                for k, r in enumerate(die):
                    if rules.faces[r].effect == "heal" and rules.faces[r].cost == 0:
                        if keep > 0:
                            keep -= 1
                        else:
                            die[k] = row(rules, "FLUFF_2")
                rules.die_names[tuple(die)] = rules.die_name(rules.start_dice[d])
                rules.start_dice[d] = die
        elif key == "tunaup":
            rules.no_type_up = {"tuna"}
        elif key == "offerheal":
            for fight in rules.fights:
                for o in fight.offers:
                    name = rules.die_name(o)
                    for k, r in enumerate(o):
                        face = rules.faces[r]
                        if face.effect == "heal" and face.cost == 0:
                            o[k] = row(rules, "FLUFF_%d" % face.amount)
                    rules.die_names[tuple(o)] = name
        elif key == "anytype":
            pass  # rewards.upgrade_options: every type on offer, not the fight's own
        elif key == "nolives":
            for fight in rules.fights:
                for o in fight.offers:
                    name = rules.die_name(o)
                    for k, r in enumerate(o):
                        if r == rules.face_row.get("NINE_LIVES"):
                            o[k] = row(rules, "BOX")
                    rules.die_names[tuple(o)] = name
        elif key == "noswap":
            rules.swap = False
        elif key == "itembound":
            rules.levels = "item"
        elif key == "twodoor":
            pass  # rewards.item_options
        elif key == "food":
            tuna = content.Face(len(rules.faces), {
                "name": "TUNA", "text": "HEAL #", "effect": "heal", "amount": 1, "cost": 0,
                "aim": "self", "slot": "food", "step": 1})
            rules.faces.append(tuna)
            rules.start_items[5] = tuna.row
            for fight in rules.fights:
                fight.cards = [133 if c < 128 and rules.faces[c].slot == "trick" else c
                               for c in fight.cards]
            rules.start_dice = [rules.start_items] * rules.hand
        elif key == "start":
            item = rules.face_row[value]
            slot = content.slot_index(rules.faces[item].slot)
            rules.start_items[slot] = item
            rules.start_dice = [rules.start_items] * rules.hand
        elif key == "base":
            for f in rules.faces:
                if f.slot in ("wand", "fluff", "star", "curse") and f.amount:
                    f.amount += int(value)
        elif key == "nocharms":
            for fight in rules.fights:
                fight.charms = []
        else:
            raise ValueError("no such variant: " + key)
    return rules
