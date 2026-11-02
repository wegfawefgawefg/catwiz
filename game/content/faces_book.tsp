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
            :weight 3
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
            :weight 3
            :steps ((cue mimic) (look) (rep) (retarget) (mimic) (end)))
        ; the faces round (docs/faces.md)
        (HAIRBALL_BLAST
            :name "HAIRBALL BLAST"
            :text "2 mana: hits #."
            :slot book
            :amount 9
            :step 2
            :cost 2
            :aim foe
            :tags ()
            :show BOLT
            :picture hairballblast
            :weight 3
            :steps ((call ZAP_HIT)))
        (PLAGUE
            :name "PLAGUE"
            :text "2 mana: fleas # on every enemy."
            :slot book
            :amount 3
            :step 1
            :cost 2
            :aim all
            :tags ()
            :show FLEAS
            :picture plague
            :weight 3
            :steps ((cue buzz) (all) (call FLEAS) (end)))
        (RAIN_CLOUD
            :name "RAIN CLOUD"
            :text "2 mana: wets every enemy, # turns."
            :slot book
            :amount 2
            :step 1
            :cost 2
            :aim all
            :tags ()
            :show RAIN
            :picture raincloud
            :weight 3
            :steps ((cue splash) (all) (call WET) (end)))
        (THUNDER_PURR
            :name "THUNDER PURR"
            :text "3 mana: # to every enemy,|twice that to a wet one."
            :slot book
            :amount 6
            :step 2
            :cost 3
            :aim all
            :tags ()
            :show LIGHTNING
            :picture thunderpurr
            :weight 3
            :steps ((cue thunder) (all) (num) (t_has wet) (more 0) (hit) (end)))
        (SHIELD_BASH
            :name "SHIELD BASH"
            :text "2 mana: every enemy takes half|your shield, +#."
            :slot book
            :amount 0
            :step 2
            :cost 2
            :aim all
            :tags (plus)
            :show SHIELD_FLING
            :picture shieldbash
            :weight 3
            :steps ((cue whoosh) (get shield) (half) (more 0) (all) (hit) (end)))
        (BLOOD_MOON
            :name "BLOOD MOON"
            :text "Costs 3 hp, no mana: hits #."
            :slot book
            :amount 14
            :step 2
            :cost 3
            :aim foe
            :tags (hp)
            :show BOLT
            :picture bloodmoon
            :weight 3
            :steps ((cue zap) (hit) (lit 3) (me) (hurt) (say_me " \x0bpays # hp.")))
        (MANA_BURN
            :name "MANA BURN"
            :text "All your mana: hits # for each."
            :slot book
            :amount 4
            :step 2
            :cost 1
            :aim foe
            :tags ()
            :show MANA_SWIRL
            :picture manaburn
            :weight 3
            :steps ((cue sparkle) (num)
                (set tmp)
                (get mana)
                (more 1)
                (times tmp)
                (get tmp)
                (hit)
                (lit 0)
                (set mana)))
        (FRESH_ROLL
            :name "FRESH ROLL"
            :text "1 mana: your played dice come back."
            :slot book
            :amount 0
            :step 0
            :cost 1
            :aim self
            :tags (none)
            :show DIE_FLIP
            :picture freshroll
            :weight 3
            :steps ((cue rattle) (back) (say "Fresh roll: the dice come back.")))
        (LULLABY
            :name "LULLABY"
            :text "3 mana: it skips its next move.|The Bulldog King stays awake."
            :slot book
            :amount 0
            :step 0
            :cost 3
            :aim foe
            :tags (none)
            :show ZZZ
            :picture lullaby
            :weight 3
            :steps ((cue snore) (lit 1) (curse sleep) (say_it " \x09falls asleep.")))
        (LASER_SHOW
            :name "LASER SHOW"
            :text "3 mana: each enemy's next hit|goes to the friend on its right."
            :slot book
            :amount 0
            :step 0
            :cost 3
            :aim all
            :tags (none)
            :show SPIRAL
            :picture lasershow
            :weight 3
            :steps ((cue zap) (all)
                (lit 1)
                (t_set laser)
                (end)
                (say "Laser show! They turn on friends.")))
        (SNOWBALL
            :name "SNOWBALL"
            :text "2 mana: hits #.|Each one after it this fight: +4."
            :slot book
            :amount 6
            :step 2
            :cost 2
            :aim foe
            :tags ()
            :show BOLT
            :picture snowball
            :weight 3
            :steps ((cue zap) (num) (plus snowball) (hit) (lit 4) (add snowball)))))
