; drawing a frame on the back page. The backdrop page holds the clean picture with the hud
; drawn into it; the looks (actors, bolt, marker, floating numbers) go over it, later looks on
; top. Each page remembers what it shows (state.drawn, and its boxes in drawn_box), so a frame
; only touches what changed since that page was last drawn, two frames ago.
;
; a look that changed and meets no other look is moved in one pass from the backdrop
; (blit.move): its new spans drawn over the backdrop, the rest of its old spans cleaned. Any
; other change takes the long way:
;   1. the boxes of the backdrop the hud changed (mark), and the old boxes of the looks that
;      changed, are copied back from the backdrop;
;   2. every look that changed, met a copied box or sits on top of one being drawn, is drawn
;      again over the page, in order.

(import state)
(import art/sprites art)
(import draw/screen)
(import draw/blit)

; what each page shows: the box of each look as drawn there, page * LOOKS + look
(let drawn_box (array state.Rect 20))

; scratch for one frame, not game state: each look's box now, and how to draw it
(let box (array state.Rect 10))
(let changed (array bool 10))
(let moved (array bool 10))
(let swapped (array bool 10))
(let redo (array bool 10))
(let restored (array state.Rect 24))
(let restored_count u8 0)

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

; the same for a box in pixels, x0 to x1 - 1 and y0 to y1 - 1
(fn mark_pixels ((x0 u16) (y0 u8) (x1 u16) (y1 u8)) void
    (let col0 u8 (as u8 (/ x0 7)))
    (let col1 u8 (as u8 (/ (+ x1 6) 7)))
    (mark col0 y0 (- col1 col0) (- y1 y0)))

; the whole backdrop onto both pages at their next frames
(fn mark_all () void
    (set (at state.full_redraw 0) true)
    (set (at state.full_redraw 1) true))

; the box look i covers this frame, into (at box i): its sprite, and its second when it has one
(fn find_box ((i u8)) void
    (let sprite u8 (at state.looks i sprite))
    (let col u8 (at state.looks i col))
    (let top u8 (at state.looks i top))
    (let right u8 (+ col (at art.SPRITE_W sprite)))
    (let bottom u8 (+ top (at art.SPRITE_H sprite)))
    (let second u8 (at state.looks i second))
    (if (!= second state.NOTHING)
        (do
            (let second_col u8 (at state.looks i second_col))
            (let second_top u8 (at state.looks i second_top))
            (if (< second_col col)
                (set col second_col))
            (if (< second_top top)
                (set top second_top))
            (let r u8 (+ second_col (at art.SPRITE_W second)))
            (let b u8 (+ second_top (at art.SPRITE_H second)))
            (if (> r right)
                (set right r))
            (if (> b bottom)
                (set bottom b))))
    (set (at box i) (make state.Rect :col col :top top :cols (- right col) :rows (- bottom top))))

(fn restore_box ((page u8) (col u8) (top u8) (cols u8) (rows u8)) void
    (blit.restore page col top cols rows)
    (set (at restored restored_count) (make state.Rect :col col :top top :cols cols :rows rows))
    (set restored_count (+ restored_count 1)))

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
    (if (!= (at state.looks i top) (at state.drawn d top))
        (return false))
    (if (!= (at state.looks i col) (at state.drawn d col))
        (return false))
    (if (!= (at state.looks i second) (at state.drawn d second))
        (return false))
    (if (!= (at state.looks i second_top) (at state.drawn d second_top))
        (return false))
    (if (!= (at state.looks i second_col) (at state.drawn d second_col))
        (return false))
    (= (at state.looks i white) (at state.drawn d white)))

; whether look i changed only its face, from one face that swaps to another: then the new face
; is drawn straight over the old one
(fn face_only ((i u8) (d u8)) bool
    (if (or (not (at state.looks i swaps)) (not (at state.drawn d swaps)))
        (return false))
    (if (or (!= (at state.looks i sprite) (at state.drawn d sprite))
            (!= (at state.looks i col) (at state.drawn d col)))
        (return false))
    (if (or (!= (at state.looks i top) (at state.drawn d top))
            (!= (at state.looks i white) (at state.drawn d white)))
        (return false))
    (and (= (at state.looks i second_col) (at state.drawn d second_col))
        (= (at state.looks i second_top) (at state.drawn d second_top))))

; whether look i, new and old box together, meets no other look's new or old box: then it can
; move in one pass from the backdrop
(fn alone ((i u8) (first_drawn u8)) bool
    (if (= (at state.looks i sprite) state.NOTHING)
        (return false))
    (let col u8 (at box i col))
    (let top u8 (at box i top))
    (let right u8 (+ col (at box i cols)))
    (let bottom u8 (+ top (at box i rows)))
    (let d u8 (+ first_drawn i))
    (if (!= (at state.drawn d sprite) state.NOTHING)
        (do
            (if (< (at drawn_box d col) col)
                (set col (at drawn_box d col)))
            (if (< (at drawn_box d top) top)
                (set top (at drawn_box d top)))
            (let r u8 (+ (at drawn_box d col) (at drawn_box d cols)))
            (let b u8 (+ (at drawn_box d top) (at drawn_box d rows)))
            (if (> r right)
                (set right r))
            (if (> b bottom)
                (set bottom b))))
    (for j u8 0 state.LOOKS
        (if (!= j i)
            (do
                (if (!= (at state.looks j sprite) state.NOTHING)
                    (if (meets col top right bottom
                            (at box j col)
                            (at box j top)
                            (+ (at box j col) (at box j cols))
                            (+ (at box j top) (at box j rows)))
                        (return false)))
                (let dj u8 (+ first_drawn j))
                (if (!= (at state.drawn dj sprite) state.NOTHING)
                    (if (meets col top right bottom
                            (at drawn_box dj col)
                            (at drawn_box dj top)
                            (+ (at drawn_box dj col) (at drawn_box dj cols))
                            (+ (at drawn_box dj top) (at drawn_box dj rows)))
                        (return false))))))
    true)

(fn draw_look ((page u8) (i u8)) void
    (let sprite u8 (at state.looks i sprite))
    (let col u8 (at state.looks i col))
    (let top u8 (at state.looks i top))
    (if (at state.looks i white)
        (do
            (blit.white page col top sprite)
            (return)))
    (blit.sprite page col top sprite)
    (let second u8 (at state.looks i second))
    (if (and (!= second state.NOTHING) (not (at state.looks i face_on_body)))
        (blit.sprite page (at state.looks i second_col) (at state.looks i second_top) second)))

; look i in one pass from the backdrop: the old second sprite's box cleaned, the main sprite
; moved, the new second drawn over it
(fn move_look ((page u8) (i u8) (d u8)) void
    (let old u8 (at state.drawn d sprite))
    (let old_second u8 (at state.drawn d second))
    ; a face inside the body's outline goes with the body's old spans; one outside needs its
    ; box cleaned
    (if (and (and (!= old state.NOTHING) (!= old_second state.NOTHING))
            (not (at state.drawn d swaps)))
        (blit.restore page
            (at state.drawn d second_col)
            (at state.drawn d second_top)
            (at art.SPRITE_W old_second)
            (at art.SPRITE_H old_second)))
    (let white bool (at state.looks i white))
    (blit.move page old
        (at state.drawn d col)
        (at state.drawn d top)
        (at state.looks i sprite)
        (at state.looks i col)
        (at state.looks i top)
        white)
    (let second u8 (at state.looks i second))
    (if (and (and (!= second state.NOTHING) (not white)) (not (at state.looks i face_on_body)))
        (blit.sprite page (at state.looks i second_col) (at state.looks i second_top) second)))

(fn draw_frame () void
    (let page u8 screen.back)
    (let pi u8 screen.back_index)
    (let first_drawn u8 (* pi state.LOOKS))
    (set restored_count 0)
    (for i u8 0 state.LOOKS
        (if (!= (at state.looks i sprite) state.NOTHING)
            (find_box i))
        (set (at changed i) (not (same i (+ first_drawn i))))
        (set (at moved i) false)
        (set (at swapped i) false))
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
                (if (and (at changed i) (face_only i d))
                    (set (at swapped i) true))
                (if (and (at changed i) (not (at swapped i)))
                    (if (alone i first_drawn)
                        (set (at moved i) true)
                        (if (!= (at state.drawn d sprite) state.NOTHING)
                            (restore_box page
                                (at drawn_box d col)
                                (at drawn_box d top)
                                (at drawn_box d cols)
                                (at drawn_box d rows))))))))
    ; 2. what to draw: the changed looks, and the ones a copied box cut into
    (for i u8 0 state.LOOKS
        (set (at redo i) false)
        (if (and (!= (at state.looks i sprite) state.NOTHING) (not (at moved i)))
            (do
                (if (and (at changed i) (not (at swapped i)))
                    (set (at redo i) true))
                (for n u8 0 restored_count
                    (if (box_meets_restored i n)
                        (set (at redo i) true))))))
    ; and anything on top of a look being drawn, since drawing it covers them
    (for i u8 0 state.LOOKS
        (if (or (at redo i) (and (at swapped i) (not (at redo i))))
            (for j u8 (+ i 1) state.LOOKS
                (if (and (not (at redo j)) (!= (at state.looks j sprite) state.NOTHING))
                    (if (box_meets_box i j)
                        (set (at redo j) true))))))
    (for i u8 0 state.LOOKS
        (let d u8 (+ first_drawn i))
        (if (at moved i)
            (move_look page i d))
        (if (at redo i)
            (draw_look page i))
        (if (and (at swapped i) (not (at redo i)))
            (blit.sprite page
                (at state.looks i second_col)
                (at state.looks i second_top)
                (at state.looks i second)))
        (set (at state.drawn d) (at state.looks i))
        (set (at drawn_box d) (at box i))))
