# Catwiz

An Apple II hi-res dice roguelike in Tisple ][ (github.com/wegfawefgawefg/tisple), a toy to
prove the compiler and an engine. Public repo, shelved 2026-10-30 with two fights of ten. It
started as Witchdog (a dog witch hero); the old name stays only in history notes. Enhanced
IIe with 128 KB is the target.

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

- The battle runs in mixed mode: the picture's top 160 rows and four rows of 40-column text
  (`draw/text.tsp`). The text is written to text pages 1 and 2, since the screen flips hi-res
  pages and each shows its own text page. `battle/words.tsp` writes the top two rows (the die
  picked: name and what it does; else the target), `battle/log.tsp` the bottom two (what just
  happened, in sentences).
- Strings are plain ASCII in the code and the content tables; `#` in a face or move text is its
  number. The ROM font shows any character; the hi-res hud font (`pen`) only ' ' to 'Z', and
  some punctuation there is icons (`tools/art/icons.py`).

## Art

- `tools/art/*.py` draw the actors, dice pictures, backdrop and title, and
  `python3 tools/art/export.py` writes them to `game/art/*.tsp` (generated:
  never edit by hand; split to stay under 500 lines) and previews to `shots/art/`. Offline
  asset tools in Python are fine; keep them plain. Throwaway scripts need less rigour.
- Faces are patches over the body. Moods whose changes stay inside the idle silhouette share
  one box (`KIND_PATCH_SWAPS`), so changing between them is one small blit; keep new faces
  inside the head when you can.
- Hi-res rules: 2-px strokes, dither in pixel pairs, light backdrops behind dark actors,
  stylized silhouettes with depth, faces that carry state. NTSC artifact colour is the real
  target; check the clean look for readability. Actors sit on even byte columns so their
  colours hold (a 1-byte move swaps violet and green).

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
TISPLE=~/Coding/LangDev/tisple/build/tisple
$TISPLE build                        # build/catwiz.dsk; $TISPLE build --disk x.dsk --asm > x.asm
$TISPLE machine --disk build/catwiz.dsk --frames 1000 --keys "700f:RETURN" --screenshot shots/x.png
```

- `tisple.project` makes a bare `tisple build` (anywhere in the repo) `tisple build
  game/main.tsp --origin 0x8000 --disk build/catwiz.dsk`, and `tisple run` that plus booting it
  with `--mockingboard 4 --scale 2 --taps tools/phone/catwiz.json` (needs Tisple 71899ed or
  later). When the program does not fit, Tisple builds it with a tighter size budget
  (squeeze levels) and says which functions it kept as calls instead of copying them into
  their callers; `TISPLE_SIZE_NOTES=1` lists what the budget weighs. The game keeps no list of
  its own (it had `game/noinline.txt` until 2026-10-30).
- The boot shows LOADING for about 12 s (the title's pictures go to aux memory), then the title.

- Never open windows on the owner's display; run the machine headless and look at
  screenshots (`shots/`).
- Frame costs: `python3 tools/measure.py "1000f:RETURN" 1300 1600` builds a
  copy that runs flat out and prints cycles a pass of the main loop between two frames;
  `VSYNC=1` measures the real game, extra `"file|old|new"` arguments try an edit in the copy.
  A frame is 17,030 cycles.
- `tisple build --disk ... --asm` prints the listing (2026-10-30).
- At most 8 build jobs and 8 processes at once.
- Apple ROMs live in `~/.local/share/tisple/roms`; never commit or copy them into the repo.
- No maintained test suites; one-off runs and screenshots are welcome.
- Commit focused, verified chunks; stage explicit paths, never `git commit -a`.

## Memory

Self-booting disk, origin `$8000`: hi-res page 1 `$2000`, page 2 `$4000`, the backdrop copy
`$6000`, all reserved. Code and data fill `$8000-$BEFF`, then `$0C00-$1FFF`, then the
language card. The backdrop and title pictures live in aux memory and are copied in with
lib/auxmem, as are the songs.

- Page `$0B` is reserved whole (`draw/text.tsp`): text page 2's last two mixed-mode rows are at
  `$0B50` and `$0BD0`, and a disk segment loads whole pages, so anything placed beside them was
  overwritten when the next segment loaded.
- Scratch that is set before it is read lives at fixed addresses the layout does not use, and
  is not zeroed at the start: `$0200-$02D7` (state.drawn), `$0800-$0AFF` once the boot loader
  is done (the song buffer, the log, the text line, the dice, the floaters, the draw scratch;
  not `$0A50-$0A77` or `$0AD0-$0AF7`, text page 2's rows), and the rows of text page 1 the
  mixed screen never shows (`$0400-$05F7` but `$0478-$047F` and the other screen holes, and
  `$0600-$064F`, `$0680-$06CF`, `$0700-$074F`, `$0780-$07CF`). Each such let says so.
- No multiply or division routines: `(* a b)` and `/` on variables pull in tables and routines
  (1 KB for the quarter squares); the game multiplies by constants and uses shifts. Watch the
  listing for `rt.` calls.
- 2026-10-30, at the shelving (Tisple 02e5697, squeeze 3 of 10): main memory full of code
  (`$8000-$BEFF` and `$0C00-$1FFF`, data spills to the language card); the language card
  11,449 of 12,288 bytes (839 left), after the boss's pictures (1,803 bytes and their tables)
  were left out of the build (`LEFT_OUT` in `tools/art/export.py`: put them back with the final
  fight); aux 41,907 bytes from `$0800` (about 5.2 KB left); zero page 179 of 256. A pass of
  the battle's main loop flat out: 13,304 cycles (0.78 frames).
