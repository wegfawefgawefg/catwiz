; what the game needs from the machine: a IIe with 128 KB, since the pictures live in aux
; memory. Checked before anything touches aux memory, without lib/auxmem: its mover runs from
; aux memory, which a 64 KB machine does not have.

(import apple2 a2)

(const PROBE u16 0x0400) ; text page 1, which the game never shows

; with 80STORE on, PAGE2 sends $0400-$07FF to aux memory: a byte written there must still
; be there after a different one is written to main memory at the same address
(fn has_aux () bool
    (io_write u8 a2.SET80STORE 0)
    (io_read u8 a2.HISCR)
    (io_write u8 PROBE 0xA5)
    (io_read u8 a2.LOWSCR)
    (io_write u8 PROBE 0x5A)
    (io_read u8 a2.HISCR)
    (let seen u8 (io_read u8 PROBE))
    (io_read u8 a2.LOWSCR)
    (io_write u8 a2.CLR80STORE 0)
    (= seen 0xA5))

; one line of the 40-column text screen, at text row 20 + r: s in normal characters
(fn say ((r u8) (s (ptr u8))) void
    (let row u16 (+ 0x0650 (* (as u16 r) 0x80)))
    (let i u8 0)
    (while (!= (load (+ s i)) 0)
        (io_write u8 (+ row (as u16 i)) (| (load (+ s i)) 0x80))
        (set i (+ i 1))))

; say what is missing, at the foot of a blank text screen, and stay there
(fn refuse () void
    (io_read u8 a2.TXTSET)
    (io_read u8 a2.LOWSCR)
    (for i u16 0 0x0400
        (io_write u8 (+ PROBE i) 0xA0))
    (say 1 "CATWIZ NEEDS A 128K APPLE IIE")
    (say 2 "(AN EXTENDED 80-COLUMN CARD)")
    (while true))
