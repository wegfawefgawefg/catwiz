# Sim exploration of the faces build (2026-11-03)

What the catalog sim says about the `faces` build (b6f0cf6): 88 faces and 35 charms in the
draws, 52 and 23 of them new. Exploratory: nothing under `game/` was changed. Suggestions are
marked as suggestions and were not applied.

## The short list

Broken, or nearly (the expert wins 88% unforced; "alone" is the face given from fight 1 in its
slot and kept there, 128 runs, against 87.5% with nothing given):

1. Paw Flip. Alone 97.7%; every pair with it but Kitten Cannon 98-100%; forced +3 (the most a card can add near
   the ceiling). The sim lets the search turn only two dice; the game lets her turn every
   unplayed die to any face before her next play, so in the game it is stronger still.
2. Fresh Roll. The best forced card in every third (96%, 93%, 91%); alone 96%; seven of its
   pairs won every run. One mana brings every played die back, up to the five-a-turn cap it
   shares with Red Dot; with Cheap Trick it is free.
3. Red Dot (alone 97.7%), Copycat, Love Bite, Scratching Habit (alone 96%): strong single
   cards. Red Dot and Fresh Roll together won every run.
4. Scratching Habit grows by its whole number, habit included, so each use doubles it (2, 4,
   8, 16 ... 255 by its eighth use). It is in 99% of the fights where a hit reached 255 (1.3%
   of fights, 9% of runs). It is not a win-rate lock (forced -0.7), because damage is rarely
   what kills the expert, but the 255s are all its.
5. Mana Burn with Plus One (or Times Two, Double or Nothing, Stone Cat): the plus and times go
   on its number before the mana multiplies it, so a level-1 Mana Burn after two Plus Ones hit
   the King for 50 (seed 6300018). Mana Burn's pairs have the biggest lifts (+5 to +7).

Unusably bad (forced at or under a blank face of its slot, or far under a skip):

1. Coin Flip: forced 28%, 47%, 53%; 29 points under a blank wand; taken 0% when offered. Tails
   is half its number at her, through her shield, at 10 hp.
2. Blood Moon (3 hp a cast) and Hiss (2 hp): under a blank in all three thirds. A hit point
   is a tenth of her life and the nap is the only healing between fights.
3. Hat Trick: under a blank in all three thirds (69%, 78%, 88%). Its draws include Blood Moon,
   Hiss, Coin Flip, Fresh Roll at the wrong time and faces with no target.
4. Kitten Cannon: no better than a blank (67%, 73%, 73%; a blank wand 67%, 72%, 75%) without
   kittens, and the expert never has many: it is never taken.
5. Cursed Coin: the one bad charm, -11 forced; every other charm is within 2 points.
6. Weak but not dead: Puffed Up (60% at fight 1: it replaces Fluff, and doubling no shield is
   2), 3 AM Screaming, Plague, Shield Bash, Feather Toy (taken 1% of the time it is offered).

Healthy: most of the pool. 62 of the 88 faces force within 5 points of the unforced runs and
are never at or under a blank; the charms (but Cursed Coin) within 2; no face is taken more
than 56% of the time it is offered (Catnap 68%, the one exception); the nap's heal and its
levels win within 3 points of each other.

The game is easy for the expert: 88% (the old target was 60-75%), and the King kills 1.5% of
runs. Suggestions are at the end.

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
  fights plus learned values (the picks study, two passes: 192 runs a line from the rollout
  draft, then 384 with the first pass's values). The learned values count 30 hit points for a
  whole run's win rate (768 runs: 0 won 78.5%, 15 86.8%, 30 87.1%, 60 87.4%). Its position
  value is the item sim's with the new statuses added (and two fixes, item 7 below); the
  weights were not retuned (her hp at 3 or 4 a point instead of 2 changed nothing).

```sh
cd tools/sim/cg && make
./catwiz-sim --player search --runs 4096 --learned learned.txt --learn 30
./catwiz-sim --learned learned.txt --learn 30 --replay 6300018   # one run of a seed, told
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
   it has seen the real one; with a hypnotized enemy the enemies' turn is the mean of four
   too. Deeper in a plan (and for Pied Piper) it uses one imagined outcome. Before this, the
   search played Hat Trick whenever its one imagined draw was good (a kit with Hat Trick for
   Plus One won 46%, after it 61%), and Hypnotize whenever its one imagined enemy turn went
   well (the first picks pass had it under a blank curse; now just above one).
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
   wins 85%, the game's own kit 79% (rollout draft, 384 runs). Long fights remain (7% of runs have one over 15 turns),
   from slow kits, not stalls.

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
  is a design question, not a mismatch: Scratching Habit (the short list).

## The players and the range

4,096 runs each (random 20,000, greedy 8,192), the same seeds (61):

| player | won | where the runs end |
|---|---|---|
| random (keys at random) | 0.0% | fight 2 72%, fight 3 25% |
| greedy (the best play now) | 0.0% | fight 2 27%, the old shroom 56% |
| strong (turn search, rollout draft) | 34.1% | the old shroom 21%, the mailman 11%, the King 16% |
| search, rollout draft only (no learned values) | 78.5% (768 runs) | |
| search, a slip a fight (5.5% of plays, 10% of picks random) | 78.3% | the old shroom 6.5%, the mailman 5.5%, the King 3.2% |
| search, a blunder a turn (22%, 25%) | 53.8% | the old shroom 12.5%, the mailman 10.8%, fight 5 5.7%, the King 5.3% |
| search, two a turn (45%, 50%) | 20.2% | the old shroom 23.5%, the mailman 13.7%, fight 5 11.8%, fight 2 10.8% |
| the expert: search, learned draft | 88.3% | the old shroom 4.2%, the mailman 2.3%, the King 1.5% |

The range is wide and falls level by level: a slip a fight (1.1 blunders a fight) costs 10
points, a blunder a turn (1.0 a turn) 34, two a turn 68. The learned draft is worth 10 points
over the rollout draft (78.5% to 88.3%). Greedy and random never win: greedy dies at the old
shroom (56% of its runs). The old shroom and the mailman are where every level below the
expert loses most.

The expert, fight by fight (4,096 runs):

| fight | 1 | 2 | 3 shroom | 4 | 5 | 6 mailman | 7 | 8 | 9 vet or bath | 10 King |
|---|---|---|---|---|---|---|---|---|---|---|
| won | 100% | 99% | 96% | 99% | 99% | 97% | 100% | 100% | 100% | 98% |
| hp lost (of 10) | 1.5 | 2.0 | 2.2 | 1.1 | 1.7 | 2.5 | 0.7 | 0.4 | 1.4 | 3.8 |
| turns | 1.5 | 4.4 | 4.6 | 2.6 | 4.1 | 4.7 | 2.2 | 2.6 | 5.4 | 9.1 |

Runs lost: fight 2 1.5%, the old shroom 4.2%, fight 4 0.6%, fight 5 1.0%, the mailman 2.3%,
fight 8 0.2%, fight 9 0.4%, the King 1.5%. The old shroom is the hardest fight and the King
the third; the King's fight is long (9 turns, 43 at most) but rarely deadly. Doors: the expert
takes the big bath 96% of the time; forced, the vet wins 80.7% and the bath 89.6%. 5.2% of
runs have a fight over 15 turns (slow kits, not stalls).

Starting kits: 64 random kits (a random face of each slot from the faces that can be drawn or
start, no charms; the draft goes on as usual, so a kit's faces can be replaced), 256 runs each
(seed 66). The game's kit won 89.1%. The random kits: mean 89.6%, lowest 43.8%, 10th
percentile 67.6%, median 93.8%, 90th percentile 98.0%, best 99.6% (Chain Bounce, Bell Collar,
Fortify, Meowcronomicon, Catnip Bomb, Paw Flip). Seven kits won under 70%: five have Coin Flip
on the wand, one Kitten Cannon and Hiss, one Blood Moon and Puffed Up. Without the unusable
faces the start barely matters; the game's own kit is below most random ones (34 of 64 beat it
by 4 points or more).

Offers' luck (4,000 runs, seed 65). Of the runs that won fight 2, by the learned worth of the
best card in each of the first two offers: the unluckiest fifth won 80.9%, then 88.1%, 89.5%,
91.5%, the luckiest 94.4%. By the first six offers (runs that won fight 6): 96.5% to 99.0%, so
by then the luck is spent. The same 1,000 seeds with four different draws each: 60.5% of the
seeds won all four, 0.3% none. Most of a run's risk is in the first two picks; a bad first
offer costs about 13 points against a good one.

## Each face

Forced: the card slipped into the offer at the first pick of each third (after fights 1, 4,
7), taken, the rest of the run drafted as usual, 384 runs a line, the same seeds (12); a
line's noise is about 1.5 points. The unforced runs won 89.8%. "vs a skip" is against
skipping that pick (keeping the face she had), "vs a blank" against a face that does nothing
in the same slot (see the blank table). Offered and taken are from 4,096 natural runs (seed
62): the runs that were offered it, the share of offers taken, and of those runs the ones
that took it against the ones that passed. The six +1 rows are the upgrade cards.

The blank faces (that slot's face does nothing from that pick on) and a skip:

| slot | after fight 1 | 4 | 7 |
|---|---|---|---|
| wand | 67% | 72% | 75% |
| fluff | 16% | 46% | 66% |
| star | 63% | 81% | 84% |
| book | 64% | 85% | 86% |
| curse | 80% | 81% | 86% |
| trick | 71% | 85% | 90% |
| skip | 80% | 88% | 89% |

A blank fluff after fight 1 wins 16%: the fluff is the only shield in the starting kit and
every fluff face is worth 40 points over nothing there. The curse slot is worth least (a blank
curse at fight 1 wins 80%, the starting Fleas 80%).

| card | slot | forced after 1, 4, 7 | vs unforced | vs a skip | vs a blank | offered runs | taken when offered | offered: won if taken (if passed) |
|---|---|---|---|---|---|---|---|---|
| Fresh Roll | book | 96%, 93%, 91% | +3.5 | +7.7 | +15.2 | 1587 | 42% | 97% (93%) |
| Paw Flip | trick | 93%, 95%, 92% | +3.1 | +7.4 | +11.0 | 610 | 29% | 99% (94%) |
| Spook | curse | 96%, 92%, 90% | +3.0 | +7.2 | +10.2 | 1512 | 56% | 96% (97%) |
| Fortify | star | 95%, 92%, 91% | +2.8 | +7.0 | +16.7 | 1603 | 35% | 95% (94%) |
| Glare | curse | 94%, 93%, 90% | +2.3 | +6.6 | +9.5 | 1567 | 48% | 96% (96%) |
| Spray Bottle | wand | 93%, 93%, 90% | +2.1 | +6.3 | +20.4 | 1561 | 44% | 96% (95%) |
| Copycat | trick | 92%, 92%, 91% | +1.8 | +6.1 | +9.7 | 1562 | 39% | 95% (95%) |
| Catnap | fluff | 93%, 92%, 90% | +1.7 | +6.0 | +49.3 | 1614 | 68% | 95% (97%) |
| Moon Bowl | star | 92%, 92%, 90% | +1.7 | +5.9 | +15.5 | 1592 | 26% | 94% (95%) |
| Yarn Wand | wand | 92%, 91%, 91% | +1.5 | +5.7 | +19.8 | 1625 | 29% | 94% (94%) |
| Love Bite | wand | 92%, 91%, 90% | +1.3 | +5.6 | +19.6 | 1603 | 46% | 96% (98%) |
| Purr | star | 92%, 92%, 89% | +1.2 | +5.5 | +15.1 | 1635 | 38% | 94% (95%) |
| Drenched | curse | 92%, 91%, 91% | +1.2 | +5.5 | +8.4 | 1609 | 48% | 97% (95%) |
| Catfight | curse | 94%, 89%, 89% | +1.0 | +5.3 | +8.2 | 1600 | 46% | 94% (97%) |
| Red Dot | curse | 91%, 91%, 91% | +1.0 | +5.2 | +8.2 | 635 | 13% | 94% (95%) |
| All In | trick | 90%, 90%, 90% | +0.4 | +4.7 | +8.3 | 568 | 21% | 94% (93%) |
| Leech | curse | 92%, 87%, 90% | +0.0 | +4.3 | +7.2 | 1593 | 13% | 94% (94%) |
| +1 TRICK | trick | 89%, 90%, 91% | -0.1 | +4.2 | +7.8 |  |  |
| Flea Collar | fluff | 88%, 90%, 90% | -0.5 | +3.7 | +47.1 | 1594 | 26% | 93% (94%) |
| +1 WAND | wand | 88%, 91%, 90% | -0.5 | +3.7 | +17.8 |  |  |
| Mouse On String | wand | 86%, 91%, 90% | -0.7 | +3.6 | +17.6 | 1556 | 42% | 96% (93%) |
| Scratching Habit | wand | 88%, 90%, 90% | -0.7 | +3.6 | +17.6 | 1589 | 31% | 94% (95%) |
| Times Two | trick | 89%, 89%, 90% | -0.8 | +3.5 | +7.1 (at or under in 1) | 607 | 16% | 95% (95%) |
| Double Or Nothing | trick | 89%, 88%, 90% | -0.8 | +3.5 | +7.1 (at or under in 1) | 602 | 14% | 92% (96%) |
| Laser Pointer | book | 89%, 89%, 89% | -0.9 | +3.4 | +10.8 | 1562 | 34% | 92% (96%) |
| Fishbone Wand | wand | 88%, 89%, 90% | -0.9 | +3.4 | +17.4 | 1616 | 29% | 93% (94%) |
| Wet | curse | 87%, 90%, 90% | -1.0 | +3.3 | +6.2 | 1584 | 18% | 92% (94%) |
| Ball Of Yarn | curse | 88%, 89%, 90% | -1.1 | +3.1 | +6.1 | 1580 | 17% | 94% (94%) |
| Shooting Star | star | 86%, 90%, 88% | -1.5 | +2.8 | +12.4 | 1651 | 33% | 92% (94%) |
| +1 FLUFF | fluff | 84%, 91%, 91% | -1.5 | +2.8 | +46.1 |  |  |
| Overflow | star | 86%, 89%, 91% | -1.6 | +2.7 | +12.3 | 1559 | 33% | 93% (94%) |
| Laser Show | book | 90%, 86%, 89% | -1.6 | +2.7 | +10.2 | 1544 | 25% | 89% (95%) |
| Calm Paw | wand | 88%, 87%, 90% | -1.6 | +2.6 | +16.7 | 1592 | 27% | 93% (95%) |
| Warm Blanket | fluff | 87%, 87%, 90% | -1.8 | +2.4 | +45.8 | 1579 | 10% | 90% (94%) |
| Big Stick | wand | 87%, 88%, 89% | -1.8 | +2.4 | +16.5 | 1534 | 24% | 92% (95%) |
| +1 STAR | star | 84%, 89%, 90% | -1.9 | +2.3 | +12.0 |  |  |
| +1 BOOK | book | 86%, 87%, 90% | -2.3 | +2.0 | +9.5 |  |  |
| Sunbeam | star | 83%, 90%, 90% | -2.3 | +2.0 | +11.6 | 1569 | 11% | 94% (94%) |
| Thick Fur | fluff | 84%, 88%, 90% | -2.5 | +1.7 | +45.1 | 1514 | 42% | 91% (95%) |
| Chain Bounce | wand | 86%, 88%, 88% | -2.6 | +1.7 | +15.7 | 1555 | 9% | 90% (94%) |
| Lucky Paw | fluff | 84%, 88%, 89% | -2.8 | +1.5 | +44.8 | 1606 | 11% | 90% (94%) |
| Static Fur | fluff | 85%, 86%, 91% | -2.9 | +1.4 | +44.7 | 1570 | 10% | 90% (92%) |
| Hairball Wall | fluff | 83%, 88%, 90% | -3.0 | +1.2 | +44.5 | 1567 | 13% | 96% (93%) |
| Knead | trick | 81%, 88%, 91% | -3.1 | +1.1 | +4.8 | 1564 | 18% | 97% (93%) |
| Rattle | star | 81%, 90%, 90% | -3.1 | +1.1 | +10.8 | 1605 | 6% | 96% (94%) |
| Puddle Splash | wand | 82%, 89%, 89% | -3.2 | +1.0 | +15.1 | 1619 | 5% | 92% (93%) |
| Mirror Fur | fluff | 83%, 89%, 88% | -3.2 | +1.0 | +44.4 | 1593 | 16% | 92% (93%) |
| Mimic | book | 83%, 87%, 90% | -3.3 | +1.0 | +8.4 | 1592 | 7% | 95% (94%) |
| +1 CURSE | curse | 80%, 89%, 91% | -3.6 | +0.7 | +3.6 (at or under in 1) |  |  |
| Rain Cloud | book | 80%, 87%, 91% | -3.8 | +0.4 | +7.9 | 1605 | 11% | 96% (94%) |
| Wishing Star | star | 82%, 85%, 90% | -3.9 | +0.3 | +10.0 | 1582 | 12% | 96% (93%) |
| Moonbeam | wand | 84%, 86%, 88% | -3.9 | +0.3 | +14.4 | 1547 | 4% | 86% (93%) |
| Mana Burn | book | 79%, 89%, 90% | -3.9 | +0.3 | +7.8 | 1515 | 18% | 96% (94%) |
| Knock It Off | book | 82%, 88%, 88% | -3.9 | +0.3 | +7.8 | 1590 | 28% | 95% (94%) |
| Star Cluster | star | 83%, 87%, 88% | -4.0 | +0.3 | +9.9 | 1550 | 6% | 91% (93%) |
| Bright Star | star | 83%, 85%, 89% | -4.2 | +0.0 | +9.6 | 1568 | 14% | 90% (94%) |
| Moon Tide | star | 82%, 87%, 88% | -4.3 | -0.1 | +9.6 | 1576 | 4% | 87% (94%) |
| Last Stand | trick | 79%, 87%, 91% | -4.3 | -0.1 | +3.6 | 1544 | 12% | 96% (93%) |
| Triple Hex | curse | 82%, 87%, 87% | -4.4 | -0.2 | +2.8 | 1611 | 4% | 83% (94%) |
| Mana Leech | curse | 86%, 83%, 87% | -4.5 | -0.3 | +2.7 | 1554 | 5% | 90% (94%) |
| Mark Territory | curse | 82%, 86%, 88% | -4.6 | -0.3 | +2.6 | 1506 | 2% | 95% (94%) |
| Spell Echo | trick | 80%, 86%, 90% | -4.8 | -0.5 | +3.1 | 642 | 4% | 97% (93%) |
| Hairball Blast | book | 80%, 86%, 89% | -4.8 | -0.5 | +6.9 | 1536 | 16% | 94% (93%) |
| Bell Collar | fluff | 80%, 86%, 89% | -4.8 | -0.5 | +42.8 | 1593 | 2% | 93% (93%) |
| Flea Circus | curse | 84%, 85%, 86% | -4.8 | -0.5 | +2.4 (at or under in 1) | 1615 | 10% | 92% (93%) |
| Cardboard Box | fluff | 80%, 86%, 89% | -4.8 | -0.5 | +42.8 | 1581 | 3% | 94% (94%) |
| Lullaby | book | 79%, 87%, 89% | -4.9 | -0.6 | +6.9 | 1605 | 8% | 89% (94%) |
| If It Fits | book | 78%, 88%, 89% | -4.9 | -0.6 | +6.9 | 1552 | 4% | 94% (93%) |
| Flea Comb | curse | 83%, 83%, 89% | -4.9 | -0.6 | +2.3 | 1598 | 10% | 90% (94%) |
| Stone Cat | trick | 79%, 88%, 89% | -4.9 | -0.7 | +3.0 (at or under in 1) | 1637 | 6% | 97% (93%) |
| Spiky Fluff | fluff | 79%, 86%, 90% | -4.9 | -0.7 | +42.6 | 1548 | 4% | 96% (94%) |
| Catnip | trick | 77%, 88%, 90% | -4.9 | -0.7 | +2.9 | 1569 | 12% | 96% (93%) |
| Catnip Bomb | curse | 85%, 83%, 86% | -5.1 | -0.9 | +2.1 (at or under in 1) | 1564 | 12% | 88% (94%) |
| Snowball | book | 79%, 85%, 90% | -5.2 | -1.0 | +6.5 | 1550 | 15% | 95% (94%) |
| Thunder Purr | book | 80%, 84%, 90% | -5.2 | -1.0 | +6.5 (at or under in 1) | 1545 | 5% | 91% (94%) |
| Box Slam | wand | 78%, 87%, 89% | -5.3 | -1.0 | +13.0 | 1570 | 4% | 94% (94%) |
| Claw Swipe | wand | 78%, 87%, 88% | -5.5 | -1.2 | +12.8 | 1615 | 4% | 97% (94%) |
| Flea Market | star | 76%, 88%, 90% | -5.5 | -1.2 | +8.4 | 1566 | 3% | 97% (93%) |
| Meowcronomicon | book | 78%, 86%, 89% | -5.5 | -1.3 | +6.2 | 1592 | 12% | 97% (94%) |
| Hypnotize | curse | 84%, 81%, 86% | -6.0 | -1.7 | +1.2 (at or under in 1) | 1587 | 8% | 80% (94%) |
| Sharpen Claws | trick | 74%, 88%, 89% | -6.2 | -1.9 | +1.7 (at or under in 1) | 1622 | 3% | 94% (93%) |
| Grudge | wand | 78%, 85%, 89% | -6.2 | -1.9 | +12.1 | 1595 | 2% | 94% (93%) |
| Scratch The Itch | wand | 79%, 84%, 88% | -6.6 | -2.3 | +11.7 | 1600 | 2% | 90% (94%) |
| Litter Star | star | 74%, 86%, 89% | -7.1 | -2.9 | +6.8 | 1534 | 2% | 97% (92%) |
| Shield Bash | book | 72%, 83%, 90% | -7.9 | -3.6 | +3.8 (at or under in 1) | 1558 | 4% | 94% (93%) |
| Feather Toy | wand | 75%, 83%, 86% | -8.4 | -4.2 | +9.9 | 1592 | 1% | 92% (94%) |
| Plague | book | 65%, 85%, 88% | -10.4 | -6.2 | +1.3 | 1527 | 4% | 97% (93%) |
| 3 Am Screaming | book | 70%, 81%, 86% | -10.7 | -6.4 | +1.0 (at or under in 1) | 1561 | 2% | 97% (94%) |
| Hat Trick | trick | 69%, 78%, 88% | -11.8 | -7.6 | -3.9 (at or under in 3) | 602 | 6% | 92% (93%) |
| Puffed Up | fluff | 60%, 83%, 85% | -14.0 | -9.7 | +33.6 | 1597 | 0% | 100% (93%) |
| Hiss | trick | 61%, 79%, 87% | -14.1 | -9.9 | -6.2 (at or under in 3) | 1575 | 1% | 100% (93%) |
| Kitten Cannon | wand | 67%, 73%, 73% | -18.8 | -14.6 | -0.5 (at or under in 2) | 1562 | 0% | 90% (93%) |
| Blood Moon | book | 52%, 75%, 85% | -19.0 | -14.8 | -7.3 (at or under in 3) | 1534 | 0% | 100% (94%) |
| Coin Flip | wand | 28%, 47%, 53% | -47.1 | -42.9 | -28.8 (at or under in 3) | 1563 | 0% | nan% (94%) |

## Each charm

Forced at the charm pick after each elite (fights 3, 6, 9), 384 runs a line:

| charm | forced after 3, 6, 9 | vs unforced | offered runs | taken when offered | offered: won if taken (if passed) |
|---|---|---|---|---|---|
| Scratch Post | 93%, 91%, 91% | +2.0 | 928 | 65% | 97% (97%) |
| Flea Farm | 91%, 91%, 90% | +1.0 | 926 | 60% | 97% (97%) |
| Storm Cloud | 91%, 90%, 90% | +0.7 | 944 | 60% | 96% (96%) |
| Lucky Collar | 91%, 90%, 90% | +0.5 | 928 | 72% | 97% (97%) |
| Head Start | 90%, 91%, 90% | +0.4 | 933 | 47% | 96% (97%) |
| Pied Piper | 90%, 90%, 91% | +0.4 | 927 | 39% | 95% (97%) |
| Spare Yarn | 89%, 91%, 90% | +0.4 | 899 | 39% | 96% (97%) |
| Nine Lives | 91%, 90%, 90% | +0.3 | 960 | 76% | 96% (100%) |
| Rubber Duck | 89%, 91%, 90% | +0.3 | 927 | 43% | 97% (95%) |
| Mother Cat | 89%, 91%, 90% | +0.1 | 945 | 50% | 95% (96%) |
| Lucky Seven | 90%, 90%, 90% | +0.1 | 979 | 33% | 96% (96%) |
| Thick Skin | 89%, 90%, 90% | +0.0 | 907 | 50% | 97% (96%) |
| Hunger | 90%, 91%, 89% | +0.0 | 937 | 50% | 97% (96%) |
| Thick Coat | 89%, 90%, 90% | -0.3 | 893 | 55% | 97% (96%) |
| Momentum | 90%, 89%, 89% | -0.3 | 995 | 34% | 96% (97%) |
| Porcupine | 88%, 91%, 89% | -0.3 | 957 | 33% | 98% (96%) |
| Bad Milk | 89%, 90%, 90% | -0.4 | 951 | 44% | 97% (96%) |
| Purrfect Trio | 88%, 89%, 90% | -0.9 | 917 | 16% | 97% (96%) |
| Ninth Life | 87%, 90%, 90% | -1.0 | 957 | 18% | 96% (96%) |
| Grumpy Face | 88%, 89%, 89% | -1.0 | 979 | 20% | 96% (96%) |
| Rain Boots | 86%, 90%, 89% | -1.1 | 909 | 16% | 96% (97%) |
| Fluffy Tail | 88%, 89%, 89% | -1.2 | 916 | 30% | 94% (95%) |
| Cheap Trick | 87%, 90%, 89% | -1.2 | 931 | 29% | 96% (96%) |
| Still Water | 86%, 90%, 90% | -1.3 | 954 | 21% | 96% (95%) |
| Troublemaker | 87%, 89%, 90% | -1.4 | 915 | 17% | 95% (96%) |
| Sixth Toe | 87%, 89%, 89% | -1.4 | 917 | 31% | 96% (97%) |
| Mana Battery | 87%, 89%, 89% | -1.5 | 328 | 10% | 94% (97%) |
| Nap Spot | 87%, 89%, 89% | -1.6 | 977 | 14% | 97% (95%) |
| Skip | 86%, 90%, 89% | -1.6 |  |  |
| Monsoon | 85%, 90%, 90% | -1.6 | 939 | 16% | 98% (95%) |
| Litter Box | 86%, 89%, 89% | -1.6 | 949 | 10% | 97% (96%) |
| Echo | 85%, 90%, 89% | -1.8 | 930 | 10% | 95% (97%) |
| Kitten Mittens | 86%, 89%, 89% | -1.9 | 914 | 6% | 100% (97%) |
| Jackpot | 86%, 89%, 89% | -1.9 | 356 | 9% | 100% (95%) |
| Itchy | 85%, 89%, 89% | -2.2 | 932 | 11% | 96% (96%) |
| Cursed Coin | 72%, 83%, 83% | -10.9 | 949 | 4% | 90% (97%) |

The charms barely matter: every one but Cursed Coin forces within 2 points of the unforced
runs and of a skip (-1.6). Cursed Coin (a sixth die for 1 hp a turn) is -11. Scratch Post (+2)
is the best.

## Broken

Hits of 255 (4,096 runs, seed 63): 1.3% of fights (508) have one, 9.0% of runs; a turn whose
hits add up to 255 or more 1.35%. Scratching Habit is in 99.0% of those fights (18.8 times its
share of all fights); nothing else is in more than 13%. Replay: seeds 6300001 (fight 10),
6300007, 6300034, 6300044 (fight 9). Every seed in this file replays with
`./catwiz-sim --learned learned.txt --learn 30 --replay SEED`. The most hit points one turn took: 84 (the enemies'
hit points cap it; the biggest single hits are 255).

The biggest turn of each fight, her hits added up: under 20 21%, 20-49 70%, 50-99 6.8%,
100-199 0.8%, 200-299 0.9%, 300-499 0.4%, 500 or more 0.2%.

Beaten in one of her turns from full hit points, of the fights it stood in:

| enemy | hp | one-turn kills | seeds |
|---|---|---|---|
| The old shroom | 56 | 0.2% of 4,026 | 6300123, 6300386 |
| The mailman | 70 | 0.4% of 3,780 | 6300150, 6300292 |
| The vet | 70 | 9.1% of 143 | 6300242, 6300312 |
| The big bath | 80 | 2.3% of 3,535 | 6300002, 6300012 |
| Drain gremlin (the bath's second form) | 24 | 66.5% of 3,519 | 6300000, 6300001 |
| Bulldog King | 66 | 4.3% of 3,659 | 6300018, 6300068 |
| Bulldog King, cross | 66 | 20.0% of 3,624 | 6300001, 6300022 |
| Bulldog King, furious | 68 | 19.8% of 3,617 | 6300001, 6300044 |

No fight with the King was won on its first turn (0.0%); the big bath 0.1%, the vet 9.1%.
The King's later forms fall in one turn a fifth of the time: they come with fewer wards (1,
then 0) and her kit is at its biggest. Seed 6300018: Mana Burn after two Plus Ones hits the
King for 50, then 18.

Loops: none run away. Her dice came back the most a turn (5) in 2.3% of fights (seeds
6300009, 6300012, 6300017): the cap holds. No hat trick drew a hat trick drawing a hat trick
(calls three deep) in 4,096 runs; the most steps one play took was 1,256 (the guard is
200,000): no play ran away. A start kit built to chain (Big Stick,
Fresh Roll, Red Dot, Spell Echo, Cheap Trick) brought the dice back to the cap in 19% of its
fights and won 94% of 256 runs; still no loop.

Pairs (`--study lift`, 25 suspects given from fight 1, 128 runs a cell, the first pass's
learned values; nothing given 87.5%):

| alone | won | | alone | won |
|---|---|---|---|---|
| Paw Flip | 97.7% | | Mimic | 91.4% |
| Red Dot | 97.7% | | Snowball | 89.8% |
| Fresh Roll | 96.1% | | Times Two | 89.8% |
| Copycat | 96.1% | | Double or Nothing | 89.1% |
| Love Bite | 96.1% | | Mana Burn | 88.3% |
| Scratching Habit | 96.1% | | Stone Cat | 87.5% |
| Catfight | 95.3% | | Mana Battery (charm) | 87.5% |
| Catnap | 94.5% | | Thunder Purr | 85.9% |
| Drenched | 94.5% | | Meowcronomicon | 85.9% |
| All In | 93.8% | | Box Slam | 83.6% |
| Spell Echo | 92.2% | | Sharpen Claws | 82.8% |
| | | | Hat Trick | 77.3% |
| | | | Hiss | 71.1% |
| | | | Kitten Cannon | 67.2% |

15 of the 231 pairs won all 128 runs; 13 of them have Paw Flip or Fresh Roll. The biggest lifts
(the pair against the better of its two alone): Mana Burn with Box Slam, Double or Nothing or
Stone Cat (+6 to +7), Times Two with Meowcronomicon (+7), Times Two with Mana Burn (+5). Paw
Flip's pairs add at most +2: it is at the ceiling alone. Kitten Cannon with Paw Flip lost 12
points against Paw Flip alone (both take a slot from a better face). No triple was run: the
pairs are at the ceiling already.

## Domains

The domains are docs/faces.md's groups (`gen.py` DOMAIN_OF; a few cards are in two, the
starting faces count). Of 4,096 natural runs (seed 64), a kit held 3 faces or more of one
domain walking into the last fight it reached in 4.5% of runs; counting her charms too, 27%.
docs/faces.md expected 69% (faces and charms) under five mixed offers. The expert does not
build domains: with 88 faces drawn five at a time, nine card picks and one face a slot, a third
face of one domain rarely comes while it still wants one.

| domain | faces in the draws | charms | runs with 3+ faces | those runs won |
|---|---|---|---|---|
| simple | 5 | 3 | 0.2% | |
| kittens | 6 | 3 | 0.0% | |
| three | 8 | 2 | 0.1% | |
| fleas | 6 | 2 | 0.0% | |
| wet | 8 | 3 | 0.4% | |
| shield | 10 | 3 | 0.4% | |
| life | 8 | 3 | 0.5% | 95.5% (22 runs) |
| mana | 8 | 5 | 0.5% | 54.5% (22 runs) |
| dice | 7 | 5 | 0.4% | |
| chaos | 12 | 2 | 1.8% | 94.5% (73 runs) |
| growth | 4 | 2 | 0.0% | |
| gambles | 4 | 2 | 0.0% | |

Too few runs build a domain to say which domains win when built. What a domain's cards are
worth one at a time, forced (the mean of its faces' and charms' forced lines against the
unforced runs):

| domain | cards | mean forced | its best | its worst |
|---|---|---|---|---|
| dice | 12 | -0.4 | Fresh Roll | Rattle |
| simple | 8 | -1.2 | Glare | Hairball Blast |
| wet | 11 | -1.7 | Spray Bottle | Thunder Purr |
| mana | 13 | -2.4 | Bad Milk | Spell Echo |
| chaos | 14 | -2.6 | Spook | 3 AM Screaming |
| growth | 6 | -3.1 | Thick Skin | Grudge |
| shield | 13 | -3.2 | Fortify | Puffed Up |
| life | 11 | -3.2 | Catnap | Blood Moon |
| three | 10 | -3.6 | Purrfect Trio | Claw Swipe |
| fleas | 8 | -4.2 | Flea Farm | Plague |
| kittens | 9 | -4.3 | Mother Cat | Feather Toy |
| gambles | 6 | -12.0 | All In | Coin Flip |

The gambles lose: Coin Flip, Hat Trick and Cursed Coin are three of its six. Kittens and
fleas are the weakest of the rest: their payoffs (Kitten Cannon, Meowcronomicon, Plague, Flea
Comb) want a build the draws do not give.

## Suggestions (not applied)

1. Suggestion: Paw Flip turns one die. Clear `flip` after the first turn of a die (in
   `turn.select`, or a step), as its line reads ("Turns a die to the face you pick"). Today it
   is the strongest face in the sim with the sim using only two turns of it.
2. Suggestion: Fresh Roll costs 2, or brings the dice back once a turn (its own cap, not the
   five shared with Red Dot). At 1 mana it is the best forced card in every third.
3. Suggestion: Scratching Habit grows by its step, not its number. Its steps are `(hit) (num)
   (add habit)`, and `num` includes the habit, so each use doubles it; the owner's note
   (91e5caa) reads "grows by its number (2, +1 a level)", which reads as the base. A step that
   gives the face's number without the habit, or `(lit 1)` and a bigger amount, would keep it
   linear.
4. Suggestion: Coin Flip's tails at half its number is too costly at 10 hp: tails a quarter,
   or tails hitting her shield only, or heads x2 for the same risk.
5. Suggestion: Blood Moon and Hiss cost 1 hp, or cost hp only when they kill nothing. A hit
   point is a tenth of her life; the sim never takes them.
6. Suggestion: Hat Trick draws from the faces she could be offered with weight (not the
   hairball, and not the hp-cost faces), or from her slot's faces.
7. Suggestion: Kitten Cannon makes a kitten when she has none, or the kitten domain gets one
   more kitten source: today the cannon is a blank.
8. Suggestion: Cursed Coin's hit point every turn is the price of a whole sixth die; a hit
   point a fight would be closer to Sixth Toe's re-roll.
9. Suggestion: the expert wins 88% and the King kills 1.5% of runs. If 60-75% is still the
   target, the elites and the King need more (the old shroom kills the most, 4.2%). A sim of
   it is cheap now: change the rows, `make`, run the expert.
10. Suggestion: look at the starting kit: it is weaker than most random kits (see the kits
    table). If the start is meant to be plain, that is fine; if not, any slot of it is a
    place to add.
11. Suggestion: if domains are meant to form, the draws need a lean toward what she holds
    (docs/faces.md dropped it); with five mixed cards 4.5% of runs hold three faces of one.
