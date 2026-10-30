; PROPOSAL, bag model (kept to compare; tools/sim, docs/balance.md): game/content/encounters.tsp for fights 3-10 and the
; boss. The run is FIGHT_COUNT fights in order; a fight with an other is a choice of two doors
; (both shown: the vet or the big bath), the other listed after the run's fights. After each won
; fight the reward offers that fight's two dice (FIGHT_OFFERS, rows of DICE), its type upgrade
; (FIGHT_UPGRADES) and taking a die out; a new die into a full bag takes the place of one you
; pick. A fight with nap is followed by a nap: NAP_HEAL hit points back, or that fight's type
; upgrade.

(import state)
(import content/enemies en)
(import content/faces)
(import art/sprites art)

(struct Hero ((name (ptr u8)) (hp u8) (figure u8) (col u8)))

(const HERO Hero (make Hero :name "CATWIZ" :hp 30 :figure art.KIND_CAT :col 6))

(enum Zone (day dusk night))

(struct Spot ((enemy u8) (col u8)))

(struct Fight ((zone Zone) (count u8) (spots (array Spot 3)) (nap bool) (other u8)))

(const NAP_HEAL u8 10)

; the die a hairball move puts in your bag for the fight (DICE row): all junk faces
(const JUNK_DIE u8 11)

(const FIGHT_COUNT u8 11)

(const FIGHTS (array Fight 12)
    (make (array Fight 12)
        (make Fight
            :zone Zone.day
            :count 2
            :spots (make (array Spot 3)
                (make Spot :enemy en.PUFFCAP :col 16)
                (make Spot :enemy en.SPORELET :col 24)
                (make Spot :enemy en.PUFFCAP :col 30))
            :nap false
            :other state.NOTHING)
        (make Fight
            :zone Zone.day
            :count 3
            :spots (make (array Spot 3)
                (make Spot :enemy en.PUFFCAP :col 16)
                (make Spot :enemy en.SPORELET :col 24)
                (make Spot :enemy en.NIGHTFLAP :col 30))
            :nap false
            :other state.NOTHING)
        (make Fight
            :zone Zone.day
            :count 3
            :spots (make (array Spot 3)
                (make Spot :enemy en.GNOME :col 16)
                (make Spot :enemy en.SPORELET :col 24)
                (make Spot :enemy en.SPORELET :col 30))
            :nap false
            :other state.NOTHING)
        (make Fight
            :zone Zone.day
            :count 3
            :spots (make (array Spot 3)
                (make Spot :enemy en.SQUIRREL :col 16)
                (make Spot :enemy en.POSSUM :col 24)
                (make Spot :enemy en.SQUIRREL :col 30))
            :nap false
            :other state.NOTHING)
        (make Fight
            :zone Zone.dusk
            :count 3
            :spots (make (array Spot 3)
                (make Spot :enemy en.DUST_BUNNY :col 16)
                (make Spot :enemy en.ROOMBA :col 24)
                (make Spot :enemy en.DUST_BUNNY :col 30))
            :nap false
            :other state.NOTHING)
        (make Fight
            :zone Zone.dusk
            :count 3
            :spots (make (array Spot 3)
                (make Spot :enemy en.CUCUMBER :col 16)
                (make Spot :enemy en.GNOME :col 24)
                (make Spot :enemy en.SPRINKLER :col 30))
            :nap false
            :other state.NOTHING)
        (make Fight
            :zone Zone.dusk
            :count 1
            :spots (make (array Spot 3)
                (make Spot :enemy en.MAILMAN :col 16)
                (make Spot :enemy en.MAILMAN :col 24)
                (make Spot :enemy en.MAILMAN :col 30))
            :nap true
            :other state.NOTHING)
        (make Fight
            :zone Zone.night
            :count 2
            :spots (make (array Spot 3)
                (make Spot :enemy en.HOOVER :col 16)
                (make Spot :enemy en.DUST_BUNNY :col 24)
                (make Spot :enemy en.HOOVER :col 30))
            :nap false
            :other state.NOTHING)
        (make Fight
            :zone Zone.night
            :count 2
            :spots (make (array Spot 3)
                (make Spot :enemy en.SPRINKLER :col 16)
                (make Spot :enemy en.MOWER :col 24)
                (make Spot :enemy en.SPRINKLER :col 30))
            :nap false
            :other state.NOTHING)
        (make Fight
            :zone Zone.night
            :count 1
            :spots (make (array Spot 3)
                (make Spot :enemy en.VET :col 16)
                (make Spot :enemy en.VET :col 24)
                (make Spot :enemy en.VET :col 30))
            :nap false
            :other 11)
        (make Fight
            :zone Zone.night
            :count 1
            :spots (make (array Spot 3)
                (make Spot :enemy en.KING :col 16)
                (make Spot :enemy en.KING :col 24)
                (make Spot :enemy en.KING :col 30))
            :nap false
            :other state.NOTHING)
        (make Fight
            :zone Zone.night
            :count 1
            :spots (make (array Spot 3)
                (make Spot :enemy en.BATH :col 16)
                (make Spot :enemy en.BATH :col 24)
                (make Spot :enemy en.BATH :col 30))
            :nap false
            :other state.NOTHING)))

(const DICE (array faces.Die 12)
    (make (array faces.Die 12)
        (make faces.Die
            :name "SCREAM DIE"
            :faces (make (array u8 6)
                faces.SCREAM faces.STAR faces.STAR_2 faces.BOX faces.WAND_2 faces.BATH))
        (make faces.Die
            :name "GOLD WAND DIE"
            :faces (make (array u8 6)
                faces.WAND_3 faces.WAND_3 faces.WAND_3 faces.WAND_4 faces.STAR faces.PLUS_1))
        (make faces.Die
            :name "FUR DIE"
            :faces (make (array u8 6)
                faces.STATIC faces.FLUFF_3 faces.FLUFF_3 faces.FLUFF_2 faces.STAR faces.STAR))
        (make faces.Die
            :name "LASER DIE"
            :faces (make (array u8 6)
                faces.LASER faces.STAR faces.STAR faces.WAND_3 faces.WAND_3 faces.HISS))
        (make faces.Die
            :name "CATNIP DIE"
            :faces (make (array u8 6)
                faces.CATNIP faces.STAR faces.STAR_2 faces.WAND_3 faces.PLUS_1 faces.FLUFF_2))
        (make faces.Die
            :name "TRAP DIE"
            :faces (make (array u8 6)
                faces.TRAP faces.FLUFF_3 faces.STAR faces.STAR faces.COLLAR faces.WAND_2))
        (make faces.Die
            :name "TABLE DIE"
            :faces (make (array u8 6)
                faces.KNOCK faces.STAR faces.STAR_2 faces.WAND_3 faces.WAND_3 faces.BATH))
        (make faces.Die
            :name "NAP DIE"
            :faces (make (array u8 6)
                faces.NINE_LIVES faces.STAR faces.STAR_2 faces.FLUFF_3 faces.TUNA_2 faces.LINT))
        (make faces.Die
            :name "TERRITORY DIE"
            :faces (make (array u8 6)
                faces.MARK faces.ZOOMIES faces.STAR faces.STAR faces.WAND_2 faces.WAND_3))
        (make faces.Die
            :name "COLLAR DIE"
            :faces (make (array u8 6)
                faces.COLLAR faces.COLLAR faces.FLUFF_3 faces.FLUFF_2 faces.WAND_3 faces.HISS))
        (make faces.Die
            :name "CLAW DIE"
            :faces (make (array u8 6)
                faces.WAND_3 faces.WAND_4 faces.WAND_4 faces.WAND_3 faces.DOUBLE faces.LINT))
        (make faces.Die
            :name "HAIRBALL"
            :faces (make (array u8 6)
                faces.HAIRBALL faces.HAIRBALL faces.HAIRBALL faces.HAIRBALL faces.HAIRBALL
                faces.HAIRBALL))))

; the type a fight's reward offers to upgrade: +1 to every face of that type, all run, TYPE_MOST
; at most (a type a bag has no face of is not offered)
(enum Type (none wand fluff tuna star fleas plus)) ; none: no type upgrade on offer

(const TYPE_MOST u8 3)

(const FIGHT_UPGRADES (array Type 12)
    (make (array Type 12)
        Type.wand Type.none Type.star Type.none Type.fluff Type.none Type.wand Type.none Type.plus
        Type.none Type.none Type.none))

(const FIGHT_OFFERS (array (array u8 2) 12)
    (make (array (array u8 2) 12)
        (make (array u8 2) 0 1)
        (make (array u8 2) 2 3)
        (make (array u8 2) 4 5)
        (make (array u8 2) 6 7)
        (make (array u8 2) 8 9)
        (make (array u8 2) 10 0)
        (make (array u8 2) 7 6)
        (make (array u8 2) 4 2)
        (make (array u8 2) 9 8)
        (make (array u8 2) 10 7)
        (make (array u8 2) 0 0)
        (make (array u8 2) 10 7)))
