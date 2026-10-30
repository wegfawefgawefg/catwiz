; the hud, drawn into the backdrop page and marked for copying onto both pages: hit points (and
; ward pips) and a status row under each actor, enemy intents over their heads, and the dice
; tray in a black band at the foot of the picture, with the re-rolls and the mana beside it.
; Each part is redrawn whole when its flag in state says it changed: first the clean backdrop
; from aux memory over its area. The words are at the bottom, in text (battle/words, log).

(import state)
(import art/backdrop bd)
(import art/sprites art)
(import auxmem)
(import hgr)
(import draw/screen)
(import draw/pen)
(import draw/blit)
(import draw/scene)
(import battle/place)
(import content/action ac)
(import content/faces)
(import content/effects fx)
(import content/enemies en)
(import content/statuses st)

(const PILL_TOP u8 105)
(const STATUS_TOP u8 116)
(const CAPSULE_ROWS u8 11)
(const BAND_TOP u8 127) ; the tray's black band, down to the text
(const BAND_ROWS u8 33)
(const MARK_TOP u8 127) ; the bar over the picked die
(const TRAY_TOP u8 130) ; the dice pictures
(const DIGIT_TOP u8 150)
(const TRAY_FIRST_COL u8 2)
(const TRAY_STEP u8 6)
(const SIDE_COL u8 29) ; the re-rolls and the mana, right of the dice
(const SIDE_X u16 241) ; and their middle
(const REROLL_Y u8 131)
(const MANA_Y u8 144)

; what the backdrop shows now, not game state: how far down and how far either side of its
; middle each actor's hud reaches, so a redraw cleans only that
(let pill_bottom (array u8 4) :address 0x0700) ; scratch: see AGENTS.md, Memory
(let pill_half (array u8 4) :address 0x0704)

; the clean backdrop back over a box, from the copy in aux memory, and marked
(fn clean ((col u8) (top u8) (cols u8) (rows u8)) void
    (let picture (ptr u8) (addr_of (at bd.backdrop 0)))
    (for r u8 0 rows
        (let y u8 (+ top r))
        (let offset u16 (+ (- (at hgr.ROW y) 0x2000) (as u16 col)))
        (auxmem.read (screen.row_at screen.BACKDROP y col) (+ picture offset) (as u16 cols)))
    (scene.mark col top cols rows))

(fn clean_pixels ((x0 u16) (y0 u8) (x1 u16) (y1 u8)) void
    (let col0 u8 (screen.byte_of x0))
    (let col1 u8 (+ (screen.byte_of (- x1 1)) 1))
    (clean col0 y0 (- col1 col0) (- y1 y0)))

; a row of hud glyphs, built up and then drawn in a capsule: what it holds so far
(let glyphs (array u8 13))
(let glyph_count u8 0)

(fn start_glyphs () void
    (set glyph_count 0))

(fn put ((c u8)) void
    (if (< glyph_count 12)
        (do
            (set (at glyphs glyph_count) c)
            (set glyph_count (+ glyph_count 1)))))

(fn put_number ((n u8)) void
    (if (>= n 10)
        (put (+ '0' (/ n 10))))
    (put (+ '0' (% n 10))))

; the glyphs in a capsule centred on x; gives half the capsule's width in pixels
(fn draw_glyphs ((x u16) (top u8)) u8
    (set (at glyphs glyph_count) 0)
    (let half u8 (+ (* glyph_count 6) 3))
    (let left u16 (- x (as u16 (- half 4))))
    (pen.capsule (- x (as u16 half)) top (+ x (as u16 half)) (+ top CAPSULE_ROWS))
    (pen.text left (+ top 2) (addr_of (at glyphs 0)))
    half)

; the black band the tray sits in, over the backdrop's foot
(fn band () void
    (blit.fill screen.BACKDROP 0 BAND_TOP 40 BAND_ROWS 0)
    (scene.mark 0 BAND_TOP 40 BAND_ROWS))

; ---- under each actor: hit points and ward pips, then a row of its statuses

; a fresh backdrop: nothing drawn on it yet
(fn forget () void
    (for i u8 0 state.ACTORS
        (set (at pill_bottom i) PILL_TOP)
        (set (at pill_half i) 0)))

(fn pill ((who u8)) void
    (let x u16 (place.centre_x who))
    (let half u8 (at pill_half who))
    (if (> half 0)
        (clean_pixels (- x (as u16 half)) PILL_TOP (+ x (as u16 half)) (at pill_bottom who)))
    (set (at pill_bottom who) PILL_TOP)
    (set (at pill_half who) 0)
    ; a beaten enemy's hud goes; the hero's stays, at 0
    (if (and (not (at state.actors who alive)) (!= who state.DOG))
        (return))
    ; a heart and the hit points, then a glyph for each stack of the pip statuses
    (start_glyphs)
    (put '*')
    (put_number (at state.actors who hp))
    (for s u8 0 st.STATUS_COUNT
        (if (= (at st.SHOW s) st.Show.pips)
            (for k u8 0 (state.stack who s)
                (put (at st.GLYPH s)))))
    (set half (draw_glyphs x PILL_TOP))
    (set (at pill_bottom who) (+ PILL_TOP CAPSULE_ROWS))
    ; the status row: a glyph for each status, with its number for counts
    (start_glyphs)
    (for s u8 0 st.STATUS_COUNT
        (let n u8 (state.stack who s))
        (let show st.Show (at st.SHOW s))
        (if (and (> n 0) (or (= show st.Show.count) (= show st.Show.flag)))
            (do
                (put (at st.GLYPH s))
                (if (= show st.Show.count)
                    (put_number n)))))
    (if (> glyph_count 0)
        (do
            (let row_half u8 (draw_glyphs x STATUS_TOP))
            (if (> row_half half)
                (set half row_half))
            (set (at pill_bottom who) (+ STATUS_TOP CAPSULE_ROWS))))
    (set (at pill_half who) half)
    (scene.mark_pixels (- x (as u16 half)) PILL_TOP (+ x (as u16 half)) (at pill_bottom who)))

; ---- over each enemy: what it means to do next

(fn intent ((who u8)) void
    (let x u16 (place.centre_x who))
    (let top u8 (- (place.top who) 15))
    (clean_pixels (- x 21) top (+ x 21) (+ top 13))
    (if (not (at state.actors who alive))
        (return))
    (let row u8 (at state.actors who move))
    (let icon u8 (fx.intent_icon who row))
    (start_glyphs)
    (put icon)
    (if (= icon (at en.MOVES row icon))
        (put_number (fx.intent_amount who row)))
    (draw_glyphs x top))

; ---- the dice tray and the re-rolls

; tray slot n: a face's picture and caption, or nothing (icon art.NONE); picked, a white bar
; over it. A two-glyph caption is 22 px, a pixel wider than the picture, so the slot cleans a
; fourth column too: else that pixel stays when the next face has a narrower one
(fn slot ((n u8) (icon u8) (caption (ptr u8)) (picked bool)) void
    (let col u8 (+ TRAY_FIRST_COL (* n TRAY_STEP)))
    (let x u16 (* (as u16 col) 7))
    (blit.fill screen.BACKDROP col MARK_TOP 4 (- (+ DIGIT_TOP 9) MARK_TOP) 0)
    (if picked
        (blit.fill screen.BACKDROP col MARK_TOP 3 2 0x7F))
    (if (!= icon art.NONE)
        (do
            (blit.sprite screen.BACKDROP col TRAY_TOP icon)
            (let w u16 (pen.text_width caption))
            (if (> w 0)
                (do
                    (pen.capsule x DIGIT_TOP (+ x 22) (+ DIGIT_TOP 9))
                    (pen.text (- (+ x 11) (>> w 1)) (+ DIGIT_TOP 1) caption)))))
    (scene.mark col MARK_TOP 4 (- (+ DIGIT_TOP 9) MARK_TOP)))

(fn die ((d u8)) void
    (if (at state.played d)
        (do
            (slot d art.NONE "" false)
            (return)))
    (let face u8 (at state.hand d))
    (slot d (at faces.FACES face icon) (at faces.FACES face caption) (= state.selected d)))

; R and the re-rolls left; under it the mana as stars, filled for what the hero has, so it
; sits by the spell faces' costs
(fn side () void
    (start_glyphs)
    (put 'R')
    (put_number state.rerolls)
    (draw_glyphs SIDE_X REROLL_Y)
    (start_glyphs)
    (let mana u8 (fx.mana))
    (for k u8 0 fx.MOST_MANA
        (put (if (< k mana)
            '\''
            '&')))
    (draw_glyphs SIDE_X MANA_Y)
    (scene.mark SIDE_COL REROLL_Y (- 40 SIDE_COL) (- (+ MANA_Y CAPSULE_ROWS) REROLL_Y)))

; whatever changed since the last frame
(fn refresh () void
    ; the hero's stacks hold her mana, by the tray
    (if (!= (& state.hud_pills 1) 0)
        (set state.hud_rerolls true))
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
    (if (= state.phase state.Phase.reward)
        (return))
    (for d u8 0 state.HAND
        (if (!= (& state.hud_dice (<< 1 d)) 0)
            (die d)))
    (set state.hud_dice 0)
    (if state.hud_rerolls
        (do
            (side)
            (set state.hud_rerolls false))))
