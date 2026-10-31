; an enemy comes onto the field: at a fight's start, called in by a friend (a summon) or getting
; up as its next form (an enemy's then). Spot i - 1 of the fight is actor i's place.

(import state)
(import content/enemies en)
(import content/encounters enc)
(import content/statuses st)

; actor i becomes a fresh enemy of kind, standing at its spot, on its first move; fresh: it
; waits a round before its first move (a summon, a then)
(fn enemy ((i u8) (kind u8) (fresh bool)) void
    (let fight enc.Fight (at enc.FIGHTS state.fight))
    (let col u8 (at fight.spots (- i 1) col))
    (let k en.Enemy (at en.ENEMIES kind))
    (set (at state.actors i)
        (make state.Actor
            :alive true
            :kind kind
            :figure k.figure
            :hp k.hp
            :max_hp k.hp
            :col col
            :home col
            :lift 0
            :move k.first_move
            :moves_made 0
            :mood state.Mood.angry
            :mood_time 0
            :flash 0
            :knock 0
            :dying 0))
    (st.start i kind)
    (if fresh
        (state.set_stack i (as u8 st.Status.fresh) 1)))

; nobody at actor i
(fn nobody ((i u8)) void
    (set (at state.actors i alive) false)
    (set (at state.actors i kind) state.NOTHING)
    (set (at state.actors i dying) 0))
