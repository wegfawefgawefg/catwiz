; what the charms do (content/encounters CHARMS: passives kept all run, state.charms counts each
; one held), at the moments the engine calls these hooks. The kittens' pounce and the trio's
; hit are in content/effects (they strike).

(import state)
(import content/encounters enc)
(import content/statuses st)
(import battle/log)

(const KITTENS_MOST u8 5)

; how much of charm kind the run holds: its amount, once for each one held
(fn amount ((kind enc.CharmKind)) u8
    (let n u8 0)
    (for c u8 0 10
        (if (= (at enc.CHARMS c kind) kind)
            (for k u8 0 (at state.charms c)
                (set n (+ n (at enc.CHARMS c amount))))))
    n)

(fn held ((kind enc.CharmKind)) bool
    (> (amount kind) 0))

; the dice a fight rolls: a sixth toe adds one
(fn dice () u8
    (let n u8 (+ state.DICE (amount enc.CharmKind.toe)))
    (if (> n state.DICE_MOST)
        (set n state.DICE_MOST))
    n)

(fn add ((status st.Status) (n u8)) void
    (let s u8 (as u8 status))
    (state.set_stack state.HERO s (+ (state.stack state.HERO s) n)))

; a fight starts: a mother cat's kittens, bad milk's fleas
(fn fight_start () void
    (let kittens u8 (amount enc.CharmKind.mother))
    (if (> kittens KITTENS_MOST)
        (set kittens KITTENS_MOST))
    (state.set_stack state.HERO (as u8 st.Status.kittens) kittens)
    (if (held enc.CharmKind.badmilk)
        (do
            (state.set_stack state.HERO (as u8 st.Status.poison) 2)
            (state.set_stack state.HERO (as u8 st.Status.flea_turns) 3))))

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

; she lost hit points: a kitten runs off; a grumpy face gives mana
(fn hero_hurt () void
    (let kittens u8 (state.stack state.HERO (as u8 st.Status.kittens)))
    (if (> kittens 0)
        (do
            (state.set_stack state.HERO (as u8 st.Status.kittens) (- kittens 1))
            (log.line "A kitten runs off." 0)))
    (st.gain_mana (amount enc.CharmKind.grumpy)))

; a ward pip took a curse (hers or an enemy's): a rubber duck's shield
(fn ward_blocked () void
    (let duck u8 (amount enc.CharmKind.duck))
    (if (> duck 0)
        (add st.Status.shield duck)))

; her turn ends with no re-roll in it: still water's mana
(fn still_water () void
    (if (not state.rerolled)
        (st.gain_mana (amount enc.CharmKind.still))))
