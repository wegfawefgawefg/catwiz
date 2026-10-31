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

; who's name: the hero's, or the enemy kind's (in aux memory: text.add_aux)
(fn name ((who u8)) (ptr u8)
    (if (= who state.HERO)
        (return enc.HERO.name))
    (en.name (at state.actors who kind)))

(fn clear () void
    (set waiting 0)
    (set unshown false)
    (text.start)
    (text.save (addr_of (at older 0)))
    (text.save (addr_of (at newer 0)))
    (text.show ROW_OLDER)
    (text.show ROW_NEWER))

; the lines that came since the rows were drawn, waiting for the next frame (flush): each as
; its kind (a plain sentence, one about who, who starting an action), who's name, the sentence
; with its number. Writing one is a few bytes; making the text is flush's, once
(const LINE u8 0)
(const WHO u8 1)
(const USES u8 2)
(const WAITING u8 8)
(let waiting u8 0)
; scratch (AGENTS.md, Memory): set before they are read, as waiting counts them
(let w_kind (array u8 8) :address 0x0447)
(let w_name (array (ptr u8) 8) :address 0x0457)
(let w_text (array (ptr u8) 8) :address 0x0467)
(let w_n (array u8 8) :address 0x044F)
(let unshown bool false)

; a line waits for flush; with the line full, the oldest goes (only the last two show anyway)
(fn wait ((kind u8) (nm (ptr u8)) (s (ptr u8)) (n u8)) void
    (if (= waiting WAITING)
        (do
            (for i u8 1 WAITING
                (set (at w_kind (- i 1)) (at w_kind i))
                (set (at w_name (- i 1)) (at w_name i))
                (set (at w_text (- i 1)) (at w_text i))
                (set (at w_n (- i 1)) (at w_n i)))
            (set waiting (- WAITING 1))))
    (set (at w_kind waiting) kind)
    (set (at w_name waiting) nm)
    (set (at w_text waiting) s)
    (set (at w_n waiting) n)
    (set waiting (+ waiting 1))
    (set unshown true)
    (set state.log_hold HOLD_FRAMES))

; the line text.line holds now, under the one before
(fn push () void
    (for i u8 0 text.COLUMNS
        (set (at older i) (at newer i)))
    (text.save (addr_of (at newer 0))))

; the lines waiting made and the two rows drawn again, if a line came since they were
(fn flush () void
    (if (not unshown)
        (return))
    (set unshown false)
    (for k u8 0 waiting
        (text.start)
        (let kind u8 (at w_kind k))
        (if (!= kind LINE)
            (text.add_aux (at w_name k)))
        (if (= kind USES)
            (text.add ": "))
        ; every sentence is in aux memory: a move's text (the content's) or a module's SAY table
        (text.add_aux_n (at w_text k) (at w_n k))
        (if (= kind USES)
            (text.char '.'))
        (push))
    (set waiting 0)
    (text.load_line (addr_of (at newer 0)))
    (text.show ROW_NEWER)
    (text.load_line (addr_of (at older 0)))
    (text.show ROW_OLDER))

; the two rows shown again as they were (a page over the stage wrote over them)
(fn reshow () void
    (text.load_line (addr_of (at newer 0)))
    (text.show ROW_NEWER)
    (text.load_line (addr_of (at older 0)))
    (text.show ROW_OLDER))

; a sentence: s (in aux memory: a SAY table's) with n for its #
(fn line ((s (ptr u8)) (n u8)) void
    (wait LINE "" s n))

; a sentence about who: its name, then s (in aux memory)
(fn who ((w u8) (s (ptr u8)) (n u8)) void
    (wait WHO (name w) s n))

; who starts an action: "Puffcap: Headbutt for 2." (s, a move's text in aux memory, with n for
; its #)
(fn uses ((w u8) (s (ptr u8)) (n u8)) void
    (wait USES (name w) s n))

; whether hint h is still to show: true the first time, then never again
(fn once ((h u8)) bool
    (if (!= (& hints_shown h) 0)
        (return false))
    (set hints_shown (| hints_shown h))
    true)
