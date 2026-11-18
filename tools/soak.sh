#!/bin/bash
# The careless bot: every realm, random keys, enemies, a boss, every world
# event. Fails on any script error or broken invariant. Headless, no window.
# usage: ./tools/soak.sh [seconds per realm, default 40]
cd "$(dirname "$0")/../game" || exit 1
G=${GODOT:-godot}
LOG=$(mktemp)
$G --headless --fixed-fps 60 --path . res://tests/Soak.tscn -- --no-title "${1:-40}" 2>&1 | tee "$LOG" | grep -E "soak:|PROBLEM|^--"
if grep -q -E "SCRIPT ERROR|PROBLEM" "$LOG"; then
  grep -E "SCRIPT ERROR|at: " "$LOG" | sort | uniq -c | sort -rn | head -20
  echo "SOAK FAILED"; rm -f "$LOG"; exit 1
fi
rm -f "$LOG"; echo "SOAK CLEAN"
