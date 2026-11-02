; the faces for her book face: books: spells paid in mana (content/faces.tsp says what a row is).

(import content/cards)

(macro rows ()
    '((ZOOMIES
            :name "ZOOMIES"
            :text "2 mana: 5 hits of #, left to right"
            :slot book
            :amount 2
            :step 1
            :cost 2
            :aim all
            :tags ()
            :show STREAK
            :picture zoomies
            :weight 0
            :steps ((cue zap) (me) (lit cards.ZOOMIES_HITS) (rep) (next) (num) (hit) (end)))
        (MEOW_BOOK
            :name "MEOWCRONOMICON"
            :text "3 mana: # kittens join you."
            :slot book
            :amount 3
            :step 1
            :cost 3
            :aim self
            :tags (kittens)
            :show NONE
            :picture meowbook
            :weight 3
            :steps ((cue meow) (add kittens) (get kittens) (say KITTENS_JOIN_YOU)))
        (LASER
            :name "LASER POINTER"
            :text "3 mana: # to every enemy.|Their next hit goes to a friend."
            :slot book
            :amount 8
            :step 2
            :cost 3
            :aim all
            :tags ()
            :show BOLT
            :picture laser
            :weight 3
            :steps ((cue zap) (all) (num) (hit) (if_up) (lit 1) (t_set laser) (end)))
        (SCREAM
            :name "3 AM SCREAMING"
            :text "3 mana: # to all foes, 1 to you."
            :slot book
            :amount 8
            :step 2
            :cost 3
            :aim all
            :tags ()
            :show BOLT
            :picture scream
            :weight 3
            :steps ((cue wobble) (all)
                (hit)
                (end)
                (lit cards.SCREAM_SELF)
                (me)
                (hurt)
                (say_me " \x0dtakes # from screaming.")))
        (KNOCK
            :name "KNOCK IT OFF"
            :text "3 mana: hits #.|Its shield and boosts go first."
            :slot book
            :amount 12
            :step 2
            :cost 3
            :aim foe
            :tags ()
            :show BOLT
            :picture knock
            :weight 3
            :steps ((cue zap) (lit 0)
                (t_set shield)
                (t_set cheer)
                (t_set strength)
                (t_set reflect)
                (say_it " drops its shield and buffs.")
                (num)
                (hit)))
        (FITS
            :name "IF IT FITS"
            :text "2 mana: shield 3, and # more|for each kitten you have."
            :slot book
            :amount 1
            :step 1
            :cost 2
            :aim self
            :tags (kittens)
            :show NONE
            :picture fits
            :weight 2
            :steps ((lit 3) (kits 0) (call SHIELD)))
        (MIMIC
            :name "MIMIC"
            :text "2 mana: use its next move # times."
            :slot book
            :amount 1
            :step 1
            :cost 2
            :aim foe
            :tags ()
            :show MIMIC
            :picture mimic
            :weight 1
            :steps ((cue mimic) (look) (rep) (retarget) (mimic) (end)))))
