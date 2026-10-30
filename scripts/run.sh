#!/bin/sh
# builds the disk and plays it in Tisple's IIe window, with the Mockingboard (slot 4) and
# clicks on the dice and enemies: scripts/run.sh [more tisple machine flags]
# TISPLE names the compiler, as for tools/build.sh
ROOT=$(cd "$(dirname "$0")/.." && pwd)
TISPLE=${TISPLE:-$HOME/Coding/LangDev/tisple/build/tisple}
[ -x "$TISPLE" ] || TISPLE=tisple
"$ROOT/tools/build.sh" || exit 1
exec "$TISPLE" machine --disk "$ROOT/build/catwiz.dsk" --mockingboard 4 --window --scale 2 \
    --taps "$ROOT/tools/phone/catwiz.json" "$@"
