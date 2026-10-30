# Witchdog

An Apple II hi-res dice roguelike in Tisple ][ (github.com/wegfawefgawefg/tisple), a toy to
prove the compiler and an engine. Private repo. Enhanced IIe with 128 KB is the target.

## Code style: C+-

From ~/Coding/AGENTS.md and the Mans In My House rules, in Tisple terms:

- Files 300-500 lines at most (aim under 450), one clear job each, in flat domain folders:
  `battle/`, `draw/`, `sound/`, `content/`, `title/`, `art/` (generated). No `utils`,
  `common` or `misc` files.
- Ultra low abstraction: plain structs and free functions. One game state: `state.tsp`
  holds all of it as top-level lets (`state.actors`, `state.phase`, ...). Not one struct:
  Tisple splits a top-level array of structs into a byte table a field (`LDA hp,X`) but packs
  one inside a struct, so every access would multiply. Drawing keeps its own scratch in
  `draw/scene.tsp`. A thin `main.tsp` whose loop reads top to bottom in commented paragraphs.
- Hot arrays stay split: no `addr_of` on an element of `state.actors`, `state.looks` and the
  like (taking an element's address packs the whole array). Pass indices, not pointers.
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

## Art

- `tools/art/*.py` draw the actors, dice pictures, backdrop and title, and
  `tools/.venv/bin/python tools/art/export.py` writes them to `game/art/*.tsp` (generated:
  never edit by hand; split to stay under 500 lines) and previews to `shots/art/`. Offline
  asset tools in Python are fine; keep them plain. Throwaway scripts need less rigour.
- Faces are patches over the body. Moods whose changes stay inside the idle silhouette share
  one box (`KIND_PATCH_SWAPS`), so changing between them is one small blit; keep new faces
  inside the head when you can.
- Hi-res rules: 2-px strokes, dither in pixel pairs, light backdrops behind dark actors,
  stylized silhouettes with depth, faces that carry state. NTSC artifact colour is the real
  target; check the clean look for readability. Actors sit on even byte columns so their
  colours hold (a 1-byte move swaps violet and green).

## Building and running

```sh
TISPLE=~/Coding/LangDev/tisple/build/tisple
cd game && $TISPLE build main.tsp --origin 0x8000 --disk ../build/witchdog.dsk
$TISPLE machine --disk ../build/witchdog.dsk --frames 900 --keys "700f:RETURN" --screenshot ../shots/x.png
```

- Never open windows on the owner's display; run the machine headless and look at
  screenshots (`shots/`).
- Frame costs: `tools/.venv/bin/python tools/measure.py "1000f:RETURN" 1300 1600` builds a
  copy that runs flat out and prints cycles a pass of the main loop between two frames;
  `VSYNC=1` measures the real game, extra `"file|old|new"` arguments try an edit in the copy.
  A frame is 17,030 cycles.
- `tisple build --disk` gives no `--asm` listing (2026-10-30); for one, build a copy of the
  compiler with the flag added to `src/disk/disk_build_command.cpp`, never in the owner's
  checkout.
- At most 8 build jobs and 8 processes at once.
- Apple ROMs live in `~/.local/share/tisple/roms`; never commit or copy them into the repo.
- No maintained test suites; one-off runs and screenshots are welcome.
- Commit focused, verified chunks; stage explicit paths, never `git commit -a`.

## Memory

Self-booting disk, origin `$8000`: hi-res page 1 `$2000`, page 2 `$4000`, the backdrop copy
`$6000`, all reserved. Code and data fill `$8000-$BEFF`, then `$0B00-$1FFF`, then the
language card. The backdrop and title pictures live in aux memory and are copied in with
lib/auxmem. 2026-10-30: main has about 2 KB left, the card about 3 KB, aux about 6 KB.
