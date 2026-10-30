"""One battle, step by step, as game/battle/*.tsp and game/content/effects.tsp and
statuses.tsp play it. Each function says which engine function it copies. The proposals'
mechanics are the sim's own (the game has none of them yet; docs/balance.md lists what the
engine would need): the enemies' new moves are here, marked PROPOSAL; the bag proposal's new
spells in bagfx.py; the item-slot model's faces, levels and charms in items.py.

A battle is played by a policy calling play(), reroll() and end_turn(), and
start_round() after end_turn() when the fight goes on. Actor 0 is the hero, 1-3 the enemies.
"""

import bagfx
import foes
import items

NOTHING = 255
HERO = 0
ACTORS = 4

# the game's statuses (content/statuses.tsp, in its order), then the proposals'
STATUSES = [
    "shield", "poison", "flea_turns", "wet", "hiss", "cheer", "ward", "box", "mana", "plus",
    "double",
    # PROPOSAL, both models
    "spook", "reflect", "mark", "laser", "thorns", "catnip", "fluffs", "hurt", "fresh",
    "strength",
    # PROPOSAL, the item model (items.py)
    "kittens", "nipped", "tangle", "brand", "knead_fluff", "knead_wand", "nip", "mult", "keep",
    "freebook", "wish",
]
for _i, _name in enumerate(STATUSES):
    globals()[_name.upper()] = _i
NS = len(STATUSES)
GONE = 254  # the bag proposal: a hairball die coughed up, back never


class Battle:
    def __init__(self, rules, dice, hero_hp, enemies, rng, exact=False, charms=(),
                 levels=None, zone="", lives=0):
        """battle.enter_fight: the bag's dice (lists of face rows), the hero's hit points and
        the fight's enemy kinds. exact: draw and roll with every random byte the game takes
        (4 tumbles a roll), for matching the emulator's own random numbers. The proposals:
        charms (kinds, by name), levels (the item model: face row to level), the zone (day,
        dusk, night) and lives (nine lives charms left this run)."""
        self.R = rules
        self.rng = rng
        self.exact = exact
        self.dice = list(dice)  # the fight's own list: hairballs leave with it
        self.charms = charms
        self.levels = levels or {}
        self.zone = zone
        self.lives = lives
        self.hp = [hero_hp, 0, 0, 0]
        self.maxhp = [rules.hero_hp, 0, 0, 0]
        self.alive = [True, False, False, False]
        self.kind = [NOTHING] * ACTORS
        self.move = [0] * ACTORS
        self.made = [0] * ACTORS
        self.st = [[0] * NS for _ in range(ACTORS)]
        self.bonus = bagfx.type_bonus(charms)
        for i, k in enumerate(enemies):
            self.set_enemy(i + 1, k)
        n = len(dice)
        self.in_draw = [True] * n  # bag.gather
        self.held = [NOTHING] * n  # PROPOSAL: the enemy holding the die (a squirrel)
        self.hand_n = rules.hand + charms.count("toe")  # the sixth toe charm rolls 6
        self.tray = [NOTHING] * self.hand_n
        self.hand = [0] * self.hand_n
        self.face_of = [0] * self.hand_n  # which face of its die each slot rolled
        self.played = [True] * self.hand_n
        self.rerolls = 0
        self.target = 1
        self.turn = 0
        self.last_played = NOTHING
        self.last_face = NOTHING  # the item model: the last face played and on whom (copycat)
        self.last_on = 1
        self.clogged = {}  # the item model: slot to the item a hairball covers
        self.combo = {}  # the item model: faces of each slot played this turn
        self.rerolled = False
        self.old_shield = 0
        self.result = None
        self.log = None  # a list to append lines to, for traces
        self.hero_lost = 0  # hit points the hero lost this fight
        self.hero_healed = 0  # hit points the hero got back this fight
        self.self_hits = 0  # zoomies outlasting the enemies, hitting the cat (as in the game)
        self.lost_this_round = 0
        items.fight_start(self)

    def clone(self):
        b = Battle.__new__(Battle)
        b.__dict__.update(self.__dict__)
        b.__dict__.pop("play", None)  # validate.plan_turn's recorders stay on its own copy
        b.__dict__.pop("reroll", None)
        for name in ("dice", "hp", "maxhp", "alive", "kind", "move", "made", "in_draw", "held",
                     "tray", "hand", "face_of", "played"):
            setattr(b, name, getattr(self, name)[:])
        b.st = [s[:] for s in self.st]
        b.clogged = dict(self.clogged)
        b.combo = dict(self.combo)
        b.log = None
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
        h = self.hand_n
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
            for s in range(self.hand_n):
                if not self.played[s]:
                    f = (self.rng.byte() * 6) >> 8
                    self.face_of[s] = f
                    self.hand[s] = self.dice[self.tray[s]][f]

    # ---- the hero's turn: battle/turn.tsp

    def start_round(self):
        self.turn += 1
        st = self.st[HERO]
        self.old_shield = st[SHIELD]  # the fluffy tail charm keeps half (items.round_start)
        st[SHIELD] = 0  # statuses.turn_start
        st[BOX] = 0
        st[THORNS] = 0
        self.rerolls = self.R.rerolls
        self.last_played = NOTHING
        self.lost_this_round = 0
        items.round_start(self)
        if self.result is not None:
            return
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
        if self.played[s]:
            return False
        face = self.R.faces[self.hand[s]]
        if face.slot == "junk":
            return False  # a hairball: only a re-roll coughs it up
        if face.slot == "book":
            return True  # the item model: a book with too little mana gives 1 mana
        return face.cost <= self.st[HERO][MANA]

    def playable(self):
        return [s for s in range(self.hand_n) if self.can_play(s)]

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
        if self.R.model == "items":
            items.land(self, row, t)
        else:
            self.land_face(row, t)
        self.after_action()

    def reroll(self):
        self.rerolls -= 1
        items.cough(self)
        self.roll()
        if self.log is not None:
            self.say("  RE-ROLL: " + ", ".join(
                self.R.faces[self.hand[s]].name for s in range(self.hand_n) if not self.played[s]))

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
        n = self.boosted(face.amount + self.bonus.get(bagfx.family(face), 0))
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
        # PROPOSAL: the enemies' new moves
        elif effect == "hit2":
            self.strike(by, target, n)
            if self.alive[target]:
                self.strike(by, target, n)
        elif effect == "mend":
            for i in range(1, ACTORS):
                if i != by and self.alive[i]:
                    self.heal(i, n)
        elif effect == "summon":
            foes.summon(self, by, n)
        elif effect == "steal":
            d = self.last_played
            if d != NOTHING and self.held[d] == NOTHING:
                self.held[d] = by
                self.in_draw[d] = False
                self.say("  IT TAKES A DIE")
        elif effect == "grow":
            self.add(by, STRENGTH, n)
        elif effect == "reflect":
            self.add(by, REFLECT, n)
        elif effect == "junk" and R.model == "items":
            items.clog(self, n)
        elif not bagfx.apply(self, effect, by, target, n):
            raise ValueError("effect the sim does not know: " + effect)

    def next_standing(self, t):
        """effects.next_standing. t is a u8 in the game: from NOTHING (255) it wraps to 0,
        the hero, so zoomies that outlast the enemies hit her (as the game does)"""
        for _ in range(3):
            t = (t + 1) & 0xFF
            if t == ACTORS:
                t = 1
            if self.alive[t]:
                if t == HERO and self.R.proposal:
                    return NOTHING  # the proposals take the fix: no zoomies at the cat
                return t
        return NOTHING

    def curse(self, effect, target, n):
        """effects.curse: always lands; a ward pip breaks instead"""
        st = self.st[target]
        if st[WARD] > 0:
            st[WARD] -= 1
            items.ward_blocked(self)
            return
        if effect == "fleas":
            self.add(target, POISON, n)
            st[FLEA_TURNS] = self.R.fx["FLEA_TURNS"]
        elif effect == "wet":
            st[WET] = max(st[WET], n, 1)  # the item model's wet lasts n turns; the game's 1
        elif effect == "hiss":
            st[HISS] = 1
        elif effect == "spook":
            self.add(target, SPOOK, n)
        elif effect == "brand":
            self.add(target, BRAND, n)
        elif effect == "tangled":
            self.add(target, TANGLE, n)
        elif effect == "blink":
            st[LASER] = 1
        else:
            st[SHIELD] = 0

    # ---- battle/hit.tsp

    def dealt(self, who, damage, use):
        st = self.st[who]
        cheer = st[CHEER]
        if use:
            st[CHEER] = 0
        d = (damage + cheer + st[STRENGTH]) & 0xFF  # strength: PROPOSAL
        if st[TANGLE]:  # PROPOSAL: tangled, till its turn ends
            d = max(0, d - st[TANGLE])
        if st[WET] > 0:
            d >>= 1
        return d

    def strike(self, by, target, amount, pierce=False):
        if by == HERO and target == HERO:
            self.self_hits += 1
        damage = self.dealt(by, amount, True)
        st = self.st[target]
        damage += st[MARK] + st[BRAND]  # PROPOSAL
        if st[REFLECT] and by == HERO:  # PROPOSAL
            back = min(st[REFLECT], damage)
            st[REFLECT] -= back
            damage -= back
            self.strike_plain(HERO, back)
        if pierce:
            self.lose(target, damage)
        else:
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
        if who == HERO and n == hp and n > 0 and self.lives > 0:  # PROPOSAL: nine lives
            self.lives -= 1
            n = hp - 1
        self.hp[who] = hp - n
        if who == HERO:
            self.hero_lost += n
            self.lost_this_round += n
            if n > 0:
                items.hero_hurt(self)
        else:
            self.st[who][HURT] += n
        if hp - n == 0:
            self.die(who)

    def die(self, who):
        if who != HERO:
            then = self.R.kinds[self.kind[who]].then
            self.release(who)
            if then != NOTHING:  # PROPOSAL: the possum gets up, the boss's next phase
                self.set_enemy(who, then)
                self.st[who][FRESH] = 1  # a round to get up: it skips one move
                self.say("  %s GETS UP" % self.R.kinds[then].name)
                return
            self.alive[who] = False
            items.enemy_beaten(self, who)
            return
        self.alive[who] = False

    def release(self, who):
        for d in range(len(self.held)):
            if self.held[d] == who:
                self.held[d] = NOTHING
                self.in_draw[d] = True

    def heal(self, who, n):
        hp = min(self.hp[who] + n, self.maxhp[who])
        if who == HERO:
            self.hero_healed += hp - self.hp[who]
        self.hp[who] = hp

    def add(self, who, status, n):
        st = self.st[who]
        st[status] = min(st[status] + n, 99)

    # ---- the enemies' turn: foes.py

    def end_turn(self):
        """the hero's statuses tick, every enemy makes its move, theirs tick; the next round is
        start_round's, for the caller (a search may stop here and look)"""
        foes.end_turn(self)
