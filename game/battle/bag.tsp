; the hero's bag of dice. A run starts with the starting dice in it, and rewards add dice to it
; or take them out. Each turn the tray takes HAND dice from the draw pile, at random; the ones
; in the tray go to the discard at the next turn, played or not. When the draw pile runs out,
; the discard is shuffled back into it, so every die comes up in its turn. A fight starts with
; the whole bag in the draw pile.

(import random)
(import state)
(import content/faces)
(import battle/log)

; a run's start: the starting dice
(fn fill () void
    (for d u8 0 faces.DIE_COUNT
        (for f u8 0 state.DIE_FACES
            (set (at state.dice (+ (* d state.DIE_FACES) f))
                (at (at faces.STARTING_DICE d faces) f))))
    (set state.bag faces.DIE_COUNT))

; a fight's start: every die in the draw pile, none in the tray
(fn gather () void
    (for d u8 0 state.BAG_MOST
        (set (at state.in_draw d) (< d state.bag)))
    (for s u8 0 state.HAND
        (set (at state.tray_die s) state.NOTHING)))

; the dice in the draw pile
(fn draw_count () u8
    (let n u8 0)
    (for d u8 0 state.bag
        (if (at state.in_draw d)
            (set n (+ n 1))))
    n)

(fn in_tray ((d u8)) bool
    (for s u8 0 state.HAND
        (if (= (at state.tray_die s) d)
            (return true)))
    false)

; the discard back into the draw pile: every die not in the tray
(fn reshuffle () void
    (if (log.once log.HINT_SHUFFLE)
        (log.line "BAG EMPTY: USED DICE SHUFFLED BACK IN." 0))
    (for d u8 0 state.bag
        (if (not (in_tray d))
            (set (at state.in_draw d) true))))

; one die from the draw pile at random, out of it; NOTHING when there is none
(fn draw_one () u8
    (if (= (draw_count) 0)
        (reshuffle))
    (let n u8 (draw_count))
    (if (= n 0)
        (return state.NOTHING))
    ; 0 to n - 1 without a division routine: a random 0 to 7 until it is below n
    (let k u8 (& (random.byte) 7))
    (while (>= k n)
        (set k (& (random.byte) 7)))
    (for d u8 0 state.bag
        (if (at state.in_draw d)
            (do
                (if (= k 0)
                    (do
                        (set (at state.in_draw d) false)
                        (return d)))
                (set k (- k 1)))))
    state.NOTHING)

; a new turn's tray: the dice there go to the discard, and new ones come from the draw pile. A
; slot with no die left (a bag smaller than the tray) stays empty, as if played
(fn deal () void
    (for s u8 0 state.HAND
        (set (at state.tray_die s) state.NOTHING))
    (for s u8 0 state.HAND
        (let d u8 (draw_one))
        (set (at state.tray_die s) d)
        (set (at state.played s) (= d state.NOTHING))))

; die d out of the bag, the ones after it moving down
(fn remove ((d u8)) void
    (for i u8 (* (+ d 1) state.DIE_FACES) (* state.bag state.DIE_FACES)
        (set (at state.dice (- i state.DIE_FACES)) (at state.dice i)))
    (set state.bag (- state.bag 1)))
