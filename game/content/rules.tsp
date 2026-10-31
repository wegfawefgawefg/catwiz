; the rules page's text (battle/rules): ten pages, each a title and up to fifteen lines of 35
; columns, on the disk (:on disk; read with lib/disk while the page is open), since aux memory is
; full. Every rule here is the engine's as it is (content/effects, statuses, charms, battle/turn,
; reward, offer): change them together. page lays a page out: the title in inverse, every line
; padded to 35 with spaces, PAGE_BYTES in all.

(const PAGE_LINES u8 15)
(const PAGE_BYTES u16 560) ; the title and PAGE_LINES lines, 35 bytes each
(const PAGE_COUNT u8 10)

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
    "Catwiz rolls five dice each turn."
    "A die's six faces are her six"
    "slots: wand, fluff, star, book,"
    "curse and trick."
    ""
    "Pick a die, then an enemy, to play"
    "it. A die for her or for every"
    "enemy plays when picked again."
    "Keys: 1-6 dice, Z X C enemies."
    ""
    "Two re-rolls a turn (R) throw every"
    "die not played yet again."
    ""
    "The turn ends when all dice are"
    "played or with E; then enemies act.")

(page RULES_SLOTS "SLOTS, ITEMS, LEVELS"
    "The item in a slot is what its face"
    "does: a wand hits, a fluff shields,"
    "a star makes mana, a book casts a"
    "spell, a curse goes on an enemy, a"
    "trick sets up the next dice."
    ""
    "A face's number is its item's, and"
    "1 more for each level on its slot."
    "A slot has two levels at most."
    ""
    "Levels belong to the slot: a new"
    "item there keeps them."
    ""
    "Her kit (B) shows her slots, their"
    "levels and what each one is doing.")

(page RULES_THREES "THREES"
    "Play three faces of one slot in a"
    "turn, and the third sets off its"
    "item's three: the twig wand's third"
    "hits every enemy, the fluff's keeps"
    "her shield a turn, and so on. An"
    "item's card says its three."
    ""
    "Times Two counts its number towards"
    "a three: a wand at x2 counts as two"
    "wands."
    ""
    "Tricks never count towards one, and"
    "not every item has a three."
    ""
    "A new turn starts the count again.")

(page RULES_TRICKS "TRICKS AND BOOSTS"
    "A trick sets up the next dice. It"
    "takes no boosts itself."
    ""
    "PLUS ONE: the next two dice +1."
    "Pluses add up: +1, then +1 again,"
    "gives the next two dice +2."
    ""
    "TIMES TWO: the next die x2, of any"
    "slot but a trick. After a plus it"
    "doubles the plus too. Times add up:"
    "x2 then x2 is x4."
    ""
    "Catnip, Knead and a wish boost the"
    "next dice too. A spook on her takes"
    "from every die till her turn ends.")

(page RULES_MANA "MANA AND BOOKS"
    "Stars make mana. Mana stays all"
    "fight, five at most: the stars by"
    "the tray show it."
    ""
    "A book is a spell. Playing it pays"
    "its mana, then the spell works."
    ""
    "With too little mana a book can't"
    "be played: re-roll it or get mana."
    ""
    "Some stars do more: a hit, a"
    "shield, a wish."
    ""
    "A new fight starts with no mana.")

(page RULES_STATUS1 "STATUSES (1 OF 2)"
    "The badge under each fighter shows"
    "its hit points and its statuses."
    ""
    "FLEAS N: N damage at the end of"
    "each of its turns, for 3 turns."
    "More fleas add up, and the 3 turns"
    "start again."
    "WET N: its hits are halved, for N"
    "of its turns."
    "TANGLED N: its hits are N less,"
    "till its turn ends."
    "MARKED N: hits on it are N more,"
    "all fight. Kittens go for it first."
    "SPOOKED N: her dice are N less,"
    "till her turn ends.")

(page RULES_STATUS2 "STATUSES (2 OF 2)"
    "WARD: each pip takes a curse, which"
    "breaks the pip and does nothing."
    "SHIELD N: takes N of the hits. It"
    "is gone at its holder's next turn."
    "KITTENS N: each pounces for 1 at"
    "the end of her turn. One runs off"
    "each time she is hurt. 5 at most."
    "STRENGTH N: its hits are N more,"
    "all fight."
    "CHEERED N: its next hit is N more."
    ""
    "Over each enemy, a badge shows what"
    "it will do next: a sword and how"
    "much for a hit, a shield, a cheer.")

(page RULES_CHARMS "CHARMS"
    "A charm works all run."
    ""
    "After each elite, she picks one of"
    "three charms drawn at random from"
    "the ones she does not have yet."
    ""
    "Her kit (B) shows her charms; pick"
    "one there to read it."
    ""
    "Each charm's card has a mark, so"
    "they tell apart: + for the Scratch"
    "Post's re-roll, 6 for the Sixth"
    "Toe's sixth die, and so on.")

(page RULES_REWARDS "REWARDS"
    "After each fight, she picks one of"
    "three cards drawn at random:"
    "an item for a slot (the old one"
    "goes, the levels stay), or +1 on a"
    "slot. Taking an item she has is +1"
    "on its slot. A slot at two levels"
    "gets no more."
    ""
    "After an elite: a card, then a"
    "charm, then a nap (hit points"
    "back) or a bonus upgrade (+1 on a"
    "slot of her choice)."
    ""
    "Her hit points carry over from"
    "fight to fight.")

(page RULES_RUN "THE RUN"
    "Ten fights: three in the woods,"
    "three in the garden, three in the"
    "yard, each place ending with an"
    "elite; then the Bulldog King."
    ""
    "Before the yard's elite, two doors:"
    "the vet or the big bath."
    ""
    "The map at the top of the stage"
    "shows the place, its three fights"
    "(an elite's mark is bigger, this"
    "one's lit) and the king's crown."
    ""
    "Lose all her hit points and the run"
    "is over.")

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
        (_ (addr_of (at RULES_RUN 0)))))
