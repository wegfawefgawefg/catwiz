# Catwiz memory map and audit

2026-11-03. Catwiz main at 37275af, built with Tisple 30e74b1 (before Tisple merged its
`load-music` branch). Pictures: `docs/memory-map.png` (every space and both disks) and
`docs/memory-map-low.png` (zero page and the stack page a byte a cell, then `$0000-$1FFF` of
both memories). Every number here comes from that build: the summary, the `--asm` listing, the
data notes (`TISPLE_DATA_NOTES=1`), `--tables`, `build/catwiz.vars.json`, the loader's table on
`build/catwiz.dsk` and `art/dhgr/memory.txt`. `python3 tools/memmap/memmap.py` rebuilds and
redraws both pictures and writes `build/memmap.txt` (every item and hole), for comparing after
the memory pass.

Moving target: Catwiz's `load-music` branch is changing memory right now. Its notes say Tisple's
homes grew 16 bytes (lib/auxcard to `$1DA6`, lib/dhgr's runs end at `$1F50`), zero page `$FF`
is taken, the title jingle left the with_aux mirror for the title's group (166 bytes), and the
four lets that held `$0400` became one, `state.aux_page1`. Main does not build with Tisple as it
is now (4439026: "does not fit even with the tightest size budget"); it needs that branch.
Redraw after it merges; the tool already reads `state.aux_page1`.

## Headline

- Main memory and the card are full of code at the tightest budget. Squeeze 10 of 10, 26
  functions in bank 1, five overlay groups. Main memory has 69 bytes free in 18 holes (the
  biggest 35). The card has 12 bytes (`$FFEE-$FFF9`). Bank 1 has 421.
- Aux memory has 1,566 bytes free: 1,271 at the top (`$BB09-$BFFF`), 256 in page 2, and 39
  bytes in 8 holes. The aux card is all sprite room, filled per fight; fight 10 has 496 bytes
  to spare across its three sprite areas.
- The layout is not wasteful in the large; it is crowded and hand-placed. 118 `:address` lets
  in Catwiz (28 more in Tisple's lib) are the owner doing the linker's job in low memory. Most
  of the holes are between them.
- The biggest reclaimable pieces of the tight memories are code. 2,238 bytes of resident code
  are called only from overlay groups, about 1 KB of it movable without growing the overlay
  region, and about 0.9 KB of main and the card holds set-up code and data used once. That is
  where a memory pass gets room, more than in the data.

## Totals per space

Bytes, from `build/memmap.txt`. "Machinery" is Tisple's own: stubs, the disk reader, the
unpacker, the guard, startup, runtime scratch. "Hardware" is the stack, vectors and the screen
holes the cards' firmware owns.

| Space | Code | Tables | Variables | Art | Sound | Screens | Machinery | Hardware | Free | Holes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Main `$0000-$BFFF` | 23,532 | 411 | 2,382 | 889 | 1,112 | 16,384 | 4,252 | 121 | 69 | 18 |
| Card bank 2 + `$E000` | 8,929 | 1,086 | 294 | 1,524 | 114 | 0 | 323 | 6 | 12 | 1 |
| Card bank 1 | 3,675 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 421 | 1 |
| Aux `$0000-$BFFF` | 8,008 | 6,338 | 3,827 | 11,031 | 493 | 16,384 | 929 | 512 | 1,566 | 10 |
| Aux card bank 2 + `$E000` | 0 | 0 | 0 | 12,272 | 0 | 0 | 0 | 16 | 0 | 0 |
| Aux card bank 1 | 0 | 0 | 0 | 4,096 | 0 | 0 | 0 | 0 | 0 | 0 |

- The card's code includes the overlay region (3,226 bytes at `$E71E`); resident code there is
  5,703 bytes. Aux code is the with_aux mirror (2,492) and three group images (5,516).
- Aux "unused" (64 bytes, not in the table): `$0300-$033F`, the part of `auxmem.home_aux` below
  the guard's copy.
- The build's own count: code 44,629 bytes (34,394 resident with Tisple's stubs and startup,
  10,235 in group images), data 28,449; functions and runtime 42,770 bytes at squeeze 10
  against 54,797 at the usual budget. Zero page 240 of 256 (frames 123).

What I would call waste, per space:

- Main: 34 bytes in 17 holes under 16 bytes each (too small for anything but a byte or two).
  Set-up code that runs once and stays: 474 bytes at the top of `main.main` (the machine check
  151, the guard's install 35, the mouse found and set up 271) and Tisple's startup 108.
- The card: the zero-page image (107, read once by startup), `auxmem.GUARD` (108, copied once
  into page 3), `mockingboard_player.page.patch` (137, run by startup and the sound card's
  set-up). 352 bytes of once-only code and data in the tightest spot.
- Aux: 64 reserved and never used; 26 bytes of page-alignment holes between tables.
- Disk 1: 59 sectors of rounding and 58 pages of zeros read at boot (below).

## Fragmentation

- Main: 18 holes, 69 bytes. Zero page 12 bytes (`$00`, `$47`, `$4D-$4F`, `$5B-$5E`, `$C3-$C4`,
  `$FF`: named by no let and no line of the listing; the build's count says 16 free). The stack
  page 6 (`$017C-$017F`, `$019E-$019F`, between the scratch lets). Page 2: `$02FE-$02FF`. Text
  page 1: `$0477`, `$0646-$0668` (35, the biggest), `$0675-$0677`, `$0777`, `$07F2`,
  `$07F6-$07F7`. Text page 2: `$098E-$098F`, `$09B6-$09B7`, `$09DE-$09DF`. Nothing above
  `$0BDF` is free in main memory.
- `$0646-$0668` is left from the kit round: AGENTS.md says the glyph tables take
  `$0600-$0668`, but `text.glyph_at` is 70 bytes (`$0600-$0645`) and `text.cells` moved to
  `$0424`.
- The card: one hole, `$FFEE-$FFF9` (12), under the 6502 vectors. Bank 1: one, `$DE5B-$DFFF`.
- Aux: `$BB09-$BFFF` (1,271), `$0200-$02FF` (256), `$07F3-$07FF` (13), and 7 holes of 1-12
  bytes between page-aligned tables in `$99FF-$A4FF`.
- The stack page: the stack proper starts at `$01A8`. AGENTS.md says a session never went below
  `$01DA`, so about 50 bytes of it are never touched in practice; that is a measurement, not a
  guarantee, so the map counts it as stack.

## The tightest spot: the language card

`$D000-$FFFF` (bank 2 and the shared 8 KB), 12,288 bytes, 12 free:

- `$D000-$E656` resident code, 5,703 bytes: the tray, the kit card, the foes' moves, the
  action, the turn, words, boxes, the sound player's page patch.
- `$E657-$E71D` runtime (92) and the zero-page image (107).
- `$E71E-$F3B7` the overlay region, 3,226 bytes, sized by the reward's group (3,223); the pages'
  group is 3,150.
- `$F3B8-$F3F7` frames in memory (64).
- `$F3F8-$FFED` data, 3,062 bytes: the 35-column font (760), the hud font (568), `dhgr.ROW`
  (448), the card shapes' ends (160), lib/dhgr_pixels' MONO tables (512), `state.stacks` (120),
  `auxmem.GUARD` (108) and about 50 single-byte state lets.
- `$FFFA-$FFFF` the vectors.

The 12 bytes are not room in any useful sense: the layout fills the card first-fit and the 12 are
what the last let did not fit. The fonts, the row table and the MONO tables are read on every
drawn glyph and row, so they belong there. What does not: the zero-page image, GUARD and the
page patch (352 bytes, all once-only).

Bank 1 (`$D000-$DE5A`): 26 functions, 3,675 bytes (3,645 of function bodies), 421 free. The
build says the crossings cost about 238,680 cycles a run (11,934 of them). The stubs that make
them are in main memory: 580 bytes at `$806C`, 26 into bank 1 and 32 back out, 10 bytes each.

## Duplication

- The with_aux mirror, 2,492 bytes in both memories (`$6000-$69BB`): 55 functions and the
  overlay copy, whole, because each runs with RAMRD on. Needed for what really copies from aux
  (lib/auxmem's moves, `dhgr.copy`, `dhgr.copy_box`, `dhgr_pixels.read`, the overlay copy). Not
  needed in its present size: 24 of them are 12-byte accessors for one byte of an aux table, and
  several are bigger functions mirrored whole for one read (`sound.cue_byte` 193, `tray.shift`
  165, `sfx.play` 112, `paint.picture` 99, `stage.backdrop` 78, `disk2.has_label` 71). A
  function with a with_aux is also barred from bank 1 and from overlay groups, which is the
  bigger cost (below). The `load-music` branch already moved the jingle out this way.
- lib/unpack (394) and lib/dhgr's runs (343) in both memories at `$1C00` and `$1E00`: needed;
  they run with RAMRD on.
- The guard three times: main `$0340` (108), aux `$0340-$03FF` (192, its copy and the
  vectors), and `auxmem.GUARD` in the card (108), the source the install copies from. The first
  two are needed. The card's copy is read once at start.
- The title's picture, runs and song on both disks (3,991 bytes each): needed, the first title
  shows before disk 2 is found. Disk space is not short.
- The overlay groups' code is in the region and in its image: that is how overlays work. The
  three aux images take 5,516 bytes of aux memory for code that is in main only while it runs.

## Reserved but rarely used

- lib/disk's reader and work, `$1400-$1BFF`, 2,048 bytes of main memory, used only while a disk
  is read (a fight's art, a record, a song, a rules page, a group from disk 2). It has to be
  resident; it is the largest single piece of main memory after the screens.
- The overlay region holds one group at a time. With the title's group in (1,603) it has 1,623
  bytes idle; the fight's start (1,496) 1,730; the ending (763) 2,463. That idle room is the
  cheapest code room in the program: a group may grow to 3,226 bytes without costing a byte
  elsewhere.
- `sound.playing` (`$0800`, 395): sized by hand to the biggest song (TITLE, 395); the battle's
  song is 307.
- Aux text page 1, `$0400-$062F` (560): the rules page, a song read from disk, a hat trick's
  record, disk 2's label, never two at once. `$0630-$07F2`: the log's history (11 lines of 41
  bytes). AGENTS.md still says 13 lines of 35 to `$07F6`.
- Aux `$0300-$033F` (64): reserved by `auxmem.home_aux`, never used.
- `sprite_aux` (10,824 aux): fights 1, 4, 6, 8, 9 and 11 use 8,021 of it (the hero's halves);
  the rest of it is the picture's buffer at a fight's start and the offers' records between
  fights, so it is not idle.
- The hi-res pages' screen holes: the last 8 bytes of each 128 are not shown, 512 bytes a page in
  each memory, 2,048 in all. Nothing uses them. Whether lib/dhgr's whole-page copies and the
  picture's unpack write them I did not check; treat them as unsafe until someone does.

## Code that could move out of resident memory

From the listing's calls: resident functions whose every caller is in an overlay group
(transitively), so nothing resident needs them.

| Called only from | Functions | Bytes | Why resident now |
| --- | --- | --- | --- |
| the title and the fight's start | `blit.place_blocks` 329, `blit.into_card` 160, `stage.picture` 132, `packs.part` 87, `unpack.aux_to_card` 62 | 770 | shared by two groups that take turns, so Tisple keeps it resident |
| the reward and the pages | `kit.card` 461, `charms.mark` 18 | 479 | shared; the reward's group plus this would outgrow the region |
| the title | `music.jingle` 166, `disk2.has_label` 71 | 237 | with_aux (the jingle moves on `load-music`) |
| the fight's start | `stage.backdrop` 78, `stage.runs_of` 23, `encounters.count`, `.zone` (12 each) | 125 | with_aux |
| the ending | `offer.pool_byte` | 24 | with_aux |
| the reward | `encounters.other` | 12 | with_aux |
| the title, fight start, pages | `dhgr.copy_box` 117, `screen.copy_box` 62 | 179 | shared; with_aux |
| two or more groups | `sound.song` 101, `charms.refresh` 80, `encounters.spot_enemy` 64, `meter.read` 38, `offer.ok` 33, `charms.holding` 32, `charms.grow_hp` 31, `offer.levels` 21, `encounters.elite` 12 | 412 | shared |

2,238 bytes in all.

- The title's and the fight start's 770: if each group carried its own copy, the title's group
  would be about 2,370 bytes and the fight start's about 2,270, both under the region's 3,226.
  `packs.part` (87) has a with_aux and would stay; the other 683 bytes would leave resident
  memory. The cost is 683 bytes more in the title's aux image and three sectors on disk 2.
  Tisple does not do this today (marked roots that share code keep it resident).
- With_aux functions only one group calls: reading their aux bytes through `auxmem.read`
  instead lets them join their group, as `load-music` did with the jingle. `disk2.has_label`,
  `stage.backdrop`, `stage.runs_of`, `offer.pool_byte`: about 200 bytes of resident main memory
  and the same in the aux mirror. The 12-byte accessors are not worth it (the call costs as
  much as the accessor). Tried in the memory pass (below) and left as it was: each cost speed.
- The set-up code in `main.main`: done in the memory pass (below), as a group of its own,
  `title.setup`, not in the title's group.
- Disk overlays for more code: the ending's group (763, in aux) could be read from disk 2 like
  the reward's, a short read at a fight's end. That frees aux, not main.

## Data that could move to aux or the disk

- The card effects, `sound/card_fx` (379 bytes: 362 in `$10BE-$1281` among the player's tables,
  and `scratch`, 17, at `$BFEF`): the handler reads the
  playing effect, so all of them stay resident. lib/mockingboard plays one at a time; the one
  playing could be copied from aux into a buffer of the longest effect's size (17 bytes, `scratch`) when it
  starts, freeing about 360 bytes of main memory. `load-music` is rewriting `sound.tsp` now, so
  this waits for it.
- `auxmem.GUARD` (108, the card) to aux memory or the title's image: it is read once.
- The zero-page image (107, the card): startup reads it before anything else runs, when the
  overlay region is still empty; Tisple could put it there.
- `mockingboard_player.page.patch` (137, the card): Tisple keeps patch functions resident; it
  runs at startup and at the sound card's set-up.
- Aux memory: the title's group (1,603) could be read from disk 1 (Tisple has no images on the
  boot disk yet); the pages' group (3,150) from disk 2 at the cost of a slower page open (the
  owner kept it in aux for speed); `items.records` keeps 11 rows of 256 bytes, while records
  use 176 bytes on average (faces, the largest 244) and charms 152 (the largest 199), so packed
  rows would save about 800 bytes but need an offset table.
- Small leftovers: `$0646-$0668` in text page 1 (35), aux page 2 (256) and `$0300-$033F` (64)
  for small aux tables.

## The disks

- Disk 1 boots 10 segments, 293 pages, in tracks 1-23 (22 tracks; 17 is DOS's catalog). Each
  segment starts a track of its own, so 59 sectors are rounding: `$1C00` and `$1E00` (2 pages
  each) and the reader at `$1700` (5) take a track each, `$0B00` (9 pages) a track. 58 of the
  293 pages are zeros: `sprite_aux` is 43 pages of the aux `$6000` segment and `items.records`
  11 of the `$0800` one, lets with no value that load from the disk because they sit between
  pieces that do; the other 3 of the `$0800` segment's 14 zero pages are the unpacker's and the
  runs' aux homes, 1 the end of bank 1. The loader takes about two turns a track
  (docs/disks.md).
- Tracks 24-32 are free (144 sectors). Tracks 33-34 hold the title's three tables in 17
  sectors; 15 sectors of track 34 hold nothing.
- Disk 2: 380 of 544 slots, tracks 1-24 (164 sectors free). The art is tracks 1-12, the catalog
  12-21, the rules 21-23, the two disk overlay groups 23-24.
- `$0B00-$13FF`, `$1400-$16FF` (disk.work, reserved), `$1700-$1BFF`, `$1C00-$1DFF` and
  `$1E00-$1FFF` are contiguous. As one segment (zeros over disk.work at boot) they would take 2
  tracks instead of 4 and 1 segment instead of 4. With `sprite_aux` past the end of what aux
  memory loads, the aux `$6000` segment would drop 43 pages (6 tracks to 4). Together: the boot
  program from 22 tracks to 18, and 7 of the 10 segments used. `items.records` cannot leave the
  loaded run as easily: aux memory has no room for it past the end.

## What makes the layout hard to work with

- Hand-placed scratch. 118 `:address` lets in Catwiz put state in the stack page, pages 2 and 3,
  text page 1 around the screen holes and the mouse's slot, and text page 2. Each new one needs
  an address found by hand, and the holes between them are what is left of main memory. The
  layout cannot see the four pointers into aux text page 1 at all.
- The prose in AGENTS.md "Memory" has drifted from the build: lib/dhgr's runs are
  `$1E00-$1F56` (it says `$1F32`), code fills `$8000-$BFFF` (it says `$BEFF`), the log's history
  is 11 lines of 41 to `$07F2`, the glyph tables end at `$0645`. Use the tool's output instead
  of the prose for addresses.
- Everything is at a limit at once: squeeze 10 of 10, bank 1 within 421 bytes, the card within
  12, the overlay region sized by the reward within 3 bytes of its group, 10 of 10 disk
  segments, `sprite_aux` within 1 byte of fight 2's need, fight 7's sprites within 3 bytes of
  bank 2. A small change moves functions in or out of bank 1 (with cycles in places nobody
  touched) or breaks the build.
- First fit in declaration order: what is free moves around with every change, and the card's
  12 bytes say only that the next let did not fit.
- Sizes kept in step by hand: `sound.PLAYING` with the biggest song, `sprite_aux` with
  `tools/dhgr/memory.py`, `HIST_AT` and the rules buffer with text page 1's layout.
- A with_aux pins a function resident and out of bank 1, which is easy to do by accident
  (AGENTS.md warns about it for groups); 2,492 bytes of the mirror are its price in aux.

## Suggested memory-pass changes, ranked

Bytes freed are in main memory or the card unless said otherwise. Risk is my judgment of the
chance of breaking something and the work to verify it.

| # | Change | Where | Frees | Risk |
| --- | --- | --- | --- | --- |
| 1 | Mouse set-up and the guard's install from `main.main` into `title.enter` (the title's group), the machine check left resident (done: its own group, below) | Catwiz | about 306 main | low |
| 2 | With_aux functions only one group calls read through `auxmem.read` and join their group (`disk2.has_label`, `stage.backdrop`, `stage.runs_of`, `offer.pool_byte`) (tried, left: each cost speed, below) | Catwiz | about 200 main, 200 aux | low |
| 3 | Once-only data out of the card: `auxmem.GUARD` to aux, the zero-page image into the empty overlay region at boot | Tisple | 215 card | low |
| 4 | Code shared only by the title's and the fight start's groups copied into both images instead of kept resident | Tisple | about 683 main, costs 683 aux | medium |
| 5 | Card effects in aux, the playing one copied into a 17-byte buffer (after `load-music` merges) | Catwiz, lib/mockingboard | about 360 main | medium |
| 6 | One shared `ov.enter` for all groups instead of five (about 75 bytes each now) | Tisple | about 230 main | low-medium |
| 7 | Boot disk: merge contiguous main segments (`$0B00-$1FFF`), put no-value aux lets past what loads | Tisple | 0 bytes; boot 4 tracks shorter, 3 segments free | low-medium |
| 8 | Scratch lets the layout places (never zeroed, in memory free after boot) instead of 118 hand addresses | Tisple, then Catwiz | the 69 bytes of holes, and the hand work | medium |
| 9 | Calls out of bank 1 to functions that never touch `$D000-$DFFF` made plain JSRs | Tisple | up to about 280 main, and crossing cycles | medium-high |
| 10 | The ending's group read from disk 2; page 2 and `$0300-$033F` of aux used for small tables | Catwiz | 763 + 320 aux | low |

1 to 6 together are about 2 KB of main memory and the card, without cutting a feature. The
`page.patch` (137 bytes of the card) is the next once-only piece if Tisple lets patch functions
leave resident memory.

## How the numbers were taken

- `python3 tools/memmap/memmap.py` runs `tisple build --asm --tables` with
  `TISPLE_DATA_NOTES=1` and keeps it in `build/asm.txt`, then reads it, `build/catwiz.vars.json`
  (which data are lets) and the boot loader's table from `build/catwiz.dsk`.
- Code: the listing's function headers (address, bytes, bank 1 or overlay group). Data: every
  `data` line (bytes, address, memory). The aux mirror: main functions whose addresses inside an
  aux segment no let or image takes. Zero page frames: the operands the listing names that no
  global owns.
- Fixed regions typed into the tool: I/O and slot ROMs, the ROM, the stack page above the
  scratch, the vectors, the screen holes, the boot loader's pages, aux zero page and stack. The
  aux text page buffers are read from their source (`rules.buffer` or `state.aux_page1`,
  `rules.PAGE_BYTES`, `log.HIST_AT`, `HISTORY`, `text.LINE_BYTES`).
- "Called only from a group" is from the listing's JSR and JMP operands, followed up through
  resident callers; a call through a function pointer would be missed (Catwiz has one dispatcher).
- Record fill on disk 2: each `FACES` and `CHARMS` sector's last nonzero byte.

## The memory pass (2026-11-03)

Catwiz's side of the table above, on main at dcdc9b0 with Tisple 8100596. Bytes are from
`build/memmap.txt` before and after each change; "free" counts what the layout left, and since
main memory and the card are full of code at squeeze 10, room freed there mostly shows as
functions that left bank 1 (fewer crossings) rather than as free bytes in main memory. Loads were
measured headless with the card in slot 5: frames from the key until the screen takes keys
(fight 1 from the title, fight 2 from the reward's S in a build that wins every fight at once,
the title after a run's last key), and the boot's title.

Before (dcdc9b0): main 68 free, the card 24, bank 1 550 (26 functions, 3,546 bytes, about
242,840 cycles a run in crossings), aux 1,529. Fight 1 424 frames, fight 2 251, the title after a
run 127 (126.75 exactly), the boot's title 813 (812.50); no tick lost in any load.

1. The guard's install and the mouse's set-up left `main.main` (324 bytes) and lib/mouse's
   helpers left bank 1 and the card (116). In `title.enter` (the title's group, with a once flag)
   the title after a run was ready 0.46 frames later (127.21: the group's copy from aux memory,
   423 bytes more, at every title), so they are a group of their own, `title.setup`, which main's
   loop runs once in the first pass before the title's step (433 bytes, 0.4 frames to load, at
   boot only). Tisple merges groups whose roots' dispatch facts do not contradict, so main calls
   `title.setup` while `title.set_up` is false and the title's step and draw while it is true.
   After: main 68 free, the card 31, bank 1 992 (19 functions, 3,104 bytes, about 191,860
   cycles a run): 449 bytes more free in main memory, the card and bank 1 together, after the
   sixth group's stubs. Aux 1,105 free (424 less: the group's image).
   Fight 1 424, fight 2 251, the title after a run 127 (126.73), the boot's title 813 (812.49).
2. Not done: every one cost speed. `stage.backdrop` had already joined the fight's start's group
   on `load-music` (its table read in `stage.picture_of`, 23 bytes, resident).
   - `disk2.has_label` (69 bytes, resident and in the mirror) with `auxmem.read` into the text
     line's buffer and `WANT` in main memory (8 bytes): 86 bytes in the title's group (1,918).
     121 bytes more free in main memory, the card and bank 1, aux 9 less, but the title after a
     run was ready at 138 frames (was 127): the group's copy took 0.08 frames longer, and the
     disk read after it missed its sector and waited a turn of the disk. The title's loads are
     that close to a sector; anything that makes the title's group bigger risks the same.
   - `stage.runs_of` and `picture_of` (23 each) with `auxmem.read`: 86 bytes more in the fight's
     start's group, which is read from disk 2 (16.3 frames a load to 16.8), for 46 resident
     bytes; and `addr_of` on an element packs `RUNS` and `PICTURES` (the build warns).
   - `offer.pool_byte` (24): the draws call it for every byte of the pool they look at (the
     faces' pool is 94 rows, about 2,000 calls for a draw of five), and `auxmem.read` costs
     about 100 cycles a call more than the with_aux: by that count (not measured) about 12 frames
     more on every reward. The
     pool would need a main-memory buffer of a sector to be read once, and there is none.

