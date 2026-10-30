; the one game state: game. Everything that changes while the game runs is in it, from whose
; turn it is to what each page of the screen shows.

(const ACTORS u8 4) ; the dog, then up to three enemies
(const DOG u8 0)
(const STATUS_SLOTS u8 16)
(const HAND u8 5) ; dice in the hand
(const DIE_FACES u8 6)
(const FLOATERS u8 4) ; damage numbers in the air at once
(const LOOKS u8 10)   ; things drawn over the backdrop: 4 actors, bolt, marker, 4 floaters
(const LOOK_BOLT u8 4)
(const LOOK_MARKER u8 5)
(const LOOK_FLOATER u8 6)
(const RECTS u8 12) ; backdrop boxes waiting to be copied onto each page
(const NOTHING u8 255)

(enum Screen (title battle))

(enum Phase (rolling player acting enemies won lost reward))

; the steps of the reward screen: pick an offer, then the die it replaces, or the die and the
; face to upgrade
(enum Pick (offer replace upgrade_die upgrade_face))

; the face an actor shows; the same order as the art's moods
(enum Mood (idle angry worried hurt bark happy ko))

; how an action looks on screen: a jump at the target, a bolt thrown at it, or a hop in place
(enum Motion (lunge throw hop))

; who an action is for: an enemy the player picks (or the hero, for an enemy), the one doing
; it, every enemy, or an enemy's friend
(enum Aim (foe self all friend))

; where the action in flight came from: a die face (or the meow), or an enemy's move
(enum Source (face move))

(struct Actor ((alive bool)
        (kind u8)   ; the enemy's row in content/enemies, or NOTHING for the dog
        (figure u8) ; the art kind that draws it
        (hp u8)
        (max_hp u8)
        (col u8)        ; byte column of the sprite's left edge now
        (home u8)       ; and where it stands
        (lift u8)       ; pixels above its spot: hops and bobs
        (move u8)       ; enemies: the move it means to make next, a row in content/enemies
        (moves_made u8) ; how far through its moves it is
        (mood Mood)
        (mood_time u8) ; frames until the mood goes back to its resting face
        (flash u8)     ; frames of white hit flash left
        (knock u8)     ; frames of knockback left
        (dying u8)))   ; frames of the death blink and poof left; 0 when alive or gone

(struct Floater ((sprite u8) (second u8) (col u8) (top u8) (time u8)))

; what one look on screen shows: a sprite and a second one over it (a face patch, a second
; digit), or sprite NOTHING when it is not there
(struct Look ((sprite u8)
        (col u8)
        (top u8)
        (second u8)
        (second_col u8)
        (second_top u8)
        (white bool) ; drawn as a white shape: the hit flash
        (swaps bool) ; the second is a face that can be drawn straight over another such face
        (face_on_body bool))) ; and it is the face the body already has: drawn only to swap back

(struct Rect ((col u8) (top u8) (cols u8) (rows u8)))

; Some lets have an :address in memory the layout does not use: $0800-$0AFF (the boot loader's,
; free once the game runs) and the rows of text page 1 the mixed screen never shows. Those
; are not zeroed at the start, so the game sets them before it reads them (AGENTS.md, Memory).
;
; ---- the game state, all of it, as top-level lets in this one module: state.phase reads
; shorter than state.game.phase, and the code is the same either way. Keep addr_of off their
; elements: taking an element's address packs a whole array of structs, and then every
; (at actors i hp) multiplies i by the struct's size instead of one LDA hp,X

(let screen Screen)
(let ticks u16) ; every pass of the main loop, for measuring frame costs
(let frame u8)  ; counts up every frame but in hit-stop
(let idle u8)   ; counts up while the dog's turn waits for a key: idle bobs and wing flaps
(let phase Phase)
(let timer u8) ; frames into the phase
(let actors (array Actor 4) :address 0x0680)
(let stacks (array u8 64) :address 0x0600) ; status stacks: actor * STATUS_SLOTS + status
; the run: which fight, the hero's hit points between fights, and her dice as face rows (die d
; is d * DIE_FACES to d * DIE_FACES + 5)
(let fight u8)
(let hero_hp u8)
(let dice (array u8 30) :address 0x0A10)
(let hand (array u8 5)) ; the face each die shows, a row in content/faces
(let played (array bool 5))
(let rerolls u8)
(let meowed bool)
(let selected u8) ; the die picked to play next, or NOTHING
(let target u8)   ; the enemy the dice go to
(let log_hold u8) ; frames the enemies wait, so the last log line can be read
; the reward screen
(let pick Pick)
(let picked u8) ; the slot picked, or NOTHING
(let offer u8)  ; the offer taken
(let upgrade_die u8)
(let next_enemy u8) ; on the enemies' turn, who acts next
(let turn u8)
; the action in flight
(let act_source Source)
(let act_row u8) ; its row in the faces or moves table
(let act_by u8)
(let act_on u8)
(let act_time u8)
(let act_done bool) ; its effect has landed
(let hitstop u8)    ; frames everything holds still after a hit
(let bolt_col u8)
(let bolt_top u8)
(let bolt_on bool)
(let bolt_sx i16) ; k steps of the way, times 8: see battle/act.tsp
(let bolt_sy i16)
(let floaters (array Floater 4) :address 0x0A30)
; the hud parts that need drawing again
(let hud_pills u8)   ; a bit for each actor whose hit points or statuses changed
(let hud_intents u8) ; a bit for each enemy whose intent changed
(let hud_dice u8)    ; a bit for each die to draw again
(let hud_rerolls bool)
(let hud_words bool) ; the bottom text's top two lines
; drawing: what each look should show, and what each page shows now
(let looks (array Look 10) :address 0x0580)
(let drawn (array Look 20) :address 0x0200) ; page * LOOKS + look
(let rects (array Rect 24) :address 0x0400) ; page * RECTS + n
(let rect_count (array u8 2))
(let full_redraw (array bool 2))
; the title
(let glow u8) ; which step of the glow cycle it shows
(let glow_time u8)
(let glow_loaded bool) ; a new glow step is on the back page, to show

(fn stack ((who u8) (status u8)) u8
    (at stacks (+ (* who STATUS_SLOTS) status)))

(fn set_stack ((who u8) (status u8) (n u8)) void
    (set (at stacks (+ (* who STATUS_SLOTS) status)) n)
    (set hud_pills (| hud_pills (<< 1 who))))
