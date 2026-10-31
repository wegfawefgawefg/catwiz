# Balance

The balance sims (`tools/sim/`), the targets, and the proposal: the item-slot model in the
owner's ten-fight run (the woods, the garden, the yard, each two fights and an elite, then the
bulldog king), cards drawn at random from one pool after every fight, a charm and a nap after
each elite. Tuned with the C sim's searching player. Numbers are from the sims at the commit
that last touched this file; rerun them before trusting a small difference (1,000 runs swing a
win rate by about 3 points, 100 runs by about 10).

## The sims

Two sims of the same rules. The C sim (`tools/sim/c/`) is the one to use: it plays the item
model (`tools/sim/proposal`), on 8 threads, with the searching player and the studies. The
Python sim (`tools/sim/*.py`) is the original: it also plays the bag game's fights 1-2 and the
bag model, and `validate.py` checks it against the real game. Both read the same tables.

### The C sim

```sh
cd tools/sim/c && make                     # gen.py writes gen_content.h from tools/sim/proposal
./catwiz-sim --player search --runs 2000 --learned learned.txt --learn 80 --picks
./catwiz-sim --player all --runs 1000      # random, greedy, strong, search
./catwiz-sim --player search --learned learned.txt --learn 80 --runs 1 --log 1   # one run told
./catwiz-sim --study picks --runs 256 --out new.txt     # every pick forced in turn; learns
./catwiz-sim --learned learned.txt --learn 80 --study swings --runs 2000   # big turns, pairs
./catwiz-sim --learned learned.txt --learn 80 --study lift --runs 128      # what wins together
./catwiz-sim --learned learned.txt --learn 80 --study luck --runs 4000     # offer luck
./catwiz-sim ... --plan "card:1:TIMES TWO;charm:3:BAD MILK;nap:3:+1 TRICK"  # force a line
python3 check.py --player strong --runs 400 --toe-fix --mult-cap 16      # against Python
python3 ../tablediff.py                    # what changed in the tables since f403880
```

Plain C11 and pthreads (8 workers at most), files under 500 lines, one job each: `battle.c` the
rules, `items.c` the faces and charms, `foes.c` the enemies' turn, `players.c` random, greedy
and strong, `search.c` and `value.c` the searching player's turn, `draft.c` its picks,
`rewards.c` the offers and picks, `run.c` the run, `report.c`, `study.c`, `swings.c`,
`combos.c`, `tell.c` the logs. No number is retyped: `gen.py` reads the tables with the Python
sim's reader (`tsp.py`) and writes `gen_content.h`; `make` reruns it when a table changes. A
run is the same for its seed (run n of `--seed s` is seed s * 100000 + n) on any number of
threads. `learned.txt` is the learned pick values for the tables as they are (redo them with
the picks study when the tables change; below).

Speed, the same tables and rules, 8 workers each (the owner's desktop, 2026-10-31):

| player | Python sim | C sim | C faster | C, one thread |
|---|---|---|---|---|
| random | 1,214 runs a second | 371,116 | 306x | |
| greedy | 647 | 127,791 | 198x | |
| strong | 9 | 155 | 17x | 20 |
| search | | 53 | | |

The strong player gains least: most of its time is its search's positions (copied and hashed
whole). The picks study (about 140 options x 256 runs) takes about 13 minutes; the lift study
(36 parts, every pair) about 40 minutes here, 25 on the Mac mini (14 threads: built with
`-DMOST_JOBS=14`; the same seeds give the same runs there).

### How close the two sims are

The C sim takes Python's random numbers (MT19937 with Python's seeding, `getrandbits`,
`randrange`, `random`), so a seed plays the same run in both, die for die. `check.py` runs both
on the same seeds and compares every run's line (each fight's hit points left, turns, hit points
lost, every pick):

| tables and rules | random | greedy | strong |
|---|---|---|---|
| the original proposal (f403880), the old rules (some with the toe and cap switches) | 0 of 2,900 differ | 0 of 4,900 | 20 of 400 differ: all runs where strong hoards Times Two past x2^20 (Python's numbers have no end; C's are 32 bits). With a cap on the waiting times, 0 of 800 |
| the ten-fight run, random offers, the owner's rules as they came (each change checked) | 0 of 1,200 | 0 of 2,500 | 0 of 480 |

The strong player on the original tables, 400 runs, against this file's old table (the Python
sim): fight 7 won 97% and lost 6.1 (Python 6.0), fight 10 92%, 2.3 (92%, 2.1), the boss 85%,
3.7 (85%, 3.7); runs won 69.8% (70%). Greedy's table came out digit for digit.

What the port found in the Python sim, all fixed in both:

1. Sixth Toe gave no sixth die: the bag held five dice, so the sixth tray spot stayed empty and
   the toe was only a re-roll less. The engine gives the die (as the charm says).
2. A waiting times had no end: the strong player played Times Two over and over (its judge
   paid 1.5 a point of waiting times) and reached x1,000,000; in the game a hit's damage is a
   byte. Now x16 at most (a rule change, below).
3. Python 3.12's `sum()` of floats compensates its rounding (Neumaier); C's plain adding did
   not, so two kits worth "13.7" ranked differently and greedy picked another card in 1% of
   runs. The C sim sums the same way now.
4. A Bad Milk that cost 6 hit points a fight, and Kitten Cannon dead in every version (both below).

### The Python sim and the real game

The Python sim plays the proposal tables with every rule above too (check.py). Its own
check against the real game (the bag game of 2026-10-30, fights 1-2):


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

### Players

| player | a turn | the picks between fights |
|---|---|---|
| random | a random playable die on a random enemy until none is left; re-rolls or ends at random | at random |
| greedy | the one die and target that leave the best position after the enemies' shown moves, again and again; re-rolls when no die helps | a fixed table of what items are worth |
| strong | every order of the dice and targets (1,500 positions at most), ended by the enemies' moves; re-rolls after the plan's first few dice when 6 imagined re-rolls say so | rollouts of the next fight with the greedy player |
| search | below | below |

random, greedy and strong are the Python sim's players, ported die for die. The searching
player is new and is the "good player" of the targets:

- A turn: every order of the dice shown and every target, merged where two orders reach the
  same position (6,000 at most), each ended by the enemies' moves and valued the way a careful
  player weighs it: her hit points, each enemy's hit points and its next three moves (the
  roomba's bump in 2 and the king's flop count before they land), shields, mana, a waiting +1
  or times, kittens, statuses on both sides, a shown hit she could not take.
- A re-roll re-rolls every die not played, so "keep" means "play it first". For every set of
  dice she could play before re-rolling, the re-roll is worth the mean of her best plan over
  the new dice: every outcome when two dice or fewer are re-rolled, else 10 imagined rolls
  (her own random numbers, the same rolls for every set), the best 3 sets again with 30. She
  re-rolls when that beats playing out.
- Picks: each option is tried in 24 rollouts of the next 3 fights (the greedy player plays
  them, fast), plus what she has learned: each option's win rate when it was forced in a few
  hundred whole runs (the picks study, by third of the run: a card slipped into the offer and
  taken). The learned values count 80 hit points for a whole run won; the rollouts settle the
  close calls by the run as it stands. The nap weighs the heal against every level, not one.
- Books and mana: a book without its mana is a dud, so the turn search plays stars before books
  and keeps a book die only when this turn's stars can pay for it (else a re-roll is worth
  more); between turns her value counts mana up to her book's cost at three times what mana past
  it is worth, so she banks for a cast.
- She never sees the dice to come: imagined rolls and rollouts take her own random numbers.

The draft is most of the skill. On the final tables the same turn search wins 52% with the
rollout picks alone and 74% with the learned values (4,096 runs). Learning: the picks study
from the rollout draft, then again with that table (each pass about 13 minutes); for small
table changes, start from the last good table. A table learned on other tables is worse than
none (it can drop a run from 70% to 20%).

## Targets

What "balanced" means, as numbers the sims measure, restated for the ten-fight run. The good
player is the searching player with learned picks; strong is a decent player who plays turns
well and drafts badly.

| target | why |
|---|---|
| random dies at the first elite (fight 3) or soon after | mashing keys gets through the woods' first fights, not their elite |
| greedy (no plan) dies at the first two elites, wins under 5% | playing the best die now is not enough |
| the good player wins 50-75% | more often than not, not always |
| a normal fight costs the good player about 10% (2-5 hit points), an elite 15-30% (5-9) | the owner's numbers |
| fights last 3-6 turns, the king about 8-12 | long enough to plan, short enough not to grind |
| each place costs more than the last | the run builds |
| no healing loop | hit point tension inside the places |
| no card in more than about 80% of won runs | choices matter |
| no face is dead weight (played under 50% of the times it shows) | every face does something |
| the nap and the bonus level both get taken | the owner's "skip the nap to get stronger" |

## The proposal: the item-slot model

The owner's model (2026-10-30): Catwiz rolls five identical dice each turn, with two re-rolls of
the dice not played; each die's six faces are her six item slots, and the item in a slot decides
what that face does. The tables are in `tools/sim/proposal/` in the game's content shape
(`items.tsp`, `enemies.tsp`, `moves.tsp`, `encounters.tsp`, `action.tsp`, `effects.tsp`).

| slot | every item in it does | items differ by |
|---|---|---|
| wand | N damage to the enemy picked | a rider on the hit (the twig wand has a combo) |
| fluff | shield N till her next turn | a combo: what the third fluff in a turn adds |
| star | mana (kept all fight, 5 at most) | how the mana comes, and what else |
| book | casts its spell for mana | the spell; without its mana the die is a dud |
| curse | N of a status on the enemy picked | the status |
| trick | a boost or rule for the next die | the rule |

Levels belong to the slot (an item swapped in keeps the slot's levels), two at most. Mana ties
the slots together (stars make it, books spend it); kittens are the second thread; the tricks
are the run's engine (below).

### The run

| fight | place | enemies | after it |
|---|---|---|---|
| 1 | woods | puffcap, sporelet | 3 cards |
| 2 | woods | squirrel, possum, squirrel | 3 cards |
| 3 | woods | THE OLD SHROOM (elite) | 3 cards, a charm (one of 3), the nap or a bonus level |
| 4 | garden | dust bunny, roomba, dust bunny | 3 cards |
| 5 | garden | cucumber, garden gnome, sprinkler | 3 cards |
| 6 | garden | THE MAILMAN (elite) | 3 cards, a charm, the nap or a bonus level |
| 7 | yard | hoover jr., dust bunny | 3 cards |
| 8 | yard | sprinkler, lawnmower | 3 cards |
| 9 | yard | THE VET or THE BIG BATH (two doors, both shown) | 3 cards, a charm, the nap or a bonus level |
| 10 | yard | THE BULLDOG KING (three phases) | |

All at night; the places are only art. Of the old eleven fights, the first, the squirrels'
and possum's, the roomba's, the cucumber's, the hoover's and the mower's survive; the
puffcap-sporelet-nightflap and gnome-sporelets fights are gone (the nightflap is in no fight
now). The nap: the hit points she is missing back (NAP_HEAL_SHIFT 0; 1 is half), or a level on
a slot of her choice instead. Catwiz: 30 hit points; starts with Twig Wand, Fluff, Star,
Zoomies, Fleas, Plus One.

The woods' elite, new (one enemy, three moves; the engine's stand-in is "Old gnome"):

| enemy | hp | ward | moves | twist |
|---|---|---|---|---|
| THE OLD SHROOM | 46 | 1 | calls 2 sporelets; cap slam 8; spore cap: shield 5 | calls sporelets, who cheer it (+1 its next hit each): hit groups (Zoomies, Screaming, the twig's sweep, Mouse on String), Knock It Off takes the cheer off |

### The offers

After every fight three cards are drawn at random, by weight, from one pool (`OFFER_CARDS`:
card, weight, the first fight it can follow), three different ones that still give her kit
something (a held item at two levels, or a slot at two levels, is left out). After each elite
three charms are drawn the same way from `OFFER_CHARMS` (not ones she has). Start items are
not in the pool (their slot's upgrade card is the way to level them); weight 0 means never.
The game's draw takes its own random numbers; the sims take the dice's.

The plainer pieces come from the start, the middle ones from fight 3, the engines (Times Two,
Copycat, Knead, Wishing Star, +1 Trick) rarer and from fights 3-5, so early offers are plain
and later ones spicier:

| card | weight | from fight |
|---|---|---|
| YARN WAND | 4 | 1 |
| SPRAY BOTTLE | 4 | 1 |
| MOUSE ON STRING | 4 | 1 |
| FISHBONE WAND | 3 | 1 |
| FEATHER TOY | 3 | 1 |
| SPIKY FLUFF | 4 | 1 |
| CARDBOARD BOX | 4 | 1 |
| BELL COLLAR | 3 | 1 |
| SHOOTING STAR | 4 | 1 |
| MOON BOWL | 4 | 1 |
| LITTER STAR | 4 | 1 |
| WET | 4 | 1 |
| BALL OF YARN | 4 | 1 |
| +1 WAND | 3 | 1 |
| +1 FLUFF | 3 | 1 |
| +1 STAR | 3 | 1 |
| MEOWCRONOMICON | 3 | 3 |
| MARK TERRITORY | 3 | 3 |
| STATIC FUR | 3 | 3 |
| WARM BLANKET | 2 | 3 |
| LASER POINTER | 3 | 3 |
| KNOCK IT OFF | 3 | 3 |
| 3 AM SCREAMING | 3 | 3 |
| IF IT FITS | 2 | 3 |
| CATNIP | 3 | 3 |
| +1 BOOK | 2 | 3 |
| +1 CURSE | 2 | 3 |
| TIMES TWO | 2 | 3 |
| COPYCAT | 2 | 4 |
| WISHING STAR | 2 | 5 |
| KNEAD | 2 | 4 |
| +1 TRICK | 2 | 5 |

CHARM_| card | weight | from fight |
|---|---|---|
| YARN WAND | 4 | 1 |
| SPRAY BOTTLE | 4 | 1 |
| MOUSE ON STRING | 4 | 1 |
| FISHBONE WAND | 3 | 1 |
| FEATHER TOY | 3 | 1 |
| SPIKY FLUFF | 4 | 1 |
| CARDBOARD BOX | 4 | 1 |
| BELL COLLAR | 3 | 1 |
| SHOOTING STAR | 4 | 1 |
| MOON BOWL | 4 | 1 |
| LITTER STAR | 4 | 1 |
| WET | 4 | 1 |
| BALL OF YARN | 4 | 1 |
| +1 WAND | 3 | 1 |
| +1 FLUFF | 3 | 1 |
| +1 STAR | 3 | 1 |
| MEOWCRONOMICON | 3 | 3 |
| MARK TERRITORY | 3 | 3 |
| STATIC FUR | 3 | 3 |
| WARM BLANKET | 2 | 3 |
| LASER POINTER | 3 | 3 |
| KNOCK IT OFF | 3 | 3 |
| 3 AM SCREAMING | 3 | 3 |
| IF IT FITS | 2 | 3 |
| CATNIP | 3 | 3 |
| +1 BOOK | 2 | 3 |
| +1 CURSE | 2 | 3 |
| TIMES TWO | 2 | 3 |
| COPYCAT | 2 | 4 |
| WISHING STAR | 2 | 5 |
| KNEAD | 2 | 4 |
| +1 TRICK | 2 | 5 |

### Items

The card's item line (35 columns at most); the slot's base is the card's first line. Number:
the face's number at level 0, and what a level adds.

| item | slot | text | number, a level more | cost |
|---|---|---|---|---|
| TWIG WAND | wand | #. 3 IN A TURN: THE 3RD HITS ALL | 1, +1 |  |
| YARN WAND | wand | #, AND IT IS TANGLED 1 | 3, +1 |  |
| SPRAY BOTTLE | wand | #, AND IT IS WET | 1, +1 |  |
| FEATHER TOY | wand | #, AND YOUR KITTENS POUNCE IT | 4, +1 |  |
| FISHBONE WAND | wand | #, AND NO SHIELD STOPS IT | 5, +1 |  |
| MOUSE ON STRING | wand | #, THEN # TO THE NEXT ENEMY | 3, +1 |  |
| FLUFF | fluff | 3 IN A TURN: SHIELD STAYS A TURN | 1, +1 |  |
| SPIKY FLUFF | fluff | 3 IN A TURN: WHO HITS YOU TAKES 3 | 2, +1 |  |
| CARDBOARD BOX | fluff | 3 IN A TURN: HIT-ALLS MISS, +KITTEN | 2, +1 |  |
| WARM BLANKET | fluff | 3 IN A TURN: HEAL 2 | 1, +1 |  |
| STATIC FUR | fluff | 3 IN A TURN: 5 TO ALL, 10 IF WET | 2, +1 |  |
| BELL COLLAR | fluff | 3 IN A TURN: 2 WARD PIPS | 2, +1 |  |
| STAR | star | +# MANA | 2, +1 |  |
| SHOOTING STAR | star | +1 MANA, AND # DAMAGE | 2, +1 |  |
| MOON BOWL | star | +1 MANA, AND SHIELD # | 1, +1 |  |
| WISHING STAR | star | +# MANA; THE NEXT WAND TIMES 2 | 1, +1 |  |
| LITTER STAR | star | +# MANA, AND 1 MORE A KITTEN | 2, +1 |  |
| ZOOMIES | book | 2 MANA: # TO FOES 5 TIMES, L TO R | 2, +1 | 2 |
| MEOWCRONOMICON | book | 3 MANA: # KITTENS JOIN YOU | 3, +1 | 3 |
| LASER POINTER | book | 3 MANA: # TO ALL; THEY HIT FRIENDS | 6, +1 | 3 |
| 3 AM SCREAMING | book | 3 MANA: # TO ALL FOES, 1 TO YOU | 9, +1 | 3 |
| KNOCK IT OFF | book | 3 MANA: IT DROPS SHIELD, BUFFS; # | 12, +1 | 3 |
| IF IT FITS | book | 2 MANA: SHIELD #, +2 A KITTEN | 8, +1 | 2 |
| FLEAS | curse | # A TURN FOR 3 TURNS; THEY STACK | 1, +1 |  |
| WET | curse | ITS HITS HALVED FOR # TURNS | 1, +1 |  |
| BALL OF YARN | curse | TANGLED #: ITS HITS # LESS | 2, +1 |  |
| MARK TERRITORY | curse | MARKED #: HITS ON IT # MORE | 2, +1 |  |
| PLUS ONE | trick | NEXT DIE +#, EACH HIT AND STAR | 2, +1 |  |
| TIMES TWO | trick | NEXT DIE X#: COUNTS # | 2, +1 |  |
| COPYCAT | trick | YOUR LAST FACE AGAIN, +# | 0, +1 |  |
| CATNIP | trick | NEXT # DICE +1; KITTENS ACT TWICE | 4, +1 |  |
| KNEAD | trick | NEXT FLUFF TIMES 2, NEXT WAND +# | 2, +1 |  |

The hairball (an enemy's dud on a slot, coughed up by a re-roll) is in the item table too.

### Charms

| charm | text | amount |
|---|---|---|
| SCRATCH POST | TWO MORE RE-ROLLS EVERY TURN | 2 |
| SIXTH TOE | ROLL 6 DICE, BUT 1 RE-ROLL LESS | 1 |
| STILL WATER | A TURN WITH NO RE-ROLL: +2 MANA | 2 |
| PURRFECT TRIO | EACH 3 IN A TURN ALSO HITS ALL 1 | 1 |
| KITTEN MITTENS | YOUR KITTENS HIT 1 HARDER | 1 |
| MOTHER CAT | EACH FIGHT STARTS WITH A KITTEN | 1 |
| FLUFFY TAIL | YOUR SHIELD HALVES, NOT GONE | 1 |
| GRUMPY FACE | A HIT THAT HURTS YOU: +1 MANA | 1 |
| RUBBER DUCK | A CURSE A WARD BLOCKS: SHIELD 3 | 3 |
| BAD MILK | WANDS +2; BOOKS COST 1 MORE | 2 |

### Enemies

| enemy | hp | ward | moves (round and round) |
|---|---|---|---|
| PUFFCAP | 15 | 0 | headbutt for 2; spore shield 2 |
| SPORELET | 7 | 0 | nip for 1; cheer: friend +1 next |
| GARDEN GNOME | 14 | 1 | guards a friend: 3; rod poke for 4 |
| POSSUM | 12 | 0 | bite for 2; puffs up: shield 2 (then POSSUM (FAKED IT)) |
| POSSUM (FAKED IT) | 4 | 0 | cheap shot for 2 |
| SQUIRREL | 7 | 0 | grabs your last die; acorn for 3 |
| ROOMBA | 34 | 0 | beep. bumps in 2; beep beep. in 1; full speed bump 12 |
| DUST BUNNY | 4 | 0 | sneeze for 2; hairball: your fluff |
| CUCUMBER | 14 | 1 | spooks: dice -1 next; rolls at you for 3 |
| SPRINKLER | 16 | 0 | sprays all for 3; waters friends +2 |
| HOOVER JR. | 50 | 2 | calls 2 dust bunnies; sucks for 9; sucks for 9 (calls DUST BUNNY) |
| LAWNMOWER | 60 | 2 | revs up: +1 for good; mows for 14 (stalls after losing 16 in a turn) |
| THE MAILMAN | 80 | 2 | parcel for 10; return to sender 6; heavy parcel for 12; grumpier: +1 for good |
| THE VET | 76 | 2 | needle: fleas 4; takes a temperature; checkup for 18; snaps gloves: +1 good; treats itself +6 |
| THE BIG BATH | 70 | 2 | rinse: you get wet; splash for 18; hairball: your wand (then DRAIN GREMLIN) |
| DRAIN GREMLIN | 40 | 1 | glug glug 8 twice; gurgles: +1 for good |
| BULLDOG KING | 98 | 2 | royal bark: dice -1; chomp for 26; throne nap: shield 8 (then BULLDOG KING, CROSS) |
| BULLDOG KING, CROSS | 98 | 1 | calls 2 royal pugs; slobber all for 8; chomp for 28; decree: +1 for good (calls ROYAL PUG, then BULLDOG KING, FURIOUS) |
| BULLDOG KING, FURIOUS | 98 | 0 | winds up: flop in 2; winds up: flop in 1; belly flop all 36; growl: +2 for good |
| ROYAL PUG | 8 | 0 | yap for 3; cheer: king +2 next |
| THE OLD SHROOM | 46 | 1 | calls 2 sporelets; cap slam for 8; spore cap: shield 5 (calls SPORELET) |

### Results, fight by fight

Full naps (the owner's lean), 4,096 runs of the good player, 3,000 strong, 5,000 greedy and
random. Lost: hit points lost by the runs that won the fight; p90: lost by the worst tenth of
the runs that reached it (a death counts all she had); turns: mean (most).

| fight | good: reached, won | hp in | lost | p90 | turns | strong: reached, won | lost |
|---|---|---|---|---|---|---|---|
| 1 woods | 100%, 100% | 30.0 | 2.2 | 3 | 2.2 (6) | 100%, 100% | 2.3 |
| 2 woods | 100%, 100% | 27.8 | 2.8 | 5 | 2.9 (9) | 100%, 100% | 3.1 |
| 3 old shroom | 100%, 100% | 25.0 | 7.3 | 10 | 3.8 (9) | 100%, 100% | 8.4 |
| 4 garden | 100%, 100% | 29.4 | 1.6 | 6 | 2.9 (10) | 100%, 100% | 3.2 |
| 5 garden | 100%, 100% | 27.9 | 2.9 | 6 | 3.1 (25) | 100%, 100% | 3.6 |
| 6 mailman | 100%, 98% | 25.0 | 11.3 | 19 | 4.5 (32) | 100%, 87% | 13.3 |
| 7 yard | 98%, 100% | 29.9 | 4.2 | 9 | 3.3 (28) | 87%, 100% | 7.2 |
| 8 yard | 98%, 100% | 25.7 | 2.1 | 9 | 3.4 (27) | 87%, 96% | 4.8 |
| 9 vet or bath | 98%, 94% | 23.6 | 6.1 | 18 | 4.6 (60) | 84%, 64% | 9.2 |
| 10 the king | 93%, 80% | 29.7 | 14.3 | 30 | 8.8 (54) | 54%, 31% | 17.7 |

The good player wins 74.2% and ends with 15.3 hit points; with rollout picks only, 52.3%;
strong 16.7% (deaths at the mailman 13%, fight 9 30%, the king 37%); greedy 0.1% (77% die at
the mailman); random 0% (65% die at the shroom). Doors: the vet 48%, the bath 52%.

| target | result |
|---|---|
| random dies at the first elite | met: 65% at fight 3, the rest by 6 |
| greedy dies at the first two elites, wins under 5% | met: 9% at 3, 77% at 6, wins 0.1% |
| the good player wins 50-75% | met: 74.2% (batches of 100 runs: 61-84%) |
| normal fight 2-5, elite 5-9 | normal fights 1.6-4.2 (fight 4 a little cheap); the shroom 7.3 and fight 9 6.1 met; the mailman 11.3 high (38%) and the king 14.3: the garden's elite is the wall for strong |
| fights 3-6 turns, the king 8-12 | fights 1 and 4 short (2.2, 2.9: the new books and stars kill fast), the rest 2.9-4.6; the king 8.8 |
| each place costs more | woods 12.3 in all, garden 15.8, yard 12.4, then the king 14.3: the garden costs the most |
| no healing loop | met: no heal in a fight but Warm Blanket's combo. But banking stalls exist (below) |
| no card above 80% of won runs | met: Mouse on String 73%, Scratch Post 72%, +1 Wand 68% the most taken (the nap's heal aside) |
| no dead face | nearly: Meowcronomicon is played 48% of the times it shows (a 3-mana book, a dud without the mana), If It Fits 50%, Laser 56%; the rest 67-96% |
| the nap and the bonus level both taken | with full naps, after the woods only (16% dream +1 Trick then); with half naps, a real choice (below) |

### The nap or the bonus level

The good player, the same seeds, the nap forced each way after each elite (512 runs a line,
won):

| after | the heal | +1 trick | +1 fluff | +1 wand | +1 book | +1 star | +1 curse |
|---|---|---|---|---|---|---|---|
| fight 3 | 74% | 77% | 71% | 71% | 70% | 67% | 62% |
| fight 6 | 74% | 69% | 62% | 61% | 65% | 62% | 56% |
| fight 9 | 72% | 64% | 59% | 61% | 58% | 57% | 56% |

| nap | good player won | strong won | greedy | what the good player takes |
|---|---|---|---|---|
| full heal (NAP_HEAL_SHIFT 0) | 74.2% | 16.7% | dies at 6 | the heal 90%, 96%, 81% after 3, 6, 9; +1 Trick 16% after 9 |
| half the missing (shift 1) | 55.9% | 5.4% | dies at 5-6 | after 3: the heal 50%, +1 Trick 22%, +1 Book 15%, +1 Fluff 11%; later the heal 92-98% |

1. With full naps the choice is lopsided after the garden and the yard (the heal wins by 5-15
   points); after the woods the levels are close to the heal and +1 Trick beats it a little.
   The bonus level needs no cost; it is a real choice early only.
2. With half naps the run is much harder (56%, strong 5%) and the woods' stop becomes a
   four-way choice. Half naps would need the elites and the king about 15% softer.
3. Recommendation: full naps, as tuned. To make the bonus level a choice later too, give it
   "and 5 hit points" rather than shrinking the heal.

### Offer luck

The offers are the run's second luck. The good player, 4,000 runs, by how many engine cards
(Times Two, Copycat, Knead, Wishing Star, +1 Trick) the first six offers showed:

| engines offered by fight 6 | runs | won |
|---|---|---|
| none | 38% | 67% |
| 1 | 40% | 76% |
| 2 | 17% | 81% |
| 3 | 4% | 84% |
| 4 or more | 1% | 78% (few runs) |

A run that sees no engine still wins two in three: the engines are the big swing, not a must.
Batches of 100 runs won 61% to 84% (about 10 points of that spread is what a hundred runs
give anyway).

### The owner's +1 and Star tests

Plus One on the next die only, its base +1 or +2 (a level +1 either way), the learned draft
re-learned for each, 2,048 runs; the trick cards' forced values by third of the run:

| Plus One base | good player won | strong | +1 Trick (Plus One levelled) | Times Two in its place | Copycat |
|---|---|---|---|---|---|
| +1 | 60.4% | 10.4% | 64-68% | 82-86% | 67-72% |
| +2 | 70.8% | 14.8% | 73-81% | 88-90% | 70-75% |

At +1 a Plus One is a weak start and levelling it loses its pick to everything; at +2 the
level is a fair pick (within 7-15 points of Times Two, the strongest trick, and above Copycat
late) and Plus One stays the start's engine. Base +2.

The plain Star's base 1 or 2 with the stronger books (and books duds without their mana), the
draft re-learned, 2,048 runs, how often each book is played when it shows:

| Star base | good player won | Zoomies | Knock It Off | Laser | If It Fits | Meowcronomicon | 3 AM Screaming |
|---|---|---|---|---|---|---|---|
| 1 | 78.6% | 72% | 59% | 48% | 46% | 43% | 30% (4 mana) |
| 2 | 81.9% | 80% | 70% | 59% | 52% | 50% | 35% (4 mana) |

At 1 too many book dice are duds: a 3-mana book needs three star faces. At 2 a star pays
Zoomies alone and two stars a payoff book, so a bank for a big book is a turn's plan, not a
hope; banking still matters (mana carries over, 5 at most). Base 2. A +2 on a star makes 4
mana and a x2 makes 4, so a boosted star is a full cast; past 5 the mana is lost (the boost
study's +2.7 a boosted star shows the cap biting). 3 AM Screaming went to 3 mana (for 9) after
this: at 4 it was a dud two times in three.

The books, as payoffs. Forced in the pick study (Star 2), a book is worth 57-75% of runs won
(If It Fits and Meowcronomicon the best), still under +1 Book on Zoomies, the start's book
(78-84%): Zoomies is the book most runs keep.

| book | was | now |
|---|---|---|
| Zoomies | 2 mana, 1 five times | 2 mana, 2 five times |
| Laser Pointer | 2 mana, 4 to all | 3 mana, 6 to all |
| 3 AM Screaming | 3 mana, 7 to all | 3 mana, 9 to all |
| Knock It Off | 2 mana, 8 | 3 mana, 12 |
| If It Fits | 2 mana, shield 5 | 2 mana, shield 8 |
| Meowcronomicon | 3 mana, 3 kittens | as it was |

### How the tables moved with the owner's rules

| | the good player won | died at |
|---|---|---|
| the eleven-fight run, fixed cards, the old +1 and x2 (its learned picks) | 92.0% | the boss 3%, fights 9-10 4% |
| the same, +1s stacking and x2 on any die, the same picks | 91.0% | the same |
| the ten-fight run, random offers, full naps, before its retune (rollout picks) | 97.5% | fight 9 1%, the king 2% |
| after the retune (learned picks) | 75.6% | the mailman 4%, fight 9 7%, the king 13% |
| Plus One on one die (base +2), no studying, Star 2, payoff books, Wet adding, before the last retune (the last table) | 81.9% | |
| after (the final tables) | 74.2% | the mailman 2%, fight 9 5%, the king 19% |

Hit points lost a fight by the good player, the ten-fight run before its first retune and now:

| fight | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| before | 2.3 | 3.1 | 5.5 | 2.6 | 3.2 | 9.1 | 5.9 | 1.9 | 2.8 | 4.1 |
| now | 2.2 | 2.8 | 7.3 | 1.6 | 2.9 | 11.3 | 4.2 | 2.1 | 6.1 | 14.3 |

What the retunes did, against the ten-fight run's first tables (f3cdbe9): the first normal
fights longer (puffcap 15 to 20 hp, sporelet 7 to 9, squirrel 7 to 9, possum 12 to 15, roomba 34
to 42, dust bunny 4 to 5); the elites and the king harder and longer: the shroom 40 to 46 hp,
cap slam 6 to 8; the mailman 62 to 80, parcels 9 and 10 to 10 and 12; the vet 46 to 76, checkup
11 to 18, needle fleas 3 to 4; the bath 54 to 70, splash 11 to 18, its gremlin 34 to 40, glug 6
to 8; the king 54 to 98 a phase, chomps 12 and 13 to 26 and 28, slobber 5 to 8, belly flop 20 to
36, his pugs 6 to 8 hp and yap 2 to 3; the mower 44 to 60 and mows 9 to 14. A run that builds x2
makes 150-220 in a turn (below), so the king has 294 hit points in all.

## Combos

How the parts win together, from three studies with the good player:

1. Lift (`--study lift`, 192 runs a cell, run on the Mac mini): each part (an item not in the
   starting kit, or a charm) given from fight 1, its slot locked so no card replaces it; alone,
   in every pair, and the best pairs with a third, the same seeds. A pair's lift is its
   log-odds of winning less what the parts give apart (logit(AB) - logit(A) - logit(B) +
   logit(none)): above 0 they win together more than the parts say. About 0.4 either way is
   noise; near 100% won the log-odds stretch, so the Times Two pairs (Times Two alone wins 97%
   from fight 1) look bigger than they are. (Run on the tables just before the first normal
   fights got their last hit points; that only touches fights 1, 2 and 4.)
2. Swings (`--study swings`): 2,048 natural runs, each turn's damage and the systems it
   touched (a book paid with mana, kittens, a three-in-a-turn combo, a status put on or paying
   off, a trick's boost used, a charm); the biggest turns told from the run's log.
3. Boosts (`--study boosts`): which faces take the waiting +1 and x2, and what they add.

### What wins together

Parts alone, from fight 1 (none: 76.6% won): Times Two 97%, Mouse on String 95%, Sixth Toe
91%, Wishing Star 89%, Cardboard Box 88%, Static Fur and Mark Territory 88%, Copycat 87% at the
top; Feather Toy 69%, Catnip 62%, Knead 60%, 3 AM Screaming 57% at the bottom (Knead and Catnip
take the trick slot from Plus One; Screaming takes the book slot from Zoomies).

| pair | lift | won together | apart |
|---|---|---|---|
| Feather Toy + Meowcronomicon | +2.12 | 95% | 69%, 77% |
| Mark Territory + Scratch Post | +1.57 | 98% | 88%, 84% |
| Meowcronomicon + Catnip | +0.94 | 81% | 77%, 62% |
| Wishing Star + 3 AM Screaming | +0.91 | 89% | 89%, 57% |
| Fluffy Tail + Bad Milk | +0.84 | 94% | 81%, 84% |
| Scratch Post + Mother Cat | +0.83 | 93% | 84%, 78% |
| Wet + Mother Cat | +0.83 | 93% | 84%, 78% |
| 3 AM Screaming + Mother Cat | +0.79 | 76% | 57%, 78% |
| Feather Toy + Bell Collar | +0.78 | 86% | 69%, 81% |
| Moon Bowl + Meowcronomicon | +0.77 | 88% | 77%, 77% |
| Spray Bottle + Mark Territory | +0.74 | 96% | 85%, 88% |
| Meowcronomicon + Mark Territory | +0.71 | 94% | 77%, 88% |
| with Times Two (at the ceiling): Laser Pointer +2.56, Litter Star +2.21, Static Fur +1.67, Ball of Yarn +1.51, Sixth Toe +1.29 | | 99-100% | |

Worse together: Meowcronomicon + Times Two (-1.05: x2 wants Zoomies in the book slot), If It
Fits + Sixth Toe (-0.91), Spray Bottle + Times Two (-0.86), Spray Bottle + Wet (-0.79: both put
on wet, the second adds little), Knock It Off + Catnip (-0.72).

Triples: Feather Toy + Meowcronomicon + Scratch Post won 100% (the pair 95%); Mark Territory
+ Scratch Post + Meowcronomicon 99% (the pair 98%); Laser Pointer + Times Two + Bell Collar 99%.

The systems behind them: kittens (Meowcronomicon makes them, Feather Toy makes them pounce
again, Catnip twice, Mother Cat one each fight, Moon Bowl's and Bell Collar's shields keep them
from running off); marks (Mark Territory adds to every hit, kittens' too, and Scratch Post's
extra re-rolls find more Marks); x2 into a book that hits many (Laser, Zoomies) or into a star
(a full cast).

### The big turns

2,048 runs, 80,019 turns, 19.7 damage a turn on average; 32% of turns touch three systems or
more. The biggest are x2 chains, all at the king (the one fight long enough to bank a times):
Times Two at a level is x3, at two x4, and two of them make x16. As the logs show them (`x3
waits`: a times waiting from the turn before; `= 48`: the face's number after the boosts; the
hits show a mark's extra):

Two x2s on a waiting x3, into Zoomies (201 damage: mana, status, trick, charm):

```
turn 2  hp 27 mana 5 (x3 waits) | BULLDOG KING 98 (CHOMP FOR 26); | dice: TIMES TWO, STAR, ZOOMIES, MOUSE ON STRING, TIMES TWO, BELL COLLAR
  TIMES TWO
  TIMES TWO
  ZOOMIES x16 = 48: 5 hits of 48 (BULLDOG KING 3, BULLDOG KING, CROSS 2); BULLDOG KING, CROSS GETS UP
  MOUSE ON STRING = 5 on BULLDOG KING, CROSS: 2 hits of 5 (BULLDOG KING, CROSS 1, BULLDOG KING, FURIOUS 1); BULLDOG KING, FURIOUS GETS UP
  re-roll STAR, BELL COLLAR -> TIMES TWO, STAR
  re-roll TIMES TWO, STAR -> MARK TERRITORY, MARK TERRITORY
  re-roll MARK TERRITORY, MARK TERRITORY -> MARK TERRITORY, MARK TERRITORY
  MARK TERRITORY = 2 on BULLDOG KING, FURIOUS; BULLDOG KING, FURIOUS marked 2
  MARK TERRITORY = 2 on BULLDOG KING, FURIOUS; BULLDOG KING, FURIOUS marked 2

```

x16 Zoomies with three kittens on, and a wishing star waiting for the next wand (179 damage:
mana, kittens, status, trick):

```
turn 4  hp 30 mana 3 kittens 3 (x4 waits) (wish waits) | BULLDOG KING 69 sh8 (ROYAL BARK: DICE -1); | dice: CARDBOARD BOX, ZOOMIES, MARK TERRITORY, ZOOMIES, SPRAY BOTTLE
  re-roll CARDBOARD BOX, ZOOMIES, MARK TERRITORY, ZOOMIES, SPRAY BOTTLE -> SPRAY BOTTLE, WISHING STAR, TIMES TWO, MARK TERRITORY, ZOOMIES
  TIMES TWO
  ZOOMIES x16 = 48: 5 hits of 48 (BULLDOG KING 2, BULLDOG KING, CROSS 3); BULLDOG KING, CROSS GETS UP; BULLDOG KING, FURIOUS GETS UP
  re-roll SPRAY BOTTLE, WISHING STAR, MARK TERRITORY -> MARK TERRITORY, ZOOMIES, CARDBOARD BOX
  MARK TERRITORY = 2 on BULLDOG KING, FURIOUS; BULLDOG KING, FURIOUS marked 2
  3 kitten pounces on BULLDOG KING, FURIOUS for 4

```

Five systems at once: kittens (Mother Cat's, the box's), a wet king from earlier turns,
Fluffy Tail's kept shield, three x2s, Zoomies paid with banked mana (148 damage):

```
turn 5  hp 30 mana 5 shield 1 kittens 1 | BULLDOG KING 48 wet8 (CHOMP FOR 26); | dice: TIMES TWO, CARDBOARD BOX, YARN WAND, YARN WAND, WET
  TIMES TWO
  re-roll CARDBOARD BOX, YARN WAND, YARN WAND, WET -> WET, TIMES TWO, STAR, TIMES TWO
  TIMES TWO
  TIMES TWO
  re-roll WET, STAR -> ZOOMIES, YARN WAND
  ZOOMIES x16 spooked -1 = 31: 5 hits of 31 (BULLDOG KING 2, BULLDOG KING, CROSS 3); BULLDOG KING, CROSS GETS UP
  YARN WAND spooked -1 = 5 on BULLDOG KING, CROSS: 5 on BULLDOG KING, CROSS; BULLDOG KING, FURIOUS GETS UP; BULLDOG KING, FURIOUS tangled 1
  1 kitten pounces on BULLDOG KING, FURIOUS for 2

```

### Boost targets: where she puts +1 and x2

4,000 runs, 27.8 boosts a run (a waiting +1 or times taken by a face). Added: what one boost
added to the face's number on average (on every hit of it: Zoomies' five, Mouse on String's
two). Main target: the face that took the most boosts in a run.

| face | share of the boosts | a boost added | main target in | those runs won |
|---|---|---|---|---|
| Zoomies | 36% | +4.0, five hits | 62% of runs | 74% |
| Mouse on String | 18% | +8.5, two hits | 26% | 83% |
| Fleas | 8% | +2.9 a turn, three turns | 2% | 49% |
| Star | 6% | +2.7 mana (5 at most) | 0.2% | |
| Spray Bottle | 5% | +5.4 | 2.5% | 55% |
| Yarn Wand | 4% | +7.8 | 2.5% | 60% |
| Fluff | 3% | +3.9 shield | | |
| Twig Wand | 3% | +3.7 | | |
| Cardboard Box | 3% | +5.2 shield | | |
| Mark Territory | 2% | +4.5 marks, all fight | 0.6% | 73% |
| Wet | 2% | +4.8 turns | | |
| Feather Toy | 2% | +8.8 | 1.4% | 67% |
| the big books (Knock It Off, Laser, Screaming) | under 0.2% | +16 to +27 | | |

The best targets are the faces that hit more than once: Zoomies and Mouse on String take more
than half of all boosts, and the runs built on Mouse on String win the most (83%). Mark
Territory is the best target per boost (every later hit on the enemy, all fight) but comes up
rarely. A boosted star loses most of its boost past 5 mana.

Is each card's # the right one to boost? For most, yes: the # is the number a boost makes
interesting (hits, stacks, turns, shields). Proposals, no new items:

| card | its # now | the trouble | proposal |
|---|---|---|---|
| Wishing Star | the mana (+1) | a boost to it is mostly lost to the 5 cap; the wand x2 is the card | "+1 MANA; NEXT WAND TIMES #" (# 2): a boosted wishing star makes a x4 or x6 wand |
| Litter Star | the mana | the same cap | "+1 MANA, AND # A KITTEN" or keep: kittens are few |
| Meowcronomicon | the kittens | a boost runs into the 4-kitten cap | keep (it is rarely boosted) |
| Yarn Wand | the damage | the tangle is the card; a boost misses it | "1, AND IT IS TANGLED #": a boosted yarn wand silences a big hitter |
| Spray Bottle | the damage | the wet is the card; with Wet adding, a boosted wet is control | "1, AND IT IS WET #" (turns) |
| Bell Collar, Static Fur, Spiky Fluff | the shield | the combo is the card and it takes no boost | keep: the shield is the fluff's part |

## What changed and why

### Rule changes

The owner's (2026-10-31), in the game already or coming:

1. +1s stack: a Plus One adds its number to the waiting plus (99 at most). Times Two played
   after a plus doubles it.
2. Plus One boosts the next die only, on every hit of it, and is used up there (was the next
   two dice). Base: +2, a level +1 (tested against +1, below). Text "NEXT DIE +#, EACH HIT AND
   STAR".
3. A waiting times takes the next die of any slot but a trick (was a wand, fluff or book); it
   counts towards a three as before. Times Two's text "NEXT DIE X#: COUNTS #".
4. No more studying: a book without its mana cannot be played; the die is a dud till a re-roll
   or a star pays for it. The plain Star's base: 2, a level +1 (tested against 1, below). The
   books are payoffs now (below).
5. Wet adds its turns to what the enemy has (was the longer of the two).
6. One # a card: a boost changes only the card's # (Shooting Star's and Moon Bowl's 1 mana,
   Litter Star's and If It Fits' kitten parts stay as they are). The sims already did this.
7. The run's shape: ten fights in three places, two fights and an elite each, then the king;
   three cards drawn at random from one weighted pool after every fight; after each elite a
   charm drawn from a pool, then the nap (full, the owner's lean) or a bonus level.

Mine, each the smallest that fixed what the sim showed:

8. A waiting times stacks to x16 at most (no end before). The strong player hoarded Times Two
   past x1,000,000; a hit's damage is a byte in the game. x16 is x2 four times, so the owner's
   "super mega strong" stacking stays.
9. Kittens pounce for 2 (KITTEN_HIT, effects.tsp; 1 in the code before) and are 4 at most
   (KITTENS_MOST; 5). At 1 the kitten cards lost their picks by 30-60 points; at 2 with 5
   kittens the kitten line won 93%.
10. Bad Milk: "WANDS +2; BOOKS COST 1 MORE" (was wands +1 and fleas 2 on her at every fight's
    start, 6 hit points a fight: forced, it won 0% of runs). A trade between wands and books.
11. Kitten Cannon is cut: forced, it lost its pick in every version (11-40%), as a book and as
    a wand.
12. A woods elite, THE OLD SHROOM (an enemy and three moves), for the new shape.

Tried and dropped: kittens that run off when a hit-all lands instead of whenever she is hurt
(a point better for the kitten line, not worth the engine's rework).

Sim fixes, not rules (the engine has them): Sixth Toe's sixth die; Python 3.12's compensated
sums in the C sim.

Flagged, not changed:

- Mouse on String with one enemy left hits it twice.
- A waiting +1 or times stays to the next turn, so she can bank them over turns ("+36 waits"
  in the logs), and Wet now adds without end (99). Together they make stalls: 1% of the good
  player's fights last over 15 turns (8% of runs have one, mostly at the king and fight 9).
  One logged: the big bath at 1 hit point and 87 turns wet, so it can do nothing, while she
  banks +36 and shields with a Moon Bowl for 37, turn after turn, to one-shot the gremlin
  next. If that is not wanted, the smallest fixes are a waiting boost gone at the turn's end,
  or Wet at most 5 turns.

### Content

`python3 tools/sim/tablediff.py` lists every number and text that changed since f403880 (what
the engine was built from), and the pools and fights in full. By kind:

- Items: the wands' numbers up (yarn 3, feather 4, fishbone 5, mouse on string 3; spray 1;
  they were all 1) so a rider competes with the wand's level; the fluff with combos start at 2
  (spiky, box, static fur, bell collar) and their combos up (spiky 3, static fur 5 or 10 if
  wet, bell collar 2 ward pips); Star 2; Litter Star 2; Moon Bowl 1 (it was the pick 100% of
  the time at 2); the books as payoffs (above); Ball of Yarn and Mark Territory 2 a face;
  Plus One +2; Catnip 4 dice; Knead 2; texts for Times Two, Plus One, the books that moved.
- Charms: Scratch Post two more re-rolls (at one it lost to Mother Cat by 13 points); Bad Milk.
- Enemies: every fight longer, the elites and the king much harder (above); wards 2 on the
  hoover, the mower and the mailman (against curse builds); the vet's needle 4.
- The run: the owner's shape, the pools, the nap; the old shroom.

The engine's memory: one enemy and three moves new (the old shroom); one item gone (Kitten
Cannon); a few card texts a word or two longer; the pools 3 bytes a card.

### How the tuning went

The C sim's pick study did it: every option forced in turn, the rest of the run drafted by
the player, the same seeds, so each card's worth at its pick is a win rate. Under the fixed
cards each trio came within about 10 points, and the study showed that a good draft finds one
line and takes it every time (a kitten fortress of Wet, Yarn Wand, Meowcronomicon, Cardboard
Box, Catnip and Mittens took 100% of the picks it was offered), and that a card forced off that
line can lose by 70 points because it breaks the slot the line rests on. Forcing whole lines
(`--plan`) showed which builds could win then: kittens 88%, Zoomies with x2 81%, books 74%,
curses 36%, Copycat 26%, wands 17%. The owner's random pool ended the single line: no card is in
more than 73% of won runs now, and most picks fall between 10% and 60%. Each rule change after
that was followed by a re-learned draft and a retune of the elites and the king.

## What the engine needs for these tables

The item model is in the game (Catwiz main, from f403880's tables). For the tuned tables, on
top of it:

1. The new tables' numbers: `python3 tools/sim/tablediff.py` lists them (items, enemies, moves,
   charms, the fights, the pools, the constants).
2. KITTEN_HIT (2) and KITTENS_MOST (4) as content constants where the pounce and the kitten cap
   read them.
3. Bad Milk: wands +2 (its amount), books cost 1 more for each bad milk held; no fleas.
4. A waiting times at most x16.
5. THE OLD SHROOM: an enemy row and three moves (calls 2 sporelets, cap slam 8, spore cap
   shield 5), its art; in the engine's stand-in's place.
6. Kitten Cannon's row can go.
7. The pools as `OFFER_CARDS` and `OFFER_CHARMS` (the game's shape: the sims' tables carry
   only the cards in the pool; the rest weigh 0), NAP_HEAL_SHIFT 0.

The sims' draw: three different cards by weight among those whose `from` is at most the
fights won and that give the kit something (a held item or a slot at two levels is left out),
then, after an elite, three charms she does not hold; the card pick, the charm, then the nap.

## History: the bag game's fights 1-2 (2026-10-30)

Fights 1-2 of the game (`python3 tools/sim/run.py`, 400 runs a player). Lost: hit points lost
by the runs that won the fight; healed: got back in it; turns: mean (most).

| player | fight | won | hp in | lost | healed | turns |
|---|---|---|---|---|---|---|
| random | 1 | 100% | 30.0 | 5.4 | 2.0 | 4.1 (8) |
| random | 2 | 100% | 26.6 | 14.4 | 5.0 | 6.1 (13) |
| greedy | 1 | 100% | 30.0 | 2.9 | 1.6 | 3.3 (6) |
| greedy | 2 | 100% | 28.7 | 7.1 | 2.6 | 4.2 (7) |
| strong | 1 | 100% | 30.0 | 2.1 | 1.1 | 2.8 (5) |
| strong | 2 | 100% | 29.0 | 4.7 | 2.9 | 3.8 (6) |

Every player wins both; random ends with 17 hit points, greedy 24, strong 27. The reward after
fight 1: the strong player upgrades a face (Gem to Big Gem 46%, a wand 31%) more than it takes a
new die (gold wand die 15%, scream die 7%); greedy always takes the gold wand die. Every die is
played 79-95% of the times it is in the tray.

What the sim says is off in fights 1-2:

1. Zoomies hit the cat. `effects.next_standing` keeps its search in a u8: when the last enemy
   falls before zoomies' five hits are done, the next search starts from NOTHING (255), wraps to
   0, finds the hero standing and the next hit strikes her. In the sim it happened in 7-16% of
   runs; the machine did it too (validate matched both cases). The fix is one line: stop when
   `next_standing` gives NOTHING, or skip index 0.
2. The fights are easy: every player wins both, even random (it loses about 15 of 30 hit
   points). The strong player loses 2.1 and 4.7 (about 7% and 16%) and heals some back; greedy 2.9 and 7.1.
3. The cardboard box's "hit-alls miss you" does nothing yet: no enemy move is a hit-all. Today it
   is shield 6 for 2 mana.
4. "Take a die out" with five dice in the bag is a pure loss: with a bag of five every die comes
   up every turn anyway (the tray takes five), so removing one leaves four dice a turn. Only a
   full bag of six has a die sitting out each turn; there removal makes the other five come up
   every turn. The reward text ("fewer dice: the rest come up more") is true only then.
5. A new die is worth little: with HAND 5 and BAG_MOST 6 the sixth die only replaces the
   average of the others one turn in six. The strong player prefers face upgrades (Gem to Big
   Gem 46% of runs, the gold wand die 15%).
6. Boosts (+1, x2) are kept across turns and to the end of the fight; a +1 played as the last
   die of a turn waits for the next turn. Fine, but worth knowing; the bottom text should show a
   waiting boost.

Python commands:

```sh
python3 tools/sim/run.py                                     # the bag game's fights 1-2
python3 tools/sim/run.py --content proposal --policy strong --runs 400 --variant toefix,multcap=16
python3 tools/sim/validate.py                                # the Python sim against the game
```

## History: comparisons (the Python sim, the eleven-fight proposal of 2026-10-30)

`python3 tools/sim/study.py <name>` prints these (96-200 strong runs a line, three times as many
greedy and random). "Won" is the strong player's unless said; "hp" is hit points walking into the
last fight.

#### The bag model against the item model

The same eleven fights in both (`--content bag` and `--content proposal`), each tuned a while:

| model | strong won | hp at the boss | turns a fight | greedy dies at | random dies at |
|---|---|---|---|---|---|
| bag (start 5, cap 6, swap when full, type upgrades, tuna faces) | 86% | 26.9 | 9.2 | 7 | 4 |
| item slots (the proposal) | 72% | 13.1 | 4.9 | 7 | 5 |

The bag version's strong player wins more but by stalling: it heals back to near full in every
fight (the tuna faces, 9 turns a fight). Its numbers would need the heal cut (below) before a
fair comparison; the item model was tuned to the targets and is the owner's choice.

#### Starting bag size (the bag model)

The coordinator's question: is a starting bag of exactly five right, when the tray draws five?
Extra starting dice are weak ones (PLAIN DIE: 2 wand 2, 2 fluff 2, tuna 2, lint; LINT DIE: four
lint, wand 2, fluff 2; PLAIN WAND DIE: five wand 2 and a lint), the bag's cap raised to 10:

| start | the game's fights 1-2: strong hp at fight 2, turns | the bag proposal, 11 fights: strong won, greedy dies at | dice the strong winners end with |
|---|---|---|---|
| 5 (cap 6, the game) | 29.0, 3.4 | 86%, 7 | 6 (95%) |
| 5 (cap 10) | | 65%, 7 | 5-10, most 7-8 |
| 6 (+plain) | 28.8, 3.6 | 60%, 7 | 5-10 |
| 7 (+plain, lint) | 28.5, 3.9 | 61%, 7 | 5-10 |
| 8 (+plain, lint, wand) | 28.6, 3.6 | 48%, 7 | 5-10 |

1. In fights 1-2 the bag size hardly matters: everyone wins, and a bigger bag costs the strong
   player half a hit point and half a turn a fight. With five dice every die comes up every
   turn, so fight 1 has no draw at all; the draw only starts mattering at six dice.
2. Over a run, bigger bags lose: weak dice dilute the good ones, and a cap of 6 with a swap when
   full (the bag proposal's rule) played best. Greedy takes dice out of a big bag (it ends with
   5-6); the strong player keeps adding (its rollouts look one fight ahead, where a new die
   always helps a little) and ends with 7-10, which is part of why it wins less with a big cap.
3. Slay the Spire starts with 10 cards and draws 5: half the deck a turn. Here a die is already
   a small deck of six faces, so five dice are thirty faces and the roll is the draw. A 2:1 bag
   (ten dice, five drawn) adds a second layer of luck, which dice come up, over the roll's, and
   the sim says it only dilutes. If the bag model came back: start at 5, cap 6, swap when full.
4. Dog Witch (read from the owner's extracted data, not copied): a fixed set of five dice rolled
   every turn, no bag; items are the dice's faces, upgrades are item upgrades, jewelry are
   passives on the core verbs (dice count, re-rolls), and enemies can steal dice. The item model
   follows that shape; the bag is Catwiz's own twist, and the owner now prefers the item model.
   In it the dice count changes only by charm (Sixth Toe: six dice, one re-roll less) and by
   theft (squirrels, the vet).

#### Upgrades

| rule | won | greedy | notes |
|---|---|---|---|
| bag: one face of one die (the game today) | 64% | dies at 5 | 10.8 turns a fight: slow |
| bag: +1 to a face type, the fight's type (the bag proposal) | 86% | dies at 7 | |
| bag: +1 to any type | 93% | 11% won | too strong: every reward goes to wands |
| bag: every face of a type one step up its upgrade row | 73% | dies at 7 | |
| items: levels on the slot (the proposal) | 72% | dies at 7 | swapping an item keeps the level |
| items: levels on the item | 41% | | a new item starts at +0: swapping is punished, so runs keep their starting items or lose |
| items: two doors (new item, or +1 on any slot) | 100% (greedy 22%) | | +1 on the best slot every time wins: too strong and samey |

Recommendation: slot levels and the mixed pick of three (the owner's choice). The two-door
flow needs a level to cost more on a slot that has one, or only on the slots the fight names,
before it could be compared fairly.

#### Heal tension (tuna)

| version | won | greedy | hp at the boss | turns a fight |
|---|---|---|---|---|
| bag: 3 tuna faces in the starting bag (the game) | 86% | dies at 7 | 26.9 | 9.2 |
| bag: tuna not type-upgradable | 86% | dies at 7 | 26.9 | 9.2 |
| bag: 1 tuna face | 76% | dies at 7 | 25.4 | 8.4 |
| bag: no tuna anywhere | 59% | dies at 7 | 24.9 | 7.8 |
| items: no heal face (the proposal) | 72% | dies at 7 | 13.1 | 4.9 |
| items: the sixth slot is food (TUNA: heal 1, +1 a level) | 94% | 84% won | 29.6 | 9.5 |

(The bag proposal never offers a tuna type upgrade, so "not upgradable" is the same run.)

A heal face on every die undoes the damage of every fight: with Tuna in the sixth slot even the
greedy player wins most runs and the strong one walks into the boss at full health, stalling
fights to heal (9-10 turns). Recommendation: no heal face. Healing comes from the nap (10), the
Warm Blanket's combo (2) and nothing else; a charm or a rare book could add a little, once a
fight at most. The tricks take the sixth slot (the owner's option A).

#### +1 against x2

The rules now: Plus One gives +N to the next two dice of any slot (each Zoomies hit, each
fleas stack, each star's mana); Times Two doubles the next wand, fluff or book only (a star or
curse leaves it waiting) and counts it as two towards a three. With base values of 1, +1 is the
early pick (two dice of +1 against one die of 1 more), x2 grows with the slot's levels.

| start the trick slot with | strong won | greedy won |
|---|---|---|
| Plus One (the proposal) | 72% | 0% |
| Times Two | 77% | 54% |
| Copycat | 81% | 0% |

Starting with Times Two is stronger mostly because fight 1's card then reads as a level on it
(x3 after fight 1), not a swap. In the proposal's runs neither boost wins: the trick the strong
winners end with is Copycat 36%, Plus One 25%, Times Two 25%, Knead 8%, Catnip 6%; after fight 1
27% swap Plus One for Times Two, the rest keep it and take Yarn Wand or +1 Wand. Greedy always
takes Times Two and loses: it plays it without building the big wand or the fluff three it pays
for. A charm that gives the other boost (Bad Milk's wands +1, the Wishing Star's next wand x2)
lets a run hold both, and then order matters a little: Plus One then Times Two doubles the +1 as
well; Times Two then Plus One adds the +1 after.

Bottom text: one line is enough for a waiting boost ("NEXT 2 DICE +1", "NEXT WAND, FLUFF, BOOK
X2"), shown in the hero's row where statuses go.

#### Other checks on the item model

| variant | strong won | greedy | hp at the boss |
|---|---|---|---|
| the proposal | 72% | dies at 7 | 13.1 |
| base values 2, not 1 (`base=1`: every number 1 more) | 96% | 9% won | 22.5 |
| no charms | 42% | dies at 7 | 9.4 |
| levels on the item, not the slot | 41% | dies at 6 | 11.8 |
| two doors: new item or +1 on any slot | 100% | 22% won | 23.0 |
| food in the sixth slot (Tuna) | 94% | 84% won | 29.6 |

Base values of 1 are what the tuning rests on: at 2 the same fights are a walk. Charms are worth
about 30 points of win rate, three of them a run.

## Cut, and why

From the seed lists the coordinator passed on, and from the sim's own first cuts:

| cut | why |
|---|---|
| items that changed by zone (Sun Drop, a zone-only Moon Bowl, Sunbeam, Night Eyes) | the owner: zones are only art. The Moon Bowl stays as a plain star (+1 mana and shield) |
| Scratching Post wand (store this turn's damage, double next turn) | touches nothing but itself; hard to show in the bottom text. Scratch Post is now the re-roll charm |
| random targets (Feather Toy's second hit "at a random enemy", Cucumber "hits a random target") | chance only in the roll. The Feather Toy now makes the kittens pounce; Mouse on String hits the next enemy |
| Bell Collar charm "see intents two turns ahead" | the sim's players already know the move cycles; a second intent needs hud room. Bell Collar is a fluff item (a ward pip) |
| Nine Lives (book or charm) | a heal or a second life that touches no other system; healing loops (below) |
| Tuna Can (2 mana: heal 3) | a heal book made the strong player stall fights to heal to full (Tuna Can in 88% of won runs, 10-25 turn fights). Kitten Cannon took its place |
| Tuna as the sixth slot's food | see the heal comparison: it undoes the damage of every fight |
| Hiss and Bath Time as curses | Hiss on 1 face in 6 of five dice skips nearly every enemy move; Bath Time overlaps Knock It Off and the claw. The roomba and the boss have countdowns for the timing play hiss gave |
| Claw Wand, Comet, Thick Fur, Lucky Star, Sardine, Milk, Chicken, Sun Drop | overlaps, or a number and nothing else |
| the third book in a turn free, Copycat copying a book for free | made Laser Pointer and Copycat a loop (a free laser every turn); a copied book is paid again |
| Laser Pointer and Slow Blink redirecting a lone enemy onto itself | a lone elite or the boss never hit you; now with no friend standing the hit comes at you |
| Wishing Star's "next die times 2" | 98% of won runs; now "the next wand times 2" |
| zoomies hitting the cat (the game's u8 wrap) | a bug in the game; the proposals take the fix |
| Kitten Cannon (2026-10-31) | lost its pick in every version, as a book (it had to beat Zoomies and Meowcronomicon for the slot) and as a wand |
| the fixed three cards a fight | the owner: offers drawn at random from one pool |
| the eleven-fight run's puffcap-sporelet-nightflap and gnome-sporelets fights | the ten-fight shape has six normal fights; the nightflap is in no fight now |
| studying (a book without mana gave 1 mana) | the owner: a book without its mana is a dud |
| kittens that run off on hit-alls only | a point better for the kitten line; not worth the engine's rework |
