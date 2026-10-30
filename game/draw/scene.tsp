; drawing a frame on the back page. The backdrop page holds the clean picture with the hud
; drawn into it (the tray, the text); the looks (actors, badges, bolt, markers, floating
; numbers) go over it, later looks on top. Each page remembers what it shows (state.drawn), so
; a frame only touches what changed since that page was last drawn, two frames ago:
;   1. the boxes of the backdrop the hud changed (mark), and the old boxes of the looks that
;      changed, are copied back from the backdrop;
;   2. every look that changed, met a copied box or sits on top of one being drawn, is drawn
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
(let redo (array bool 19) :address 0x055F)
(let restored (array state.Rect 30) :address 0x0480)
(let restored_count u8 0)
(const MOST_RESTORED u8 30)

; a box of the backdrop the hud drew into, for both pages
(fn mark ((col u8) (top u8) (cols u8) (rows u8)) void
    (for page u8 0 2
        (let n u8 (at state.rect_count page))
        (if (= n state.RECTS)
            (set (at state.full_redraw page) true)
            (do
                (let slot u8 (+ (* page state.RECTS) n))
                (set (at state.rects slot)
                    (make state.Rect :col col :top top :cols cols :rows rows))
                (set (at state.rect_count page) (+ n 1))))))

; the whole backdrop onto both pages at their next frames
(fn mark_all () void
    (set (at state.full_redraw 0) true)
    (set (at state.full_redraw 1) true))

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

(fn draw_look ((page u8) (i u8)) void
    (let sprite u8 (at state.looks i sprite))
    (let col u8 (at state.looks i col))
    (let top u8 (at state.looks i top))
    (if (= sprite state.BADGE)
        (do
            (badge.draw page (- i state.LOOK_HP) col top (at state.looks i wide))
            (return)))
    (blit.draw page col top sprite (at state.looks i white))
    (let second u8 (at state.looks i second))
    (if (!= second state.NOTHING)
        (blit.sprite page (+ col 2) top second)))

; the old box of the look page shows as d, copied back from the backdrop
(fn restore_drawn ((page u8) (d u8)) void
    (box_of (at state.drawn d sprite)
        (at state.drawn d col)
        (at state.drawn d top)
        (at state.drawn d second)
        (at state.drawn d wide))
    (restore_box page the_box.col the_box.top the_box.cols the_box.rows))

; the frame on the back page; false when that page shows it already (nothing to draw or show)
(fn draw_frame () bool
    (let page u8 screen.back)
    (let pi u8 screen.back_index)
    (let first_drawn u8 (* pi state.LOOKS))
    (set restored_count 0)
    (let any bool (or (at state.full_redraw pi) (> (at state.rect_count pi) 0)))
    (for i u8 0 state.LOOKS
        (if (!= (at state.looks i sprite) state.NOTHING)
            (find_box i))
        (set (at changed i) (not (same i (+ first_drawn i))))
        (if (at changed i)
            (set any true)))
    (if (not any)
        (return false))
    ; 1. what to copy back from the backdrop
    (if (at state.full_redraw pi)
        (do
            (screen.copy_page screen.BACKDROP page)
            (set (at state.full_redraw pi) false)
            (set (at state.rect_count pi) 0)
            (set (at restored 0) (make state.Rect :col 0 :top 0 :cols 40 :rows 192))
            (set restored_count 1))
        (do
            (for n u8 0 (at state.rect_count pi)
                (let r u8 (+ (* pi state.RECTS) n))
                (restore_box page
                    (at state.rects r col)
                    (at state.rects r top)
                    (at state.rects r cols)
                    (at state.rects r rows)))
            (set (at state.rect_count pi) 0)
            (for i u8 0 state.LOOKS
                (let d u8 (+ first_drawn i))
                (if (and (at changed i) (!= (at state.drawn d sprite) state.NOTHING))
                    (restore_drawn page d)))))
    ; 2. what to draw: the changed looks, and the ones a copied box cut into
    (for i u8 0 state.LOOKS
        (set (at redo i) false)
        (if (!= (at state.looks i sprite) state.NOTHING)
            (do
                (if (at changed i)
                    (set (at redo i) true))
                (for n u8 0 restored_count
                    (if (box_meets_restored i n)
                        (set (at redo i) true))))))
    ; and anything on top of a look being drawn, since drawing it covers them
    (for i u8 0 state.LOOKS
        (if (at redo i)
            (for j u8 (+ i 1) state.LOOKS
                (if (and (not (at redo j)) (!= (at state.looks j sprite) state.NOTHING))
                    (if (box_meets_box i j)
                        (set (at redo j) true))))))
    (for i u8 0 state.LOOKS
        (if (at redo i)
            (draw_look page i))
        ; what the page shows now: only a changed look shows something new
        (if (at changed i)
            (set (at state.drawn (+ first_drawn i)) (at state.looks i))))
    true)
