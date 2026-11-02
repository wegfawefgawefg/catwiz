; what the hero's faces (content/effects) say in the log: its sentences, in aux memory (battle/log
; reads them there), by name

(const SAY (array (ptr u8) 40)
    (make (array (ptr u8) 40)
        "The next die gets +#."
        "Times: the next die x#."
        "Nothing to copy yet."
        "Copycat!"
        "Catnip! The next # dice +1."
        "Knead: next fluff x2, wand +#."
        " shields #."
        "Mana is now #."
        " shields #, +1 mana."
        "A wish: the next wand x2."
        "Kittens join you: # now."
        " takes # from screaming."
        "A hairball. Nothing happens."
        " drops its shield and buffs."
        "3 in a turn: it hits all!"
        "3 in a turn: your shield stays."
        "3 in a turn: spiky! # back."
        "3 in a turn: a box, and a kitten."
        "3 in a turn: warm."
        "3 in a turn: static!"
        "3 in a turn: a ward pip."
        "Your kittens pounce!"
        "# kittens launched!"
        ": ward broken, no curse."
        " gets fleas: # a turn."
        " is wet: half hits, # turns."
        " is spooked: dice -#."
        " is marked: hits +#."
        " is tangled: hits -#."
        " has a red dot: # times."
        " wants a catfight: +#."
        " gets a flea circus: #."
        " catches the fleas: #."
        "You get a free re-roll."
        "Your next die is x#. Use it or pay!"
        " loses the bet: # hp."
        "There is nothing to mimic."
        " gets spiky: # back."
        " comes back with # hp!"
        " takes # bounced back.")
    :strings aux)

(const SAY_NEXT_DIE u8 0)
(const SAY_TIMES_NEXT u8 1)
(const SAY_NOTHING_COPY_YET u8 2)
(const SAY_COPYCAT u8 3)
(const SAY_CATNIP_NEXT_DICE u8 4)
(const SAY_KNEAD_NEXT_FLUFF u8 5)
(const SAY_SHIELDS u8 6)
(const SAY_MANA_NOW u8 7)
(const SAY_SHIELDS_1_MANA u8 8)
(const SAY_WISH_NEXT_WAND u8 9)
(const SAY_KITTENS_JOIN_YOU u8 10)
(const SAY_TAKES_FROM_SCREAMING u8 11)
(const SAY_HAIRBALL_NOTHING_HAPPENS u8 12)
(const SAY_DROPS_ITS_SHIELD u8 13)
(const SAY_THREE_HITS_ALL u8 14)
(const SAY_THREE_SHIELD_STAYS u8 15)
(const SAY_THREE_SPIKY u8 16)
(const SAY_THREE_BOX u8 17)
(const SAY_THREE_WARM u8 18)
(const SAY_THREE_STATIC u8 19)
(const SAY_THREE_WARD u8 20)
(const SAY_KITTENS_POUNCE u8 21)
(const SAY_KITTENS_LAUNCHED u8 22)
(const SAY_WARD_BROKEN_NO u8 23)
(const SAY_GETS_FLEAS_TURN u8 24)
(const SAY_WET_HALF_HITS u8 25)
(const SAY_SPOOKED_DICE u8 26)
(const SAY_MARKED_HITS u8 27)
(const SAY_TANGLED_HITS u8 28)
(const SAY_RED_DOT u8 29)
(const SAY_CATFIGHT u8 30)
(const SAY_FLEA_CIRCUS u8 31)
(const SAY_FLEAS_JUMP u8 32)
(const SAY_FREE_REROLL u8 33)
(const SAY_DOUBLE_NEXT u8 34)
(const SAY_BET_LOST u8 35)
(const SAY_NO_MIMIC u8 36)
(const SAY_SPIKY u8 37)
(const SAY_NINE_LIVES u8 38)
(const SAY_BOUNCED u8 39)
