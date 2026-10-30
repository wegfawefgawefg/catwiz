; a badge on a page: a black pill with hud glyphs in it (a heart and the hit points, a sword and
; what an enemy will hit for, status icons), drawn over whatever the page shows there, a row at
; a time in whole pixels (draw/pix). Its glyphs are in state.badge_glyphs; battle/hud.tsp fills
; them and makes the badge a look.

(import state)
(import draw/pix)

(const ROWS u8 9)
(const BLACK u8 0)
(const WHITE u8 15)

; badge b (0 to state.BADGES - 1) in the box of wide byte columns from col, rows from top; its
; first rows rows
(fn draw ((page u8) (b u8) (col u8) (top u8) (wide u8) (rows u8)) void
    (let n u8 (at state.badge_count b))
    (let glyphs (ptr u8) (addr_of (at state.badge_glyphs (* b state.BADGE_MOST))))
    (let x0 u8 (at state.badge_x b))
    (let x1 u8 (+ (+ x0 (pix.glyphs_width glyphs n)) 4))
    (pix.begin (>> col 1) (>> wide 1))
    (if (> rows ROWS)
        (set rows ROWS))
    (for r u8 0 rows
        (let y u8 (+ top r))
        (pix.read page y)
        (let inset u8 (if (or (= r 0) (= r (- ROWS 1)))
            1
            0))
        (pix.span (+ x0 inset) (- x1 inset) BLACK)
        (if (and (>= r 2) (< r 8))
            (pix.glyphs (+ x0 2) glyphs n (- r 2) WHITE))
        (pix.write page y)))
