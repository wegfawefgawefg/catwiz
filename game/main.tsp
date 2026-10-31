; Catwiz: a cat wizard's dice battle in the forest, for the Apple IIe in double hi-res.
; The title, then a battle, then back to the title. See AGENTS.md and docs/plan.md.

(import apple2 a2)
(import keys)
(import state)
(import title/title)
(import title/machine)
(import battle/battle)
(import sound/sound)
(import mockingboard mb)
(import draw/screen)

(fn wants_key () bool
    (match state.screen
        (state.Screen.title true)
        (state.Screen.battle (battle.wants_key))))

; the program's one interrupt handler: the Mockingboard's tick, which plays the music
(fn irq () void :interrupt
    (set state.clock (+ state.clock 1))
    (take_key)
    (mb.service))

; keys go into a line as the card's tick finds them, 60 times a second, so a tap is never lost
; to the next one while a long frame draws (the keyboard holds one key); the loop takes them in
; order. The tick only adds (tail), the loop only takes (head): no interrupts off for it. With
; no card, the keyboard is read once a pass
(const KEY_LINE u8 8) ; a power of 2
(let key_line (array u8 8))
(let key_head u8 0)
(let key_tail u8 0)

(fn take_key () void
    (let next u8 (& (+ key_tail 1) (- KEY_LINE 1)))
    (if (= next key_head)
        (return))
    ; the keyboard read here, not with keys.read: the loop calls that too, and the tick may
    ; stop it halfway
    (let k u8 (io_read u8 a2.KBD))
    (if (< k 0x80)
        (return))
    (io_read u8 a2.KBDSTRB)
    (set (at key_line key_tail) (& k 0x7F))
    (set key_tail next))

(fn next_key () u8
    (if (not mb.found)
        (return (keys.read)))
    (if (= key_head key_tail)
        (return 0))
    (let k u8 (at key_line key_head))
    (set key_head (& (+ key_head 1) (- KEY_LINE 1)))
    k)

; the battle steps once for every frame that went by since the last pass, so its animations
; keep their time while nothing changes on screen, but never past a change: the first step that
; changes the picture is drawn before the next (battle.will_change). Nothing is skipped; a change
; that takes longer to draw than the frames until the next one slows the animation down.
; The card's tick counts the frames; with no card, one step a pass. owed carries what one pass
; took more or less than its steps, a frame or two at most, so a long load is not caught up
(const MOST_STEPS i8 20)
(let counted u8 0)
(let owed i8 0)

(fn steps_due () u8
    ; at least a frame a pass: drawing goes straight onto the screen, with no flip to wait for
    (if (not mb.found)
        (do
            (screen.wait_frame)
            (return 1)))
    (while (= state.clock counted))
    (let now u8 state.clock)
    (let gone u8 (- now counted))
    (set counted now)
    (if (> gone 8)
        (set gone 8))
    (set owed (+ owed (as i8 gone)))
    (let steps i8 owed)
    (if (< steps 1)
        (set steps 1))
    (if (> steps MOST_STEPS)
        (set steps MOST_STEPS))
    (set owed (- owed steps))
    (if (> owed 2)
        (set owed 2))
    (if (< owed -2)
        (set owed -2))
    (as u8 steps))

(fn main () void
    (if (not (machine.has_aux))
        (machine.refuse))
    (sound.setup)
    (set state.ticks 0)
    (title.enter)
    (while true
        (set state.ticks (+ state.ticks 1))
        ; read keys, only when the screen takes them: a key pressed during her own action or
        ; the dice landing waits in the line (so dice can be played one after another as fast
        ; as they are tapped), one in the enemies' turn is dropped (battle.wants_key)
        (let key u8 (if (wants_key)
            (next_key)
            0))
        ; step the screen we are on, and change screens when it asks
        (let steps u8 (steps_due))
        (let next state.Screen (match state.screen
            (state.Screen.title (title.step key))
            (state.Screen.battle (battle.step key))))
        (while (and (and (> steps 1) (not (battle.will_change)))
                (and (= state.screen state.Screen.battle) (= next state.screen)))
            (set next (battle.step (if (battle.wants_key)
                (next_key)
                0)))
            (set steps (- steps 1)))
        (if (!= next state.screen)
            (match next
                (state.Screen.title (title.enter))
                (state.Screen.battle (battle.enter))))
        ; draw frame, then show it at the next vertical blank
        (match state.screen
            (state.Screen.title (title.draw))
            (state.Screen.battle (battle.draw)))))
