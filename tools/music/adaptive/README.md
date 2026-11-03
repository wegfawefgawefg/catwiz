# Music that follows the fight

`battle.asong` is one fight song with six states. The game would pick a state. The player
changes the music only in ways the Apple's player can do cheaply:

- **Layers.** Each voice's volume can be turned down by some steps.
- **Sections.** Each voice switches to another order list when its current pattern ends.

The King's motif comes in as a section: in `king`, the bass and the counter play it.

```sh
python3 tools/music/adaptive/adaptive.py size battle.asong          # bytes per section
python3 tools/music/adaptive/adaptive.py render --out DIR *.timeline # the demos
python3 tools/music/adaptive/player_patch.py                         # what the player costs
```

The renders use Tisple's own player with the additions below. `player_patch.py` makes them as
text edits on fresh copies of `lib/mockingboard.tsp` and `lib/mockingboard_player.tsp`, put in
the program's folder. Tisple itself is unchanged. `adaptive.py` assembles the song's bytes. For
all 17 plain songs in `songs/` (the ones without bends), they come out the same as
`tune.song`'s.

## The states

| state | section | layers (steps down, voices 0-5) | what changes |
| --- | --- | --- | --- |
| calm | main | 3 15 15 3 15 2 | the player thinking: lead, bass and echo only, softer |
| fight | main | 0 15 15 0 0 0 | the drums come in |
| low | main | 0 0 0 0 0 0 | the enemy is low: the counter and the hats join |
| danger | danger | 0 15 15 0 0 0 | the cat is low: half time, a heartbeat bass (D D, C# C#), only the twitch on the lead |
| windup | king | 15 0 0 0 0 15 | an elite winds up: the King's motif in the bass and two octaves up on the counter; drums pound quarters; lead and echo out |
| victory | victory | 0 15 0 0 0 0 | one hit from winning: the motif turns major and climbs, over main's bass and drums |

Voices:

- 0: the lead.
- 1: the counter.
- 2: hats. Lent to the hero's effects.
- 3: bass.
- 4: drums.
- 5: the lead's echo. Lent to the enemies' effects.

The left chip has the lead, counter and hats. The right chip has the bass, drums and echo.

Every harmony pattern is 2 bars (192 ticks), so a section change lands on the next 2-bar line.
That is at most 3.2 s after the game asks. The drums' patterns are 1 bar, so the drums can
change a bar early.

The song is 391 bytes:

| part | bytes |
| --- | ---: |
| the start's music and the header | 188 |
| main's return table | 12 |
| danger | 70 |
| king | 81 |
| victory | 40 |

To fit 395 bytes, three parts came out:

- the danger counter's creeping line;
- the lead's alarm over the King;
- victory's own counter and second phrase. Victory reuses main's 2nd-time phrase.

## What the player needs

Measured by building a small program that plays a song (`tisple build`, "code N"): the stock
player is 2,686 bytes of code.

### 1. A per-voice layer

- `(let layer (array u8 6))` holds each voice's steps down.
- `heard` subtracts the layer along with the fade: `(- l (+ (>> hush 2) (at layer s)))`.
- `play` starts each voice at its layer's target. The game sets the first state, then plays.

There are two ways to move a layer:

- **Instant.** `(mb.layer v steps)` sets the layer and marks the voice stale. The volume
  changes on the next tick, so a part comes in or out with a cut. The game could ramp it from
  its own loop.
- **Ramped.** The tick moves `layer` toward `layer_to` by a step every 4 ticks, as the fade
  does. A part takes up to 1 s to come in or go out. This needs `layer_to`, a moving flag and a
  clock. **The renders use this one.**

### 2. A "next section" per voice

- `(let next_order (array (ptr u8) 6))` holds the list each voice takes next.
- `next_pattern` takes `next_order[v]` (and clears it) before reading the order list.
- `play` clears all six.
- `(mb.section k)` reads section k's table: six u16 offsets at 12 * k in the song, with the
  header as section 0. It sets `next_order` for each voice whose offset is not 0.

Each section costs 12 bytes of table in the song, plus its own order lists. Lists that are the
same are stored once, so a section that reuses another's bass and drums pays nothing for them.

### Measured cost

| | code bytes more |
| --- | ---: |
| instant layers + sections, nothing called (the handler side: `heard`, `next_pattern`, `play`) | +59 |
| ... calling `mb.layer` | +76 |
| ... calling `mb.section` | +152 |
| **instant layers, calling both** | **+155** |
| ramped layers, nothing called | +147 |
| **ramped layers, calling both** | **+237** |

The lets are 24 bytes (`layer`, `layer_to`, `next_order`), plus 2 for the ramp. `mb.section`
is the biggest part, about 80 bytes for its loop over the table.

Tick time (estimated, not measured):

- `heard` adds about 10 cycles to each volume write.
- `next_pattern` adds about 15 cycles to each new pattern.
- When nothing moves, the ramp costs one flag test.
- While a ramp moves, every 4th tick walks the six voices, about 250 cycles.

### What the game needs too

- **A `section` form in `lib/mockingboard_song`'s `tune.song`.** It is compile-time only. It
  lays out the tables after the header and stores each distinct list once, as `adaptive.py`'s
  `assemble` does. Its bytes are counted in the song's 391.
- **A state table in `sound.tsp`.** Each state is a section number and six layers, 7 bytes, so
  42 bytes for six states. A `(sound.mood s)` would set them: about 30-40 bytes of code. This
  is an estimate.

Catwiz's main memory is full, so even the instant version (about 155 + 40 bytes) needs room
found first.

## The timelines

Each is 90 s with a state change every 10-20 s. They end with the 1 s fade a song change
makes. `elite_fight` and `close_call` include the game's effects on the lent voices
(`game/sound/card_fx.tsp`: rattle, zap, thump, growl, yelp, chime, squeak).

**`states_tour`** (no effects)

| time | state |
| --- | --- |
| 0:00 | calm |
| 0:14 | fight |
| 0:28 | low |
| 0:42 | danger |
| 0:56 | windup |
| 1:10 | victory |
| 1:26 | fade |

**`elite_fight`**

| time | state |
| --- | --- |
| 0:00 | calm |
| 0:10 | fight |
| 0:20 | windup |
| 0:32 | danger (the move landed) |
| 0:45 | fight (healed) |
| 0:55 | windup |
| 1:06 | low (the move fizzled) |
| 1:16 | victory |
| 1:26 | fade |

**`close_call`**

| time | state |
| --- | --- |
| 0:00 | fight |
| 0:12 | danger |
| 0:26 | calm (thinking while low) |
| 0:38 | danger |
| 0:50 | fight |
| 1:02 | low |
| 1:15 | victory |
| 1:27 | fade |

A section change sounds at the next 2-bar line after the time given. A layer change ramps in
over up to 1 s from that time.
