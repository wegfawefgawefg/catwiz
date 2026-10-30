"""The bag proposal's new hero spells and its hairball dice (tools/sim/proposal_bag), and its
type upgrades. The bag model is kept to compare with the item-slot model (items.py)."""

# the face types a type upgrade raises: the free faces, by effect
FAMILIES = {"hit": "wand", "shield": "fluff", "heal": "tuna", "mana": "star", "fleas": "fleas",
            "plus": "plus"}
JUNK_MOST = 2  # hairball dice in the bag at once, at most, past BAG_MOST


def family(face):
    if face.cost:
        return None
    return FAMILIES.get(face.effect)


def type_bonus(charms):
    """+1 to every face of a type for each "type:<family>" the run took"""
    return {fam: charms.count("type:" + fam) for fam in FAMILIES.values()}


def apply(b, effect, by, target, n):
    """the bag proposal's effects; false for an effect it does not know"""
    import rules as ru

    st = b.st
    if effect == "mark":
        b.add(target, ru.MARK, n)
    elif effect == "laser":
        st[target][ru.LASER] = 1
    elif effect == "knock":
        st[target][ru.SHIELD] = 0
        b.strike(by, target, n)
    elif effect == "catnip":
        b.add(ru.HERO, ru.CATNIP, n)
    elif effect == "thorns":
        b.add(ru.HERO, ru.SHIELD, n)
        st[ru.HERO][ru.THORNS] = b.R.fx["TRAP_BACK"]
    elif effect == "static":
        n += st[ru.HERO][ru.FLUFFS]
        for i in range(1, ru.ACTORS):
            if b.alive[i]:
                b.strike(by, i, n)
    elif effect == "ward":
        b.add(target, ru.WARD, n)
    elif effect == "junk":
        # hairball dice into the bag's draw pile, for this fight
        for _ in range(n):
            if len(b.dice) < b.R.bag_most + JUNK_MOST:
                b.dice.append(b.R.junk_die)
                b.in_draw.append(True)
                b.held.append(ru.NOTHING)
    elif effect == "cough":
        # the hairball played is coughed up: out of the bag for this fight
        if b.last_played != ru.NOTHING:
            b.held[b.last_played] = ru.GONE
    else:
        return False
    return True
