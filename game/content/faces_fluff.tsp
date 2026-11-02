; the faces for her fluff face: fluff: shields, and what the third fluff of a turn adds (content/faces.tsp says what a row is).

(import content/cards)

(macro rows ()
    '((FLUFF
            :name "FLUFF"
            :text "Shield #.|3rd fluff this turn: shield stays."
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
                (say "Third in a turn: shield stays on.")))
        (SPIKY_FLUFF
            :name "SPIKY FLUFF"
            :text "Shield #.|3rd fluff this turn: hitters take 4"
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
                (say "Third in a turn: spiky! # back.")))
        (BOX
            :name "CARDBOARD BOX"
            :text "Shield #.|3rd fluff this turn: +1 kitten,|and attacks on all miss you."
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
                (say "Third in a turn: a box, a kitten.")))
        (WARM_BLANKET
            :name "WARM BLANKET"
            :text "Shield #.|3rd fluff this turn: heal 6."
            :slot fluff
            :amount 4
            :step 2
            :cost 0
            :aim self
            :tags (three)
            :show NONE
            :picture blanket
            :weight 3
            :steps ((call SHIELD) (three) (say "Third in a turn: warm, heal 6.") (lit 6) (heal)))
        (STATIC_FUR
            :name "STATIC FUR"
            :text "Shield #.|3rd fluff this turn: 6 to all,|or 12 to an enemy that is wet."
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
                (say "Third in a turn: static!")
                (all)
                (lit 6)
                (t_has wet)
                (lit 12)
                (hit)
                (end)))
        (BELL_COLLAR
            :name "BELL COLLAR"
            :text "Shield #.|3rd fluff this turn: block 2 curses"
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
                (say "Third in a turn: a curse blocker.")))
        (MIRROR_FUR
            :name "MIRROR FUR"
            :text "Shield #.|Blocked hits bounce back: # most."
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
            :text "Shield #. You get a free re-roll."
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
            :text "Shield #."
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
            :text "Shield #.|Who hits you gets fleas 2 a turn."
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
            :text "Doubles your shield, then +#."
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
                (say_me " \x0chas shield #.")))
        (HAIRBALL_WALL
            :name "HAIRBALL WALL"
            :text "Shield #.|Who hits you hits 1 less next turn."
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
            :text "Shield #.|No re-roll this turn: you heal 3."
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
