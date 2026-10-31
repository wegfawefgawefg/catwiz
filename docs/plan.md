# Plan

Catwiz: an Apple II double hi-res dice roguelike in Tisple ][, to prove the compiler and an
engine. Shelved 2026-10-30 with two of ten fights, then ported to double hi-res with the day
art (branch dhgr-port, 2026-10-30). Owner: an homage in the genre, not a remake; no
text or data from any other game; the content can be replaced by much stranger stuff later.

## Where it stands

`tisple build` builds `build/catwiz.dsk` from `game/` (Tisple's branch catwiz-dhgr-lib until it
is merged; settings in `tisple.project`).

1. Boot: LOADING, then by frame 600 the title in double hi-res: CATWIZ in white with a rim
   that glows (magenta, orange, yellow, orange), the cat against a big white moon on a night
   page, "a dice battle in the woods", PRESS RETURN. One packed picture and the rim's four
   colours as sprites.
2. A run: fight 1 in the clearing (puffcap, sporelet), what comes between fights, fight 2 on the
   path (puffcap, sporelet, nightflap), then "to be continued" and the title. Both at night
   (2026-10-31, midnight: the whole game). Hit points and her kit carry between fights; losing
   ends the run. Fights 3-11 (docs/balance.md, the run fight by fight) are in the content as data
   and play in test builds on fight 1-2's screens with stand-in figures (`battle/battle.tsp`'s
   test constants); the run stops after fight 2 until their art and per-fight disk loading.
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
   - Between fights (`battle/reward.tsp`): one of the fight's three cards (an item for a slot,
     the old one going, or a level on a slot; the item you hold is a level); after fights 4, 7
     and 10 one of three charms (`content/charms.tsp`); after 7 the nap (10 hit points, or a
     level on a slot of your choice); before 10 two doors (the vet or the big bath).
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
   `tools/phone/catwiz.json` has the tap boxes (the six cards, the re-roll button and the
   stars, END TURN, the enemies, the cat, then the whole screen as ESC) for Tisple's web player
   and `tisple machine --taps`, the web player's portrait pad (DIE 1-6), and `"look": "ntsc"`:
   the player starts in the TV look. One-time hints in the log (once a boot): the first turn,
   the first mana.
5. Screen: double hi-res, all graphics: the stage (rows 0-117 and a black gutter), the tray
   (rows 118-159), four lines of 35-column text drawn into the picture (rows 160-191): the pick
   (the item's name, its base or how to play it, its line) or the target (name, hit points,
   statuses, next move), then a log of what happened. A black pill badge under each actor (a
   heart and its hit points, then its statuses as glyphs: the kittens a kitten's head) and over
   each enemy (its next move: a sword and how much, a shield, a cheer, a Z when it skips...).
   The tray: a tilted white card for each die with its item's picture and number, the picked one
   lifted with a yellow bar; a sixth die's card where the buttons were; right of the cards the
   re-roll button (a die and X and the re-rolls left), five mana stars, END TURN. Between fights
   the tray holds the choices and the stage her six slots (a picture and a pip a level each, the
   slot a choice changes framed in yellow, showing the change). Sprites in the night's light,
   solid on a black stage.
6. Sound: Mockingboard music and effects in any slot; speaker effects and the title jingle
   without one.
7. Memory (2026-10-31, the item model): main memory and the language card full, built at
   squeeze 10 with 1.3 KB of cold code in the card's bank 1; aux about 2.7 KB left
   (`$B540-$BFFF`); zero page 172 of 256 (AGENTS.md, Memory). The content's text (items,
   moves, charms, enemies: about 3 KB) is most of what grew; Open 7.
8. Speed: waiting for a key a pass is a frame; a pick shows in 2 frames; the same turn of plain
   wand hits takes the frames it took before the item model, give or take one an action (AGENTS.md,
   Memory).

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
3. Per-fight art from disk: the packed store grows a screen (about 1.2 KB packed) and the new
   enemies' runs (2-3 KB) a fight, and aux has about 2.7 KB left, so fights 3-11 need their art
   read from the disk when they start (Tisple main 7c3de44's `:on disk` tables and lib/disk,
   which reserves main memory `$1400-$1BFF`: main memory is full, so that needs 2 KB of code
   moved to the language card or bank 1 first, or the reader placed elsewhere), each fight's
   tables into the same aux buffer; and a buffer for a fight's enemies at most (today sized by
   fight 2).
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
7. Room: the content's text in aux memory (or read from the disk with a fight's art) would take
   the build out of the squeeze; today a squeezed pass costs about 2% more flat out, kept even
   by writing the per-pass code out by hand (the tray's lift, the looks).

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
