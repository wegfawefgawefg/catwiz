; the battle's moving picture: idle bobs and wing flaps, faces, flashes, knockback, the death
; blink and poof, the floating numbers; then what each look should show this frame
; (state.looks), for draw/scene.tsp to bring the page up to date. The badges' looks are the
; hud's (battle/hud.tsp).
;
; a mood shows as one of the kind's frames (art.KIND_FRAME by role: idle, attack, hurt, happy,
; surprised, flap); a kind without that frame shows its idle one.

(import state)
(import art/sprites art)
(import battle/place)
(import content/enemies en)

(const BLINK_UNTIL u8 16) ; dying: blinking above this, then the two puffs
(const POOF_SWITCH u8 8)
(const ROLE_IDLE u8 0)
(const ROLE_ATTACK u8 1)
(const ROLE_HURT u8 2)
(const ROLE_HAPPY u8 3)
(const ROLE_SURPRISED u8 4)
(const ROLE_FLAP u8 5)
(const ROLE_FLASH u8 6) ; a solid kind's white shape, for the hit flash

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
    (if (= who state.HERO)
        (do
            (if (= state.phase state.Phase.won)
                (return state.Mood.happy))
            (if (not (at state.actors who alive))
                (return state.Mood.ko))))
    state.Mood.idle)

; a temporary face for frames frames
(fn show_mood ((who u8) (mood state.Mood) (frames u8)) void
    (set (at state.actors who mood) mood)
    (set (at state.actors who mood_time) frames))

; the role a mood shows as
(fn role ((mood state.Mood)) u8
    (match mood
        (state.Mood.attack ROLE_ATTACK)
        (state.Mood.angry ROLE_ATTACK)
        (state.Mood.hurt ROLE_HURT)
        (state.Mood.ko ROLE_HURT)
        (state.Mood.happy ROLE_HAPPY)
        (state.Mood.surprised ROLE_SURPRISED)
        (_ ROLE_IDLE)))

; the sprite kind shows for role, its idle frame when it has none for it
(fn frame ((kind u8) (r u8)) u8
    (let id u8 (at art.KIND_FRAME (+ (* kind art.ROLE_COUNT) r)))
    (if (= id art.NONE)
        (return (at art.KIND_FRAME (* kind art.ROLE_COUNT))))
    id)

; ---- the looks

(fn hide ((i u8)) void
    (set (at state.looks i)
        (make state.Look
            :sprite state.NOTHING
            :col 0
            :top 0
            :second state.NOTHING
            :white false
            :wide 0)))

(fn show ((i u8) (sprite u8) (col u8) (top u8)) void
    (set (at state.looks i)
        (make state.Look
            :sprite sprite
            :col col
            :top top
            :second state.NOTHING
            :white false
            :wide 0)))

; the bob: flyers (kinds with a wing frame) drift 0, 1, 2, 1 pixels, flapping on the same beat,
; each on its own beat. The ones standing stand still: drawing a sprite again in double hi-res
; costs about as much as a frame, so a bob a second each would take a fifth of the time
(fn bob ((i u8)) u8
    (if (= (at art.KIND_FRAME (+ (* (at state.actors i figure) art.ROLE_COUNT) ROLE_FLAP)) art.NONE)
        (return 0))
    (let drift u8 (& (>> (+ state.idle (* i 11)) 4) 3))
    (if (= drift 3)
        1
        drift))

(fn show_actor ((i u8)) void
    (let kind u8 (at state.actors i figure))
    (let dying u8 (at state.actors i dying))
    ; a beaten enemy is gone once it has puffed away; the hero stays down
    (if (and (and (not (at state.actors i alive)) (= dying 0)) (!= i state.HERO))
        (do
            (hide i)
            (return)))
    (let col u8 (at state.actors i col))
    ; knocked back 2 columns, unless that would leave the screen
    (if (> (at state.actors i knock) 0)
        (do
            (let knocked u8 (as u8 (- (as i8 col) (* (place.facing i) 2))))
            (if (and (< knocked 250) (<= (+ knocked (at art.KIND_COLS kind)) 40))
                (set col knocked))))
    (let top u8 (- (- (place.top i) (at state.actors i lift)) (bob i)))
    ; dying: blink, then puff away
    (if (and (> dying 0) (<= dying BLINK_UNTIL))
        (do
            (let poof u8 (if (> dying POOF_SWITCH)
                art.POOF0
                art.POOF1))
            (let pcol u8 (- (place.middle i) (>> (at art.COLS poof) 1)))
            (let ptop u8 (+ top (>> (- (place.feet i) (place.top i)) 2)))
            (show i poof (& pcol 0xFE) ptop)
            (return)))
    (if (and (> dying 0) (= (& (>> dying 2) 1) 0))
        (do
            (hide i)
            (return)))
    (let r u8 (role (at state.actors i mood)))
    (if (and (= r ROLE_IDLE) (= (& (>> (+ state.idle (* i 11)) 4) 1) 1))
        (set r ROLE_FLAP))
    ; the flash: a solid kind shows its white frame (a solid frame drawn white would be a white
    ; box), the others their frame drawn white
    (let white bool (> (at state.actors i flash) 0))
    (if (and white (has_flash kind))
        (do
            (set r ROLE_FLASH)
            (set white false)))
    (let id u8 (frame kind r))
    (show i id (as u8 (+ (as i8 col) (at art.DCOL id))) (as u8 (+ (as i8 top) (at art.DTOP id))))
    (set (at state.looks i white) white))

; whether kind has a white frame for the flash
(fn has_flash ((kind u8)) bool
    (if (<= art.ROLE_COUNT ROLE_FLASH)
        (return false))
    (!= (at art.KIND_FRAME (+ (* kind art.ROLE_COUNT) ROLE_FLASH)) art.NONE))

; marker k over who's head (over its intent badge), bob rows down
(fn marker ((k u8) (who u8) (bob u8)) void
    (let top u8 (if (= who state.HERO)
        8
        (- (place.top who) 25)))
    (show (+ state.LOOK_MARKER k) art.MARKER (& (- (place.middle who) 2) 0xFE) (+ top bob)))

; on the hero's turn, arrows over whoever the die picked goes to, bobbing: the target, the hero
; for her own faces, every enemy for a hit-all. With no die picked, a still arrow over the
; enemy the bottom text describes
(fn markers ((aim state.Aim)) void
    (if (= state.selected state.NOTHING)
        (do
            (marker 0 state.target 0)
            (return)))
    (let bob u8 (& (>> state.idle 3) 2))
    (match aim
        (state.Aim.self (marker 0 state.HERO bob))
        (state.Aim.all
            (let k u8 0)
            (for i u8 1 state.ACTORS
                (if (at state.actors i alive)
                    (do
                        (marker k i bob)
                        (set k (+ k 1))))))
        (_ (marker 0 state.target bob))))

; every look for this frame but the badges; aim is the picked die's
(fn update ((aim state.Aim)) void
    (for i u8 0 state.ACTORS
        (show_actor i))
    (hide state.LOOK_BOLT)
    (if state.bolt_on
        (show state.LOOK_BOLT art.BOLT state.bolt_col state.bolt_top))
    (for k u8 0 state.MARKERS
        (hide (+ state.LOOK_MARKER k)))
    (if (= state.phase state.Phase.player)
        (markers aim))
    (for i u8 0 state.FLOATERS
        (let look u8 (+ state.LOOK_FLOATER i))
        (hide look)
        (if (> (at state.floaters i time) 0)
            (do
                (show look
                    (at state.floaters i sprite)
                    (at state.floaters i col)
                    (at state.floaters i top))
                (set (at state.looks look second) (at state.floaters i second))))))
