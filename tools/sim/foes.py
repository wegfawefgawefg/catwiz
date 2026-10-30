"""The enemies' turn (battle/turn.tsp: end_turn, enemies_step, end_enemies; content/statuses
turn_end) and the proposals' summons. Functions of a battle b (rules.Battle)."""

import items
import rules as r  # rules imports this module: its names are read when the functions run


def summon(b, by, n):
    """PROPOSAL: n of by's kind's calls into empty spots; they wait for the next round"""
    k = b.R.kinds[b.kind[by]].calls
    for _ in range(n):
        for i in range(1, r.ACTORS):
            if not b.alive[i]:
                b.set_enemy(i, k)
                b.st[i][r.FRESH] = 1
                break


def end_turn(b):
    """the hero's statuses tick, every enemy makes its move, theirs tick; the next
    round is start_round's, for the caller (a search may stop here and look)"""
    st = b.st[r.HERO]
    items.turn_end(b)
    if b.result is not None:
        return
    bite = status_end(b, r.HERO)
    st[r.CATNIP] = 0
    st[r.SPOOK] = 0
    if bite:
        b.lose(r.HERO, bite)
    if not b.alive[r.HERO]:
        b.result = "lost"
        return
    for i in range(1, r.ACTORS):
        b.st[i][r.MARK] = 0
        if b.alive[i]:
            b.st[i][r.SHIELD] = 0
            b.st[i][r.BOX] = 0
            b.st[i][r.REFLECT] = 0
    hp_before = b.hp[r.HERO]
    for i in range(1, r.ACTORS):
        if not b.alive[i]:
            continue
        si = b.st[i]
        if si[r.FRESH]:
            continue
        if si[r.HISS]:
            si[r.HISS] = 0
            continue
        kind = b.R.kinds[b.kind[i]]
        if kind.stall and si[r.HURT] >= kind.stall:
            b.say("  %s STALLS" % kind.name)
            continue
        row = b.move[i]
        land_move(b, row, i, move_target(b, i, row))
        b.after_action()
        if b.result is not None:
            return
    for i in range(1, r.ACTORS):
        if b.alive[i]:
            bite = status_end(b, i)
            if bite:
                b.lose(i, bite)
        if b.alive[i]:
            si = b.st[i]
            si[r.HURT] = 0
            if si[r.FRESH]:
                si[r.FRESH] = 0
            else:
                next_move(b, i)
    items.enemies_done(b, b.hp[r.HERO] >= hp_before)
    if not any(b.alive[1:]):
        b.result = "won"


def status_end(b, who):
    """statuses.turn_end: wet dries, fleas bite (the damage given back)"""
    st = b.st[who]
    st[r.WET] = max(0, st[r.WET] - 1)  # the game's wet is 1: dried
    st[r.TANGLE] = 0
    turns = st[r.FLEA_TURNS]
    if turns == 0:
        return 0
    bite = st[r.POISON]
    st[r.FLEA_TURNS] = turns - 1
    if turns == 1:
        st[r.POISON] = 0
    return bite


def move_target(b, by, row):
    move = b.R.moves[row]
    if move.aim == "self":
        return by
    lasered = b.st[by][r.LASER] and move.effect in ("hit", "hit2")
    if lasered:
        # PROPOSAL: its hit goes to a friend; with no friend standing it comes at you
        b.st[by][r.LASER] = 0
        for i in range(1, r.ACTORS):
            if i != by and b.alive[i]:
                return i
        if b.R.model == "bag":
            return by  # the bag proposal's laser: alone, it hits itself
        return r.HERO
    if move.aim == "friend":
        for i in range(1, r.ACTORS):
            if i != by and b.alive[i]:
                return i
        return by
    return r.HERO


def land_move(b, row, by, target):
    move = b.R.moves[row]
    b.say("  %s: %s" % (b.R.kinds[b.kind[by]].name,
                           move.text.replace("#", str(move.amount))))
    if move.aim == "all" and target == r.HERO and b.st[r.HERO][r.BOX] > 0:
        return
    b.apply(move.effect, by, target, move.amount)


def next_move(b, i):
    kind = b.R.kinds[b.kind[i]]
    made = b.made[i] + 1
    if made >= kind.count:
        made = 0
    b.made[i] = made
    b.move[i] = kind.first + made
