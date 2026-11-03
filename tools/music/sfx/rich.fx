; rich effects for the Mockingboard: several voices at once, for tools/music/scene.py. A demo,
; not in the game. Each (rich name "what" (lane L1 "text") ...) is one effect; a lane is one
; voice, in lib/mockingboard_song's text, starting as an effect does (l1 v15 k0 m1).
;
; Lanes: L1-L3 the left chip's voices, R1-R3 the right's. A scene maps them to voices (by
; default L1=2 L2=1 L3=0 R1=5 R2=4 R3=3: the first of each side is the one the songs lend).
; The hero stands on the left, the enemies on the right: her magic starts left and lands
; right, their blows start right and land left.
;
; The chip's noise period and hardware envelope are the chip's, not a voice's: each effect
; uses noise on one lane of a chip at a time, and the envelope on one.
; Envelope sums used here (the card's clock 1,020,484 Hz):
;   h8 / h12 (a saw, over and over) at period P: 3986 / P Hz; h8:72 is A1, h8:36 A2
;   h10 / h14 (a triangle): 1993 / P Hz
;   h0 (one fall, then silent) at P: falls in P / 3986 s; h0:2000 is half a second, smooth,
;   where k steps 3 dB at a time
;   h13 (one rise, then held) at P: rises in P / 3986 s
; with m0 (no tone, no noise) the voice plays the envelope's own shape: a saw or triangle
; bass; with m1 the tone cuts it into a buzz. The envelope plays at full level: v does not
; touch it, so those lanes are kept short or under other sounds.

; ---- the hero's dice

; the tray's roll: woody clicks of tone and noise both sides, the gaps growing as the dice
; settle, and two low knocks as they land
(rich roll "the dice tray roll"
    (lane L1 "l1 m3 n3 v12 c6 m2 v8 c4 l2 r l1 m3 n2 v13 g5 l3 r l1 m3 n4 v11 d6 m2 v7 c4 l3 r l1 m3 n3 v12 a5 l5 r l1 m3 n2 v10 e6 m2 v6 c4 l6 r l1 m3 n3 v12 c6 l9 r l1 m3 n4 v11 g5 m2 v6 c4 l12 r l1 m3 n2 v12 c6 m1 l6 k2 v10 g5")
    (lane R1 "l2 r l1 m3 n3 v11 f5 m2 v7 c4 l3 r l1 m3 n4 v12 b5 l2 r l1 m3 n2 v10 d#6 m2 v7 c4 l4 r l1 m3 n3 v12 g#5 l6 r l1 m3 n4 v11 c#6 l7 r l1 m3 n2 v10 f5 m2 v6 c4 l11 r l1 m3 n3 v11 a#5 m1 l6 k2 v9 f5")
    (lane L2 "l44 r l1 v12 k0 g3 d3 l8 k2 v10 g2")
    (lane R2 "l50 r l1 v11 k0 a3 e3 l8 k2 v9 a2"))

; ---- the hero's magic, left to right

; a wand's bolt: a fizzing whistle up on the left, the hit on the right (a pitch falling
; into noise), a glitter after it
(rich zap "a wand's zap landing"
    (lane L1 "m3 n2 v11 c6 e6 g6 c7 v12 e7 g7 m1 c8 l2 k3 v10 g7")
    (lane R1 "l6 r l1 m3 n5 v15 g5 d5 a4 e4 m2 n9 v14 c4 l2 k1 v12 c4 l8 k1 v10 c4")
    (lane R2 "l8 r l1 v10 c8 g7 e7 c7 l3 k2 v9 g7 e7"))

; a crit or 255: the bolt as before, then everything at once: a saw bass diving on both chips
; (a little apart, so it is wide), a noise crash falling to rumble on both, a bright ring
; and its echo. A two-tick hush before it lands
(rich crit "a big hit: a crit, or 255"
    (lane L1 "m3 n1 v13 c5 g5 c6 g6 c7 v14 g7 m1 c8 l2 r l2 r l2 v13 k2 c8 l3 g7 l30 k2 v12 e7")
    (lane L2 "l9 r m0 l1 h8:26 c4 h8:32 c4 h8:40 c4 h8:50 c4 h8:60 c4 h8:72 c4 h8:84 c4 h8:98 c4 l2 h8:112 c4 h8:128 c4 h8:146 c4 m1 v14 k3 l40 c2")
    (lane L3 "l9 r m2 n1 v15 c4 n3 c4 n5 c4 n8 c4 n11 l2 c4 n14 c4 n18 c4 n22 l4 k1 v14 c4 n26 l40 k3 v13 c4")
    (lane R1 "l9 r m0 l1 h8:28 c4 h8:35 c4 h8:43 c4 h8:53 c4 h8:64 c4 h8:76 c4 h8:89 c4 h8:103 c4 l2 h8:118 c4 h8:134 c4 h8:152 c4 m1 v14 k3 l40 c#2")
    (lane R2 "l9 r m2 n2 v15 c4 n4 c4 n7 c4 n10 c4 n13 l2 c4 n17 c4 n21 c4 n25 l4 k1 v14 c4 n29 l40 k3 v13 c4")
    (lane R3 "l12 r l2 v13 k1 c7 e7 g7 b7 l30 k2 v12 c8 l8 r l2 v8 k1 g7 b7 l20 k2 v7 c8"))

; a book's spell: two pages flipped, a swell (the envelope's slow rise on a low tone) under a
; turning arpeggio both sides, then the spell goes: a flash of noise, a sweep up, a bell
(rich book "a spell cast from a book"
    (lane L1 "m2 n2 l1 v5 c4 v9 c4 v12 c4 v8 c4 v4 c4 l3 r l1 v6 c4 v10 c4 v13 c4 v8 c4 v4 c4 l2 r m1 h13:2400 l36 a3 l1 m2 n1 v15 c4 v14 c4 n2 v13 c4 n3 l2 v12 c4 n4 l16 k1 v11 c4")
    (lane L2 "l14 r l2 v6 k0 a5 c#6 e6 g#6 v8 a5 c#6 e6 g#6 v10 a5 c#6 e6 g#6 v11 a5 c#6 e6 g#6 l1 v12 a5 c#6 e6 g#6 a6 c#7 e7 g#7 a7 l24 k2 v11 e8")
    (lane R1 "l16 r l2 v5 k0 e6 g#6 b6 d#7 v7 e6 g#6 b6 d#7 v9 e6 g#6 b6 d#7 v10 e6 g#6 b6 d#7 v11 e6 g#6 b6 d#7 l30 k2 v13 a6")
    (lane R2 "l52 r l2 v12 k1 c#7 e7 a7 l20 k2 v10 c#8 l6 r l2 v6 k1 e7 a7 l14 k2 v5 c#8"))

; mana from a star: a sparkle ping-ponging up, left and right, over a soft low root, then a
; glitter dying away on the right
(rich mana "mana gained: a star's sparkle"
    (lane L1 "l2 v13 k1 e6 l4 r l2 b6 l4 r l2 e7 l24 k2 v12 b7")
    (lane R1 "l3 r l2 v12 k1 g#6 l4 r l2 e7 l4 r l2 g#7 l24 k2 v11 e8")
    (lane L2 "l40 v9 k3 e5")
    (lane R2 "l16 r l1 v8 b7 e8 v7 b7 e8 v6 b7 e8 v6 b7 e8 v5 b7 e8 v4 b7 e8 v3 b7 e8 v2 b7 e8"))

; ---- fluff

; a shield going up: an airy swell of noise on the left, a soft fifth rising both sides, a
; little shimmer on top
(rich shield "a shield going up (fluff)"
    (lane L1 "m2 n13 l2 v6 c4 v8 c4 v10 c4 v12 c4 n11 v13 c4 n10 l16 k2 v12 c4")
    (lane L2 "l2 r l3 v11 k0 c5 g5 c6 l3 e6 l24 k3 v13 g6")
    (lane R1 "l5 r l3 v10 k0 e5 c6 e6 l3 g6 l24 k3 v12 c7")
    (lane R2 "l14 r l1 v8 g7 r v8 c8 r v7 g7 r v7 c8 r v6 g7 r v5 c8 r v4 g7 r v3 c8"))

; a shield taking a blow: a pillowy thump on her side, a bell, its echo on the other side
(rich block "a shield taking a blow"
    (lane L1 "m3 n18 v15 a3 f3 d3 m2 n22 l2 k1 v13 c4 l10 k1 v10 c4")
    (lane L2 "l2 v13 e7 l40 k3 v12 b6")
    (lane R1 "l8 r l2 v8 e7 l30 k3 v8 b6"))

; ---- curses on the enemies

; fleas: tiny bites hopping about both sides, a thin high trill itching under them, a few
; hops at the end
(rich fleas "fleas biting"
    (lane L1 "m3 n1 v15 f7 r l3 r l1 v13 g7 r l5 r l1 v15 f#7 r l2 r l1 v12 a7 l7 r l1 v14 g7 r l4 r l1 v15 f7")
    (lane R1 "l2 r l1 m3 n1 v14 g#7 l4 r l1 v15 f7 r l3 r l1 v13 a#7 l6 r l1 v15 g7 r l2 r l1 v12 f#7 l5 r l1 v14 a7")
    (lane L2 "v7 a7 a#7 v6 a7 a#7 v7 a7 a#7 v5 a7 a#7 v7 a7 a#7 v6 a7 a#7 v7 a7 a#7 v5 a7 a#7 v6 a7 a#7 v5 a7 a#7 v4 a7 a#7")
    (lane R2 "l32 r l2 v9 k3 g6 r a6 r l4 b6"))

; wet: a splash of noise, bright and falling, on both chips, a bloop, drops after
(rich wet "wet: a splash"
    (lane L1 "m2 n1 v13 c4 n2 v12 c4 n3 c4 n4 v11 c4 n5 l2 v10 c4 n6 v9 c4 n8 l20 k2 v8 c4")
    (lane R1 "l1 r m2 n2 v12 c4 n3 c4 n5 v11 c4 n6 c4 l2 n7 v10 c4 n9 v9 c4 l20 k2 n10 v8 c4")
    (lane L2 "l1 v12 c5 e5 g5 c6 l8 k2 e6")
    (lane R2 "l14 r l1 v10 k0 g6 b6 l2 k3 d7 l6 r l1 v8 e6 g6 l2 k3 b6 l9 r l1 v7 a6 c7 l2 k3 e7")
    (lane L3 "l22 r l1 v9 c7 e7 l2 k3 g7 l8 r l1 v7 f6 a6 l2 k3 c7"))

; lightning: a crack on both chips, a zigzag of high tone, a saw bass boom, then thunder
; rolling from side to side
(rich lightning "a lightning curse"
    (lane L1 "m3 n0 v15 c8 b7 c8 m2 c4 l2 n1 c4 n3 c4 n24 l3 v13 c4 v9 c4 v12 c4 v7 c4 v11 c4 v6 c4 v10 c4 v5 c4 v9 c4 v4 c4 v7 c4 l20 k3 v6 c4")
    (lane R1 "m3 n0 v15 b7 c8 b7 m2 c4 l2 n1 c4 n4 c4 n27 l3 v8 c4 v12 c4 v7 c4 v11 c4 v6 c4 v10 c4 v5 c4 v9 c4 v4 c4 v8 c4 l20 k3 v7 c4")
    (lane L2 "l3 r m0 l1 h8:110 c4 h8:116 c4 h8:122 c4 h8:128 c4 l2 h8:134 c4 h8:140 c4 m1 v13 k4 l60 d#1")
    (lane R2 "l1 v13 c8 f#7 b7 f7 a#7 e7 a7 d#7 g#7 d7 l3 k2 g7"))

; ---- her heart

; a heal: a heartbeat (ba-dum), then hearts rising, a major arpeggio in thirds left and
; right over a warm low note, a twinkle at the top
(rich heal "a heal: hearts rising"
    (lane L1 "v13 k0 c3 a2 f2 l5 r l1 v11 c3 a2 f2 l40 r")
    (lane L2 "l10 r l3 v11 k1 c5 e5 g5 c6 e6 g6 l24 k2 c7")
    (lane R1 "l13 r l3 v9 k1 e5 g5 c6 e6 g6 c7 l24 k2 e7")
    (lane R2 "l30 r l2 v8 k2 g7 r c8 r l12 e8")
    (lane L3 "l10 r l60 v9 k6 c4"))

; ---- the enemies' turn, right to left

; an enemy's blow: a whoosh winding up on its side, the thud on hers (a saw bass diving
; into a low tone, a burst of dark noise), her mrrp
(rich thud "an enemy's blow landing on her"
    (lane R1 "m2 n12 v4 c4 v6 c4 n10 v8 c4 v10 c4 n7 v12 c4 n5 v13 c4 n3 l2 k3 v9 c4")
    (lane L1 "l6 r m0 l1 h8:48 c4 h8:60 c4 h8:74 c4 h8:90 c4 h8:108 c4 l2 h8:128 c4 m1 v13 k2 l20 d#2")
    (lane L2 "l6 r m2 n14 v15 c4 n18 l2 v14 c4 n22 l12 k1 v12 c4")
    (lane L3 "l12 r l2 v12 e6 d6 c6 a5 g5 l6 k2 e5"))

; an enemy falling: a spinning squeak down on its side, a bump on the floor and a puff of
; dust, then her little pip-pip on the left
(rich fall "an enemy beaten, falling"
    (lane R1 "v14 g6 a6 f6 g6 e6 f#6 d6 e6 c6 d6 b5 c6 a5 b5 g5 a5 f5 g5 e5 f5 d5 l2 k1 v12 c5 b4 a4")
    (lane R2 "l28 r m3 n16 v15 c3 a2 f2 m2 n20 l2 v12 c4 l14 k1 v10 c4")
    (lane L1 "l6 r l1 v6 g6 a6 f6 g6 e6 f#6 d6 e6 c6 d6 l4 k1 v5 b5")
    (lane L2 "l46 r l3 v11 k1 g6 r l12 c7"))

; ---- the dice

; three of a kind: ding on the left, ding on the right, DING on both with a G major on top,
; a run up, a crash and a bass under it
(rich three "three of a kind"
    (lane L1 "m3 n1 v13 g6 m1 l7 k2 v12 g6 l8 r l1 m3 n1 v14 d7 m1 l40 k3 v13 d7")
    (lane R1 "l8 r l1 m3 n1 v13 b6 m1 l7 k2 v12 b6 l1 m3 n1 v14 g7 m1 l40 k3 v13 g7")
    (lane L2 "l16 r l2 v13 b6 l50 k4 v12 b6")
    (lane R2 "l18 r l1 v11 g5 b5 d6 g6 b6 d7 g7 b7 d8 l20 k2 v9 g8")
    (lane L3 "l16 r l3 v14 k1 g2 l24 k2 v13 g3")
    (lane R3 "l16 r m2 l40 v12 k3 c4"))

; ---- the end of a fight (a fight won is stingers.fx's fight_won)

; defeat: her last mew falling, a low thump, two sad notes and a long low A
(rich defeat "the hero beaten"
    (lane L1 "l2 v12 g5 b5 d6 l3 c6 a5 f5 d5 l20 k1 v10 b4")
    (lane L2 "l22 r m3 n18 v14 c3 a2 f2 m2 n24 l20 k1 v11 c4")
    (lane R1 "l30 r l10 v10 k1 e5 c5 l40 k2 v11 a4")
    (lane R2 "l30 r l10 v8 k1 c5 g#4 l40 k2 v9 e4")
    (lane L3 "l30 r l20 v10 k0 a2 - l40 k3 a1"))

; ---- the Bulldog King

; his roar: a growl (a buzzing saw bass, wobbling, rising) over noise shuddering on both
; chips, then two barks: each a falling tone through noise, and the bass's own drop
(rich roar "the Bulldog King's roar and bark"
    (lane L1 "l2 h8:96 c2 h8:92 c2 h8:98 c2 h8:90 c2 h8:94 c2 h8:86 c2 h8:90 c2 h8:82 c2 h8:86 c2 h8:78 c2 h8:80 c2 h8:72 c2 h8:74 c2 h8:66 c2 h8:68 c2 h8:60 c2 l3 r l1 m0 h8:40 c4 h8:52 c4 h8:66 c4 h8:84 c4 l6 r l1 h8:38 c4 h8:50 c4 h8:64 c4 h8:82 c4 h8:104 c4 m1 v12 k2 l20 a1")
    (lane R1 "l2 h8:100 c#2 h8:94 c#2 h8:102 c#2 h8:92 c#2 h8:98 c#2 h8:88 c#2 h8:94 c#2 h8:84 c#2 h8:90 c#2 h8:80 c#2 h8:84 c#2 h8:74 c#2 h8:78 c#2 h8:68 c#2 h8:72 c#2 h8:62 c#2 l3 r l1 m3 n6 v15 a4 f#4 d#4 c4 l6 r l1 a4 f#4 d#4 c4 a3 m2 n10 l12 k1 v12 c4")
    (lane L2 "m2 n24 l2 v8 c4 v11 c4 v7 c4 v12 c4 v8 c4 v12 c4 v9 c4 v13 c4 v9 c4 v13 c4 v10 c4 v14 c4 v10 c4 v14 c4 v11 c4 v14 c4 l3 r l1 n7 v15 c4 v14 c4 n9 v13 c4 v11 c4 l6 r l1 n7 v15 c4 v14 c4 n9 v13 c4 n12 l12 k1 v12 c4")
    (lane R2 "l3 r l2 v4 g4 a4 g4 a#4 g4 a#4 a4 b4 a4 c5 a#4 c#5 b4 d5 c5 d#5 l35 r"))
