; where actors stand on the screen, from their art: each kind's idle frame is drawn where it
; stands (art.KIND_TOP, its top row, and KIND_FEET, the row under its feet), at the actor's
; home byte column; its middle and front from there. A byte column is 3.5 pixels.

(import state)
(import art/sprites art)

; the top row of who's idle frame when it stands still
(fn top ((who u8)) u8
    (at art.KIND_TOP (at state.actors who figure)))

; the row under who's feet
(fn feet ((who u8)) u8
    (at art.KIND_FEET (at state.actors who figure)))

; the byte column at the middle of who's spot
(fn middle ((who u8)) u8
    (+ (at state.actors who home) (>> (at art.KIND_COLS (at state.actors who figure)) 1)))

; the pixel at the middle of who's spot
(fn centre_x ((who u8)) u8
    (let cols u16
        (as u16
            (+ (<< (at state.actors who home) 1) (at art.KIND_COLS (at state.actors who figure)))))
    (as u8 (>> (* cols 7) 2)))

; which way who faces: +1 for the hero, looking right at the enemies; -1 for them
(fn facing ((who u8)) i8
    (if (= who state.HERO)
        1
        -1))

; the byte column just in front of who, where a thrown bolt starts (the bolt is 2 wide)
(fn front ((who u8)) u8
    (let home u8 (at state.actors who home))
    (if (= who state.HERO)
        (return (+ home (at art.KIND_COLS (at state.actors who figure)))))
    (- home 2))

; the row a thrown bolt starts at: a little above who's middle, so it clears the heads of
; whoever stands in front
(fn hand_y ((who u8)) u8
    (let rows u8 (- (feet who) (top who)))
    (- (+ (top who) (>> rows 1)) 6))
