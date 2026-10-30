; speaker sound effects. Each one holds the processor while it plays, so they stay short: a
; frame is 17030 cycles, and the longest here takes about 4 frames.
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

(const PARTS (array Part 25)
    (make (array Part 25)
        ; 0 rattle: one shake of the dice, a few dry clicks
        (make Part :kind Kind.noise :half 120 :step 0 :count 2)
        (make Part :kind Kind.noise :half 1200 :step 0 :count 2)
        (make Part :kind Kind.noise :half 150 :step 0 :count 2)
        ; 3 zap: a quick rising whistle
        (make Part :kind Kind.slide :half 700 :step -18 :count 34)
        ; 4 hit: a thump of noise
        (make Part :kind Kind.noise :half 600 :step 0 :count 18)
        (make Part :kind Kind.noise :half 1400 :step 0 :count 8)
        ; 6 ping: a hit a shield took
        (make Part :kind Kind.tone :half 220 :step 0 :count 60)
        (make Part :kind Kind.tone :half 330 :step 0 :count 30)
        ; 8 chime: hit points back, two notes up
        (make Part :kind Kind.tone :half 390 :step 0 :count 70)
        (make Part :kind Kind.tone :half 290 :step 0 :count 100)
        ; 10 hiss: a fire catching, thin fast noise
        (make Part :kind Kind.noise :half 70 :step 0 :count 100)
        ; 11 wobble: a spooky swing up and down
        (make Part :kind Kind.slide :half 900 :step -40 :count 10)
        (make Part :kind Kind.slide :half 500 :step 40 :count 10)
        (make Part :kind Kind.slide :half 900 :step -40 :count 10)
        (make Part :kind Kind.slide :half 500 :step 40 :count 10)
        ; 15 puff: a die that does nothing
        (make Part :kind Kind.noise :half 1600 :step 0 :count 10)
        ; 16 squeak: the last of a beaten enemy, two falling chirps
        (make Part :kind Kind.slide :half 160 :step 12 :count 40)
        (make Part :kind Kind.slide :half 200 :step 16 :count 36)
        ; 18 yelp: the dog's ow
        (make Part :kind Kind.slide :half 300 :step 30 :count 30)
        ; 19 tick: a key that does nothing now
        (make Part :kind Kind.tone :half 120 :step 0 :count 2)
        ; 20 win: a little rising fanfare
        (make Part :kind Kind.tone :half 776 :step 0 :count 60)
        (make Part :kind Kind.tone :half 615 :step 0 :count 75)
        (make Part :kind Kind.tone :half 517 :step 0 :count 180)
        ; 23 lose: a long falling slide
        (make Part :kind Kind.slide :half 400 :step 8 :count 120)
        (make Part :kind Kind.slide :half 1360 :step 2 :count 40)))

; count clicks from half cycles apart, the gap moving by step after each (0 for a tone);
; noise adds a random 0 to 4 * 255 cycles to each gap. One wait for all three kinds: each
; variable wait_cycles is 76 bytes
(fn run ((noise bool) (half u16) (step i16) (count u8)) void
    (let h u16 half)
    (for i u8 0 count
        (io_read u8 a2.SPKR)
        (let gap u16 h)
        (if noise
            (set gap (+ h (<< (as u16 (random.byte)) 2))))
        (wait_cycles gap)
        (set h (as u16 (+ (as i16 h) step)))))

(fn play ((first u8) (count u8)) void
    (for p u8 first (+ first count)
        (run (= (at PARTS p kind) Kind.noise)
            (at PARTS p half)
            (at PARTS p step)
            (at PARTS p count))))

(fn win () void
    (play 20 3))

(fn lose () void
    (play 23 2))

; count clicks half cycles apart, for the jingle
(fn tone ((half u16) (count u8)) void
    (run false half 0 count))
