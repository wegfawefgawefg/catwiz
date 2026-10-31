; the top two rows of the bottom text: what the player needs to choose. With a die picked, its
; item's name, its slot's base (a wand's damage, a fluff's shield) or how to play it, and its
; item line (with its number after boosts); else the target's name, hit points, statuses and
; next move in words; on the enemies' turn the hero's own. The log (battle/log.tsp) has the two rows under it. Drawn again only when
; something it shows may have changed.

(import state)
(import draw/text)
(import battle/log)
(import content/action ac)
(import content/items)
(import content/effects fx)
(import content/foes)
(import content/statuses st)

(const PROMPT_COL u8 16) ; after the longest item name
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

; the face die d shows: its item's name; a wand's damage or a fluff's shield (their items' lines
; say the rest), else how to play it; then its item line, its number after the boosts
(fn die_rows ((d u8)) void
    (let row u8 (at state.hand d))
    (let n u8 (fx.boosted row false))
    (text.start)
    (set text.inverse true)
    (text.add (at items.ITEMS row name))
    (set text.inverse false)
    (text.tab PROMPT_COL)
    (match (at items.ITEMS row slot)
        (ac.Slot.wand (text.add_n "# damage" n))
        (ac.Slot.fluff (text.add_n "Shield #" n))
        (ac.Slot.junk (text.add "Re-roll it"))
        (_
            (if (and (= (at items.ITEMS row slot) ac.Slot.book)
                    (< (fx.mana) (at items.ITEMS row cost)))
                (text.add "Too little mana: +1")
                (match (at items.ITEMS row aim)
                    (state.Aim.foe (text.add "Pick an enemy"))
                    (state.Aim.all (text.add "Again: hits all"))
                    (_ (text.add "Again: on you"))))))
    (text.show 0)
    (text.start)
    (text.add_n (at items.ITEMS row text) n)
    (text.show 1))

; the target's next move
(fn intent_row ((who u8)) void
    (text.start)
    (if (at state.actors who alive)
        (do
            (let row u8 (at state.actors who move))
            (text.add "Next: ")
            (text.add_n (foes.intent_text who row) (foes.intent_amount who row))))
    (text.show 1))

(fn line_row ((r u8) (s (ptr u8))) void
    (text.start)
    (text.add s)
    (text.show r))

; on the enemies' turn: the hero's own state
(fn their_turn () void
    (actor_row state.HERO)
    (line_row 1 "Their turn"))

; whether the rows are to be drawn again (refresh draws them)
(fn due () bool
    ; while her own action plays, the rows keep showing the die she played: drawn again once it
    ; is over (the phase changes)
    (if (and (= state.phase state.Phase.acting) (!= state.act_source state.Source.move))
        (return false))
    (or (or state.hud_words (!= shown_phase state.phase))
        (or (!= state.hud_pills 0) (!= state.hud_intents 0))))

(fn refresh () void
    (if (not (due))
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
