; the enemies, fights 1-10 and the boss. An enemy makes its moves (content/moves.tsp) in order,
; round and round, from its first. calls: the kind its summon brings into empty spots (they wait
; a round); then: what it becomes when beaten, with that kind's full hit points, after a round to
; get up (the possum that faked it, the big bath's gremlin, the boss's phases); stall: it skips
; its move after losing this many hit points in one of your turns (the lawnmower). Figures past
; the nightflap are stand-ins (the puffcap's, the sporelet's) until their art is drawn.

(import state)
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
            :name "Puffcap"
            :hp 6
            :ward 0
            :figure art.KIND_PUFFCAP
            :first_move 0
            :move_count 2
            :calls state.NOTHING
            :then state.NOTHING
            :stall 0)
        (make Enemy
            :name "Sporelet"
            :hp 4
            :ward 0
            :figure art.KIND_SPORELET
            :first_move 2
            :move_count 2
            :calls state.NOTHING
            :then state.NOTHING
            :stall 0)
        (make Enemy
            :name "Nightflap"
            :hp 5
            :ward 1
            :figure art.KIND_NIGHTFLAP
            :first_move 4
            :move_count 3
            :calls state.NOTHING
            :then state.NOTHING
            :stall 0)
        (make Enemy
            :name "Garden gnome"
            :hp 11
            :ward 1
            :figure art.KIND_PUFFCAP
            :first_move 7
            :move_count 2
            :calls state.NOTHING
            :then state.NOTHING
            :stall 0)
        (make Enemy
            :name "Possum"
            :hp 9
            :ward 0
            :figure art.KIND_PUFFCAP
            :first_move 9
            :move_count 2
            :calls state.NOTHING
            :then POSSUM_UP
            :stall 0)
        (make Enemy
            :name "Possum (faked it)"
            :hp 4
            :ward 0
            :figure art.KIND_PUFFCAP
            :first_move 11
            :move_count 1
            :calls state.NOTHING
            :then state.NOTHING
            :stall 0)
        (make Enemy
            :name "Squirrel"
            :hp 5
            :ward 0
            :figure art.KIND_SPORELET
            :first_move 12
            :move_count 2
            :calls state.NOTHING
            :then state.NOTHING
            :stall 0)
        (make Enemy
            :name "Roomba"
            :hp 18
            :ward 0
            :figure art.KIND_PUFFCAP
            :first_move 14
            :move_count 3
            :calls state.NOTHING
            :then state.NOTHING
            :stall 0)
        (make Enemy
            :name "Dust bunny"
            :hp 3
            :ward 0
            :figure art.KIND_SPORELET
            :first_move 17
            :move_count 2
            :calls state.NOTHING
            :then state.NOTHING
            :stall 0)
        (make Enemy
            :name "Cucumber"
            :hp 8
            :ward 1
            :figure art.KIND_SPORELET
            :first_move 19
            :move_count 2
            :calls state.NOTHING
            :then state.NOTHING
            :stall 0)
        (make Enemy
            :name "Sprinkler"
            :hp 10
            :ward 0
            :figure art.KIND_SPORELET
            :first_move 21
            :move_count 2
            :calls state.NOTHING
            :then state.NOTHING
            :stall 0)
        (make Enemy
            :name "Hoover Jr."
            :hp 28
            :ward 1
            :figure art.KIND_PUFFCAP
            :first_move 23
            :move_count 3
            :calls DUST_BUNNY
            :then state.NOTHING
            :stall 0)
        (make Enemy
            :name "Lawnmower"
            :hp 32
            :ward 2
            :figure art.KIND_PUFFCAP
            :first_move 26
            :move_count 2
            :calls state.NOTHING
            :then state.NOTHING
            :stall 12)
        (make Enemy
            :name "The mailman"
            :hp 42
            :ward 2
            :figure art.KIND_PUFFCAP
            :first_move 28
            :move_count 4
            :calls state.NOTHING
            :then state.NOTHING
            :stall 0)
        (make Enemy
            :name "The vet"
            :hp 48
            :ward 2
            :figure art.KIND_PUFFCAP
            :first_move 32
            :move_count 5
            :calls state.NOTHING
            :then state.NOTHING
            :stall 0)
        (make Enemy
            :name "The big bath"
            :hp 30
            :ward 2
            :figure art.KIND_PUFFCAP
            :first_move 37
            :move_count 3
            :calls state.NOTHING
            :then GREMLIN
            :stall 0)
        (make Enemy
            :name "Drain gremlin"
            :hp 22
            :ward 0
            :figure art.KIND_SPORELET
            :first_move 40
            :move_count 2
            :calls state.NOTHING
            :then state.NOTHING
            :stall 0)
        (make Enemy
            :name "Bulldog king"
            :hp 26
            :ward 2
            :figure art.KIND_PUFFCAP
            :first_move 42
            :move_count 3
            :calls state.NOTHING
            :then KING_2
            :stall 0)
        (make Enemy
            :name "Bulldog king, cross"
            :hp 26
            :ward 1
            :figure art.KIND_PUFFCAP
            :first_move 45
            :move_count 4
            :calls PUG
            :then KING_3
            :stall 0)
        (make Enemy
            :name "Bulldog king, furious"
            :hp 26
            :ward 0
            :figure art.KIND_PUFFCAP
            :first_move 49
            :move_count 4
            :calls state.NOTHING
            :then state.NOTHING
            :stall 0)
        (make Enemy
            :name "Royal pug"
            :hp 6
            :ward 0
            :figure art.KIND_SPORELET
            :first_move 53
            :move_count 2
            :calls state.NOTHING
            :then state.NOTHING
            :stall 0)) :strings aux)
