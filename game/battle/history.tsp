; the log's history, a page over the stage in her turn (H, a click on the log's rows, LOG on the
; phone's pad; battle/page opens and closes it): the fight's last lines of the log
; (log.HISTORY), the oldest at the top, drawn down the stage as the rules page draws its lines.
; battle/log keeps them in aux memory as each line comes. Any key, or a click anywhere, closes it.

(import auxmem)
(import draw/text)
(import battle/log)

; the page's own lines, in aux memory (main memory is full)
(const SAY_TITLE u8 0)
(const SAY_LINES u8 1)
(const SAY_NONE u8 2)
(const SAY_NEWEST u8 3)
(const SAY_CLOSE u8 4)

(const SAY (array (ptr u8) 5)
    (make (array (ptr u8) 5)
        "THE LOG"
        "The last # lines"
        "Nothing has happened yet."
        "The newest line is at the bottom."
        "Any key or CLOSE: go back.")
    :strings aux)

(fn row ((r u8) (s (ptr u8)) (n u8)) void
    (text.start)
    (text.add_aux_n s n)
    (text.show r))

(fn open () void
    (let n u8 log.hist_count)
    ; the oldest line: the first one kept, or the one the next will write over
    (let k u8 (if (< n log.HISTORY)
        0
        log.hist_next))
    (for i u8 0 n
        (auxmem.read (addr_of (at text.line 0)) (log.hist_line k) (as u16 text.COLUMNS))
        (text.draw_at (<< i 3) (text.blocks))
        (set k (+ k 1))
        (if (= k log.HISTORY)
            (set k 0)))
    (text.start)
    (set text.inverse true)
    (text.add_aux (at SAY SAY_TITLE))
    (set text.inverse false)
    (text.tab 18)
    (text.add_aux_n (at SAY SAY_LINES) log.HISTORY)
    (text.show 0)
    (row 1
        (if (> n 0)
            (at SAY SAY_NEWEST)
            (at SAY SAY_NONE))
        0)
    (text.start)
    (text.show 2)
    (row 3 (at SAY SAY_CLOSE) 0))

; a key on the page; gives true to close it: any
(fn key ((k u8)) bool
    (!= k 0))
