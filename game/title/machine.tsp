; what the game needs from the machine: a IIe with 128 KB, since the pictures live in aux
; memory. Checked before anything touches aux memory, without lib/auxmem: its mover runs from
; aux memory, which a 64 KB machine does not have.

(import apple2 a2)
(import text40)

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

; say what is missing, and stay there
(fn refuse () void
    (text40.on)
    (text40.move 4 10)
    (text40.print "WITCHDOG NEEDS A 128K APPLE IIE")
    (text40.move 9 12)
    (text40.print "(AN EXTENDED 80-COLUMN CARD)")
    (while true))
