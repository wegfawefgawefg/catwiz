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
            :weight 4
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
            :weight 2
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
            :weight 2
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
            :weight 2
            :steps ((cue lucky) (add shield)
                (say_me SHIELDS)
                (lit 1)
                (rerolls)
                (say "You get a free re-roll.")))))
