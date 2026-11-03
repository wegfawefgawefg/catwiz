# Sim exploration of the faces build (2026-11-03)

What the catalog sim says about the `faces` build (b6f0cf6): 88 faces and 35 charms in the
draws, 52 and 23 of them new. Exploratory: nothing under `game/` was changed. Suggestions are
marked as suggestions and were not applied.

RESULTS

## Validation against the game

`tools/sim/cg/validate.py` builds a test copy of the game in a scratch folder (the repo's
`game/` with `items.STARTING_ITEMS`, `battle.START_STAGE`, `START_CHARM` and `SEED` changed),
boots it in `tisple machine` headless with the Mockingboard, and plays it key by key from
snapshots. At every step it reads the machine's whole battle state through
`build/catwiz.vars.json` (her kit and charm totals, every actor, all 120 stack bytes, the
dice, the turn's flags, the engine lets that carry between steps such as `effects.three`,
`hooks.blocked`, `hit.lost`, and `random.seed`), has `catwiz-check` take the same step from
that state with lib/random's xorshift seeded from the machine, and compares the state after:
hit points, who stands, every stack, the dice and their faces, re-rolls, combos, last face,
kept kittens, spent charms, the target and the random seed (so the number of random bytes
drawn must match too). The steps are a die played, a paw flip's turn, a re-roll, and the
turn's end with the enemies' turn, their statuses and the next roll.

| suite | cases | steps compared | differ |
|---|---|---|---|
| `--suite`: 10 kits of new faces, 6 seeds over two runs | 50 runs | 931 | 0 |
| `--suite2`: 30 charms, each from fight 2, and 3 hook kits, 2 seeds | 66 runs | 1,246 | 0 |
| Scratching Habit at the old shroom | 1 | 29 | 0 |

The plays covered every op the brief lists: plus and t_plus (Grudge, Scratch the Itch), more
(Puddle Splash, Box Slam, Calm Paw, Thunder Purr), half (Chain Bounce, Shield Bash, Coin
Flip), fell (Moonbeam), landed (Love Bite), low (Last Stand), coin (Coin Flip, 8 plays),
if_calm (Calm Paw), t_times (Flea Comb), no_rerolls (All In), hat (Hat Trick, 19 plays), and
the hooks: Red Dot, Mirror Fur, Flea Collar, Hairball Wall, Leech, Mana Leech, Porcupine's
quills, Double or Nothing's bet. Every charm but Lucky Collar and Ninth Life (they act
between fights) was held in at least two runs. The comparisons
include the enemies' turns, so the new statuses (scared, hypnotized, berserk, asleep, snagged,
lasered) were checked through the moves they changed.

Not covered or not settled:

- Five steps the harness could not press: it chose a key the game refused (a die or a target
  the machine's state read as playable). The case stopped there; nothing was compared.
- The draws between fights (offers, charms, nap) are not compared: the sim mirrors
  `battle/offer.tsp` but takes its own random numbers, not the game's.
- The fight's end and the reward screen are compared only as "won" or "lost": the ending's
  drawing leaves aux memory switched in, and the machine's memory does not read there.
- The game's own row text agrees with the steps everywhere I read it, with one exception that
  is a design question, not a mismatch: Scratching Habit (below).

## The sim

`tools/sim/cg/` is a new sim, the catalog sim. `tools/sim/c/` (the item sim on the proposal
tables) is untouched and still builds, but it knows none of the new cards and plays the old
30 hp tables, so nothing here comes from it.

The catalog sim is the C sim's players and studies on a port of the game's own engine:

- `gen.py` writes `gen_content.h` from the game's files: every face's and charm's row with its
  steps (through `tools/sim/catalog.py`), cards.tsp's shared rows, hooks and Mimic's table, the
  51 statuses, the enemies, moves and fights, the six upgrades' weights and the engine numbers
  (BACK_MOST, REROLLS_MOST, KITTEN_HIT, ITEM_MOST ...). Each step is compiled to its two bytes
  the way `steps.tsp`'s macro does it. A new or retuned card needs no sim code: `make` rebuilds
  the header when a content file changes.
- `play.c` is `content/play.tsp` line for line (the step loop, calls three deep, loops three
  deep, the hooks' queue of four, the echo charm and Spell Echo, copy, look and mimic, hat);
  `fx.c` is `content/effects.tsp` and `content/charms.tsp`; `hit.c` is `battle/hit.tsp` and
  `content/statuses.tsp`; `foes.c` is `content/foes.tsp`; `battle.c` is `battle/turn.tsp`,
  `battle/dice.tsp` and the fight's start in `battle/battle.tsp`. The stacks are the game's one
  120-byte table with its offsets, every number a byte that stops at 255.
- The run is the game's: 10 hp, ten fights, the doors before fight 9, five cards a reward by
  the rows' weights (the six upgrades among them; a held face is its slot's upgrade; five
  different; a level only below 2 a slot; no gates), three charms after an elite (Ninth Life's
  hit points first), then the nap or a level. A card or a charm can be skipped, as in the game.
  The enemies, fights and offer rules are read from `game/content` and `battle/offer.tsp`, so
  they match the branch by construction.
- The players: random, greedy and strong (the item sim's, adapted), and the searching player
  ("search", the expert): every order of the dice shown and every target to the turn's end and
  the enemies' moves, re-rolls judged by sampled rolls, the draft by rollouts of the next three
  fights plus learned values (the picks study, two passes). Its position value is the item
  sim's with the new statuses added; the weights were not retuned.

```sh
cd tools/sim/cg && make
./catwiz-sim --player search --runs 4096 --learned learned.txt --learn 30
./catwiz-sim --replay 6300042                      # one run of that seed, told turn by turn
./catwiz-sim --study picks --runs 384 --out learned.txt --table picks.tsv
./catwiz-sim --study cards|broken|domains|luck|kits|lift --learned learned.txt --learn 30 ...
python3 validate.py --suite ; python3 validate.py --suite2   # against the real game
python3 tiers.py picks.tsv cards.txt 384                     # the tables below
```

The learned values (`learned.txt`) are committed; the heavy runs were on the Mac mini, 12
threads, about 30 search runs a second.

Where the sim stands in for a player's decision it uses a heuristic. These are approximate:

1. Paw Flip. In the game a flip lasts until she plays a die, and in that time she can turn
   every unplayed die to any face (pick a die, pick it again to turn it, then the next die).
   The search turns at most two dice, each once, and none in imagined re-rolls. The sim
   under-rates Paw Flip, if anything.
2. Hat Trick, Coin Flip, Overflow and Flea Circus take random numbers. The real fight takes
   the game's; the search averages four imagined outcomes of such a play and plans again once
   it has seen the real one. Deeper in a plan (and for Pied Piper and hypnotized enemies) it
   uses one imagined outcome. Before this, the search played Hat Trick whenever its one
   imagined draw was good: a kit with Hat Trick for Plus One won 46%, after it 61%.
3. Targets: a face for an enemy is tried on every enemy, Hat Trick too (its face goes to the
   target); her own faces and hit-alls have none.
4. Dice coming back (Red Dot, Fresh Roll) end a line of the search, worth the position plus 3
   a die, then sampled over 10 imagined rolls.
5. The draft's rollouts are played by the greedy player, who mostly dies at the old shroom,
   so the draft's skill is mostly the learned values.
6. Re-rolls are searched as in the item sim (every outcome for two dice or fewer, else 10
   rolls, the best 3 again with 30).
7. The position value was the item sim's, and it had two holes the new cards found; both are
   fixed in the sim (not the game). Marks, wet and leech counted their whole stack, so the
   search piled Drenched on a possum at 1 hp (wet 99, marked 31) instead of beating it and
   facing its next form, and the fight ran to the 60-turn cap (a loss): a kit with Drenched
   for Fleas won 60%, a blank curse 74%. And a form's next forms (the possum getting up, the
   King's phases) were not a threat until they came, so the search kept the King at 1 hp for
   40 turns. Now a status is worth at most what it can still pay out, capped by the hit points
   it stands on, and the next forms' moves count while a form stands: the same Drenched kit
   wins 85%, the game's own kit 79%. Long fights remain (7% of runs have one over 15 turns),
   from slow kits, not stalls.
