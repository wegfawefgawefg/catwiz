; the hud, drawn into the backdrop page and marked for copying onto both pages: hit point pills
; and status stacks under each actor, enemy intents over their heads, the dice tray, the
; re-rolls left, the top line, and the win and lose banners. Each part is redrawn whole when its
; flag in state.game says it changed: first the clean backdrop from aux memory over its area.

(import state)
(import art/sprites art)
(import art/backdrop bd)
(import auxmem)
(import hgr)
(import draw/screen)
(import draw/pen)
(import draw/blit)
(import draw/scene)
(import battle/place)
(import content/dice)
(import content/effects fx)
(import content/enemies en)
(import content/statuses st)

(const PILL_TOP u8 109)
(const STATUS_TOP u8 122)
(const STATUS_STEP u8 9)
(const AREA_HALF u16 21) ; an actor's hud is 42 px wide round its middle
(const AREA_BOTTOM u8 150)
(const TRAY_TOP u8 155) ; the dice pictures, as in tools/art/scenes.py
(const DIGIT_TOP u8 177)
(const TRAY_FIRST_COL u8 4)
(const TRAY_STEP u8 6)

; the clean backdrop back over a box, from the copy in aux memory, and marked
(fn clean ((col u8) (top u8) (cols u8) (rows u8)) void
    (let picture (ptr u8) (addr_of (at bd.backdrop 0)))
    (for r u8 0 rows
        (let y u8 (+ top r))
        (let offset u16 (+ (- (at hgr.ROW y) 0x2000) (as u16 col)))
        (auxmem.read (screen.row_at screen.BACKDROP y col) (+ picture offset) (as u16 cols)))
    (scene.mark col top cols rows))

(fn clean_pixels ((x0 u16) (y0 u8) (x1 u16) (y1 u8)) void
    (let col0 u8 (as u8 (/ x0 7)))
    (let col1 u8 (as u8 (/ (+ x1 6) 7)))
    (clean col0 y0 (- col1 col0) (- y1 y0)))

; a capsule just big enough for width px of text, centred on x; gives the text's left edge
(fn label ((x u16) (top u8) (width u16)) u16
    (let left u16 (- x (>> width 1)))
    (pen.capsule (- left 4) top (+ (+ left width) 4) (+ top 11))
    left)

; ---- under each actor: hit points, then a row for each status it has

(fn pill ((who u8)) void
    (let x u16 (place.centre_x who))
    (clean_pixels (- x AREA_HALF) PILL_TOP (+ x AREA_HALF) AREA_BOTTOM)
    (if (not (at state.actors who alive))
        (return))
    (let hp u8 (at state.actors who hp))
    (let left u16 (label x PILL_TOP (+ 12 (pen.number_width hp))))
    (pen.glyph left (+ PILL_TOP 2) 42) ; heart
    (pen.number (+ left 12) (+ PILL_TOP 2) hp)
    (let top u8 STATUS_TOP)
    (for s u8 0 st.STATUS_COUNT
        (let n u8 (state.stack who s))
        (if (> n 0)
            (do
                (let sl u16 (label x top (+ 12 (pen.number_width n))))
                (pen.glyph sl (+ top 2) (at st.GLYPH s))
                (pen.number (+ sl 12) (+ top 2) n)
                (set top (+ top STATUS_STEP))))))

; ---- over each enemy: what it means to do next

(fn intent ((who u8)) void
    (let x u16 (place.centre_x who))
    (let top u8 (- (place.top who) 15))
    (clean_pixels (- x AREA_HALF) top (+ x AREA_HALF) (+ top 13))
    (if (not (at state.actors who alive))
        (return))
    (let move fx.Action (at en.moves (at state.actors who move)))
    (let left u16 (label x top (+ 12 (pen.number_width move.amount))))
    (pen.glyph left (+ top 2) move.icon)
    (pen.number (+ left 12) (+ top 2) move.amount))

; ---- the dice tray and the re-rolls

(fn die ((d u8)) void
    (let col u8 (+ TRAY_FIRST_COL (* d TRAY_STEP)))
    (let x u16 (* (as u16 col) 7))
    (blit.fill screen.BACKDROP col TRAY_TOP 3 20 0)
    (pen.capsule x DIGIT_TOP (+ x 21) (+ DIGIT_TOP 9))
    (if (not (at state.played d))
        (do
            (let face u8 (at state.hand d))
            (blit.sprite screen.BACKDROP col TRAY_TOP (at dice.faces face icon))
            (let n u8 (at dice.faces face amount))
            (if (> n 0)
                (pen.number (- (+ x 11) (>> (pen.number_width n) 1)) (+ DIGIT_TOP 1) n))))
    (scene.mark col TRAY_TOP 3 (+ (- DIGIT_TOP TRAY_TOP) 9)))

; a diamond for each re-roll left, under the re-roll die
(fn rerolls () void
    (pen.capsule 248 181 278 191)
    (for r u8 0 state.rerolls
        (pen.glyph (+ 251 (* (as u16 r) 14)) 183 36))
    (scene.mark 35 181 5 10))

; ---- the top line: whose turn, and who the dice go to

; text in a capsule with its left edge at left
(fn tag ((left u16) (top u8) (s (ptr u8))) void
    (let w u16 (pen.text_width s))
    (pen.capsule left top (+ (+ left w) 8) (+ top 11))
    (pen.text (+ left 4) (+ top 2) s))

; the same with its right edge at right
(fn tag_right ((right u16) (top u8) (s (ptr u8))) void
    (tag (- (- right (pen.text_width s)) 8) top s))

; what the top line should show now: as state.hud_top. In an action it stays as it was
(fn top_wanted () u8
    (match state.phase
        (state.Phase.player (+ 3 state.target))
        (state.Phase.rolling 1)
        (state.Phase.enemies 2)
        (state.Phase.acting state.hud_top)
        (_ 0)))

(fn top_line ((wanted u8)) void
    (clean 0 0 40 16)
    (match wanted
        (0)
        (1 (tag 4 2 "ROLLING"))
        (2 (tag 4 2 "THEIR TURN"))
        (_
            (tag 4 2 (en.name (at state.actors (- wanted 3) kind)))
            (tag_right 276 2 "B BARK E END"))))

; ---- the end

(fn banner ((line1 (ptr u8)) (line2 (ptr u8))) void
    (pen.capsule 30 56 250 90)
    (let w1 u16 (pen.text_width line1))
    (pen.text (- 140 (>> w1 1)) 62 line1)
    (let w2 u16 (pen.text_width line2))
    (pen.text (- 140 (>> w2 1)) 78 line2)
    (scene.mark_pixels 30 56 250 90))

; whatever changed since the last frame
(fn refresh () void
    (for i u8 0 state.ACTORS
        (let bit u8 (<< 1 i))
        (if (or (= i state.DOG) (!= (at state.actors i kind) state.NOTHING))
            (do
                (if (!= (& state.hud_pills bit) 0)
                    (pill i))
                (if (and (!= i state.DOG) (!= (& state.hud_intents bit) 0))
                    (intent i)))))
    (set state.hud_pills 0)
    (set state.hud_intents 0)
    (for d u8 0 state.HAND
        (if (!= (& state.hud_dice (<< 1 d)) 0)
            (die d)))
    (set state.hud_dice 0)
    (if state.hud_rerolls
        (do
            (rerolls)
            (set state.hud_rerolls false)))
    (let wanted u8 (top_wanted))
    (if (!= wanted state.hud_top)
        (do
            (top_line wanted)
            (set state.hud_top wanted))))
