# Plan

Catwiz (was Witchdog): a toy Apple II hi-res dice roguelike in Tisple ][, to prove the compiler and an
engine. Owner, 2026-10-30: an homage in the genre, not a remake; no text or data from any
other game; all content gets replaced later by much stranger stuff.

## Where it stands (2026-10-30, branch `catwiz-engine`)

A first run, booting from `build/witchdog.dsk` (built by `tools/build.sh` from `game/`):

1. Title: CATWIZ glowing over night clouds, the cat against a big moon, Press Return.
2. A run: fight 1 (puffcap, sporelet), a reward, fight 2 (puffcap, sporelet, nightflap), then
   "to be continued" and the title. Hit points carry between fights; losing ends the run.
3. Rules (decided with the owner; numbers our own starting tuning; the dice are the only luck):
   - Catwiz, 30 HP, five dice of six faces, rolled each turn; two re-rolls of the unplayed dice.
   - Faces are items: wand (damage), bone (heal), kibble (shield till the next turn), gem
     (mana, kept all fight, 5 at most), spells by mana (hairball, zoomies, cardboard box, 3 AM
     screaming), curses (fleas, wet, hiss, bath time; each ward pip blocks one), +1 and x2
     (boost the next die), lint (nothing; upgrades to +1).
   - Enemies show their next move and make their moves in order from the first: puffcap 9 HP
     (headbutt 2, spore shield 3), sporelet 6 (nip 1, cheer: a friend hits +1 next), nightflap
     9 with a ward pip (bite 3, bite 3, dive 5).
   - Reward: one of two new dice (replacing one of yours) or one face upgraded.
4. Controls: pick a die (1-5), its name and what it does show at the bottom; then an enemy
   (Z X C, or the arrows and RETURN), or the same die again for the hero's own faces. ESC lets
   go, R re-rolls, E ends the turn. The phone player has the same as buttons and taps
   (`tools/phone/witchdog.json`).
5. Mixed mode: the stage and the tray above four text rows: the pick or the target (name,
   hit points, statuses, next move in words), then a log of what happened in sentences.
6. Hit feel, Mockingboard music and effects, speaker effects without a card: as before.

The meow (once a turn) and the bark are gone: the decided rules make the dice the only actions.

## How it is built

- `game/content/`: the rules content, plain Tisple tables the engine reads (dice faces,
  enemies and their moves, the encounter, the hero) and the `match` that carries out each
  effect kind (`effects.tsp`) and the status hooks (`statuses.tsp`). The engine never names an
  enemy, die, effect or status.
- `game/battle/`: turns, actions in flight, hits and their feel, the hud, the moving picture.
- `game/draw/`: the three hi-res pages (page 1, page 2, the backdrop copy at $6000), sprite
  blits, the per-page redraw of what changed, the hud pen.
- `tools/art/`: the art in Python, exported to `game/art/*.tsp`. Actors get their faces as
  patches: the moods that only change pixels inside the idle silhouette share one box, so a
  face swap is one small blit.

## Next

1. Room. Main memory is full and the language card has about 100 bytes left; the boss's
   pictures (1,803 bytes of their own) are in it though no fight uses them yet. Ideas, biggest first:
   per-fight sprite data in aux memory, copied into one buffer when a fight starts (the boss
   and the forest enemies take turns; the export would write them as separate tables); Tisple
   features: the language card's bank 1 (4 KB unused), code overlays loaded from aux memory
   or disk per screen, a way to say a small function stays a call (now `game/noinline.txt`).
2. Play it on the real IIe (FloppyEmu or ADTPro) and fix what only hardware shows.
3. Tuning by play: a greedy simulated player loses about 0.5 HP in fight 1 and 4 in fight 2
   (bones and kibble undo fight 1's hits); a careless one loses about 4 and 20.
4. The title's four glow pictures (32 KB of aux, about 5 s of the boot) could be one picture and
   the glow's changes.
5. Speed: per-row overhead dominates the blits (about 200 cycles a row against 28 a byte).
6. Content: the final fight (the bulldog king), more spells (Static Fur, Catnip, Mark
   Territory, Knock It Off The Table, Laser Pointer, Belly Rub Trap, Nine Lives).
7. Mockingboard: play it on a real card; balance the mix by ear.

## Art rules

See the header comments in `mockup/battle_forest_v6.py` and `tools/art/actors.py`. Owner's
direction: build on the v6 look; stylized silhouettes, depth, three-quarter angles, NTSC as
the real target with clean as the readability check, expressive faces that carry state.
