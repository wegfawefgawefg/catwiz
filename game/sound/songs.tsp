; Catwiz's music for the Mockingboard, in lib/mockingboard_song's text: loops of different
; lengths that drift against each other, no lead tune on top. The songs live on the disk;
; game/sound/sound.tsp reads the one starting into the language card's bank 1, where it plays
; (sound/waiting).
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
; (BATTLE), the garden's (GARDEN), the house's (HOUSE), the elites' (ELITE), the King's (KING);
; the run won (WON) or lost (LOST). The songs' room holds two of the biggest (KING): keep every
; song within sound/waiting HALF bytes (tisple build --tables gives each one's).
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

; ---- the run won: G major, bouncy, 2026-11-04 (tools/music/songs/b_adventure.song, the
; owner's pick; it replaced a 1.6 s stinger): a 16th of 6 ticks (150 bpm), four 8-bar sections,
; 32 bars, then again (51 s): the hook, the hook closing on G, the chorus, the chorus through F
;
; bass     square 8ths (root, octave, fifth), in the choruses the left chip's envelope, a saw
;          that pumps each held note in 16ths
; lead     the hook and the chorus tune; no volume of its own, so voice 5 shares the patterns
; arps     3 ticks a note up each chord, from the second verse (voice 2, lent to the hero's)
; counter  soft half notes under the lead
; drums    kick, snare and hat, a roll every 8th bar (n4 at the fill too: an effect on the chip
;          leaves its own noise)
; echo     the lead a dotted 8th later, soft (voice 5, lent to the enemies')
(tune.song WON
    (pattern in_lead "v13 k3 l1 r")
    (pattern in_arps "v8 k1 l4 r")
    (pattern in_counter "l3 r")
    (pattern in_drums "l2 r")
    (pattern in_echo "v7 k3 l19 r")
    (pattern ba_g "l12 v12 k3 g2 g3 d3 g3 g2 g3 d3 g3")
    (pattern ba_fs "f#2 f#3 d3 f#3 f#2 f#3 d3 f#3")
    (pattern ba_em "e2 e3 b2 e3 e2 e3 b2 e3")
    (pattern ba_c "c2 c3 g2 c3 c2 c3 g2 c3")
    (pattern ba_d "d2 d3 a2 d3 d2 d3 a2 d3")
    (pattern ba_am "a1 a2 e2 a2 a1 a2 e2 a2")
    (pattern bb_1 "h8:399 l48 c2 g2 d2 a2 b1 f#2 e2 b2")
    (pattern bb_2 "c2 g2 d2 a2 g2 d2 g1 d2")
    (pattern bb_3 "a1 e2 c2 g2 f2 c2 d2 a1")
    (pattern lead_a1
        "l12 d5 g5 a5 l24 b5 l12 a5 g5 a5 l36 f#5 l12 e5 l24 d5 r l12 b4 e5 f#5 l24 g5 l12 f#5 e5 f#5 l36 e5 l12 d5 l24 e5 g5")
    (pattern lead_a2
        "l12 d5 g5 a5 l24 b5 l12 a5 b5 d6 l36 d6 l12 c6 b5 l36 a5 l12 g5 e5 g5 l24 c6 l12 b5 a5 g5 l36 a5 l12 f#5 l24 d5 r")
    (pattern lead_a3
        "l12 c6 b5 a5 l24 e5 l12 a5 b5 c6 l36 d6 l12 c6 b5 a5 l24 f#5 l48 g5 l24 r l12 d5 e5 l24 g5 l12 a5 b5 l24 c6 d6")
    (pattern lead_b1
        "l36 e6 l12 d6 c6 d6 l24 e6 l36 d6 l12 c6 b5 c6 l24 d6 l36 b5 l12 a5 f#5 a5 l24 b5 l60 g5 l12 r e5 g5")
    (pattern lead_b2
        "l36 e6 l12 d6 c6 d6 l24 e6 l36 f#6 l12 e6 d6 e6 l24 f#6 l36 g6 - l24 r l12 d6 b5 l24 g5 l12 a5 b5 l24 d6")
    (pattern lead_b3
        "l36 e6 l12 d6 c6 b5 l24 a5 l36 g5 l12 a5 c6 d6 l24 e6 l36 f6 l12 e6 c6 a5 l24 c6 l48 d6 l12 c6 a5 l24 f#5")
    (pattern rest8 "l64 r r r r r r r r r r r r")
    (pattern ar_g "l3 d5 g5 b5 d6 d5 g5 b5 d6 d5 g5 b5 d6 d5 g5 b5 d6")
    (pattern ar_d "d5 f#5 a5 d6 d5 f#5 a5 d6 d5 f#5 a5 d6 d5 f#5 a5 d6")
    (pattern ar_em "e5 g5 b5 e6 e5 g5 b5 e6 e5 g5 b5 e6 e5 g5 b5 e6")
    (pattern ar_c "c5 e5 g5 c6 c5 e5 g5 c6 c5 e5 g5 c6 c5 e5 g5 c6")
    (pattern ar_am "c5 e5 a5 c6 c5 e5 a5 c6 c5 e5 a5 c6 c5 e5 a5 c6")
    (pattern ar_bm "d5 f#5 b5 d6 d5 f#5 b5 d6 d5 f#5 b5 d6 d5 f#5 b5 d6")
    (pattern ar_f "c5 f5 a5 c6 c5 f5 a5 c6 c5 f5 a5 c6 c5 f5 a5 c6")
    (pattern counter_a1 "l48 v9 k6 b4 d5 a4 f#4 g4 b4 c5 g4")
    (pattern counter_a2 "b4 d5 a4 d5 e5 c5 a4 c5")
    (pattern counter_a3 "c5 e5 d5 c5 b4 d5 b4 g4")
    (pattern counter_b1 "e5 c5 f#5 d5 d5 b4 b4 g4")
    (pattern counter_b2 "e5 c5 f#5 a5 b5 g5 b4 d5")
    (pattern counter_b3 "c5 e5 e5 g5 c5 f5 d5 c5")
    (pattern groove
        "l6 n4 m1 v13 k1 c2 r m2 v5 c4 r v12 k2 c4 r v5 k1 c4 m1 v13 c2 r c2 m2 v5 c4 r v12 k2 c4 r v5 k1 c4 v3 c4")
    (pattern fill
        "n4 m1 v13 c2 r m2 v5 c4 r v12 k2 c4 r v5 k1 c4 m1 v13 c2 m2 v8 k2 c4 r v9 c4 c4 v10 c4 v11 c4 v12 c4 v14 c4")
    (voice 0 ba_g ba_fs ba_em ba_c ba_g ba_d ba_c ba_d
        ba_g ba_fs ba_em ba_c ba_am ba_d ba_g ba_g
        bb_1 bb_2 bb_1 bb_3)
    (voice 1 in_lead loop lead_a1 lead_a2 lead_a1 lead_a3 lead_b1 lead_b2 lead_b1 lead_b3)
    (voice 2 in_arps loop rest8
        ar_g ar_g ar_d ar_d ar_em ar_em ar_c ar_c ar_am ar_am ar_d ar_d ar_g ar_g ar_g ar_g
        ar_c ar_c ar_d ar_d ar_bm ar_bm ar_em ar_em ar_c ar_c ar_d ar_d ar_g ar_g ar_g ar_g
        ar_c ar_c ar_d ar_d ar_bm ar_bm ar_em ar_em ar_am ar_am ar_c ar_c ar_f ar_f ar_d ar_d)
    (voice 3 in_counter loop counter_a1 counter_a2 counter_a1 counter_a3
        counter_b1 counter_b2 counter_b1 counter_b3)
    (voice 4 in_drums loop groove groove groove groove groove groove groove fill)
    (voice 5 in_echo loop lead_a1 lead_a2 lead_a1 lead_a3 lead_b1 lead_b2 lead_b1 lead_b3)
    :on disk2
    :in aux)

; ---- the stinger: once, then quiet: each voice ends after its patterns (end), and the music
; stops, so the song after starts at once (lib/mockingboard: a fade with no voice playing)
;
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

; ---- the elites: E minor, math rock in straight 4/4, 2026-11-04
; (tools/music/songs/c_mathrock_straight.song, the owner's pick): a 16th of 6 ticks (150 bpm),
; riff, bass and kick pushing 3+3+2+3+3+2 inside each bar, 16 bars (25.6 s) round; the riff
; plays 2 bars alone first
;
; bass   the left chip's envelope (a saw, tone off), its period the pitch, chugging with the
;        kick, climbing into each next 8 bars
; riff   tapped 16ths over a pedal; no volume of its own, so voice 5 shares the patterns
; hats   16ths, accents on the beat (voice 2, lent to the hero's effects; n2 each pattern)
; kick   and snare, a roll every 4th bar (n7 at the fill too)
; stabs  a quartal chord rolled fast on the 6th and 14th 16ths
; echo   the riff a dotted 8th later, soft (voice 5, lent to the enemies')
(tune.song ELITE
    (pattern in_riff "l1 v12 k1 r")
    (pattern in_echo "l19 v7 k1 r")
    (pattern in_band "l64 r r r")
    (pattern riff_a "l6 e5 b4 g4 g5 b4 g4 f#5 b4 d5 b4 g4 e5 b4 g4 a5 g5")
    (pattern riff_a3 "l6 e5 b4 g4 g5 b4 g4 f#5 b4 b5 b4 g4 a5 b4 g4 f#5 d5")
    (pattern riff_a2 "l6 e5 b4 f#4 g5 b4 f#4 f#5 b4 d5 b4 f#4 b5 a5 g5 f#5 d5")
    (pattern riff_b "l6 d6 b5 e5 b5 a5 e5 a5 g5 e5 g5 f#5 e5 f#5 d5 e5 g5")
    (pattern riff_b2 "l6 e5 g5 b5 e5 a5 d6 e5 b5 e6 e5 d6 b5 a5 g5 f#5 d5")
    (pattern riff_b3 "l6 b4 d5 f#5 d5 f#5 a5 f#5 a5 b5 a5 b5 d6 b5 d6 f#6 d#6")
    (pattern he "m0 l6 h8:97 e1")
    (pattern hc "h8:61 e1")
    (pattern ha "h8:72 e1")
    (pattern hd "h8:54 e1")
    (pattern hb "h8:65 e1")
    (pattern chug "- r e1 - r e1 r e1 - r e1 - r e1 e1")
    (pattern climb "- r e1 - r e1 r e1 - r h8:54 e1 - r h8:48 e1 h8:43 e1")
    (pattern hats "l6 m2 n2 k1 v10 c4 v5 c4 v7 c4 v5 c4")
    (pattern groove "n7 v14 k1 m1 l18 g1 l6 g1 m2 l24 c4 m1 l18 g1 l6 g1 m2 l12 c4 m1 g1")
    (pattern fill "n7 m1 l18 g1 l6 g1 m2 l24 c4 m1 l12 g1 m2 l6 c4 c4 l3 c4 c4 c4 c4 l6 c4 c4")
    (pattern stabs "l36 v11 k2 r l1 a4 d5 e5 a4 d5 e5 l42 r l1 a4 d5 e5 a4 d5 e5 l6 r")
    (voice 0 in_band loop he chug hc chug ha chug hb chug he chug hc chug hd chug hb climb
        hc chug hd chug hb chug he chug hc chug hd chug hb chug hb climb)
    (voice 1 in_riff riff_a riff_a2 loop riff_a riff_a riff_a riff_a2 riff_a riff_a3 riff_a riff_a2
        riff_b riff_b2 riff_b riff_b2 riff_b riff_b2 riff_b riff_b3)
    (voice 2 in_band loop hats)
    (voice 3 in_band loop groove groove groove fill)
    (voice 4 in_band loop stabs)
    (voice 5 in_echo riff_a riff_a2 loop riff_a riff_a riff_a riff_a2 riff_a riff_a3 riff_a riff_a2
        riff_b riff_b2 riff_b riff_b2 riff_b riff_b2 riff_b riff_b3)
    :on disk2
    :in aux)

; ---- the King: C minor, a pompous royal march, 2026-11-04 (tools/music/songs/a_king.song, the
; owner's pick): a 16th of 9 ticks (100 bpm), a 2-bar herald's call once, then the march (8
; bars) and the anthem (8 bars) round, 38.4 s
;
; bass     the left chip's envelope saw (tone off), its period the pitch: a tuba, then pumping
; trumpet  the tune: triplet calls, a dotted fanfare, long lines
; second   in thirds and sixths, then held notes under it (voice 2, lent to the hero's)
; snare    a march, stomps, rolls (the right chip's envelope); n5 at each pattern (an effect on
;          the chip leaves its own noise)
; horn     oom-pah with the bass, then off-beat eighths
; timpani  bar starts, roots, rolls (voice 5, lent to the enemies')
(tune.song KING
    (pattern call_lead "l12 v13 k8 g4 g4 g4 l36 c5 l12 g4 g4 g4 l36 d#5 l12 g4 c5 d#5 l36 g5 - r")
    (pattern call_harm
        "l2 r l12 v10 k8 d#4 d#4 d#4 l36 g4 l12 d#4 d#4 d#4 l36 g4 l12 d#4 g4 c5 l36 d#5 - r")
    (pattern call_bass "l1 r m0 l36 r h8:122 c1 r c1 r c1 - r")
    (pattern call_snare "l3 r m2 n5 k1 l36 h8:180 c4 - - - l12 v12 c4 c4 c4 l36 v15 c4 r r")
    (pattern call_horn "l64 r r l56 r l36 v10 k4 c4 - r")
    (pattern call_timp "l4 r l36 h8:180 c2 - - - l36 v15 k3 r c2 r r")
    (pattern lead_a
        "l27 g4 l9 g4 l36 c5 l27 c5 l9 d5 l36 d#5 l27 d5 l9 c5 l36 d5 g4 - l27 c5 l9 c5 l36 d#5 l27 d#5 l9 f5 l36 g#5 g5 - l27 f5 l9 d5 l36 b4 c6 - l27 g5 l9 g5 l36 d#5 l27 f5 l9 g5 l36 g#5 l27 g#5 l9 g5 l36 f5 l27 g5 l9 g5 l36 f5 d5 b4 c5 - - r")
    (pattern lead_b
        "l36 g#4 - c5 d#5 c6 - a#5 g#5 g#5 - g5 f5 c5 - f5 g#5 c#6 - - c6 a#5 - g#5 f5 g5 - - f5 d5 - b4 r")
    (pattern harm_a
        "l27 d#4 l9 d#4 l36 g4 l27 g4 l9 f4 l36 g4 l27 b4 l9 g4 l36 b4 b3 - l27 g#4 l9 g#4 l36 c5 l27 c5 l9 d5 l36 c5 d5 - l27 d5 l9 b4 l36 g4 g5 - l27 d#5 l9 d#5 l36 c5 l27 g#4 l9 a#4 l36 c5 l27 c5 l9 a#4 l36 g#4 l27 d5 l9 d5 l36 b4 g4 f4 d#4 - - r")
    (pattern harm_b
        "l36 d#4 - g#4 c5 d#5 - - c5 c5 - a#4 g#4 g#4 - c5 c5 f5 - - f5 c#5 - - g#4 b4 - - d5 b4 - g4 r")
    (pattern bass_a
        "l36 h8:61 c2 r h8:81 g1 r g1 r h8:54 d2 r h8:77 g#1 r h8:51 d#2 r h8:81 g1 r h8:54 d2 r h8:61 c2 r h8:81 g1 r h8:91 f1 r h8:61 c2 r h8:81 g1 r h8:65 b1 r h8:61 c2 r h8:122 c1 r")
    (pattern pump_ab "h8:77 l9 g#1 r g#1 r g#1 r g#1 r g#1 r g#1 r g#1 r g#1 r")
    (pattern pump_f "h8:91 f1 r f1 r f1 r f1 r f1 r f1 r f1 r f1 r")
    (pattern pump_db "h8:115 c#1 r c#1 r c#1 r c#1 r c#1 r c#1 r c#1 r c#1 r")
    (pattern pump_g "h8:81 g1 r g1 r g1 r g1 r g1 r g1 r g1 r g1 r")
    (pattern walk_up "h8:81 g1 r g1 r g1 r g1 r h8:72 a1 r a1 r h8:65 b1 r b1 r")
    (pattern snare_a
        "n5 l9 v13 k1 c4 r v6 c4 c4 v13 c4 r v6 c4 r v13 c4 r v6 c4 c4 v13 c4 v6 c4 c4 c4")
    (pattern snare_fill "n5 l36 v14 k1 c4 v10 c4 h8:180 c4 -")
    (pattern snare_stomp "n5 l36 v13 k1 r c4 l27 r l9 v7 c4 l36 v13 c4")
    (pattern snare_roll "n5 l36 h8:180 c4 - - v14 k1 c4")
    (pattern horn_a
        "l36 r c4 r c4 r b3 r b3 r c4 r c4 r b3 r b3 r c4 r c4 r c4 r c4 r b3 r b3 r c4 r c4")
    (pattern horn_ab "l18 r d#4 r d#4 r d#4 r d#4")
    (pattern horn_f "r c4 r c4 r c4 r c4")
    (pattern horn_db "r f4 r f4 r f4 r f4")
    (pattern horn_g "r d4 r d4 r d4 r d4")
    (pattern timp_a
        "l36 v14 k3 c2 r r r g1 r r r g#1 r r r g1 r r r c2 r r r f1 r r r g1 r r r c2 r r r")
    (pattern timp_b
        "g#1 r d#2 r g#1 r d#2 r f1 r c2 r f1 r h8:180 c2 - v14 c#2 r g#1 r c#2 r g#1 r g1 g1 g1 g1 g1 r h8:180 g1 -")
    (voice 0 call_bass loop bass_a pump_ab pump_ab pump_f pump_f pump_db pump_db pump_g walk_up)
    (voice 1 call_lead loop lead_a lead_b)
    (voice 2 call_harm loop harm_a harm_b)
    (voice 3 call_snare loop snare_a snare_a snare_a snare_a snare_a snare_a snare_a snare_fill
        snare_stomp snare_stomp snare_stomp snare_stomp snare_roll snare_roll snare_roll snare_fill)
    (voice 4 call_horn loop horn_a horn_ab horn_ab horn_f horn_f horn_db horn_db horn_g horn_g)
    (voice 5 call_timp loop timp_a timp_b)
    :on disk2
    :in aux)

; ---- room on the disk: the songs above take 15 sectors and these 3 a whole track with them,
; so every table after them (disk 2's label, the catalog, the rules, the overlay groups' code)
; keeps its sectors one track on. 4 sectors alone moved the fight's start group onto a new track
; for its last sector: the first fight was ready 24 frames later. Never read; take its sectors
; for the next songs (2026-11-04: was 12; the run won's 3 more, the elites' 2, the King's 4)
(macro zero (i)
    0)

(tables.table DISK_ROOM u8 768 zero :on disk2)
