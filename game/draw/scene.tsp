; drawing a frame straight onto the page on screen (screen.PAGE: one page, no flipping, each
; change drawn once), over the fight's picture on the midnight stage: the looks (actors,
; badges, bolt, markers, floating numbers) move only over black (tools/dhgr/lanes.py), rows
; 0-120; the hud (the tray, the text) is drawn from row 121 down. The page remembers what it
; shows (state.drawn), so a frame only touches what changed:
;   1. the old boxes of the looks that changed are filled black (a solid fighter's only where
;      its new box does not cover: it is drawn whole over its old pose, so it never blinks);
;   2. every look that changed, met a filled box or sits on top of one being drawn, is drawn
;      again over the page, in order.

(import state)
(import art/sprites art)
(import draw/screen)
(import draw/blit)
(import draw/badge)

(const BADGE_ROWS u8 9)

; scratch for one frame, not game state: each look's box now, the boxes copied back, and what
; to draw (see AGENTS.md, Memory)
(let box (array state.Rect 19) :address 0x0500)
(let changed (array bool 19) :address 0x054C)
(let redo (array u8 19) :address 0x055F) ; rows to draw again from the top, 0 for none
(let restored (array state.Rect 30) :address 0x0480)
(let restored_count u8 0)
(let cut (array bool 4)) ; an actor whose box meets another's: drawn without its black
(const MOST_RESTORED u8 30)

; the hud drew onto the page (fresh: the frame has something new, whatever the looks do)
(let fresh bool false)

(fn mark ((col u8) (top u8) (cols u8) (rows u8)) void
    (set fresh true))

; a new picture on the page (a fight's backdrop): no look is on it
(fn forget () void
    (set fresh true)
    (for i u8 0 state.LOOKS
        (set (at state.drawn i sprite) state.NOTHING)))

; a frame starts: nothing filled yet (before the hud draws)
(fn begin () void
    (set restored_count 0))

; the box a look covers, given what it shows, into the_box
(let the_box state.Rect)

(fn box_of ((sprite u8) (col u8) (top u8) (second u8) (wide u8)) void
    (if (= sprite state.BADGE)
        (do
            (set the_box (make state.Rect :col col :top top :cols wide :rows BADGE_ROWS))
            (return)))
    (let cols u8 (at art.COLS sprite))
    (let rows u8 (at art.ROWS sprite))
    (if (!= second state.NOTHING)
        (do
            (set cols (+ 2 (at art.COLS second)))
            (if (> (at art.ROWS second) rows)
                (set rows (at art.ROWS second)))))
    (set the_box (make state.Rect :col col :top top :cols cols :rows rows)))

; the box look i covers this frame, into (at box i)
(fn find_box ((i u8)) void
    (box_of (at state.looks i sprite)
        (at state.looks i col)
        (at state.looks i top)
        (at state.looks i second)
        (at state.looks i wide))
    (set (at box i) the_box))

(fn restore_box ((page u8) (col u8) (top u8) (cols u8) (rows u8)) void
    (blit.restore page col top cols rows)
    (if (< restored_count MOST_RESTORED)
        (do
            (set (at restored restored_count)
                (make state.Rect :col col :top top :cols cols :rows rows))
            (set restored_count (+ restored_count 1)))))

; whether two boxes meet, each given by its corners
(fn meets ((a_col u8)
        (a_top u8)
        (a_right u8)
        (a_bottom u8)
        (b_col u8)
        (b_top u8)
        (b_right u8)
        (b_bottom u8)) bool
    (and (and (< a_col b_right) (< b_col a_right)) (and (< a_top b_bottom) (< b_top a_bottom))))

(fn box_meets_restored ((i u8) (n u8)) bool
    (meets (at box i col)
        (at box i top)
        (+ (at box i col) (at box i cols))
        (+ (at box i top) (at box i rows))
        (at restored n col)
        (at restored n top)
        (+ (at restored n col) (at restored n cols))
        (+ (at restored n top) (at restored n rows))))

(fn box_meets_box ((i u8) (j u8)) bool
    (meets (at box i col)
        (at box i top)
        (+ (at box i col) (at box i cols))
        (+ (at box i top) (at box i rows))
        (at box j col)
        (at box j top)
        (+ (at box j col) (at box j cols))
        (+ (at box j top) (at box j rows))))

; whether look i shows what drawn look d shows
(fn same ((i u8) (d u8)) bool
    (if (!= (at state.looks i sprite) (at state.drawn d sprite))
        (return false))
    (if (= (at state.looks i sprite) state.NOTHING)
        (return true))
    (if (!= (at state.looks i top) (at state.drawn d top))
        (return false))
    (if (!= (at state.looks i col) (at state.drawn d col))
        (return false))
    (if (!= (at state.looks i second) (at state.drawn d second))
        (return false))
    (if (!= (at state.looks i wide) (at state.drawn d wide))
        (return false))
    (= (at state.looks i white) (at state.drawn d white)))

; whether any look differs from what the page on screen shows
(fn differs () bool
    (for i u8 0 state.LOOKS
        (if (not (same i i))
            (return true)))
    false)

; look i to be drawn again down to row bottom (as far as its box goes)
(fn cover ((i u8) (bottom u8)) void
    (let top u8 (at box i top))
    (if (<= bottom top)
        (return))
    (let rows u8 (- bottom top))
    (if (> rows (at box i rows))
        (set rows (at box i rows)))
    (if (> rows (at redo i))
        (set (at redo i) rows)))

; whether look i is what d shows but for the white flash: then it is drawn straight over it,
; with no box copied back first (the white shape covers every pixel the sprite has, and the
; sprite over its white shape puts each one back)
(fn flash_only ((i u8) (d u8)) bool
    (and
        (and (= (at state.looks i sprite) (at state.drawn d sprite))
            (!= (at state.looks i sprite) state.BADGE))
        (and
            (and (= (at state.looks i col) (at state.drawn d col))
                (= (at state.looks i top) (at state.drawn d top)))
            (= (at state.looks i second) (at state.drawn d second)))))

; look i drawn over the page, its first rows rows
(fn draw_look ((page u8) (i u8) (rows u8)) void
    (let sprite u8 (at state.looks i sprite))
    (let col u8 (at state.looks i col))
    (let top u8 (at state.looks i top))
    (if (= sprite state.BADGE)
        (do
            (badge.draw page (- i state.LOOK_HP) col top (at state.looks i wide) rows)
            (return)))
    (let cut_out bool (and (< i state.ACTORS) (at cut i)))
    (blit.draw page col top sprite (at state.looks i white) cut_out rows)
    (let second u8 (at state.looks i second))
    (if (!= second state.NOTHING)
        (blit.draw page (+ col 2) top second false false rows)))

; the old box of the look page shows as d, filled black
(fn restore_drawn ((page u8) (d u8)) void
    (box_of (at state.drawn d sprite)
        (at state.drawn d col)
        (at state.drawn d top)
        (at state.drawn d second)
        (at state.drawn d wide))
    (restore_box page the_box.col the_box.top the_box.cols the_box.rows))

; whether look i is a solid frame (a fighter flattened onto black, art.SOLID) drawn where the
; page shows d, solid too: then its box is drawn whole with no copy back, and only the rest of
; d's old box is copied back (rest_of)
(fn solid_over ((i u8) (d u8)) bool
    (let now u8 (at state.looks i sprite))
    (let was u8 (at state.drawn d sprite))
    (if (or (= now state.NOTHING) (= now state.BADGE))
        (return false))
    (if (or (= was state.NOTHING) (= was state.BADGE))
        (return false))
    (and (= (at art.SOLID now) 1) (= (at art.SOLID was) 1)))

; the parts of the old box of the look page shows as d that look i's box does not cover, copied
; black: the rows above and below it, and beside it in the rows they share
(fn rest_of ((page u8) (d u8) (i u8)) void
    (box_of (at state.drawn d sprite)
        (at state.drawn d col)
        (at state.drawn d top)
        (at state.drawn d second)
        (at state.drawn d wide))
    (let o_col u8 the_box.col)
    (let o_top u8 the_box.top)
    (let o_right u8 (+ the_box.col the_box.cols))
    (let o_bottom u8 (+ the_box.top the_box.rows))
    (let n_col u8 (at box i col))
    (let n_top u8 (at box i top))
    (let n_right u8 (+ n_col (at box i cols)))
    (let n_bottom u8 (+ n_top (at box i rows)))
    (if (not (meets o_col o_top o_right o_bottom n_col n_top n_right n_bottom))
        (do
            (restore_box page o_col o_top the_box.cols the_box.rows)
            (return)))
    (let mid_top u8 o_top)
    (if (< o_top n_top)
        (do
            (restore_box page o_col o_top the_box.cols (- n_top o_top))
            (set mid_top n_top)))
    (let mid_bottom u8 o_bottom)
    (if (> o_bottom n_bottom)
        (do
            (restore_box page o_col n_bottom the_box.cols (- o_bottom n_bottom))
            (set mid_bottom n_bottom)))
    (let mid_rows u8 (- mid_bottom mid_top))
    (if (< o_col n_col)
        (restore_box page o_col mid_top (- n_col o_col) mid_rows))
    (if (> o_right n_right)
        (restore_box page n_right mid_top (- o_right n_right) mid_rows)))

; the frame onto the page, when anything changed
(fn draw_frame () void
    (let page u8 screen.PAGE)
    (let first_drawn u8 0)
    (let any bool fresh)
    (set fresh false)
    (for i u8 0 state.LOOKS
        (set (at changed i) (not (same i (+ first_drawn i))))
        (if (at changed i)
            (set any true)))
    (if (not any)
        (return))
    (for i u8 0 state.LOOKS
        (if (!= (at state.looks i sprite) state.NOTHING)
            (find_box i)))
    ; actors near enough to meet are drawn without their black, over each other, and leave
    ; their whole old box (a solid one drawn over its old pose would blot the other)
    (for i u8 0 state.ACTORS
        (set (at cut i) false)
        (if (!= (at state.looks i sprite) state.NOTHING)
            (for j u8 0 state.ACTORS
                (if (and (!= i j) (!= (at state.looks j sprite) state.NOTHING))
                    (if (box_meets_box i j)
                        (set (at cut i) true))))))
    ; 1. what the looks that changed leave, filled black
    (for i u8 0 state.LOOKS
        (let d u8 (+ first_drawn i))
        (if (and (and (at changed i) (!= (at state.drawn d sprite) state.NOTHING))
                (not (flash_only i d)))
            (if (and (solid_over i d) (not (and (< i state.ACTORS) (at cut i))))
                (rest_of page d i)
                (restore_drawn page d))))
    ; 2. what to draw, and how many of its rows from its top: a changed look whole, one a
    ; copied box cut into down to that box's foot
    (for i u8 0 state.LOOKS
        (set (at redo i) 0)
        (if (!= (at state.looks i sprite) state.NOTHING)
            (do
                (if (at changed i)
                    (set (at redo i) (at box i rows)))
                (for n u8 0 restored_count
                    (if (box_meets_restored i n)
                        (cover i (+ (at restored n top) (at restored n rows))))))))
    ; and anything on top of a look being drawn, down to where that drawing reaches, since
    ; drawing it covers them
    (for i u8 0 state.LOOKS
        (if (> (at redo i) 0)
            (for j u8 (+ i 1) state.LOOKS
                (if (!= (at state.looks j sprite) state.NOTHING)
                    (if (box_meets_box i j)
                        (cover j (+ (at box i top) (at redo i))))))))
    (for i u8 0 state.LOOKS
        (if (> (at redo i) 0)
            (draw_look page i (at redo i)))
        ; what the page shows now: only a changed look shows something new
        (if (at changed i)
            (set (at state.drawn (+ first_drawn i)) (at state.looks i)))))
