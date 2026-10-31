; PROPOSAL (tools/sim, docs/balance.md): the hero's items, for the item-slot model.
; Catwiz rolls five identical dice; each die's six faces are her six item slots, and the item in
; a slot decides what its face does. Each slot varies its own way. Wands: damage, and a rider
; on the hit (the twig wand has a combo instead). Fluff: shield, and a combo: what the third
; fluff played in a turn adds (combo, combo_n). Stars: mana, each its own way. Books: spells
; paid in mana (with too little mana a book gives 1 mana: she studies it). Curses: amount of
; a status on an enemy. Tricks: a rule for the next die (times two counts it twice towards a
; three). amount is the number, step more a level.
; A reward gives an item for a slot (the old one goes). Levels belong to the slot: an upgrade
; card, or the item you hold again, is a level on that slot (ITEM_MOST at most), whichever item
; is in it. text: the card's item line (the slot's base is the card's first line), 35 columns,
; # the number after levels and boosts. Tiles: art still to draw (icon is a placeholder).

(import state)
(import content/action ac)
(import art/sprites art)

(enum Slot (wand fluff star book curse trick food junk)) ; junk: the hairball, no slot

(const ITEM_MOST u8 2)

; what the third face of a slot in a turn adds (combo_n: how much)
(enum Combo (none sweep keep thorns box heal static ward))

; item rows, by name
(const TWIG_WAND u8 0)
(const YARN_WAND u8 1)
(const SPRAY_BOTTLE u8 2)
(const FEATHER_TOY u8 3)
(const FISHBONE_WAND u8 4)
(const MOUSE_STRING u8 5)
(const FLUFF u8 6)
(const SPIKY_FLUFF u8 7)
(const BOX u8 8)
(const WARM_BLANKET u8 9)
(const STATIC_FUR u8 10)
(const BELL_COLLAR u8 11)
(const STAR u8 12)
(const SHOOTING_STAR u8 13)
(const MOON_BOWL u8 14)
(const WISHING_STAR u8 15)
(const LITTER_STAR u8 16)
(const ZOOMIES u8 17)
(const MEOW_BOOK u8 18)
(const LASER u8 19)
(const SCREAM u8 20)
(const KNOCK u8 21)
(const FITS u8 22)
(const FLEAS u8 23)
(const WET u8 24)
(const TANGLE u8 25)
(const MARK u8 26)
(const PLUS u8 27)
(const TIMES u8 28)
(const COPYCAT u8 29)
(const CATNIP u8 30)
(const KNEAD u8 31)
(const HAIRBALL u8 32)
(const ITEM_COUNT u8 33)

(const ITEMS (array ac.Item 33)
    (make (array ac.Item 33)
        (make ac.Item
            :name "TWIG WAND"
            :text "#. 3 IN A TURN: THE 3RD HITS ALL"
            :slot Slot.wand
            :effect ac.Effect.hit
            :amount 1
            :step 1
            :cost 0
            :combo Combo.sweep
            :combo_n 0
            :aim state.Aim.foe
            :icon art.TILE_WAND)
        (make ac.Item
            :name "YARN WAND"
            :text "#, AND IT IS TANGLED 1"
            :slot Slot.wand
            :effect ac.Effect.yarn
            :amount 3
            :step 1
            :cost 0
            :combo Combo.none
            :combo_n 0
            :aim state.Aim.foe
            :icon art.TILE_WAND)
        (make ac.Item
            :name "SPRAY BOTTLE"
            :text "#, AND IT IS WET"
            :slot Slot.wand
            :effect ac.Effect.spray
            :amount 1
            :step 1
            :cost 0
            :combo Combo.none
            :combo_n 0
            :aim state.Aim.foe
            :icon art.TILE_WAND)
        (make ac.Item
            :name "FEATHER TOY"
            :text "#, AND YOUR KITTENS POUNCE IT"
            :slot Slot.wand
            :effect ac.Effect.feather
            :amount 4
            :step 1
            :cost 0
            :combo Combo.none
            :combo_n 0
            :aim state.Aim.foe
            :icon art.TILE_WAND)
        (make ac.Item
            :name "FISHBONE WAND"
            :text "#, AND NO SHIELD STOPS IT"
            :slot Slot.wand
            :effect ac.Effect.pierce
            :amount 5
            :step 1
            :cost 0
            :combo Combo.none
            :combo_n 0
            :aim state.Aim.foe
            :icon art.TILE_WAND)
        (make ac.Item
            :name "MOUSE ON STRING"
            :text "#, THEN # TO THE NEXT ENEMY"
            :slot Slot.wand
            :effect ac.Effect.string
            :amount 3
            :step 1
            :cost 0
            :combo Combo.none
            :combo_n 0
            :aim state.Aim.foe
            :icon art.TILE_WAND)
        (make ac.Item
            :name "FLUFF"
            :text "3 IN A TURN: SHIELD STAYS A TURN"
            :slot Slot.fluff
            :effect ac.Effect.shield
            :amount 1
            :step 1
            :cost 0
            :combo Combo.keep
            :combo_n 0
            :aim state.Aim.self
            :icon art.TILE_KIBBLE)
        (make ac.Item
            :name "SPIKY FLUFF"
            :text "3 IN A TURN: WHO HITS YOU TAKES 3"
            :slot Slot.fluff
            :effect ac.Effect.shield
            :amount 2
            :step 1
            :cost 0
            :combo Combo.thorns
            :combo_n 3
            :aim state.Aim.self
            :icon art.TILE_KIBBLE)
        (make ac.Item
            :name "CARDBOARD BOX"
            :text "3 IN A TURN: HIT-ALLS MISS, +KITTEN"
            :slot Slot.fluff
            :effect ac.Effect.shield
            :amount 2
            :step 1
            :cost 0
            :combo Combo.box
            :combo_n 1
            :aim state.Aim.self
            :icon art.TILE_KIBBLE)
        (make ac.Item
            :name "WARM BLANKET"
            :text "3 IN A TURN: HEAL 2"
            :slot Slot.fluff
            :effect ac.Effect.shield
            :amount 1
            :step 1
            :cost 0
            :combo Combo.heal
            :combo_n 2
            :aim state.Aim.self
            :icon art.TILE_KIBBLE)
        (make ac.Item
            :name "STATIC FUR"
            :text "3 IN A TURN: 5 TO ALL, 10 IF WET"
            :slot Slot.fluff
            :effect ac.Effect.shield
            :amount 2
            :step 1
            :cost 0
            :combo Combo.static
            :combo_n 5
            :aim state.Aim.self
            :icon art.TILE_KIBBLE)
        (make ac.Item
            :name "BELL COLLAR"
            :text "3 IN A TURN: 2 WARD PIPS"
            :slot Slot.fluff
            :effect ac.Effect.shield
            :amount 2
            :step 1
            :cost 0
            :combo Combo.ward
            :combo_n 2
            :aim state.Aim.self
            :icon art.TILE_KIBBLE)
        (make ac.Item
            :name "STAR"
            :text "+# MANA"
            :slot Slot.star
            :effect ac.Effect.mana
            :amount 1
            :step 1
            :cost 0
            :combo Combo.none
            :combo_n 0
            :aim state.Aim.self
            :icon art.TILE_GEM)
        (make ac.Item
            :name "SHOOTING STAR"
            :text "+1 MANA, AND # DAMAGE"
            :slot Slot.star
            :effect ac.Effect.shoot
            :amount 2
            :step 1
            :cost 0
            :combo Combo.none
            :combo_n 0
            :aim state.Aim.foe
            :icon art.TILE_GEM)
        (make ac.Item
            :name "MOON BOWL"
            :text "+1 MANA, AND SHIELD #"
            :slot Slot.star
            :effect ac.Effect.moon
            :amount 1
            :step 1
            :cost 0
            :combo Combo.none
            :combo_n 0
            :aim state.Aim.self
            :icon art.TILE_GEM)
        (make ac.Item
            :name "WISHING STAR"
            :text "+# MANA; THE NEXT WAND TIMES 2"
            :slot Slot.star
            :effect ac.Effect.wish
            :amount 1
            :step 1
            :cost 0
            :combo Combo.none
            :combo_n 0
            :aim state.Aim.self
            :icon art.TILE_GEM)
        (make ac.Item
            :name "LITTER STAR"
            :text "+# MANA, AND 1 MORE A KITTEN"
            :slot Slot.star
            :effect ac.Effect.litter
            :amount 2
            :step 1
            :cost 0
            :combo Combo.none
            :combo_n 0
            :aim state.Aim.self
            :icon art.TILE_GEM)
        (make ac.Item
            :name "ZOOMIES"
            :text "2 MANA: # TO FOES 5 TIMES, L TO R"
            :slot Slot.book
            :effect ac.Effect.zoomies
            :amount 1
            :step 1
            :cost 2
            :combo Combo.none
            :combo_n 0
            :aim state.Aim.all
            :icon art.TILE_BOOK)
        (make ac.Item
            :name "MEOWCRONOMICON"
            :text "3 MANA: # KITTENS JOIN YOU"
            :slot Slot.book
            :effect ac.Effect.kittens
            :amount 3
            :step 1
            :cost 3
            :combo Combo.none
            :combo_n 0
            :aim state.Aim.self
            :icon art.TILE_BOOK)
        (make ac.Item
            :name "LASER POINTER"
            :text "2 MANA: # TO ALL; THEY HIT FRIENDS"
            :slot Slot.book
            :effect ac.Effect.laserall
            :amount 4
            :step 1
            :cost 2
            :combo Combo.none
            :combo_n 0
            :aim state.Aim.all
            :icon art.TILE_BOOK)
        (make ac.Item
            :name "3 AM SCREAMING"
            :text "3 MANA: # TO ALL FOES, 1 TO YOU"
            :slot Slot.book
            :effect ac.Effect.scream
            :amount 7
            :step 1
            :cost 3
            :combo Combo.none
            :combo_n 0
            :aim state.Aim.all
            :icon art.TILE_BOOK)
        (make ac.Item
            :name "KNOCK IT OFF"
            :text "2 MANA: IT DROPS SHIELD, BUFFS; #"
            :slot Slot.book
            :effect ac.Effect.knock
            :amount 8
            :step 1
            :cost 2
            :combo Combo.none
            :combo_n 0
            :aim state.Aim.foe
            :icon art.TILE_BOOK)
        (make ac.Item
            :name "IF IT FITS"
            :text "2 MANA: SHIELD #, +2 A KITTEN"
            :slot Slot.book
            :effect ac.Effect.pile
            :amount 5
            :step 1
            :cost 2
            :combo Combo.none
            :combo_n 0
            :aim state.Aim.self
            :icon art.TILE_BOOK)
        (make ac.Item
            :name "FLEAS"
            :text "# A TURN FOR 3 TURNS; THEY STACK"
            :slot Slot.curse
            :effect ac.Effect.fleas
            :amount 1
            :step 1
            :cost 0
            :combo Combo.none
            :combo_n 0
            :aim state.Aim.foe
            :icon art.TILE_FLEAS)
        (make ac.Item
            :name "WET"
            :text "ITS HITS HALVED FOR # TURNS"
            :slot Slot.curse
            :effect ac.Effect.wet
            :amount 1
            :step 1
            :cost 0
            :combo Combo.none
            :combo_n 0
            :aim state.Aim.foe
            :icon art.TILE_WET)
        (make ac.Item
            :name "BALL OF YARN"
            :text "TANGLED #: ITS HITS # LESS"
            :slot Slot.curse
            :effect ac.Effect.tangled
            :amount 2
            :step 1
            :cost 0
            :combo Combo.none
            :combo_n 0
            :aim state.Aim.foe
            :icon art.TILE_HISS)
        (make ac.Item
            :name "MARK TERRITORY"
            :text "MARKED #: HITS ON IT # MORE"
            :slot Slot.curse
            :effect ac.Effect.brand
            :amount 2
            :step 1
            :cost 0
            :combo Combo.none
            :combo_n 0
            :aim state.Aim.foe
            :icon art.TILE_BATH)
        (make ac.Item
            :name "PLUS ONE"
            :text "NEXT 2 DICE +#, EACH HIT AND STAR"
            :slot Slot.trick
            :effect ac.Effect.plus
            :amount 1
            :step 1
            :cost 0
            :combo Combo.none
            :combo_n 0
            :aim state.Aim.self
            :icon art.TILE_PLUS1)
        (make ac.Item
            :name "TIMES TWO"
            :text "NEXT WAND, FLUFF, BOOK X#: COUNTS #"
            :slot Slot.trick
            :effect ac.Effect.double
            :amount 2
            :step 1
            :cost 0
            :combo Combo.none
            :combo_n 0
            :aim state.Aim.self
            :icon art.TILE_TIMES2)
        (make ac.Item
            :name "COPYCAT"
            :text "YOUR LAST FACE AGAIN, +#"
            :slot Slot.trick
            :effect ac.Effect.copy
            :amount 0
            :step 1
            :cost 0
            :combo Combo.none
            :combo_n 0
            :aim state.Aim.self
            :icon art.TILE_PLUS1)
        (make ac.Item
            :name "CATNIP"
            :text "NEXT # DICE +1; KITTENS ACT TWICE"
            :slot Slot.trick
            :effect ac.Effect.catnip2
            :amount 4
            :step 1
            :cost 0
            :combo Combo.none
            :combo_n 0
            :aim state.Aim.self
            :icon art.TILE_PLUS1)
        (make ac.Item
            :name "KNEAD"
            :text "NEXT FLUFF TIMES 2, NEXT WAND +#"
            :slot Slot.trick
            :effect ac.Effect.knead
            :amount 2
            :step 1
            :cost 0
            :combo Combo.none
            :combo_n 0
            :aim state.Aim.self
            :icon art.TILE_PLUS1)
        (make ac.Item
            :name "HAIRBALL"
            :text "A DUD. RE-ROLL IT TO COUGH IT UP"
            :slot Slot.junk
            :effect ac.Effect.nothing
            :amount 0
            :step 0
            :cost 0
            :combo Combo.none
            :combo_n 0
            :aim state.Aim.self
            :icon art.TILE_LINT)))

; what she starts with, a slot each: wand, fluff, star, book, curse, then the sixth slot
(const STARTING_ITEMS (array u8 6) (make (array u8 6) TWIG_WAND FLUFF STAR ZOOMIES FLEAS PLUS))
