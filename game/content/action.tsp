; the row both dice faces (content/faces) and enemy moves (content/enemies) are made of, and
; the kinds of effect they can have. What each kind does is in content/effects.tsp.

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
        hairball  ; spell: amount damage, and fleas
        zoomies   ; spell: amount damage 5 times, enemies left to right
        box       ; spell: amount shield, and hit-all attacks miss until your next turn
        scream    ; spell: amount damage to every enemy, 1 to you
        cheer     ; an enemy's friend hits amount harder next time
        nothing)) ; lint

; name: what the log and the bottom text call it; text: what it does, # standing for the
; amount (after boosts); caption: under the die in the tray, 2 characters at most; cost: mana;
; icon: the tile in the tray, or for an enemy move the glyph over its head; upgrade: the face
; row it becomes when upgraded, state.NOTHING for none
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
