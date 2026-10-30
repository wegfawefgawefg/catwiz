; the forest's enemies and their moves. An enemy makes its moves in order, round and round,
; from its first; a move's icon is the glyph shown over its head before it acts, and its text
; what the bottom line says it will do (# the number it will do it for).

(import state)
(import content/action ac)
(import art/sprites art)

(struct Enemy ((name (ptr u8))
        (hp u8)
        (ward u8)       ; ward pips: each curse breaks one instead of landing
        (figure u8)     ; the art kind that draws it
        (first_move u8) ; its moves are rows first_move to first_move + move_count - 1
        (move_count u8)))

(const PUFFCAP u8 0)
(const SPORELET u8 1)
(const NIGHTFLAP u8 2)

(const ENEMIES (array Enemy 3)
    (make (array Enemy 3)
        (make Enemy
            :name "PUFFCAP"
            :hp 9
            :ward 0
            :figure art.KIND_CAP_BIG
            :first_move 0
            :move_count 2)
        (make Enemy
            :name "SPORELET"
            :hp 6
            :ward 0
            :figure art.KIND_CAP_SMALL
            :first_move 2
            :move_count 2)
        (make Enemy
            :name "NIGHTFLAP"
            :hp 9
            :ward 1
            :figure art.KIND_BAT
            :first_move 4
            :move_count 3)))

(const MOVES (array ac.Action 7)
    (make (array ac.Action 7)
        ; puffcap: a head-butt, then hunkers down under spores
        (make ac.Action
            :name "HEADBUTT"
            :text "HEADBUTT FOR #"
            :caption ""
            :effect ac.Effect.hit
            :amount 2
            :cost 0
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!'
            :upgrade state.NOTHING)
        (make ac.Action
            :name "SPORE SHIELD"
            :text "SPORE SHIELD #"
            :caption ""
            :effect ac.Effect.shield
            :amount 3
            :cost 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '#'
            :upgrade state.NOTHING)
        ; sporelet: a nip, then cheers its friend on
        (make ac.Action
            :name "NIP"
            :text "NIP FOR #"
            :caption ""
            :effect ac.Effect.hit
            :amount 1
            :cost 0
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!'
            :upgrade state.NOTHING)
        (make ac.Action
            :name "CHEER"
            :text "CHEER: A FRIEND HITS +# NEXT"
            :caption ""
            :effect ac.Effect.cheer
            :amount 1
            :cost 0
            :aim state.Aim.friend
            :motion state.Motion.hop
            :icon '+'
            :upgrade state.NOTHING)
        ; nightflap: two bites, then a dive every third turn
        (make ac.Action
            :name "BITE"
            :text "BITE FOR #"
            :caption ""
            :effect ac.Effect.hit
            :amount 3
            :cost 0
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!'
            :upgrade state.NOTHING)
        (make ac.Action
            :name "BITE"
            :text "BITE FOR #"
            :caption ""
            :effect ac.Effect.hit
            :amount 3
            :cost 0
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!'
            :upgrade state.NOTHING)
        (make ac.Action
            :name "DIVE"
            :text "DIVE FOR #"
            :caption ""
            :effect ac.Effect.hit
            :amount 5
            :cost 0
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!'
            :upgrade state.NOTHING)))
