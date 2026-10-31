; the battle log: the bottom two text rows, plain sentences of what just happened, the newest
; at the bottom. Each new line makes the enemies wait a moment (state.log_hold), so it can be
; read before the next one pushes it up.

(import state)
(import draw/text)
(import content/encounters enc)
(import content/enemies en)

(const ROW_OLDER u8 2)
(const ROW_NEWER u8 3)
(const HOLD_FRAMES u8 30)

; one-time hints for a new player, in the log: a bit each, set once it has shown (once a boot)
(const HINT_TURN u8 1)    ; the first turn: how to play a die and end the turn
(const HINT_MANA u8 2)    ; the first mana
(const HINT_SHUFFLE u8 4) ; the first time the discard goes back into the draw pile
(let hints_shown u8 0)

; what the two rows show, as screen codes
(let older (array u8 35) :address 0x0990) ; scratch: see AGENTS.md, Memory
(let newer (array u8 35) :address 0x09B8)

; who's name: the hero's, or the enemy kind's
(fn name ((who u8)) (ptr u8)
    (if (= who state.HERO)
        (return enc.HERO.name))
    (at en.ENEMIES (at state.actors who kind) name))

(fn clear () void
    (text.start)
    (text.save (addr_of (at older 0)))
    (text.save (addr_of (at newer 0)))
    (text.show ROW_OLDER)
    (text.show ROW_NEWER))

; the line text.line holds now, under the one before; the rows are drawn at the next frame
; (flush), once however many lines came in the steps before it
(let unshown bool false)

(fn push () void
    (for i u8 0 text.COLUMNS
        (set (at older i) (at newer i)))
    (text.save (addr_of (at newer 0)))
    (set unshown true)
    (set state.log_hold HOLD_FRAMES))

; the two rows drawn again, if a line came since they were
(fn flush () void
    (if (not unshown)
        (return))
    (set unshown false)
    (text.load_line (addr_of (at newer 0)))
    (text.show ROW_NEWER)
    (text.load_line (addr_of (at older 0)))
    (text.show ROW_OLDER))

; a sentence: s with n for its #
(fn line ((s (ptr u8)) (n u8)) void
    (text.start)
    (text.add_n s n)
    (push))

; a sentence about who: its name, then s
(fn who ((w u8) (s (ptr u8)) (n u8)) void
    (text.start)
    (text.add (name w))
    (text.add_n s n)
    (push))

; who starts an action: "Catwiz: WAND 2.", "Puffcap: Headbutt for 2." (s with n for its #)
(fn uses ((w u8) (s (ptr u8)) (n u8)) void
    (text.start)
    (text.add (name w))
    (text.add ": ")
    (text.add_n s n)
    (text.char '.')
    (push))

; whether hint h is still to show: true the first time, then never again
(fn once ((h u8)) bool
    (if (!= (& hints_shown h) 0)
        (return false))
    (set hints_shown (| hints_shown h))
    true)
