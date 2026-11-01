; what every card does, as steps (content/steps.tsp: the vocabulary; content/play.tsp runs
; them): the hero's items (content/items.tsp names each row's steps), the enemies' curses on
; her, the hooks statuses carry, the charms' (content/encounters CHARMS names them) and Mimic's
; table. A new card that is made of these steps costs its row here, no code. The rules are the
; balance sim's (tools/sim/items.py, rules.py, cards.py): each card does exactly what its text
; says.

(import content/steps)
(import content/action ac)
(import content/statuses st)

(const FLEA_TURNS u8 3)   ; fleas bite for this many of its turns
(const ZOOMIES_HITS u8 5) ; Zoomies' hits, enemies left to right
(const SCREAM_SELF u8 1)  ; what 3 AM Screaming does to her

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

; ---- the hooks: steps a status sets off (t: who set it off; v: the holder's value stack)

(steps.steps THORNS (hurt))

(struct Hook ((status st.Status) (when steps.When) (value st.Status) (fx (ptr u8))))

(const HOOK_COUNT u8 1)

(const HOOKS (array Hook 1)
    (make (array Hook 1)
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
