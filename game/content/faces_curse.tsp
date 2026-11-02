; the faces for her curse face: curses: a status on an enemy (content/faces.tsp says what a row is).

(import content/cards)

(macro rows ()
    '((FLEAS
            :name "FLEAS"
            :text "Fleas bite it # a turn, 3 turns."
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
            :text "Its hits are halved for # turns."
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
            :text "Its next turn's hits are # less."
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
            :text "Every hit on it does # more.|Your kittens go for it first."
            :slot curse
            :amount 1
            :step 1
            :cost 0
            :aim foe
            :tags ()
            :show PUFF
            :picture mark
            :weight 3
            :steps ((curse brand) (t_get brand) (say_it " \x09is marked: hits +#.")))
        (RED_DOT
            :name "RED DOT"
            :text "Puts # red dots on it.|A wand hit on it brings dice back."
            :slot curse
            :amount 1
            :step 1
            :cost 0
            :aim foe
            :tags ()
            :show RED_DOT
            :picture reddot
            :weight 1
            :steps ((cue dart) (curse dot) (t_get dot) (say_it " \x09has a red dot: # times.")))
        (CATFIGHT
            :name "CATFIGHT"
            :text "Its next hit goes to a friend, +#."
            :slot curse
            :amount 6
            :step 2
            :cost 0
            :aim foe
            :tags ()
            :show CATFIGHT
            :picture catfight
            :weight 3
            :steps ((cue yowl) (curse catfight) (t_get catfight) (say_it " wants a catfight: +#.")))
        (FLEA_CIRCUS
            :name "FLEA CIRCUS"
            :text "Fleas # on it and a random other."
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
                (say_it " \x09gets a flea circus: #.")
                (pick)
                (num)
                (curse poison)
                (lit cards.FLEA_TURNS)
                (t_set flea_turns)
                (t_get poison)
                (say_it " \x09gets a flea circus: #.")))
        ; the faces round (docs/faces.md)
        (GLARE
            :name "GLARE"
            :text "Its next turn's hits are # less."
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
            :text "Every hit on it does # more.|3rd curse this turn: all get +2."
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
                (say_it " \x09is marked: hits +#.")
                (three)
                (say "Third in a turn: all marked!")
                (all)
                (lit 2)
                (curse brand)
                (end)))
        (FLEA_COMB
            :name "FLEA COMB"
            :text "Its fleas bite x# as hard."
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
            :text "It is wet for # turns,|and marked: hits on it +1."
            :slot curse
            :amount 3
            :step 1
            :cost 0
            :aim foe
            :tags ()
            :show SPRAY
            :picture drenched
            :weight 3
            :steps ((cue splash) (call WET)
                (lit 1)
                (curse brand)
                (say_it " \x09is marked: hits +#.")))
        (LEECH
            :name "LEECH"
            :text "Each hit you land on it heals you|1, for # turns."
            :slot curse
            :amount 3
            :step 1
            :cost 0
            :aim foe
            :tags ()
            :show HEART
            :picture leech
            :weight 3
            :steps ((cue slurp) (curse leech) (t_get leech) (say_it " \x09is leeched: # turns.")))
        (MANA_LEECH
            :name "MANA LEECH"
            :text "Each hit on it this turn makes|# mana."
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
                (say_it " \x09is a mana leech: # a hit.")))
        (SPOOK
            :name "SPOOK"
            :text "Its next attack is a shield of|its number instead."
            :slot curse
            :amount 1
            :step 0
            :cost 0
            :aim foe
            :tags (none)
            :show ALERT
            :picture spook
            :weight 3
            :steps ((cue boing) (lit 1) (curse scared) (say_it " \x09is scared: it will hide.")))
        (HYPNOTIZE
            :name "HYPNOTIZE"
            :text "Its next attack hits a fighter at|random, its friends too."
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
            :text "Its next attack hits everyone,|itself too."
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
