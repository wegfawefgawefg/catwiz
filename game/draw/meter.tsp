; the fight's load meter: a trail of paw prints along the foot of the stage while the fight's
; kinds' runs are read and unpacked (battle.load_art, about 2 s with the picture already shown
; on the spare page). A sector read counts 1 and an unpack UNPACK (each takes about 5 sectors'
; time), so the paws come about evenly. A paw is drawn once, when it is due: between two
; sectors (read, below) one paw at most, about 1,500 cycles, inside the reader's 8,700. Off,
; the calls do nothing: the title's runs, the pictures and the rules' pages are read the same
; way (one way to read keeps lib/disk's plain read out of a full main memory).

(import disk)
(import auxmem)
(import dhgr)
(import tables)
(import draw/screen)

(const PAWS u8 16)
(const FIRST_GROUP u8 2) ; 7-pixel groups 2-17: the 16 paws centred
(const TOP u8 164)       ; the left feet's top row; the right ones STEP_DOWN rows lower
(const STEP_DOWN u8 6)
(const ROWS u8 10)
(const UNPACK u8 5) ; an unpack's weight, in sectors

; a paw's rows, bit x for pixel x of its 7-pixel group: four toes, then the pad
(macro paw_rows ()
    (list 0x14 0x14 0x41 0x41 0x00 0x1C 0x3E 0x3E 0x3E 0x1C))

; byte b of a paw row in white (the group's bytes: 0 aux, 1 main, 2 aux, 3 main, 7 of its 28
; dots each, pixel p lighting dots 4p to 4p + 3)
(macro paw_byte (bits b)
    (let byte 0)
    (for t 0 7
        (let p (/ (+ (* 7 b) t) 4))
        (if (!= (& (>> bits p) 1) 0)
            (set byte (| byte (<< 1 t)))))
    byte)

; each memory's two bytes a row, the rows one after another, made while compiling
(macro paw_aux (i)
    (paw_byte (nth (paw_rows) (/ i 2)) (* 2 (% i 2))))

(macro paw_main (i)
    (paw_byte (nth (paw_rows) (/ i 2)) (+ 1 (* 2 (% i 2)))))

(tables.table PAW_AUX u8 20 paw_aux :in aux)
(tables.table PAW_MAIN u8 20 paw_main)

(let on bool false)
(let total u8 1) ; the load's weight: under 176, so done stays a byte
(let done u8 0)  ; PAWS times the weight done, less total for each paw drawn
(let drawn u8 0)

; paw i onto the spare page: its bytes copied in, both memories
(fn paw ((i u8)) void
    (let col u8 (<< (+ FIRST_GROUP i) 1))
    (let top u8 TOP)
    (if (!= (& i 1) 0)
        (set top (+ top STEP_DOWN)))
    (dhgr.copy screen.SPARE dhgr.AUX col top 2 ROWS (addr_of (at PAW_AUX 0)))
    (dhgr.copy screen.SPARE dhgr.MAIN col top 2 ROWS (addr_of (at PAW_MAIN 0))))

; the sectors a disk table's record says it has (lib/disk: its length first, low byte first)
; a table's record (every table on the disks has its record in aux memory: main memory is full),
; copied here, where lib/disk reads it; 16 bytes, the longest (a boot disk table's)
(let record (array u8 16))

(fn fetch ((table (ptr u8))) (ptr u8)
    (auxmem.read (addr_of (at record 0)) table 16)
    (addr_of (at record 0)))

(fn sectors ((table (ptr u8))) u8
    (let r (ptr u8) (fetch table))
    (+ (load (+ r 1)) (if (= (load r) 0)
        0
        1)))

; the meter on, for a load of weight (each part at most UNPACK)
(fn start ((weight u8)) void
    (set total weight)
    (set done 0)
    (set drawn 0)
    (set on true))

; weight more of the load is in: the paws now due
(fn add ((weight u8)) void
    (if (not on)
        (return))
    (set done (+ done (<< weight 4)))
    (while (and (>= done total) (< drawn PAWS))
        (set done (- done total))
        (paw drawn)
        (set drawn (+ drawn 1))))

; one sector in: disk.read_with's step, and once after the read for its last
(fn sector () void
    (add 1))

; a disk table into aux memory at dst, a sector at a time on the meter; disk.DONE or the error
(fn read ((dst (ptr u8)) (table (ptr u8))) u8
    (let status u8 (disk.read_with dst (fetch table) disk.AUX sector))
    (sector)
    status)

(fn unpacked () void
    (add UNPACK))

; the meter off, its paws cleared from the spare page (black, as the foot of a picture is)
(fn stop () void
    (dhgr.box screen.SPARE (<< FIRST_GROUP 1) TOP (<< PAWS 1) (+ ROWS STEP_DOWN) dhgr.BLACK)
    (set on false))
