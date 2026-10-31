; the title: CATWIZ with a glowing rim over the night, the cat against the moon, a jingle, and
; PRESS RETURN (any key or tap starts). One picture (art/title_*, packed), unpacked onto both
; pages; the glow is the letters' rim drawn again in turn in each of its
; colours (art KIND_GLOW: the rim's sprites), straight onto the page on screen.

(import apple2 a2)
(import dhgr)
(import random)
(import state)
(import art/sprites art)
(import draw/screen)
(import draw/blit)
(import draw/stage)
(import sound/sound)

(const GLOW_STEPS u8 4)   ; the rim's colours in turn (tools/dhgr/title.py, GLOW)
(const GLOW_FRAMES u8 10) ; frames on each step

(let shown bool false) ; the title has been on the screen

(fn enter () void
    (set state.screen state.Screen.title)
    (sound.quiet)
    (screen.wait_frame)
    (screen.wait_frame)
    (stage.title dhgr.PAGE2)
    ; page 1 is where the runs are read (draw/blit): once the screen is graphics (after the
    ; first title) the picture shows from page 2 meanwhile
    (if shown
        (dhgr.show dhgr.PAGE2))
    (set shown true)
    (stage.title_runs)
    (screen.copy_page dhgr.PAGE2 dhgr.PAGE1)
    (screen.on)
    (set state.glow 0)
    (set state.glow_time 0)
    ; a tap or key from the loading or the run before waits in the keyboard: not a start
    (io_read u8 a2.KBDSTRB)
    (sound.song sound.Song.title))

; one frame of the title; gives the screen to show next
(fn step ((key u8)) state.Screen
    ; the time to the key press seeds the dice
    (set random.seed (+ random.seed 1))
    (if (!= key 0)
        (do
            (sound.cue sound.Cue.confirm)
            (return state.Screen.battle)))
    (set state.glow_time (+ state.glow_time 1))
    state.Screen.title)

(fn draw () void
    (if (< state.glow_time GLOW_FRAMES)
        (return))
    (set state.glow_time 0)
    (set state.glow (+ state.glow 1))
    (if (= state.glow GLOW_STEPS)
        (set state.glow 0))
    (let rim u8 (+ art.GLOW0 state.glow))
    (blit.sprite screen.PAGE (at art.KIND_COL art.KIND_GLOW) (at art.KIND_TOP art.KIND_GLOW) rim))
