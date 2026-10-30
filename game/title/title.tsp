; the title: CATWIZ with a glowing rim over the night, the cat against the moon, a jingle, and
; PRESS RETURN (any key or tap starts). One picture (art/title_*, packed), unpacked onto the
; backdrop page and both pages; the glow is the letters' rim drawn again in turn in each of its
; colours (art KIND_GLOW: the rim's sprites), on the page not shown, then shown.

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

(fn enter () void
    (set state.screen state.Screen.title)
    (sound.quiet)
    (screen.wait_frame)
    (screen.wait_frame)
    (stage.title)
    (blit.start)
    (blit.want art.KIND_GLOW)
    (blit.unpack_all)
    (screen.copy_page screen.BACKDROP dhgr.PAGE1)
    (screen.copy_page screen.BACKDROP dhgr.PAGE2)
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
        (do
            (screen.wait_frame)
            (return)))
    (set state.glow_time 0)
    (set state.glow (+ state.glow 1))
    (if (= state.glow GLOW_STEPS)
        (set state.glow 0))
    (let rim u8 (+ art.GLOW0 state.glow))
    (blit.sprite screen.back (at art.KIND_COL art.KIND_GLOW) (at art.KIND_TOP art.KIND_GLOW) rim)
    (screen.flip))
