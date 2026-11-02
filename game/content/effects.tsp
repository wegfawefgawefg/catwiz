; the rules her faces land by: a face's number, the boosts on it in their order, what playing
; it pays and counts (a book's mana, its slot's count towards a three, what she played last),
; and the kittens' pounce. What each face then does is its item's steps (content/cards.tsp, run
; by content/play). The rules are the balance sim's (tools/sim/items.py, rules.py): every
; effect does exactly what its text says; the dice are the only luck. Every number is a byte and
; stops at 255 (st.sum) instead of wrapping (the owner, 2026-11-01).

(import state)
(import battle/hit)
(import content/action ac)
(import content/cards)
(import content/charms)
(import content/encounters enc)
(import content/items)
(import content/statuses st)

(const COMBO_AT u8 3)       ; the third face of a slot in a turn sets off its three
(const KITTEN_HIT u8 2)     ; what a kitten's pounce does (kitten mittens add theirs)
(const KITTENS_MOST u8 255) ; kittens at most (a byte: no cap)

(fn hero ((s st.Status)) u8
    (state.stack state.HERO (as u8 s)))

(fn set_hero ((s st.Status) (n u8)) void
    (state.set_stack state.HERO (as u8 s) n))

(fn add_hero ((s st.Status) (n u8)) void
    (hit.add_stacks state.HERO (as u8 s) n))

(fn mana () u8
    (hero st.Status.mana))

; the mana item row costs: a book's cost, 1 more for each bad milk she holds
(fn cost ((row u8)) u8
    (let c u8 (at items.ITEMS row cost))
    (if (= (at items.ITEMS row slot) ac.Slot.book)
        (set c (+ c (at state.charms enc.CHARM_BAD_MILK))))
    c)

; whether item row is a book she has too little mana for: it can't be played (the owner,
; 2026-10-31: no fizzle; a re-roll, or a star first)
(fn short_of_mana ((row u8)) bool
    (and (= (at items.ITEMS row slot) ac.Slot.book) (< (mana) (cost row))))

; whether the hero can play item row: not a hairball (a re-roll coughs it up), not a book she
; has too little mana for
(fn can_play ((row u8)) bool
    (and (!= (at items.ITEMS row slot) ac.Slot.junk) (not (short_of_mana row))))

; n times m, by adding (no multiply routine), 255 at most
(fn times ((n u8) (m u8)) u8
    (let out u8 0)
    (for k u8 0 m
        (set out (st.sum out n)))
    out)

; item row's number at its slot's level: its amount, and its step more a level; one that grows
; with her habit (ac.GROWS) that much more
(fn number ((row u8)) u8
    (let slot ac.Slot (at items.ITEMS row slot))
    (if (= slot ac.Slot.junk)
        (return 0))
    (let n u8 (number_at row (at state.levels (as u8 slot))))
    (if (!= (& (cards.tags row) ac.GROWS) 0)
        (set n (st.sum n (hero st.Status.habit))))
    n)

; and at level (a card shows what an item would be)
(fn number_at ((row u8) (level u8)) u8
    (+ (at items.ITEMS row amount) (times (at items.ITEMS row step) level)))

; how many faces the last face boosted counts for, towards its slot's three (a times counts
; its number)
(let counts u8 1)

; the number item row lands with: its number, then the boosts in their order (as
; tools/sim/items.py): a times waiting (the next die, any slot but a trick: the owner,
; 2026-10-31, a star leaving it waiting was not right), a plus (the next die, on every hit of
; it), catnip's 1, knead (a fluff times 2, a wand more), bad milk (a wand more), a wish (a wand
; times 2), then a spook takes away; 255 at most. use: the boosts are used up (it lands); else
; only looked at (the bottom text). A trick takes no boosts
(fn boosted ((row u8) (use bool)) u8
    (let slot ac.Slot (at items.ITEMS row slot))
    (let n u8 (number row))
    (set counts 1)
    (if (= slot ac.Slot.trick)
        (return n))
    (let mult u8 (hero st.Status.mult))
    (if (> mult 0)
        (do
            (set n (times n mult))
            (set counts mult)
            (if use
                (do
                    ; a die took the times: a double or nothing's bet is won
                    (set_hero st.Status.mult 0)
                    (set_hero st.Status.gamble 0)))))
    (if (> (hero st.Status.plus_left) 0)
        (do
            (set n (st.sum n (hero st.Status.plus)))
            (if use
                (do
                    (set_hero st.Status.plus_left 0)
                    (set_hero st.Status.plus 0)))))
    (let nip u8 (hero st.Status.nip))
    (if (> nip 0)
        (do
            (set n (st.sum n 1))
            (if use
                (set_hero st.Status.nip (- nip 1)))))
    (if (and (= slot ac.Slot.fluff) (> (hero st.Status.knead_fluff) 0))
        (do
            (set n (st.sum n n))
            (if use
                (set_hero st.Status.knead_fluff 0))))
    (if (= slot ac.Slot.wand)
        (do
            (set n
                (st.sum n
                    (st.sum (hero st.Status.knead_wand) (charms.amount enc.CharmKind.badmilk))))
            (if use
                (set_hero st.Status.knead_wand 0))
            (if (> (hero st.Status.wish) 0)
                (do
                    (set n (st.sum n n))
                    (if use
                        (set_hero st.Status.wish 0))))))
    (let spook u8 (hero st.Status.spook))
    (if (> n spook)
        (- n spook)
        0))

; whether the face landing now is its slot's third this turn (its item's three steps run)
(let three bool false)

; item row (no trick) is about to land on target: its number after the boosts (given), its
; slot's count towards a three, its mana (a book's cost, bad milk's more; a copy of a book is
; free, as she may have spent the mana) and what she played last. again: a copy (copycat), which
; is not what she played last
(fn prepare ((row u8) (target u8) (again bool)) u8
    (let slot ac.Slot (at items.ITEMS row slot))
    (let n u8 (boosted row true))
    (let before u8 (at state.combo (as u8 slot)))
    (let after u8 (st.sum before counts))
    (set (at state.combo (as u8 slot)) after)
    (set three (and (< before COMBO_AT) (>= after COMBO_AT)))
    (if (not again)
        (do
            (set state.last_face row)
            (set state.last_on target)))
    (if (and (= slot ac.Slot.book) (not again))
        (set_hero st.Status.mana (- (mana) (cost row))))
    (set state.wand_on (= slot ac.Slot.wand))
    n)

(fn alive ((i u8)) bool
    (at state.actors i alive))

; every kitten pounces on t: KITTEN_HIT each, more with mittens and on a mark
(fn pounce ((t u8)) void
    (let bite u8 (+ KITTEN_HIT (charms.amount enc.CharmKind.mittens)))
    (for k u8 0 (hero st.Status.kittens)
        (if (not (alive t))
            (return))
        (hit.plain t (st.sum bite (state.stack t (as u8 st.Status.brand))))))

; the next enemy standing after t, left to right and round again; NOTHING when none is
(fn next_standing ((t u8)) u8
    ; once every enemy is down, stay down: NOTHING + 1 would wrap round to the hero
    (if (= t state.NOTHING)
        (return state.NOTHING))
    (for n u8 0 3
        (set t (+ t 1))
        (if (= t state.ACTORS)
            (set t 1))
        (if (alive t)
            (return t)))
    state.NOTHING)
