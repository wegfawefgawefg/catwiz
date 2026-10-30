"""One battle, step by step, as game/battle/*.tsp and game/content/effects.tsp and
statuses.tsp play it. Each function says which engine function it copies. The proposal's
mechanics (marked PROPOSAL) are the sim's own: the game has none of them yet, and
docs/balance.md lists what the engine would need for each.

A battle is played by a policy calling play(), reroll() and end_turn(), and
start_round() after end_turn() when the fight goes on. Actor 0 is the hero, 1-3 the enemies.
"""

NOTHING = 255
HERO = 0
ACTORS = 4

# the game's statuses (content/statuses.tsp, in its order), then the proposal's
STATUSES = [
    "shield", "poison", "flea_turns", "wet", "hiss", "cheer", "ward", "box", "mana", "plus",
    "double",
    # PROPOSAL
    "spook", "reflect", "mark", "laser", "thorns", "catnip", "fluffs", "hurt", "fresh",
]
S = {name: i for i, name in enumerate(STATUSES)}
SHIELD, POISON, FLEA_TURNS, WET, HISS, CHEER, WARD, BOX, MANA, PLUS, DOUBLE = range(11)
SPOOK, REFLECT, MARK, LASER, THORNS, CATNIP, FLUFFS, HURT, FRESH = range(11, 20)
NS = len(STATUSES)


class Battle:
    def __init__(self, rules, dice, hero_hp, enemies, rng, exact=False):
        """battle.enter_fight: the bag's dice (lists of face rows), the hero's hit points and
        the fight's enemy kinds. exact: draw and roll with every random byte the game takes
        (4 tumbles a roll), for matching the emulator's own random numbers."""
        self.R = rules
        self.rng = rng
        self.exact = exact
        self.dice = dice
        self.hp = [hero_hp, 0, 0, 0]
        self.maxhp = [rules.hero_hp, 0, 0, 0]
        self.alive = [True, False, False, False]
        self.kind = [NOTHING] * ACTORS
        self.move = [0] * ACTORS
        self.made = [0] * ACTORS
        self.st = [[0] * NS for _ in range(ACTORS)]
        for i, k in enumerate(enemies):
            self.set_enemy(i + 1, k)
        n = len(dice)
        self.in_draw = [True] * n  # bag.gather
        self.held = [NOTHING] * n  # PROPOSAL: the enemy holding the die (a squirrel)
        self.tray = [NOTHING] * rules.hand
        self.hand = [0] * rules.hand
        self.played = [True] * rules.hand
        self.rerolls = 0
        self.target = 1
        self.turn = 0
        self.last_played = NOTHING
        self.result = None
        self.log = None  # a list to append lines to, for traces
        self.hero_lost = 0  # hit points the hero lost this fight
        self.self_hits = 0  # zoomies outlasting the enemies, hitting the cat (as in the game)

    def clone(self):
        b = Battle.__new__(Battle)
        b.R = self.R
        b.rng = self.rng
        b.exact = self.exact
        b.dice = self.dice
        b.hp = self.hp[:]
        b.maxhp = self.maxhp[:]
        b.alive = self.alive[:]
        b.kind = self.kind[:]
        b.move = self.move[:]
        b.made = self.made[:]
        b.st = [s[:] for s in self.st]
        b.in_draw = self.in_draw[:]
        b.held = self.held[:]
        b.tray = self.tray[:]
        b.hand = self.hand[:]
        b.played = self.played[:]
        b.rerolls = self.rerolls
        b.target = self.target
        b.turn = self.turn
        b.last_played = self.last_played
        b.result = self.result
        b.log = None
        b.hero_lost = self.hero_lost
        b.self_hits = self.self_hits
        return b

    def say(self, line):
        if self.log is not None:
            self.log.append(line)

    # ---- setting up: battle.set_enemy, statuses.start

    def set_enemy(self, i, k):
        kind = self.R.kinds[k]
        self.kind[i] = k
        self.hp[i] = kind.hp
        self.maxhp[i] = kind.hp
        self.alive[i] = True
        self.move[i] = kind.first
        self.made[i] = 0
        self.st[i] = [0] * NS
        self.st[i][WARD] = kind.ward

    # ---- the bag: battle/bag.tsp

    def draw_count(self):
        return sum(self.in_draw)

    def draw_one(self):
        if self.draw_count() == 0:
            for d in range(len(self.dice)):  # reshuffle: every die not in the tray
                if d not in self.tray and self.held[d] == NOTHING:
                    self.in_draw[d] = True
        n = self.draw_count()
        if n == 0:
            return NOTHING
        k = self.rng.byte() & 7
        while k >= n:
            k = self.rng.byte() & 7
        for d in range(len(self.dice)):
            if self.in_draw[d]:
                if k == 0:
                    self.in_draw[d] = False
                    return d
                k -= 1
        return NOTHING

    def deal(self):
        h = self.R.hand
        self.tray = [NOTHING] * h
        for s in range(h):
            d = self.draw_one()
            self.tray[s] = d
            self.played[s] = d == NOTHING

    def roll(self):
        """turn.roll_step: the unplayed dice tumble 4 times (a random face each, 0-5 from a
        byte times 6 over 256); the last tumble is the face."""
        tumbles = 4 if self.exact else 1
        for _ in range(tumbles):
            for s in range(self.R.hand):
                if not self.played[s]:
                    f = (self.rng.byte() * 6) >> 8
                    self.hand[s] = self.dice[self.tray[s]][f]

    # ---- the hero's turn: battle/turn.tsp

    def start_round(self):
        self.turn += 1
        st = self.st[HERO]
        st[SHIELD] = 0  # statuses.turn_start
        st[BOX] = 0
        st[THORNS] = 0
        self.rerolls = self.R.rerolls
        self.last_played = NOTHING
        self.deal()
        self.roll()
        self.fix_target()

    def fix_target(self):
        if not self.alive[self.target]:
            t = self.target
            for _ in range(3):
                t += 1
                if t == ACTORS:
                    t = 1
                if self.alive[t]:
                    self.target = t
                    return

    def mana(self):
        return self.st[HERO][MANA]

    def can_play(self, s):
        return not self.played[s] and self.R.faces[self.hand[s]].cost <= self.st[HERO][MANA]

    def playable(self):
        return [s for s in range(self.R.hand) if self.can_play(s)]

    def any_unplayed(self):
        return not all(self.played)

    def turn_over(self):
        """the turn ends by itself: every die played, or none playable and no re-roll left"""
        if self.result is not None:
            return True
        if not self.playable():
            return all(self.played) or self.rerolls == 0
        return False

    def play(self, s, target=None):
        """turn.play_selected: slot s's face, on target for a face for one enemy"""
        row = self.hand[s]
        face = self.R.faces[row]
        self.played[s] = True
        self.last_played = self.tray[s]
        if face.aim == "self":
            t = HERO
        else:
            if target is not None and face.aim == "foe":
                self.target = target
            t = self.target
        if self.log is not None:
            on = "" if t == HERO or face.aim == "all" else " on " + self.R.kinds[self.kind[t]].name
            self.say("  CATWIZ USES %s%s" % (face.name, on))
        self.land_face(row, t)
        self.after_action()

    def reroll(self):
        self.rerolls -= 1
        self.roll()
        if self.log is not None:
            self.say("  RE-ROLL: " + ", ".join(
                self.R.faces[self.hand[s]].name for s in range(self.R.hand) if not self.played[s]))

    def after_action(self):
        if not self.alive[HERO]:
            self.result = "lost"
        elif not any(self.alive[1:]):
            self.result = "won"
        else:
            self.fix_target()

    # ---- effects.land_face and boosted

    def boosted(self, n):
        st = self.st[HERO]
        n = ((n << st[DOUBLE]) + st[PLUS]) & 0xFF
        n += st[CATNIP]  # PROPOSAL
        if st[SPOOK]:
            n = max(0, n - st[SPOOK])
        return n

    def land_face(self, row, target):
        face = self.R.faces[row]
        st = self.st[HERO]
        if face.effect == "plus":
            self.add(HERO, PLUS, face.amount)
            return
        if face.effect == "double":
            st[PLUS] = (st[PLUS] << 1) & 0xFF
            self.add(HERO, DOUBLE, 1)
            return
        n = self.boosted(face.amount)
        st[PLUS] = 0
        st[DOUBLE] = 0
        if face.cost > 0:
            st[MANA] -= face.cost
        if face.effect == "shield":
            st[FLUFFS] += 1  # PROPOSAL: Static Fur counts the Fluff faces played
        self.apply(face.effect, HERO, target, n)

    # ---- effects.apply: the one match on the effect kind

    def apply(self, effect, by, target, n):
        R = self.R
        if effect == "hit":
            self.strike(by, target, n)
        elif effect == "shield":
            self.add(target, SHIELD, n)
        elif effect == "heal":
            self.heal(target, n)
        elif effect == "mana":
            self.st[HERO][MANA] = min(self.st[HERO][MANA] + n, R.most_mana)
        elif effect == "hairball":
            self.strike(by, target, n)
            if self.alive[target]:
                self.curse("fleas", target, R.fx["HAIRBALL_FLEAS"])
        elif effect == "zoomies":
            t = 0
            for _ in range(R.fx["ZOOMIES_HITS"]):
                t = self.next_standing(t)
                if t != NOTHING:
                    self.strike(by, t, n)
        elif effect == "box":
            self.add(target, SHIELD, n)
            self.st[target][BOX] = 1
        elif effect == "scream":
            for i in range(1, ACTORS):
                if self.alive[i]:
                    self.strike(by, i, n)
            self.lose(HERO, R.fx["SCREAM_SELF"])
        elif effect == "cheer":
            self.add(target, CHEER, n)
        elif effect in ("nothing", "plus", "double", "wait"):
            pass
        elif effect in ("fleas", "wet", "hiss", "bath", "spook"):
            self.curse(effect, target, n)
        # PROPOSAL: the hero's new spells
        elif effect == "mark":
            self.add(target, MARK, n)
        elif effect == "laser":
            self.st[target][LASER] = 1
        elif effect == "knock":
            self.st[target][SHIELD] = 0
            self.strike(by, target, n)
        elif effect == "catnip":
            self.add(HERO, CATNIP, n)
        elif effect == "thorns":
            self.add(HERO, SHIELD, n)
            self.st[HERO][THORNS] = R.fx["TRAP_BACK"]
        elif effect == "static":
            n += self.st[HERO][FLUFFS]
            for i in range(1, ACTORS):
                if self.alive[i]:
                    self.strike(by, i, n)
        elif effect == "ward":
            self.add(target, WARD, n)
        # PROPOSAL: the enemies' new moves
        elif effect == "mend":
            for i in range(1, ACTORS):
                if i != by and self.alive[i]:
                    self.heal(i, n)
        elif effect == "summon":
            self.summon(by, n)
        elif effect == "steal":
            d = self.last_played
            if d != NOTHING and self.held[d] == NOTHING:
                self.held[d] = by
                self.in_draw[d] = False
                self.say("IT TAKES A DIE")
        elif effect == "reflect":
            self.add(by, REFLECT, n)
        else:
            raise ValueError("effect the sim does not know: " + effect)

    def next_standing(self, t):
        """effects.next_standing. t is a u8 in the game: from NOTHING (255) it wraps to 0,
        the hero, so zoomies that outlast the enemies hit her (as the game does)"""
        for _ in range(3):
            t = (t + 1) & 0xFF
            if t == ACTORS:
                t = 1
            if self.alive[t]:
                return t
        return NOTHING

    def curse(self, effect, target, n):
        """effects.curse: always lands; a ward pip breaks instead"""
        st = self.st[target]
        if st[WARD] > 0:
            st[WARD] -= 1
            return
        if effect == "fleas":
            self.add(target, POISON, n)
            st[FLEA_TURNS] = self.R.fx["FLEA_TURNS"]
        elif effect == "wet":
            st[WET] = 1
        elif effect == "hiss":
            st[HISS] = 1
        elif effect == "spook":
            self.add(target, SPOOK, n)
        else:
            st[SHIELD] = 0

    def summon(self, by, n):
        """PROPOSAL: n of by's kind's calls into empty spots; they wait for the next round"""
        k = self.R.kinds[self.kind[by]].calls
        for _ in range(n):
            for i in range(1, ACTORS):
                if not self.alive[i]:
                    self.set_enemy(i, k)
                    self.st[i][FRESH] = 1
                    break

    # ---- battle/hit.tsp

    def dealt(self, who, damage, use):
        st = self.st[who]
        cheer = st[CHEER]
        if use:
            st[CHEER] = 0
        d = (damage + cheer) & 0xFF
        if st[WET] > 0:
            d >>= 1
        return d

    def strike(self, by, target, amount):
        if by == HERO and target == HERO:
            self.self_hits += 1
        damage = self.dealt(by, amount, True)
        st = self.st[target]
        damage += st[MARK]  # PROPOSAL
        if st[REFLECT] and by == HERO:  # PROPOSAL
            back = min(st[REFLECT], damage)
            st[REFLECT] -= back
            damage -= back
            self.strike_plain(HERO, back)
        self.strike_plain(target, damage)
        if target == HERO and by != HERO and self.st[HERO][THORNS]:  # PROPOSAL
            self.lose(by, self.st[HERO][THORNS])

    def strike_plain(self, target, damage):
        """statuses.taken, then hit.lose"""
        st = self.st[target]
        shield = st[SHIELD]
        if shield >= damage:
            st[SHIELD] = shield - damage
            return
        st[SHIELD] = 0
        self.lose(target, damage - shield)

    def lose(self, who, n):
        if not self.alive[who]:
            return
        hp = self.hp[who]
        n = min(n, hp)
        self.hp[who] = hp - n
        if who == HERO:
            self.hero_lost += n
        else:
            self.st[who][HURT] += n
        if hp - n == 0:
            self.die(who)

    def die(self, who):
        if who != HERO:
            then = self.R.kinds[self.kind[who]].then
            if then != NOTHING:  # PROPOSAL: the possum gets up, the boss's next phase
                self.release(who)
                self.set_enemy(who, then)
                self.st[who][FRESH] = 1  # a round to get up: it skips one move
                self.say("%s GETS UP" % self.R.kinds[then].name)
                return
            self.release(who)
        self.alive[who] = False

    def release(self, who):
        for d in range(len(self.held)):
            if self.held[d] == who:
                self.held[d] = NOTHING
                self.in_draw[d] = True

    def heal(self, who, n):
        self.hp[who] = min(self.hp[who] + n, self.maxhp[who])

    def add(self, who, status, n):
        st = self.st[who]
        st[status] = min(st[status] + n, 99)

    # ---- the enemies' turn: turn.end_turn, enemies_step, end_enemies

    def end_turn(self):
        """the hero's statuses tick, every enemy makes its move, theirs tick; the next
        round is start_round's, for the caller (a search may stop here and look)"""
        st = self.st[HERO]
        bite = self.status_end(HERO)
        st[CATNIP] = 0
        st[SPOOK] = 0
        if bite:
            self.lose(HERO, bite)
        if not self.alive[HERO]:
            self.result = "lost"
            return
        for i in range(1, ACTORS):
            self.st[i][MARK] = 0
            if self.alive[i]:
                self.st[i][SHIELD] = 0
                self.st[i][BOX] = 0
                self.st[i][REFLECT] = 0
        for i in range(1, ACTORS):
            if not self.alive[i]:
                continue
            si = self.st[i]
            if si[FRESH]:
                continue
            if si[HISS]:
                si[HISS] = 0
                continue
            kind = self.R.kinds[self.kind[i]]
            if kind.stall and si[HURT] >= kind.stall:
                self.say("%s STALLS" % kind.name)
                continue
            row = self.move[i]
            self.land_move(row, i, self.move_target(i, row))
            self.after_action()
            if self.result is not None:
                return
        for i in range(1, ACTORS):
            if self.alive[i]:
                bite = self.status_end(i)
                if bite:
                    self.lose(i, bite)
            if self.alive[i]:
                si = self.st[i]
                si[HURT] = 0
                if si[FRESH]:
                    si[FRESH] = 0
                else:
                    self.next_move(i)
        if not any(self.alive[1:]):
            self.result = "won"

    def status_end(self, who):
        """statuses.turn_end: wet dries, fleas bite (the damage given back)"""
        st = self.st[who]
        st[WET] = 0
        turns = st[FLEA_TURNS]
        if turns == 0:
            return 0
        bite = st[POISON]
        st[FLEA_TURNS] = turns - 1
        if turns == 1:
            st[POISON] = 0
        return bite

    def move_target(self, by, row):
        aim = self.R.moves[row].aim
        if aim == "self":
            return by
        if aim == "friend" or (self.st[by][LASER] and self.R.moves[row].effect == "hit"):
            self.st[by][LASER] = 0
            for i in range(1, ACTORS):
                if i != by and self.alive[i]:
                    return i
            return by
        return HERO

    def land_move(self, row, by, target):
        move = self.R.moves[row]
        self.say("  %s: %s" % (self.R.kinds[self.kind[by]].name, move.text.replace("#", str(move.amount))))
        if move.aim == "all" and target == HERO and self.st[HERO][BOX] > 0:
            return
        self.apply(move.effect, by, target, move.amount)

    def next_move(self, i):
        kind = self.R.kinds[self.kind[i]]
        made = self.made[i] + 1
        if made >= kind.count:
            made = 0
        self.made[i] = made
        self.move[i] = kind.first + made

    # ---- for policies

    def incoming(self):
        """what the enemies' shown moves would take off the hero now (a copy plays it out)"""
        b = self.clone()
        hp = b.hp[HERO]
        b.end_turn()
        return hp - b.hp[HERO]
