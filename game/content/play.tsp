; a face lands, and the steps run: content/steps.tsp's vocabulary, content/cards.tsp's rows. The
; one place a card's effect is worked out; the unique cards' native routines (Copycat, Mimic)
; are steps here too. Also her turn's end (the boosts go, the kittens pounce) and drain, which
; runs the hooks and charms an enemy's hit or a status set off (content/hooks).

(import state)
(import battle/hit)
(import battle/log)
(import content/action ac)
(import content/cards)
(import content/charms)
(import content/effects fx)
(import content/hooks)
(import content/items)
(import content/statuses st)
(import content/steps)
(import content/effects_said said)
(import sound/sound)

(const CALLS u8 3) ; steps calling steps (do, a hook, a copy), this deep at most
(const LOOPS u8 3)
(const ALL u8 0) ; a loop's kind: every enemy standing, all but t, v times
(const OTHERS u8 1)
(const REP u8 2)

; the calls to go back to: where, on whom, the value and the number there, and its loops
(let call_p (array (ptr u8) 3))
(let call_pc (array u8 3))
(let call_t (array u8 3))
(let call_v (array u8 3))
(let call_n (array u8 3))
(let call_loops (array u8 3))
(let calls u8 0)
; the loops open: their first step, kind, times left (rep), and t before (all, others)
(let loop_pc (array u8 3))
(let loop_kind (array u8 3))
(let loop_left (array u8 3))
(let loop_t (array u8 3))
(let loops u8 0)
(let threes bool false) ; a three's steps ran: the charms' threes come when the face is done

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
; charms' threes and whatever waits (content/hooks)
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
        (let s u8 (& a 0x7F))
        (let who u8 (if (>= a steps.ON_T)
            t
            state.HERO))
        (match op
            (steps.NUM (set v n))
            (steps.LIT (set v a))
            (steps.KITS
                (for k u8 0 a
                    (set v (st.sum v (fx.hero st.Status.kittens)))))
            (steps.GET (set v (state.stack who s)))
            (steps.LEAST
                (if (< v a)
                    (set v a)))
            (steps.KEPT (set v state.kept))
            (steps.IF
                (if (= (state.stack who s) 0)
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
                        (sound.cue sound.Cue.chime))
                    (set go false)))
            (steps.CALM
                (if state.rerolled
                    (set go false)))
            (steps.ADD (hit.add_stacks who s v))
            (steps.SET (state.set_stack who s v))
            (steps.MAX
                (if (> v (state.stack who s))
                    (state.set_stack who s v)))
            (steps.TIMES (state.set_stack who s (fx.times (state.stack who s) v)))
            (steps.SUB
                (let h u8 (state.stack who s))
                (state.set_stack who s (if (> h v)
                    (- h v)
                    0)))
            (steps.MANA (st.gain_mana v))
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
                (set t (fx.next_standing t))
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
                    (set v hooks.blocked)))
            (steps.COPY
                ; copycat: her last face again (free), its number plus this one's, on whom it
                ; went (or t, when that one is down)
                (if (= state.last_face state.NOTHING)
                    (do
                        (log.line (at said.SAY said.SAY_NOTHING_COPY_YET) 0)
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
                        (log.line (at said.SAY said.SAY_COPYCAT) 0)
                        (let row u8 state.last_face)
                        (set v (fx.prepare row on true))
                        (if (< calls CALLS)
                            (do
                                (set (at call_p calls) p)
                                (set (at call_pc calls) pc)
                                (set (at call_t calls) t)
                                (set (at call_v calls) v)
                                (set (at call_n calls) n)
                                (set (at call_loops calls) loops)
                                (set calls (+ calls 1))
                                (set base loops)
                                (set p (at items.ITEMS row fx))
                                (set pc 0)
                                (set t on)
                                (set n v))))))
            (steps.DO
                (if (< calls CALLS)
                    (do
                        (set (at call_p calls) p)
                        (set (at call_pc calls) pc)
                        (set (at call_t calls) t)
                        (set (at call_v calls) v)
                        (set (at call_n calls) n)
                        (set (at call_loops calls) loops)
                        (set calls (+ calls 1))
                        (set base loops)
                        (set p (at cards.SUBS a))
                        (set pc 0)
                        (set n v))))
            (steps.CUE (sound.cue_byte a))
            (steps.SAY
                (let line (ptr u8) (at said.SAY (& a steps.SAY_LINE)))
                (if (!= (& a steps.SAY_IT) 0)
                    (log.who t line v)
                    (if (!= (& a steps.SAY_ME) 0)
                        (log.who state.HERO line v)
                        (log.line line v))))
            (_ (set go false)))
        (if go
            ; what this step set off (a hook, a charm) runs now, then the steps go on
            (if (and (hooks.waiting) (< calls CALLS))
                (do
                    (set (at call_p calls) p)
                    (set (at call_pc calls) pc)
                    (set (at call_t calls) t)
                    (set (at call_v calls) v)
                    (set (at call_n calls) n)
                    (set (at call_loops calls) loops)
                    (set calls (+ calls 1))
                    (set base loops)
                    (set p (hooks.take))
                    (set pc 0)
                    (set t hooks.on_now)
                    (set v hooks.value_now)
                    (set n v)))
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
            (log.who t (at said.SAY said.SAY_WARD_BROKEN_NO) 0)
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
    (let p (ptr u8) (at items.ITEMS row fx))
    (if (= (at items.ITEMS row slot) ac.Slot.trick)
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
                (log.line (at said.SAY said.SAY_KITTENS_POUNCE) 0)
                (fx.pounce t)
                (drain)))))
