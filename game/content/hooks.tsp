; the steps waiting to run: hooks (content/cards HOOKS) and charms' moments set off in the middle
; of something (a hit, a fall, a hurt). They wait here, in order, and content/play runs them as
; soon as the step or the enemy's hit that set them off is done (play.drain): a hit cannot run
; steps itself, since steps hit.

(import state)
(import content/cards)
(import content/steps)

(const QUEUE u8 4)

(let fx_of (array (ptr u8) 4))
(let on (array u8 4) :address 0x0AF8)
(let value (array u8 4) :address 0x0AFC)
(let head u8 0)
(let count u8 0)

; what her shield took of the last enemy hit on her (Mirror Fur's bounce)
(let blocked u8 0)

; steps fx to run on t with v; with the line full it is dropped
(fn add ((fx (ptr u8)) (t u8) (v u8)) void
    (if (>= count QUEUE)
        (return))
    (set (at fx_of count) fx)
    (set (at on count) t)
    (set (at value count) v)
    (set count (+ count 1)))

(fn waiting () bool
    (< head count))

; the next waiting steps' row (taken: then on_now and value_now say for whom and how much)
(let on_now u8 0)
(let value_now u8 0)

(fn take () (ptr u8)
    (let k u8 head)
    (set head (+ k 1))
    (if (= head count)
        (do
            (set head 0)
            (set count 0)))
    (set on_now (at on k))
    (set value_now (at value k))
    (at fx_of k))

; the hooks of moment when that holder's statuses set off, run on t: each whose status holder
; carries, with v its value stack (none when that is 0)
(fn status ((when steps.When) (holder u8) (t u8)) void
    (for k u8 0 cards.HOOK_COUNT
        (if (= (cards.hook_when k) when)
            (if (> (state.stack holder (cards.hook_status k)) 0)
                (do
                    (let v u8 (state.stack holder (cards.hook_value k)))
                    (if (> v 0)
                        (add (cards.hook_fx k) t v)))))))
