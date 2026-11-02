; the steps a card's effect is made of (the owner, 2026-11-01: cards as data, so a new card costs
; table bytes, not code). A card's steps are a row of bytes in aux memory, two a step: what it
; does (Op) and its argument. content/cards.tsp writes them with the steps macro below;
; content/play.tsp runs them. While steps run they keep a target t (an enemy, or her), the
; card's number n (its # after levels and boosts) and a value v (n to start with), which the
; steps that give or take an amount use.
;
; values:     num (v = n), lit k (v = k), kits k (v + k a kitten), get s (v = her stack s),
;             least k (v at least k), most k (v at most k), kept (v = the kittens kept from the last fight)
; conditions: has s (the next step only when her stack s is not 0), if_up (the rest of the loop, or
;             of the steps, only while t stands), three (the rest only when this face is her
;             slot's third this turn: the item's three), calm (the rest only when she has not
;             re-rolled this turn)
; stacks:     add s, set s, max s, times s (her stack s plus, set to, at least, times v),
;             sub s (less v, 0 at least). t_add, t_set, t_sub, t_get, t_has: t's stack instead
; her:        mana (+v, 5 at most), spill (+v mana; v becomes what went past 5), rerolls (+v,
;             9 at most), heal (v hit points back)
; on t:       hit (v, her statuses and its shield), pierce (no shield), plain (its shield
;             only), hurt (v hit points off, none for 0), curse s (a ward pip on t takes it and
;             the steps stop; else its stack s plus v), pounce (her kittens pounce t)
; targets:    all ... end (the steps between for each enemy standing, left to right), others
;             ... end (the same, not t), rep ... end (v times; no loop inside a loop), next
;             (t = the next enemy standing after t; the steps stop when none), pick (t = another
;             enemy standing, picked at random; the steps stop when none), retarget (t is
;             down: the next standing), me (t = her)
; calls:      call k (a shared row of cards.SUBS, then on), stop (the end: the macro adds it)
; chains:     back (every die comes back to be rolled again after this play; stops when they
;             already will), blocked (v at most what her shield took of the last hit on her)
; the uniques, each a native routine: copy (copycat: her last face again), look and mimic
;             (Mimic: what t's shown move would be for her, then do it)
; sound, log: cue c (a sound), say l, say_it l, say_me l (a line of effects_said's SAY, with v
;             for its #; say_it and say_me name t or her first)
;
; Triggers: content/cards.tsp HOOKS runs steps when an enemy holding a status is hit by a wand
; or falls, when she is hit holding one, or at her turn's end; a charm's row (content/encounters
; CHARMS) names a moment of its own (When) and its steps. They run as soon as what set them off
; is done (content/hooks queues them).

(import content/statuses st)
(import content/effects_said said)
(import sound/sound)

; the ops, a byte each (content/play matches on them)
(const NUM u8 0)
(const LIT u8 1)
(const KITS u8 2)
(const GET u8 3)
(const LEAST u8 4)
(const KEPT u8 5)
(const IF u8 6)
(const IF_UP u8 7)
(const THREE u8 8)
(const CALM u8 9)
(const ADD u8 10)
(const SET u8 11)
(const MAX u8 12)
(const TIMES u8 13)
(const SUB u8 14)
(const MANA u8 15)
(const SPILL u8 16)
(const REROLLS u8 17)
(const HEAL u8 18)
(const HIT u8 19)
(const PIERCE u8 20)
(const PLAIN u8 21)
(const HURT u8 22)
(const CURSE u8 23)
(const POUNCE u8 24)
(const ALL u8 25)
(const REP u8 26)
(const END u8 27)
(const NEXT u8 28)
(const RETARGET u8 29)
(const ME u8 30)
(const DO u8 31)
(const STOP u8 32)
(const BACK u8 33)
(const BLOCKED u8 34)
(const COPY u8 35)
(const MIMIC u8 36)
(const CUE u8 37)
(const SAY u8 38)
(const MOST u8 39)

; a stack step's argument: the status, plus ON_T for t's stack instead of hers
(const ON_T u8 0x80)
; a say's argument: the line, plus SAY_IT to name t first, or SAY_ME to name her
(const SAY_IT u8 0x80)
(const SAY_ME u8 0x40)
(const SAY_LINE u8 0x3F)

; when a hook runs: an enemy with the status is hit by a wand (wand_hit), falls (falls), she is
; hit by an enemy holding it (hit_her), her turn ends (turn_end); and the charms' moments: a
; fight starts, she is hurt, a ward pip takes a curse, a three, she would die (dies: the charm
; brings her back, content/charms saved), none (a charm that changes a rule instead)
(enum When (wand_hit falls hit_her turn_end fight_start hurt warded three dies none))

; (steps NAME (op arg) ...): a card's steps as a byte row in aux memory, a stop added at the end.
; kind_of: a step as written in content/cards.tsp, its op and the kind of its argument; arg_of:
; the argument for its kind (none, a number: a form from the card's file, a status: hers or
; t's, a sound cue, a log line)
(macro steps (name & rows)
    (let kind_of (fn (word)
        (match word
            ('num (list 'NUM 'none))
            ('lit (list 'LIT 'num))
            ('kits (list 'KITS 'num))
            ('get (list 'GET 'her))
            ('t_get (list 'GET 'its))
            ('least (list 'LEAST 'num))
            ('most (list 'MOST 'num))
            ('kept (list 'KEPT 'none))
            ('has (list 'IF 'her))
            ('t_has (list 'IF 'its))
            ('if_up (list 'IF_UP 'none))
            ('three (list 'THREE 'none))
            ('calm (list 'CALM 'none))
            ('add (list 'ADD 'her))
            ('t_add (list 'ADD 'its))
            ('set (list 'SET 'her))
            ('t_set (list 'SET 'its))
            ('max (list 'MAX 'her))
            ('times (list 'TIMES 'her))
            ('sub (list 'SUB 'her))
            ('t_sub (list 'SUB 'its))
            ('mana (list 'MANA 'none))
            ('spill (list 'SPILL 'none))
            ('rerolls (list 'REROLLS 'none))
            ('heal (list 'HEAL 'none))
            ('hit (list 'HIT 'none))
            ('pierce (list 'PIERCE 'none))
            ('plain (list 'PLAIN 'none))
            ('hurt (list 'HURT 'none))
            ('curse (list 'CURSE 'its))
            ('pounce (list 'POUNCE 'none))
            ('all (list 'ALL 'none))
            ('others (list 'ALL 'others))
            ('rep (list 'REP 'none))
            ('end (list 'END 'none))
            ('next (list 'NEXT 'none))
            ('pick (list 'NEXT 'pick))
            ('retarget (list 'RETARGET 'none))
            ('me (list 'ME 'none))
            ('call (list 'DO 'num))
            ('stop (list 'STOP 'none))
            ('back (list 'BACK 'none))
            ('blocked (list 'BLOCKED 'none))
            ('copy (list 'COPY 'none))
            ('look (list 'MIMIC 'none))
            ('mimic (list 'MIMIC 'mimic))
            ('cue (list 'CUE 'cue))
            ('say (list 'SAY 'say))
            ('say_it (list 'SAY 'say_it))
            ('say_me (list 'SAY 'say_me))
            (_ (error "steps: no step " word)))))
    (let arg_of (fn (sort a)
        (match sort
            ('none 0)
            ('num a)
            ('her `(as u8 ,(symbol 'st.Status. a)))
            ('its `(+ (as u8 ,(symbol 'st.Status. a)) ON_T))
            ('cue `(as u8 ,(symbol 'sound.Cue. a)))
            ('say (symbol 'said.SAY_ a))
            ('say_it `(+ ,(symbol 'said.SAY_ a) SAY_IT))
            ('say_me `(+ ,(symbol 'said.SAY_ a) SAY_ME))
            ('others 1)
            ('mimic 1)
            ('pick 1)
            (_ (error "steps: no argument kind " sort)))))
    (let bytes (list))
    (for i 0 (len rows)
        (let r (nth rows i))
        (let k (kind_of (head r)))
        (set bytes
            (append bytes
                (list (nth k 0)
                    (arg_of (nth k 1) (if (> (len r) 1)
                        (nth r 1)
                        0))))))
    (set bytes (append bytes (list 'STOP 0)))
    `(const ,name (array u8 ,(len bytes)) (make (array u8 ,(len bytes)) ,@bytes) :in aux))
