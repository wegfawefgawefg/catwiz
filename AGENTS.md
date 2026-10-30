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
- Explicit dispatch: effects and enemy actions are a `match` on a kind enum, in one obvious
  place (`content/effects.tsp`). Function pointers only where a table is clearly the plainer
  form, and say so where you use one (none so far).
- No generic engine layers or premature reuse. Write what this game needs, directly.
- Plain comments that say what and why.
- `tisple fmt -w` the files you touch.

## Content

- Game rules content (dice, enemies, statuses, encounters, the hero, effects) is hand-written
  Tisple in `content/`: plain tables of structs written out, and the `match` on the effect
  kind. No macros, no separate data format, no parser, no Python step for it.
- The engine (`battle/`, `draw/`) never names a specific enemy, die, effect or status. It reads
  the tables and calls the hooks in `content/statuses.tsp` and `content/effects.tsp`, so the
  content files can be replaced without touching the engine.
- No text, names or item lists from other games. Our own names and art.

## Text

- The screen is all graphics (double hi-res, no mixed text window). The four text lines at the
  foot (rows 160-191) are drawn into the backdrop page by `draw/text.tsp` and copied onto both
  pages like any hud part. The font is the 35-column one in whole colour pixels (`FONT35`, a
  4-pixel cell a character, white in every look, drawn with lib/dhgr_pixels' cells);
  `FONT_35` in `draw/text.tsp` is the one place that switches to the 40-column dot font
  (`art/font40`, violet and green in the flat colour look). Strings are 35 characters at most
  either way. A line is drawn again only when it changed.
- `battle/words.tsp` writes the top two rows (the die picked: name and what it does; else the
  target), `battle/log.tsp` the bottom two (what just happened, in sentences).
- Strings are plain ASCII in sentence case in the code and the content tables (names
  capitalised, a die's name in capitals, inverse); `#` in a face or move text is its number. The
  hud font (badges, card captions, buttons: `tools/dhgr/game_hud.py`, 3 x 5 pixels) has ' ' to
  '_', and some punctuation there is icons (heart, sword, shield, star and the statuses).

## Art

- Double hi-res (2026-10-30): `tools/dhgr/`, run `python3 tools/dhgr/make.py` (previews to
  `shots/dhgr/`, byte tables to `art/dhgr/`, memory per fight in `art/dhgr/memory.txt`) and
  `python3 tools/dhgr/game.py` (or `make.py game`) for the game's tables in `game/art/`
  (generated: never edit by hand; formats at the top of `game.py`). Drawn at 140 x 192 wide
  pixels (a pixel is 4 dots, 1.83 rows wide).
- Sprites are cut on 7-pixel steps (4 bytes: aux, main, aux, main) so their colours hold, and
  move on them (2 byte columns a step); up and down at any row. Each half is stored as lib/dhgr
  runs (skips, opaque runs, edged runs with masks) and packed (`tables.packed_bytes`, in aux
  memory); a screen's kinds are unpacked when it starts (`draw/blit.tsp`): the main halves into
  the aux language card's bank 2, the aux halves into its bank 1, the rest of bank 2, then
  `sprite_aux` in aux memory, as they fit. Frames are whole (no face patches): a mood shows as a
  kind's frame by role (idle, attack, hurt, happy, surprised, flap; `battle/look.tsp`), its idle
  one when it has none.
- Fighters are drawn once in materials and lit per zone (day, dusk, night: `tools/dhgr/light.py`,
  a palette swap plus rims by code); the build carries the zone of its fights (day) lit
  offline. Fights 1-4 are day, 5-7 dusk, 8-10 and the boss night.
- The backdrops are whole screens with the fighters' shadows (`game.py`, `fight_picture`), the
  title one picture with its letters' rim in four colours as sprites (the glow).
- The hud is drawn in whole pixels (`draw/pix.tsp`, lib/dhgr_pixels): badges (`draw/badge.tsp`,
  looks over the stage), the tray's cards (spans and rectangles from `art/hud_data`, the pictures
  from `art/icons`), the buttons, the text.
- NTSC (the TV look) is the real target and the web player starts in it (`"look": "ntsc"` in
  `tools/phone/catwiz.json`); judge the art and take screenshots there first, colour second. In
  NTSC every colour but black, white and grey shows fine stripes, the dark ones worst: big areas
  white or black (the day is a white page, the night a black one), then the light tier (light
  blue, aqua), darks in small pieces, flat fills, no dithered areas.
- Faces that carry state, stylized silhouettes with depth, light backdrops behind dark actors.
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
- The music is `game/sound/songs.tsp` (lib/mockingboard_song's text), each song `:in aux` and
  copied into main when it starts (`sound.PLAYING` bytes: keep it at the largest song's size,
  which `tisple expand` shows).
- `sound.setup` installs lib/auxmem's guard, so aux copies run with interrupts on: the
  Mockingboard's handler runs with main memory in even when a tick lands in a copy.
- `tisple machine ... --mockingboard 4 --wav x.wav` plays and saves it; `MB=4` makes
  `tools/measure.py` measure with the card in.

## Building and running

```sh
TISPLE=~/Coding/LangDev/tisple-catlib/build/tisple   # Tisple's branch catwiz-dhgr-lib
$TISPLE build                        # build/catwiz.dsk; $TISPLE build --disk x.dsk --asm > x.asm
$TISPLE machine --disk build/catwiz.dsk --frames 1000 --keys "700f:RETURN" --screenshot shots/x.png
$TISPLE machine --disk build/catwiz.dsk --frames 1000 --keys "700f:RETURN" --ntsc --screenshot x.png
```

- The game needs Tisple's branch `catwiz-dhgr-lib` (lib/dhgr's runs and `FROM_CARD`,
  lib/auxcard, lib/dhgr_pixels, unpacking into the aux card, `dhgr_text2`) until it is merged.

- `tisple.project` makes a bare `tisple build` (anywhere in the repo) `tisple build
  game/main.tsp --origin 0x8000 --disk build/catwiz.dsk`, and `tisple run` that plus booting it
  with `--mockingboard 4 --scale 2 --taps tools/phone/catwiz.json` (needs Tisple 71899ed or
  later). When the program does not fit, Tisple builds it with a tighter size budget
  (squeeze levels) and says which functions it kept as calls instead of copying them into
  their callers; `TISPLE_SIZE_NOTES=1` lists what the budget weighs. The game keeps no list of
  its own (it had `game/noinline.txt` until 2026-10-30).
- The boot shows LOADING, then the title by frame 600 (10 s); a fight's art unpacks in about
  a second while the title still shows (the music stops first: the card's halves unpack with
  interrupts off).

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

Self-booting disk, origin `$8000`. Double hi-res: page 1 `$2000`, page 2 `$4000` and the
backdrop copy `$6000`, each in both main and aux memory, all reserved (48 KB). Code and data
fill `$8000-$BEFF`, then `$0BE0-$1BFF`, then the language card (and its bank 1 for code, when
the program does not fit). Tisple's libraries keep `$1C00-$1D89` (lib/unpack, both memories),
`$1D8A-$1DDC` (lib/auxcard, main) and `$1E00-$1FFE` (lib/dhgr, both). The packed art and the
songs live in aux memory; a screen's sprites in the aux language card and `blit.sprite_aux`.

- Scratch that is set before it is read lives at fixed addresses the layout does not use, and
  is not zeroed at the start: `$0200-$02E3` (state.drawn), `$0800-$0BDF` once the boot loader
  is done (the song buffer, the log, the text line and what each line shows, the reward's six,
  the hud's pixel row and its bytes), and text page 1 (`$0400-$07FF` but `$0478-$047F` and the
  other screen holes: the rects, the scene's boxes, the looks, the stacks, the actors, the
  floaters, the dice, the badges, the counter). Each such let says so. The screen shows no text
  page (`dhgr_text2` is not imported), so both are free.
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
