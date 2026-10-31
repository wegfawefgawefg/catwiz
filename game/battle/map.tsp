; the map of the run at the top of the stage, over the cat (pixels 77-104, rows 0-11: kept black
; like a lane, tools/dhgr/lanes.py MAP): the zone's name, a mark for each of its fights (an elite's
; bigger), the one she is on lit, the ones behind her grey, and a crown for the boss. Drawn once
; when a fight starts (and when a page over the stage closes), never during a fight.

(import state)
(import content/encounters enc)
(import draw/pix)
(import draw/screen)
(import draw/scene)

(const G0 u8 11) ; pixel 77
(const GN u8 4)
(const X0 u8 79)
(const ROWS u8 12)
(const MARKS_TOP u8 7)
(const BLACK u8 0)
(const GREY u8 5)
(const LBLUE u8 7)
(const YELLOW u8 13)
(const WHITE u8 15)

(fn colour ((s u8)) u8
    (if (< s state.stage)
        (return GREY))
    (if (= s state.stage)
        (return YELLOW))
    LBLUE)

; row r (0-4) of a mark at x: a small square, an elite's a bigger diamond
(fn mark_row ((x u8) (r u8) (elite bool) (c u8)) void
    (if elite
        (match r
            (0 (pix.dot (+ x 2) c))
            (1 (pix.span (+ x 1) (+ x 4) c))
            (2 (pix.span x (+ x 5) c))
            (3 (pix.span (+ x 1) (+ x 4) c))
            (_ (pix.dot (+ x 2) c)))
        (if (and (>= r 1) (< r 4))
            (pix.span (+ x 1) (+ x 4) c))))

; row r of the crown at x
(fn crown_row ((x u8) (r u8) (c u8)) void
    (match r
        (1
            (pix.dot x c)
            (pix.dot (+ x 2) c)
            (pix.dot (+ x 4) c))
        (2 (pix.span x (+ x 5) c))
        (3 (pix.span x (+ x 5) c))
        (_)))

(fn draw () void
    (let boss u8 (- enc.FIGHT_COUNT 1))
    (let zone enc.Zone (enc.zone state.fight))
    (let name (ptr u8) (at enc.ZONE_NAME (as u8 zone)))
    (let len u8 0)
    (while (!= (load (+ name len)) 0)
        (set len (+ len 1)))
    (pix.begin G0 GN)
    (for y u8 0 ROWS
        (pix.fill BLACK)
        (if (and (>= y 1) (< y 6))
            (pix.glyphs X0 name len (- y 1) WHITE))
        (if (>= y MARKS_TOP)
            (do
                (let r u8 (- y MARKS_TOP))
                (let x u8 X0)
                (for s u8 0 boss
                    (if (= (enc.zone s) zone)
                        (do
                            (mark_row x r (enc.elite s) (colour s))
                            (set x (+ x 6)))))
                (crown_row x r (if (= state.stage boss)
                    YELLOW
                    LBLUE))))
        (pix.write screen.PAGE y))
    (scene.mark (<< G0 1) 0 (<< GN 1) ROWS))
