; the double hi-res pages (lib/dhgr), the whole screen graphics: page 1 at $2000 shown and drawn
; on, page 2 at $4000 where pictures are unpacked. Each is 8 KB of main memory and 8 KB of aux
; memory at the same addresses; a page is named by its high byte (dhgr.PAGE1, dhgr.PAGE2), so
; row y of it is (at dhgr.ROW y) plus that many pages less $20. There is no backdrop page (the
; midnight stage: what a look leaves is black, draw/scene.tsp).

(import apple2 a2)
(import dhgr)
(import unpack)

; the one page drawn and shown: every change goes straight onto the screen (draw/scene), drawn
; once, with nothing to wait for. A picture is unpacked onto SPARE and copied over, so it never
; shows half made
(const PAGE u8 dhgr.PAGE1)
(const SPARE u8 dhgr.PAGE2)

; the address of byte column col of row y on page, in the memory it is read from
(fn row_at ((page u8) (y u8) (col u8)) u16
    (+ (+ (at dhgr.ROW y) (<< (as u16 (- page dhgr.PAGE1)) 8)) (as u16 col)))

; graphics, the whole screen, the page on (the title turns it on once its picture is there)
(fn on () void
    (dhgr.show PAGE)
    (dhgr.on false))

; false only to measure frame costs: frames then run as fast as they can
(const WAIT_FOR_BLANK bool true)

; wait for the start of the next vertical blank (RDVBLBAR bit 7 is 0 during it on a IIe)
(fn wait_frame () void
    (if (not WAIT_FOR_BLANK)
        (return))
    (while (< (io_read u8 a2.RDVBLBAR) 0x80))
    (while (>= (io_read u8 a2.RDVBLBAR) 0x80)))

; a box of page from copied onto page, both memories
(fn copy_box ((page u8) (col u8) (top u8) (cols u8) (rows u8) (from u8)) void
    (dhgr.copy_box page dhgr.AUX col top cols rows from)
    (dhgr.copy_box page dhgr.MAIN col top cols rows from))

; one page copied onto another, whole
(fn copy_page ((from u8) (to u8)) void
    (copy_box to 0 0 40 192 from))

; a screen packed in aux memory (its two halves, art/NAME_aux and NAME_main) onto page
(fn unpack_page ((page u8) (aux (ptr u8)) (main (ptr u8))) void
    (let at (ptr u8) (as (ptr u8) (<< (as u16 page) 8)))
    (unpack.aux_to_aux at aux)
    (unpack.aux_to_main at main))
