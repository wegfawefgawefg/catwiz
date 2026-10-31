; what comes between fights, after a won one: one of three cards drawn at random (battle/offer:
; an item for a slot, or a level on a slot); after an elite, one of three charms drawn too, then
; the nap (hit points back) or a bonus upgrade (a level on a slot of her choice); and the two
; doors before a fight that has another. The choices are cards in the tray (1-3, the six slots for
; a bonus upgrade); the stage shows her six slots (battle/kit), the one a card changes picked out,
; so she always sees what she is changing. As in battle, a number key picks a card and shows its
; text, the same key again (or RETURN) takes it; ESC lets go.

(import apple2 a2)
(import state)
(import art/icons)
(import draw/text)
(import battle/tray)
(import battle/kit)
(import battle/offer)
(import content/action ac)
(import content/charms)
(import content/effects fx)
(import content/encounters enc)
(import content/enemies en)
(import content/items)
(import sound/sound)

(const UP u8 128) ; a card of 128 + a slot: a level on that slot (enc.UP_WAND ...)

; the step's choices: card codes, charm rows, sleep and dream, slots, or fight rows (doors)
(let choice (array u8 6))
(let choices u8 0)

; a slot's base, the card's second line (# its number), and its name
(const BASE (array (ptr u8) 6)
    (make (array (ptr u8) 6)
        "Wand: # damage" "Fluff: shield #" "Star: makes mana" "Book: a spell for mana"
        "Curse: on an enemy" "Trick: for the next dice")
    :strings aux)

(const SLOT_NAME (array (ptr u8) 6)
    (make (array (ptr u8) 6) "WAND" "FLUFF" "STAR" "BOOK" "CURSE" "TRICK")
    :strings aux)

; the screen's words, in aux memory (text.add_aux): SAY_ and their words
(const SAY (array (ptr u8) 23)
    (make (array (ptr u8) 23)
        "A reward! Pick a card (1-3)."
        "+1 "
        "A charm! Pick one (1-3)."
        "A rest. Pick one (1-2)."
        "1 Nap: # hit points back"
        "2 Bonus upgrade: +1 on a slot"
        "Upgrade: +1 on which slot? (1-6)"
        "ESC: back to the rest"
        "Two doors. Pick one (1-2)."
        "Again: take"
        " (+#)"
        " is at its most."
        "+1 on the slot: "
        "You have it: +1 on "
        "Replaces: "
        "A charm works all run."
        "NAP"
        "# hit points back,"
        "up to # of 30."
        "BONUS UPGRADE"
        "+1 on a slot of your choice."
        "# hit points"
        "Ward #")
    :strings aux)

(const SAY_REWARD u8 0)
(const SAY_PLUS1 u8 1)
(const SAY_CHARM u8 2)
(const SAY_REST u8 3)
(const SAY_NAP_BACK u8 4)
(const SAY_BONUS u8 5)
(const SAY_WHICH_SLOT u8 6)
(const SAY_BACK_REST u8 7)
(const SAY_DOORS u8 8)
(const SAY_AGAIN u8 9)
(const SAY_UP u8 10)
(const SAY_AT_MOST u8 11)
(const SAY_ON_SLOT u8 12)
(const SAY_HAVE_IT u8 13)
(const SAY_REPLACES u8 14)
(const SAY_ALL_RUN u8 15)
(const SAY_NAP u8 16)
(const SAY_HP_BACK u8 17)
(const SAY_UP_TO u8 18)
(const SAY_BONUS_UPGRADE u8 19)
(const SAY_YOUR_CHOICE u8 20)
(const SAY_HP u8 21)
(const SAY_WARD u8 22)

(fn start () void
    (set state.phase state.Phase.reward)
    (set state.selected state.NOTHING)
    (set state.next_fight (+ state.stage 1))
    (tray.clear_side)
    (kit.show)
    (offer.draw false)
    (go state.Pick.cards))

; a step: its choices in the tray, its prompt in the text
(fn go ((pick state.Pick)) void
    (set state.pick pick)
    (set state.picked state.NOTHING)
    (set due state.NOTHING)
    (set choices 0)
    (match pick
        (state.Pick.cards (add_drawn))
        (state.Pick.charms (add_drawn))
        (state.Pick.nap
            (add 0)
            (add 1))
        (state.Pick.nap_slot
            (for k u8 0 state.SLOTS
                (add k)))
        (state.Pick.door
            (add state.next_fight)
            (add (enc.other state.next_fight))))
    (kit.preview state.NOTHING state.NOTHING false)
    (draw_cards)
    (prompt))

(fn add ((c u8)) void
    (set (at choice choices) c)
    (set choices (+ choices 1)))

; the cards or charms drawn for the step (drawn once, as it starts: letting go keeps them)
(fn add_drawn () void
    (for k u8 0 offer.count
        (add (at offer.drawn k))))

(fn card_slot ((c u8)) u8
    (offer.card_slot c))

(fn card_levels ((c u8)) bool
    (offer.card_levels c))

(fn card_ok ((c u8)) bool
    (offer.card_ok c))

; ---- the tray: a card for each choice

(fn draw_card ((n u8)) void
    (let picked bool (= n state.picked))
    (if (>= n choices)
        (do
            (tray.slot n false state.NOTHING "" false)
            (return)))
    (let c u8 (at choice n))
    (match state.pick
        (state.Pick.cards
            (let slot u8 (card_slot c))
            (if (>= c UP)
                (tray.slot n true (at items.ITEMS (at state.items slot) icon) "+1" picked)
                (tray.slot n true (at items.ITEMS c icon) "" picked)))
        (state.Pick.charms (tray.slot n true icons.TILE_CHARM (at enc.MARKS c) picked))
        (state.Pick.nap
            (if (= c 0)
                (tray.slot n true icons.TILE_NAP "" picked)
                (tray.slot n true icons.TILE_PLUS1 "" picked)))
        (state.Pick.nap_slot (tray.slot n true (at items.ITEMS (at state.items c) icon) "" picked))
        (state.Pick.door (tray.slot n true icons.TILE_DOOR "" picked))))

(fn draw_cards () void
    (for n u8 0 state.DICE_MOST
        (draw_card n)))

; ---- the text: each step writes its rows over the last ones (only what changed is drawn
; again, draw/text), and the rows it leaves out are blanked (rest)

(let written u8 0) ; a bit for each row written since the step's text started

(fn show ((r u8)) void
    (text.show r)
    (set written (| written (<< 1 r))))

(fn rest () void
    (for r u8 0 text.ROWS
        (if (= (& written (<< 1 r)) 0)
            (do
                (text.start)
                (text.show r))))
    (set written 0))

; s is one of SAY's
(fn row ((r u8) (s (ptr u8)) (n u8)) void
    (text.start)
    (text.add_aux_n s n)
    (show r))

; the same with s a content string, in aux memory
(fn row_aux ((r u8) (s (ptr u8)) (n u8)) void
    (text.start)
    (text.add_aux_n s n)
    (show r))

; the step's prompt, nothing picked: rows 0 to 3
(fn prompt () void
    (match state.pick
        (state.Pick.cards
            (row 0 (at SAY SAY_REWARD) 0)
            (for k u8 0 choices
                (text.start)
                (text.char (+ '1' k))
                (text.char ' ')
                (let c u8 (at choice k))
                (if (>= c UP)
                    (do
                        (text.add_aux (at SAY SAY_PLUS1))
                        (text.add_aux (at SLOT_NAME (card_slot c))))
                    (text.add_aux (at items.ITEMS c name)))
                (show (+ k 1))))
        (state.Pick.charms
            (row 0 (at SAY SAY_CHARM) 0)
            (for k u8 0 choices
                (text.start)
                (text.char (+ '1' k))
                (text.char ' ')
                (text.add_aux (enc.charm_name (at choice k)))
                (show (+ k 1))))
        (state.Pick.nap
            (row 0 (at SAY SAY_REST) 0)
            (row 1 (at SAY SAY_NAP_BACK) (- (healed) state.hero_hp))
            (row 2 (at SAY SAY_BONUS) 0))
        (state.Pick.nap_slot
            (row 0 (at SAY SAY_WHICH_SLOT) 0)
            (row 1 (at SAY SAY_BACK_REST) 0))
        (state.Pick.door
            (row 0 (at SAY SAY_DOORS) 0)
            (for k u8 0 2
                (text.start)
                (text.char (+ '1' k))
                (text.char ' ')
                (text.add_aux (en.name (enc.first_enemy (at choice k))))
                (show (+ k 1)))))
    (rest))

; row 0: the name (a content string, in aux memory), inverse, and how to take it
(fn title ((name (ptr u8)) (up bool)) void
    (text.start)
    (set text.inverse true)
    (if up
        (text.add_aux (at SAY SAY_PLUS1)))
    (text.add_aux name)
    (set text.inverse false)
    (text.tab 24)
    (text.add_aux (at SAY SAY_AGAIN))
    (show 0))

; row 1: slot's base with item row at level, and the level
(fn base_row ((slot u8) (item u8) (level u8)) void
    (text.start)
    (text.add_aux_n (at BASE slot) (fx.number_at item level))
    (if (> level 0)
        (text.add_aux_n (at SAY SAY_UP) level))
    (show 1))

; the card the item or level c makes of its slot, in the balance's four lines: what it is, the
; slot's base at its level, the item's line, what it replaces (or the level it gives)
(fn describe_card ((c u8)) void
    (let slot u8 (card_slot c))
    (let level u8 (at state.levels slot))
    (let old u8 (at state.items slot))
    (if (card_levels c)
        (do
            (title
                (if (>= c UP)
                    (at SLOT_NAME slot)
                    (at items.ITEMS c name))
                (>= c UP))
            (if (not (card_ok c))
                (do
                    (base_row slot old level)
                    (row_aux 2 (at items.ITEMS old text) (fx.number_at old level))
                    (text.start)
                    (text.add_aux (at SLOT_NAME slot))
                    (text.add_aux (at SAY SAY_AT_MOST))
                    (show 3)
                    (return)))
            (base_row slot old (+ level 1))
            (row_aux 2 (at items.ITEMS old text) (fx.number_at old (+ level 1)))
            (text.start)
            (text.add_aux (if (>= c UP)
                (at SAY SAY_ON_SLOT)
                (at SAY SAY_HAVE_IT)))
            (text.add_aux (at items.ITEMS old name))
            (show 3)
            (return)))
    (title (at items.ITEMS c name) false)
    (base_row slot c level)
    (row_aux 2 (at items.ITEMS c text) (fx.number_at c level))
    (text.start)
    (text.add_aux (at SAY SAY_REPLACES))
    (text.add_aux (at items.ITEMS old name))
    (show 3))

; choice n's text, picked: rows 0 to 3
(fn describe ((n u8)) void
    (let c u8 (at choice n))
    (match state.pick
        (state.Pick.cards (describe_card c))
        (state.Pick.nap_slot (describe_card (+ UP c)))
        (state.Pick.charms
            (title (enc.charm_name c) false)
            (row_aux 1 (enc.charm_text c) 0)
            (row 2 (at SAY SAY_ALL_RUN) 0))
        (state.Pick.nap
            (if (= c 0)
                (do
                    (title (at SAY SAY_NAP) false)
                    (row 1 (at SAY SAY_HP_BACK) (- (healed) state.hero_hp))
                    (row 2 (at SAY SAY_UP_TO) (healed)))
                (do
                    (title (at SAY SAY_BONUS_UPGRADE) false)
                    (row 1 (at SAY SAY_YOUR_CHOICE) 0))))
        (state.Pick.door
            (let kind u8 (enc.first_enemy c))
            (title (en.name kind) false)
            (row 1 (at SAY SAY_HP) (en.hp kind))
            (row 2 (at SAY SAY_WARD) (en.ward kind))))
    (rest))

; her hit points after a nap: the ones she is missing, shifted right enc.NAP_HEAL_SHIFT (rounded
; up), back
(fn healed () u8
    (let missing u8 (- enc.HERO.hp state.hero_hp))
    (let part u8 (>> (+ missing (- (<< 1 enc.NAP_HEAL_SHIFT) 1)) enc.NAP_HEAL_SHIFT))
    (+ state.hero_hp part))

; the slot choice n changes, shown on the stage: the card's item in it, or its next level
(fn show_change ((n u8)) void
    (let c u8 (at choice n))
    (match state.pick
        (state.Pick.cards
            (let slot u8 (card_slot c))
            (if (card_levels c)
                (kit.preview slot (at state.items slot) (card_ok c))
                (kit.preview slot c false)))
        (state.Pick.nap_slot (kit.preview c (at state.items c) (card_ok (+ UP c))))
        (_ (kit.preview state.NOTHING state.NOTHING false))))

; ---- taking

; after the cards: after an elite a charm, then the rest; then the doors; gives true when all is
; done
(fn after_cards () bool
    (if (enc.elite state.fight)
        (do
            (offer.draw true)
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

; choice n is taken. Gives true when all is done and the next fight can start
(fn take ((n u8)) bool
    (let c u8 (at choice n))
    ; a pick not drawn yet is not drawn: the step changes or ends
    (set due state.NOTHING)
    (match state.pick
        (state.Pick.cards
            (if (not (card_ok c))
                (do
                    (sound.cue sound.Cue.nope)
                    (return false)))
            (if (card_levels c)
                (level_up (card_slot c))
                (set (at state.items (card_slot c)) c))
            (kit.show)
            (after_cards))
        (state.Pick.charms
            (set (at state.charms c) (+ (at state.charms c) 1))
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
            (if (not (card_ok (+ UP c)))
                (do
                    (sound.cue sound.Cue.nope)
                    (return false)))
            (level_up c)
            (kit.show)
            (after_nap))
        (state.Pick.door
            (set state.next_fight c)
            true)))

; choice n picked: its text and the slot it changes; picked again, taken
(fn pick ((n u8)) bool
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

; the text and the stage of the choice picked, drawn the frame after its card lifts, so the
; pick shows at once
(let due u8 255)

(fn refresh () void
    (if (= due state.NOTHING)
        (return))
    (show_change due)
    (describe due)
    (set due state.NOTHING))

; one frame of what comes between fights; true when it is done and the next fight can start
(fn step ((key u8)) bool
    (if (and (>= key '1') (< key (+ '1' choices)))
        (return (pick (- key '1'))))
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

; ESC: back to the rest from its slots, else the step again with nothing picked
(fn back () bool
    (go (if (= state.pick state.Pick.nap_slot)
        state.Pick.nap
        state.pick))
    false)
