; PROPOSAL (tools/sim, docs/balance.md): game/content/encounters.tsp for fights 1-10 and the
; boss, the item-slot model. The run is FIGHT_COUNT fights in order; a fight with an other is a
; choice of two doors (both shown: the vet or the big bath), the other listed after the run's
; fights. After each won fight: pick one of the fight's three cards (FIGHT_CARDS); a fight with
; charms (the end of the day, the elites) then offers one of three charms (FIGHT_CHARMS; NOTHING
; for none); a fight with nap is followed by a nap: NAP_HEAL hit points back, or a level on a
; slot.

(import state)
(import content/enemies en)
(import content/items)
(import art/sprites art)

(struct Hero ((name (ptr u8)) (hp u8) (figure u8) (col u8)))

(const HERO Hero (make Hero :name "CATWIZ" :hp 30 :figure art.KIND_CAT :col 6))

(enum Zone (day dusk night))

(struct Spot ((enemy u8) (col u8)))

(struct Fight ((zone Zone) (count u8) (spots (array Spot 3)) (nap bool) (other u8)))

(const NAP_HEAL u8 10)

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

; a card is an item (a row of items.ITEMS: a new item for its slot, or a level when you hold
; it), or a slot's upgrade (UP_ and the slot: a level on that slot, whatever item is in it)
(const UP_WAND u8 128)
(const UP_FLUFF u8 129)
(const UP_STAR u8 130)
(const UP_BOOK u8 131)
(const UP_CURSE u8 132)
(const UP_TRICK u8 133)

(const FIGHT_CARDS (array (array u8 3) 12)
    (make (array (array u8 3) 12)
        (make (array u8 3) UP_WAND items.YARN_WAND items.TIMES)
        (make (array u8 3) items.SPRAY_BOTTLE items.SPIKY_FLUFF UP_STAR)
        (make (array u8 3) items.MEOW_BOOK items.LITTER_STAR items.TANGLE)
        (make (array u8 3) UP_FLUFF items.FEATHER_TOY items.MARK)
        (make (array u8 3) items.BOX items.CANNON items.COPYCAT)
        (make (array u8 3) items.STATIC_FUR items.SHOOTING_STAR items.WET)
        (make (array u8 3) items.WISHING_STAR items.KNOCK items.CATNIP)
        (make (array u8 3) items.MOON_BOWL items.LASER items.MOUSE_STRING)
        (make (array u8 3) items.FISHBONE_WAND items.BELL_COLLAR items.KNEAD)
        (make (array u8 3) UP_BOOK items.WARM_BLANKET items.SCREAM)
        (make (array u8 3) UP_WAND UP_FLUFF UP_STAR)
        (make (array u8 3) UP_CURSE items.FITS UP_TRICK)))

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
            :text "ONE MORE RE-ROLL EVERY TURN"
            :kind CharmKind.pocket
            :amount 1)
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
            :text "WANDS +1; FIGHTS START WITH FLEAS 2"
            :kind CharmKind.badmilk
            :amount 1)))

(const FIGHT_CHARMS (array (array u8 3) 12)
    (make (array (array u8 3) 12)
        (make (array u8 3) state.NOTHING state.NOTHING state.NOTHING)
        (make (array u8 3) state.NOTHING state.NOTHING state.NOTHING)
        (make (array u8 3) state.NOTHING state.NOTHING state.NOTHING)
        (make (array u8 3) CHARM_MOTHER_CAT CHARM_SCRATCH_POST CHARM_BAD_MILK)
        (make (array u8 3) state.NOTHING state.NOTHING state.NOTHING)
        (make (array u8 3) state.NOTHING state.NOTHING state.NOTHING)
        (make (array u8 3) CHARM_FLUFFY_TAIL CHARM_STILL_WATER CHARM_MITTENS)
        (make (array u8 3) state.NOTHING state.NOTHING state.NOTHING)
        (make (array u8 3) state.NOTHING state.NOTHING state.NOTHING)
        (make (array u8 3) CHARM_TRIO CHARM_GRUMPY CHARM_SIXTH_TOE)
        (make (array u8 3) state.NOTHING state.NOTHING state.NOTHING)
        (make (array u8 3) CHARM_TRIO CHARM_RUBBER_DUCK CHARM_SIXTH_TOE)))
