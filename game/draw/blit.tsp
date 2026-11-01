; sprites onto a page, and the backdrop back over a page.
;
; a sprite (art/sprites.tsp) is two halves stored as lib/dhgr runs: its aux memory bytes and
; its main memory bytes. A screen's sprites come in blocks (a figure's frames, the small
; sprites): their runs are read from the disk (draw/packs tables, into page 1's aux memory, not
; shown then: READ_AT) and unpacked from there into the aux language card and aux memory, so
; neither half takes main memory. A screen's runs table starts with its tables (art/sprites
; tab: every sprite's box, every kind's frames), unpacked into main memory. The hero's and the
; small sprites' blocks (0 and 1 of every fight screen, art/hero) are unpacked once and stay
; while fights follow; the title's glow takes their place. Sprites go on the byte grid: col is
; an even byte column (7 pixels a step of 2), top a row, both of the sprite's top-left corner.
; Nothing is clipped: callers keep sprites on the screen.

(import auxcard)
(import dhgr)
(import unpack)
(import art/sprites art)
(import art/hero)
(import draw/meter)
(import draw/packs)

; where the runs go: the main halves in the aux language card (bank 2's 12 KB at $D000, then
; bank 1's 4 KB), the aux halves in bank 1, then what is left of bank 2, then sprite_aux, as
; each fits; the hero's blocks first (their aux halves straight to sprite_aux, leaving the card
; to the enemies' main halves, which can go nowhere else), then the screen's (art/dhgr/
; memory.txt). Keep sprite_aux at what memory.py says the screens need
(const AUX_BYTES u16 10752)
(const CARD_START u16 0xD000)
(const CARD2_END u16 0xFFF0) ; bank 2 and the shared 8 KB, short of the vectors
(const CARD1_END u16 0xE000)
(let sprite_aux (array u8 10752) :in aux)

; where each block's runs are now (an address, and dhgr.runs' flags saying in which memory)
(let aux_at (array u16 art.BLOCKS_MOST))
(let aux_flags (array u8 art.BLOCKS_MOST))
(let card_at (array u16 art.BLOCKS_MOST))
(let card_flags (array u8 art.BLOCKS_MOST))
; and where the next ones go
(let aux_next u16 0)
(let card2_next u16 0xD000)
(let card1_next u16 0xD000)
; where the next ones went after the hero's: a fight screen's blocks go from there; hero_in
; while the hero's blocks are in (the title's glow puts them out)
(let hero_in bool false)
(let hero_aux u16 0)
(let hero_card2 u16 0)
(let hero_card1 u16 0)

; where a screen's runs table is read: page 1 in aux memory, not shown while its art loads
(const READ_AT u16 0x2000)

; packed runs of size bytes into the card: bank 2 if they fit, else bank 1 (with aux_first,
; bank 1 first); gives the flags for where, or 0 for neither
(let placed_at u16 0)

(fn into_card ((src (ptr u8)) (size u16) (aux_first bool)) u8
    (let fits2 bool (<= size (- CARD2_END card2_next)))
    (let fits1 bool (<= size (- CARD1_END card1_next)))
    (if (and fits1 (or aux_first (not fits2)))
        (do
            (set placed_at card1_next)
            (unpack.aux_to_card (as (ptr u8) card1_next) src auxcard.BANK1)
            (set card1_next (+ card1_next size))
            (return dhgr.FROM_CARD1)))
    (if fits2
        (do
            (set placed_at card2_next)
            (unpack.aux_to_card (as (ptr u8) card2_next) src auxcard.BANK2)
            (set card2_next (+ card2_next size))
            (return dhgr.FROM_CARD)))
    0)

(fn size_of ((lo u8) (hi u8)) u16
    (| (as u16 lo) (<< (as u16 hi) 8)))

; blocks first to first + n - 1 from the table read at READ_AT: their main halves from part
; part on (they must go in the card), then their aux halves (interrupts are off while a half
; unpacks into the card), to sprite_aux first with aux_home
(fn place_blocks ((part u8) (first u8) (n u8) (aux_home bool)) void
    (let read (ptr u8) (as (ptr u8) READ_AT))
    (for i u8 0 n
        (let b u8 (+ first i))
        (set (at card_flags b)
            (into_card (packs.part read (+ part i))
                (size_of (at art.tab.main_size_lo b) (at art.tab.main_size_hi b))
                false))
        (set (at card_at b) placed_at)
        (meter.unpacked))
    (for i u8 0 n
        (let b u8 (+ first i))
        (let size u16 (size_of (at art.tab.aux_size_lo b) (at art.tab.aux_size_hi b)))
        (let src (ptr u8) (packs.part read (+ (+ part n) i)))
        (let flags u8 (if aux_home
            0
            (into_card src size true)))
        (set (at aux_flags b) flags)
        (set (at aux_at b) placed_at)
        (if (= flags 0)
            (do
                (let at (ptr u8) (+ (addr_of (at sprite_aux 0)) aux_next))
                (unpack.aux_to_aux at src)
                (set (at aux_at b) (as u16 at))
                (set aux_next (+ aux_next size))))
        (meter.unpacked)))

; a screen's runs table: read, its tables (part 0) unpacked into art/sprites tab
(fn read_tables ((table (ptr u8))) void
    (let read (ptr u8) (as (ptr u8) READ_AT))
    (meter.read read table)
    (unpack.aux_to_main (as (ptr u8) (as u16 (addr_of art.tab))) (packs.part read 0)))

; the hero's blocks, unless they are in already: their own table's tables, then them, from
; the start of every memory
(fn hero_blocks () void
    (if hero_in
        (return))
    (set aux_next 0)
    (set card2_next CARD_START)
    (set card1_next CARD_START)
    (read_tables (addr_of (at hero.RUNS 0)))
    (place_blocks 1 art.KIND_CAT 2 true)
    (set hero_aux aux_next)
    (set hero_card2 card2_next)
    (set hero_card1 card1_next)
    (set hero_in true))

; a fight screen's runs: the hero's blocks if they are out, then its tables and its own blocks
; (2 on) after the hero's
(fn fight_runs ((table (ptr u8))) void
    (hero_blocks)
    (read_tables table)
    (set aux_next hero_aux)
    (set card2_next hero_card2)
    (set card1_next hero_card1)
    (place_blocks 1 2 (- art.tab.blocks 2) false))

; the title's runs: its tables and its glow, from the start (the hero's blocks are out)
(fn title_runs ((table (ptr u8))) void
    (set hero_in false)
    (read_tables table)
    (set aux_next 0)
    (set card2_next CARD_START)
    (set card1_next CARD_START)
    (place_blocks 1 0 1 false))

; where a fight's picture is read before its runs: sprite_aux past the hero's halves (art/
; dhgr/memory.txt checks it fits), or its start while they are out
(fn picture_room () (ptr u8)
    (+ (addr_of (at sprite_aux 0)) (if hero_in
        hero_aux
        0)))

(fn aux_runs ((id u8)) (ptr u8)
    (as (ptr u8)
        (+ (at aux_at (at art.tab.kind_of id))
            (size_of (at art.tab.aux_lo id) (at art.tab.aux_hi id)))))

(fn card_runs ((id u8)) (ptr u8)
    (as (ptr u8)
        (+ (at card_at (at art.tab.kind_of id))
            (size_of (at art.tab.main_lo id) (at art.tab.main_hi id)))))

; the sprite drawn over what the page has, or its shape in white (the hit flash), cut: a solid
; frame without its black (over another sprite): its first rows rows (as many as it has at
; most), the rest left as they are
(fn draw ((page u8) (col u8) (top u8) (id u8) (white bool) (cut bool) (rows u8)) void
    (if (> rows (at art.tab.rows id))
        (set rows (at art.tab.rows id)))
    (let block u8 (at art.tab.kind_of id))
    (let flags u8 (if white
        dhgr.AS_WHITE
        0))
    (if cut
        (set flags (| flags dhgr.CUTOUT)))
    (dhgr.runs page dhgr.AUX col top rows (aux_runs id) (| flags (at aux_flags block)))
    (dhgr.runs page dhgr.MAIN col top rows (card_runs id) (| flags (at card_flags block))))

(fn sprite ((page u8) (col u8) (top u8) (id u8)) void
    (draw page col top id false false 255))

; what a look leaves: black (the midnight stage keeps every pixel a look can cover black,
; tools/dhgr/lanes.py), cols byte columns from col, rows from top
(fn restore ((page u8) (col u8) (top u8) (cols u8) (rows u8)) void
    (dhgr.box page col top cols rows 0))
