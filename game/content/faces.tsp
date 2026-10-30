; the dice. A face is an item: a row of FACES. The hero's five dice start as STARTING_DICE
; (die d is faces d * 6 to d * 6 + 5) and change with the rewards (content/encounters).

(import state)
(import content/action ac)
(import art/icons)

(const DIE_COUNT u8 5)
(const FACES_PER_DIE u8 6)

; face rows, by name
(const WAND_2 u8 0)
(const WAND_3 u8 1)
(const WAND_4 u8 2)
(const FLUFF_2 u8 3)
(const FLUFF_3 u8 4)
(const FLUFF_4 u8 5)
(const TUNA_2 u8 6)
(const TUNA_3 u8 7)
(const TUNA_4 u8 8)
(const STAR u8 9)
(const STAR_2 u8 10)
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
            :text "# damage to an enemy"
            :caption "2"
            :effect ac.Effect.hit
            :amount 2
            :cost 0
            :aim state.Aim.foe
            :motion state.Motion.throw
            :icon icons.TILE_WAND
            :upgrade WAND_3)
        (make ac.Action
            :name "GOLD WAND"
            :text "# damage to an enemy"
            :caption "3"
            :effect ac.Effect.hit
            :amount 3
            :cost 0
            :aim state.Aim.foe
            :motion state.Motion.throw
            :icon icons.TILE_WAND
            :upgrade WAND_4)
        (make ac.Action
            :name "STAR WAND"
            :text "# damage to an enemy"
            :caption "4"
            :effect ac.Effect.hit
            :amount 4
            :cost 0
            :aim state.Aim.foe
            :motion state.Motion.throw
            :icon icons.TILE_WAND
            :upgrade state.NOTHING)
        (make ac.Action
            :name "FLUFF 2"
            :text "Shield # till your next turn"
            :caption "2"
            :effect ac.Effect.shield
            :amount 2
            :cost 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon icons.TILE_FLUFF
            :upgrade FLUFF_3)
        (make ac.Action
            :name "FLUFF 3"
            :text "Shield # till your next turn"
            :caption "3"
            :effect ac.Effect.shield
            :amount 3
            :cost 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon icons.TILE_FLUFF
            :upgrade FLUFF_4)
        (make ac.Action
            :name "FLUFF 4"
            :text "Shield # till your next turn"
            :caption "4"
            :effect ac.Effect.shield
            :amount 4
            :cost 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon icons.TILE_FLUFF
            :upgrade state.NOTHING)
        (make ac.Action
            :name "TUNA 2"
            :text "Heal #"
            :caption "2"
            :effect ac.Effect.heal
            :amount 2
            :cost 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon icons.TILE_TUNA
            :upgrade TUNA_3)
        (make ac.Action
            :name "TUNA 3"
            :text "Heal #"
            :caption "3"
            :effect ac.Effect.heal
            :amount 3
            :cost 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon icons.TILE_TUNA
            :upgrade TUNA_4)
        (make ac.Action
            :name "TUNA 4"
            :text "Heal #"
            :caption "4"
            :effect ac.Effect.heal
            :amount 4
            :cost 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon icons.TILE_TUNA
            :upgrade state.NOTHING)
        (make ac.Action
            :name "STAR"
            :text "+# mana, kept all fight, 5 at most"
            :caption "1"
            :effect ac.Effect.mana
            :amount 1
            :cost 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon icons.TILE_STAR
            :upgrade STAR_2)
        (make ac.Action
            :name "BIG STAR"
            :text "+# mana, kept all fight, 5 at most"
            :caption "2"
            :effect ac.Effect.mana
            :amount 2
            :cost 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon icons.TILE_STAR
            :upgrade state.NOTHING)
        (make ac.Action
            :name "HAIRBALL"
            :text "2 mana: # damage + fleas (2 a turn)"
            :caption "2'"
            :effect ac.Effect.hairball
            :amount 4
            :cost 2
            :aim state.Aim.foe
            :motion state.Motion.throw
            :icon icons.TILE_BOOK
            :upgrade state.NOTHING)
        (make ac.Action
            :name "ZOOMIES"
            :text "2 mana: # damage x5, left to right"
            :caption "2'"
            :effect ac.Effect.zoomies
            :amount 1
            :cost 2
            :aim state.Aim.all
            :motion state.Motion.lunge
            :icon icons.TILE_BOOK
            :upgrade state.NOTHING)
        (make ac.Action
            :name "CARDBOARD BOX"
            :text "2 mana: shield #, hit-alls miss you"
            :caption "2'"
            :effect ac.Effect.box
            :amount 6
            :cost 2
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon icons.TILE_BOOK
            :upgrade state.NOTHING)
        (make ac.Action
            :name "3 AM SCREAMING"
            :text "3 mana: # damage to all, 1 to you"
            :caption "3'"
            :effect ac.Effect.scream
            :amount 3
            :cost 3
            :aim state.Aim.all
            :motion state.Motion.throw
            :icon icons.TILE_BOOK
            :upgrade state.NOTHING)
        (make ac.Action
            :name "FLEAS"
            :text "Curse: # damage a turn, 3 turns"
            :caption "2"
            :effect ac.Effect.fleas
            :amount 2
            :cost 0
            :aim state.Aim.foe
            :motion state.Motion.throw
            :icon icons.TILE_FLEAS
            :upgrade state.NOTHING)
        (make ac.Action
            :name "WET"
            :text "Curse: half damage on its next turn"
            :caption ""
            :effect ac.Effect.wet
            :amount 0
            :cost 0
            :aim state.Aim.foe
            :motion state.Motion.throw
            :icon icons.TILE_WET
            :upgrade state.NOTHING)
        (make ac.Action
            :name "HISS"
            :text "Curse: it skips its next move"
            :caption ""
            :effect ac.Effect.hiss
            :amount 0
            :cost 0
            :aim state.Aim.foe
            :motion state.Motion.throw
            :icon icons.TILE_HISS
            :upgrade state.NOTHING)
        (make ac.Action
            :name "BATH TIME"
            :text "Curse: it loses all its shield"
            :caption ""
            :effect ac.Effect.bath
            :amount 0
            :cost 0
            :aim state.Aim.foe
            :motion state.Motion.throw
            :icon icons.TILE_BATH
            :upgrade state.NOTHING)
        (make ac.Action
            :name "PLUS 1"
            :text "The next die you play gets +#"
            :caption "+1"
            :effect ac.Effect.plus
            :amount 1
            :cost 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon icons.TILE_PLUS1
            :upgrade PLUS_2)
        (make ac.Action
            :name "PLUS 2"
            :text "The next die you play gets +#"
            :caption "+2"
            :effect ac.Effect.plus
            :amount 2
            :cost 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon icons.TILE_PLUS1
            :upgrade state.NOTHING)
        (make ac.Action
            :name "TIMES 2"
            :text "The next die you play does double"
            :caption "X2"
            :effect ac.Effect.double
            :amount 0
            :cost 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon icons.TILE_TIMES2
            :upgrade state.NOTHING)
        (make ac.Action
            :name "LINT"
            :text "Does nothing. Upgrades to plus 1"
            :caption ""
            :effect ac.Effect.nothing
            :amount 0
            :cost 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon icons.TILE_LINT
            :upgrade PLUS_1)))

; a die: its name for the reward screen and its six faces
(struct Die ((name (ptr u8)) (faces (array u8 6))))

(const STARTING_DICE (array Die 5)
    (make (array Die 5)
        (make Die
            :name "WAND DIE"
            :faces (make (array u8 6) WAND_2 WAND_2 WAND_2 WAND_3 WAND_3 FLUFF_2))
        (make Die :name "WAND DIE" :faces (make (array u8 6) WAND_2 WAND_2 WAND_3 STAR STAR TUNA_2))
        (make Die
            :name "FLUFF DIE"
            :faces (make (array u8 6) FLUFF_2 FLUFF_2 FLUFF_2 FLUFF_3 TUNA_2 TUNA_2))
        (make Die
            :name "STAR DIE"
            :faces (make (array u8 6) STAR STAR STAR_2 HAIRBALL ZOOMIES WAND_2))
        (make Die :name "CURSE DIE" :faces (make (array u8 6) FLEAS WET HISS PLUS_1 LINT DOUBLE))))
