; a card's lines on the four text rows between fights (battle/reward): its name, the slot's base,
; the item's line in its parts, and how her levels make its number. Each step writes its rows over
; the last ones (only what changed is drawn again, draw/text), and the rows it leaves out are
; blanked (rest).

(import state)
(import draw/text)
(import battle/kit)
(import content/effects fx)
(import content/items)

; a slot's base, the card's second line (# its number), and its name
(const BASE (array (ptr u8) 6)
    (make (array (ptr u8) 6)
        "Wand: # damage" "Fluff: shield #" "Star: makes mana" "Book: a spell for mana"
        "Curse: goes on an enemy" "Trick: helps the next dice")
    :strings aux)

(const SLOT_NAME (array (ptr u8) 6)
    (make (array (ptr u8) 6) "WAND" "FLUFF" "STAR" "BOOK" "CURSE" "TRICK")
    :strings aux)

(const SAY (array (ptr u8) 6)
    (make (array (ptr u8) 6)
        "+1 " "Tap again to take" " (+#)" "Your levels add +# to this face." " (#,"
        " +# from your levels)")
    :strings aux)

(const SAY_PLUS1 u8 0)
(const SAY_AGAIN u8 1)
(const SAY_UP u8 2)
(const SAY_LEVELS_STAY u8 3)
(const SAY_NOTE_A u8 4)
(const SAY_NOTE_P u8 5)

(let written u8 0) ; a bit for each row written since the step's text started

(fn show ((r u8)) void
    (text.show r)
    (set written (| written (<< 1 r))))

(fn rest () void
    (for r u8 0 text.ROWS
        (if (= (& written (<< 1 r)) 0)
            (do
                (text.start)
                (text.show r))))
    (set written 0))

; s is an aux string (a SAY's, a content string)
(fn row ((r u8) (s (ptr u8)) (n u8)) void
    (text.start)
    (text.add_aux_n s n)
    (show r))

; an item's line on row r, its number inverse (text.add_item)
(fn item_row ((r u8) (s (ptr u8)) (n u8)) void
    (text.start)
    (text.add_item s n)
    (show r))

; row 0: the name (aux memory), inverse, after +1 for an upgrade, and how to take it
(fn title ((name (ptr u8)) (up bool)) void
    (text.start)
    (set text.inverse true)
    (if up
        (text.add_aux (at SAY SAY_PLUS1)))
    (text.add_aux name)
    (set text.inverse false)
    (text.tab 18)
    (text.add_aux (at SAY SAY_AGAIN))
    (show 0))

; row 1: slot's base with item row at level, and the level
(fn base_row ((slot u8) (item u8) (level u8)) void
    (text.start)
    (text.add_item (at BASE slot) (fx.number_at item level))
    (if (> level 0)
        (text.add_aux_n (at SAY SAY_UP) level))
    (show 1))

; ---- her levels in a new face's number (docs/faces.md: the levels stay with the face, whatever
; item is on it): "Hits 10 (6, +4 from your levels)." on its first part when that fits a row

(const NOTE_COLUMNS u8 23) ; " (", ", +", " from your levels)"

(fn digits_of ((n u8)) u8
    (if (>= n 100)
        (return 3))
    (if (>= n 10)
        (return 2))
    1)

; part s (aux memory) on row r with its # as n (inverse), then the note after it: amount a, +p
; from her levels; false (nothing shown) when that does not fit a row
(fn noted_row ((r u8) (s (ptr u8)) (n u8) (a u8) (p u8)) bool
    (text.start)
    (text.add_item s n)
    (let end u8 text.number_end)
    (let tail u8 (- text.col end))
    (if (> (+ text.col (+ NOTE_COLUMNS (+ (digits_of a) (digits_of p)))) text.COLUMNS)
        (return false))
    ; what follows the number, kept (the kit's picture scratch, free while text is made)
    (let buf (ptr u8) (addr_of (at kit.picture 0)))
    (for i u8 0 tail
        (store (+ buf i) (at text.line (+ end i))))
    (set text.col end)
    (text.add_aux_n (at SAY SAY_NOTE_A) a)
    (text.add_aux_n (at SAY SAY_NOTE_P) p)
    (for i u8 0 tail
        (text.char (load (+ buf i))))
    (show r)
    true)

; item's line at level from row 1: a line in parts (text.next_part) a row each, in place of the
; slot's base (its first part says what the item always does); else the slot's base and the line.
; A new face (fresh) on a slot with levels shows them in its number, the base left out (the note
; says the rest), or on the row after its line. Gives the next row free, 4 for none
(fn item_lines ((slot u8) (item u8) (level u8) (fresh bool)) u8
    (let n u8 (fx.number_at item level))
    (let s (ptr u8) (items.text item))
    (let part (ptr u8) (text.next_part s))
    (let up u8 (- n (items.amount item)))
    (let note bool (and fresh (> up 0)))
    (let r u8 1)
    (if (and (= (as u16 part) 0) (not note))
        (do
            (base_row slot item level)
            (set r 2)))
    (if (and note (noted_row r s n (items.amount item) up))
        (set note false)
        (item_row r s n))
    (set r (+ r 1))
    (while (and (!= (as u16 part) 0) (< r text.ROWS))
        (item_row r part n)
        (set r (+ r 1))
        (set part (text.next_part part)))
    (if (and note (< r text.ROWS))
        (do
            (row r (at SAY SAY_LEVELS_STAY) up)
            (set r (+ r 1))))
    r)
