; the hero, and who she meets. A spot is an enemy and the byte column of its sprite's left
; edge (even, so its colours hold).

(import state)
(import content/effects fx)
(import content/enemies en)
(import art/sprites art)

(struct Hero ((hp u8) (figure u8) (col u8) (bark fx.Action))) ; what barking does to the target, once a turn

(const HERO Hero
    (make Hero
        :hp 30
        :figure art.KIND_DOG
        :col 6
        :bark (make fx.Action
            :effect fx.Effect.boo
            :amount 1
            :motion state.Motion.hop
            :aim state.Aim.foe
            :icon '@')))

(struct Spot ((enemy u8) (col u8)))

(const FOREST_SIZE u8 3)

(const FOREST (array Spot 3)
    (make (array Spot 3)
        (make Spot :enemy en.PUFFCAP :col 16)
        (make Spot :enemy en.SPORELET :col 24)
        (make Spot :enemy en.NIGHTFLAP :col 28)))
