; every sound the game makes goes through here, the one place that picks the Mockingboard or the
; speaker: (sound.cue Cue.zap) for an effect, (sound.song Song.battle) for the music.
;
; With a card (found by setup, in any slot): the music plays from the card's timer interrupt
; (main's irq calls mb.service), and an effect borrows one music voice while it plays, the
; music on it coming back after. The card plays one effect at a time, so one that comes while
; another plays waits in lib/mockingboard's line: a blow that kills plays its zap, thump and
; squeak one after the other, as the speaker does. Cues that only matter now (a dice rattle, a
; dead key) are dropped instead of waiting.
;
; With no card: the speaker effects of sfx.tsp, which hold the processor while they play, the
; title jingle, and no other music.
;
; The songs live on the disks (songs.tsp); the one starting is read into aux memory and copied
; into main memory (sound/waiting), with interrupts on: the first title puts in lib/auxmem's
; guard. A song change fades the one before out and the new one in (song), and the game goes on
; meanwhile; a screen's song starts as its load begins and plays through it.

(import mockingboard mb)
(import mockingboard_player player)
(import mockingboard_song tune)
(import state)
(import sound/sfx)
(import sound/music)
(import sound/card_fx fx)
(import sound/songs)
(import sound/waiting)
(import draw/meter)
(import title/disk2)

(enum Cue (rattle ; one shake of the dice
        tok       ; a die played
        zap       ; a magic bolt lands
        thump     ; a blow lands on an enemy
        ping      ; a shield takes a blow, or goes up
        chime     ; hit points back
        hiss      ; a fire catches
        wobble    ; spooked
        puff      ; a die that does nothing
        squeak    ; someone beaten
        yelp      ; the hero hurt
        growl     ; an enemy starts its move
        turn_on   ; the hero's turn begins
        turn_off  ; and ends
        blip      ; the target moves
        confirm   ; RETURN on the title
        nope      ; a key that does nothing now
        meow      ; the hero's meow, M
        dart      ; Red Dot
        mimic     ; Mimic
        yowl      ; Catfight
        shimmer   ; Mirror Fur
        lucky     ; Lucky Paw
        hops      ; Flea Circus
        glow      ; Sunbeam
        scratch   ; Scratching Habit
        coin      ; Double or Nothing
        buzz      ; fleas
        splash    ; wet
        thunder   ; lightning
        slurp     ; a bite that heals her
        snore     ; asleep
        boing     ; spooked
        whoosh    ; her shield flung
        sparkle)) ; mana

(enum Song (title battle won lost))

; the voice each cue borrows: 2, the pad on the left chip, for the hero's side, and 5, the
; shaker on the right chip, for the enemies'. The hero stands on the left of the screen.
(const CUE_VOICE (array u8 35)
    (make (array u8 35) 2 2 2 5 5 2 5 5 2 5 2 5 2 2 2 2 2 2 5 2 5 2 2 5 2 5 2 5 5 5 2 5 5 2 2)
    :in aux)

; whether a cue waits in line while another effect plays; false: dropped
(const CUE_WAITS (array bool 35)
    (make (array bool 35)
        false true true true true true true true true true true true true true false true false
        false true true true true true true true true true true true true true true true true true)
    :in aux)

; where each song's fade in starts, in steps down (3 dB a step), in Song's order: 3 steps below
; its first notes' volume (songs.tsp: the title's bass v13, the battle's v12), so the first note
; is heard from its first tick and rises from there (from 13, the loudest volume, both songs'
; first notes decayed faster than the fade rose and were never heard: the battle's first 36
; ticks were silent). The stingers (won, lost) at full at once: a fade in would take most of
; them
(const FADE_FROM (array u8 4) (make (array u8 4) 10 9 0 0))

; at the start: find the card, if there is one, and start its tick (title.enter puts
; lib/auxmem's guard in first, which lets aux copies run while it ticks), the music faded out,
; so the first song starts at once and fades in
(fn setup () void
    (mb.init)
    (mb.fade_in 15)
    (mb.fade 15))

; the card's effect for each cue, in Cue's order
(const CARD_EFFECT (array (ptr u8) 35)
    (make (array (ptr u8) 35)
        (addr_of (at fx.rattle 0))
        (addr_of (at fx.tok 0))
        (addr_of (at fx.zap 0))
        (addr_of (at fx.thump 0))
        (addr_of (at fx.ping 0))
        (addr_of (at fx.chime 0))
        (addr_of (at fx.hiss 0))
        (addr_of (at fx.wobble 0))
        (addr_of (at fx.puff 0))
        (addr_of (at fx.squeak 0))
        (addr_of (at fx.yelp 0))
        (addr_of (at fx.growl 0))
        (addr_of (at fx.turn_on 0))
        (addr_of (at fx.turn_off 0))
        (addr_of (at fx.blip 0))
        (addr_of (at fx.confirm 0))
        (addr_of (at fx.nope 0))
        (addr_of (at fx.meow 0))
        (addr_of (at fx.dart 0))
        (addr_of (at fx.mimic 0))
        (addr_of (at fx.yowl 0))
        (addr_of (at fx.shimmer 0))
        (addr_of (at fx.lucky 0))
        (addr_of (at fx.hops 0))
        (addr_of (at fx.glow 0))
        (addr_of (at fx.scratch 0))
        (addr_of (at fx.coin 0))
        (addr_of (at fx.buzz 0))
        (addr_of (at fx.splash 0))
        (addr_of (at fx.thunder 0))
        (addr_of (at fx.slurp 0))
        (addr_of (at fx.snore 0))
        (addr_of (at fx.boing 0))
        (addr_of (at fx.whoosh 0))
        (addr_of (at fx.sparkle 0)))
    :in aux)

; the speaker's version of each cue, in Cue's order: the first of sfx.parts and how many
; (0: none; the cues added with the card have none, but the dead key's tick). The chain
; cards' borrow the sound they replace in their steps (Mimic and Scratching Habit the zap,
; Mirror Fur and Lucky Paw the ping, Sunbeam and Double or Nothing the chime), and the curses'
; have none (the curse's hiss follows them), so the speaker holds the processor no longer. The
; faces round's have their own parts, each no longer than the sound its cue first borrowed (the
; splash the puff's, the thunder the hit's, the slurp and the sparkle the chime's, the snore the
; wobble's, the whoosh the zap's), and the buzz and the boing none, as the hops and the blip
(const SPEAKER_FIRST (array u8 35)
    (make (array u8 35)
        0 0 3 4 6 8 10 11 15 16 18 0 0 0 0 0 19 25 0 3 0 6 6 0 8 3 8 0 27 28 30 32 0 33 34)
    :in aux)

(const SPEAKER_COUNT (array u8 35)
    (make (array u8 35) 3 0 1 2 2 2 1 4 1 2 1 0 0 0 0 0 1 2 0 1 0 2 2 0 2 1 2 0 1 2 2 1 0 1 3)
    :in aux)

; the card's effects are in aux memory (card_fx), and the card's handler plays them from main
; memory: each is copied into one of these buffers as it is cued, the next in turn. Every cue
; goes in at one priority, so lib/mockingboard plays them in the order they come, one playing and
; at most LINE waiting: the buffer a cue takes was the one of the cue LINE + 1 before it, over by
; then. A cue the full line would drop takes none (cue_byte)
(const FX_BUFFERS u8 5)        ; player.LINE + 1
(let fx_buffers (array u8 85)) ; FX_BUFFERS of fx.MOST
(let fx_at u8 0)               ; the next cue's buffer, its first byte in fx_buffers

; cue number c: on the card, its effect on its voice (dropped while another plays if it does
; not wait); without one, its speaker parts. The cues' tables are in aux memory (main memory is
; full), read here with one with_aux; a card's steps name their sounds by number (content/play)
(fn cue_byte ((c u8)) void
    (let first u8 0)
    (let count u8 0)
    (let waits bool false)
    (let voice u8 0)
    (let effect (ptr u8) (as (ptr u8) 0))
    (with_aux true false
        (set first (at SPEAKER_FIRST c))
        (set count (at SPEAKER_COUNT c))
        (set waits (at CUE_WAITS c))
        (set voice (at CUE_VOICE c))
        (set effect (at CARD_EFFECT c)))
    (if (not mb.found)
        (do
            (sfx.play first count)
            (return)))
    (if (and (not waits) (mb.effect_playing))
        (return))
    ; the tick held off from here until the effect is in line: the copy never makes it start a
    ; tick later (the tick due meanwhile comes as mb.effect is done, and starts it)
    (sei)
    (if (= player.line_count player.LINE)
        (do
            (cli)
            (return)))
    (let to (ptr u8) (+ (addr_of (at fx_buffers 0)) (as u16 fx_at)))
    (with_aux true false
        (let i u8 0)
        (while true
            (let b u8 (load (+ effect i)))
            (store (+ to i) b)
            (if (= b tune.END)
                (break))
            (set i (+ i 1))))
    (set fx_at (+ fx_at fx.MOST))
    (if (= fx_at (* FX_BUFFERS fx.MOST))
        (set fx_at 0))
    (mb.effect to voice 1))

(fn cue ((c Cue)) void
    (cue_byte (as u8 c)))

; each song's table on the disk, in Song's order (aux memory is full)
(const SONG_BYTES (array (ptr u8) 4)
    (make (array (ptr u8) 4)
        (addr_of (at songs.TITLE 0))
        (addr_of (at songs.BATTLE 0))
        (addr_of (at songs.WON 0))
        (addr_of (at songs.LOST 0))))

; the music fades out and stops (lib/mockingboard's fade, 1 s): as a run starts (the title's
; key), so the title's song is fading while the second disk is found and the fight's code read,
; and in every song. With no card it does nothing
(fn quiet () void
    (mb.fade 15))

; a song from its start. On the card: the song before fades out (quiet) while the new one is
; read from the disk into aux memory's text page 1 (the rules page's buffer, which reads its
; page again when it opens), and waiting.start plays it once the one before is silent: from the
; main loop, or between the sectors of a load (a screen's song, called as its load begins: the
; fight's at enter_fight's start, the title's at its enter), so the game goes on while it fades
; (the run's end: the battle's song under the banner). A second song while one waits takes its
; place in the buffer. Nothing else reads into the buffer in the second a song can wait (the
; rules page and a hat trick's face come in her turn, disk 2's label before the first fight's
; song, and at the first title, whose song never waits). On the speaker, the title's jingle and
; the battle's ends
(fn song ((s Song)) void
    (if (not mb.found)
        (do
            ; (the title's jingle: title.step)
            (match s
                (Song.won (sfx.win))
                (Song.lost (sfx.lose))
                (_))
            (return)))
    (quiet)
    ; the title's from the first disk until the second is found (a machine with one drive has
    ; the second in it then)
    (let table (ptr u8) (at SONG_BYTES (as u8 s)))
    (if (and (= s Song.title) disk2.found)
        (set table (addr_of (at songs.TITLE2 0))))
    (meter.read (as (ptr u8) state.aux_page1) table)
    (set waiting.waits (+ (at FADE_FROM (as u8 s)) 1))
    (waiting.start))
