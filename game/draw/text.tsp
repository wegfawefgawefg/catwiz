; the four lines of 40-column text under the picture (mixed mode). A line is built in line,
; then shown: copied to text page 1, which the bottom of the screen reads while hi-res page 1
; is shown, and to text page 2, which it reads while page 2 is shown (the game flips the two
; every frame). Text page 2's last two lines lie inside the program's memory ($0B50 and
; $0BD0), kept out of the layout below; its first two in the boot loader's, free once the
; game runs.
;
; strings are plain ASCII; add turns them into screen codes (bit 7 set: normal, or inverse
; while inverse is on). A # in a string stands for the number given to add_n.

(import apple2 a2)

(const COLUMNS u8 40)
(const ROWS u8 4)
(const SPACE u8 0xA0)

(let text2_row2 (array u8 40) :address 0x0B50 :reserve)
(let text2_row3 (array u8 40) :address 0x0BD0 :reserve)

; text rows 20 to 23 on each page
(const PAGE1_ROW (array u16 4) (make (array u16 4) 0x0650 0x06D0 0x0750 0x07D0))
(const PAGE2_ROW (array u16 4) (make (array u16 4) 0x0A50 0x0AD0 0x0B50 0x0BD0))

; the line being built, as screen codes, and where the next character goes
(let line (array u8 40) :address 0x09E0) ; scratch: see AGENTS.md, Memory
(let col u8 0)
(let inverse bool false)

(fn start () void
    (for i u8 0 COLUMNS
        (set (at line i) SPACE))
    (set col 0)
    (set inverse false))

; one ASCII character
(fn char ((c u8)) void
    (if (>= col COLUMNS)
        (return))
    (let code u8 (| c 0x80))
    (if inverse
        (set code (if (>= c 0x40)
            (- c 0x40)
            c)))
    (set (at line col) code)
    (set col (+ col 1)))

; n in decimal
(fn number ((n u8)) void
    (if (>= n 100)
        (char (+ '0' (/ n 100))))
    (if (>= n 10)
        (char (+ '0' (% (/ n 10) 10))))
    (char (+ '0' (% n 10))))

; a string, with n for each #
(fn add_n ((s (ptr u8)) (n u8)) void
    (let i u8 0)
    (while (!= (load (+ s i)) 0)
        (let c u8 (load (+ s i)))
        (if (= c '#')
            (number n)
            (char c))
        (set i (+ i 1))))

(fn add ((s (ptr u8))) void
    (add_n s 0))

; the next character at column c
(fn tab ((c u8)) void
    (if (> c col)
        (set col c)))

; the line onto text row r (0 to 3) of both pages
(fn show ((r u8)) void
    (let p1 (ptr u8) (as (ptr u8) (at PAGE1_ROW r)))
    (let p2 (ptr u8) (as (ptr u8) (at PAGE2_ROW r)))
    (for i u8 0 COLUMNS
        (let c u8 (at line i))
        (store (+ p1 i) c)
        (store (+ p2 i) c)))

; the line kept elsewhere (the log), and back
(fn save ((to (ptr u8))) void
    (for i u8 0 COLUMNS
        (store (+ to i) (at line i))))

(fn load_line ((from (ptr u8))) void
    (for i u8 0 COLUMNS
        (set (at line i) (load (+ from i)))))

; all four rows blank
(fn clear () void
    (start)
    (for r u8 0 ROWS
        (show r)))

; graphics with the four text rows under it, or the whole screen graphics
(fn mixed ((on_now bool)) void
    (if on_now
        (io_read u8 a2.MIXSET)
        (io_read u8 a2.MIXCLR)))
