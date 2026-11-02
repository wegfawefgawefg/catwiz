; the draws between fights: five different faces (or upgrades) from the faces' pool, or three
; charms from the charms' pool, each by its weight among the ones that can come (docs/faces.md:
; no gates by fight), with the run's random numbers (lib/random, seeded at the title). The pools
; are on disk 2 (content/catalog FACE_POOL, CHARM_POOL, from the rows' weights), read into the
; offer's scratch (content/items) as a draw starts. A face comes once a draw, and only as it could
; be taken: a level (an upgrade, or the face she holds: the same card to a draw) only on a slot
; below items.ITEM_MOST. A charm comes once a draw, when she holds none.

(import random)
(import state)
(import auxmem)
(import content/catalog)
(import content/charms)
(import content/items)
(import draw/meter)

(const UP u8 128) ; a card of 128 + a slot: a level on that slot, whatever is on it
(const FACES_DRAWN u8 5)
(const CHARMS_DRAWN u8 3)

; what the last draw gave: each card (a face's id, UP + a slot, or a charm's id) and its slot
(let drawn (array u8 5) :address 0x0168) ; scratch: AGENTS.md, Memory
(let drawn_slot (array u8 5) :address 0x016D)
(let count u8 0)

; whether card c (on slot) is a level (else a new face there)
(fn levels ((c u8) (slot u8)) bool
    (or (>= c UP) (= (at state.items slot) c)))

; whether card c (on slot) can be taken: a level only below items.ITEM_MOST
(fn ok ((c u8) (slot u8)) bool
    (if (not (levels c slot))
        (return true))
    (< (at state.levels slot) items.ITEM_MOST))

; what card c gives, so a draw has each once: a level on a slot (an upgrade, or the face she
; holds: the same) as UP and the slot, a new face as itself; a charm as itself
(fn what ((c u8) (slot u8) (of_charms bool)) u8
    (if (or of_charms (not (levels c slot)))
        (return c))
    (+ UP slot))

; the pool read (aux memory, in the offer's scratch): its count first, then rows of 3 bytes (a
; face's id or UP + a slot, its weight, its slot) or 2 (a charm's id, its weight)
(fn pool_byte ((i u8)) u8
    (let p (ptr u8) (+ (items.scratch) (as u16 i)))
    (with_aux true false
        (load p)))

(fn row_at ((of_charms bool) (k u8)) u8
    (if of_charms
        (return (+ 1 (<< k 1))))
    (+ 1 (+ k (<< k 1))))

(fn card_at ((of_charms bool) (k u8)) u8
    (pool_byte (row_at of_charms k)))

(fn slot_at ((of_charms bool) (k u8)) u8
    (if of_charms
        (return 0))
    (pool_byte (+ (row_at of_charms k) 2)))

; row k's weight, 0 when it cannot come now
(fn weight ((of_charms bool) (k u8)) u8
    (let c u8 (card_at of_charms k))
    (let slot u8 (slot_at of_charms k))
    (for i u8 0 count
        (if (= (what (at drawn i) (at drawn_slot i) of_charms) (what c slot of_charms))
            (return 0)))
    (if of_charms
        (if (!= (charms.holding c) state.NOTHING)
            (return 0))
        (if (not (ok c slot))
            (return 0)))
    (pool_byte (+ (row_at of_charms k) 1)))

; a random number below n (1 on): a random u16 cut to the bits n needs, again until it is below
; n (no division routine)
(fn below ((n u16)) u16
    (let bits u16 1)
    (while (< bits n)
        (set bits (| (<< bits 1) 1)))
    (while true
        (let r u16 (& (| (as u16 (random.byte)) (<< (as u16 (random.byte)) 8)) bits))
        (if (< r n)
            (return r)))
    0)

; five faces (or three charms) into drawn, each by its weight among those that can come; gives
; how many (battle/reward reads their records into the offer's rows as it shows them)
(fn draw ((of_charms bool)) u8
    (meter.read (items.scratch) (if of_charms
        (addr_of (at catalog.CHARM_POOL 0))
        (addr_of (at catalog.FACE_POOL 0))))
    (let rows u8 (pool_byte 0))
    (set count 0)
    (for n u8 0 (if of_charms
            CHARMS_DRAWN
            FACES_DRAWN)
        (let total u16 0)
        (for k u8 0 rows
            (set total (+ total (as u16 (weight of_charms k)))))
        (if (= total 0)
            (break))
        (let r u16 (below total))
        (let k u8 0)
        (while true
            (let w u16 (as u16 (weight of_charms k)))
            (if (< r w)
                (break))
            (set r (- r w))
            (set k (+ k 1)))
        (set (at drawn count) (card_at of_charms k))
        (set (at drawn_slot count) (slot_at of_charms k))
        (set count (+ count 1)))
    count)
