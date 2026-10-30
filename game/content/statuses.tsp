; the statuses an actor can carry, as stacks (state.stack), and when each one acts. The engine
; calls the four hooks below at the right moments and never names a status itself.

(import state)

(enum Status (shield burn spook))

(const STATUS_COUNT u8 3)

; the hud glyph for each, in the font
(const GLYPH (array u8 3) (make (array u8 3) '#' '%' '@'))

; at the start of who's turn: last turn's shield is gone
(fn turn_start ((who u8)) void
    (state.set_stack who (as u8 Status.shield) 0))

; at the end of who's turn: burn hurts and dies down, spook wears off a little. Gives the
; damage the statuses do to who
(fn turn_end ((who u8)) u8
    (let burn u8 (state.stack who (as u8 Status.burn)))
    (if (> burn 0)
        (state.set_stack who (as u8 Status.burn) (- burn 1)))
    (let spook u8 (state.stack who (as u8 Status.spook)))
    (if (> spook 0)
        (state.set_stack who (as u8 Status.spook) (- spook 1)))
    burn)

; a hit who makes, after their statuses: spook takes off its stacks
(fn dealt ((who u8) (damage u8)) u8
    (let spook u8 (state.stack who (as u8 Status.spook)))
    (if (>= spook damage)
        (return 0))
    (- damage spook))

; a hit who takes, after their statuses: shield soaks it up and is used up by it
(fn taken ((who u8) (damage u8)) u8
    (let shield u8 (state.stack who (as u8 Status.shield)))
    (if (>= shield damage)
        (do
            (state.set_stack who (as u8 Status.shield) (- shield damage))
            (return 0)))
    (state.set_stack who (as u8 Status.shield) 0)
    (- damage shield))
