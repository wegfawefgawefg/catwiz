; what the hero's faces say in the log, the lines more than one card or the engine says: in aux
; memory (battle/log reads them there), by name; the table too (line reads it). A line only one
; face or charm says is in its own row, a string in its say (content/faces.tsp), and costs no
; memory

(const SAY (array (ptr u8) 20)
    (make (array (ptr u8) 20)
        "Your next die gets +#."
        "Nothing to copy yet."
        "Copycat!"
        " \x0cgets # shield."
        "\x0eMana is now #."
        "Kittens join! You have \x0d# now."
        "Your kittens pounce!"
        "'s ward blocks the curse."
        " \x09has # fleas now."
        " \x09is wet and hits for half."
        " \x09is spooked. Dice get -#."
        " \x09hits # less next turn."
        " \x0bloses the bet and # hp."
        "There is nothing to mimic."
        " \x09is spiky. Attackers take #."
        " \x0dtakes # bounced back."
        " \x09will hit # less next turn."
        " comes out of the hat!"
        " will not sleep."
        "Again!")
    :in aux)

; sentence k's place (in aux memory, as text.add_aux takes it)
(fn line ((k u8)) (ptr u8)
    (with_aux true false
        (at SAY k)))

(const SAY_NEXT_DIE u8 0)
(const SAY_NOTHING_COPY_YET u8 1)
(const SAY_COPYCAT u8 2)
(const SAY_SHIELDS u8 3)
(const SAY_MANA_NOW u8 4)
(const SAY_KITTENS_JOIN_YOU u8 5)
(const SAY_KITTENS_POUNCE u8 6)
(const SAY_WARD_BROKEN_NO u8 7)
(const SAY_GETS_FLEAS_TURN u8 8)
(const SAY_WET_HALF_HITS u8 9)
(const SAY_SPOOKED_DICE u8 10)
(const SAY_TANGLED_HITS u8 11)
(const SAY_BET_LOST u8 12)
(const SAY_NO_MIMIC u8 13)
(const SAY_SPIKY u8 14)
(const SAY_BOUNCED u8 15)
(const SAY_TANGLED_NEXT u8 16)
(const SAY_OUT_OF_HAT u8 17)
(const SAY_WONT_SLEEP u8 18)
(const SAY_ECHO u8 19)
