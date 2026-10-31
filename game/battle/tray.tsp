; the dice tray at the foot of the stage, drawn into the backdrop page in whole pixels
; (draw/pix) and marked for both pages: a tilted white card for each slot (art/hud_data's spans
; per row), a die's picture on it (art/icons) and its number under it; at the right the re-roll
; button, the mana stars and END TURN (side). The reward uses a sixth slot where the buttons are.
;
; a slot is drawn again with the groups of pixels its card covers, every card there composed
; anew from black, so neighbours that reach in stay right. Each card stays inside its slot's 5
; byte columns, so picking one is only bytes moved: its columns' rows go up LIFT rows and a
; glow bar fills in under it (lift), and back down when it is put back (drop), a pick on screen
; in about a frame where composing the slot again took ten.

(import state)
(import art/hud_data hud)
(import art/icons)
(import draw/screen)
(import draw/pix)
(import draw/scene)
(import dhgr)

(const BLACK u8 0)
(const GREY u8 5)
(const PINK u8 11)
(const MAGENTA u8 1)
(const WHITE u8 15)
(const FOCUS u8 13) ; yellow
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
(let lifted (array bool 6)) ; what the backdrop shows
(let side_on bool false)
; the groups of pixels to draw again at the next flush, and whether only the faces changed
(let dirty_g0 u8 255)
(let dirty_g1 u8 0)
(let faces_only bool true)

(const FACE_TOP u8 124) ; the rows a face (picture and caption) may change, picked or not
(const FACE_END u8 153)

; a slot's card and what is on it; drawn at the next flush, composed again only when the card
; or what is on it changed
(fn slot ((n u8) (has_card bool) (tile u8) (text (ptr u8)) (is_picked bool)) void
    (set (at picked n) is_picked)
    (if (and (and (= (at card n) has_card) (= (at icon n) tile)) (= (at caption n) text))
        (return))
    (if (!= (at card n) has_card)
        (set faces_only false))
    (set (at card n) has_card)
    (set (at icon n) tile)
    (set (at caption n) text)
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

; what changed since the last flush drawn into the backdrop, all at once: lifted cards that are
; no longer picked, or that the groups composed again reach, dropped first; the groups
; composed; then the picked cards lifted. Gives whether anything was drawn
(fn flush () bool
    (let compose bool (!= dirty_g0 255))
    (let any bool compose)
    (for n u8 0 hud.SLOTS
        (if (at lifted n)
            (if (or (not (at picked n)) (and compose (reaches n)))
                (do
                    (drop n)
                    (set any true)))))
    (if compose
        (do
            (if faces_only
                (draw_groups dirty_g0 (- dirty_g1 dirty_g0) FACE_TOP FACE_END)
                (draw_groups dirty_g0 (- dirty_g1 dirty_g0) hud.TRAY_TOP (+ hud.TRAY_TOP hud.TRAY_ROWS)))
            (set dirty_g0 255)
            (set dirty_g1 0)
            (set faces_only true)))
    (for n u8 0 hud.SLOTS
        (if (and (and (at picked n) (at card n)) (not (at lifted n)))
            (do
                (lift n)
                (set any true))))
    any)

; whether slot n's groups meet the ones to compose
(fn reaches ((n u8)) bool
    (let g0 u8 (at hud.SLOT_G0 n))
    (and (< g0 dirty_g1) (> (+ g0 (at hud.SLOT_GN n)) dirty_g0)))

; ---- picking: a card's columns moved

; the card rows of slot columns col to col + 4 in the backdrop moved LIFT rows up, or down, in
; one memory (aux: with aux memory switched in for reading and writing)
(fn shift ((col u8) (up bool) (aux bool)) void
    (with_aux aux aux
        (let y u8 (if up
            hud.CARD_TOP
            (- hud.CARD_BOTTOM 1)))
        ; up: row y onto y - LIFT, from the top; down: row y - LIFT onto y, from the bottom
        (for k u8 0 (- hud.CARD_BOTTOM hud.CARD_TOP)
            (let from u8 (if up
                y
                (- y hud.LIFT)))
            (let to u8 (if up
                (- y hud.LIFT)
                y))
            (let src (ptr u8) (as (ptr u8) (screen.row_at screen.BACKDROP from col)))
            (let dst (ptr u8) (as (ptr u8) (screen.row_at screen.BACKDROP to col)))
            (for i u8 0 hud.SLOT_COLS
                (store (+ dst i) (load (+ src i))))
            (set y (if up
                (+ y 1)
                (- y 1))))))

(fn lift ((n u8)) void
    (let col u8 (* n hud.SLOT_COLS))
    (shift col true false)
    (shift col true true)
    (let left u8 (- hud.CARD_BOTTOM hud.LIFT))
    (dhgr.box screen.BACKDROP col left hud.SLOT_COLS hud.LIFT BLACK)
    (dhgr.box screen.BACKDROP (+ col 1) (- hud.CARD_BOTTOM hud.GLOW_ROWS) 3 hud.GLOW_ROWS FOCUS)
    (set (at lifted n) true)
    (mark_slot col))

(fn drop ((n u8)) void
    (let col u8 (* n hud.SLOT_COLS))
    (shift col false false)
    (shift col false true)
    (dhgr.box screen.BACKDROP col (- hud.CARD_TOP hud.LIFT) hud.SLOT_COLS hud.LIFT BLACK)
    (set (at lifted n) false)
    (mark_slot col))

(fn mark_slot ((col u8)) void
    (scene.mark col (- hud.CARD_TOP hud.LIFT) hud.SLOT_COLS (+ (- hud.CARD_BOTTOM hud.CARD_TOP) hud.LIFT)))

; no cards at all, nothing drawn (a new backdrop's tray is black)
(fn forget () void
    (for n u8 0 hud.SLOTS
        (set (at card n) false)
        (set (at icon n) state.NOTHING)
        (set (at picked n) false)
        (set (at lifted n) false))
    (set dirty_g0 255)
    (set dirty_g1 0)
    (set faces_only true)
    (set side_on false))

; row y of slot n's card: its white
(fn card_row ((n u8) (y u8)) void
    (let at u8 (+ (* n hud.TRAY_ROWS) (- y hud.TRAY_TOP)))
    (pix.span (at hud.CARD_FIRST at) (at hud.CARD_END at) WHITE))

; row y of slot n's picture and caption
(fn face_row ((n u8) (y u8)) void
    (let tile u8 (at icon n))
    (if (= tile state.NOTHING)
        (return))
    (let x u8 (at hud.ICON_X n))
    (let top u8 (at hud.ICON_Y n))
    (let cap_y u8 hud.CAPTION_Y)
    (if (and (>= y top) (< y (+ top ICON_H)))
        (do
            (let at u16 (+ (* (as u16 tile) icons.ICON_BYTES) (as u16 (* (- y top) 6))))
            ; the picture's pixels in the stretch: from i0 to i1 of its 11, at px k on
            (let i0 u8 0)
            (if (< x pix.origin)
                (set i0 (- pix.origin x)))
            (let end u8 (+ pix.origin pix.width))
            (let i1 u8 ICON_W)
            (if (< end (+ x ICON_W))
                (set i1 (if (> end x)
                    (- end x)
                    0)))
            (let k u8 (- (+ x i0) pix.origin))
            (for i u8 i0 i1
                (let b u8 (at icons.PIXELS (+ at (as u16 (>> i 1)))))
                (let c u8 (if (= (& i 1) 0)
                    (>> b 4)
                    (& b 15)))
                (if (!= c WHITE)
                    (set (at pix.px k) c))
                (set k (+ k 1)))))
    (if (and (>= y cap_y) (< y (+ cap_y 5)))
        (pix.glyphs (at caption_x n) (at caption n) (at caption_len n) (- y cap_y) BLACK)))

; groups g0 to g0 + gn - 1 of the tray's rows composed anew, every card down (flush lifts the
; picked one after)
(let near (array bool 6)) ; the slots with a card that reaches into the groups drawn

(fn draw_groups ((g0 u8) (gn u8) (y0 u8) (y1 u8)) void
    (pix.begin g0 gn)
    (for n u8 0 hud.SLOTS
        (let s0 u8 (at hud.SLOT_G0 n))
        (set (at near n) (and (at card n) (and (< s0 (+ g0 gn)) (> (+ s0 (at hud.SLOT_GN n)) g0)))))
    (for y u8 y0 y1
        (pix.fill BLACK)
        (for n u8 0 hud.SLOTS
            (if (at near n)
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

; the side as it shows: drawn whole the first time, then only the rows of the re-roll button
; and the stars, and only when what they show changed (the hero's badge changing asks too)
(let side_rerolls u8 0)
(let side_mana u8 0)
(const COUNTS_TOP u8 128)
(const COUNTS_END u8 140)

(fn side ((rerolls u8) (mana u8) (most u8)) void
    (let y0 u8 hud.TRAY_TOP)
    (let y1 u8 (+ hud.TRAY_TOP hud.TRAY_ROWS))
    (if side_on
        (do
            (if (and (= rerolls side_rerolls) (= mana side_mana))
                (return))
            (set y0 COUNTS_TOP)
            (set y1 COUNTS_END)))
    (set side_on true)
    (set side_rerolls rerolls)
    (set side_mana mana)
    (pix.begin SIDE_G0 SIDE_GN)
    (for y u8 y0 y1
        (side_row y rerolls mana most)
        (pix.write screen.BACKDROP y))
    (scene.mark (<< SIDE_G0 1) y0 (<< SIDE_GN 1) (- y1 y0)))

; the buttons off, for the reward: its sixth slot goes there
(fn clear_side () void
    (set side_on false)
    (pix.begin SIDE_G0 SIDE_GN)
    (pix.fill BLACK)
    (for y u8 hud.TRAY_TOP (+ hud.TRAY_TOP hud.TRAY_ROWS)
        (pix.write screen.BACKDROP y))
    (scene.mark (<< SIDE_G0 1) hud.TRAY_TOP (<< SIDE_GN 1) hud.TRAY_ROWS))
