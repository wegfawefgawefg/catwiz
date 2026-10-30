; speaker sound effects. Each one holds the processor while it plays, so they stay short: a
; frame is 17030 cycles, and the longest here, the bark, takes about 5 frames.
;
; the speaker cone moves on every access to SPKR; a wave of half-period h cycles is a click
; every h cycles, about 1023000 / (2 h) Hz. An effect is a run of parts from the table below,
; each one of three kinds:
;   tone   count clicks, half cycles apart
;   slide  count clicks from half, the gap moving by step after each
;   noise  count clicks at random gaps of half to half + 4 * 255 cycles: lower as half grows
; played by one loop (play), so the speaker code is in one place.

(import apple2 a2)
(import random)

(enum Kind (tone slide noise))

(struct Part ((kind Kind) (half u16) (step i16) (count u8)))

(let parts (array Part 33)
    (make (array Part 33)
        ; 0 bark: rrr, rising and rough, then a low wuf
        (make Part :kind Kind.slide :half 1400 :step -60 :count 6)
        (make Part :kind Kind.noise :half 300 :step 0 :count 3)
        (make Part :kind Kind.slide :half 1300 :step -60 :count 6)
        (make Part :kind Kind.noise :half 300 :step 0 :count 3)
        (make Part :kind Kind.slide :half 1200 :step -60 :count 6)
        (make Part :kind Kind.noise :half 300 :step 0 :count 3)
        (make Part :kind Kind.noise :half 900 :step 0 :count 10)
        (make Part :kind Kind.slide :half 1100 :step 120 :count 8)
        ; 8 rattle: one shake of the dice, a few dry clicks
        (make Part :kind Kind.noise :half 120 :step 0 :count 2)
        (make Part :kind Kind.noise :half 1200 :step 0 :count 2)
        (make Part :kind Kind.noise :half 150 :step 0 :count 2)
        ; 11 zap: a quick rising whistle
        (make Part :kind Kind.slide :half 700 :step -18 :count 34)
        ; 12 hit: a thump of noise
        (make Part :kind Kind.noise :half 600 :step 0 :count 18)
        (make Part :kind Kind.noise :half 1400 :step 0 :count 8)
        ; 14 ping: a hit a shield took
        (make Part :kind Kind.tone :half 220 :step 0 :count 60)
        (make Part :kind Kind.tone :half 330 :step 0 :count 30)
        ; 16 chime: hit points back, two notes up
        (make Part :kind Kind.tone :half 390 :step 0 :count 70)
        (make Part :kind Kind.tone :half 290 :step 0 :count 100)
        ; 18 hiss: a fire catching, thin fast noise
        (make Part :kind Kind.noise :half 70 :step 0 :count 100)
        ; 19 wobble: a spooky swing up and down
        (make Part :kind Kind.slide :half 900 :step -40 :count 10)
        (make Part :kind Kind.slide :half 500 :step 40 :count 10)
        (make Part :kind Kind.slide :half 900 :step -40 :count 10)
        (make Part :kind Kind.slide :half 500 :step 40 :count 10)
        ; 23 puff: a die that does nothing
        (make Part :kind Kind.noise :half 1600 :step 0 :count 10)
        ; 24 squeak: the last of a beaten enemy, two falling chirps
        (make Part :kind Kind.slide :half 160 :step 12 :count 40)
        (make Part :kind Kind.slide :half 200 :step 16 :count 36)
        ; 26 yelp: the dog's ow
        (make Part :kind Kind.slide :half 300 :step 30 :count 30)
        ; 27 tick: a key that does nothing now
        (make Part :kind Kind.tone :half 120 :step 0 :count 2)
        ; 28 win: a little rising fanfare
        (make Part :kind Kind.tone :half 776 :step 0 :count 60)
        (make Part :kind Kind.tone :half 615 :step 0 :count 75)
        (make Part :kind Kind.tone :half 517 :step 0 :count 180)
        ; 31 lose: a long falling slide
        (make Part :kind Kind.slide :half 400 :step 8 :count 120)
        (make Part :kind Kind.slide :half 1360 :step 2 :count 40)))

(fn play ((first u8) (count u8)) void
    (for p u8 first (+ first count)
        (let half u16 (at parts p half))
        (let step i16 (at parts p step))
        (let kind Kind (at parts p kind))
        (for i u8 0 (at parts p count)
            (io_read u8 a2.SPKR)
            (match kind
                (Kind.tone (wait_cycles half))
                (Kind.slide
                    (wait_cycles half)
                    (set half (as u16 (+ (as i16 half) step))))
                (Kind.noise (wait_cycles (+ half (<< (as u16 (random.byte)) 2))))))))

(fn bark () void
    (play 0 8))

(fn rattle () void
    (play 8 3))

(fn zap () void
    (play 11 1))

(fn hit () void
    (play 12 2))

(fn ping () void
    (play 14 2))

(fn chime () void
    (play 16 2))

(fn hiss () void
    (play 18 1))

(fn wobble () void
    (play 19 4))

(fn puff () void
    (play 23 1))

(fn squeak () void
    (play 24 2))

(fn yelp () void
    (play 26 1))

(fn tick () void
    (play 27 1))

(fn win () void
    (play 28 3))

(fn lose () void
    (play 31 2))

; count clicks half cycles apart, for the jingle
(fn tone ((half u16) (count u8)) void
    (for i u8 0 count
        (io_read u8 a2.SPKR)
        (wait_cycles half)))
