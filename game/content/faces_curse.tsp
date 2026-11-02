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
            :weight 4
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
            :weight 1
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
                (say_it " \x09gets a flea circus: #.")))))
