; the turns of a battle. The dog's turn: the dice roll, then she plays them one at a time on
; the target, re-rolls the rest up to twice, barks once, and ends her turn. Then each enemy
; makes the move it showed, statuses tick, the enemies pick their next moves, and the dog's
; turn comes round again.

(import apple2 a2)
(import random)
(import state)
(import content/effects fx)
(import content/dice)
(import content/enemies en)
(import content/statuses st)
(import battle/act)
(import battle/hit)
(import battle/look)
(import sound/sfx)

(const ROLL_FRAMES u8 16)
(const ROLL_EVERY u8 3)
(const ENEMY_PAUSE u8 14)
(const KEY_1 u8 0x31)

(fn any_enemy_alive () bool
    (for i u8 1 state.ACTORS
        (if (at state.actors i alive)
            (return true)))
    false)

; the dog's turn begins: her shield from last turn is gone, the dice come back and roll
(fn start_round () void
    (set state.turn (+ state.turn 1))
    (st.turn_start state.DOG)
    (set state.rerolls 2)
    (set state.hud_rerolls true)
    (set state.barked false)
    (for d u8 0 state.HAND
        (set (at state.played d) false))
    (start_roll))

(fn start_roll () void
    (set state.phase state.Phase.rolling)
    (set state.timer 0))

; the unplayed dice tumble a few times, then show their faces
(fn roll_step () void
    (let t u8 state.timer)
    (set state.timer (+ t 1))
    (if (and (< t ROLL_FRAMES) (= (% t ROLL_EVERY) 0))
        (do
            (for d u8 0 state.HAND
                (if (not (at state.played d))
                    (do
                        (set (at state.hand d)
                            (+ (* d dice.FACES_PER_DIE) (random.below dice.FACES_PER_DIE)))
                        (set state.hud_dice (| state.hud_dice (<< 1 d))))))
            (sfx.rattle)))
    (if (>= t ROLL_FRAMES)
        (start_player)))

(fn start_player () void
    (set state.phase state.Phase.player)
    (if (not (at state.actors state.target alive))
        (next_target 1)))

; the next living enemy one way or the other from the target (step 1 or 255)
(fn next_target ((step u8)) void
    (let t u8 state.target)
    (for n u8 0 3
        (set t (+ t step))
        (if (= t 0)
            (set t (- state.ACTORS 1)))
        (if (= t state.ACTORS)
            (set t 1))
        (if (at state.actors t alive)
            (do
                (set state.target t)
                (return)))))

(fn player_key ((key u8)) void
    (if (and (>= key KEY_1) (< key (+ KEY_1 state.HAND)))
        (do
            (play_die (- key KEY_1))
            (return)))
    (match (& key 0xDF)   ; letters either case
        (0x52 (reroll))   ; R
        (0x42 (bark))     ; B
        (0x45 (end_turn)) ; E
        (_))
    (match key
        (a2.KEY_LEFT (next_target 255))
        (a2.KEY_RIGHT (next_target 1))
        (a2.KEY_RETURN (end_turn))
        (_)))

(fn play_die ((d u8)) void
    (if (at state.played d)
        (return))
    (let face u8 (at state.hand d))
    (set (at state.played d) true)
    (set state.hud_dice (| state.hud_dice (<< 1 d)))
    (let target u8 (if (= (at dice.faces face aim) state.Aim.foe)
        state.target
        state.DOG))
    (act.begin state.Source.face face state.DOG target))

(fn bark () void
    (if state.barked
        (return))
    (set state.barked true)
    (sfx.bark)
    (act.begin state.Source.bark 0 state.DOG state.target))

(fn reroll () void
    (if (= state.rerolls 0)
        (return))
    (let any bool false)
    (for d u8 0 state.HAND
        (if (not (at state.played d))
            (set any true)))
    (if (not any)
        (return))
    (set state.rerolls (- state.rerolls 1))
    (set state.hud_rerolls true)
    (start_roll))

; after an action is over: the battle may be over, else back to whose turn it is
(fn after_action () void
    (if (not (at state.actors state.DOG alive))
        (do
            (end_battle state.Phase.lost)
            (return)))
    (if (not (any_enemy_alive))
        (do
            (end_battle state.Phase.won)
            (return)))
    (if (= state.act_source state.Source.move)
        (do
            (set state.phase state.Phase.enemies)
            (set state.timer 0)
            (return)))
    (start_player))

(fn end_battle ((how state.Phase)) void
    (set state.phase how)
    (set state.timer 0)
    (look.show_mood state.DOG
        (if (= how state.Phase.won)
            state.Mood.happy
            state.Mood.ko)
        1))

; the dog's statuses tick, then the enemies' turn begins: their shields from last turn go
(fn end_turn () void
    (let burn u8 (st.turn_end state.DOG))
    (if (> burn 0)
        (hit.lose state.DOG burn))
    (if (not (at state.actors state.DOG alive))
        (do
            (end_battle state.Phase.lost)
            (return)))
    (for i u8 1 state.ACTORS
        (if (at state.actors i alive)
            (st.turn_start i)))
    (set state.next_enemy 1)
    (set state.phase state.Phase.enemies)
    (set state.timer 0))

; the next enemy makes its move, a short pause after the one before
(fn enemies_step () void
    (set state.timer (+ state.timer 1))
    (if (< state.timer ENEMY_PAUSE)
        (return))
    (let i u8 state.next_enemy)
    (while (and (< i state.ACTORS) (not (at state.actors i alive)))
        (set i (+ i 1)))
    (if (= i state.ACTORS)
        (do
            (end_enemies)
            (return)))
    (set state.next_enemy (+ i 1))
    (let move u8 (at state.actors i move))
    (let target u8 (if (= (at en.moves move aim) state.Aim.foe)
        state.DOG
        i))
    (act.begin state.Source.move move i target))

; the enemies' statuses tick and each picks its next move; then the dog's turn
(fn end_enemies () void
    (for i u8 1 state.ACTORS
        (if (at state.actors i alive)
            (do
                (let burn u8 (st.turn_end i))
                (if (> burn 0)
                    (hit.lose i burn))
                (next_move i))))
    (set state.hud_intents 0x0E)
    (if (not (any_enemy_alive))
        (do
            (end_battle state.Phase.won)
            (return)))
    (start_round))

(fn next_move ((i u8)) void
    (let kind u8 (at state.actors i kind))
    (let made u8 (+ (at state.actors i moves_made) 1))
    (set (at state.actors i moves_made) made)
    (set (at state.actors i move)
        (+ (at en.enemies kind first_move) (% made (at en.enemies kind move_count)))))
