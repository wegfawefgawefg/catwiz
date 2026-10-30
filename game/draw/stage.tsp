; the screens' pictures (art/, packed in aux memory), unpacked onto the backdrop page when a
; screen starts: the fights' backdrops by number (content/encounters' backdrop) and the title.

(import art/fight1_aux)
(import art/fight1_main)
(import art/fight2_aux)
(import art/fight2_main)
(import art/title_aux)
(import art/title_main)
(import draw/screen)

; fight backdrop n: 0 the clearing, 1 the path
(fn backdrop ((n u8)) void
    (match n
        (0
            (screen.unpack_page screen.BACKDROP
                (addr_of (at fight1_aux.picture 0))
                (addr_of (at fight1_main.picture 0))))
        (_
            (screen.unpack_page screen.BACKDROP
                (addr_of (at fight2_aux.picture 0))
                (addr_of (at fight2_main.picture 0))))))

(fn title () void
    (screen.unpack_page screen.BACKDROP
        (addr_of (at title_aux.picture 0))
        (addr_of (at title_main.picture 0))))
