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
            :tags (kittens)
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
            :steps ((cue scratch) (hit) (num) (add habit)))))
