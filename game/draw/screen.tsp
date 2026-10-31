; the double hi-res pages (lib/dhgr): page 1 at $2000 and page 2 at $4000 take turns on screen,
; the whole screen graphics. Each is 8 KB of main memory and 8 KB of aux memory at the same
; addresses; a page is named by its high byte (dhgr.PAGE1, dhgr.PAGE2), so row y of it is
; (at dhgr.ROW y) plus that many pages less $20. There is no backdrop page (the midnight stage:
; what a look leaves is black, and the hud is drawn onto the page being drawn and copied from
; it onto the other, draw/scene.tsp).

(import apple2 a2)
(import dhgr)
(import unpack)

; the page being drawn, which is not the one on screen, and its number (0 or 1)
(let back u8 dhgr.PAGE2)
(let back_index u8 1)

; the page on screen
(fn front () u8
    (if (= back dhgr.PAGE2)
        dhgr.PAGE1
        dhgr.PAGE2))

; the address of byte column col of row y on page, in the memory it is read from
(fn row_at ((page u8) (y u8) (col u8)) u16
    (+ (+ (at dhgr.ROW y) (<< (as u16 (- page dhgr.PAGE1)) 8)) (as u16 col)))

; graphics, the whole screen, page 1 on, page 2 drawn next (the title turns it on once its
; picture is on both pages)
(fn on () void
    (dhgr.show dhgr.PAGE1)
    (dhgr.on false)
    (set back dhgr.PAGE2)
    (set back_index 1))

; false only to measure frame costs: frames then run as fast as they can
(const WAIT_FOR_BLANK bool true)

; wait for the start of the next vertical blank (RDVBLBAR bit 7 is 0 during it on a IIe)
(fn wait_frame () void
    (if (not WAIT_FOR_BLANK)
        (return))
    (while (< (io_read u8 a2.RDVBLBAR) 0x80))
    (while (>= (io_read u8 a2.RDVBLBAR) 0x80)))

; at the next vertical blank, show the page just drawn
(fn flip () void
    (wait_frame)
    (dhgr.show back)
    (set back (dhgr.hidden))
    (set back_index (if (= back dhgr.PAGE2)
        1
        0)))

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
