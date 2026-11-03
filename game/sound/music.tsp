; the title jingle on the speaker: a little minor run up and a fall back, about a second and a
; half. Notes are half-periods in cycles and lengths in milliseconds; the half-periods are
; worked out while compiling from the pitches.

(import auxmem)
(import tables)
(import sound/sfx)
(import sound/waiting)

; the half-period in cycles of a note of freq Hz, on the IIe's 1.023 MHz clock
(macro half_period (freq)
    (round (/ 511500 (float freq))))

(const NOTES u8 10)

; clicks for ms milliseconds of a note of freq Hz: ms * 1023 / (2 * half), as ms * 128 /
; (half / 4), worked out while compiling
(macro clicks (freq ms)
    (/ (* ms 128) (>> (half_period freq) 2)))

; the notes, Hz and milliseconds: E5 G5 B5 E6 D6 B5 C6 B5 G#5 E5
(macro tune ()
    (list (list 659 90)
        (list 784 90)
        (list 988 90)
        (list 1319 200)
        (list 1175 90)
        (list 988 90)
        (list 1047 160)
        (list 988 90)
        (list 831 90)
        (list 659 250)))

; byte k of the notes' table: 4 a note, its half-period then its clicks, low bytes first
(macro note_byte (k)
    (let n (nth (tune) (/ k 4)))
    (let word (if (< (% k 4) 2)
        (half_period (nth n 0))
        (clicks (nth n 0) (nth n 1))))
    (if (= (% k 2) 0)
        (& word 255)
        (>> word 8)))

(tables.table NOTE_BYTES u8 40 note_byte :in aux)

; a note: clicks clicks, half cycles apart
(fn note ((half u16) (clicks u16)) void
    (let left u16 clicks)
    (while (> left 0)
        (let n u8 (if (> left 255)
            255
            (as u8 left)))
        (sfx.tone half n)
        (set left (- left (as u16 n)))))

; the notes' table, copied out of aux memory (main memory is full) into the song buffer
; (sound/waiting), which is free with no card: the jingle plays only then (title.step). Read
; with auxmem.read and not a with_aux here, so the jingle's code is in the title's overlay group
(fn word_at ((k u8)) u16
    (let p (ptr u8) (+ (addr_of (at waiting.playing 0)) k))
    (| (as u16 (load p)) (<< (as u16 (load (+ p 1))) 8)))

(fn jingle () void
    (auxmem.read (addr_of (at waiting.playing 0)) (addr_of (at NOTE_BYTES 0)) 40)
    (for i u8 0 NOTES
        (note (word_at (<< i 2)) (word_at (+ (<< i 2) 2)))
        ; a breath between notes
        (wait_cycles 9000)))
