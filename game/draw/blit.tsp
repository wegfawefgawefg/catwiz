; sprites onto a page, and the backdrop back over a page.
;
; a sprite (art/sprites.tsp) w bytes wide and h rows tall is h rows of w picture bytes, h rows
; of w mask bytes, then each row's span: h firsts and h counts, the bytes with something in
; them. Each screen byte in a span becomes (screen & mask) | picture. Sprites go on the byte
; grid: col is a byte column (7 pixels), top a pixel row, both of the sprite's top-left corner.
; Nothing is clipped: callers keep sprites on the screen.
;
; the inner loops index the sprite row and the screen row with the same Y, so a row costs a
; screen address and two pointer steps.

(import hgr)
(import art/sprites art)
(import draw/screen)

(fn data_at ((offset u16)) (ptr u8)
    (+ (addr_of (at art.sprite_data 0)) offset))

; the sprite drawn over what the page has
(fn sprite ((page u8) (col u8) (top u8) (id u8)) void
    (let w u8 (at art.SPRITE_W id))
    (let h u8 (at art.SPRITE_H id))
    (let pic (ptr u8) (data_at (at art.SPRITE_AT id)))
    (let mask (ptr u8) (data_at (at art.SPRITE_MASK_AT id)))
    (let firsts (ptr u8) (data_at (at art.SPRITE_SPAN_AT id)))
    (let counts (ptr u8) (+ firsts h))
    (for r u8 0 h
        (let first u8 (load (+ firsts r)))
        (let end u8 (+ first (load (+ counts r))))
        (let dst (ptr u8) (screen.row_at page (+ top r) col))
        (for c u8 first end
            (store (+ dst c) (| (& (load (+ dst c)) (load (+ mask c))) (load (+ pic c)))))
        (set pic (+ pic w))
        (set mask (+ mask w))))

; the sprite's shape in white: the hit flash
(fn white ((page u8) (col u8) (top u8) (id u8)) void
    (let w u8 (at art.SPRITE_W id))
    (let h u8 (at art.SPRITE_H id))
    (let mask (ptr u8) (data_at (at art.SPRITE_MASK_AT id)))
    (let firsts (ptr u8) (data_at (at art.SPRITE_SPAN_AT id)))
    (let counts (ptr u8) (+ firsts h))
    (for r u8 0 h
        (let first u8 (load (+ firsts r)))
        (let end u8 (+ first (load (+ counts r))))
        (let dst (ptr u8) (screen.row_at page (+ top r) col))
        (for c u8 first end
            (let m u8 (load (+ mask c)))
            (store (+ dst c) (| (& (load (+ dst c)) m) (& (~ m) 0x7F))))
        (set mask (+ mask w))))

; a box of the backdrop page copied onto page: cols byte columns from col, rows from top
(fn restore ((page u8) (col u8) (top u8) (cols u8) (rows u8)) void
    (for r u8 0 rows
        (let row u16 (+ (at hgr.ROW (+ top r)) (as u16 col)))
        (let src (ptr u8) (as (ptr u8) (+ row (<< (as u16 screen.BACKDROP) 8))))
        (let dst (ptr u8) (as (ptr u8) (+ row (<< (as u16 page) 8))))
        (for i u8 0 cols
            (store (+ dst i) (load (+ src i))))))

; a box of page filled with one byte
(fn fill ((page u8) (col u8) (top u8) (cols u8) (rows u8) (value u8)) void
    (for r u8 0 rows
        (let dst (ptr u8) (screen.row_at page (+ top r) col))
        (for i u8 0 cols
            (store (+ dst i) value))))

; a sprite moved or changed, in one pass over the rows either covers: in the new sprite's
; spans the screen gets the backdrop with the sprite over it ((backdrop & mask) | picture, or
; white for the flash), and the rest of the old sprite's spans gets the backdrop back. old may
; be art.NONE for a sprite just appearing. Only for a sprite that nothing else on the screen
; meets: it draws from the backdrop, not over what the page has
(fn move ((page u8)
        (old u8)
        (old_col u8)
        (old_top u8)
        (new u8)
        (new_col u8)
        (new_top u8)
        (white bool)) void
    (let w u8 (at art.SPRITE_W new))
    (let new_rows u8 (at art.SPRITE_H new))
    (let pic (ptr u8) (data_at (at art.SPRITE_AT new)))
    (let mask (ptr u8) (data_at (at art.SPRITE_MASK_AT new)))
    (let firsts (ptr u8) (data_at (at art.SPRITE_SPAN_AT new)))
    (let counts (ptr u8) (+ firsts new_rows))
    (let old_rows u8 0)
    (let old_firsts (ptr u8) firsts)
    (if (!= old art.NONE)
        (do
            (set old_rows (at art.SPRITE_H old))
            (set old_firsts (data_at (at art.SPRITE_SPAN_AT old)))))
    (let old_counts (ptr u8) (+ old_firsts old_rows))
    (let old_end u8 (+ old_top old_rows))
    (let new_end u8 (+ new_top new_rows))
    (let y0 u8 new_top)
    (let y1 u8 new_end)
    (if (and (> old_rows 0) (< old_top y0))
        (set y0 old_top))
    (if (and (> old_rows 0) (> old_end y1))
        (set y1 old_end))
    (for y u8 y0 y1
        (let row u16 (at hgr.ROW y))
        (let src (ptr u8) (as (ptr u8) (+ row (<< (as u16 screen.BACKDROP) 8))))
        (let dst (ptr u8) (as (ptr u8) (+ row (<< (as u16 page) 8))))
        ; this row's new span, in screen columns, n_first up to n_end; empty off the sprite
        (let n_first u8 0)
        (let n_end u8 0)
        (if (and (>= y new_top) (< y new_end))
            (do
                (let r u8 (- y new_top))
                (let count u8 (load (+ counts r)))
                (if (> count 0)
                    (do
                        (set n_first (+ new_col (load (+ firsts r))))
                        (set n_end (+ n_first count))))))
        ; the old span, cleaned where the new one does not cover it
        (if (and (>= y old_top) (< y old_end))
            (do
                (let r u8 (- y old_top))
                (let o_first u8 (+ old_col (load (+ old_firsts r))))
                (let o_end u8 (+ o_first (load (+ old_counts r))))
                (if (= n_end 0)
                    (for c u8 o_first o_end
                        (store (+ dst c) (load (+ src c))))
                    (do
                        (let left_end u8 (if (< o_end n_first)
                            o_end
                            n_first))
                        (for c u8 o_first left_end
                            (store (+ dst c) (load (+ src c))))
                        (let right_first u8 (if (> o_first n_end)
                            o_first
                            n_end))
                        (for c u8 right_first o_end
                            (store (+ dst c) (load (+ src c))))))))
        ; the new span, indexed from the sprite's own left edge
        (if (> n_end 0)
            (do
                (let s (ptr u8) (+ src new_col))
                (let d (ptr u8) (+ dst new_col))
                (let first u8 (- n_first new_col))
                (let end u8 (- n_end new_col))
                (if white
                    (for c u8 first end
                        (let m u8 (load (+ mask c)))
                        (store (+ d c) (| (& (load (+ s c)) m) (& (~ m) 0x7F))))
                    (for c u8 first end
                        (store (+ d c)
                            (| (& (load (+ s c)) (load (+ mask c))) (load (+ pic c))))))))
        (if (and (>= y new_top) (< y new_end))
            (do
                (set pic (+ pic w))
                (set mask (+ mask w))))))
