; the hud: a badge of hit points (and statuses) under each actor and an intent badge over each
; enemy, both looks drawn over the stage (draw/badge, draw/scene); the dice tray at the foot of
; the stage and the buttons by it, drawn into the backdrop page (battle/tray). Each part is
; drawn again when its flag in state says it changed. The words are at the bottom
; (battle/words, log).

(import dhgr)
(import state)
(import art/sprites art)
(import art/icons)
(import draw/pix)
(import draw/text)
(import battle/place)
(import battle/tray)
(import content/action ac)
(import content/items)
(import content/cards)
(import content/effects fx)
(import content/foes)
(import content/moves mv)
(import content/statuses st)

(const HP_TOP u8 112) ; a standing actor's hit point badge, under its feet

; ---- badges: a badge's glyphs are put in state.badge_glyphs, then it becomes a look

(let filling u8 0) ; the badge being filled
; what it showed before, so a badge filled the same again is not drawn again (each drawing is
; a read and a write of its rows on both pages)
(let was (array u8 8) :address 0x0700) ; scratch: see AGENTS.md, Memory
(let was_count u8 0)

(fn start_glyphs ((b u8)) void
    (set filling b)
    (set was_count (at state.badge_count b))
    (for k u8 0 state.BADGE_MOST
        (set (at was k) (at state.badge_glyphs (+ (* b state.BADGE_MOST) k))))
    (set (at state.badge_count b) 0))

; whether badge b holds what it held before start_glyphs
(fn unchanged ((b u8)) bool
    (if (!= (at state.badge_count b) was_count)
        (return false))
    (for k u8 0 was_count
        (if (!= (at was k) (at state.badge_glyphs (+ (* b state.BADGE_MOST) k)))
            (return false)))
    true)

(fn put ((c u8)) void
    (let n u8 (at state.badge_count filling))
    (if (< n state.BADGE_MOST)
        (do
            (set (at state.badge_glyphs (+ (* filling state.BADGE_MOST) n)) c)
            (set (at state.badge_count filling) (+ n 1)))))

; n in up to three digits (every number is a byte: 255 at most)
(fn put_number ((n u8)) void
    (text.digits n)
    (if (> text.hundreds 0)
        (put (+ '0' text.hundreds)))
    (if (or (> text.hundreds 0) (> text.tens 0))
        (put (+ '0' text.tens)))
    (put (+ '0' text.ones)))

; the badge just filled, centred on pixel cx with its top at top, as look: its box the groups
; of pixels the pill covers
(fn finish ((look u8) (cx u8) (top u8)) void
    (let b u8 filling)
    (let n u8 (at state.badge_count b))
    (let w u8 (+ (pix.glyphs_width (addr_of (at state.badge_glyphs (* b state.BADGE_MOST))) n) 4))
    (let half u8 (>> w 1))
    (let x0 u8 (if (> cx half)
        (- cx half)
        0))
    (if (> (+ x0 w) 140)
        (set x0 (- 140 w)))
    ; shown already, the same and in the same place: nothing to draw
    (if (and (and (= (at state.looks look sprite) state.BADGE) (= (at state.looks look top) top))
            (and (= (at state.badge_x b) x0) (unchanged b)))
        (return))
    (set (at state.badge_x b) x0)
    (set (at state.badge_stamp b) (+ (at state.badge_stamp b) 1))
    (let g0 u8 (at dhgr.X_GROUP x0))
    (let g1 u8 (at dhgr.X_GROUP (- (+ x0 w) 1)))
    (set (at state.looks look)
        (make state.Look
            :sprite state.BADGE
            :col (<< g0 1)
            :top top
            :second (at state.badge_stamp b)
            :white false
            :wide (<< (+ (- g1 g0) 1) 1))))

(fn hide ((look u8)) void
    (set (at state.looks look)
        (make state.Look
            :sprite state.NOTHING
            :col 0
            :top 0
            :second state.NOTHING
            :white false
            :wide 0)))

; under who: a heart and the hit points, a pip for each ward, then a glyph for each status
; with its number for counts. A beaten enemy's badge goes; the hero's stays, at 0
(fn pill ((who u8)) void
    (let look u8 (+ state.LOOK_HP who))
    (if (and (not (at state.actors who alive)) (!= who state.HERO))
        (do
            (hide look)
            (return)))
    (start_glyphs who)
    (put '*')
    (put_number (at state.actors who hp))
    ; its stacks read straight from the table (state.stack is a call when the build is squeezed)
    (let first u8 (at state.FIRST_STACK who))
    (for s u8 0 st.STATUS_COUNT
        (let n u8 (at state.stacks (+ first s)))
        (let show st.Show (at st.SHOW s))
        (if (= show st.Show.pips)
            (for k u8 0 n
                (put (at st.GLYPH s))))
        (if (and (> n 0) (or (= show st.Show.count) (= show st.Show.flag)))
            (do
                (put (at st.GLYPH s))
                (if (= show st.Show.count)
                    (put_number n)))))
    ; a flyer's badge just under it, a standing one's on the ground below
    (let top u8 HP_TOP)
    (if (< (place.feet who) 100)
        (set top (+ (place.feet who) 2)))
    (finish look (place.centre_x who) top))

; over enemy who: what it means to do next, the move's glyph and how much
(fn intent ((who u8)) void
    (let look u8 (- (+ state.LOOK_INTENT who) 1))
    (if (not (at state.actors who alive))
        (do
            (hide look)
            (return)))
    (let row u8 (at state.actors who move))
    (let icon u8 (foes.intent_icon who row))
    (start_glyphs (- (+ state.ACTORS who) 1))
    (put icon)
    (if (and (= icon (mv.icon row)) (foes.shows_amount row))
        (put_number (foes.intent_amount who row)))
    (finish look (place.centre_x who) (- (place.top who) 12)))

; a fresh fight: no badges yet, the tray empty
(fn forget () void
    (for i u8 0 state.BADGES
        (hide (+ state.LOOK_HP i)))
    (tray.forget))

; ---- the dice tray and the re-rolls

; the number under a face's picture: its number at its slot's level (a plus, a copy, a knead
; with a +, a times with an X), none for the hairball; built here (the tray keeps its own copy)
(let cap_text (array u8 3) :address 0x03CA)

; (the most a face's number is at two levels: 14, Knock It Off's; a trick's 4)
(fn caption ((row u8)) (ptr u8)
    (let n u8 (fx.number row))
    (if (> n 15)
        (set n 15))
    (let tags u8 (cards.tags row))
    (let k u8 0)
    (set (at cap_text 0) 0)
    (if (!= (& tags ac.CAP_NONE) 0)
        (return (addr_of (at cap_text 0))))
    (if (!= (& tags (| ac.CAP_TIMES ac.CAP_PLUS)) 0)
        (do
            (set (at cap_text 0) (if (!= (& tags ac.CAP_TIMES) 0)
                'X'
                '+'))
            (set k 1)
            (if (> n 9)
                (set n 9))))
    (if (>= n 10)
        (do
            (set (at cap_text k) '1')
            (set k (+ k 1))
            (set n (- n 10))))
    (set (at cap_text k) (+ '0' n))
    (set (at cap_text (+ k 1)) 0)
    (addr_of (at cap_text 0)))

; die d's card: none past the dice she rolls, a paw on it while an enemy holds it (picked, the
; rows say who: battle/words), a blank card once it is played
(fn die ((d u8)) void
    (if (>= d state.dice_n)
        (do
            (tray.slot d false state.NOTHING "" false)
            (return)))
    (if (!= (at state.held d) state.NOTHING)
        (do
            (tray.slot d true icons.TILE_GRABBED "" false)
            (return)))
    (if (at state.played d)
        (do
            (tray.slot d true state.NOTHING "" false)
            (return)))
    (let row u8 (at state.hand d))
    (tray.slot d true (items.icon row) (caption row) (= state.selected d)))

; whatever changed since the last frame; gives whether the tray drew anything
(fn refresh () bool
    ; the hero's stacks hold her mana, by the tray
    (if (!= (& state.hud_pills 1) 0)
        (set state.hud_rerolls true))
    (for i u8 0 state.ACTORS
        (let bit u8 (<< 1 i))
        (if (or (= i state.HERO) (!= (at state.actors i kind) state.NOTHING))
            (do
                (if (!= (& state.hud_pills bit) 0)
                    (pill i))
                (if (and (!= i state.HERO) (!= (& state.hud_intents bit) 0))
                    (intent i)))))
    (set state.hud_pills 0)
    (set state.hud_intents 0)
    (if (= state.phase state.Phase.reward)
        (return (tray.flush)))
    (for d u8 0 state.DICE_MOST
        (if (!= (& state.hud_dice (<< 1 d)) 0)
            (die d)))
    (set state.hud_dice 0)
    (let drew bool (tray.flush))
    (if state.hud_rerolls
        (do
            (tray.side state.rerolls (fx.mana) st.MOST_MANA state.mana_shake)
            (set state.hud_rerolls false)))
    drew)
