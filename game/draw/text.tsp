; the four lines of text at the foot of the screen, drawn into the picture (rows 160-191 of the
; backdrop page, then copied onto both pages as any hud part is). A line is built in line, then
; shown. The font is the 35-column one in whole colour pixels (white in every look: a glyph is 3
; pixels of a 4-pixel cell); FONT_35 false draws the 40-column dot font instead (white in NTSC,
; violet and green in the flat colour look), with strings of 35 at most either way.
;
; strings are plain ASCII; inverse (set while adding) draws them dark on a light block. A # in a
; string stands for the number given to add_n.

(import auxmem)
(import art/hud_data hud)
(import art/font40)
(import draw/screen)
(import draw/pix)
(import dhgr_pixels)
(import draw/scene)

(const FONT_35 bool true) ; the one place the text's font is chosen
(const COLUMNS u8 35)
(const ROWS u8 4)
(const TOP u8 160) ; the first text row on the screen
(const INVERSE u8 0x80)

; the line being built, as ASCII with INVERSE set for inverse, and where the next character
; goes; and what each line on the screen shows, so an unchanged one is not drawn again
(let line (array u8 35) :address 0x09E0) ; scratch: see AGENTS.md, Memory
(let shown (array u8 140) :address 0x0A10)
(let col u8 0)
(let inverse bool false)

(fn start () void
    (for i u8 0 COLUMNS
        (set (at line i) ' '))
    (set col 0)
    (set inverse false))

; one ASCII character
(fn char ((c u8)) void
    (if (>= col COLUMNS)
        (return))
    (set (at line col) (if inverse
        (| c INVERSE)
        c))
    (set col (+ col 1)))

; n in decimal
(fn number ((n u8)) void
    (if (>= n 100)
        (char (+ '0' (/ n 100))))
    (if (>= n 10)
        (char (+ '0' (% (/ n 10) 10))))
    (char (+ '0' (% n 10))))

; a string, with n for each #
(fn add_n ((s (ptr u8)) (n u8)) void
    (let i u8 0)
    (while (!= (load (+ s i)) 0)
        (let c u8 (load (+ s i)))
        (if (= c '#')
            (number n)
            (char c))
        (set i (+ i 1))))

(fn add ((s (ptr u8))) void
    (add_n s 0))

; the next character at column c
(fn tab ((c u8)) void
    (if (> c col)
        (set col c)))

; row r of the line in the 35-column font onto row y of the backdrop: a 4-pixel cell a
; character, the glyph's 3 pixels then a gap (lib/dhgr_pixels' cells), inverse the cell's bits
; flipped; glyph_at and flip are the line's, worked out once
(let glyph_at (array u16 35))
(let flip (array u8 35))
(let cells (array u8 35))

(fn glyphs35 () void
    (for i u8 0 COLUMNS
        (let c u8 (at line i))
        (set (at flip i) 0)
        (if (>= c INVERSE)
            (do
                (set (at flip i) 15)
                (set c (& c 0x7F))))
        (set (at glyph_at i) (<< (as u16 (- c 32)) 3))))

; its blocks of 7 characters from block b0, n of them
(fn row35 ((r u8) (y u8) (b0 u8) (n u8)) void
    (let i0 u8 (* b0 7))
    (for i u8 i0 (+ i0 (* n 7))
        (let bits u8 (at hud.FONT35 (+ (at glyph_at i) (as u16 r))))
        (set (at cells i) (^ bits (at flip i))))
    (dhgr_pixels.cells screen.BACKDROP (<< b0 3) y n (addr_of (at cells i0))))

; row y of the line in the 40-column font: a character is one aux byte and one main byte
(fn row40 ((r u8) (y u8)) void
    (for i u8 0 40
        (let c u8 (if (< i COLUMNS)
            (at line i)
            ' '))
        (let flip u8 0)
        (if (>= c INVERSE)
            (do
                (set flip 0x7F)
                (set c (& c 0x7F))))
        (let at u16 (+ (* (as u16 (- c 32)) 16) (as u16 (<< r 1))))
        (set (at pix.aux_bytes i) (^ (at font40.FONT40 at) flip))
        (set (at pix.main_bytes i) (^ (at font40.FONT40 (+ at 1)) flip)))
    (let p (ptr u8) (as (ptr u8) (screen.row_at screen.BACKDROP y 0)))
    (for i u8 0 40
        (store (+ p i) (at pix.main_bytes i)))
    (auxmem.write p (addr_of (at pix.aux_bytes 0)) 40))

; whether text row r already shows the line
(fn same ((r u8)) bool
    (let at u8 (* r COLUMNS))
    (for i u8 0 COLUMNS
        (if (!= (at shown (+ at i)) (at line i))
            (return false)))
    true)

; how far a row's characters reach: past the last one that is not a blank (a new backdrop's
; rows hold 0s, which are blank too)
(fn reach ((chars (ptr u8))) u8
    (let n u8 COLUMNS)
    (while (and (> n 0) (or (= (load (+ chars (- n 1))) ' ') (= (load (+ chars (- n 1))) 0)))
        (set n (- n 1)))
    n)

; the line onto text row r (0 to 3): into the backdrop, marked for both pages; in the 35-column
; font only the blocks of 7 characters (8 byte columns) from the first that changed to the last,
; so a number changing costs a block, not the line, to draw and to copy onto the pages
(fn show ((r u8)) void
    (let at u8 (* r COLUMNS))
    (let first u8 COLUMNS)
    (let last u8 0)
    (for i u8 0 COLUMNS
        (if (!= (at shown (+ at i)) (at line i))
            (do
                (if (= first COLUMNS)
                    (set first i))
                (set last (+ i 1)))))
    (if (= first COLUMNS)
        (return))
    (for i u8 0 COLUMNS
        (set (at shown (+ at i)) (at line i)))
    (let y u8 (+ TOP (<< r 3)))
    (if (not FONT_35)
        (do
            (for k u8 0 8
                (row40 k (+ y k)))
            (scene.mark 0 y 40 8)
            (return)))
    (let b0 u8 (/ first 7))
    (let b1 u8 (/ (+ last 6) 7))
    (glyphs35)
    (for k u8 0 8
        (row35 k (+ y k) b0 (- b1 b0)))
    (scene.mark (<< b0 3) y (<< (- b1 b0) 3) 8))

; the line kept elsewhere (the log), and back
(fn save ((to (ptr u8))) void
    (for i u8 0 COLUMNS
        (store (+ to i) (at line i))))

(fn load_line ((from (ptr u8))) void
    (for i u8 0 COLUMNS
        (set (at line i) (load (+ from i)))))

; all four rows blank; forget delays nothing: a new backdrop has none of the lines on it
(fn forget () void
    (for i u8 0 140
        (set (at shown i) 0)))

(fn clear () void
    (start)
    (for r u8 0 ROWS
        (show r)))
