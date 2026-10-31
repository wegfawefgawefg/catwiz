; what the hero's faces (content/effects) say in the log: its sentences, in aux memory (battle/log
; reads them there), by name

(const SAY (array (ptr u8) 29)
    (make (array (ptr u8) 29)
        "Too little mana: she studies. +1"
        "The next 2 dice get +#."
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
        ": ward broken, no curse."
        " gets fleas: # a turn."
        " is wet: half hits, # turns."
        " is spooked: dice -#."
        " is marked: hits +#."
        " is tangled: hits -#.")
    :strings aux)

(const SAY_TOO_LITTLE_MANA u8 0)
(const SAY_NEXT_2_DICE u8 1)
(const SAY_TIMES_NEXT u8 2)
(const SAY_NOTHING_COPY_YET u8 3)
(const SAY_COPYCAT u8 4)
(const SAY_CATNIP_NEXT_DICE u8 5)
(const SAY_KNEAD_NEXT_FLUFF u8 6)
(const SAY_SHIELDS u8 7)
(const SAY_MANA_NOW u8 8)
(const SAY_SHIELDS_1_MANA u8 9)
(const SAY_WISH_NEXT_WAND u8 10)
(const SAY_KITTENS_JOIN_YOU u8 11)
(const SAY_TAKES_FROM_SCREAMING u8 12)
(const SAY_HAIRBALL_NOTHING_HAPPENS u8 13)
(const SAY_DROPS_ITS_SHIELD u8 14)
(const SAY_THREE_HITS_ALL u8 15)
(const SAY_THREE_SHIELD_STAYS u8 16)
(const SAY_THREE_SPIKY u8 17)
(const SAY_THREE_BOX u8 18)
(const SAY_THREE_WARM u8 19)
(const SAY_THREE_STATIC u8 20)
(const SAY_THREE_WARD u8 21)
(const SAY_KITTENS_POUNCE u8 22)
(const SAY_WARD_BROKEN_NO u8 23)
(const SAY_GETS_FLEAS_TURN u8 24)
(const SAY_WET_HALF_HITS u8 25)
(const SAY_SPOOKED_DICE u8 26)
(const SAY_MARKED_HITS u8 27)
(const SAY_TANGLED_HITS u8 28)
