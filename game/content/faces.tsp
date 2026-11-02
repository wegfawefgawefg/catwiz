; the hero's faces, a row each: what an item on a die face does (docs/faces.md; "faces" is the
; player's word, an item the code's). Data only: the build lays every row out on the second disk
; (content/catalog: a face's record, its id the row's place in rows below), and memory holds only
; the faces in play (content/items: her six, the hairball, the offer). The rows are in a file a
; slot (content/faces_wand.tsp to faces_trick.tsp; the hairball here). To add a face, add its row
; to its slot's file (and its picture: tools/dhgr/icons.py, then python3 tools/dhgr/game.py); to
; cut one, take its row out. No other file changes, and no memory: the row costs a sector of
; disk 2.
;
; A row: (NAME :field value ...), NAME the face's name in code ((catalog.id NAME), e.g. the
; starting faces in content/items). The fields:
;   :name     what the card and the log call it, in capitals, 17 columns at most
;   :text     the card's line, # its number (amount + step a level, after the boosts); parts split
;             by | a row each, what it always does first, then each extra with its condition first;
;             35 columns a part, plain English, subject first, never "slot"
;   :slot     wand fluff star book curse trick (junk: the hairball, on no die face)
;   :amount   its number at level 0;  :step  more a level of its slot
;   :cost     a book's mana;  :aim  foe (an enemy she picks), self, all (every enemy)
;   :tags     words from three (its steps after (three) run for the third face of its slot in a
;             turn), kittens (her kit page shows her kittens by it), grows (its number grows with
;             her habit), and the tray caption's look: plus (+n), times (Xn), none (no number)
;   :show     how its play looks (content/shows: BOLT, NONE, SPRAY, STREAK, PUFF, FLEAS, ...)
;   :picture  its card picture's name in tools/dhgr/icons.py (11 x 15 pixels)
;   :weight   its share of the draws between fights (battle/offer); 0: never offered
;   :steps    what it does: content/steps.tsp's vocabulary, run by content/play. A say may give its
;             line as a string, kept in the face's own record: (say "Third in a turn: static!")
;
; The build fails on a row it cannot lay out (an unknown field, slot or picture; a record past
; 256 bytes: the name, the text, the steps and their lines take about 150 of it).

(import content/cards)
(import content/faces_wand)
(import content/faces_fluff)
(import content/faces_star)
(import content/faces_book)
(import content/faces_curse)
(import content/faces_trick)

(macro rows ()
    (append (faces_wand.rows)
        (faces_fluff.rows)
        (faces_star.rows)
        (faces_book.rows)
        (faces_curse.rows)
        (faces_trick.rows)
        '((HAIRBALL
                :name "HAIRBALL"
                :text "A dud. Re-roll it to cough it up."
                :slot junk
                :amount 0
                :step 0
                :cost 0
                :aim self
                :tags (none)
                :show NONE
                :picture hairball
                :weight 0
                :steps ((cue puff) (say "A hairball. Nothing happens."))))))

; the six upgrade cards' weights (a level on her wand, fluff, star, book, curse, trick face,
; whatever is on it), drawn among the faces' rows by the same rule
(macro upgrades ()
    '(3 3 3 2 2 1))
