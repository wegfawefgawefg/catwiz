; the rules, a page over the stage in her turn (?; battle/page opens and closes it): ten pages of
; text (content/rules), each read from the disk when it comes up (lib/disk) into aux memory's text
; page 1 (free: the game never shows a text page, and the layout never places anything there),
; its lines drawn down the stage, its title in the bottom text. BACK and NEXT in the tray (1-3,
; 4-6), the arrows, a tap on the stage or space turn the pages; ESC, ? or CLOSE closes.

(import apple2 a2)
(import auxmem)
(import disk)
(import state)
(import draw/meter)
(import draw/text)
(import content/rules)
(import sound/sound)

; the page is read into aux memory's text page 1 (state.aux_page1), rules.PAGE_BYTES of it
(const COLUMNS u8 35)

; the page's own lines, in aux memory (main memory is full)
(const SAY_DISK u8 0)
(const SAY_PAGE u8 1)
(const SAY_TURN u8 2)
(const SAY_CLOSE u8 3)

(const SAY (array (ptr u8) 4)
    (make (array (ptr u8) 4)
        "The disk did not read (#)."
        "Page #/"
        "Arrows, BACK or NEXT turn the page."
        "Press ESC, ? or CLOSE to go back.")
    :strings aux)

(let shown u8 0) ; the page shown; the last one read comes up again next time
(let drawn (array u8 15) :address 0x03E1) ; how many blocks of each line the stage shows (scratch: AGENTS.md, Memory)

; the line k (0 the title) of the page read, into text's line
(fn fetch ((k u8)) void
    (text.start)
    (auxmem.read (addr_of (at text.line 0))
        (as (ptr u8) (+ state.aux_page1 (* (as u16 k) (as u16 COLUMNS))))
        (as u16 COLUMNS)))

; page shown read and drawn: its lines down the stage, its title and how to go on in the text
(fn show () void
    (let status u8 (meter.read (as (ptr u8) state.aux_page1) (rules.page_table shown)))
    (if (!= status disk.DONE)
        (do
            (text.start)
            (text.add_aux_n (at SAY SAY_DISK) status)
            (text.show 0)
            (return)))
    ; each line as far as it or the one it replaces reaches (the stage's picture: all of it)
    (for k u8 0 rules.PAGE_LINES
        (fetch (+ k 1))
        (let b u8 (text.blocks))
        (let was u8 (at drawn k))
        (set (at drawn k) b)
        (text.draw_at (<< k 3) (if (> was b)
            was
            b)))
    (fetch 0)
    (text.tab 25)
    (text.add_aux_n (at SAY SAY_PAGE) (+ shown 1))
    (text.number rules.PAGE_COUNT)
    (text.show 0)
    (text.start)
    (text.show 1)
    (text.add_aux (at SAY SAY_TURN))
    (text.show 2)
    (text.start)
    (text.add_aux (at SAY SAY_CLOSE))
    (text.show 3))

(fn open () void
    (for k u8 0 rules.PAGE_LINES
        (set (at drawn k) text.BLOCKS))
    (show))

; the page one way (1) or the other (255): a blip and the page, or a nope at either end
(fn turn ((way u8)) void
    (let next u8 (+ shown way))
    (if (>= next rules.PAGE_COUNT)
        (do
            (sound.cue sound.Cue.nope)
            (return)))
    (sound.cue sound.Cue.blip)
    (set shown next)
    (show))

; a key on the page; gives true to close it
(fn key ((k u8)) bool
    (if (and (>= k '1') (<= k '3'))
        (do
            (turn 255)
            (return false)))
    (if (and (>= k '4') (<= k '6'))
        (do
            (turn 1)
            (return false)))
    (match k
        (0 false)
        (a2.KEY_LEFT
            (turn 255)
            false)
        (a2.KEY_RIGHT
            (turn 1)
            false)
        (a2.KEY_ESC true)
        ('?' true)
        (_
            (match (& k 0xDF)
                ('B' true)
                ('R' true)
                ('E' true)
                (_
                    ; a tap on the stage (M Z X C .), space, RETURN: the next page
                    (turn 1)
                    false)))))
