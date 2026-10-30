; the battle log: the bottom two text rows, plain sentences of what just happened, the newest
; at the bottom. Each new line makes the enemies wait a moment (state.log_hold), so it can be
; read before the next one pushes it up.

(import state)
(import draw/text)
(import content/encounters enc)
(import content/enemies en)

(const ROW_OLDER u8 2)
(const ROW_NEWER u8 3)
(const HOLD_FRAMES u8 40)

; what the two rows show, as screen codes
(let older (array u8 40) :address 0x0990) ; scratch: see AGENTS.md, Memory
(let newer (array u8 40) :address 0x09B8)

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

; the line text.line holds now, under the one before
(fn push () void
    (for i u8 0 text.COLUMNS
        (set (at older i) (at newer i)))
    (text.save (addr_of (at newer 0)))
    (text.show ROW_NEWER)
    (text.load_line (addr_of (at older 0)))
    (text.show ROW_OLDER)
    (set state.log_hold HOLD_FRAMES))

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

; who starts an action: "CATWIZ: WAND 2.", "PUFFCAP: HEADBUTT FOR 2." (s with n for its #)
(fn uses ((w u8) (s (ptr u8)) (n u8)) void
    (text.start)
    (text.add (name w))
    (text.add ": ")
    (text.add_n s n)
    (text.char '.')
    (push))
