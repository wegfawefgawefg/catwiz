#!/bin/sh
# builds the game's disk: tools/build.sh [out.dsk] [more tisple build flags]
# TISPLE names the compiler (default: ~/Coding/LangDev/tisple/build/tisple, else tisple on PATH)
ROOT=$(cd "$(dirname "$0")/.." && pwd)
TISPLE=${TISPLE:-$HOME/Coding/LangDev/tisple/build/tisple}
[ -x "$TISPLE" ] || TISPLE=tisple
OUT=${1:-$ROOT/build/catwiz.dsk}
[ $# -gt 0 ] && shift
mkdir -p "$(dirname "$OUT")"
cd "$ROOT/game" && exec "$TISPLE" build main.tsp --origin 0x8000 --disk "$OUT" "$@"
