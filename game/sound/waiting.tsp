; the song waiting to start: sound.song reads it from the disk into aux memory's text page 1
; (state.aux_page1) while the one before fades out, and start plays it once that one is silent. start is called
; every pass of the main loop and between the sectors of every disk read (draw/meter), so in a
; screen's load too: a song started as the load begins plays through the rest of it (Tisple's
; card unpacks let the card's tick in, docs/dhgr.md "Packed data").

(import auxmem)
(import mockingboard mb)
(import state)

; the song the card plays, copied from aux memory: the largest song's size (the title's and the
; house's, 395), and each song is copied whole at this size; the bytes after a smaller one in aux
; memory come too. Main memory is full: a bigger song wants room found first (AGENTS.md, Sound)
(const PLAYING u16 395)
(let playing (array u8 395) :address 0x0800) ; scratch: see AGENTS.md, Memory

; the song in buffer waiting for the one before to be silent: the steps down its fade in starts
; from, and 1; 0 for none
(let waits u8 0)

; the song waiting, once the one before is silent and stopped: copied into main memory with
; interrupts off (about 6,500 cycles, so it delays a tick and loses none), played, faded in.
; About 8,000 cycles in all: in a disk read's step (draw/meter) it can cost the read a sector's
; time (0.7 frame), once a song
(fn start () void
    (if (or (= waits 0) (not (mb.faded)))
        (return))
    (let from u8 (- waits 1))
    (set waits 0)
    (sei)
    (auxmem.read (addr_of (at playing 0)) (as (ptr u8) state.aux_page1) PLAYING)
    (mb.play (addr_of (at playing 0)))
    (mb.fade_in from))
