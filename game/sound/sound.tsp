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
; The songs live in aux memory (songs.tsp); the one playing is copied into playing, with
; interrupts on: setup puts in lib/auxmem's guard.

(import auxmem)
(import mockingboard mb)
(import sound/sfx)
(import sound/music)
(import sound/card_fx fx)
(import sound/songs)

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
        coin))    ; Double or Nothing

(enum Song (title battle won lost))

; the voice each cue borrows: 2, the pad on the left chip, for the hero's side, and 5, the
; shaker on the right chip, for the enemies'. The hero stands on the left of the screen.
(const CUE_VOICE (array u8 27)
    (make (array u8 27) 2 2 2 5 5 2 5 5 2 5 2 5 2 2 2 2 2 2 5 2 5 2 2 5 2 5 2)
    :in aux) ; the cues' tables are in aux memory (main memory is full): read by cue_row

; whether a cue waits in line while another effect plays; false: dropped
(const CUE_WAITS (array bool 27)
    (make (array bool 27)
        false true true true true true true true true true true true true true false true false
        false true true true true true true true true true)
    :in aux)

; the song the card plays, copied from aux memory: the largest song's size (the title's), and
; each song is copied whole at this size; the bytes after a smaller one in aux memory come too
(const PLAYING u16 395)
(let playing (array u8 395) :address 0x0800) ; scratch: see AGENTS.md, Memory

; at the start: find the card, if there is one, and start its tick; the guard lets aux copies
; run while it ticks
(fn setup () void
    (mb.init)
    (auxmem.guard))

; the card's effect for each cue, in Cue's order
(const CARD_EFFECT (array (ptr u8) 27)
    (make (array (ptr u8) 27)
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
        (addr_of (at fx.coin 0)))
    :in aux)

; the speaker's version of each cue, in Cue's order: the first of sfx.parts and how many
; (0: none; the cues added with the card have none, but the dead key's tick). The chain
; cards' borrow the sound they replace in their steps (Mimic and Scratching Habit the zap,
; Mirror Fur and Lucky Paw the ping, Sunbeam and Double or Nothing the chime), and the curses'
; have none (the curse's hiss follows them), so the speaker holds the processor no longer
(const SPEAKER_FIRST (array u8 27)
    (make (array u8 27) 0 0 3 4 6 8 10 11 15 16 18 0 0 0 0 0 19 25 0 3 0 6 6 0 8 3 8)
    :in aux)

(const SPEAKER_COUNT (array u8 27)
    (make (array u8 27) 3 0 1 2 2 2 1 4 1 2 1 0 0 0 0 0 1 2 0 1 0 2 2 0 2 1 2)
    :in aux)

; cue c's row of the tables, read from aux memory into these
(let row_effect (ptr u8))
(let row_voice u8)
(let row_waits bool)
(let row_first u8)
(let row_count u8)

(fn cue_row ((c u8)) void
    (with_aux true false
        (set row_effect (at CARD_EFFECT c))
        (set row_voice (at CUE_VOICE c))
        (set row_waits (at CUE_WAITS c))
        (set row_first (at SPEAKER_FIRST c))
        (set row_count (at SPEAKER_COUNT c))))

; cue c: on the card, or on the speaker without one
(fn cue ((c Cue)) void
    (cue_byte (as u8 c)))

; the same for cue number c (a card's steps name their sounds by number: content/play)
(fn cue_byte ((c u8)) void
    (cue_row c)
    (if (not mb.found)
        (do
            (sfx.play row_first row_count)
            (return)))
    (if (and (not row_waits) (mb.effect_playing))
        (return))
    (mb.effect row_effect row_voice 1))

; each song in aux memory, in Song's order
(const SONG_BYTES (array (ptr u8) 4)
    (make (array (ptr u8) 4)
        (addr_of (at songs.title 0))
        (addr_of (at songs.battle 0))
        (addr_of (at songs.won 0))
        (addr_of (at songs.lost 0))))

; no song for a moment: before a screen's art unpacks into the aux language card with
; interrupts off, which would hold the notes playing
(fn quiet () void
    (if mb.found
        (mb.stop)))

; a song from its start: on the card, copied in from aux memory with interrupts off (the
; handler would read the song playing while it changes; about 6,500 cycles, so it delays a tick
; and loses none) and played; on the speaker, the title's jingle and the battle's ends
(fn song ((s Song)) void
    (if (not mb.found)
        (do
            (match s
                (Song.title (music.jingle))
                (Song.won (sfx.win))
                (Song.lost (sfx.lose))
                (_))
            (return)))
    (sei)
    (auxmem.read (addr_of (at playing 0)) (at SONG_BYTES (as u8 s)) PLAYING)
    (mb.play (addr_of (at playing 0))))
