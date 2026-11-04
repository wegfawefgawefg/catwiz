; the faces for her curse face: curses: a status on an enemy (content/faces.tsp says what a row is).

(import content/cards)

(macro rows ()
    '((FLEAS
            :name "FLEAS"
            :text "Enemy gets # fleas for 3 turns.|Each flea bites 1 a turn."
            :slot curse
            :amount 2
            :step 1
            :cost 0
            :aim foe
            :tags ()
            :show FLEAS
            :picture fleas
            :weight 0
            :steps ((curse poison) (lit cards.FLEA_TURNS)
                (t_set flea_turns)
                (t_get poison)
                (say_it GETS_FLEAS_TURN)))
        (WET
            :name "WET"
            :text "Wet enemy for # turns.|Wet enemies hit for half."
            :slot curse
            :amount 1
            :step 1
            :cost 0
            :aim foe
            :tags ()
            :show SPRAY
            :picture wet
            :weight 3
            :steps ((least 1) (curse wet) (t_get wet) (say_it WET_HALF_HITS)))
        (TANGLE
            :name "BALL OF YARN"
            :text "Enemy hits # less next turn."
            :slot curse
            :amount 2
            :step 1
            :cost 0
            :aim foe
            :tags ()
            :show PUFF
            :picture yarnball
            :weight 3
            :steps ((curse tangle) (t_get tangle) (say_it TANGLED_HITS)))
        (MARK
            :name "MARK TERRITORY"
            :text "Hits on enemy do # more.|Your kittens go for enemy first.|The mark lasts all fight."
            :slot curse
            :amount 1
            :step 1
            :cost 0
            :aim foe
            :tags ()
            :show PUFF
            :picture mark
            :weight 3
            :steps ((curse brand) (t_get brand) (say_it " \x09is marked +#.")))
        (RED_DOT
            :name "RED DOT"
            :text "Enemy gets # red dots.|A wand hit on enemy uses a dot and|brings all your dice back."
            :slot curse
            :amount 1
            :step 1
            :cost 0
            :aim foe
            :tags ()
            :show RED_DOT
            :picture reddot
            :weight 1
            :steps ((cue dart) (curse dot) (t_get dot) (say_it " \x09has # red dots.")))
        (CATFIGHT
            :name "CATFIGHT"
            :text "Enemy's next hit is # harder and|lands on another enemy."
            :slot curse
            :amount 6
            :step 2
            :cost 0
            :aim foe
            :tags ()
            :show CATFIGHT
            :picture catfight
            :weight 3
            :steps ((cue yowl) (curse catfight)
                (t_get catfight)
                (say_it " will hit a friend # harder.")))
        (FLEA_CIRCUS
            :name "FLEA CIRCUS"
            :text "Enemy gets # fleas, and so does a|random other enemy."
            :slot curse
            :amount 3
            :step 1
            :cost 0
            :aim foe
            :tags ()
            :show FLEAS
            :picture fleacircus
            :weight 3
            :steps ((cue hops) (curse poison)
                (lit cards.FLEA_TURNS)
                (t_set flea_turns)
                (t_get poison)
                (say_it " \x09gets # circus fleas.")
                (pick)
                (num)
                (curse poison)
                (lit cards.FLEA_TURNS)
                (t_set flea_turns)
                (t_get poison)
                (say_it " \x09gets # circus fleas.")))
        ; the faces round (docs/faces.md)
        (GLARE
            :name "GLARE"
            :text "Enemy hits # less next turn."
            :slot curse
            :amount 4
            :step 1
            :cost 0
            :aim foe
            :tags ()
            :show ALERT
            :picture glare
            :weight 3
            :steps ((cue boing) (curse tangle) (t_get tangle) (say_it TANGLED_HITS)))
        (TRIPLE_HEX
            :name "TRIPLE HEX"
            :text "Hits on enemy do # more.|3rd curse in a turn also marks|all enemies, 2 more each."
            :slot curse
            :amount 1
            :step 1
            :cost 0
            :aim foe
            :tags (three)
            :show PUFF
            :picture triplehex
            :weight 3
            :steps ((curse brand) (t_get brand)
                (say_it " \x09is marked +#.")
                (three)
                (say "All enemies are marked!")
                (all)
                (lit 2)
                (curse brand)
                (end)))
        (FLEA_COMB
            :name "FLEA COMB"
            :text "Enemy's fleas multiply by #."
            :slot curse
            :amount 2
            :step 1
            :cost 0
            :aim foe
            :tags (times)
            :show FLEAS
            :picture fleacomb
            :weight 3
            :steps ((cue buzz) (t_times poison) (t_get poison) (say_it GETS_FLEAS_TURN)))
        (DRENCHED
            :name "DRENCHED"
            :text "Enemy is wet for # turns.|Wet enemies hit for half.|Hits on enemy do 1 more."
            :slot curse
            :amount 3
            :step 1
            :cost 0
            :aim foe
            :tags ()
            :show SPRAY
            :picture drenched
            :weight 3
            :steps ((cue splash) (call WET) (lit 1) (curse brand) (say_it " \x09is marked +#.")))
        (LEECH
            :name "LEECH"
            :text "For # turns, each hit you land on|enemy heals you 1."
            :slot curse
            :amount 3
            :step 1
            :cost 0
            :aim foe
            :tags ()
            :show HEART
            :picture leech
            :weight 3
            :steps ((cue slurp) (curse leech)
                (t_get leech)
                (say_it " \x09has a leech for # turns.")))
        (MANA_LEECH
            :name "MANA LEECH"
            :text "Gain # mana for each hit you land|on enemy this turn."
            :slot curse
            :amount 1
            :step 1
            :cost 0
            :aim foe
            :tags ()
            :show MANA_SWIRL
            :picture manaleech
            :weight 3
            :steps ((cue sparkle) (curse mleech)
                (t_get mleech)
                (say_it " \x09gives you # mana a hit.")))
        (SPOOK
            :name "SPOOK"
            :text "Enemy's next attack becomes a|shield of the same number."
            :slot curse
            :amount 1
            :step 0
            :cost 0
            :aim foe
            :tags (none)
            :show ALERT
            :picture spook
            :weight 3
            :steps ((cue boing) (lit 1) (curse scared) (say_it " \x09is scared and will hide.")))
        (HYPNOTIZE
            :name "HYPNOTIZE"
            :text "Enemy's next attack hits anyone at|random, you or another enemy."
            :slot curse
            :amount 1
            :step 0
            :cost 0
            :aim foe
            :tags (none)
            :show SPIRAL
            :picture hypnotize
            :weight 3
            :steps ((cue shimmer) (lit 1) (curse hypno) (say_it " \x09is hypnotized.")))
        (CATNIP_BOMB
            :name "CATNIP BOMB"
            :text "Enemy's next attack hits everyone,|the enemy too."
            :slot curse
            :amount 1
            :step 0
            :cost 0
            :aim foe
            :tags (none)
            :show PUFF
            :picture catnipbomb
            :weight 3
            :steps ((cue puff) (lit 1) (curse berserk) (say_it " \x09goes berserk!")))))
