; the statuses an actor can carry, as stacks (state.stack), and when each one acts. The engine
; calls the hooks below at the right moments and never names a status itself; the hud shows
; them by the tables here.

(import state)
(import battle/log)
(import content/enemies en)

(enum Status (shield ; soaks hits until the holder's next turn
        poison       ; fleas: damage at the end of each of its turns
        flea_turns   ; turns of fleas left
        wet          ; deals half damage this turn
        hiss         ; skips its next move
        cheer        ; its next hit does this much more
        ward         ; pips: each curse breaks one instead of landing
        box          ; the hero in a box: hit-all attacks miss
        mana         ; the hero's mana
        plus         ; the next die played gets this much more
        double))     ; and is doubled this many times

(const STATUS_COUNT u8 11)

; how the hud shows each: under the hit points as glyph and number, as a glyph alone, as one
; glyph per stack in the hit point pill, or not at all
(enum Show (count flag pips hidden))

(const SHOW (array Show 11)
    (make (array Show 11)
        Show.count Show.count Show.hidden Show.flag Show.flag Show.count Show.pips Show.flag
        Show.count Show.count Show.flag))

; the glyphs, in the hud font: # shield, , fleas (a bug), < buff, ; ward pip (a solid
; shield), ' mana pip (a star), + plus; letters for the rest
(const GLYPH (array u8 11) (make (array u8 11) '#' ',' ' ' 'W' 'Z' '<' ';' 'B' '\'' '+' 'X'))

; in words, for the bottom text: a name, then the stack's number for counts
(const NAME (array (ptr u8) 11)
    (make (array (ptr u8) 11)
        "SHIELD" "FLEAS" "" "WET" "HISSED" "CHEERED +" "WARD" "IN A BOX" "MANA" "NEXT +"
        "NEXT X2"))

; a new fight: no stacks, and the ward its kind has (the hero: kind NOTHING)
(fn start ((who u8) (kind u8)) void
    (for s u8 0 STATUS_COUNT
        (state.set_stack who s 0))
    (if (!= kind state.NOTHING)
        (state.set_stack who (as u8 Status.ward) (at en.ENEMIES kind ward))))

; at the start of who's turn: last turn's shield and box are gone
(fn turn_start ((who u8)) void
    (state.set_stack who (as u8 Status.shield) 0)
    (state.set_stack who (as u8 Status.box) 0))

; at the end of who's turn: wet dries, fleas bite. Gives the damage for the engine to take off
(fn turn_end ((who u8)) u8
    (state.set_stack who (as u8 Status.wet) 0)
    (let turns u8 (state.stack who (as u8 Status.flea_turns)))
    (if (= turns 0)
        (return 0))
    (let bite u8 (state.stack who (as u8 Status.poison)))
    (state.set_stack who (as u8 Status.flea_turns) (- turns 1))
    (if (= turns 1)
        (state.set_stack who (as u8 Status.poison) 0))
    (log.who who " TAKES # FROM FLEAS." bite)
    bite)

; whether who skips the move it was going to make (hissed at); the hiss is used up
(fn skips ((who u8)) bool
    (if (= (state.stack who (as u8 Status.hiss)) 0)
        (return false))
    (state.set_stack who (as u8 Status.hiss) 0)
    (log.who who " SKIPS ITS MOVE." 0)
    true)

; a hit who makes, after their statuses: cheer adds (used up when the hit is made, use),
; then wet halves
(fn dealt ((who u8) (damage u8) (use bool)) u8
    (let cheer u8 (state.stack who (as u8 Status.cheer)))
    (if use
        (state.set_stack who (as u8 Status.cheer) 0))
    (let d u8 (+ damage cheer))
    (if (> (state.stack who (as u8 Status.wet)) 0)
        (set d (>> d 1)))
    d)

; a hit who takes, after their statuses: shield soaks it up and is used up by it
(fn taken ((who u8) (damage u8)) u8
    (let shield u8 (state.stack who (as u8 Status.shield)))
    (if (>= shield damage)
        (do
            (state.set_stack who (as u8 Status.shield) (- shield damage))
            (return 0)))
    (state.set_stack who (as u8 Status.shield) 0)
    (- damage shield))
