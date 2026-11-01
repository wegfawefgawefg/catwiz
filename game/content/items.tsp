; the hero's items, for the item-slot model (docs/balance.md, the proposal). Catwiz rolls five
; identical dice; each die's six faces are her six item slots, and the item in a slot decides what
; its face does. Each slot varies its own way. Wands: damage, and a rider on the hit (the twig
; wand has a combo instead). Fluff: shield, and a combo: what the third fluff played in a turn
; adds (combo, combo_n). Stars: mana, each its own way. Books: spells paid in mana (with too
; little mana a book can't be played). Curses: amount of a status on an enemy.
; Tricks: a rule for the next die (times two counts it twice towards a three). amount is the
; number, step more a level.
; A reward gives an item for a slot (the old one goes). Levels belong to the slot: an upgrade
; card, or the item you hold again, is a level on that slot (ITEM_MOST at most), whichever item
; is in it. text: the card's item line (the slot's base is the card's first line), 35 columns,
; # the number after levels and boosts.

(import state)
(import content/action ac)
(import art/icons)

(const ITEM_MOST u8 2)

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
(const CANNON u8 23)
(const FLEAS u8 24)
(const WET u8 25)
(const TANGLE u8 26)
(const MARK u8 27)
(const PLUS u8 28)
(const TIMES u8 29)
(const COPYCAT u8 30)
(const CATNIP u8 31)
(const KNEAD u8 32)
(const HAIRBALL u8 33)
; the chain and combo cards (2026-11-01, the owner's picks of the sim's round)
(const RED_DOT u8 34)
(const MIMIC u8 35)
(const CATFIGHT u8 36)
(const MIRROR_FUR u8 37)
(const LUCKY_PAW u8 38)
(const FLEA_CIRCUS u8 39)
(const SUNBEAM u8 40)
(const SCRATCHING_HABIT u8 41)
(const DOUBLE_OR_NOTHING u8 42)
(const ITEM_COUNT u8 43)

(const ITEMS (array ac.Item 43)
    (make (array ac.Item 43)
        (make ac.Item
            :name "TWIG WAND"
            :text "#. 3 in a turn: the 3rd hits all"
            :slot ac.Slot.wand
            :amount 1
            :step 1
            :cost 0
            :aim state.Aim.foe
            :icon icons.TILE_TWIG)
        (make ac.Item
            :name "YARN WAND"
            :text "#, and it is tangled 1"
            :slot ac.Slot.wand
            :amount 3
            :step 1
            :cost 0
            :aim state.Aim.foe
            :icon icons.TILE_YARNWAND)
        (make ac.Item
            :name "SPRAY BOTTLE"
            :text "#, and it is wet"
            :slot ac.Slot.wand
            :amount 1
            :step 1
            :cost 0
            :aim state.Aim.foe
            :icon icons.TILE_SPRAY)
        (make ac.Item
            :name "FEATHER TOY"
            :text "#, and your kittens pounce it"
            :slot ac.Slot.wand
            :amount 4
            :step 1
            :cost 0
            :aim state.Aim.foe
            :icon icons.TILE_FEATHER)
        (make ac.Item
            :name "FISHBONE WAND"
            :text "#, and no shield stops it"
            :slot ac.Slot.wand
            :amount 5
            :step 1
            :cost 0
            :aim state.Aim.foe
            :icon icons.TILE_FISHBONE)
        (make ac.Item
            :name "MOUSE ON STRING"
            :text "#, then # to the next enemy"
            :slot ac.Slot.wand
            :amount 3
            :step 1
            :cost 0
            :aim state.Aim.foe
            :icon icons.TILE_MOUSE)
        (make ac.Item
            :name "FLUFF"
            :text "3 in a turn: shield stays a turn"
            :slot ac.Slot.fluff
            :amount 1
            :step 1
            :cost 0
            :aim state.Aim.self
            :icon icons.TILE_FLUFF)
        (make ac.Item
            :name "SPIKY FLUFF"
            :text "3 in a turn: who hits you takes 3"
            :slot ac.Slot.fluff
            :amount 2
            :step 1
            :cost 0
            :aim state.Aim.self
            :icon icons.TILE_SPIKY)
        (make ac.Item
            :name "CARDBOARD BOX"
            :text "3 in a turn: hit-alls miss, +kitten"
            :slot ac.Slot.fluff
            :amount 2
            :step 1
            :cost 0
            :aim state.Aim.self
            :icon icons.TILE_BOX)
        (make ac.Item
            :name "WARM BLANKET"
            :text "3 in a turn: heal 2"
            :slot ac.Slot.fluff
            :amount 1
            :step 1
            :cost 0
            :aim state.Aim.self
            :icon icons.TILE_BLANKET)
        (make ac.Item
            :name "STATIC FUR"
            :text "3 in a turn: 5 to all, 10 if wet"
            :slot ac.Slot.fluff
            :amount 2
            :step 1
            :cost 0
            :aim state.Aim.self
            :icon icons.TILE_STATIC)
        (make ac.Item
            :name "BELL COLLAR"
            :text "3 in a turn: 2 ward pips"
            :slot ac.Slot.fluff
            :amount 2
            :step 1
            :cost 0
            :aim state.Aim.self
            :icon icons.TILE_BELL)
        (make ac.Item
            :name "STAR"
            :text "+# mana"
            :slot ac.Slot.star
            :amount 2
            :step 1
            :cost 0
            :aim state.Aim.self
            :icon icons.TILE_STAR)
        (make ac.Item
            :name "SHOOTING STAR"
            :text "+1 mana, and # damage"
            :slot ac.Slot.star
            :amount 2
            :step 1
            :cost 0
            :aim state.Aim.foe
            :icon icons.TILE_SHOOTING)
        (make ac.Item
            :name "MOON BOWL"
            :text "+1 mana, and shield #"
            :slot ac.Slot.star
            :amount 1
            :step 1
            :cost 0
            :aim state.Aim.self
            :icon icons.TILE_MOONBOWL)
        (make ac.Item
            :name "WISHING STAR"
            :text "+# mana; the next wand times 2"
            :slot ac.Slot.star
            :amount 1
            :step 1
            :cost 0
            :aim state.Aim.self
            :icon icons.TILE_WISHING)
        (make ac.Item
            :name "LITTER STAR"
            :text "+# mana, and 1 more a kitten"
            :slot ac.Slot.star
            :amount 2
            :step 1
            :cost 0
            :aim state.Aim.self
            :icon icons.TILE_LITTER)
        (make ac.Item
            :name "ZOOMIES"
            :text "2 mana: # to foes 5 times, L to R"
            :slot ac.Slot.book
            :amount 2
            :step 1
            :cost 2
            :aim state.Aim.all
            :icon icons.TILE_ZOOMIES)
        (make ac.Item
            :name "MEOWCRONOMICON"
            :text "3 mana: # kittens join you"
            :slot ac.Slot.book
            :amount 3
            :step 1
            :cost 3
            :aim state.Aim.self
            :icon icons.TILE_MEOWBOOK)
        (make ac.Item
            :name "LASER POINTER"
            :text "3 mana: # to all; they hit friends"
            :slot ac.Slot.book
            :amount 6
            :step 1
            :cost 3
            :aim state.Aim.all
            :icon icons.TILE_LASER)
        (make ac.Item
            :name "3 AM SCREAMING"
            :text "3 mana: # to all foes, 1 to you"
            :slot ac.Slot.book
            :amount 9
            :step 1
            :cost 3
            :aim state.Aim.all
            :icon icons.TILE_SCREAM)
        (make ac.Item
            :name "KNOCK IT OFF"
            :text "3 mana: it drops shield, buffs; #"
            :slot ac.Slot.book
            :amount 12
            :step 1
            :cost 3
            :aim state.Aim.foe
            :icon icons.TILE_KNOCK)
        (make ac.Item
            :name "IF IT FITS"
            :text "2 mana: shield #, +2 a kitten"
            :slot ac.Slot.book
            :amount 8
            :step 1
            :cost 2
            :aim state.Aim.self
            :icon icons.TILE_FITS)
        (make ac.Item
            :name "KITTEN CANNON"
            :text "Launch all kittens, # each"
            :slot ac.Slot.wand
            :amount 5
            :step 1
            :cost 0
            :aim state.Aim.foe
            :icon icons.TILE_CANNON)
        (make ac.Item
            :name "FLEAS"
            :text "# a turn for 3 turns; they stack"
            :slot ac.Slot.curse
            :amount 1
            :step 1
            :cost 0
            :aim state.Aim.foe
            :icon icons.TILE_FLEAS)
        (make ac.Item
            :name "WET"
            :text "Its hits halved for # turns"
            :slot ac.Slot.curse
            :amount 1
            :step 1
            :cost 0
            :aim state.Aim.foe
            :icon icons.TILE_WET)
        (make ac.Item
            :name "BALL OF YARN"
            :text "Tangled #: its hits # less"
            :slot ac.Slot.curse
            :amount 2
            :step 1
            :cost 0
            :aim state.Aim.foe
            :icon icons.TILE_YARNBALL)
        (make ac.Item
            :name "MARK TERRITORY"
            :text "Marked #: hits on it # more"
            :slot ac.Slot.curse
            :amount 2
            :step 1
            :cost 0
            :aim state.Aim.foe
            :icon icons.TILE_MARK)
        (make ac.Item
            :name "PLUS ONE"
            :text "Next die +#, each hit and star"
            :slot ac.Slot.trick
            :amount 2
            :step 1
            :cost 0
            :aim state.Aim.self
            :icon icons.TILE_PLUS1)
        (make ac.Item
            :name "TIMES TWO"
            :text "Next die x#: counts #"
            :slot ac.Slot.trick
            :amount 2
            :step 1
            :cost 0
            :aim state.Aim.self
            :icon icons.TILE_TIMES2)
        (make ac.Item
            :name "COPYCAT"
            :text "Your last face again, +#"
            :slot ac.Slot.trick
            :amount 0
            :step 1
            :cost 0
            :aim state.Aim.self
            :icon icons.TILE_COPYCAT)
        (make ac.Item
            :name "CATNIP"
            :text "Next # dice +1; kittens act twice"
            :slot ac.Slot.trick
            :amount 4
            :step 1
            :cost 0
            :aim state.Aim.self
            :icon icons.TILE_CATNIP)
        (make ac.Item
            :name "KNEAD"
            :text "Next fluff times 2, next wand +#"
            :slot ac.Slot.trick
            :amount 2
            :step 1
            :cost 0
            :aim state.Aim.self
            :icon icons.TILE_KNEAD)
        (make ac.Item
            :name "HAIRBALL"
            :text "A dud. Re-roll it to cough it up"
            :slot ac.Slot.junk
            :amount 0
            :step 0
            :cost 0
            :aim state.Aim.self
            :icon icons.TILE_HAIRBALL)
        (make ac.Item
            :name "RED DOT"
            :text "# wand hits on it bring dice back."
            :slot ac.Slot.curse
            :amount 2
            :step 1
            :cost 0
            :aim state.Aim.foe
            :icon icons.TILE_REDDOT)
        (make ac.Item
            :name "MIMIC"
            :text "2 mana: copy its next move # times"
            :slot ac.Slot.book
            :amount 1
            :step 1
            :cost 2
            :aim state.Aim.foe
            :icon icons.TILE_MIMIC)
        (make ac.Item
            :name "CATFIGHT"
            :text "It hits a friend next, # harder."
            :slot ac.Slot.curse
            :amount 4
            :step 1
            :cost 0
            :aim state.Aim.foe
            :icon icons.TILE_CATFIGHT)
        (make ac.Item
            :name "MIRROR FUR"
            :text "Shield #. Blocked hits bounce back."
            :slot ac.Slot.fluff
            :amount 3
            :step 1
            :cost 0
            :aim state.Aim.self
            :icon icons.TILE_MIRRORFUR)
        (make ac.Item
            :name "LUCKY PAW"
            :text "Shield #. You get a free re-roll."
            :slot ac.Slot.fluff
            :amount 2
            :step 1
            :cost 0
            :aim state.Aim.self
            :icon icons.TILE_LUCKYPAW)
        (make ac.Item
            :name "FLEA CIRCUS"
            :text "Fleas #. They jump x2 when it dies."
            :slot ac.Slot.curse
            :amount 2
            :step 1
            :cost 0
            :aim state.Aim.foe
            :icon icons.TILE_FLEACIRCUS)
        (make ac.Item
            :name "SUNBEAM"
            :text "+# mana. Past 5, up to 2 re-rolls."
            :slot ac.Slot.star
            :amount 2
            :step 1
            :cost 0
            :aim state.Aim.self
            :icon icons.TILE_SUNBEAM)
        (make ac.Item
            :name "SCRATCHING HABIT"
            :text "Hits #. +1 each use this fight."
            :slot ac.Slot.wand
            :amount 2
            :step 1
            :cost 0
            :aim state.Aim.foe
            :icon icons.TILE_HABIT)
        (make ac.Item
            :name "DOUBLE OR NOTHING"
            :text "Next die x#. It costs you 1 hp."
            :slot ac.Slot.trick
            :amount 3
            :step 1
            :cost 0
            :aim state.Aim.self
            :icon icons.TILE_DOUBLE))
    :strings aux)

; what she starts with, a slot each: wand, fluff, star, book, curse, then the sixth slot
(const STARTING_ITEMS (array u8 6) (make (array u8 6) TWIG_WAND FLUFF STAR ZOOMIES FLEAS PLUS))
