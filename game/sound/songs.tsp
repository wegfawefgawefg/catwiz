; Catwiz's music for the Mockingboard, in lib/mockingboard_song's text: loops of different
; lengths that drift against each other, no lead tune on top. The songs live in aux memory;
; game/sound/sound.tsp copies the one starting into main memory to play it.
;
; Voices: 0-2 the first chip (left), 3-5 the second (right). The battle lends voice 2 to the
; hero's effects and voice 5 to the enemies', so those two carry the parts least missed: the
; pad and the shaker. Each voice comes in after a rest of 0-4 ticks so that voices which share
; a pulse start their notes on different ticks: a note start is the player's dearest work.
;
; A tick is 1/60 s. Every pattern sets its own length, volume and decay, since a voice keeps
; them from the pattern before.

(import mockingboard_song tune)

; ---- the title: E minor (aeolian), a pulse of 7 ticks (16ths at about 128 bpm)
;
; bass   7 pulses (2+2+3), under a round of chords E C A D B, 224 pulses (26 s)
; arp_a 12 pulses, the hook, left
; arp_b the same 12 and a rest, right: it slips a pulse behind arp_a every bar, back in step
;       after 156 pulses
; drums 16 pulses (3+3+3+3+2+2), from pulse 112
; bell   5 + 5 pulses, from pulse 168
; pad    one chord tone every 14 pulses
; The voices come in one at a time over the first 20 s, then all play on.
(tune.song title
    (pattern in_tick "l1 r")
    (pattern in_two "l2 r")
    (pattern in_arp_b "l2 r l56 r r r r r r r")
    (pattern in_drums "l56 r r r r r r r r r r r r r r")
    (pattern in_bell "l1 r l56 r r r r r r r r r r r r r r r r r r r r r")
    (pattern bass_e "l7 v13 k2 e2 - e2 r b1 d2 e2")
    (pattern bass_c "l7 v13 k2 c2 - c2 r g1 b1 c2")
    (pattern bass_a "l7 v13 k2 a1 - a1 r e1 g1 a1")
    (pattern bass_d "l7 v13 k2 d2 - d2 r a1 c2 d2")
    (pattern bass_b "l7 v13 k2 b1 - b1 r f#1 a1 b1")
    (pattern arp_a "l7 v11 k1 e4 b4 e5 r d5 b4 f#5 r e5 g5 d5 b4")
    (pattern arp_b "l7 v10 k1 e4 b4 e5 r d5 b4 f#5 r e5 g5 d5 b4 r")
    (pattern drums
        "l7 n1 m1 v13 k1 e1 m2 v8 c4 v5 c4 m1 v13 e1 m2 v8 c4 v5 c4 m1 v13 e1 m2 v8 c4 v5 c4 m1 v13 e1 m2 v8 c4 v5 c4 m1 v13 e1 m2 v8 c4 m1 v12 e1 m2 v9 c4")
    (pattern bell_1 "l7 v7 k1 b5 r e6 r d6")
    (pattern bell_2 "l7 v7 k1 b5 r f#6 r r")
    (pattern pad_e "l49 v8 k9 g3 - b3 - g3 - f#3 -")
    (pattern pad_c "l49 v8 k9 e3 - g3 - e3 - b3 -")
    (pattern pad_a "l49 v8 k9 c4 - e3 - c4 - g3 -")
    (pattern pad_d "l49 v8 k9 f#3 - a3 -")
    (pattern pad_b "l49 v8 k9 f#3 - d3 -")
    (voice 0 bass_e bass_e bass_e bass_e bass_e bass_e bass_e bass_e
        bass_c bass_c bass_c bass_c bass_c bass_c bass_c bass_c
        bass_a bass_a bass_a bass_a bass_a bass_a bass_a bass_a
        bass_d bass_d bass_d bass_d bass_b bass_b bass_b bass_b)
    (voice 1 in_tick loop arp_a)
    (voice 2 in_two loop pad_e pad_c pad_a pad_d pad_b)
    (voice 3 in_arp_b loop arp_b)
    (voice 4 in_bell loop bell_1 bell_2)
    (voice 5 in_drums loop drums)
    :in aux)

; ---- the battle: A dorian, a pulse of 9 ticks (16ths at 100 bpm), soft
;
; bass     12 pulses, under Am D Am G Em, 192 pulses (29 s)
; mallet_a 10 pulses (3+3+2+2), left, from pulse 12
; mallet_b  9 pulses, right, from pulse 24: with mallet_a, back in step every 90 pulses
; sparkle   7 pulses, high and quiet, from pulse 48
; pad      a chord tone every 12 pulses (voice 2, lent to the hero's effects)
; shaker    3 pulses, written out 5 times so it reads a new pattern less often, and not on
;          the bass's ticks (voice 5, lent to the enemies' effects). It sets its noise again
;          each time round: an effect on the chip leaves its own
(tune.song battle
    (pattern in_none "l1 r")
    (pattern in_mallet_a "l1 r l54 r r")
    (pattern in_mallet_b "l2 r l54 r r r r")
    (pattern in_sparkle "l3 r l54 r r r r r r r r")
    (pattern in_pad "l4 r")
    (pattern b_bass_a "l9 v12 k3 a2 - - r e2 r a2 - r g2 r r")
    (pattern b_bass_d "l9 v12 k3 d2 - - r a1 r d2 - r c2 r r")
    (pattern b_bass_g "l9 v12 k3 g1 - - r d2 r g1 - r f#1 r r")
    (pattern b_bass_e "l9 v12 k3 e2 - - r b1 r e2 - r d2 r r")
    (pattern mallet_a "l9 v10 k1 a4 e5 b4 r d5 c5 r e5 g4 r")
    (pattern mallet_b "l9 v9 k1 e5 r a5 g5 r e5 d5 r c5")
    (pattern sparkle "l9 v6 k1 e6 r r b5 r a5 r")
    (pattern b_pad_a "l54 v7 k12 c4 - e4 - c4 - g3 -")
    (pattern b_pad_d "l54 v7 k12 f#3 - a3 - f#3 - c4 -")
    (pattern b_pad_g "l54 v7 k12 b3 - f#3 -")
    (pattern b_pad_e "l54 v7 k12 g3 - d4 -")
    (pattern shaker
        "l9 m2 k1 n1 v5 c4 v3 c4 c4 n1 v5 c4 v3 c4 c4 n1 v5 c4 v3 c4 c4 n1 v5 c4 v3 c4 c4 n1 v5 c4 v3 c4 c4")
    (voice 0 b_bass_a b_bass_a b_bass_a b_bass_a b_bass_d b_bass_d b_bass_d b_bass_d
        b_bass_a b_bass_a b_bass_a b_bass_a b_bass_g b_bass_g b_bass_e b_bass_e)
    (voice 1 in_mallet_a loop mallet_a)
    (voice 2 in_pad loop b_pad_a b_pad_d b_pad_a b_pad_g b_pad_e)
    (voice 3 in_mallet_b loop mallet_b)
    (voice 4 in_sparkle loop sparkle)
    (voice 5 shaker)
    :in aux)

; ---- the stingers: once, then quiet. A voice's last pattern is a long rest it loops on.
;
; won: A major, the battle's key brightened. Two arpeggios, 8 notes of 6 ticks against 12 of
; 4 (3 against 2), meet on the last chord over a IV V I in the bass; 1.6 s with the ring
(tune.song won
    (pattern quiet "l64 r")
    (pattern w_bass "l12 v13 k2 a2 a2 d2 e2 l48 k3 a1")
    (pattern w_low "l6 v12 k1 a4 e5 a4 e5 c#5 a5 e5 c#6 l48 k3 a5")
    (pattern w_high "l1 r l4 v11 k1 c#5 e5 a5 c#5 e5 a5 e5 a5 c#6 e5 a5 c#6 l48 k3 e6")
    (pattern w_ring "l2 r l24 r r l48 v8 k4 c#5")
    (voice 0 w_bass loop quiet)
    (voice 1 w_low loop quiet)
    (voice 3 w_high loop quiet)
    (voice 4 w_ring loop quiet)
    :in aux)

; lost: A minor, falling. Thirds that slide down at 8 and at 12 ticks a note (3 against 2)
; over a bass that sinks F E, onto a low A minor; 1.8 s with the ring
(tune.song lost
    (pattern quiet "l64 r")
    (pattern l_bass "l16 v12 k2 a2 f2 e2 l48 k2 a1")
    (pattern l_fast "l8 v11 k1 e5 c5 b4 g4 e4 b3 l48 k3 a3")
    (pattern l_slow "l1 r l12 v10 k1 a4 g4 e4 d4 l48 k3 c4")
    (voice 0 l_bass loop quiet)
    (voice 1 l_fast loop quiet)
    (voice 3 l_slow loop quiet)
    :in aux)
