; the steps memory keeps (content/steps.tsp: the vocabulary; content/play.tsp runs them): the
; shared rows a face's call names (SUBS), the enemies' curses on her, the hooks statuses carry
; and Mimic's table. A face's and a charm's own steps are in its row (content/faces.tsp,
; content/charm_rows.tsp) and its record on disk 2 (content/catalog), so a new card made of
; these steps costs no memory and no code. The rules are the balance sim's (tools/sim/items.py,
; rules.py, cards.py): each card does exactly what its text says.

(import content/steps)
(import content/action ac)
(import content/statuses st)

(const FLEA_TURNS u8 3)      ; fleas bite for this many of its turns
(const BACK_MOST u8 5)       ; her dice come back this many times a turn at most (the sim's cap)
(const REROLLS_MOST u8 9)    ; re-rolls she can hold at most (the tray shows one digit)
(const SUNBEAM_REROLLS u8 2) ; the re-rolls a sunbeam's mana past 5 gives at most (the sim's)
(const ZOOMIES_HITS u8 5)    ; Zoomies' hits, enemies left to right
(const SCREAM_SELF u8 1)     ; what 3 AM Screaming does to her

; ---- shared steps (call k, k a row of SUBS: steps.SUB_ZAP_HIT ...)

(steps.steps ZAP_HIT (cue zap) (hit))
(steps.steps SHIELD (cue ping) (add shield) (say_me SHIELDS))

; the curses a face, a call or an enemy's move puts on t (and Mimic's table names)
(steps.steps FLEAS
    (curse poison)
    (lit FLEA_TURNS)
    (t_set flea_turns)
    (t_get poison)
    (say_it GETS_FLEAS_TURN))

(steps.steps WET (least 1) (curse wet) (t_get wet) (say_it WET_HALF_HITS))
(steps.steps TANGLE (curse tangle) (t_get tangle) (say_it TANGLED_HITS))
(steps.steps SPOOK (curse spook) (say_it SPOOKED_DICE))

; what an enemy's move is for her when she mimics it, v its number: its hit on t (a hit-all on
; them all), its shield, its healing on her, its call a kitten, its cheer or growing a waiting
; plus, its curse on t, its reflect her spikes; the rest do nothing
(steps.steps AS_HIT (hit))
(steps.steps AS_HIT2 (hit) (if_up) (hit))
(steps.steps AS_HIT_ALL (all) (hit) (end))
(steps.steps AS_HEAL (heal))
(steps.steps AS_KITTENS (add kittens) (get kittens) (say KITTENS_JOIN_YOU))
(steps.steps AS_PLUS (add plus) (lit 1) (max plus_left) (get plus) (say NEXT_DIE))
(steps.steps AS_SPIKY (max thorns) (say_me SPIKY))

(struct Mimicry ((effect ac.Effect) (all bool) (fx (ptr u8))))

; a move's row: the first with its effect (all: only a move for every enemy)
(const MIMICRY_COUNT u8 13)

(const MIMICRY (array Mimicry 13)
    (make (array Mimicry 13)
        (make Mimicry :effect ac.Effect.hit :all true :fx (addr_of (at AS_HIT_ALL 0)))
        (make Mimicry :effect ac.Effect.hit2 :all true :fx (addr_of (at AS_HIT_ALL 0)))
        (make Mimicry :effect ac.Effect.hit :all false :fx (addr_of (at AS_HIT 0)))
        (make Mimicry :effect ac.Effect.hit2 :all false :fx (addr_of (at AS_HIT2 0)))
        (make Mimicry :effect ac.Effect.shield :all false :fx (addr_of (at SHIELD 0)))
        (make Mimicry :effect ac.Effect.heal :all false :fx (addr_of (at AS_HEAL 0)))
        (make Mimicry :effect ac.Effect.mend :all false :fx (addr_of (at AS_HEAL 0)))
        (make Mimicry :effect ac.Effect.summon :all false :fx (addr_of (at AS_KITTENS 0)))
        (make Mimicry :effect ac.Effect.cheer :all false :fx (addr_of (at AS_PLUS 0)))
        (make Mimicry :effect ac.Effect.grow :all false :fx (addr_of (at AS_PLUS 0)))
        (make Mimicry :effect ac.Effect.fleas :all false :fx (addr_of (at FLEAS 0)))
        (make Mimicry :effect ac.Effect.wet :all false :fx (addr_of (at WET 0)))
        (make Mimicry :effect ac.Effect.reflect :all false :fx (addr_of (at AS_SPIKY 0))))
    :in aux)

; ---- the hooks: steps a status sets off, when its holder carries it and its value stack is
; not 0 (t: the one it is on, or the enemy that hit her; v: the value stack)

; a wand hit on a red dot: her dice come back (once a play), and a dot is used
(steps.steps DOT_FIRES (back) (lit 1) (t_sub dot))

; her turn ended with a double or nothing's times still waiting
(steps.steps BET_LOST (sub gamble) (hurt) (say_me BET_LOST))

; she was hit through mirror fur: what her shield took goes back, the mirror's most
(steps.steps MIRROR (blocked) (sub mirror) (hurt) (say_it BOUNCED))
; she was hit while spiky: who hit her takes the spikes
(steps.steps THORNS (hurt))
; her shield took a whole hit with a porcupine: the hitter takes its quills (hit.strike)
(steps.steps QUILLS (hurt) (say_it " \x0dtakes # from the quills."))
; she was hit in a flea collar: who hit her gets its fleas (FLEAS); in a hairball wall: tangled
; at its next turn (a snag: content/statuses turn_end)
(steps.steps SNAG (curse snag) (t_get snag) (say_it TANGLED_NEXT))
; a hit she landed on a leech: she heals 1; on a mana leech: its mana (v)
(steps.steps LEECHED (lit 1) (me) (heal))
(steps.steps MANA_LEECHED (mana))

(struct Hook ((status st.Status) (when steps.When) (value st.Status) (fx (ptr u8))))

(const HOOK_COUNT u8 8)

(const HOOKS (array Hook 8)
    (make (array Hook 8)
        (make Hook
            :status st.Status.dot
            :when steps.When.wand_hit
            :value st.Status.dot
            :fx (addr_of (at DOT_FIRES 0)))
        (make Hook
            :status st.Status.mirror
            :when steps.When.hit_her
            :value st.Status.mirror
            :fx (addr_of (at MIRROR 0)))
        (make Hook
            :status st.Status.thorns
            :when steps.When.hit_her
            :value st.Status.thorns
            :fx (addr_of (at THORNS 0)))
        (make Hook
            :status st.Status.gamble
            :when steps.When.turn_end
            :value st.Status.gamble
            :fx (addr_of (at BET_LOST 0)))
        (make Hook
            :status st.Status.collar
            :when steps.When.hit_her
            :value st.Status.collar
            :fx (addr_of (at FLEAS 0)))
        (make Hook
            :status st.Status.wall
            :when steps.When.hit_her
            :value st.Status.wall
            :fx (addr_of (at SNAG 0)))
        (make Hook
            :status st.Status.leech
            :when steps.When.her_hit
            :value st.Status.leech
            :fx (addr_of (at LEECHED 0)))
        (make Hook
            :status st.Status.mleech
            :when steps.When.her_hit
            :value st.Status.mleech
            :fx (addr_of (at MANA_LEECHED 0))))
    :in aux)

; nothing: play.drain runs it to start the waiting hooks
(steps.steps NOTHING)

; ---- the shared steps' rows, for call (in steps.SUB_'s order)

(const SUBS (array (ptr u8) 5)
    (make (array (ptr u8) 5)
        (addr_of (at ZAP_HIT 0))
        (addr_of (at SHIELD 0))
        (addr_of (at TANGLE 0))
        (addr_of (at WET 0))
        (addr_of (at FLEAS 0))))

; a hook's fields, read from aux memory in one go
(fn hook_when ((k u8)) steps.When
    (with_aux true false
        (at HOOKS k when)))

(fn hook_status ((k u8)) u8
    (with_aux true false
        (as u8 (at HOOKS k status))))

(fn hook_value ((k u8)) u8
    (with_aux true false
        (as u8 (at HOOKS k value))))

(fn hook_fx ((k u8)) (ptr u8)
    (with_aux true false
        (at HOOKS k fx)))

; the row of MIMICRY for a move of effect e (all: for every enemy), NOTHING for none
(fn mimicry ((e ac.Effect) (all bool)) u8
    (with_aux true false
        (for k u8 0 MIMICRY_COUNT
            (if (and (= (at MIMICRY k effect) e) (or all (not (at MIMICRY k all))))
                (return k)))
        255))

(fn mimicry_fx ((k u8)) (ptr u8)
    (with_aux true false
        (at MIMICRY k fx)))
