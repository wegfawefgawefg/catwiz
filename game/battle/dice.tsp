; the hero's dice: five identical dice (six with a sixth toe), each die's six faces her six item
; slots, so a face shows the item in its slot (state.items). Die d sits in tray slot d. A turn
; deals every die no enemy holds; a roll gives each unplayed one a random face; a slot a hairball
; clogs shows the hairball on every die until a re-roll of a die showing it coughs it up.

(import random)
(import state)
(import content/items)
(import battle/log)

; the log's sentences, in aux memory (battle/log reads them there): SAY_ and their words
(const SAY (array (ptr u8) 1) (make (array (ptr u8) 1) "Hack! A hairball coughed up.") :strings aux)

(const SAY_HACK_HAIRBALL_COUGHED u8 0)

; a fight's start: every die back, no hairball
(fn gather () void
    (for d u8 0 state.DICE_MOST
        (set (at state.held d) state.NOTHING)
        (set (at state.clogged d) false)))

; a new turn: the dice an enemy holds stay out (played, their cards gone from the tray), as do
; the slots past the dice she rolls
(fn deal () void
    (for d u8 0 state.DICE_MOST
        (let held bool (!= (at state.held d) state.NOTHING))
        (if held
            (set state.hud_dice (| state.hud_dice (<< 1 d))))
        (set (at state.played d) (or (>= d state.dice_n) held))))

; 0 to 5, from a random byte times 6 over 256: no division routine
(fn random_face () u8
    (as u8 (>> (* (as u16 (random.byte)) (as u16 state.SLOTS)) 8)))

; the item face f shows: the slot's, or a hairball
(fn item_on ((f u8)) u8
    (if (at state.clogged f)
        items.HAIRBALL
        (at state.items f)))

; die d lands on a random face
(fn roll ((d u8)) void
    (let f u8 (random_face))
    (set (at state.face_of d) f)
    (set (at state.hand d) (item_on f)))

; a re-roll: the hairballs the unplayed dice show are coughed up, their slots back on every die
(fn cough () void
    (set state.rerolled true)
    (for d u8 0 state.DICE_MOST
        (if (and (not (at state.played d)) (= (at state.hand d) items.HAIRBALL))
            (do
                (set (at state.clogged (at state.face_of d)) false)
                (log.line (at SAY SAY_HACK_HAIRBALL_COUGHED) 0)))))
