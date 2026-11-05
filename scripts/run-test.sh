#!/usr/bin/env bash
# scripts/run-test.sh <test-file.gd> <fps|realtime> [timeout-seconds]
set -o pipefail
mkdir -p logs
if [ "$2" = "realtime" ]; then
	fps_args=(); tag="realtime"
else
	fps_args=(--fixed-fps "$2"); tag="${2}fps"
fi
log="logs/$(basename "$1" .gd)_${tag}.log"
timeout "${3:-120}" godot --headless "${fps_args[@]}" --path godot --script "res://tests/$1" 2>&1 | tee "$log"
status=$?
if grep -qE "SHADER ERROR|SCRIPT ERROR" "$log"; then status=1; fi
exit $status
