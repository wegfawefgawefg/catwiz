; the top two rows of the bottom text: what the player needs to choose. With a die picked, its
; name and what it does (with its number after boosts) and how to play it; else the target's
; name, hit points, statuses and next move in words, and the bag; on the enemies' turn the
; hero's own. The log (battle/log.tsp) has the two rows under it. Drawn again only when
; something it shows may have changed.

(import state)
(import draw/text)
(import battle/log)
(import battle/bag)
(import content/action ac)
(import content/faces)
(import content/effects fx)
(import content/statuses st)

(const PROMPT_COL u8 16) ; after the longest face name
(const BAG_COL u8 23)    ; after "Next: " and the longest move
(const WOODS_QUIET (ptr u8) "The woods go quiet.")

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
    (text.add " hp")
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

; the face die d shows, and how to play it
(fn die_rows ((d u8)) void
    (let row u8 (at state.hand d))
    (let face ac.Action (at faces.FACES row))
    (text.start)
    (set text.inverse true)
    (text.add face.name)
    (set text.inverse false)
    (text.tab PROMPT_COL)
    (if (not (fx.can_play row))
        (text.add_n "Needs # mana" face.cost)
        (if (= face.aim state.Aim.foe)
            (text.add "Pick an enemy")
            (text.add (if (= face.aim state.Aim.all)
                "Again: hits all"
                "Again: on you"))))
    (text.show 0)
    (text.start)
    (let n u8 face.amount)
    (if (and (!= face.effect ac.Effect.plus) (!= face.effect ac.Effect.double))
        (set n (fx.boosted n)))
    (text.add_n face.text n)
    (text.show 1))

; the target's next move, and the bag: its dice, and how many are left to draw
(fn intent_row ((who u8)) void
    (text.start)
    (if (at state.actors who alive)
        (do
            (let row u8 (at state.actors who move))
            (text.add "Next: ")
            (text.add_n (fx.intent_text who row) (fx.intent_amount who row))))
    (text.tab BAG_COL)
    (text.add_n "Bag #" state.bag)
    (text.add_n " draw #" (bag.draw_count))
    (text.show 1))

(fn line_row ((r u8) (s (ptr u8))) void
    (text.start)
    (text.add s)
    (text.show r))

; on the enemies' turn: the hero's own state
(fn their_turn () void
    (actor_row state.HERO)
    (line_row 1 "Their turn"))

(fn refresh () void
    (if (and (and (not state.hud_words) (= shown_phase state.phase))
            (and (= state.hud_pills 0) (= state.hud_intents 0)))
        (return))
    (set state.hud_words false)
    (set shown_phase state.phase)
    (match state.phase
        (state.Phase.enemies (their_turn))
        (state.Phase.rolling
            (actor_row state.HERO)
            (line_row 1 "Rolling"))
        (state.Phase.won
            (line_row 0 WOODS_QUIET)
            (line_row 1 ""))
        (state.Phase.lost
            (actor_row state.HERO)
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
        (do
            (text.add WOODS_QUIET)
            (text.show 0)
            (line_row 1 "To be continued..."))
        (do
            (text.add (log.name state.HERO))
            (text.add " is down. The run is over.")
            (text.show 0)
            (line_row 1 "")))
    (line_row 2 "")
    (line_row 3 "Press RETURN or tap."))
