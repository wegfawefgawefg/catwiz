; the rules page's text (battle/rules): thirteen pages, each a title and up to fifteen lines of 35
; columns, on the second disk (:on disk2; read with lib/disk while the page is open), since aux
; memory is full. Every rule here is the engine's as it is (content/effects, statuses, charms,
; battle/turn, reward, offer): change them together. page lays a page out: the title in inverse, every line
; padded to 35 with spaces, PAGE_BYTES in all.

(const PAGE_LINES u8 15)
(const PAGE_BYTES u16 560) ; the title and PAGE_LINES lines, 35 bytes each
(const PAGE_COUNT u8 13)

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
    `(const ,name (array u8 560) (make (array u8 560) ,@bytes) :on disk2 :in aux))

(page RULES_GOAL "HOW TO PLAY"
    "You are Catwiz, a cat witch. Beat"
    "every enemy in a fight to win it."
    "Win all ten fights to win the run."
    "If Catwiz runs out of hit points"
    "(hp), the run is over."
    ""
    "Each turn Catwiz rolls five dice."
    "Every die shows a picture, and the"
    "picture says what the die does:"
    "hit an enemy, shield Catwiz, make"
    "mana, cast a spell, and more."
    ""
    "Pick a die to read what it does"
    "at the bottom of the screen.")

(page RULES_PLAY "PLAYING A DIE"
    "Pick a die with its number key, or"
    "tap it. Then choose who it is for."
    ""
    "A die that hits one enemy: pick"
    "that enemy with Z, X or C."
    ""
    "A die for Catwiz herself, or one"
    "that hits every enemy: press the"
    "same die again."
    ""
    "ESC puts a picked die back down."
    ""
    "Each die can be played once a"
    "turn.")

(page RULES_TURN "RE-ROLLS AND THE TURN"
    "Don't like your dice? Press R to"
    "re-roll. Every die you haven't"
    "played yet is thrown again. You"
    "get two re-rolls a turn. Cards can"
    "give more, up to 9."
    ""
    "The turn ends when every die is"
    "played, or when you press E."
    ""
    "Then the enemies act. The badge"
    "over each enemy shows what it will"
    "do next: a sword and a number is"
    "an attack, a shield blocks damage."
    ""
    "Plan your dice around their moves.")

(page RULES_KINDS "THE SIX FACES"
    "Every die has the same six faces:"
    ""
    "WAND: hits an enemy."
    "FLUFF: shields Catwiz."
    "STAR: makes mana."
    "BOOK: a spell that costs mana."
    "CURSE: puts a status on an enemy."
    "TRICK: boosts the next die."
    ""
    "Catwiz has one item for each face:"
    "her wand, her fluff, her star and"
    "so on. The item decides what that"
    "face does. Two different wands hit"
    "in different ways.")

(page RULES_ITEMS "ITEMS AND LEVELS"
    "The number on a face is how strong"
    "it is: its damage, shield or mana."
    ""
    "After each fight you pick a reward:"
    "a new item for one of the faces (it"
    "replaces the old one) or a level."
    "A level adds 1 or 2 to a face's"
    "number; its card shows the new one."
    "Each face can have two levels, and"
    "they stay when its item changes."
    "Press B to see Catwiz's kit: her"
    "items, their levels and her charms.")

(page RULES_MANA "MANA AND BOOKS"
    "Star faces give mana. Mana stays"
    "for the whole fight, up to 5. The"
    "stars next to the dice show it."
    ""
    "Book faces are spells. A book costs"
    "mana to play; its card says how"
    "much. Without enough mana you"
    "can't play it: re-roll it, or play"
    "a star first."
    ""
    "Mana goes back to 0 each fight.")

(page RULES_TRICKS "TRICKS AND BOOSTS"
    "A trick face makes the next die"
    "you play stronger: a boost."
    ""
    "PLUS ONE: the next die gets +2. If"
    "it hits more than once, every hit"
    "gets +2."
    "TIMES TWO: the next die's number"
    "is doubled."
    ""
    "Boosts add up: two Times Twos make"
    "x4. A boost waits for the next die"
    "you play, but it is lost when the"
    "turn ends."
    ""
    "A trick can't boost another trick.")

(page RULES_THREES "THREE OF A KIND"
    "Play three faces of the same kind"
    "in one turn, like three wands, and"
    "the third one does something"
    "extra. Each item's card says what."
    ""
    "For example, with the twig wand,"
    "the third wand hits every enemy."
    ""
    "A die at x2 counts as two of its"
    "kind, and a die at x3 as three."
    ""
    "Tricks never count, and some items"
    "have no three."
    ""
    "The count starts over each turn.")

(page RULES_STATUS1 "STATUSES (1 OF 3)"
    "Statuses are effects on a fighter."
    "The badge under each fighter shows"
    "its hp and its statuses."
    ""
    "FLEAS N: the fighter takes N at the"
    "end of each of its turns, 3 turns."
    "WET N: its attacks do half damage,"
    "for N turns. More wet adds turns."
    "TANGLED N: its attacks do N less"
    "until its turn ends."
    "MARKED N: every hit on it does N"
    "more. Kittens attack it first."
    "SPOOKED N: Catwiz's dice are N"
    "lower until her turn ends.")

(page RULES_STATUS2 "STATUSES (2 OF 3)"
    "SHIELD N: blocks N damage. It is"
    "gone at its owner's next turn."
    "WARD: each pip blocks one curse."
    "KITTENS N: Catwiz's kittens. Each"
    "one pounces on an enemy for 2 at"
    "the end of her turn. One runs away"
    "each time she gets hurt."
    "STRENGTH N: its attacks do N more"
    "for the rest of the fight."
    "CHEERED N: its next attack does N"
    "more."
    ""
    "No number goes above 255.")

(page RULES_STATUS3 "STATUSES (3 OF 3)"
    "RED DOT N: when a wand hits it, all"
    "your dice come back, even played"
    "ones, and roll again. It uses one"
    "dot. Dice come back 5 times a turn"
    "at most."
    "CATFIGHT N: its next attack hits"
    "one of its friends instead, N more."
    "MIRROR N: damage Catwiz's shield"
    "blocks goes back to the attacker,"
    "N at most, until her next turn."
    "IN A BOX: attacks on everyone miss"
    "Catwiz until her next turn."
    "HABIT N: Scratching Habit hits N"
    "harder for the rest of the fight."
    "SPIKY N: who hits Catwiz takes N.")

(page RULES_REWARDS "REWARDS AND CHARMS"
    "After each fight, pick one of five"
    "cards: a new face or a level."
    "Tap a card or press its number."
    "S or SKIP takes nothing."
    ""
    "After an elite (a harder fight at"
    "the end of each place) you also get"
    "a charm, then a rest: Catwiz heals"
    "to full and picks a face for +1."
    ""
    "A charm helps for the whole run."
    "Tap her faces, or BAG (B), to read"
    "them while you pick."
    "Catwiz's hp carries over from one"
    "fight to the next.")

(page RULES_RUN "THE RUN"
    "A run is ten fights in three"
    "places: the woods, the garden and"
    "the house. Each place ends with an"
    "elite. The last fight is the"
    "Bulldog King."
    ""
    "Before the house's elite, pick a"
    "door: the vet or the big bath."
    ""
    "The map at the top of the screen"
    "shows where you are in the run."
    ""
    "Lost track? Press H, or tap the"
    "log, to read what just happened.")

; page n's place on the disk, for lib/disk
(fn page_table ((n u8)) (ptr u8)
    (match n
        (0 (addr_of (at RULES_GOAL 0)))
        (1 (addr_of (at RULES_PLAY 0)))
        (2 (addr_of (at RULES_TURN 0)))
        (3 (addr_of (at RULES_KINDS 0)))
        (4 (addr_of (at RULES_ITEMS 0)))
        (5 (addr_of (at RULES_MANA 0)))
        (6 (addr_of (at RULES_TRICKS 0)))
        (7 (addr_of (at RULES_THREES 0)))
        (8 (addr_of (at RULES_STATUS1 0)))
        (9 (addr_of (at RULES_STATUS2 0)))
        (10 (addr_of (at RULES_STATUS3 0)))
        (11 (addr_of (at RULES_REWARDS 0)))
        (_ (addr_of (at RULES_RUN 0)))))
