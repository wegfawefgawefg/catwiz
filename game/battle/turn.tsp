; the turns of a battle. The hero's turn: five dice from her bag (battle/bag.tsp) roll; she
; picks one (its text shows at the bottom) and plays it: on an enemy picked next (Z X C, or the
; arrows and RETURN), or with the same key again (or M, the cat) on herself, or on every enemy
; for a hit-all. The same key again on a die for one enemy lets it go, as ESC does. She
; re-rolls the unplayed dice up to twice and ends her turn (E); M with no die for her meows, for
; fun. With every die played, or none playable and no re-roll left, the turn ends by itself
; after a beat. Then each enemy makes the move it showed, statuses tick, the enemies take up
; their next moves, and her turn comes round again. Taps on the screen send the same keys
; (tools/phone/catwiz.json).

(import apple2 a2)
(import random)
(import state)
(import content/action ac)
(import content/faces)
(import content/effects fx)
(import content/enemies en)
(import content/statuses st)
(import battle/act)
(import battle/bag)
(import battle/hit)
(import battle/log)
(import battle/look)
(import battle/words)
(import sound/sound)

(const ROLL_FRAMES u8 16)
(const ROLL_EVERY u8 4) ; a power of 2: (& t 3) is the test
(const ENEMY_PAUSE u8 14)
(const KEY_1 u8 '1')
(const END_BEAT u8 30) ; frames from the last play to a turn that ends by itself

(fn any_enemy_alive () bool
    (for i u8 1 state.ACTORS
        (if (at state.actors i alive)
            (return true)))
    false)

; the hero's turn begins: her shield from last turn is gone, the dice come back and roll
(fn start_round () void
    (set state.turn (+ state.turn 1))
    (st.turn_start state.HERO)
    (set state.rerolls 2)
    (set state.hud_rerolls true)
    (set state.selected state.NOTHING)
    (sound.cue sound.Cue.turn_on)
    (if (log.once log.HINT_TURN)
        (do
            (log.line "PICK A DIE (1-5), THEN AN ENEMY (Z X C)." 0)
            (log.line "DONE? E (OR TAP END) ENDS YOUR TURN." 0))
        (log.line "YOUR TURN: PICK A DIE (1-5)." 0))
    (bag.deal)
    (start_roll))

; 0 to 5, from a random byte times 6 over 256: no division routine
(fn random_face () u8
    (as u8 (>> (* (as u16 (random.byte)) (as u16 state.DIE_FACES)) 8)))

(fn start_roll () void
    (set state.phase state.Phase.rolling)
    (set state.timer 0))

; the unplayed dice tumble a few times, then show their faces
(fn roll_step () void
    (let t u8 state.timer)
    (set state.timer (+ t 1))
    (if (and (< t ROLL_FRAMES) (= (& t (- ROLL_EVERY 1)) 0))
        (do
            (for d u8 0 state.HAND
                (if (not (at state.played d))
                    (do
                        (let first u8 (* (at state.tray_die d) state.DIE_FACES))
                        (set (at state.hand d) (at state.dice (+ first (random_face))))
                        (set state.hud_dice (| state.hud_dice (<< 1 d))))))
            (sound.cue sound.Cue.rattle)))
    (if (< t ROLL_FRAMES)
        (return))
    (start_player))

; the hero's turn goes on; with nothing left to play it ends by itself after a beat, unless
; a re-roll might help
(fn start_player () void
    (set state.phase state.Phase.player)
    (if (not (at state.actors state.target alive))
        (next_target 1))
    (let left bool false)
    (for d u8 0 state.HAND
        (if (not (at state.played d))
            (do
                (if (fx.can_play (at state.hand d))
                    (return))
                (set left true))))
    (if (not left)
        (do
            (set state.end_wait END_BEAT)
            (return)))
    (if (> state.rerolls 0)
        (do
            (log.line "R RE-ROLL OR E END TURN." 0)
            (return)))
    (log.line "NO PLAYABLE DICE." 0)
    (set state.end_wait END_BEAT))

; the next living enemy one way or the other from the target (step 1 or 255)
(fn next_target ((step u8)) void
    (let t u8 state.target)
    (set state.hud_words true)
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

; what the die picked goes to; with none, the target is the enemy the text describes
(fn picked_aim () state.Aim
    (if (= state.selected state.NOTHING)
        (return state.Aim.foe))
    (at faces.FACES (at state.hand state.selected) aim))

; a target picked with the arrows: a blip when it moves. A die for the hero or for every enemy
; has no target to move
(fn pick_target ((step u8)) void
    (let was u8 state.target)
    (if (= (picked_aim) state.Aim.foe)
        (next_target step))
    (sound.cue (if (= state.target was)
        sound.Cue.nope
        sound.Cue.blip)))

; an enemy picked by name (Z, X, C: the enemies left to right, and taps on them): with a die
; for an enemy or every enemy picked, it plays there; with none it becomes the target. A die
; for the hero does not go to an enemy
(fn choose_target ((t u8)) void
    (if (or (not (and (< t state.ACTORS) (at state.actors t alive)))
            (= (picked_aim) state.Aim.self))
        (do
            (sound.cue sound.Cue.nope)
            (return)))
    (set state.target t)
    (set state.hud_words true)
    (if (= state.selected state.NOTHING)
        (do
            (sound.cue sound.Cue.blip)
            (return)))
    (play_selected))

; M (and taps on the cat): a die for the hero picked plays; else she meows and hops, just for
; fun: no effect on the fight, as often as you like
(fn meow () void
    (if (= (picked_aim) state.Aim.self)
        (do
            (play_selected)
            (return)))
    (sound.cue sound.Cue.meow)
    (log.who state.HERO ": MEOW!" 0)
    (act.begin state.Source.meow 0 state.HERO state.HERO))

(fn player_key ((key u8)) void
    ; the beat before a turn ends by itself; a key in it still counts
    (if (> state.end_wait 0)
        (do
            (set state.end_wait (- state.end_wait 1))
            (if (= state.end_wait 0)
                (do
                    (end_turn)
                    (return)))))
    (if (and (>= key KEY_1) (< key (+ KEY_1 state.HAND)))
        (do
            (select (- key KEY_1))
            (return)))
    (match (& key 0xDF) ; letters either case
        ('R' (reroll))
        ('E' (end_turn))
        ('M' (meow))
        ('Z' (choose_target 1))
        ('X' (choose_target 2))
        ('C' (choose_target 3))
        (_
            (match key
                (0 (return))
                (a2.KEY_LEFT (pick_target 255))
                (a2.KEY_RIGHT (pick_target 1))
                (a2.KEY_RETURN (play_selected))
                (a2.KEY_ESC (deselect))
                (_ (sound.cue sound.Cue.nope))))))

; die d of the tray to draw again (none for NOTHING)
(fn mark_slot ((d u8)) void
    (if (< d state.HAND)
        (set state.hud_dice (| state.hud_dice (<< 1 d)))))

; slot d picked: its text shows; picked again, it plays, or with a die for one enemy it is let
; go. An empty slot lets go of the picked die
(fn select ((d u8)) void
    (if (at state.played d)
        (do
            (deselect)
            (sound.cue sound.Cue.nope)
            (return)))
    (if (!= d state.selected)
        (do
            (mark_slot state.selected)
            (mark_slot d)
            (set state.selected d)
            (set state.hud_words true)
            (sound.cue sound.Cue.blip)
            (return)))
    (if (= (picked_aim) state.Aim.foe)
        (do
            (deselect)
            (return)))
    (play_selected))

(fn deselect () void
    (mark_slot state.selected)
    (set state.selected state.NOTHING)
    (set state.hud_words true))

; the picked face plays: on the target, or on the hero for her own faces
(fn play_selected () void
    (let d u8 state.selected)
    (if (= d state.NOTHING)
        (do
            (sound.cue sound.Cue.nope)
            (return)))
    (let row u8 (at state.hand d))
    (let face ac.Action (at faces.FACES row))
    (if (not (fx.can_play row))
        (do
            (sound.cue sound.Cue.nope)
            (return)))
    (sound.cue sound.Cue.tok)
    (deselect)
    (set (at state.played d) true)
    (mark_slot d)
    (let target u8 (if (= face.aim state.Aim.self)
        state.HERO
        state.target))
    (log.uses state.HERO face.name 0)
    (act.begin state.Source.face row state.HERO target))

(fn reroll () void
    (if (= state.rerolls 0)
        (do
            (sound.cue sound.Cue.nope)
            (return)))
    (let any bool false)
    (for d u8 0 state.HAND
        (if (not (at state.played d))
            (set any true)))
    (if (not any)
        (do
            (sound.cue sound.Cue.nope)
            (return)))
    (deselect)
    (set state.rerolls (- state.rerolls 1))
    (set state.hud_rerolls true)
    (start_roll))

; after an action is over: the battle may be over, else back to whose turn it is
(fn after_action () void
    (if (not (at state.actors state.HERO alive))
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
    (if (> (fx.mana) 0)
        (if (log.once log.HINT_MANA)
            (log.line "MANA FILLS THE STARS. SPELLS SPEND IT." 0)))
    (start_player))

(fn end_battle ((how state.Phase)) void
    (set state.phase how)
    (set state.timer 0)
    (look.show_mood state.HERO
        (if (= how state.Phase.won)
            state.Mood.happy
            state.Mood.ko)
        1))

; statuses that hurt at the end of who's turn
(fn turn_end ((who u8)) void
    (let hurt u8 (st.turn_end who))
    (if (> hurt 0)
        (hit.lose who hurt)))

; the hero's statuses tick, then the enemies' turn begins: their shields from last turn go
(fn end_turn () void
    (set state.end_wait 0)
    (deselect)
    (sound.cue sound.Cue.turn_off)
    (turn_end state.HERO)
    (if (not (at state.actors state.HERO alive))
        (do
            (end_battle state.Phase.lost)
            (return)))
    (for i u8 1 state.ACTORS
        (if (at state.actors i alive)
            (st.turn_start i)))
    (set state.next_enemy 1)
    (set state.phase state.Phase.enemies)
    (set state.timer 0))

; the next enemy makes its move, a short pause after the one before and once the log is read
(fn enemies_step () void
    (set state.timer (+ state.timer 1))
    (if (or (< state.timer ENEMY_PAUSE) (> state.log_hold 0))
        (return))
    (let i u8 state.next_enemy)
    (while (and (< i state.ACTORS) (not (at state.actors i alive)))
        (set i (+ i 1)))
    (if (= i state.ACTORS)
        (do
            (end_enemies)
            (return)))
    (set state.next_enemy (+ i 1))
    (set state.timer 0)
    (if (st.skips i)
        (return))
    (let row u8 (at state.actors i move))
    (sound.cue sound.Cue.growl)
    (log.uses i (at en.MOVES row text) (fx.intent_amount i row))
    (act.begin state.Source.move row i (fx.move_target i row)))

; the enemies' statuses tick and each takes up its next move; then the hero's turn
(fn end_enemies () void
    (for i u8 1 state.ACTORS
        (if (at state.actors i alive)
            (do
                (turn_end i)
                (next_move i)
                ; its face follows its new intent, unless it is still showing a hurt
                (if (= (at state.actors i mood_time) 0)
                    (set (at state.actors i mood) (look.resting_mood i))))))
    (set state.hud_intents 0x0E)
    (if (not (any_enemy_alive))
        (do
            (end_battle state.Phase.won)
            (return)))
    (start_round))

; the next of its moves, round and round (moves_made counts within the round)
(fn next_move ((i u8)) void
    (let kind u8 (at state.actors i kind))
    (let made u8 (+ (at state.actors i moves_made) 1))
    (if (>= made (at en.ENEMIES kind move_count))
        (set made 0))
    (set (at state.actors i moves_made) made)
    (set (at state.actors i move) (+ (at en.ENEMIES kind first_move) made)))
