; the turns of a battle. The hero's turn: her five dice (battle/dice.tsp) roll; she
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
(import content/charms)
(import content/items)
(import content/effects fx)
(import content/foes)
(import content/moves mv)
(import content/statuses st)
(import battle/act)
(import battle/dice)
(import battle/hit)
(import battle/log)
(import battle/look)
(import battle/words)
(import sound/sound)

; the log's sentences, in aux memory (battle/log reads them there): SAY_ and their words
(const SAY (array (ptr u8) 8)
    (make (array (ptr u8) 8)
        "Pick a die 1-5, then an enemy ZXC."
        "E ends the turn. B: kit. ?: rules."
        "Your turn: pick a die (1-5)."
        "R re-roll or E end turn."
        "No playable dice."
        ": meow!"
        "A hairball: re-roll it to cough it up."
        "Stars fill your mana; spells spend.")
    :strings aux)

(const SAY_PICK_DIE_1 u8 0)
(const SAY_E_ENDS_TURN u8 1)
(const SAY_TURN_PICK_DIE u8 2)
(const SAY_R_RE_ROLL u8 3)
(const SAY_NO_PLAYABLE_DICE u8 4)
(const SAY_MEOW u8 5)
(const SAY_HAIRBALL_RE_ROLL u8 6)
(const SAY_STARS_FILL_MANA u8 7)

(const HURT_LEFT u8 8)  ; frames of a held hurt face left once the enemies' turn ends
(const DEAL_EVERY u8 4) ; frames from one die landing to the next: a power of 2
(const DEAL_SHIFT u8 2)
(const ENEMY_PAUSE u8 10)
(const KEY_1 u8 '1')
(const END_BEAT u8 20) ; frames from the last play to a turn that ends by itself

(fn any_enemy_alive () bool
    (for i u8 1 state.ACTORS
        (if (at state.actors i alive)
            (return true)))
    false)

; the hero's turn begins: her shield from last turn is gone (content/charms says what stays),
; no face of any slot played yet, the dice come back and roll
(fn start_round () void
    (set state.turn (+ state.turn 1))
    (set state.rerolls (charms.round_start))
    (set state.rerolled false)
    (set state.last_played state.NOTHING)
    (for k u8 0 state.SLOTS
        (set (at state.combo k) 0))
    (set state.hud_rerolls true)
    (set state.selected state.NOTHING)
    (sound.cue sound.Cue.turn_on)
    (if (log.once log.HINT_TURN)
        (do
            (log.line (at SAY SAY_PICK_DIE_1) 0)
            (log.line (at SAY SAY_E_ENDS_TURN) 0))
        (log.line (at SAY SAY_TURN_PICK_DIE) 0))
    (dice.deal)
    (start_roll))

(fn start_roll () void
    (set state.phase state.Phase.rolling)
    (set state.timer 0))

; the unplayed dice land one at a time, left to right, each with a rattle, then her turn goes
; on: a slot is drawn once (a few frames for its card), not every slot at every tumble
(fn roll_step () void
    (let t u8 state.timer)
    (set state.timer (+ t 1))
    (if (= (& t (- DEAL_EVERY 1)) 0)
        (do
            (let d u8 (>> t DEAL_SHIFT))
            (if (and (< d state.DICE_MOST) (not (at state.played d)))
                (do
                    (dice.roll d)
                    (set state.hud_dice (| state.hud_dice (<< 1 d)))
                    (sound.cue sound.Cue.rattle)))))
    (if (< t (<< state.DICE_MOST DEAL_SHIFT))
        (return))
    (start_player))

; the hero's turn goes on; with nothing left to play it ends by itself after a beat, unless
; a re-roll might help
(fn start_player () void
    (set state.phase state.Phase.player)
    (if (not (at state.actors state.target alive))
        (next_target 1))
    (let left bool false)
    (for d u8 0 state.DICE_MOST
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
            (log.line (at SAY SAY_R_RE_ROLL) 0)
            (return)))
    (log.line (at SAY SAY_NO_PLAYABLE_DICE) 0)
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
    (at items.ITEMS (at state.hand state.selected) aim))

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
    (log.who state.HERO (at SAY SAY_MEOW) 0)
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
    (if (and (>= key KEY_1) (< key (+ KEY_1 state.DICE_MOST)))
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
                ('.' (deselect)) ; a tap on the stage where nobody stands
                (_ (sound.cue sound.Cue.nope))))))

; die d of the tray to draw again (none for NOTHING)
(fn mark_slot ((d u8)) void
    (if (< d state.DICE_MOST)
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
    (if (not (fx.can_play row))
        (do
            (sound.cue sound.Cue.nope)
            (log.line (at SAY SAY_HAIRBALL_RE_ROLL) 0)
            (return)))
    (sound.cue sound.Cue.tok)
    (deselect)
    (set (at state.played d) true)
    (set state.last_played d)
    (mark_slot d)
    (let target u8 (if (= (at items.ITEMS row aim) state.Aim.self)
        state.HERO
        state.target))
    ; no log line for her own die: the rows above still show it (battle/words), and each line
    ; is two rows drawn again
    (act.begin state.Source.face row state.HERO target))

(fn reroll () void
    (if (= state.rerolls 0)
        (do
            (sound.cue sound.Cue.nope)
            (return)))
    (let any bool false)
    (for d u8 0 state.DICE_MOST
        (if (not (at state.played d))
            (set any true)))
    (if (not any)
        (do
            (sound.cue sound.Cue.nope)
            (return)))
    (deselect)
    (set state.rerolls (- state.rerolls 1))
    (set state.hud_rerolls true)
    (dice.cough)
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
            (log.line (at SAY SAY_STARS_FILL_MANA) 0)))
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

; her turn ends: her kittens pounce (content/effects), her statuses tick, a spook wears off;
; then the enemies' turn begins: their shields from last turn go
(fn end_turn () void
    (set state.end_wait 0)
    (deselect)
    (sound.cue sound.Cue.turn_off)
    (fx.turn_end)
    (if (not (any_enemy_alive))
        (do
            (end_battle state.Phase.won)
            (return)))
    (turn_end state.HERO)
    (state.set_stack state.HERO (as u8 st.Status.spook) 0)
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
    (if (foes.skips i)
        (do
            (log.uses i (foes.intent_text i (at state.actors i move)) 0)
            (return)))
    (let row u8 (at state.actors i move))
    (sound.cue sound.Cue.growl)
    (log.uses i (mv.text row) (foes.intent_amount i row))
    (act.begin state.Source.move row i (foes.move_target i row true)))

; the enemies' statuses tick and each takes up its next move; then the hero's turn (and her
; face again, if a hit held it hurt)
(fn end_enemies () void
    (if (> (at state.actors state.HERO mood_time) HURT_LEFT)
        (set (at state.actors state.HERO mood_time) HURT_LEFT))
    (for i u8 1 state.ACTORS
        (if (at state.actors i alive)
            (turn_end i))
        ; still standing: this turn's hurt is forgotten, and it takes up its next move (one
        ; that came in or got up keeps its first)
        (if (at state.actors i alive)
            (do
                (state.set_stack i (as u8 st.Status.hurt) 0)
                (if (st.skips i)
                    (state.set_stack i (as u8 st.Status.fresh) 0)
                    (foes.next_move i))
                ; its face follows its new intent, unless it is still showing a hurt
                (if (= (at state.actors i mood_time) 0)
                    (set (at state.actors i mood) (look.resting_mood i))))))
    (set state.hud_intents 0x0E)
    (if (not (any_enemy_alive))
        (do
            (end_battle state.Phase.won)
            (return)))
    (start_round))
