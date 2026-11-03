; stingers_motif: the victory, elite-kill and upgrade stingers built from the Catwiz motif
; (tools/music/songs/d_motif.song: 1 5 #4 5 3, "the twitch"), in stingers.fx's form (lanes
; L1-L3 left, R1-R3 right; each starts l1 v15 k0 m1). A demo, not in the game; heard with
; tools/music/sfx/stingers_motif.scene, against stingers.fx's fight_won, elite and upgrade.
;
; Key: A major, as stingers.fx (the fights are in A). In A the motif is A E D# E C#.
; The envelope bass (m0 and h8:P, a saw at 3986 / P Hz: A1 72, D2 54, E2 48) plays at full
; level, so it gets one lane, and its last note goes back to a plain tone to fade.

; a fight won: the motif, quick, then a hop up to the high A instead of the tail; the same an
; octave up and softer on the right, a beat behind; a little bass pom-POM. About 1 s
(rich motif_won "a fight won, the motif"
    (lane L1 "l5 v12 k1 a4 l10 e5 l5 d#5 e5 l8 c#5 l40 k2 v13 a5")
    (lane R1 "l5 r l5 v8 k1 a5 l10 e6 l5 d#6 e6 l8 c#6 l40 k2 v9 a6")
    (lane L2 "l5 v11 k1 e2 l28 r l40 k2 v13 a2")
    (lane R2 "l33 r l1 v8 a7 e8 c#8 a7 e7 c#7 l14 k1 v7 a6"))

; an elite beaten: the motif broad, in thirds over a saw tuba, its tail rising to the high A
; instead of falling home; a cymbal swelling into the last chord, a timpani hit, a run up.
; About 2.3 s
(rich motif_elite "an elite beaten, the motif"
    (lane L1 "l6 v13 k1 a4 l18 k2 e5 l6 k1 d#5 e5 l12 c#5 l6 b4 c#5 e5 l48 k3 v14 a5")
    (lane R1 "l6 v11 k1 e4 l18 k2 c#5 l6 k1 b4 c#5 l12 a4 l6 g#4 a4 c#5 l48 k3 v12 e5")
    (lane L2 "m0 l24 h8:72 c4 h8:48 c4 l12 h8:54 c4 l6 h8:48 c4 m1 v14 k3 l48 a1")
    (lane R2 "l66 r l1 v10 a5 c#6 e6 a6 c#7 e7 a7 l30 k2 v10 c#8 l10 r l1 v6 a7 e8 l20 k2 v5 c#8")
    (lane R3 "l45 r m2 n2 l3 v3 c4 v5 c4 v7 c4 v9 c4 v10 c4 v11 c4 v12 c4 l48 k3 v13 c4")
    (lane L3 "l66 r l1 v14 k0 a2 e2 a1 l30 k3 v12 a2"))

; an upgrade, +1 on a face: the motif's head (1 5 #4 5) three times, fast, each a
; step higher (A, then B, then C#), landing on a bright A with a bell, then
; glitter; its octave on the right 2 ticks behind. About 1.2 s
(rich motif_upgrade "an upgrade: +1 on a face, the motif"
    (lane L1 "l3 v10 k1 a5 e6 d#6 e6 b5 f#6 f6 f#6 c#6 g#6 g6 g#6 l30 k2 v12 a6")
    (lane R1 "l2 r l3 v7 k1 a6 e7 d#7 e7 b6 f#7 f7 f#7 c#7 g#7 g7 g#7 l30 k2 v8 a7")
    (lane L2 "l36 r l2 v12 k1 a6 l40 k3 c#7")
    (lane R2 "l40 r l1 v8 a7 e8 c#8 a7 v7 e8 c#8 a7 e8 v6 c#8 a7 e8 c#8 v5 a7 e8 c#8 a7 v4 e8 c#8 a7 e8 v3 c#8 a7 e8"))
