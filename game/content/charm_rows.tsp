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
            :weight 1
            :steps ())
        (SIXTH_TOE
            :name "SIXTH TOE"
            :text "Roll 6 dice, but 1 re-roll less."
            :kind toe
            :amount 1
            :when none
            :mark "6"
            :picture sixthtoe
            :weight 1
            :steps ())
        (STILL_WATER
            :name "STILL WATER"
            :text "A turn with no re-roll: +2 mana."
            :kind still
            :amount 2
            :when turn_end
            :mark "%"
            :picture stillwater
            :weight 2
            :steps ((calm) (mana)))
        (TRIO
            :name "PURRFECT TRIO"
            :text "Each three of a kind: 2 to all."
            :kind trio
            :amount 2
            :when three
            :mark "3"
            :picture trio
            :weight 1
            :steps ((all) (plain) (end)))
        (MITTENS
            :name "KITTEN MITTENS"
            :text "Your kittens hit 1 harder."
            :kind mittens
            :amount 1
            :when none
            :mark "_"
            :picture mittens
            :weight 2
            :steps ())
        (MOTHER_CAT
            :name "MOTHER CAT"
            :text "Each fight starts with a kitten."
            :kind mother
            :amount 1
            :when fight_start
            :mark "*"
            :picture mothercat
            :weight 1
            :steps ((add kittens)))
        (FLUFFY_TAIL
            :name "FLUFFY TAIL"
            :text "Shield halves each turn, not gone."
            :kind tail
            :amount 1
            :when none
            :mark "#"
            :picture fluffytail
            :weight 1
            :steps ())
        (GRUMPY
            :name "GRUMPY FACE"
            :text "A hit that hurts you: +1 mana."
            :kind grumpy
            :amount 1
            :when hurt
            :mark "'"
            :picture grumpy
            :weight 2
            :steps ((mana)))
        (RUBBER_DUCK
            :name "RUBBER DUCK"
            :text "Your ward blocks a curse: shield 2."
            :kind duck
            :amount 2
            :when warded
            :mark ";"
            :picture rubberduck
            :weight 2
            :steps ((add shield)))
        (BAD_MILK
            :name "BAD MILK"
            :text "Wands hit +2; books cost 1 more."
            :kind badmilk
            :amount 2
            :when none
            :mark ","
            :picture badmilk
            :weight 2
            :steps ())
        (LITTER_BOX
            :name "LITTER BOX"
            :text "Half your kittens carry over."
            :kind litterbox
            :amount 1
            :when fight_start
            :mark "e"
            :picture litterbox
            :weight 2
            :steps ((kept) (add kittens)))
        (NINE_LIVES
            :name "NINE LIVES"
            :text "You come back once with # hp."
            :kind lives9
            :amount 6
            :when dies
            :mark "f"
            :picture ninelives
            :weight 1
            :steps ((cue chime) (say_me " \x0ccomes back with # hp!")))))
