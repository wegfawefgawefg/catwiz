; the faces for her star face: stars: mana (content/faces.tsp says what a row is).

(import content/cards)

(macro rows ()
    '((STAR
            :name "STAR"
            :text "Gain # mana."
            :slot star
            :amount 2
            :step 1
            :cost 0
            :aim self
            :tags ()
            :show NONE
            :picture star
            :weight 0
            :steps ((cue chime) (mana) (get mana) (say MANA_NOW)))
        (SHOOTING_STAR
            :name "SHOOTING STAR"
            :text "Hit enemy for # and gain 1 mana."
            :slot star
            :amount 4
            :step 2
            :cost 0
            :aim foe
            :tags ()
            :show BOLT
            :picture shooting
            :weight 3
            :steps ((cue zap) (lit 1) (mana) (num) (hit)))
        (MOON_BOWL
            :name "MOON BOWL"
            :text "Gain # shield and 1 mana."
            :slot star
            :amount 2
            :step 1
            :cost 0
            :aim self
            :tags ()
            :show NONE
            :picture moonbowl
            :weight 3
            :steps ((cue ping) (lit 1)
                (mana)
                (num)
                (add shield)
                (say_me " \x0cgets # shield and 1 mana.")))
        (WISHING_STAR
            :name "WISHING STAR"
            :text "Gain # mana.|Your next wand hits double."
            :slot star
            :amount 1
            :step 1
            :cost 0
            :aim self
            :tags ()
            :show NONE
            :picture wishing
            :weight 3
            :steps ((cue chime) (mana)
                (lit 1)
                (set wish)
                (say "Wish! Your next wand hits double.")))
        (LITTER_STAR
            :name "LITTER STAR"
            :text "Gain # mana, +1 for each kitten."
            :slot star
            :amount 1
            :step 1
            :cost 0
            :aim self
            :tags (kittens)
            :show NONE
            :picture litter
            :weight 3
            :steps ((kits 1) (cue chime) (mana) (get mana) (say MANA_NOW)))
        (SUNBEAM
            :name "SUNBEAM"
            :text "Gain # mana.|Mana past your most becomes|re-rolls, 2 at most."
            :slot star
            :amount 2
            :step 1
            :cost 0
            :aim self
            :tags ()
            :show SUNBEAM
            :picture sunbeam
            :weight 3
            :steps ((cue glow) (spill)
                (most cards.SUNBEAM_REROLLS)
                (rerolls)
                (get mana)
                (say MANA_NOW)))
        ; the faces round (docs/faces.md)
        (BRIGHT_STAR
            :name "BRIGHT STAR"
            :text "Gain # mana."
            :slot star
            :amount 3
            :step 1
            :cost 0
            :aim self
            :tags ()
            :show MANA_SWIRL
            :picture brightstar
            :weight 3
            :steps ((cue sparkle) (mana) (get mana) (say MANA_NOW)))
        (STAR_CLUSTER
            :name "STAR CLUSTER"
            :text "Gain # mana.|3rd star in a turn adds 2 re-rolls."
            :slot star
            :amount 2
            :step 1
            :cost 0
            :aim self
            :tags (three)
            :show MANA_SWIRL
            :picture starcluster
            :weight 3
            :steps ((cue sparkle) (mana)
                (get mana)
                (say MANA_NOW)
                (three)
                (lit 2)
                (rerolls)
                (say "Third star! You get 2 re-rolls.")))
        (FLEA_MARKET
            :name "FLEA MARKET"
            :text "Gain # mana.|Each enemy with fleas adds 1."
            :slot star
            :amount 1
            :step 1
            :cost 0
            :aim self
            :tags ()
            :show MANA_SWIRL
            :picture fleamarket
            :weight 3
            :steps ((cue buzz) (mana)
                (lit 1)
                (all)
                (t_has poison)
                (mana)
                (end)
                (get mana)
                (say MANA_NOW)))
        (MOON_TIDE
            :name "MOON TIDE"
            :text "Gain # mana, +1 per wet enemy."
            :slot star
            :amount 2
            :step 1
            :cost 0
            :aim self
            :tags ()
            :show MANA_SWIRL
            :picture moontide
            :weight 3
            :steps ((cue splash) (mana)
                (lit 1)
                (all)
                (t_has wet)
                (mana)
                (end)
                (get mana)
                (say MANA_NOW)))
        (FORTIFY
            :name "FORTIFY"
            :text "Gain # mana, then 1 shield per|mana you have."
            :slot star
            :amount 1
            :step 1
            :cost 0
            :aim self
            :tags ()
            :show MANA_SWIRL
            :picture fortify
            :weight 3
            :steps ((cue sparkle) (mana) (get mana) (add shield) (say_me SHIELDS)))
        (PURR
            :name "PURR"
            :text "Gain # mana and heal 1."
            :slot star
            :amount 1
            :step 1
            :cost 0
            :aim self
            :tags ()
            :show HEART
            :picture purr
            :weight 3
            :steps ((cue chime) (mana) (lit 1) (heal)))
        (OVERFLOW
            :name "OVERFLOW"
            :text "Gain # mana.|Each mana past your most hits a|random enemy for 2."
            :slot star
            :amount 3
            :step 1
            :cost 0
            :aim self
            :tags ()
            :show MANA_SWIRL
            :picture overflow
            :weight 3
            :steps ((cue sparkle) (spill)
                (rep)
                (me)
                (pick)
                (lit 2)
                (hit)
                (end)
                (get mana)
                (say MANA_NOW)))
        (RATTLE
            :name "RATTLE"
            :text "Gain # mana and 1 re-roll."
            :slot star
            :amount 1
            :step 1
            :cost 0
            :aim self
            :tags ()
            :show DIE_FLIP
            :picture rattle
            :weight 3
            :steps ((cue rattle) (mana) (lit 1) (rerolls) (get mana) (say MANA_NOW)))))
