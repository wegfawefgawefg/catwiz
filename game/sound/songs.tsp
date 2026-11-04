; Catwiz's music for the Mockingboard, in lib/mockingboard_song's text: loops of different
; lengths that drift against each other, no lead tune on top. The songs live on the disk;
; game/sound/sound.tsp reads the one starting and puts it in main memory to play it.
;
; Voices: 0-2 the first chip (left), 3-5 the second (right). A fight lends voice 2 to the
; hero's effects and voice 5 to the enemies', so those two carry the parts least missed: the
; woods' pad and shaker, the garden's crickets and bell echo, the house's brushes and tune echo.
; The noise period is the chip's: every effect with noise sets its own first, and leaves it, so
; a song's noise part sets its own again each time round (the woods' shaker, the house's
; brushes at each pattern, the garden's crickets at each chirp). Each voice comes in after a
; rest of 0-4 ticks so that voices which share a pulse start their notes on different ticks: a
; note start is the player's dearest work.
;
; Which song plays where (sound.tsp Song, battle.fight_song): the title; the woods' fights
; (BATTLE), the garden's (GARDEN), the house's (HOUSE); the run won (WON) or lost (LOST).
;
; A tick is 1/60 s. Every pattern sets its own length, volume and decay, since a voice keeps
; them from the pattern before.

(import mockingboard_song tune)
(import tables)

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
; the title's song is on both disks: the first title plays before the second disk is found, the
; titles after a run from the second disk (as the title's art: draw/stage)
(macro title_song (name where)
    `(tune.song ,name
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
        :on ,where
        :in aux))

(title_song TITLE disk)
(title_song TITLE2 disk2)

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
(tune.song BATTLE
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
    :on disk2
    :in aux)

; ---- the stingers: once, then quiet: each voice ends after its patterns (end), and the music
; stops, so the song after starts at once (lib/mockingboard: a fade with no voice playing)
;
; won: A major, the battle's key brightened. Two arpeggios, 8 notes of 6 ticks against 12 of
; 4 (3 against 2), meet on the last chord over a IV V I in the bass; 1.6 s with the ring
(tune.song WON
    (pattern w_bass "l12 v13 k2 a2 a2 d2 e2 l48 k3 a1")
    (pattern w_low "l6 v12 k1 a4 e5 a4 e5 c#5 a5 e5 c#6 l48 k3 a5")
    (pattern w_high "l1 r l4 v11 k1 c#5 e5 a5 c#5 e5 a5 e5 a5 c#6 e5 a5 c#6 l48 k3 e6")
    (pattern w_ring "l2 r l24 r r l48 v8 k4 c#5")
    (voice 0 w_bass end)
    (voice 1 w_low end)
    (voice 3 w_high end)
    (voice 4 w_ring end)
    :on disk2
    :in aux)

; lost: A minor, falling. Thirds that slide down at 8 and at 12 ticks a note (3 against 2)
; over a bass that sinks F E, onto a low A minor; 1.8 s with the ring
(tune.song LOST
    (pattern l_bass "l16 v12 k2 a2 f2 e2 l48 k2 a1")
    (pattern l_fast "l8 v11 k1 e5 c5 b4 g4 e4 b3 l48 k3 a3")
    (pattern l_slow "l1 r l12 v10 k1 a4 g4 e4 d4 l48 k3 c4")
    (voice 0 l_bass end)
    (voice 1 l_fast end)
    (voice 3 l_slow end)
    :on disk2
    :in aux)

; ---- the garden: D lydian, ambient, 2026-11-04 (tools/music/songs/b_nightgarden.song, the
; owner's pick): Dmaj9 | E/D | Bm9 | Gmaj9#11, 8 s a chord; a pulse of 60 ticks, no beat
;
; bass      the root, then the fifth (or the pedal) halfway, slow to fade
; low pad   the chord's 3rd or 7th, a second behind the bass
; crickets  tone and noise, high, chirps of 4 one-tick pulses, then a long quiet (voice 2, lent
;           to the hero's effects). n1 at each chirp (the song file's has it once a round, 15
;           s: an effect on the chip leaves its own noise, which the chirps took till then)
; high pad  the 7th, 9th and #11 colours, two seconds behind the bass
; bell      now and then, only b c# e f#; three phrases of 592, 794 and 696 ticks
; echo      the bell's, 40 ticks later and soft (voice 5, lent to the enemies' effects)
(tune.song GARDEN
    (pattern in_low "l60 r")
    (pattern in_high "l60 r r")
    (pattern in_bell "v9 k8 l64 r r r")
    (pattern in_echo "v4 k8 l64 r r r l40 r")
    (pattern in_crickets "l64 r r l9 r")
    (pattern bass_d "l60 v10 k15 d2 - - - a1 - - -")
    (pattern bass_e "d2 - - - b1 - - -")
    (pattern bass_b "b1 - - - f#2 - - -")
    (pattern bass_g "g1 - - - d2 - - -")
    (pattern low_d "l60 v8 k15 f#3 - - - a3 - - -")
    (pattern low_e "g#3 - - - b3 - - -")
    (pattern low_b "a3 - - - - - f#3 -")
    (pattern low_g "f#3 - - - a3 - - -")
    (pattern high_d "l60 v7 k15 c#4 - - - e4 - - -")
    (pattern high_e "e4 - - - - f#4 - -")
    (pattern high_b "d4 - - c#4 - - - -")
    (pattern high_g "b3 - - - c#4 - - -")
    (pattern bell_a "l20 f#6 b5 l40 c#6 l64 r r r r r r r r")
    (pattern bell_b "l30 e6 l60 c#6 l64 r r r r r r r r r r r")
    (pattern bell_c "l20 b5 c#6 e6 l60 f#6 l64 r r r r r r r r r")
    (pattern crickets
        "m3 n1 v8 k0 l1 c8 r c8 r c8 r c8 l29 r n1 l1 c8 r c8 r c8 r c8 l29 r n1 l1 c8 r c8 r c8 r c8 l64 r r r r r n1 l1 c8 r c8 r c8 r c8 l29 r n1 l1 c8 r c8 r c8 r c8 l64 r r r r r r r")
    (voice 0 bass_d bass_e bass_b bass_g)
    (voice 1 in_low loop low_d low_e low_b low_g)
    (voice 2 in_crickets loop crickets)
    (voice 3 in_high loop high_d high_e high_b high_g)
    (voice 4 in_bell loop bell_a bell_b bell_c)
    (voice 5 in_echo loop bell_a bell_b bell_c)
    :on disk2
    :in aux)

; ---- the house: swing in D minor, 2026-11-04 (tools/music/songs/b_lounge.song, the owner's
; pick): Gm9 C13 Fmaj9 Bbmaj9 | Em7b5 A7b9 Dm9 D7b9, a bar each; a beat of 30 ticks (120 bpm)
; swung on a triplet grid of 10; the tune A B A C repeats after 1920 ticks (32 s)
;
; walk    the bass in quarters, chromatic steps into each next root
; comp    rootless voicings rolled up and left to ring, on the swung "and" of 4
; brushes noise: a sweep on 1 and 3, a tap on 2 and 4 with a ghost, a drag every 4th bar
;         (voice 2, lent to the hero's effects; n3 at each pattern)
; tune    tiptoe pickups, a diminished climb over A7b9, a run down D7b9; no volume of its
;         own, so voice 5 shares the patterns
; guide   the 7ths and 3rds, one soft note a bar
; echo    the tune a swung 8th later and soft (voice 5, lent to the enemies' effects)
(tune.song HOUSE
    (pattern in_comp "l52 r r")
    (pattern in_brush "l1 r")
    (pattern in_tune "v11 k3 l2 r l10")
    (pattern in_echo "v5 k2 l22 r l10")
    (pattern walk
        "l30 v12 k3 g2 a#2 d3 c#3 c3 a#2 g2 e2 f2 a2 c3 b2 a#2 a2 g2 f2 e2 g2 a#2 g#2 a2 g2 e2 c#2 d2 e2 f2 a2 d3 c3 a2 f#2")
    (pattern comp
        "v10 k6 l2 a#3 d4 e4 l57 a4 - l2 a3 c4 e4 l57 g4 - l2 a3 c4 d4 l57 f4 - l2 a#3 d4 e4 l57 g4 - l2 a#3 c#4 e4 l57 g4 - l2 a3 c4 e4 l57 f4 - l2 a3 c4 d#4 l57 f#4 - l2 a#3 d4 f4 l57 a4 -")
    (pattern brush "l30 m2 n3 v6 k4 c4 l20 v10 k2 c4 l10 v5 k1 c4")
    (pattern brush_drag "l30 m2 n3 v6 k4 c4 l10 v8 k1 c4 v6 c4 v10 c4")
    (pattern guide "l60 v6 k12 f4 - e4 - e4 - d4 - d4 - c#4 - c4 - c4 -")
    (pattern tune_a
        "r r f#4 g4 r a#4 d5 r c#5 d5 - f5 e5 - - r r d5 a#4 - g4 a4 - - r r e4 f4 r g#4 a4 r b4 c5 - e5 d5 - - r r c5 a4 - f4 - r r")
    (pattern tune_b
        "g5 - e5 d5 - a#4 r r g4 a#4 - c#5 e5 - g5 a#5 - - r r g5 e5 c#5 a#4 a4 - - r r e5 f5 - r d5 - - r r c5 a4 f#4 r a4 r r r r r")
    (pattern tune_c
        "e5 - - r g5 - r a#5 - r a5 g5 f5 - - e5 - - r r c#5 a#4 g4 e4 f4 - - r r a4 c5 - e5 - d5 - r r r f#5 d#5 c5 a4 r r r r r")
    (voice 0 walk)
    (voice 1 in_comp loop comp)
    (voice 2 in_brush loop brush brush brush brush brush brush brush brush_drag)
    (voice 3 in_tune loop tune_a tune_b tune_a tune_c)
    (voice 4 guide)
    (voice 5 in_echo loop tune_a tune_b tune_a tune_c)
    :on disk2
    :in aux)

; ---- room on the disk: the songs above GARDEN and HOUSE take 4 sectors, and with this 12 they
; take a whole track, so every table after them (disk 2's label, the catalog, the rules, the
; overlay groups' code) keeps its sectors one track on. 4 sectors alone moved the fight's start
; group onto a new track for its last sector: the first fight was ready 24 frames later. Never
; read; take its sectors for the next songs (2026-11-04)
(macro zero (i)
    0)

(tables.table DISK_ROOM u8 3072 zero :on disk2)
