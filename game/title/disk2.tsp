; the second disk: the fights' art and the rules pages are on it (Tisple's :on disk2), read from
; drive 2, or from drive 1 on a machine with one drive. Found once, as the first run starts
; (battle.enter): its label read from drive 2, then from drive 1; when neither has it, the text
; lines ask for it and wait for a key, and it is looked for again. A drive that gave nothing at
; all (a machine with one drive: NO_DISK) is not asked again, so the words say drive 1. Once it
; is found the game never needs the boot disk again (the later titles' art is on both).

(import apple2 a2)
(import disk)
(import draw/meter)
(import draw/text)

(const LABEL_BYTES u8 8)

; the second disk's label, and the bytes it must hold (in aux memory, where it is read to)
(const LABEL (array u8 8) (make (array u8 8) 67 65 84 87 73 90 32 50) :on disk2) ; CATWIZ 2
(const WANT (array u8 8) (make (array u8 8) 67 65 84 87 73 90 32 50) :in aux)

; where the label is read: aux memory's text page 1, the rules page's buffer, free now (a let:
; main memory's text page has lets there)
(let read_at u16 0x0400)

(const SAY (array (ptr u8) 3)
    (make (array (ptr u8) 3)
        "Put CATWIZ DISK 2 in drive 2,"
        "Put CATWIZ DISK 2 in drive 1,"
        "then press RETURN.")
    :strings aux)

(let found bool false)
(let no_drive2 bool false) ; drive 2 gave nothing at all: there is none

; whether the drive disk.disk2_in named has the second disk; status, the read's
(let status u8 0)

(fn has_label () bool
    (let at (ptr u8) (as (ptr u8) read_at))
    (set status (meter.read at (addr_of (at LABEL 0))))
    (if (!= status disk.DONE)
        (return false))
    (let same bool true)
    (with_aux true false
        (for i u8 0 LABEL_BYTES
            (if (!= (load (+ at i)) (at WANT i))
                (set same false))))
    same)

; the words, and a key (read here with the card's tick held off, which would take it)
(fn ask () void
    (text.start)
    (text.add_aux
        (at SAY (if no_drive2
            1
            0)))
    (text.show 2)
    (text.start)
    (text.add_aux (at SAY 2))
    (text.show 3)
    (sei)
    (io_read u8 a2.KBDSTRB)
    (while (< (io_read u8 a2.KBD) 0x80))
    (io_read u8 a2.KBDSTRB)
    (cli))

(fn find () void
    (while (not found)
        (if (not no_drive2)
            (do
                (disk.disk2_in 2)
                (if (has_label)
                    (do
                        (set found true)
                        (return)))
                (set no_drive2 (= status disk.NO_DISK))))
        (disk.disk2_in 1)
        (if (has_label)
            (do
                (set found true)
                (return)))
        (ask)))
