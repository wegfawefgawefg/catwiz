# Plan

Catwiz: an Apple II double hi-res dice roguelike in Tisple ][, to prove the compiler and an
engine. Shelved 2026-10-30 with two of ten fights, then ported to double hi-res with the day
art (branch dhgr-port, 2026-10-30). Owner: an homage in the genre, not a remake; no
text or data from any other game; the content can be replaced by much stranger stuff later.

## Where it stands

`tisple build` builds `build/catwiz.dsk` from `game/` (Tisple's branch catwiz-dhgr-lib until it
is merged; settings in `tisple.project`).

1. Boot: LOADING, then by frame 600 the title in double hi-res: CATWIZ in white with a rim
   that glows (magenta, orange, yellow, orange), the cat against a big white moon on a night
   page, "a dice battle in the woods", PRESS RETURN. One packed picture and the rim's four
   colours as sprites.
2. A run: fight 1 in the clearing (puffcap, sporelet), a reward, fight 2 on the path (puffcap,
   sporelet, nightflap), then "to be continued" and the title. Both day fights. Hit points and
   the bag carry between fights; losing ends the run.
3. Rules (numbers are our own starting tuning; the dice are the only luck):
   - Catwiz has 30 HP and a bag of six-faced dice (five to start, six at most). Each turn five
     come from the bag's draw pile at random and roll; at the end of the turn they go to the
     discard, played or not; when the draw pile runs out the discard is shuffled back in. A
     fight starts with the whole bag in the draw pile. Two re-rolls a turn of the unplayed dice.
   - Faces: wand (damage), tuna (heal), fluff (shield till the next turn), star (mana, kept all
     fight, 5 at most; the card a bold yellow star, as the mana meter's), spells paid in mana
     (hairball, zoomies, cardboard box, 3 AM screaming), curses for enemies (fleas, wet, hiss,
     bath time; each ward pip blocks one), +1 and x2 (boost the next die), lint (nothing;
     upgrades to +1).
   - Enemies show their next move and act in order from the first: puffcap 9 HP (headbutt 4,
     spore shield 3), sporelet 6 (nip 2, cheer: a friend hits +1 next), nightflap 8 with a ward
     pip (scratch 1, bite 2, dive 3).
   - Reward: one of two new dice into the bag, one face of a bag die upgraded, or a die taken
     out of the bag.
   - M meows: a sound, a hop and the happy face; no effect on the fight.
4. Controls: 1-5 pick a die (its text shows at the bottom, arrows show who it goes to); Z X C
   (or the arrows and RETURN) play it on an enemy; the same number again plays a die for the
   hero or for every enemy, and lets go of one for a single enemy; M (the cat) plays a die for
   the hero, else meows. ESC lets go, R re-rolls, E ends the turn; the turn ends by itself a
   beat after the last die is played, or when none can be played and no re-roll is left ("No
   playable dice."; with re-rolls left the log says "R re-roll or E end turn."). Any key starts
   the title and leaves the run's end. Everything is also a tap or a click on the screen:
   `tools/phone/catwiz.json` has the tap boxes (the five cards, the re-roll button and the
   stars, END TURN, the enemies, the cat, then the whole screen as ESC) for Tisple's web player
   and `tisple machine --taps`, the web player's portrait pad, and `"look": "ntsc"`: the player
   starts in the TV look. The reward's sixth slot sits where the re-roll button is, and the
   reward takes R as that slot (the box there sends R; its lower part is END's box). One-time
   hints in the log (once a boot): the first turn, the first mana, the first reshuffle.
5. Screen: double hi-res, all graphics: the stage (rows 0-117 and a black gutter), the tray
   (rows 118-159), four lines of 35-column text drawn into the picture (rows 160-191): the pick
   or the target (name, hit points, statuses, next move, Bag n draw n), then a log of what
   happened. A black pill badge under each actor (a heart and its hit points, then its statuses)
   and over each enemy (its next move: a sword and how much, a shield, a cheer, an orange sword
   for a dive). The tray: a tilted white card for each die with its picture and number, the
   picked one upright, lifted and rimmed in yellow; the re-roll button (a die and X and the re-
   rolls left), five mana stars, END TURN. Sprites in the day's light.
6. Sound: Mockingboard music and effects in any slot; speaker effects and the title jingle
   without one.
7. Memory: main memory full, the language card about 3 KB left (bank 1 0.5 KB), aux about
   2.9 KB, the aux language card (a fight's sprites) 0.5 KB in bank 2 and 0.7 KB in bank 1 at
   fight 2, zero page 172 of 256 (AGENTS.md, Memory).
8. Speed: waiting for a key a pass is a frame (fight 2 1.6: the nightflap's wings); an action
   (a die thrown, an enemy's lunge) about 5 frames a pass; picking a die shows in a few frames.

## Open

1. Fights 3-10: more enemies and encounters in `game/content/`, the dusk (5-7) and night (8-10
   and the boss) zones' art and lighting in `tools/dhgr/` (the fighters lit for the zone; the
   build carries the day's), and the final fight (the bulldog king, to draw in double hi-res).
2. Per-fight art from disk: the packed store grows a screen (about 1.2 KB packed) and the new
   enemies' runs (2-3 KB) a fight, and aux has about 2.9 KB left, so fights 3-10 need their art
   read from the disk when they start (Tisple main 7c3de44's `:on disk` tables and lib/disk,
   which reserves main memory `$1400-$1BFF`: main memory is full, so that needs 2 KB of code
   moved to the language card or bank 1 first, or the reader placed elsewhere), each fight's
   tables into the same aux buffer; and a buffer for a fight's enemies at most (today sized by
   fight 2).
3. Speed in actions (about 5 frames a pass): a sprite drawn again costs a restore of its box and
   its runs (the cat about 110,000 cycles). Ideas: a runs pass over the backdrop for a moving
   sprite (restore and draw in one; lib/dhgr's kit has a byte left and no zero page, so it
   needs room there), clipping a redraw's first rows too (bottom clipping is in), the nightflap
   flapping less often.
4. A bigger reward picker: the bag stops at six dice because the reward shows the whole bag in
   the tray's six slots; a picker that pages would lift that.
5. Mouse support: the Apple mouse card (Tisple's machine has one, `--mouse`) for picking dice
   and enemies on a real IIe; today clicks work through the web player and `--taps`.
6. A balance sim: a greedy simulated player for the run, kept in the repo, to tune by. A one-off
   one (2026-10-30) lost about 2.3 HP in fight 1 and 4.2 in fight 2.

Smaller:

- Play it on a real IIe (FloppyEmu or ADTPro) and a real Mockingboard; balance the mix by ear.
- The tray is drawn in Tisple (about 2,500 cycles a group of pixels a row); the roll's redraw of
  all five faces takes a few frames.
- More spells (Static Fur, Catnip, Mark Territory, Knock It Off The Table, Laser Pointer, Belly
  Rub Trap, Nine Lives).

## Art rules

Double hi-res, `tools/dhgr/` (AGENTS.md, Art): day, dusk and night zones, one sprite set lit
per zone by palette swap and rims; NTSC (the TV look) the real target, the flat colour look the
second check; big areas white or black, darks in small pieces, no dithered areas. The hi-res
rules came from `mockup/battle_forest_v6.py` and `tools/art/actors.py`.
