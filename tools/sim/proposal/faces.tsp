; PROPOSAL (tools/sim, docs/balance.md): game/content/faces.tsp for fights 3-10 and the boss.
; The game's faces with the port's names (gem is STAR, bone TUNA, kibble FLUFF; the 4 wand is
; MOON WAND, as STAR is mana now), then eight new: seven spells and the bell collar. New tiles
; for the spells' book and the collar are art still to draw (they borrow TILE_BOOK and
; TILE_KIBBLE here).

(import state)
(import content/action ac)
(import art/sprites art)

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
(const MARK u8 23)
(const LASER u8 24)
(const KNOCK u8 25)
(const CATNIP u8 26)
(const NINE_LIVES u8 27)
(const TRAP u8 28)
(const STATIC u8 29)
(const COLLAR u8 30)
(const FACE_COUNT u8 31)

(const FACES (array ac.Action 31)
    (make (array ac.Action 31)
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
            :name "MOON WAND"
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
            :name "FLUFF 2"
            :text "SHIELD # TILL YOUR NEXT TURN"
            :caption "2"
            :effect ac.Effect.shield
            :amount 2
            :cost 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon art.TILE_KIBBLE
            :upgrade FLUFF_3)
        (make ac.Action
            :name "FLUFF 3"
            :text "SHIELD # TILL YOUR NEXT TURN"
            :caption "3"
            :effect ac.Effect.shield
            :amount 3
            :cost 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon art.TILE_KIBBLE
            :upgrade FLUFF_4)
        (make ac.Action
            :name "FLUFF 4"
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
            :name "TUNA 2"
            :text "HEAL #"
            :caption "2"
            :effect ac.Effect.heal
            :amount 2
            :cost 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon art.TILE_BONE
            :upgrade TUNA_3)
        (make ac.Action
            :name "TUNA 3"
            :text "HEAL #"
            :caption "3"
            :effect ac.Effect.heal
            :amount 3
            :cost 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon art.TILE_BONE
            :upgrade TUNA_4)
        (make ac.Action
            :name "TUNA 4"
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
            :name "STAR"
            :text "+# MANA. KEPT ALL FIGHT, 5 AT MOST"
            :caption "1"
            :effect ac.Effect.mana
            :amount 1
            :cost 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon art.TILE_GEM
            :upgrade STAR_2)
        (make ac.Action
            :name "BIG STAR"
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
            :text "JUNK. PLAY IT TO COUGH IT UP"
            :caption ""
            :effect ac.Effect.cough
            :amount 0
            :cost 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon art.TILE_LINT
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
            :upgrade PLUS_1)
        (make ac.Action
            :name "MARK TERRITORY"
            :text "2 MANA: IT TAKES +# A HIT THIS TURN"
            :caption "2'"
            :effect ac.Effect.mark
            :amount 2
            :cost 2
            :aim state.Aim.foe
            :motion state.Motion.throw
            :icon art.TILE_BOOK
            :upgrade state.NOTHING)
        (make ac.Action
            :name "LASER POINTER"
            :text "2 MANA: ITS NEXT HIT GOES TO A FRIEND"
            :caption "2'"
            :effect ac.Effect.laser
            :amount 0
            :cost 2
            :aim state.Aim.foe
            :motion state.Motion.throw
            :icon art.TILE_BOOK
            :upgrade state.NOTHING)
        (make ac.Action
            :name "KNOCK IT OFF"
            :text "3 MANA: OFF THE TABLE: NO SHIELD, # DAMAGE"
            :caption "3'"
            :effect ac.Effect.knock
            :amount 7
            :cost 3
            :aim state.Aim.foe
            :motion state.Motion.throw
            :icon art.TILE_BOOK
            :upgrade state.NOTHING)
        (make ac.Action
            :name "CATNIP"
            :text "2 MANA: YOUR DICE GET +# THIS TURN"
            :caption "2'"
            :effect ac.Effect.catnip
            :amount 1
            :cost 2
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon art.TILE_BOOK
            :upgrade state.NOTHING)
        (make ac.Action
            :name "NINE LIVES"
            :text "4 MANA: HEAL #"
            :caption "4'"
            :effect ac.Effect.heal
            :amount 9
            :cost 4
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon art.TILE_BOOK
            :upgrade state.NOTHING)
        (make ac.Action
            :name "BELLY RUB TRAP"
            :text "2 MANA: SHIELD #. WHO HITS YOU TAKES 3"
            :caption "2'"
            :effect ac.Effect.thorns
            :amount 4
            :cost 2
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon art.TILE_BOOK
            :upgrade state.NOTHING)
        (make ac.Action
            :name "STATIC FUR"
            :text "2 MANA: # TO ALL, +1 A FLUFF PLAYED"
            :caption "2'"
            :effect ac.Effect.static
            :amount 1
            :cost 2
            :aim state.Aim.all
            :motion state.Motion.throw
            :icon art.TILE_BOOK
            :upgrade state.NOTHING)
        (make ac.Action
            :name "BELL COLLAR"
            :text "WARD +#: IT BLOCKS THE NEXT CURSE"
            :caption "1"
            :effect ac.Effect.ward
            :amount 1
            :cost 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon art.TILE_KIBBLE
            :upgrade state.NOTHING)))

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
            :faces (make (array u8 6) STAR STAR STAR_2 STATIC ZOOMIES WAND_2))
        (make Die :name "CURSE DIE" :faces (make (array u8 6) FLEAS WET HISS PLUS_1 LINT DOUBLE))))
