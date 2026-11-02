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
                (max knead_fluff)
                (lit 2)
                (times knead_fluff)
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
                (say "Your next die is x#. Use it or pay!")))
        ; the faces round (docs/faces.md)
        (STONE_CAT
            :name "STONE CAT"
            :text "Your next fluff is x#."
            :slot trick
            :amount 3
            :step 1
            :cost 0
            :aim self
            :tags (times)
            :show NONE
            :picture stonecat
            :weight 3
            :steps ((cue chime) (lit 1)
                (max knead_fluff)
                (num)
                (times knead_fluff)
                (get knead_fluff)
                (say "Stone cat: the next fluff x#.")))
        (HISS
            :name "HISS"
            :text "Costs 2 hp: your next die is x#."
            :slot trick
            :amount 2
            :step 1
            :cost 2
            :aim self
            :tags (times hp)
            :show NONE
            :picture hiss
            :weight 3
            :steps ((cue hiss) (lit 2)
                (me)
                (hurt)
                (say_me " \x0bpays # hp.")
                (lit 1)
                (max mult)
                (num)
                (times mult)
                (get mult)
                (say "Hiss! The next die x#.")))
        (LAST_STAND
            :name "LAST STAND"
            :text "Under 4 hp: your next die is x#."
            :slot trick
            :amount 3
            :step 1
            :cost 0
            :aim self
            :tags (times)
            :show NONE
            :picture laststand
            :weight 3
            :steps ((cue chime) (low 4)
                (lit 1)
                (max mult)
                (num)
                (times mult)
                (get mult)
                (say "Last stand: the next die x#.")))
        (SPELL_ECHO
            :name "SPELL ECHO"
            :text "Your next book is cast twice."
            :slot trick
            :amount 0
            :step 0
            :cost 0
            :aim self
            :tags (none)
            :show MANA_SWIRL
            :picture spellecho
            :weight 1
            :steps ((cue sparkle) (lit 1) (set echo) (say "Your next book goes twice.")))
        (PAW_FLIP
            :name "PAW FLIP"
            :text "Turns a die to the face you pick:|pick it, then again to turn it."
            :slot trick
            :amount 0
            :step 0
            :cost 0
            :aim self
            :tags (none)
            :show DIE_FLIP
            :picture pawflip
            :weight 1
            :steps ((cue rattle) (lit 1) (set flip) (say "Pick a die, again to turn it.")))
        (SHARPEN_CLAWS
            :name "SHARPEN CLAWS"
            :text "Every wand +# for the rest of the|fight."
            :slot trick
            :amount 1
            :step 1
            :cost 0
            :aim self
            :tags (plus)
            :show CLAWS
            :picture sharpenclaws
            :weight 3
            :steps ((cue scratch) (num)
                (add sharp)
                (get sharp)
                (say "Sharp claws: wands +# this fight.")))
        (ALL_IN
            :name "ALL IN"
            :text "Every die left this turn is x#,|but no more re-rolls."
            :slot trick
            :amount 2
            :step 1
            :cost 0
            :aim self
            :tags (times)
            :show COIN
            :picture allin
            :weight 1
            :steps ((cue coin) (lit 1)
                (max allin)
                (num)
                (times allin)
                (no_rerolls)
                (get allin)
                (say "All in: every die x# this turn!")))
        (HAT_TRICK
            :name "HAT TRICK"
            :text "Plays a face drawn from all the|faces there are, at your levels."
            :slot trick
            :amount 0
            :step 0
            :cost 0
            :aim self
            :tags (none)
            :show SPIRAL
            :picture hattrick
            :weight 1
            :steps ((cue sparkle) (hat)))))
