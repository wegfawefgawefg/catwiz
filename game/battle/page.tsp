; the pages over the stage in her turn: her kit (battle/bag: B, or BAG) and the rules
; (battle/rules: ?, or the ? button). A page covers the stage and the tray's rows with black and
; draws itself there, with CLOSE where the re-roll and END TURN buttons were (their tap boxes, R
; and E, close it); the fight waits under it (battle.step goes no further while one is open, and
; no look is drawn). Closing puts the stage back from the spare page (the fight's picture stays
; there all fight: battle.load_art), then the map, the tray, the text, and every look again.

(import dhgr)
(import state)
(import draw/pix)
(import draw/screen)
(import draw/scene)
(import battle/bag)
(import battle/rules)
(import battle/map)
(import battle/log)
(import battle/tray)
(import sound/sound)

(const COVER_ROWS u8 160)  ; the stage and the tray
(const STAGE_LINES u8 120) ; the rules' fifteen lines
(const PILL_TOP u8 130)
(const PILL_END u8 150)
(const TEXT_TOP u8 138) ; a pill's word, 5 rows
(const BLACK u8 0)
(const MAGENTA u8 1)
(const PINK u8 11)
(const WHITE u8 15)

; key in her turn: B opens her kit, ? the rules; gives whether it opened one
(fn opens ((key u8)) bool
    (if (= (& key 0xDF) 'B')
        (do
            (open state.Page.bag)
            (return true)))
    (if (= key '?')
        (do
            (open state.Page.rules)
            (return true)))
    false)

; row y's part of a pill from pixel x0 to x1 - 1 with the word s (n glyphs) on it
(fn pill_row ((y u8) (x0 u8) (x1 u8) (s (ptr u8)) (n u8)) void
    (let inset u8 (if (or (= y PILL_TOP) (= y (- PILL_END 1)))
        1
        0))
    (pix.span (+ x0 inset) (- x1 inset) MAGENTA)
    (if (= y (+ PILL_TOP 1))
        (pix.span (+ x0 2) (- x1 2) PINK))
    (if (and (>= y TEXT_TOP) (< y (+ TEXT_TOP 5)))
        (pix.glyphs (- (+ x0 (>> (- x1 x0) 1)) (>> (pix.glyphs_width s n) 1))
            s
            n
            (- y TEXT_TOP)
            WHITE)))

; the page's buttons in the tray's rows (black there: open filled them), drawn over the stretch
; they take: CLOSE on the right, and for the rules BACK (over the first three dice' tap boxes) and
; NEXT (the last three)
(fn buttons ((nav bool)) void
    (let g0 u8 (if nav
        0
        15))
    (pix.begin g0 (- 20 g0))
    (for y u8 PILL_TOP PILL_END
        (pix.fill BLACK)
        (if nav
            (do
                (pill_row y 3 50 "BACK" 4)
                (pill_row y 55 102 "NEXT" 4)))
        (pill_row y 106 140 "CLOSE" 5)
        (pix.write screen.PAGE y))
    (scene.mark (<< g0 1) PILL_TOP (<< (- 20 g0) 1) (- PILL_END PILL_TOP)))

(fn open ((p state.Page)) void
    (set state.page p)
    (sound.cue sound.Cue.confirm)
    ; the rules' lines cover the stage's first 120 rows whole: only the rest is filled black
    (let top u8 (if (= p state.Page.bag)
        0
        STAGE_LINES))
    (dhgr.box screen.PAGE 0 top 40 (- COVER_ROWS top) BLACK)
    (scene.mark 0 top 40 (- COVER_ROWS top))
    (match p
        (state.Page.bag
            (bag.open)
            (buttons false))
        (_
            (rules.open)
            (buttons true))))

; one frame with a page open
(fn step ((key u8)) void
    (let close bool (if (= state.page state.Page.bag)
        (bag.key key)
        (rules.key key)))
    (if close
        (shut)))

; the page closed: the stage and the tray's rows as the fight's picture has them, the map, then
; the tray, the text and the looks drawn again as they are
(fn shut () void
    (set state.page state.Page.none)
    (sound.cue sound.Cue.blip)
    (screen.copy_box screen.PAGE 0 0 40 COVER_ROWS screen.SPARE)
    (scene.forget)
    (map.draw)
    (tray.forget)
    (set state.hud_dice 0x3F)
    (set state.hud_rerolls true)
    (set state.hud_words true)
    (log.reshow))
