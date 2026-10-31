; the reward after a won fight, in the tray and the bottom text: pick one of four offers (two
; new dice for the bag, one face upgraded, or a die taken out of the bag). An upgrade asks for
; the die, then the face; taking a die out asks which. As in battle, a number key picks a slot
; and shows its text, the same key again (or RETURN) takes it; ESC goes back to the offers.

(import apple2 a2)
(import state)
(import art/icons)
(import draw/text)
(import battle/tray)
(import battle/bag)
(import content/action ac)
(import content/faces)
(import content/encounters enc)
(import sound/sound)

(const OFFER_UPGRADE u8 2) ; the third offer; the first two are enc.OFFER_DICE
(const OFFER_REMOVE u8 3)

; the six faces the text lists now
(let six (array u8 6) :address 0x0A08) ; scratch: see AGENTS.md, Memory

(fn start () void
    (set state.phase state.Phase.reward)
    (set state.selected state.NOTHING)
    (go state.Pick.offer))

; a step of the reward: its slots in the tray, the prompt in the text
(fn go ((pick state.Pick)) void
    (set state.pick pick)
    (set state.picked state.NOTHING)
    (draw_slots)
    (text.clear)
    (text.start)
    (text.add_n
        (match pick
            (state.Pick.offer "A reward! Pick one (1-4).")
            (state.Pick.remove "Take which die out of the bag? 1-#")
            (state.Pick.upgrade_die "Upgrade a face of which die? 1-#")
            (state.Pick.upgrade_face "Upgrade which face? (1-6)"))
        state.bag)
    (text.show 0))

; how many slots this step has
(fn slots () u8
    (match state.pick
        (state.Pick.offer 4)
        (state.Pick.upgrade_face state.DIE_FACES)
        (_ state.bag)))

; the face row bag die d shows first, its picture in the tray
(fn first_face ((d u8)) u8
    (at state.dice (* d state.DIE_FACES)))

(fn draw_slot ((n u8)) void
    (let picked bool (= n state.picked))
    (match state.pick
        (state.Pick.offer
            (match n
                (OFFER_UPGRADE (tray.slot n true icons.TILE_PLUS1 "+" picked))
                (OFFER_REMOVE (tray.slot n true icons.TILE_LINT "-" picked))
                (_
                    (tray.slot n true
                        (at faces.FACES (at (at enc.OFFER_DICE n faces) 0) icon)
                        "" picked))))
        (state.Pick.upgrade_face
            (let face u8 (at state.dice (+ (* state.upgrade_die state.DIE_FACES) n)))
            (tray.slot n true (at faces.FACES face icon) (at faces.FACES face caption) picked))
        (_
            (let face u8 (first_face n))
            (tray.slot n true (at faces.FACES face icon) "" picked))))

; the slots this step has on the tray's cards (the sixth where the buttons were), the other
; cards empty
(fn draw_slots () void
    (tray.clear_side)
    (for n u8 0 state.BAG_MOST
        (if (< n (slots))
            (draw_slot n)
            (tray.slot n (< n state.HAND) state.NOTHING "" false))))

; the names of the six faces in six, two to a row on rows 1 to 3
(fn list_six () void
    (for r u8 0 3
        (text.start)
        (text.add (at faces.FACES (at six (* r 2)) name))
        (text.tab 18)
        (text.add (at faces.FACES (at six (+ (* r 2) 1)) name))
        (text.show (+ r 1))))

(fn hero_die_to_six ((d u8)) void
    (for f u8 0 state.DIE_FACES
        (set (at six f) (at state.dice (+ (* d state.DIE_FACES) f)))))

; how to take it, at the end of row 0
(fn again () void
    (text.tab 24)
    (text.add "Again: take")
    (text.show 0))

; slot n's text: rows 0 to 3
(fn describe ((n u8)) void
    (text.clear)
    (text.start)
    (match state.pick
        (state.Pick.offer
            (if (>= n OFFER_UPGRADE)
                (do
                    (text.add (if (= n OFFER_UPGRADE)
                        "Upgrade one face"
                        "Take a die out"))
                    (again)
                    (text.start)
                    (text.add (if (= n OFFER_UPGRADE)
                        "Pick the die, then the face."
                        "Fewer dice: the rest come up more."))
                    (text.show 1)
                    (return)))
            (text.add "New die: ")
            (text.add (at enc.OFFER_DICE n name))
            (if (= state.bag state.BAG_MOST)
                (do
                    (text.add ". Bag full")
                    (text.show 0)
                    (for f u8 0 state.DIE_FACES
                        (set (at six f) (at (at enc.OFFER_DICE n faces) f)))
                    (list_six)
                    (return)))
            (for f u8 0 state.DIE_FACES
                (set (at six f) (at (at enc.OFFER_DICE n faces) f))))
        (state.Pick.upgrade_face
            (let face ac.Action
                (at faces.FACES (at state.dice (+ (* state.upgrade_die state.DIE_FACES) n))))
            (text.add face.name)
            (if (= face.upgrade state.NOTHING)
                (do
                    (text.add ": no upgrade")
                    (text.show 0)
                    (return)))
            (let better ac.Action (at faces.FACES face.upgrade))
            (text.add " becomes ")
            (text.add better.name)
            (text.show 0)
            (text.start)
            (text.add_n better.text better.amount)
            (text.show 1)
            (return))
        (_
            (text.add "Bag die ")
            (text.char (+ '1' n))
            (hero_die_to_six n)))
    (again)
    (list_six))

; the slot picked is taken. Gives true when the reward is done
(fn take ((n u8)) bool
    (match state.pick
        (state.Pick.offer
            (if (= n OFFER_UPGRADE)
                (do
                    (go state.Pick.upgrade_die)
                    (return false)))
            (if (= n OFFER_REMOVE)
                (do
                    (if (<= state.bag 1)
                        (do
                            (sound.cue sound.Cue.nope)
                            (return false)))
                    (go state.Pick.remove)
                    (return false)))
            ; a new die into the bag
            (if (>= state.bag state.BAG_MOST)
                (do
                    (sound.cue sound.Cue.nope)
                    (return false)))
            (let first u8 (* state.bag state.DIE_FACES))
            (for f u8 0 state.DIE_FACES
                (set (at state.dice (+ first f)) (at (at enc.OFFER_DICE n faces) f)))
            (set state.bag (+ state.bag 1))
            true)
        (state.Pick.remove
            (bag.remove n)
            true)
        (state.Pick.upgrade_die
            (set state.upgrade_die n)
            (go state.Pick.upgrade_face)
            false)
        (state.Pick.upgrade_face
            (let at_face u8 (+ (* state.upgrade_die state.DIE_FACES) n))
            (let better u8 (at faces.FACES (at state.dice at_face) upgrade))
            (if (= better state.NOTHING)
                (do
                    (sound.cue sound.Cue.nope)
                    (return false)))
            (set (at state.dice at_face) better)
            true)))

; slot n picked: its text; picked again, taken
(fn pick_slot ((n u8)) bool
    (if (= n state.picked)
        (do
            (sound.cue sound.Cue.confirm)
            (return (take n))))
    (let was u8 state.picked)
    (set state.picked n)
    (if (!= was state.NOTHING)
        (draw_slot was))
    (draw_slot n)
    (describe n)
    (sound.cue sound.Cue.blip)
    false)

; one frame of the reward; true when it is done and the next fight can start
(fn step ((key u8)) bool
    ; the sixth slot is where the battle's buttons are: their tap boxes (R over its top, E over
    ; its foot) pick it
    (if (or (= (& key 0xDF) 'R') (= (& key 0xDF) 'E'))
        (set key '6'))
    (if (and (>= key '1') (< key (+ '1' (slots))))
        (return (pick_slot (- key '1'))))
    (match key
        (0 false)
        (a2.KEY_RETURN
            (if (= state.picked state.NOTHING)
                (do
                    (sound.cue sound.Cue.nope)
                    (return false)))
            (pick_slot state.picked))
        (a2.KEY_ESC
            (go state.Pick.offer)
            false)
        (_
            (sound.cue sound.Cue.nope)
            false)))
