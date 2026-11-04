; the faces for her trick face: tricks: a rule for the next dice (content/faces.tsp says what a row is).

(import content/cards)

(macro rows ()
    '((PLUS
            :name "PLUS ONE"
            :text "Your next die gets +#."
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
            :text "Your next die gets x#."
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
                (say "Your next die gets x#.")))
        (COPYCAT
            :name "COPYCAT"
            :text "Play your last die again, with +#."
            :slot trick
            :amount 0
            :step 2
            :cost 0
            :aim self
            :tags (plus)
            :show NONE
            :picture copycat
            :weight 3
            :steps ((cue chime) (copy)))
        (CATNIP
            :name "CATNIP"
            :text "Your next # dice get +1.|Kittens pounce twice this turn."
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
                (say "Catnip! Your next # dice get +1.")))
        (KNEAD
            :name "KNEAD"
            :text "Your next wand gets +#, and your|next fluff gets x2."
            :slot trick
            :amount 4
            :step 2
            :cost 0
            :aim self
            :tags (plus)
            :show NONE
            :picture knead
            :weight 3
            :steps ((cue chime) (lit 1)
                (max knead_fluff)
                (lit 2)
                (times knead_fluff)
                (num)
                (add knead_wand)
                (say "Kneading! Your next wand gets +#.")))
        (DOUBLE_OR_NOTHING
            :name "DOUBLE OR NOTHING"
            :text "Your next die gets x#.|If no die uses the x# this turn,|you lose # hp."
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
            :text "Your next fluff gets x#."
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
                (say "Your next fluff gets x#.")))
        (HISS
            :name "HISS"
            :text "Lose 2 hp. Your next die gets x#."
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
                (say "Hiss! Your next die gets x#.")))
        (LAST_STAND
            :name "LAST STAND"
            :text "Your next die gets x# if you have|under 4 hp."
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
                (say "Last stand! Your next die gets x#.")))
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
            :steps ((cue sparkle) (lit 1) (set echo) (say "Your next book will cast twice.")))
        (PAW_FLIP
            :name "PAW FLIP"
            :text "Pick a die, then pick it again to|turn the die one face each time."
            :slot trick
            :amount 0
            :step 0
            :cost 0
            :aim self
            :tags (none)
            :show DIE_FLIP
            :picture pawflip
            :weight 1
            :steps ((cue rattle) (lit 1) (set flip) (say "Pick a die again to turn its face.")))
        (SHARPEN_CLAWS
            :name "SHARPEN CLAWS"
            :text "Your wands hit # more this fight."
            :slot trick
            :amount 1
            :step 1
            :cost 0
            :aim self
            :tags (plus)
            :show CLAWS
            :picture sharpenclaws
            :weight 3
            :steps ((cue scratch) (num) (add sharp) (get sharp) (say "Your wands now hit # more.")))
        (ALL_IN
            :name "ALL IN"
            :text "Your other dice get x# this turn,|but you lose all your re-rolls."
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
                (say "All in! Your dice get x# this turn.")))
        (HAT_TRICK
            :name "HAT TRICK"
            :text "Play a random face from all faces|in the game, at your levels."
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
