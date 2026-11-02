; the faces for her star face: stars: mana (content/faces.tsp says what a row is).

(import content/cards)

(macro rows ()
    '((STAR
            :name "STAR"
            :text "Makes # mana."
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
            :text "Makes 1 mana, and hits an enemy #."
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
            :text "Makes 1 mana, and shield #."
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
                (say_me " \x0cshields #, +1 mana.")))
        (WISHING_STAR
            :name "WISHING STAR"
            :text "Makes # mana; next wand hits x2."
            :slot star
            :amount 1
            :step 1
            :cost 0
            :aim self
            :tags ()
            :show NONE
            :picture wishing
            :weight 3
            :steps ((cue chime) (mana) (lit 1) (set wish) (say "A wish: the next wand x2.")))
        (LITTER_STAR
            :name "LITTER STAR"
            :text "Makes # mana.|Each kitten you have adds 1 more."
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
            :text "Makes # mana.|Mana past 5: re-rolls, 2 at most."
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
            :text "Makes # mana."
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
            :text "Makes # mana.|3rd star this turn: +2 re-rolls."
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
                (say "Third in a turn: +2 re-rolls.")))
        (FLEA_MARKET
            :name "FLEA MARKET"
            :text "Makes # mana.|1 more for each enemy with fleas."
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
            :text "Makes # mana.|1 more for each wet enemy."
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
            :text "Makes # mana, then shield as much|as your mana."
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
            :text "Makes # mana, and you heal 1."
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
            :text "Makes # mana.|Past your most: 2 to a random enemy|for each."
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
            :text "Makes # mana, and +1 re-roll."
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
