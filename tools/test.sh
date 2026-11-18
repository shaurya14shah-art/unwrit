#!/bin/bash
# Every headless check. Fails on any failed check or printed script error.
cd "$(dirname "$0")/../game" || exit 1
G=${GODOT:-godot}
LOG=$(mktemp)
$G --headless --path . --import >/dev/null 2>&1
$G --headless --path . res://tools/Lint.tscn 2>&1 | tee "$LOG" | grep -E "BAD|lint:"
$G --headless --path . --script res://tests/run_core.gd 2>&1 | tee -a "$LOG" | grep -E "FAIL|core:"
$G --headless --path . res://tools/Balance.tscn 2>&1 | tee -a "$LOG" | grep -E "FAIL|balance:"
$G --headless --fixed-fps 60 --path . res://tests/TestPlay.tscn -- --no-title 2>&1 | tee -a "$LOG" | grep -E "FAIL|play:|WATCHDOG"
if grep -q -E "SCRIPT ERROR|FAIL|BAD|WATCHDOG|[1-9][0-9]* failed" "$LOG"; then
  grep -E "SCRIPT ERROR|at: " "$LOG" | head -20
  echo "TESTS FAILED"; rm -f "$LOG"; exit 1
fi
rm -f "$LOG"; echo "ALL TESTS PASS"
