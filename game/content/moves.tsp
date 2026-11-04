; the enemies' moves, in their own file (content/enemies would pass 500 lines). Each enemy's
; moves are rows first_move to first_move + move_count - 1 (content/enemies), made in order,
; round and round; text is 21 characters at most, # the amount (after the enemy's statuses, for
; a hit). A hairball move's amount is the slot it clogs (items.Slot: 0 wand, 1 fluff, ...). icon:
; the hud glyph over its head (tools/dhgr/game_hud.py): ! a hit, ) a hit-all, # a shield, < a
; cheer, ^ grows, : sends back, . grabs a die, - a hairball, ? spooks, , fleas, % wet, * heals,
; + calls friends; a countdown shows its number.

(import state)
(import content/action ac)

(const MOVES (array ac.Move 58)
    (make (array ac.Move 58)
        ; puffcap
        (make ac.Move
            :text "Headbutt for #"
            :effect ac.Effect.hit
            :amount 4
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "Spore shield #"
            :effect ac.Effect.shield
            :amount 4
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '#')
        ; sporelet
        (make ac.Move
            :text "Nip for #"
            :effect ac.Effect.hit
            :amount 2
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "Cheers a friend +#"
            :effect ac.Effect.cheer
            :amount 2
            :aim state.Aim.friend
            :motion state.Motion.hop
            :icon '<')
        ; nightflap
        (make ac.Move
            :text "Scratch for #"
            :effect ac.Effect.hit
            :amount 2
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "Bite for #"
            :effect ac.Effect.hit
            :amount 2
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "Dive for #"
            :effect ac.Effect.hit
            :amount 4
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        ; garden gnome
        (make ac.Move
            :text "Shields a friend #"
            :effect ac.Effect.shield
            :amount 6
            :aim state.Aim.friend
            :motion state.Motion.hop
            :icon '#')
        (make ac.Move
            :text "Rod poke for #"
            :effect ac.Effect.hit
            :amount 6
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        ; possum
        (make ac.Move
            :text "Bite for #"
            :effect ac.Effect.hit
            :amount 4
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "Puffs up: shield #"
            :effect ac.Effect.shield
            :amount 4
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '#')
        ; possum (faked it)
        (make ac.Move
            :text "Cheap shot for #"
            :effect ac.Effect.hit
            :amount 4
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        ; squirrel
        (make ac.Move
            :text "Grabs your last die"
            :effect ac.Effect.steal
            :amount 0
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '.')
        (make ac.Move
            :text "Acorn for #"
            :effect ac.Effect.hit
            :amount 4
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        ; roomba
        (make ac.Move
            :text "Bumps in 2 turns"
            :effect ac.Effect.wait
            :amount 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '2')
        (make ac.Move
            :text "Bumps next turn"
            :effect ac.Effect.wait
            :amount 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '1')
        (make ac.Move
            :text "2 bumps of #"
            :effect ac.Effect.hit2
            :amount 5
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        ; dust bunny
        (make ac.Move
            :text "Sneeze for #"
            :effect ac.Effect.hit
            :amount 4
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "Clogs your fluff face"
            :effect ac.Effect.junk
            :amount 1
            :aim state.Aim.foe
            :motion state.Motion.throw
            :icon '-')
        ; cucumber
        (make ac.Move
            :text "Spooks your dice -#"
            :effect ac.Effect.spook
            :amount 1
            :aim state.Aim.foe
            :motion state.Motion.hop
            :icon '?')
        (make ac.Move
            :text "Rolls at you for #"
            :effect ac.Effect.hit
            :amount 4
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        ; sprinkler
        (make ac.Move
            :text "Sprays all for #"
            :effect ac.Effect.hit
            :amount 4
            :aim state.Aim.all
            :motion state.Motion.throw
            :icon ')')
        (make ac.Move
            :text "Waters friends +# hp"
            :effect ac.Effect.mend
            :amount 4
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '*')
        ; hoover jr.
        (make ac.Move
            :text "Calls # dust bunnies"
            :effect ac.Effect.summon
            :amount 2
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '+')
        (make ac.Move
            :text "Sucks twice for #"
            :effect ac.Effect.hit2
            :amount 2
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "Sucks twice for #"
            :effect ac.Effect.hit2
            :amount 2
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        ; lawnmower
        (make ac.Move
            :text "Revs up, +# strength"
            :effect ac.Effect.grow
            :amount 2
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '^')
        (make ac.Move
            :text "Mows twice for #"
            :effect ac.Effect.hit2
            :amount 3
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        ; the mailman
        (make ac.Move
            :text "2 parcels of #"
            :effect ac.Effect.hit2
            :amount 3
            :aim state.Aim.foe
            :motion state.Motion.throw
            :icon '!')
        (make ac.Move
            :text "Return to sender #"
            :effect ac.Effect.reflect
            :amount 8
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon ':')
        (make ac.Move
            :text "2 heavy parcels of #"
            :effect ac.Effect.hit2
            :amount 4
            :aim state.Aim.foe
            :motion state.Motion.throw
            :icon '!')
        (make ac.Move
            :text "Grumps, +# strength"
            :effect ac.Effect.grow
            :amount 2
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '^')
        ; the vet
        (make ac.Move
            :text "Gives you # fleas"
            :effect ac.Effect.fleas
            :amount 4
            :aim state.Aim.foe
            :motion state.Motion.throw
            :icon ',')
        (make ac.Move
            :text "2 thermometers of #"
            :effect ac.Effect.hit2
            :amount 3
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "2 checkups of #"
            :effect ac.Effect.hit2
            :amount 4
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "Gloves on, +# strength"
            :effect ac.Effect.grow
            :amount 2
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '^')
        (make ac.Move
            :text "2 injections of #"
            :effect ac.Effect.hit2
            :amount 4
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        ; the big bath
        (make ac.Move
            :text "Rinse makes you wet"
            :effect ac.Effect.wet
            :amount 0
            :aim state.Aim.foe
            :motion state.Motion.throw
            :icon '%')
        (make ac.Move
            :text "2 splashes of #"
            :effect ac.Effect.hit2
            :amount 3
            :aim state.Aim.foe
            :motion state.Motion.throw
            :icon '!')
        (make ac.Move
            :text "2 scrubs of #"
            :effect ac.Effect.hit2
            :amount 4
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        ; drain gremlin
        (make ac.Move
            :text "Glugs twice for #"
            :effect ac.Effect.hit2
            :amount 3
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "Gurgles, +# strength"
            :effect ac.Effect.grow
            :amount 2
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '^')
        ; bulldog king
        (make ac.Move
            :text "2 royal bites of #"
            :effect ac.Effect.hit2
            :amount 4
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "2 chomps of #"
            :effect ac.Effect.hit2
            :amount 4
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "2 royal swats of #"
            :effect ac.Effect.hit2
            :amount 4
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        ; bulldog king, cross
        (make ac.Move
            :text "Calls # royal pugs"
            :effect ac.Effect.summon
            :amount 2
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '+')
        (make ac.Move
            :text "2 slobbers of #"
            :effect ac.Effect.hit2
            :amount 3
            :aim state.Aim.foe
            :motion state.Motion.throw
            :icon '!')
        (make ac.Move
            :text "2 chomps of #"
            :effect ac.Effect.hit2
            :amount 4
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "Decrees +# strength"
            :effect ac.Effect.grow
            :amount 2
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '^')
        ; bulldog king, furious
        (make ac.Move
            :text "2 paw swipes of #"
            :effect ac.Effect.hit2
            :amount 4
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "Flails twice for #"
            :effect ac.Effect.hit2
            :amount 4
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "2 belly flops of #"
            :effect ac.Effect.hit2
            :amount 4
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "Growls, +# strength"
            :effect ac.Effect.grow
            :amount 3
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '^')
        ; royal pug
        (make ac.Move
            :text "Yap for #"
            :effect ac.Effect.hit
            :amount 4
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "Cheers the king +#"
            :effect ac.Effect.cheer
            :amount 2
            :aim state.Aim.friend
            :motion state.Motion.hop
            :icon '<')
        ; the old shroom
        (make ac.Move
            :text "Calls # sporelets"
            :effect ac.Effect.summon
            :amount 2
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '+')
        (make ac.Move
            :text "2 cap slams of #"
            :effect ac.Effect.hit2
            :amount 3
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "2 spore storms of #"
            :effect ac.Effect.hit2
            :amount 3
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!'))
    :in aux)

; MOVES is in aux memory (:in aux, with its text: main memory is full): its fields are read here,
; one at a time
(fn effect ((row u8)) ac.Effect
    (with_aux true false
        (at MOVES row effect)))

(fn amount ((row u8)) u8
    (with_aux true false
        (at MOVES row amount)))

(fn aim ((row u8)) state.Aim
    (with_aux true false
        (at MOVES row aim)))

(fn motion ((row u8)) state.Motion
    (with_aux true false
        (at MOVES row motion)))

(fn icon ((row u8)) u8
    (with_aux true false
        (at MOVES row icon)))

(fn text ((row u8)) (ptr u8)
    (with_aux true false
        (at MOVES row text)))
