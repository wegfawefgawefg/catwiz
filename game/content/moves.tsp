; the enemies' moves, in their own file (content/enemies would pass 500 lines). Each enemy's
; moves are rows first_move to first_move + move_count - 1 (content/enemies), made in order,
; round and round; text is 21 characters at most, # the amount (after the enemy's statuses, for
; a hit). A hairball move's amount is the slot it clogs (items.Slot: 0 wand, 1 fluff, ...). icon:
; the hud glyph over its head (tools/dhgr/game_hud.py): ! a hit, ) a hit-all, # a shield, < a
; cheer, ^ grows, : sends back, . grabs a die, - a hairball, ? spooks, , fleas, % wet, * heals,
; + calls friends; a countdown shows its number.

(import state)
(import content/action ac)

(const MOVES (array ac.Move 55)
    (make (array ac.Move 55)
        ; puffcap
        (make ac.Move
            :text "Headbutt for #"
            :effect ac.Effect.hit
            :amount 2
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "Spore shield #"
            :effect ac.Effect.shield
            :amount 2
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '#')
        ; sporelet
        (make ac.Move
            :text "Nip for #"
            :effect ac.Effect.hit
            :amount 1
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "Cheer: friend +# next"
            :effect ac.Effect.cheer
            :amount 1
            :aim state.Aim.friend
            :motion state.Motion.hop
            :icon '<')
        ; nightflap
        (make ac.Move
            :text "Scratch for #"
            :effect ac.Effect.hit
            :amount 1
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "Bite for #"
            :effect ac.Effect.hit
            :amount 1
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "Dive for #"
            :effect ac.Effect.hit
            :amount 2
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        ; garden gnome
        (make ac.Move
            :text "Guards a friend: #"
            :effect ac.Effect.shield
            :amount 3
            :aim state.Aim.friend
            :motion state.Motion.hop
            :icon '#')
        (make ac.Move
            :text "Rod poke for #"
            :effect ac.Effect.hit
            :amount 3
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        ; possum
        (make ac.Move
            :text "Bite for #"
            :effect ac.Effect.hit
            :amount 2
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "Puffs up: shield #"
            :effect ac.Effect.shield
            :amount 2
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '#')
        ; possum (faked it)
        (make ac.Move
            :text "Cheap shot for #"
            :effect ac.Effect.hit
            :amount 2
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
            :amount 2
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        ; roomba
        (make ac.Move
            :text "Beep. Bumps in 2"
            :effect ac.Effect.wait
            :amount 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '2')
        (make ac.Move
            :text "Beep beep. In 1"
            :effect ac.Effect.wait
            :amount 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '1')
        (make ac.Move
            :text "Full speed bump #"
            :effect ac.Effect.hit
            :amount 8
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        ; dust bunny
        (make ac.Move
            :text "Sneeze for #"
            :effect ac.Effect.hit
            :amount 2
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "Hairball: your fluff"
            :effect ac.Effect.junk
            :amount 1
            :aim state.Aim.foe
            :motion state.Motion.throw
            :icon '-')
        ; cucumber
        (make ac.Move
            :text "Spooks: dice -# next"
            :effect ac.Effect.spook
            :amount 1
            :aim state.Aim.foe
            :motion state.Motion.hop
            :icon '?')
        (make ac.Move
            :text "Rolls at you for #"
            :effect ac.Effect.hit
            :amount 2
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        ; sprinkler
        (make ac.Move
            :text "Sprays all for #"
            :effect ac.Effect.hit
            :amount 2
            :aim state.Aim.all
            :motion state.Motion.throw
            :icon ')')
        (make ac.Move
            :text "Waters friends +#"
            :effect ac.Effect.mend
            :amount 2
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
            :text "Sucks for #"
            :effect ac.Effect.hit
            :amount 6
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "Sucks for #"
            :effect ac.Effect.hit
            :amount 6
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        ; lawnmower
        (make ac.Move
            :text "Revs up: +# for good"
            :effect ac.Effect.grow
            :amount 2
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '^')
        (make ac.Move
            :text "Mows for #"
            :effect ac.Effect.hit
            :amount 7
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        ; the mailman
        (make ac.Move
            :text "Parcel for #"
            :effect ac.Effect.hit
            :amount 6
            :aim state.Aim.foe
            :motion state.Motion.throw
            :icon '!')
        (make ac.Move
            :text "Return to sender #"
            :effect ac.Effect.reflect
            :amount 6
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon ':')
        (make ac.Move
            :text "Heavy parcel for #"
            :effect ac.Effect.hit
            :amount 8
            :aim state.Aim.foe
            :motion state.Motion.throw
            :icon '!')
        (make ac.Move
            :text "Grumpier: +# for good"
            :effect ac.Effect.grow
            :amount 1
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '^')
        ; the vet
        (make ac.Move
            :text "Needle: fleas #"
            :effect ac.Effect.fleas
            :amount 4
            :aim state.Aim.foe
            :motion state.Motion.throw
            :icon ',')
        (make ac.Move
            :text "Takes a temperature"
            :effect ac.Effect.steal
            :amount 0
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '.')
        (make ac.Move
            :text "Checkup for #"
            :effect ac.Effect.hit
            :amount 9
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "Snaps gloves: +# good"
            :effect ac.Effect.grow
            :amount 1
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '^')
        (make ac.Move
            :text "Treats itself +#"
            :effect ac.Effect.heal
            :amount 6
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '*')
        ; the big bath
        (make ac.Move
            :text "Rinse: you get wet"
            :effect ac.Effect.wet
            :amount 0
            :aim state.Aim.foe
            :motion state.Motion.throw
            :icon '%')
        (make ac.Move
            :text "Splash for #"
            :effect ac.Effect.hit
            :amount 8
            :aim state.Aim.foe
            :motion state.Motion.throw
            :icon '!')
        (make ac.Move
            :text "Hairball: your wand"
            :effect ac.Effect.junk
            :amount 0
            :aim state.Aim.foe
            :motion state.Motion.throw
            :icon '-')
        ; drain gremlin
        (make ac.Move
            :text "Glug glug # twice"
            :effect ac.Effect.hit2
            :amount 4
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "Gurgles: +# for good"
            :effect ac.Effect.grow
            :amount 1
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '^')
        ; bulldog king
        (make ac.Move
            :text "Royal bark: dice -#"
            :effect ac.Effect.spook
            :amount 1
            :aim state.Aim.foe
            :motion state.Motion.hop
            :icon '?')
        (make ac.Move
            :text "Chomp for #"
            :effect ac.Effect.hit
            :amount 9
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "Throne nap: shield #"
            :effect ac.Effect.shield
            :amount 8
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '#')
        ; bulldog king, cross
        (make ac.Move
            :text "Calls # royal pugs"
            :effect ac.Effect.summon
            :amount 2
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '+')
        (make ac.Move
            :text "Slobber all for #"
            :effect ac.Effect.hit
            :amount 4
            :aim state.Aim.all
            :motion state.Motion.throw
            :icon ')')
        (make ac.Move
            :text "Chomp for #"
            :effect ac.Effect.hit
            :amount 10
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "Decree: +# for good"
            :effect ac.Effect.grow
            :amount 1
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '^')
        ; bulldog king, furious
        (make ac.Move
            :text "Winds up: flop in 2"
            :effect ac.Effect.wait
            :amount 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '2')
        (make ac.Move
            :text "Winds up: flop in 1"
            :effect ac.Effect.wait
            :amount 0
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '1')
        (make ac.Move
            :text "Belly flop all #"
            :effect ac.Effect.hit
            :amount 18
            :aim state.Aim.all
            :motion state.Motion.lunge
            :icon ')')
        (make ac.Move
            :text "Growl: +# for good"
            :effect ac.Effect.grow
            :amount 2
            :aim state.Aim.self
            :motion state.Motion.hop
            :icon '^')
        ; royal pug
        (make ac.Move
            :text "Yap for #"
            :effect ac.Effect.hit
            :amount 2
            :aim state.Aim.foe
            :motion state.Motion.lunge
            :icon '!')
        (make ac.Move
            :text "Cheer: king +# next"
            :effect ac.Effect.cheer
            :amount 2
            :aim state.Aim.friend
            :motion state.Motion.hop
            :icon '<')))
