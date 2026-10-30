; the title jingle on the speaker: a little minor run up and a fall back, about a second and a
; half. Notes are half-periods in cycles and lengths in milliseconds; the half-periods are
; worked out while compiling from the pitches.

(import sound/sfx)

; the half-period in cycles of a note of freq Hz, on the IIe's 1.023 MHz clock
(macro half_period (freq)
    (round (/ 511500 (float freq))))

(const NOTES u8 10)

(const NOTE_HALF (array u16 10)
    (make (array u16 10)
        (half_period 659)   ; E5
        (half_period 784)   ; G5
        (half_period 988)   ; B5
        (half_period 1319)  ; E6
        (half_period 1175)  ; D6
        (half_period 988)   ; B5
        (half_period 1047)  ; C6
        (half_period 988)   ; B5
        (half_period 831)   ; G#5
        (half_period 659))) ; E5

(const NOTE_MS (array u8 10) (make (array u8 10) 90 90 90 200 90 90 160 90 90 250))

; a note for ms milliseconds: clicks = ms * 1023 / (2 * half), as ms * 128 / (half / 4) to stay
; in 16 bits
(fn note ((half u16) (ms u8)) void
    (let clicks u16 (/ (* (as u16 ms) 128) (>> half 2)))
    (let left u16 clicks)
    (while (> left 0)
        (let n u8 (if (> left 255)
            255
            (as u8 left)))
        (sfx.tone half n)
        (set left (- left (as u16 n)))))

(fn jingle () void
    (for i u8 0 NOTES
        (note (at NOTE_HALF i) (at NOTE_MS i))
        ; a breath between notes
        (wait_cycles 9000)))
