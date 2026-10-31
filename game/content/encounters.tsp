; the hero, the run's fights in order, and the rewards after a fight. A spot is an enemy and the
; byte column of its sprite's left edge (even, so its colours hold).

(import content/enemies en)
(import content/faces)
(import art/sprites art)

(struct Hero ((name (ptr u8)) (hp u8) (figure u8) (col u8)))

(const HERO Hero (make Hero :name "Catwiz" :hp 30 :figure art.KIND_CAT :col 4))

(struct Spot ((enemy u8) (col u8)))

; a fight: its backdrop (a screen of art/: 0 the clearing, 1 the path), its enemies and where
(struct Fight ((backdrop u8) (count u8) (spots (array Spot 3))))

(const FIGHT_COUNT u8 2)

(const FIGHTS (array Fight 2)
    (make (array Fight 2)
        (make Fight
            :backdrop 0
            :count 2
            :spots (make (array Spot 3)
                (make Spot :enemy en.PUFFCAP :col 20)
                (make Spot :enemy en.SPORELET :col 32)
                (make Spot :enemy en.PUFFCAP :col 0)))
        (make Fight
            :backdrop 1
            :count 3
            :spots (make (array Spot 3)
                (make Spot :enemy en.PUFFCAP :col 20)
                (make Spot :enemy en.SPORELET :col 32)
                (make Spot :enemy en.NIGHTFLAP :col 26)))))

; after a fight, pick one of three: a new die in place of one of yours, the other new die, or
; one face of yours upgraded (faces.FACES upgrade)
(const OFFER_DICE (array faces.Die 2)
    (make (array faces.Die 2)
        (make faces.Die
            :name "SCREAM DIE"
            :faces (make (array u8 6)
                faces.SCREAM faces.STAR faces.STAR_2 faces.BOX faces.WAND_2 faces.BATH))
        (make faces.Die
            :name "GOLD WAND DIE"
            :faces (make (array u8 6)
                faces.WAND_3 faces.WAND_3 faces.WAND_3 faces.WAND_4 faces.STAR faces.PLUS_1))))
