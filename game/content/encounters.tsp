; the hero, the run's fights in order, and what comes between them. The run is FIGHT_COUNT
; fights in three zones of three (the woods, the garden, the house; each ends with an elite) and
; the boss. A fight with an other is a choice of two doors (both shown: the vet or the big bath),
; the other listed after the run's fights. After each won fight: one of five faces drawn (by
; their weights: content/faces.tsp, battle/offer); after an elite, then one of three charms drawn
; (content/charm_rows.tsp), then the nap (NAP_HEAL_SHIFT) or a bonus upgrade (a level on a slot of her choice). A spot is an enemy and
; the byte column of its sprite's left edge (even, so its colours hold); a fight's spots past its
; count are where its summons come in. backdrop: the scenery its screen is drawn with (0 the
; woods' clearing, 1 the woods' path, 2 the clearing again for the old shroom, 3 the garden, 4
; the house; tools/dhgr/night.py picture_for: each fight has its own screen, the scenery round
; its own lanes, tools/dhgr/screens.py); zone: the place, for the map at the top of the stage.

(import state)
(import content/enemies en)
(import art/sprites art)

(struct Hero ((name (ptr u8)) (hp u8) (figure u8) (col u8)))

(const HERO Hero (make Hero :name "Catwiz" :hp 10 :figure art.KIND_CAT :col 4) :strings aux)

(enum Zone (woods garden house))

(const ZONE_NAME (array (ptr u8) 3) (make (array (ptr u8) 3) "WOODS" "GARDEN" "HOUSE"))

(struct Spot ((enemy u8) (col u8)))

(struct Fight ((backdrop u8) (zone Zone) (count u8) (spots (array Spot 3)) (elite bool) (other u8)))

; the nap after an elite: the hit points she is missing, shifted right this much (rounded up): 0
; all of them, 1 half
(const NAP_HEAL_SHIFT u8 0)

(const FIGHT_COUNT u8 10)

(const FIGHTS (array Fight 11)
    (make (array Fight 11)
        (make Fight
            :backdrop 0
            :zone Zone.woods
            :count 2
            :spots (make (array Spot 3)
                (make Spot :enemy en.PUFFCAP :col 20)
                (make Spot :enemy en.SPORELET :col 32)
                (make Spot :enemy en.PUFFCAP :col 26))
            :elite false
            :other state.NOTHING)
        (make Fight
            :backdrop 1
            :zone Zone.woods
            :count 3
            :spots (make (array Spot 3)
                (make Spot :enemy en.SQUIRREL :col 14)
                (make Spot :enemy en.POSSUM :col 20)
                (make Spot :enemy en.SQUIRREL :col 32))
            :elite false
            :other state.NOTHING)
        (make Fight
            :backdrop 2
            :zone Zone.woods
            :count 1
            :spots (make (array Spot 3)
                (make Spot :enemy en.SHROOM :col 14)
                (make Spot :enemy en.SPORELET :col 26)
                (make Spot :enemy en.SPORELET :col 32))
            :elite true
            :other state.NOTHING)
        (make Fight
            :backdrop 3
            :zone Zone.garden
            :count 2
            :spots (make (array Spot 3)
                (make Spot :enemy en.SPRINKLER :col 14)
                (make Spot :enemy en.MOWER :col 20)
                (make Spot :enemy en.SPRINKLER :col 32))
            :elite false
            :other state.NOTHING)
        (make Fight
            :backdrop 3
            :zone Zone.garden
            :count 3
            :spots (make (array Spot 3)
                (make Spot :enemy en.CUCUMBER :col 14)
                (make Spot :enemy en.GNOME :col 20)
                (make Spot :enemy en.SPRINKLER :col 32))
            :elite false
            :other state.NOTHING)
        (make Fight
            :backdrop 3
            :zone Zone.garden
            :count 1
            :spots (make (array Spot 3)
                (make Spot :enemy en.MAILMAN :col 22)
                (make Spot :enemy en.MAILMAN :col 32)
                (make Spot :enemy en.MAILMAN :col 14))
            :elite true
            :other state.NOTHING)
        (make Fight
            :backdrop 4
            :zone Zone.house
            :count 2
            :spots (make (array Spot 3)
                (make Spot :enemy en.HOOVER :col 14)
                (make Spot :enemy en.DUST_BUNNY :col 32)
                (make Spot :enemy en.HOOVER :col 24))
            :elite false
            :other state.NOTHING)
        (make Fight
            :backdrop 4
            :zone Zone.house
            :count 3
            :spots (make (array Spot 3)
                (make Spot :enemy en.DUST_BUNNY :col 14)
                (make Spot :enemy en.ROOMBA :col 20)
                (make Spot :enemy en.DUST_BUNNY :col 32))
            :elite false
            :other state.NOTHING)
        (make Fight
            :backdrop 4
            :zone Zone.house
            :count 1
            :spots (make (array Spot 3)
                (make Spot :enemy en.VET :col 22)
                (make Spot :enemy en.VET :col 32)
                (make Spot :enemy en.VET :col 14))
            :elite true
            :other 10)
        (make Fight
            :backdrop 4
            :zone Zone.house
            :count 3
            :spots (make (array Spot 3)
                (make Spot :enemy en.KING :col 22)
                (make Spot :enemy en.PUG :col 32)
                (make Spot :enemy en.PUG :col 14))
            :elite false
            :other state.NOTHING)
        (make Fight
            :backdrop 4
            :zone Zone.house
            :count 1
            :spots (make (array Spot 3)
                (make Spot :enemy en.BATH :col 22)
                (make Spot :enemy en.BATH :col 32)
                (make Spot :enemy en.BATH :col 14))
            :elite true
            :other state.NOTHING))
    :in aux)

; charms: passives kept all run (content/charm_rows.tsp, content/charms). kind says what it is
; (the sim's rules.py has each): a charm that changes a rule (when none) is read where the rule
; is, by its kind (content/charms amount: the dice, the re-rolls, the shield, the kittens' bite,
; a wand's number, a book's cost)
(enum CharmKind (badmilk
        duck
        grumpy
        mittens
        mother
        pocket
        still
        tail
        toe
        trio
        litterbox
        lives9
        ; the faces round's (docs/faces.md); plain: a charm whose steps are all it does
        plain
        echo
        itchy
        porcupine
        coat
        cheap
        battery
        nap
        lucky7
        cursedcoin
        jackpot
        boots
        trouble
        skin
        collar
        monsoon
        ninth))

; FIGHTS is in aux memory (:in aux: main memory is full): its fields are read here, one at a time
(fn backdrop ((f u8)) u8
    (with_aux true false
        (at FIGHTS f backdrop)))

(fn count ((f u8)) u8
    (with_aux true false
        (at FIGHTS f count)))

(fn spot_enemy ((f u8) (k u8)) u8
    (with_aux true false
        (at (at FIGHTS f spots) k enemy)))

(fn spot_col ((f u8) (k u8)) u8
    (with_aux true false
        (at (at FIGHTS f spots) k col)))

(fn elite ((f u8)) bool
    (with_aux true false
        (at FIGHTS f elite)))

(fn other ((f u8)) u8
    (with_aux true false
        (at FIGHTS f other)))

(fn zone ((f u8)) Zone
    (with_aux true false
        (at FIGHTS f zone)))

; the kind in fight f's first spot (a door's enemy)
(fn first_enemy ((f u8)) u8
    (spot_enemy f 0))
