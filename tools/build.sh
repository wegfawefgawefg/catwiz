#!/bin/sh
# builds the game's disk: tools/build.sh [out.dsk] [more tisple build flags]
# with game/noinline.txt's functions kept as calls (see the file)
ROOT=$(cd "$(dirname "$0")/.." && pwd)
TISPLE=${TISPLE:-$HOME/Coding/LangDev/tisple/build/tisple}
OUT=${1:-$ROOT/build/witchdog.dsk}
[ $# -gt 0 ] && shift
FLAGS=$(grep -v '^#' "$ROOT/game/noinline.txt" | sed 's/^/--no-inline /' | tr '\n' ' ')
mkdir -p "$(dirname "$OUT")"
cd "$ROOT/game" && exec "$TISPLE" build main.tsp --origin 0x8000 --disk "$OUT" $FLAGS "$@"
