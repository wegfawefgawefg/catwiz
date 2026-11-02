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
; interrupts on: main puts in lib/auxmem's guard.

(import auxmem)
(import mockingboard mb)
(import sound/sfx)
(import sound/music)
(import sound/card_fx fx)
(import sound/songs)
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
        coin))    ; Double or Nothing

(enum Song (title battle won lost))

; the voice each cue borrows: 2, the pad on the left chip, for the hero's side, and 5, the
; shaker on the right chip, for the enemies'. The hero stands on the left of the screen.
(const CUE_VOICE (array u8 27)
    (make (array u8 27) 2 2 2 5 5 2 5 5 2 5 2 5 2 2 2 2 2 2 5 2 5 2 2 5 2 5 2)
    :in aux)

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

; at the start: find the card, if there is one, and start its tick (main puts lib/auxmem's guard
; in first, which lets aux copies run while it ticks)
(fn setup () void
    (mb.init))

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
    (mb.effect effect voice 1))

(fn cue ((c Cue)) void
    (cue_byte (as u8 c)))

; each song's table on the disk, in Song's order (aux memory is full)
(const SONG_BYTES (array (ptr u8) 4)
    (make (array (ptr u8) 4)
        (addr_of (at songs.TITLE 0))
        (addr_of (at songs.BATTLE 0))
        (addr_of (at songs.WON 0))
        (addr_of (at songs.LOST 0))))

; no song for a moment: before a screen's art unpacks into the aux language card with
; interrupts off, which would hold the notes playing
(fn quiet () void
    (if mb.found
        (mb.stop)))

; a song from its start: on the card, read from the disk into aux memory's text page 1 (the
; rules page's buffer, which reads its page again when it opens) with the song before stopped,
; then copied into main memory with interrupts off (the handler would read the song playing
; while it changes; about 6,500 cycles, so it delays a tick and loses none) and played; on the
; speaker, the title's jingle and the battle's ends. A song starts with a screen (a read of a
; sector or two, as the screen loads anyway) or at the run's end
; a let, not a constant pointer: the layout checks a constant one against main memory's lets
; there, which aux memory's bytes are not
(let song_buffer u16 0x0400)

(fn song ((s Song)) void
    (if (not mb.found)
        (do
            (match s
                (Song.title (music.jingle))
                (Song.won (sfx.win))
                (Song.lost (sfx.lose))
                (_))
            (return)))
    (mb.stop)
    ; the title's from the first disk until the second is found (a machine with one drive has
    ; the second in it then)
    (let table (ptr u8) (at SONG_BYTES (as u8 s)))
    (if (and (= s Song.title) disk2.found)
        (set table (addr_of (at songs.TITLE2 0))))
    (meter.read (as (ptr u8) song_buffer) table)
    (sei)
    (auxmem.read (addr_of (at playing 0)) (as (ptr u8) song_buffer) PLAYING)
    (mb.play (addr_of (at playing 0))))
