; the faces for her trick face: tricks: a rule for the next dice (content/faces.tsp says what a row is).

(import content/cards)

(macro rows ()
    '((PLUS
            :name "PLUS ONE"
            :text "Your next die's number is +#."
            :slot trick
            :amount 2
            :step 2
            :cost 0
            :aim self
            :tags (plus)
            :show NONE
            :picture plus1
            :weight 0
            :steps ((cue chime) (add plus) (lit 1) (set plus_left) (get plus) (say NEXT_DIE)))
        (TIMES
            :name "TIMES TWO"
            :text "Your next die's number is x#."
            :slot trick
            :amount 2
            :step 1
            :cost 0
            :aim self
            :tags (times)
            :show NONE
            :picture times2
            :weight 1
            :steps ((cue chime) (times plus)
                (lit 1)
                (max mult)
                (num)
                (times mult)
                (get mult)
                (say "Times: the next die x#.")))
        (COPYCAT
            :name "COPYCAT"
            :text "Plays your last die again, # more."
            :slot trick
            :amount 0
            :step 2
            :cost 0
            :aim self
            :tags (plus)
            :show NONE
            :picture copycat
            :weight 1
            :steps ((cue chime) (copy)))
        (CATNIP
            :name "CATNIP"
            :text "Next # dice +1.|Kittens pounce twice this turn."
            :slot trick
            :amount 4
            :step 1
            :cost 0
            :aim self
            :tags ()
            :show NONE
            :picture catnip
            :weight 3
            :steps ((cue chime) (add nip)
                (lit 1)
                (set nipped)
                (num)
                (say "Catnip! The next # dice +1.")))
        (KNEAD
            :name "KNEAD"
            :text "Next fluff x2, and next wand +#."
            :slot trick
            :amount 4
            :step 2
            :cost 0
            :aim self
            :tags (plus)
            :show NONE
            :picture knead
            :weight 2
            :steps ((cue chime) (lit 1)
                (set knead_fluff)
                (num)
                (add knead_wand)
                (say "Knead: next fluff x2, wand +#.")))
        (DOUBLE_OR_NOTHING
            :name "DOUBLE OR NOTHING"
            :text "Next die's number x#.|If no die uses it: you lose # hp."
            :slot trick
            :amount 2
            :step 1
            :cost 0
            :aim self
            :tags (times)
            :show COIN
            :picture double
            :weight 1
            :steps ((cue coin) (lit 1)
                (max mult)
                (num)
                (times mult)
                (num)
                (add gamble)
                (get mult)
                (say "Your next die is x#. Use it or pay!")))))
