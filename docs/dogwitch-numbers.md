# Dog Witch reference numbers

Pulled 2026-11-02 from Dog Witch's own data files (Unity asset bundles, read with UnityPy), as a
reference for balancing Catwiz. These are base values: an enemy's attack hits for its strength
(its attack ability shows `{strength}`); fights may scale them, and enemies grow through buffs.

## The dog

- Starting hp: 5 (the owner, from play).
- From the item text: a plain fluff gives shield 2; heals are 3 or 6; a typical damage item does 4.

## Enemies (base hp and strength)

| enemy | tier | hp | strength (hit) | curse resist | notes |
|---|---|---|---|---|---|
| Big Bwat | small | 1 | 4 | 1 |  |
| Bwat | small | 1 | 2 | 1 |  |
| Bad Bee | small | 2 | 2 | 1 |  |
| Skeleton | small | 2 | 2 | 1 | undying |
| Carrot | small | 3 | 1 | -1 | starts with shield 9 |
| Gummy Fish | small | 3 | 2 | 1 |  |
| Mummy | small | 3 | 2 | 2 |  |
| Tree Root | small | 3 | 2 | 1 |  |
| Musho | small | 4 | 2 | 2 |  |
| Eye | small | 5 | 1 | 1 |  |
| Snake Egg | small | 5 | 2 | -1 |  |
| Milk Carlton | normal | 6 | 2 | 3 |  |
| Zappy | normal | 7 | 2 | 3 |  |
| Snake Baby | normal | 8 | 1 | 1 |  |
| Swordy | normal | 9 | 3 | 3 |  |
| Bee Hive | normal | 10 | 2 | -1 |  |
| Bomp | normal | 10 | 3 | 3 |  |
| Beasty | normal | 11 | 2 | 3 |  |
| Leafy | normal | 11 | 1 | 3 |  |
| Russian Doll | normal | 11 | 2 | 4 |  |
| Russian Doll | normal | 12 | 2 | 4 |  |
| Vacuum | normal | 12 | 2 | 4 |  |
| Goblin Thief | normal | 13 | 3 | 3 |  |
| Russian Doll | normal | 13 | 2 | 4 |  |
| Shieldy | normal | 13 | 3 | 3 |  |
| Big Zappy | normal | 14 | 3 | 3 | lure |
| Russian Doll | normal | 14 | 2 | 4 |  |
| Cat Lady | normal | 15 | 3 | 4 |  |
| Snake Frog Guard | normal | 15 | 2 | 3 |  |
| Ghosty | normal | 16 | 1 | 3 | startsGhosted |
| Witch Sister | normal | 16 | 2 | 4 |  |
| F-Ball | normal | 17 | 2 | 4 | mask |
| Goblin Theif Leader | normal | 17 | 4 | 4 |  |
| Bomby | normal | 20 | 3 | 5 |  |
| F-Knight | normal | 20 | 3 | 5 | mask |
| Snake Frog King | normal | 20 | 3 | 5 |  |
| Snake Mama | normal | 20 | 2 | 5 |  |
| Tricycle | normal | 20 | 2 | 3 |  |
| Television | big | 22 | 2 | 3 | lure |
| Jack Rabbit | big | 25 | 2 | 4 |  |
| Moo Machine | big | 26 | 4 | 8 |  |
| Sphynx | big | 26 | 3 | 7 |  |
| Rock Golem | big | 28 | 3 | 8 |  |
| Big Bad Tree | big | 33 | 3 | 5 |  |
| Bwat Queen | big | 33 | 2 | 4 |  |
| Sheriff Bozo | big | 35 | 3 | 5 |  |
| Carrot Girl | big | 45 | 3 | 5 | starts with shield 9 |
| Crabba | big | 50 | 2 | 8 | spicy |
| Totem | big | 50 | 2 | 4 | startsInvisible |
| ManyEyes | boss | 92 | 3 | 8 |  |
| Cat | boss | 99 | 3 | 4 |  |
| Mad Master Wizard | boss | 100 | 4 | 5 | startsGhosted |

## How enemies grow

- Attacks hit for the enemy's strength, one target, a random target, or everyone.
- Buffs: +1 or +2 strength to itself, or to a friend when it dies.
- Poison: 1 or 2 on everyone.
- Stealing: a die or mana from the dog (some also buff or shield themselves); a stolen die comes back when the thief dies.

## Scale in short

| | Dog Witch | at 2x (the Catwiz target, 2026-11-02) |
|---|---|---|
| hero hp | 5 | 10 |
| enemy hit | 1-4 | 2-8 |
| plain shield | 2 | 4 |
| heal | 3-6 | 6-12 |
| normal enemy hp | 4-20 | 10-40 |
| big enemy hp | 25-50 | 50-100 |
| final boss hp | 100 | 200 |
