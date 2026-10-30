; where actors stand on the screen, from their art: the ground line, each one's top row and
; middle

(import state)
(import art/sprites art)

(const GROUND u8 104) ; the row actors stand on, as in the art

; the top row of who's sprite when it stands still
(fn top ((who u8)) u8
    (- GROUND (at art.KIND_FOOT (at state.actors who figure))))

; the byte column at the middle of who's spot
(fn middle ((who u8)) u8
    (+ (at state.actors who home) (>> (at art.KIND_COLS (at state.actors who figure)) 1)))

; the pixel at the middle of who's spot
(fn centre_x ((who u8)) u16
    (let cols u8 (at art.KIND_COLS (at state.actors who figure)))
    (+ (* (as u16 (at state.actors who home)) 7) (as u16 (/ (* cols 7) 2))))

; which way who faces: +1 for the dog, looking right at the enemies; -1 for them
(fn facing ((who u8)) i8
    (if (= who state.DOG)
        1
        -1))

; the byte column just in front of who, where a thrown bolt starts (the bolt is 4 wide)
(fn front ((who u8)) u8
    (let home u8 (at state.actors who home))
    (if (= who state.DOG)
        (return (+ (+ home (at art.KIND_COLS (at state.actors who figure))) 2)))
    (- home 2))

; the row a thrown bolt starts at: a little above who's middle, so it clears the heads of
; whoever stands in front
(fn hand_y ((who u8)) u8
    (let rows u8 (- GROUND (top who)))
    (- (+ (top who) (>> rows 1)) 6))
