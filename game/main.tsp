; Catwiz: a cat wizard's dice battle in the forest, for the Apple IIe in double hi-res.
; The title, then a battle, then back to the title. See AGENTS.md and docs/plan.md.

(import keys)
(import state)
(import title/title)
(import title/machine)
(import battle/battle)
(import sound/sound)
(import mockingboard mb)

(fn wants_key () bool
    (match state.screen
        (state.Screen.title true)
        (state.Screen.battle (battle.wants_key))))

; the program's one interrupt handler: the Mockingboard's tick, which plays the music
(fn irq () void :interrupt
    (set state.clock (+ state.clock 1))
    (mb.service))

; the battle steps once for every frame that went by since the last pass, so its animations
; keep their time however long a frame takes to draw (a pass with sprites moving takes a few).
; The card's tick counts the frames; with no card, one step a pass. owed carries what one pass
; took more or less than its steps, a frame or two at most, so a long load is not caught up
(const MOST_STEPS i8 12)
(let counted u8 0)
(let owed i8 0)

(fn steps_due () u8
    (if (not mb.found)
        (return 1))
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
        ; read keys, only when the screen takes them: a key pressed during an animation waits
        (let key u8 (if (wants_key)
            (keys.read)
            0))
        ; step the screen we are on, and change screens when it asks
        (let steps u8 (steps_due))
        (let next state.Screen (match state.screen
            (state.Screen.title (title.step key))
            (state.Screen.battle (battle.step key))))
        (while (and (> steps 1) (and (= state.screen state.Screen.battle) (= next state.screen)))
            (set next (battle.step 0))
            (set steps (- steps 1)))
        (if (!= next state.screen)
            (match next
                (state.Screen.title (title.enter))
                (state.Screen.battle (battle.enter))))
        ; draw frame, then show it at the next vertical blank
        (match state.screen
            (state.Screen.title (title.draw))
            (state.Screen.battle (battle.draw)))))
