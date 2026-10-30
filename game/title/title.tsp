; the title: WITCHDOG glowing over the night clouds, a jingle, and Press Return. The glow is
; four pictures in aux memory, faint to full, each copied onto the back page in turn and shown.

(import apple2 a2)
(import random)
(import state)
(import art/title_0)
(import art/title_1)
(import art/title_2)
(import art/title_3)
(import draw/screen)
(import sound/music)

(const GLOW_STEPS u8 6)  ; faint, mid, bright, full, bright, mid
(const GLOW_FRAMES u8 6) ; frames on each step, on top of the copy's own

(const GLOW_PICTURE (array u8 6) (make (array u8 6) 0 1 2 3 2 1))

(fn picture ((n u8)) (ptr u8)
    (match n
        (0 (addr_of (at title_0.picture 0)))
        (1 (addr_of (at title_1.picture 0)))
        (2 (addr_of (at title_2.picture 0)))
        (_ (addr_of (at title_3.picture 0)))))

(fn enter () void
    (set state.screen state.Screen.title)
    (screen.load_page screen.back (picture 3))
    (screen.flip)
    (set state.glow 3)
    (set state.glow_time 0)
    (set state.glow_loaded false)
    (music.jingle))

; one frame of the title; gives the screen to show next
(fn step ((key u8)) state.Screen
    ; the time to the key press seeds the dice
    (set random.seed (+ random.seed 1))
    (if (= key a2.KEY_RETURN)
        (return state.Screen.battle))
    (set state.glow_time (+ state.glow_time 1))
    (if (< state.glow_time GLOW_FRAMES)
        (return state.Screen.title))
    (set state.glow_time 0)
    (set state.glow (% (+ state.glow 1) GLOW_STEPS))
    (screen.load_page screen.back (picture (at GLOW_PICTURE state.glow)))
    (set state.glow_loaded true)
    state.Screen.title)

(fn draw () void
    (if state.glow_loaded
        (do
            (screen.flip)
            (set state.glow_loaded false)
            (return)))
    (screen.wait_frame))
