# Faces: the big round (2026-11-02)

The owner's call: many more faces (an item on a die face; "faces" is the player word, charms stay
charms), built in one go after the disk catalog. This is the spec those jobs build from.

## Scale and text

- Our scale is Dog Witch x2 (docs/dogwitch-numbers.md): Catwiz 10 hp; plain wand hits 4, plain
  fluff shields 4, plain star makes 2 mana, mana stops at 5; a 3-mana book is about 12 to one
  enemy or 8 to all, a 2-mana book about 8. Levels add +2 (stars and curses +1).
- A face that scales starts below average and its levels feed the scaling (If It Fits: shield 3,
  +# a kitten, # 1 and +1 a level). A face's perk is its price: a special wand hits like a plain
  one, not three times as hard.
- Card lines: what it always does first, then any extra with its condition first; plain English,
  subject first, 35 columns a row, parts split by `|`; never "slot".

## Offers

- Five mixed faces a reward (it was three). No lean, no rarity tiers, no gates by fight (drop
  the `from` of every row to 1). Simulated: 69% of runs reach 3 faces of one domain, 31% after a
  pivot, about today's game with its 43 faces.
- Weights: most faces 3; the wild ones 1 (Jackpot, Hat Trick, Red Dot, Mana Battery, Double or
  Nothing, Times Two, Paw Flip, Spell Echo, All In). Charms the same way.
- Every domain about the same size (6-8 faces and charms). Kittens are 11 today: Kitten Cannon
  and Catnip count as generic tricks now, the rest stays.
- The reward screen shows five cards like the tray's, a card's lines when it is picked.
- The offer card shows the number with her levels in it ("hits 10: 6, +4 from your levels"): the
  owner did not know levels stay with the face.

## The faces

Numbers before levels. * needs new engine code; the rest are steps we have.

Simple (strong alone, for runs with no build):
1. Big Stick (wand): hits 6.
2. Thick Fur (fluff): shield 6.
3. Bright Star (star): makes 3 mana.
4. Hairball Blast (book, 2 mana): hits 9.
5. Glare (curse): its next turn's hits are 4 less.

Kittens. Have: Meowcronomicon, Feather Toy, Litter Star, If It Fits, Kitten Cannon, Cardboard Box,
Catnip, Mark Territory, Mother Cat, Kitten Mittens, Litter Box. Nothing new.

Three of a kind. Have: Twig Wand, the six fluffs, Purrfect Trio.
6. Claw Swipe (wand): hits 3. 3rd wand this turn: it hits 3 more times.
7. Star Cluster (star): 2 mana. 3rd star this turn: +2 re-rolls.
8. Triple Hex (curse): marked 1. 3rd curse this turn: every enemy is marked 2.
9. Echo (charm): her three-of-a-kind extras happen twice.

Fleas. Have: Fleas, Flea Circus.
10. Scratch the Itch (wand): hits 3, +1 for each flea on it.
11. Flea Collar (fluff): shield 4. Whoever hits her gets fleas 2.
12. Flea Market (star): 1 mana, +1 for each enemy with fleas.*
13. Plague (book, 2 mana): fleas 3 on every enemy.
14. Flea Comb (curse): doubles its fleas.
15. Itchy (charm): fleas bite twice a turn.*
16. Flea Farm (charm): each fight starts with fleas 2 on every enemy.

Wet. Have: Spray Bottle, Wet, Static Fur.
17. Puddle Splash (wand): hits 4, +4 if it is wet.
18. Moon Tide (star): 2 mana, +1 for each wet enemy.*
19. Rain Cloud (book, 2 mana): wets every enemy for 2 turns.
20. Thunder Purr (book, 3 mana): 6 to every enemy, 12 to wet ones.
21. Drenched (curse): wet 3 and marked 1.
22. Monsoon (charm): wet lasts twice as long.*

Shield. Have: Mirror Fur, Lucky Paw, Moon Bowl, Knead, Fluffy Tail.
23. Box Slam (wand): hits for her shield; the shield stays.
24. Puffed Up (fluff): doubles her shield, then +2.
25. Fortify (star): 1 mana, and shield equal to her mana.
26. Shield Bash (book, 2 mana): hits every enemy for half her shield.*
27. Hairball Wall (fluff): shield 4. Whoever hits her is tangled 1.
28. Stone Cat (trick): her next fluff x3.
29. Porcupine (charm): when her shield blocks a whole hit, the attacker takes 2.*
30. Thick Coat (charm): every fluff +1.

Life. Have: Warm Blanket, Nine Lives.
31. Love Bite (wand): hits 3, heal 2 if it lands.
32. Catnap (fluff): shield 4; if she has not re-rolled this turn, heal 3.
33. Purr (star): 1 mana and heal 1.
34. Blood Moon (book, no mana): costs 3 hp, hits 14.
35. Hiss (trick): costs 2 hp, her next die x2.
36. Leech (curse): for 3 turns, each hit she lands on it heals her 1.*
37. Last Stand (trick): her next die x3 if she is under 4 hp.*
38. Hunger (charm): each enemy she beats heals her 2.
39. Ninth Life (charm): +1 max hp after each elite.*

Spells and mana. Have: Star, Shooting Star, Wishing Star, Sunbeam, the books, Still Water, Grumpy
Face, Bad Milk.
40. Moonbeam (wand): hits 4, +1 mana if it beats it.*
41. Overflow (star): 3 mana; mana past 5 hits a random enemy 2 each.
42. Mana Burn (book, all her mana): hits 4 for each mana spent.
43. Mana Leech (curse): each hit on it this turn makes 1 mana.*
44. Spell Echo (trick): her next book is cast twice.*
45. Cheap Trick (charm): her first book each turn costs 1 less.*
46. Mana Battery (charm): mana holds up to 9.*

Dice. Have: Red Dot, Lucky Paw, Sunbeam, Scratch Post, Sixth Toe, Still Water.
47. Calm Paw (wand): hits 4, x2 if she has not re-rolled this turn.
48. Rattle (star): 1 mana and +1 re-roll.
49. Fresh Roll (book, 1 mana): every die she played comes back.
50. Paw Flip (trick): turn another die to a face she chooses.*
51. Nap Spot (charm): keep one die for next turn.*
52. Lucky Seven (charm): five different faces showing: +2 re-rolls.*

Chaos. Have: Laser Pointer, Catfight, Mimic, Knock It Off, 3 AM Screaming, Mouse on String.
53. Chain Bounce (wand): hits 4, then half as much to the next enemy, on down the line.*
54. Spook (curse): its next move is a shield instead of an attack.*
55. Hypnotize (curse): its next attack hits a random fighter, friends too.*
56. Catnip Bomb (curse): next turn it attacks everyone, itself too.*
57. Lullaby (book, 3 mana): it skips its next move; not the King.
58. Laser Show (book, 3 mana): every enemy attacks the enemy to its right this turn.*

Growth. Have: Scratching Habit.
59. Grudge (wand): hits 3, +2 for every time she was hit this fight.*
60. Snowball (book, 2 mana): hits 6; each Snowball after it this fight hits 4 more.*
61. Sharpen Claws (trick): every wand +1 for the rest of the fight; stacks.*

Gambles. Have: Double or Nothing.
62. Coin Flip (wand): hits 8, or hits her 4, half and half.*
63. All In (trick): every die left this turn x2, but no more re-rolls.*
64. Hat Trick (trick): plays a random face from the whole catalog.*
65. Cursed Coin (charm): roll 6 dice, but lose 1 hp each turn.*
66. Jackpot (charm): five matching faces wins the fight.*

## Engine additions

- Steps: count s (+1 for each enemy with status s), half, fell (the rest only when the last hit
  beat t), low k (the rest only when her hp is under k), coin (the rest half the time); a face
  that costs hp instead of mana.
- Hooks: an enemy that hits her gets a status (Flea Collar, Hairball Wall), her shield blocking a
  whole hit (Porcupine), hits she lands on a cursed enemy (Leech, Mana Leech). "When she is hit"
  and "when it dies" exist.
- Statuses: sharp, snowball, a hit count (Grudge), scared, hypnotized, berserk, leech, mana leech.
  Sleep is the existing skip-a-move status with a flag the King ignores.
- Rules: a book cast twice, all in, the mana cap from Mana Battery, the first book cheaper, fleas
  biting twice, max hp up, keeping a die, choosing a face (a pick-a-face step), Hat Trick playing a
  face straight from the catalog.

## Looks and sounds

One signature look and sound a domain, so a new face looks new without art of its own beyond its
card picture: fleas hopping target to target; rain over every enemy; lightning (the bolt with a
flash); a shield flung forward; a heart floating back to her; a mana swirl; a die shaking and
flipping in the tray; Zzz, a "!", a spiral, a spinning coin over enemies. Sounds: buzz, splash,
thunder, thump, a heal chime, a slurp, a dice rattle, a snore, a boing, a coin.

## Order

1. The disk catalog: every face's row, text, steps and picture on disk 2; memory holds only her six
   faces, her charms and the offer, so adding or cutting a face costs no memory and no repack.
2. The faces in batches by domain: steps, text, picture, look, sound, checked in a real fight;
   the C sim (tools/sim/c) taught the new faces to flag anything broken.
3. The owner plays; numbers by hand from there.
