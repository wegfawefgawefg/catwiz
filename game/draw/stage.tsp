; the screens' art (art/screen_*: on the disks, draw/packs), read when a screen starts: the
; picture onto a page (its table read into blit.sprite_aux, free then: past the hero's runs
; for a fight), then the screen's tables and its blocks' runs (draw/blit). A fight's screen
; is its row of content/encounters' FIGHTS (tools/dhgr/screens.py makes one for each), on the
; second disk; the title's is on both: the first from the boot disk, the later ones (after a
; run) from the second, which a machine with one drive has in then.

(import art/screen_fight1 fight1)
(import art/screen_fight2 fight2)
(import art/screen_fight3 fight3)
(import art/screen_fight4 fight4)
(import art/screen_fight5 fight5)
(import art/screen_fight6 fight6)
(import art/screen_fight7 fight7)
(import art/screen_fight8 fight8)
(import art/screen_fight9 fight9)
(import art/screen_fight10 fight10)
(import art/screen_fight11 fight11)
(import art/screen_title title_art)
(import art/hero)
(import draw/blit)
(import draw/meter)
(import draw/packs)
(import draw/screen)

; the picture whose packs table is table onto page, read at at
(fn picture ((page u8) (table (ptr u8)) (at (ptr u8))) void
    (meter.read at table)
    (screen.unpack_page page (packs.part at 0) (packs.part at 1)))

; the fight screens' tables, by row (in aux memory: read through one with_aux each)
(const PICTURES (array (ptr u8) 11)
    (make (array (ptr u8) 11)
        (addr_of (at fight1.PICTURE 0))
        (addr_of (at fight2.PICTURE 0))
        (addr_of (at fight3.PICTURE 0))
        (addr_of (at fight4.PICTURE 0))
        (addr_of (at fight5.PICTURE 0))
        (addr_of (at fight6.PICTURE 0))
        (addr_of (at fight7.PICTURE 0))
        (addr_of (at fight8.PICTURE 0))
        (addr_of (at fight9.PICTURE 0))
        (addr_of (at fight10.PICTURE 0))
        (addr_of (at fight11.PICTURE 0)))
    :in aux)

(const RUNS (array (ptr u8) 11)
    (make (array (ptr u8) 11)
        (addr_of (at fight1.RUNS 0))
        (addr_of (at fight2.RUNS 0))
        (addr_of (at fight3.RUNS 0))
        (addr_of (at fight4.RUNS 0))
        (addr_of (at fight5.RUNS 0))
        (addr_of (at fight6.RUNS 0))
        (addr_of (at fight7.RUNS 0))
        (addr_of (at fight8.RUNS 0))
        (addr_of (at fight9.RUNS 0))
        (addr_of (at fight10.RUNS 0))
        (addr_of (at fight11.RUNS 0)))
    :in aux)

(fn runs_of ((n u8)) (ptr u8)
    (with_aux true false
        (at RUNS n)))

; fight row n's picture onto page
(fn backdrop ((page u8) (n u8)) void
    (let table (ptr u8) (with_aux true false
        (at PICTURES n)))
    (picture page table (blit.picture_room)))

; fight row n's runs' load, for the meter: its table's sectors and its unpacks (its tables
; and its enemies' halves, about six), and the hero's when they are out
(fn runs_weight ((n u8)) u8
    (let weight u8 (+ (meter.sectors (runs_of n)) (* 7 meter.UNPACK)))
    (if blit.hero_in
        (return weight))
    (+ (+ weight (meter.sectors (addr_of (at hero.RUNS 0)))) (* 5 meter.UNPACK)))

; fight row n's screen's tables and runs, ready to draw
(fn fight_runs ((n u8)) void
    (blit.fight_runs (runs_of n)))

; the title: the boot disk's the first time, the second disk's after a run
(let titles u8 0)

(fn title ((page u8)) void
    (let at (ptr u8) (addr_of (at blit.sprite_aux 0)))
    (if (= titles 0)
        (picture page (addr_of (at title_art.PICTURE 0)) at)
        (picture page (addr_of (at title_art.PICTURE2 0)) at)))

(fn title_runs () void
    (if (= titles 0)
        (blit.title_runs (addr_of (at title_art.RUNS 0)))
        (blit.title_runs (addr_of (at title_art.RUNS2 0))))
    (set titles 1))
