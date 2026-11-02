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
            :text "Hits #.|3rd wand this turn: it hits all."
            :slot ac.Slot.wand
            :amount 4
            :step 2
            :cost 0
            :aim state.Aim.foe
            :icon icons.TILE_TWIG)
        (make ac.Item
            :name "YARN WAND"
            :text "Hits #.|If it stands: its hits are 1 less."
            :slot ac.Slot.wand
            :amount 6
            :step 2
            :cost 0
            :aim state.Aim.foe
            :icon icons.TILE_YARNWAND)
        (make ac.Item
            :name "SPRAY BOTTLE"
            :text "Hits #.|If it stands: it hits half, 1 turn."
            :slot ac.Slot.wand
            :amount 4
            :step 2
            :cost 0
            :aim state.Aim.foe
            :icon icons.TILE_SPRAY)
        (make ac.Item
            :name "FEATHER TOY"
            :text "Hits #, then kittens pounce on it."
            :slot ac.Slot.wand
            :amount 10
            :step 2
            :cost 0
            :aim state.Aim.foe
            :icon icons.TILE_FEATHER)
        (make ac.Item
            :name "FISHBONE WAND"
            :text "Hits #. Goes through any shield."
            :slot ac.Slot.wand
            :amount 12
            :step 2
            :cost 0
            :aim state.Aim.foe
            :icon icons.TILE_FISHBONE)
        (make ac.Item
            :name "MOUSE ON STRING"
            :text "Hits #, then # to the next enemy."
            :slot ac.Slot.wand
            :amount 6
            :step 2
            :cost 0
            :aim state.Aim.foe
            :icon icons.TILE_MOUSE)
        (make ac.Item
            :name "FLUFF"
            :text "Shield #.|3rd fluff this turn: shield stays."
            :slot ac.Slot.fluff
            :amount 4
            :step 2
            :cost 0
            :aim state.Aim.self
            :icon icons.TILE_FLUFF)
        (make ac.Item
            :name "SPIKY FLUFF"
            :text "Shield #.|3rd fluff this turn: hitters take 6"
            :slot ac.Slot.fluff
            :amount 6
            :step 2
            :cost 0
            :aim state.Aim.self
            :icon icons.TILE_SPIKY)
        (make ac.Item
            :name "CARDBOARD BOX"
            :text "Shield #.|3rd fluff this turn: +1 kitten,|and attacks on all miss you."
            :slot ac.Slot.fluff
            :amount 6
            :step 2
            :cost 0
            :aim state.Aim.self
            :icon icons.TILE_BOX)
        (make ac.Item
            :name "WARM BLANKET"
            :text "Shield #.|3rd fluff this turn: heal 6."
            :slot ac.Slot.fluff
            :amount 4
            :step 2
            :cost 0
            :aim state.Aim.self
            :icon icons.TILE_BLANKET)
        (make ac.Item
            :name "STATIC FUR"
            :text "Shield #.|3rd fluff this turn: 10 to all,|or 20 to an enemy that is wet."
            :slot ac.Slot.fluff
            :amount 6
            :step 2
            :cost 0
            :aim state.Aim.self
            :icon icons.TILE_STATIC)
        (make ac.Item
            :name "BELL COLLAR"
            :text "Shield #.|3rd fluff this turn: block 2 curses"
            :slot ac.Slot.fluff
            :amount 6
            :step 2
            :cost 0
            :aim state.Aim.self
            :icon icons.TILE_BELL)
        (make ac.Item
            :name "STAR"
            :text "Makes # mana."
            :slot ac.Slot.star
            :amount 2
            :step 1
            :cost 0
            :aim state.Aim.self
            :icon icons.TILE_STAR)
        (make ac.Item
            :name "SHOOTING STAR"
            :text "Makes 1 mana, and hits an enemy #."
            :slot ac.Slot.star
            :amount 6
            :step 2
            :cost 0
            :aim state.Aim.foe
            :icon icons.TILE_SHOOTING)
        (make ac.Item
            :name "MOON BOWL"
            :text "Makes 1 mana, and shield #."
            :slot ac.Slot.star
            :amount 2
            :step 1
            :cost 0
            :aim state.Aim.self
            :icon icons.TILE_MOONBOWL)
        (make ac.Item
            :name "WISHING STAR"
            :text "Makes # mana; next wand hits x2."
            :slot ac.Slot.star
            :amount 1
            :step 1
            :cost 0
            :aim state.Aim.self
            :icon icons.TILE_WISHING)
        (make ac.Item
            :name "LITTER STAR"
            :text "Makes # mana.|Each kitten you have adds 1 more."
            :slot ac.Slot.star
            :amount 2
            :step 1
            :cost 0
            :aim state.Aim.self
            :icon icons.TILE_LITTER)
        (make ac.Item
            :name "ZOOMIES"
            :text "2 mana: 5 hits of #, left to right"
            :slot ac.Slot.book
            :amount 4
            :step 2
            :cost 2
            :aim state.Aim.all
            :icon icons.TILE_ZOOMIES)
        (make ac.Item
            :name "MEOWCRONOMICON"
            :text "3 mana: # kittens join you."
            :slot ac.Slot.book
            :amount 3
            :step 1
            :cost 3
            :aim state.Aim.self
            :icon icons.TILE_MEOWBOOK)
        (make ac.Item
            :name "LASER POINTER"
            :text "3 mana: # to every enemy.|Their next hit goes to a friend."
            :slot ac.Slot.book
            :amount 12
            :step 2
            :cost 3
            :aim state.Aim.all
            :icon icons.TILE_LASER)
        (make ac.Item
            :name "3 AM SCREAMING"
            :text "3 mana: # to all foes, 1 to you."
            :slot ac.Slot.book
            :amount 18
            :step 2
            :cost 3
            :aim state.Aim.all
            :icon icons.TILE_SCREAM)
        (make ac.Item
            :name "KNOCK IT OFF"
            :text "3 mana: hits #.|Its shield and boosts go first."
            :slot ac.Slot.book
            :amount 24
            :step 2
            :cost 3
            :aim state.Aim.foe
            :icon icons.TILE_KNOCK)
        (make ac.Item
            :name "IF IT FITS"
            :text "2 mana: shield #.|Each kitten you have adds 2 more."
            :slot ac.Slot.book
            :amount 16
            :step 2
            :cost 2
            :aim state.Aim.self
            :icon icons.TILE_FITS)
        (make ac.Item
            :name "KITTEN CANNON"
            :text "Fires all your kittens: # each."
            :slot ac.Slot.wand
            :amount 12
            :step 2
            :cost 0
            :aim state.Aim.foe
            :icon icons.TILE_CANNON)
        (make ac.Item
            :name "FLEAS"
            :text "Fleas bite it # a turn, 3 turns."
            :slot ac.Slot.curse
            :amount 2
            :step 1
            :cost 0
            :aim state.Aim.foe
            :icon icons.TILE_FLEAS)
        (make ac.Item
            :name "WET"
            :text "Its hits are halved for # turns."
            :slot ac.Slot.curse
            :amount 1
            :step 1
            :cost 0
            :aim state.Aim.foe
            :icon icons.TILE_WET)
        (make ac.Item
            :name "BALL OF YARN"
            :text "Its next turn's hits are # less."
            :slot ac.Slot.curse
            :amount 2
            :step 1
            :cost 0
            :aim state.Aim.foe
            :icon icons.TILE_YARNBALL)
        (make ac.Item
            :name "MARK TERRITORY"
            :text "Every hit on it does # more.|Your kittens go for it first."
            :slot ac.Slot.curse
            :amount 3
            :step 1
            :cost 0
            :aim state.Aim.foe
            :icon icons.TILE_MARK)
        (make ac.Item
            :name "PLUS ONE"
            :text "Your next die's number is +#."
            :slot ac.Slot.trick
            :amount 4
            :step 2
            :cost 0
            :aim state.Aim.self
            :icon icons.TILE_PLUS1)
        (make ac.Item
            :name "TIMES TWO"
            :text "Your next die's number is x#."
            :slot ac.Slot.trick
            :amount 2
            :step 1
            :cost 0
            :aim state.Aim.self
            :icon icons.TILE_TIMES2)
        (make ac.Item
            :name "COPYCAT"
            :text "Plays your last die again, # more."
            :slot ac.Slot.trick
            :amount 0
            :step 2
            :cost 0
            :aim state.Aim.self
            :icon icons.TILE_COPYCAT)
        (make ac.Item
            :name "CATNIP"
            :text "Next # dice +1.|Kittens pounce twice this turn."
            :slot ac.Slot.trick
            :amount 4
            :step 1
            :cost 0
            :aim state.Aim.self
            :icon icons.TILE_CATNIP)
        (make ac.Item
            :name "KNEAD"
            :text "Next fluff x2, and next wand +#."
            :slot ac.Slot.trick
            :amount 4
            :step 2
            :cost 0
            :aim state.Aim.self
            :icon icons.TILE_KNEAD)
        (make ac.Item
            :name "HAIRBALL"
            :text "A dud. Re-roll it to cough it up."
            :slot ac.Slot.junk
            :amount 0
            :step 0
            :cost 0
            :aim state.Aim.self
            :icon icons.TILE_HAIRBALL)
        (make ac.Item
            :name "RED DOT"
            :text "Puts # red dots on it.|A wand hit on it brings dice back."
            :slot ac.Slot.curse
            :amount 2
            :step 1
            :cost 0
            :aim state.Aim.foe
            :icon icons.TILE_REDDOT)
        (make ac.Item
            :name "MIMIC"
            :text "2 mana: use its next move # times."
            :slot ac.Slot.book
            :amount 1
            :step 1
            :cost 2
            :aim state.Aim.foe
            :icon icons.TILE_MIMIC)
        (make ac.Item
            :name "CATFIGHT"
            :text "Its next hit goes to a friend, +#."
            :slot ac.Slot.curse
            :amount 6
            :step 2
            :cost 0
            :aim state.Aim.foe
            :icon icons.TILE_CATFIGHT)
        (make ac.Item
            :name "MIRROR FUR"
            :text "Shield #.|Blocked hits bounce back: # most."
            :slot ac.Slot.fluff
            :amount 5
            :step 2
            :cost 0
            :aim state.Aim.self
            :icon icons.TILE_MIRRORFUR)
        (make ac.Item
            :name "LUCKY PAW"
            :text "Shield #. You get a free re-roll."
            :slot ac.Slot.fluff
            :amount 5
            :step 2
            :cost 0
            :aim state.Aim.self
            :icon icons.TILE_LUCKYPAW)
        (make ac.Item
            :name "FLEA CIRCUS"
            :text "Fleas # on it and a random other."
            :slot ac.Slot.curse
            :amount 3
            :step 1
            :cost 0
            :aim state.Aim.foe
            :icon icons.TILE_FLEACIRCUS)
        (make ac.Item
            :name "SUNBEAM"
            :text "Makes # mana.|Mana past 5: re-rolls, 2 at most."
            :slot ac.Slot.star
            :amount 2
            :step 1
            :cost 0
            :aim state.Aim.self
            :icon icons.TILE_SUNBEAM)
        (make ac.Item
            :name "SCRATCHING HABIT"
            :text "Hits #, +2 per use this fight."
            :slot ac.Slot.wand
            :amount 6
            :step 2
            :cost 0
            :aim state.Aim.foe
            :icon icons.TILE_HABIT)
        (make ac.Item
            :name "DOUBLE OR NOTHING"
            :text "Next die's number x#.|If no die uses it: you lose # hp."
            :slot ac.Slot.trick
            :amount 2
            :step 1
            :cost 0
            :aim state.Aim.self
            :icon icons.TILE_DOUBLE))
    :strings aux) ; its strings in aux memory; the table in main memory: the fights read its

; numbers every play (a read from aux memory each cost a fight's frames 14%)

(fn name ((row u8)) (ptr u8)
    (at ITEMS row name))

(fn text ((row u8)) (ptr u8)
    (at ITEMS row text))

(fn slot ((row u8)) ac.Slot
    (at ITEMS row slot))

(fn amount ((row u8)) u8
    (at ITEMS row amount))

(fn step ((row u8)) u8
    (at ITEMS row step))

(fn cost ((row u8)) u8
    (at ITEMS row cost))

(fn aim ((row u8)) state.Aim
    (at ITEMS row aim))

(fn icon ((row u8)) u8
    (at ITEMS row icon))

; what she starts with, a slot each: wand, fluff, star, book, curse, then the sixth slot
(const STARTING_ITEMS (array u8 6) (make (array u8 6) TWIG_WAND FLUFF STAR ZOOMIES FLEAS PLUS))
