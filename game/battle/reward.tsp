; what comes between fights, after a won one: one of the fight's three cards (an item for a
; slot, or a level on a slot), then one of three charms after the fights that give them, the nap
; after the one that has it (sleep: hit points back, or dream: a level on a slot of your
; choice), and the two doors before a fight that has another. The choices are cards in the tray
; (1-3, the six slots for a dream); the stage shows her six slots (battle/kit), the one a card
; changes picked out, so she always sees what she is changing. As in battle, a number key picks a
; card and shows its text, the same key again (or RETURN) takes it; ESC lets go.

(import apple2 a2)
(import state)
(import art/icons)
(import draw/text)
(import battle/tray)
(import battle/kit)
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
        "Curse: on an enemy" "Trick: for the next dice") :strings aux)

(const SLOT_NAME (array (ptr u8) 6)
    (make (array (ptr u8) 6) "WAND" "FLUFF" "STAR" "BOOK" "CURSE" "TRICK") :strings aux)

(fn start () void
    (set state.phase state.Phase.reward)
    (set state.selected state.NOTHING)
    (set state.next_fight (+ state.stage 1))
    (tray.clear_side)
    (kit.show)
    (go state.Pick.cards))

; a step: its choices in the tray, its prompt in the text
(fn go ((pick state.Pick)) void
    (set state.pick pick)
    (set state.picked state.NOTHING)
    (set due state.NOTHING)
    (set choices 0)
    (match pick
        (state.Pick.cards
            (for k u8 0 3
                (add (at (at enc.FIGHT_CARDS state.fight) k))))
        (state.Pick.charms
            (for k u8 0 3
                (add (at (at enc.FIGHT_CHARMS state.fight) k))))
        (state.Pick.nap
            (add 0)
            (add 1))
        (state.Pick.nap_slot
            (for k u8 0 state.SLOTS
                (add k)))
        (state.Pick.door
            (add state.next_fight)
            (add (at enc.FIGHTS state.next_fight other))))
    (kit.preview state.NOTHING state.NOTHING false)
    (draw_cards)
    (prompt))

(fn add ((c u8)) void
    (set (at choice choices) c)
    (set choices (+ choices 1)))

; the slot a card goes to, and whether it is a level (else a new item there)
(fn card_slot ((c u8)) u8
    (if (>= c UP)
        (return (- c UP)))
    (as u8 (at items.ITEMS c slot)))

(fn card_levels ((c u8)) bool
    (or (>= c UP) (= (at state.items (card_slot c)) c)))

; whether a card can be taken: a level only below items.ITEM_MOST
(fn card_ok ((c u8)) bool
    (if (not (card_levels c))
        (return true))
    (< (at state.levels (card_slot c)) items.ITEM_MOST))

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
        (state.Pick.charms (tray.slot n true icons.TILE_CHARM "" picked))
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

(fn row ((r u8) (s (ptr u8)) (n u8)) void
    (text.start)
    (text.add_n s n)
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
            (row 0 "A reward! Pick a card (1-3)." 0)
            (for k u8 0 choices
                (text.start)
                (text.char (+ '1' k))
                (text.char ' ')
                (let c u8 (at choice k))
                (if (>= c UP)
                    (do
                        (text.add "+1 ")
                        (text.add_aux (at SLOT_NAME (card_slot c))))
                    (text.add_aux (at items.ITEMS c name)))
                (show (+ k 1))))
        (state.Pick.charms
            (row 0 "A charm! Pick one (1-3)." 0)
            (for k u8 0 choices
                (text.start)
                (text.char (+ '1' k))
                (text.char ' ')
                (text.add_aux (at enc.CHARMS (at choice k) name))
                (show (+ k 1))))
        (state.Pick.nap
            (row 0 "A nap. Pick one (1-2)." 0)
            (row 1 "1 Sleep: # hit points back" enc.NAP_HEAL)
            (row 2 "2 Dream: +1 on a slot" 0))
        (state.Pick.nap_slot
            (row 0 "Dream: +1 on which slot? (1-6)" 0)
            (row 1 "ESC: back to the nap" 0))
        (state.Pick.door
            (row 0 "Two doors. Pick one (1-2)." 0)
            (for k u8 0 2
                (text.start)
                (text.char (+ '1' k))
                (text.char ' ')
                (let fight enc.Fight (at enc.FIGHTS (at choice k)))
                (text.add_aux (at en.ENEMIES (at fight.spots 0 enemy) name))
                (show (+ k 1)))))
    (rest))

; row 0: the name (a content string, in aux memory), inverse, and how to take it
(fn title ((name (ptr u8)) (up bool)) void
    (text.start)
    (set text.inverse true)
    (if up
        (text.add "+1 "))
    (text.add_aux name)
    (set text.inverse false)
    (text.tab 24)
    (text.add "Again: take")
    (show 0))

; row 1: slot's base with item row at level, and the level
(fn base_row ((slot u8) (item u8) (level u8)) void
    (text.start)
    (text.add_aux_n (at BASE slot) (fx.number_at item level))
    (if (> level 0)
        (text.add_n " (+#)" level))
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
                    (text.add " is at its most.")
                    (show 3)
                    (return)))
            (base_row slot old (+ level 1))
            (row_aux 2 (at items.ITEMS old text) (fx.number_at old (+ level 1)))
            (text.start)
            (text.add (if (>= c UP)
                "+1 on the slot: "
                "You have it: +1 on "))
            (text.add_aux (at items.ITEMS old name))
            (show 3)
            (return)))
    (title (at items.ITEMS c name) false)
    (base_row slot c level)
    (row_aux 2 (at items.ITEMS c text) (fx.number_at c level))
    (text.start)
    (text.add "Replaces: ")
    (text.add_aux (at items.ITEMS old name))
    (show 3))

; choice n's text, picked: rows 0 to 3
(fn describe ((n u8)) void
    (let c u8 (at choice n))
    (match state.pick
        (state.Pick.cards (describe_card c))
        (state.Pick.nap_slot (describe_card (+ UP c)))
        (state.Pick.charms
            (title (at enc.CHARMS c name) false)
            (row_aux 1 (at enc.CHARMS c text) 0)
            (row 2 "A charm works all run." 0))
        (state.Pick.nap
            (if (= c 0)
                (do
                    (title "SLEEP" false)
                    (row 1 "# hit points back," (- (healed) state.hero_hp))
                    (row 2 "up to # of 30." (healed)))
                (do
                    (title "DREAM" false)
                    (row 1 "+1 on a slot of your choice." 0))))
        (state.Pick.door
            (let fight enc.Fight (at enc.FIGHTS c))
            (let kind u8 (at fight.spots 0 enemy))
            (title (at en.ENEMIES kind name) false)
            (row 1 "# hit points" (at en.ENEMIES kind hp))
            (row 2 "Ward #" (at en.ENEMIES kind ward))))
    (rest))

; her hit points after a sleep
(fn healed () u8
    (let hp u8 (+ state.hero_hp enc.NAP_HEAL))
    (if (> hp enc.HERO.hp)
        (set hp enc.HERO.hp))
    hp)

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

; after the cards: a charm, the nap, the doors, as the fight has them; gives true when all is done
(fn after_cards () bool
    (if (!= (at (at enc.FIGHT_CHARMS state.fight) 0) state.NOTHING)
        (do
            (go state.Pick.charms)
            (return false)))
    (after_charms))

(fn after_charms () bool
    (if (at enc.FIGHTS state.fight nap)
        (do
            (go state.Pick.nap)
            (return false)))
    (after_nap))

(fn after_nap () bool
    (if (and (< state.next_fight enc.FIGHT_COUNT)
            (!= (at enc.FIGHTS state.next_fight other) state.NOTHING))
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
        (a2.KEY_ESC
            (go (if (= state.pick state.Pick.nap_slot)
                state.Pick.nap
                state.pick))
            false)
        (_
            (sound.cue sound.Cue.nope)
            false)))
