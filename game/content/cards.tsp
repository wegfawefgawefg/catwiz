; what every card does, as steps (content/steps.tsp: the vocabulary; content/play.tsp runs
; them): the hero's items (content/items.tsp names each row's steps), the enemies' curses on
; her, the hooks statuses carry, the charms' (content/encounters CHARMS names them) and Mimic's
; table. A new card that is made of these steps costs its row here, no code. The rules are the
; balance sim's (tools/sim/items.py, rules.py, cards.py): each card does exactly what its text
; says.

(import content/steps)
(import content/action ac)
(import content/statuses st)
(import content/shows)

(const FLEA_TURNS u8 3)      ; fleas bite for this many of its turns
(const BACK_MOST u8 5)       ; her dice come back this many times a turn at most (the sim's cap)
(const REROLLS_MOST u8 9)    ; re-rolls she can hold at most (the tray shows one digit)
(const SUNBEAM_REROLLS u8 2) ; the re-rolls a sunbeam's mana past 5 gives at most (the sim's)
(const GAMBLE_PRICE u8 1)    ; the hit points a double or nothing costs when played (the sim's)
(const ZOOMIES_HITS u8 5)    ; Zoomies' hits, enemies left to right
(const SCREAM_SELF u8 1)     ; what 3 AM Screaming does to her

; ---- shared steps (call k, k a row of SUBS)

(steps.steps ZAP_HIT (cue zap) (hit))
(steps.steps SHIELD (cue ping) (add shield) (say_me SHIELDS))

; ---- the hero's items, by slot

; wands
(steps.steps TWIG_WAND (call SUB_ZAP_HIT) (three) (say THREE_HITS_ALL) (others) (hit) (end))

(steps.steps YARN_WAND (call SUB_ZAP_HIT) (if_up) (lit 1) (call SUB_TANGLE))

(steps.steps SPRAY_BOTTLE (call SUB_ZAP_HIT) (if_up) (lit 1) (call SUB_WET))

(steps.steps FEATHER_TOY (call SUB_ZAP_HIT) (pounce))

(steps.steps FISHBONE_WAND (cue zap) (pierce))

(steps.steps MOUSE_STRING (call SUB_ZAP_HIT) (next) (hit))

(steps.steps CANNON
    (cue zap)
    (get kittens)
    (sub kittens)
    (say KITTENS_LAUNCHED)
    (rep)
    (retarget)
    (num)
    (hit)
    (end))

; fluff: a shield, and the third fluff's three
(steps.steps FLUFF (call SUB_SHIELD) (three) (lit 1) (set keep) (say THREE_SHIELD_STAYS))

(steps.steps SPIKY_FLUFF (call SUB_SHIELD) (three) (lit 3) (max thorns) (say THREE_SPIKY))

(steps.steps BOX (call SUB_SHIELD) (three) (lit 1) (set box) (add kittens) (say THREE_BOX))

(steps.steps WARM_BLANKET (call SUB_SHIELD) (three) (say THREE_WARM) (lit 2) (heal))

(steps.steps STATIC_FUR
    (call SUB_SHIELD)
    (three)
    (say THREE_STATIC)
    (all)
    (lit 5)
    (t_has wet)
    (lit 10)
    (hit)
    (end))

(steps.steps BELL_COLLAR (call SUB_SHIELD) (three) (lit 2) (add ward) (say THREE_WARD))

; stars
(steps.steps STAR (cue chime) (mana) (get mana) (say MANA_NOW))
(steps.steps SHOOTING_STAR (cue zap) (lit 1) (mana) (num) (hit))
(steps.steps MOON_BOWL (cue ping) (lit 1) (mana) (num) (add shield) (say_me SHIELDS_1_MANA))
(steps.steps WISHING_STAR (cue chime) (mana) (lit 1) (set wish) (say WISH_NEXT_WAND))
(steps.steps LITTER_STAR (kits 1) (cue chime) (mana) (get mana) (say MANA_NOW))

; books (their mana is paid before the steps run)
(steps.steps ZOOMIES (cue zap) (me) (lit ZOOMIES_HITS) (rep) (next) (num) (hit) (end))
(steps.steps MEOW_BOOK (cue meow) (add kittens) (get kittens) (say KITTENS_JOIN_YOU))
(steps.steps LASER (cue zap) (all) (num) (hit) (if_up) (lit 1) (t_set laser) (end))

(steps.steps SCREAM
    (cue wobble)
    (all)
    (hit)
    (end)
    (lit SCREAM_SELF)
    (me)
    (hurt)
    (say_me TAKES_FROM_SCREAMING))

(steps.steps KNOCK
    (cue zap)
    (lit 0)
    (t_set shield)
    (t_set cheer)
    (t_set strength)
    (t_set reflect)
    (say_it DROPS_ITS_SHIELD)
    (num)
    (hit))

(steps.steps FITS (kits 2) (call SUB_SHIELD))

; curses (and the enemies' curses on her)
(steps.steps FLEAS
    (curse poison)
    (lit FLEA_TURNS)
    (t_set flea_turns)
    (t_get poison)
    (say_it GETS_FLEAS_TURN))

(steps.steps WET (least 1) (curse wet) (t_get wet) (say_it WET_HALF_HITS))
(steps.steps TANGLE (curse tangle) (t_get tangle) (say_it TANGLED_HITS))
(steps.steps MARK (curse brand) (t_get brand) (say_it MARKED_HITS))
(steps.steps SPOOK (curse spook) (say_it SPOOKED_DICE))

; tricks: a rule for the next dice (no boosts on them, no count towards a three)
(steps.steps PLUS (cue chime) (add plus) (lit 1) (set plus_left) (get plus) (say NEXT_DIE))

(steps.steps TIMES
    (cue chime)
    (times plus)
    (lit 1)
    (max mult)
    (num)
    (times mult)
    (get mult)
    (say TIMES_NEXT))

(steps.steps COPYCAT (cue chime) (copy))
(steps.steps CATNIP (cue chime) (add nip) (lit 1) (set nipped) (num) (say CATNIP_NEXT_DICE))

(steps.steps KNEAD
    (cue chime)
    (lit 1)
    (set knead_fluff)
    (num)
    (add knead_wand)
    (say KNEAD_NEXT_FLUFF))

(steps.steps HAIRBALL (cue puff) (say HAIRBALL_NOTHING_HAPPENS))

; ---- the chain and combo cards (docs/balance.md "The chain and combo cards", the owner's picks)

; Red Dot (curse): its dots; a wand hit on it brings her dice back (HOOKS: DOT_FIRES)
(steps.steps RED_DOT (curse dot) (t_get dot) (say_it RED_DOT))

; Catfight (curse): its next hit on her goes to a friend, this much harder (content/foes)
(steps.steps CATFIGHT (curse catfight) (t_get catfight) (say_it CATFIGHT))

; Flea Circus (curse): fleas, and when it falls they jump on (HOOKS: CIRCUS_JUMPS)
(steps.steps FLEA_CIRCUS
    (curse poison)
    (lit FLEA_TURNS)
    (t_set flea_turns)
    (lit 1)
    (t_set circus)
    (t_get poison)
    (say_it FLEA_CIRCUS))

; Mirror Fur (fluff): a shield, and what it takes this round bounces back (HOOKS: MIRROR)
(steps.steps MIRROR_FUR (call SUB_SHIELD) (add mirror))

; Lucky Paw (fluff): a shield and a re-roll
(steps.steps LUCKY_PAW (call SUB_SHIELD) (lit 1) (rerolls) (say FREE_REROLL))

; Sunbeam (star): mana, and what goes past the most is re-rolls, SUNBEAM_REROLLS at most
(steps.steps SUNBEAM (cue chime) (spill) (most SUNBEAM_REROLLS) (rerolls) (get mana) (say MANA_NOW))

; Scratching Habit (wand): a hit (her habit adds: content/action GROWS), then her habit grows
; for the fight
(steps.steps SCRATCHING_HABIT (call SUB_ZAP_HIT) (lit 1) (add habit))

; Double or Nothing (trick): the next die times #, and it costs her GAMBLE_PRICE hit points as
; it is played (the sim's final form: x3 for 1 hp)
(steps.steps DOUBLE_OR_NOTHING
    (cue chime)
    (lit 1)
    (max mult)
    (num)
    (times mult)
    (lit GAMBLE_PRICE)
    (me)
    (hurt)
    (get mult)
    (say DOUBLE_NEXT))

; Mimic (book): t's shown move, # times, done by her (MIMICRY says what each move is for her)
(steps.steps MIMIC (cue zap) (look) (rep) (retarget) (mimic) (end))

; what an enemy's move is for her when she mimics it, v its number: its hit on t (a hit-all on
; them all), its shield, its healing on her, its call a kitten, its cheer or growing a waiting
; plus, its curse on t, its reflect her spikes; the rest do nothing
(steps.steps AS_HIT (hit))
(steps.steps AS_HIT2 (hit) (if_up) (hit))
(steps.steps AS_HIT_ALL (all) (hit) (end))
(steps.steps AS_HEAL (heal))
(steps.steps AS_KITTENS (add kittens) (get kittens) (say KITTENS_JOIN_YOU))
(steps.steps AS_PLUS (add plus) (lit 1) (max plus_left) (get plus) (say NEXT_DIE))
(steps.steps AS_SPIKY (max thorns) (say_me SPIKY))

(struct Mimicry ((effect ac.Effect) (all bool) (fx (ptr u8))))

; a move's row: the first with its effect (all: only a move for every enemy)
(const MIMICRY_COUNT u8 13)

(const MIMICRY (array Mimicry 13)
    (make (array Mimicry 13)
        (make Mimicry :effect ac.Effect.hit :all true :fx (addr_of (at AS_HIT_ALL 0)))
        (make Mimicry :effect ac.Effect.hit2 :all true :fx (addr_of (at AS_HIT_ALL 0)))
        (make Mimicry :effect ac.Effect.hit :all false :fx (addr_of (at AS_HIT 0)))
        (make Mimicry :effect ac.Effect.hit2 :all false :fx (addr_of (at AS_HIT2 0)))
        (make Mimicry :effect ac.Effect.shield :all false :fx (addr_of (at SHIELD 0)))
        (make Mimicry :effect ac.Effect.heal :all false :fx (addr_of (at AS_HEAL 0)))
        (make Mimicry :effect ac.Effect.mend :all false :fx (addr_of (at AS_HEAL 0)))
        (make Mimicry :effect ac.Effect.summon :all false :fx (addr_of (at AS_KITTENS 0)))
        (make Mimicry :effect ac.Effect.cheer :all false :fx (addr_of (at AS_PLUS 0)))
        (make Mimicry :effect ac.Effect.grow :all false :fx (addr_of (at AS_PLUS 0)))
        (make Mimicry :effect ac.Effect.fleas :all false :fx (addr_of (at FLEAS 0)))
        (make Mimicry :effect ac.Effect.wet :all false :fx (addr_of (at WET 0)))
        (make Mimicry :effect ac.Effect.reflect :all false :fx (addr_of (at AS_SPIKY 0))))
    :in aux)

; ---- the hooks: steps a status sets off, when its holder carries it and its value stack is
; not 0 (t: the one it is on, or the enemy that hit her; v: the value stack)

; a wand hit on a red dot: her dice come back (once a play), and a dot is used
(steps.steps DOT_FIRES (back) (lit 1) (t_sub dot))

; a flea circus's host fell: its fleas jump to the next one standing, doubled, fresh turns
(steps.steps CIRCUS_JUMPS
    (next)
    (t_set poison)
    (t_add poison)
    (lit FLEA_TURNS)
    (t_set flea_turns)
    (lit 1)
    (t_set circus)
    (t_get poison)
    (say_it FLEAS_JUMP))

; she was hit through mirror fur: what her shield took goes back, the mirror's most
(steps.steps MIRROR (blocked) (sub mirror) (hurt) (say_it BOUNCED))
; she was hit while spiky: who hit her takes the spikes
(steps.steps THORNS (hurt))

(struct Hook ((status st.Status) (when steps.When) (value st.Status) (fx (ptr u8))))

(const HOOK_COUNT u8 4)

(const HOOKS (array Hook 4)
    (make (array Hook 4)
        (make Hook
            :status st.Status.dot
            :when steps.When.wand_hit
            :value st.Status.dot
            :fx (addr_of (at DOT_FIRES 0)))
        (make Hook
            :status st.Status.circus
            :when steps.When.falls
            :value st.Status.poison
            :fx (addr_of (at CIRCUS_JUMPS 0)))
        (make Hook
            :status st.Status.mirror
            :when steps.When.hit_her
            :value st.Status.mirror
            :fx (addr_of (at MIRROR 0)))
        (make Hook
            :status st.Status.thorns
            :when steps.When.hit_her
            :value st.Status.thorns
            :fx (addr_of (at THORNS 0))))
    :in aux)

; ---- the charms' steps (v: the charm's amount, times the ones she holds)

(steps.steps NOTHING)
(steps.steps MOTHER_CAT (set kittens))
(steps.steps GRUMPY (mana))
(steps.steps RUBBER_DUCK (add shield))
(steps.steps STILL_WATER (calm) (mana))
(steps.steps TRIO (all) (plain) (end))
(steps.steps LITTER_BOX (kept) (add kittens))
(steps.steps NINE_LIVES (cue chime) (say_me NINE_LIVES))

; ---- each item's steps and tags (content/action: THREE, KITTENS, GROWS, the caption) and its
; show (content/shows: how its play looks), in the order of content/items ITEMS: a new item adds
; its row there and its card here

(struct Card ((fx (ptr u8)) (tags u8) (show u8)))

(const CARDS (array Card 43)
    (make (array Card 43)
        (make Card :fx (addr_of (at TWIG_WAND 0)) :tags ac.THREE :show shows.BOLT)
        (make Card :fx (addr_of (at YARN_WAND 0)) :tags 0 :show shows.BOLT)
        (make Card :fx (addr_of (at SPRAY_BOTTLE 0)) :tags 0 :show shows.BOLT)
        (make Card :fx (addr_of (at FEATHER_TOY 0)) :tags ac.KITTENS :show shows.BOLT)
        (make Card :fx (addr_of (at FISHBONE_WAND 0)) :tags 0 :show shows.BOLT)
        (make Card :fx (addr_of (at MOUSE_STRING 0)) :tags 0 :show shows.BOLT)
        (make Card :fx (addr_of (at FLUFF 0)) :tags ac.THREE :show shows.NONE)
        (make Card :fx (addr_of (at SPIKY_FLUFF 0)) :tags ac.THREE :show shows.NONE)
        (make Card :fx (addr_of (at BOX 0)) :tags ac.THREE :show shows.NONE)
        (make Card :fx (addr_of (at WARM_BLANKET 0)) :tags ac.THREE :show shows.NONE)
        (make Card :fx (addr_of (at STATIC_FUR 0)) :tags ac.THREE :show shows.NONE)
        (make Card :fx (addr_of (at BELL_COLLAR 0)) :tags ac.THREE :show shows.NONE)
        (make Card :fx (addr_of (at STAR 0)) :tags 0 :show shows.NONE)
        (make Card :fx (addr_of (at SHOOTING_STAR 0)) :tags 0 :show shows.BOLT)
        (make Card :fx (addr_of (at MOON_BOWL 0)) :tags 0 :show shows.NONE)
        (make Card :fx (addr_of (at WISHING_STAR 0)) :tags 0 :show shows.NONE)
        (make Card :fx (addr_of (at LITTER_STAR 0)) :tags ac.KITTENS :show shows.NONE)
        (make Card :fx (addr_of (at ZOOMIES 0)) :tags 0 :show shows.BOLT)
        (make Card :fx (addr_of (at MEOW_BOOK 0)) :tags ac.KITTENS :show shows.NONE)
        (make Card :fx (addr_of (at LASER 0)) :tags 0 :show shows.BOLT)
        (make Card :fx (addr_of (at SCREAM 0)) :tags 0 :show shows.BOLT)
        (make Card :fx (addr_of (at KNOCK 0)) :tags 0 :show shows.BOLT)
        (make Card :fx (addr_of (at FITS 0)) :tags ac.KITTENS :show shows.NONE)
        (make Card :fx (addr_of (at CANNON 0)) :tags ac.KITTENS :show shows.BOLT)
        (make Card :fx (addr_of (at FLEAS 0)) :tags 0 :show shows.BOLT)
        (make Card :fx (addr_of (at WET 0)) :tags 0 :show shows.BOLT)
        (make Card :fx (addr_of (at TANGLE 0)) :tags 0 :show shows.BOLT)
        (make Card :fx (addr_of (at MARK 0)) :tags 0 :show shows.BOLT)
        (make Card :fx (addr_of (at PLUS 0)) :tags ac.CAP_PLUS :show shows.NONE)
        (make Card :fx (addr_of (at TIMES 0)) :tags ac.CAP_TIMES :show shows.NONE)
        (make Card :fx (addr_of (at COPYCAT 0)) :tags ac.CAP_PLUS :show shows.NONE)
        (make Card :fx (addr_of (at CATNIP 0)) :tags 0 :show shows.NONE)
        (make Card :fx (addr_of (at KNEAD 0)) :tags ac.CAP_PLUS :show shows.NONE)
        (make Card :fx (addr_of (at HAIRBALL 0)) :tags ac.CAP_NONE :show shows.NONE)
        (make Card :fx (addr_of (at RED_DOT 0)) :tags 0 :show shows.RED_DOT)
        (make Card :fx (addr_of (at MIMIC 0)) :tags 0 :show shows.MIMIC)
        (make Card :fx (addr_of (at CATFIGHT 0)) :tags 0 :show shows.CATFIGHT)
        (make Card :fx (addr_of (at MIRROR_FUR 0)) :tags 0 :show shows.MIRROR)
        (make Card :fx (addr_of (at LUCKY_PAW 0)) :tags 0 :show shows.LUCKY_PAW)
        (make Card :fx (addr_of (at FLEA_CIRCUS 0)) :tags 0 :show shows.FLEAS)
        (make Card :fx (addr_of (at SUNBEAM 0)) :tags 0 :show shows.SUNBEAM)
        (make Card :fx (addr_of (at SCRATCHING_HABIT 0)) :tags ac.GROWS :show shows.CLAWS)
        (make Card :fx (addr_of (at DOUBLE_OR_NOTHING 0)) :tags ac.CAP_TIMES :show shows.COIN))
    :in aux)

; a card's fields, read from aux memory (CARDS is :in aux: main memory is full)
(fn fx ((row u8)) (ptr u8)
    (with_aux true false
        (at CARDS row fx)))

(fn tags ((row u8)) u8
    (with_aux true false
        (at CARDS row tags)))

(fn show ((row u8)) u8
    (with_aux true false
        (at CARDS row show)))

; ---- the shared steps' rows, for call

(const SUB_ZAP_HIT u8 0)
(const SUB_SHIELD u8 1)
(const SUB_TANGLE u8 2)
(const SUB_WET u8 3)

(const SUBS (array (ptr u8) 4)
    (make (array (ptr u8) 4)
        (addr_of (at ZAP_HIT 0))
        (addr_of (at SHIELD 0))
        (addr_of (at TANGLE 0))
        (addr_of (at WET 0))))

; a hook's fields, read from aux memory in one go
(fn hook_when ((k u8)) steps.When
    (with_aux true false
        (at HOOKS k when)))

(fn hook_status ((k u8)) u8
    (with_aux true false
        (as u8 (at HOOKS k status))))

(fn hook_value ((k u8)) u8
    (with_aux true false
        (as u8 (at HOOKS k value))))

(fn hook_fx ((k u8)) (ptr u8)
    (with_aux true false
        (at HOOKS k fx)))

; the row of MIMICRY for a move of effect e (all: for every enemy), NOTHING for none
(fn mimicry ((e ac.Effect) (all bool)) u8
    (with_aux true false
        (for k u8 0 MIMICRY_COUNT
            (if (and (= (at MIMICRY k effect) e) (or all (not (at MIMICRY k all))))
                (return k)))
        255))

(fn mimicry_fx ((k u8)) (ptr u8)
    (with_aux true false
        (at MIMICRY k fx)))
