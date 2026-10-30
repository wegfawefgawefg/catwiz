# Catwiz (private; was Witchdog)

A small Apple II hi-res dice roguelike in Tisple ][ (github.com/wegfawefgawefg/tisple): a
cat wizard fighting spooky-cute things in a forest with dice. A toy for ourselves, to prove the
compiler and an engine; an homage in the genre, not a remake. The folder name is historical.
Targets an enhanced IIe with 128 KB (aux memory holds the pictures).

- `game/`: the game. `main.tsp` is the loop; `battle/`, `draw/`, `sound/`, `title/` the
  engine; `content/` the rules content as plain tables (dice, enemies, statuses, effects, the
  encounter); `art/` generated pictures.
- `tools/art/`: the art, drawn in Python at 280 x 192 in the hi-res colours (the v6 mockup's
  style), and `export.py`, which writes `game/art/*.tsp`. `tools/hgr.py` is the canvas and the
  HGR converter; `tools/measure.py` measures frame costs on Tisple's IIe.
- `mockup/`: the hi-res mockups the look came from.
- `shots/`: screenshots from the machine.
- `data/extracted/` and the extraction tools in `tools/` are left over from before; the game
  uses none of them.

```sh
TISPLE=~/Coding/LangDev/tisple/build/tisple
tools/build.sh                                            # build/witchdog.dsk
$TISPLE machine --disk build/witchdog.dsk --window        # on your own screen
$TISPLE machine --disk build/witchdog.dsk --mockingboard 4 --window   # with music
tools/.venv/bin/python tools/art/export.py                # after changing the art
```

Keys in battle: 1-5 pick a die (its text shows at the bottom, arrows show who it goes to); then
Z, X or C (the enemies left to right), or LEFT/RIGHT and RETURN, plays it on that enemy; a die
for the hero or for every enemy plays when picked again (or RETURN). Another die switches, ESC
lets go. R re-rolls the dice not played yet (twice a turn), E ends the turn, M meows (for fun).
The five dice each turn come from the hero's bag. The reward after a fight works the same way
with 1-4 (then 1-6).

Rules for working here: `AGENTS.md`. The plan and where things stand: `docs/plan.md`.
