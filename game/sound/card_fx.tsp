; the effects on the Mockingboard, in lib/mockingboard_song's text (a tick is 1/60 s; an
; effect starts at l1 v15 k0 m1). Short and soft-edged: notes that fall away with k, noise
; only as a dash. game/sound/sound.tsp picks the voice each borrows from the music. The speaker
; has its own versions in sfx.tsp.

(import mockingboard_song tune)

; one shake of the dice: three dry clicks
(tune.effect rattle "m2 n2 v12 c4 r n5 v9 c4 r n1 v11 c4")

; a die played: a woody tok
(tune.effect tok "m3 n3 v13 c6 m1 v12 g5 l3 k3 c6")

; a magic bolt lands: a quick whistle up, short, since the thump of the blow waits for it
(tune.effect zap "v13 e5 a5 d6 g6 l3 k5 c7")

; a blow that lands: a thump, then a puff of low noise
(tune.effect thump "m3 n12 g3 e3 c3 m2 n18 l4 k2 c4")

; a blow a shield took: a small bell
(tune.effect ping "v14 e6 l12 k1 b6")

; hit points back: three notes up
(tune.effect chime "l4 v12 k1 c#6 e6 l14 a6")

; a fire catching: crackles, then a hiss
(tune.effect hiss "m2 n1 v14 c4 r v11 c4 r n2 l12 k1 v13 c4")

; spooked: a sliding wobble down
(tune.effect wobble "l2 v12 e5 f5 e5 d#5 d5 c#5 d5 c5 l8 k2 b4")

; a die that does nothing: a soft puff
(tune.effect puff "m2 n20 l10 v10 k1 c4")

; an enemy beaten: two falling chirps
(tune.effect squeak "v14 g6 e6 c6 a5 r f6 d6 b5 g5 l3 k3 e5")

; the hero hurt: a yelp
(tune.effect yelp "m3 n10 e6 m1 d6 c6 a5 g5 e5 l3 k3 c5")

; an enemy winds up its move: a little growl rising
(tune.effect growl "l2 m3 n14 v11 c3 d#3 m1 f#3 l4 k2 a3")

; the hero's turn: two notes up; her turn over: two down
(tune.effect turn_on "l3 v10 k1 e5 l8 a5")
(tune.effect turn_off "l3 v10 k1 a5 l8 e5")

; the target moves: a blip
(tune.effect blip "v9 c6 l2 k4 g6")

; RETURN on the title
(tune.effect confirm "l2 v13 a5 c#6 l12 k1 e6")

; a key that does nothing now: a soft low bonk
(tune.effect nope "l2 v9 k3 e3")

; the hero's meow: a mew sliding up, then down
(tune.effect meow "v12 l2 g5 b5 d6 f6 l3 e6 d6 l10 k2 b5")

; ---- the chain cards' own (2026-11-01), each named in its card's steps (content/cards.tsp)

; Red Dot: a laser dot darting, three tiny high blips
(tune.effect dart "l2 v12 k2 e7 r b6 r f7")

; Mimic: a copycat's mew and its echo
(tune.effect mimic "l2 v12 k2 g5 c6 l2 v8 g5 l6 k2 c6")

; Catfight: a yowl, half a hiss
(tune.effect yowl "l2 m3 n6 v13 f5 e5 m1 g5 f#5 l6 k2 d5")

; Mirror Fur: a shimmer up, glassy
(tune.effect shimmer "l2 v12 k1 e6 g#6 b6 l10 k1 e7")

; Lucky Paw: a lucky cat's bell, twice
(tune.effect lucky "l3 v12 k1 b6 r l10 k1 b6")

; Flea Circus: fleas hopping on, hop hop hop
(tune.effect hops "l2 v11 k3 g6 r a6 r l4 b6")

; Sunbeam: a warm glow coming up
(tune.effect glow "l3 v10 k1 c5 e5 g5 l12 k1 c6")

; Scratching Habit: three quick scratches
(tune.effect scratch "m2 n3 l2 v13 c4 r n2 c4 r n1 l4 k2 c4")

; Double or Nothing: a coin flipped, ting, and caught
(tune.effect coin "l2 v13 k1 b6 e7 r l10 k1 e7")

; ---- the faces round's sounds (docs/faces.md): placeholders, each a copy of an older one until
; the sounds job makes it
(tune.effect buzz "l2 v11 k3 g6 r a6 r l4 b6") ; placeholder: hops
(tune.effect splash "m2 n20 l10 v10 k1 c4") ; placeholder: puff
(tune.effect thunder "m3 n12 g3 e3 c3 m2 n18 l4 k2 c4") ; placeholder: thump
(tune.effect slurp "l4 v12 k1 c#6 e6 l14 a6") ; placeholder: chime
(tune.effect snore "l2 v12 e5 f5 e5 d#5 d5 c#5 d5 c5 l8 k2 b4") ; placeholder: wobble
(tune.effect boing "v9 c6 l2 k4 g6") ; placeholder: blip
(tune.effect whoosh "v13 e5 a5 d6 g6 l3 k5 c7") ; placeholder: zap
(tune.effect sparkle "l3 v10 k1 c5 e5 g5 l12 k1 c6") ; placeholder: glow
