; PROPOSAL (tools/sim, docs/balance.md): game/content/action.tsp for fights 3-10 and the boss:
; the effect kinds grow by the new spells' and moves', and enemy moves get their own smaller row.
; What each kind does is in docs/balance.md (and the sim's tools/sim/rules.py) until
; content/effects.tsp has it.

(import state)

(enum Effect (hit ; amount damage
        shield    ; amount shield, gone at the holder's next turn
        heal      ; amount hit points back
        mana      ; amount mana, kept all fight, effects.MOST_MANA at most
        fleas     ; curse: amount damage at the end of each of its turns, for 3 turns
        wet       ; curse: it deals half damage next turn
        hiss      ; curse: it skips its next move
        bath      ; curse: it loses all its shield
        plus      ; the next die played gets amount more
        double    ; the next die played does double
        hairball  ; spell: amount damage, and fleas (the game's; the proposal has no such face)
        zoomies   ; spell: amount damage 5 times, enemies left to right
        box       ; spell: amount shield, and hit-all attacks miss until your next turn
        scream    ; spell: amount damage to every enemy, 1 to you
        cheer     ; an enemy's friend hits amount harder next time
        nothing   ; lint
        mark      ; spell: the enemy takes amount more from every hit till your turn ends
        laser     ; spell: the enemy's next hit goes to its friend (itself when alone)
        knock     ; spell: the enemy loses its shield, then amount damage
        catnip    ; spell: every die you play this turn gets amount more
        thorns    ; spell: amount shield; whoever hits you till your next turn takes TRAP_BACK
        static    ; spell: amount damage to every enemy, +1 for each fluff face played this fight
        ward      ; amount ward pips: each blocks the next curse
        wait      ; an enemy move that does nothing (the countdowns)
        spook     ; curse on you: your dice get amount less on your next turn
        mend      ; an enemy heals each of its friends amount
        summon    ; an enemy calls amount of its kind's calls into empty spots
        steal     ; an enemy takes the die you played last; you get it back when it is beaten
        reflect   ; an enemy sends back the next amount damage you deal it, till its next turn
        hit2      ; amount damage twice
        junk      ; an enemy puts amount hairball dice (encounters.JUNK_DIE) in your bag this fight
        cough))   ; the hairball face: the die is coughed up, out of the bag for the fight

; a die face. name: what the log and the bottom text call it; text: what it does, # standing
; for the amount (after boosts); caption: under the die in the tray, 2 characters at most;
; cost: mana; icon: the tile in the tray; upgrade: the face row it becomes when upgraded,
; state.NOTHING for none
(struct Action ((name (ptr u8))
        (text (ptr u8))
        (caption (ptr u8))
        (effect Effect)
        (amount u8)
        (cost u8)
        (aim state.Aim)
        (motion state.Motion)
        (icon u8)
        (upgrade u8)))

; an enemy's move: text for the bottom text and the log (no name, # its number, 21 characters
; at most), icon the glyph over its head before it acts
(struct Move ((text (ptr u8))
        (effect Effect)
        (amount u8)
        (aim state.Aim)
        (motion state.Motion)
        (icon u8)))
