; her six slots on the stage while she picks what comes between fights (battle/reward): a white
; card with the item's picture for each, in two rows of three right of her, where the enemies
; stood (black there: tools/dhgr/lanes.py), the slot's level as yellow pips under it. The slot a
; choice changes is framed in yellow and shows the change: the new item, or one pip more. The
; next fight's picture covers it all. The kit page (battle/bag) draws the same cards (card).

(import auxmem)
(import state)
(import art/icons)
(import content/items)
(import draw/pix)
(import draw/screen)
(import draw/scene)
(import dhgr)

(const G0 u8 11)        ; the first cell's 7-pixel group (pixel 77), 3 groups a cell
(const TOP u8 62)       ; the first row of cells' top row, a row of cells every 26 rows
(const ROWS u8 24)      ; a card's rows, with its pips
(const MARK_ROWS u8 26) ; with a mark under it instead
(const WIDE u8 17)      ; a card's pixels, its frame's included
(const BLACK u8 0)
(const WHITE u8 15)
(const YELLOW u8 13)

(let picture (array u8 90) :address 0x0780) ; the card's picture, copied from aux memory (scratch)
(let framed u8 255)                         ; the cell framed, or NOTHING

; every cell as the slots are, none framed
(fn show () void
    (set framed state.NOTHING)
    (for k u8 0 state.SLOTS
        (cell k (at state.items k) false false)))

; slot's cell framed, showing item (with a level more, up); the one framed before as it is.
; slot NOTHING: none framed
(fn preview ((slot u8) (item u8) (up bool)) void
    (let was u8 framed)
    (set framed slot)
    (if (and (!= was state.NOTHING) (!= was slot))
        (cell was (at state.items was) false false))
    (if (!= slot state.NOTHING)
        (cell slot item true up)))

; row r of the picture with its first pixel at screen pixel x
(fn picture_row ((r u8) (x u8)) void
    (let at u8 (* r 6))
    (let k u8 (- x pix.origin))
    (for i u8 0 6
        (let b u8 (at picture (+ at i)))
        (let c u8 (>> b 4))
        (if (!= c WHITE)
            (set (at pix.px k) c))
        (set c (& b 15))
        (if (!= c WHITE)
            (set (at pix.px (+ k 1)) c))
        (set k (+ k 2))))

; a card at pixel x, row top, over what the page shows round it: a frame in yellow (frame),
; white, the picture tile (art/icons) on it, and under it pips yellow pips, or the hud glyph mark
; (a charm's; "" for none)
(fn card ((x u8) (top u8) (tile u8) (pips u8) (frame bool) (mark (ptr u8))) void
    (auxmem.read (addr_of (at picture 0))
        (addr_of (at icons.pixels (* (as u16 tile) icons.ICON_BYTES)))
        icons.ICON_BYTES)
    (let g u8 (at dhgr.X_GROUP x))
    (let gn u8 (- (+ (at dhgr.X_GROUP (+ x (- WIDE 1))) 1) g))
    (let rows u8 (if (= (load mark) 0)
        ROWS
        MARK_ROWS))
    (pix.begin g gn)
    (for i u8 0 rows
        (let y u8 (+ top i))
        (pix.read screen.PAGE y)
        (pix.span x (+ x WIDE) BLACK)
        (if frame
            (if (or (= i 0) (= i 20))
                (pix.span x (+ x WIDE) YELLOW)
                (if (< i 20)
                    (do
                        (pix.dot x YELLOW)
                        (pix.dot (+ x (- WIDE 1)) YELLOW)))))
        (if (and (>= i 2) (< i 19))
            (pix.span (+ x 2) (+ x 15) WHITE))
        (if (and (>= i 3) (< i 18))
            (picture_row (- i 3) (+ x 3)))
        (if (and (>= i 21) (< i 23))
            (for p u8 0 pips
                (let px u8 (+ (+ x 4) (<< p 2)))
                (pix.span px (+ px 2) YELLOW)))
        (if (and (>= i 21) (= rows MARK_ROWS))
            (pix.glyphs (+ x 7) mark 1 (- i 21) WHITE))
        (pix.write screen.PAGE y))
    (scene.mark (<< g 1) top (<< gn 1) rows))

; cell k (slot k: wand, fluff, star on the first row, book, curse, trick on the second) showing
; item, framed or not, with a level more (up)
(fn cell ((k u8) (item u8) (frame bool) (up bool)) void
    (let c u8 k)
    (let top u8 TOP)
    (if (>= k 3)
        (do
            (set c (- k 3))
            (set top (+ TOP 26))))
    (let pips u8 (at state.levels k))
    (if up
        (set pips (+ pips 1)))
    (card (+ (* (+ G0 (* c 3)) 7) 2) top (at items.ITEMS item icon) pips frame ""))
