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

; the rows' words, in aux memory (text.add_aux): SAY_ and their words
(const SAY (array (ptr u8) 15)
    (make (array (ptr u8) 15)
        "The woods go quiet."
        " hp"
        "# damage"
        "Shield #"
        "Re-roll it"
        "Too little mana: +1"
        "Pick an enemy"
        "Again: hits all"
        "Again: on you"
        "Next: "
        "Their turn"
        "Rolling"
        "To be continued..."
        " is down. The run is over."
        "Press RETURN or tap.")
    :strings aux)

(const SAY_QUIET u8 0)
(const SAY_HP u8 1)
(const SAY_DAMAGE u8 2)
(const SAY_SHIELD u8 3)
(const SAY_REROLL u8 4)
(const SAY_STUDY u8 5)
(const SAY_PICK_ENEMY u8 6)
(const SAY_HITS_ALL u8 7)
(const SAY_ON_YOU u8 8)
(const SAY_NEXT u8 9)
(const SAY_THEIR_TURN u8 10)
(const SAY_ROLLING u8 11)
(const SAY_CONTINUED u8 12)
(const SAY_DOWN u8 13)
(const SAY_PRESS u8 14)

; what the rows were drawn for, so a change of phase draws them again
(let shown_phase state.Phase state.Phase.won)

; who's name, hit points and statuses on one row
(fn actor_row ((who u8)) void
    (text.start)
    (text.add_aux (log.name who))
    (text.char ' ')
    (text.number (at state.actors who hp))
    (text.char '/')
    (text.number (at state.actors who max_hp))
    (text.add_aux (at SAY SAY_HP))
    (for s u8 0 st.STATUS_COUNT
        (let n u8 (state.stack who s))
        (let show st.Show (at st.SHOW s))
        (if (and (> n 0) (!= show st.Show.hidden))
            (do
                (text.char ' ')
                (text.add_aux (at st.NAME s))
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
    (text.add_aux (at items.ITEMS row name))
    (set text.inverse false)
    (text.tab PROMPT_COL)
    (match (at items.ITEMS row slot)
        (ac.Slot.wand (text.add_aux_n (at SAY SAY_DAMAGE) n))
        (ac.Slot.fluff (text.add_aux_n (at SAY SAY_SHIELD) n))
        (ac.Slot.junk (text.add_aux (at SAY SAY_REROLL)))
        (_
            (if (and (= (at items.ITEMS row slot) ac.Slot.book)
                    (< (fx.mana) (at items.ITEMS row cost)))
                (text.add_aux (at SAY SAY_STUDY))
                (match (at items.ITEMS row aim)
                    (state.Aim.foe (text.add_aux (at SAY SAY_PICK_ENEMY)))
                    (state.Aim.all (text.add_aux (at SAY SAY_HITS_ALL)))
                    (_ (text.add_aux (at SAY SAY_ON_YOU)))))))
    (text.show 0)
    (text.start)
    (text.add_aux_n (at items.ITEMS row text) n)
    (text.show 1))

; the target's next move
(fn intent_row ((who u8)) void
    (text.start)
    (if (at state.actors who alive)
        (do
            (let row u8 (at state.actors who move))
            (text.add_aux (at SAY SAY_NEXT))
            (text.add_aux_n (foes.intent_text who row) (foes.intent_amount who row))))
    (text.show 1))

; row r: s, one of SAY's
(fn line_row ((r u8) (s (ptr u8))) void
    (text.start)
    (text.add_aux s)
    (text.show r))

(fn blank_row ((r u8)) void
    (text.start)
    (text.show r))

; on the enemies' turn: the hero's own state
(fn their_turn () void
    (actor_row state.HERO)
    (line_row 1 (at SAY SAY_THEIR_TURN)))

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
            (line_row 1 (at SAY SAY_ROLLING)))
        (state.Phase.won
            (line_row 0 (at SAY SAY_QUIET))
            (blank_row 1))
        (state.Phase.lost
            (actor_row state.HERO)
            (blank_row 1))
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
            (text.add_aux (at SAY SAY_QUIET))
            (text.show 0)
            (line_row 1 (at SAY SAY_CONTINUED)))
        (do
            (text.add_aux (log.name state.HERO))
            (text.add_aux (at SAY SAY_DOWN))
            (text.show 0)
            (blank_row 1)))
    (blank_row 2)
    (line_row 3 (at SAY SAY_PRESS)))
