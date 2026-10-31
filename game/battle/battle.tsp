; the run's battles in the forest: a run starts the hero's kit (an item in each of her six
; slots, no levels, no charms) and hit points, each fight is set up from its encounter, steps one
; frame at a time and is drawn; after a won fight what comes between fights (battle/reward.tsp:
; a card, a charm, the nap, the doors), then the next fight; after the last, "to be continued".

(import apple2 a2)
(import dhgr)
(import state)
(import content/charms)
(import content/encounters enc)
(import content/items)
(import content/statuses st)
(import draw/screen)
(import draw/scene)
(import draw/stage)
(import draw/text)
(import battle/place)
(import battle/look)
(import battle/hud)
(import battle/act)
(import battle/dice)
(import battle/spawn)
(import battle/turn)
(import battle/words)
(import battle/log)
(import battle/reward)
(import battle/map)
(import battle/page)
(import random)
(import sound/sound)

(const BANNER_AFTER u8 56) ; frames from the last blow to the end: the poof has finished

; for test builds, flipped in a copy: the run starts at fight START_STAGE (0 the first; with
; START_FIGHT its row, for the other door) and goes on to STOP_STAGE before "to be continued"
; (fights 3-10 fight on fight 1-2's screens with stand-in figures); START_CHARM is held from
; the start (a row of enc.CHARMS); WIN_AT_ONCE wins every fight as it starts, to walk what
; comes between fights (the cards, charms, the rest, the doors); SEED, when not 0, seeds the
; run's random numbers (the dice and the draws between fights) the same every time, for testing
; the draws. The kit: items.STARTING_ITEMS
(const START_STAGE u8 0)
(const START_FIGHT u8 0)
(const STOP_STAGE u8 2)
(const START_CHARM u8 state.NOTHING)
(const WIN_AT_ONCE bool false)
(const SEED u16 0)

; a new run: the starting items, no levels or charms, full hit points, the first fight
(fn enter () void
    (if (!= SEED 0)
        (set random.seed SEED))
    (set state.page state.Page.none)
    (for k u8 0 state.SLOTS
        (set (at state.items k) (at items.STARTING_ITEMS k))
        (set (at state.levels k) 0))
    (for c u8 0 10
        (set (at state.charms c) 0))
    (let charm u8 START_CHARM)
    (if (< charm 10)
        (set (at state.charms charm) 1))
    (set state.hero_hp enc.HERO.hp)
    (set state.stage START_STAGE)
    (set state.fight START_FIGHT)
    (set state.screen state.Screen.battle)
    (enter_fight))

; the fight's art, from the disk (draw/stage): its screen's picture unpacked onto the spare page
; and shown there (so it never shows half unpacked) while the screen's runs (the hero's, the small
; sprites', the enemies' figures) are read through the page (draw/blit) and unpacked; then copied
; onto the page, shown again. The spare page keeps the picture all fight (battle/page puts the
; stage back from it). The music stops first: the card's half unpacks with interrupts off
(fn load_art () void
    (sound.quiet)
    (screen.wait_frame)
    (screen.wait_frame)
    (let n u8 (enc.backdrop state.fight))
    (stage.backdrop screen.SPARE n)
    (dhgr.show screen.SPARE)
    (stage.fight_runs n)
    (screen.copy_page screen.SPARE screen.PAGE)
    (dhgr.show screen.PAGE)
    (scene.forget)
    (text.forget)
    (hud.forget))

(fn enter_fight () void
    (load_art)
    (map.draw)
    (set state.turn 0)
    (set state.hitstop 0)
    (set state.bolt_on false)
    (set state.target 1)
    (set state.selected state.NOTHING)
    (set state.log_hold 0)
    (set state.last_face state.NOTHING)
    (set state.last_on state.HERO)
    (set state.dice_n (charms.dice))
    (dice.gather)
    (for i u8 0 state.FLOATERS
        (set (at state.floaters i time) 0))
    (set_hero)
    (st.start state.HERO state.NOTHING)
    (charms.fight_start)
    (let count u8 (enc.count state.fight))
    (for i u8 1 state.ACTORS
        (if (> i count)
            (spawn.nobody i)
            (spawn.enemy i (enc.spot_enemy state.fight (- i 1)) false))
        (set (at state.actors i mood) (look.resting_mood i)))
    (text.clear)
    (log.clear)
    (set state.hud_pills 0x0F)
    (set state.hud_intents 0x0E)
    (set state.hud_dice 0x3F)
    (set state.hud_rerolls true)
    (set state.hud_words true)
    (sound.song sound.Song.battle)
    (turn.start_round)
    (if WIN_AT_ONCE
        (do
            (for i u8 1 state.ACTORS
                (spawn.nobody i))
            (turn.end_battle state.Phase.won))))

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

; whether this frame takes a key: in the hero's turn, the reward and at the end; and in the
; enemies' turn, to drop it (step does nothing with it). In her own action and while the dice
; land, keys wait for the turn to go on
(fn wants_key () bool
    (if (> state.hitstop 0)
        (return false))
    (match state.phase
        (state.Phase.player true)
        (state.Phase.won true)
        (state.Phase.lost true)
        (state.Phase.reward true)
        (state.Phase.enemies true)
        (state.Phase.acting (= state.act_source state.Source.move))
        (_ false)))

; one frame of the battle; gives the screen to show next
(fn step ((key u8)) state.Screen
    ; a page over the stage: the fight waits under it
    (if (!= state.page state.Page.none)
        (do
            (page.step key)
            (return state.Screen.battle)))
    (look.tick)
    (if (> state.mana_shake 0)
        (do
            (set state.mana_shake (- state.mana_shake 1))
            (set state.hud_rerolls true)))
    (if (> state.log_hold 0)
        (set state.log_hold (- state.log_hold 1)))
    (if (> state.hitstop 0)
        (return state.Screen.battle))
    (match state.phase
        (state.Phase.rolling (turn.roll_step))
        (state.Phase.player
            (if (not (page.opens key))
                (turn.player_key key)))
        (state.Phase.acting
            (if (act.step)
                (turn.after_action)))
        (state.Phase.enemies (turn.enemies_step))
        (state.Phase.reward
            (if (reward.step key)
                (do
                    (set state.stage (+ state.stage 1))
                    (set state.fight state.next_fight)
                    (enter_fight))))
        (state.Phase.won (return (ending key true)))
        (state.Phase.lost (return (ending key false))))
    state.Screen.battle)

; whether the fight just won was the run's last (or the last with art, STOP_STAGE)
(fn last_fight () bool
    (let next u8 (+ state.stage 1))
    (or (>= next enc.FIGHT_COUNT) (>= next STOP_STAGE)))

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

; whether drawing now would change the picture: the hud has something to draw, the phase
; changed, or a look is not what the screen shows. The main loop runs the frames a long drawing
; took up to the first one that does, so every change is shown
(let drawn_phase state.Phase state.Phase.won)

(fn will_change () bool
    (if (!= state.page state.Page.none)
        (return false))
    (if (or (or (!= state.hud_pills 0) (!= state.hud_intents 0))
            (or (!= state.hud_dice 0) (or state.hud_rerolls state.hud_words)))
        (return true))
    (if (or (or log.unshown (!= drawn_phase state.phase)) (!= reward.due state.NOTHING))
        (return true))
    (look.update (turn.picked_aim))
    (scene.differs))

; the tray first: a pick shows a pass before the rows of words it changes (each a few frames
; to draw), which wait for the next
(fn draw () void
    (if (!= state.page state.Page.none)
        (return))
    (scene.begin)
    (set drawn_phase state.phase)
    (let words_due bool (words.due))
    (let tray_drew bool (hud.refresh))
    (if words_due
        (set state.hud_words true))
    (if (not tray_drew)
        (do
            (words.refresh)
            (log.flush)
            (reward.refresh)))
    (look.update (turn.picked_aim))
    (scene.draw_frame))
