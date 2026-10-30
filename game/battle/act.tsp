; the action in flight: a die face, an enemy's move or the bark, from its start to its effect
; landing and the actor settling back. Its look comes from the action's motion:
;   lunge  the actor jumps at the target in 2-column steps and lands the effect on contact
;   throw  the actor winds up, a bolt arcs across to the target, the effect lands with it
;   hop    the actor hops in place and the effect lands as it comes down

(import state)
(import art/sprites art)
(import content/effects fx)
(import content/dice)
(import content/enemies en)
(import content/encounters enc)
(import battle/place)
(import battle/look)

(const WINDUP u8 6)
(const TRAVEL u8 8)
(const HOLD u8 6)
(const SETTLE u8 12)

; how high the bolt rides over the straight line, by step of its flight
(const ARC (array u8 9) (make (array u8 9) 0 7 11 13 14 13 11 7 0))

; up 2, 4, 6, 6, 4, 2, then down to land
(const HOP (array u8 6) (make (array u8 6) 2 4 6 6 4 2))

; by starts the action in row row of source's table, aimed at target
(fn begin ((source state.Source) (row u8) (by u8) (target u8)) void
    (set state.act_source source)
    (set state.act_row row)
    (set state.act_by by)
    (set state.act_on target)
    (set state.act_time 0)
    (set state.act_done false)
    (set state.phase state.Phase.acting)
    (let hop bool (= (action_motion) state.Motion.hop))
    (if (= by state.DOG)
        (look.show_mood by
            (if hop
                state.Mood.happy
                state.Mood.bark)
            24)
        (look.show_mood by
            (if hop
                state.Mood.idle
                state.Mood.angry)
            24)))

; the action in flight, from its table
(fn action_effect () fx.Effect
    (match state.act_source
        (state.Source.face (at dice.FACES state.act_row effect))
        (state.Source.move (at en.MOVES state.act_row effect))
        (state.Source.bark enc.HERO.bark.effect)))

(fn action_amount () u8
    (match state.act_source
        (state.Source.face (at dice.FACES state.act_row amount))
        (state.Source.move (at en.MOVES state.act_row amount))
        (state.Source.bark enc.HERO.bark.amount)))

(fn action_motion () state.Motion
    (match state.act_source
        (state.Source.face (at dice.FACES state.act_row motion))
        (state.Source.move (at en.MOVES state.act_row motion))
        (state.Source.bark enc.HERO.bark.motion)))

(fn land () void
    (fx.apply (action_effect) state.act_by state.act_on (action_amount))
    (set state.act_done true)
    (set state.act_time 0))

; one frame of the action; true once it is over
(fn step () bool
    (let t u8 state.act_time)
    (set state.act_time (+ t 1))
    (match (action_motion)
        (state.Motion.lunge (lunge_step t))
        (state.Motion.throw (throw_step t))
        (state.Motion.hop (hop_step t))))

; how far by jumps towards target: to just short of it, in whole 2-column steps
(fn reach ((by u8) (target u8)) u8
    (let by_home u8 (at state.actors by home))
    (let target_home u8 (at state.actors target home))
    (let gap u8 0)
    (if (< by_home target_home)
        (do
            (let edge u8 (+ by_home (at art.KIND_COLS (at state.actors by figure))))
            (if (> target_home edge)
                (set gap (- target_home edge))))
        (do
            (let edge u8 (+ target_home (at art.KIND_COLS (at state.actors target figure))))
            (if (> by_home edge)
                (set gap (- by_home edge)))))
    (if (> gap 10)
        (set gap 10))
    (if (< gap 2)
        (set gap 2))
    (& gap 0xFE))

(fn lunge_step ((t u8)) bool
    (let by u8 state.act_by)
    (let home u8 (at state.actors by home))
    (let col u8 (at state.actors by col))
    (let moved u8 (if (> col home)
        (- col home)
        (- home col)))
    (let step i8 (* (place.facing by) 2))
    (if (not state.act_done)
        (do
            (if (< moved (reach by state.act_on))
                (do
                    ; a jump: up off the ground on the way, down on contact
                    (set (at state.actors by col) (as u8 (+ (as i8 col) step)))
                    (set (at state.actors by lift) 4)
                    (return false)))
            (set (at state.actors by lift) 0)
            (land)
            (return false)))
    ; hold on contact, then step back home
    (if (< t HOLD)
        (return false))
    (if (> moved 0)
        (do
            (set (at state.actors by col) (as u8 (- (as i8 col) step)))
            (return false)))
    (>= t (+ HOLD SETTLE)))

(fn throw_step ((t u8)) bool
    (let by u8 state.act_by)
    (if state.act_done
        (return (>= t SETTLE)))
    (if (< t WINDUP)
        (return false))
    (let k u8 (- t WINDUP))
    (if (> k TRAVEL)
        (do
            (set state.bolt_on false)
            (land)
            (return false)))
    ; the bolt flies from just in front of by to the target's middle, k steps of TRAVEL along.
    ; It starts clear of by, so it never has to be drawn over it
    (let target u8 state.act_on)
    (let x0 i16 (as i16 (place.front by)))
    (let x1 i16 (as i16 (place.middle target)))
    (let y0 i16 (as i16 (place.hand_y by)))
    (let y1 i16 (as i16 (+ (place.top target) 8)))
    (let kk i16 (as i16 k))
    (let col i16 (+ x0 (/ (* (- x1 x0) kk) (as i16 TRAVEL))))
    (let top i16 (+ y0 (/ (* (- y1 y0) kk) (as i16 TRAVEL))))
    (set state.bolt_col (- (as u8 col) 2))
    (set state.bolt_top (- (as u8 top) (at ARC k)))
    (set state.bolt_on true)
    false)

(fn hop_step ((t u8)) bool
    (let by u8 state.act_by)
    (if state.act_done
        (return (>= t SETTLE)))
    (if (< t 6)
        (do
            (set (at state.actors by lift) (at HOP t))
            (return false)))
    (set (at state.actors by lift) 0)
    (land)
    false)
