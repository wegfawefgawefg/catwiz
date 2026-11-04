; the song waiting to start: sound.song reads it from the disk into the language card's bank 1
; (room, below) while the one before fades out, and start plays it there once that one is
; silent. start is called every pass of the main loop and between the sectors of every disk read
; (draw/meter), so in a screen's load too: a song started as the load begins plays through the
; rest of it (Tisple's card unpacks let the card's tick in, docs/dhgr.md "Packed data").

(import mockingboard mb)

; the songs' room, in the card's bank 1 (Tisple's :in bank1: main memory is full, and bank 1 has
; room above its code): two halves, each the biggest song's size (the King's, KING, 895 bytes).
; The song playing is in one, and the next is read into the other (sound.song, sound.lose; a
; song read while another waits takes its place there). The player reads the song where it is
; (mb.play_bank1): nothing is copied (AGENTS.md, Sound)
(const HALF u16 895)
(let room (array u8 1790) :in bank1)

; the half the next song is read into: the one the song playing is not in
(let next (ptr u8) (addr_of (at room 0)))

; the song in next waiting for the one before to be silent: the steps down its fade in starts
; from, and 1; 0 for none. A read into next sets it to 0 first, so a song is never started half
; read (the read's sector steps call start)
(let waits u8 0)

; the song waiting, once the one before is silent and stopped: played where it is, faded in,
; and the next song's half is the other. About 1,000 cycles (nothing to copy)
(fn start () void
    (if (or (= waits 0) (not (mb.faded)))
        (return))
    (let from u8 (- waits 1))
    (set waits 0)
    (mb.play_bank1 next)
    (set next (if (= next (addr_of (at room 0)))
        (addr_of (at room HALF))
        (addr_of (at room 0))))
    (mb.fade_in from))
