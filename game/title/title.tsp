; the title: CATWIZ with a glowing rim over the night, the cat against the moon, a jingle, and
; PRESS RETURN (any key or tap starts). One picture (art/title_*, packed), unpacked onto both
; pages; the glow is the letters' rim drawn again in turn in each of its
; colours (art KIND_GLOW: the rim's sprites), straight onto the page on screen.

(import apple2 a2)
(import auxmem)
(import mouse)
(import dhgr)
(import random)
(import state)
(import art/sprites art)
(import draw/screen)
(import draw/blit)
(import draw/stage)
(import sound/sound)
(import sound/music)
(import mockingboard mb)
(import title/disk2)

(const GLOW_STEPS u8 4)   ; the rim's colours in turn (tools/dhgr/title.py, GLOW)
(const GLOW_FRAMES u8 10) ; frames on each step

(let shown bool false)    ; the title has been on the screen
(let card_due bool false) ; the sound card is set up at the first title's first step
(let song_due bool false) ; the title's song (or with no card its jingle) starts at its step
(let due bool false)      ; the title is set up at its next step (begin): in the title's group

; the title comes next: its step sets it up (enter), so that code is in the title's overlay group
; (from aux memory), not resident
(fn begin () void
    (set state.screen state.Screen.title)
    (set state.glow_time 0)
    (set due true))

(let set_up bool false) ; the guard and the mouse are in (setup)

; once, in the first title's first pass, before its step: lib/auxmem's guard, before anything
; runs a with_aux with interrupts on (the card's tick starts at the step, sound.setup; an overlay
; group's copy from aux memory runs with them off), then the mouse card found and set up (main's
; loop reads it from then on). An overlay group of its own, copied in from aux memory once: cold
; code out of main memory, and out of the title's group, which loads at every title (in it, the
; title after a run was ready half a frame later). Main's loop calls it only while set_up is
; false and the title's step and draw only while it is true, which is what keeps them in two
; groups (Tisple's dispatch facts)
(fn setup () void :overlay
    (auxmem.guard)
    (mouse.init)
    (set state.mouse_on mouse.found)
    (set set_up true))

(fn enter () void
    ; the first time: the sound card is set up at the title's first step (step, in the title's
    ; overlay group: it is cold, and main memory is full)
    (if (not shown)
        (set card_due true))
    (set state.screen state.Screen.title)
    ; after a run, with the card: the title's song now, so it comes in while the title loads as
    ; the run's last fades out (sound.song); the first time, and with no card, at the step
    (let early bool (and shown mb.found))
    (if early
        (sound.song sound.Song.title))
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
    ; the song starts at the step (the first time with the card set up) unless it has already
    (set song_due (not early)))

; one frame of the title; gives the screen to show next
(fn step ((key u8)) state.Screen :overlay
    ; a key or click from before the title was up (read before the load, or put in the key
    ; line by the tick while it ran) is not a start: this pass ignores its key and empties the
    ; line
    (if due
        (do
            (set due false)
            (enter)
            (set state.key_head state.key_tail)
            (set key 0)))
    (if card_due
        (do
            (set card_due false)
            (sound.setup)))
    ; the song, or on the speaker the jingle (here: the title's group has its code)
    (if song_due
        (do
            (set song_due false)
            (if mb.found
                (sound.song sound.Song.title)
                (music.jingle))))
    ; the time to the key press seeds the dice
    (set random.seed (+ random.seed 1))
    (if (!= key 0)
        (do
            (sound.cue sound.Cue.confirm)
            ; the title's song fades out from here, while the second disk is found (the first
            ; time: title/disk2, in the title's group) and the fight's code and her kit load;
            ; the fight's song is read from it at once and comes in as soon as that is silent
            (sound.quiet)
            (disk2.find)
            (sound.song sound.Song.woods) ; the first fight's (battle.fight_song)
            (return state.Screen.battle)))
    (set state.glow_time (+ state.glow_time 1))
    state.Screen.title)

(fn draw () void :overlay
    (if (< state.glow_time GLOW_FRAMES)
        (return))
    (set state.glow_time 0)
    (set state.glow (+ state.glow 1))
    (if (= state.glow GLOW_STEPS)
        (set state.glow 0))
    (let rim u8 (+ art.GLOW0 state.glow))
    (blit.sprite screen.PAGE (at art.tab.kcol art.KIND_GLOW) (at art.tab.ktop art.KIND_GLOW) rim))
