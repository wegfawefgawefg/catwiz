; the faces for her fluff face: fluff: shields, and what the third fluff of a turn adds (content/faces.tsp says what a row is).

(import content/cards)

(macro rows ()
    '((FLUFF
            :name "FLUFF"
            :text "Gain # shield.|3rd fluff in a turn keeps your|shield into your next turn."
            :slot fluff
            :amount 4
            :step 2
            :cost 0
            :aim self
            :tags (three)
            :show NONE
            :picture fluff
            :weight 0
            :steps ((call SHIELD) (three)
                (lit 1)
                (set keep)
                (say "Your shield stays for next turn.")))
        (SPIKY_FLUFF
            :name "SPIKY FLUFF"
            :text "Gain # shield.|3rd fluff in a turn makes enemies|that hit you take 4."
            :slot fluff
            :amount 4
            :step 2
            :cost 0
            :aim self
            :tags (three)
            :show NONE
            :picture spiky
            :weight 3
            :steps ((call SHIELD) (three)
                (lit 4)
                (max thorns)
                (say "Spiky! Enemies that hit you take #.")))
        (BOX
            :name "CARDBOARD BOX"
            :text "Gain # shield. 3rd fluff in a turn|gives 1 kitten, and attacks that|hit everyone miss you."
            :slot fluff
            :amount 4
            :step 2
            :cost 0
            :aim self
            :tags (three)
            :show NONE
            :picture box
            :weight 3
            :steps ((call SHIELD) (three)
                (lit 1)
                (set box)
                (add kittens)
                (say "You hide in a box with a kitten.")))
        (WARM_BLANKET
            :name "WARM BLANKET"
            :text "Gain # shield.|3rd fluff in a turn heals you 6."
            :slot fluff
            :amount 4
            :step 2
            :cost 0
            :aim self
            :tags (three)
            :show NONE
            :picture blanket
            :weight 3
            :steps ((call SHIELD) (three) (say "Third fluff! The blanket is warm.") (lit 6) (heal)))
        (STATIC_FUR
            :name "STATIC FUR"
            :text "Gain # shield.|3rd fluff in a turn hits every|enemy for 6, a wet enemy for 12."
            :slot fluff
            :amount 4
            :step 2
            :cost 0
            :aim self
            :tags (three)
            :show NONE
            :picture static
            :weight 3
            :steps ((call SHIELD) (three)
                (say "Static! Your fur zaps every enemy.")
                (all)
                (lit 6)
                (t_has wet)
                (lit 12)
                (hit)
                (end)))
        (BELL_COLLAR
            :name "BELL COLLAR"
            :text "Gain # shield.|3rd fluff in a turn blocks the next|2 curses on you."
            :slot fluff
            :amount 4
            :step 2
            :cost 0
            :aim self
            :tags (three)
            :show NONE
            :picture bell
            :weight 3
            :steps ((call SHIELD) (three)
                (lit 2)
                (add ward)
                (say "The bell blocks the next 2 curses.")))
        (MIRROR_FUR
            :name "MIRROR FUR"
            :text "Gain # shield.|Damage your shield blocks goes back|to the attacker, # at most."
            :slot fluff
            :amount 4
            :step 2
            :cost 0
            :aim self
            :tags ()
            :show MIRROR
            :picture mirrorfur
            :weight 3
            :steps ((cue shimmer) (add shield) (say_me SHIELDS) (add mirror)))
        (LUCKY_PAW
            :name "LUCKY PAW"
            :text "Gain # shield and 1 re-roll."
            :slot fluff
            :amount 4
            :step 2
            :cost 0
            :aim self
            :tags ()
            :show LUCKY_PAW
            :picture luckypaw
            :weight 3
            :steps ((cue lucky) (add shield)
                (say_me SHIELDS)
                (lit 1)
                (rerolls)
                (say "You get a free re-roll.")))
        ; the faces round (docs/faces.md)
        (THICK_FUR
            :name "THICK FUR"
            :text "Gain # shield."
            :slot fluff
            :amount 6
            :step 2
            :cost 0
            :aim self
            :tags ()
            :show NONE
            :picture thickfur
            :weight 3
            :steps ((call SHIELD)))
        (FLEA_COLLAR
            :name "FLEA COLLAR"
            :text "Gain # shield.|Enemies that hit you get 2 fleas."
            :slot fluff
            :amount 4
            :step 2
            :cost 0
            :aim self
            :tags ()
            :show FLEAS
            :picture fleacollar
            :weight 3
            :steps ((call SHIELD) (lit 2) (max collar)))
        (PUFFED_UP
            :name "PUFFED UP"
            :text "Double your shield, then add #."
            :slot fluff
            :amount 2
            :step 2
            :cost 0
            :aim self
            :tags (plus)
            :show NONE
            :picture puffedup
            :weight 3
            :steps ((cue ping) (lit 2)
                (times shield)
                (num)
                (add shield)
                (get shield)
                (say_me " \x0cnow has # shield.")))
        (HAIRBALL_WALL
            :name "HAIRBALL WALL"
            :text "Gain # shield.|Enemies that hit you hit 1 less|the turn after."
            :slot fluff
            :amount 4
            :step 2
            :cost 0
            :aim self
            :tags ()
            :show NONE
            :picture hairballwall
            :weight 3
            :steps ((call SHIELD) (lit 1) (max wall)))
        (CATNAP
            :name "CATNAP"
            :text "Gain # shield.|Heal 3 if you have not re-rolled|this turn."
            :slot fluff
            :amount 4
            :step 2
            :cost 0
            :aim self
            :tags ()
            :show HEART
            :picture catnap
            :weight 3
            :steps ((call SHIELD) (calm) (lit 3) (heal)))))
