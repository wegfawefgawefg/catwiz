; stingers: short fanfares for the game's events, in rich.fx's form (lanes L1-L3 left, R1-R3
; right; each starts l1 v15 k0 m1). A demo, not in the game. Each could be played as a short
; song (its lanes the voices, each ending on a long rest it loops on, as songs.tsp's WON) or,
; once the player can start several effect lanes at once, as a resident rich effect.
;
; Keys: the fights are in A (dorian), so the wins are in A major, as today's WON; the King's
; in A minor with a tritone in it.
; The envelope bass (m0 and h8:P, a saw at 3986 / P Hz: A1 72, D2 54, E2 48, A2 36) plays at
; full level, so it gets one lane, and its last note goes back to a plain tone to fade.

; ---- in a fight

; a fight won, every fight: light and quick, a "ta-da": arpeggio up both sides a third apart
; over a little bass pom-POM, a glitter when it lands. About 1.1 s
(rich fight_won "a fight won"
    (lane L1 "l5 v12 k1 e5 a5 c#6 l8 e6 l40 k2 v13 a6")
    (lane R1 "l7 r l5 v10 k1 a5 c#6 l8 e6 l40 k2 v11 c#7")
    (lane L2 "l5 v11 k1 e2 l10 r l40 k2 v13 a2")
    (lane R2 "l23 r l1 v8 a7 e8 c#8 a7 e7 c#7 l14 k1 v7 a6"))

; an elite beaten: bigger, a fanfare. A pickup arpeggio, then I IV V I under a melody in
; thirds, a saw bass (the envelope) like a tuba, a cymbal swelling into a crash on the last
; chord, a timpani hit and a run up to the top. About 2.4 s
(rich elite "an elite beaten"
    (lane L1 "l6 v13 k1 a4 c#5 e5 l18 k2 a5 l6 k1 g#5 f#5 g#5 l40 k3 v14 a5")
    (lane R1 "l6 v11 k1 e4 a4 c#5 l18 k2 e5 l6 k1 e5 d5 e5 l40 k3 v12 c#5")
    (lane L2 "m0 l18 h8:72 c4 h8:54 c4 h8:48 c4 m1 v14 k3 l48 a1")
    (lane R2 "l54 r l1 v10 a5 c#6 e6 a6 c#7 e7 a7 l30 k2 v10 c#8 l10 r l1 v6 a7 e8 l20 k2 v5 c#8")
    (lane R3 "l36 r m2 n2 l3 v3 c4 v5 c4 v7 c4 v9 c4 v10 c4 v11 c4 l48 k3 v13 c4")
    (lane L3 "l54 r l1 v14 k0 a2 e2 a1 l30 k3 v12 a2"))

; ---- the reward screen and the map

; a card taken: a swish of the card off the table, a snap into the deck, two notes up
(rich card "a card taken"
    (lane L1 "m2 n1 v6 c4 v9 c4 n2 v11 c4 n3 v9 c4 n5 v6 c4 l2 r l1 m3 n8 v13 c5 m2 v8 c4")
    (lane R1 "l9 r l3 v11 k1 e6 l16 k2 a6"))

; an upgrade, +1 on a face: rising and sparkly. Two whole-tone runs up, a third apart and
; 3 ticks apart left and right, landing on a bright C with a bell, then glitter. About 1.2 s
(rich upgrade "an upgrade: +1 on a face"
    (lane L1 "l1 v9 c5 d5 e5 f#5 g#5 a#5 v10 c6 d6 e6 f#6 g#6 a#6 v11 c7 d7 e7 l30 k2 v12 g7")
    (lane R1 "l3 r l1 v7 e5 f#5 g#5 a#5 c6 d6 v8 e6 f#6 g#6 a#6 c7 d7 v9 e7 f#7 g#7 l30 k2 v10 c8")
    (lane L2 "l18 r l2 v12 k1 c7 l40 k3 e7")
    (lane R2 "l22 r l1 v8 c8 g7 e8 c8 v7 g7 e8 c8 g7 v6 e8 c8 g7 e8 v5 c8 g7 e8 c8 v4 g7 e8 c8 g7 v3 e8 c8 g7"))

; a charm taken: a charm bracelet's jingle (two bells shaken, a tick of noise on each
; shake), its echo on the right, a warm low fifth under them
(rich charm "a charm taken"
    (lane L1 "m3 n1 v11 b7 m1 v10 g#7 b7 g#7 m3 v11 b7 m1 v9 g#7 b7 g#7 l2 r l1 m3 v12 e8 m1 l24 k2 v11 b7")
    (lane R1 "l3 r l1 v8 e7 g#7 e7 g#7 v7 e7 g#7 e7 g#7 l2 r l1 v9 b7 l24 k2 v8 e8")
    (lane L2 "l6 r l6 v9 k2 e5 l30 k3 b5"))

; a door picked: a creak (tone and low noise, wobbling up), a thunk as it shuts, a little
; mystery of three notes and their echo
(rich door "a door picked"
    (lane L1 "m3 n31 l2 v8 a3 a#3 a3 b3 a#3 c4 b3 c#4 c4 d4 c#4 l4 k1 v9 d#4")
    (lane R1 "l24 r m3 n20 v14 e2 c2 a1 m2 n24 l10 k1 v11 c4")
    (lane L2 "l32 r l8 v9 k1 e5 a#5 l30 k2 v10 a5")
    (lane R2 "l38 r l8 v5 k1 e5 a#5 l30 k2 v5 a5"))

; ---- the Bulldog King

; he appears: a saw bass sinking A G# G to D# (a tritone down) under a timpani roll that
; swells into a crash, a regal call in A minor in octaves (its D# the tritone), and his bark
; at the end. About 2.6 s
(rich king "the Bulldog King appears"
    (lane L1 "m0 l24 h8:72 c4 l12 h8:76 c4 h8:81 c4 l40 h8:102 c4 m1 v14 k3 l40 d#1")
    (lane R1 "m3 n28 l1 v6 a2 r v7 a2 r v8 a2 r v9 a2 r v10 a2 r v11 a2 r v12 a2 r v12 a2 r v13 a2 r v13 a2 r v14 a2 r v14 a2 r l30 v15 k2 a2")
    (lane L2 "l24 r l12 v12 k1 a4 l6 a4 c5 l24 k2 e5 l12 k1 d#5 l36 k3 a4")
    (lane R2 "l24 r l12 v10 k1 a3 l6 a3 c4 l24 k2 e4 l12 k1 d#4 l36 k3 a3")
    (lane L3 "m2 n3 l3 v2 c4 v3 c4 v4 c4 v5 c4 v6 c4 v7 c4 v8 c4 v9 c4 l40 k2 v13 c4")
    (lane R3 "l114 r l1 v14 a4 f#4 d#4 c4 l3 r l1 v13 a4 f#4 d#4 c4 a3 l14 k2 v10 f3"))

; he changes to his next form: a rush of noise rising on both chips with a chromatic sweep
; up two octaves, a crash, and a saw bass diving under a fifth of a growl. About 1.6 s
(rich king_form "the King changes to his next form"
    (lane L1 "m2 l2 n31 v6 c4 n28 v7 c4 n25 v8 c4 n22 v9 c4 n19 v10 c4 n16 v11 c4 n13 v12 c4 n10 v12 c4 n7 v13 c4 n4 v13 c4 n2 v14 c4 n1 v14 c4 l2 r l1 n1 v15 c4 n2 c4 n4 v14 c4 n8 l40 k3 v13 c4")
    (lane R1 "l1 r m2 l2 n30 v6 c4 n27 v7 c4 n24 v8 c4 n21 v9 c4 n18 v10 c4 n15 v11 c4 n12 v12 c4 n9 v12 c4 n6 v13 c4 n3 v13 c4 n2 v14 c4 l1 r l2 r l1 n2 v15 c4 n3 c4 n6 v14 c4 n12 l40 k3 v13 c4")
    (lane L2 "l1 v8 c4 c#4 d4 d#4 e4 f4 f#4 g4 g#4 a4 a#4 b4 v9 c5 c#5 d5 d#5 e5 f5 f#5 g5 g#5 a5 a#5 b5 l2 r m0 l1 h8:30 c4 h8:38 c4 h8:48 c4 h8:60 c4 h8:74 c4 h8:90 c4 h8:108 c4 l3 h8:128 c4 m1 v14 k3 l40 a1")
    (lane R2 "l1 v7 g4 g#4 a4 a#4 b4 c5 c#5 d5 d#5 e5 f5 f#5 v8 g5 g#5 a5 a#5 b5 c6 c#6 d6 d#6 e6 f6 f#6 l2 r l2 v12 e3 f3 e3 f#3 e3 g3 l20 k2 v11 e3"))

; ---- the run's end

; the run won: a real fanfare, against today's WON (1.6 s). A pickup, then a tune in thirds
; over I V IV I (A, E, D, A) in a saw bass, timpani on each chord, a cymbal swelling into the
; last, a run to the top and glitter. About 4 s
(rich run_won "the run won"
    (lane L1 "l8 v12 k1 e5 a5 c#6 l24 k1 v13 e6 l8 c#6 l24 d6 l8 b5 a5 c#6 e6 l60 k3 v14 a6")
    (lane R1 "l8 v10 k1 c#5 e5 a5 l24 k1 v11 c#6 l8 a5 l24 b5 l8 g#5 e5 a5 c#6 l60 k3 v12 e6")
    (lane L2 "l24 r m0 l32 h8:72 c4 h8:48 c4 l24 h8:54 c4 l12 h8:72 c4 m1 v14 k4 l60 a1")
    (lane R2 "l24 r m3 n20 v13 a2 m1 l31 k2 v11 a2 l1 m3 v13 e2 m1 l31 k2 v11 e2 l1 m3 v13 d2 m1 l23 k2 v11 d2 l1 m3 v14 a2 m1 l40 k2 v12 a2")
    (lane L3 "l88 r m2 n2 l3 v3 c4 v4 c4 v5 c4 v6 c4 v7 c4 v8 c4 v9 c4 v11 c4 l60 k3 v13 c4")
    (lane R3 "l112 r l1 v9 a5 c#6 e6 a6 c#7 e7 a7 c#8 e8 l30 k2 v9 a7 l8 r l1 v6 a7 e8 v5 c#8 a7 v4 e8 c#8 l20 k2 v3 a7"))
