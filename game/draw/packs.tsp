; the screens' art on the disk (art/screen_*.tsp, written by tools/dhgr/game.py): a table of
; several parts, each packed while compiling (ZX0, as tables.packed), read whole with lib/disk
; and unpacked part by part (lib/unpack). (packs NAME (bytes...) (bytes...) ...) makes the const
; :on disk: a count, each part's offset from the table's start (2 bytes, low first), then the
; packed parts one after another.

(macro packs (name & parts)
    (let n (len parts))
    (let packed (list))
    (for i 0 n
        (set packed (append packed (list (pack (nth parts i))))))
    (let offsets (list n))
    (let offset (+ 1 (* 2 n)))
    (for i 0 n
        (set offsets (append offsets (list (% offset 256) (/ offset 256))))
        (set offset (+ offset (len (nth packed i)))))
    (let bytes offsets)
    (for i 0 n
        (set bytes (append bytes (nth packed i))))
    `(const ,name (array u8 ,(len bytes)) (make (array u8 ,(len bytes)) ,@bytes) :on disk))

; part k of a packs table read to table in aux memory
(fn part ((table (ptr u8)) (k u8)) (ptr u8)
    (let i u16 (+ 1 (as u16 (<< k 1))))
    (let lo u8 0)
    (let hi u8 0)
    (with_aux true false
        (set lo (load (+ table i)))
        (set hi (load (+ table (+ i 1)))))
    (+ table (| (as u16 lo) (<< (as u16 hi) 8))))
