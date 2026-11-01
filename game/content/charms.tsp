; what the charms do (content/encounters CHARMS: passives kept all run, state.charms counts each
; one held). A charm that acts at a moment runs its steps then (content/cards.tsp, queued here
; with hook, run by content/play); the rest change a rule, read here by kind (amount). The
; kittens' bite and a wand's bad milk are read in content/effects.

(import state)
(import content/encounters enc)
(import content/hooks)
(import content/statuses st)
(import content/steps)
(import battle/log)

; the log's sentences, in aux memory (battle/log reads them there): SAY_ and their words
(const SAY (array (ptr u8) 1) (make (array (ptr u8) 1) "A kitten runs off.") :strings aux)

(const SAY_KITTEN_RUNS_OFF u8 0)

(const CHARM_COUNT u8 10)

; each kind's row of enc.CHARMS
(const KIND_ROW (array u8 10)
    (make (array u8 10)
        enc.CHARM_BAD_MILK
        enc.CHARM_RUBBER_DUCK
        enc.CHARM_GRUMPY
        enc.CHARM_MITTENS
        enc.CHARM_MOTHER_CAT
        enc.CHARM_SCRATCH_POST
        enc.CHARM_STILL_WATER
        enc.CHARM_FLUFFY_TAIL
        enc.CHARM_SIXTH_TOE
        enc.CHARM_TRIO))

; how much of charm c the run holds: its amount, once for each one held
(fn of ((c u8)) u8
    (let held u8 (at state.charms c))
    (if (= held 0)
        (return 0))
    (let a u8 (enc.charm_amount c))
    (let n u8 0)
    (for k u8 0 held
        (set n (+ n a)))
    n)

; and of charm kind
(fn amount ((kind enc.CharmKind)) u8
    (of (at KIND_ROW (as u8 kind))))

(fn held ((kind enc.CharmKind)) bool
    (> (at state.charms (at KIND_ROW (as u8 kind))) 0))

; the charms she holds that act at moment when: their steps wait to run (content/play), v their
; amount
(fn hook ((when steps.When)) void
    (for c u8 0 CHARM_COUNT
        (if (> (at state.charms c) 0)
            (if (= (enc.charm_when c) when)
                (hooks.add (enc.charm_fx c) state.HERO (of c))))))

; the dice a fight rolls: a sixth toe adds one
(fn dice () u8
    (let n u8 (+ state.DICE (amount enc.CharmKind.toe)))
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
    (if (> (state.stack state.HERO (as u8 st.Status.keep)) 0)
        (do
            (state.set_stack state.HERO shield old)
            (state.set_stack state.HERO (as u8 st.Status.keep) 0)))
    (if (held enc.CharmKind.tail)
        (if (> (>> old 1) (state.stack state.HERO shield))
            (state.set_stack state.HERO shield (>> old 1))))
    (- (+ 2 (amount enc.CharmKind.pocket)) (amount enc.CharmKind.toe)))

; she lost hit points: a kitten runs off; the charms for it (a grumpy face's mana)
(fn hero_hurt () void
    (let kittens u8 (state.stack state.HERO (as u8 st.Status.kittens)))
    (if (> kittens 0)
        (do
            (state.set_stack state.HERO (as u8 st.Status.kittens) (- kittens 1))
            (log.line (at SAY SAY_KITTEN_RUNS_OFF) 0)))
    (hook steps.When.hurt))
