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
./catwiz-sim ... --study lift --without MEOWCRONOMICON --lift-from old.txt   # triples without it, old cells reused
./catwiz-sim --learned learned.txt --learn 80 --study cards --runs 4096    # each card taken, held, won
./catwiz-sim --learned learned.txt --learn 80 --study luck --runs 4000     # offer luck
./catwiz-sim ... --plan "card:1:TIMES TWO;charm:3:BAD MILK;nap:3:+1 TRICK"  # force a line
python3 check.py --player strong --runs 120 --toe-fix    # against Python
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
   byte. It was x16 at most for a while; now every number saturates at 255 (the owner's rule
   of 2026-11-01, below).
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

The owner's targets of 2026-11-01 are a check now (`--check-targets`, in "The final pool and
the retune" below): random 0%, greedy a few % at most, the expert 60-75%, a ladder of blunders
that falls level by level (a blunder a turn well under half the expert), the king the biggest
killer, every elite killing some runs. The older targets:

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

The woods' elite, new (one enemy, three moves; in the game since 2026-11-01, on the puffcap's figure until it has art):

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

(With kittens capped at 4 and a pounce of 2: the kitten section below has the final run with
no cap, a pounce of 1 and the Kitten Cannon, 73.7% won, within a point of this.) Full naps (the owner's lean), 4,096 runs of the good player, 3,000 strong, 5,000 greedy and
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

How the parts win together, from three studies with the good player, under the rules before
2026-11-01 (boosts banked over turns, a x16 cap; the lift under the new rules is in that
round's section, below):

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

## Kittens without a cap, and the Kitten Cannon (2026-10-31)

The owner's tests: no kitten cap (KITTENS_MOST 99, a status's room), a pounce of 1 against
2, one kitten still running off each time she is hurt; and Kitten Cannon back as a cash-out
book. Everything else as above. The draft was re-learned for each (two passes for the pounce
tests, one more for each Cannon, on the Mac mini). "Kittens": the most she had at once in the
run.

| setting | good player won | kittens: median, top tenth, top hundredth, most | Meowcronomicon taken when offered | runs that held it won | runs with 20-39 kittens | 40 or more |
|---|---|---|---|---|---|---|
| a pounce of 2, 4 at most (before) | 74.2% | capped at 4 | | | | |
| a pounce of 1, no cap | 75.0% | 1, 17, 67, 99 | 26% | 81% (16% of runs) | 5% of runs, won 89% | 3%, won 99% |
| a pounce of 2, no cap | 80.2% | 1, 30, 65, 99 | 71% | 91% (38% of runs) | 15%, won 100% | 6%, won 100% |

1. A pounce of 1 with no cap is the one to keep. A huge pile is an insane payoff (runs that
   reach 40 kittens win 99%), but few runs get there, and building it costs the run: the
   kitten runs win 81% against 75% for all. It is a line, not a lock.
2. A pounce of 2 with no cap is a lock: Meowcronomicon is taken 71% of the times it is
   offered and its runs win 91%.
3. The big piles come from x2 on Meowcronomicon (x16 makes 63 kittens in one cast), then
   Feather Toy and Mittens to make them pounce.

The Kitten Cannon: "3 MANA: LAUNCH ALL KITTENS, # EACH". Every kitten hits the picked enemy for
#, the next enemy when it falls, then all are gone. As a book, with a pounce of 1 and no cap:

| cost, # | taken when offered | forced, by third of the run (won) | good player won |
|---|---|---|---|
| 2 mana, 2 each | 0% | 35%, 37%, 42% | 74.4% |
| 3 mana, 2 each | 0% | 32%, 40%, 42% | 74.1% |
| 3 mana, 3 each | 0% | 32%, 38%, 43% | 74.4% |
| 3 mana, 4 each | 0% | 31%, 41%, 39% | 74.9% |

Its # hardly matters, because the Cannon fails on its slot. It is a book, so it pushes out
Meowcronomicon, the only big kitten maker, and kittens do not carry between fights. A Cannon
run launches only Mother Cat's one kitten and the Cardboard Box's one per three fluffs. Its
lift (given from fight 1, 192 runs a cell): alone it wins 39% (it pushes out Zoomies too);
with Feather Toy -0.77, with Catnip -1.11; it cannot be held with Meowcronomicon at all. Its
best pairs are mana (Moon Bowl +0.69, Wishing Star +0.66, Bad Milk +0.50), still under 75%.

Tried as a wand ("LAUNCH ALL KITTENS AT IT, # EACH", no mana), so it can sit beside
Meowcronomicon:

| wand, # | taken when offered | forced (won) | lift with Meowcronomicon | with Catnip | with Times Two |
|---|---|---|---|---|---|
| 1 each | 1% | 53%, 55%, 44% | +0.55 | -0.28 | -0.45 |
| 2 each | 2% | 55%, 53%, 43% | +0.40 | -0.67 | +0.10 |

Better, still rarely right: spending kittens loses to keeping them, since kept kittens pounce
every turn and the pile keeps growing. Runs made to hold a wand Cannon and Meowcronomicon
won 35% (1,500 runs); runs made to hold a book Cannon, Mother Cat and the Box won 18%.

The biggest Cannon turns (all at the king; the turn's damage count in these logs stopped at
255; the hits show what it was). The wand with Meowcronomicon: a waiting x9 and one more Times
Two make x16 (the cap) on the book, 64 kittens; one Times Two more on the Cannon (x3) launches
them at 8 each, and 16 hit before the king's last phase falls (the other 48 find no one):

```
turn 3  hp 26 mana 4 (x9 waits) | BULLDOG KING 98 (THRONE NAP: SHIELD 8); | dice: FLUFF, TIMES TWO, KITTEN CANNON, FLUFF, MEOWCRONOMICON
  TIMES TWO
  MEOWCRONOMICON x16 = 64
  re-roll FLUFF, KITTEN CANNON, FLUFF -> WET, KITTEN CANNON, KITTEN CANNON
  WET = 1 on BULLDOG KING; BULLDOG KING's ward blocks it
  re-roll KITTEN CANNON, KITTEN CANNON -> TIMES TWO, MOON BOWL
  TIMES TWO
  re-roll MOON BOWL -> KITTEN CANNON
  KITTEN CANNON x3 = 8 on BULLDOG KING: 16 hits of 8 (BULLDOG KING 13, BULLDOG KING, CROSS 3); 64 kittens launched; BULLDOG KING, CROSS GETS UP; BULLDOG KING, FURIOUS GETS UP; BULLDOG KING, FURIOUS beaten
```

The book (3 mana, 3 each) with Mother Cat and the Box: Times Two three times (x16, the cap),
four kittens at 48 each:

```
turn 6  hp 22 mana 5 kittens 4 (wish waits) | BULLDOG KING, CROSS 30 fleas2x2 (CHOMP FOR 28); ROYAL PUG 8 (CHEER: KING +2 NEXT); ROYAL PUG 8 (CHEER: KING +2 NEXT); | dice: TIMES TWO, TIMES TWO, KITTEN CANNON, CARDBOARD BOX, WISHING STAR, FLEAS
  TIMES TWO
  re-roll TIMES TWO, KITTEN CANNON, CARDBOARD BOX, WISHING STAR, FLEAS -> FLEAS, TIMES TWO, CARDBOARD BOX, TIMES TWO, KITTEN CANNON
  TIMES TWO
  TIMES TWO
  KITTEN CANNON x16 = 48 on BULLDOG KING, CROSS: 4 hits of 48 (BULLDOG KING, CROSS 1, BULLDOG KING, FURIOUS 3); 4 kittens launched; BULLDOG KING, FURIOUS GETS UP; BULLDOG KING, FURIOUS beaten
  FLEAS = 1 on ROYAL PUG; ROYAL PUG fleas 1
  ROYAL PUG: CHEER: KING +2 NEXT (at ROYAL PUG)
  ROYAL PUG: CHEER: KING +2 NEXT (at ROYAL PUG)

```

Recommendation: keep the pounce of 1 and no cap. The Cannon as a book is a dead card in the
item-slot model (left in the pool as asked, weight 3 from fight 3; almost never taken, so it
barely moves runs: 73.7% won with it, 75.0% without). For it to work it needs a kitten maker
outside the book slot, or not to spend the kittens: the owner's call, with the next content
round. The tables (`tools/sim/proposal`): KITTEN_HIT 1 and KITTENS_MOST 99 in effects.tsp;
KITTEN CANNON a new row after the hairball (row 33, book, 3, a level +1, cost 3); in
OFFER_CARDS `(make Offer :card items.CANNON :weight 3 :from 3)`. `learned.txt` is learned for
these tables.

The final run with them, the good player, 4,096 runs:

| fight | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| won | 100% | 100% | 100% | 100% | 100% | 98% | 100% | 100% | 94% | 80% |
| hp lost | 2.2 | 2.9 | 7.3 | 1.8 | 3.0 | 11.2 | 4.5 | 2.5 | 6.4 | 14.5 |
| turns | 2.2 | 2.9 | 3.8 | 2.8 | 3.1 | 4.4 | 3.4 | 3.5 | 5.0 | 9.1 |

Runs won 73.7%; strong 18.4%; greedy 0% (77% die at the mailman); random 0% (66% at the shroom).

## Boosts to the turn's end, bytes, and the wand Cannon (2026-11-01)

The owner's rules:

1. A waiting times and a waiting plus last to the end of the turn. They still stack within it,
   over re-rolls; nothing carries into the next turn.
2. No x16 cap. Every number saturates at 255 (the game keeps them in bytes) instead of
   wrapping or stopping at 99: the times, the plus, a face's boosted number, a hit's damage,
   shield, kittens (KITTENS_MOST 255), status turns, wet's turns, the three-count.
3. Kittens as merged: a pounce of 1, no cap but the byte.
4. Kitten Cannon a wand (beside Meowcronomicon now), still spending the kittens: "LAUNCH ALL
   KITTENS, # EACH", gone after; no mana.

Both sims play the rules the same way (`check.py`: greedy and random 500 runs, strong 120, 0
differ). The draft was re-learned for each Cannon # (two passes each, on the Mac mini).

### The run

The good player, 4,096 runs, the final tables (the Cannon at 5):

| fight | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| won | 100% | 100% | 100% | 100% | 100% | 97% | 100% | 100% | 92% | 76% |
| hp lost | 2.2 | 3.0 | 7.7 | 2.4 | 3.3 | 11.3 | 5.1 | 2.7 | 7.2 | 17.3 |
| hp lost before | 2.2 | 2.9 | 7.3 | 1.8 | 3.0 | 11.2 | 4.5 | 2.5 | 6.4 | 14.5 |
| turns | 2.3 | 2.9 | 4.0 | 2.9 | 3.3 | 4.7 | 3.6 | 3.8 | 5.4 | 9.7 |
| turns before | 2.2 | 2.9 | 3.8 | 2.8 | 3.1 | 4.4 | 3.4 | 3.5 | 5.0 | 9.1 |
| most turns | 5 | 9 | 11 | 14 | 12 | 40 | 44 | 33 | 60 | 58 |

Runs won 67.4% (73.7% before); lost at the mailman 3.3%, fight 9 8.1%, the king 21.0%.
Rollout picks 39.2%, strong 11.0%, greedy 0% (69% die at the mailman), random 0% (70% at the
shroom). The enemies were not retuned. The 6 points are mostly boosts that no longer bank
over turns: the king and fight 9 take more turns and more hit points. Their hit points are
the lever if the owner wants 74% back.

Stalls: 10.8% of runs have a fight over 15 turns (12.0% on another 4,096 seeds; 9.7% before
on the same count and seeds as the second; the 8% before was an older count). The longest
fights are fights 9 and 10 (60 and 58 turns at most), then fight 7 and the mailman (44, 40):
with no banked boosts the long fights get longer. Wet still adds its turns (to 255 now), so
the Wet stall (an enemy kept wet so it does nothing) is there as before; the owner keeps it
as a technique.

### Times Two and +1 Trick

| card | taken when offered | runs that held it | those runs won | all runs won |
|---|---|---|---|---|
| Times Two | 84% (97% before) | 31.9% | 83.9% (90.4%) | 69.4% (73.7%) |
| Times Two at x3 or more (a level) | | 9.0% (20.7%) | 95.1% (97.9%) | |
| Times Two at x4 or more | | 1.6% (6.2%) | 98.4% (98.8%) | |
| +1 Trick | 79% (85%) | 21.2% (24.0%) | 75.3% (79.3%) | |
| Copycat | 50% | 16.9% | 77.2% | |
| Meowcronomicon | 36% (32%) | 20.7% (19.8%) | 76.8% (80.0%) | |

Times Two is still close to an auto-pick: 84% taken, and its runs win 15 points over the
rest. Less than before (97%), since it can no longer bank a times for the next turn; it now
needs two or three Times Two faces up in one turn, which is what re-rolls are for. Levelled
it is a lock: x3 three times in a turn is x27, and runs that hold a x3 win 95%. If that is
too much, the smallest change is its level step (x2, then x3 at most), or its from-fight.
Meowcronomicon is no lock (36% taken when offered, its runs 77%: the pounce of 2 was 71% and
91%).

### The biggest turns

Turn damage in the logs is counted to 65,535 now; each hit stops at 255. Times Two at a
level three times in one turn, x27 on Zoomies (two Times Two came from a re-roll):

```
turn 2  hp 30 mana 3 | BULLDOG KING 68 (CHOMP FOR 26); | dice: CARDBOARD BOX, SPRAY BOTTLE, ZOOMIES, TIMES TWO, FLEAS
  TIMES TWO
  re-roll CARDBOARD BOX, SPRAY BOTTLE, ZOOMIES, FLEAS -> STAR, TIMES TWO, FLEAS, TIMES TWO
  TIMES TWO
  TIMES TWO
  re-roll STAR, FLEAS -> ZOOMIES, CARDBOARD BOX
  ZOOMIES x27 spooked -1 = 53: 5 hits of 53 (BULLDOG KING 2, BULLDOG KING, CROSS 2, BULLDOG KING, FURIOUS 1); BULLDOG KING, CROSS GETS UP; BULLDOG KING, FURIOUS GETS UP
```

221 damage, all three of the king's phases in one turn. Marks, no Times Two: 48 marks on the
king, put on over the fight, make a plain Zoomies of 3 hit for 51:

```
turn 4  hp 20 mana 4 | BULLDOG KING, CROSS 98 marked48 (CHOMP FOR 28); ROYAL PUG 8 (CHEER: KING +2 NEXT); ROYAL PUG 8 (CHEER: KING +2 NEXT); | dice: MARK TERRITORY, TIMES TWO, BELL COLLAR, ZOOMIES, MARK TERRITORY
  ZOOMIES = 3: 51 on BULLDOG KING, CROSS, 3 on ROYAL PUG, 3 on ROYAL PUG, 51 on BULLDOG KING, CROSS, 3 on ROYAL PUG; BULLDOG KING, FURIOUS GETS UP
```

Kittens: 26 kittens on, Mouse on String at x9, then the pounce (129 damage):

```
turn 4  hp 25 mana 1 kittens 26 | BULLDOG KING, CROSS 31 (CHOMP FOR 28); | dice: MEOWCRONOMICON, SPIKY FLUFF, SPIKY FLUFF, MEOWCRONOMICON, MEOWCRONOMICON
  re-roll MEOWCRONOMICON, SPIKY FLUFF, SPIKY FLUFF, MEOWCRONOMICON, MEOWCRONOMICON -> MOUSE ON STRING, SPIKY FLUFF, MOUSE ON STRING, MEOWCRONOMICON, MOUSE ON STRING
  MOUSE ON STRING = 5 on BULLDOG KING, CROSS: 2 hits of 5 (BULLDOG KING, CROSS 2)
  re-roll SPIKY FLUFF, MOUSE ON STRING, MEOWCRONOMICON, MOUSE ON STRING -> MOUSE ON STRING, TIMES TWO, TIMES TWO, SPIKY FLUFF
  TIMES TWO
  TIMES TWO
  MOUSE ON STRING x9 = 29 on BULLDOG KING, CROSS: 2 hits of 29 (BULLDOG KING, CROSS 1, BULLDOG KING, FURIOUS 1); BULLDOG KING, FURIOUS GETS UP
  re-roll SPIKY FLUFF -> TIMES TWO
  re-roll TIMES TWO -> MARK TERRITORY
  MARK TERRITORY = 2 on BULLDOG KING, FURIOUS; BULLDOG KING, FURIOUS marked 2
  26 kitten pounces on BULLDOG KING, FURIOUS for 3
  BULLDOG KING, FURIOUS beaten
```

Boost targets moved little: 26.9 boosts a run; Zoomies 32% of them (+3.4 a hit, the main
target in 63% of runs, won 68%), Mouse on String 13% (+6.7, 19% of runs, won 79%), Fleas 12%,
Star 7%.

### The wand Kitten Cannon

"LAUNCH ALL KITTENS, # EACH", a wand, no mana, a level +1; every kitten hits the picked enemy
for #, the next standing enemy when it falls, then the kittens are 0. In the pool at weight 3
from fight 3 (the book's place; chosen so it comes with Meowcronomicon's from-fight and no
more often than the other mid cards). Each # with its own learned draft, 4,096 runs:

| # | good player won | taken when offered | forced, by third of the run (won) | Meowcronomicon then and Cannon (forced, 1,500 runs) |
|---|---|---|---|---|
| 3 | 65.7% | 0% | 38%, 36%, 32% | 25.5% |
| 4 | 65.8% | 0% | 36%, 41%, 29% | 32.7% |
| 5 | 67.4% | 0% | 38%, 47%, 31% | 41.7% |

Lift (given from fight 1, slot locked, 192 runs a cell; "none" 67-69%):

| # | Cannon alone | with Meowcronomicon (won) | with Catnip | with Times Two |
|---|---|---|---|---|
| 3 | 50.0% | +0.57 (67.7%) | -0.25 (33.3%) | -0.46 (73.4%) |
| 4 | 45.3% | +1.13 (75.0%) | +0.26 (38.5%) | +0.09 (80.7%) |
| 5 | 52.1% | +0.62 (76.0%) | -0.57 (33.9%) | -0.44 (74.0%) |

Still a dead card at every #: it is never taken. As a wand it now fights Mouse on String
(taken 72% when offered) for the wand slot, and a run's kittens are few (median 1 at once, top
tenth 17), so most launches are a few kittens at 5. With Meowcronomicon it does lift (+0.6 to
+1.1), but the pair only reaches the plain run's win rate. I kept # 5 (the best forced runs
and the best with Meowcronomicon). The biggest launches reach the king's whole 98 in one turn,
but they need Meowcronomicon at x8 or x9 first; most of the kittens find no one:

```
turn 2  hp 30 mana 4 (wish waits) | BULLDOG KING 98 (CHOMP FOR 26); | dice: KITTEN CANNON, TIMES TWO, MEOWCRONOMICON, KITTEN CANNON, KITTEN CANNON
  TIMES TWO
  re-roll KITTEN CANNON, MEOWCRONOMICON, KITTEN CANNON, KITTEN CANNON -> SPIKY FLUFF, WET, WISHING STAR, TIMES TWO
  TIMES TWO
  re-roll SPIKY FLUFF, WET, WISHING STAR -> WISHING STAR, MEOWCRONOMICON, TIMES TWO
  TIMES TWO
  MEOWCRONOMICON x8 spooked -1 = 23
  re-roll WISHING STAR -> KITTEN CANNON
  KITTEN CANNON wish x2 spooked -1 = 17 on BULLDOG KING: 16 hits of 17 (BULLDOG KING 6, BULLDOG KING, CROSS 6, BULLDOG KING, FURIOUS 4); 23 kittens launched; BULLDOG KING, CROSS GETS UP; BULLDOG KING, FURIOUS GETS UP; BULLDOG KING, FURIOUS beaten
```

(294 damage counted against the king's 98: the count adds each hit's full number.) For the
Cannon to be picked, kept kittens must be worth less than launched ones; as long as every
kitten pounces every turn, keeping them wins.

### What wins together now, and the combos without Meowcronomicon

The lift study again under these rules (each part given from fight 1, its slot locked, 192
runs a cell, every pair; about 0.4 either way is noise). Alone (none: 67.7%): Times Two 90%,
Sixth Toe 89%, Spray Bottle 88%, Mouse on String 85%, Copycat 85%, Mark Territory 84%; at the
bottom 3 AM Screaming 45%, Knock It Off 47%, Knead and Kitten Cannon 52%.

The kitten pairs are still at the top: Meowcronomicon with Kitten Mittens +1.55 (96% won),
Catnip +1.38 (92%), Feather Toy +1.36 (94%). The best pairs without Meowcronomicon:

| pair | lift | won together | apart | why |
|---|---|---|---|---|
| Mouse on String + Wet | +1.60 | 98% | 85%, 76% | two hits a turn, and the big hitter's hits halved for turns: damage and safety from two cheap faces in different slots |
| Spray Bottle + Mark Territory | +1.08 | 98% | 88%, 84% | the marked enemy takes more from every wand hit, and the spray keeps it wet (its hits halved) while doing it |
| Wishing Star + Knock It Off | +0.81 | 78% | 78%, 47% | the 3 mana book is a dud without mana; Wishing Star pays it (still below the plain run) |
| Static Fur + Wishing Star | +0.81 | 94% | 81%, 78% | likely the fur's 5 to all on the pups while the star's mana keeps Zoomies coming |
| Mouse on String + Copycat | +0.80 | 97% | 85%, 85% | Copycat plays the last face again, +#: both of Mouse on String's hits again, harder |
| Mouse on String + Wishing Star | +0.80 | 96% | 85%, 78% | the star's "next wand times 2" doubles both hits |
| Wishing Star + Mother Cat | +0.74 | 91% | 78%, 74% | mana and a kitten from the start of each fight (near noise) |
| Fishbone Wand + Times Two | +0.70 | 94% | 64%, 90% | a x2 or x3 hit that no shield stops (the king's shields) |
| Knock It Off + Times Two | +0.69 | 88% | 47%, 90% | the book drops the shield and buffs, then hits at x2 |
| Fishbone Wand + Wet | +0.64 | 83% | 64%, 76% | the same pierce, with the enemy's hits halved |
| Mouse on String + Static Fur | +0.64 | 96% | 85%, 81% | the wand on the big ones, the fur's 5 to all on the pups |
| Bell Collar + Times Two | +0.61 | 97% | 80%, 90% | Times Two "counts #" towards a three, so a fluff combo fires with fewer fluffs up |
| Cardboard Box + Times Two | +0.57 | 97% | 83%, 90% | the same: hit-alls miss and a kitten, more often |
| Mark Territory + Sixth Toe | +0.57 | 97% | 84%, 89% | the sixth die finds Mark more often, and every die after hits the marked one harder |

Triples without Meowcronomicon (the best of those pairs and a third that lifts with both):
Mouse on String + Wishing Star + Spiky Fluff 99% (the pair 96%); Mouse on String + Wishing Star
+ Static Fur 98%; Fishbone Wand + Times Two + Wishing Star 96% (the pair 94%: the star's x2 and
Times Two's on one piercing hit); Wishing Star + Knock It Off + Mouse on String 97% (the pair
78%); Mouse on String + Wet + Still Water 96% (no better than the pair, 98%). At 96-99% a third
part adds little; the pairs are the combos.

So yes: Mouse on String is the other engine. It is the best wand (85% alone) and everything
that boosts a wand doubles both its hits (Wishing Star, Copycat; in natural runs Bad Milk +2 on
both, +18 damage a turn on the turns both are played, the top pair of the swings study); with
Wet it is also the safest build. Times Two's second use is on the fluff: its x counts towards a
three. Marks are the third: Mark Territory with a wand that hits often (Spray Bottle) or more
dice (Sixth Toe).

Worse together: Yarn Wand + Ball of Yarn -1.36 (two tangles on one enemy, the second adds
little), the Cannon with a book (Laser Pointer -1.28, 3 AM Screaming -1.27, If It Fits -1.06)
or with Bad Milk (-1.13), If It Fits + Mark Territory -1.13,
Feather Toy + Bad Milk -0.98, Spray Bottle + Sixth Toe -0.89.

### The tables

`tools/sim/proposal`, in the game's shape:

- effects.tsp: `(const KITTEN_HIT u8 1)`, `(const KITTENS_MOST u8 255)`.
- items.tsp, KITTEN CANNON (row 33): `:text "LAUNCH ALL KITTENS, # EACH" :slot Slot.wand
  :effect ac.Effect.cannon :amount 5 :step 1 :cost 0 :aim state.Aim.foe :icon art.TILE_WAND`.
- encounters.tsp, OFFER_CARDS: `(make Offer :card items.CANNON :weight 3 :from 3)` (unchanged).
- `learned.txt` is learned for these tables.

## The chain and combo cards (2026-11-01, sim only)

Seventeen new cards in both sims, nothing else changed (the enemies are not retuned): the
owner's Red Dot and six re-roll chain cards, then ten combo cards. The owner's rules for them:
one # a card (a boost changes only that #); boosts change output, never costs; "all dice
back" means every die, used or not, is rolled again and playable; a waiting plus or times
lasts to the turn's end, so it survives a refresh. `check.py` shows 0 differences on main's
tables (`--tables`, `--bin`: greedy and random 300 runs, strong 40) and on these (greedy and
random 400, strong 60). These tables are in `tools/sim/proposal`; `learned.txt` is learned
for them. The game's tables are not touched.

### The cards

| card | slot | text | # (a level) | cost | pool: weight, from | engine |
|---|---|---|---|---|---|---|
| Red Dot | curse | # TIMES: A WAND HIT ON IT, ALL BACK | 2 (+1) | | 3, 3 | a status, a check in the hit, the refresh |
| Finishing Swat | wand | #; IF IT FALLS, THIS DIE COMES BACK | 3 (+1) | | 3, 1 | an effect: "fell" from the hit unmarks its die |
| Lucky Paw | fluff | SHIELD #, AND A FREE RE-ROLL | 2 (+1) | | 3, 1 | an effect (shield, re-rolls + 1) |
| Sunbeam | star | +# MANA; MANA PAST 5 IS RE-ROLLS | 2 (+1) | | 3, 1 | an effect |
| Big Stretch | trick | RE-ROLL # DICE, USED ONES TOO | 2 (+1) | | 2, 4 | an effect, the refresh on # dice |
| Second Wind (charm) | | ONCE A FIGHT: ALL USED, ALL BACK | | | 2 | a charm kind, a check after each play, a flag a fight |
| Litter Box (charm) | | KITTENS STAY BETWEEN FIGHTS | | | 2 | a charm kind, a byte of run state |
| Mimic | book | 2 MANA: DO ITS SHOWN MOVE, # TIMES | 1 (+1) | 2 | 3, 3 | an effect and a move-to-hero table (the most code here) |
| Catfight | curse | IT HITS A FRIEND INSTEAD, # MORE | 4 (+1) | | 3, 1 | a status, a branch in the enemy's aim (like Laser's) |
| Mirror Fur | fluff | SHIELD #; BLOCKED HITS BOUNCE BACK | 3 (+1) | | 3, 1 | a status, a check in the hit on her |
| Dry Off | book | 2 MANA: EACH WET TURN HITS FOR # | 2 (+1) | 2 | 2, 3 | an effect (a loop over the enemies) |
| Flea Circus | curse | FLEAS #; IF IT FALLS, THEY JUMP X2 | 2 (+1) | | 3, 1 | a status flag, an on-fall hook |
| Haunted | curse | WHEN IT FALLS, ALL TAKE # | 4 (+2) | | 3, 1 | a status, the same on-fall hook |
| Scratching Habit | wand | #, AND +1 FOR GOOD EVERY USE | 2 (+1) | | 3, 1 | an effect, a byte of run state |
| Double or Nothing | trick | NEXT DIE X#; A DUD COSTS # HP | 3 (+1) | | 2, 3 | Times Two's code, a price status, a turn-end check |
| Cough It Up | wand | # FOR EACH HAIRBALL YOU ROLLED | 4 (+1) | | 2, 1 | an effect, a count in the roll |
| Nine Lives (charm) | | DIE ONCE, COME BACK WITH 10 HP | 10 | | 2 | a charm kind, a run flag, a check at her death |

How the sim plays them, where the text leaves room:

- The refresh (Red Dot, Big Stretch, Second Wind) is one routine: the dice are marked unplayed
  and rolled; a hairball on one is coughed up; it is not a re-roll (Still Water still pays).
- Red Dot fires once a wand face, on the first of its hits that lands on a dotted enemy (Mouse
  on String's two hits, the Cannon's kittens, a Copycat of a wand all count); each fire uses
  one #. A Red Dot played again adds its #. The turns form ("# TURNS", it fires every time
  while it lasts) played the same: 88.1% against 87.9%, so the times form is kept (it ends by
  itself).
- Finishing Swat's die comes back as it is (the same face, playable) when its hit drops an
  enemy to 0, a getting-up phase too.
- Big Stretch rolls the used dice first, then dice that cannot be played (the sim picks).
- Second Wind is the once-a-fight dice version of Nine Lives (renamed, both are in the pool);
  the once-a-turn form was dropped by the owner before testing.
- Mimic copies the picked enemy's shown move: a hit hits it (a hit-all hits them all), a
  shield shields her, a call is a kitten, a cheer or a growing is a waiting plus, a heal heals
  her, fleas and wet go on it, a reflect is her thorns; the rest do nothing. # is how many
  times; a +1 or a times on it is more times.
- Catfight: the enemy's next hit on her goes to its first friend, # harder; with no friend it
  waits.
- Mirror Fur: what that shield blocks this round goes back to the hitter, # at most.
- Flea Circus: when the host falls its fleas jump to the next enemy, doubled, with fresh turns
  and the jump again.
- Double or Nothing: a "dud" is the times still waiting at the turn's end (she always picks a
  die she can play, so an unplayable next die never happens); then she loses #.
- Cough It Up counts hairball faces rolled this turn, re-rolls and refreshes too. Only two
  enemies give hairballs: the dust bunnies (her fluff) and the big bath (her wand, which
  covers Cough It Up itself). Nothing she can take makes them.

The searching player's turn: a play that brings dice back ends a line of its search; at the
root the best four such lines are worth the mean of the best plan over the same imagined
rolls, and she takes one when it beats the plan and the re-roll (search.c). Deeper, a die
coming back is worth 3 points.

### Win rates

The good player, 4,096 runs (seed 61), each pool with its own learned draft:

| pool | won | runs with a fight over 15 turns | lost at 6, 9, 10 |
|---|---|---|---|
| main's (the baseline) | 67.7% (67.4% on seed 91) | 11.1% | 2.6%, 8.4%, 20.8% |
| + the seven chain cards | 76.0% | 6.4% | 1.7%, 5.4%, 16.4% |
| + all seventeen | 87.9% | 3.7% | 1.3%, 3.2%, 7.5% |

All seventeen, fight by fight:

| fight | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| won | 100% | 100% | 100% | 100% | 100% | 99% | 100% | 100% | 97% | 92% |
| hp lost | 2.2 | 2.7 | 6.7 | 1.4 | 1.9 | 10.4 | 2.7 | 1.8 | 5.0 | 8.3 |
| turns | 2.3 | 2.9 | 3.9 | 2.6 | 2.6 | 3.8 | 2.6 | 2.7 | 3.6 | 6.0 |

The learning: two passes from the last table, as before; in both pools the second pass played
3 points worse than the first on the test seeds (87.9% against 84.9% for all seventeen, and the
other way for the chain set: 74.3% against 76.0%), so each pool keeps its better table (the
chain set learned with Red Dot's turns form, played with the times form).

### How much the expert likes them

All seventeen in the pool. Taken when offered and held: natural runs (4,096, seed 81). Forced:
the card slipped into the offer and taken at the first pick of each third (256 runs a line;
unforced 86.7%). Alone from fight 1: the lift study's part alone, its slot locked (192 runs;
nothing: 90.1%). Its turns: the turns that played its face (a charm: the turns it was held),
their damage (most is 294, the king's three phases) and the share that touched three systems
or more.

| card | taken when offered | runs that held it (won) | forced, by third (won) | alone from fight 1 | its turns: damage mean, top tenth; 3+ systems |
|---|---|---|---|---|---|
| Scratching Habit | 94% | 49% (96%) | 97.3%, 96.5%, 95.7% | 100% | 43, 90; 19% |
| Big Stretch | 92% | 22% (89%) | from 4: 90.2%, 90.6% | 95% | 35, 76; 33% |
| Second Wind | 89% | 56% (92%) | 90.6%, 88.7%, 88.3% | 96% | 34, 76; 33% |
| Nine Lives | 83% | 54% (91%) | 85.5%, 87.1%, 87.9% | 90% | 29, 67; 24% |
| Double or Nothing | 80% | 22% (95%) | 93.0%, 96.5%, 96.5% | 100% | 46, 98; 36% |
| Mirror Fur | 72% | 39% (91%) | 90.2%, 91.0%, 86.3% | 94% | 21, 51; 23% |
| Mimic | 61% | 24% (93%) | 87.5%, 89.5%, 94.1% | 94% | 46, 96; 52% |
| Red Dot | 57% | 23% (93%) | 87.9%, 87.5%, 87.9% | 99% | 46, 93; 61% |
| Catfight | 57% | 34% (89%) | 88.7%, 82.8%, 83.6% | 92% | 20, 47; 34% |
| Lucky Paw | 39% | 23% (88%) | 87.9%, 84.8%, 84.8% | 96% | 26, 61; 24% |
| Flea Circus | 37% | 22% (87%) | 84.0%, 83.6%, 82.4% | 84% | 16, 40; 33% |
| Sunbeam | 25% | 15% (89%) | 87.9%, 85.2%, 84.0% | 90% | 34, 75; 36% |
| Litter Box | 14% | 11% (81%) | 83.2%, 82.4%, 85.9% | 88% | 26, 62; 24% |
| Haunted | 7% | 4% (90%) | 81.6%, 80.1%, 77.7% | 84% | 30, 67; 36% |
| Finishing Swat | 6% | 4% (86%) | 85.5%, 72.7%, 66.0% | 79% | 19, 36; 22% |
| Cough It Up | 2% | 1% (83%) | 84.8%, 60.9%, 56.6% | 67% | 15, 41; 23% |
| Dry Off | 1% | 0.4% | 58.6%, 61.3%, 67.2% | 62% | (too few) |
| for scale: Times Two | 62% | 18% (90%) | 92.2%, 89.8%, 89.8% | 93% | 35, 78; 34% |
| Mouse on String | 52% | 36% (87%) | 87.9%, 87.1%, 80.1% | 93% | 28, 52; 21% |
| Meowcronomicon | 42% | 18% (90%) | 80.5%, 81.2%, 85.5% | 90% | 33, 71; 85% |

The most exciting turns: Red Dot (61% of its turns touch three systems, a mean of 46),
Mimic (52%, 46), Double or Nothing (46 a turn) and Big Stretch; Meowcronomicon is still the
most many-system card (85%). Scratching Habit makes big turns (43) but plain ones (19%: one
wand hitting harder and harder).

Dead: Dry Off (it takes the book slot from Zoomies; she has no wet to cash: Spray, Wet and Dry
Off forced together won 33%), Cough It Up (no hairballs to cough; with the big bath it covers
itself), Finishing Swat past the woods (swarms are rare later), Haunted (most fights are one
big enemy), and still the Kitten Cannon.

### Chains

A turn of a fight that held the card (all seventeen; the chain set alone in brackets):

| card | what | median, top tenth, most a turn | turns with one |
|---|---|---|---|
| Red Dot | refreshes | 0, 3, 23 (0, 4, 196) | 36% |
| Big Stretch | refreshes | 1, 4, 19 (1, 4, 77) | 59% |
| Second Wind | refreshes | 0, 1, 1 | 30% |
| Finishing Swat | its die back | 0, 1, 3 | 19% |
| Lucky Paw | re-rolls got | 0, 2, 49 (0, 2, 255) | 39% |
| Sunbeam | re-rolls got | 0, 2, 240 (0, 2, 255) | 20% |
| every refresh | | 1, 4, 35 (1, 5, 254), on 19,245 turns | |

The searching player's time did not blow up: 64 runs a second with all seventeen, 56 with the
chain set, 58 on main's tables (the Mac mini, 14 threads). But the chains do not end by
themselves. In the chain set's pool one turn refreshed 254 times (the byte) for 0 damage: the
big bath at 1 hit point and wet 181 (the owner's Wet stall), she wet herself too, so her
sprays hit for 0, and every spray on the dotted bath brought the dice back, with Red Dots and
Big Stretches coming up again to keep it going:

```
turn 11  hp 30 mana 5 | THE BIG BATH 1 wet181 (SPLASH FOR 18); | dice: SPRAY BOTTLE, SPRAY BOTTLE, IF IT FITS, IF IT FITS, BIG STRETCH
  IF IT FITS = 8
  BIG STRETCH; back -> SPRAY BOTTLE, SPRAY BOTTLE, IF IT FITS, IF IT FITS, SPRAY BOTTLE
  re-roll SPRAY BOTTLE, SPRAY BOTTLE, IF IT FITS, IF IT FITS, SPRAY BOTTLE -> LUCKY PAW, BIG STRETCH, RED DOT, BIG STRETCH, SUNBEAM
  re-roll LUCKY PAW, BIG STRETCH, RED DOT, BIG STRETCH, SUNBEAM -> SUNBEAM, IF IT FITS, LUCKY PAW, LUCKY PAW, SPRAY BOTTLE
  SUNBEAM = 2
  LUCKY PAW = 3
  LUCKY PAW = 3
  SPRAY BOTTLE = 1 on THE BIG BATH: 0 on THE BIG BATH; THE BIG BATH wet 1; back -> IF IT FITS, IF IT FITS, SPRAY BOTTLE, RED DOT, SPRAY BOTTLE
  ... (254 times)
```

A limit of refreshes a turn (`--refresh-most N`, the counts are dice-back events of Red Dot,
Big Stretch and Second Wind):

| refreshes a turn at most | all seventeen won | chain set won | the longest turn (all seventeen) |
|---|---|---|---|
| none (255) | 88.8% | 75.8% | 35 refreshes |
| 5 | 89.0% | 75.9% | 7 (with swats) |
| 3 | 88.4% | 73.4% | 5 |

(the chains study's seeds, 4,096 runs.) At most 5 a turn costs nothing and ends the loops;
it is what I would ship (a rule in the engine, no card text). The main
numbers above are with no limit. Re-rolls also run to the byte: Sunbeam gave 240 re-rolls in
one turn (boosted mana past 5), Lucky Paw 49 over a chain; a cap on re-rolls (9, say)
or on Sunbeam's overflow (# at most) would end those.

### Locks

- Scratching Habit: forced at fight 1 it wins 99.9% (1,500 runs), alone from fight 1 100%;
  taken 94% of the times it is offered. The habit grows all run (24 to 35 by the king), so it
  is a lock. Tested: the +1s lasting the fight only ("+1 FOR THE FIGHT EVERY USE"): forced at
  fight 1, 88.1%; all runs 80.9% (87.9% with it for the run). That is the fix I would make.
- Double or Nothing: forced at fight 3, 97.9%; taken 80%. It is Times Two at x3 from level 0,
  and the price is easy to dodge: the search plays it when a die can take it. Fixes: x2 at level 0
  like Times Two, or the price paid when it is played.
- Red Dot: alone from fight 1, 99%; with Mouse on String forced (3 and 4), 97.1%. Taken only
  57% when offered, so the draft undervalues it: held from the start it is a lock.
- Big Stretch (92%), Second Wind (89%) and Nine Lives (83%) are near auto-picks but not
  locks (their runs win 89-92% against 88.8%). Second Wind is one refresh a fight, always
  taken and never a decision: drop it (the owner's condition) unless a cheaper charm pool
  needs it. Nine Lives as a second life is fine and cheap.
- Litter Box with Meowcronomicon: both from fight 1, 100% (+3.98, the biggest lift of the
  round). In the natural draft it is no kitten lock: Litter Box is taken 14%, Meowcronomicon
  42% (its runs 89.5%); forced Meowcronomicon and Litter Box at fight 3 won 87.7%, like the
  plain run. The Cannon still kills the line: with all three forced, 39.9% (it takes the wand).

### Lift with the partners

Each card given from fight 1 with every other part (192 runs a cell; nothing: 90.1%, so
everything sits near the ceiling and the won column says more than the lift):

| card | alone | Times Two | Scratch Post | Sixth Toe | Mouse on String | its best pair |
|---|---|---|---|---|---|---|
| Red Dot | 99% | +0.19 (100%) | +0.60 (100%) | -0.57 (99%) | -0.32 (99%) | Sunbeam +1.68 (100%) |
| Finishing Swat | 79% | +0.79 (92%) | -0.27 (89%) | +0.03 (88%) | (a wand) | Kitten Mittens +1.15 (88%) |
| Lucky Paw | 96% | -0.32 (96%) | -1.24 (95%) | -0.29 (97%) | -0.19 (96%) | Second Wind +0.88 (100%) |
| Sunbeam | 90% | +0.75 (96%) | +1.18 (99%) | +0.65 (97%) | +1.07 (97%) | Warm Blanket +1.70 (96%) |
| Big Stretch | 95% | (a trick) | -0.25 (98%) | +0.80 (99%) | +0.45 (98%) | Flea Circus, Still Water +1.29 (98%) |
| Second Wind | 96% | +0.93 (99%) | -0.36 (98%) | +0.68 (99%) | +0.59 (98%) | Still Water +3.13 (100%) |
| Litter Box | 88% | +1.01 (97%) | +0.48 (97%) | +0.93 (97%) | +0.73 (96%) | Meowcronomicon +3.98 (100%); Cannon +0.22 (59%) |
| Mimic | 94% | +0.21 (96%) | +2.26 (100%) | +0.75 (98%) | +0.74 (98%) | Litter Box +2.34 (100%) |
| Catfight | 92% | +0.66 (97%) | +0.60 (98%) | +0.02 (95%) | +0.66 (97%) | Mimic +2.00 (100%) |
| Mirror Fur | 94% | +1.25 (99%) | -0.25 (97%) | +2.62 (100%) | +0.65 (98%) | Flea Circus +3.71 (100%) |
| Dry Off | 62% | +0.26 (75%) | -0.17 (80%) | -0.30 (69%) | -0.10 (68%) | Scratching Habit +1.68 (100%) |
| Flea Circus | 84% | +1.36 (97%) | +1.04 (98%) | +0.71 (95%) | +1.08 (96%) | Mirror Fur +3.71 (100%) |
| Haunted | 84% | +0.76 (94%) | -0.33 (92%) | +0.19 (92%) | +0.67 (94%) | Wishing Star +1.13 (96%) |
| Scratching Habit | 100% | -0.32 (100%) | -1.02 (100%) | -0.57 (100%) | (a wand) | everything 100% |
| Double or Nothing | 100% | (a trick) | -1.02 (100%) | +0.53 (100%) | -0.32 (100%) | Bad Milk +0.85 (100%) |
| Cough It Up | 67% | +0.41 (81%) | +0.13 (86%) | +0.45 (85%) | (a wand) | Kitten Mittens +1.25 (80%) |
| Nine Lives | 90% | +0.85 (97%) | +0.00 (96%) | +0.77 (97%) | +1.02 (97%) | Mark Territory +2.18 (100%) |

Lucky Paw with Times Two -0.32 and Sunbeam with Times Two +0.75: Sunbeam's re-rolls fish for
Times Two, Lucky Paw's shield is what it gives instead. Mimic with Catfight (+2.00), likely
because both turn the enemies' own hits against them.

### The biggest turns

Mimic at three levels, four Plus Ones waiting (+8: 10 times), the king's chomp done to him ten
times (255 damage, his three phases):

```
turn 2  hp 26 mana 3 kittens 1 | BULLDOG KING 78 marked4 wet3 (CHOMP FOR 26); | dice: BELL COLLAR, SPRAY BOTTLE, SPRAY BOTTLE, PLUS ONE, BELL COLLAR
  PLUS ONE
  re-roll BELL COLLAR, SPRAY BOTTLE, SPRAY BOTTLE, BELL COLLAR -> MARK TERRITORY, PLUS ONE, MARK TERRITORY, PLUS ONE
  PLUS ONE
  re-roll MARK TERRITORY, MARK TERRITORY, PLUS ONE -> PLUS ONE, LITTER STAR, SPRAY BOTTLE
  re-roll PLUS ONE, LITTER STAR, SPRAY BOTTLE -> PLUS ONE, PLUS ONE, MIMIC
  PLUS ONE
  PLUS ONE
  MIMIC +8 spooked -1 = 10 on BULLDOG KING: 30 on BULLDOG KING, 30 on BULLDOG KING, 30 on BULLDOG KING, 26 on BULLDOG KING, CROSS, 26 on BULLDOG KING, CROSS, 26 on BULLDOG KING, CROSS, 26 on BULLDOG KING, CROSS, 26 on BULLDOG KING, FURIOUS, 26 on BULLDOG KING, FURIOUS, 26 on BULLDOG KING, FURIOUS; BULLDOG KING, CROSS GETS UP; BULLDOG KING, FURIOUS GETS UP
```

Red Dot, Big Stretch and a habit at 24: every habit hit on the dotted king brings the dice
back, the habit grows 24 to 29 in the turn, the king's 294 in turn 1:

```
turn 1  hp 30 mana 0 | BULLDOG KING 98 (ROYAL BARK: DICE -1); | dice: SCRATCHING HABIT, ZOOMIES, RED DOT, SHOOTING STAR, BIG STRETCH, BELL COLLAR
  SCRATCHING HABIT = 24 on BULLDOG KING: 24 on BULLDOG KING
  RED DOT = 2 on BULLDOG KING; BULLDOG KING's ward blocks it
  SHOOTING STAR = 2 on BULLDOG KING: 2 on BULLDOG KING
  BIG STRETCH; back -> RED DOT, ZOOMIES, SCRATCHING HABIT, RED DOT, BELL COLLAR
  RED DOT = 2 on BULLDOG KING; BULLDOG KING's ward blocks it
  RED DOT = 2 on BULLDOG KING; BULLDOG KING red dot 2
  BELL COLLAR = 3
  SCRATCHING HABIT = 25 on BULLDOG KING: 25 on BULLDOG KING; back -> ZOOMIES, BELL COLLAR, SCRATCHING HABIT, ZOOMIES, SHOOTING STAR, SHOOTING STAR
  ... (the same, 24 more plays)
```

Double or Nothing after a chain: Lucky Paws and Litter Stars for shield and mana, a Fishbone
on the dotted king brings two Double or Nothings back, x9 Zoomies (258 damage, turn 1):

```
turn 1  hp 30 mana 0 kittens 1 | BULLDOG KING 98 (ROYAL BARK: DICE -1); | dice: LUCKY PAW, DOUBLE OR NOTHING, LUCKY PAW, ZOOMIES, LUCKY PAW
  re-roll LUCKY PAW, DOUBLE OR NOTHING, LUCKY PAW, ZOOMIES, LUCKY PAW -> LITTER STAR, RED DOT, LUCKY PAW, LITTER STAR, ZOOMIES
  ...
  RED DOT = 2 on BULLDOG KING; BULLDOG KING red dot 2
  FISHBONE WAND = 5 on BULLDOG KING: 5 on BULLDOG KING; back -> FISHBONE WAND, ZOOMIES, LITTER STAR, LITTER STAR, ZOOMIES
  ZOOMIES = 4: 5 hits of 4 (BULLDOG KING 5)
  LITTER STAR = 3
  ZOOMIES = 4: 5 hits of 4 (BULLDOG KING 5)
  LITTER STAR = 3
  FISHBONE WAND = 5 on BULLDOG KING: 5 on BULLDOG KING; back -> DOUBLE OR NOTHING, DOUBLE OR NOTHING, LUCKY PAW, FISHBONE WAND, ZOOMIES
  DOUBLE OR NOTHING
  DOUBLE OR NOTHING
  ZOOMIES x9 = 36: 5 hits of 36 (BULLDOG KING 1, BULLDOG KING, CROSS 3, BULLDOG KING, FURIOUS 1); BULLDOG KING, CROSS GETS UP; BULLDOG KING, FURIOUS GETS UP
```

### What I would do with them

1. Keep, as they are: Mimic (the most fun card here: big, many-system, an answer to whatever
   the enemy shows), Red Dot with a cap of 5 refreshes a turn, Catfight, Mirror Fur, Lucky
   Paw, Flea Circus, Nine Lives (die once). Mimic is the most engine code; the rest are a
   status or an effect each.
2. Fix: Scratching Habit's +1s for the fight only (tested above); Double or Nothing x2 at
   level 0, or its price paid up front; Sunbeam's re-rolls capped.
3. Drop or rework: Second Wind (an always-taken flat bonus), Dry Off and Cough It Up (no
   enablers in her pool), Finishing Swat and Haunted (swarms are too rare; they could come
   back with a swarm zone).
4. With any of them in, the enemies need retuning: all seventeen take the expert from 67% to
   88%, the chain set alone to 76%.

Tools: `--study chains` (the take rates of every card and charm, the chains a turn, the longest
chain told, each card's turns), `--refresh-most N`, `--dot-turns`, `--habit-fight` (a test),
`check.py --tables DIR --bin BUILT`.

## The final pool and the retune (2026-11-01)

The owner settled the pool, the enemies were retuned to his targets, and the targets are now a
check the sim runs (`--check-targets`). It passes on the final tables. Both sims play the
same (`check.py`, 0 differ on these tables and on main's old ones).

### The pool

1. In: Mimic, Red Dot, Catfight, Mirror Fur, Lucky Paw, Flea Circus, Nine Lives (die once,
   back with 10), Sunbeam, Litter Box, and the two fixed cards below.
2. Out: Second Wind, Big Stretch, Dry Off, Cough It Up, Finishing Swat, Haunted. Their rows are
   gone from the tables (the effect kinds stay, marked "no row", for the sims).
3. Kitten Cannon stays, bad on purpose (the owner: some cards good, some bad).

Rules on the cards:

- Red Dot's refreshes: at most 5 a turn (`REFRESH_MOST`, a rule in the engine, no card text).
- Sunbeam: "+# MANA; PAST 5, UP TO 2 RE-ROLLS" (`SUNBEAM_REROLLS` 2). It gave 240 re-rolls in
  a turn before; the re-rolls got in a turn (with Lucky Paw's) are now 12 at most.
- Scratching Habit: "#, +1 FOR THE FIGHT EVERY USE". The +1s are gone at the fight's end, so
  it is a wand that warms up, not a run that snowballs (forced it won 99.9% before).
- Double or Nothing: "NEXT DIE X#; IT COSTS YOU 1 HP": x3 (a level x4) on the next die, and 1
  hit point paid when it is played. The old card (x3, # hit points only if no die took it)
  won 93-97% forced last round. Three designs forced into runs (2,048 runs each, the tables
  before the enemy changes; unforced 77%):

| design | forced at fight 3 | at 5 | at 7 |
|---|---|---|---|
| x3, # hp (3) paid when played | 29% | 49% | 61% |
| x2, # hp (2) only if no die takes it | 84% | 83% | 83% |
| x3, 1 hp paid when played (chosen) | 82% | 86% | 86% |

  Paying # was a death sentence: she plays it over and over and bleeds 3 a time. x2 with the
  dud price is Times Two again (forced 82-85% too), so the card would have no reason to exist.
  x3 for 1 hit point keeps it the bigger, riskier Times Two: a real price every time, strong,
  not a lock.

### The enemies

| enemy | before | now | why |
|---|---|---|---|
| The Old Shroom (woods elite) | 46 hp, cap slam 8 | 60 hp, cap slam 14 | it killed no expert run; now 4.4% |
| The Mailman (garden elite) | heavy parcel 12 | heavy parcel 14 | 2.1-2.8% kills; now 3.0% |
| The Vet (a yard elite) | 76 hp, checkup 18 | 66 hp, checkup 30 | it killed 1-2% of the runs that chose it; harder all round (86 hp, needle 6, checkup 26) and no run chose it; now lighter but its checkup can kill: 13% of runs take it, 2.6% of those die |
| Bulldog King, all three phases | 98 hp each | 108 hp each | the last fight is to be brutal; it now kills 17% of expert runs (20% of the ones that reach it) |

Nothing else moved (no fight's make-up changed). The Big Bath already killed 7-8%.

### The skill ladder

The expert is the searching player with its learned draft. A blunder is a random legal play
(any die it can play, any target) instead of its own; after one it plans again from where it
is. At a separate rate a pick between fights (card, charm, rest, door) is a random option.
The levels, by how often (each play, each pick):

| level | a play | a pick | blunders made | won |
|---|---|---|---|---|
| the expert | 0 | 0 | 0 | 69.3% |
| a slip a fight | 5.5% | 10% | 1.06 a fight (0.25 a turn) | 51.4% |
| a blunder a turn | 22% | 25% | 0.98 a turn | 23.9% |
| two a turn | 45% | 50% | 1.94 a turn | 3.1% |
| for scale: strong (the old searching player, no learned draft) | | | | 14.9% |
| greedy (the best play this turn, no look-ahead) | | | | 0.1% |
| random | | | | 0% |

Runs lost by fight (4,096 runs each, seed 61):

| level | 1 | 2 | 3 shroom | 4 | 5 | 6 mailman | 7 | 8 | 9 vet or bath | 10 king |
|---|---|---|---|---|---|---|---|---|---|---|
| the expert | 0 | 0 | 4.4% | 0 | 0 | 2.9% | 0 | 0.2% | 6.1% | 17.1% |
| a slip a fight | 0 | 0 | 6.9% | 0.2% | 0.4% | 8.3% | 0.5% | 1.1% | 10.1% | 21.0% |
| a blunder a turn | 0 | 0 | 17.1% | 1.3% | 2.3% | 19.1% | 2.2% | 2.9% | 14.5% | 16.7% |
| two a turn | 0 | 0 | 36.0% | 5.0% | 6.3% | 27.0% | 3.9% | 3.1% | 9.4% | 6.4% |
| greedy | 0 | 0 | 75.3% | 0 | 0.4% | 17.7% | 0 | 3.0% | 2.5% | 1.0% |

The shroom is the skill check now: the expert loses 4% there, a blunder a turn 17%, greedy 75%.
The expert, fight by fight:

| fight | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| won | 100% | 100% | 96% | 100% | 100% | 97% | 100% | 100% | 93% | 80% |
| hp lost | 2.2 | 2.7 | 12.7 | 2.2 | 2.8 | 13.0 | 4.9 | 3.4 | 8.7 | 16.4 |
| turns | 2.3 | 3.0 | 5.1 | 3.0 | 3.2 | 4.7 | 3.4 | 3.5 | 5.3 | 8.6 |

Stalls: 8.0% of the expert's runs have a fight over 15 turns (11.1% on main's tables, 3.7%
with all seventeen chain cards).

The target check (`./catwiz-sim --learned learned.txt --learn 80 --check-targets --runs 4096
--seed 61`, exit 1 on any FAIL), on the final tables:

```
targets: 4096 runs a line, seed 61
  PASS  random wins 0.0% (under 0.5%)
  PASS  greedy wins 0.1% (5% at most)
    lost in fight: 1:0.0% 2:0.0% 3:75.3% 4:0.0% 5:0.4% 6:17.7% 7:0.0% 8:3.0% 9:2.5% 10:1.0%
  expert             wins  69.3%  (a play 0.000, a pick 0.00: 0.00 blunders a turn, 0.00 a fight)
    lost in fight: 1:0.0% 2:0.0% 3:4.4% 4:0.0% 5:0.0% 6:2.9% 7:0.0% 8:0.2% 9:6.1% 10:17.1%
  PASS  the expert wins 69.3% (60-75%)
  PASS  the king kills the most expert runs (17.1%)
  PASS  THE OLD SHROOM kills 4.4% of the 4096 expert runs reaching it (2% at least)
  PASS  THE MAILMAN kills 3.0% of the 3915 expert runs reaching it (2% at least)
  PASS  THE VET kills 2.6% of the 543 expert runs reaching it (2% at least)
  PASS  THE BIG BATH kills 7.3% of the 3244 expert runs reaching it (2% at least)
  a slip a fight     wins  51.4%  (a play 0.055, a pick 0.10: 0.25 blunders a turn, 1.06 a fight)
    lost in fight: 1:0.0% 2:0.0% 3:6.9% 4:0.2% 5:0.4% 6:8.3% 7:0.5% 8:1.1% 9:10.1% 10:21.0%
  a blunder a turn   wins  23.9%  (a play 0.220, a pick 0.25: 0.98 blunders a turn, 4.16 a fight)
    lost in fight: 1:0.0% 2:0.0% 3:17.1% 4:1.3% 5:2.3% 6:19.1% 7:2.2% 8:2.9% 9:14.5% 10:16.7%
  two a turn         wins   3.1%  (a play 0.450, a pick 0.50: 1.94 blunders a turn, 8.06 a fight)
    lost in fight: 1:0.0% 2:0.0% 3:36.0% 4:5.0% 5:6.3% 6:27.0% 7:3.9% 8:3.1% 9:9.4% 10:6.4%
  PASS  a slip a fight (51.4%) wins less than expert (69.3%)
  PASS  a blunder a turn (23.9%) wins less than a slip a fight (51.4%)
  PASS  two a turn (3.1%) wins less than a blunder a turn (23.9%)
  PASS  a blunder a turn wins 23.9%, under 45% of the expert's (31.2%)
PASS: 0 failed
```

Thresholds I chose for the owner's words: random under 0.5%; greedy 5% at most ("a few %");
a blunder a turn under 45% of the expert ("well under half"); an elite kills 2% or more of the
runs reaching it, judged when 100 runs or more reach it.

Targets that are odd as stated:

- Greedy wins 0.1%: "a few % at most" passes, but it dies at the shroom 75% of the time. If
  the owner meant greedy should sometimes get far, the shroom is the place to soften.
- The vet: the run sees both doors and takes the one its kit handles, so a door's kills are
  the kills of runs that chose it. Made harder, nobody chose it; the vet now hits harder with
  less hp, and some runs take it and some die there.

### The tier list

Every card and charm in the pool, the final tables. Forced: the card slipped into the offer and
taken at the first pick of each third of the run (fights 1-3, 4-6, 7-9; a charm at the elites
3, 6, 9), 256 runs a line; the unforced player won 67.2% on those seeds, so "vs unforced" is the
mean of the thirds less 67.2 (about 2 points either way is noise). Taken when offered and held:
4,096 natural runs. Alone from fight 1: the lift study's part given from the start, its slot
locked, 192 runs (nothing given: 69.3%); best pair: its best lift there.

The tiers, by the forced win rate against the unforced 67.2%:

- broken: a lock or a no-decision auto-pick that wins nearly always: forced 90% or more in a
  third, or 98% alone from fight 1, or taken 90% of the time with its runs winning 90%;
- really good: +6 points or more; good: +2 to +6; okay: within 2; bad: -2 to -8; really bad:
  -8 or worse.

Nothing is broken. 

| tier | card | forced, by third | vs unforced | taken when offered | runs that held it (won) | alone from fight 1 | best pair |
|---|---|---|---|---|---|---|---|
| really good | Mimic | 76%, 78%, 82% | +11.4 | 74% | 30% (86%) | 81% | Scratch Post +2.20 (99%) |
| really good | +1 Book (a level) | 77%, 77%, 71% | +7.8 |  |  |  |  |
| really good | Times Two | 74%, 75%, 75% | +7.5 | 72% | 20% (84%) | 85% | Ball of Yarn +0.85 (92%) |
| really good | Spray Bottle | 78%, 75%, 70% | +7.3 | 75% | 51% (75%) | 88% | Meowcronomicon +1.13 (92%) |
| really good | Double or Nothing | 74%, 72%, 78% | +7.1 | 69% | 20% (82%) | 85% | Mouse on String +0.91 (98%) |
| good | Mirror Fur | 79%, 73%, 67% | +6.0 | 78% | 44% (78%) | 88% | Meowcronomicon +1.02 (92%) |
| good | Scratch Post | 76%, 74%, 69% | +5.8 | 84% | 54% (81%) | 82% | Mimic +2.20 (99%) |
| good | +1 Trick (a level) | 72%, 73% | +5.5 |  |  |  |  |
| good | Sixth Toe | 71%, 72% | +4.3 | 80% | 23% (81%) | 88% | Purrfect Trio +0.40 (91%) |
| good | Catfight | 77%, 70%, 66% | +4.1 | 71% | 42% (70%) | 80% | Meowcronomicon +1.31 (89%) |
| good | Red Dot | 69%, 70%, 74% | +3.8 | 52% | 22% (84%) | 94% | Mimic +1.44 (100%) |
| good | +1 Fluff (a level) | 71%, 72%, 67% | +2.7 |  |  |  |  |
| okay | Copycat | 70%, 67% | +1.3 | 58% | 15% (71%) | 74% | Scratching Habit +1.37 (97%) |
| okay | +1 Wand (a level) | 66%, 69%, 70% | +1.3 |  |  |  |  |
| okay | Nine Lives | 65%, 71%, 70% | +1.3 | 89% | 56% (78%) | 84% | Wishing Star +0.39 (92%) |
| okay | Rubber Duck | 71%, 67%, 67% | +1.2 | 55% | 39% (75%) | 81% | Scratching Habit +0.39 (94%) |
| okay | Mouse on String | 74%, 67%, 62% | +0.4 | 57% | 40% (72%) | 87% | Mimic +1.21 (98%) |
| okay | +1 Curse (a level) | 66%, 70%, 66% | +0.2 |  |  |  |  |
| okay | Mark Territory | 69%, 66%, 68% | +0.1 | 51% | 22% (77%) | 86% | Meowcronomicon +0.91 (90%) |
| okay | Flea Circus | 67%, 67%, 63% | -1.4 | 41% | 25% (72%) | 79% | Spray Bottle +0.76 (96%) |
| okay | Grumpy Face | 64%, 66%, 68% | -1.6 | 35% | 28% (72%) | 74% | Moon Bowl +0.89 (85%) |
| bad | +1 Star (a level) | 63%, 68%, 65% | -2.1 |  |  |  |  |
| bad | Lucky Paw | 67%, 65%, 63% | -2.2 | 34% | 21% (69%) | 83% | Red Dot +1.30 (100%) |
| bad | Wet | 62%, 71%, 61% | -2.5 | 41% | 34% (70%) | 77% | Meowcronomicon +1.01 (83%) |
| bad | Bad Milk | 65%, 65%, 62% | -3.2 | 26% | 20% (70%) | 77% | Meowcronomicon +0.87 (81%) |
| bad | Mother Cat | 67%, 63%, 62% | -3.3 | 20% | 16% (70%) | 71% | Red Dot +1.13 (98%) |
| bad | Wishing Star | 64%, 64% | -3.3 | 33% | 7% (74%) | 76% | Scratch Post +1.16 (95%) |
| bad | Cardboard Box | 67%, 63%, 60% | -3.5 | 27% | 22% (68%) | 78% | Meowcronomicon +0.62 (78%) |
| bad | If It Fits | 66%, 67%, 59% | -3.5 | 40% | 12% (70%) | 73% | Scratching Habit +1.28 (96%) |
| bad | Kitten Mittens | 65%, 62%, 64% | -3.5 | 17% | 14% (74%) | 72% | Meowcronomicon +2.36 (94%) |
| bad | Static Fur | 63%, 65%, 60% | -4.2 | 28% | 13% (70%) | 78% | Sunbeam +0.88 (93%) |
| bad | Still Water | 58%, 65%, 64% | -4.7 | 19% | 16% (71%) | 74% | Mimic +0.73 (92%) |
| bad | Fluffy Tail | 62%, 61%, 64% | -4.8 | 7% | 6% (82%) | 74% | Red Dot +0.72 (98%) |
| bad | Scratching Habit | 59%, 61%, 66% | -4.8 | 28% | 17% (74%) | 85% | Copycat +1.37 (97%) |
| bad | Litter Box | 64%, 60%, 62% | -5.1 | 2% | 2% (73%) | 74% | Meowcronomicon +3.89 (99%) |
| bad | Ball of Yarn | 62%, 64%, 59% | -5.5 | 16% | 14% (64%) | 64% | Mimic +1.08 (91%) |
| bad | Fishbone Wand | 66%, 62%, 57% | -5.5 | 31% | 20% (67%) | 70% | Mimic +1.17 (94%) |
| bad | Sunbeam | 57%, 63%, 64% | -5.7 | 19% | 12% (70%) | 77% | Mimic +1.00 (95%) |
| bad | Purrfect Trio | 59%, 63% | -6.2 | 3% | 1% (88%) | 69% | Red Dot +0.79 (97%) |
| bad | Yarn Wand | 65%, 60%, 57% | -6.6 | 19% | 17% (68%) | 75% | Meowcronomicon +0.89 (80%) |
| bad | Litter Star | 58%, 64%, 60% | -6.6 | 16% | 14% (72%) | 74% | Spray Bottle +0.70 (95%) |
| bad | Bell Collar | 64%, 60%, 55% | -7.3 | 16% | 11% (68%) | 75% | Mimic +0.70 (92%) |
| bad | Spiky Fluff | 62%, 61%, 56% | -7.4 | 16% | 14% (67%) | 77% | Mimic +0.94 (94%) |
| bad | Feather Toy | 66%, 54%, 58% | -7.7 | 18% | 12% (63%) | 66% | Meowcronomicon +2.62 (94%) |
| really bad | Warm Blanket | 57%, 60%, 58% | -9.0 | 8% | 3% (65%) | 69% | Mother Cat +0.33 (78%) |
| really bad | Catnip | 58%, 60%, 56% | -9.4 | 8% | 4% (72%) | 55% | Meowcronomicon +1.97 (83%) |
| really bad | Meowcronomicon | 54%, 53%, 59% | -11.7 | 10% | 5% (82%) | 55% | Litter Box +3.89 (99%) |
| really bad | Shooting Star | 47%, 59%, 58% | -12.5 | 9% | 8% (70%) | 68% | Knead +0.59 (56%) |
| really bad | Moon Bowl | 46%, 59%, 57% | -13.0 | 5% | 4% (67%) | 65% | Grumpy Face +0.89 (85%) |
| really bad | Knock It Off | 49%, 56%, 44% | -17.6 | 6% | 3% (58%) | 58% | Knead +0.32 (38%) |
| really bad | Knead | 51%, 45% | -19.0 | 3% | 1% (61%) | 42% | Red Dot +1.12 (94%) |
| really bad | Laser Pointer | 47%, 46%, 44% | -21.7 | 1% | 1% (74%) | 55% | Copycat +0.39 (69%) |
| really bad | Kitten Cannon | 46%, 50%, 32% | -24.2 | 1% | 0% (50%) | 45% | Meowcronomicon +1.14 (58%) |
| really bad | 3 AM Screaming | 38%, 44%, 35% | -28.4 | 0% | 0% (75%) | 38% | Moon Bowl +0.74 (50%) |

Notes:

1. Mimic is the best card (really good, +11): it copies the enemy's biggest move. Strong, not a
   lock (82% forced late, 86% for the runs that hold it).
2. Double or Nothing at x3 for 1 hp is really good (+7, like Times Two), no longer broken.
   Scratching Habit for the fight is now bad (-5): a wand that warms up over a fight.
3. Meowcronomicon with Litter Box is the strongest pair: given both from fight 1 it wins 99%
   (lift +3.89). It is not a lock in a real run: forced together at fight 3 they win 82.6%
   (2,048 runs; unforced 70.0%), Meowcronomicon alone at 3 59.0%, Litter Box at 6 with it 71.2%.
   Litter Box is taken 2% of the time it is offered; the expert does not see the pair coming.
4. Nine Lives is taken 89% of the time it is offered, but forced it is only okay (+1): a
   comfort pick, not a lock.
5. The books that replace Zoomies (Knock It Off, Laser Pointer, 3 AM Screaming, Meowcronomicon
   alone) and the Kitten Cannon are really bad: Zoomies is still the book. The owner wants some
   bad cards; these are the bad ones, nothing was buffed.

### The tables in the game's shape

`tools/sim/proposal` (`learned.txt` is learned for them). What the game needs from this
round, on top of the earlier rounds' list:

1. effects.tsp: `REFRESH_MOST` 5, `SUNBEAM_REROLLS` 2, `GAMBLE_UPFRONT` 1, `GAMBLE_PRICE` 1.
2. items.tsp: the new rows 34-42 (Red Dot, Lucky Paw, Sunbeam, Mimic, Catfight, Mirror Fur,
   Flea Circus, Scratching Habit, Double or Nothing; texts above and in the file).
3. encounters.tsp: the charms Litter Box (10) and Nine Lives (11, amount 10); OFFER_CARDS 42
   rows, OFFER_CHARMS 12 (the pool as settled).
4. enemies.tsp and moves.tsp: the numbers in the enemy table above.
5. The effect kinds out of the pool (swat, stretch, dryoff, haunt, cough, and the charm kind
   nine) are not needed.

Tools: `--check-targets`, `--blunder P`, `--blunder-pick Q`.

## The house (2026-11-01)

The third zone is THE HOUSE now (the owner: a cat's journey home, the woods, the garden, the
house). Fights 4 and 8 swap so the enemies fit their places: fight 4 is the sprinkler and the
lawnmower (in the garden; the table's fight has 2 enemies, its third spot unused, as it was
at 8), fight 8 the dust bunnies and the roomba (in the house). Every other fight stays. Only
the two enemies that live in one fight each were retuned, so the sprinkler and the dust bunny
(also in fights 5 and 7) keep their numbers:

| enemy | field | was | now |
|---|---|---|---|
| Lawnmower | hp | 60 | 34 |
| Lawnmower | mows for # | 14 | 6 |
| Roomba | hp | 42 | 62 |
| Roomba | full speed bump # | 12 | 18 |

Each fight plays like its slot did (the expert, 4,096 runs, seed 61):

| fight | hp lost, turns before the swap | the swap alone | retuned |
|---|---|---|---|
| 4 | 2.2, 3.0 | 6.4, 4.0 (the mailman then killed 10.9%) | 2.6, 3.0 |
| 8 | 3.4, 3.5 | 1.3, 2.7 | 3.2, 3.3 |

The draft was re-learned (two passes); the expert wins 70.5% (69.3% before), runs with a fight
over 15 turns 7.6%. The target check on these tables:

```
targets: 4096 runs a line, seed 61
  PASS  random wins 0.0% (under 0.5%)
  PASS  greedy wins 0.0% (5% at most)
    lost in fight: 1:0.0% 2:0.0% 3:75.3% 4:0.0% 5:0.3% 6:17.6% 7:0.2% 8:1.5% 9:4.3% 10:0.8%
  expert             wins  70.5%  (a play 0.000, a pick 0.00: 0.00 blunders a turn, 0.00 a fight)
    lost in fight: 1:0.0% 2:0.0% 3:3.9% 4:0.0% 5:0.0% 6:2.6% 7:0.0% 8:0.1% 9:5.8% 10:17.1%
  PASS  the expert wins 70.5% (60-75%)
  PASS  the king kills the most expert runs (17.1%)
  PASS  THE OLD SHROOM kills 3.9% of the 4096 expert runs reaching it (2% at least)
  PASS  THE MAILMAN kills 2.7% of the 3936 expert runs reaching it (2% at least)
  PASS  THE VET kills 3.0% of the 1109 expert runs reaching it (2% at least)
  PASS  THE BIG BATH kills 7.5% of the 2716 expert runs reaching it (2% at least)
  a slip a fight     wins  53.0%  (a play 0.055, a pick 0.10: 0.25 blunders a turn, 1.04 a fight)
    lost in fight: 1:0.0% 2:0.0% 3:6.9% 4:0.3% 5:0.6% 6:8.2% 7:0.4% 8:0.9% 9:10.3% 10:19.4%
  a blunder a turn   wins  23.4%  (a play 0.220, a pick 0.25: 0.99 blunders a turn, 4.17 a fight)
    lost in fight: 1:0.0% 2:0.0% 3:16.6% 4:0.8% 5:2.4% 6:19.9% 7:2.3% 8:3.1% 9:14.0% 10:17.3%
  two a turn         wins   3.8%  (a play 0.450, a pick 0.50: 1.94 blunders a turn, 8.09 a fight)
    lost in fight: 1:0.0% 2:0.0% 3:35.2% 4:4.0% 5:6.2% 6:28.0% 7:4.5% 8:3.3% 9:8.4% 10:6.7%
  PASS  a slip a fight (53.0%) wins less than expert (70.5%)
  PASS  a blunder a turn (23.4%) wins less than a slip a fight (53.0%)
  PASS  two a turn (3.8%) wins less than a blunder a turn (23.4%)
  PASS  a blunder a turn wins 23.4%, under 45% of the expert's (31.7%)
PASS: 0 failed
```

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
   past x1,000,000; a hit's damage is a byte in the game. Superseded on 2026-11-01: no cap, every
   number saturates at 255, and boosts end with the turn (the owner's, above).
9. Kittens: KITTEN_HIT and KITTENS_MOST are numbers in effects.tsp now (1 and 5 in the code
   before). At 1 with a cap of 5 the kitten cards lost their picks by 30-60 points; the
   owner's test (above) settled on a pounce of 1 and no cap (99, then 255).
10. Bad Milk: "WANDS +2; BOOKS COST 1 MORE" (was wands +1 and fleas 2 on her at every fight's
    start, 6 hit points a fight: forced, it won 0% of runs). A trade between wands and books.
11. Kitten Cannon: cut (it lost its pick in every version, 11-40%, as a book and as a wand),
    then back as the owner's cash-out book, then a wand (2026-11-01): every kitten hits for
    its #, all gone (above).
12. A woods elite, THE OLD SHROOM (an enemy and three moves), for the new shape.

Tried and dropped: kittens that run off when a hit-all lands instead of whenever she is hurt
(a point better for the kitten line, not worth the engine's rework).

Sim fixes, not rules (the engine has them): Sixth Toe's sixth die; Python 3.12's compensated
sums in the C sim.

Flagged, not changed:

- Mouse on String with one enemy left hits it twice.
- (Settled by the owner on 2026-11-01: boosts end with the turn; the Wet stall is a
  technique.) A waiting +1 or times stayed to the next turn, so she could bank them over turns
  ("+36 waits" in the logs), and Wet adds without end (99). Together they made stalls: 1% of the good
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

The item model is in the game (Catwiz main, from f403880's tables). The tuned tables went in on
2026-11-01 (branch `tuned`); each of the list below is in now:

1. In: the new tables' numbers (`python3 tools/sim/tablediff.py` lists them): items, enemies,
   moves, the charms' amounts and texts, the fights as the sim's run (the nightflap is in no
   fight now), the constants.
2. In: KITTEN_HIT (1) and KITTENS_MOST (255) in content/effects.tsp, where the pounce and the
   kitten cap read them.
3. In: Bad Milk, wands +2 (its amount), books cost 1 more for each bad milk held (`fx.cost`; the
   kit page shows the cost with it, the book's own line still says its base); no fleas.
4. In: a waiting plus and times cleared at the turn's end (after still water's mana, as the
   sim), and every number saturating at 255 (`st.sum`, `fx.times`): the times, the plus, a
   face's boosted number, a hit's damage (after the mark), stacks (shield, kittens, statuses),
   wet's adding, the three-count, mana gained. The hud's badges show three digits; a floating
   number shows 99 at most (the log has the whole number).
5. In: THE OLD SHROOM, an enemy row and three moves (calls 2 sporelets, cap slam 8, spore cap
   shield 5). No art yet: it stands in on the puffcap's figure.
6. In: Kitten Cannon as a cash-out wand (no mana, 5 each, a level +1): every kitten launched at
   the picked enemy for the face's number (a wand's boosts count), on to the next standing enemy
   when it falls, then the kittens are 0.
7. In: the pools as `OFFER_CARDS` (the sim's 33 rows; the start items are not in it) and
   `OFFER_CHARMS`, NAP_HEAL_SHIFT 0.

Kept as the game had it (the owner): a Copycat copy of a book is free (the sim makes it pay,
a dud without the mana). The sim's proposed new numbers for Wishing Star, Yarn and Spray are
not in (proposals, not in the tables).

`validate.py` (the sim against the machine, above) is the bag game's: it does not run on the
item game (it stops reading the game's tables, before booting) and was not ported, so the
2026-11-01 rules were checked by hand in the machine (scripted dice in a test copy): a plus
used up by one die, a times gone the next turn, wet 1, 2, 3 on one enemy, the Cannon (3 kittens
for 15; 255 kittens through both enemies), a Times Two stack to x64 hitting for 255, the old
shroom's fight and moves, Bad Milk's costs.

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
| Kitten Cannon (2026-10-31; back the same day as a cash-out book, see the kittens section) | lost its pick in every version, as a book (it had to beat Zoomies and Meowcronomicon for the slot) and as a wand |
| the fixed three cards a fight | the owner: offers drawn at random from one pool |
| the eleven-fight run's puffcap-sporelet-nightflap and gnome-sporelets fights | the ten-fight shape has six normal fights; the nightflap is in no fight now |
| studying (a book without mana gave 1 mana) | the owner: a book without its mana is a dud |
| kittens that run off on hit-alls only | a point better for the kitten line; not worth the engine's rework |
