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

; the log's sentences, in aux memory (battle/log reads them there): SAY_ and their words
(const SAY (array (ptr u8) 8)
    (make (array (ptr u8) 8)
        "It misses the box."
        " shields #."
        " will hit # harder."
        " grabs a die: beat it back."
        " hits # harder for good."
        " will send # back."
        "A hairball clogs a slot. Re-roll!"
        " comes along.")
    :strings aux)

(const SAY_MISSES_BOX u8 0)
(const SAY_SHIELDS u8 1)
(const SAY_WILL_HIT_HARDER u8 2)
(const SAY_GRABS_DIE_BEAT u8 3)
(const SAY_HITS_HARDER_FOR u8 4)
(const SAY_WILL_SEND_BACK u8 5)
(const SAY_HAIRBALL_CLOGS_SLOT u8 6)
(const SAY_COMES_ALONG u8 7)

(const SKIP_ICON u8 '@') ; a Z over its head: it skips its move

; whether enemy who stalls this turn: it lost its kind's stall or more in the hero's turn
(fn stalls ((who u8)) bool
    (let stall u8 (en.stall (at state.actors who kind)))
    (and (> stall 0) (>= (state.stack who (as u8 st.Status.hurt)) stall)))

; whether enemy who makes no move this turn: it just came in or got up, or it stalls
(fn skips ((who u8)) bool
    (or (st.skips who) (stalls who)))

; who an enemy's move goes to: itself, a friend (the first other one standing, left to right;
; itself when alone), else the hero. A lasered enemy's hit goes to a friend, or to the hero when
; it has none; the laser is used up (use: the move is made, not only shown)
(fn move_target ((by u8) (row u8) (use bool)) u8
    (let aim state.Aim (mv.aim row))
    (let effect ac.Effect (mv.effect row))
    (if (= aim state.Aim.self)
        (return by))
    (if (and (> (state.stack by (as u8 st.Status.laser)) 0)
            (or (= effect ac.Effect.hit) (= effect ac.Effect.hit2)))
        (do
            (if use
                (state.set_stack by (as u8 st.Status.laser) 0))
            (return (friend by state.HERO))))
    (if (= aim state.Aim.friend)
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
    (let effect ac.Effect (mv.effect row))
    (let amount u8 (mv.amount row))
    (if (or (= effect ac.Effect.hit) (= effect ac.Effect.hit2))
        (return (st.dealt who amount false)))
    amount)

; whether its number shows by its glyph: a move with a number (a countdown, a grab, a hairball
; or a soaking have none)
(fn shows_amount ((row u8)) bool
    (and (> (mv.amount row) 0) (!= (mv.effect row) ac.Effect.junk)))

; the glyph shown over an enemy for its next move: a Z when it will skip it
(fn intent_icon ((who u8) (row u8)) u8
    (if (skips who)
        (return SKIP_ICON))
    (mv.icon row))

; what the bottom text says an enemy will do next: its move's text, or that it will skip it (in
; aux memory, as the moves' are: text.add_aux)
(const QUIET (array (ptr u8) 2) (make (array (ptr u8) 2) "Finds its feet" "Stalls") :strings aux)

(fn intent_text ((who u8) (row u8)) (ptr u8)
    (if (st.skips who)
        (return (at QUIET 0)))
    (if (stalls who)
        (return (at QUIET 1)))
    (mv.text row))

; an enemy's move lands. Hit-all moves miss a hero in a box
(fn land_move ((row u8) (by u8) (target u8)) void
    (if (and (and (= (mv.aim row) state.Aim.all) (= target state.HERO))
            (> (state.stack target (as u8 st.Status.box)) 0))
        (do
            (sound.cue sound.Cue.ping)
            (log.line (at SAY SAY_MISSES_BOX) 0)
            (return)))
    (apply (mv.effect row) by target (mv.amount row)))

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
            (log.who target (at SAY SAY_SHIELDS) n))
        (ac.Effect.heal
            (sound.cue sound.Cue.chime)
            (hit.heal target n))
        (ac.Effect.cheer
            (sound.cue sound.Cue.chime)
            (hit.add_stacks target (as u8 st.Status.cheer) n)
            (log.who target (at SAY SAY_WILL_HIT_HARDER) n))
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
                    (log.who by (at SAY SAY_GRABS_DIE_BEAT) 0))))
        (ac.Effect.grow
            (sound.cue sound.Cue.wobble)
            (hit.add_stacks by (as u8 st.Status.strength) n)
            (log.who by (at SAY SAY_HITS_HARDER_FOR) n))
        (ac.Effect.reflect
            (sound.cue sound.Cue.ping)
            (hit.add_stacks by (as u8 st.Status.reflect) n)
            (log.who by (at SAY SAY_WILL_SEND_BACK) n))
        (ac.Effect.junk
            (if (not (at state.clogged n))
                (do
                    (sound.cue sound.Cue.puff)
                    (set (at state.clogged n) true)
                    (log.line (at SAY SAY_HAIRBALL_CLOGS_SLOT) 0))))
        (ac.Effect.fleas (fx.curse effect target n))
        (ac.Effect.wet (fx.curse effect target n))
        (ac.Effect.spook (fx.curse effect target n))
        (_)))

; n of by's kind's calls into empty spots, each waiting a round before its first move
(fn summon ((by u8) (n u8)) void
    (let kind u8 (en.calls (at state.actors by kind)))
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
                (log.who spot (at SAY SAY_COMES_ALONG) 0)))))

; the next of its moves, round and round (moves_made counts within the round)
(fn next_move ((i u8)) void
    (let kind u8 (at state.actors i kind))
    (let made u8 (+ (at state.actors i moves_made) 1))
    (if (>= made (en.move_count kind))
        (set made 0))
    (set (at state.actors i moves_made) made)
    (set (at state.actors i move) (+ (en.first_move kind) made)))
