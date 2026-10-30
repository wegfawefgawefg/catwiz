; what happens to an actor when something lands on it: hits after statuses, hit points lost and
; mended, stacks added, and the feel of each: the white flash, hit-stop, knockback, the number
; floating up, the hurt face, and the death blink.

(import state)
(import art/sprites art)
(import content/statuses st)
(import battle/place)
(import sound/sfx)

(const FLASH_FRAMES u8 3)
(const HITSTOP_FRAMES u8 3)
(const KNOCK_FRAMES u8 6)
(const HURT_FRAMES u8 30)
(const FLOAT_FRAMES u8 26)
(const DEATH_FRAMES u8 48) ; 32 of blinking, then two puffs of 8
(const MOST_STACKS u8 99)

; by hits target for amount: by's statuses, then target's, then what is left comes off its
; hit points
(fn strike ((by u8) (target u8) (amount u8)) void
    (let damage u8 (st.dealt by amount))
    (set damage (st.taken target damage))
    (set state.hud_pills (| state.hud_pills (<< 1 target)))
    (if (= damage 0)
        (do
            (sfx.ping)
            (set (at state.actors target flash) 1)
            (float_number target 0 false)
            (return)))
    (lose target damage))

; n hit points off who, with all the feel of a hit; at 0 it starts dying
(fn lose ((who u8) (n u8)) void
    (if (not (at state.actors who alive))
        (return))
    (let hp u8 (at state.actors who hp))
    (if (> n hp)
        (set n hp))
    (set (at state.actors who hp) (- hp n))
    (set state.hud_pills (| state.hud_pills (<< 1 who)))
    (set (at state.actors who flash) FLASH_FRAMES)
    (set (at state.actors who knock) KNOCK_FRAMES)
    (set (at state.actors who mood) state.Mood.hurt)
    (set (at state.actors who mood_time) HURT_FRAMES)
    (set state.hitstop HITSTOP_FRAMES)
    (float_number who n false)
    (if (= who state.DOG)
        (sfx.yelp)
        (sfx.hit))
    (if (= (- hp n) 0)
        (die who)))

(fn die ((who u8)) void
    (set (at state.actors who alive) false)
    (if (!= who state.DOG)
        (set (at state.actors who dying) DEATH_FRAMES))
    (set (at state.actors who mood) state.Mood.ko)
    (set (at state.actors who mood_time) DEATH_FRAMES)
    (set state.hud_intents (| state.hud_intents (<< 1 who)))
    (sfx.squeak))

(fn heal ((who u8) (n u8)) void
    (let hp u8 (at state.actors who hp))
    (let room u8 (- (at state.actors who max_hp) hp))
    (if (> n room)
        (set n room))
    (set (at state.actors who hp) (+ hp n))
    (set (at state.actors who mood) state.Mood.happy)
    (set (at state.actors who mood_time) HURT_FRAMES)
    (set state.hud_pills (| state.hud_pills (<< 1 who)))
    (float_number who n true))

(fn add_stacks ((who u8) (status u8) (n u8)) void
    (let now u8 (state.stack who status))
    (if (> n (- MOST_STACKS now))
        (set n (- MOST_STACKS now)))
    (state.set_stack who status (+ now n)))

; a number rising from who's head: the hit points lost, or with plus the ones mended
(fn float_number ((who u8) (n u8) (plus bool)) void
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
            (set first (+ art.DIGIT_0 (/ n 10)))
            (set second (+ art.DIGIT_0 (% n 10)))))
    (if (and plus (< n 10))
        (do
            (set first art.BIG_PLUS)
            (set second (+ art.DIGIT_0 n))))
    (let col u8 (- (place.middle who) 1))
    (if (!= second state.NOTHING)
        (set col (- col 1)))
    (let top u8 (place.top who))
    (set top (if (> top 24)
        (- top 18)
        6))
    (set (at state.floaters slot)
        (make state.Floater :sprite first :second second :col col :top top :time FLOAT_FRAMES)))
