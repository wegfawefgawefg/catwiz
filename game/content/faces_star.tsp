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
            :weight 4
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
            :weight 2
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
            :weight 1
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
            :weight 4
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
                (say MANA_NOW)))))
