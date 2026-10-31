; the statuses an actor can carry, as stacks (state.stack), and when each one acts. The engine
; calls the hooks below at the right moments and never names a status itself; the hud shows
; them by the tables here.

(import state)
(import battle/log)
(import content/enemies en)

(enum Status (shield ; soaks hits until the holder's next turn
        poison       ; fleas: damage at the end of each of its turns
        flea_turns   ; turns of fleas left
        wet          ; its hits are halved, for this many of its turns
        cheer        ; its next hit does this much more
        ward         ; pips: each curse breaks one instead of landing
        box          ; the hero in a box: hit-all attacks miss
        mana         ; the hero's mana
        plus         ; the next plus_left dice played get this much more
        plus_left
        mult        ; the next wand, fluff or book is times this, and counts this towards a three
        spook       ; the hero's dice are this much less, till her turn ends
        reflect     ; it sends back this much of what the hero deals it, till its turn
        laser       ; its next hit goes to a friend (to the hero when it has none)
        thorns      ; who hits the hero takes this much back, till her next turn
        strength    ; its hits are this much more, all fight
        kittens     ; the hero's kittens: each pounces at the end of her turn
        tangle      ; its hits are this much less, till its turn ends
        brand       ; marked: every hit on it is this much more, all fight; kittens go for it
        nip         ; catnip: the next this many dice get 1 more
        nipped      ; catnip this turn: the kittens pounce twice at its end
        knead_fluff ; the next fluff is times 2
        knead_wand  ; the next wand is this much more
        keep        ; the hero's shield stays through her next turn's start
        wish        ; the next wand is times 2
        hurt        ; hit points it lost this turn of the hero's (a stall counts them)
        fresh))     ; just came in or got up: it skips its next move

(const STATUS_COUNT u8 27)
(const MOST_MANA u8 5) ; mana is kept all fight, this much at most

; how the hud shows each: under the hit points as glyph and number, as a glyph alone, as one
; glyph per stack in the hit point pill, or not at all (mana: the stars by the tray show it)
(enum Show (count flag pips hidden))

(const SHOW (array Show 27)
    (make (array Show 27)
        Show.count Show.count Show.hidden Show.count Show.count Show.pips Show.flag Show.hidden
        Show.count Show.hidden Show.count Show.count Show.count Show.flag Show.count Show.count
        Show.count Show.count Show.count Show.count Show.hidden Show.flag Show.count Show.flag
        Show.flag Show.hidden Show.hidden))

; the glyphs, in the hud font (tools/dhgr/game_hud.py): # shield, , fleas (a bug), % wet (a
; drop), < cheered, ; a ward pip, & in a box, + the next dice's plus, > times, ? spooked, :
; sends back (an arrow), " lasered (a red dot), / spiky, ^ strength (an orange sword), _
; kittens (a kitten's head), [ tangled (yarn), ] marked, ( catnip (a leaf), \ knead (a paw), =
; shield stays, ' wished (a star)
(const GLYPH (array u8 27)
    (make (array u8 27)
        '#' ',' ' ' '%' '<' ';' '&' ' ' '+' ' ' '>' '?' ':' '"' '/' '^' '_' '[' ']' '(' ' ' '\\'
        '\\' '=' '\'' ' ' ' '))

; in words, for the bottom text: a name, then the stack's number for counts
(const NAME (array (ptr u8) 27)
    (make (array (ptr u8) 27)
        "Shield " "Fleas " "" "Wet " "Cheered +" "Ward " "In a box" "" "Next +" "" "Next x"
        "Spooked -" "Sends back " "Lasered" "Spiky " "Strength +" "Kittens " "Tangled " "Marked "
        "Catnip +" "" "Knead" "Knead +" "Shield stays" "Wished" "" "") :strings aux)

; a new fight: no stacks, and the ward its kind has (the hero: kind NOTHING)
(fn start ((who u8) (kind u8)) void
    (for s u8 0 STATUS_COUNT
        (state.set_stack who s 0))
    (if (!= kind state.NOTHING)
        (state.set_stack who (as u8 Status.ward) (at en.ENEMIES kind ward))))

; an enemy's turn starts: last turn's shield and the hits it sends back are gone
(fn turn_start ((who u8)) void
    (state.set_stack who (as u8 Status.shield) 0)
    (state.set_stack who (as u8 Status.box) 0)
    (state.set_stack who (as u8 Status.reflect) 0))

; at the end of who's turn: wet dries a turn, tangles come loose, fleas bite. Gives the damage
; for the engine to take off
(fn turn_end ((who u8)) u8
    (let wet u8 (state.stack who (as u8 Status.wet)))
    (if (> wet 0)
        (state.set_stack who (as u8 Status.wet) (- wet 1)))
    (state.set_stack who (as u8 Status.tangle) 0)
    (let turns u8 (state.stack who (as u8 Status.flea_turns)))
    (if (= turns 0)
        (return 0))
    (let bite u8 (state.stack who (as u8 Status.poison)))
    (state.set_stack who (as u8 Status.flea_turns) (- turns 1))
    (if (= turns 1)
        (state.set_stack who (as u8 Status.poison) 0))
    (log.who who " takes # from fleas." bite)
    bite)

; whether who skips the move it was going to make: it just came in or got up
(fn skips ((who u8)) bool
    (> (state.stack who (as u8 Status.fresh)) 0))

; a hit who makes, after their statuses: cheer and strength add (cheer used up when the hit is
; made, use), tangled takes away, then wet halves
(fn dealt ((who u8) (damage u8) (use bool)) u8
    (let cheer u8 (state.stack who (as u8 Status.cheer)))
    (if use
        (state.set_stack who (as u8 Status.cheer) 0))
    (let d u8 (+ (+ damage cheer) (state.stack who (as u8 Status.strength))))
    (let tangle u8 (state.stack who (as u8 Status.tangle)))
    (set d (if (> d tangle)
        (- d tangle)
        0))
    (if (> (state.stack who (as u8 Status.wet)) 0)
        (set d (>> d 1)))
    d)

; a hit who takes, after their statuses: shield soaks it up and is used up by it
(fn taken ((who u8) (damage u8)) u8
    (let shield u8 (state.stack who (as u8 Status.shield)))
    (if (>= shield damage)
        (do
            (state.set_stack who (as u8 Status.shield) (- shield damage))
            (return 0)))
    (state.set_stack who (as u8 Status.shield) 0)
    (- damage shield))

; n mana more for the hero, MOST_MANA at most
(fn gain_mana ((n u8)) void
    (if (= n 0)
        (return))
    (let s u8 (as u8 Status.mana))
    (let now u8 (+ (state.stack state.HERO s) n))
    (if (> now MOST_MANA)
        (set now MOST_MANA))
    (state.set_stack state.HERO s now))
