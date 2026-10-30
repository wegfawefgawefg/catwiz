; the top two rows of the bottom text: what the player needs to choose. With a die picked, its
; name and what it does (with its number after boosts) and how to play it; else the target's
; name, hit points, statuses and next move in words; on the enemies' turn the hero's own. The
; log (battle/log.tsp) has the two rows under it. Drawn again only when something it shows
; may have changed.

(import state)
(import draw/text)
(import battle/log)
(import content/action ac)
(import content/faces)
(import content/enemies en)
(import content/effects fx)
(import content/statuses st)

(const PROMPT_COL u8 26)

; what the rows were drawn for, so a change of phase draws them again
(let shown_phase state.Phase state.Phase.won)

; who's name, hit points and statuses on one row
(fn actor_row ((who u8)) void
    (text.start)
    (text.add (log.name who))
    (text.char ' ')
    (text.number (at state.actors who hp))
    (text.char '/')
    (text.number (at state.actors who max_hp))
    (text.add " HP")
    (for s u8 0 st.STATUS_COUNT
        (let n u8 (state.stack who s))
        (let show st.Show (at st.SHOW s))
        (if (and (> n 0) (!= show st.Show.hidden))
            (do
                (text.char ' ')
                (text.add (at st.NAME s))
                (if (!= show st.Show.flag)
                    (text.number n)))))
    (text.show 0))

; the face row in slot d of the tray: a die's face, or the meow past the dice
(fn face_of ((d u8)) u8
    (if (= d state.HAND)
        (return faces.MEOW))
    (at state.hand d))

; the face in slot d, and how to play it
(fn die_rows ((d u8)) void
    (let row u8 (face_of d))
    (let face ac.Action (at faces.FACES row))
    (text.start)
    (set text.inverse true)
    (text.add face.name)
    (set text.inverse false)
    (text.tab PROMPT_COL)
    (if (not (fx.can_play row))
        (text.add_n "NEEDS # MANA" face.cost)
        (if (= face.aim state.Aim.foe)
            (text.add "PICK AN ENEMY")
            (do
                (text.add "PRESS ")
                (text.char (+ '1' d))
                (text.add " AGAIN"))))
    (text.show 0)
    (text.start)
    (let n u8 face.amount)
    (if (and (!= face.effect ac.Effect.plus) (!= face.effect ac.Effect.double))
        (set n (fx.boosted n)))
    (text.add_n face.text n)
    (text.show 1))

; the target's next move
(fn intent_row ((who u8)) void
    (text.start)
    (if (at state.actors who alive)
        (do
            (let row u8 (at state.actors who move))
            (text.add "NEXT: ")
            (text.add_n (at en.MOVES row text) (fx.intent_amount who row))))
    (text.show 1))

(fn line_row ((r u8) (s (ptr u8))) void
    (text.start)
    (text.add s)
    (text.show r))

; on the enemies' turn: the hero's own state
(fn their_turn () void
    (actor_row state.DOG)
    (line_row 1 "THEIR TURN"))

(fn refresh () void
    (if (and (and (not state.hud_words) (= shown_phase state.phase))
            (and (= state.hud_pills 0) (= state.hud_intents 0)))
        (return))
    (set state.hud_words false)
    (set shown_phase state.phase)
    (match state.phase
        (state.Phase.enemies (their_turn))
        (state.Phase.rolling
            (actor_row state.DOG)
            (line_row 1 "ROLLING"))
        (state.Phase.won
            (line_row 0 "THE WOODS GO QUIET.")
            (line_row 1 ""))
        (state.Phase.lost
            (actor_row state.DOG)
            (line_row 1 ""))
        (state.Phase.reward)
        (_
            (if (and (= state.phase state.Phase.acting) (= state.act_source state.Source.move))
                (do
                    (their_turn)
                    (return)))
            (if (!= state.selected state.NOTHING)
                (die_rows state.selected)
                (do
                    (actor_row state.target)
                    (intent_row state.target))))))

; the run is over: won (to be continued) or lost
(fn ending ((won bool)) void
    (text.start)
    (if won
        (text.add "THE WOODS GO QUIET. TO BE CONTINUED...")
        (do
            (text.add (log.name state.DOG))
            (text.add " IS DOWN. THE RUN IS OVER.")))
    (text.show 0)
    (line_row 1 "PRESS RETURN"))
