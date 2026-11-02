; the pages over the stage: in her turn her kit (battle/bag: B, or BAG) and the rules
; (battle/rules: ?, or the ? button); between fights her kit (B, BAG), to read her faces while
; she picks. A page covers the stage and the tray's rows with black and
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
(import battle/reward)
(import battle/rules)
(import battle/history)
(import battle/map)
(import battle/log)
(import battle/tray)
(import sound/sound)

(const COVER_ROWS u8 160)  ; the stage and the tray
(const STAGE_LINES u8 120) ; the rules' fifteen lines
(const PILL_TOP u8 130)
(const PILL_END u8 150)
(const PILL_H u8 20)
; the buttons' stretches of pixels (battle/boxes takes clicks on them)
(const BACK_X u8 3)
(const NEXT_X u8 55)
(const NAV_W u8 47)
(const CLOSE_X u8 107)
(const CLOSE_W u8 30)
(const TEXT_TOP u8 138) ; a pill's word, 5 rows
(const BLACK u8 0)
(const MAGENTA u8 1)
(const PINK u8 11)
(const WHITE u8 15)

; key in her turn (rules) or between fights: B opens her kit, ? the rules (in her turn); gives
; whether it opens one. It is drawn at the next step (step: fresh), so only the pages' own code
; draws pages, and it loads with them (an overlay group), whatever screen opened one
(let fresh bool false)

(fn opens ((key u8) (in_turn bool)) bool
    (let p state.Page state.Page.none)
    (if (= (& key 0xDF) 'B')
        (set p state.Page.bag))
    (if in_turn
        (do
            (if (= key '?')
                (set p state.Page.rules))
            (if (= (& key 0xDF) 'H')
                (set p state.Page.log))))
    (if (= p state.Page.none)
        (return false))
    (set state.page p)
    (set fresh true)
    true)

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
                (pill_row y BACK_X (+ BACK_X NAV_W) "BACK" 4)
                (pill_row y NEXT_X (+ NEXT_X NAV_W) "NEXT" 4)))
        (pill_row y CLOSE_X (+ CLOSE_X CLOSE_W) "CLOSE" 5)
        (pix.write screen.PAGE y))
    (scene.mark (<< g0 1) PILL_TOP (<< (- 20 g0) 1) (- PILL_END PILL_TOP)))

(fn open ((p state.Page)) void
    (sound.cue sound.Cue.confirm)
    ; the rules' lines cover the stage's first 120 rows whole: only the rest is filled black
    (let top u8 (if (= p state.Page.rules)
        STAGE_LINES
        0))
    (dhgr.box screen.PAGE 0 top 40 (- COVER_ROWS top) BLACK)
    (scene.mark 0 top 40 (- COVER_ROWS top))
    (match p
        (state.Page.bag
            (bag.open)
            (buttons false))
        (state.Page.log
            (history.open)
            (buttons false))
        (state.Page.won (bag.won))
        (_
            (rules.open)
            (buttons true))))

; one frame with a page open
(fn step ((key u8)) void :overlay
    (if fresh
        (do
            (set fresh false)
            (open state.page)
            (return)))
    (let close bool (match state.page
        (state.Page.bag (bag.key key))
        (state.Page.log (history.key key))
        (state.Page.won false) ; battle.step takes the key: the title
        (_ (rules.key key))))
    (if close
        (shut)))

; the page closed: the stage and the tray's rows as the fight's picture has them, the map, then
; the tray, the text and the looks drawn again as they are; between fights the reward's next
; step draws its own again (reward.reshow)
(fn shut () void
    (set state.page state.Page.none)
    (sound.cue sound.Cue.blip)
    (screen.copy_box screen.PAGE 0 0 40 COVER_ROWS screen.SPARE)
    (scene.forget)
    (map.draw)
    (tray.forget)
    (if (= state.phase state.Phase.reward)
        (do
            (set reward.reshow true)
            (return)))
    (set state.hud_dice 0x3F)
    (set state.hud_rerolls true)
    (set state.hud_words true)
    (log.reshow))
