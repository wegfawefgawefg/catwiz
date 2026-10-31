; the one game state: game. Everything that changes while the game runs is in it, from whose
; turn it is to what each page of the screen shows.

(const ACTORS u8 4) ; the hero, then up to three enemies
(const HERO u8 0)
(const STATUS_SLOTS u8 16)
(const HAND u8 5) ; dice in the hand
(const DIE_FACES u8 6)
(const FLOATERS u8 4) ; damage numbers in the air at once
(const BAG_MOST u8 6) ; dice in the bag at most: the reward's pickers show them all in the tray
(const MARKERS u8 3)  ; arrows over who the picked die goes to: every enemy, for a hit-all
; things drawn over the backdrop, later ones on top: 4 actors, their hit point badges, the
; enemies' intent badges, the bolt, 3 markers, 4 floaters
(const LOOKS u8 19)
(const LOOK_HP u8 4)
(const LOOK_INTENT u8 8) ; then 9 and 10: actor i's at LOOK_INTENT + i - 1
(const LOOK_BOLT u8 11)
(const LOOK_MARKER u8 12)
(const LOOK_FLOATER u8 15)
(const BADGES u8 7)     ; the badges: 4 hit point ones, then 3 intents
(const BADGE_MOST u8 8) ; glyphs in a badge at most
(const RECTS u8 12)     ; backdrop boxes waiting to be copied onto each page
(const NOTHING u8 255)
(const BADGE u8 254) ; a look's sprite when it is a badge

(enum Screen (title battle))

(enum Phase (rolling player acting enemies won lost reward))

; the steps of the reward screen: pick an offer, then the die to take out of the bag, or the
; die and the face to upgrade
(enum Pick (offer remove upgrade_die upgrade_face))

; the face an actor shows (battle/look turns it into a frame of the art)
(enum Mood (idle angry worried hurt attack happy ko surprised))

; how an action looks on screen: a jump at the target, a bolt thrown at it, or a hop in place
(enum Motion (lunge throw hop))

; who an action is for: an enemy the player picks (or the hero, for an enemy), the one doing
; it, every enemy, or an enemy's friend
(enum Aim (foe self all friend))

; where the action in flight came from: a die face, an enemy's move, or the hero's meow (M:
; just for fun, no effect)
(enum Source (face move meow))

(struct Actor ((alive bool)
        (kind u8)   ; the enemy's row in content/enemies, or NOTHING for the hero
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

; what one look on screen shows: a sprite (and a second one beside it, a floater's second
; digit), or a badge (sprite BADGE: its glyphs in state.badge_glyphs, second the count of its
; changes so a page sees a new one), or sprite NOTHING when it is not there. col is a byte
; column (even), top a row
(struct Look ((sprite u8)
        (col u8)
        (top u8)
        (second u8)
        (white bool) ; drawn as a white shape: the hit flash
        (wide u8)))  ; a badge's byte columns

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
; every pass of the main loop, for measuring frame costs (tools/measure.py reads it with --peek:
; outside zero page, which reads as aux memory's while code with the aux language card in runs)
(let ticks u16 :address 0x06E2)
; the Mockingboard's ticks, one a frame (main.irq): the frames that really went by, however
; long drawing one took
(let clock u8)
; a pose worth seeing was just reached (an action's start, its contact, a bolt's launch, a
; tumble): the main loop draws it before stepping further
(let pose bool)
(let frame u8) ; counts up every frame but in hit-stop
(let idle u8)  ; counts up while the hero's turn waits for a key: idle bobs and wing flaps
(let phase Phase)
(let timer u8) ; frames into the phase
(let actors (array Actor 4) :address 0x0680)
(let stacks (array u8 64) :address 0x0600) ; status stacks: actor * STATUS_SLOTS + status
; the run: which fight, the hero's hit points between fights, and her bag of dice as face rows
; (die d is d * DIE_FACES to d * DIE_FACES + 5)
(let fight u8)
(let hero_hp u8)
(let dice (array u8 36) :address 0x0700) ; BAG_MOST * DIE_FACES
(let bag u8)                             ; dice in the bag
; each turn the tray takes HAND dice from the bag's draw pile; when it runs out, the dice not
; in the tray are shuffled back into it. A fight starts with every die in the draw pile
(let in_draw (array bool 6) :address 0x06D6) ; die d is in the draw pile
(let tray_die (array u8 5) :address 0x06DC)  ; the bag die in each tray slot, NOTHING for none
(let hand (array u8 5))                      ; the face each die shows, a row in content/faces
(let played (array bool 5))
(let rerolls u8)
(let end_wait u8) ; frames until the hero's turn ends by itself, 0 for not
(let selected u8) ; the die picked to play next, or NOTHING
(let target u8)   ; the enemy the dice go to
(let log_hold u8) ; frames the enemies wait, so the last log line can be read
; the reward screen
(let pick Pick)
(let picked u8) ; the slot picked, or NOTHING
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
(let floaters (array Floater 4) :address 0x06BC)
; the hud parts that need drawing again
(let hud_pills u8)   ; a bit for each actor whose hit points or statuses changed
(let hud_intents u8) ; a bit for each enemy whose intent changed
(let hud_dice u8)    ; a bit for each die to draw again
(let hud_rerolls bool)
(let hud_words bool) ; the bottom text's top two lines
; the badges' glyphs (badge * BADGE_MOST + k), how many, and a count of their changes
(let badge_glyphs (array u8 56) :address 0x0724)
(let badge_count (array u8 7) :address 0x075C)
(let badge_stamp (array u8 7) :address 0x0763)
(let badge_x (array u8 7) :address 0x076A) ; the pill's first pixel
; drawing: what each look should show, and what each page shows now
(let looks (array Look 19) :address 0x0580)
(let drawn (array Look 38) :address 0x0200) ; page * LOOKS + look
(let rects (array Rect 24) :address 0x0400) ; page * RECTS + n
(let rect_count (array u8 2))
(let full_redraw (array bool 2))
; the title
(let glow u8) ; which step of the glow cycle it shows
(let glow_time u8)

(fn stack ((who u8) (status u8)) u8
    (at stacks (+ (* who STATUS_SLOTS) status)))

; a stack changes who's pill, and may change the intent over its head (wet halves it, a hiss
; skips it)
(fn set_stack ((who u8) (status u8) (n u8)) void
    (set (at stacks (+ (* who STATUS_SLOTS) status)) n)
    (let bit u8 (<< 1 who))
    (set hud_pills (| hud_pills bit))
    (set hud_intents (| hud_intents bit)))
