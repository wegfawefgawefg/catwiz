; what comes between fights, after a won one: one of five cards drawn at random (battle/offer:
; a face for a slot, or a level on a slot); after an elite, one of three charms drawn too, then
; the nap (hit points back) or a bonus upgrade (a level on a slot of her choice); and the two
; doors before a fight that has another. The choices are cards in the tray's slots (1-5, the six
; slots for a bonus upgrade), each card's lines on the text rows when it is picked; the stage
; shows her six slots (battle/kit), the one a card changes picked out, so she always sees what she
; is changing. As in battle, a number key (a tap) picks a card and shows its text, the same key
; again (or RETURN) takes it; ESC lets go.

(import apple2 a2)
(import state)
(import art/icons)
(import draw/text)
(import battle/tray)
(import battle/kit)
(import battle/offer)
(import battle/card_words cw)
(import content/action ac)
(import content/charms)
(import content/effects fx)
(import content/encounters enc)
(import content/enemies en)
(import content/items)
(import sound/sound)

(const UP u8 128) ; a card of 128 + a slot: a level on that slot (offer.UP)

; the step's choices: cards (a face's id or UP + a slot, and its slot), charms' ids, sleep and
; dream, slots, or fight rows (doors). A card's face is offer row items.OFFER_ROW + n, a charm's
; items.OFFER_CHARM_ROW + n
(let choice (array u8 6) :address 0x06DC)
(let choice_slot (array u8 6))
(let choices u8 0)

; the screen's words, in aux memory (text.add_aux): SAY_ and their words
(const SAY (array (ptr u8) 21)
    (make (array (ptr u8) 21)
        "A reward: pick a card, S to skip."
        "Five faces. Tap one to read it."
        "A charm: pick one, or S to skip."
        "A rest: pick one, or S to skip."
        "1 Nap: # hit points back"
        "2 Bonus upgrade: +1 on a face"
        "Upgrade: +1 on which face? (1-6)"
        "ESC: back to the rest. S: skip."
        "Two doors. Pick one (1-2)."
        " is at its most."
        "+1 on the face: "
        "You have it: +1 on "
        "Replaces: "
        "A charm works all run."
        "NAP"
        "# hit points back,"
        "up to #."
        "BONUS UPGRADE"
        "+1 on a face of your choice."
        "# hit points"
        "Ward #")
    :strings aux)

(const SAY_REWARD u8 0)
(const SAY_FIVE u8 1)
(const SAY_CHARM u8 2)
(const SAY_REST u8 3)
(const SAY_NAP_BACK u8 4)
(const SAY_BONUS u8 5)
(const SAY_WHICH_SLOT u8 6)
(const SAY_BACK_REST u8 7)
(const SAY_DOORS u8 8)
(const SAY_AT_MOST u8 9)
(const SAY_ON_SLOT u8 10)
(const SAY_HAVE_IT u8 11)
(const SAY_REPLACES u8 12)
(const SAY_ALL_RUN u8 13)
(const SAY_NAP u8 14)
(const SAY_HP_BACK u8 15)
(const SAY_UP_TO u8 16)
(const SAY_BONUS_UPGRADE u8 17)
(const SAY_YOUR_CHOICE u8 18)
(const SAY_HP u8 19)
(const SAY_WARD u8 20)

; the keys of her six faces on the stage, clicked (battle/boxes): her kit's page opens on that
; face (battle.step), to read it before she picks
(const FACE_KEY u8 0x11)

; what comes between fights starts (battle.ending): the draws for all of it now, five cards and
; after an elite three charms, and their records read (code only the ending's overlay group has,
; so the reward's group is smaller); the reward's first step draws its screen (fresh)
(let fresh bool false)
(let cards (array u8 5) :address 0x0172) ; the cards drawn (offer.drawn keeps the charms), and their slots
(let card_slots (array u8 5) :address 0x0177)
(let cards_n u8 0)

(fn start () void :overlay
    (set state.phase state.Phase.reward)
    (set state.selected state.NOTHING)
    (set state.next_fight (+ state.stage 1))
    (set reshow false)
    (set fresh true)
    (set cards_n (offer.draw false))
    (for k u8 0 cards_n
        (set (at cards k) (at offer.drawn k))
        (set (at card_slots k) (at offer.drawn_slot k)))
    (if (enc.elite state.fight)
        (do
            ; ninth life: her most hit points grow after each elite
            (charms.grow_hp (charms.amount enc.CharmKind.ninth))
            (offer.draw true))))

; her kit's page closed (battle/page): the step as it was, drawn again over the fight's picture:
; the BAG button, her six faces on the stage, the choices, the text (the pick's, if one is)
(let reshow bool false)

(fn show_again () void
    (set reshow false)
    (tray.clear_side)
    (tray.skip_button (!= state.pick state.Pick.door))
    (kit.show)
    (draw_cards)
    (if (= state.picked state.NOTHING)
        (do
            (kit.preview state.NOTHING state.NOTHING false)
            (prompt))
        (set due state.picked)))

; a step: its choices in the tray, its prompt in the text
(fn go ((pick state.Pick)) void
    (let again bool (= pick state.pick))
    (set state.pick pick)
    (set state.picked state.NOTHING)
    (set due state.NOTHING)
    (set staged state.NOTHING)
    (set choices 0)
    (match pick
        (state.Pick.cards
            (for k u8 0 cards_n
                (add (at cards k) (at card_slots k))))
        (state.Pick.charms
            (for k u8 0 offer.count
                (add (at offer.drawn k) 0)))
        (state.Pick.nap
            (add 0 0)
            (add 1 0))
        (state.Pick.nap_slot
            (for k u8 0 state.SLOTS
                (add (+ UP k) k)))
        (state.Pick.door
            (add state.next_fight 0)
            (add (enc.other state.next_fight) 0)))
    (if (not (or (= pick state.Pick.cards) (= pick state.Pick.charms)))
        (set loaded choices)
        (if (not again)
            (set loaded 0)))
    (kit.preview state.NOTHING state.NOTHING false)
    (tray.skip_button (!= pick state.Pick.door))
    (draw_cards)
    (prompt))

; the choices whose cards are up: a card's or charm's record is read into its offer row (content/
; items) a step at a time as the step starts, and its card shown then (a read takes about a
; fifth of a second: the prompt and her faces show first). Back to the same step keeps them
(let loaded u8 0)

(fn load_next () void
    (if (>= loaded choices)
        (return))
    (let c u8 (at choice loaded))
    (match state.pick
        (state.Pick.cards
            (if (< c UP)
                (items.read (+ items.OFFER_ROW loaded) c false)))
        (state.Pick.charms (items.read (+ items.OFFER_CHARM_ROW loaded) c true))
        (_))
    (set loaded (+ loaded 1))
    (draw_card (- loaded 1))
    (tray.flush))

(fn add ((c u8) (slot u8)) void
    (set (at choice choices) c)
    (set (at choice_slot choices) slot)
    (set choices (+ choices 1)))

; card choice n (a card, or a slot's upgrade for the bonus): its slot, whether it is a level (else
; a new face there), whether it can be taken, and the row whose face it shows: her slot's for a
; level, else its offer row
(fn card_slot ((n u8)) u8
    (at choice_slot n))

(fn card_levels ((n u8)) bool
    (offer.levels (at choice n) (card_slot n)))

(fn card_ok ((n u8)) bool
    (offer.ok (at choice n) (card_slot n)))

(fn card_row ((n u8)) u8
    (if (card_levels n)
        (return (card_slot n)))
    (+ items.OFFER_ROW n))

; ---- the tray: a card for each choice, in the tray's slots (the dice's places)

(fn draw_card ((n u8)) void
    (let picked bool (= n state.picked))
    (if (>= n loaded)
        (do
            (tray.slot n false state.NOTHING "" false)
            (return)))
    (let c u8 (at choice n))
    (let tile u8 icons.TILE_DOOR)
    (let caption (ptr u8) "")
    (match state.pick
        (state.Pick.cards
            (set tile (card_row n))
            (if (>= c UP)
                (set caption "+1")))
        (state.Pick.charms
            (set tile (+ items.OFFER_CHARM_ROW n))
            (set caption (charms.mark tile)))
        (state.Pick.nap
            (set tile (if (= c 0)
                icons.TILE_NAP
                icons.TILE_PLUS1)))
        (state.Pick.nap_slot (set tile (card_slot n)))
        (state.Pick.door))
    (tray.slot n true tile caption picked))

(fn draw_cards () void
    (for n u8 0 state.DICE_MOST
        (draw_card n)))

; ---- the text

; s is one of SAY's
(fn row ((r u8) (s (ptr u8)) (n u8)) void
    (cw.row r s n))

; the step's prompt, nothing picked: rows 0 to 3
(fn prompt () void
    (match state.pick
        (state.Pick.cards
            (row 0 (at SAY SAY_REWARD) 0)
            (row 1 (at SAY SAY_FIVE) 0))
        (state.Pick.charms
            (row 0 (at SAY SAY_CHARM) 0)
            (choice_rows))
        (state.Pick.nap
            (row 0 (at SAY SAY_REST) 0)
            (row 1 (at SAY SAY_NAP_BACK) (- (healed) state.hero_hp))
            (row 2 (at SAY SAY_BONUS) 0))
        (state.Pick.nap_slot
            (row 0 (at SAY SAY_WHICH_SLOT) 0)
            (row 1 (at SAY SAY_BACK_REST) 0))
        (state.Pick.door
            (row 0 (at SAY SAY_DOORS) 0)
            (choice_rows)))
    (cw.rest))

; rows 1 on: each choice's key and name (a charm; a door's first enemy): three at most
(fn choice_rows () void
    (for k u8 0 choices
        (text.start)
        (text.char (+ '1' k))
        (text.char ' ')
        (if (= state.pick state.Pick.charms)
            (text.add_aux (items.name (+ items.OFFER_CHARM_ROW k)))
            (text.add_aux (en.name (enc.first_enemy (at choice k)))))
        (cw.show (+ k 1))))

; the card choice n makes of its slot, in the balance's four lines: what it is, the slot's base
; at its level, the item's line, what it replaces (or the level it gives); a new face on a slot
; with levels says how they make its number (they stay with the slot: card_words)
(fn describe_card ((n u8)) void
    (let slot u8 (card_slot n))
    (let level u8 (at state.levels slot))
    (let up bool (>= (at choice n) UP))
    (if (card_levels n)
        (do
            (cw.title
                (if up
                    (at cw.SLOT_NAME slot)
                    (items.name slot))
                up)
            (if (not (card_ok n))
                (do
                    (if (< (cw.item_lines slot slot level false) text.ROWS)
                        (do
                            (text.start)
                            (text.add_aux (at cw.SLOT_NAME slot))
                            (text.add_aux (at SAY SAY_AT_MOST))
                            (cw.show 3)))
                    (return)))
            (if (< (cw.item_lines slot slot (+ level 1) false) text.ROWS)
                (do
                    (text.start)
                    (text.add_aux (if up
                        (at SAY SAY_ON_SLOT)
                        (at SAY SAY_HAVE_IT)))
                    (text.add_aux (items.name slot))
                    (cw.show 3)))
            (return)))
    (let r u8 (+ items.OFFER_ROW n))
    (cw.title (items.name r) false)
    (let next u8 (cw.item_lines slot r level true))
    (if (< next text.ROWS)
        (do
            (text.start)
            (text.add_aux (at SAY SAY_REPLACES))
            (text.add_aux (items.name slot))
            (cw.show next))))

; choice n's text, picked: rows 0 to 3
(fn describe ((n u8)) void
    (let c u8 (at choice n))
    (match state.pick
        (state.Pick.cards (describe_card n))
        (state.Pick.nap_slot (describe_card n))
        (state.Pick.charms
            (let r u8 (+ items.OFFER_CHARM_ROW n))
            (cw.title (items.name r) false)
            (cw.item_row 1 (items.text r) (items.amount r))
            (row 2 (at SAY SAY_ALL_RUN) 0))
        (state.Pick.nap
            (if (= c 0)
                (do
                    (cw.title (at SAY SAY_NAP) false)
                    (row 1 (at SAY SAY_HP_BACK) (- (healed) state.hero_hp))
                    (row 2 (at SAY SAY_UP_TO) (healed)))
                (do
                    (cw.title (at SAY SAY_BONUS_UPGRADE) false)
                    (row 1 (at SAY SAY_YOUR_CHOICE) 0))))
        (state.Pick.door
            (let kind u8 (enc.first_enemy c))
            (cw.title (en.name kind) false)
            (row 1 (at SAY SAY_HP) (en.hp kind))
            (row 2 (at SAY SAY_WARD) (en.ward kind))))
    (cw.rest))

; her hit points after a nap: the ones she is missing, shifted right enc.NAP_HEAL_SHIFT (rounded
; up), back
(fn healed () u8
    (let missing u8 (- state.hero_max state.hero_hp))
    (let part u8 (>> (+ missing (- (<< 1 enc.NAP_HEAL_SHIFT) 1)) enc.NAP_HEAL_SHIFT))
    (+ state.hero_hp part))

; the slot choice n changes, shown on the stage: the card's face in it, or its next level
(fn show_change ((n u8)) void
    (match state.pick
        (state.Pick.cards
            (kit.preview (card_slot n) (card_row n) (and (card_levels n) (card_ok n))))
        (state.Pick.nap_slot (kit.preview (card_slot n) (card_slot n) (card_ok n)))
        (_ (kit.preview state.NOTHING state.NOTHING false))))

; ---- taking

; after the cards: after an elite a charm, then the rest; then the doors; gives true when all is
; done
(fn after_cards () bool
    (if (enc.elite state.fight)
        (do
            (go state.Pick.charms)
            (if (> choices 0)
                (return false))))
    (after_charms))

(fn after_charms () bool
    (if (enc.elite state.fight)
        (do
            (go state.Pick.nap)
            (return false)))
    (after_nap))

(fn after_nap () bool
    (if (and (< state.next_fight enc.FIGHT_COUNT) (!= (enc.other state.next_fight) state.NOTHING))
        (do
            (go state.Pick.door)
            (return false)))
    true)

; a level on slot
(fn level_up ((slot u8)) void
    (set (at state.levels slot) (+ (at state.levels slot) 1)))

; choice n is taken. Gives true when all is done and the next fight can start. A new face's
; record is read into her slot's row (content/items), a charm's into her charms'
(fn take ((n u8)) bool
    (let c u8 (at choice n))
    ; a pick not drawn yet is not drawn: the step changes or ends
    (set due state.NOTHING)
    (set staged state.NOTHING)
    (match state.pick
        (state.Pick.cards
            (if (not (card_ok n))
                (do
                    (sound.cue sound.Cue.nope)
                    (return false)))
            (let slot u8 (card_slot n))
            (if (card_levels n)
                (level_up slot)
                (do
                    (set (at state.items slot) c)
                    (items.read slot c false)))
            (kit.show)
            (after_cards))
        (state.Pick.charms
            (charms.take c)
            (after_charms))
        (state.Pick.nap
            (if (= c 1)
                (do
                    (go state.Pick.nap_slot)
                    (return false)))
            (set state.hero_hp (healed))
            (set (at state.actors state.HERO hp) state.hero_hp)
            (set state.hud_pills (| state.hud_pills 1))
            (after_nap))
        (state.Pick.nap_slot
            (if (not (card_ok n))
                (do
                    (sound.cue sound.Cue.nope)
                    (return false)))
            (level_up (card_slot n))
            (kit.show)
            (after_nap))
        (state.Pick.door
            (set state.next_fight c)
            true)))

; choice n picked: its text and the slot it changes; picked again, taken
(fn pick ((n u8)) bool
    (if (>= n loaded)
        (do
            (sound.cue sound.Cue.nope)
            (return false)))
    (if (= n state.picked)
        (do
            (sound.cue sound.Cue.confirm)
            (return (take n))))
    (let was u8 state.picked)
    (set state.picked n)
    (if (!= was state.NOTHING)
        (draw_card was))
    (draw_card n)
    (set due n)
    (sound.cue sound.Cue.blip)
    false)

; the text and the stage of the choice picked, drawn after its card lifts, so the pick shows at
; once: its text at the next step (here: code only these steps reach loads with them, an overlay
; group, out of main memory), the slot it changes on the stage in that frame's drawing (refresh)
(let due u8 255)
(let staged u8 255)

(fn describe_due () void
    (if (= due state.NOTHING)
        (return))
    (describe due)
    (set staged due)
    (set due state.NOTHING))

(fn refresh () void
    (if (= staged state.NOTHING)
        (return))
    (show_change staged)
    (set staged state.NOTHING))

; one frame of what comes between fights; true when it is done and the next fight can start
(fn step ((key u8)) bool :overlay_disk2
    (if fresh
        (do
            (set fresh false)
            (tray.clear_side)
            (kit.show)
            (set loaded 0)
            (set state.pick state.Pick.cards)
            (go state.Pick.cards)))
    (if reshow
        (show_again))
    (describe_due)
    (load_next)
    (if (and (>= key '1') (< key (+ '1' choices)))
        (return (pick (- key '1'))))
    (if (= (& key 0xDF) 'S')
        (return (skip)))
    (match key
        (0 false)
        (a2.KEY_RETURN
            (if (= state.picked state.NOTHING)
                (do
                    (sound.cue sound.Cue.nope)
                    (return false)))
            (pick state.picked))
        (a2.KEY_ESC (back))
        ('.' (back)) ; a tap on the stage
        (_
            (sound.cue sound.Cue.nope)
            false)))

; S or SKIP: this step taken with nothing (not the doors: one must be picked)
(fn skip () bool
    (if (= state.pick state.Pick.door)
        (do
            (sound.cue sound.Cue.nope)
            (return false)))
    (sound.cue sound.Cue.confirm)
    (set due state.NOTHING)
    (set staged state.NOTHING)
    (match state.pick
        (state.Pick.cards (after_cards))
        (state.Pick.charms (after_charms))
        (_ (after_nap))))

; ESC: back to the rest from its slots, else the step again with nothing picked
(fn back () bool
    (go (if (= state.pick state.Pick.nap_slot)
        state.Pick.nap
        state.pick))
    false)
