; Witchdog: a witch dog's dice battle in the forest, for the Apple IIe in hi-res.
; The title, then a battle, then back to the title. See AGENTS.md and docs/plan.md.

(import keys)
(import state)
(import draw/screen)
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
    (mb.service))

(fn main () void
    (if (not (machine.has_aux))
        (machine.refuse))
    (sound.setup)
    (screen.setup)
    (title.enter)
    (while true
        (set state.ticks (+ state.ticks 1))
        ; read keys, only when the screen takes them: a key pressed during an animation waits
        (let key u8 (if (wants_key)
            (keys.read)
            0))
        ; step the screen we are on, and change screens when it asks
        (let next state.Screen (match state.screen
            (state.Screen.title (title.step key))
            (state.Screen.battle (battle.step key))))
        (if (!= next state.screen)
            (match next
                (state.Screen.title (title.enter))
                (state.Screen.battle (battle.enter))))
        ; an effect waiting for the card's effect voice
        (sound.step)
        ; draw frame, then show it at the next vertical blank
        (match state.screen
            (state.Screen.title (title.draw))
            (state.Screen.battle (battle.draw)))))
