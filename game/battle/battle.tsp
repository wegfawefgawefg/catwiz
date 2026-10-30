; a battle in the forest: setting it up from the encounter, one step a frame, and drawing it

(import apple2 a2)
(import random)
(import state)
(import art/sprites art)
(import art/backdrop bd)
(import content/enemies en)
(import content/encounters enc)
(import draw/screen)
(import draw/scene)
(import draw/pen)
(import draw/blit)
(import battle/place)
(import battle/look)
(import battle/hud)
(import battle/act)
(import battle/turn)
(import sound/sfx)

(const BANNER_AFTER u8 56) ; frames from the last blow to the banner: the poof has finished

(fn enter () void
    (screen.load_page screen.BACKDROP (addr_of (at bd.backdrop 0)))
    (set state.screen state.Screen.battle)
    (set state.turn 0)
    (set state.hitstop 0)
    (set state.bolt_on false)
    (set state.target 1)
    (for i u8 0 state.FLOATERS
        (set (at state.floaters i time) 0))
    (for i u8 0 (* state.ACTORS state.STATUS_SLOTS)
        (set (at state.stacks i) 0))
    (set_dog)
    (for i u8 1 state.ACTORS
        (set_enemy i)
        (set (at state.actors i mood) (look.resting_mood i)))
    (draw_shadows)
    (hud.forget)
    (pen.glyph 236 164 82) ; R, by the re-roll die
    (set state.hud_pills 0x0F)
    (set state.hud_intents 0x0E)
    (set state.hud_dice 0x1F)
    (set state.hud_rerolls true)
    (set state.hud_top 255)
    (scene.mark_all)
    (turn.start_round))

(fn set_dog () void
    (let hp u8 enc.hero.hp)
    (set (at state.actors state.DOG)
        (make state.Actor
            :alive true
            :kind state.NOTHING
            :figure enc.hero.figure
            :hp hp
            :max_hp hp
            :col enc.hero.col
            :home enc.hero.col
            :lift 0
            :move 0
            :moves_made 0
            :mood state.Mood.idle
            :mood_time 0
            :flash 0
            :knock 0
            :dying 0)))

; actor i is spot i - 1 of the forest, or nobody past its end
(fn set_enemy ((i u8)) void
    (if (> i enc.FOREST_SIZE)
        (do
            (set (at state.actors i alive) false)
            (set (at state.actors i kind) state.NOTHING)
            (set (at state.actors i dying) 0)
            (return)))
    (let spot enc.Spot (at enc.forest (- i 1)))
    (let kind en.Enemy (at en.enemies spot.enemy))
    (let made u8 (random.below kind.move_count))
    (set (at state.actors i)
        (make state.Actor
            :alive true
            :kind spot.enemy
            :figure kind.figure
            :hp kind.hp
            :max_hp kind.hp
            :col spot.col
            :home spot.col
            :lift 0
            :move (+ kind.first_move made)
            :moves_made made
            :mood state.Mood.angry
            :mood_time 0
            :flash 0
            :knock 0
            :dying 0)))

; shadows on the ground under everyone, part of the backdrop
(fn draw_shadows () void
    (for i u8 0 state.ACTORS
        (if (or (= i state.DOG) (!= (at state.actors i kind) state.NOTHING))
            (do
                (let a u8 (at state.actors i figure))
                (let col u8 (as u8 (+ (as i8 (at state.actors i home)) (at art.KIND_SHADOW_DX a))))
                (let top u8 (as u8 (+ (as i8 place.GROUND) (at art.KIND_SHADOW_DY a))))
                (blit.sprite screen.BACKDROP col top (at art.KIND_SHADOW a))))))

; whether this frame takes a key: in the dog's turn and at the end
(fn wants_key () bool
    (if (> state.hitstop 0)
        (return false))
    (match state.phase
        (state.Phase.player true)
        (state.Phase.won true)
        (state.Phase.lost true)
        (_ false)))

; one frame of the battle; gives the screen to show next
(fn step ((key u8)) state.Screen
    (look.tick)
    (if (> state.hitstop 0)
        (return state.Screen.battle))
    (match state.phase
        (state.Phase.rolling (turn.roll_step))
        (state.Phase.player (turn.player_key key))
        (state.Phase.acting
            (if (act.step)
                (turn.after_action)))
        (state.Phase.enemies (turn.enemies_step))
        (state.Phase.won (return (ending key true)))
        (state.Phase.lost (return (ending key false))))
    state.Screen.battle)

; after the last blow: the banner, then RETURN goes back to the title
(fn ending ((key u8) (won bool)) state.Screen
    (if (< state.timer 255)
        (set state.timer (+ state.timer 1)))
    (if (= state.timer BANNER_AFTER)
        (do
            (if won
                (hud.banner "THE WOODS GO QUIET" "PRESS RETURN")
                (hud.banner "WITCHDOG IS BONKED" "PRESS RETURN"))
            (if won
                (sfx.win)
                (sfx.lose))))
    (if (and (> state.timer BANNER_AFTER) (= key a2.KEY_RETURN))
        (return state.Screen.title))
    state.Screen.battle)

(fn draw () void
    (hud.refresh)
    (look.update)
    (scene.draw_frame)
    (screen.flip))
