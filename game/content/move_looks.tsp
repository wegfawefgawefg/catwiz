; how each enemy move looks and sounds, by its row of content/moves MOVES (the same order; in
; its own file, so moves.tsp stays the rules): show, its show (content/shows: the bolt thrown,
; its own sprites thrown or played over whoever it is for: shows.FOE ones are the mover's shot
; roles, tools/dhgr/figures.py), and cue, the sound as it starts (sound.Cue: the growl unless
; it has its own). In aux memory, read through look and cue

(import content/shows)
(import sound/sound)

(struct MoveLook ((show u8) (cue u8)))

(const GROWL u8 (as u8 sound.Cue.growl))

(const LOOKS (array MoveLook 58)
    (make (array MoveLook 58)
        (make MoveLook :show shows.BOLT :cue GROWL) ; puffcap: Headbutt for #
        (make MoveLook :show shows.BOLT :cue GROWL) ; puffcap: Spore shield #
        (make MoveLook :show shows.BOLT :cue GROWL) ; sporelet: Nip for #
        (make MoveLook :show shows.BOLT :cue GROWL) ; sporelet: Cheer: friend +# next
        (make MoveLook :show shows.BOLT :cue GROWL) ; nightflap: Scratch for #
        (make MoveLook :show shows.BOLT :cue GROWL) ; nightflap: Bite for #
        (make MoveLook :show shows.BOLT :cue GROWL) ; nightflap: Dive for #
        (make MoveLook :show shows.GUARD :cue GROWL) ; garden gnome: Guards a friend: #
        (make MoveLook :show shows.HOOK :cue GROWL) ; garden gnome: Rod poke for #
        (make MoveLook :show shows.BITE :cue GROWL) ; possum: Bite for #
        (make MoveLook :show shows.PUFF :cue GROWL) ; possum: Puffs up: shield #
        (make MoveLook :show shows.SMACK :cue GROWL) ; possum (faked it): Cheap shot for #
        (make MoveLook :show shows.SNATCH :cue GROWL) ; squirrel: Grabs your last die
        (make MoveLook :show shows.ACORN :cue GROWL) ; squirrel: Acorn for #
        (make MoveLook :show shows.BOLT :cue GROWL) ; roomba: Beep. Bumps in 2
        (make MoveLook :show shows.BOLT :cue GROWL) ; roomba: Beep beep. In 1
        (make MoveLook :show shows.BOLT :cue GROWL) ; roomba: Full speed bump #
        (make MoveLook :show shows.BOLT :cue GROWL) ; dust bunny: Sneeze for #
        (make MoveLook :show shows.BOLT :cue GROWL) ; dust bunny: Hairball: your fluff
        (make MoveLook :show shows.FRIGHT :cue GROWL) ; cucumber: Spooks: dice -# next
        (make MoveLook :show shows.BUMP :cue GROWL) ; cucumber: Rolls at you for #
        (make MoveLook :show shows.SPRAY_ALL :cue GROWL) ; sprinkler: Sprays all for #
        (make MoveLook :show shows.FOUNTAIN :cue GROWL) ; sprinkler: Waters friends +#
        (make MoveLook :show shows.BOLT :cue GROWL) ; hoover jr.: Calls # dust bunnies
        (make MoveLook :show shows.BOLT :cue GROWL) ; hoover jr.: Sucks for #
        (make MoveLook :show shows.BOLT :cue GROWL) ; hoover jr.: Sucks for #
        (make MoveLook :show shows.REVS :cue GROWL) ; lawnmower: Revs up: +# for good
        (make MoveLook :show shows.CLIPPINGS :cue GROWL) ; lawnmower: Mows for #
        (make MoveLook :show shows.PARCEL :cue GROWL) ; the mailman: Parcel for #
        (make MoveLook :show shows.MIRROR :cue GROWL) ; the mailman: Return to sender #
        (make MoveLook :show shows.HEAVY :cue GROWL) ; the mailman: Heavy parcel for #
        (make MoveLook :show shows.BOLT :cue GROWL) ; the mailman: Grumpier: +# for good
        (make MoveLook :show shows.BOLT :cue GROWL) ; the vet: Needle: fleas #
        (make MoveLook :show shows.BOLT :cue GROWL) ; the vet: Takes a temperature
        (make MoveLook :show shows.BOLT :cue GROWL) ; the vet: Checkup for #
        (make MoveLook :show shows.BOLT :cue GROWL) ; the vet: Snaps gloves: +# good
        (make MoveLook :show shows.BOLT :cue GROWL) ; the vet: Treats itself +#
        (make MoveLook :show shows.BOLT :cue GROWL) ; the big bath: Rinse: you get wet
        (make MoveLook :show shows.BOLT :cue GROWL) ; the big bath: Splash for #
        (make MoveLook :show shows.BOLT :cue GROWL) ; the big bath: Hairball: your wand
        (make MoveLook :show shows.BOLT :cue GROWL) ; drain gremlin: Glug glug # twice
        (make MoveLook :show shows.BOLT :cue GROWL) ; drain gremlin: Gurgles: +# for good
        (make MoveLook :show shows.BUMP :cue GROWL) ; bulldog king: Royal bite # twice (its teeth over her)
        (make MoveLook :show shows.BUMP :cue GROWL) ; bulldog king: Chomp # twice
        (make MoveLook :show shows.BOLT :cue GROWL) ; bulldog king: Royal swat # twice
        (make MoveLook :show shows.BOLT :cue GROWL) ; bulldog king, cross: Calls # royal pugs
        (make MoveLook :show shows.ACORN :cue GROWL) ; bulldog king, cross: Slobber # twice (thrown)
        (make MoveLook :show shows.BUMP :cue GROWL) ; bulldog king, cross: Chomp # twice
        (make MoveLook :show shows.BOLT :cue GROWL) ; bulldog king, cross: Decree: +# for good
        (make MoveLook :show shows.SMACK :cue GROWL) ; bulldog king, furious: Paw swipe # twice (a blow's star)
        (make MoveLook :show shows.BITE :cue GROWL) ; bulldog king, furious: Flails # twice
        (make MoveLook :show shows.BUMP :cue GROWL) ; bulldog king, furious: Belly flop # twice
        (make MoveLook :show shows.BOLT :cue GROWL) ; bulldog king, furious: Growl: +# for good
        (make MoveLook :show shows.FRIGHT :cue GROWL) ; royal pug: Yap for # (over her head)
        (make MoveLook :show shows.BOLT :cue GROWL) ; royal pug: Cheer: king +# next
        (make MoveLook :show shows.BOLT :cue GROWL) ; the old shroom: Calls # sporelets
        (make MoveLook :show shows.BOLT :cue GROWL) ; the old shroom: Cap slam for #
        (make MoveLook :show shows.BOLT :cue GROWL)) ; the old shroom: Spore cap: shield #
    :in aux)

(fn show ((row u8)) u8
    (with_aux true false
        (at LOOKS row show)))

(fn cue ((row u8)) u8
    (with_aux true false
        (at LOOKS row cue)))
