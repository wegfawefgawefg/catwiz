; PROPOSAL (tools/sim, docs/balance.md): game/content/encounters.tsp for fights 1-10 and the
; boss, the item-slot model. The run is FIGHT_COUNT fights in order; a fight with an other is a
; choice of two doors (both shown: the vet or the big bath), the other listed after the run's
; fights: the woods (1-3), the garden (4-6), the yard (7-9), each two fights and an elite,
; then the bulldog king. After each won fight: three cards drawn at random from OFFERS (by weight, those whose
; from is at most the number of fights won, three different ones that still give the kit
; something), pick one. A fight with charm then offers three charms drawn the same way from
; CHARM_OFFERS (not ones she has); a fight with rest (the elites) is followed by a rest
; first: REST_HEAL percent of the missing hit points back, or dream (a level on a slot).

(import state)
(import content/enemies en)
(import content/items)
(import art/sprites art)

(struct Hero ((name (ptr u8)) (hp u8) (figure u8) (col u8)))

(const HERO Hero (make Hero :name "CATWIZ" :hp 30 :figure art.KIND_CAT :col 6))

(enum Zone (woods garden yard)) ; places, all at night: art only

(struct Spot ((enemy u8) (col u8)))

(struct Fight ((zone Zone) (count u8) (spots (array Spot 3)) (rest bool) (charm bool) (other u8)))

; after the fights with rest (the elites): a rest, REST_HEAL percent of the hit points she is
; missing back (100: all), or dream instead (a level on a slot of her choice); then a charm
(const REST_HEAL u8 100)

(const FIGHT_COUNT u8 10)

(const FIGHTS (array Fight 11)
    (make (array Fight 11)
        (make Fight
            :zone Zone.woods
            :count 2
            :spots (make (array Spot 3)
                (make Spot :enemy en.PUFFCAP :col 16)
                (make Spot :enemy en.SPORELET :col 24)
                (make Spot :enemy en.PUFFCAP :col 30))
            :rest false
            :charm false
            :other state.NOTHING)
        (make Fight
            :zone Zone.woods
            :count 3
            :spots (make (array Spot 3)
                (make Spot :enemy en.SQUIRREL :col 16)
                (make Spot :enemy en.POSSUM :col 24)
                (make Spot :enemy en.SQUIRREL :col 30))
            :rest false
            :charm false
            :other state.NOTHING)
        (make Fight
            :zone Zone.woods
            :count 1
            :spots (make (array Spot 3)
                (make Spot :enemy en.SHROOM :col 16)
                (make Spot :enemy en.SHROOM :col 24)
                (make Spot :enemy en.SHROOM :col 30))
            :rest true
            :charm true
            :other state.NOTHING)
        (make Fight
            :zone Zone.garden
            :count 3
            :spots (make (array Spot 3)
                (make Spot :enemy en.DUST_BUNNY :col 16)
                (make Spot :enemy en.ROOMBA :col 24)
                (make Spot :enemy en.DUST_BUNNY :col 30))
            :rest false
            :charm false
            :other state.NOTHING)
        (make Fight
            :zone Zone.garden
            :count 3
            :spots (make (array Spot 3)
                (make Spot :enemy en.CUCUMBER :col 16)
                (make Spot :enemy en.GNOME :col 24)
                (make Spot :enemy en.SPRINKLER :col 30))
            :rest false
            :charm false
            :other state.NOTHING)
        (make Fight
            :zone Zone.garden
            :count 1
            :spots (make (array Spot 3)
                (make Spot :enemy en.MAILMAN :col 16)
                (make Spot :enemy en.MAILMAN :col 24)
                (make Spot :enemy en.MAILMAN :col 30))
            :rest true
            :charm true
            :other state.NOTHING)
        (make Fight
            :zone Zone.yard
            :count 2
            :spots (make (array Spot 3)
                (make Spot :enemy en.HOOVER :col 16)
                (make Spot :enemy en.DUST_BUNNY :col 24)
                (make Spot :enemy en.HOOVER :col 30))
            :rest false
            :charm false
            :other state.NOTHING)
        (make Fight
            :zone Zone.yard
            :count 2
            :spots (make (array Spot 3)
                (make Spot :enemy en.SPRINKLER :col 16)
                (make Spot :enemy en.MOWER :col 24)
                (make Spot :enemy en.SPRINKLER :col 30))
            :rest false
            :charm false
            :other state.NOTHING)
        (make Fight
            :zone Zone.yard
            :count 1
            :spots (make (array Spot 3)
                (make Spot :enemy en.VET :col 16)
                (make Spot :enemy en.VET :col 24)
                (make Spot :enemy en.VET :col 30))
            :rest true
            :charm true
            :other 10)
        (make Fight
            :zone Zone.yard
            :count 1
            :spots (make (array Spot 3)
                (make Spot :enemy en.KING :col 16)
                (make Spot :enemy en.KING :col 24)
                (make Spot :enemy en.KING :col 30))
            :rest false
            :charm false
            :other state.NOTHING)
        (make Fight
            :zone Zone.yard
            :count 1
            :spots (make (array Spot 3)
                (make Spot :enemy en.BATH :col 16)
                (make Spot :enemy en.BATH :col 24)
                (make Spot :enemy en.BATH :col 30))
            :rest true
            :charm true
            :other state.NOTHING)))

; a card is an item (a row of items.ITEMS: a new item for its slot, or a level when you hold
; it), or a slot's upgrade (UP_ and the slot: a level on that slot, whatever item is in it)
(const UP_WAND u8 128)
(const UP_FLUFF u8 129)
(const UP_STAR u8 130)
(const UP_BOOK u8 131)
(const UP_CURSE u8 132)
(const UP_TRICK u8 133)

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
            :text "TWO MORE RE-ROLLS EVERY TURN"
            :kind CharmKind.pocket
            :amount 2)
        (make Charm
            :name "SIXTH TOE"
            :text "ROLL 6 DICE, BUT 1 RE-ROLL LESS"
            :kind CharmKind.toe
            :amount 1)
        (make Charm
            :name "STILL WATER"
            :text "A TURN WITH NO RE-ROLL: +2 MANA"
            :kind CharmKind.still
            :amount 2)
        (make Charm
            :name "PURRFECT TRIO"
            :text "EACH 3 IN A TURN ALSO HITS ALL 1"
            :kind CharmKind.trio
            :amount 1)
        (make Charm
            :name "KITTEN MITTENS"
            :text "YOUR KITTENS HIT 1 HARDER"
            :kind CharmKind.mittens
            :amount 1)
        (make Charm
            :name "MOTHER CAT"
            :text "EACH FIGHT STARTS WITH A KITTEN"
            :kind CharmKind.mother
            :amount 1)
        (make Charm
            :name "FLUFFY TAIL"
            :text "YOUR SHIELD HALVES, NOT GONE"
            :kind CharmKind.tail
            :amount 1)
        (make Charm
            :name "GRUMPY FACE"
            :text "A HIT THAT HURTS YOU: +1 MANA"
            :kind CharmKind.grumpy
            :amount 1)
        (make Charm
            :name "RUBBER DUCK"
            :text "A CURSE A WARD BLOCKS: SHIELD 3"
            :kind CharmKind.duck
            :amount 3)
        (make Charm
            :name "BAD MILK"
            :text "WANDS +2; BOOKS COST 1 MORE"
            :kind CharmKind.badmilk
            :amount 2)))

; the reward pool: card (an item row: a new item for its slot, or a level when she holds it; or
; UP_ and a slot: a level on that slot), weight (its share of the draw), from (it can come after
; this many fights won: the plainer pieces from the start, the engines later)
(struct Offer ((card u8) (weight u8) (from u8)))

(const OFFER_COUNT u8 32)

(const OFFERS (array Offer 32)
    (make (array Offer 32)
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
        (make Offer :card UP_BOOK :weight 2 :from 3)
        (make Offer :card UP_CURSE :weight 2 :from 3)
        (make Offer :card items.TIMES :weight 2 :from 3)
        (make Offer :card items.COPYCAT :weight 2 :from 4)
        (make Offer :card items.WISHING_STAR :weight 2 :from 5)
        (make Offer :card items.KNEAD :weight 2 :from 4)
        (make Offer :card UP_TRICK :weight 2 :from 5)))

; the charm pool, drawn the same way at the fights with charm (charm: a row of CHARMS)
(struct CharmOffer ((charm u8) (weight u8) (from u8)))

(const CHARM_OFFER_COUNT u8 10)

(const CHARM_OFFERS (array CharmOffer 10)
    (make (array CharmOffer 10)
        (make CharmOffer :charm CHARM_SCRATCH_POST :weight 2 :from 1)
        (make CharmOffer :charm CHARM_SIXTH_TOE :weight 1 :from 6)
        (make CharmOffer :charm CHARM_STILL_WATER :weight 2 :from 1)
        (make CharmOffer :charm CHARM_TRIO :weight 1 :from 6)
        (make CharmOffer :charm CHARM_MITTENS :weight 2 :from 1)
        (make CharmOffer :charm CHARM_MOTHER_CAT :weight 2 :from 1)
        (make CharmOffer :charm CHARM_FLUFFY_TAIL :weight 2 :from 1)
        (make CharmOffer :charm CHARM_GRUMPY :weight 2 :from 1)
        (make CharmOffer :charm CHARM_RUBBER_DUCK :weight 2 :from 1)
        (make CharmOffer :charm CHARM_BAD_MILK :weight 2 :from 1)))
