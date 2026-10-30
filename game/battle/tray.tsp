; the dice tray at the foot of the stage, drawn into the backdrop page in whole pixels
; (draw/pix) and marked for both pages: a tilted white card for each slot (art/hud_data's spans
; per row), a die's picture on it (art/icons) and its number under it, the picked one upright,
; lifted and rimmed in yellow; at the right the re-roll button, the mana stars and END TURN
; (side). The reward uses a sixth slot where the buttons are.
;
; a slot is drawn again with the groups of pixels its card covers, every card there composed
; anew from black, so neighbours that reach in stay right.

(import state)
(import art/hud_data hud)
(import art/icons)
(import draw/screen)
(import draw/pix)
(import draw/scene)

(const BLACK u8 0)
(const GREY u8 5)
(const PINK u8 11)
(const MAGENTA u8 1)
(const WHITE u8 15)
(const ICON_W u8 11)
(const ICON_H u8 15)
(const SIDE_G0 u8 13) ; the buttons' groups: pixels 91-139
(const SIDE_GN u8 7)

; what each slot shows (not game state: the tray's own record): a card or not, its picture
; (icons' TILE number or state.NOTHING), its caption and where it starts, whether it is picked
(let card (array bool 6))
(let icon (array u8 6))
(let caption (array (ptr u8) 6))
(let caption_len (array u8 6))
(let caption_x (array u8 6))
(let picked (array bool 6))
(let side_on bool false)
; the groups of pixels to draw again at the next flush, and whether only the faces changed
(let dirty_g0 u8 255)
(let dirty_g1 u8 0)
(let faces_only bool true)

(const FACE_TOP u8 124) ; the rows a face (picture and caption) may change, picked or not
(const FACE_END u8 153)

; a slot's card and what is on it; drawn at the next flush
(fn slot ((n u8) (has_card bool) (tile u8) (text (ptr u8)) (is_picked bool)) void
    (if (or (!= (at card n) has_card) (!= (at picked n) is_picked))
        (set faces_only false))
    (set (at card n) has_card)
    (set (at icon n) tile)
    (set (at caption n) text)
    (set (at picked n) is_picked)
    (let len u8 0)
    (while (!= (load (+ text len)) 0)
        (set len (+ len 1)))
    (set (at caption_len n) len)
    (set (at caption_x n) (- (at hud.CARD_X n) (>> (pix.glyphs_width text len) 1)))
    (let g0 u8 (at hud.SLOT_G0 n))
    (let g1 u8 (+ g0 (at hud.SLOT_GN n)))
    (if (< g0 dirty_g0)
        (set dirty_g0 g0))
    (if (> g1 dirty_g1)
        (set dirty_g1 g1)))

; what changed since the last flush drawn into the backdrop, all at once
(fn flush () void
    (if (= dirty_g0 255)
        (return))
    (if faces_only
        (draw_groups dirty_g0 (- dirty_g1 dirty_g0) FACE_TOP FACE_END)
        (draw_groups dirty_g0 (- dirty_g1 dirty_g0) hud.TRAY_TOP (+ hud.TRAY_TOP hud.TRAY_ROWS)))
    (set dirty_g0 255)
    (set dirty_g1 0)
    (set faces_only true))

; no cards at all, nothing drawn (a new backdrop's tray is black)
(fn forget () void
    (for n u8 0 hud.SLOTS
        (set (at card n) false)
        (set (at icon n) state.NOTHING)
        (set (at picked n) false))
    (set dirty_g0 255)
    (set dirty_g1 0)
    (set faces_only true)
    (set side_on false))

; row y of slot n's card: its white, or picked its rim, edge and white
(fn card_row ((n u8) (y u8)) void
    (if (not (at picked n))
        (do
            (let at u8 (+ (* n hud.TRAY_ROWS) (- y hud.TRAY_TOP)))
            (pix.span (at hud.CARD_FIRST at) (at hud.CARD_END at) WHITE)
            (return)))
    (for k u8 0 3
        (let at u8 (+ (* n 15) (* k 5)))
        (if (and (>= y (at hud.PICKED (+ at 2))) (< y (at hud.PICKED (+ at 3))))
            (pix.span (at hud.PICKED at) (at hud.PICKED (+ at 1)) (at hud.PICKED (+ at 4))))))

; row y of slot n's picture and caption
(fn face_row ((n u8) (y u8)) void
    (let tile u8 (at icon n))
    (if (= tile state.NOTHING)
        (return))
    (let x u8 (at hud.ICON_X n))
    (let top u8 (at hud.ICON_Y n))
    (let cap_y u8 hud.CAPTION_Y)
    (if (at picked n)
        (do
            (set x (at hud.PICKED_ICON_X n))
            (set top (at hud.PICKED_ICON_Y n))
            (set cap_y hud.PICKED_CAPTION_Y)))
    (if (and (>= y top) (< y (+ top ICON_H)))
        (do
            (let at u16 (+ (* (as u16 tile) icons.ICON_BYTES) (as u16 (* (- y top) 6))))
            (for i u8 0 ICON_W
                (let b u8 (at icons.PIXELS (+ at (as u16 (>> i 1)))))
                (let c u8 (if (= (& i 1) 0)
                    (>> b 4)
                    (& b 15)))
                (if (!= c WHITE)
                    (pix.dot (+ x i) c)))))
    (if (and (>= y cap_y) (< y (+ cap_y 5)))
        (pix.glyphs (at caption_x n) (at caption n) (at caption_len n) (- y cap_y) BLACK)))

; groups g0 to g0 + gn - 1 of the tray's rows composed anew: the cards not picked, then the
; picked one over them
(fn draw_groups ((g0 u8) (gn u8) (y0 u8) (y1 u8)) void
    (pix.begin g0 gn)
    (for y u8 y0 y1
        (pix.fill BLACK)
        (for n u8 0 hud.SLOTS
            (if (and (at card n) (not (at picked n)))
                (do
                    (card_row n y)
                    (face_row n y))))
        (for n u8 0 hud.SLOTS
            (if (and (at card n) (at picked n))
                (do
                    (card_row n y)
                    (face_row n y))))
        (pix.write screen.BACKDROP y))
    (scene.mark (<< g0 1) y0 (<< gn 1) (- y1 y0)))

; ---- the buttons and the mana, right of the cards

; the re-roll button (a die, X and the re-rolls left, grey with none), the mana stars lit for
; what the hero has, END TURN
(let side_glyphs (array u8 8))

(fn side_row ((y u8) (rerolls u8) (mana u8) (most u8)) void
    (pix.fill BLACK)
    ; the re-roll button: a white pill with a die's five pips
    (if (and (>= y 128) (< y 140))
        (do
            (let inset u8 (if (or (= y 128) (= y 139))
                1
                0))
            (pix.span (+ 92 inset) (- 99 inset) (if (> rerolls 0)
                WHITE
                GREY))
            (if (or (or (= y 130) (= y 131)) (or (= y 136) (= y 137)))
                (do
                    (pix.dot 93 BLACK)
                    (pix.dot 97 BLACK)))
            (if (or (= y 133) (= y 134))
                (pix.dot 95 BLACK))))
    (if (and (>= y 132) (< y 137))
        (do
            (set (at side_glyphs 0) 'X')
            (set (at side_glyphs 1) (+ '0' rerolls))
            (pix.glyphs 101 (addr_of (at side_glyphs 0)) 2 (- y 132) WHITE)))
    ; the mana: a star for each, lit while the hero has it
    (if (and (>= y 131) (< y 137))
        (do
            (for k u8 0 most
                (set (at side_glyphs k) (if (< k mana)
                    '\''
                    '$')))
            (pix.glyphs 109 (addr_of (at side_glyphs 0)) most (- y 131) WHITE)))
    ; END TURN: a magenta pill rimmed in white, a pink shine along its top
    (if (and (>= y 143) (< y 157))
        (do
            (let inset u8 (if (or (= y 143) (= y 156))
                1
                0))
            (pix.span (+ 91 inset) (- 138 inset) WHITE)
            (if (and (>= y 144) (< y 156))
                (do
                    (let inner u8 (if (or (= y 144) (= y 155))
                        1
                        0))
                    (pix.span (+ 92 inner) (- 137 inner) MAGENTA)))
            (if (= y 145)
                (pix.span 94 135 PINK))
            (if (and (>= y 148) (< y 153))
                (pix.glyphs 99 "END TURN" 8 (- y 148) WHITE)))))

(fn side ((rerolls u8) (mana u8) (most u8)) void
    (set side_on true)
    (pix.begin SIDE_G0 SIDE_GN)
    (for y u8 hud.TRAY_TOP (+ hud.TRAY_TOP hud.TRAY_ROWS)
        (side_row y rerolls mana most)
        (pix.write screen.BACKDROP y))
    (scene.mark (<< SIDE_G0 1) hud.TRAY_TOP (<< SIDE_GN 1) hud.TRAY_ROWS))

; the buttons off, for the reward: its sixth slot goes there
(fn clear_side () void
    (set side_on false)
    (pix.begin SIDE_G0 SIDE_GN)
    (pix.fill BLACK)
    (for y u8 hud.TRAY_TOP (+ hud.TRAY_TOP hud.TRAY_ROWS)
        (pix.write screen.BACKDROP y))
    (scene.mark (<< SIDE_G0 1) hud.TRAY_TOP (<< SIDE_GN 1) hud.TRAY_ROWS))
