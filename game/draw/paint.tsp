; a card picture (art/icons, packed in aux memory) unpacked into main memory, ICON_BYTES there,
; to be drawn (battle/tray, battle/kit): packed, the pictures take about half the aux memory
(import unpack)
(import art/icons)

(fn picture ((dst (ptr u8)) (tile u8)) void
    (let src (ptr u8) (with_aux true false
        (at icons.PICTURES tile)))
    (unpack.aux_to_main dst src))
