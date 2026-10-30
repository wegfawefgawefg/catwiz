; PROPOSAL (tools/sim, docs/balance.md): game/content/enemies.tsp for fights 1-10 and the boss.
; An enemy makes its moves (content/moves.tsp) in order, round and round, from its first. New
; fields: calls (the kind its summon brings into empty spots; they wait a round), then (what it
; becomes when beaten, with that kind's full hit points, after a round to get up: the possum
; that faked it, the elites' second forms, the boss's phases) and stall (it skips its move after
; losing this many hit points in one of your turns: the lawnmower). Figures are placeholders:
; each new enemy needs its art.

(import state)
(import content/action ac)
(import art/sprites art)

(struct Enemy ((name (ptr u8))
        (hp u8)
        (ward u8)       ; ward pips: each curse breaks one instead of landing
        (figure u8)     ; the art kind that draws it
        (first_move u8) ; its moves are rows first_move to first_move + move_count - 1
        (move_count u8)
        (calls u8)   ; the kind its summon calls, NOTHING for none
        (then u8)    ; the kind it becomes when beaten, NOTHING for none
        (stall u8))) ; it stalls after losing this much in a turn, 0 for never

(const PUFFCAP u8 0)
(const SPORELET u8 1)
(const NIGHTFLAP u8 2)
(const GNOME u8 3)
(const POSSUM u8 4)
(const POSSUM_UP u8 5)
(const SQUIRREL u8 6)
(const ROOMBA u8 7)
(const DUST_BUNNY u8 8)
(const CUCUMBER u8 9)
(const SPRINKLER u8 10)
(const HOOVER u8 11)
(const MOWER u8 12)
(const MAILMAN u8 13)
(const VET u8 14)
(const BATH u8 15)
(const GREMLIN u8 16)
(const KING u8 17)
(const KING_2 u8 18)
(const KING_3 u8 19)
(const PUG u8 20)

(const ENEMIES (array Enemy 21)
    (make (array Enemy 21)
        (make Enemy
            :name "PUFFCAP"
            :hp 6
            :ward 0
            :figure art.KIND_CAP_BIG
            :first_move 0
            :move_count 2
            :calls state.NOTHING
            :then state.NOTHING
            :stall 0)
        (make Enemy
            :name "SPORELET"
            :hp 4
            :ward 0
            :figure art.KIND_CAP_SMALL
            :first_move 2
            :move_count 2
            :calls state.NOTHING
            :then state.NOTHING
            :stall 0)
        (make Enemy
            :name "NIGHTFLAP"
            :hp 5
            :ward 1
            :figure art.KIND_BAT
            :first_move 4
            :move_count 3
            :calls state.NOTHING
            :then state.NOTHING
            :stall 0)
        (make Enemy
            :name "GARDEN GNOME"
            :hp 9
            :ward 1
            :figure art.KIND_CAP_BIG
            :first_move 7
            :move_count 2
            :calls state.NOTHING
            :then state.NOTHING
            :stall 0)
        (make Enemy
            :name "POSSUM"
            :hp 8
            :ward 0
            :figure art.KIND_CAP_BIG
            :first_move 9
            :move_count 2
            :calls state.NOTHING
            :then POSSUM_UP
            :stall 0)
        (make Enemy
            :name "POSSUM (FAKED IT)"
            :hp 4
            :ward 0
            :figure art.KIND_CAP_BIG
            :first_move 11
            :move_count 1
            :calls state.NOTHING
            :then state.NOTHING
            :stall 0)
        (make Enemy
            :name "SQUIRREL"
            :hp 5
            :ward 0
            :figure art.KIND_CAP_SMALL
            :first_move 12
            :move_count 2
            :calls state.NOTHING
            :then state.NOTHING
            :stall 0)
        (make Enemy
            :name "ROOMBA"
            :hp 12
            :ward 0
            :figure art.KIND_CAP_BIG
            :first_move 14
            :move_count 3
            :calls state.NOTHING
            :then state.NOTHING
            :stall 0)
        (make Enemy
            :name "DUST BUNNY"
            :hp 2
            :ward 0
            :figure art.KIND_CAP_SMALL
            :first_move 17
            :move_count 2
            :calls state.NOTHING
            :then state.NOTHING
            :stall 0)
        (make Enemy
            :name "CUCUMBER"
            :hp 6
            :ward 1
            :figure art.KIND_CAP_SMALL
            :first_move 19
            :move_count 2
            :calls state.NOTHING
            :then state.NOTHING
            :stall 0)
        (make Enemy
            :name "SPRINKLER"
            :hp 7
            :ward 0
            :figure art.KIND_CAP_SMALL
            :first_move 21
            :move_count 2
            :calls state.NOTHING
            :then state.NOTHING
            :stall 0)
        (make Enemy
            :name "HOOVER JR."
            :hp 16
            :ward 1
            :figure art.KIND_CAP_BIG
            :first_move 23
            :move_count 3
            :calls DUST_BUNNY
            :then state.NOTHING
            :stall 0)
        (make Enemy
            :name "LAWNMOWER"
            :hp 18
            :ward 2
            :figure art.KIND_CAP_BIG
            :first_move 26
            :move_count 2
            :calls state.NOTHING
            :then state.NOTHING
            :stall 8)
        (make Enemy
            :name "THE MAILMAN"
            :hp 28
            :ward 2
            :figure art.KIND_CAP_BIG
            :first_move 28
            :move_count 4
            :calls state.NOTHING
            :then state.NOTHING
            :stall 0)
        (make Enemy
            :name "THE VET"
            :hp 34
            :ward 2
            :figure art.KIND_CAP_BIG
            :first_move 32
            :move_count 5
            :calls state.NOTHING
            :then state.NOTHING
            :stall 0)
        (make Enemy
            :name "THE BIG BATH"
            :hp 20
            :ward 2
            :figure art.KIND_CAP_BIG
            :first_move 37
            :move_count 3
            :calls state.NOTHING
            :then GREMLIN
            :stall 0)
        (make Enemy
            :name "DRAIN GREMLIN"
            :hp 14
            :ward 0
            :figure art.KIND_CAP_SMALL
            :first_move 40
            :move_count 2
            :calls state.NOTHING
            :then state.NOTHING
            :stall 0)
        (make Enemy
            :name "BULLDOG KING"
            :hp 20
            :ward 2
            :figure art.KIND_CAP_BIG
            :first_move 42
            :move_count 3
            :calls state.NOTHING
            :then KING_2
            :stall 0)
        (make Enemy
            :name "BULLDOG KING, CROSS"
            :hp 20
            :ward 1
            :figure art.KIND_CAP_BIG
            :first_move 45
            :move_count 4
            :calls PUG
            :then KING_3
            :stall 0)
        (make Enemy
            :name "BULLDOG KING, FURIOUS"
            :hp 20
            :ward 0
            :figure art.KIND_CAP_BIG
            :first_move 49
            :move_count 4
            :calls state.NOTHING
            :then state.NOTHING
            :stall 0)
        (make Enemy
            :name "ROYAL PUG"
            :hp 4
            :ward 0
            :figure art.KIND_CAP_SMALL
            :first_move 53
            :move_count 2
            :calls state.NOTHING
            :then state.NOTHING
            :stall 0)))
