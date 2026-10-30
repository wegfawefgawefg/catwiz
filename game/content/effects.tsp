; what dice faces, enemy moves and the bark do: one effect kind each, and the one match that
; carries them out. An Action is a row of the dice and enemy move tables.

(import state)
(import battle/hit)
(import content/statuses st)
(import sound/sfx)

(enum Effect (zap ; a magic bolt: damage
        bite      ; teeth: damage
        guard     ; shield stacks, soaking up hits until the holder's next turn
        mend      ; hit points back
        ember     ; burn stacks: damage at the end of each of the holder's turns
        boo       ; spook stacks: the holder's hits do that much less
        fizzle))  ; nothing at all

; icon: for a die face the tile sprite in the tray, for an enemy move the hud glyph
(struct Action ((effect Effect) (amount u8) (motion state.Motion) (aim state.Aim) (icon u8)))

; by's action lands on target, at the end of its motion
(fn apply ((effect Effect) (by u8) (target u8) (amount u8)) void
    (match effect
        (Effect.zap
            (sfx.zap)
            (hit.strike by target amount))
        (Effect.bite (hit.strike by target amount))
        (Effect.guard
            (sfx.ping)
            (hit.add_stacks target (as u8 st.Status.shield) amount))
        (Effect.mend
            (sfx.chime)
            (hit.heal target amount))
        (Effect.ember
            (sfx.hiss)
            (hit.add_stacks target (as u8 st.Status.burn) amount))
        (Effect.boo
            (sfx.wobble)
            (hit.add_stacks target (as u8 st.Status.spook) amount))
        (Effect.fizzle (sfx.puff))))
