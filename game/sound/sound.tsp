; every sound the game makes goes through here, the one place that picks the Mockingboard or the
; speaker: (sound.cue Cue.bark) for an effect, (sound.song Song.battle) for the music.
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

(enum Cue (bark  ; the dog barks
        rattle   ; one shake of the dice
        tok      ; a die played
        zap      ; a magic bolt lands
        thump    ; a blow lands on an enemy
        ping     ; a shield takes a blow, or goes up
        chime    ; hit points back
        hiss     ; a fire catches
        wobble   ; spooked
        puff     ; a die that does nothing
        squeak   ; someone beaten
        yelp     ; the dog hurt
        growl    ; an enemy starts its move
        turn_on  ; the dog's turn begins
        turn_off ; and ends
        blip     ; the target moves
        confirm  ; RETURN on the title
        nope))   ; a key that does nothing now

(enum Song (title battle won lost))

; the voice each cue borrows: 2, the pad on the left chip, for the dog's side, and 5, the
; shaker on the right chip, for the enemies'. The dog stands on the left of the screen.
(const CUE_VOICE (array u8 18) (make (array u8 18) 2 2 2 2 5 5 2 5 5 2 5 2 5 2 2 2 2 2))

; whether a cue waits in line while another effect plays; false: dropped
(const CUE_WAITS (array bool 18)
    (make (array bool 18)
        true false true true true true true true true true true true true true true false
        true false))

; the song the card plays, copied from aux memory: the largest song's size (the title's), and
; each song is copied whole at this size; the bytes after a smaller one in aux memory come too
(const PLAYING u16 395)
(let playing (array u8 395))

; at the start: find the card, if there is one, and start its tick; the guard lets aux copies
; run while it ticks
(fn setup () void
    (mb.init)
    (auxmem.guard))

; the card's effect for each cue (a table of the addresses would be smaller, but a let's
; values must be constants, and an address is not one yet)
(fn card_effect ((c Cue)) (ptr u8)
    (match c
        (Cue.bark (addr_of (at fx.bark 0)))
        (Cue.rattle (addr_of (at fx.rattle 0)))
        (Cue.tok (addr_of (at fx.tok 0)))
        (Cue.zap (addr_of (at fx.zap 0)))
        (Cue.thump (addr_of (at fx.thump 0)))
        (Cue.ping (addr_of (at fx.ping 0)))
        (Cue.chime (addr_of (at fx.chime 0)))
        (Cue.hiss (addr_of (at fx.hiss 0)))
        (Cue.wobble (addr_of (at fx.wobble 0)))
        (Cue.puff (addr_of (at fx.puff 0)))
        (Cue.squeak (addr_of (at fx.squeak 0)))
        (Cue.yelp (addr_of (at fx.yelp 0)))
        (Cue.growl (addr_of (at fx.growl 0)))
        (Cue.turn_on (addr_of (at fx.turn_on 0)))
        (Cue.turn_off (addr_of (at fx.turn_off 0)))
        (Cue.blip (addr_of (at fx.blip 0)))
        (Cue.confirm (addr_of (at fx.confirm 0)))
        (Cue.nope (addr_of (at fx.nope 0)))))

; the cue on the card now
(fn card_play ((c Cue)) void
    (mb.effect (card_effect c) (at CUE_VOICE (as u8 c)) 1))

; the speaker's version; the cues added with the card have none, but the dead key's tick
(fn speaker ((c Cue)) void
    (match c
        (Cue.bark (sfx.bark))
        (Cue.rattle (sfx.rattle))
        (Cue.zap (sfx.zap))
        (Cue.thump (sfx.hit))
        (Cue.ping (sfx.ping))
        (Cue.chime (sfx.chime))
        (Cue.hiss (sfx.hiss))
        (Cue.wobble (sfx.wobble))
        (Cue.puff (sfx.puff))
        (Cue.squeak (sfx.squeak))
        (Cue.yelp (sfx.yelp))
        (Cue.nope (sfx.tick))
        (_)))

(fn cue ((c Cue)) void
    (if (not mb.found)
        (do
            (speaker c)
            (return)))
    (if (and (not (at CUE_WAITS (as u8 c))) (mb.effect_playing))
        (return))
    (card_play c))

(fn song_bytes ((s Song)) (ptr u8)
    (match s
        (Song.title (addr_of (at songs.title 0)))
        (Song.battle (addr_of (at songs.battle 0)))
        (Song.won (addr_of (at songs.won 0)))
        (Song.lost (addr_of (at songs.lost 0)))))

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
    (auxmem.read (addr_of (at playing 0)) (song_bytes s) PLAYING)
    (mb.play (addr_of (at playing 0))))
