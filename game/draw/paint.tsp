; a card picture into main memory, ICON_BYTES there, to be drawn (battle/tray, battle/kit): a
; tile below icons.FIRST is a row of the faces and charms in play (content/items), its picture
; copied from its record in aux memory; the others (a door, a grabbed die) are art/icons',
; packed in aux memory and unpacked
(import unpack)
(import auxmem)
(import art/icons)
(import content/items)

(fn picture ((dst (ptr u8)) (tile u8)) void
    (if (< tile icons.FIRST)
        (do
            (auxmem.read dst (items.picture tile) icons.ICON_BYTES)
            (return)))
    (let src (ptr u8) (with_aux true false
        (at icons.PICTURES (- tile icons.FIRST))))
    (unpack.aux_to_main dst src))
