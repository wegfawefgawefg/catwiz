; the action in flight: a die face, an enemy's move or the meow, from its start to its effect
; landing and the actor settling back. Its look comes from the action's motion:
;   lunge  the actor jumps at the target in 2-column steps and lands the effect on contact
;   throw  the actor winds up, a bolt arcs across to the target, the effect lands with it (a
;          card's ARC show throws its own sprites)
;   hop    the actor shows its happy (hero) or idle face a moment, then the effect lands (no
;          lift: the hero is 87 rows, each height a redraw of her on both pages); a card's ON
;          show plays over the target meanwhile (content/shows: her own cards' plain hop is
;          the show with no steps)

(import state)
(import art/sprites art)
(import content/play)
(import content/foes)
(import content/items)
(import content/moves mv)
(import content/cards)
(import content/shows)
(import content/move_looks looks)
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

(const HOP_WAIT u8 6)      ; frames of the face before the effect lands
(const ANGRY_FRAMES u8 12) ; a show's angry face on its target

; by starts the action in row row of source's table, aimed at target
(fn begin ((source state.Source) (row u8) (by u8) (target u8)) void
    (set state.act_source source)
    (set state.act_row row)
    (set state.act_by by)
    (set state.act_on target)
    (set state.act_time 0)
    (set state.act_done false)
    (set state.phase state.Phase.acting)
    ; the card's show, or the move's (content/move_looks: the bolt unless it has its own, and
    ; the bolt when a lunge is shot over someone in the way); nothing for the meow. A FOE
    ; show's sprites are roles of the mover's kind
    (shows.start (match source
        (state.Source.face (cards.show row))
        (state.Source.move
            (if (and (= (mv.motion row) state.Motion.lunge) (blocked by target))
                shows.BOLT
                (looks.show row)))
        (state.Source.meow shows.NONE)))
    (if (!= (& state.show_flags shows.FOE) 0)
        (do
            (let kind u8 (at state.actors by figure))
            (set state.show_a (look.frame kind state.show_a))
            (set state.show_b (look.frame kind state.show_b))))
    (set state.bolt_sprite state.show_a)
    (if (!= (& state.show_flags shows.ANGRY) 0)
        (look.show_mood target state.Mood.angry ANGRY_FRAMES))
    (if (= by state.HERO)
        (look.show_mood by
            (if (= target by)
                state.Mood.happy
                state.Mood.attack)
            24)
        (look.show_mood by
            (if (= (action_motion) state.Motion.hop)
                state.Mood.idle
                state.Mood.angry)
            24)))

; the action in flight's motion: a move's from its table, a face's from its show (thrown on an
; ARC, else a hop with the show played over the target); a lunge with another fighter standing between the two is thrown instead,
; so no one is ever drawn through another (their frames are solid)
(fn action_motion () state.Motion
    (let m state.Motion (match state.act_source
        (state.Source.face
            (if (= state.show_way shows.ON)
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
        (state.Source.face (play.land_face state.act_row state.act_on))
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
            (let edge u8 (+ by_home (at art.tab.kcols (at state.actors by figure))))
            (if (> target_home edge)
                (set gap (- target_home edge))))
        (do
            (let edge u8 (+ target_home (at art.tab.kcols (at state.actors target figure))))
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
    ; hold on contact, then step back home; a move's ON show plays over its target meanwhile
    ; (the mower's grass flying), a step every 2 frames
    (if (< t HOLD)
        (do
            (if (and (> state.show_steps 0) (= (& t 1) 0))
                (do
                    (let k u8 (>> t 1))
                    (if (< k state.show_steps)
                        (place_on k)
                        (set state.bolt_on false))))
            (return false)))
    (set state.bolt_on false)
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
            (set state.bolt_top (- (as u8 top) (at ARC k)))
            (set state.bolt_sprite (if (= (& k 2) 0)
                state.show_a
                state.show_b))))
    (set state.bolt_on true)
    false)

; a hop: the face a moment, then the effect lands; with a card's ON show, a step every 2 frames
; at the show's places over the target (its sprites by turns), then the effect lands
(fn hop_step ((t u8)) bool
    (if state.act_done
        (return (>= t SETTLE)))
    (if (= state.show_steps 0)
        (do
            (if (>= t HOP_WAIT)
                (land))
            (return false)))
    (if (!= (& t 1) 0)
        (return false))
    (let k u8 (>> t 1))
    (if (>= k state.show_steps)
        (do
            (set state.bolt_on false)
            (land)
            (return false)))
    (place_on k)
    false)

; step k of the action's ON show over whoever it is for: its place, its sprite by turns
(fn place_on ((k u8)) void
    (let who u8 state.act_on)
    (shows.place (+ state.show_first k))
    (set state.bolt_sprite (if (= (& k 1) 0)
        state.show_a
        state.show_b))
    (set state.bolt_col (+ (at state.actors who home) state.show_col))
    (set state.bolt_top (+ (at art.tab.ktop (at state.actors who figure)) state.show_row))
    (set state.bolt_on true))
