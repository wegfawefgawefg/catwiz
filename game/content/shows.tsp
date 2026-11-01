; how each card's play looks on the stage (the owner, 2026-11-01: a new card's look is data too, a
; few frames like the bolt, never one to skip). A card names its show in its row of
; content/cards.tsp CARDS; battle/act.tsp plays it. A show is a small sprite or two (art/sprites,
; drawn in tools/dhgr/game_sprites.py SHOWS) and the way they go:
;   ARC  thrown from her along the bolt's arc to whoever the card is for, a and b by turns
;   ON   played over whoever the card is for: a step every 2 frames at the path's places
;        (PATH_COL byte columns from its spot's left, PATH_ROW rows down from its top), a and b
;        by turns; the effect lands after the last step
; and its flags: ANGRY (whoever it is for shows its angry face meanwhile). NONE: an ON show
; with no steps, her own card's plain hop (and the meow). A show takes no longer than what it
; replaces: her own cards' 3 steps are the hop's 6 frames, the rest land before the bolt would.
;
; The places stay inside the idle frame of whoever the show is for, where the stage is always
; black (tools/dhgr/lanes.py), and ARC sprites are no bigger than the bolt. Keep ON paths near the top of the figure: the figure is drawn again down to
; where the sprite was, each step.

(import state)
(import art/sprites art)

(const ARC u8 0)
(const ON u8 1)
(const ANGRY u8 1)
(const FOE u8 2)  ; a and b are roles of the mover's kind (an enemy's move: its shot, shot2)
(const SHOT u8 7) ; the roles (battle/look ROLE_SHOT, ROLE_SHOT2)
(const SHOT2 u8 8)

(struct Show ((way u8) (a u8) (b u8) (first u8) (steps u8) (flags u8)))

(const BOLT u8 0)
(const RED_DOT u8 1)
(const MIMIC u8 2)
(const CATFIGHT u8 3)
(const MIRROR u8 4)
(const LUCKY_PAW u8 5)
(const FLEAS u8 6)
(const SUNBEAM u8 7)
(const CLAWS u8 8)
(const COIN u8 9)
(const NONE u8 10)
(const SPRAY u8 11)
(const STREAK u8 12)
(const PUFF u8 13)
(const ACORN u8 14)
(const SNATCH u8 15)
(const BITE u8 16)
(const SMACK u8 17)

(const SHOWS (array Show 18)
    (make (array Show 18)
        ; the bolt: a wand's spark (and an enemy's shot)
        (make Show :way ARC :a art.BOLT :b art.BOLT :first 0 :steps 0 :flags 0)
        ; a red dot skitters about its face
        (make Show :way ON :a art.DOT0 :b art.DOT1 :first 0 :steps 5 :flags 0)
        ; a mask of its face flies at it
        (make Show :way ARC :a art.MASK :b art.MASK :first 0 :steps 0 :flags 0)
        ; a paw rakes it, and it scowls, spoiling for a fight
        (make Show :way ON :a art.CLAW0 :b art.CLAW1 :first 5 :steps 4 :flags ANGRY)
        ; a glint runs down her fur
        (make Show :way ON :a art.SHINE :b art.SHINE :first 9 :steps 3 :flags 0)
        ; a lucky paw waves by her
        (make Show :way ON :a art.PAW0 :b art.PAW1 :first 12 :steps 3 :flags 0)
        ; fleas hop across to it
        (make Show :way ARC :a art.FLEA :b art.FLEA :first 0 :steps 0 :flags 0)
        ; a sunbeam comes down on her
        (make Show :way ON :a art.BEAM :b art.BEAM :first 15 :steps 3 :flags 0)
        ; claws rake it, three strokes
        (make Show :way ON :a art.CLAW0 :b art.CLAW1 :first 18 :steps 4 :flags 0)
        ; a coin flips over her paw
        (make Show :way ON :a art.COIN0 :b art.COIN1 :first 22 :steps 3 :flags 0)
        ; none: a plain hop
        (make Show :way ON :a art.BOLT :b art.BOLT :first 0 :steps 0 :flags 0)
        ; a squirt of water flies at it (the spray bottle, wet)
        (make Show :way ARC :a art.DROP :b art.DROP :first 0 :steps 0 :flags 0)
        ; she streaks across at it (zoomies)
        (make Show :way ARC :a art.STREAK :b art.STREAK :first 0 :steps 0 :flags 0)
        ; a curse puffs up on it
        (make Show :way ON :a art.POOF1 :b art.POOF1 :first 25 :steps 2 :flags 0)
        ; ---- the enemies' moves' (content/move_looks): their own sprites, FOE
        ; the squirrel's acorn, thrown
        (make Show :way ARC :a SHOT :b SHOT :first 0 :steps 0 :flags FOE)
        ; the squirrel snatches a die off her: it flies out of her paws
        (make Show :way ON :a SHOT2 :b SHOT2 :first 27 :steps 3 :flags FOE)
        ; the possum's bite: teeth marks
        (make Show :way ON :a SHOT :b SHOT :first 30 :steps 3 :flags FOE)
        ; the possum's cheap shot: a smack's star
        (make Show :way ON :a SHOT :b SHOT :first 33 :steps 3 :flags FOE))
    :in aux)

; the ON shows' places, a show's steps one after another: byte columns from the left of the
; spot of whoever it is for (even: a sprite's colours hold only on 7-pixel steps), rows from its
; top. Keep a sprite inside the narrowest spot it can be for: an enemy's is 8 columns at least
; (the sporelet), hers 10
(const PATH_COL (array u8 36)
    (make (array u8 36)
        2 4 2 0 4 ; red dot
        2 0 4 2   ; catfight
        2 4 6     ; mirror fur
        8 8 8     ; lucky paw
        4 4 4     ; sunbeam
        0 2 4 2   ; claws
        6 6 6     ; coin
        0 2       ; puff
        6 8 8     ; snatch (over her: the die out of her paw, away to the right)
        4 6 4     ; bite
        6 4 6)    ; smack
    :in aux)

(const PATH_ROW (array u8 36)
    (make (array u8 36)
        10 4 14 18 8 ; red dot
        4 8 6 10     ; catfight
        10 18 26     ; mirror fur
        40 38 40     ; lucky paw
        0 6 12       ; sunbeam
        2 6 10 8     ; claws
        30 16 28     ; coin
        6 2          ; puff
        50 42 34     ; snatch
        40 46 52     ; bite
        34 38 32)    ; smack
    :in aux)

; show k's row into the action's copy of it (state.show_*), read out of aux memory as the action
; starts
(fn start ((k u8)) void
    (with_aux true false
        (set state.show_way (at SHOWS k way))
        (set state.show_a (at SHOWS k a))
        (set state.show_b (at SHOWS k b))
        (set state.show_first (at SHOWS k first))
        (set state.show_steps (at SHOWS k steps))
        (set state.show_flags (at SHOWS k flags))))

; step i of the paths: its byte columns from the middle and rows from the top, into
; state.show_col and show_row
(fn place ((i u8)) void
    (with_aux true false
        (set state.show_col (at PATH_COL i))
        (set state.show_row (at PATH_ROW i))))
