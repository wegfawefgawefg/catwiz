; the faces and charms in play, in memory: every one is a record in the catalog on disk 2
; (content/catalog, from content/faces.tsp and content/charm_rows.tsp), and memory holds only the
; ones in play, a row each (docs/faces.md):
;   rows 0-5    her six faces: row k is the item on her slot k (a die's face k)
;   row 6       the hairball (an enemy clogs a slot with it mid-fight)
;   rows 7-10   her charms (content/charms)
;   rows 11-15  the five faces offered between fights; rows 16-18 the three charms offered
;   row 19      a face a hat trick drew mid-fight (its record in aux memory's text page 1)
; A row's record (256 bytes) is in aux memory: rows 0-10 all run, the offer's rows only between
; fights, at the end of blit.sprite_aux (the last fight's enemies' sprites, dead until the next
; fight's art loads; the hero's stay at its start: art/dhgr/memory.txt). What a fight reads every
; play is copied into main memory as a row loads (slot, amount, step, cost, aim, tags, show: a
; read from aux memory each cost a fight's frames 14%); the name, text, steps and picture stay in
; the record. Records are read only between fights: her faces at a run's start, the offer when it
; is drawn, a face or charm again when she takes it. A charm's row keeps its kind, when and mark
; in the slot, step and cost fields (content/charms reads them).

(import state)
(import auxmem)
(import content/action ac)
(import content/catalog)
(import draw/blit)
(import draw/meter)

(const ITEM_MOST u8 2)

(const ROWS u8 20)
(const HAIRBALL u8 6)
(const CHARM_ROW u8 7)   ; her charms: rows 7 on
(const HELD_CHARMS u8 4) ; kinds of charm she holds at most (the kit page shows four)
(const RESIDENT u8 11)   ; rows 0-10, in aux memory all run
(const OFFER_ROW u8 11)  ; the faces offered: rows 11-15
(const OFFERS u8 5)
(const OFFER_CHARM_ROW u8 16) ; the charms offered: rows 16-18
(const OFFER_CHARMS u8 3)
(const HAT_ROW u8 19) ; a face a hat trick plays (content/play), its record at HAT_AT
; its record: aux memory's text page 1, the rules page's buffer, free in her turn (a let, not a
; constant pointer: the layout checks a constant one against main memory's lets there)
(let hat_at u16 0x0400)
(const SCRATCH_BYTES u16 2304) ; the draws' pool (a sector) and the offer's 8 records
(const NAME_AT u8 7)           ; a record's bytes (content/catalog)
(const TEXT_AT u8 8)

(let records (array u8 2816) :in aux) ; rows 0-10, 256 bytes each

; what a fight reads every play, in main memory: a row's slot, number (amount, step more a level),
; a book's mana, aim, tags (content/action) and show (content/shows); and its catalog id
; (scratch at fixed addresses, set as a row loads: AGENTS.md, Memory)
(let slots (array ac.Slot 20) :address 0x0272)
(let amounts (array u8 20) :address 0x0286)
(let ups (array u8 20) :address 0x029A)
(let costs (array u8 20) :address 0x02AE)
(let aims (array state.Aim 20) :address 0x02C2)
(let tag_bits (array u8 20) :address 0x02D6)
(let show_of (array u8 20) :address 0x02EA)
(let ids (array u8 20) :address 0x03CD)
(let kinds (array u8 20) :address 0x0310) ; a record's first byte as it is (a charm's kind)

; where the offer's scratch starts: the draws' pool there, the records after it
(fn scratch () (ptr u8)
    (+ (addr_of (at blit.sprite_aux 0)) (- blit.AUX_BYTES SCRATCH_BYTES)))

; row's record, in aux memory
(fn record ((row u8)) (ptr u8)
    (if (= row HAT_ROW)
        (return (as (ptr u8) hat_at)))
    (if (< row RESIDENT)
        (return (+ (addr_of (at records 0)) (<< (as u16 row) 8))))
    (+ (scratch) (<< (as u16 (- row (- OFFER_ROW 1))) 8)))

; a string of row's record (its name or text), by the place its byte k says
(fn string ((row u8) (k u8)) (ptr u8)
    (let r (ptr u8) (record row))
    (+ r
        (as u16 (with_aux true false
            (load (+ r k))))))

(fn name ((row u8)) (ptr u8)
    (string row NAME_AT))

(fn text ((row u8)) (ptr u8)
    (string row TEXT_AT))

; its steps (content/play runs them), in aux memory
(fn fx ((row u8)) (ptr u8)
    (+ (record row) catalog.STEPS_AT))

(fn picture ((row u8)) (ptr u8)
    (+ (record row) catalog.PICTURE_AT))

(fn slot ((row u8)) ac.Slot
    (at slots row))

(fn amount ((row u8)) u8
    (at amounts row))

(fn step ((row u8)) u8
    (at ups row))

(fn cost ((row u8)) u8
    (at costs row))

(fn aim ((row u8)) state.Aim
    (at aims row))

(fn tags ((row u8)) u8
    (at tag_bits row))

(fn show ((row u8)) u8
    (at show_of row))

; a charm row's kind (enc.CharmKind's number)
(fn kind ((row u8)) u8
    (at kinds row))

; ---- loading (between fights only)

(let top (array u8 7) :address 0x0197) ; a record's first bytes, copied here (scratch)

; a record's slot and aim bytes as the enums (nothing converts a number back to an enum); a
; charm's kind past the slots reads as junk
(const SLOT_OF (array ac.Slot 16)
    (make (array ac.Slot 16)
        ac.Slot.wand ac.Slot.fluff ac.Slot.star ac.Slot.book ac.Slot.curse ac.Slot.trick
        ac.Slot.junk ac.Slot.junk ac.Slot.junk ac.Slot.junk ac.Slot.junk ac.Slot.junk
        ac.Slot.junk ac.Slot.junk ac.Slot.junk ac.Slot.junk))

(const AIM_OF (array state.Aim 4)
    (make (array state.Aim 4) state.Aim.foe state.Aim.self state.Aim.all state.Aim.friend))

; record id of the faces' catalog (or the charms') into row, its fields into main memory
(fn read ((row u8) (id u8) (charm bool)) void
    (meter.read_piece (record row)
        (if charm
            (addr_of (at catalog.CHARMS 0))
            (addr_of (at catalog.FACES 0)))
        id)
    (set (at ids row) id)
    (auxmem.read (addr_of (at top 0)) (record row) 7)
    (set (at kinds row) (at top 0))
    (set (at slots row) (at SLOT_OF (& (at top 0) 15)))
    (set (at amounts row) (at top 1))
    (set (at ups row) (at top 2))
    (set (at costs row) (at top 3))
    (set (at aims row) (at AIM_OF (& (at top 4) 3)))
    (set (at tag_bits row) (at top 5))
    (set (at show_of row) (at top 6)))

; a run's start: her six faces (state.items) and the hairball
(fn load_kit () void
    (for k u8 0 state.SLOTS
        (read k (at state.items k) false))
    (read HAIRBALL (catalog.id HAIRBALL) false))

; what she starts with, a slot each: wand, fluff, star, book, curse, then the sixth slot
(const STARTING_ITEMS (array u8 6)
    (make (array u8 6)
        (catalog.id TWIG_WAND)
        (catalog.id FLUFF)
        (catalog.id STAR)
        (catalog.id ZOOMIES)
        (catalog.id FLEAS)
        (catalog.id PLUS)))
