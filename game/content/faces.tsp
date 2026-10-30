; the dice. A face is an item: a row of FACES. The hero's five dice start as STARTING_DICE
; (die d is faces d * 6 to d * 6 + 5) and change with the rewards (content/encounters).

(import state)
(import content/action ac)
(import art/sprites art)

(const DIE_COUNT u8 5)
(const FACES_PER_DIE u8 6)

; face rows, by name
(const WAND_2 u8 0)
(const WAND_3 u8 1)
(const WAND_4 u8 2)
(const KIBBLE_2 u8 3)
(const KIBBLE_3 u8 4)
(const KIBBLE_4 u8 5)
(const BONE_2 u8 6)
(const BONE_3 u8 7)
(const BONE_4 u8 8)
(const GEM u8 9)
(const GEM_2 u8 10)
(const HAIRBALL u8 11)
(const ZOOMIES u8 12)
(const BOX u8 13)
(const SCREAM u8 14)
(const FLEAS u8 15)
(const WET u8 16)
(const HISS u8 17)
(const BATH u8 18)
(const PLUS_1 u8 19)
(const PLUS_2 u8 20)
(const DOUBLE u8 21)
(const LINT u8 22)
(const FACE_COUNT u8 23)

(const FACES (array ac.Action 23)
    (make (array ac.Action 23)
        (make ac.Action
            :name "WAND 2"
            :text "# DAMAGE TO AN ENEMY"
            :caption "2"
            :effect ac.Effect.hit
            :amount 2
            :cost 0
            :aim state.Aim.foe
            :motion state.Motion.throw
            :icon art.TILE_WAND
            :upgrade WAND_3)
        (make ac.Action
            :name "GOLD WAND"
            :text "# DAMAGE TO AN ENEMY"
            :caption "3"
            :effect ac.Effect.hit
            :amount 3
            :cost 0
            :aim state.Aim.foe
            :motion state.Motion.throw
            :icon art.TILE_WAND
            :upgrade WAND_4)
        (make ac.Action
            :name "STAR WAND"
            :text "# DAMAGE TO AN ENEMY"
            :caption "4"
            :effect ac.Effect.hit
            :amount 4
            :cost 0
            :aim state.Aim.foe
            :motion state.Motion.throw
            :icon art.TILE_WAND
            :upgrade state.NOTHING)
        (make ac.Action
            :name "KIBBLE 2"
            :text "SHIELD # TILL YOUR NEXT TURN"
            :caption "2"
            :effect ac.Effect.shield
            :amount 2
            :cost 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon art.TILE_KIBBLE
            :upgrade KIBBLE_3)
        (make ac.Action
            :name "KIBBLE 3"
            :text "SHIELD # TILL YOUR NEXT TURN"
            :caption "3"
            :effect ac.Effect.shield
            :amount 3
            :cost 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon art.TILE_KIBBLE
            :upgrade KIBBLE_4)
        (make ac.Action
            :name "KIBBLE 4"
            :text "SHIELD # TILL YOUR NEXT TURN"
            :caption "4"
            :effect ac.Effect.shield
            :amount 4
            :cost 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon art.TILE_KIBBLE
            :upgrade state.NOTHING)
        (make ac.Action
            :name "BONE 2"
            :text "HEAL #"
            :caption "2"
            :effect ac.Effect.heal
            :amount 2
            :cost 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon art.TILE_BONE
            :upgrade BONE_3)
        (make ac.Action
            :name "BONE 3"
            :text "HEAL #"
            :caption "3"
            :effect ac.Effect.heal
            :amount 3
            :cost 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon art.TILE_BONE
            :upgrade BONE_4)
        (make ac.Action
            :name "BONE 4"
            :text "HEAL #"
            :caption "4"
            :effect ac.Effect.heal
            :amount 4
            :cost 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon art.TILE_BONE
            :upgrade state.NOTHING)
        (make ac.Action
            :name "GEM"
            :text "+# MANA. KEPT ALL FIGHT, 5 AT MOST"
            :caption "1"
            :effect ac.Effect.mana
            :amount 1
            :cost 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon art.TILE_GEM
            :upgrade GEM_2)
        (make ac.Action
            :name "BIG GEM"
            :text "+# MANA. KEPT ALL FIGHT, 5 AT MOST"
            :caption "2"
            :effect ac.Effect.mana
            :amount 2
            :cost 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon art.TILE_GEM
            :upgrade state.NOTHING)
        (make ac.Action
            :name "HAIRBALL"
            :text "2 MANA: # DAMAGE + FLEAS (2 A TURN)"
            :caption "2'"
            :effect ac.Effect.hairball
            :amount 4
            :cost 2
            :aim state.Aim.foe
            :motion state.Motion.throw
            :icon art.TILE_BOOK
            :upgrade state.NOTHING)
        (make ac.Action
            :name "ZOOMIES"
            :text "2 MANA: # DAMAGE 5 TIMES, LEFT TO RIGHT"
            :caption "2'"
            :effect ac.Effect.zoomies
            :amount 1
            :cost 2
            :aim state.Aim.all
            :motion state.Motion.lunge
            :icon art.TILE_BOOK
            :upgrade state.NOTHING)
        (make ac.Action
            :name "CARDBOARD BOX"
            :text "2 MANA: SHIELD #, HIT-ALLS MISS YOU"
            :caption "2'"
            :effect ac.Effect.box
            :amount 6
            :cost 2
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon art.TILE_BOOK
            :upgrade state.NOTHING)
        (make ac.Action
            :name "3 AM SCREAMING"
            :text "3 MANA: # DAMAGE TO ALL, 1 TO YOU"
            :caption "3'"
            :effect ac.Effect.scream
            :amount 3
            :cost 3
            :aim state.Aim.all
            :motion state.Motion.throw
            :icon art.TILE_BOOK
            :upgrade state.NOTHING)
        (make ac.Action
            :name "FLEAS"
            :text "CURSE: # DAMAGE A TURN, 3 TURNS"
            :caption "2"
            :effect ac.Effect.fleas
            :amount 2
            :cost 0
            :aim state.Aim.foe
            :motion state.Motion.throw
            :icon art.TILE_FLEAS
            :upgrade state.NOTHING)
        (make ac.Action
            :name "WET"
            :text "CURSE: HALF DAMAGE ON ITS NEXT TURN"
            :caption ""
            :effect ac.Effect.wet
            :amount 0
            :cost 0
            :aim state.Aim.foe
            :motion state.Motion.throw
            :icon art.TILE_WET
            :upgrade state.NOTHING)
        (make ac.Action
            :name "HISS"
            :text "CURSE: IT SKIPS ITS NEXT MOVE"
            :caption ""
            :effect ac.Effect.hiss
            :amount 0
            :cost 0
            :aim state.Aim.foe
            :motion state.Motion.throw
            :icon art.TILE_HISS
            :upgrade state.NOTHING)
        (make ac.Action
            :name "BATH TIME"
            :text "CURSE: IT LOSES ALL ITS SHIELD"
            :caption ""
            :effect ac.Effect.bath
            :amount 0
            :cost 0
            :aim state.Aim.foe
            :motion state.Motion.throw
            :icon art.TILE_BATH
            :upgrade state.NOTHING)
        (make ac.Action
            :name "PLUS 1"
            :text "THE NEXT DIE YOU PLAY GETS +#"
            :caption "+1"
            :effect ac.Effect.plus
            :amount 1
            :cost 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon art.TILE_PLUS1
            :upgrade PLUS_2)
        (make ac.Action
            :name "PLUS 2"
            :text "THE NEXT DIE YOU PLAY GETS +#"
            :caption "+2"
            :effect ac.Effect.plus
            :amount 2
            :cost 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon art.TILE_PLUS1
            :upgrade state.NOTHING)
        (make ac.Action
            :name "TIMES 2"
            :text "THE NEXT DIE YOU PLAY DOES DOUBLE"
            :caption "X2"
            :effect ac.Effect.double
            :amount 0
            :cost 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon art.TILE_TIMES2
            :upgrade state.NOTHING)
        (make ac.Action
            :name "LINT"
            :text "DOES NOTHING. UPGRADES TO PLUS 1"
            :caption ""
            :effect ac.Effect.nothing
            :amount 0
            :cost 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon art.TILE_LINT
            :upgrade PLUS_1)))

; a die: its name for the reward screen and its six faces
(struct Die ((name (ptr u8)) (faces (array u8 6))))

(const STARTING_DICE (array Die 5)
    (make (array Die 5)
        (make Die
            :name "WAND DIE"
            :faces (make (array u8 6) WAND_2 WAND_2 WAND_2 WAND_3 WAND_3 KIBBLE_2))
        (make Die :name "WAND DIE" :faces (make (array u8 6) WAND_2 WAND_2 WAND_3 GEM GEM BONE_2))
        (make Die
            :name "KIBBLE DIE"
            :faces (make (array u8 6) KIBBLE_2 KIBBLE_2 KIBBLE_2 KIBBLE_3 BONE_2 BONE_2))
        (make Die :name "GEM DIE" :faces (make (array u8 6) GEM GEM GEM_2 HAIRBALL ZOOMIES WAND_2))
        (make Die :name "CURSE DIE" :faces (make (array u8 6) FLEAS WET HISS PLUS_1 LINT DOUBLE))))
