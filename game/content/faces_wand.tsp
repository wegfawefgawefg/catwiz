; the faces for her wand face: wands: what hits an enemy (content/faces.tsp says what a row is).

(import content/cards)

(macro rows ()
    '((TWIG_WAND
            :name "TWIG WAND"
            :text "Hit enemy for #.|3rd wand in a turn also hits all|other enemies for #."
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
                (say "Your third wand hits every enemy!")
                (others)
                (hit)
                (end)))
        (YARN_WAND
            :name "YARN WAND"
            :text "Hit enemy for #.|Enemy hits 1 less next turn."
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
            :text "Hit enemy for #.|Enemy hits half next turn."
            :slot wand
            :amount 4
            :step 2
            :cost 0
            :aim foe
            :tags ()
            :show SPRAY
            :picture spray
            :weight 3
            :steps ((call ZAP_HIT) (if_up) (lit 1) (call WET)))
        (FEATHER_TOY
            :name "FEATHER TOY"
            :text "Hit enemy for #.|Your kittens pounce on enemy."
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
            :text "Hit enemy for #, ignoring shield."
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
            :text "Hit enemy for #.|Then hit the next enemy for #.|A lone enemy takes both hits."
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
            :text "Each kitten hits enemy for #.|All your kittens fire and are gone."
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
                (say "You fire # kittens!")
                (rep)
                (retarget)
                (num)
                (hit)
                (end)))
        (SCRATCHING_HABIT
            :name "SCRATCHING HABIT"
            :text "Hit enemy for #.|Then this wand hits # more for|the rest of the fight."
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
            :text "Hit enemy for #."
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
            :text "Hit enemy for #.|3rd wand in a turn also hits|3 more times for # each."
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
                (say "Third wand! You hit 3 more times.")
                (lit 3)
                (rep)
                (retarget)
                (num)
                (hit)
                (end)))
        (SCRATCH_ITCH
            :name "SCRATCH THE ITCH"
            :text "Hit enemy for #.|Each flea on enemy adds 1."
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
            :text "Hit enemy for #.|Wet enemy takes 4 more."
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
            :text "Hit enemy for # plus your shield.|You keep your shield."
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
            :text "Hit enemy for #.|If enemy loses hp, you heal 2."
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
            :text "Hit enemy for #.|If enemy falls, gain 1 mana."
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
            :text "Hit enemy for #, or double if you|have not re-rolled this turn."
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
            :text "Hit enemy for #.|Each other enemy then takes half|the hit before, left to right."
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
            :text "Hit enemy for #, +2 for each time|you were hurt this fight."
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
            :text "Heads: hit enemy for #.|Tails: you take half of #."
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
