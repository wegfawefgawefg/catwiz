; what a click hits (main.next_key: a click comes to the screen as the key of what it hit): the
; boxes of everything on the screen now that takes a click, made when the click is taken from
; what the screen shows then, with the numbers its drawing uses, so a box is always where its
; picture is. In a fight: the buttons by the tray, the dice cards, the cat and each enemy
; where it stands, the log's rows. On a page: its cards and buttons. Between fights: the cards
; in the tray, BAG, and for a bonus upgrade her six faces on the stage. The first box that holds
; the click gives its key; a click on nothing gives '.', a tap on the stage. Keys are the
; keyboard's, so a click does just what its key does.

(import state)
(import art/hud_data hud)
(import art/sprites art)
(import battle/bag)
(import battle/kit)
(import battle/page)
(import battle/reward)
(import battle/tray)

; the actors' keys: the cat M, the enemies Z X C (battle/turn)
(const ACTOR_KEY (array u8 4) (make (array u8 4) 'M' 'Z' 'X' 'C'))
(const LOG_TOP u8 176) ; the log's two text rows (battle/log), to the foot of the screen

(let px u8 0) ; the click, in whole pixels
(let py u8 0)
(let hit u8 0) ; the key of the first box that holds it, 0 for none yet

; a box: its top left pixel x, row y, its size w by h, and its key
(fn box ((x u8) (y u8) (w u8) (h u8) (k u8)) void
    (if (and (= hit 0) (and (and (>= px x) (< px (+ x w))) (and (>= py y) (< py (+ y h)))))
        (set hit k)))

; tray slot n's box, from the tray's top to its foot (battle/tray: 5 byte columns a slot)
(fn slot ((n u8) (k u8)) void
    (box (>> (* n 35) 1) hud.TRAY_TOP 18 hud.TRAY_ROWS k))

; the key of what pixel x, row y holds
(fn key_at ((x u8) (y u8)) u8
    (set px x)
    (set py y)
    (set hit 0)
    (if (= state.screen state.Screen.battle)
        (match state.page
            (state.Page.none
                (if (= state.phase state.Phase.reward)
                    (between)
                    (fight)))
            (state.Page.bag (kit_page))
            (_ (rules_page))))
    (if (= hit 0)
        '.'
        hit))

; ---- a fight

; who's box: its idle frame where it stands (battle/place), 3.5 pixels a byte column
(fn actor ((who u8)) void
    (if (not (at state.actors who alive))
        (return))
    (let kind u8 (at state.actors who figure))
    (let col u8 (at state.actors who home))
    (let top u8 (at art.KIND_TOP kind))
    (box (+ (* col 3) (>> col 1))
        top
        (>> (* (at art.KIND_COLS kind) 7) 1)
        (- (at art.KIND_FEET kind) top)
        (at ACTOR_KEY who)))

(fn fight () void
    ; BAG and ? first: they are inside the re-roll button's box
    (box tray.SMALL_X tray.BAG_TOP tray.SMALL_W tray.SMALL_H 'B')
    (box tray.SMALL_X tray.RULES_TOP tray.SMALL_W tray.SMALL_H '?')
    (box tray.SIDE_X hud.TRAY_TOP tray.SIDE_W tray.REROLL_H 'R')
    (box tray.SIDE_X tray.END_TOP tray.SIDE_W (- tray.SIDE_END tray.END_TOP) 'E')
    (for n u8 0 state.DICE_MOST
        (slot n (+ '1' n)))
    (for i u8 0 state.ACTORS
        (actor (- 3 i)))
    (box 0 LOG_TOP 140 (- 192 LOG_TOP) 'H'))

; ---- between fights: the cards to pick, BAG, and her faces for a bonus upgrade

(fn between () void
    (box tray.SMALL_X tray.BAG_TOP tray.SMALL_W tray.SMALL_H 'B')
    (for n u8 0 reward.choices
        (slot n (+ '1' n)))
    (if (= state.pick state.Pick.nap_slot)
        (for k u8 0 state.SLOTS
            (box (kit.cell_x k) (kit.cell_top k) kit.WIDE kit.ROWS (+ '1' k)))))

; ---- the pages: CLOSE where END TURN was, the rules' BACK and NEXT (battle/page)

(fn close_button () void
    (box page.CLOSE_X page.PILL_TOP page.CLOSE_W page.PILL_H 'E'))

; her kit: the six faces' cards in the tray's places, her charms on the stage
(fn kit_page () void
    (for n u8 0 state.SLOTS
        (box (>> (* n 35) 1) bag.SLOT_TOP kit.WIDE kit.ROWS (+ '1' n)))
    (for k u8 0 bag.held_n
        (box (at bag.CHARM_X k) (at bag.CHARM_Y k) kit.WIDE kit.MARK_ROWS (at ACTOR_KEY k)))
    (close_button))

(fn rules_page () void
    (box page.BACK_X page.PILL_TOP page.NAV_W page.PILL_H '1')
    (box page.NEXT_X page.PILL_TOP page.NAV_W page.PILL_H '4')
    (close_button))
