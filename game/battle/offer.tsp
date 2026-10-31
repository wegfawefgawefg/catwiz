; the draws between fights: three different cards from enc.OFFER_CARDS, or three charms from
; enc.OFFER_CHARMS, each by its weight among the ones that can come after this fight, with the
; run's random numbers (lib/random, seeded at the title). A card can come from its fight on, once a
; draw, and only as it could be taken: a level (an upgrade, or the item she holds: the same card
; to a draw) only on a slot below items.ITEM_MOST. A charm can come from its fight on, once a
; draw, when she holds none.

(import random)
(import state)
(import content/encounters enc)
(import content/items)

(const UP u8 128) ; a card of 128 + a slot: a level on that slot (enc.UP_WAND ...)
(const DRAW u8 3)

; what the last draw gave, and how many
(let drawn (array u8 3))
(let count u8 0)

; the slot card c goes to, and whether it is a level (else a new item there)
(fn card_slot ((c u8)) u8
    (if (>= c UP)
        (return (- c UP)))
    (as u8 (at items.ITEMS c slot)))

(fn card_levels ((c u8)) bool
    (or (>= c UP) (= (at state.items (card_slot c)) c)))

; what card c gives, so a draw has each once: a level on a slot (an upgrade, or the item she
; holds: the same) as UP and the slot, a new item as itself; a charm as itself
(fn what ((c u8) (charms bool)) u8
    (if (or charms (not (card_levels c)))
        (return c))
    (+ UP (card_slot c)))

; whether card c can be taken: a level only below items.ITEM_MOST
(fn card_ok ((c u8)) bool
    (if (not (card_levels c))
        (return true))
    (< (at state.levels (card_slot c)) items.ITEM_MOST))

; row k of the pool: the charms' or the cards'
(fn pool_size ((charms bool)) u8
    (if charms
        (return enc.OFFER_CHARM_COUNT))
    enc.OFFER_CARD_COUNT)

; row k of the pool, copied out of aux memory (enc's OFFER tables are :in aux)
(fn card_at ((charms bool) (k u8)) u8
    (with_aux true false
        (if charms
            (at enc.OFFER_CHARMS k card)
            (at enc.OFFER_CARDS k card))))

; row k's weight, 0 when it cannot come now
(fn weight ((charms bool) (k u8)) u8
    (let from u8 (with_aux true false
        (if charms
            (at enc.OFFER_CHARMS k from)
            (at enc.OFFER_CARDS k from))))
    (if (> from (+ state.stage 1))
        (return 0))
    (let c u8 (card_at charms k))
    (for i u8 0 count
        (if (= (what (at drawn i) charms) (what c charms))
            (return 0)))
    (if charms
        (if (> (at state.charms c) 0)
            (return 0))
        (if (not (card_ok c))
            (return 0)))
    (with_aux true false
        (if charms
            (at enc.OFFER_CHARMS k weight)
            (at enc.OFFER_CARDS k weight))))

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

; up to three into drawn, each by its weight among those that can come; gives how many
(fn draw ((charms bool)) u8
    (set count 0)
    (for n u8 0 DRAW
        (let total u16 0)
        (for k u8 0 (pool_size charms)
            (set total (+ total (as u16 (weight charms k)))))
        (if (= total 0)
            (return count))
        (let r u16 (below total))
        (let k u8 0)
        (while true
            (let w u16 (as u16 (weight charms k)))
            (if (< r w)
                (break))
            (set r (- r w))
            (set k (+ k 1)))
        (set (at drawn count) (card_at charms k))
        (set count (+ count 1)))
    count)
