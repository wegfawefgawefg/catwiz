; the rules page's text (battle/rules): eleven pages, each a title and up to fifteen lines of 35
; columns, on the disk (:on disk; read with lib/disk while the page is open), since aux memory is
; full. Every rule here is the engine's as it is (content/effects, statuses, charms, battle/turn,
; reward, offer): change them together. page lays a page out: the title in inverse, every line
; padded to 35 with spaces, PAGE_BYTES in all.

(const PAGE_LINES u8 15)
(const PAGE_BYTES u16 560) ; the title and PAGE_LINES lines, 35 bytes each
(const PAGE_COUNT u8 11)

; line s as 35 bytes, each with flag added (128: inverse)
(macro line_bytes (s flag)
    (let codes (chars s))
    (if (> (len codes) 35)
        (error "a rules line is over 35 columns: " s))
    (let out (list))
    (for i 0 35
        (set out
            (append out
                (list (if (< i (len codes))
                    (+ (nth codes i) flag)
                    32)))))
    out)

(macro page (name title & lines)
    (if (> (len lines) 15)
        (error "rules page " title " has over 15 lines"))
    (let bytes (line_bytes title 128))
    (for i 0 15
        (set bytes
            (append bytes
                (line_bytes
                    (if (< i (len lines))
                        (nth lines i)
                        "")
                    0))))
    `(const ,name (array u8 560) (make (array u8 560) ,@bytes) :on disk))

(page RULES_TURN "A TURN"
    "Catwiz has five dice. Each die"
    "has six faces, one for each slot:"
    "wand, fluff, star, book, curse and"
    "trick."
    ""
    "Pick a die, then pick an enemy."
    "Dice for Catwiz or for all enemies"
    "play when you pick them twice."
    "Keys: 1-6 dice, Z X C enemies."
    ""
    "You get two re-rolls a turn (R)."
    "A re-roll throws all unplayed dice."
    "The turn ends when all dice are"
    "played or you press E. Then the"
    "enemies take their turn.")

(page RULES_SLOTS "SLOTS, ITEMS, LEVELS"
    "Each slot holds one item. The item"
    "decides what its face does: wands"
    "hit, fluffs shield, stars make"
    "mana, books cast spells, curses go"
    "on enemies, and tricks boost the"
    "next dice."
    ""
    "A face's number is its item's"
    "number, +1 per level of its slot."
    "A slot can have up to two levels."
    ""
    "Levels stay with the slot. A new"
    "item in that slot keeps them."
    "Her kit (B) shows her slots, their"
    "levels and what each one does.")

(page RULES_THREES "THREES"
    "Play three faces of the same slot"
    "in one turn and the third one sets"
    "off the item's three. For example,"
    "a third twig wand hits every"
    "enemy. Each item's card says what"
    "its three does."
    ""
    "Times Two counts as its number: a"
    "wand at x2 counts as two wands."
    ""
    "Tricks never count, and some items"
    "have no three."
    ""
    "The count starts over each turn.")

(page RULES_TRICKS "TRICKS AND BOOSTS"
    "Tricks boost the next dice. A trick"
    "can't be boosted itself."
    ""
    "PLUS ONE: the next die gets +2 on"
    "every hit. Pluses add up: +2 and +2"
    "make +4."
    ""
    "TIMES TWO: the next die is doubled,"
    "any slot but a trick. It doubles a"
    "waiting plus too. Times add up: x2"
    "then x2 is x4."
    ""
    "Boosts last until her turn ends."
    "Catnip, Knead and wishes boost too."
    "Spooked takes from every die.")

(page RULES_MANA "MANA AND BOOKS"
    "Stars make mana. Catwiz keeps her"
    "mana all fight, five at most. The"
    "stars next to the dice show it."
    ""
    "Books are spells. Playing a book"
    "costs its mana, then the spell"
    "happens."
    ""
    "Without enough mana a book can't be"
    "played. Re-roll it or get mana."
    ""
    "Some stars do more: a hit, a"
    "shield or a wish."
    ""
    "Each fight starts with no mana.")

(page RULES_STATUS1 "STATUSES (1 OF 2)"
    "The badge under each fighter shows"
    "its hit points and statuses."
    ""
    "FLEAS N: N damage at the end of"
    "each of its turns, for 3 turns."
    "More fleas add up and restart the"
    "3 turns."
    "WET N: its hits do half damage for"
    "N turns. More wet adds turns."
    "TANGLED N: its hits do N less until"
    "its turn ends."
    "MARKED N: hits on it do N more, all"
    "fight. Kittens attack it first."
    "SPOOKED N: her dice are N lower"
    "until her turn ends.")

(page RULES_STATUS2 "STATUSES (2 OF 2)"
    "WARD: each pip blocks one curse."
    "The pip breaks and the curse fails."
    "SHIELD N: blocks N damage. It is"
    "gone at its owner's next turn."
    "KITTENS N: each one pounces for 1"
    "at the end of her turn. One runs"
    "off each time she gets hurt."
    "STRENGTH N: its hits do N more, all"
    "fight."
    "CHEERED N: its next hit is N more."
    "Numbers stop at 255."
    ""
    "The badge over each enemy shows its"
    "next move: a sword and its damage"
    "for a hit, a shield, or a cheer.")

(page RULES_CHARMS "CHARMS"
    "A charm works for the whole run."
    ""
    "After each elite, pick one of three"
    "random charms she doesn't have yet."
    ""
    "Her kit (B) shows her charms. Pick"
    "one there to read it."
    ""
    "Each charm's card has a mark so you"
    "can tell them apart: + for Scratch"
    "Post's re-rolls, 6 for Sixth Toe's"
    "sixth die, and so on.")

(page RULES_REWARDS "REWARDS"
    "After each fight, pick one of three"
    "random cards: an item for a slot"
    "(it replaces the old one, the"
    "levels stay) or +1 level on a slot."
    "Taking an item she already has"
    "gives its slot +1. A slot at two"
    "levels can't go higher."
    ""
    "After an elite: a card, then a"
    "charm, then a nap (heal) or a bonus"
    "(+1 level on any slot)."
    ""
    "Hit points carry over between"
    "fights.")

(page RULES_RUN "THE RUN"
    "A run is ten fights: three in the"
    "woods, three in the garden, three"
    "in the yard, each place ending with"
    "an elite. Then the Bulldog King."
    ""
    "Before the yard's elite, pick a"
    "door: the vet or the big bath."
    ""
    "The map at the top shows the place,"
    "its three fights (an elite has a"
    "bigger mark) and the king's crown."
    ""
    "If Catwiz runs out of hit points,"
    "the run is over.")

(page RULES_CHAINS "DICE BACK, NEW STATUSES"
    "RED DOT N: a wand hit on it brings"
    "all your dice back to roll again,"
    "used or not. Each one uses a dot."
    "Dice come back 5 times a turn at"
    "most. A waiting plus or x stays."
    "You can hold 9 re-rolls at most."
    "CATFIGHT N: its next hit lands on a"
    "friend, N harder. With no friend,"
    "it waits."
    "MIRROR N: hits her shield blocks"
    "this round bounce back, N at most."
    "FLEA CIRCUS: its fleas jump x2 to"
    "the next enemy when it dies."
    "NINE LIVES: the first time she"
    "falls, she comes back.")

; page n's place on the disk, for lib/disk
(fn page_table ((n u8)) (ptr u8)
    (match n
        (0 (addr_of (at RULES_TURN 0)))
        (1 (addr_of (at RULES_SLOTS 0)))
        (2 (addr_of (at RULES_THREES 0)))
        (3 (addr_of (at RULES_TRICKS 0)))
        (4 (addr_of (at RULES_MANA 0)))
        (5 (addr_of (at RULES_STATUS1 0)))
        (6 (addr_of (at RULES_STATUS2 0)))
        (7 (addr_of (at RULES_CHARMS 0)))
        (8 (addr_of (at RULES_REWARDS 0)))
        (9 (addr_of (at RULES_RUN 0)))
        (_ (addr_of (at RULES_CHAINS 0)))))
