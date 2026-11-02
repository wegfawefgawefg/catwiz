; Catwiz: a cat wizard's dice run through the woods, the garden and the yard to the Bulldog
; King, for the Apple IIe in double hi-res.
; The title, then a battle, then back to the title. See AGENTS.md and docs/plan.md.

(import apple2 a2)
(import keys)
(import state)
(import title/title)
(import title/machine)
(import battle/battle)
(import sound/sound)
(import mockingboard mb)
(import mouse)
(import battle/boxes)
(import draw/screen)

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
(let key_line (array u8 8) :address 0x06E4)
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

; a click: the mouse's button going down (a tap on the phone player or a click in the window
; puts the mouse there and presses it; a mouse on a real Apple works the same), a CLICK in the
; key line with where it was. The loop takes it as the key of the box it hit on the screen then
; (battle/boxes). The loop looks at the mouse once a pass, not the handler: a call into the
; card's firmware may change anything for all the compiler knows, which in the handler would
; slow every other line of the game. A press lasts longer than a pass (the players hold one 6
; frames at least)
(const CLICK u8 0x01)
(let click_x (array u8 8) :address 0x06EC) ; whole pixels, 0-139
(let click_y (array u8 8) :address 0x0708)
(let button_was bool false)

(fn poll_click () void
    ; READMOUSE: the slot's screen holes get the mouse's place and button
    (jsr mouse.read_entry (x mouse.cn) (y mouse.n0))
    (let down bool (!= (& (at mouse.status mouse.slot) 0x80) 0))
    (let was bool button_was)
    (set button_was down)
    (if (or (not down) was)
        (return))
    ; the handler puts keys in the line too: not while this one goes in
    (sei)
    (let next u8 (& (+ key_tail 1) (- KEY_LINE 1)))
    (if (= next key_head)
        (do
            (cli)
            (return)))
    ; x is 0-279 in two bytes: halved, in one
    (set (at click_x key_tail)
        (| (>> (at mouse.x_low mouse.slot) 1) (<< (at mouse.x_high mouse.slot) 7)))
    (set (at click_y key_tail) (at mouse.y_low mouse.slot))
    (set (at key_line key_tail) CLICK)
    (set key_tail next)
    (cli))

; whether a key waits: in the line (keys with a card, clicks), or on the keyboard with no card
; (a look, no call: the loop asks every pass)
(macro key_waiting ()
    `(or (!= key_head key_tail) (and (not mb.found) (>= (io_read u8 a2.KBD) 0x80))))

; the next key: from the line (a click there the key of what it hit), else with no card the
; keyboard's
(fn next_key () u8
    (if (= key_head key_tail)
        (return (if mb.found
            0
            (keys.read))))
    (let at u8 key_head)
    (set key_head (& (+ at 1) (- KEY_LINE 1)))
    (let k u8 (at key_line at))
    (if (= k CLICK)
        (return (boxes.key_at (at click_x at) (at click_y at))))
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
        (if state.mouse_on
            (poll_click))
        ; read keys, only when the screen takes them: a key pressed during her own action or
        ; the dice landing waits in the line (so dice can be played one after another as fast
        ; as they are tapped), one in the enemies' turn is dropped (battle.wants_key)
        (let key u8
            (if (and (key_waiting) (or (= state.screen state.Screen.title) (battle.wants_key)))
                (next_key)
                0))
        ; step the screen we are on, and change screens when it asks
        (let steps u8 (steps_due))
        (let next state.Screen (match state.screen
            (state.Screen.title (title.step key))
            (state.Screen.battle (battle.step key))))
        (while (and (and (> steps 1) (not (battle.will_change)))
                (and (= state.screen state.Screen.battle) (= next state.screen)))
            (set next
                (battle.step (if (battle.wants_key)
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
