; the hero, the run's fights in order, and what comes between them. The run is FIGHT_COUNT
; fights in three zones of three (the woods, the garden, the yard; each ends with an elite) and
; the boss. A fight with an other is a choice of two doors (both shown: the vet or the big bath),
; the other listed after the run's fights. After each won fight: one of three cards drawn from
; OFFER_CARDS; after an elite, then one of three charms drawn from OFFER_CHARMS, then the nap
; (NAP_HEAL_SHIFT) or a bonus upgrade (a level on a slot of her choice). A spot is an enemy and
; the byte column of its sprite's left edge (even, so its colours hold); a fight's spots past its
; count are where its summons come in. backdrop: the screen it is fought on (0 the clearing, 1 the
; path); zone: the place, for the map at the top of the stage. Fights 3-10 are stand-ins on fight
; 1-2's screens and figures until their art is drawn, and the woods' elite a stand-in enemy.

(import state)
(import content/enemies en)
(import content/items)
(import art/sprites art)

(struct Hero ((name (ptr u8)) (hp u8) (figure u8) (col u8)))

(const HERO Hero (make Hero :name "Catwiz" :hp 30 :figure art.KIND_CAT :col 4) :strings aux)

(enum Zone (woods garden yard))

(const ZONE_NAME (array (ptr u8) 3) (make (array (ptr u8) 3) "WOODS" "GARDEN" "YARD"))

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
                (make Spot :enemy en.PUFFCAP :col 20)
                (make Spot :enemy en.SPORELET :col 32)
                (make Spot :enemy en.NIGHTFLAP :col 26))
            :elite false
            :other state.NOTHING)
        (make Fight
            :backdrop 0
            :zone Zone.woods
            :count 3
            :spots (make (array Spot 3)
                (make Spot :enemy en.OLD_GNOME :col 14)
                (make Spot :enemy en.SPORELET :col 26)
                (make Spot :enemy en.SPORELET :col 32))
            :elite true
            :other state.NOTHING)
        (make Fight
            :backdrop 1
            :zone Zone.garden
            :count 3
            :spots (make (array Spot 3)
                (make Spot :enemy en.SQUIRREL :col 14)
                (make Spot :enemy en.POSSUM :col 20)
                (make Spot :enemy en.SQUIRREL :col 32))
            :elite false
            :other state.NOTHING)
        (make Fight
            :backdrop 0
            :zone Zone.garden
            :count 3
            :spots (make (array Spot 3)
                (make Spot :enemy en.DUST_BUNNY :col 14)
                (make Spot :enemy en.ROOMBA :col 20)
                (make Spot :enemy en.DUST_BUNNY :col 32))
            :elite false
            :other state.NOTHING)
        (make Fight
            :backdrop 1
            :zone Zone.garden
            :count 1
            :spots (make (array Spot 3)
                (make Spot :enemy en.MAILMAN :col 22)
                (make Spot :enemy en.MAILMAN :col 32)
                (make Spot :enemy en.MAILMAN :col 14))
            :elite true
            :other state.NOTHING)
        (make Fight
            :backdrop 0
            :zone Zone.yard
            :count 2
            :spots (make (array Spot 3)
                (make Spot :enemy en.HOOVER :col 14)
                (make Spot :enemy en.DUST_BUNNY :col 32)
                (make Spot :enemy en.HOOVER :col 24))
            :elite false
            :other state.NOTHING)
        (make Fight
            :backdrop 1
            :zone Zone.yard
            :count 2
            :spots (make (array Spot 3)
                (make Spot :enemy en.SPRINKLER :col 14)
                (make Spot :enemy en.MOWER :col 20)
                (make Spot :enemy en.SPRINKLER :col 32))
            :elite false
            :other state.NOTHING)
        (make Fight
            :backdrop 0
            :zone Zone.yard
            :count 1
            :spots (make (array Spot 3)
                (make Spot :enemy en.VET :col 22)
                (make Spot :enemy en.VET :col 32)
                (make Spot :enemy en.VET :col 14))
            :elite true
            :other 10)
        (make Fight
            :backdrop 1
            :zone Zone.yard
            :count 1
            :spots (make (array Spot 3)
                (make Spot :enemy en.KING :col 22)
                (make Spot :enemy en.KING :col 32)
                (make Spot :enemy en.KING :col 14))
            :elite false
            :other state.NOTHING)
        (make Fight
            :backdrop 1
            :zone Zone.yard
            :count 1
            :spots (make (array Spot 3)
                (make Spot :enemy en.BATH :col 22)
                (make Spot :enemy en.BATH :col 32)
                (make Spot :enemy en.BATH :col 14))
            :elite true
            :other state.NOTHING))
    :in aux)

; a card is an item (a row of items.ITEMS: a new item for its slot, or a level when you hold
; it), or a slot's upgrade (UP_ and the slot: a level on that slot, whatever item is in it)
(const UP_WAND u8 128)
(const UP_FLUFF u8 129)
(const UP_STAR u8 130)
(const UP_BOOK u8 131)
(const UP_CURSE u8 132)
(const UP_TRICK u8 133)

; what the draws after a fight take from: a card (or a charm's row), its weight (its share of
; the draw, among the ones that can come) and the first fight it can come after (1 to 10). Three
; different ones a draw (battle/offer)
(struct Offer ((card u8) (weight u8) (from u8)))

(const OFFER_CARD_COUNT u8 39)

(const OFFER_CARDS (array Offer 39)
    (make (array Offer 39)
        (make Offer :card items.TWIG_WAND :weight 1 :from 1)
        (make Offer :card items.YARN_WAND :weight 1 :from 1)
        (make Offer :card items.SPRAY_BOTTLE :weight 1 :from 1)
        (make Offer :card items.FEATHER_TOY :weight 1 :from 1)
        (make Offer :card items.FISHBONE_WAND :weight 1 :from 1)
        (make Offer :card items.MOUSE_STRING :weight 1 :from 1)
        (make Offer :card items.FLUFF :weight 1 :from 1)
        (make Offer :card items.SPIKY_FLUFF :weight 1 :from 1)
        (make Offer :card items.BOX :weight 1 :from 1)
        (make Offer :card items.WARM_BLANKET :weight 1 :from 1)
        (make Offer :card items.STATIC_FUR :weight 1 :from 1)
        (make Offer :card items.BELL_COLLAR :weight 1 :from 1)
        (make Offer :card items.STAR :weight 1 :from 1)
        (make Offer :card items.SHOOTING_STAR :weight 1 :from 1)
        (make Offer :card items.MOON_BOWL :weight 1 :from 1)
        (make Offer :card items.WISHING_STAR :weight 1 :from 1)
        (make Offer :card items.LITTER_STAR :weight 1 :from 1)
        (make Offer :card items.ZOOMIES :weight 1 :from 1)
        (make Offer :card items.MEOW_BOOK :weight 1 :from 1)
        (make Offer :card items.LASER :weight 1 :from 1)
        (make Offer :card items.SCREAM :weight 1 :from 1)
        (make Offer :card items.KNOCK :weight 1 :from 1)
        (make Offer :card items.FITS :weight 1 :from 1)
        (make Offer :card items.CANNON :weight 1 :from 1)
        (make Offer :card items.FLEAS :weight 1 :from 1)
        (make Offer :card items.WET :weight 1 :from 1)
        (make Offer :card items.TANGLE :weight 1 :from 1)
        (make Offer :card items.MARK :weight 1 :from 1)
        (make Offer :card items.PLUS :weight 1 :from 1)
        (make Offer :card items.TIMES :weight 1 :from 1)
        (make Offer :card items.COPYCAT :weight 1 :from 1)
        (make Offer :card items.CATNIP :weight 1 :from 1)
        (make Offer :card items.KNEAD :weight 1 :from 1)
        (make Offer :card UP_WAND :weight 1 :from 1)
        (make Offer :card UP_FLUFF :weight 1 :from 1)
        (make Offer :card UP_STAR :weight 1 :from 1)
        (make Offer :card UP_BOOK :weight 1 :from 1)
        (make Offer :card UP_CURSE :weight 1 :from 1)
        (make Offer :card UP_TRICK :weight 1 :from 1))
    :in aux)

; charms: passives kept all run. kind says what it does (the sim's rules.py has each), amount
; how much
(enum CharmKind (badmilk duck grumpy mittens mother pocket still tail toe trio))

(struct Charm ((name (ptr u8)) (text (ptr u8)) (kind CharmKind) (amount u8)))

(const CHARM_SCRATCH_POST u8 0)
(const CHARM_SIXTH_TOE u8 1)
(const CHARM_STILL_WATER u8 2)
(const CHARM_TRIO u8 3)
(const CHARM_MITTENS u8 4)
(const CHARM_MOTHER_CAT u8 5)
(const CHARM_FLUFFY_TAIL u8 6)
(const CHARM_GRUMPY u8 7)
(const CHARM_RUBBER_DUCK u8 8)
(const CHARM_BAD_MILK u8 9)

(const CHARMS (array Charm 10)
    (make (array Charm 10)
        (make Charm
            :name "SCRATCH POST"
            :text "One more re-roll every turn"
            :kind CharmKind.pocket
            :amount 1)
        (make Charm
            :name "SIXTH TOE"
            :text "Roll 6 dice, but 1 re-roll less"
            :kind CharmKind.toe
            :amount 1)
        (make Charm
            :name "STILL WATER"
            :text "A turn with no re-roll: +2 mana"
            :kind CharmKind.still
            :amount 2)
        (make Charm
            :name "PURRFECT TRIO"
            :text "Each 3 in a turn also hits all 1"
            :kind CharmKind.trio
            :amount 1)
        (make Charm
            :name "KITTEN MITTENS"
            :text "Your kittens hit 1 harder"
            :kind CharmKind.mittens
            :amount 1)
        (make Charm
            :name "MOTHER CAT"
            :text "Each fight starts with a kitten"
            :kind CharmKind.mother
            :amount 1)
        (make Charm
            :name "FLUFFY TAIL"
            :text "Your shield halves, not gone"
            :kind CharmKind.tail
            :amount 1)
        (make Charm
            :name "GRUMPY FACE"
            :text "A hit that hurts you: +1 mana"
            :kind CharmKind.grumpy
            :amount 1)
        (make Charm
            :name "RUBBER DUCK"
            :text "A curse a ward blocks: shield 3"
            :kind CharmKind.duck
            :amount 3)
        (make Charm
            :name "BAD MILK"
            :text "Wands +1; fights start with fleas 2"
            :kind CharmKind.badmilk
            :amount 1))
    :in aux)

(const OFFER_CHARM_COUNT u8 10)

(const OFFER_CHARMS (array Offer 10)
    (make (array Offer 10)
        (make Offer :card CHARM_SCRATCH_POST :weight 1 :from 1)
        (make Offer :card CHARM_SIXTH_TOE :weight 1 :from 1)
        (make Offer :card CHARM_STILL_WATER :weight 1 :from 1)
        (make Offer :card CHARM_TRIO :weight 1 :from 1)
        (make Offer :card CHARM_MITTENS :weight 1 :from 1)
        (make Offer :card CHARM_MOTHER_CAT :weight 1 :from 1)
        (make Offer :card CHARM_FLUFFY_TAIL :weight 1 :from 1)
        (make Offer :card CHARM_GRUMPY :weight 1 :from 1)
        (make Offer :card CHARM_RUBBER_DUCK :weight 1 :from 1)
        (make Offer :card CHARM_BAD_MILK :weight 1 :from 1))
    :in aux)

; each charm's mark on its card (the hud font, tools/dhgr/game_hud.py), so they tell apart: a plus
; (a re-roll more), 6, a drop, 3, a kitten's head, a heart, a shield, a lit star, a ward pip, a
; flea. In main memory: the tray reads them
(const MARKS (array (ptr u8) 10) (make (array (ptr u8) 10) "+" "6" "%" "3" "_" "*" "#" "'" ";" ","))

; FIGHTS, CHARMS and the OFFER tables are in aux memory (:in aux: main memory is full): their
; fields are read here, one at a time (the offers' in battle/offer)
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

(fn charm_kind ((c u8)) CharmKind
    (with_aux true false
        (at CHARMS c kind)))

(fn charm_amount ((c u8)) u8
    (with_aux true false
        (at CHARMS c amount)))

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

(fn charm_name ((c u8)) (ptr u8)
    (with_aux true false
        (at CHARMS c name)))

(fn charm_text ((c u8)) (ptr u8)
    (with_aux true false
        (at CHARMS c text)))
