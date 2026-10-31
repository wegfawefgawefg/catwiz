; her kit, a page over the stage in her turn (B; battle/page opens and closes it): her six slots
; as cards in the tray's places (the reward's cards: the item's picture, a pip a level), so a tap
; on a die's card picks that slot; her charms on the stage, each where an enemy's or the cat's tap
; box is (M, Z, X, C). Picking one (1-6 the slots, 7-9 the charms, M Z X C, or the arrows) frames
; it and fills the four rows of text: its name and level, the slot's base, the item's line, and
; what it has going on in this fight (toward a three, a boost waiting, mana, kittens, a hairball,
; a die an enemy holds); a charm's text.

(import apple2 a2)
(import state)
(import art/icons)
(import draw/text)
(import battle/kit)
(import battle/reward)
(import content/action ac)
(import content/encounters enc)
(import content/effects fx)
(import content/items)
(import content/statuses st)
(import sound/sound)

(const SLOT_TOP u8 128) ; the slots' cards, in the tray's rows
(const CHARM_TOP u8 54)
(const CHARMS_MOST u8 4)
; the charms' cards: in the cat's tap box (M), the first enemy's (Z), the second's (X), and over
; them in the flyer's (C)
(const CHARM_X (array u8 4) (make (array u8 4) 30 72 114 114))
(const CHARM_Y (array u8 4) (make (array u8 4) 54 54 54 14))

; the page's words, in aux memory (text.add_aux): SAY_ and what each is
(const SAY (array (ptr u8) 25)
    (make (array (ptr u8) 25)
        "HER KIT"
        "Fight # of "
        "No charms yet. Elites give them."
        "Her charms, all run (7-9):"
        "Her six slots, a face each (1-6):"
        "Pick a slot or a charm to read it:"
        "1-6 a slot, 7-9 a charm, or arrows."
        "ESC, B or CLOSE: back to the fight."
        "A hairball clogs it. "
        "An enemy holds one. "
        "To a 3: # this turn. "
        "+# on the next "
        "# dice. "
        "x# on the next die. "
        "+1 on the next # dice. "
        "Knead waits. "
        "Mana # of 5. "
        "Mana #, "
        "it costs #. "
        "Kittens #."
        "Nothing on it this turn."
        "Level # of "
        " (+#)"
        "A charm works all run."
        "She has # of them.")
    :strings aux)

(const SAY_HER_KIT u8 0)
(const SAY_FIGHT u8 1)
(const SAY_NO_CHARMS u8 2)
(const SAY_CHARMS u8 3)
(const SAY_SLOTS u8 4)
(const SAY_PICK u8 5)
(const SAY_KEYS u8 6)
(const SAY_BACK u8 7)
(const SAY_CLOGGED u8 8)
(const SAY_HELD u8 9)
(const SAY_THREE u8 10)
(const SAY_PLUS u8 11)
(const SAY_DICE u8 12)
(const SAY_TIMES u8 13)
(const SAY_NIP u8 14)
(const SAY_KNEAD u8 15)
(const SAY_MANA_OF u8 16)
(const SAY_MANA u8 17)
(const SAY_COSTS u8 18)
(const SAY_KITTENS u8 19)
(const SAY_NOTHING u8 20)
(const SAY_LEVEL u8 21)
(const SAY_UP u8 22)
(const SAY_ALL_RUN u8 23)
(const SAY_HAS u8 24)

(let held (array u8 4)) ; the charm rows she holds, in order
(let held_n u8 0)
(let sel u8 255) ; the entry picked: 0-5 a slot, 6 on a charm; NOTHING for none

; slot n's card: in tray slot n's place (35 n / 2 of the tray's pixels)
(fn slot_card ((n u8) (frame bool)) void
    (kit.card (>> (* n 35) 1)
        SLOT_TOP
        (at items.ITEMS (at state.items n) icon)
        (at state.levels n)
        frame
        ""))

(fn charm_card ((k u8) (frame bool)) void
    (kit.card (at CHARM_X k) (at CHARM_Y k) icons.TILE_CHARM 0 frame (at enc.MARKS (at held k))))

(fn entry_card ((e u8) (frame bool)) void
    (if (< e state.SLOTS)
        (slot_card e frame)
        (charm_card (- e state.SLOTS) frame)))

; a line of the stage's text at row y, s one of SAY's
(fn stage_line ((y u8) (s (ptr u8))) void
    (text.start)
    (text.add_aux s)
    (text.draw_at y text.BLOCKS))

; row r of the text, s one of SAY's
(fn row ((r u8) (s (ptr u8))) void
    (text.start)
    (text.add_aux s)
    (text.show r))

(fn open () void
    (set sel state.NOTHING)
    (set held_n 0)
    (for c u8 0 enc.OFFER_CHARM_COUNT
        (if (and (> (at state.charms c) 0) (< held_n CHARMS_MOST))
            (do
                (set (at held held_n) c)
                (set held_n (+ held_n 1)))))
    (text.start)
    (set text.inverse true)
    (text.add_aux (at SAY SAY_HER_KIT))
    (set text.inverse false)
    (text.tab 21)
    (text.add_aux_n (at SAY SAY_FIGHT) (+ state.stage 1))
    (text.number enc.FIGHT_COUNT)
    (text.draw_at 2 text.BLOCKS)
    (if (= held_n 0)
        (stage_line 40 (at SAY SAY_NO_CHARMS))
        (stage_line 40 (at SAY SAY_CHARMS)))
    (for k u8 0 held_n
        (charm_card k false))
    (stage_line 108 (at SAY SAY_SLOTS))
    (for n u8 0 state.SLOTS
        (slot_card n false))
    (row 0 (at SAY SAY_PICK))
    (row 1 (at SAY SAY_KEYS))
    (text.start)
    (text.show 2)
    (row 3 (at SAY SAY_BACK)))

; ---- what an entry says

(fn title ((name (ptr u8))) void
    (text.start)
    (set text.inverse true)
    (text.add_aux name)
    (set text.inverse false))

; what slot has going on in this fight, in one row
(fn live ((slot u8) (item u8)) void
    (text.start)
    (if (at state.clogged slot)
        (text.add_aux (at SAY SAY_CLOGGED)))
    (for d u8 0 state.DICE_MOST
        (if (and (!= (at state.held d) state.NOTHING) (= (at state.face_of d) slot))
            (text.add_aux (at SAY SAY_HELD))))
    (if (!= (at items.ITEMS item combo) ac.Combo.none)
        (text.add_aux_n (at SAY SAY_THREE) (at state.combo slot)))
    (match (at items.ITEMS item slot)
        (ac.Slot.trick
            (if (> (fx.hero st.Status.plus_left) 0)
                (do
                    (text.add_aux_n (at SAY SAY_PLUS) (fx.hero st.Status.plus))
                    (text.add_aux_n (at SAY SAY_DICE) (fx.hero st.Status.plus_left))))
            (if (> (fx.hero st.Status.mult) 0)
                (text.add_aux_n (at SAY SAY_TIMES) (fx.hero st.Status.mult)))
            (if (> (fx.hero st.Status.nip) 0)
                (text.add_aux_n (at SAY SAY_NIP) (fx.hero st.Status.nip)))
            (if (> (fx.hero st.Status.knead_fluff) 0)
                (text.add_aux (at SAY SAY_KNEAD))))
        (ac.Slot.star (text.add_aux_n (at SAY SAY_MANA_OF) (fx.mana)))
        (ac.Slot.book
            (text.add_aux_n (at SAY SAY_MANA) (fx.mana))
            (text.add_aux_n (at SAY SAY_COSTS) (at items.ITEMS item cost)))
        (_))
    (match (at items.ITEMS item effect)
        (ac.Effect.feather (text.add_aux_n (at SAY SAY_KITTENS) (fx.hero st.Status.kittens)))
        (ac.Effect.kittens (text.add_aux_n (at SAY SAY_KITTENS) (fx.hero st.Status.kittens)))
        (ac.Effect.cannon (text.add_aux_n (at SAY SAY_KITTENS) (fx.hero st.Status.kittens)))
        (ac.Effect.pile (text.add_aux_n (at SAY SAY_KITTENS) (fx.hero st.Status.kittens)))
        (ac.Effect.litter (text.add_aux_n (at SAY SAY_KITTENS) (fx.hero st.Status.kittens)))
        (_))
    (if (= text.col 0)
        (text.add_aux (at SAY SAY_NOTHING)))
    (text.show 3))

(fn describe_slot ((slot u8)) void
    (let item u8 (at state.items slot))
    (let level u8 (at state.levels slot))
    (title (at items.ITEMS item name))
    (text.tab 22)
    (text.add_aux_n (at SAY SAY_LEVEL) level)
    (text.number items.ITEM_MOST)
    (text.show 0)
    (text.start)
    (text.add_item (at reward.BASE slot) (fx.number_at item level))
    (if (> level 0)
        (text.add_aux_n (at SAY SAY_UP) level))
    (text.show 1)
    (text.start)
    (text.add_item (at items.ITEMS item text) (fx.number_at item level))
    (text.show 2)
    (live slot item))

(fn describe_charm ((k u8)) void
    (let c u8 (at held k))
    (title (enc.charm_name c))
    (text.show 0)
    (text.start)
    (text.add_aux (enc.charm_text c))
    (text.show 1)
    (row 2 (at SAY SAY_ALL_RUN))
    (text.start)
    (if (> (at state.charms c) 1)
        (text.add_aux_n (at SAY SAY_HAS) (at state.charms c)))
    (text.show 3))

; entry e picked: its card framed (the one before not), its text
(fn pick ((e u8)) void
    (if (>= e (+ state.SLOTS held_n))
        (do
            (sound.cue sound.Cue.nope)
            (return)))
    (sound.cue sound.Cue.blip)
    (if (!= sel state.NOTHING)
        (entry_card sel false))
    (set sel e)
    (entry_card e true)
    (if (< e state.SLOTS)
        (describe_slot e)
        (describe_charm (- e state.SLOTS))))

; the next entry one way (1) or the other (255), round
(fn step_pick ((way u8)) void
    (let n u8 (+ state.SLOTS held_n))
    (if (= sel state.NOTHING)
        (do
            (pick 0)
            (return)))
    (let e u8 (+ sel way))
    (if (= e 255)
        (set e (- n 1)))
    (if (>= e n)
        (set e 0))
    (pick e))

; a key on the page; gives true to close it
(fn key ((k u8)) bool
    (if (and (>= k '1') (<= k '9'))
        (do
            (pick (- k '1'))
            (return false)))
    (match (& k 0xDF)
        ('M' (pick state.SLOTS))
        ('Z' (pick (+ state.SLOTS 1)))
        ('X' (pick (+ state.SLOTS 2)))
        ('C' (pick (+ state.SLOTS 3)))
        ('B' (return true))
        ('R' (return true))
        ('E' (return true))
        (_
            (match k
                (0)
                (a2.KEY_LEFT (step_pick 255))
                (a2.KEY_RIGHT (step_pick 1))
                (a2.KEY_ESC (return true))
                ('.' (return true)) ; a tap on the stage where no charm is
                (_ (sound.cue sound.Cue.nope)))))
    false)
