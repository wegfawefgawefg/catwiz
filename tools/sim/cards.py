"""The chain and combo cards of the proposal (docs/balance.md): what a play sets off after it
lands (dice that come back), mimic, and what a fallen enemy leaves (flea circus, haunted).
Functions of a battle b (rules.Battle); c/cards.c is the C sim's copy."""

import items


def ru():
    import rules  # here: rules imports items, which imports this module

    return rules


def mimic(b, t, times):
    """she does the picked enemy's shown move herself, times times: its hit on it (a hit-all
    on them all), its shield on her, its call a kitten, its cheer or growing a waiting plus,
    its healing on her, its curse on it, its reflect her thorns"""
    r = ru()
    H = r.HERO
    m = b.R.moves[b.move[t]]
    e, n = m.effect, m.amount
    for _ in range(times):
        if not any(b.alive[1:]):
            return
        if not b.alive[t]:
            t = b.next_standing(t)
            if t == r.NOTHING or t == H:
                return
        if e in ("hit", "hit2"):
            if m.aim == "all":
                for i in range(1, r.ACTORS):
                    if b.alive[i]:
                        b.strike(H, i, n)
            else:
                b.strike(H, t, n)
                if e == "hit2" and b.alive[t]:
                    b.strike(H, t, n)
        elif e == "shield":
            b.add(H, r.SHIELD, n)
        elif e in ("heal", "mend"):
            b.heal(H, n)
        elif e == "summon":
            st = b.st[H]
            st[r.KITTENS] = min(items.kittens_most(b), st[r.KITTENS] + n)
        elif e in ("cheer", "grow"):
            st = b.st[H]
            st[r.PLUS] = items.sat(st[r.PLUS] + n)
            st[r.PLUS_LEFT] = max(st[r.PLUS_LEFT], 1)
        elif e in ("fleas", "wet"):
            b.curse(e, t, n)
        elif e == "reflect":
            st = b.st[H]
            st[r.THORNS] = max(st[r.THORNS], n)


def fallen(b, who, fleas, haunt):
    """an enemy fell (rules.die): a flea circus's fleas jump to the next one, doubled; a
    haunted one hits every other enemy"""
    r = ru()
    st = b.st
    if fleas:
        j = b.next_standing(who)
        if j != r.NOTHING and j != r.HERO:
            st[j][r.POISON] = items.sat(fleas * 2)
            st[j][r.FLEA_TURNS] = b.R.fx["FLEA_TURNS"]
            st[j][r.CIRCUS] = 1
    if haunt:
        wand = b.wand_on
        b.wand_on = False
        for i in range(1, r.ACTORS):
            if i != who and b.alive[i]:
                b.strike(r.HERO, i, haunt)
        b.wand_on = wand


REFRESH_MOST = 255  # refreshes a turn at most (a byte; the variant refresh=N tries a limit)


def after_play(b, s):
    """after a die's face landed (and the battle checked who stands): what it set off. Its
    die comes back as it is (finishing swat felled one); or dice come back to be rolled again:
    every die (a wand hit on a red dot; nine lives when every die is used, once a fight) or
    big stretch's few (the used ones first, then dice that cannot be played). A battle with
    no random numbers (a search's copy) leaves them waiting in b.back."""
    r = ru()
    swat, dot, stretch = b.swat_back, b.dot_fired, b.stretch
    b.swat_back = False
    b.dot_fired = False
    b.stretch = 0
    if b.result is not None:
        return
    if swat:
        b.played[s] = False
    spots = [x for x in range(b.hand_n) if b.tray[x] != r.NOTHING]
    mask = 0
    if dot:
        for x in spots:
            mask |= 1 << x
    if stretch:
        picked = [x for x in spots if b.played[x]] + [
            x for x in spots if not b.played[x] and not b.can_play(x)]
        for x in picked[:stretch]:
            mask |= 1 << x
    st = b.st[r.HERO]
    if not mask and "nine" in b.charms and not st[r.NINE] and all(b.played[x] for x in spots):
        st[r.NINE] = 1
        for x in spots:
            mask |= 1 << x
    if not mask:
        return
    most = int(b.R.variant.get("refresh") or b.R.fx.get("REFRESH_MOST", REFRESH_MOST))
    if b.refreshes >= most:
        return
    b.refreshes += 1
    for x in spots:
        if mask >> x & 1:
            b.played[x] = False
    b.back |= mask
    if b.rng is not None:
        roll_back(b)


def roll_back(b):
    """the dice waiting in b.back are rolled (a hairball on one is coughed up first)"""
    r = ru()
    if b.clogged:
        for x in range(b.hand_n):
            if b.back >> x & 1 and b.hand[x] == b.R.junk_row:
                slot = b.face_of[x]
                if slot in b.clogged:
                    faces = list(b.dice[0])
                    faces[slot] = b.clogged.pop(slot)
                    b.dice = [faces] * len(b.dice)
    for x in range(b.hand_n):
        if b.back >> x & 1:
            f = (b.rng.byte() * 6) >> 8
            b.face_of[x] = f
            b.hand[x] = b.dice[b.tray[x]][f]
            if b.hand[x] == b.R.junk_row:
                b.hair = items.sat(b.hair + 1)
    b.back = 0
    if b.log is not None:
        b.say("  ALL BACK: " + ", ".join(
            b.R.faces[b.hand[x]].name for x in range(b.hand_n) if not b.played[x]))


