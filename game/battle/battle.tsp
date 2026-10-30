; the run's battles in the forest: a run starts the hero's bag of dice and hit points, each
; fight is set up from its encounter, steps one frame at a time and is drawn; after a won fight
; the reward (battle/reward.tsp), then the next fight; after the last, "to be continued".

(import apple2 a2)
(import state)
(import art/sprites art)
(import content/enemies en)
(import content/encounters enc)
(import content/statuses st)
(import draw/screen)
(import draw/scene)
(import draw/blit)
(import draw/stage)
(import draw/text)
(import battle/place)
(import battle/look)
(import battle/hud)
(import battle/act)
(import battle/bag)
(import battle/turn)
(import battle/words)
(import battle/log)
(import battle/reward)
(import sound/sound)

(const BANNER_AFTER u8 56) ; frames from the last blow to the end: the poof has finished

; a new run: the starting dice, full hit points, the first fight
(fn enter () void
    (bag.fill)
    (set state.hero_hp enc.HERO.hp)
    (set state.fight 0)
    (set state.screen state.Screen.battle)
    (enter_fight))

; the fight's art: its backdrop onto the backdrop page, the hero's, the small sprites' and its
; enemies' runs unpacked (draw/blit). The music stops first: the card's half unpacks with
; interrupts off
(fn load_art () void
    (sound.quiet)
    (screen.wait_frame)
    (screen.wait_frame)
    (let fight enc.Fight (at enc.FIGHTS state.fight))
    (stage.backdrop fight.backdrop)
    (blit.start)
    (blit.want art.KIND_CAT)
    (blit.want art.KIND_MISC)
    (for i u8 0 fight.count
        (let spot enc.Spot (at fight.spots i))
        (let kind u8 (at en.ENEMIES spot.enemy figure))
        (let seen bool false)
        (for j u8 0 i
            (let other enc.Spot (at fight.spots j))
            (if (= (at en.ENEMIES other.enemy figure) kind)
                (set seen true)))
        (if (not seen)
            (blit.want kind)))
    (blit.unpack_all)
    (text.forget)
    (hud.forget)
    (scene.mark_all))

(fn enter_fight () void
    (load_art)
    (set state.turn 0)
    (set state.hitstop 0)
    (set state.bolt_on false)
    (set state.target 1)
    (set state.selected state.NOTHING)
    (set state.log_hold 0)
    (bag.gather)
    (for i u8 0 state.FLOATERS
        (set (at state.floaters i time) 0))
    (set_hero)
    (st.start state.HERO state.NOTHING)
    (for i u8 1 state.ACTORS
        (set_enemy i)
        (if (!= (at state.actors i kind) state.NOTHING)
            (st.start i (at state.actors i kind)))
        (set (at state.actors i mood) (look.resting_mood i)))
    (text.clear)
    (log.clear)
    (set state.hud_pills 0x0F)
    (set state.hud_intents 0x0E)
    (set state.hud_dice 0x1F)
    (set state.hud_rerolls true)
    (set state.hud_words true)
    (scene.mark_all)
    (sound.song sound.Song.battle)
    (turn.start_round))

(fn set_hero () void
    (set (at state.actors state.HERO)
        (make state.Actor
            :alive true
            :kind state.NOTHING
            :figure enc.HERO.figure
            :hp state.hero_hp
            :max_hp enc.HERO.hp
            :col enc.HERO.col
            :home enc.HERO.col
            :lift 0
            :move 0
            :moves_made 0
            :mood state.Mood.idle
            :mood_time 0
            :flash 0
            :knock 0
            :dying 0)))

; actor i is spot i - 1 of this fight, or nobody past its end. Enemies start on their first move
(fn set_enemy ((i u8)) void
    (let fight enc.Fight (at enc.FIGHTS state.fight))
    (if (> i fight.count)
        (do
            (set (at state.actors i alive) false)
            (set (at state.actors i kind) state.NOTHING)
            (set (at state.actors i dying) 0)
            (return)))
    (let spot enc.Spot (at fight.spots (- i 1)))
    (let kind en.Enemy (at en.ENEMIES spot.enemy))
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
            :move kind.first_move
            :moves_made 0
            :mood state.Mood.angry
            :mood_time 0
            :flash 0
            :knock 0
            :dying 0)))

; whether this frame takes a key: in the hero's turn, the reward and at the end
(fn wants_key () bool
    (if (> state.hitstop 0)
        (return false))
    (match state.phase
        (state.Phase.player true)
        (state.Phase.won true)
        (state.Phase.lost true)
        (state.Phase.reward true)
        (_ false)))

; one frame of the battle; gives the screen to show next
(fn step ((key u8)) state.Screen
    (look.tick)
    (if (> state.log_hold 0)
        (set state.log_hold (- state.log_hold 1)))
    (if (> state.hitstop 0)
        (return state.Screen.battle))
    (match state.phase
        (state.Phase.rolling (turn.roll_step))
        (state.Phase.player (turn.player_key key))
        (state.Phase.acting
            (if (act.step)
                (turn.after_action)))
        (state.Phase.enemies (turn.enemies_step))
        (state.Phase.reward
            (if (reward.step key)
                (do
                    (set state.fight (+ state.fight 1))
                    (enter_fight))))
        (state.Phase.won (return (ending key true)))
        (state.Phase.lost (return (ending key false))))
    state.Screen.battle)

; whether the fight just won was the run's last
(fn last_fight () bool
    (>= (+ state.fight 1) enc.FIGHT_COUNT))

; after the last blow: once the beaten have puffed away, the reward, or the end of the run
; (to be continued, or lost), where any key (RETURN, a tap) goes back to the title
(fn ending ((key u8) (won bool)) state.Screen
    (if (< state.timer 255)
        (set state.timer (+ state.timer 1)))
    (if (= state.timer BANNER_AFTER)
        (do
            (if (and won (not (last_fight)))
                (do
                    (set state.hero_hp (at state.actors state.HERO hp))
                    (reward.start)
                    (return state.Screen.battle)))
            (words.ending won)
            (sound.song (if won
                sound.Song.won
                sound.Song.lost))))
    (if (and (> state.timer BANNER_AFTER) (!= key 0))
        (return state.Screen.title))
    state.Screen.battle)

(fn draw () void
    (words.refresh)
    (hud.refresh)
    (look.update (turn.picked_aim))
    (if (scene.draw_frame)
        (screen.flip)
        (screen.wait_frame)))
