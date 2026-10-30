# Plan

Witchdog: a toy Apple II hi-res dice roguelike in Tisple ][, to prove the compiler and an
engine. Owner, 2026-10-30: an homage in the genre, not a remake; no text or data from any
other game; all content gets replaced later by much stranger stuff.

## Where it stands (2026-10-30, branch `witchdog-start`)

First playable slice, booting from `build/witchdog.dsk` (built from `game/`):

1. Title: WITCHDOG glowing over night clouds, the dog against a big moon, Press Return, a
   speaker jingle. The glow is four pictures in aux memory copied in turn.
2. One forest battle: the dog against a puffcap, a sporelet and a nightflap.
   - 5 dice roll at the start of each turn; 1-5 plays one on the target (LEFT and RIGHT pick
     it), R re-rolls the unplayed ones (twice a turn), B barks (once a turn: spooks the
     target), E or RETURN ends the turn.
   - Enemies show their next move over their heads and make it on their turn.
   - Statuses: shield (soaks hits until the holder's next turn), burn (hurts at the end of
     each of the holder's turns, then dies down), spook (the holder's hits do less).
   - Hit feel: white flash, 2-column knockback, 3-frame hit-stop, a number floating up, the
     hurt face; the beaten blink, then puff away. Lunges jump, bolts arc.
   - Win and lose banners, then RETURN goes back to the title.
3. Speaker sounds: bark, dice rattle, zap, hits, shield ping, mend chime, fire hiss, spook
   wobble, the dog's yelp, the death squeak, win and lose.
4. Mockingboard (2026-10-30, branch `witchdog-sound`): found in any slot at start. A title
   theme (E minor, 7-tick pulse: loops of 7, 12, 13, 16 and 5 pulses coming in one by one) and
   a battle theme (A dorian, 9-tick pulse: loops of 12, 10, 9, 7 and 15), won and lost
   stingers, and card versions of every effect plus the die played, an enemy's move, turn start
   and end, the target moving, RETURN on the title and a dead key. The speaker's sounds stay
   when there is no card. The music costs about 900 cycles a tick (5% of the processor) and
   about 4% of the battle's frame rate.

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

1. Play it on the real IIe (FloppyEmu or ADTPro) and fix what only hardware shows.
2. Speed: per-row overhead dominates the blits (about 200 cycles a row against 28 a byte);
   the dog, 79 rows tall, costs about 44,000 cycles to move. Ideas: pre-offset sprite
   pointers, split the dog into hat and body, skip rows the move leaves the same.
3. Room: main memory and the language card are nearly full (code 16 KB). The four title
   pictures (32 KB of aux, 8 tracks, about 5 s of the 10 s boot) could be one picture and the
   glow's changes.
4. Check for 128 KB at start and say so on a 64 KB machine.
5. Content: the real strange stuff, more encounters, a run of battles.
6. Mockingboard: play it on a real card; balance the mix by ear (written blind, by numbers).

## Art rules

See the header comments in `mockup/battle_forest_v6.py` and `tools/art/actors.py`. Owner's
direction: build on the v6 look; stylized silhouettes, depth, three-quarter angles, NTSC as
the real target with clean as the readability check, expressive faces that carry state.
