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

## The proposal: the item-slot model

The owner chose it over the bag (2026-10-30). Catwiz rolls five identical dice each turn, with
two re-rolls of the unplayed dice; each die's six faces are her six item slots, and the item in a
slot decides what that face does. No bag, no draw or discard, no taking a die out. The tables
are in `tools/sim/proposal/` in the content format (`items.tsp`, `enemies.tsp`, `moves.tsp`,
`encounters.tsp`, `action.tsp`, `effects.tsp` constants), ready to drop into `game/content`
once the engine has the mechanics (the list at the end).

### The six slots

Every die is the same: six faces, one for each slot, and the item in the slot decides what the
face does. Each slot varies its own way:

| slot | every item in it does | items differ by |
|---|---|---|
| wand | N damage to the enemy picked | a rider on the hit (the twig wand has a combo instead) |
| fluff | shield N till your next turn | a combo: what the third fluff played in a turn adds |
| star | mana (kept all fight, 5 at most) | a mana spell each: how the mana comes, and what else |
| book | casts its spell for mana | the spell. With too little mana a book can't be played (2026-10-31, the owner: no fizzle; the dead-key sound and the mana stars shake) |
| curse | N of a status on the enemy picked | the status |
| trick | a rule for the next die played | the rule |

N starts at 1 for wands and fluff and grows by levels. Levels belong to the slot.

Mana is the resource that ties the slots together: stars make it, books spend it, a book with
too little mana can't be played (it made 1 until 2026-10-31), and charms and items feed it (Still Water, Grumpy Face, Litter Star,
Shooting Star, Moon Bowl, Wishing Star). Kittens are the second thread: books, a wand, a fluff, a star, a
trick and three charms make, feed or use them.

### Items (33 and the hairball)

Text is the card's item line (35 columns at most); the slot's base is the card's first line.

| item | slot | text | touches |
|---|---|---|---|
| TWIG WAND (start) | wand | #. 3 IN A TURN: THE 3RD HITS ALL | re-rolls, x2 (counts as two), Trio |
| YARN WAND | wand | #, AND IT IS TANGLED 1 | tangled (Ball of Yarn stacks it), enemy hits |
| SPRAY BOTTLE | wand | #, AND IT IS WET | wet (Static Fur 4 on wet), Wet curse |
| FEATHER TOY | wand | #, AND YOUR KITTENS POUNCE IT | kittens, Mittens, Mark |
| FISHBONE WAND | wand | #, AND NO SHIELD STOPS IT | shields (gnome, king), Knock |
| MOUSE ON STRING | wand | #, THEN # TO THE NEXT ENEMY | groups, +1 (both hits), Mark |
| FLUFF (start) | fluff | 3 IN A TURN: SHIELD STAYS A TURN | re-rolls, x2, Knead, Fluffy Tail, the countdowns |
| SPIKY FLUFF | fluff | 3 IN A TURN: WHO HITS YOU TAKES 2 | multi-hit enemies (gremlin, pugs), Trio |
| CARDBOARD BOX | fluff | 3 IN A TURN: HIT-ALLS MISS, +KITTEN | hit-alls (sprinkler, king's flop), kittens |
| WARM BLANKET | fluff | 3 IN A TURN: HEAL 2 | hit points (the only heal in a fight) |
| STATIC FUR | fluff | 3 IN A TURN: 2 TO ALL, 4 IF WET | wet (Spray, Wet), groups |
| BELL COLLAR | fluff | 3 IN A TURN: A WARD PIP | curses on you (cucumber, vet, bath, king), Rubber Duck |
| STAR (start) | star | +# MANA | books, +1 (+1 mana) |
| SHOOTING STAR | star | +1 MANA, AND # DAMAGE | wand levels' cousin, +1, Mark |
| MOON BOWL | star | +1 MANA, AND SHIELD # | fluff, books |
| WISHING STAR | star | +# MANA; THE NEXT WAND TIMES 2 | wands, order (play it before a wand) |
| LITTER STAR | star | +# MANA, AND 1 MORE A KITTEN | kittens, books |
| ZOOMIES (start) | book | 2 MANA: # TO FOES 5 TIMES, L TO R | +1 (each hit), Mark (each hit), groups |
| MEOWCRONOMICON | book | 3 MANA: # KITTENS JOIN YOU | kittens, Catnip, Cannon, If It Fits |
| LASER POINTER | book | 3 MANA: # TO ALL; THEY HIT FRIENDS | groups (needs a friend), summoners |
| 3 AM SCREAMING | book | 3 MANA: # TO ALL FOES, 1 TO YOU | groups, Grumpy Face (the 1 to you) |
| KNOCK IT OFF | book | 2 MANA: IT DROPS SHIELD, BUFFS; # | shields, grow, cheer, return to sender |
| IF IT FITS | book | 2 MANA: SHIELD #, +2 A KITTEN | kittens, shields |
| KITTEN CANNON | book | 2 MANA: # TO IT FOR EACH KITTEN | kittens |
| FLEAS (start) | curse | # A TURN FOR 3 TURNS; THEY STACK | +1 (a stack more), x2, Bad Milk, wards |
| WET | curse | ITS HITS HALVED FOR # TURNS | Spray, Static Fur, wards |
| BALL OF YARN | curse | TANGLED #: ITS HITS # LESS | Yarn Wand, multi-hits, wards |
| MARK TERRITORY | curse | MARKED #: HITS ON IT # MORE | Zoomies, kittens (they go for it), String, wards |
| PLUS ONE (start) | trick | NEXT 2 DICE +#, EACH HIT AND STAR | wide: two dice of any slot; each Zoomies and String hit, a curse stack, a star's mana |
| TIMES TWO | trick | NEXT WAND, FLUFF, BOOK X#: COUNTS # | tall: one wand, fluff or book (a star or curse leaves it waiting); levels; counts twice towards a fluff or twig three; played after +1 it doubles that too |
| COPYCAT | trick | YOUR LAST FACE AGAIN, +# | combos (the copy counts), books (paid again) |
| CATNIP | trick | NEXT # DICE +1; KITTENS ACT TWICE | kittens, wide |
| KNEAD | trick | NEXT FLUFF TIMES 2, NEXT WAND +# | fluff and wand together, order |
| HAIRBALL | (any) | A DUD. RE-ROLL IT TO COUGH IT UP | re-rolls: an enemy's (dust bunny, big bath) |

### Charms (10)

| charm | text | touches |
|---|---|---|
| SCRATCH POST | ONE MORE RE-ROLL EVERY TURN | re-rolls, combos, hairballs |
| SIXTH TOE | ROLL 6 DICE, BUT 1 RE-ROLL LESS | combos, re-rolls (a trade) |
| STILL WATER | A TURN WITH NO RE-ROLL: +2 MANA | re-rolls against books (a trade) |
| PURRFECT TRIO | EACH 3 IN A TURN ALSO HITS ALL 1 | fluff combos, twig wand |
| KITTEN MITTENS | YOUR KITTENS HIT 1 HARDER | kittens |
| MOTHER CAT | EACH FIGHT STARTS WITH A KITTEN | kittens, Litter Star, Cannon |
| FLUFFY TAIL | YOUR SHIELD HALVES, NOT GONE | fluff, countdowns |
| GRUMPY FACE | A HIT THAT HURTS YOU: +1 MANA | books, 3 AM Screaming's 1 to you, the vet's fleas |
| RUBBER DUCK | A CURSE A WARD BLOCKS: SHIELD 3 | wards (yours and the enemies'), Bell Collar, curses |
| BAD MILK | WANDS +1; FIGHTS START WITH FLEAS 2 | wands, fleas on you (a trade) |

They come at three points, one of three each: after fight 4 (the day's end: Mother Cat, Scratch
Post, Bad Milk), after the mailman (with the nap: Fluffy Tail, Still Water, Kitten Mittens) and
after the vet or the big bath (Purrfect Trio, Grumpy Face or Rubber Duck, Sixth Toe).

### Statuses

Each used by several items or enemies:

| status | on | what | from |
|---|---|---|---|
| fleas | enemy, you | N damage at the end of its turn, 3 turns; stacks | Fleas curse, +1 (a stack more), Bad Milk and the vet (on you) |
| wet | enemy, you | its hits halved, N turns | Wet curse, Spray Bottle, the big bath (on you); Static Fur's combo hits wet enemies double |
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
   for a spray bottle keeps the +2. Two levels a slot at most (ITEM_MOST).
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

Day is the forest's own creatures; dusk is the garden at the forest's edge (the bulldog king's
backyard, where the household things roam: the owner's roomba, hoover, mailman, vet and bath
fit there without clashing with the forest); night is the yard and porch at night. The zones are
only art: no item or rule changes by zone. Each enemy has one twist; its moves go round in
order and always show.

| enemy | hp | ward | moves (round and round) | its twist |
|---|---|---|---|---|
| PUFFCAP | 6 | 0 | headbutt 2; spore shield 2 | shields itself every other turn |
| SPORELET | 4 | 0 | nip 1; cheer: a friend +1 next | makes a friend hit harder |
| NIGHTFLAP | 5 | 1 | scratch 1; bite 1; dive 2 | a ward pip: your first curse breaks it |
| GARDEN GNOME | 11 | 1 | guards a friend: shield 3; rod poke 3 | shields others (kill the friend or strip it) |
| POSSUM | 9 | 0 | bite 2; puffs up: shield 2 | plays dead: beaten, it gets up as POSSUM (FAKED IT), 4 hp, after a round |
| SQUIRREL | 5 | 0 | grabs your last die; acorn 2 | takes the die you played last until it is beaten (you roll one die less) |
| ROOMBA | 18 | 0 | beep, bumps in 2; beep beep, in 1; full speed bump 8 | a countdown: time your shield, tangle or wet for the bump |
| DUST BUNNY | 3 | 0 | sneeze 2; hairball on your fluff | clogs your fluff slot with a dud until a re-roll coughs it up |
| CUCUMBER | 8 | 1 | spooks: your dice -1 next turn; rolls at you 2 | a curse on you (a ward blocks it) |
| SPRINKLER | 10 | 0 | sprays all 2 (a hit-all); waters friends +2 | heals its friends; its spray misses a cardboard box |
| HOOVER JR. | 28 | 1 | calls 2 dust bunnies; sucks 6; sucks 6 | summons: kill the summoner or drown in hairballs |
| LAWNMOWER | 32 | 2 | revs up: +2 for good; mows 7 | grows every other turn; stalls (skips its move) after losing 12 in one of your turns |
| THE MAILMAN (elite) | 42 | 2 | parcel 6; return to sender 6; heavy parcel 8; grumpier +1 for good | sends back the next 6 you deal it (till its next turn): don't hit it then |
| THE VET (elite) | 48 | 2 | needle: fleas 4 on you; takes a temperature (your last die); checkup 9; snaps gloves +1; treats itself +6 | poisons you, steals a die, heals |
| THE BIG BATH (elite) | 30 | 2 | rinse: you are wet; splash 8; hairball on your wand | beaten, it drains into a DRAIN GREMLIN (22 hp: glug 4 twice; gurgles +1 for good) |
| BULLDOG KING | 26 a phase | 2, 1, 0 | phase 1: royal bark (your dice -1); chomp 9; throne nap: shield 8 | three phases, each a round to get up |
| BULLDOG KING, CROSS | | | calls 2 royal pugs; slobber all 4; chomp 10; decree +1 for good | the pups: ROYAL PUG 6 hp, yap 2, cheer: the king +2 next |
| BULLDOG KING, FURIOUS | | | winds up: flop in 2; in 1; belly flop all 18; growl +2 for good | a countdown to a hit-all 18: a cardboard box, a stack of shield, tangle |

Fights 1-2 keep the game's enemies with the item model's smaller numbers (the base values of 1
need puffcap 6 hp and headbutt 2 instead of 9 and 4).

### The run, fight by fight

| # | zone | enemies | the three cards after | then |
|---|---|---|---|---|
| 1 | day | puffcap, sporelet | +1 WAND, YARN WAND, TIMES TWO | |
| 2 | day | puffcap, sporelet, nightflap | SPRAY BOTTLE, SPIKY FLUFF, +1 STAR | |
| 3 | day | garden gnome, 2 sporelets | MEOWCRONOMICON, LITTER STAR, BALL OF YARN | |
| 4 | day | squirrel, possum, squirrel | +1 FLUFF, FEATHER TOY, MARK TERRITORY | a charm: Mother Cat, Scratch Post, Bad Milk |
| 5 | dusk | dust bunny, roomba, dust bunny | CARDBOARD BOX, KITTEN CANNON, COPYCAT | |
| 6 | dusk | cucumber, garden gnome, sprinkler | STATIC FUR, SHOOTING STAR, WET | |
| 7 | dusk | THE MAILMAN (elite) | WISHING STAR, KNOCK IT OFF, CATNIP | a charm: Fluffy Tail, Still Water, Kitten Mittens; the nap |
| 8 | night | hoover jr., dust bunny | MOON BOWL, LASER POINTER, MOUSE ON STRING | |
| 9 | night | sprinkler, lawnmower | FISHBONE WAND, BELL COLLAR, KNEAD | |
| 10 | night | THE VET or THE BIG BATH (two doors) | vet: +1 BOOK, WARM BLANKET, 3 AM SCREAMING; bath: +1 CURSE, IF IT FITS, +1 TRICK | a charm: Purrfect Trio, Grumpy Face (vet) or Rubber Duck (bath), Sixth Toe |
| 11 | night | THE BULLDOG KING | | |

Catwiz: 30 hit points; starts with Twig Wand, Fluff, Star, Zoomies, Fleas, Plus One.

Per fight (2026-10-30; strong 400 runs, greedy and random 900 each). Lost: hit points lost in
the fight by the runs that won it; net: lost less healed; turns: mean (most).

| fight | strong: reached, won | hp in | lost | turns | greedy: reached, won | lost | random: reached, won | lost |
|---|---|---|---|---|---|---|---|---|
| 1 | 100%, 100% | 30.0 | 1.1 | 1.8 (4) | 100%, 100% | 2.2 | 100%, 100% | 2.5 |
| 2 | 100%, 100% | 28.9 | 2.5 | 2.4 (4) | 100%, 100% | 3.9 | 100%, 100% | 5.0 |
| 3 | 100%, 100% | 26.4 | 1.7 | 2.9 (8) | 100%, 100% | 2.7 | 100%, 100% | 4.6 |
| 4 | 100%, 100% | 24.7 | 1.8 | 3.9 (8) | 100%, 100% | 7.7 | 100%, 94% | 6.4 |
| 5 | 100%, 100% | 22.9 | 0.9 | 3.1 (6) | 100%, 93% | 4.1 | 94%, 55% | 7.9 |
| 6 | 100%, 100% | 21.9 | 4.3 | 6.7 (31) | 93%, 68% | 4.7 | 51%, 2% | 10.3 |
| 7 (elite) | 100%, 97% | 17.7 | 6.0 | 6.7 (18) | 63%, 43% | 4.7 | 1%, 0% | |
| 8 | 96%, 99% | 21.7 (the nap) | 4.8 | 4.8 (13) | 27%, 88% | 6.8 | | |
| 9 | 95%, 94% | 16.9 | 2.5 | 5.6 (18) | 24%, 35% | 5.3 | | |
| 10 (elite) | 89%, 92% | 15.3 | 2.1 | 7.6 (29) | 8%, 36% | 5.1 | | |
| 11 (boss) | 82%, 85% | 13.8 | 3.7 | 10.1 (32) | 3%, 0% | | | |

Strong wins 70% of runs and ends them with 11.3 hit points; greedy wins none (it dies in fights
6-7 mostly), random none (fights 5-6). No healing in fights (the only heal, Warm Blanket's
combo, is taken in under 10% of runs); the nap's 10 hit points are taken in 99% of runs.

### The targets, met or not

| target | result |
|---|---|
| random dies by fight 4-6 | met: 6% die in 4, 42% in 5, 50% in 6 |
| greedy dies around fights 5-8, wins under 5% | met: mostly 6-7, wins 0% |
| strong wins 50-75% | met: 70% |
| strong reaches the boss under half hit points | met: 13.8 of 30 |
| a normal fight costs about 10% (2-5), an elite 15-30% | normal met (0.9-4.8). Elites low: the mailman 6.0 (20%), the vet or bath 2.1 for the runs that win, but 8% die there: elite fights are swingy, not steady |
| fights 3-6 turns, the boss 8-12 | fights 1-2 are short (1.8, 2.4); 6-7 and 10 run long (6.7-7.6); the boss 10.1 |
| hit points lost rise by zone | roughly: day 1-2.5, dusk 1-6, night 2-5 (the mailman is the wall) |
| no healing loop | met (with no heal face; see the heal comparison) |
| no card above about 80% of won runs | not yet: +1 Fluff 89%, Moon Bowl 87%, Mother Cat 86%, Wet 80%. Their rivals are weak (below) |
| no dead face | Kitten Cannon 32% and If It Fits 39% are played less than half the times they show (they want kittens); the hairball is a dud by design |

What the sim says to tune next in the proposal:

1. The kitten axis is weak: Meowcronomicon is never taken, Feather Toy and Kitten Cannon rarely;
   Mother Cat is the one kitten piece taken. Kittens hit 1 and run off when you are hurt, so they
   rarely last. Try kittens that stay till they are hit by a hit-all, or 2 damage each.
2. Spiky Fluff (2%), Static Fur (1%), Laser Pointer (5%), Mouse on String (8%), Knead (7%) lose
   their card to a clear favourite; each needs a reason (a bigger combo, a cheaper cost) or a
   different rival.
3. Elites: steadier damage (more, smaller hits; the vet's fleas) rather than big swings, so they
   cost 20-30% rather than killing 8% and costing the rest little.
4. Fights 1-2 are quick (2 turns): fine as a start, or a few more hit points on the puffcap.

## Comparisons

`python3 tools/sim/study.py <name>` prints these (96-200 strong runs a line, three times as many
greedy and random). "Won" is the strong player's unless said; "hp" is hit points walking into the
last fight.

### The bag model against the item model

The same eleven fights in both (`--content bag` and `--content proposal`), each tuned a while:

| model | strong won | hp at the boss | turns a fight | greedy dies at | random dies at |
|---|---|---|---|---|---|
| bag (start 5, cap 6, swap when full, type upgrades, tuna faces) | 86% | 26.9 | 9.2 | 7 | 4 |
| item slots (the proposal) | 72% | 13.1 | 4.9 | 7 | 5 |

The bag version's strong player wins more but by stalling: it heals back to near full in every
fight (the tuna faces, 9 turns a fight). Its numbers would need the heal cut (below) before a
fair comparison; the item model was tuned to the targets and is the owner's choice.

### Starting bag size (the bag model)

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

### Upgrades

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

### Heal tension (tuna)

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

### +1 against x2

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

### Other checks on the item model

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

## What the engine needs for the proposal

The item model replaces the bag (`battle/bag.tsp`) with the five dice of the six item slots, and
`battle/reward.tsp` with the card pick. In content and engine terms:

1. `content/items.tsp` (the `Item` row: name, text, slot, effect, amount, step, cost, combo,
   combo_n, aim, icon) instead of `content/faces.tsp`; the five dice are the six slots' items.
   State: the six items, a level a slot, the charms (a byte a charm, 10), nine-lives-style
   once-a-run flags (none left in the proposal).
2. A face's number: amount + step x the slot's level, then the boosts in their order
   (`tools/sim/items.py` top). The faces played of each slot this turn, for the combos.
3. The effects: the new kinds in `proposal/action.tsp`, each a few lines in the one match of
   `content/effects.tsp` (their sim versions in `items.py` and `rules.py`).
4. Statuses: tangled, marked, strength, kittens, keep (a shield kept), wish, mult (a pending
   times), nip, knead (two), spook; wet becomes a count of turns. The status table has 16 slots
   an actor; the proposal needs about 22 (the sim's list in `rules.py`).
5. Enemy fields: calls (summon), then (becomes another kind when beaten: the possum, the bath's
   gremlin, the boss's phases), stall (the lawnmower). Summons fill empty spots and wait a
   round; a "then" enemy keeps its spot and waits a round.
6. Enemy moves: their own `Move` row (text, effect, amount, aim, motion, icon) in
   `content/moves.tsp`: 49 of them in the formatter's layout would take enemies.tsp past 500
   lines.
7. The hairball: a slot's face is a dud for the fight; re-rolling a die that shows it coughs it
   up (the slot's item is back).
8. Steal: the die played last is held by the enemy until it is beaten (four dice a turn).
9. A book with too little mana can't be played (2026-10-31; it played as +1 mana before, and tools/sim/items.py still does until the C sim round).
10. Encounters: the zone (art only), three cards a fight (items, or 128 + a slot for an
    upgrade card), charms after three fights, the nap, the elite's other door.
11. The reward screen: three cards (name, the slot's base, the item line, what it replaces) and
    one of three charms; the nap's two choices; the door choice before fight 10.
12. Memory: the item and charm text is the big new cost (34 items and 10 charms at about 40
    bytes = 1.8 KB, the enemy moves 49 x about 22 = 1.1 KB), with 12 new enemies' art. The
    language card had 203 bytes left at the shelving; this needs the overlays or aux copies
    plan.md already lists.

The bag proposal (kept to compare, `tools/sim/proposal_bag`) needs instead: per-fight offers,
a swap when the bag is full, type upgrades as run state, and the same enemy fields.

## Cut, and why

From the seed lists the coordinator passed on, and from the sim's own first cuts:

| cut | why |
|---|---|
| day and night items (Sun Drop, Moon Bowl at night, Sunbeam, Night Eyes) | the owner: zones are only art. The Moon Bowl stays as a plain star (+1 mana and shield) |
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
