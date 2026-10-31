; sprites onto a page, and the backdrop back over a page.
;
; a sprite (art/sprites.tsp) is two halves stored as lib/dhgr runs: its aux memory bytes and
; its main memory bytes. A screen's kinds are unpacked when it starts (want, unpack_all) into
; the aux language card and aux memory, so neither half takes main memory. Sprites go on the
; byte grid: col is an even byte column (7 pixels a step of 2), top a row, both of the sprite's
; top-left corner.
; Nothing is clipped: callers keep sprites on the screen.

(import auxcard)
(import dhgr)
(import unpack)
(import art/sprites art)
(import art/runs_cat)
(import art/runs_puffcap)
(import art/runs_sporelet)
(import art/runs_nightflap)
(import art/runs_misc)
(import art/runs_glow)
(import draw/screen)

; where the runs go: the main halves in the aux language card (bank 2's 12 KB at $D000, then
; bank 1's 4 KB), the aux halves in bank 1, then what is left of bank 2, then sprite_aux, as
; each fits. The fighters are solid (on black, fills of 8 or more): fight 2 needs 10,202 bytes
; of sprite_aux (art/dhgr/memory.txt); the 8 KB of aux memory the backdrop page had pays for it
(const AUX_BYTES u16 10752)
(const CARD_START u16 0xD000)
(const CARD2_END u16 0xFFF0) ; bank 2 and the shared 8 KB, short of the vectors
(const CARD1_END u16 0xE000)
(let sprite_aux (array u8 10752) :in aux)

; where each kind's runs are now (an address, and dhgr.runs' flags saying in which memory)
(let aux_at (array u16 6))
(let aux_flags (array u8 6))
(let card_at (array u16 6))
(let card_flags (array u8 6))
; and where the next ones go
(let aux_next u16 0)
(let card2_next u16 0xD000)
(let card1_next u16 0xD000)

; a new screen's kinds from here on
(fn start () void
    (set wanted_count 0)
    (set aux_next 0)
    (set card2_next CARD_START)
    (set card1_next CARD_START))

; one kind's packed runs, the aux halves and the main ones
(fn kind_aux ((kind u8)) (ptr u8)
    (match kind
        (art.KIND_CAT (addr_of (at runs_cat.cat_aux 0)))
        (art.KIND_PUFFCAP (addr_of (at runs_puffcap.puffcap_aux 0)))
        (art.KIND_SPORELET (addr_of (at runs_sporelet.sporelet_aux 0)))
        (art.KIND_NIGHTFLAP (addr_of (at runs_nightflap.nightflap_aux 0)))
        (art.KIND_MISC (addr_of (at runs_misc.misc_aux 0)))
        (_ (addr_of (at runs_glow.glow_aux 0)))))

(fn kind_main ((kind u8)) (ptr u8)
    (match kind
        (art.KIND_CAT (addr_of (at runs_cat.cat_main 0)))
        (art.KIND_PUFFCAP (addr_of (at runs_puffcap.puffcap_main 0)))
        (art.KIND_SPORELET (addr_of (at runs_sporelet.sporelet_main 0)))
        (art.KIND_NIGHTFLAP (addr_of (at runs_nightflap.nightflap_main 0)))
        (art.KIND_MISC (addr_of (at runs_misc.misc_main 0)))
        (_ (addr_of (at runs_glow.glow_main 0)))))

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

; the kinds this screen wants, unpacked together by unpack_all
(let wanted (array u8 6))
(let wanted_count u8 0)

(fn want ((kind u8)) void
    (for i u8 0 wanted_count
        (if (= (at wanted i) kind)
            (return)))
    (set (at wanted wanted_count) kind)
    (set wanted_count (+ wanted_count 1)))

; the wanted kinds' runs unpacked for this screen, all the main halves first (they must go in
; the card), then the aux halves (interrupts are off while a half unpacks into the card)
(fn unpack_all () void
    (for i u8 0 wanted_count
        (let kind u8 (at wanted i))
        (set (at card_flags kind) (into_card (kind_main kind) (at art.KIND_MAIN_SIZE kind) false))
        (set (at card_at kind) placed_at))
    (for i u8 0 wanted_count
        (let kind u8 (at wanted i))
        (let flags u8 (into_card (kind_aux kind) (at art.KIND_AUX_SIZE kind) true))
        (set (at aux_flags kind) flags)
        (set (at aux_at kind) placed_at)
        (if (= flags 0)
            (do
                (let at (ptr u8) (+ (addr_of (at sprite_aux 0)) aux_next))
                (unpack.aux_to_aux at (kind_aux kind))
                (set (at aux_at kind) (as u16 at))
                (set aux_next (+ aux_next (at art.KIND_AUX_SIZE kind)))))))

(fn aux_runs ((id u8)) (ptr u8)
    (as (ptr u8) (+ (at aux_at (at art.KIND_OF id)) (at art.AUX_AT id))))

(fn card_runs ((id u8)) (ptr u8)
    (as (ptr u8) (+ (at card_at (at art.KIND_OF id)) (at art.MAIN_AT id))))

; the sprite drawn over what the page has, or its shape in white (the hit flash), cut: a solid
; frame without its black (over another sprite): its first rows rows (as many as it has at
; most), the rest left as they are
(fn draw ((page u8) (col u8) (top u8) (id u8) (white bool) (cut bool) (rows u8)) void
    (if (> rows (at art.ROWS id))
        (set rows (at art.ROWS id)))
    (let kind u8 (at art.KIND_OF id))
    (let flags u8 (if white
        dhgr.AS_WHITE
        0))
    (if cut
        (set flags (| flags dhgr.CUTOUT)))
    (dhgr.runs page dhgr.AUX col top rows (aux_runs id) (| flags (at aux_flags kind)))
    (dhgr.runs page dhgr.MAIN col top rows (card_runs id) (| flags (at card_flags kind))))

(fn sprite ((page u8) (col u8) (top u8) (id u8)) void
    (draw page col top id false false 255))

; what a look leaves: black (the midnight stage keeps every pixel a look can cover black,
; tools/dhgr/lanes.py), cols byte columns from col, rows from top
(fn restore ((page u8) (col u8) (top u8) (cols u8) (rows u8)) void
    (dhgr.box page col top cols rows 0))
