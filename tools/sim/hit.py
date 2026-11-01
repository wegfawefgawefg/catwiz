"""Hits, hit points and statuses (the game's battle/hit.tsp, statuses.tsp taken and lose):
a part of rules.Battle. rules imports this module: its names are read when the functions
run."""

import cards
import items
import rules as r


class Hits:
    def dealt(self, who, damage, use):
        st = self.st[who]
        cheer = st[r.CHEER]
        if use:
            st[r.CHEER] = 0
        d = damage + cheer + st[r.STRENGTH]  # strength: PROPOSAL
        d = min(d, 255) if self.R.model == "items" else d & 0xFF  # items: saturates, the bag: wraps
        if st[r.TANGLE]:  # PROPOSAL: tangled, till its turn ends
            d = max(0, d - st[r.TANGLE])
        if st[r.WET] > 0:
            d >>= 1
        return d

    def strike(self, by, target, amount, pierce=False):
        if by == r.HERO and target == r.HERO:
            self.self_hits += 1
        st = self.st[target]
        if by == r.HERO and self.wand_on and st[r.DOT] and not self.dot_fired:
            self.dot_fired = True  # PROPOSAL: a wand hit on a red dot: all dice back
            if "dotturns" not in self.R.variant:  # # is how many times it fires
                st[r.DOT] -= 1
        damage = self.dealt(by, amount, True)
        damage += st[r.MARK] + st[r.BRAND]  # PROPOSAL
        damage = min(damage, 255)  # a hit is a byte: it saturates
        if st[r.REFLECT] and by == r.HERO:  # PROPOSAL
            back = min(st[r.REFLECT], damage)
            st[r.REFLECT] -= back
            damage -= back
            self.strike_plain(r.HERO, back)
        back = 0
        if target == r.HERO and by != r.HERO and st[r.MIRROR]:  # PROPOSAL: mirror fur
            back = min(st[r.SHIELD], damage, st[r.MIRROR])
            st[r.MIRROR] -= back
        if pierce:
            self.lose(target, damage)
        else:
            self.strike_plain(target, damage)
        if back:
            self.lose(by, back)
        if target == r.HERO and by != r.HERO and self.st[r.HERO][r.THORNS]:  # PROPOSAL
            self.lose(by, self.st[r.HERO][r.THORNS])

    def strike_plain(self, target, damage):
        """statuses.taken, then hit.lose"""
        st = self.st[target]
        shield = st[r.SHIELD]
        if shield >= damage:
            st[r.SHIELD] = shield - damage
            return
        st[r.SHIELD] = 0
        self.lose(target, damage - shield)

    def lose(self, who, n):
        if not self.alive[who]:
            return
        hp = self.hp[who]
        n = min(n, hp)
        if who == r.HERO and n == hp and n > 0 and self.revive:  # PROPOSAL: nine lives (once)
            self.hp[who] = min(self.revive, self.maxhp[who])
            self.revive = 0
            self.hero_lost += n
            self.lost_this_round += n
            items.hero_hurt(self)
            self.say("  CATWIZ COMES BACK")
            return
        if who == r.HERO and n == hp and n > 0 and self.lives > 0:  # PROPOSAL: nine lives
            self.lives -= 1
            n = hp - 1
        self.hp[who] = hp - n
        if who == r.HERO:
            self.hero_lost += n
            self.lost_this_round += n
            if n > 0:
                items.hero_hurt(self)
        else:
            self.st[who][r.HURT] += n
        if hp - n == 0:
            self.die(who)

    def die(self, who):
        if who != r.HERO:
            self.falls += 1  # PROPOSAL: finishing swat
            fleas = self.st[who][r.POISON] if self.st[who][r.CIRCUS] else 0
            haunt = self.st[who][r.HAUNT]
            then = self.R.kinds[self.kind[who]].then
            self.release(who)
            if then != r.NOTHING:  # PROPOSAL: the possum gets up, the boss's next phase
                self.set_enemy(who, then)
                self.st[who][r.FRESH] = 1  # a round to get up: it skips one move
                self.say("  %s GETS UP" % self.R.kinds[then].name)
            else:
                self.alive[who] = False
                items.enemy_beaten(self, who)
            if fleas or haunt:
                cards.fallen(self, who, fleas, haunt)
            return
        self.alive[who] = False

    def release(self, who):
        for d in range(len(self.held)):
            if self.held[d] == who:
                self.held[d] = r.NOTHING
                self.in_draw[d] = True

    def heal(self, who, n):
        hp = min(self.hp[who] + n, self.maxhp[who])
        if who == r.HERO:
            self.hero_healed += hp - self.hp[who]
        self.hp[who] = hp

    def add(self, who, status, n):
        st = self.st[who]
        st[status] = min(st[status] + n, 255 if self.R.model == "items" else 99)

