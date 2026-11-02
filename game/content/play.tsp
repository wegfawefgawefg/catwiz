; a face lands, and the steps run: content/steps.tsp's vocabulary, content/cards.tsp's rows. The
; one place a card's effect is worked out; the unique cards' native routines (Copycat, Mimic)
; are steps here too. Also her turn's end (the boosts go, the kittens pounce) and drain, which
; runs the hooks and charms an enemy's hit or a status set off (content/hooks).

(import random)
(import state)
(import battle/hit)
(import battle/log)
(import content/action ac)
(import content/cards)
(import content/charms)
(import content/effects fx)
(import content/hooks)
(import content/items)
(import content/moves mv)
(import content/statuses st)
(import content/steps)
(import content/effects_said said)
(import sound/sound)

(const CALLS u8 3) ; steps calling steps (call, a hook, a copy, mimic), this deep at most
(const LOOPS u8 3)
(const ALL u8 0) ; a loop's kind: every enemy standing, all but t, v times
(const OTHERS u8 1)
(const REP u8 2)

; the calls to go back to: where, on whom, the value and the number there, and its loops
(let call_p (array (ptr u8) 3) :address 0x0572)
(let call_pc (array u8 3) :address 0x098B)
(let call_t (array u8 3) :address 0x09B3)
(let call_v (array u8 3) :address 0x09DB)
(let call_n (array u8 3) :address 0x0A0A)
(let call_loops (array u8 3) :address 0x0A0D)
(let calls u8 0)
; the loops open: their first step, kind, times left (rep), and t before (all, others)
(let loop_pc (array u8 3))
(let loop_kind (array u8 3) :address 0x05F2)
(let loop_left (array u8 3) :address 0x05F5)
(let loop_t (array u8 3) :address 0x07F3)
(let loops u8 0)
(let threes bool false) ; a three's steps ran: the charms' threes come when the face is done
; Mimic's: the steps the move it looked at is for her (cards.MIMICRY), and that move's number
(let mimicked (ptr u8))
(let mimicked_v u8 0)

; the byte at p + pc, in aux memory
(fn byte ((p (ptr u8)) (pc u8)) u8
    (with_aux true false
        (load (+ p pc))))

; the step after the close of the loop at pc (none inside it: loops do not nest in one row)
(fn past_close ((p (ptr u8)) (pc u8)) u8
    (while (!= (byte p pc) steps.END)
        (set pc (+ pc 2)))
    (+ pc 2))

; the first enemy standing after t (0: from the left), not skip; NOTHING when none
(fn standing_after ((t u8) (skip u8)) u8
    (for i u8 (+ t 1) state.ACTORS
        (if (and (at state.actors i alive) (!= i skip))
            (return i)))
    state.NOTHING)

; the steps at start run, on t0 with number n (content/steps.tsp says what each does); then the
; charms' threes and whatever waits (content/hooks). A step that runs other steps (call, copy,
; mimic) or sets off a hook enters them as a call: to, on to_t with to_v, and back after
;  another enemy standing than t, picked at random (pick), NOTHING for none
(fn other_at_random ((t u8)) u8
    (let k u8 0)
    (for i u8 1 state.ACTORS
        (if (and (!= i t) (at state.actors i alive))
            (set k (+ k 1))))
    (if (= k 0)
        (return state.NOTHING))
    (let r u8 (as u8 (>> (* (as u16 (random.byte)) (as u16 k)) 8)))
    (for i u8 1 state.ACTORS
        (if (and (!= i t) (at state.actors i alive))
            (do
                (if (= r 0)
                    (return i))
                (set r (- r 1)))))
    state.NOTHING)

(fn run ((start (ptr u8)) (t0 u8) (n0 u8)) void
    (let p (ptr u8) start)
    (let pc u8 0)
    (let t u8 t0)
    (let n u8 n0)
    (let v u8 n0)
    (let base u8 0) ; the loops open when this call began
    (set calls 0)
    (set loops 0)
    (set threes false)
    (while true
        (let op u8 (byte p pc))
        (let a u8 (byte p (+ pc 1)))
        (set pc (+ pc 2))
        (let go bool true)
        (let to (ptr u8) p) ; steps to enter, when not p
        (let to_t u8 t)
        (let to_v u8 v)
        ; a stack step's stack: hers or t's, as it is, and what it becomes (write)
        (let s u8 (& a 0x7F))
        (let who u8 (if (>= a steps.ON_T)
            t
            state.HERO))
        (let old u8 (state.stack who s))
        (let now u8 old)
        (let write bool false)
        (match op
            (steps.NUM (set v n))
            (steps.LIT (set v a))
            (steps.KITS
                (for k u8 0 a
                    (set v (st.sum v (fx.hero st.Status.kittens)))))
            (steps.GET (set v old))
            (steps.LEAST
                (if (< v a)
                    (set v a)))
            (steps.MOST
                (if (> v a)
                    (set v a)))
            (steps.KEPT (set v state.kept))
            (steps.IF
                (if (= old 0)
                    (set pc (+ pc 2))))
            (steps.IF_UP
                (if (not (at state.actors t alive))
                    (if (> loops base)
                        (set pc (- (past_close p pc) 2))
                        (set go false))))
            (steps.THREE
                (if fx.three
                    (do
                        (set threes true)
                        (sound.cue_byte (as u8 sound.Cue.chime)))
                    (set go false)))
            (steps.CALM
                (if state.rerolled
                    (set go false)))
            (steps.ADD
                (set now (st.sum old v))
                (set write true))
            (steps.SET
                (set now v)
                (set write true))
            (steps.MAX
                (set now v)
                (set write (> v old)))
            (steps.TIMES
                (set now (fx.times old v))
                (set write true))
            (steps.SUB
                (set now (if (> old v)
                    (- old v)
                    0))
                (set write true))
            (steps.MANA (st.gain_mana v))
            (steps.SPILL
                (let m u8 (st.sum (fx.mana) v))
                (set v 0)
                (if (> m st.MOST_MANA)
                    (do
                        (set v (- m st.MOST_MANA))
                        (set m st.MOST_MANA)))
                (fx.set_hero st.Status.mana m))
            (steps.REROLLS
                (let r u8 (st.sum state.rerolls v))
                (if (> r cards.REROLLS_MOST)
                    (set r cards.REROLLS_MOST))
                (set state.rerolls r)
                (set state.hud_rerolls true))
            (steps.HEAL (hit.heal state.HERO v))
            (steps.HIT (hit.strike state.HERO t v false))
            (steps.PIERCE (hit.strike state.HERO t v true))
            (steps.PLAIN (hit.plain t v))
            (steps.HURT
                (if (> v 0)
                    (hit.lose t v)))
            (steps.CURSE (set go (curse t s v)))
            (steps.POUNCE (fx.pounce t))
            (steps.ALL
                (let first u8
                    (standing_after 0 (if (= a OTHERS)
                        t
                        state.NOTHING)))
                (if (or (= first state.NOTHING) (>= loops LOOPS))
                    (set pc (past_close p pc))
                    (do
                        (set (at loop_pc loops) pc)
                        (set (at loop_kind loops) a)
                        (set (at loop_t loops) t)
                        (set loops (+ loops 1))
                        (set t first))))
            (steps.REP
                (if (or (= v 0) (>= loops LOOPS))
                    (set pc (past_close p pc))
                    (do
                        (set (at loop_pc loops) pc)
                        (set (at loop_kind loops) REP)
                        (set (at loop_left loops) v)
                        (set loops (+ loops 1)))))
            (steps.END
                (let k u8 (- loops 1))
                (if (= (at loop_kind k) REP)
                    (do
                        (let left u8 (- (at loop_left k) 1))
                        (set (at loop_left k) left)
                        (if (> left 0)
                            (set pc (at loop_pc k))
                            (set loops k)))
                    (do
                        (let after u8
                            (standing_after t (if (= (at loop_kind k) OTHERS)
                                (at loop_t k)
                                state.NOTHING)))
                        (if (= after state.NOTHING)
                            (do
                                (set t (at loop_t k))
                                (set loops k))
                            (do
                                (set t after)
                                (set pc (at loop_pc k)))))))
            (steps.NEXT
                (if (= a 0)
                    (set t (fx.next_standing t))
                    (set t (other_at_random t)))
                (if (= t state.NOTHING)
                    (set go false)))
            (steps.RETARGET
                (if (not (at state.actors t alive))
                    (do
                        (set t (fx.next_standing t))
                        (if (= t state.NOTHING)
                            (set go false)))))
            (steps.ME (set t state.HERO))
            (steps.BLOCKED
                (if (> v hooks.blocked)
                    (set v hooks.blocked))
                (if (= v 0)
                    (set go false)))
            (steps.BACK
                (if state.back_due
                    (set go false)
                    (set state.back_due true)))
            (steps.MIMIC
                (if (= a 0)
                    ; look: what t's shown move would be for her
                    (do
                        (let row u8 (at state.actors t move))
                        (let k u8 (cards.mimicry (mv.effect row) (= (mv.aim row) state.Aim.all)))
                        (if (= k state.NOTHING)
                            (do
                                (log.line (said.line said.SAY_NO_MIMIC) 0)
                                (set go false))
                            (do
                                (set mimicked (cards.mimicry_fx k))
                                (set mimicked_v (mv.amount row))
                                ; a hit at its strength: what it would do to her
                                (if (or (= (mv.effect row) ac.Effect.hit)
                                        (= (mv.effect row) ac.Effect.hit2))
                                    (set mimicked_v
                                        (st.sum
                                            (st.sum mimicked_v
                                                (state.stack t (as u8 st.Status.strength)))
                                            (state.stack t (as u8 st.Status.cheer))))))))
                    ; mimic: do it, with its number
                    (do
                        (set to mimicked)
                        (set to_v mimicked_v))))
            (steps.COPY
                ; copycat: her last face again (free), its number plus this one's, on whom it
                ; went (or t, when that one is down)
                (if (= state.last_face state.NOTHING)
                    (do
                        (log.line (said.line said.SAY_NOTHING_COPY_YET) 0)
                        (set go false))
                    (do
                        (if (> v 0)
                            (do
                                (fx.add_hero st.Status.plus v)
                                (if (= (fx.hero st.Status.plus_left) 0)
                                    (fx.set_hero st.Status.plus_left 1))))
                        (let on u8 state.last_on)
                        (if (not (at state.actors on alive))
                            (set on t))
                        (log.line (said.line said.SAY_COPYCAT) 0)
                        (let row u8 state.last_face)
                        (set to (cards.fx row))
                        (set to_t on)
                        (set to_v (fx.prepare row on true)))))
            (steps.DO (set to (at cards.SUBS a)))
            (steps.CUE (sound.cue_byte a))
            (steps.SAY
                (let line (ptr u8) (said.line (& a steps.SAY_LINE)))
                (let named u8 (if (!= (& a steps.SAY_IT) 0)
                    t
                    state.HERO))
                (if (= (& a (| steps.SAY_IT steps.SAY_ME)) 0)
                    (log.line line v)
                    (log.who named line v)))
            (_ (set go false)))
        (if write
            (state.set_stack who s now))
        (if go
            (do
                ; what this step set off (a hook, a charm) runs now, then the steps go on
                (if (and (and (= to p) (hooks.waiting)) (< calls CALLS))
                    (do
                        (set to (hooks.take))
                        (set to_t hooks.on_now)
                        (set to_v hooks.value_now)))
                (if (and (!= to p) (< calls CALLS))
                    (do
                        (set (at call_p calls) p)
                        (set (at call_pc calls) pc)
                        (set (at call_t calls) t)
                        (set (at call_v calls) v)
                        (set (at call_n calls) n)
                        (set (at call_loops calls) loops)
                        (set calls (+ calls 1))
                        (set base loops)
                        (set p to)
                        (set pc 0)
                        (set t to_t)
                        (set v to_v)
                        (set n to_v))))
            (if (> calls 0)
                ; back to the steps that called these
                (do
                    (set calls (- calls 1))
                    (set p (at call_p calls))
                    (set pc (at call_pc calls))
                    (set t (at call_t calls))
                    (set v (at call_v calls))
                    (set n (at call_n calls))
                    (set loops (at call_loops calls))
                    (set base (if (> calls 0)
                        (at call_loops (- calls 1))
                        0)))
                ; the steps are done: the charms' threes, then whatever waits
                (do
                    (set state.wand_on false)
                    (if threes
                        (do
                            (set threes false)
                            (charms.hook steps.When.three)))
                    (if (not (hooks.waiting))
                        (return))
                    (set p (hooks.take))
                    (set pc 0)
                    (set t hooks.on_now)
                    (set v hooks.value_now)
                    (set n v)
                    (set loops 0)
                    (set base 0))))))

; a curse on t: s plus v, unless a ward pip takes it (the pip breaks; a rubber duck shields her
; then): gives whether it landed. A curse always lands otherwise
(fn curse ((t u8) (s u8) (v u8)) bool
    (sound.cue sound.Cue.hiss)
    (let ward u8 (state.stack t (as u8 st.Status.ward)))
    (if (> ward 0)
        (do
            (state.set_stack t (as u8 st.Status.ward) (- ward 1))
            (log.who t (said.line said.SAY_WARD_BROKEN_NO) 0)
            (charms.hook steps.When.warded)
            (return false)))
    (hit.add_stacks t s v)
    true)

; the hooks and charms waiting (an enemy's hit, a status's tick set them off) run now
(fn drain () void
    (if (hooks.waiting)
        (run (addr_of (at cards.NOTHING 0)) state.HERO 0)))

; the hero's face lands on target: a trick's steps with its number (no boosts on a trick); any
; other item's with its number after the boosts, its mana paid, its count towards a three
(fn land_face ((row u8) (target u8)) void
    (let p (ptr u8) (cards.fx row))
    (if (= (items.slot row) ac.Slot.trick)
        (do
            (run p target (fx.number row))
            (return)))
    (run p target (fx.prepare row target false)))

; her turn ends: the charms for it (still water's mana); the turn's boosts go, a waiting plus and
; times too (the owner, 2026-11-01), and the hooks of her statuses for it; the kittens pounce (a
; marked enemy first, else the leftmost), twice with catnip
(fn turn_end () void
    (charms.hook steps.When.turn_end)
    (drain)
    (fx.set_hero st.Status.plus 0)
    (fx.set_hero st.Status.plus_left 0)
    (fx.set_hero st.Status.mult 0)
    (hooks.status steps.When.turn_end state.HERO state.HERO)
    (drain)
    (if (not (at state.actors state.HERO alive))
        (return))
    (let times u8 (if (> (fx.hero st.Status.nipped) 0)
        2
        1))
    (fx.set_hero st.Status.nipped 0)
    (fx.set_hero st.Status.nip 0)
    (fx.set_hero st.Status.knead_fluff 0)
    (fx.set_hero st.Status.knead_wand 0)
    (if (= (fx.hero st.Status.kittens) 0)
        (return))
    (for k u8 0 times
        (let t u8 state.NOTHING)
        (for i u8 1 state.ACTORS
            (if (and (at state.actors i alive) (= t state.NOTHING))
                (set t i)))
        (for i u8 1 state.ACTORS
            (if (and (at state.actors i alive) (> (state.stack i (as u8 st.Status.brand)) 0))
                (if (or (= t state.NOTHING) (= (state.stack t (as u8 st.Status.brand)) 0))
                    (set t i))))
        (if (!= t state.NOTHING)
            (do
                (log.line (said.line said.SAY_KITTENS_POUNCE) 0)
                (fx.pounce t)
                (drain)))))
