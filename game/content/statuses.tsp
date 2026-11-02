; the statuses an actor can carry, as stacks (state.stack), and when each one acts. The engine
; calls the hooks below at the right moments and never names a status itself; the hud shows
; them by the tables here. (No log here: content/steps' macro needs this module, and the log
; needs the content's names; battle/turn writes the fleas' line.)

(import state)
(import content/enemies en)

; the log's sentences, in aux memory (battle/log reads them there): SAY_ and their words
(const SAY (array (ptr u8) 1) (make (array (ptr u8) 1) " \x09takes # from fleas.") :strings aux)

(const SAY_TAKES_FROM_FLEAS u8 0)

(enum Status (shield ; soaks hits until the holder's next turn
        poison       ; fleas: damage at the end of each of its turns
        flea_turns   ; turns of fleas left
        wet          ; its hits are halved, for this many of its turns
        cheer        ; its next hit does this much more
        ward         ; pips: each curse breaks one instead of landing
        reflect      ; it sends back this much of what the hero deals it, till its turn
        laser        ; its next hit goes to a friend (to the hero when it has none)
        strength     ; its hits are this much more, all fight
        tangle       ; its hits are this much less, till its turn ends
        brand        ; marked: every hit on it is this much more, all fight; kittens go for it
        hurt         ; hit points it lost this turn of the hero's (a stall counts them)
        fresh        ; just came in or got up: it skips its next move
        dot          ; red dot: this many times, a wand hit on it brings her dice back
        catfight     ; its next hit goes to a friend, this much harder
        circus       ; a flea circus: when it falls its fleas jump to the next one, doubled
        scared       ; spooked: its next attack is a shield of its number instead
        hypno        ; hypnotized: its next attack hits a random fighter, friends too
        berserk      ; catnip bomb: its next attack hits everyone, itself too
        leech        ; turns left: each hit she lands on it heals her 1
        mleech       ; mana leech: each hit she lands on it this turn makes 1 mana
        snag         ; tangled next turn: its tangle when its turn ends
        sleep        ; asleep: it skips its next move (not the King: content/play curse)
        ; hers alone from here on: an enemy's stacks are only the ones above (FOE_COUNT)
        box ; the hero in a box: hit-all attacks miss
        mana ; the hero's mana
        plus ; the next die played gets this much more, till her turn ends
        plus_left ; 1 while a plus waits for its die
        mult ; the next die but a trick: times this, counting this towards a three
        spook ; the hero's dice are this much less, till her turn ends
        thorns ; who hits the hero takes this much back, till her next turn
        kittens ; the hero's kittens: each pounces at the end of her turn
        nip ; catnip: the next this many dice get 1 more
        nipped ; catnip this turn: the kittens pounce twice at its end
        knead_fluff ; the next fluff is times 2
        knead_wand ; the next wand is this much more
        keep ; the hero's shield stays through her next turn's start
        wish ; the next wand is times 2
        mirror ; what her shield takes this round goes back to the hitter, this much at most
        gamble ; double or nothing: she loses this much at her turn's end if no die took the times
        habit ; scratching habit: her habit's number is this much more, all fight
        sharp ; sharpen claws: her wands are this much more, all fight
        snowball ; her snowballs hit this much more, all fight
        scars ; the times she was hurt this fight (grudge, thick skin)
        collar ; a flea collar: whoever hits her gets this many fleas, till her next turn
        wall ; a hairball wall: whoever hits her is tangled this much next turn, till her next turn
        echo ; spell echo: her next book is cast twice
        allin ; all in: every die but a trick this turn is times this, and no re-rolls
        flip ; paw flip: the die she picks turns a face each time she picks it again
        momentum ; her first wand each turn is this much more (a charm adds to it each turn)
        rolls ; re-rolls more at her next turn's start (spare yarn)
        tmp)) ; scratch for a card's sums

(const STATUS_COUNT u8 51)
(const FOE_COUNT u8 23) ; an enemy's statuses, the first ones (state.FIRST_STACK)
(const MOST u8 255)     ; every number is a byte and stops here (the owner, 2026-11-01)
(const MOST_MANA u8 5)  ; mana is kept all fight, this much at most

; how the hud shows each: under the hit points as glyph and number, as a glyph alone, as one
; glyph per stack in the hit point pill, or not at all (mana: the stars by the tray show it)
(enum Show (count flag pips hidden))

(const SHOW (array Show 51)
    (make (array Show 51)
        Show.count Show.count Show.hidden Show.count Show.count Show.pips Show.count Show.flag
        Show.count Show.count Show.count Show.hidden Show.hidden Show.count Show.count Show.flag
        Show.flag Show.flag Show.flag Show.count Show.flag Show.count Show.flag Show.flag
        Show.hidden Show.count Show.hidden Show.count Show.count Show.count Show.count Show.count
        Show.hidden Show.flag Show.count Show.flag Show.flag Show.count Show.hidden Show.count
        Show.count Show.hidden Show.hidden Show.count Show.count Show.flag Show.count Show.hidden
        Show.hidden Show.hidden Show.hidden)
    :in aux)

; the glyphs, in the hud font (tools/dhgr/game_hud.py): # shield, , fleas (a bug), % wet (a
; drop), < cheered, ; a ward pip, & in a box, + the next dice's plus, > times, ? spooked, :
; sends back (an arrow), " lasered (a red dot), / spiky, ^ strength (an orange sword), _
; kittens (a kitten's head), [ tangled (yarn), ] marked, ( catnip (a leaf), \ knead (a paw), =
; shield stays, ' wished (a star); past _ the chain cards' own: ` a red dot, a catfight (a
; swipe), b mirror fur (a hand mirror), c a flea circus (a flea over its stand), d her habit
; (claw marks); the faces round's reuse them: d sharp, ? scared, " hypnotized, ! berserk, *
; leech (a heart), ' mana leech and spell echo (a star), , a flea collar, - a hairball wall, [
; snagged, @ asleep (a Z), > all in
(const GLYPH (array u8 51)
    (make (array u8 51)
        '#' ',' ' ' '%' '<' ';' ':' '"' '^' '[' ']' ' ' ' ' '`' 'a' 'c' '?' '"' '!' '*'
        '\'' '[' '@' '&' ' ' '+' ' ' '>' '?' '/' '_' '(' ' ' '\\' '\\' '=' '\'' 'b' ' ' 'd'
        'd' ' ' ' ' ',' '-' '\'' '>' ' ' ' ' ' ' ' ')
    :in aux)

; in words, for the bottom text: a name, then the stack's number for counts
(const NAME (array (ptr u8) 51)
    (make (array (ptr u8) 51)
        "Shield " "Fleas " "" "Wet " "Cheered +" "Ward "
        "Sends back " "Lasered" "Strength +" "Tangled " "Marked " ""
        "" "Red dot " "Catfight +" "Flea circus" "Scared" "Hypnotized"
        "Berserk" "Leech " "Mana leech" "Snagged " "Asleep" "In a box"
        "" "Next +" "" "Next x" "Spooked -" "Spiky "
        "Kittens " "Catnip +" "" "Knead" "Knead +" "Shield stays"
        "Wished" "Mirror " "" "Habit +" "Sharp +" ""
        "" "Flea collar " "Hairball wall " "Spell echo" "All in x" ""
        "" "" "")
    :in aux) ; with its strings: main memory is full (name reads it)

; status s's way of showing and its glyph, out of aux memory (the hud reads them only for a
; stack not 0)
(fn show_of ((s u8)) Show
    (with_aux true false
        (at SHOW s)))

(fn glyph_of ((s u8)) u8
    (with_aux true false
        (at GLYPH s)))

; status s's name, out of aux memory
(fn name ((s u8)) (ptr u8)
    (with_aux true false
        (at NAME s)))

; the statuses who can have: hers all, an enemy's the first FOE_COUNT
(fn count_of ((who u8)) u8
    (if (= who state.HERO)
        STATUS_COUNT
        FOE_COUNT))

; a + b, MOST at most instead of wrapping
(fn sum ((a u8) (b u8)) u8
    (let s u8 (+ a b))
    (if (< s a)
        (return MOST))
    s)

; a new fight: no stacks, and the ward its kind has (the hero: kind NOTHING)
(fn start ((who u8) (kind u8)) void
    (for s u8 0 (count_of who)
        (state.set_stack who s 0))
    (if (!= kind state.NOTHING)
        (state.set_stack who (as u8 Status.ward) (en.ward kind))))

; an enemy's turn starts: last turn's shield, the hits it sends back and a mana leech are gone
(fn turn_start ((who u8)) void
    (state.set_stack who (as u8 Status.shield) 0)
    (state.set_stack who (as u8 Status.reflect) 0)
    (state.set_stack who (as u8 Status.mleech) 0))

; status s of who a turn less, 0 at least
(fn wear ((who u8) (s Status)) void
    (let n u8 (state.stack who (as u8 s)))
    (if (> n 0)
        (state.set_stack who (as u8 s) (- n 1))))

; at the end of who's turn: wet dries a turn and a leech lets go a turn, tangles come loose (a
; snag tangles it next turn), fleas bite. Gives the damage for the engine to take off
; (battle/turn logs the bite)
(fn turn_end ((who u8)) u8
    (wear who Status.wet)
    (wear who Status.leech)
    (state.set_stack who (as u8 Status.tangle) (state.stack who (as u8 Status.snag)))
    (state.set_stack who (as u8 Status.snag) 0)
    (let turns u8 (state.stack who (as u8 Status.flea_turns)))
    (if (= turns 0)
        (return 0))
    (let bite u8 (state.stack who (as u8 Status.poison)))
    (state.set_stack who (as u8 Status.flea_turns) (- turns 1))
    (if (= turns 1)
        (state.set_stack who (as u8 Status.poison) 0))
    bite)

; whether who skips the move it was going to make: it just came in or got up, or it is asleep
(fn skips ((who u8)) bool
    (> (| (state.stack who (as u8 Status.fresh)) (state.stack who (as u8 Status.sleep))) 0))

; a hit who makes, after their statuses: cheer and strength add (cheer used up when the hit is
; made, use), tangled takes away, then wet halves
(fn dealt ((who u8) (damage u8) (use bool)) u8
    (let cheer u8 (state.stack who (as u8 Status.cheer)))
    (if use
        (state.set_stack who (as u8 Status.cheer) 0))
    (let d u8 (sum (sum damage cheer) (state.stack who (as u8 Status.strength))))
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

; n mana more for the hero, state.mana_most at most (MOST_MANA, more with a mana battery)
(fn gain_mana ((n u8)) void
    (if (= n 0)
        (return))
    (let s u8 (as u8 Status.mana))
    (let now u8 (sum (state.stack state.HERO s) n))
    (if (> now state.mana_most)
        (set now state.mana_most))
    (state.set_stack state.HERO s now))
