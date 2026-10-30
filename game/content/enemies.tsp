; the forest's enemies and their moves. An enemy makes its moves in order, round and round,
; starting from a random one; a move's icon is the glyph shown over its head before it acts.

(import state)
(import content/effects fx)
(import art/sprites art)

(struct Enemy ((hp u8)
        (figure u8)     ; the art kind that draws it
        (first_move u8) ; its moves are rows first_move to first_move + move_count - 1
        (move_count u8)))

(const PUFFCAP u8 0)
(const SPORELET u8 1)
(const NIGHTFLAP u8 2)

(let enemies (array Enemy 3)
    (make (array Enemy 3)
        (make Enemy :hp 16 :figure art.KIND_CAP_BIG :first_move 0 :move_count 3)
        (make Enemy :hp 11 :figure art.KIND_CAP_SMALL :first_move 3 :move_count 2)
        (make Enemy :hp 9 :figure art.KIND_BAT :first_move 5 :move_count 3)))

; glyphs: 33 ! sword, 35 # shield, 37 % flame, 64 @ ghost
(let moves (array fx.Action 8)
    (make (array fx.Action 8)
        ; puffcap: a heavy head-butt, a hunker down, a bigger head-butt
        (make fx.Action
            :effect fx.Effect.bite
            :amount 5
            :motion state.Motion.lunge
            :aim state.Aim.foe
            :icon 33)
        (make fx.Action
            :effect fx.Effect.guard
            :amount 5
            :motion state.Motion.hop
            :aim state.Aim.self
            :icon 35)
        (make fx.Action
            :effect fx.Effect.bite
            :amount 7
            :motion state.Motion.lunge
            :aim state.Aim.foe
            :icon 33)
        ; sporelet: hot spores, then a nip
        (make fx.Action
            :effect fx.Effect.ember
            :amount 3
            :motion state.Motion.throw
            :aim state.Aim.foe
            :icon 37)
        (make fx.Action
            :effect fx.Effect.bite
            :amount 4
            :motion state.Motion.lunge
            :aim state.Aim.foe
            :icon 33)
        ; nightflap: a swoop, a screech that spooks, a swoop
        (make fx.Action
            :effect fx.Effect.bite
            :amount 4
            :motion state.Motion.lunge
            :aim state.Aim.foe
            :icon 33)
        (make fx.Action
            :effect fx.Effect.boo
            :amount 2
            :motion state.Motion.throw
            :aim state.Aim.foe
            :icon 64)
        (make fx.Action
            :effect fx.Effect.bite
            :amount 5
            :motion state.Motion.lunge
            :aim state.Aim.foe
            :icon 33)))

(fn name ((kind u8)) (ptr u8)
    (match kind
        (PUFFCAP "PUFFCAP")
        (SPORELET "SPORELET")
        (_ "NIGHTFLAP")))
