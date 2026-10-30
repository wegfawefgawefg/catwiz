; small hud drawing onto the backdrop page, at any pixel: black or white boxes and 5x7 glyphs
; with every dot 2 px wide (a lone hi-res pixel shows as colour, two side by side as white),
; white on black and black on white. Callers mark what they drew for copying to the screen
; (draw/scene.tsp, mark).

(import hgr)
(import tables)
(import art/sprites art)
(import draw/screen)

(const GLYPH_W u16 12) ; a glyph is 10 px wide, then a 2-px gap
(const GLYPH_H u8 7)

; pixels x0 to x1 - 1 of row y on the backdrop, all off, or all on for white
(fn clear_row ((x0 u16) (x1 u16) (y u8) (white bool)) void
    (let first u8 (screen.byte_of x0))
    (let last u8 (screen.byte_of (- x1 1)))
    (let row (ptr u8) (screen.row_at screen.BACKDROP y 0))
    ; the dots of the first and last byte that are in the run
    (let keep_left u8 (- (screen.bit_of x0) 1))
    (let keep_right u8 (& (~ (- (<< (screen.bit_of (- x1 1)) 1) 1)) 0x7F))
    (let ink u8 (if white
        0x7F
        0))
    (if (= first last)
        (do
            (set_bits (+ row first) (| keep_left keep_right) ink)
            (return)))
    (set_bits (+ row first) keep_left ink)
    (for col u8 (+ first 1) last
        (store (+ row col) ink))
    (set_bits (+ row last) keep_right ink))

; the byte at p: the dots in keep stay, the others take ink's
(fn set_bits ((p (ptr u8)) (keep u8) (ink u8)) void
    (store p (| (& (load p) (| keep 0x80)) (& ink (~ keep)))))

; a black (or white) box from x0, y0 up to x1, y1, its corners rounded off
(fn capsule ((x0 u16) (y0 u8) (x1 u16) (y1 u8) (white bool)) void
    (for y u8 y0 y1
        (let inset u16 0)
        (if (or (= y y0) (= y (- y1 1)))
            (set inset 2))
        (if (or (= y (+ y0 1)) (= y (- y1 2)))
            (set inset 1))
        (clear_row (+ x0 inset) (- x1 inset) y white)))

; a glyph row of 5 dots as 10 pixels, each dot doubled: bit 2i and 2i + 1 for dot i
(macro doubled (bits)
    (let out 0)
    (for i 0 5
        (if (!= (& bits (<< 1 i)) 0)
            (set out (| out (<< 3 (* 2 i))))))
    out)

(tables.table DOUBLED u16 32 doubled)

; one glyph, its top-left at x, y: its dots flip what is there, so it is white on black and
; black on white. Codes 32 to 90: ' ' to 'Z' and the icons in it. Each row's 10 pixels are
; shifted into the 7-pixel bytes they fall in, up to three of them
(fn glyph ((x u16) (y u8) (code u8)) void
    (let at_row u16 (* (as u16 (- code 32)) 7))
    (let col u8 (screen.byte_of x))
    (let shift u8 (as u8 (- x (* (as u16 col) 7))))
    (for r u8 0 GLYPH_H
        (let bits u16 (<< (at DOUBLED (at art.FONT (+ at_row (as u16 r)))) shift))
        (let p (ptr u8) (screen.row_at screen.BACKDROP (+ y r) col))
        (store p (^ (load p) (& (as u8 bits) 0x7F)))
        (store (+ p 1) (^ (load (+ p 1)) (& (as u8 (>> bits 7)) 0x7F)))
        (if (>= bits 0x4000)
            (store (+ p 2) (^ (load (+ p 2)) (as u8 (>> bits 14)))))))

; a zero-terminated string; gives the x after it
(fn text ((x u16) (y u8) (s (ptr u8))) u16
    (let px u16 x)
    (let i u8 0)
    (while (!= (load (+ s i)) 0)
        (glyph px y (load (+ s i)))
        (set px (+ px GLYPH_W))
        (set i (+ i 1)))
    px)

(fn text_width ((s (ptr u8))) u16
    (let n u16 0)
    (let i u8 0)
    (while (!= (load (+ s i)) 0)
        (set n (+ n GLYPH_W))
        (set i (+ i 1)))
    (- n 2))
