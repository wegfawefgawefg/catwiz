; what happens to an actor when something lands on it: hits after statuses, hit points lost and
; mended, stacks added, and the feel of each: the white flash, hit-stop, knockback, the number
; floating up, the hurt face, and the death blink.

(import state)
(import art/sprites art)
(import content/charms)
(import content/enemies en)
(import content/statuses st)
(import battle/spawn)
(import battle/place)
(import battle/log)
(import draw/text)
(import content/hooks)
(import content/steps)
(import sound/sound)

; the log's sentences, in aux memory (battle/log reads them there): SAY_ and their words
(const SAY (array (ptr u8) 8)
    (make (array (ptr u8) 8)
        " \x0dsends # back."
        " \x0dtakes #."
        "'s shield \x0ctakes it all."
        " gets up!"
        " is beaten."
        " is at full hp already."
        " \x0cheals #."
        " \x0btakes #.")
    :strings aux)

(const SAY_SENDS_BACK u8 0)
(const SAY_TAKES u8 1)
(const SAY_SHIELD_TAKES_ALL u8 2)
(const SAY_GETS_UP u8 3)
(const SAY_BEATEN u8 4)
(const SAY_AT_FULL_HP u8 5)
(const SAY_HEALS u8 6)
(const SAY_HURTS u8 7) ; her own: the number pink (draw/text colours)

; the flash and the knockback end on the same frame: each change of a sprite costs a redraw
; of it on both pages (the hero's about 50,000 cycles), so a hit is three changes (hurt, white
; and knocked back; back in colour and place; the face again), not five
(const FLASH_FRAMES u8 4)
(const HITSTOP_FRAMES u8 3)
(const KNOCK_FRAMES u8 4)
(const HURT_FRAMES u8 24)
(const HURT_HELD u8 255) ; until the enemies' turn ends (turn.end_enemies)
(const FLOAT_FRAMES u8 26)
(const DEATH_FRAMES u8 48) ; 32 of blinking, then two puffs of 8

; by hits target for amount: a wand of hers sets off the hooks of target's statuses for it; by's
; statuses (content/statuses dealt), then a mark on target adds (255 at most); an enemy sending
; hits back returns its share to the hero; then target's shield, unless pierce, and what is left
; comes off its hit points. An enemy's hit on her sets off the hooks of her statuses for it (who
; hits a spiky hero takes some back); what her shield took is hooks.blocked
(fn strike ((by u8) (target u8) (amount u8) (pierce bool)) void
    (if (and (= by state.HERO) state.wand_on)
        (hooks.status steps.When.wand_hit target target))
    (let damage u8 (st.sum (st.dealt by amount true) (state.stack target (as u8 st.Status.brand))))
    (if (= by state.HERO)
        (do
            (let back u8 (state.stack target (as u8 st.Status.reflect)))
            (if (> back damage)
                (set back damage))
            (if (> back 0)
                (do
                    (state.set_stack target
                        (as u8 st.Status.reflect)
                        (- (state.stack target (as u8 st.Status.reflect)) back))
                    (set damage (- damage back))
                    (log.who target (at SAY SAY_SENDS_BACK) back)
                    (plain state.HERO back)))))
    (let at_her bool (and (= target state.HERO) (!= by state.HERO)))
    (if at_her
        (do
            (let shield u8 (state.stack state.HERO (as u8 st.Status.shield)))
            (set hooks.blocked (if (> shield damage)
                damage
                shield))))
    (if pierce
        (do
            (set state.hud_pills (| state.hud_pills (<< 1 target)))
            (log.who target (takes target) damage)
            (lose target damage))
        (plain target damage))
    (if at_her
        (hooks.status steps.When.hit_her state.HERO by)))

; the line for who taking damage: her number pink, an enemy's yellow (her hits)
(fn takes ((who u8)) (ptr u8)
    (if (= who state.HERO)
        (at SAY SAY_HURTS)
        (at SAY SAY_TAKES)))

; damage on target, its shield first (a kitten's pounce, a trio, what is sent back)
(fn plain ((target u8) (damage u8)) void
    (set damage (st.taken target damage))
    (set state.hud_pills (| state.hud_pills (<< 1 target)))
    (if (= damage 0)
        (do
            (log.who target (at SAY SAY_SHIELD_TAKES_ALL) 0)
            (sound.cue sound.Cue.ping)
            (set (at state.actors target flash) 1)
            (float_number target 0 false)
            (return)))
    (log.who target (takes target) damage)
    (lose target damage))

; n hit points off who, with all the feel of a hit; at 0 it starts dying
(fn lose ((who u8) (n u8)) void
    (if (not (at state.actors who alive))
        (return))
    ; a form that just got up takes nothing more this turn (the rest of a pounce is wasted)
    (if (!= (& state.risen (<< 1 who)) 0)
        (return))
    (let hp u8 (at state.actors who hp))
    (if (> n hp)
        (set n hp))
    (let left u8 (- hp n))
    ; she would fall: a charm may bring her back (nine lives), her max at most
    (if (and (and (= left 0) (> n 0)) (= who state.HERO))
        (do
            (set left (charms.saved))
            (if (> left (at state.actors who max_hp))
                (set left (at state.actors who max_hp)))))
    (set (at state.actors who hp) left)
    (set state.hud_pills (| state.hud_pills (<< 1 who)))
    (set (at state.actors who flash) FLASH_FRAMES)
    (set (at state.actors who mood) state.Mood.hurt)
    (set (at state.actors who mood_time) HURT_FRAMES)
    ; the hero is the big sprite (each change a redraw of 87 rows on both pages): she is not
    ; knocked back, and hit on the enemies' turn she keeps the hurt face until it ends (a
    ; second hit is then only a flash)
    (if (= who state.HERO)
        (do
            (if (= state.act_source state.Source.move)
                (set (at state.actors who mood_time) HURT_HELD)))
        (set (at state.actors who knock) KNOCK_FRAMES))
    (set state.hitstop HITSTOP_FRAMES)
    (float_number who n false)
    (if (= who state.HERO)
        (do
            (sound.cue sound.Cue.yelp)
            (if (> n 0)
                (charms.hero_hurt)))
        (do
            (sound.cue sound.Cue.thump)
            (add_stacks who (as u8 st.Status.hurt) n)))
    (if (= left 0)
        (die who)))

; at 0 hit points: the hooks of its statuses for a fall wait; the dice it held come back; an enemy with a next form gets up as it (with a
; round to get up), any other is beaten
(fn die ((who u8)) void
    ; the hooks of its statuses for its fall wait, with its stacks as they are now
    (if (!= who state.HERO)
        (hooks.status steps.When.falls who who))
    (for d u8 0 state.DICE_MOST
        (if (= (at state.held d) who)
            (do
                (set (at state.held d) state.NOTHING)
                (set state.hud_dice (| state.hud_dice (<< 1 d))))))
    (if (!= who state.HERO)
        (do
            (let next u8 (en.then (at state.actors who kind)))
            (if (!= next state.NOTHING)
                (do
                    (spawn.enemy who next true)
                    (set state.risen (| state.risen (<< 1 who)))
                    (set (at state.actors who mood) state.Mood.hurt)
                    (set (at state.actors who mood_time) HURT_FRAMES)
                    (set state.hud_intents (| state.hud_intents (<< 1 who)))
                    (log.who who (at SAY SAY_GETS_UP) 0)
                    (sound.cue sound.Cue.wobble)
                    (return)))))
    (set (at state.actors who alive) false)
    (if (!= who state.HERO)
        (set (at state.actors who dying) DEATH_FRAMES))
    (set (at state.actors who mood) state.Mood.ko)
    (set (at state.actors who mood_time) DEATH_FRAMES)
    (set state.hud_intents (| state.hud_intents (<< 1 who)))
    (log.who who (at SAY SAY_BEATEN) 0)
    (sound.cue sound.Cue.squeak))

(fn heal ((who u8) (n u8)) void
    (let hp u8 (at state.actors who hp))
    (let room u8 (- (at state.actors who max_hp) hp))
    (if (> n room)
        (set n room))
    ; nothing to mend: no +0 floats up
    (if (= n 0)
        (do
            (log.who who (at SAY SAY_AT_FULL_HP) 0)
            (return)))
    (set (at state.actors who hp) (+ hp n))
    (log.who who (at SAY SAY_HEALS) n)
    (set (at state.actors who mood) state.Mood.happy)
    (set (at state.actors who mood_time) HURT_FRAMES)
    (set state.hud_pills (| state.hud_pills (<< 1 who)))
    (float_number who n true))

; n more of who's status, 255 at most
(fn add_stacks ((who u8) (status u8) (n u8)) void
    (state.set_stack who status (st.sum (state.stack who status) n)))

; a number rising from who's head: the hit points lost, or with plus the ones mended. Two
; digits: a hit of 100 or more shows 99 (the log says the whole number)
(fn float_number ((who u8) (n u8) (plus bool)) void
    (if (> n 99)
        (set n 99))
    (let slot u8 state.NOTHING)
    (for i u8 0 state.FLOATERS
        (if (= (at state.floaters i time) 0)
            (set slot i)))
    (if (= slot state.NOTHING)
        (return))
    (let first u8 (+ art.DIGIT_0 n))
    (let second u8 state.NOTHING)
    (if (>= n 10)
        (do
            (text.digits n)
            (set first (+ art.DIGIT_0 text.tens))
            (set second (+ art.DIGIT_0 text.ones))))
    (if (and plus (< n 10))
        (do
            (set first art.DIGIT_PLUS)
            (set second (+ art.DIGIT_0 n))))
    ; enemies: above the intent over the head, low enough to rise without leaving the screen.
    ; The hero: beside her face, clear of the tall hat, so the number never has to be drawn
    ; over her
    (let col u8 (& (- (place.middle who) 1) 0xFE))
    (if (!= second state.NOTHING)
        (set col (- col 2)))
    (let top u8 (place.top who))
    (set top (if (> top 54)
        (- top 34)
        20))
    (if (= who state.HERO)
        (do
            (set col
                (& (+ (at state.actors who home) (at art.tab.kcols (at state.actors who figure)))
                    0xFE))
            (set top 44)))
    (set (at state.floaters slot)
        (make state.Floater :sprite first :second second :col col :top top :time FLOAT_FRAMES)))
