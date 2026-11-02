; the four lines of text at the foot of the screen, drawn into the picture (rows 160-191 of the
; backdrop page, then copied onto both pages as any hud part is). A line is built in line, then
; shown. The font is the 35-column one in whole colour pixels (white in every look: a glyph is 3
; pixels of a 4-pixel cell); FONT_35 false draws the 40-column dot font instead (white in NTSC,
; violet and green in the flat colour look), with strings of 35 at most either way.
;
; strings are plain ASCII; inverse (set while adding) draws them dark on a light block. A # in a
; string stands for the number given to add_n.

(import auxmem)
(import dhgr)
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
(let mark_number bool false) ; an item's line: its # drawn inverse (add_item)

; colours (2026-11-01, the owner: colour makes the text easier to read), the double hi-res
; palette's numbers. A line starts white; in a string a byte under 16 (a \x escape: WHITE \x0f,
; YELLOW \x0d her numbers, PINK \x0b hurts to her and enemy attacks, GREEN \x0c shields and
; healing, AQUA \x0e mana, ORANGE \x09 statuses, LBLUE \x07 names: aqua reads like green in the
; colour look, so the names, the most often, are light blue) is the colour of what
; follows, taking no column. A line keeps up to RUNS changes (runs: the column, the colour; an
; unused one's column 255), and each row the runs it shows (shown_runs), so a row drawn again
; in new colours is drawn whole. A line kept elsewhere keeps its runs too (save_runs)
(const WHITE u8 15)
(const YELLOW u8 13)
(const PINK u8 11)
(const GREEN u8 12)
(const LBLUE u8 7)
(const ORANGE u8 9)
(const AQUA u8 14)
(const RUNS u8 3)
(let colour u8 15)
(let runs (array u8 6) :address 0x0A03) ; scratch, right after line: see AGENTS.md, Memory
(let run_n u8 :address 0x0A09)
(const LINE_BYTES u16 41) ; line and its runs, one after the other (the log's history)
(let shown_runs (array u8 24) :address 0x07DA) ; 6 bytes a row
; the line's colour masks for lib/dhgr_pixels' cells, 4 bytes a 7-pixel group, all 255 while
; masks_white (a white line's)
(let masks (array u8 80) :address 0x0A9C)
(let masks_white bool false)

(fn start () void
    (for i u8 0 COLUMNS
        (set (at line i) ' '))
    (set col 0)
    (set inverse false)
    (set colour WHITE)
    (set run_n 0)
    (for i u8 0 6
        (set (at runs i) 255)))

; what follows in colour c
(fn paint ((c u8)) void
    (if (or (= c colour) (= run_n RUNS))
        (return))
    (let k u8 (<< run_n 1))
    (set (at runs k) col)
    (set (at runs (+ k 1)) c)
    (set run_n (+ run_n 1))
    (set colour c))

; one ASCII character
(fn char ((c u8)) void
    (if (>= col COLUMNS)
        (return))
    (set (at line col) (if inverse
        (| c INVERSE)
        c))
    (set col (+ col 1)))

; n's decimal digits, by subtraction (a division would pull in the runtime's routines: AGENTS.md
; Memory); battle/hud and battle/hit read them too
(let hundreds u8 0)
(let tens u8 0)
(let ones u8 0)

(fn digits ((n u8)) void
    (set hundreds 0)
    (while (>= n 100)
        (set n (- n 100))
        (set hundreds (+ hundreds 1)))
    (set tens 0)
    (while (>= n 10)
        (set n (- n 10))
        (set tens (+ tens 1)))
    (set ones n))

; n in decimal
(fn number ((n u8)) void
    (digits n)
    (if (> hundreds 0)
        (char (+ '0' hundreds)))
    (if (or (> hundreds 0) (> tens 0))
        (char (+ '0' tens)))
    (char (+ '0' ones)))

; a string, with n for each #
(fn add_n ((s (ptr u8)) (n u8)) void
    (let i u8 0)
    (while (!= (load (+ s i)) 0)
        (let c u8 (load (+ s i)))
        (if (< c 16)
            (paint c)
            (if (= c '#')
                (do
                    (let was bool inverse)
                    (if mark_number
                        (set inverse true))
                    (number n)
                    (set inverse was))
                (char c)))
        (set i (+ i 1))))

(fn add ((s (ptr u8))) void
    (add_n s 0))

; a string of a const table in aux memory (the content's text: tables marked :strings aux), copied
; here with aux memory switched in for reading, then added as add_n does. Strings written in the
; code are in main memory: add and add_n
(let aux_text (array u8 36) :address 0x0400) ; scratch: see AGENTS.md, Memory

(fn add_aux_n ((s (ptr u8)) (n u8)) void
    (let to (ptr u8) (addr_of (at aux_text 0)))
    (with_aux true false
        (let i u8 0)
        (while (and (< i 35) (!= (load (+ s i)) 0))
            (store (+ to i) (load (+ s i)))
            (set i (+ i 1)))
        (store (+ to i) 0))
    (add_n to n))

(fn add_aux ((s (ptr u8))) void
    (add_aux_n s 0))

; an item's line (aux memory), its number inverse: the number a boost or an upgrade changes, so
; it stands out from the line's fixed numbers (the owner, 2026-10-31)
(fn add_item ((s (ptr u8)) (n u8)) void
    (set mark_number true)
    (add_aux_n s n)
    (set mark_number false))

; the next character at column c
(fn tab ((c u8)) void
    (if (> c col)
        (set col c)))

; row r of the line in the 35-column font onto row y of the backdrop: a 4-pixel cell a
; character, the glyph's 3 pixels then a gap (lib/dhgr_pixels' cells), inverse the cell's bits
; flipped; glyph_at and flip are the line's, worked out once
(let glyph_at (array u16 35) :address 0x0600) ; scratch: see AGENTS.md, Memory
(let flip (array u8 35) :address 0x0646)
(let cells (array u8 35) :address 0x0424)

(fn glyphs35 () void
    (line_masks)
    (for i u8 0 COLUMNS
        (let c u8 (at line i))
        (set (at flip i) 0)
        (if (>= c INVERSE)
            (do
                (set (at flip i) 15)
                (set c (& c 0x7F))))
        (set (at glyph_at i) (<< (as u16 (- c 32)) 3))))

; the line's masks: each pixel's colour (its character's) into pix.px, free while text draws,
; then each 7-pixel group's mask from them; a white line's all 255, set once
(fn line_masks () void
    (if (= run_n 0)
        (do
            (if masks_white
                (return))
            (for i u8 0 80
                (set (at masks i) 255))
            (set masks_white true)
            (return)))
    (set masks_white false)
    (let c u8 WHITE)
    (let k u8 0)
    (let p u8 0)
    (for i u8 0 COLUMNS
        (if (and (< k run_n) (= (at runs (<< k 1)) i))
            (do
                (set c (at runs (+ (<< k 1) 1)))
                (set k (+ k 1))))
        (for j u8 0 4
            (set (at pix.px p) c)
            (set p (+ p 1))))
    (let g u8 0)
    (for m u8 0 20
        (dhgr_pixels.colour_mask (addr_of (at pix.px g)) (addr_of (at masks (<< m 2))))
        (set g (+ g 7))))

; its blocks of 7 characters from block b0, n of them
(fn row35 ((r u8) (y u8) (b0 u8) (n u8)) void
    (let i0 u8 (* b0 7))
    (for i u8 i0 (+ i0 (* n 7))
        (let bits u8 (at hud.FONT35 (+ (at glyph_at i) (as u16 r))))
        (set (at cells i) (^ bits (at flip i))))
    (dhgr_pixels.cells screen.PAGE
        (<< b0 3)
        y n
        (addr_of (at cells i0))
        (addr_of (at masks (<< b0 4)))))

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
    (let p (ptr u8) (as (ptr u8) (screen.row_at screen.PAGE y 0)))
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
    ; new colours: the row whole
    (let ra u8 (* r 6))
    (for i u8 0 6
        (if (!= (at shown_runs (+ ra i)) (at runs i))
            (do
                (set (at shown_runs (+ ra i)) (at runs i))
                (set first 0)
                (set last COLUMNS))))
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
    ; the blocks of 7 characters from first's to last's (dhgr.X_GROUP: a pixel's 7-pixel group)
    (let b0 u8 (at dhgr.X_GROUP first))
    (let b1 u8 (at dhgr.X_GROUP (+ last 6)))
    (glyphs35)
    (for k u8 0 8
        (row35 k (+ y k) b0 (- b1 b0)))
    (scene.mark (<< b0 3) y (<< (- b1 b0) 3) 8))

; the line onto row y of the page, its first blocks of 7 characters (5 the whole width), not
; kept as one of the four rows: the pages over the stage (battle/bag, rules)
(const BLOCKS u8 5)

(fn draw_at ((y u8) (blocks u8)) void
    (if (= blocks 0)
        (return))
    (glyphs35)
    (for k u8 0 8
        (row35 k (+ y k) 0 blocks))
    (scene.mark 0 y (<< blocks 3) 8))

; the blocks of 7 characters the line reaches
(fn blocks () u8
    (let n u8 (reach (addr_of (at line 0))))
    (let b u8 0)
    (while (> n 0)
        (set b (+ b 1))
        (set n (if (> n 7)
            (- n 7)
            0)))
    b)

; the line's runs kept at to, and back (6 bytes)
(fn save_runs ((to (ptr u8))) void
    (for i u8 0 6
        (store (+ to i) (at runs i))))

(fn load_runs ((from (ptr u8))) void
    (set run_n 0)
    (for i u8 0 6
        (set (at runs i) (load (+ from i))))
    (for k u8 0 RUNS
        (if (!= (at runs (<< k 1)) 255)
            (set run_n (+ run_n 1)))))

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
        (set (at shown i) 0))
    (for i u8 0 24
        (set (at shown_runs i) 255)))

(fn clear () void
    (start)
    (for r u8 0 ROWS
        (show r)))
