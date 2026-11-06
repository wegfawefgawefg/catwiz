# Plan

Catwiz: an Apple II double hi-res dice roguelike in Tisple ][, to prove the compiler and an
engine. Shelved 2026-10-30 with two of ten fights, then ported to double hi-res with the day
art (branch dhgr-port, 2026-10-30). Owner: an homage in the genre, not a remake; no
text or data from any other game; the content can be replaced by much stranger stuff later.

## Where it stands

Checked against the code at 1406bbb (2026-11-06). `tisple build` builds `build/catwiz.dsk` and
`build/catwiz2.dsk` from `game/` (Tisple main; settings in `tisple.project`). v0.2 (2026-11-03,
"Catwiz 0.2: the whole run") plays all ten fights; 56 commits since are on main, not released.

1. Boot: LOADING, then the title in double hi-res (frame 684 in the last measurement, AGENTS.md
   Memory, 2026-11-04): CATWIZ in white with a rim that glows (magenta, orange, yellow, orange),
   the cat against a big white moon on a night page, "a cat witch's long way home", PRESS
   RETURN. A key or click from before the title is up is not a start.
2. The run (`content/encounters.tsp`): ten fights, 3-3-3-1, all at night. The woods (1-3: the
   puffcap and sporelet, the squirrels and possum, the elite THE OLD SHROOM), the garden (4-6:
   sprinklers and the mower, the cucumber and the gnome, the elite THE MAILMAN), the house (7-9:
   the hoover and dust bunnies, the dust bunnies and roomba, two doors at 9: the vet or the big
   bath), then the Bulldog King. Each fight has its own screen and art (`art/screen_fight1` to
   `11`); `STOP_STAGE` in `battle/battle.tsp` is `FIGHT_COUNT`, so the run is won after the King
   (a page of her kit and the fights), then the title. Hit points and her kit carry between
   fights; losing ends the run.
3. Rules (the item-slot model; the sim's, `tools/sim/`, docs/balance.md; docs/balance.md still
   says 30 hit points and three cards where the game has 10 and five):
   - Catwiz has 10 hit points (`HERO`, more with charms) and rolls five identical dice (six with
     the sixth toe); each die's six faces are her six item slots (wand, fluff, star, book,
     curse, trick) and the item in a slot decides what its face does. She starts with Twig
     Wand, Fluff, Star, Zoomies, Fleas, Plus One. Two re-rolls a turn. Levels belong to the
     slot. The third face of a slot in a turn sets off its item's combo.
   - Faces and charms are rows of data on disk 2 (`content/faces_*.tsp`, `charm_rows.tsp`, cards
     as steps in `content/cards.tsp`): 94 faces and the hairball, 35 charms. A face or charm
     costs a disk sector, not memory (AGENTS.md, Content).
   - Enemies show their next move and act in order, round and round (`content/moves.tsp`).
   - Between fights (`battle/reward.tsp`, `offer.tsp`): one of five faces drawn at random by
     weight, or a level on a slot. After each elite (3, 6, 9) also one of three charms, then the
     rest: she heals to full (hearts rise by her), then may put +1 on a face of her choice or
     skip it (`NAP_HEAL_SHIFT` 0). The sim's tuned tables went in 2026-11-01.
   - M meows: a sound, a hop and the happy face; no effect on the fight.
4. Controls: 1-5 pick a die (1-6 with the sixth toe); Z X C (or the arrows and RETURN) play it
   on an enemy; the same number again plays a die for the hero or for every enemy, and lets
   go of one for a single enemy; M plays a die for the hero, else meows. ESC lets go, R
   re-rolls, E ends the turn, H shows the log's history. The turn ends by itself when the last
   die is played or none can be and no re-roll is left. Between fights the choices are cards in
   the tray: 1-5 (1-3 for charms, 1-6 for a slot, 1-2 for the doors) picks and shows one, the same
   key again or RETURN takes it, S skips.
   Every key has a click (`battle/boxes.tsp`, an AppleMouse in any slot; the phone player and
   `tisple machine --taps` press the mouse where a tap is, `tools/phone/catwiz.json`). Pages
   over the stage: BAG (B, her kit), ? (the rules, thirteen pages, `PAGE_COUNT`), the log (H).
   One-time hints in the log (first turn, first mana).
5. Screen: double hi-res. The stage is rows 0-120 (`HUD_TOP` 121 in `battle/tray.tsp`), the
   hud and tray below it, then four lines of 35-column text from row 160: the pick or target,
   then the log. Badges under and over the actors (hit points, statuses, the enemy's next
   move). The map of the run at the top of the stage. Sprites are solid frames on black
   (the lanes, Art rules below).
6. Sound: with a Mockingboard in any slot, songs and effects; without one, speaker effects and
   the title jingle. Songs (AGENTS.md, Sound): the title's, one a zone (woods, garden, house),
   one for the elites, the King, the run won and the run lost. They play from the card's bank 1
   (two halves of 895 bytes), fade out and in at a change, a zone's song plays on across its
   fights, and a screen's song starts as its load begins and plays through it. The songs come
   from `tools/music` (a generator makes songs from rules and a seed; `listen.py` hears one
   without the game).
7. Memory (AGENTS.md Memory, the song-bank entry, 2026-11-04; docs/memory-map.md is of
   2026-11-03 and was drawn before the memory pass and the songs): main memory and the language
   card are full. Free after the songs went in: 70 bytes in main's holes (and `$08F7-$098A` of
   scratch), 53 in the card, 56 in bank 1, 373 in aux. The disk has 10 segments, the most a
   disk holds. Six overlay groups (the pages, the reward, the fight's start, the ending, the
   title, the set-up) take turns in one region.
8. Speed, all from AGENTS.md Memory: a pass waiting for a key in fight 1 is 5,920 cycles
   (2026-11-03, the rest round); the title at frame 684 from boot; fight 1 ready 448 frames
   after the title's key, fight 2 from the reward 167, the title after a run 126 (2026-11-04,
   the song-bank entry). The music handler costs about 1,130 cycles a tick.
9. Play stats: in the browser the player sends anonymous records to the dev VPS
   (`tools/phone/catwiz.json` "telemetry", the receiver in `tools/telemetry/`, tables with
   `tools/telemetry/report.py`); the player's STATS button turns it off. README, "Play stats".
10. License: GPL-3.0-or-later, code and content (`LICENSE`, 2026-11-04). The README takes no
    pull requests.

## Open

Release (the owner's queue, 2026-11-06):

1. Cut Catwiz v0.3: everything since v0.2 (music, the rest after elites, the text pass, the
   memory pass, title keys, play stats, the license). Disks, release notes, and the web build
   to match (docs/hn-post.md asks for it).
2. Refresh the README screenshots before a post to r/apple2: `shots/*_ntsc.png` were taken
   2026-11-01 and predate the text pass. The README says the screens after fight 2 come from
   test builds, which is no longer true.
3. The Show HN post went up (docs/hn-post.md is still the draft); it is being watched for
   replies.

Game:

4. Play it on a real enhanced IIe (FloppyEmu or ADTPro), with a real Mockingboard and a real
   mouse card; the plan never recorded the mouse, the music or the loads tried there. Balance the mix
   by ear.
5. A fight's art loads after the reward (`battle.load_art`, a paw-print meter). Reading the
   next screen's runs while the reward shows would hide it (page 1 is the read buffer today,
   so that needs another).
6. Speed in actions: a sprite drawn again costs a restore of its box and its runs. Ideas: a runs
   pass over the backdrop for a moving sprite (restore and draw in one), clipping a redraw's
   first rows too (bottom clipping is in), the nightflap flapping less often (it is in no
   fight). The action window was about 2 to 3 frames a pass in the 2026-11-02 measurement.
7. Room is the limit on everything else (Later, 4). The memory map lists what could move out of
   resident memory: 2,238 bytes of code called only from overlay groups, about 0.9 KB of
   once-only set-up code in main and the card (docs/memory-map.md; the memory pass took part of
   it).
8. Text drawing is the pages' cost (about 2 frames a line in the 35-column font): the rules page
   and closing a page (the tray and every look drawn again).
9. The tray is drawn in Tisple (about 2,500 cycles a group of pixels a row); the roll's redraw
   of all five faces takes a few frames.

## Later (planned, the owner 2026-11-04: the game feels right as it is; tag postnicemusic)

The owner's difficulty check at postnicemusic: lost 5-10 runs, won one, "about right". Keep
the numbers as the baseline.

1. The rests' waltz with vibrato (`a_waltz_vib`, after each elite only; ordinary rewards keep
   the zone's song). It needs glide, vibrato and detune. Tisple branch `rich-sound` (fe83135)
   has `lib/mockingboard_bends_small.tsp`: 1,513 bytes of handler code, about 830 more than
   Catwiz has free. Not merged.
2. The rich multi-voice sound effects (`tools/music/sfx/rich.fx`, `stingers.fx`,
   `stingers_motif.fx`), on top of every current sound: keep each sound distinct and the
   punchy impacts (smack, tackle), plus a fight-win sting over the zone song.
3. Attack effects from the a2fx combat kit (`~/Coding/Graphics/a2fx`, renders/combat.mp4):
   the owner picks two or three. No slower fights.
4. What unblocks all three is room. The biggest lever is a 65C02-only build (954 bytes
   smaller; loses only the unenhanced IIe). It needs a CPU check at boot, a Tisple way to put
   a library's variables in a program's free scratch, and a load pass (the 65C02 test build
   lost a disk turn at the run's end). The other option is a Tisple feature for handler code
   loaded only while a screen is up. The owner leans to staying plain 6502 (2026-11-04): the
   double hi-res games of the day needed 128K but not a 65C02, and running on an original 1983
   IIe is part of the point.
5. Tisple placement by constraints: the reader recovering from a missed sector first, then
   constraint-placed scratch (retiring the hand `:address` lets), then a solver weighted by
   call counts that keeps the layout stable.

## Art rules

Double hi-res, `tools/dhgr/` (AGENTS.md, Art). Midnight (2026-10-31): the whole game is night,
the fighters solid frames on pure black. The lane rule: every pixel a battle look can cover is
black in the backdrop (`lanes.py` works them out from the game's numbers; `make.py lanes`
checks); the scenery only outside them, a thin frame. One sprite set lit by palette swap and
rims, the rims round the whole figure on black; NTSC (the TV look) the real target, the flat
colour look the second check; big areas black, the light tier in small shapes, darks in small
pieces, no dithered areas. The hi-res
rules came from `mockup/battle_forest_v6.py` and `tools/art/actors.py`.
