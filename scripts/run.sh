#!/bin/sh
# builds the disk and plays it in Tisple's IIe window, with the Mockingboard (slot 5) and
# the mouse card (slot 4: a click is the mouse there, pressed), as tisple.project says: scripts/run.sh [more tisple run flags]
# TISPLE names the compiler (default: ~/Coding/LangDev/tisple/build/tisple, else tisple on PATH)
ROOT=$(cd "$(dirname "$0")/.." && pwd)
TISPLE=${TISPLE:-$HOME/Coding/LangDev/tisple/build/tisple}
[ -x "$TISPLE" ] || TISPLE=tisple
cd "$ROOT" && exec "$TISPLE" run "$@"
