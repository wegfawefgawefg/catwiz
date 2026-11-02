; the charms, a row each: passives kept all run (docs/faces.md). Data only, as the faces
; (content/faces.tsp): the build lays each row out on the second disk (content/catalog), and memory
; holds only the charms she has and the three offered. To add a charm, add its row here (and its
; picture: tools/dhgr/charm_icons.py, then python3 tools/dhgr/game.py).
;
; A row: (NAME :field value ...). The fields:
;   :name     in capitals, 17 columns at most;  :text  its line (# its amount), 35 columns
;   :kind     what it is (content/encounters CharmKind): a charm that changes a rule is read where
;             the rule is, by its kind (content/charms amount)
;   :amount   how much (its steps' v, times the ones she holds)
;   :when     the moment its steps run (steps.When: fight_start, hurt, warded, three, dies,
;             turn_end; none for a rule)
;   :mark     its glyph on the card in the tray (the hud font, tools/dhgr/game_hud.py)
;   :picture  its card picture's name in tools/dhgr/charm_icons.py
;   :weight   its share of the charm draws after an elite;  :steps  as a face's

(macro rows ()
    '((SCRATCH_POST
            :name "SCRATCH POST"
            :text "One more re-roll each turn."
            :kind pocket
            :amount 1
            :when none
            :mark "+"
            :picture scratchpost
            :weight 3
            :steps ())
        (SIXTH_TOE
            :name "SIXTH TOE"
            :text "Roll 6 dice, but 1 re-roll less."
            :kind toe
            :amount 1
            :when none
            :mark "6"
            :picture sixthtoe
            :weight 3
            :steps ())
        (STILL_WATER
            :name "STILL WATER"
            :text "A turn with no re-roll: +2 mana."
            :kind still
            :amount 2
            :when turn_end
            :mark "%"
            :picture stillwater
            :weight 3
            :steps ((calm) (mana)))
        (TRIO
            :name "PURRFECT TRIO"
            :text "Each three of a kind: 2 to all."
            :kind trio
            :amount 2
            :when three
            :mark "3"
            :picture trio
            :weight 3
            :steps ((all) (plain) (end)))
        (MITTENS
            :name "KITTEN MITTENS"
            :text "Your kittens hit 1 harder."
            :kind mittens
            :amount 1
            :when none
            :mark "_"
            :picture mittens
            :weight 3
            :steps ())
        (MOTHER_CAT
            :name "MOTHER CAT"
            :text "Each fight starts with a kitten."
            :kind mother
            :amount 1
            :when fight_start
            :mark "*"
            :picture mothercat
            :weight 3
            :steps ((add kittens)))
        (FLUFFY_TAIL
            :name "FLUFFY TAIL"
            :text "Shield halves each turn, not gone."
            :kind tail
            :amount 1
            :when none
            :mark "#"
            :picture fluffytail
            :weight 3
            :steps ())
        (GRUMPY
            :name "GRUMPY FACE"
            :text "A hit that hurts you: +1 mana."
            :kind grumpy
            :amount 1
            :when hurt
            :mark "'"
            :picture grumpy
            :weight 3
            :steps ((mana)))
        (RUBBER_DUCK
            :name "RUBBER DUCK"
            :text "Your ward blocks a curse: shield 2."
            :kind duck
            :amount 2
            :when warded
            :mark ";"
            :picture rubberduck
            :weight 3
            :steps ((add shield)))
        (BAD_MILK
            :name "BAD MILK"
            :text "Wands hit +2; books cost 1 more."
            :kind badmilk
            :amount 2
            :when none
            :mark ","
            :picture badmilk
            :weight 3
            :steps ())
        (LITTER_BOX
            :name "LITTER BOX"
            :text "Half your kittens carry over."
            :kind litterbox
            :amount 1
            :when fight_start
            :mark "e"
            :picture litterbox
            :weight 3
            :steps ((kept) (add kittens)))
        (NINE_LIVES
            :name "NINE LIVES"
            :text "You come back once with # hp."
            :kind lives9
            :amount 6
            :when dies
            :mark "f"
            :picture ninelives
            :weight 3
            :steps ((cue chime) (say_me " \x0ccomes back with # hp!")))
        ; the faces round (docs/faces.md)
        (ECHO
            :name "ECHO"
            :text "Each three of a kind's extra|happens twice."
            :kind echo
            :amount 1
            :when none
            :mark "E"
            :picture echo
            :weight 3
            :steps ())
        (ITCHY
            :name "ITCHY"
            :text "Fleas on enemies bite twice a turn."
            :kind itchy
            :amount 1
            :when none
            :mark ","
            :picture itchy
            :weight 3
            :steps ())
        (FLEA_FARM
            :name "FLEA FARM"
            :text "Each fight starts with fleas #|on every enemy."
            :kind plain
            :amount 2
            :when fight_start
            :mark "c"
            :picture fleafarm
            :weight 3
            :steps ((all) (call FLEAS) (end)))
        (MONSOON
            :name "MONSOON"
            :text "Wet lasts twice as long."
            :kind monsoon
            :amount 1
            :when none
            :mark "%"
            :picture monsoon
            :weight 3
            :steps ())
        (PORCUPINE
            :name "PORCUPINE"
            :text "Your shield takes all of a hit:|the hitter takes #."
            :kind porcupine
            :amount 2
            :when none
            :mark "/"
            :picture porcupine
            :weight 3
            :steps ())
        (THICK_COAT
            :name "THICK COAT"
            :text "Every fluff shields # more."
            :kind coat
            :amount 1
            :when none
            :mark "#"
            :picture thickcoat
            :weight 3
            :steps ())
        (HUNGER
            :name "HUNGER"
            :text "Each enemy you beat heals you #."
            :kind plain
            :amount 2
            :when kill
            :mark "*"
            :picture hunger
            :weight 3
            :steps ((heal)))
        (NINTH_LIFE
            :name "NINTH LIFE"
            :text "After each elite: +# max hp."
            :kind ninth
            :amount 1
            :when none
            :mark "9"
            :picture ninthlife
            :weight 3
            :steps ())
        (CHEAP_TRICK
            :name "CHEAP TRICK"
            :text "First book each turn: # less mana."
            :kind cheap
            :amount 1
            :when none
            :mark "'"
            :picture cheaptrick
            :weight 3
            :steps ())
        (MANA_BATTERY
            :name "MANA BATTERY"
            :text "Your mana holds 9, not 5."
            :kind battery
            :amount 4
            :when none
            :mark "B"
            :picture manabattery
            :weight 1
            :steps ())
        (NAP_SPOT
            :name "NAP SPOT"
            :text "A die you do not play stays for|your next turn."
            :kind nap
            :amount 1
            :when none
            :mark "@"
            :picture napspot
            :weight 3
            :steps ())
        (LUCKY_SEVEN
            :name "LUCKY SEVEN"
            :text "Five different faces showing:|+2 re-rolls."
            :kind lucky7
            :amount 1
            :when none
            :mark "7"
            :picture luckyseven
            :weight 3
            :steps ())
        (CURSED_COIN
            :name "CURSED COIN"
            :text "You roll 6 dice, but lose # hp|each turn."
            :kind cursedcoin
            :amount 1
            :when turn_end
            :mark "6"
            :picture cursedcoin
            :weight 3
            :steps ((hurt) (say_me " \x0bpays # hp to the coin.")))
        (JACKPOT
            :name "JACKPOT"
            :text "Five matching faces win the fight."
            :kind jackpot
            :amount 1
            :when none
            :mark "J"
            :picture jackpot
            :weight 1
            :steps ())
        (RAIN_BOOTS
            :name "RAIN BOOTS"
            :text "Wet enemies take # more from every|hit."
            :kind boots
            :amount 1
            :when none
            :mark "%"
            :picture rainboots
            :weight 3
            :steps ())
        (STORM_CLOUD
            :name "STORM CLOUD"
            :text "Each fight starts with every enemy|wet for # turn."
            :kind plain
            :amount 1
            :when fight_start
            :mark "%"
            :picture stormcloud
            :weight 3
            :steps ((all) (call WET) (end)))
        (TROUBLEMAKER
            :name "TROUBLEMAKER"
            :text "An enemy's hit on its friend is|doubled."
            :kind trouble
            :amount 1
            :when none
            :mark "a"
            :picture troublemaker
            :weight 3
            :steps ())
        (PIED_PIPER
            :name "PIED PIPER"
            :text "Each fight starts with an enemy|hypnotized, picked at random."
            :kind plain
            :amount 1
            :when fight_start
            :mark "P"
            :picture piedpiper
            :weight 3
            :steps ((pick) (lit 1) (t_set hypno) (say_it " \x09is hypnotized.")))
        (MOMENTUM
            :name "MOMENTUM"
            :text "Your first wand each turn hits 1|more than the turn before."
            :kind plain
            :amount 1
            :when turn_start
            :mark "^"
            :picture momentum
            :weight 3
            :steps ((get momentum) (add knead_wand) (lit 1) (add momentum)))
        (THICK_SKIN
            :name "THICK SKIN"
            :text "Each turn: shield 1 for each time|you were hurt this fight."
            :kind plain
            :amount 1
            :when turn_start
            :mark "#"
            :picture thickskin
            :weight 3
            :steps ((get scars) (add shield) (has scars) (say_me SHIELDS)))
        (LUCKY_COLLAR
            :name "LUCKY COLLAR"
            :text "You have # more max hp."
            :kind collar
            :amount 2
            :when none
            :mark "*"
            :picture luckycollar
            :weight 3
            :steps ())
        (SPARE_YARN
            :name "SPARE YARN"
            :text "First turn of a fight: +# re-roll."
            :kind plain
            :amount 1
            :when fight_start
            :mark "["
            :picture spareyarn
            :weight 3
            :steps ((add rolls)))
        (HEAD_START
            :name "HEAD START"
            :text "Each fight starts with # mana."
            :kind plain
            :amount 2
            :when fight_start
            :mark "'"
            :picture headstart
            :weight 3
            :steps ((mana)))))
