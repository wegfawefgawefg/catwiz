; what the hero's faces do: the one match on the effect kind (content/action) for her items, the
; boosts and the threes, the curses (hers and the enemies'), and her kittens. The enemies' moves
; are content/foes.tsp. The rules are the balance sim's (tools/sim/items.py, rules.py): every
; effect does exactly what its text says; the dice are the only luck.

(import state)
(import battle/hit)
(import battle/log)
(import content/action ac)
(import content/charms)
(import content/encounters enc)
(import content/items)
(import content/statuses st)
(import sound/sound)
(import content/effects_said said)

(const FLEA_TURNS u8 3)
(const ZOOMIES_HITS u8 5)
(const SCREAM_SELF u8 1)
(const PLUS_DICE u8 2) ; plus one: how many dice it boosts
(const COMBO_AT u8 3)  ; the third face of a slot in a turn sets off its combo

(fn hero ((s st.Status)) u8
    (state.stack state.HERO (as u8 s)))

(fn set_hero ((s st.Status) (n u8)) void
    (state.set_stack state.HERO (as u8 s) n))

(fn add_hero ((s st.Status) (n u8)) void
    (hit.add_stacks state.HERO (as u8 s) n))

(fn mana () u8
    (hero st.Status.mana))

; whether the hero can play item row: not a hairball (a re-roll coughs it up); a book always,
; since with too little mana she studies it (1 mana)
(fn can_play ((row u8)) bool
    (!= (at items.ITEMS row slot) ac.Slot.junk))

; n times m, by adding (no multiply routine)
(fn times ((n u8) (m u8)) u8
    (let out u8 0)
    (for k u8 0 m
        (set out (+ out n)))
    out)

; item row's number at its slot's level: its amount, and its step more a level
(fn number ((row u8)) u8
    (let slot ac.Slot (at items.ITEMS row slot))
    (if (= slot ac.Slot.junk)
        (return 0))
    (number_at row (at state.levels (as u8 slot))))

; and at level (a card shows what an item would be)
(fn number_at ((row u8) (level u8)) u8
    (+ (at items.ITEMS row amount) (times (at items.ITEMS row step) level)))

; how many faces the last face boosted counts for, towards its slot's three (a times counts
; its number)
(let counts u8 1)

; the number item row lands with: its number, then the boosts in their order (as
; tools/sim/items.py): a times waiting (the next die, any slot but a trick: the owner,
; 2026-10-31, a star leaving it waiting was not right), a plus, catnip's 1, knead (a
; fluff times 2, a wand more), bad milk (a wand +1), a wish (a wand times 2), then a spook takes
; away. use: the boosts are used up (it lands); else only looked at (the bottom text). A trick
; takes no boosts
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
                (set_hero st.Status.mult 0))))
    (let left u8 (hero st.Status.plus_left))
    (if (> left 0)
        (do
            (set n (+ n (hero st.Status.plus)))
            (if use
                (do
                    (set_hero st.Status.plus_left (- left 1))
                    (if (= left 1)
                        (set_hero st.Status.plus 0))))))
    (let nip u8 (hero st.Status.nip))
    (if (> nip 0)
        (do
            (set n (+ n 1))
            (if use
                (set_hero st.Status.nip (- nip 1)))))
    (if (and (= slot ac.Slot.fluff) (> (hero st.Status.knead_fluff) 0))
        (do
            (set n (<< n 1))
            (if use
                (set_hero st.Status.knead_fluff 0))))
    (if (= slot ac.Slot.wand)
        (do
            (set n (+ n (+ (hero st.Status.knead_wand) (charms.amount enc.CharmKind.badmilk))))
            (if use
                (set_hero st.Status.knead_wand 0))
            (if (> (hero st.Status.wish) 0)
                (do
                    (set n (<< n 1))
                    (if use
                        (set_hero st.Status.wish 0))))))
    (let spook u8 (hero st.Status.spook))
    (if (> n spook)
        (- n spook)
        0))

; the hero's face lands: a trick sets up the next dice; any other item lands with its boosts
(fn land_face ((row u8) (target u8)) void
    (if (= (at items.ITEMS row slot) ac.Slot.trick)
        (do
            (trick row target)
            (return)))
    (land_item row target false))

; item row (no trick) lands on target: its number, its slot's count towards a three, its mana
; (a book with too little studies instead: 1 mana), its effect, then its combo when this face
; makes the third. again: a copy (copycat), which is not what she played last
(fn land_item ((row u8) (target u8) (again bool)) void
    (let slot ac.Slot (at items.ITEMS row slot))
    (let n u8 (boosted row true))
    (let before u8 (at state.combo (as u8 slot)))
    (let after u8 (+ before counts))
    (set (at state.combo (as u8 slot)) after)
    (let three bool (and (< before COMBO_AT) (>= after COMBO_AT)))
    (if (not again)
        (do
            (set state.last_face row)
            (set state.last_on target)))
    (if (= slot ac.Slot.book)
        (do
            (let cost u8 (at items.ITEMS row cost))
            (if (< (mana) cost)
                (do
                    (sound.cue sound.Cue.chime)
                    (st.gain_mana 1)
                    (log.line (at said.SAY said.SAY_TOO_LITTLE_MANA) 0)
                    (return)))
            (set_hero st.Status.mana (- (mana) cost))))
    (effect (at items.ITEMS row effect) target n)
    (if (and three (!= (at items.ITEMS row combo) ac.Combo.none))
        (combo row target n)))

; a trick: a rule for the next dice
(fn trick ((row u8) (target u8)) void
    (let n u8 (number row))
    (sound.cue sound.Cue.chime)
    (match (at items.ITEMS row effect)
        (ac.Effect.plus
            ; pluses add up: +1 then +1 is +2 on the next two dice (the owner, 2026-10-31: a
            ; second +1 only starting the two again "doesnt seem right")
            (add_hero st.Status.plus n)
            (set_hero st.Status.plus_left PLUS_DICE)
            (log.line (at said.SAY said.SAY_NEXT_2_DICE) (hero st.Status.plus)))
        (ac.Effect.double
            ; played after a plus it doubles that too
            (set_hero st.Status.plus (times (hero st.Status.plus) n))
            (let mult u8 (hero st.Status.mult))
            (if (= mult 0)
                (set mult 1))
            (set_hero st.Status.mult (times mult n))
            (log.line (at said.SAY said.SAY_TIMES_NEXT) (hero st.Status.mult)))
        (ac.Effect.copy
            (if (= state.last_face state.NOTHING)
                (do
                    (log.line (at said.SAY said.SAY_NOTHING_COPY_YET) 0)
                    (return)))
            (if (> n 0)
                (do
                    (add_hero st.Status.plus n)
                    (if (= (hero st.Status.plus_left) 0)
                        (set_hero st.Status.plus_left 1))))
            (let on u8 state.last_on)
            (if (not (at state.actors on alive))
                (set on target))
            (log.line (at said.SAY said.SAY_COPYCAT) 0)
            (land_item state.last_face on true))
        (ac.Effect.catnip2
            (add_hero st.Status.nip n)
            (set_hero st.Status.nipped 1)
            (log.line (at said.SAY said.SAY_CATNIP_NEXT_DICE) n))
        (ac.Effect.knead
            (set_hero st.Status.knead_fluff 1)
            (add_hero st.Status.knead_wand n)
            (log.line (at said.SAY said.SAY_KNEAD_NEXT_FLUFF) n))
        (_)))

(fn strike ((t u8) (n u8)) void
    (hit.strike state.HERO t n false))

(fn alive ((i u8)) bool
    (at state.actors i alive))

(fn effect ((e ac.Effect) (t u8) (n u8)) void
    (match e
        (ac.Effect.hit
            (sound.cue sound.Cue.zap)
            (strike t n))
        (ac.Effect.shield
            (sound.cue sound.Cue.ping)
            (add_hero st.Status.shield n)
            (log.who state.HERO (at said.SAY said.SAY_SHIELDS) n))
        (ac.Effect.mana
            (sound.cue sound.Cue.chime)
            (st.gain_mana n)
            (log.line (at said.SAY said.SAY_MANA_NOW) (mana)))
        (ac.Effect.yarn
            (sound.cue sound.Cue.zap)
            (strike t n)
            (if (alive t)
                (curse ac.Effect.tangled t 1)))
        (ac.Effect.spray
            (sound.cue sound.Cue.zap)
            (strike t n)
            (if (alive t)
                (curse ac.Effect.wet t 1)))
        (ac.Effect.feather
            (sound.cue sound.Cue.zap)
            (strike t n)
            (pounce t))
        (ac.Effect.pierce
            (sound.cue sound.Cue.zap)
            (hit.strike state.HERO t n true))
        (ac.Effect.string
            (sound.cue sound.Cue.zap)
            (strike t n)
            (let t2 u8 (next_standing t))
            (if (!= t2 state.NOTHING)
                (strike t2 n)))
        (ac.Effect.shoot
            (sound.cue sound.Cue.zap)
            (st.gain_mana 1)
            (strike t n))
        (ac.Effect.moon
            (sound.cue sound.Cue.ping)
            (st.gain_mana 1)
            (add_hero st.Status.shield n)
            (log.who state.HERO (at said.SAY said.SAY_SHIELDS_1_MANA) n))
        (ac.Effect.wish
            (sound.cue sound.Cue.chime)
            (st.gain_mana n)
            (set_hero st.Status.wish 1)
            (log.line (at said.SAY said.SAY_WISH_NEXT_WAND) 0))
        (ac.Effect.litter
            (sound.cue sound.Cue.chime)
            (st.gain_mana (+ n (hero st.Status.kittens)))
            (log.line (at said.SAY said.SAY_MANA_NOW) (mana)))
        (ac.Effect.kittens
            (sound.cue sound.Cue.meow)
            (add_kittens n)
            (log.line (at said.SAY said.SAY_KITTENS_JOIN_YOU) (hero st.Status.kittens)))
        (ac.Effect.laserall
            (sound.cue sound.Cue.zap)
            (for i u8 1 state.ACTORS
                (if (alive i)
                    (do
                        (strike i n)
                        (if (alive i)
                            (state.set_stack i (as u8 st.Status.laser) 1))))))
        (ac.Effect.knock
            (sound.cue sound.Cue.zap)
            (strip t)
            (strike t n))
        (ac.Effect.cannon
            (sound.cue sound.Cue.zap)
            (strike t (times n (hero st.Status.kittens))))
        (ac.Effect.pile
            (sound.cue sound.Cue.ping)
            (let shield u8 (+ n (<< (hero st.Status.kittens) 1)))
            (add_hero st.Status.shield shield)
            (log.who state.HERO (at said.SAY said.SAY_SHIELDS) shield))
        (ac.Effect.zoomies
            (sound.cue sound.Cue.zap)
            (let at u8 0)
            (for k u8 0 ZOOMIES_HITS
                (set at (next_standing at))
                (if (!= at state.NOTHING)
                    (strike at n))))
        (ac.Effect.scream
            (sound.cue sound.Cue.wobble)
            (for i u8 1 state.ACTORS
                (if (alive i)
                    (strike i n)))
            (hit.lose state.HERO SCREAM_SELF)
            (log.who state.HERO (at said.SAY said.SAY_TAKES_FROM_SCREAMING) SCREAM_SELF))
        (ac.Effect.nothing
            (sound.cue sound.Cue.puff)
            (log.line (at said.SAY said.SAY_HAIRBALL_NOTHING_HAPPENS) 0))
        (ac.Effect.fleas (curse e t n))
        (ac.Effect.wet (curse e t n))
        (ac.Effect.tangled (curse e t n))
        (ac.Effect.brand (curse e t n))
        (_)))

; the knock: it drops its shield, its cheer, its strength and what it sends back
(fn strip ((t u8)) void
    (state.set_stack t (as u8 st.Status.shield) 0)
    (state.set_stack t (as u8 st.Status.cheer) 0)
    (state.set_stack t (as u8 st.Status.strength) 0)
    (state.set_stack t (as u8 st.Status.reflect) 0)
    (log.who t (at said.SAY said.SAY_DROPS_ITS_SHIELD) 0))

; what the third face of a slot in a turn adds (the item's combo, combo_n), n the face's number
(fn combo ((row u8) (t u8) (n u8)) void
    (let k u8 (at items.ITEMS row combo_n))
    (sound.cue sound.Cue.chime)
    (match (at items.ITEMS row combo)
        (ac.Combo.sweep ; the third hits every other enemy too
            (log.line (at said.SAY said.SAY_THREE_HITS_ALL) 0)
            (for i u8 1 state.ACTORS
                (if (and (alive i) (!= i t))
                    (strike i n))))
        (ac.Combo.keep ; the shield stays through her next turn's start
            (set_hero st.Status.keep 1)
            (log.line (at said.SAY said.SAY_THREE_SHIELD_STAYS) 0))
        (ac.Combo.thorns
            (if (> k (hero st.Status.thorns))
                (set_hero st.Status.thorns k))
            (log.line (at said.SAY said.SAY_THREE_SPIKY) k))
        (ac.Combo.box ; hit-alls miss, and a kitten
            (set_hero st.Status.box 1)
            (add_kittens k)
            (log.line (at said.SAY said.SAY_THREE_BOX) 0))
        (ac.Combo.heal
            (log.line (at said.SAY said.SAY_THREE_WARM) 0)
            (hit.heal state.HERO k))
        (ac.Combo.static ; k to every enemy, twice that to a wet one
            (log.line (at said.SAY said.SAY_THREE_STATIC) 0)
            (for i u8 1 state.ACTORS
                (if (alive i)
                    (strike i (if (> (state.stack i (as u8 st.Status.wet)) 0)
                        (<< k 1)
                        k)))))
        (ac.Combo.ward
            (add_hero st.Status.ward k)
            (log.line (at said.SAY said.SAY_THREE_WARD) 0))
        (_))
    ; a purrfect trio: each three hits every enemy too
    (let trio u8 (charms.amount enc.CharmKind.trio))
    (if (> trio 0)
        (for i u8 1 state.ACTORS
            (if (alive i)
                (hit.plain i trio)))))

(fn add_kittens ((n u8)) void
    (let k u8 (+ (hero st.Status.kittens) n))
    (if (> k charms.KITTENS_MOST)
        (set k charms.KITTENS_MOST))
    (set_hero st.Status.kittens k))

; every kitten pounces on t: 1 each, more with mittens and on a mark
(fn pounce ((t u8)) void
    (let bite u8 (+ 1 (charms.amount enc.CharmKind.mittens)))
    (for k u8 0 (hero st.Status.kittens)
        (if (not (alive t))
            (return))
        (hit.plain t (+ bite (state.stack t (as u8 st.Status.brand))))))

; her turn ends: still water's mana; the kittens pounce (a marked enemy first, else the
; leftmost), twice with catnip; the turn's boosts that wait for nothing more go
(fn turn_end () void
    (charms.still_water)
    (let times u8 (if (> (hero st.Status.nipped) 0)
        2
        1))
    (set_hero st.Status.nipped 0)
    (set_hero st.Status.nip 0)
    (set_hero st.Status.knead_fluff 0)
    (set_hero st.Status.knead_wand 0)
    (if (= (hero st.Status.kittens) 0)
        (return))
    (for k u8 0 times
        (let t u8 state.NOTHING)
        (for i u8 1 state.ACTORS
            (if (and (alive i) (= t state.NOTHING))
                (set t i)))
        (for i u8 1 state.ACTORS
            (if (and (alive i) (> (state.stack i (as u8 st.Status.brand)) 0))
                (if (or (= t state.NOTHING) (= (state.stack t (as u8 st.Status.brand)) 0))
                    (set t i))))
        (if (!= t state.NOTHING)
            (do
                (log.line (at said.SAY said.SAY_KITTENS_POUNCE) 0)
                (pounce t)))))

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

; a curse always lands: on a ward it breaks one pip instead of taking effect (a rubber duck
; shields her then)
(fn curse ((e ac.Effect) (target u8) (n u8)) void
    (sound.cue sound.Cue.hiss)
    (let ward u8 (state.stack target (as u8 st.Status.ward)))
    (if (> ward 0)
        (do
            (state.set_stack target (as u8 st.Status.ward) (- ward 1))
            (log.who target (at said.SAY said.SAY_WARD_BROKEN_NO) 0)
            (charms.ward_blocked)
            (return)))
    (match e
        (ac.Effect.fleas
            (hit.add_stacks target (as u8 st.Status.poison) n)
            (state.set_stack target (as u8 st.Status.flea_turns) FLEA_TURNS)
            (log.who target
                (at said.SAY said.SAY_GETS_FLEAS_TURN)
                (state.stack target (as u8 st.Status.poison))))
        (ac.Effect.wet
            (let turns u8 (state.stack target (as u8 st.Status.wet)))
            (if (< turns n)
                (set turns n))
            (if (= turns 0)
                (set turns 1))
            (state.set_stack target (as u8 st.Status.wet) turns)
            (log.who target (at said.SAY said.SAY_WET_HALF_HITS) turns))
        (ac.Effect.spook
            (hit.add_stacks target (as u8 st.Status.spook) n)
            (log.who target (at said.SAY said.SAY_SPOOKED_DICE) n))
        (ac.Effect.brand
            (hit.add_stacks target (as u8 st.Status.brand) n)
            (log.who target
                (at said.SAY said.SAY_MARKED_HITS)
                (state.stack target (as u8 st.Status.brand))))
        (ac.Effect.tangled
            (hit.add_stacks target (as u8 st.Status.tangle) n)
            (log.who target
                (at said.SAY said.SAY_TANGLED_HITS)
                (state.stack target (as u8 st.Status.tangle))))
        (_)))
