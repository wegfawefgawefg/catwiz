; the screens' art (art/screen_*: on the disk, draw/packs), read when a screen starts: the
; picture onto a page (its table read into blit.sprite_aux, free then: the runs are unpacked
; there after it), then its kinds' runs (draw/blit). The fights' screens by number (content/
; encounters' backdrop: 0 the clearing, 1 the path, 2 the clearing with the old shroom, the
; woods' elite), and the title.

(import disk)
(import art/screen_fight1 fight1)
(import art/screen_fight2 fight2)
(import art/screen_fight3 fight3)
(import art/screen_title title_art)
(import draw/blit)
(import draw/packs)
(import draw/screen)

; the picture whose packs table is table onto page
(fn picture ((page u8) (table (ptr u8))) void
    (let at (ptr u8) (addr_of (at blit.sprite_aux 0)))
    (disk.read at table disk.AUX)
    (screen.unpack_page page (packs.part at 0) (packs.part at 1)))

; the fight screens' tables, by number
(const PICTURES (array (ptr u8) 3)
    (make (array (ptr u8) 3)
        (addr_of (at fight1.PICTURE 0))
        (addr_of (at fight2.PICTURE 0))
        (addr_of (at fight3.PICTURE 0))))

(const RUNS (array (ptr u8) 3)
    (make (array (ptr u8) 3)
        (addr_of (at fight1.RUNS 0))
        (addr_of (at fight2.RUNS 0))
        (addr_of (at fight3.RUNS 0))))

(const KINDS (array (ptr u8) 3)
    (make (array (ptr u8) 3)
        (addr_of (at fight1.KINDS 0))
        (addr_of (at fight2.KINDS 0))
        (addr_of (at fight3.KINDS 0))))

(fn backdrop ((page u8) (n u8)) void
    (picture page (at PICTURES n)))

; fight screen n's kinds' runs, ready to draw (each screen has 4 kinds)
(fn fight_runs ((n u8)) void
    (blit.unpack_all (at RUNS n) (at KINDS n) 4))

(fn title ((page u8)) void
    (picture page (addr_of (at title_art.PICTURE 0))))

(fn title_runs () void
    (blit.unpack_all (addr_of (at title_art.RUNS 0)) (addr_of (at title_art.KINDS 0)) 1))
