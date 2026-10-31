; what the enemies' moves do (content/moves): the one match on the effect kind for them, who a
; move goes to, and what the hud shows of it before it comes. The rules are the balance sim's
; (tools/sim/rules.py, foes.py).

(import state)
(import battle/hit)
(import battle/log)
(import battle/spawn)
(import content/action ac)
(import content/effects fx)
(import content/enemies en)
(import content/moves mv)
(import content/statuses st)
(import sound/sound)

(const SKIP_ICON u8 '@') ; a Z over its head: it skips its move

; whether enemy who stalls this turn: it lost its kind's stall or more in the hero's turn
(fn stalls ((who u8)) bool
    (let stall u8 (at en.ENEMIES (at state.actors who kind) stall))
    (and (> stall 0) (>= (state.stack who (as u8 st.Status.hurt)) stall)))

; whether enemy who makes no move this turn: it just came in or got up, or it stalls
(fn skips ((who u8)) bool
    (or (st.skips who) (stalls who)))

; who an enemy's move goes to: itself, a friend (the first other one standing, left to right;
; itself when alone), else the hero. A lasered enemy's hit goes to a friend, or to the hero when
; it has none; the laser is used up (use: the move is made, not only shown)
(fn move_target ((by u8) (row u8) (use bool)) u8
    (let move ac.Move (at mv.MOVES row))
    (if (= move.aim state.Aim.self)
        (return by))
    (if (and (> (state.stack by (as u8 st.Status.laser)) 0)
            (or (= move.effect ac.Effect.hit) (= move.effect ac.Effect.hit2)))
        (do
            (if use
                (state.set_stack by (as u8 st.Status.laser) 0))
            (return (friend by state.HERO))))
    (if (= move.aim state.Aim.friend)
        (return (friend by by)))
    state.HERO)

; the first enemy standing other than by, else alone
(fn friend ((by u8) (alone u8)) u8
    (for i u8 1 state.ACTORS
        (if (and (!= i by) (at state.actors i alive))
            (return i)))
    alone)

; the number shown over an enemy for its next move: a hit after its own statuses
(fn intent_amount ((who u8) (row u8)) u8
    (let move ac.Move (at mv.MOVES row))
    (if (or (= move.effect ac.Effect.hit) (= move.effect ac.Effect.hit2))
        (return (st.dealt who move.amount false)))
    move.amount)

; whether its number shows by its glyph: a move with a number (a countdown, a grab, a hairball
; or a soaking have none)
(fn shows_amount ((row u8)) bool
    (and (> (at mv.MOVES row amount) 0) (!= (at mv.MOVES row effect) ac.Effect.junk)))

; the glyph shown over an enemy for its next move: a Z when it will skip it
(fn intent_icon ((who u8) (row u8)) u8
    (if (skips who)
        (return SKIP_ICON))
    (at mv.MOVES row icon))

; what the bottom text says an enemy will do next: its move's text, or that it will skip it
(fn intent_text ((who u8) (row u8)) (ptr u8)
    (if (st.skips who)
        (return "Finds its feet"))
    (if (stalls who)
        (return "Stalls"))
    (at mv.MOVES row text))

; an enemy's move lands. Hit-all moves miss a hero in a box
(fn land_move ((row u8) (by u8) (target u8)) void
    (let move ac.Move (at mv.MOVES row))
    (if (and (and (= move.aim state.Aim.all) (= target state.HERO))
            (> (state.stack target (as u8 st.Status.box)) 0))
        (do
            (sound.cue sound.Cue.ping)
            (log.line "It misses the box." 0)
            (return)))
    (apply move.effect by target move.amount))

(fn apply ((effect ac.Effect) (by u8) (target u8) (n u8)) void
    (match effect
        (ac.Effect.hit
            (sound.cue sound.Cue.zap)
            (hit.strike by target n false))
        (ac.Effect.hit2
            (sound.cue sound.Cue.zap)
            (hit.strike by target n false)
            (if (at state.actors target alive)
                (hit.strike by target n false)))
        (ac.Effect.shield
            (sound.cue sound.Cue.ping)
            (hit.add_stacks target (as u8 st.Status.shield) n)
            (log.who target " shields #." n))
        (ac.Effect.heal
            (sound.cue sound.Cue.chime)
            (hit.heal target n))
        (ac.Effect.cheer
            (sound.cue sound.Cue.chime)
            (hit.add_stacks target (as u8 st.Status.cheer) n)
            (log.who target " will hit # harder." n))
        (ac.Effect.mend
            (sound.cue sound.Cue.chime)
            (for i u8 1 state.ACTORS
                (if (and (!= i by) (at state.actors i alive))
                    (hit.heal i n))))
        (ac.Effect.summon (summon by n))
        (ac.Effect.steal
            (let d u8 state.last_played)
            (if (and (!= d state.NOTHING) (= (at state.held d) state.NOTHING))
                (do
                    (sound.cue sound.Cue.squeak)
                    (set (at state.held d) by)
                    (log.who by " grabs a die: beat it back." 0))))
        (ac.Effect.grow
            (sound.cue sound.Cue.wobble)
            (hit.add_stacks by (as u8 st.Status.strength) n)
            (log.who by " hits # harder for good." n))
        (ac.Effect.reflect
            (sound.cue sound.Cue.ping)
            (hit.add_stacks by (as u8 st.Status.reflect) n)
            (log.who by " will send # back." n))
        (ac.Effect.junk
            (if (not (at state.clogged n))
                (do
                    (sound.cue sound.Cue.puff)
                    (set (at state.clogged n) true)
                    (log.line "A hairball clogs a slot. Re-roll!" 0))))
        (ac.Effect.fleas (fx.curse effect target n))
        (ac.Effect.wet (fx.curse effect target n))
        (ac.Effect.spook (fx.curse effect target n))
        (_)))

; n of by's kind's calls into empty spots, each waiting a round before its first move
(fn summon ((by u8) (n u8)) void
    (let kind u8 (at en.ENEMIES (at state.actors by kind) calls))
    (sound.cue sound.Cue.growl)
    (for k u8 0 n
        (let spot u8 state.NOTHING)
        (for i u8 1 state.ACTORS
            (if (and (= spot state.NOTHING) (not (at state.actors i alive)))
                (set spot i)))
        (if (!= spot state.NOTHING)
            (do
                (spawn.enemy spot kind true)
                (set state.hud_pills (| state.hud_pills (<< 1 spot)))
                (log.who spot " comes along." 0)))))

; the next of its moves, round and round (moves_made counts within the round)
(fn next_move ((i u8)) void
    (let kind u8 (at state.actors i kind))
    (let made u8 (+ (at state.actors i moves_made) 1))
    (if (>= made (at en.ENEMIES kind move_count))
        (set made 0))
    (set (at state.actors i moves_made) made)
    (set (at state.actors i move) (+ (at en.ENEMIES kind first_move) made)))
