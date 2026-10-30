; the battle's moving picture: idle bobs and wing flaps, faces, flashes, knockback, the death
; blink and poof, the floating numbers; then what each look should show this frame
; (state.looks), for draw/scene.tsp to bring the page up to date.

(import state)
(import art/sprites art)
(import battle/place)

(const BLINK_UNTIL u8 16) ; dying: blinking above this, then the two puffs
(const POOF_SWITCH u8 8)

; one frame of the ambient motion; everything holds still during hit-stop
(fn tick () void
    (if (> state.hitstop 0)
        (do
            (set state.hitstop (- state.hitstop 1))
            (return)))
    (set state.frame (+ state.frame 1))
    ; idle motion only while waiting for a key, so it never slows an action down
    (if (= state.phase state.Phase.player)
        (set state.idle (+ state.idle 1)))
    (for i u8 0 state.ACTORS
        (tick_actor i))
    (for i u8 0 state.FLOATERS
        (let time u8 (at state.floaters i time))
        (if (> time 0)
            (do
                (set (at state.floaters i time) (- time 1))
                ; rise fast, then slow down near the end
                (if (or (> time 12) (= (& time 1) 0))
                    (set (at state.floaters i top) (- (at state.floaters i top) 1)))))))

(fn tick_actor ((i u8)) void
    (if (> (at state.actors i flash) 0)
        (set (at state.actors i flash) (- (at state.actors i flash) 1)))
    (if (> (at state.actors i knock) 0)
        (set (at state.actors i knock) (- (at state.actors i knock) 1)))
    (if (> (at state.actors i dying) 0)
        (set (at state.actors i dying) (- (at state.actors i dying) 1)))
    (if (> (at state.actors i mood_time) 0)
        (do
            (set (at state.actors i mood_time) (- (at state.actors i mood_time) 1))
            (if (= (at state.actors i mood_time) 0)
                (set (at state.actors i mood) (resting_mood i))))))

; the face who shows when nothing has just happened to it
(fn resting_mood ((who u8)) state.Mood
    (let low bool
        (<= (* (as u16 (at state.actors who hp)) 3) (as u16 (at state.actors who max_hp))))
    (if (= who state.DOG)
        (do
            (if (= state.phase state.Phase.won)
                (return state.Mood.happy))
            (if (not (at state.actors who alive))
                (return state.Mood.ko))
            (if low
                (return state.Mood.worried))
            (return state.Mood.idle)))
    (if low
        (return state.Mood.worried))
    state.Mood.angry)

; a temporary face for frames frames
(fn show_mood ((who u8) (mood state.Mood) (frames u8)) void
    (set (at state.actors who mood) mood)
    (set (at state.actors who mood_time) frames))

; ---- the looks

(fn hide ((i u8)) void
    (set (at state.looks i)
        (make state.Look
            :sprite state.NOTHING
            :col 0
            :top 0
            :second state.NOTHING
            :second_col 0
            :second_top 0
            :white false
            :swaps false
            :face_on_body false)))

(fn show ((i u8) (sprite u8) (col u8) (top u8)) void
    (set (at state.looks i)
        (make state.Look
            :sprite sprite
            :col col
            :top top
            :second state.NOTHING
            :second_col 0
            :second_top 0
            :white false
            :swaps false
            :face_on_body false)))

; the bob, 0 or 1 pixel (more for flyers), each actor on its own beat; the dog, the biggest
; to redraw, breathes slowest
(fn bob ((i u8)) u8
    (let beat u8 (+ state.idle (* i 11)))
    (if (= i state.DOG)
        (return (& (>> beat 5) 1)))
    (if (!= (at art.KIND_FLAP (at state.actors i figure)) art.NONE)
        (do
            ; flyers (kinds with a wing frame) drift 0, 1, 2, 1 pixels, flapping on the same beat
            (let drift u8 (& (>> beat 4) 3))
            (return (if (= drift 3)
                1
                drift))))
    (& (>> beat 4) 1))

(fn show_actor ((i u8)) void
    (let figure u8 (at state.actors i figure))
    (let dying u8 (at state.actors i dying))
    ; a beaten enemy is gone once it has puffed away; the dog stays down
    (if (and (and (not (at state.actors i alive)) (= dying 0)) (!= i state.DOG))
        (do
            (hide i)
            (return)))
    (let col u8 (at state.actors i col))
    ; knocked back 2 columns, unless that would leave the screen
    (if (> (at state.actors i knock) 0)
        (do
            (let knocked u8 (as u8 (- (as i8 col) (* (place.facing i) 2))))
            (if (and (< knocked 250) (<= (+ knocked (at art.KIND_COLS figure)) 40))
                (set col knocked))))
    (let top u8 (- (- (place.top i) (at state.actors i lift)) (bob i)))
    ; dying: blink, then puff away
    (if (and (> dying 0) (<= dying BLINK_UNTIL))
        (do
            (let poof u8 (if (> dying POOF_SWITCH)
                art.POOF0
                art.POOF1))
            (let pcol u8 (- (place.middle i) (>> (at art.SPRITE_W poof) 1)))
            (let ptop u8 (+ top (>> (at art.SPRITE_H (at art.KIND_BODY figure)) 2)))
            (show i poof (& pcol 0xFE) ptop)
            (return)))
    (if (and (> dying 0) (= (& (>> dying 2) 1) 0))
        (do
            (hide i)
            (return)))
    (let body u8 (at art.KIND_BODY figure))
    (let flap u8 (at art.KIND_FLAP figure))
    (if (and (!= flap art.NONE) (= (& (>> (+ state.idle (* i 11)) 4) 1) 1))
        (set body flap))
    (let mood_row u8 (+ (* figure art.MOOD_COUNT) (as u8 (at state.actors i mood))))
    (set (at state.looks i)
        (make state.Look
            :sprite body
            :col col
            :top top
            :second (at art.KIND_PATCH mood_row)
            :second_col (+ col (at art.KIND_PATCH_DX mood_row))
            :second_top (+ top (at art.KIND_PATCH_DY mood_row))
            :white (> (at state.actors i flash) 0)
            :swaps (= (at art.KIND_PATCH_SWAPS mood_row) 1)
            :face_on_body (= (at state.actors i mood) state.Mood.idle))))

; every look for this frame
(fn update () void
    (for i u8 0 state.ACTORS
        (show_actor i))
    (hide state.LOOK_BOLT)
    (if state.bolt_on
        (show state.LOOK_BOLT art.BOLT state.bolt_col state.bolt_top))
    (hide state.LOOK_MARKER)
    (if (= state.phase state.Phase.player)
        (do
            (let t u8 state.target)
            (let top u8 (- (place.top t) 30))
            (if (= (& (>> state.idle 4) 1) 1)
                (set top (+ top 2)))
            (show state.LOOK_MARKER art.MARKER (- (place.middle t) 2) top)))
    (for i u8 0 state.FLOATERS
        (let look u8 (+ state.LOOK_FLOATER i))
        (hide look)
        (if (> (at state.floaters i time) 0)
            (do
                (let col u8 (at state.floaters i col))
                (let top u8 (at state.floaters i top))
                (show look (at state.floaters i sprite) col top)
                (if (!= (at state.floaters i second) state.NOTHING)
                    (do
                        (set (at state.looks look second) (at state.floaters i second))
                        (set (at state.looks look second_col) (+ col 2))
                        (set (at state.looks look second_top) top)))))))
