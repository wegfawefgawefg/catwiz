; the three hi-res pages: page 1 at $2000 and page 2 at $4000 take turns on screen, and the
; backdrop page at $6000 holds the clean picture everything is drawn over. A page is named by
; how far it sits past page 1, in pages of 256 bytes: PAGE_1, PAGE_2 or BACKDROP, so the
; address of row y on it is (at hgr.ROW y) plus that many pages.

(import apple2 a2)
(import hgr)
(import auxmem)

(let page2 (array u8 8192) :address a2.HGR_PAGE2 :reserve)
(let backdrop_page (array u8 8192) :address 0x6000 :reserve)

(const PAGE_1 u8 0x00)
(const PAGE_2 u8 0x20)
(const BACKDROP u8 0x40)

; the page being drawn, which is not the one on screen, and its number (0 or 1)
(let back u8 PAGE_2)
(let back_index u8 1)

; the address of byte column col of row y on page
(fn row_at ((page u8) (y u8) (col u8)) (ptr u8)
    (let row u16 (at hgr.ROW y))
    (as (ptr u8) (+ (+ row (<< (as u16 page) 8)) (as u16 col))))

(fn page_start ((page u8)) (ptr u8)
    (as (ptr u8) (+ a2.HGR_PAGE1 (<< (as u16 page) 8))))

; graphics, full screen, page 1 on, page 2 drawn next
(fn setup () void
    (io_read u8 a2.TXTCLR)
    (io_read u8 a2.MIXCLR)
    (io_read u8 a2.HIRES)
    (show_page_1))

(fn show_page_1 () void
    (io_read u8 a2.LOWSCR)
    (set back PAGE_2)
    (set back_index 1))

(fn show_page_2 () void
    (io_read u8 a2.HISCR)
    (set back PAGE_1)
    (set back_index 0))

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
    (if (= back PAGE_2)
        (show_page_2)
        (show_page_1)))

; 8 KB from aux memory onto a page
(fn load_page ((page u8) (picture (ptr u8))) void
    (auxmem.read (page_start page) picture 8192))

; one page copied onto another, whole
(fn copy_page ((from u8) (to u8)) void
    (let src (ptr u8) (page_start from))
    (let dst (ptr u8) (page_start to))
    (for i u16 0 8192
        (store (+ dst i) (load (+ src i)))))

; every byte of a page the same
(fn fill_page ((page u8) (value u8)) void
    (let dst (ptr u8) (page_start page))
    (for i u16 0 8192
        (store (+ dst i) value)))
