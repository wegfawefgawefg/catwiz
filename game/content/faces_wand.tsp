; the faces for her wand face: wands: what hits an enemy (content/faces.tsp says what a row is).

(import content/cards)

(macro rows ()
    '((TWIG_WAND
            :name "TWIG WAND"
            :text "Hits #.|3rd wand this turn: it hits all."
            :slot wand
            :amount 4
            :step 2
            :cost 0
            :aim foe
            :tags (three)
            :show BOLT
            :picture twig
            :weight 0
            :steps ((call ZAP_HIT) (three)
                (say "Third in a turn: it hits all!")
                (others)
                (hit)
                (end)))
        (YARN_WAND
            :name "YARN WAND"
            :text "Hits #.|If it stands: its hits are 1 less."
            :slot wand
            :amount 4
            :step 2
            :cost 0
            :aim foe
            :tags ()
            :show BOLT
            :picture yarnwand
            :weight 3
            :steps ((call ZAP_HIT) (if_up) (lit 1) (call TANGLE)))
        (SPRAY_BOTTLE
            :name "SPRAY BOTTLE"
            :text "Hits #.|If it stands: it hits half, 1 turn."
            :slot wand
            :amount 4
            :step 2
            :cost 0
            :aim foe
            :tags ()
            :show SPRAY
            :picture spray
            :weight 4
            :steps ((call ZAP_HIT) (if_up) (lit 1) (call WET)))
        (FEATHER_TOY
            :name "FEATHER TOY"
            :text "Hits #, then kittens pounce on it."
            :slot wand
            :amount 2
            :step 2
            :cost 0
            :aim foe
            :tags (kittens)
            :show BOLT
            :picture feather
            :weight 3
            :steps ((call ZAP_HIT) (pounce)))
        (FISHBONE_WAND
            :name "FISHBONE WAND"
            :text "Hits #. Goes through any shield."
            :slot wand
            :amount 6
            :step 2
            :cost 0
            :aim foe
            :tags ()
            :show BOLT
            :picture fishbone
            :weight 3
            :steps ((cue zap) (pierce)))
        (MOUSE_STRING
            :name "MOUSE ON STRING"
            :text "Hits #, then # to the next enemy."
            :slot wand
            :amount 4
            :step 2
            :cost 0
            :aim foe
            :tags ()
            :show BOLT
            :picture mouse
            :weight 3
            :steps ((call ZAP_HIT) (next) (hit)))
        (CANNON
            :name "KITTEN CANNON"
            :text "Fires all your kittens: # each."
            :slot wand
            :amount 8
            :step 2
            :cost 0
            :aim foe
            :tags ()
            :show BOLT
            :picture cannon
            :weight 3
            :steps ((cue zap) (get kittens)
                (sub kittens)
                (say "# kittens launched!")
                (rep)
                (retarget)
                (num)
                (hit)
                (end)))
        (SCRATCHING_HABIT
            :name "SCRATCHING HABIT"
            :text "Hits #. Each use adds # more|for the rest of the fight."
            :slot wand
            :amount 2
            :step 1
            :cost 0
            :aim foe
            :tags (grows)
            :show CLAWS
            :picture habit
            :weight 3
            :steps ((cue scratch) (hit) (num) (add habit)))
        ; the faces round (docs/faces.md)
        (BIG_STICK
            :name "BIG STICK"
            :text "Hits #."
            :slot wand
            :amount 6
            :step 2
            :cost 0
            :aim foe
            :tags ()
            :show BOLT
            :picture bigstick
            :weight 3
            :steps ((call ZAP_HIT)))
        (CLAW_SWIPE
            :name "CLAW SWIPE"
            :text "Hits #.|3rd wand this turn: 3 more hits."
            :slot wand
            :amount 3
            :step 2
            :cost 0
            :aim foe
            :tags (three)
            :show CLAWS
            :picture clawswipe
            :weight 3
            :steps ((cue scratch) (hit)
                (three)
                (say "Third in a turn: three more!")
                (lit 3)
                (rep)
                (retarget)
                (num)
                (hit)
                (end)))
        (SCRATCH_ITCH
            :name "SCRATCH THE ITCH"
            :text "Hits #, +1 for each flea on it."
            :slot wand
            :amount 3
            :step 2
            :cost 0
            :aim foe
            :tags ()
            :show FLEAS
            :picture scratchtheitch
            :weight 3
            :steps ((cue buzz) (num) (t_plus poison) (hit)))
        (PUDDLE_SPLASH
            :name "PUDDLE SPLASH"
            :text "Hits #.|If it is wet: 4 more."
            :slot wand
            :amount 4
            :step 2
            :cost 0
            :aim foe
            :tags ()
            :show SPRAY
            :picture puddlesplash
            :weight 3
            :steps ((cue splash) (num) (t_has wet) (more 4) (hit)))
        (BOX_SLAM
            :name "BOX SLAM"
            :text "Hits as much as your shield, +#.|Your shield stays."
            :slot wand
            :amount 0
            :step 2
            :cost 0
            :aim foe
            :tags (plus)
            :show SHIELD_FLING
            :picture boxslam
            :weight 3
            :steps ((cue whoosh) (get shield) (more 0) (hit)))
        (LOVE_BITE
            :name "LOVE BITE"
            :text "Hits #.|If it hurts it: you heal 2."
            :slot wand
            :amount 3
            :step 2
            :cost 0
            :aim foe
            :tags ()
            :show HEART
            :picture lovebite
            :weight 3
            :steps ((cue slurp) (hit) (landed) (lit 2) (heal)))
        (MOONBEAM
            :name "MOONBEAM"
            :text "Hits #.|If it beats it: +1 mana."
            :slot wand
            :amount 4
            :step 2
            :cost 0
            :aim foe
            :tags ()
            :show MANA_SWIRL
            :picture moonbeam
            :weight 3
            :steps ((cue sparkle) (hit) (fell) (lit 1) (mana)))
        (CALM_PAW
            :name "CALM PAW"
            :text "Hits #.|No re-roll this turn: twice that."
            :slot wand
            :amount 4
            :step 2
            :cost 0
            :aim foe
            :tags ()
            :show DIE_FLIP
            :picture calmpaw
            :weight 3
            :steps ((cue rattle) (num) (if_calm) (more 0) (hit)))
        (CHAIN_BOUNCE
            :name "CHAIN BOUNCE"
            :text "Hits #, then half that to each|other enemy, halving each time."
            :slot wand
            :amount 4
            :step 2
            :cost 0
            :aim foe
            :tags ()
            :show BOLT
            :picture chainbounce
            :weight 3
            :steps ((cue zap) (hit) (others) (half) (hit) (end)))
        (GRUDGE
            :name "GRUDGE"
            :text "Hits #, +2 for each time you were|hurt this fight."
            :slot wand
            :amount 3
            :step 2
            :cost 0
            :aim foe
            :tags ()
            :show CLAWS
            :picture grudge
            :weight 3
            :steps ((cue scratch) (num) (plus scars) (plus scars) (hit)))
        (COIN_FLIP
            :name "COIN FLIP"
            :text "Heads: hits #.|Tails: it hits you half that."
            :slot wand
            :amount 8
            :step 2
            :cost 0
            :aim foe
            :tags ()
            :show COIN
            :picture coinflip
            :weight 3
            :steps ((cue coin) (coin 3) (say "Tails!") (me) (half) (hit)))))
