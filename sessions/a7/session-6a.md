I wrote `godot/tests/test_archer_edges.gd` and it passes: **325 passed, 0 failed**. No game file, scene, clip, existing test, pin or shader was touched, and nothing is committed. The full run is in `logs/test_archer_edges_60fps.log` (about 120 KB, mostly per-tick lines).

## Real output (summary lines from `./scripts/run-test.sh test_archer_edges.gd 60`)
```
==== measuring the boundaries (no interrupt) ====
MEASURED loss: 40 scarecrows placed at the wall at f 0 of a fresh run -> LOST on f 31
MEASURED (walker) shot 1: T 1, A 19, R 20, E 32 | shot 2: T 37, A 55, R 56, E 68 | release_window on R: false, on R+1: false; play position on R 0.3000
MEASURED (walker) offsets from T: A +18, R +19, E +31
MEASURED (cone) shot 1: T 1, A 19, R 20, E 32 | shot 2: T 37, A 55, R 56, E 68 | release_window on R: false, on R+1: false; play position on R 0.3000
MEASURED (cone) offsets from T: A +18, R +19, E +31
BOUNDARIES of the shot under test (shot 2): START T=37, ACTIVE A=55, RECOVERY R=56, END E=68
==== placing a target so its death lands on each boundary (scan of its start height) ====
death scan: 112 runs, found ["ACTIVE:1", "RECOVERY:0", "RECOVERY:1", "END:-1", "END:0", "END:1", "START:-1", "START:0", "START:1", "ACTIVE:-1", "ACTIVE:0", "RECOVERY:-1"]
==== boundary START: tick 37 (T+0) ====
MEASURED [START] pause t=36 (B-1) boundaries T, A, R, E: [47, 65, 66, 78] (unpaused [37, 55, 56, 68])
MEASURED [START] pause t=37 (B+0) boundaries T, A, R, E: [47, 65, 66, 78] (unpaused [37, 55, 56, 68])
MEASURED [START] pause t=38 (B+1) boundaries T, A, R, E: [37, 65, 66, 78] (unpaused [37, 55, 56, 68])
==== boundary ACTIVE: tick 55 (T+18) ====
  ... (same pattern; every boundary on or after the pause tick moves by exactly 10)
==== boundary END: tick 68 (T+31) ====
MEASURED [END] pause t=69 (B+1) boundaries T, A, R, E: [37, 55, 56, 68] (unpaused [37, 55, 56, 68])
INFO restart mid-startup (gate fell on tick 42, node shoot), R at resume 52 with a target placed in the same resume: tree on tick 53 is idle; the new run's first draw is on tick 54 (= R + 2)
NOT AT THE EXACT TICK: none
RESULT test_archer_edges: 325 passed, 0 failed
```
One group as an example (START, target leaves the cone):
```
PASS [START] cone t=36 (B-1) §5.2 the draw still starts on T=37 (cooldown <= 0.3, idle) and locks the walker, the target left in the cone
PASS [START] cone t=38 (B+1) §5.5 startup: drawing on tick 37 (armed, shoot), cancelled on tick 38 (shot_armed false)
PASS [START] cone t=38 (B+1) §5.5 startup: back in idle at once on tick 38, locked target cleared (node idle, lock "")
PASS [START] cone t=38 (B+1) §5.5 startup: the cooldown continues as normal (0.300000 -> 0.283333)
PASS [START] cone t=38 (B+1) §5.5 startup: no arrow from the cancelled shot (none on ticks 38..56)
PASS [START] cone t=38 (B+1) §5.5 no new target on the cancel tick, although walker is in the cone on it
PASS [START] cone t=38 (B+1) §5.2 the next tick (39) draws on walker by the normal rule: idle, in the cone, cooldown 0.2667 <= 0.3
```
`godot --headless --path godot --import` finished with no errors. It only printed the editor's scan and layout progress lines, and it created `test_archer_edges.gd.uid` for the new script.

## How the test works
- **Shot under test:** the second, back-to-back shot. Its draw comes from the 0.3 s cooldown rule, so tick T−1 is a real idle tick. Measured from the setup: T=37, A=55, R=56, E=68.
- **Measured constants:** these are in the file with the comment "measured 2026-11-21", and the test checks them again on every run. The loss constant is 31 ticks; my first guess of 30 was wrong.
- **Fresh run for every scenario:** each one starts with the gate falling (40 scarecrows at the wall, out of the cone) and then R.
- **Each interrupt is placed on its exact tick:**
  - Cone: a target at the wall 70 px to the left leaves the cone after one 7 px step.
  - Move: a far target stays in the cone while D is held.
  - Pause: P on the tick, then P again 10 ticks later.
  - Game end: the wall scarecrows are placed `t − 31` ticks ahead, so the gate falls on tick t.
- **Death:** it can be timed through real play. A target straight above the archer is shot by real arrows and burn. Its start height sets how long the arrows fly, so the test scans heights in 5 px steps and keeps the first run whose death lands on each boundary ±1. All 12 were hit exactly. These cases use the 4th or 5th shot rather than shot 2, and each line names its own T/A/E.
- **What R means:** "the tick after fired" can't move when a pause starts on that tick. So the test reads R as the first tick after `fired` on which the tree's play position has reached 9/30 s. In an unpaused run this equals fired + 1, and the measurement step checks that.

## NOT AT THE EXACT TICK
None. Every interrupt landed on B−1, B and B+1.

## Not a failure, but worth knowing
A target can be present on the very first tick of a new run, after a restart that happened mid-shot. Then the first draw comes on R+2 instead of R+1. On tick R+1 `archer.gd` still reads `get_current_node() == "shoot"`, because `playback.start("idle")` only takes effect in the tree's update later in that tick.
- Real play can't produce this: `reset()` clears every scarecrow and the first spawn comes 1 s later. So I print it as INFO, not as a FAIL.
- The asserted case places the target 3 ticks after R, and it follows the normal draw rule.

`git status` also shows changes I didn't make: `CHANGE-BRIEF.md` is modified, and `evidence/a7-mutations/` and `prompts/a7/prompt-6b.txt` are new. I left them alone.