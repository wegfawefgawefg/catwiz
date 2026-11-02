; a card picture (art/icons, packed in aux memory) unpacked into main memory, ICON_BYTES there,
; to be drawn (battle/tray, battle/kit): packed, the pictures take about half the aux memory. A
; charm's (a tile from TILE_CHARMS on) is copied from the spare page's aux memory instead, where
; each fight's art loading puts them (art/charm_pictures, battle.load_art): aux memory is full
(import unpack)
(import auxmem)
(import draw/screen)
(import art/icons)
(import art/charm_pictures charm_art)

(const ICON_ROWS u8 15)

(fn picture ((dst (ptr u8)) (tile u8)) void
    (if (>= tile icons.TILE_CHARMS)
        (do
            (charm dst (- tile icons.TILE_CHARMS))
            (return)))
    (let src (ptr u8) (with_aux true false
        (at icons.PICTURES tile)))
    (unpack.aux_to_main dst src))

; charm k's picture: its band's rows of the spare page from CHARM_ROW, 6 bytes each from 6 k
; (in its band), read in aux memory, into dst in main
(fn charm ((dst (ptr u8)) (k u8)) void
    (let top u8 charm_art.CHARM_ROW)
    (if (>= k charm_art.CHARM_BAND)
        (do
            (set k (- k charm_art.CHARM_BAND))
            (set top (+ top ICON_ROWS))))
    (let col u8 (* k 6))
    (for r u8 0 ICON_ROWS
        (auxmem.read dst (as (ptr u8) (screen.row_at screen.SPARE (+ top r) col)) 6)
        (set dst (+ dst 6))))
