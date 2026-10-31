# Plan

Catwiz: an Apple II double hi-res dice roguelike in Tisple ][, to prove the compiler and an
engine. Shelved 2026-10-30 with two of ten fights, then ported to double hi-res with the day
art (branch dhgr-port, 2026-10-30). Owner: an homage in the genre, not a remake; no
text or data from any other game; the content can be replaced by much stranger stuff later.

## Where it stands

`tisple build` builds `build/catwiz.dsk` from `game/` (Tisple main; settings in
`tisple.project`).

1. Boot: LOADING, then by frame 600 the title in double hi-res: CATWIZ in white with a rim
   that glows (magenta, orange, yellow, orange), the cat against a big white moon on a night
   page, "a dice battle in the woods", PRESS RETURN. One packed picture and the rim's four
   colours as sprites.
2. A run (the owner, 2026-10-31): ten fights, 3-3-3-1: the woods (1-3, an elite at 3), the
   garden (4-6, the mailman at 6), the yard (7-9, the two doors at 9: the vet or the big bath),
   then the Bulldog King. All at night; the zones are places now. Fight 1 in the clearing
   (puffcap, sporelet), what comes between fights, fight 2 on the path (puffcap, sporelet,
   nightflap), then "to be continued" and the title. Hit points and her kit carry between
   fights; losing ends the run. Fights 3-10 are in the content as data (stand-ins laid out to the
   new shape until the sim's tables come: the woods' elite is the OLD GNOME, a garden gnome with
   24 hit points) and play in test builds on fight 1-2's screens with stand-in figures
   (`battle/battle.tsp`'s test constants); the run stops after fight 2 until their art.
3. Rules: the item-slot model (2026-10-31; docs/balance.md, the proposal; the balance sim's
   rules, `tools/sim/items.py` and `rules.py`):
   - Catwiz has 30 HP and rolls five identical dice; each die's six faces are her six item slots
     (wand, fluff, star, book, curse, trick), and the item in a slot decides what its face does
     (`content/items.tsp`, 33 items and the hairball). She starts with Twig Wand, Fluff, Star,
     Zoomies, Fleas, Plus One. Two re-rolls a turn of the unplayed dice. A face's number is its
     item's amount, a step more for each level on its slot (two at most), then the boosts in
     the sim's order (a times, a plus, catnip, knead, bad milk, a wish, a spook). The third face
     of a slot in a turn sets off its item's combo; a times counts its number towards it. A book
     with too little mana gives 1 mana. Kittens pounce at the end of her turn and one runs off
     when she is hurt.
   - Enemies show their next move and act in order from the first, round and round
     (`content/moves.tsp`). Summons fill empty spots, an enemy with a next form gets up as it,
     both a round later; a squirrel or the vet holds the die played last till it is beaten; a
     hairball clogs a slot on every die till a re-roll of a die showing it; the lawnmower stalls
     after losing 12 in a turn.
   - Between fights (`battle/reward.tsp`): one of three cards drawn at random from one weighted
     pool of every item and slot upgrade (`content/encounters.tsp` OFFER_CARDS: a card, its
     weight, the first fight it comes after; `battle/offer.tsp`): an item for a slot, the old one
     going, or a level on a slot; the item you hold is a level; three different, no level on a
     slot at its most. After each elite (3, 6, 9), in order: the card, one of three charms drawn
     the same way (OFFER_CHARMS, ones she does not hold), then the nap (`NAP_HEAL_SHIFT`: all the
     hit points she is missing by default, the sim may make it half) or a bonus upgrade (a level
     on a slot of her choice). Before fight 9 two doors (the vet or the big bath). Every weight
     is 1 and everything comes from fight 1 until the sim's tuned weights drop in.
   - M meows: a sound, a hop and the happy face; no effect on the fight.
4. Controls: 1-5 pick a die (1-6 with the sixth toe; its text shows at the bottom, arrows show
   who it goes to); Z X C (or the arrows and RETURN) play it on an enemy; the same number again
   plays a die for the hero or for every enemy, and lets go of one for a single enemy; M (the
   cat) plays a die for the hero, else meows. ESC lets go, R re-rolls, E ends the turn; the turn
   ends by itself a beat after the last die is played, or when none can be played and no
   re-roll is left ("No playable dice."; with re-rolls left the log says "R re-roll or E end
   turn."). Between fights the choices are cards in the tray: 1-3 (1-2, or 1-6 for a dream's
   slot) picks one and shows it, the same key again or RETURN takes it, ESC lets go. Any key
   starts the title and leaves the run's end. Everything is also a tap or a click on the screen:
   `tools/phone/catwiz.json` has the tap boxes (the six cards, BAG and ?, the re-roll button
   and the stars, END TURN, the enemies, the cat, the rest of the stage as `.`, then the whole
   screen as ESC) for Tisple's web player
   and `tisple machine --taps`, the web player's portrait pad (BAG, RULES, MEOW, LET GO; <, RE-ROLL, END TURN, >; ENEMY 1-3; DIE 1-6), and `"look": "ntsc"`:
   the player starts in the TV look. One-time hints in the log (once a boot): the first turn
   (the keys, and B and ? for the pages), the first mana.
   - Her kit (B, the BAG button by the re-roll button, BAG on the pad): a page over the stage
     with her six slots as cards in the tray's places (a pip a level) and her charms on the stage
     (each where the cat's or an enemy's tap box is); 1-6 a slot, 7-9 a charm, M Z X C (taps on
     the charms), the arrows (< > on the pad) step; the text shows its name and level, the slot's
     base, the item's line, what it has going this fight. ESC, B, CLOSE (the re-roll and END
     TURN boxes) or a tap on the empty stage closes.
   - The rules (?, the ? button, RULES on the pad): ten pages read from the disk; LEFT/RIGHT,
     1-3 (BACK) and 4-6 (NEXT), a tap on the stage or space turn them; ESC, ? or CLOSE closes.
   - A tap on the stage where nobody stands is `.`: it lets go of a die, as ESC does.
5. Screen: double hi-res, all graphics: the stage (rows 0-117 and a black gutter), the tray
   (rows 118-159), four lines of 35-column text drawn into the picture (rows 160-191): the pick
   (the item's name, its base or how to play it, its line) or the target (name, hit points,
   statuses, next move), then a log of what happened. A black pill badge under each actor (a
   heart and its hit points, then its statuses as glyphs: the kittens a kitten's head) and over
   each enemy (its next move: a sword and how much, a shield, a cheer, a Z when it skips...).
   The tray: a tilted white card for each die with its item's picture and number, the picked one
   lifted with a yellow bar; a sixth die's card where the buttons were; right of the cards the
   re-roll button (a die and X and the re-rolls left), BAG and ?, five mana stars, END TURN.
   The map of the run at the top of the stage (the place, its three fights, the elite's mark
   bigger, the one she is on lit, the king's crown), drawn once a fight. Between fights
   the tray holds the choices and the stage her six slots (a picture and a pip a level each, the
   slot a choice changes framed in yellow, showing the change). Sprites in the night's light,
   solid on a black stage.
6. Sound: Mockingboard music and effects in any slot; speaker effects and the title jingle
   without one.
7. Memory (2026-10-31, the kit round): main memory and the language card full, built at
   squeeze 10 with 2.3 KB in the card's bank 1; lib/disk's reader in `$1400-$1BFF`; the art and
   the rules' text on the disk; the moves, enemies, fights, charms, offers and the code's
   sentences in aux memory; aux 7.5 KB left (`$A275-$BFFF`); the disk at its 10 segments
   (AGENTS.md, Memory).
8. Speed: waiting for a key a pass is a frame; a pick shows in 3 frames; a turn of fight 1
   (passlog SEED=5) takes the frames it took before the kit round. Loading is slower: the title
   at frame 770, a fight's art 3.2 s from the key (the runs come off the disk). The rules page
   0.9 s (a page turn 0.7 s), the kit page 1.0 s, closing either 1.2 s (AGENTS.md, Memory).

## Open

1. Fights 3-11's nights: each fight's night in `tools/dhgr/night.py` outside its lanes
   (`lanes.py`: add the fight's spots), and the final fight (the bulldog king, to draw in double
   hi-res). The game is midnight throughout now: the
   day and dusk zones are not planned any more.
2. The sprites do not fit (2026-10-31, `art/dhgr/memory.txt`): solid frames and the four flash
   frames put fight 1 at 22,977 bytes and fight 2 at 27,597 against 21,744 of room (the aux
   language card and `sprite_aux`). Ways: a fill run in lib/dhgr's runs (n copies of a byte:
   the black margins and the flash's white; about 5 KB off fight 2's fighters), a bigger
   `sprite_aux` (aux has 3.7 KB left, and the night backdrops pack smaller), the cat's ears
   frame left out while nothing shows the surprised mood (2,448 bytes), a flash only for the
   enemies.
3. Per-fight art from disk: in (2026-10-31): each screen's picture and runs are one disk table
   each (`art/screen_*`, `draw/packs`, written by `tools/dhgr/game.py`); fights 3-10 need their
   own screens there (a picture and the kinds they use) and `draw/stage.tsp` to pick them by
   fight. Loading got 1.2 s slower; reading a screen's runs while the reward screen shows would
   hide it (page 1 is the read buffer today, so that needs another).
4. Speed in actions (about 5 frames a pass): a sprite drawn again costs a restore of its box and
   its runs (the cat about 110,000 cycles). Ideas: a runs pass over the backdrop for a moving
   sprite (restore and draw in one; lib/dhgr's kit has a byte left and no zero page, so it
   needs room there), clipping a redraw's first rows too (bottom clipping is in), the nightflap
   flapping less often.
5. Mouse support: the Apple mouse card (Tisple's machine has one, `--mouse`) for picking dice
   and enemies on a real IIe; today clicks work through the web player and `--taps`.
6. Fights 3-11's art: twelve new enemies (the stand-ins are the puffcap's and sporelet's
   figures, `content/enemies.tsp`), their nights and lanes, and their spots in
   `content/encounters.tsp` laid out for them; with Open 3 the run goes on past fight 2
   (`battle/battle.tsp` STOP_STAGE).
7. Room: the build is at squeeze 10 with code in bank 1 again (2026-10-31). Aux memory has 7.5
   KB left: the items table (442 bytes, read by name all over) or more code strings could move
   there to take the build back towards squeeze 8. A squeezed pass costs about 2% more flat out,
   kept even by writing the per-pass code out by hand (the tray's lift, the looks).
8. The sim's tables: `OFFER_CARDS`, `OFFER_CHARMS` (weights, first fights), `NAP_HEAL_SHIFT`
   and the fights of the new shape (the woods' elite is a stand-in) come from tools/sim as
   data. The rules page says no numbers that the sim may change (the nap's hit points).
9. Text drawing is the pages' cost (about 2 frames a line in the 35-column font): the rules
   page, and closing a page (the tray and every look drawn again).

Smaller:

- Play it on a real IIe (FloppyEmu or ADTPro) and a real Mockingboard; balance the mix by ear.
- The tray is drawn in Tisple (about 2,500 cycles a group of pixels a row); the roll's redraw of
  all five faces takes a few frames.
- The balance doc's next tunings (docs/balance.md: the kitten axis, the cards that lose to a
  clear favourite, steadier elites) are content changes in `game/content`.

## Art rules

Double hi-res, `tools/dhgr/` (AGENTS.md, Art). Midnight (2026-10-31): the whole game is night,
the fighters solid frames on pure black. The lane rule: every pixel a battle look can cover is
black in the backdrop (`lanes.py` works them out from the game's numbers; `make.py lanes`
checks); the scenery only outside them, a thin frame. One sprite set lit by palette swap and
rims, the rims round the whole figure on black; NTSC (the TV look) the real target, the flat
colour look the second check; big areas black, the light tier in small shapes, darks in small
pieces, no dithered areas. The hi-res
rules came from `mockup/battle_forest_v6.py` and `tools/art/actors.py`.
