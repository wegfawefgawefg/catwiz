# The text pass (2026-11-04)

Every player line rewritten so it says who it is about, in plain word order. Card and charm
texts are in short card style ("3 mana: enemy sleeps 1 turn.", "Hit enemy for #.",
"Gain # shield."), as the owner asked mid-pass; log lines, prompts and the rules pages are
plain full sentences. No number, value or rule changed. In the tables " / " is a new row on
the screen (a `|` part in a face or charm text, 35 columns a row, 3 rows at most). Strings are
shown without their colour codes; a log line that starts with a space follows a name.

## How the text is shown

- A face: in a fight its name and prompt on row 0, its parts on rows 1-3 (the log's two rows
  while the die is picked). Between fights and on the kit page a one-part face gets the slot's
  base row ("Wand: # damage") first; three parts leave no room for "This replaces ..." or
  "You get +1 on ...", as Cardboard Box and Overflow already did. Mouse on String is three parts
  now, so its +1 card no longer says which face it lands on (the title says "+1 WAND").
- A charm: rows 1-3, then "A charm works all run." when a row is free.
- The log: one row, the name first; long enemy names were cut short before and still are.
- The card title row: "Tap again to take" (was "Again to take") starts at column 18 now (was
  22) so it fits after a 17-column name.

## What did not fit

- Resident text: main memory and the language card are full, and the text that lives in aux
  memory has about 205 bytes of room before the build drops the title's set-up overlay group
  (its code then goes resident and bank 1 grows from 15 to 20 functions, twice the crossings).
  The first wording added 270 bytes; trimmed to +106. Kept as they were to save room:
  "Mana is now #.", "Nothing to copy yet.", "There is nothing to mimic.", "Knead waits.",
  "Rolling", and the key legends "ESC, B or CLOSE: go back." and "Any key or CLOSE: go back.".
  Twelve enemy moves use "2 X of #" ("2 chomps of #") rather than "X twice for #" to stay
  short. The build is the same as before: the same code size, the same 15 functions in bank 1,
  the same six overlay groups and their sizes, the same loads (fight 1 up 424 frames after the
  title's key; the reward group 3,209 bytes, 27.6 frames), the same disk sectors.
- Triple Hex's record went past 256 bytes: its log lines are shorter ("Puffcap is marked +1.",
  "All enemies are marked!"), and Mark Territory and Drenched say the same line.
- Wet for 1 turn: "for # turns" reads "1 turns" at level 0, so the Wet curse says
  "Enemy is wet for # of its turns." and the log says "is wet and hits for half."
- The status names on the hp row ("Next +2", "Spooked -1", "Knead +4") are labels and stayed.

## Texts that were wrong about the card (fixed to match the code)

- RUBBER DUCK: "Your ward blocks a curse: shield 2." Any ward blocking any curse sets it off,
  an enemy's ward blocking your curse too (content/play curse calls the charm hook for every
  ward). Now "When any ward blocks a curse, gain 2 shield."
- GRUMPY FACE: "A hit that hurts you: +1 mana." Any hp you lose sets it off (fleas, Blood Moon,
  Hiss, a lost bet), not only hits. Now "Losing hp gives you 1 mana."
- MOUSE ON STRING: "then # to the next enemy" — with one enemy standing the same enemy takes
  both hits (next_standing goes round to itself). Now says so.
- The kit page's star row said "Mana # of 5", wrong with a Mana Battery (9). Now "Mana #."
- The first-turn hint "A hairball: re-roll it to cough it up." was 38 columns and was cut off
  on screen. Now "Re-roll a hairball to cough it up."
- LITTER BOX keeps half the kittens rounded up; the text says "(rounded up)" now.

Screenshots of the tightest screens: shots/textpass/ (a three-row face in a fight, a three-row
curse, the kit page's face and charm, the log, the reward prompt and two cards, the first fight).
The charm pick after an elite was not shot: a WIN_AT_ONCE test build starting at fight 3 went
from the card straight to the next fight, and that was not looked into.

# Every changed line

## game/content/faces_wand.tsp (22)

| Before | After |
|---|---|
| Hits #. / 3rd wand this turn: it hits all. | Hit enemy for #. / 3rd wand in a turn also hits all / other enemies for #. |
| Third in a turn: it hits all! | Your third wand hits every enemy! |
| Hits #. / If it stands: its hits are 1 less. | Hit enemy for #. / Enemy hits 1 less next turn. |
| Hits #. / If it stands: it hits half, 1 turn. | Hit enemy for #. / Enemy hits half next turn. |
| Hits #, then kittens pounce on it. | Hit enemy for #. / Your kittens pounce on enemy. |
| Hits #. Goes through any shield. | Hit enemy for #, ignoring shield. |
| Hits #, then # to the next enemy. | Hit enemy for #. / Then hit the next enemy for #. / A lone enemy takes both hits. |
| Fires all your kittens: # each. | Each kitten hits enemy for #. / All your kittens fire and are gone. |
| # kittens launched! | You fire # kittens! |
| Hits #. Each use adds # more / for the rest of the fight. | Hit enemy for #. / Then this wand hits # more for / the rest of the fight. |
| Hits #. | Hit enemy for #. |
| Hits #. / 3rd wand this turn: 3 more hits. | Hit enemy for #. / 3rd wand in a turn also hits / 3 more times for # each. |
| Third in a turn: three more! | Third wand! You hit 3 more times. |
| Hits #, +1 for each flea on it. | Hit enemy for #. / Each flea on enemy adds 1. |
| Hits #. / If it is wet: 4 more. | Hit enemy for #. / Wet enemy takes 4 more. |
| Hits as much as your shield, +#. / Your shield stays. | Hit enemy for # plus your shield. / You keep your shield. |
| Hits #. / If it hurts it: you heal 2. | Hit enemy for #. / If enemy loses hp, you heal 2. |
| Hits #. / If it beats it: +1 mana. | Hit enemy for #. / If enemy falls, gain 1 mana. |
| Hits #. / No re-roll this turn: twice that. | Hit enemy for #, or double if you / have not re-rolled this turn. |
| Hits #, then half that to each / other enemy, halving each time. | Hit enemy for #. / Each other enemy then takes half / the hit before, left to right. |
| Hits #, +2 for each time you were / hurt this fight. | Hit enemy for #, +2 for each time / you were hurt this fight. |
| Heads: hits #. / Tails: it hits you half that. | Heads: hit enemy for #. / Tails: you take half of #. |

## game/content/faces_fluff.tsp (20)

| Before | After |
|---|---|
| Shield #. / 3rd fluff this turn: shield stays. | Gain # shield. / 3rd fluff in a turn keeps your / shield into your next turn. |
| Third in a turn: shield stays on. | Your shield stays for next turn. |
| Shield #. / 3rd fluff this turn: hitters take 4 | Gain # shield. / 3rd fluff in a turn makes enemies / that hit you take 4. |
| Third in a turn: spiky! # back. | Spiky! Enemies that hit you take #. |
| Shield #. / 3rd fluff this turn: +1 kitten, / and attacks on all miss you. | Gain # shield. 3rd fluff in a turn / gives 1 kitten, and attacks that / hit everyone miss you. |
| Third in a turn: a box, a kitten. | You hide in a box with a kitten. |
| Shield #. / 3rd fluff this turn: heal 6. | Gain # shield. / 3rd fluff in a turn heals you 6. |
| Third in a turn: warm, heal 6. | Third fluff! The blanket is warm. |
| Shield #. / 3rd fluff this turn: 6 to all, / or 12 to an enemy that is wet. | Gain # shield. / 3rd fluff in a turn hits every / enemy for 6, a wet enemy for 12. |
| Third in a turn: static! | Static! Your fur zaps every enemy. |
| Shield #. / 3rd fluff this turn: block 2 curses | Gain # shield. / 3rd fluff in a turn blocks the next / 2 curses on you. |
| Third in a turn: a curse blocker. | The bell blocks the next 2 curses. |
| Shield #. / Blocked hits bounce back: # most. | Gain # shield. / Damage your shield blocks goes back / to the attacker, # at most. |
| Shield #. You get a free re-roll. | Gain # shield and 1 re-roll. |
| Shield #. | Gain # shield. |
| Shield #. / Who hits you gets fleas 2 a turn. | Gain # shield. / Enemies that hit you get 2 fleas. |
| Doubles your shield, then +#. | Double your shield, then add #. |
| has shield #. | now has # shield. |
| Shield #. / Who hits you hits 1 less next turn. | Gain # shield. / Enemies that hit you hit 1 less / the turn after. |
| Shield #. / No re-roll this turn: you heal 3. | Gain # shield. / Heal 3 if you have not re-rolled / this turn. |

## game/content/faces_star.tsp (17)

| Before | After |
|---|---|
| Makes # mana. | Gain # mana. |
| Makes 1 mana, and hits an enemy #. | Hit enemy for # and gain 1 mana. |
| Makes 1 mana, and shield #. | Gain # shield and 1 mana. |
| shields #, +1 mana. | gets # shield and 1 mana. |
| Makes # mana; next wand hits x2. | Gain # mana. / Your next wand hits double. |
| A wish: the next wand x2. | Wish! Your next wand hits double. |
| Makes # mana. / Each kitten you have adds 1 more. | Gain # mana, +1 for each kitten. |
| Makes # mana. / Mana past 5: re-rolls, 2 at most. | Gain # mana. / Mana past your most becomes / re-rolls, 2 at most. |
| Makes # mana. | Gain # mana. |
| Makes # mana. / 3rd star this turn: +2 re-rolls. | Gain # mana. / 3rd star in a turn adds 2 re-rolls. |
| Third in a turn: +2 re-rolls. | Third star! You get 2 re-rolls. |
| Makes # mana. / 1 more for each enemy with fleas. | Gain # mana. / Each enemy with fleas adds 1. |
| Makes # mana. / 1 more for each wet enemy. | Gain # mana, +1 per wet enemy. |
| Makes # mana, then shield as much / as your mana. | Gain # mana, then 1 shield per / mana you have. |
| Makes # mana, and you heal 1. | Gain # mana and heal 1. |
| Makes # mana. / Past your most: 2 to a random enemy / for each. | Gain # mana. / Each mana past your most hits a / random enemy for 2. |
| Makes # mana, and +1 re-roll. | Gain # mana and 1 re-roll. |

## game/content/faces_book.tsp (20)

| Before | After |
|---|---|
| 2 mana: 5 hits of #, left to right | 2 mana: hit 5 times for # each, / enemy after enemy, left to right. |
| 3 mana: # to every enemy. / Their next hit goes to a friend. | 3 mana: hit all enemies for #. / Each enemy's next hit lands on / another enemy. |
| 3 mana: # to all foes, 1 to you. | 3 mana: hit all enemies for #. / You lose 1 hp. |
| 3 mana: hits #. / Its shield and boosts go first. | 3 mana: hit enemy for #. / Enemy's shield and boosts go first. |
| drops its shield and buffs. | loses shield and boosts. |
| 2 mana: shield 3, and # more / for each kitten you have. | 2 mana: gain 3 shield, and # more / for each kitten you have. |
| 2 mana: use its next move # times. | 2 mana: copy enemy's move # times. |
| 2 mana: hits #. | 2 mana: hit enemy for #. |
| 2 mana: fleas # on every enemy. | 2 mana: all enemies get # fleas. |
| 2 mana: wets every enemy, # turns. | 2 mana: wet all enemies # turns. / Wet enemies hit for half. |
| 3 mana: # to every enemy, / twice that to a wet one. | 3 mana: hit all enemies for #. / Wet enemies take double. |
| 2 mana: every enemy takes half / your shield, +#. | 2 mana: hit all enemies for # plus / half your shield. |
| Costs 3 hp, no mana: hits #. | 3 hp, no mana: hit enemy for #. |
| All your mana: hits # for each. | Hit enemy for # per mana you have. / Spend all your mana, 1 at least. |
| 1 mana: your played dice come back. | 1 mana: all your dice come back, / even played ones, and roll again. |
| Fresh roll: the dice come back. | Fresh roll! Your dice come back. |
| 3 mana: it skips its next move. / The Bulldog King stays awake. | 3 mana: enemy sleeps 1 turn. / The Bulldog King stays awake. |
| 3 mana: each enemy's next hit / goes to the friend on its right. | 3 mana: each enemy's next hit / lands on the enemy to its right. |
| Laser show! They turn on friends. | Laser show! Enemies hit each other. |
| 2 mana: hits #. / Each one after it this fight: +4. | 2 mana: hit enemy for #. / Each snowball this fight makes / later snowballs hit 4 more. |

## game/content/faces_curse.tsp (27)

| Before | After |
|---|---|
| Fleas bite it # a turn, 3 turns. | Enemy gets # fleas for 3 turns. / Each flea bites 1 a turn. |
| Its hits are halved for # turns. | Enemy is wet for # of its turns. / Wet enemies hit for half. |
| Its next turn's hits are # less. | Enemy hits # less next turn. |
| Every hit on it does # more. / Your kittens go for it first. | Hits on enemy do # more. / Your kittens go for enemy first. / The mark lasts all fight. |
| is marked: hits +#. | is marked +#. |
| Puts # red dots on it. / A wand hit on it brings dice back. | Enemy gets # red dots. / A wand hit on enemy uses a dot and / brings all your dice back. |
| has a red dot: # times. | has # red dots. |
| Its next hit goes to a friend, +#. | Enemy's next hit is # harder and / lands on another enemy. |
| wants a catfight: +#. | will hit a friend # harder. |
| Fleas # on it and a random other. | Enemy gets # fleas, and so does a / random other enemy. |
| gets a flea circus: #. | gets # circus fleas. |
| gets a flea circus: #. | gets # circus fleas. |
| Its next turn's hits are # less. | Enemy hits # less next turn. |
| Every hit on it does # more. / 3rd curse this turn: all get +2. | Hits on enemy do # more. / 3rd curse in a turn also marks / all enemies, 2 more each. |
| is marked: hits +#. | is marked +#. |
| Third in a turn: all marked! | All enemies are marked! |
| Its fleas bite x# as hard. | Enemy's fleas multiply by #. |
| It is wet for # turns, / and marked: hits on it +1. | Enemy is wet for # turns. / Wet enemies hit for half. / Hits on enemy do 1 more. |
| is marked: hits +#. | is marked +#. |
| Each hit you land on it heals you / 1, for # turns. | For # turns, each hit you land on / enemy heals you 1. |
| is leeched: # turns. | has a leech for # turns. |
| Each hit on it this turn makes / # mana. | Gain # mana for each hit you land / on enemy this turn. |
| is a mana leech: # a hit. | gives you # mana a hit. |
| Its next attack is a shield of / its number instead. | Enemy's next attack becomes a / shield of the same number. |
| is scared: it will hide. | is scared and will hide. |
| Its next attack hits a fighter at / random, its friends too. | Enemy's next attack hits anyone at / random, you or another enemy. |
| Its next attack hits everyone, / itself too. | Enemy's next attack hits everyone, / the enemy too. |

## game/content/faces_trick.tsp (23)

| Before | After |
|---|---|
| Your next die's number is +#. | Your next die gets +#. |
| Your next die's number is x#. | Your next die gets x#. |
| Times: the next die x#. | Your next die gets x#. |
| Plays your last die again, # more. | Play your last die again, with +#. |
| Next # dice +1. / Kittens pounce twice this turn. | Your next # dice get +1. / Kittens pounce twice this turn. |
| Catnip! The next # dice +1. | Catnip! Your next # dice get +1. |
| Next fluff x2, and next wand +#. | Your next wand gets +#, and your / next fluff gets x2. |
| Knead: next fluff x2, wand +#. | Kneading! Your next wand gets +#. |
| Next die's number x#. / If no die uses it: you lose # hp. | Your next die gets x#. / If no die uses the x# this turn, / you lose # hp. |
| Your next fluff is x#. | Your next fluff gets x#. |
| Stone cat: the next fluff x#. | Your next fluff gets x#. |
| Costs 2 hp: your next die is x#. | Lose 2 hp. Your next die gets x#. |
| Hiss! The next die x#. | Hiss! Your next die gets x#. |
| Under 4 hp: your next die is x#. | Your next die gets x# if you have / under 4 hp. |
| Last stand: the next die x#. | Last stand! Your next die gets x#. |
| Your next book goes twice. | Your next book will cast twice. |
| Turns a die to the face you pick: / pick it, then again to turn it. | Pick a die, then pick it again to / turn the die one face each time. |
| Pick a die, again to turn it. | Pick a die again to turn its face. |
| Every wand +# for the rest of the / fight. | Your wands hit # more this fight. |
| Sharp claws: wands +# this fight. | Your wands now hit # more. |
| Every die left this turn is x#, / but no more re-rolls. | Your other dice get x# this turn, / but you lose all your re-rolls. |
| All in: every die x# this turn! | All in! Your dice get x# this turn. |
| Plays a face drawn from all the / faces there are, at your levels. | Play a random face from all faces / in the game, at your levels. |

## game/content/faces.tsp (1)

| Before | After |
|---|---|
| A dud. Re-roll it to cough it up. | Hairball does nothing. / Re-roll to cough up the hairball. |

## game/content/charm_rows.tsp (23)

| Before | After |
|---|---|
| One more re-roll each turn. | 1 more re-roll each turn. |
| Roll 6 dice, but 1 re-roll less. | Roll 6 dice, but 1 fewer re-roll / each turn. |
| A turn with no re-roll: +2 mana. | No re-roll in a turn gives 2 mana. |
| Each three of a kind: 2 to all. | Each three of a kind hits all / enemies for 2. |
| Each fight starts with a kitten. | Start each fight with a kitten. |
| Shield halves each turn, not gone. | Your shield halves each turn / instead of going away. |
| A hit that hurts you: +1 mana. | Losing hp gives you 1 mana. |
| Your ward blocks a curse: shield 2. | When any ward blocks a curse, gain / 2 shield. |
| Half your kittens carry over. | Half your kittens (rounded up) stay / for the next fight. |
| Each three of a kind's extra / happens twice. | Three of a kind extras work twice. |
| Each fight starts with fleas # / on every enemy. | Each fight, all enemies start with / # fleas. |
| Your shield takes all of a hit: / the hitter takes #. | When your shield takes a whole hit, / the attacker takes #. |
| Every fluff shields # more. | Your fluffs give # more shield. |
| After each elite: +# max hp. | Each elite you beat adds # max hp. |
| First book each turn: # less mana. | Your first book each turn costs # / less mana. |
| Five different faces showing: / +2 re-rolls. | If your dice show 5 different / faces, gain 2 re-rolls. |
| Wet enemies take # more from every / hit. | Wet enemies take # more per hit. |
| Each fight starts with every enemy / wet for # turn. | Each fight, all enemies start wet / for # turn. |
| An enemy's hit on its friend is / doubled. | An enemy's hit on another enemy is / doubled. |
| Each fight starts with an enemy / hypnotized, picked at random. | Each fight, a random enemy starts / hypnotized. That enemy's next / attack hits anyone at random. |
| Each turn: shield 1 for each time / you were hurt this fight. | Each turn, gain 1 shield for each / time you were hurt this fight. |
| First turn of a fight: +# re-roll. | # more re-roll on the first turn / of each fight. |
| Each fight starts with # mana. | Start each fight with # mana. |

## game/content/moves.tsp (38)

| Before | After |
|---|---|
| Cheer: friend +# next | Cheers a friend +# |
| Guards a friend: # | Shields a friend # |
| Beep. Bumps in 2 | Bumps in 2 turns |
| Beep beep. In 1 | Bumps next turn |
| Bumps # twice | 2 bumps of # |
| Hairball: your fluff | Clogs your fluff face |
| Spooks: dice -# next | Spooks your dice -# |
| Waters friends +# | Waters friends +# hp |
| Sucks # twice | Sucks twice for # |
| Sucks # twice | Sucks twice for # |
| Revs up: +# for good | Revs up, +# strength |
| Mows # twice | Mows twice for # |
| Parcels # twice | 2 parcels of # |
| Heavy parcel # twice | 2 heavy parcels of # |
| Grumpier: +# for good | Grumps, +# strength |
| Needle: fleas # | Gives you # fleas |
| Thermometer # twice | 2 thermometers of # |
| Checkup # twice | 2 checkups of # |
| Snaps gloves: +# good | Gloves on, +# strength |
| Injection # twice | 2 injections of # |
| Rinse: you get wet | Rinse makes you wet |
| Splash # twice | 2 splashes of # |
| Scrub # twice | 2 scrubs of # |
| Glug glug # twice | Glugs twice for # |
| Gurgles: +# for good | Gurgles, +# strength |
| Royal bite # twice | 2 royal bites of # |
| Chomp # twice | 2 chomps of # |
| Royal swat # twice | 2 royal swats of # |
| Slobber # twice | 2 slobbers of # |
| Chomp # twice | 2 chomps of # |
| Decree: +# for good | Decrees +# strength |
| Paw swipe # twice | 2 paw swipes of # |
| Flails # twice | Flails twice for # |
| Belly flop # twice | 2 belly flops of # |
| Growl: +# for good | Growls, +# strength |
| Cheer: king +# next | Cheers the king +# |
| Cap slam # twice | 2 cap slams of # |
| Spore storm # twice | 2 spore storms of # |

## game/content/effects_said.tsp (11)

| Before | After |
|---|---|
| The next die gets +#. | Your next die gets +#. |
| shields #. | gets # shield. |
| Kittens join you: # now. | Kittens join! You have # now. |
| : ward broken, no curse. | 's ward blocks the curse. |
| gets fleas: # a turn. | has # fleas now. |
| is wet: half hits, # turns. | is wet and hits for half. |
| is spooked: dice -#. | is spooked. Dice get -#. |
| is tangled: hits -#. | hits # less next turn. |
| loses the bet: # hp. | loses the bet and # hp. |
| gets spiky: # back. | is spiky. Attackers take #. |
| is tangled next turn: -#. | will hit # less next turn. |

## game/content/foes.tsp (5)

| Before | After |
|---|---|
| It misses the box. | The attack misses the box. |
| shields #. | gets # shield. |
| grabs a die: beat it back. | grabs one of your dice. |
| A hairball clogs a face. Re-roll! | A hairball clogs one of your faces. |
| Finds its feet | Skips a turn |

## game/battle/card_words.tsp (4)

| Before | After |
|---|---|
| Curse: on an enemy | Curse: goes on an enemy |
| Trick: for the next dice | Trick: helps the next dice |
| Again to take | Tap again to take |
| Your levels stay: +# in its number. | Your levels add +# to this face. |

## game/battle/reward.tsp (9)

| Before | After |
|---|---|
| A reward: pick a card, S to skip. | Pick a reward card, or S to skip. |
| Five faces. Tap one to read it. | Tap a card once to read it. |
| A charm: pick one, or S to skip. | Pick a charm, or S to skip. |
| A rest: Catwiz heals to full. | Catwiz rests and heals to full. |
| Two doors. Pick one (1-2). | Pick one of the two doors (1-2). |
| is at its most. | is at its highest level. |
| +1 on the face:  | You get +1 on  |
| You have it: +1 on  | You have this. +1 on  |
| Replaces:  | This replaces  |

## game/battle/words.tsp (5)

| Before | After |
|---|---|
| Needs more mana | Not enough mana |
| Again: hits all | Tap again for all |
| Again: on you | Tap again for you |
| Their turn | Enemies' turn |
| Beat it and the die comes back. | Beat the enemy to get the die back. |

## game/battle/turn.tsp (8)

| Before | After |
|---|---|
| E ends turn. B kit, ? rules, H log. | E ends the turn. ? shows the rules. |
| Your turn: pick a die (1-5). | Your turn. Pick a die (1-5). |
| R re-roll or E end turn. | R re-rolls. E ends the turn. |
| No playable dice. | No die can be played. |
| A hairball: re-roll it to cough it up. | Re-roll a hairball to cough it up. |
| Stars fill your mana; spells spend. | Stars make mana. Books spend it. |
| Jackpot! Five alike win the fight! | Jackpot! Five matching faces win! |
| Lucky seven: +# re-rolls. | Lucky seven! +# re-rolls. |

## game/battle/bag.tsp (19)

| Before | After |
|---|---|
| HER KIT | CATWIZ'S KIT |
| Her charms, all run (7-9): | Your charms last all run (7-9): |
| Her six faces (1-6): | Your six faces (1-6): |
| Pick a face or a charm to read it: | Pick a face or a charm to read it. |
| 1-6 a face, 7-9 a charm, or arrows. | Use 1-6, 7-9 or the arrows. |
| A hairball clogs it.  | This face has a hairball.  |
| An enemy holds one.  | An enemy holds a die.  |
| To a 3: # this turn.  | Three of a kind #/3.  |
| +# on the next die.  | Your next die gets +#.  |
| x# on the next die.  | Your next die gets x#.  |
| +1 on the next # dice.  | Your next # dice get +1.  |
| Mana # of 5.  | Mana #.  |
| it costs #.  | cost #.  |
| Nothing on it this turn. | Nothing to show this turn. |
| She has # of them. | You have # of these. |
| Her charms: | Your charms: |
| Her six faces at the end: | Your six faces at the end: |
| Ten fights won: the woods, the | You won all ten fights, in the |
| garden, the house and the King. | woods, the garden and the house. |

## game/battle/rules.tsp (2)

| Before | After |
|---|---|
| Arrows, BACK, NEXT: turn the page. | Arrows, BACK or NEXT turn the page. |
| ESC, ? or CLOSE: back to the fight. | Press ESC, ? or CLOSE to go back. |

## game/battle/dice.tsp (1)

| Before | After |
|---|---|
| Hack! A hairball coughed up. | Hack! You cough up the hairball. |

## game/battle/hit.tsp (1)

| Before | After |
|---|---|
| 's shield takes it all. | 's shield blocks the hit. |

## game/content/rules.tsp (11)

| Before | After |
|---|---|
| If her hit points (hp) reach 0, | If Catwiz runs out of hit points |
| the run is over. | (hp), the run is over. |
| FLEAS N: N damage at the end of | FLEAS N: the fighter takes N at the |
| each of its turns, for 3 turns. | end of each of its turns, 3 turns. |
| MIRROR N: damage her shield blocks | MIRROR N: damage Catwiz's shield |
| goes back to the attacker, N at | blocks goes back to the attacker, |
| most, until her next turn. | N at most, until her next turn. |
| her, until her next turn. | Catwiz until her next turn. |
| HABIT N: her Scratching Habit hits | HABIT N: Scratching Habit hits N |
| N harder for the rest of the fight. | harder for the rest of the fight. |
| SPIKY N: who hits her takes N. | SPIKY N: who hits Catwiz takes N. |
