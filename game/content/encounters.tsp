; the hero, the run's fights in order, and what comes between them. The run is FIGHT_COUNT
; fights in three zones of three (the woods, the garden, the house; each ends with an elite) and
; the boss. A fight with an other is a choice of two doors (both shown: the vet or the big bath),
; the other listed after the run's fights. After each won fight: one of three cards drawn from
; OFFER_CARDS; after an elite, then one of three charms drawn from OFFER_CHARMS, then the nap
; (NAP_HEAL_SHIFT) or a bonus upgrade (a level on a slot of her choice). A spot is an enemy and
; the byte column of its sprite's left edge (even, so its colours hold); a fight's spots past its
; count are where its summons come in. backdrop: the screen it is fought on (0 the clearing, 1 the
; path, 2 the clearing with the old shroom's figure); zone: the place, for the map at the top of
; the stage. Fights 4-10 are stand-ins on fight 1-2's screens and figures until their art is
; drawn.

(import state)
(import content/enemies en)
(import content/items)
(import content/cards)
(import content/steps)
(import art/sprites art)

(struct Hero ((name (ptr u8)) (hp u8) (figure u8) (col u8)))

(const HERO Hero (make Hero :name "Catwiz" :hp 30 :figure art.KIND_CAT :col 4) :strings aux)

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
            :backdrop 1
            :zone Zone.garden
            :count 2
            :spots (make (array Spot 3)
                (make Spot :enemy en.SPRINKLER :col 14)
                (make Spot :enemy en.MOWER :col 20)
                (make Spot :enemy en.SPRINKLER :col 32))
            :elite false
            :other state.NOTHING)
        (make Fight
            :backdrop 0
            :zone Zone.garden
            :count 3
            :spots (make (array Spot 3)
                (make Spot :enemy en.CUCUMBER :col 14)
                (make Spot :enemy en.GNOME :col 20)
                (make Spot :enemy en.SPRINKLER :col 32))
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
            :zone Zone.house
            :count 2
            :spots (make (array Spot 3)
                (make Spot :enemy en.HOOVER :col 14)
                (make Spot :enemy en.DUST_BUNNY :col 32)
                (make Spot :enemy en.HOOVER :col 24))
            :elite false
            :other state.NOTHING)
        (make Fight
            :backdrop 1
            :zone Zone.house
            :count 3
            :spots (make (array Spot 3)
                (make Spot :enemy en.DUST_BUNNY :col 14)
                (make Spot :enemy en.ROOMBA :col 20)
                (make Spot :enemy en.DUST_BUNNY :col 32))
            :elite false
            :other state.NOTHING)
        (make Fight
            :backdrop 0
            :zone Zone.house
            :count 1
            :spots (make (array Spot 3)
                (make Spot :enemy en.VET :col 22)
                (make Spot :enemy en.VET :col 32)
                (make Spot :enemy en.VET :col 14))
            :elite true
            :other 10)
        (make Fight
            :backdrop 1
            :zone Zone.house
            :count 1
            :spots (make (array Spot 3)
                (make Spot :enemy en.KING :col 22)
                (make Spot :enemy en.KING :col 32)
                (make Spot :enemy en.KING :col 14))
            :elite false
            :other state.NOTHING)
        (make Fight
            :backdrop 1
            :zone Zone.house
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
; different ones a draw (battle/offer). The items she starts with are not in it: their slot's
; upgrade levels them
(struct Offer ((card u8) (weight u8) (from u8)))

(const OFFER_CARD_COUNT u8 42)

(const OFFER_CARDS (array Offer 42)
    (make (array Offer 42)
        (make Offer :card items.YARN_WAND :weight 4 :from 1)
        (make Offer :card items.SPRAY_BOTTLE :weight 4 :from 1)
        (make Offer :card items.MOUSE_STRING :weight 4 :from 1)
        (make Offer :card items.FISHBONE_WAND :weight 3 :from 1)
        (make Offer :card items.FEATHER_TOY :weight 3 :from 1)
        (make Offer :card items.SPIKY_FLUFF :weight 4 :from 1)
        (make Offer :card items.BOX :weight 4 :from 1)
        (make Offer :card items.BELL_COLLAR :weight 3 :from 1)
        (make Offer :card items.SHOOTING_STAR :weight 4 :from 1)
        (make Offer :card items.MOON_BOWL :weight 4 :from 1)
        (make Offer :card items.LITTER_STAR :weight 4 :from 1)
        (make Offer :card items.WET :weight 4 :from 1)
        (make Offer :card items.TANGLE :weight 4 :from 1)
        (make Offer :card UP_WAND :weight 3 :from 1)
        (make Offer :card UP_FLUFF :weight 3 :from 1)
        (make Offer :card UP_STAR :weight 3 :from 1)
        (make Offer :card items.MEOW_BOOK :weight 3 :from 3)
        (make Offer :card items.MARK :weight 3 :from 3)
        (make Offer :card items.STATIC_FUR :weight 3 :from 3)
        (make Offer :card items.WARM_BLANKET :weight 2 :from 3)
        (make Offer :card items.LASER :weight 3 :from 3)
        (make Offer :card items.KNOCK :weight 3 :from 3)
        (make Offer :card items.SCREAM :weight 3 :from 3)
        (make Offer :card items.FITS :weight 2 :from 3)
        (make Offer :card items.CATNIP :weight 3 :from 3)
        (make Offer :card items.CANNON :weight 3 :from 3)
        (make Offer :card UP_BOOK :weight 2 :from 3)
        (make Offer :card UP_CURSE :weight 2 :from 3)
        (make Offer :card items.TIMES :weight 2 :from 3)
        (make Offer :card items.COPYCAT :weight 2 :from 4)
        (make Offer :card items.WISHING_STAR :weight 2 :from 5)
        (make Offer :card items.KNEAD :weight 2 :from 4)
        (make Offer :card UP_TRICK :weight 2 :from 5)
        (make Offer :card items.RED_DOT :weight 3 :from 3)
        (make Offer :card items.LUCKY_PAW :weight 3 :from 1)
        (make Offer :card items.SUNBEAM :weight 3 :from 1)
        (make Offer :card items.MIMIC :weight 3 :from 3)
        (make Offer :card items.CATFIGHT :weight 3 :from 1)
        (make Offer :card items.MIRROR_FUR :weight 3 :from 1)
        (make Offer :card items.FLEA_CIRCUS :weight 3 :from 1)
        (make Offer :card items.SCRATCHING_HABIT :weight 3 :from 1)
        (make Offer :card items.DOUBLE_OR_NOTHING :weight 2 :from 3))
    :in aux)

; charms: passives kept all run. kind says what it is (the sim's rules.py has each), amount
; how much. A charm that acts at a moment (when) runs its steps then (fx, content/cards.tsp:
; v its amount, times the ones she holds); one that changes a rule (when none) is read where
; the rule is, by its kind (content/charms amount: the dice, the re-rolls, the shield, the
; kittens' bite, a wand's number, a book's cost)
(enum CharmKind (badmilk duck grumpy mittens mother pocket still tail toe trio litterbox lives9))

(struct Charm ((name (ptr u8))
        (text (ptr u8))
        (kind CharmKind)
        (amount u8)
        (when steps.When)
        (fx (ptr u8))))

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
(const CHARM_LITTER_BOX u8 10)
(const CHARM_NINE_LIVES u8 11)

(const CHARMS (array Charm 12)
    (make (array Charm 12)
        (make Charm
            :name "SCRATCH POST"
            :text "Two more re-rolls every turn"
            :kind CharmKind.pocket
            :amount 2
            :when steps.When.none
            :fx (addr_of (at cards.NOTHING 0)))
        (make Charm
            :name "SIXTH TOE"
            :text "Roll 6 dice, but 1 re-roll less"
            :kind CharmKind.toe
            :amount 1
            :when steps.When.none
            :fx (addr_of (at cards.NOTHING 0)))
        (make Charm
            :name "STILL WATER"
            :text "A turn with no re-roll: +2 mana"
            :kind CharmKind.still
            :amount 2
            :when steps.When.turn_end
            :fx (addr_of (at cards.STILL_WATER 0)))
        (make Charm
            :name "PURRFECT TRIO"
            :text "Each 3 in a turn also hits all 1"
            :kind CharmKind.trio
            :amount 1
            :when steps.When.three
            :fx (addr_of (at cards.TRIO 0)))
        (make Charm
            :name "KITTEN MITTENS"
            :text "Your kittens hit 1 harder"
            :kind CharmKind.mittens
            :amount 1
            :when steps.When.none
            :fx (addr_of (at cards.NOTHING 0)))
        (make Charm
            :name "MOTHER CAT"
            :text "Each fight starts with a kitten"
            :kind CharmKind.mother
            :amount 1
            :when steps.When.fight_start
            :fx (addr_of (at cards.MOTHER_CAT 0)))
        (make Charm
            :name "FLUFFY TAIL"
            :text "Your shield halves, not gone"
            :kind CharmKind.tail
            :amount 1
            :when steps.When.none
            :fx (addr_of (at cards.NOTHING 0)))
        (make Charm
            :name "GRUMPY FACE"
            :text "A hit that hurts you: +1 mana"
            :kind CharmKind.grumpy
            :amount 1
            :when steps.When.hurt
            :fx (addr_of (at cards.GRUMPY 0)))
        (make Charm
            :name "RUBBER DUCK"
            :text "A curse a ward blocks: shield 3"
            :kind CharmKind.duck
            :amount 3
            :when steps.When.warded
            :fx (addr_of (at cards.RUBBER_DUCK 0)))
        (make Charm
            :name "BAD MILK"
            :text "Wands +2; books cost 1 more"
            :kind CharmKind.badmilk
            :amount 2
            :when steps.When.none
            :fx (addr_of (at cards.NOTHING 0)))
        (make Charm
            :name "LITTER BOX"
            :text "Your kittens stay between fights."
            :kind CharmKind.litterbox
            :amount 1
            :when steps.When.fight_start
            :fx (addr_of (at cards.LITTER_BOX 0)))
        (make Charm
            :name "NINE LIVES"
            :text "You come back once with # hp."
            :kind CharmKind.lives9
            :amount 10
            :when steps.When.dies
            :fx (addr_of (at cards.NINE_LIVES 0))))
    :in aux)

(const OFFER_CHARM_COUNT u8 12)

(const OFFER_CHARMS (array Offer 12)
    (make (array Offer 12)
        (make Offer :card CHARM_SCRATCH_POST :weight 2 :from 1)
        (make Offer :card CHARM_SIXTH_TOE :weight 1 :from 6)
        (make Offer :card CHARM_STILL_WATER :weight 2 :from 1)
        (make Offer :card CHARM_TRIO :weight 1 :from 6)
        (make Offer :card CHARM_MITTENS :weight 2 :from 1)
        (make Offer :card CHARM_MOTHER_CAT :weight 2 :from 1)
        (make Offer :card CHARM_FLUFFY_TAIL :weight 2 :from 1)
        (make Offer :card CHARM_GRUMPY :weight 2 :from 1)
        (make Offer :card CHARM_RUBBER_DUCK :weight 2 :from 1)
        (make Offer :card CHARM_BAD_MILK :weight 2 :from 1)
        (make Offer :card CHARM_LITTER_BOX :weight 2 :from 1)
        (make Offer :card CHARM_NINE_LIVES :weight 2 :from 1))
    :in aux)

; each charm's mark on its card (the hud font, tools/dhgr/game_hud.py), so they tell apart: a plus
; (a re-roll more), 6, a drop, 3, a kitten's head, a heart, a shield, a lit star, a ward pip, a
; flea, a litter tray (the litter box), a cat with a halo (nine lives). In main memory: the tray
; reads them
(const MARKS (array (ptr u8) 12)
    (make (array (ptr u8) 12) "+" "6" "%" "3" "_" "*" "#" "'" ";" "," "e" "f"))

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

(fn charm_amount ((c u8)) u8
    (with_aux true false
        (at CHARMS c amount)))

(fn charm_when ((c u8)) steps.When
    (with_aux true false
        (at CHARMS c when)))

(fn charm_fx ((c u8)) (ptr u8)
    (with_aux true false
        (at CHARMS c fx)))

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
