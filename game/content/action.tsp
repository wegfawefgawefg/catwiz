; the rows the hero's items (content/items) and the enemies' moves (content/moves) are made of.
; What an item does is its steps (content/cards.tsp); what a move does, content/foes.tsp.

(import state)

; what an enemy's move does (content/foes.tsp has each; Mimic's table, content/cards.tsp
; MIMICRY, what each would be for her)
(enum Effect (hit ; amount damage
        shield    ; amount shield, gone at the holder's next turn
        heal      ; amount hit points back
        fleas     ; curse: amount damage at the end of each of its turns, for 3 turns; stacks
        wet       ; curse: its hits are halved, for amount turns more
        cheer     ; an enemy's friend hits amount harder next time
        wait      ; an enemy move that does nothing (the countdowns)
        spook     ; curse on you: your dice get amount less on your next turn
        mend      ; an enemy heals each of its friends amount
        summon    ; an enemy calls amount of its kind's calls into empty spots
        steal     ; an enemy takes the die you played last; you get it back when it is beaten
        reflect   ; an enemy sends back the next amount damage you deal it, till its next turn
        hit2      ; amount damage twice
        grow      ; an enemy hits amount harder for the rest of the fight
        junk))    ; an enemy clogs your slot amount with a hairball for the fight

; the six item slots, a face each (wand, fluff, star, book, curse, then the sixth: tricks), and
; junk: the hairball, on no slot
(enum Slot (wand fluff star book curse trick junk))

; an item's tags: THREE it has a three (what the third face of its slot in a turn adds: its
; steps after three), KITTENS her kit page shows her kittens by it, GROWS its number grows with
; her habit stack (Scratching Habit), and how the tray's caption shows its number: CAP_PLUS
; (+n), CAP_TIMES (Xn), CAP_NONE (none)
(const THREE u8 1)
(const KITTENS u8 2)
(const GROWS u8 4)
(const CAP_PLUS u8 8)
(const CAP_TIMES u8 16)
(const CAP_NONE u8 32)

; an item: what a face does (content/items.tsp). name: the log's and the card's name; text: the
; card's item line (# its number); slot: which face it sits on; amount: its number, step more a
; level; cost: mana; fx: its steps (content/cards.tsp); tags (above); aim: who it goes to; icon:
; its picture on the card (art/icons). A face for an enemy is thrown at it, one for the hero is a
; hop (battle/act)
(struct Item ((name (ptr u8))
        (text (ptr u8))
        (slot Slot)
        (amount u8)
        (step u8)
        (cost u8)
        (fx (ptr u8))
        (tags u8)
        (aim state.Aim)
        (icon u8)))

; an enemy's move: text for the bottom text and the log (no name, # its number, 21 characters
; at most), icon the hud glyph over its head before it acts
(struct Move ((text (ptr u8))
        (effect Effect)
        (amount u8)
        (aim state.Aim)
        (motion state.Motion)
        (icon u8)))
