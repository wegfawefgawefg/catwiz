; drawing in whole colour pixels, a row at a time: a stretch of a page's row is read into
; pixels (one byte each, a colour 0-15), or started blank, drawn on, and written back
; (lib/dhgr_pixels). A stretch is n 7-pixel
; groups from group g0 (byte columns 2 * g0 on), so it ends on whole bytes. The hud (badges,
; the tray, the text lines) is drawn this way; sprites are not (draw/blit).
;
; a group's 7 pixels are its 4 bytes' 28 dots, aux byte, main byte, aux, main: pixel p is dots
; 4p to 4p + 3 (its colour's bits 0-3), bit 0 the leftmost dot of a byte.

(import auxmem)
(import dhgr_pixels)
(import art/hud_data hud)
(import draw/screen)

(const MOST_GROUPS u8 20)

; scratch: see AGENTS.md, Memory
(let px (array u8 140) :address 0x0B00)
(let aux_bytes (array u8 40) :address 0x0B90)
(let main_bytes (array u8 40) :address 0x0BB8)

; the stretch: its first group and how many, its first pixel and how many
(let first u8 0)
(let groups u8 0)
(let origin u8 0)
(let width u8 0)

(fn begin ((g0 u8) (n u8)) void
    (set first g0)
    (set groups n)
    (set origin (* g0 7))
    (set width (* n 7)))

; the stretch of row y of page as pixels
(fn read ((page u8) (y u8)) void
    (let count u8 (<< groups 1))
    (let p (ptr u8) (as (ptr u8) (screen.row_at page y (<< first 1))))
    (for i u8 0 count
        (set (at main_bytes i) (load (+ p i))))
    (auxmem.read (addr_of (at aux_bytes 0)) p (as u16 count))
    (let k u8 0)
    (let x u8 0)
    (while (< x width)
        (let b0 u8 (at aux_bytes k))
        (let b1 u8 (at main_bytes k))
        (let b2 u8 (at aux_bytes (+ k 1)))
        (let b3 u8 (at main_bytes (+ k 1)))
        (set (at px x) (& b0 15))
        (set (at px (+ x 1)) (| (>> b0 4) (<< (& b1 1) 3)))
        (set (at px (+ x 2)) (& (>> b1 1) 15))
        (set (at px (+ x 3)) (| (>> b1 5) (<< (& b2 3) 2)))
        (set (at px (+ x 4)) (& (>> b2 2) 15))
        (set (at px (+ x 5)) (| (>> b2 6) (<< (& b3 7) 1)))
        (set (at px (+ x 6)) (>> b3 3))
        (set k (+ k 2))
        (set x (+ x 7))))

; the pixels back onto row y of page (lib/dhgr_pixels)
(fn write ((page u8) (y u8)) void
    (dhgr_pixels.row page (<< first 1) y groups (addr_of (at px 0))))

; pixels x0 to x1 - 1 (screen pixels) in colour c, as far as they are in the stretch
(fn span ((x0 u8) (x1 u8) (c u8)) void
    (let end u8 (+ origin width))
    (if (< x0 origin)
        (set x0 origin))
    (if (> x1 end)
        (set x1 end))
    (if (>= x0 x1)
        (return))
    (for i u8 (- x0 origin) (- x1 origin)
        (set (at px i) c)))

; one pixel, if it is in the stretch
(fn dot ((x u8) (c u8)) void
    (if (and (>= x origin) (< x (+ origin width)))
        (set (at px (- x origin)) c)))

; the whole stretch in colour c
(fn fill ((c u8)) void
    (for x u8 0 width
        (set (at px x) c)))

; row r (0-5) of hud glyph code at x: its pixels in its own colour, or in ink for a letter or
; digit; gives the x after it and a pixel's gap
(fn glyph ((x u8) (code u8) (r u8) (ink u8)) u8
    (let at u16 (<< (as u16 (- code 32)) 3))
    (let w u8 (at hud.HUD_FONT at))
    (let c u8 (at hud.HUD_FONT (+ at 1)))
    (if (= c 0)
        (set c ink))
    (let bits u8 (at hud.HUD_FONT (+ at (as u16 (+ r 2)))))
    (if (or (= bits 0) (< x origin))
        (return (+ (+ x w) 1)))
    (let i u8 (- x origin))
    (while (!= bits 0)
        (if (and (!= (& bits 1) 0) (< i width))
            (set (at px i) c))
        (set bits (>> bits 1))
        (set i (+ i 1)))
    (+ (+ x w) 1))

; how wide a string of hud glyphs is, without the last gap
(fn glyphs_width ((s (ptr u8)) (n u8)) u8
    (let w u8 0)
    (for i u8 0 n
        (let at u16 (* (as u16 (- (load (+ s i)) 32)) 8))
        (set w (+ (+ w (at hud.HUD_FONT at)) 1)))
    (- w 1))

; row r of n hud glyphs from s at x
(fn glyphs ((x u8) (s (ptr u8)) (n u8) (r u8) (ink u8)) void
    (for i u8 0 n
        (set x (glyph x (load (+ s i)) r ink))))
