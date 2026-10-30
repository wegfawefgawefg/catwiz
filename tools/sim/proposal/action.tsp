; PROPOSAL (tools/sim, docs/balance.md): game/content/action.tsp for the item-slot model: the
; effect kinds of the items and moves, a die face is an item (content/items.tsp), and an enemy
; move gets its own smaller row. What each kind does is in docs/balance.md (and
; the sim's tools/sim/rules.py) until content/effects.tsp has it.

(import state)

(enum Effect (hit ; amount damage
        shield ; amount shield, gone at the holder's next turn
        heal ; amount hit points back
        mana ; amount mana, kept all fight, effects.MOST_MANA at most
        fleas ; curse: amount damage at the end of each of its turns, for 3 turns; stacks
        wet ; curse: its hits are halved, for amount turns
        tangled ; curse: its hits are amount less, till its turn ends
        brand ; curse: every hit on it does amount more, all fight (marked)
        plus ; trick: the next 2 dice played get amount more (each hit, each stack, each star)
        double ; trick: the next wand, fluff or book: times amount, and it counts amount towards a three
        copy ; trick: the last face you played again (free), amount more
        catnip2 ; trick: the next amount dice get 1 more; kittens pounce twice this turn
        knead ; trick: the next fluff times 2, the next wand amount more
        zoomies ; spell: amount damage 5 times, enemies left to right
        kittens ; spell: amount kittens join you (each pounces 1 at your turn's end)
        laserall ; spell: amount damage to every enemy; each one's next hit goes to a friend
        scream ; spell: amount damage to every enemy, 1 to you
        knock ; spell: the enemy drops its shield and buffs, then amount damage
        pile ; spell: amount shield, and 2 more for each kitten
        cannon ; spell: amount damage for each kitten
        yarn ; wand: amount damage, and tangled 1
        spray ; wand: amount damage, and wet 1
        feather ; wand: amount damage, and the kittens pounce it
        pierce ; wand: amount damage that no shield stops
        string ; wand: amount damage, then amount to the next enemy
        shoot ; star: 1 mana, and amount damage
        moon ; star: 1 mana, and amount shield
        wish ; star: amount mana, and the next wand times 2
        litter ; star: amount mana, and 1 more for each kitten
        cheer ; an enemy's friend hits amount harder next time
        nothing ; does nothing (the hairball)
        wait ; an enemy move that does nothing (the countdowns)
        spook ; curse on you: your dice get amount less on your next turn
        mend ; an enemy heals each of its friends amount
        summon ; an enemy calls amount of its kind's calls into empty spots
        steal ; an enemy takes the die you played last; you get it back when it is beaten
        reflect ; an enemy sends back the next amount damage you deal it, till its next turn
        hit2 ; amount damage twice
        grow ; an enemy hits amount harder for the rest of the fight
        junk)) ; an enemy clogs your slot amount with a hairball for the fight

; an item: what a face does (content/items.tsp). name: the log's and the card's name; text: the
; card's item line; slot: which face it sits on; effect, amount: what it does, step more a
; level; cost: mana; combo: what the third face of its slot in a turn adds, combo_n how much
(struct Item ((name (ptr u8))
        (text (ptr u8))
        (slot u8)
        (effect Effect)
        (amount u8)
        (step u8)
        (cost u8)
        (combo u8)
        (combo_n u8)
        (aim state.Aim)
        (icon u8)))

; an enemy's move: text for the bottom text and the log (no name, # its number, 21 characters
; at most), icon the glyph over its head before it acts
(struct Move ((text (ptr u8))
        (effect Effect)
        (amount u8)
        (aim state.Aim)
        (motion state.Motion)
        (icon u8)))
