; what the charms do: passives kept all run (content/charm_rows.tsp, in the catalog on disk 2).
; The ones she holds are rows of content/items (CHARM_ROW on, held_n of them; state.charms counts
; each, state.spent marks one that works once a run). A charm that acts at a moment runs its
; steps then (its record's, queued here with hook, run by content/play); the rest change a rule,
; read here by kind (amount: the totals of each kind, made when she takes one). The kittens'
; bite and a wand's bad milk are read in content/effects.

(import state)
(import content/encounters enc)
(import content/hooks)
(import content/items)
(import content/statuses st)
(import content/steps)
(import battle/log)

; the log's sentences, in aux memory (battle/log reads them there): SAY_ and their words
(const SAY (array (ptr u8) 1) (make (array (ptr u8) 1) "A kitten runs off.") :strings aux)

(const SAY_KITTEN_RUNS_OFF u8 0)

(const KINDS u8 29) ; enc.CharmKind's members

(let held_n u8 0) ; the charms she holds: rows items.CHARM_ROW on
; each kind's amount (the charms of it she holds, each its amount, as many times as she holds
; it) and how many of it she holds: made as she takes one (refresh), read by the rules
; (scratch in the 6502 stack page's unused bottom: AGENTS.md, Memory)
(let kind_amount (array u8 29) :address 0x0100)
(let kind_count (array u8 29) :address 0x011D)
(let mark_text (array u8 2)) ; a charm's mark as a string (the tray, the kit page)

; held charm h's row
(fn row ((h u8)) u8
    (+ items.CHARM_ROW h))

; how much of held charm h the run holds: its amount, once for each one held
(fn of ((h u8)) u8
    (let a u8 (items.amount (row h)))
    (let n u8 0)
    (for k u8 0 (at state.charms h)
        (set n (+ n a)))
    n)

; the kinds' totals again
(fn refresh () void
    (for k u8 0 KINDS
        (set (at kind_amount k) 0)
        (set (at kind_count k) 0))
    (for h u8 0 held_n
        (let k u8 (items.kind (row h)))
        (set (at kind_amount k) (+ (at kind_amount k) (of h)))
        (set (at kind_count k) (+ (at kind_count k) (at state.charms h))))
    ; a mana battery holds more
    (set state.mana_most (+ st.MOST_MANA (amount enc.CharmKind.battery))))

; and of charm kind
(fn amount ((kind enc.CharmKind)) u8
    (at kind_amount (as u8 kind)))

(fn count ((kind enc.CharmKind)) u8
    (at kind_count (as u8 kind)))

(fn held ((kind enc.CharmKind)) bool
    (> (at kind_count (as u8 kind)) 0))

; whether she holds charm id (the catalog's), and which (NOTHING for none)
(fn holding ((id u8)) u8
    (for h u8 0 held_n
        (if (= (at items.ids (row h)) id)
            (return h)))
    state.NOTHING)

; charm row's mark (its record's glyph) as a string in main memory
(fn mark ((r u8)) (ptr u8)
    (set (at mark_text 0) (items.cost r))
    (set (at mark_text 1) 0)
    (addr_of (at mark_text 0)))

; a run's start: none held (none spent); with id not NOTHING, that one (battle START_CHARM)
(fn start ((id u8)) void
    (set held_n 0)
    (for h u8 0 items.HELD_CHARMS
        (set (at state.charms h) 0)
        (set (at state.spent h) false))
    (if (!= id state.NOTHING)
        (take id))
    (refresh))

; she takes charm id (between fights): one more of it, or its record read into her next row
(fn take ((id u8)) void
    (let h u8 (holding id))
    (if (!= h state.NOTHING)
        (set (at state.charms h) (+ (at state.charms h) 1))
        (do
            (if (>= held_n items.HELD_CHARMS)
                (return))
            (set h held_n)
            (items.read (row h) id true)
            (set (at state.charms h) 1)
            (set (at state.spent h) false)
            (set held_n (+ held_n 1))))
    (refresh)
    ; a lucky collar: more hit points at most, and those hit points
    (if (= (items.kind (row h)) (as u8 enc.CharmKind.collar))
        (grow_hp (items.amount (row h)))))

; her most hit points n more, and n more hit points (between fights)
(fn grow_hp ((n u8)) void
    (set state.hero_max (st.sum state.hero_max n))
    (set state.hero_hp (st.sum state.hero_hp n)))

; the charms she holds that act at moment when: their steps wait to run (content/play), v their
; amount. In the order she took them: charms of one moment must not depend on their order (a
; mother cat adds her kitten, as a litter box does)
(fn hook ((when steps.When)) void
    (for h u8 0 held_n
        (if (= (items.step (row h)) (as u8 when))
            (hooks.add (items.fx (row h)) state.HERO (of h)))))

; the dice a fight rolls: a sixth toe adds one
(fn dice () u8
    (let n u8 (+ (+ state.DICE (amount enc.CharmKind.toe)) (count enc.CharmKind.cursedcoin)))
    (if (> n state.DICE_MOST)
        (set n state.DICE_MOST))
    n)

; her turn starts (turn.start_round): last turn's shield is gone, unless a fluff three kept it;
; a fluffy tail keeps half. Gives the re-rolls for the turn
(fn round_start () u8
    (let shield u8 (as u8 st.Status.shield))
    (let old u8 (state.stack state.HERO shield))
    (state.set_stack state.HERO shield 0)
    (state.set_stack state.HERO (as u8 st.Status.box) 0)
    (state.set_stack state.HERO (as u8 st.Status.thorns) 0)
    (state.set_stack state.HERO (as u8 st.Status.mirror) 0)
    (state.set_stack state.HERO (as u8 st.Status.collar) 0)
    (state.set_stack state.HERO (as u8 st.Status.wall) 0)
    (if (> (state.stack state.HERO (as u8 st.Status.keep)) 0)
        (do
            (state.set_stack state.HERO shield old)
            (state.set_stack state.HERO (as u8 st.Status.keep) 0)))
    (if (held enc.CharmKind.tail)
        (if (> (>> old 1) (state.stack state.HERO shield))
            (state.set_stack state.HERO shield (>> old 1))))
    ; spare yarn's re-rolls, this turn only
    (let rolls u8 (state.stack state.HERO (as u8 st.Status.rolls)))
    (state.set_stack state.HERO (as u8 st.Status.rolls) 0)
    (+ (- (+ 2 (amount enc.CharmKind.pocket)) (amount enc.CharmKind.toe)) rolls))

; she would fall: a charm for it not spent this run (nine lives) brings her back, with its
; amount of hit points (given; 0 for none), and its steps run (the log)
(fn saved () u8
    (for h u8 0 held_n
        (if (and (= (items.step (row h)) (as u8 steps.When.dies)) (not (at state.spent h)))
            (do
                (set (at state.spent h) true)
                (let hp u8 (items.amount (row h)))
                (hooks.add (items.fx (row h)) state.HERO hp)
                (return hp))))
    0)

; she lost hit points: a kitten runs off; the charms for it (a grumpy face's mana)
(fn hero_hurt () void
    (state.set_stack state.HERO
        (as u8 st.Status.scars)
        (st.sum (state.stack state.HERO (as u8 st.Status.scars)) 1))
    (let kittens u8 (state.stack state.HERO (as u8 st.Status.kittens)))
    (if (> kittens 0)
        (do
            (state.set_stack state.HERO (as u8 st.Status.kittens) (- kittens 1))
            (log.line (at SAY SAY_KITTEN_RUNS_OFF) 0)))
    (hook steps.When.hurt))
