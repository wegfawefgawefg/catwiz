# Balance

The balance sim (`tools/sim/`), what it says about fights 1-2 today, the targets, and the
proposal for fights 1-10 and the bulldog king: the item-slot model, tuned with the sim. Numbers
are from the sim at the commit that last touched this file; rerun them before trusting a
small difference (100 strong runs swing a win rate by about 5 points).

## The sim

Python 3, no packages. It reads the content tables themselves (`tools/sim/tsp.py` parses the
`.tsp` s-expressions; no number is retyped) and plays the engine's rules step by step
(`rules.py`, `foes.py`; each function names the engine function it copies). The proposals'
mechanics are the sim's own until the engine has them (`items.py` for the item model,
`bagfx.py` for the bag model's proposal).

```sh
python3 tools/sim/run.py                                     # the game's fights 1-2, all players
python3 tools/sim/run.py --content proposal --policy strong --runs 400 --picks
python3 tools/sim/run.py --content proposal --trace --policy greedy --runs 1 --jobs 1
python3 tools/sim/run.py --content bag --variant upgrade=single    # tools/sim/variants.py
python3 tools/sim/study.py bagsize|upgrades|heal|items|tricks      # the comparisons below
python3 tools/sim/validate.py                                # against the real game
```

Content sets: `game` (game/content), `proposal` (tools/sim/proposal, the item-slot model) and
`bag` (tools/sim/proposal_bag: the same fights in the bag model, kept to compare). Runs are
seeded (run n of `--seed s` is seed s * 100000 + n) and use 8 processes.

Players:

- random: plays a random playable die on a random enemy until none is left; re-rolls or ends at
  random when stuck; random rewards. A player mashing keys.
- greedy: each step plays the die and target that leaves the best position after the enemies'
  shown moves (they are deterministic); ends when no die helps; re-rolls the dice it would not
  play. Rewards by a fixed table of what faces are worth.
- strong: searches the whole turn (every order of dice and targets, merged where they meet, then
  the enemies' moves), and whether to play some dice and re-roll the rest (sampling the
  re-roll); rewards, charms, the nap and the elite door by rollouts of the next fight. It is a
  good player, not a perfect one: it sees one turn ahead and the next fight in its rollouts.

Speed (8 processes): random about 1,300 full runs a second, greedy 700, strong 4-7 (the game's
two fights: 2,300, 1,700 and 70). The strong player is the slow one; use it for the final word
and greedy to iterate.

Guesses and limits:

- The sim takes the Mockingboard's random numbers: without the card the speaker's noise
  effects draw random bytes too, so the dice differ from the machine's (the rules do not).
- The engine's timing (animations, the beat before a turn ends) is not modelled; only the
  order of events.
- The policies value hit points at twice an enemy's (`policy.py`, `W_HP`): a human may play
  more or less carefully.

## How close it is to the game

`validate.py` builds the disk, boots it in Tisple's machine headless with the Mockingboard
(never a window), presses keys one at a time (each waits until the game has read it), and after
every die played, every re-roll and every enemy turn compares the machine's memory (each
actor's hit points and statuses, mana, boosts, who stands, each enemy's next move) with the sim
fed the same dice. It plays fights 1 and 2 (and the reward between) from many start frames with
the greedy, random and strong players.

Result (2026-10-30, 21 runs of fights 1-2): 954 comparisons, 0 mismatched. Separately the sim
predicted the machine's own dice from its random seed (the xorshift of lib/random, the bag's
draw and the 4 tumbles of a roll): 204 of 204 deals and re-rolls right. Zoomies that outlast the
enemies and hit the cat (below) happened in the machine twice and the sim matched both.

One thing to know when reading memory: when a fight ends the game copies a song in from aux
memory with aux switched in for reading, and a peek in that moment reads aux (the cat showed 0
hit points once). validate waits two frames after a fight ends.

## Targets

What "balanced" means here, as numbers the sim measures. "Strong", "greedy", "random" are the
players above.

| target | why |
|---|---|
| random dies by fight 4-6 | mashing keys gets through the day, not the dusk |
| greedy (no plan) dies around fights 5-8, wins under 5% | playing the best die now is not enough |
| strong wins 50-75% | a good player wins more often than not, not always |
| strong reaches the boss under half hit points | the run's hit points are its resource |
| a normal fight costs a strong player about 10% (2-5 hit points), an elite 15-30% | the owner's numbers (normal 10%, elite 25-30%) |
| fights last 3-6 turns, the boss about 8-12 | long enough to plan, short enough not to grind |
| hit points lost rise by zone | day, dusk, night get harder |
| no healing loop: a strong player cannot stall a fight to heal up | hit point tension |
| no reward card in more than about 80% of won runs, no slot's item never taken | choices matter |
| no face is a dead weight (played under 50% of the times it is rolled) | every face does something |

## Fights 1-2 today (the game's content)

FIGHTS_TODAY

What the sim says is off in fights 1-2:

1. Zoomies hit the cat. `effects.next_standing` keeps its search in a u8: when the last enemy
   falls before zoomies' five hits are done, the next search starts from NOTHING (255), wraps to
   0, finds the hero standing and the next hit strikes her. In the sim it happened in 7-16% of
   runs; the machine did it too (validate matched both cases). The fix is one line: stop when
   `next_standing` gives NOTHING, or skip index 0.
2. The fights are easy: every player wins both, even random (it loses about 15 of 30 hit
   points). The strong player loses 2.0 and 4.7 (about 7% and 16%); greedy 2.9 and 7.1.
3. The cardboard box's "hit-alls miss you" does nothing yet: no enemy move is a hit-all. Today it
   is shield 6 for 2 mana.
4. "Take a die out" with five dice in the bag is a pure loss: with a bag of five every die comes
   up every turn anyway (the tray takes five), so removing one leaves four dice a turn. Only a
   full bag of six has a die sitting out each turn; there removal makes the other five come up
   every turn. The reward text ("fewer dice: the rest come up more") is true only then.
5. A new die is worth little: with HAND 5 and BAG_MOST 6 the sixth die only replaces the
   average of the others one turn in six. The strong player prefers face upgrades (Gem to Big
   Gem 43% of runs, the gold wand die 19%).
6. Boosts (+1, x2) are kept across turns and to the end of the fight; a +1 played as the last
   die of a turn waits for the next turn. Fine, but worth knowing; the bottom text should show a
   waiting boost.

## The proposal: the item-slot model

The owner chose it over the bag (2026-10-30). Catwiz rolls five identical dice each turn, with
two re-rolls of the unplayed dice; each die's six faces are her six item slots, and the item in a
slot decides what that face does. No bag, no draw or discard, no taking a die out. The tables
are in `tools/sim/proposal/` in the content format (`items.tsp`, `enemies.tsp`, `moves.tsp`,
`encounters.tsp`, `action.tsp`, `effects.tsp` constants), ready to drop into `game/content`
once the engine has the mechanics (the list at the end).

ITEMS_SECTION

### Statuses

Each used by several items or enemies:

| status | on | what | from |
|---|---|---|---|
| fleas | enemy, you | N damage at the end of its turn, 3 turns; stacks | Fleas curse, +1 (a stack more), Bad Milk and the vet (on you) |
| wet | enemy, you | its hits halved, N turns | Wet curse, Spray Bottle, the big bath and sprinkler theme; Static Fur hits wet enemies double |
| tangled | enemy | its hits N less, till its turn ends | Ball of Yarn, Yarn Wand |
| marked | enemy | every hit on it N more, all fight; kittens go for it first | Mark Territory; pays off with Zoomies, String, kittens |
| spooked | you | your dice N less next turn | the cucumber, the bulldog king |
| ward | anyone | each pip blocks one curse | Bell Collar, enemies' wards, Rubber Duck |
| kittens | you | each pounces 1 at the end of your turn (marked enemy first, else the leftmost); one runs off each time you lose hit points | Meowcronomicon, Feather Toy, Cardboard Box, Mother Cat, Catnip, Mittens, Cannon, If It Fits, Litter Star |
| strength | enemy | its hits N more, all fight (the grow moves) | elites, the lawnmower, the boss; Knock It Off takes it away |

### The reward flow

1. After each won fight: one of the fight's three cards. A card is an item for a slot (the old
   item goes; the card says what it replaces) or an upgrade for a slot ("+1 WAND"). Picking the
   item you already hold is +1 on its slot. Levels belong to the slot, so swapping the twig wand
   for a zap wand keeps the +2. Two levels a slot at most (ITEM_MOST).
2. After fight 4 (the day's end), the mailman and the vet or big bath: one of three charms.
3. After the mailman, a nap: 10 hit points back, or +1 on a slot of your choice.
4. Fight 10 has two doors, both shown: the vet or the big bath.

The cards are fixed per fight (no chance, as the owner wants); the runs differ by the player's
picks and the dice. The card, 35 columns:

```
SPRAY BOTTLE
WAND: 2 DAMAGE (+1)
2, AND IT IS WET
REPLACES: TWIG WAND
```

The first line is the item, the second the slot's base at the slot's level, the third (and a
fourth when needed) the item's own line, the last what it replaces, or "YOU HAVE IT: WAND +1".

### Enemies

ENEMIES_SECTION

### The run, fight by fight

RUN_SECTION

## Comparisons

COMPARISONS

## What the engine needs for the proposal

ENGINE

## Cut, and why

CUTS
