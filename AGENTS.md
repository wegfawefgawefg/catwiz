# Catwiz

An Apple II double hi-res dice roguelike in Tisple ][ (github.com/wegfawefgawefg/tisple), a toy
to prove the compiler and an engine. Public repo, shelved 2026-10-30 with two fights of ten,
then ported from hi-res to double hi-res (2026-10-30, branch dhgr-port). It started as Witchdog
(a dog witch hero); the old name stays only in history notes. Enhanced IIe with 128 KB is the
target.

## Code style: C+-

From ~/Coding/AGENTS.md and the Mans In My House rules, in Tisple terms:

- Files 300-500 lines at most (aim under 450), one clear job each, in flat domain folders:
  `battle/`, `draw/`, `sound/`, `content/`, `title/`, `art/` (generated). No `utils`,
  `common` or `misc` files.
- Ultra low abstraction: plain structs and free functions. One game state: `state.tsp`
  holds all of it as top-level lets (`state.actors`, `state.phase`, ...). Drawing keeps its
  own record of what each page shows, and its scratch, in `draw/scene.tsp`. A thin
  `main.tsp` whose loop reads top to bottom in commented paragraphs.
- Hot arrays stay split: no `addr_of` on an element of `state.actors`, `state.looks` and the
  like. Tisple stores an array of structs as one byte table a field (`LDA hp,X`) until
  something takes an element's address; then it packs the whole array and every access
  multiplies (it cost the redraw about half its speed once). Pass indices, not pointers.
- Early returns and flat branching; concrete names; code easy to trace in the listing
  (`tisple build --asm`).
- Explicit dispatch: a card's effect is its row of steps, run by the one `match` on the step
  (`content/play.tsp`); enemy actions are a `match` on a kind enum (`content/foes.tsp`).
  Function pointers only where a table is clearly the plainer form, and say so where you use
  one (none so far).
- No generic engine layers or premature reuse. Write what this game needs, directly.
- Plain comments that say what and why.
- `tisple fmt -w` the files you touch.

## Content

- Game rules content is hand-written Tisple in `content/`: plain tables of structs written out
  (`enemies.tsp` and `moves.tsp`, `encounters.tsp` the hero, the run's fights (`FIGHTS`: zone,
  elite, the other door), the charms' kinds and `NAP_HEAL_SHIFT` (the sim's: the rest heals all); `rules.tsp` the
  rules page's text), the faces and charms as rows of data (`faces.tsp` and a file a slot,
  `charm_rows.tsp`: the disk catalog, below), the shared steps (`cards.tsp`), the rules faces land by
  (`effects.tsp`: a face's number, the boosts, a book's mana, the threes' count, the kittens'
  pounce), the `match` on the enemies' move kinds (`foes.tsp`), the charms' rules
  (`charms.tsp`) and the statuses (`statuses.tsp`). No separate data format, no parser, no
  Python step for it (two small macros: `content/rules.tsp` `page` lays the rules page's text
  out, `content/steps.tsp` `steps` a card's steps; `draw/packs` packs the generated art). The
  rules are
  the balance sim's (`tools/sim/items.py`, `rules.py`; docs/balance.md, the item-slot model), its
  tuned tables since 2026-11-01 (`python3 tools/sim/tablediff.py`; docs/balance.md "What the
  engine needs").
- Cards as data (2026-11-01, the owner: many more cards, each costing table bytes, not code):
  what an item, a charm, a status's hook or an enemy's curse does is a row of steps in
  `content/cards.tsp`, written with the `steps` macro of `content/steps.tsp` (the vocabulary,
  each step explained at its top) and run by `content/play.tsp`. While steps run they keep a
  target t, the card's number n (its # after levels and boosts) and a value v (n to start
  with). The steps: values (num, lit k, kits k, get s, least k, most k, kept, plus s, more k,
  half), conditions (has s, if_up, fell, landed, three, calm, if_calm, low k, coin k), stacks
  (add, set, max, times, sub on her stack s; t_add, t_set, t_sub, t_get, t_has, t_plus, t_times
  on t's), her (mana, spill, rerolls, no_rerolls, heal), on t (hit, pierce, plain, hurt,
  curse s, pounce), targets and loops (all, others, rep ... end; next, pick, retarget, me),
  calls (call k: a shared row of `cards.SUBS`), chains (back: every die comes back after this
  play; blocked), the uniques as native steps (copy: Copycat; look and mimic: Mimic, with
  `cards.MIMICRY` saying what each enemy move is for her; hat: a face from the catalog, read
  from disk 2 mid-fight), sound and log (cue c; say, say_it, say_me l: a line of
  `effects_said.tsp`'s SAY). `steps.tsp`'s top says what each does; docs/faces.md "As built"
  what the faces round added. Triggers: `cards.HOOKS` rows (a status, a
  moment, the stack that is its value, the steps) for a wand hit on its holder, its fall, an
  enemy's hit on her, her turn's end; a charm's row (`encounters` CHARMS) names its moment
  (`steps.When`: a fight's start, her turn's start, she is hurt, a ward takes a curse, a three,
  she would fall, an enemy beaten, or none: a charm that changes a rule is read where the rule
  is, by its kind; plain is the kind of a charm whose steps are all it does). Hooks set off
  in the middle of a hit wait in `content/hooks` and run as soon as the step (or the enemy's
  hit) is done. The rows are plain s-expressions a tool like the sim's `tsp.py` can read: a
  step is `(word arg)`.
- The disk catalog (2026-11-02, docs/faces.md: faces and charms cost no memory). A face is a row
  of data in its slot's file (`content/faces_wand.tsp` ... `faces_trick.tsp`, the hairball in
  `faces.tsp`, whose top says what each field is), a charm a row of `content/charm_rows.tsp`:
  name, text with `#`, slot (a charm: kind, when, mark), amount, step, cost, aim, tags, show,
  picture by name, weight (its share of the draws; 0 never offered) and steps (a say may carry
  its own line as a string, kept in the record). `content/catalog.tsp` lays every row out while
  compiling as one sector of a disk 2 table (`FACES`, `CHARMS`: the hot fields, the 15 x 11
  picture from `art/pictures`, the steps and their lines, the name, the text; a face's id is
  its row's place, `(catalog.id TWIG_WAND)`) and the draws' pools (`FACE_POOL`, `CHARM_POOL`,
  with `faces.upgrades`' six weights). It fails the build on an unknown field, slot, tag or
  picture, a name past 17 columns, a text part past 35, a record past 256 bytes. Memory holds
  rows only (`content/items`): rows 0-5 her faces (row k is slot k's item), 6 the hairball,
  7-10 her charms (`content/charms`), in aux memory all run; 11-15 the five faces offered and
  16-18 the three charms, at the end of `blit.sprite_aux` between fights (the last fight's
  enemies' sprites, dead then); 19 a face a hat trick drew, in aux memory's text page 1. What a fight reads each play (slot, amount, step, cost, aim,
  tags, show) is copied into main memory as a row loads. Records are read only between fights
  (`items.read`, `meter.read_piece`: one sector, about a fifth of a second): her six faces and
  the hairball as a run starts (in resident `battle.enter`, so the overlay groups that read
  records share no code), the offer as the reward shows it (a card a step, after the prompt),
  a face or charm again as she takes it. `state.items` holds her slots' catalog ids.
  `python3 tools/sim/catalog.py` lists the rows as the build reads them.
- To add a face: its picture in `tools/dhgr/icons.py` (a charm's: `charm_icons.py`) and
  `python3 tools/dhgr/game.py` (it writes `art/pictures`), then its row in its slot's file:
  nothing else, no memory, a sector of disk 2. A status it needs: a row in `statuses.tsp`
  (`Status`, `SHOW`, `GLYPH`, `NAME`; `STATUS_SLOTS` in `state.tsp`) and, when it acts at a
  moment, a `HOOKS` row. The statuses an enemy can have come first (`FOE_COUNT`, state
  `FOE_SLOTS`): an enemy's stacks are only those (state `FIRST_STACK`, 120 bytes for all four),
  so a status only she has goes after them, and no step may put one of hers on an enemy. Only an effect no step can make needs a new step (a byte in
  `steps.tsp`, its arm in `play.run`): keep the vocabulary small. A line more than one card
  says goes in `effects_said.tsp`.
- The chain and combo cards (2026-11-01, the owner's picks of docs/balance.md "The chain and
  combo cards", numbers from `tools/sim/proposal`, not retuned yet: a retune changes rows only):
  Red Dot, Mimic, Catfight, Mirror Fur, Lucky Paw, Flea Circus, Sunbeam, Scratching Habit (its
  +1s last the fight: her `habit` stack, which `effects.number` adds), Double or Nothing (the bet
  is its # for now, the sim's form: `(num) (add gamble)` in its steps, so another price is a
  table change), and the charms Nine Lives (once a run: `state.spent`) and Litter Box (the
  kittens she won with: `state.kept`). Their rules (`cards.tsp`): her dice come back `BACK_MOST`
  times a turn at most (5, the sim's cap: `battle/turn` after_action, `dice.back`); re-rolls stop
  at `REROLLS_MOST` (9: the sim has no number for it; the tray shows one digit). Catfight's turn
  of a hit is in `foes.move_target`; Nine Lives' save in `hit.lose` (`charms.saved`).
- The sims read the game's tables with `tools/sim/tsp.py`: since the cards are data, items have
  no `effect`, `combo` or `combo_n` (their steps are in `cards.tsp`), and `FLEA_TURNS`,
  `ZOOMIES_HITS`, `SCREAM_SELF` moved from `effects.tsp` to `cards.tsp`; the sims' game-table
  readers (`tablediff.py`, `content.py` "game") need that the next time they read the game.
- Every number is a byte and stops at 255 instead of wrapping (the owner, 2026-11-01): add with
  `st.sum` (content/statuses), multiply with `fx.times`, stacks with `hit.add_stacks`. The
  badges show three digits; a floating number two (99 at most, the log has the whole number).
- The engine (`battle/`, `draw/`) never names a specific enemy, item, effect or status. It reads
  the tables and calls the hooks in `content/`, so the content files can be replaced without
  touching the engine.
- The hero rolls five identical dice (six with a charm); each die's six faces are her six item
  slots (`state.items`), so a face is the item in its slot (`battle/dice.tsp`; `state.hand` holds
  rows of `content/items`). Levels belong to the slot (`state.levels`). The run (2026-10-31, the owner): ten fights, three places of three
  (the woods, the garden, the yard), each ending with an elite, then the Bulldog King; the two
  doors (the vet or the big bath) are the yard's elite. Between fights (`battle/reward.tsp`):
  one of five cards drawn at random (`battle/offer.tsp`: by weight from the faces' pool, five
  different, no gates by fight, no level on a slot at its most; the item she holds is a level,
  the same card to a draw as the slot's upgrade), in the tray's slots, a card's lines on the
  text rows when it is picked (`battle/card_words`: a new face on a slot with levels shows how
  they make its number, "Hits 10 (6, +4 from your levels)."); after an elite also one of three
  charms drawn the same way (ones she has not got), then the rest (2026-11-03, the owner: she
  heals to full, her badge counting up with hearts rising by her, then she may put +1 on a face
  of her choice, or skip it as every pick can be); before the 9th fight the doors. The stage shows her six slots (`battle/kit`). The
  fights are the sim's (docs/balance.md "The run"): the woods' elite THE OLD SHROOM has its own
  figure and screen (the clearing's scenery round its lanes, `screen_fight3`), and the
  nightflap is in no fight (no screen carries it).
- The map of the run (`battle/map.tsp`) at the top of the stage, over the cat, drawn once a
  fight: the place, a mark a fight (an elite's bigger, hers lit), the king's crown. Its box is a
  lane (`tools/dhgr/lanes.py` MAP), so the scenery stays out of it.
- Pages over the stage in her turn (`battle/page.tsp`): her kit (`battle/bag.tsp`, B) and the
  rules (`battle/rules.tsp`, ?); between fights her kit too (B, the BAG button), and closing
  it draws the reward's step again as it was (`reward.reshow`). A page opens at the step after
  its key (`page.fresh`), so only the pages' code draws pages (their overlay group). The
  fight waits under one; closing puts the stage back from the spare page, which keeps the
  fight's picture all fight.
- Clicks (2026-11-01, the owner: exact boxes for everything clickable): the game reads an
  AppleMouse (lib/mouse, set up in `title.enter`) once a pass of the main loop (`main.poll_click`;
  not in the handler: a call into the card's firmware may change anything for all the compiler
  knows, which would slow the whole game). A press goes in the key line as CLICK with where it
  was, and `main.next_key` gives the key of the box it hits on the screen as it is then
  (`battle/boxes.tsp`, made from the drawing's own numbers: tray slots, `tray.SIDE_X`...,
  `page.CLOSE_X`..., `kit.cell_x`, the actors' idle frames where they stand); a click on
  nothing is `.`. So every screen takes clicks as keys. Add a box there with anything new that
  takes a click. The emulator (`tisple machine --taps` with `"mouse": true`, the web player)
  puts the mouse where a click or tap is and holds each press until READMOUSE has seen it.
- Test builds: the constants at the top of `battle/battle.tsp` (start at fight N or its other
  door, play on past fight 2 on stand-in art, a charm held from the start, every fight won as it
  starts, `SEED`: the run's random numbers, the dice and the draws, the same every time) and
  `items.STARTING_ITEMS`, flipped in a copy.
- No text, names or item lists from other games. Our own names and art.

## Text

- Strings: main memory is full, so text lives in aux memory. The content's tables are
  `:strings aux` (the hero, the status names) or wholly `:in aux` (moves, enemies, fights:
  read through their modules' accessors, `(mv.text row)`, `(en.hp kind)`,
  `(enc.elite f)`, a `with_aux` each). The code's sentences are `SAY` tables, `:strings aux`, one
  a module with a `SAY_` name for each (`(at SAY SAY_SHORT)`; the lines more than one face says
  in `content/effects_said.tsp`, a face's own in its row and record). A face's and charm's name
  and text are in its row's record in aux memory (`items.name row`, `items.text row`). All are read with `text.add_aux` / `add_aux_n` (a copy under
  with_aux, then as `add_n`), and the log takes only aux strings. Strings written in the code
  stay in main memory (`text.add`, `add_n`): only those lib/dhgr_pixels' glyphs read (the tray's
  captions, `battle/hud.tsp` DIGITS...; the buttons' words; the map's places; the charms'
  marks). A pointer cannot tell which, so a function that takes one takes one kind.
- The rules page's text is on the second disk (`content/rules.tsp`, `:on disk2`; its `page` macro pads
  each line to 35 columns and fails a longer one), read a page at a time into aux memory's text
  page 1 (`$0400`, free: the game shows no text page). Every rule there is the engine's: change
  them together.

- The screen is all graphics (double hi-res, no mixed text window). The four text lines at the
  foot (rows 160-191) are drawn onto the page being drawn by `draw/text.tsp`, only the blocks of
  7 characters that changed, and copied onto the other page like any hud part. The font is the 35-column one in whole colour pixels (`FONT35`, a
  4-pixel cell a character, white in every look, drawn with lib/dhgr_pixels' cells). Its glyphs
  are one of the candidates in `tools/dhgr/fonts35.py` (`PICK`; `CATWIZ_FONT=name make.py game`
  tries another, `python3 tools/dhgr/fonts35.py out.png` draws them all): any of them is the same
  760-byte table, so a font costs no memory;
  `FONT_35` in `draw/text.tsp` is the one place that switches to the 40-column dot font
  (`art/font40`, violet and green in the flat colour look). Strings are 35 characters at most
  either way. A line is drawn again only when it changed.
- `battle/words.tsp` writes the top two rows (the die picked: its item's name, a wand's damage
  or a fluff's shield or how to play it, and the item's line; else the target), `battle/log.tsp`
  the bottom two (what just happened, in sentences: a line waits as data, made once a frame).
  Between fights `battle/reward.tsp` writes all four (a card in balance.md's four lines).
- Strings are plain ASCII in sentence case in the code and the content tables (names
  capitalised, an item's or charm's name in capitals, inverse); `#` in an item or move text is
  its number. The hud font (badges, card captions, buttons: `tools/dhgr/game_hud.py`, 3 x 5
  pixels) has ' ' to '_', and its punctuation is icons (heart, sword, shield, star, the statuses
  and the moves' glyphs: `HUD_ICONS`). Glyphs a badge holds stay 3 wide (`lanes.py`
  BADGE_GLYPHS: the badges' lanes are sized by the widest).

## Art

- Double hi-res (2026-10-30): `tools/dhgr/`, run `python3 tools/dhgr/make.py` (previews to
  `shots/dhgr/`, the lanes checked, memory per fight in `art/dhgr/memory.txt`) and
  `python3 tools/dhgr/game.py` (or `make.py game`) for the game's tables in `game/art/`
  (generated: never edit by hand; formats at the top of `game.py`). Drawn at 140 x 192 wide
  pixels (a pixel is 4 dots, 1.83 rows wide).
- Sprites are cut on 7-pixel steps (4 bytes: aux, main, aux, main) so their colours hold, and
  move on them (2 byte columns a step); up and down at any row. Each half is stored as lib/dhgr
  runs (skips, opaque runs, edged runs with masks). Frames are whole (no face patches): a mood
  shows as a kind's frame by role (idle, attack, hurt, happy, surprised, flap, flash, and shot,
  shot2: the small sprites its moves throw; `battle/look.tsp`), its idle one when it has none.
- Figures (2026-11-01, `tools/dhgr/figures.py`): a block is a figure's frames drawn as one run
  of sprites; a kind is a role table over a block, and may borrow another's (the possum that
  faked it, the Bulldog King's phases): a phase costs only the frames it adds. An enemy names
  its figure (`content/enemies.tsp :figure art.FIG_...`); `spawn` turns it into its kind on the
  screen (`art.tab.figure`). The Bulldog King (2026-11-02, `king.py`) is three looks: sat
  up on his throne smug (`king`), cross on it (`king_cross`, the same block: folded arms, the
  crown crooked, a vein), and furious off it (`king_furious`, its own block: flushed pink,
  red-eyed, steaming); his frames are 4 groups wide so the three and the royal pugs (3 groups)
  fit fight 10's sprite room (`art/dhgr/memory.txt`, 596 bytes to spare).
- Screens (2026-11-01, `tools/dhgr/screens.py`): one a row of `encounters` FIGHTS, made from
  the table itself (the sim's `tools/sim/tsp.py` reads it): the figures of its spots up to the
  count, the spots past it when someone there (or what it becomes) calls friends, every then.
  Reorder the fights and run `make.py game` again. Each is on the second disk
  (`art/screen_fightN.tsp`, `draw/packs` tables): PICTURE (read into `sprite_aux` past the
  hero's runs, unpacked onto the spare page and shown there) and RUNS: the screen's tables
  (`art/sprites` `tab`, main memory: every sprite's box and runs' place, every kind's place and
  role frames, the blocks' sizes, the figures' kinds; the largest screen's size) and its
  enemies' blocks' runs (read into page 1's aux memory, not shown then, and unpacked:
  `draw/blit.tsp`). The hero's and the small sprites' blocks (`art/hero.tsp`, blocks 0 and 1 of
  every fight screen) are unpacked once and stay while fights follow (the title's glow puts them
  out): every block's main halves into the aux language card's bank 2, the aux halves into its
  bank 1, the rest of bank 2, then `sprite_aux`, as they fit (`art/dhgr/memory.txt` checks each
  screen, and that its picture fits `sprite_aux` past the hero's); then the spare page is copied
  onto page 1.
- Midnight (2026-10-31): the whole game is night, for speed. The fighters stand on pure black
  and every fighter frame is solid: the figure flattened onto black over its whole box, only
  opaque runs (`SOLID` in `art/sprites`). One copy of a frame erases the last pose and draws the
  new one, with no restore and no mask. The flash role is a solid white silhouette of the hurt
  frame. The small sprites (marker, bolt, poofs, digits, the title's glow) stay masked.
- The lane rule: every pixel of the stage that any battle look can ever cover is black (colour
  0) in the backdrop. `tools/dhgr/lanes.py` works the lanes out from the game's numbers (each
  frame at home and on its lunge, lifts, the knockback, the flyer's bob, the bolt's arc, the
  floating numbers' rise, markers, poofs, badges), mirrored from `battle/` and `draw/badge.tsp`:
  change one of those and the lanes in `lanes.py` with it, then `make.py lanes` (it fails when
  scenery is in a lane; `shots/dhgr/lanes_*.png` shows them tinted). The lanes take about 80% of
  the stage (fight 1 79%, fight 2 86%): the scenery is a thin frame round them.
- Fighters are drawn once in materials and lit per zone (`tools/dhgr/light.py`, a palette swap
  plus rims by code); the build carries the night, lit offline. On black the outline is gone,
  so the night rims go round the whole figure but the feet (light blue left and top, pink
  right).
- The backdrops are whole screens (`game.py`, `fight_picture`): `tools/dhgr/night.py` draws each
  fight's night outside its lanes (the clearing: a full moon, an oak, a fairy ring; the path: a
  crescent, a lantern, flagstones). No shadows: every spot under a fighter is in a lane. The
  title is one picture with its letters' rim in four colours as sprites (the glow). The day
  forest (`forest.py`, `palettes.py`) and its previews are the old plan, kept for the record.
- The hud is drawn in whole pixels (`draw/pix.tsp`, lib/dhgr_pixels): badges (`draw/badge.tsp`,
  looks over the stage), the tray's cards (spans and rectangles from `art/hud_data`, the pictures
  from the rows' records and `art/icons`), the buttons, the text. The card pictures
  (`tools/dhgr/icons.py`, 11 x 15, by name) are in the faces' and charms' records on disk 2
  (`game.py` writes them as a macro, `art/pictures`, which `content/catalog` reads while
  compiling): a row's picture is in its record in aux memory (`draw/paint`: a tile below
  `icons.FIRST` is a row); a door and a grabbed die stay in aux memory packed (`art/icons`). Each tray slot copies its picture when it changes
  (`battle/tray.tsp`), the stage's slots one at a time (`battle/kit.tsp`). The tray's
  cards are shapes slots share, moved sideways (`art/hud_data` CARD_SHAPE, CARD_SHIFT).
- The charms' pictures (2026-11-02, `tools/dhgr/charm_icons.py`, by name, a charm's row names its
  own) are in the charms' records like the faces' (the kit page, the charm pick and the ending
  page show them). Until the catalog they were a disk table copied onto the spare page's aux
  rows 160-189 as every fight's art loaded; nothing uses those rows now.
- Each card's play has a show (2026-11-01, `content/shows.tsp`, named in its row's `:show`): one
  or two small sprites (`game_sprites.py` SHOWS, in the small sprites' kind) thrown on the bolt's
  arc (ARC: the bolt, Mimic's mask, Flea Circus's flea) or played over whoever it is for (ON: a
  step every 2 frames at a path's places, then the effect lands: the red dot skittering, claws
  raking (Catfight, with its angry face; Scratching Habit), a glint down her fur, a lucky paw
  waving, a sunbeam coming down, a coin flipping; and the old cards' squirt of water (the spray
  bottle, wet), streak (zoomies), flea (fleas) and puff (ball of yarn, mark territory)). NONE is
  the plain hop. A show is never longer
  than what it replaces (her own cards' 3 steps are the hop's 6 frames; the rest land before
  the bolt would), and an ON sprite stays inside its fighter's idle frame (a lane always). The
  scene draws the fighter's rows again where a small look left it, with no black fill first
  (`scene.restore_drawn`), so a show (or the bolt landing) never blinks a hole in a figure.
- Her heal's look (2026-11-03, the owner: hearts float up on her): every heal of hers (a face,
  a charm, a leech; `hit.heal`) puts a heart in each floater the heal's number leaves free, and
  they rise like the numbers by her head on black (`hit.heart`, HEART_COL/ROW: left of her
  hat's brim and right of it under the number, in her lanes, out of her happy frame so she is
  not drawn again as they move; her happy face lasts as long, HEAL_FRAMES), each 4 frames
  shorter than the last so all move on the same frames, the last 5 frames a glint (`look.update`,
  the shine sprite). A number takes a heart's floater when none is free. No sprite of its own:
  the faces round's heart. The rest's full heal (`reward.mend`) counts her badge up a hit point
  every 4 frames with a heart every 8. The hearts' lanes are in `lanes.py` (HEARTS).
- The chain cards have their own pictures (2026-11-01, `icons.py`): a glowing red dot, a cat
  mask on a stick (Mimic), two black paws swiping (Catfight), a fur-framed hand mirror, a lucky
  cat waving, a flea on a striped stand, a window's sunbeam, claw marks (Scratching Habit), a
  coin (Double or Nothing). Their statuses and the two charms have hud glyphs past `_` in the
  hud font (`game_hud.py` HUD_ICONS: `` ` `` red dot, a catfight, b mirror fur, c flea circus, d
  habit, e the litter box, f nine lives); `pix.glyph` reads any code the table holds.
- NTSC (the TV look) is the real target and the web player starts in it (`"look": "ntsc"` in
  `tools/phone/catwiz.json`); judge the art and take screenshots there first, colour second. In
  NTSC every colour but black, white and grey shows fine stripes, the dark ones worst: big areas
  white or black (the night is a black page), then the light tier (light
  blue, aqua), darks in small pieces, flat fills, no dithered areas.
- Faces that carry state, stylized silhouettes with depth, rims that read on black.
- `tools/art/` is the hi-res art the game had until the port (its export writes to
  `build/art_hires/` now), kept for the record.

## Sound

- `game/sound/sound.tsp` is the one place sounds go through: `(sound.cue sound.Cue.zap)` for an
  effect, `(sound.song sound.Song.battle)` for music. With a Mockingboard (any slot, found at
  start) the card plays them; without one the speaker effects of `sfx.tsp` and the title jingle
  of `music.tsp` play, and there is no other music.
- Card effects are `tune.effect`s in `game/sound/card_fx.tsp`. lib/mockingboard plays one at
  a time and keeps the ones that come while another plays in its own short line; cues marked
  not to wait are dropped while an effect plays or waits (`mb.effect_playing`). Each borrows a
  music voice: 2 (left, the hero's side) or 5 (right, the enemies'), so the songs keep their
  least-missed parts there (the pad and the shaker).
- The chain cards have their own cues (2026-11-01), named by a `(cue ...)` step in each card's
  steps: dart (Red Dot), mimic, yowl (Catfight), shimmer (Mirror Fur), lucky (Lucky Paw), hops
  (Flea Circus), glow (Sunbeam), scratch (Scratching Habit), coin (Double or Nothing). On the
  speaker each borrows the sound it replaced (the zap, the ping, the chime), and the curses'
  have none (the curse's hiss follows), so the speaker holds the processor no longer than before.
- The music is `game/sound/songs.tsp` (lib/mockingboard_song's text), each song `:on disk`
  (2026-11-01: aux memory was full), read when it starts into aux memory's text page 1 (the
  rules page's buffer) and copied into main (`waiting.PLAYING` bytes: keep it at the largest
  song's size, which `tisple expand` shows). A song starts with a screen or at the run's end.
- Song changes fade (2026-11-03, the owner; Tisple's `mb.fade`, docs/mockingboard.md "Fades"):
  `sound.quiet` (the title's key, and every `sound.song`) fades the music out, a volume step every
  4 ticks, 1 s to silence, then the player stops it (a song playing on silently under a load
  slowed the disk reads: fight loads took about 20 frames longer). The new song is read meanwhile
  and `waiting.start` copies it in once the one before is silent: from `song` when it is by then,
  between a load's sectors (`draw/meter.sector`), or from the main loop's look each pass (the
  run's end, where the battle's song fades under the banner), and fades it in from 13 steps down
  (`FADE_FROM`, the loudest any song has: 0.87 s); the stingers (won, lost) start at full. Nothing
  waits for a fade. While a song waits, nothing else may read into aux text page 1
  (`state.aux_page1`; sound.tsp says why none does). `tools/music/renders/fade_demo.ogg` is the
  title to the first fight as it was before the music went through the loads.
- Music through the loads (2026-11-03, the owner: "we should at least have the capability";
  Tisple's `load-music` branch, docs/dhgr.md "Ticks through the card"): a screen's song starts as
  its load begins and plays through it. The title's key fades the title's song out at once and
  reads the battle's song (title.step); a fight from the reward reads it at enter_fight's start;
  the title after a run reads its own at its enter. `sound/waiting.tsp` holds the song waiting
  and `start`, which the main loop and every disk read's sector step call (`draw/meter.sector`),
  so the song comes in within a sector's read of the fade's end. Tisple's card unpacks let the
  tick in every page out and 32 matches, so no tick is lost in a load (686 of 686 from boot through the first
  fight's load, the latest 12,884 cycles late; 35 lost before). Silence at a change (the old
  song's inaudible tail, the wait for a sector's end, and the battle song's first bass note,
  silent under the fade in from 13 steps: about 36 frames of it) is about 1.1 s, was about 3.3 s
  (title to fight 1: 63 frames silent, was 174 + 22; reward to fight 2: 68, was 115 + 23; the
  run's end to the title: the title's song 90 frames after the key, was 171). The cost is the
  tick's work while a load reads: the battle song (about 1,100 cycles a tick) makes reads miss
  sectors, so the fight from the reward is ready 294 frames after the key, was 251; the first
  fight 436, was 452, and the title after a run 132, was 162 (both now play less music through
  their reads than before); the boot's title 813, was 808. `tools/music/renders/load_music_demo.ogg` is the title to the first
  fight and a reward to the next fight (a build that wins at once for the second part).
- `sound.setup` installs lib/auxmem's guard, so aux copies run with interrupts on: the
  Mockingboard's handler runs with main memory in even when a tick lands in a copy.
- `tisple machine ... --mockingboard 5 --wav x.wav` plays and saves it; `MB=5` makes
  `tools/measure.py` measure with the card in. Slot 5: the emulator's mouse card is in slot 4
  (`tisple.project`, `tools/phone/catwiz.json`; the game finds either card in any slot).

## Building and running

```sh
TISPLE=~/Coding/LangDev/tisple/build/tisple          # Tisple with the second disk (drive2 branch)
$TISPLE build                        # build/catwiz.dsk and build/catwiz2.dsk; --tables: where each went
D="--disk build/catwiz.dsk --disk2 build/catwiz2.dsk"
$TISPLE machine $D --frames 1500 --keys "950f:RETURN" --screenshot shots/x.png
$TISPLE machine $D --frames 1500 --keys "950f:RETURN" --ntsc --screenshot x.png
# a machine with one drive: the prompt, the swap, RETURN
$TISPLE machine --disk build/catwiz.dsk --drives 1 --swap 1300f:build/catwiz2.dsk \
    --keys "950f:RETURN,1400f:RETURN" --frames 2000 --screenshot x.png
# the phone player (Tisple's web/publish.py)
python3 $TISPLE_SRC/web/publish.py catwiz build/catwiz.dsk tools/phone/catwiz.json --disk2 build/catwiz2.dsk
```

- The phone pad (portrait only; sideways the screen's click boxes are the touch interface and
  the pad is gone) follows the game (2026-11-02, Tisple b2cc49c, docs/phone.md "The pad follows
  the game"): each key's `when` and `live` in `tools/phone/catwiz.json` are conditions over the
  game's lets and enums (`state.phase`, `state.actors.alive[2]`, `battle/reward.choices`,
  `state.Phase.player`), whose addresses come from `build/catwiz.vars.json` (every build writes
  it; publish.py copies what the conditions name). No game memory. Fight keys show in her turn
  and while her action or the roll runs (keys wait in the line then), dim in the enemies' turn;
  ENEMY n while that enemy is alive; DIE n up to `dice_n`, dim when played or held; < > with two
  enemies or more and on the kit and rules pages; RE-ROLL dim with none left; LET GO dim with
  nothing picked; between fights BAG, SKIP (not the doors) and PICK 1 to `choices`; a page
  CLOSE; the title START; the end GO ON. Renaming a let or an enum member the config names fails
  the publish (say which): change the config with it. The `56` in "over" is
  `battle.BANNER_AFTER`.

- Two disks (2026-11-01): disk 1 is the boot and the title's art; disk 2 (Tisple's `:on disk2`)
  everything read during play: every fight screen, the hero's runs, the rules pages, a label,
  and the title's art again for the titles after a run. A run's start finds disk 2
  (`title/disk2.tsp`): its label from drive 2, else from drive 1, else the text lines say "Put
  CATWIZ DISK 2 in drive N, then press RETURN" and it looks again; a machine with one drive swaps
  once, after the first title, and never back. Two drives: no prompt.

- The game needs Tisple main with lib/dhgr's runs, lib/auxcard, lib/dhgr_pixels, `:strings
  aux` and lib/disk (the `catwiz-dhgr-lib` branch is merged), and lib/mockingboard's fade
  (`mb.fade`, `mb.fade_in`, `mb.faded`: Tisple's `song-fade` branch, 2026-11-03), and its card
  unpacks that let the tick in (Tisple's `load-music` branch, 2026-11-03: lib/auxcard moved to
  `$1DA6`, lib/dhgr's runs end at `$1F50`).

- `tisple.project` makes a bare `tisple build` (anywhere in the repo) `tisple build
  game/main.tsp --origin 0x8000 --disk build/catwiz.dsk`, and `tisple run` that plus booting it
  with `--mockingboard 5 --scale 2 --taps tools/phone/catwiz.json` (the config's `"mouse":
  true`: a click is the mouse card's mouse there, pressed; Tisple's mouse-player branch). When the program does not fit, Tisple builds it with a tighter size budget
  (squeeze levels) and says which functions it kept as calls instead of copying them into
  their callers; `TISPLE_SIZE_NOTES=1` lists what the budget weighs. The game keeps no list of
  its own (it had `game/noinline.txt` until 2026-10-30).
- The boot shows LOADING with Tisple's meter (a percent and a bar, Tisple d14df73 or later),
  then the title by frame 784 (13 s); a fight's art loads in about 3 s, the title still
  showing while its picture is read, then the picture while its runs are read and unpacked,
  with paw prints along the foot of the stage (`draw/meter`; the fight's song plays meanwhile:
  Sound, Music through the loads). Every disk read goes through `meter.read`.
- 2026-11-01: main memory had about 15 bytes free; the meter's 377 bytes of code made the
  build put `battle/look.update` in bank 1 too (an action pass about 4% slower, still under
  a frame).
- 2026-11-03 (music through the loads): Tisple's homes took 16 bytes more and zero page `$FF`,
  and the build no longer fit. Two moves made room, no feature cut: the speaker's title jingle
  reads its notes' table with `auxmem.read` instead of a `with_aux`, so its code (about 166
  bytes) went into the title's overlay group; and the four lets that each held `$0400` (aux
  text page 1 for the rules page, a song, disk 2's label, a hat trick's face) are one,
  `state.aux_page1`. Bank 1 holds 25 functions (3,498 bytes), was 26 (3,675).

- Never open windows on the owner's display; run the machine headless and look at
  screenshots (`shots/`).
- Frame costs: `python3 tools/measure.py "700f:RETURN" 1300 1600` builds a
  copy that runs flat out and prints cycles a pass of the main loop between two frames;
  `VSYNC=1` measures the real game, extra `"file|old|new"` arguments try an edit in the copy
  (`"battle/battle.tsp|(set state.fight 0)|(set state.fight 1)"` starts at fight 2). A frame
  is 17,030 cycles. `state.ticks` is outside zero page: `--peek` reads the memory switched in,
  so a run stopping while the double hi-res code has RAMRD or ALTZP on reads 0 (measure.py
  tries the frames after).
- A frame that changes nothing on the back page is not drawn or shown (`scene.draw_frame`
  gives false), so a pass flat out with nothing moving is short.
- `tisple build --disk ... --asm` prints the listing (2026-10-30).
- At most 8 build jobs and 8 processes at once.
- Apple ROMs live in `~/.local/share/tisple/roms`; never commit or copy them into the repo.
- No maintained test suites; one-off runs and screenshots are welcome.
- Commit focused, verified chunks; stage explicit paths, never `git commit -a`.

## Memory

Self-booting disk, origin `$8000`. Double hi-res: page 1 `$2000` and page 2 `$4000`, each in
both main and aux memory, reserved (32 KB). One page is drawn and shown (2026-10-31, page 1):
every change goes straight onto the screen once, with no flip to wait for (a big pose may tear
for a frame); page 2 is where a screen's picture is unpacked, shown while its runs load, and
kept all fight (a page over the stage closes by copying the stage back from it).
There is no backdrop page: what a look leaves is filled black (the lanes). The looks keep to
rows 0-120, the hud to rows 121-191. Fighters whose boxes meet are drawn with lib/dhgr's
CUTOUT (their black not drawn); a lunge with another fighter in the way is a shot instead
(`battle/act.tsp` blocked), so no one passes through anyone. Code and data fill `$8000-$BEFF`, `$6000-$7FFF`,
then `$0BE0-$13FF`, then the language card (bank 2, and code in bank 1). Tisple's libraries keep
`$1400-$1BFF` (lib/disk's reader, main), `$1C00-$1DA5` (lib/unpack, both memories, and zero
page `$FF`), `$1DA6-$1DF2` (lib/auxcard, main) and `$1E00-$1F50` (lib/dhgr's runs, both). The art (each
screen's picture and runs) and the rules' text are on the disk (`:on disk`); the songs, the
card pictures and most text live in aux memory; a screen's sprites in the aux language card and
`blit.sprite_aux`. The disk has 10 segments, the most a disk holds: a new `:address` let that
splits a memory would not build.

- Overlay groups (Tisple `:overlay`, `:overlay_disk2`; `TISPLE_OVERLAY_NOTES=1` lists them and
  says why one is dropped): the pages (`page.step`: kit, rules, log, the won page; from aux
  memory, a page opens fast), the reward (`reward.step`, from disk 2), the fight's start
  (`battle.enter_fight` with the art's loading, from disk 2: its own step, `Phase.start`, from
  the reward and the run's start) and the ending (`battle.ending` with `reward.start`, which
  makes the reward's draws, from aux). They take turns in one region the size of the biggest
  (the pages', about 3.1 KB, in the language card): keep the reward's group under it. A group is
  dropped (its code all resident, about 3 KB more) when resident code names one of its labels:
  a `with_aux` in a group's function keeps that function resident, so read aux tables in a
  group through functions outside it or keep their tables `:strings aux`.
- Every disk table's record is in aux memory (`:on disk2 :in aux`, the packs macro and the
  rules' page macro add it); `meter.read` and `meter.sectors` copy it to main memory for
  lib/disk. Read a disk table only through them.
- The songs are on disk 2, the title's on both (`TITLE` for the first title, before disk 2 is
  found; `TITLE2` after: `sound.song`).

- Scratch that is set before it is read lives at fixed addresses the layout does not use, and
  is not zeroed at the start: `$0200-$02E3` (state.drawn), `$0800-$0BDF` once the boot loader
  is done (the song buffer, the log, the text line and what each line shows, the hud's pixel
  row and its bytes), and text page 1 (`$0400-$07FF` but `$0478-$047F` and the
  other screen holes: the rects, the scene's boxes, the looks, the stacks, the actors, the
  floaters, the dice, the badges, the counter; and since the kit round the text's glyph tables
  `$0424`, `$0600-$0668`, the log's waiting lines `$0447-$0476`, the hud's `was` `$0700`, the
  kit's picture `$0780`). Each such let says so. The screen shows no text page (`dhgr_text2` is
  not imported), so both are free; aux memory's `$0400-$062F` is the rules page's buffer (and
  where a song is read from the disk), `$0630-$07F6` the log's history (13 lines of 35:
  `battle/log` writes each line there, `battle/history`, H, shows them).
- The tray's copies of its cards' pictures are on the spare page (rows 160-174, 6 bytes a slot
  each: `tray.picture_at`), which nothing reads once a fight's picture is shown: main memory is
  full. Numbers are split into digits by subtraction (`text.digits`): no division routines.
- No multiply or division routines: `(* a b)` and `/` on variables pull in tables and routines
  (1 KB for the quarter squares); the game multiplies by constants and uses shifts. Watch the
  listing for `rt.` calls.
- 2026-10-30, at the shelving (Tisple 02e5697, squeeze 3 of 10): main memory full of code
  (`$8000-$BEFF` and `$0C00-$1FFF`, data spills to the language card); the language card
  11,449 of 12,288 bytes (839 left), after the boss's pictures (1,803 bytes and their tables)
  were left out of the build (`LEFT_OUT` in `tools/art/export.py`: put them back with the final
  fight); aux 41,907 bytes from `$0800` (about 5.2 KB left); zero page 179 of 256. A pass of
  the battle's main loop flat out: 13,304 cycles (0.78 frames).
- 2026-10-30, after the controls round (auto end turn, the END button, tilted dice cards,
  hints): the language card 12,085 of 12,288 (203 left); a pass 13,270 cycles.
- 2026-10-30, the double hi-res port (Tisple catwiz-dhgr-lib e67b906, squeeze 1 and 4
  functions in bank 1): main memory full (`$8000-$BEFF`, `$0BE0-$1BFF`); the language card
  9,203 of 12,288 (about 3 KB left), bank 1 3,575 of 4,096; aux 18,698 bytes (`$0800-$1BCF`,
  `$8000-$B4D1`: about 2.9 KB left at `$B4D2-$BFFF`), of it 5,376 `sprite_aux`; the aux
  language card for fight 2: bank 2 11,760 of 12,272 (the main halves, the nightflap's aux
  half), bank 1 3,415 of 4,096; zero page 172 of 256. A pass of the battle's loop flat out,
  waiting for a key: fight 1 4,870 cycles, fight 2 15,915 (its nightflap flaps); with the vertical
  blank fight 1 1.0 frames a pass, fight 2 1.6; during an action (a die thrown, the enemies'
  lunges) about 5 frames a pass.
- 2026-10-31, the midnight art (solid fighter frames and a flash frame a kind;
  `art/dhgr/memory.txt`, `make.py memory`, places them as `blit.unpack_all` does): the sprites
  of fight 1 take 22,977 bytes (was 17,139), fight 2 27,597 (was 20,539), against 21,744 of
  room (bank 2 12,272, bank 1 4,096, `sprite_aux` 5,376). Neither fits as placed: fight 1 is
  3,192 short, fight 2 7,458, and the aux halves that do not fit run past `sprite_aux`'s end.
  Solid frames are bigger than masked ones (the black round the figure is stored), and the
  flash frames are 4,752 of it. The night backdrops pack smaller (zlib: fight 1 1,034 to 785,
  fight 2 1,204 to 549); aux memory (Tisple fbc83f2, squeeze 6) 5,107 at `$0800` and 12,680 at
  `$8000` (3.7 KB left at `$B188-$BFFF`).
- 2026-10-31, later: fill runs (Tisple 770a16b, `$C0 + n`, used for 8 or more of one byte, where
  they pay for a segment's 55 cycles) and the backdrop page gone: no squeeze (code 29,928 bytes,
  `$6000-$7FFF` holds code now), `sprite_aux` 10,752 bytes in the aux memory the backdrop had;
  fight 1's sprites leave 5,839 bytes spare, fight 2's 1,779. Five dice played as fast as tapped
  (passlog SEED=5): done at frame 416 after the first tap, was 806.
- 2026-10-31, the item-slot model (branch items, Tisple bf11831): the content's tables and their
  text (items, moves, enemies, charms, the fights; about 3 KB of text) and the new rules' code
  do not fit main memory and the language card at the usual size budget (37.2 KB of code):
  built at squeeze 10 with 1.3 KB of cold code in the card's bank 1; the card 12,254 of 12,288
  bytes; aux 4,977 bytes at `$0800` and 21,824 at `$6000` (2.7 KB left at `$B540-$BFFF`, the card
  pictures 3,330 of it); the disk 68,976 bytes in 9 segments (the title by frame 725, was 670).
  The code every pass runs is written out where the squeeze would call it (the tray's lift, the
  looks): a pass flat out waiting for a key 5,657 cycles in fight 1 (was 5,535), 11,278 in fight
  2 (was 11,106); a pick shows in 2 frames; a turn of plain wand hits takes the frames it took
  (passlog, every face a wand: each throw within a frame, the enemies' turn within ten).
- 2026-10-31, the kit round (branch kit, Tisple 34fde5b): the random offers, the map, the kit and
  rules pages and lib/disk (its reader takes `$1400-$1BFF`, 2 KB of main memory) did not fit.
  Moved out of main memory: the art onto the disk (each screen's picture and runs, one table
  each, `art/screen_*`), which freed 11 KB of aux memory; into aux memory the moves, enemies,
  fights, charms and offers (`:in aux`, read through accessors) and the code's sentences (the
  log's, the reward's, the rows', the kit page's: `SAY` tables); small lets to text page 1. Built
  at squeeze 10 (was 8) with 14 functions (2,290 bytes) in the card's bank 1; bank 2 12,138 of
  12,288; aux memory 6,143 at `$0800` and 17,013 at `$6000` (7.5 KB left at `$A275-$BFFF`); the
  disk 64,199 bytes in 10 segments, 16 tables on tracks 28-34. Speed: passlog SEED=5 on a turn
  of fight 1 (five dice and the enemies' turn) the same to the frame (627 frames, the roll back
  at the same frame); a pass waiting for a key, flat out, 5,708 cycles (was 5,583); a pick still
  shows in 3 frames. Loading: the title at frame 770 (was about 725); a fight's art 3.2 s from
  the key (was about 2 s: the runs are read from the disk, 1.2 s). The rules page: its first
  line 0.37 s after ?, the page 0.93 s, the buttons 1.3 s; a page turn 0.7 s. The kit page
  1.0 s; closing a page puts the fight back in 1.2 s.
- 2026-11-01, the tuned tables (branch tuned, Tisple 34fde5b): the sim's numbers, fights and
  pools, the old shroom (an enemy and three moves in aux memory), the rules of 2026-11-01
  (`st.sum` on every add, the turn's end clearing the boosts, the Cannon's launch, Bad Milk's
  cost), three-digit badges, two-digit tray captions (`hud.DIGITS` to 15, in main memory).
  Squeeze 10 as before, now 16 functions (3,083 bytes) in the card's bank 1 (was 14, 2,336;
  `look.update` and `words.their_turn` joined); bank 2 11,882 of 12,288 (was 12,229); aux
  memory 6,142 at `$0800` and 17,058 at `$6000`; the disk 64,773 bytes. A pass waiting for a
  key in fight 1, flat out: 5,812 cycles (was 5,740, measure.py "900f:RETURN" 1500 1800).
- 2026-11-01, cards as data (branch cards-data, Tisple a48832d): every card a row of steps in aux
  memory (`content/cards.tsp`), run by `content/play.tsp`; then the nine chain cards and two
  charms. Before (d71ca80): squeeze 8, the functions 34,413 bytes (44,718 at the usual budget);
  the language card 12,280 of 12,288, its bank 1 2,129 (13 functions); the overlay region 2,795;
  aux memory 6,143 at `$0800` and 22,219 at `$6000` (2,357 left); the disk boots 69,379 bytes,
  64 sectors free, 16 tables on it. The old cards as data (1cf46d6): 43,522 bytes at the usual
  budget (1,196 less), but built at squeeze 10 (32,723 bytes; bank 1 643; aux 1,833 left; the
  disk boots 68,390). With the new cards: squeeze 10, 33,438 bytes (43,975 at the usual
  budget); the card 12,111 (177 left), bank 1 1,910 (11 functions, about 2.2 KB left); the
  overlay region 2,636; aux 6,141 at `$0800` and 24,003 at `$6000` (573 left at `$BDC3-$BFFF`:
  the next cards' steps and text want room found there); the disk boots 70,813 bytes, 64 sectors
  free, 19 tables (main's 12-page guide and the third statuses page). Why squeeze 10: Tisple
  weighs a `while` loop 8 trips, so
  every routine the steps loop calls (the log, the stacks, the hits) looks 8 times hotter than
  under the old match, and the size budget spends room copying them; with the loop taken out
  (one step a call) the old cards built at squeeze 8, and the new cards' code alone then needs
  10. Speed: a pass waiting for a key, flat out, 5,719 cycles (main 5,718; measure.py
  "950f:RETURN" 1500 3000); a pick shows in 2 frames and is drawn by 9 (was 2 and 11), a target
  in 3 (3), a play in 2 (2) (screenshots each frame); a scripted turn and the enemies' turn
  (passlog SEED=5, frames 1395-2300) 928 frames against 926: the heavier text passes a frame
  slower, others a frame faster. The hud's pill and the target's row read the stacks table
  straight (no `state.stack` call).
- 2026-11-01, the art pass (branch art-pass, Tisple 34fde5b): the chain cards' pictures, hud
  glyphs past `_`, the old shroom's figure and screen, the cards' shows and the chain cards'
  sounds. Room: the path's screen dropped the nightflap (in no fight), so sprite_aux went from
  10,240 to 9,232 bytes (the elite's screen: the hero's aux half and the old shroom's); CARDS and
  the rules page's lines moved to aux memory, the screens' tables by number. Aux memory 6,144 at
  `$0800` and 23,872 at `$6000` (704 left at `$BD40-$BFFF`, was 573); the language card 12,235
  of 12,288, its bank 1 2,538 (was 1,919: `main.next_key`, `hud.start_glyphs`, `tray.flush`,
  `words.their_turn`, `scene.restore_drawn` joined); the disk 71,419 bytes, 32 sectors free (was
  64), 21 tables. The main loop asks for a key only when one waits (`key_waiting`), which pays for
  the bank 1 crossing: a pass waiting for a key, flat out, 5,641 cycles (was 5,727; measure.py
  "950f:RETURN" 1500 3000); the scripted turn (passlog SEED=5, 1395-2300) 928 frames (928); a pick
  shows in 2 frames (2) and is drawn by 9 (13); the title at the same frame.
- 2026-11-01, all the art's engine (branch all-art, Tisple drive2 c3ea362): the two disks, the
  screens' tables per screen (`art/sprites` `tab`: 511 bytes for today's 43 sprites, 4 kinds, 4
  blocks; the 679 bytes of const tables gone), the hero's runs read once, the card pictures
  packed in aux memory (`draw/paint`: unpacked to main memory to draw), the cues' tables in aux
  memory (`sound.cue_byte`, one with_aux). Tisple's libraries load their code at their homes
  (820 bytes of main memory and the card freed). Before (64cf790): squeeze 10, 17 functions
  (3,255 bytes) in bank 1, the card 12,189; aux 6,143 at `$0800` and 24,012 at `$6000`; the disk
  boots 72,219 bytes in 10 segments, 32 sectors free, 21 tables on it. After: squeeze 10, 15
  functions (2,449 bytes) in bank 1, the card 12,141; aux 6,142 and 22,714 (1.3 KB more free);
  disk 1 boots 70,883 bytes in 10 segments, 160 sectors free, 2 tables (the title); disk 2: 39
  tables in tracks 1-12. Speed (measure.py, SEED 5): a pass waiting for a key 5,685 cycles (was
  5,717), the scripted turn's actions 11,968 (11,968) and the enemies' 6,129 (6,170). The first
  fight's art is on screen 312 frames after RETURN (was 296: the label and the hero's table are
  read first); later fights skip the hero's runs.
- 2026-11-02, the room pass (branch room-pass, Tisple 66f6679): the UI round merged onto the
  game-range numbers and three owner requests. Tisple: overlay groups read from disk 2
  (`:overlay_disk2`), records of disk tables in aux memory, zero page's second free run
  (`$01-$44`) used for globals (240 of 256 bytes now), bank 1 passing over a candidate too big
  for what is left. Catwiz: the reward's group and the fight's start on disk 2, the ending its
  own group, the items' table back in main memory (the fights read it every play), the
  faces' log sentences and the title jingle's notes in aux memory, cold setup code out of main
  (the machine check, the guard and the mouse in main, the sound card in `title.enter`, bank 1).
  Main memory, the card and bank 1: 12,032 of 12,282 in the card, bank 1 3,605 of 4,096; aux
  6,142 at `$0800` and 24,482 at `$6000` (about 1.4 KB left). Coloured text (the UI round) made
  text passes 20-30% slower; the masks now only for the blocks drawn and not white, white blocks
  drawn without masks (lib/dhgr_pixels `cells_white`), new colours redraw only what they change,
  and the log's older line moves up a row by a copy: the scripted turn (SEED 5, measure.py
  VSYNC=1) 22/33/30/51 passes in frames 1500-1560, 1560-1620, 1622-1700, 1700-1800 (game-range
  23/35/30/52); a pass waiting for a key, flat out, 5,940 cycles (5,845: the mouse is read every
  pass). `tools/passlog` no longer fits (its counting code needs about 300 bytes).
- 2026-11-02, the art round (branch room-pass): the King's figures (fight 10's sprites 26,460
  bytes, 596 to spare), the charms' pictures on disk 2 (paint's copy in resident code, the load
  in the fight's start group), `sprite_aux` cut from 10,752 to 10,688 bytes (fight 2 needs 10,671)
  to pay the aux memory the bigger page group took. The language card 12,135 (147 left), bank 1
  3,605; aux 6,144 at `$0800` and 24,549 at `$6000` (27 bytes left); a pass waiting for a key,
  flat out, 5,936 cycles in fight 1 (5,940), 6,521 in fight 10. An enemy's floating number now
  starts at row 32 at the highest (it rose into the map of the run and erased the zone's name).
- 2026-11-02, the disk catalog (branch faces): every face's and charm's record on disk 2
  (content/catalog), memory holds only the rows in play. Before (bfeffdc): squeeze 10, the
  functions 39,804 bytes (50,485 at the usual budget); the language card 12,135 of 12,282 (147
  left), bank 1 3,605 (491 left); aux 6,144 at `$0800` and 24,549 at `$6000` (27 left); disk 2
  tracks 1-16 (18 free). After: squeeze 10, 40,555 (52,695); the card 12,280 (2 left), bank 1
  3,444 (652 left: the card and bank 1 together 16 bytes less used); aux 6,143 and 20,963 (3,613
  left at `$B1E3-$BFFF`: 6.4 KB of faces' and charms' tables, text, steps and pictures gone, 2.8
  KB of it back as the eleven resident rows); disk 2 tracks 1-19 (15 free: the faces 43 sectors,
  the charms 12, the pools 2, the charm pictures' 5 gone). A face or charm more costs a sector
  of disk 2 and no memory. Speed: a pass waiting for a key, flat out, 5,915 cycles in fight 1
  (5,936), 6,500 in fight 10 (6,521); the scripted turn (SEED 5, VSYNC=1, keys 41 frames later
  to match the later start) 59/33/42/39/48/81/120 passes against 59/33/42/39/49/82/119. Loads: a
  record about a fifth of a second; a run's first fight ready 41 frames later (her seven
  records); the reward's prompt 26 frames later (the pool), its five cards one a step after it
  (about 1.5 s for all five), a face taken one record; a fight's start no longer reads the charm
  pictures. The reward's group 3,068 bytes (the pages' 3,099 sizes the region). Main memory and
  the card stay full: the next round's engine code wants room found (aux memory has it).
- 2026-11-02, the faces round's engine (branch faces-engine, Tisple 5ee9476): 52 faces, 23
  charms, their steps, hooks, statuses and rules (docs/faces.md "As built"). Room, as Tisple
  gained three things: a boot disk keeps `$BF00-$BFFF` (no zero page saved for a caller), a
  layout out of room with bank 1 code's data retried with those vars and the biggest first, and
  marked overlay roots that only share code stay apart. Catwiz: the title's set-up, its jingle,
  the sound card's set-up and finding disk 2 in the title's group (`title.begin`, the set-up at
  its step), the run's set-up in the fight's start (`battle.start_run`, `new_run`); the stacks
  as hers and an enemy's few; the statuses' SHOW and GLYPH in aux memory (read only for a stack
  not 0); lets set before they are read moved to fixed scratch: items' row fields (`$0272`,
  `$0310`, `$03CD`), the action's and the bolt's (text page 1's holes left by the cards'
  firmware: never `$xx7C`, slot 4's, the mouse's), and in the 6502 stack page's bottom
  (`$0100-$01A7`: charms' kinds, the meter's record, blit's blocks, the offer's draws, the hooks'
  queue, text segments, a record's top, the side's glyphs; a session's stack never went below
  `$01DA`). Before (113e226, Tisple 3719474): the card 12,280 of 12,282, bank 1 3,523, aux
  21,066 at `$6000`, disk 2 tracks 1-19. After (with the looks and the art merged): the card
  12,180, bank 1 3,681 (25 functions), aux 6,142 at `$0800` and 23,431 at `$6000` (1,145 left),
  disk 2 tracks 1-24 (10 free); the overlay region 3,092 bytes. Speed (measure.py): a pass
  waiting for a key 5,913 cycles in fight 1 (5,917), 6,496 in fight 10 (6,498); the scripted
  turn (SEED 5) ends at frame 1911 as before. A fight's art is up about 10 frames later (the
  fight's start group reads the run's set-up). `battle.enter` sets `state.hitstop` (scratch now:
  battle.step reads it first).
- 2026-11-03, the rest and the heal's hearts (branch rest, on fixes 2dfc658): the nap's step and
  its words gone; the picked card's stage preview drawn in the reward's step with its text (it was
  battle.draw's a frame later: `reward.refresh`, `staged` and the `card_*` helpers left resident
  code); the nap and plus1 pictures out of aux memory. Before: the boot 73,311 bytes, the card
  12,278 of 12,282, bank 1 3,681 (25 functions, `blit.draw` among them), aux 6,142 at `$0800`
  and 23,526 at `$6000`, the overlay region 3,160 (the reward's group sized it; the pages'
  3,150). After, with the hearts: the boot 72,937 (374 less), the card 12,281 (the layout fills
  it), bank 1 3,545 (25 functions; `blit.draw` back in bank 2, 11,566 crossings a run against
  12,670), aux 6,144 and 23,283 (243 less: 1,293 left at `$6000`), the overlay region 3,232 (the
  reward's group 3,223 now holds the preview's code; it is read from disk 2, 27.7 frames). The
  sprite room is as it was (no new sprite). A pass waiting for a key, flat out, 5,920 cycles in
  fight 1 (5,915). The hearts cost about 31,000 cycles over the 40 frames they rise (a heal of
  hers, measured with `tools/measure.py` and a profile: the scene's boxes and fills).
- Item lines may come in parts split by `|` (`text.next_part`): what the card always does, then
  each extra with its condition first. A picked die's other parts use the log's two rows while it
  is picked (`log.taken`, words.refresh puts the log back); between fights and on the kit page
  they take the slot's base row.
