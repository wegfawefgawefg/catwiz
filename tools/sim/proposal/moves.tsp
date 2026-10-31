; PROPOSAL (tools/sim, docs/balance.md): the enemies' moves, in their own file (the enemies file
; would pass 500 lines) and in the smaller ac.Move row: a move never had a name, caption, cost or
; upgrade. Each enemy's moves are rows first_move to first_move + move_count - 1
; (content/enemies), made in order, round and round; text is 21 characters at most, # the amount.
; A hairball move's amount is the slot it clogs (items.Slot: 0 wand, 1 fluff, ...).

(import state)
(import content/action ac)

(const MOVES (array ac.Move 58)
    (make (array ac.Move 58)
        ; puffcap
        (make ac.Move
            :text "HEADBUTT FOR #"
            :effect ac.Effect.hit
            :amount 2
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "SPORE SHIELD #"
            :effect ac.Effect.shield
            :amount 2
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '#')
        ; sporelet
        (make ac.Move
            :text "NIP FOR #"
            :effect ac.Effect.hit
            :amount 1
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "CHEER: FRIEND +# NEXT"
            :effect ac.Effect.cheer
            :amount 1
            :aim state.Aim.friend
            :motion state.Motion.hop
            :icon '<')
        ; nightflap
        (make ac.Move
            :text "SCRATCH FOR #"
            :effect ac.Effect.hit
            :amount 1
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "BITE FOR #"
            :effect ac.Effect.hit
            :amount 1
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "DIVE FOR #"
            :effect ac.Effect.hit
            :amount 2
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '>')
        ; garden gnome
        (make ac.Move
            :text "GUARDS A FRIEND: #"
            :effect ac.Effect.shield
            :amount 3
            :aim state.Aim.friend
            :motion state.Motion.hop
            :icon '#')
        (make ac.Move
            :text "ROD POKE FOR #"
            :effect ac.Effect.hit
            :amount 4
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        ; possum
        (make ac.Move
            :text "BITE FOR #"
            :effect ac.Effect.hit
            :amount 2
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "PUFFS UP: SHIELD #"
            :effect ac.Effect.shield
            :amount 2
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '#')
        ; possum (faked it)
        (make ac.Move
            :text "CHEAP SHOT FOR #"
            :effect ac.Effect.hit
            :amount 2
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        ; squirrel
        (make ac.Move
            :text "GRABS YOUR LAST DIE"
            :effect ac.Effect.steal
            :amount 0
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '$')
        (make ac.Move
            :text "ACORN FOR #"
            :effect ac.Effect.hit
            :amount 3
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        ; roomba
        (make ac.Move
            :text "BEEP. BUMPS IN 2"
            :effect ac.Effect.wait
            :amount 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '2')
        (make ac.Move
            :text "BEEP BEEP. IN 1"
            :effect ac.Effect.wait
            :amount 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '1')
        (make ac.Move
            :text "FULL SPEED BUMP #"
            :effect ac.Effect.hit
            :amount 12
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        ; dust bunny
        (make ac.Move
            :text "SNEEZE FOR #"
            :effect ac.Effect.hit
            :amount 2
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "HAIRBALL: YOUR FLUFF"
            :effect ac.Effect.junk
            :amount 1
            :aim state.Aim.foe
            :motion state.Motion.throw
            :icon '*')
        ; cucumber
        (make ac.Move
            :text "SPOOKS: DICE -# NEXT"
            :effect ac.Effect.spook
            :amount 1
            :aim state.Aim.foe
            :motion state.Motion.hop
            :icon '?')
        (make ac.Move
            :text "ROLLS AT YOU FOR #"
            :effect ac.Effect.hit
            :amount 3
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        ; sprinkler
        (make ac.Move
            :text "SPRAYS ALL FOR #"
            :effect ac.Effect.hit
            :amount 3
            :aim state.Aim.all
            :motion state.Motion.throw
            :icon '%')
        (make ac.Move
            :text "WATERS FRIENDS +#"
            :effect ac.Effect.mend
            :amount 2
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '+')
        ; hoover jr.
        (make ac.Move
            :text "CALLS # DUST BUNNIES"
            :effect ac.Effect.summon
            :amount 2
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '&')
        (make ac.Move
            :text "SUCKS FOR #"
            :effect ac.Effect.hit
            :amount 9
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "SUCKS FOR #"
            :effect ac.Effect.hit
            :amount 9
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        ; lawnmower
        (make ac.Move
            :text "REVS UP: +# FOR GOOD"
            :effect ac.Effect.grow
            :amount 1
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '^')
        (make ac.Move
            :text "MOWS FOR #"
            :effect ac.Effect.hit
            :amount 9
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        ; the mailman
        (make ac.Move
            :text "PARCEL FOR #"
            :effect ac.Effect.hit
            :amount 9
            :aim state.Aim.foe
            :motion state.Motion.throw
            :icon '!')
        (make ac.Move
            :text "RETURN TO SENDER #"
            :effect ac.Effect.reflect
            :amount 6
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '@')
        (make ac.Move
            :text "HEAVY PARCEL FOR #"
            :effect ac.Effect.hit
            :amount 10
            :aim state.Aim.foe
            :motion state.Motion.throw
            :icon '!')
        (make ac.Move
            :text "GRUMPIER: +# FOR GOOD"
            :effect ac.Effect.grow
            :amount 1
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '^')
        ; the vet
        (make ac.Move
            :text "NEEDLE: FLEAS #"
            :effect ac.Effect.fleas
            :amount 3
            :aim state.Aim.foe
            :motion state.Motion.throw
            :icon ',')
        (make ac.Move
            :text "TAKES A TEMPERATURE"
            :effect ac.Effect.steal
            :amount 0
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '$')
        (make ac.Move
            :text "CHECKUP FOR #"
            :effect ac.Effect.hit
            :amount 11
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "SNAPS GLOVES: +# GOOD"
            :effect ac.Effect.grow
            :amount 1
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '^')
        (make ac.Move
            :text "TREATS ITSELF +#"
            :effect ac.Effect.heal
            :amount 6
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '+')
        ; the big bath
        (make ac.Move
            :text "RINSE: YOU GET WET"
            :effect ac.Effect.wet
            :amount 0
            :aim state.Aim.foe
            :motion state.Motion.throw
            :icon 'W')
        (make ac.Move
            :text "SPLASH FOR #"
            :effect ac.Effect.hit
            :amount 11
            :aim state.Aim.foe
            :motion state.Motion.throw
            :icon '!')
        (make ac.Move
            :text "HAIRBALL: YOUR WAND"
            :effect ac.Effect.junk
            :amount 0
            :aim state.Aim.foe
            :motion state.Motion.throw
            :icon '*')
        ; drain gremlin
        (make ac.Move
            :text "GLUG GLUG # TWICE"
            :effect ac.Effect.hit2
            :amount 6
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "GURGLES: +# FOR GOOD"
            :effect ac.Effect.grow
            :amount 1
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '^')
        ; bulldog king
        (make ac.Move
            :text "ROYAL BARK: DICE -#"
            :effect ac.Effect.spook
            :amount 1
            :aim state.Aim.foe
            :motion state.Motion.hop
            :icon '?')
        (make ac.Move
            :text "CHOMP FOR #"
            :effect ac.Effect.hit
            :amount 12
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "THRONE NAP: SHIELD #"
            :effect ac.Effect.shield
            :amount 8
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '#')
        ; bulldog king, cross
        (make ac.Move
            :text "CALLS # ROYAL PUGS"
            :effect ac.Effect.summon
            :amount 2
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '&')
        (make ac.Move
            :text "SLOBBER ALL FOR #"
            :effect ac.Effect.hit
            :amount 5
            :aim state.Aim.all
            :motion state.Motion.throw
            :icon '%')
        (make ac.Move
            :text "CHOMP FOR #"
            :effect ac.Effect.hit
            :amount 13
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "DECREE: +# FOR GOOD"
            :effect ac.Effect.grow
            :amount 1
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '^')
        ; bulldog king, furious
        (make ac.Move
            :text "WINDS UP: FLOP IN 2"
            :effect ac.Effect.wait
            :amount 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '2')
        (make ac.Move
            :text "WINDS UP: FLOP IN 1"
            :effect ac.Effect.wait
            :amount 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '1')
        (make ac.Move
            :text "BELLY FLOP ALL #"
            :effect ac.Effect.hit
            :amount 20
            :aim state.Aim.all
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "GROWL: +# FOR GOOD"
            :effect ac.Effect.grow
            :amount 2
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '^')
        ; royal pug
        (make ac.Move
            :text "YAP FOR #"
            :effect ac.Effect.hit
            :amount 2
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "CHEER: KING +# NEXT"
            :effect ac.Effect.cheer
            :amount 2
            :aim state.Aim.friend
            :motion state.Motion.hop
            :icon '<')
        ; the old shroom
        (make ac.Move
            :text "CALLS # SPORELETS"
            :effect ac.Effect.summon
            :amount 2
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '+')
        (make ac.Move
            :text "CAP SLAM FOR #"
            :effect ac.Effect.hit
            :amount 6
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "SPORE CAP: SHIELD #"
            :effect ac.Effect.shield
            :amount 5
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '#')))
