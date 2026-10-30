# Plan

Catwiz: an Apple II hi-res dice roguelike in Tisple ][, to prove the compiler and an engine.
Shelved 2026-10-30 with two of ten fights. Owner: an homage in the genre, not a remake; no
text or data from any other game; the content can be replaced by much stranger stuff later.

## Where it stands

`tools/build.sh` builds `build/catwiz.dsk` from `game/` (Tisple 02e5697 or later).

1. Boot: LOADING for about 12 s, then the title: CATWIZ glowing over night clouds, the cat
   against a big moon, Press Return.
2. A run: fight 1 (puffcap, sporelet), a reward, fight 2 (puffcap, sporelet, nightflap), then
   "to be continued" and the title. Hit points and the bag carry between fights; losing ends
   the run.
3. Rules (numbers are our own starting tuning; the dice are the only luck):
   - Catwiz has 30 HP and a bag of six-faced dice (five to start, six at most). Each turn five
     come from the bag's draw pile at random and roll; at the end of the turn they go to the
     discard, played or not; when the draw pile runs out the discard is shuffled back in. A
     fight starts with the whole bag in the draw pile. Two re-rolls a turn of the unplayed dice.
   - Faces: wand (damage), bone (heal), kibble (shield till the next turn), gem (mana, kept all
     fight, 5 at most), spells paid in mana (hairball, zoomies, cardboard box, 3 AM screaming),
     curses for enemies (fleas, wet, hiss, bath time; each ward pip blocks one), +1 and x2
     (boost the next die), lint (nothing; upgrades to +1).
   - Enemies show their next move and act in order from the first: puffcap 9 HP (headbutt 4,
     spore shield 3), sporelet 6 (nip 2, cheer: a friend hits +1 next), nightflap 8 with a ward
     pip (scratch 1, bite 2, dive 3).
   - Reward: one of two new dice into the bag, one face of a bag die upgraded, or a die taken
     out of the bag.
   - M meows: a sound, a hop and the happy face; no effect on the fight.
4. Controls: 1-5 pick a die (its text shows at the bottom, arrows show who it goes to); Z X C
   (or the arrows and RETURN) play it on an enemy; the same number again plays a die for the
   hero or for every enemy. ESC lets go, R re-rolls, E ends the turn. The phone player and
   `tisple machine --taps` use `tools/phone/catwiz.json` (buttons, and tap boxes on the dice,
   the enemies, the re-roll die and the cat).
5. Screen: mixed mode, the stage and the tray over four text rows: the pick or the target (name,
   hit points, statuses, next move, BAG n DRAW n), then a log of what happened. The mana is five
   stars by the tray.
6. Sound: Mockingboard music and effects in any slot; speaker effects and the title jingle
   without one.
7. Memory: main memory full of code, the language card 839 bytes left, aux about 5.2 KB, zero
   page 179 of 256 (AGENTS.md, Memory).

## Open

1. Fights 3-10: more enemies and encounters in `game/content/`, and the final fight (the bulldog
   king, `tools/art/boss.py`).
2. The boss's art back in the build (`LEFT_OUT` in `tools/art/export.py`; 1,803 bytes and its
   tables), which needs room first.
3. Room, in Tisple: code overlays loaded from aux memory or disk per screen (Tisple's
   `docs/overlays.md`), per-fight sprite data in aux copied into one buffer when a fight
   starts, the language card's bank 1 (4 KB unused).
4. A bigger reward picker: the bag stops at six dice because the reward shows the whole bag in
   the tray's six slots; a picker that pages would lift that.
5. Mouse support: the Apple mouse card (Tisple's machine has one, `--mouse`) for picking dice
   and enemies; today clicks only work through the phone player and `--taps`.
6. A balance sim: a greedy simulated player for the run, kept in the repo, to tune by. A one-off
   one (2026-10-30) lost about 2.3 HP in fight 1 and 4.2 in fight 2.

Smaller:

- Play it on a real IIe (FloppyEmu or ADTPro) and a real Mockingboard; balance the mix by ear.
- The title's four glow pictures (32 KB of aux, about 5 s of the boot) could be one picture and
  the glow's changes.
- Blits: per-row overhead dominates (about 200 cycles a row against 28 a byte).
- More spells (Static Fur, Catnip, Mark Territory, Knock It Off The Table, Laser Pointer, Belly
  Rub Trap, Nine Lives).

## Art rules

See the header comments in `mockup/battle_forest_v6.py` and `tools/art/actors.py`. Owner's
direction: build on the v6 look; stylized silhouettes, depth, three-quarter angles, NTSC as
the real target with clean as the readability check, expressive faces that carry state.
