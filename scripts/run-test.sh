#!/usr/bin/env bash
# scripts/run-test.sh <test-file.gd> <fps>
set -o pipefail
mkdir -p logs
log="logs/$(basename "$1" .gd)_${2}fps.log"
timeout 120 godot --headless --path godot --script "res://tests/$1" --fixed-fps "$2" 2>&1 | tee "$log"
status=$?
if grep -qE "SHADER ERROR|SCRIPT ERROR" "$log"; then status=1; fi
exit $status
