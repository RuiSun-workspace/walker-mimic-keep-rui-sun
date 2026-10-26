#!/usr/bin/env bash
# scripts/check-session.sh <session.jsonl>
# The two checks after every agent session: the final result event (did it stop at --max-turns?
# any permission denials?) and that godot/shaders/ and scripts/run-test.sh are untouched.
f="$1"
echo "== final result event in $f"
python -c '
import json, sys
res = None
for line in open(sys.argv[1], encoding="utf-8"):
    line = line.strip()
    if not line:
        continue
    try:
        e = json.loads(line)
    except ValueError:
        continue
    if e.get("type") == "result":
        res = e
if res is None:
    print("NO result event: the session did not finish cleanly"); sys.exit(1)
for k in ("subtype", "is_error", "num_turns", "duration_ms", "total_cost_usd"):
    print(f"{k}: {res.get(k)}")
d = res.get("permission_denials") or []
print(f"permission_denials: {len(d)}")
for x in d:
    print("  -", x.get("tool_name"), json.dumps(x.get("tool_input"))[:160])
' "$f"
echo "== git diff --stat godot/shaders/ (must print nothing)"
git diff --stat HEAD -- godot/shaders/
git status --short -- godot/shaders/
echo "== git diff --stat scripts/run-test.sh (must print nothing)"
git diff --stat HEAD -- scripts/run-test.sh
