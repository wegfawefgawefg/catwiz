# Plan

Goal: a title screen and a playable first forest battle, booting from a disk
image on a real Apple II. Planned 2026-10-27; paused for the owner's quota.

## Before the game (in Tisple, ~/Coding/LangDev/tisple)

1. Finish the round-4 miscompile fixes: branch `worktree-agent-a900e4aed77eb6c84`
   (227 farm seeds in `tests/programs/fuzz_farm/run6_seeds.txt`). A game is
   exactly the kind of big program that could hit one.
2. Merge the aux-memory branch `worktree-agent-a5ab7d6c7c2b6bc09`: multi-region
   programs, the language card, `:in aux`. Two hi-res pages, a background copy,
   art and code are tight in 48 KB without it.

## The game

1. Art pipeline: the mockup scripts export background, sprites, masks and face
   patches as Tisple data modules.
2. Engine: masked sprite drawing with save-under, page flipping each frame,
   actors on the byte grid (vertical bob, byte-step knockback, no pre-shift).
3. Battle: roll 5 dice, play them, 2 re-rolls, end turn, enemies act on intents,
   statuses tick, bark key. Hit feel: white flash, knockback, 2-3 frame hit-stop,
   floating damage numbers, hurt face; death blinks then poofs.
4. Title: glowing DOG WITCH over dark dithered clouds, Press Return.
5. Sound: speaker effects (bark "rrwuf", dice rattle, zap, hits, death squeak);
   a speaker jingle on the title.
6. Mockingboard (later): emulate the card in Tisple's machine (AppleWin's
   Mockingboard code is GPL, so borrowable), detect it at start, use it for music
   and effects when present, fall back to the speaker.

## Open questions for the owner

- The real first forest fight's enemies and the starting dice (placeholder:
  two Mushos and a Bwat; wand, voodoo doll, gem, book, bone, simplified).

## Art rules so far

See the header comments in `mockup/battle_forest_v*.py`. Owner's direction:
stylized silhouettes, depth, three-quarter angles, NTSC as the real target with
clean as the readability check, expressive faces that carry state.
