#!/usr/bin/env bash
# Capture review screenshots from the running game.
#   tools/capture.sh <out_dir> "name:x,y,z:dir:stage" ...
GODOT="${GODOT:-/e/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$1"; shift
LOG="$(mktemp)"
timeout "${LIMIT:-400}" "$GODOT" --path "$ROOT" --resolution 1600x900 --script res://tools/capture/capture.gd -- "$OUT" "$@" >"$LOG" 2>&1
CODE=$?
grep -vE "Unreferenced static|at: unref|^\s*$|^Godot Engine|^D3D12" "$LOG" | sort | uniq -c | sort -rn | head -40
rm -f "$LOG"
exit $CODE
