; what dice faces and enemy moves do: the one match on the effect kind (content/action) that
; carries them out. The rules: every effect does exactly what its text says; the dice are the
; only luck.

(import state)
(import battle/hit)
(import battle/log)
(import content/action ac)
(import content/faces)
(import content/enemies en)
(import content/statuses st)
(import sound/sound)

(const MOST_MANA u8 5)
(const FLEA_TURNS u8 3)
(const HAIRBALL_FLEAS u8 2)
(const ZOOMIES_HITS u8 5)
(const SCREAM_SELF u8 1)

(fn mana () u8
    (state.stack state.HERO (as u8 st.Status.mana)))

; whether the hero can play face row now: spells need their mana
(fn can_play ((row u8)) bool
    (<= (at faces.FACES row cost) (mana)))

; amount after the boosts the +1 and x2 faces left for the next die
(fn boosted ((n u8)) u8
    (let doubles u8 (state.stack state.HERO (as u8 st.Status.double)))
    (+ (<< n doubles) (state.stack state.HERO (as u8 st.Status.plus))))

; the hero's face lands. +1 and x2 add to the boost for the next die; any other face uses
; the boost up, and a spell its mana
(fn land_face ((row u8) (target u8)) void
    (let plus u8 (as u8 st.Status.plus))
    (let double u8 (as u8 st.Status.double))
    (match (at faces.FACES row effect)
        (ac.Effect.plus
            (sound.cue sound.Cue.chime)
            (hit.add_stacks state.HERO plus (at faces.FACES row amount))
            (log.line "The next die gets +#." (state.stack state.HERO plus))
            (return))
        (ac.Effect.double
            (sound.cue sound.Cue.chime)
            (state.set_stack state.HERO plus (<< (state.stack state.HERO plus) 1))
            (hit.add_stacks state.HERO double 1)
            (log.line "The next die does double." 0)
            (return))
        (_))
    (let n u8 (boosted (at faces.FACES row amount)))
    (state.set_stack state.HERO plus 0)
    (state.set_stack state.HERO double 0)
    (if (> (at faces.FACES row cost) 0)
        (state.set_stack state.HERO (as u8 st.Status.mana) (- (mana) (at faces.FACES row cost))))
    (apply (at faces.FACES row effect) state.HERO target n))

; an enemy's move lands. Hit-all moves miss a hero in a box
(fn land_move ((row u8) (by u8) (target u8)) void
    (let move ac.Action (at en.MOVES row))
    (if (and (= move.aim state.Aim.all) (> (state.stack target (as u8 st.Status.box)) 0))
        (do
            (sound.cue sound.Cue.ping)
            (log.line "It misses the box." 0)
            (return)))
    (apply move.effect by target move.amount))

; who an enemy's move goes to: the hero, itself, or a friend (the first other one standing,
; left to right; itself when it is alone)
(fn move_target ((by u8) (row u8)) u8
    (match (at en.MOVES row aim)
        (state.Aim.self by)
        (state.Aim.friend
            (for i u8 1 state.ACTORS
                (if (and (!= i by) (at state.actors i alive))
                    (return i)))
            by)
        (_ state.HERO)))

; the number shown over an enemy for its next move: a hit after its own statuses
(fn intent_amount ((who u8) (row u8)) u8
    (let move ac.Action (at en.MOVES row))
    (if (= move.effect ac.Effect.hit)
        (return (st.dealt who move.amount false)))
    move.amount)

; the glyph shown over an enemy for its next move: @ (a Z) when it will skip it
(fn intent_icon ((who u8) (row u8)) u8
    (if (> (state.stack who (as u8 st.Status.hiss)) 0)
        (return '@'))
    (at en.MOVES row icon))

; what the bottom text says an enemy will do next: its move's text, or that it will skip it
(fn intent_text ((who u8) (row u8)) (ptr u8)
    (if (> (state.stack who (as u8 st.Status.hiss)) 0)
        (return "Skips its move"))
    (at en.MOVES row text))

(fn apply ((effect ac.Effect) (by u8) (target u8) (n u8)) void
    (match effect
        (ac.Effect.hit
            (sound.cue sound.Cue.zap)
            (hit.strike by target n))
        (ac.Effect.shield
            (sound.cue sound.Cue.ping)
            (hit.add_stacks target (as u8 st.Status.shield) n)
            (log.who target " shields #." n))
        (ac.Effect.heal
            (sound.cue sound.Cue.chime)
            (hit.heal target n))
        (ac.Effect.mana
            (sound.cue sound.Cue.chime)
            (let now u8 (+ (mana) n))
            (if (> now MOST_MANA)
                (set now MOST_MANA))
            (state.set_stack state.HERO (as u8 st.Status.mana) now)
            (log.line "Mana is now #." now))
        (ac.Effect.hairball
            (sound.cue sound.Cue.zap)
            (hit.strike by target n)
            (if (at state.actors target alive)
                (curse ac.Effect.fleas target HAIRBALL_FLEAS)))
        (ac.Effect.zoomies
            (sound.cue sound.Cue.zap)
            (let t u8 0)
            (for k u8 0 ZOOMIES_HITS
                (set t (next_standing t))
                (if (!= t state.NOTHING)
                    (hit.strike by t n))))
        (ac.Effect.box
            (sound.cue sound.Cue.ping)
            (hit.add_stacks target (as u8 st.Status.shield) n)
            (state.set_stack target (as u8 st.Status.box) 1)
            (log.who target " hides in a box: shield #." n))
        (ac.Effect.scream
            (sound.cue sound.Cue.wobble)
            (for i u8 1 state.ACTORS
                (if (at state.actors i alive)
                    (hit.strike by i n)))
            (hit.lose state.HERO SCREAM_SELF)
            (log.who state.HERO " takes # from screaming." SCREAM_SELF))
        (ac.Effect.cheer
            (sound.cue sound.Cue.chime)
            (hit.add_stacks target (as u8 st.Status.cheer) n)
            (log.who target " will hit # harder." n))
        (ac.Effect.nothing
            (sound.cue sound.Cue.puff)
            (log.line "Lint. Nothing happens." 0))
        (ac.Effect.plus)
        (ac.Effect.double)
        (_ (curse effect target n))))

; the next enemy standing after t, left to right and round again; NOTHING when none is
(fn next_standing ((t u8)) u8
    ; once every enemy is down, stay down: NOTHING + 1 would wrap round to the hero
    (if (= t state.NOTHING)
        (return state.NOTHING))
    (for n u8 0 3
        (set t (+ t 1))
        (if (= t state.ACTORS)
            (set t 1))
        (if (at state.actors t alive)
            (return t)))
    state.NOTHING)

; a curse always lands: on a ward it breaks one pip instead of taking effect
(fn curse ((effect ac.Effect) (target u8) (n u8)) void
    (sound.cue sound.Cue.hiss)
    (let ward u8 (state.stack target (as u8 st.Status.ward)))
    (if (> ward 0)
        (do
            (state.set_stack target (as u8 st.Status.ward) (- ward 1))
            (log.who target ": ward broken, no curse." 0)
            (return)))
    (match effect
        (ac.Effect.fleas
            (hit.add_stacks target (as u8 st.Status.poison) n)
            (state.set_stack target (as u8 st.Status.flea_turns) FLEA_TURNS)
            (log.who target " gets fleas: # a turn." (state.stack target (as u8 st.Status.poison))))
        (ac.Effect.wet
            (state.set_stack target (as u8 st.Status.wet) 1)
            (log.who target " is wet: half damage." 0))
        (ac.Effect.hiss
            (state.set_stack target (as u8 st.Status.hiss) 1)
            (log.who target " is hissed at: skips." 0))
        (_
            (state.set_stack target (as u8 st.Status.shield) 0)
            (log.who target " has a bath: no shield." 0))))
