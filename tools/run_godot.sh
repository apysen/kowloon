#!/usr/bin/env bash
# Run a headless Godot script against the project with a hard timeout and
# print only the lines worth reading (errors, warnings, our own prints).
#   tools/run_godot.sh res://tools/level/bake_level.gd [timeout_seconds]
GODOT="${GODOT:-/e/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$1"
LIMIT="${2:-300}"
LOG="$(mktemp)"
timeout "$LIMIT" "$GODOT" --headless --path "$ROOT" --script "$SCRIPT" >"$LOG" 2>&1
CODE=$?
grep -vE "Unreferenced static string|^\s+at: unref|^Godot Engine v|^\s*$" "$LOG" | head -${LINES_OUT:-80}
echo "exit $CODE"
rm -f "$LOG"
exit $CODE
