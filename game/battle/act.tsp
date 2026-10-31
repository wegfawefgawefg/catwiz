; the action in flight: a die face, an enemy's move or the meow, from its start to its effect
; landing and the actor settling back. Its look comes from the action's motion:
;   lunge  the actor jumps at the target in 2-column steps and lands the effect on contact
;   throw  the actor winds up, a bolt arcs across to the target, the effect lands with it
;   hop    the actor shows its happy (hero) or idle face a moment, then the effect lands (no
;          lift: the hero is 87 rows, each height a redraw of her on both pages)

(import state)
(import art/sprites art)
(import content/effects fx)
(import content/foes)
(import content/items)
(import content/moves mv)
(import battle/place)
(import battle/look)

(const WINDUP u8 6)
(const TRAVEL u8 8)
(const HOLD u8 6)
(const SETTLE u8 8)
(const LUNGE_STEP u8 4) ; byte columns a jump, the last one shorter

; every change of the picture is drawn before the next (main.tsp), so motions change it every
; few frames, each change worth seeing: a jump of 4 columns, the bolt every other frame

; how high the bolt rides over the straight line, by step of its flight
(const ARC (array u8 9) (make (array u8 9) 0 7 11 13 14 13 11 7 0))

(const HOP_WAIT u8 6) ; frames of the face before the effect lands

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
    (if (= by state.HERO)
        (look.show_mood by
            (if hop
                state.Mood.happy
                state.Mood.attack)
            24)
        (look.show_mood by
            (if hop
                state.Mood.idle
                state.Mood.angry)
            24)))

; the action in flight's motion: a move's from its table, a face thrown at an enemy (or a hop
; when it is for her); a lunge with another fighter standing between the two is thrown instead,
; so no one is ever drawn through another (their frames are solid)
(fn action_motion () state.Motion
    (let m state.Motion (match state.act_source
        (state.Source.face
            (if (= (at items.ITEMS state.act_row aim) state.Aim.self)
                state.Motion.hop
                state.Motion.throw))
        (state.Source.move (mv.motion state.act_row))
        (state.Source.meow state.Motion.hop)))
    (if (and (= m state.Motion.lunge) (blocked state.act_by state.act_on))
        state.Motion.throw
        m))

; whether a fighter still standing is between by and target
(fn blocked ((by u8) (target u8)) bool
    (let a u8 (at state.actors by home))
    (let b u8 (at state.actors target home))
    (if (> a b)
        (do
            (let swap u8 a)
            (set a b)
            (set b swap)))
    (for k u8 0 state.ACTORS
        (if (and (and (!= k by) (!= k target)) (at state.actors k alive))
            (do
                (let h u8 (at state.actors k home))
                (if (and (> h a) (< h b))
                    (return true)))))
    false)

(fn land () void
    (match state.act_source
        (state.Source.face (fx.land_face state.act_row state.act_on))
        (state.Source.move (foes.land_move state.act_row state.act_by state.act_on))
        (state.Source.meow))
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
    ; a step short of touching: its frames are wider than its spot, and boxes that meet draw
    ; the other again
    (if (> gap 10)
        (set gap 10))
    (if (>= gap 4)
        (set gap (- gap 2)))
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
    (let facing i8 (place.facing by))
    (if (not state.act_done)
        (do
            (let far u8 (reach by state.act_on))
            (if (< moved far)
                (do
                    ; a jump: up off the ground on the way, down on contact
                    (let n u8 (- far moved))
                    (if (> n LUNGE_STEP)
                        (set n LUNGE_STEP))
                    (set (at state.actors by col) (as u8 (+ (as i8 col) (* facing (as i8 n)))))
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
            (let n u8 moved)
            (if (> n LUNGE_STEP)
                (set n LUNGE_STEP))
            (set (at state.actors by col) (as u8 (- (as i8 col) (* facing (as i8 n)))))
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
    ; the bolt flies from just in front of by to the target's middle, k steps of TRAVEL (8)
    ; along: k eighths of the way, added up a step a frame rather than multiplied, so the game
    ; needs no multiply routine. It starts clear of by, so it never has to be drawn over it
    (let target u8 state.act_on)
    (let x0 i16 (as i16 (place.front by)))
    (let y0 i16 (as i16 (place.hand_y by)))
    (if (= k 0)
        (do
            (set state.bolt_sx 0)
            (set state.bolt_sy 0)))
    (let col i16 (+ x0 (>> state.bolt_sx 3)))
    (let top i16 (+ y0 (>> state.bolt_sy 3)))
    (set state.bolt_sx (+ state.bolt_sx (- (as i16 (place.middle target)) x0)))
    (set state.bolt_sy (+ state.bolt_sy (- (as i16 (+ (place.top target) 8)) y0)))
    ; it moves on every other step: 4 hops along the arc
    (if (= (& k 1) 0)
        (do
            (set state.bolt_col (& (as u8 col) 0xFE))
            (set state.bolt_top (- (as u8 top) (at ARC k)))))
    (set state.bolt_on true)
    false)

(fn hop_step ((t u8)) bool
    (if state.act_done
        (return (>= t SETTLE)))
    (if (< t HOP_WAIT)
        (return false))
    (land)
    false)
