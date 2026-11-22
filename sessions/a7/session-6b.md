The pins now pass, and every other suite passes too. But the `_steer_one_arrow()` change you specified makes **test_burning_tint fail at 30, 60 and 144: no arrow is fired at all.** As you said, I left that unchanged and am reporting it as a finding. Nothing is committed, and no game, scene, clip or shader file was touched.

## Results (each through `./scripts/run-test.sh` as written)

| Test | fps | Result |
|---|---|---|
| test_pins_a7 | 60 | **38 passed, 0 failed** (before the re-pin: 26 passed, 12 failed) |
| test_burning_tint | 30 | **11 passed, 6 failed** |
| test_burning_tint | 60 | **11 passed, 6 failed** |
| test_burning_tint | 144 | **11 passed, 6 failed** |
| test_archer_state_machine | 60 | 107 passed, 0 failed |
| test_archer_edges | 60 | 325 passed, 0 failed |
| test_rules | 60 | 23 passed, 0 failed |
| test_input | 60 | 14 passed, 0 failed |
| test_impact_burst_state | 60 | 29 passed, 0 failed |
| test_burning_embers_state | 60 | 54 passed, 0 failed |
| test_wall_targeting | 30 / 60 / 144 | 10 / 10 / 10 passed, 0 failed |

## Pin measurements
- First fired frame is 19 in (a), (b), (c) and in the (f) new run. In (a) the scarecrow dies at 136. In (c) the cooldown reaches 0 at 55 and the shot comes 18 frames after re-entry. (f) is lost at 103.
- **Scenario (d):**
  - The first release is at f 19, where the cooldown resets to 0.6.
  - The cooldown reads 0.300000 at f 37 and the next shot comes at f 55 = 37 + 18, so the second draw starts on tick 37. P at the resume of frame f pauses ticks f+1 to f+30, so f can be 19 to 36. I chose **f 28**, the middle of that gap.
  - Result: cooldown at pause 0.45 and still 0.45 after the pause, shots at f 19 and 85. Shift = 85 − 19 − 36 = **30**.
  - "(d) P pauses mid-cooldown and P again resumes" and the shift of 30 now pass without any change to those checks.
- All of (a)–(f) and the global invariant checks pass with their checks unchanged.

## Finding: the new steering helper never gets an arrow out
All six arrow checks fail with "hit at -1 … arrows 0". The cause comes from the test's geometry, not from Revision 2:
- **The target barely enters the cone.** `TARGET` = (958, 423) sits about 149 px above the archer (y ≈ 572). With the 60° half-cone, the archer is in range once it is within about 258 px sideways. It starts at x 640 (318 px away) and moves 7 px per tick, so the draw starts with the target at most 7 px inside the cone edge.
- **Letting go of D strands it.** The archer stops right there. During the 18-tick draw the scarecrow walks 13.5 px closer, which narrows the in-range distance by about 23 px. The target leaves the cone and §5.5 cancels the draw.
- **Nothing starts a new draw.** No key is held now, so the helper waits for `fired` until `MAX_FRAMES` runs out.

Under the old helper the archer kept walking during the draw, which is why the target stayed in the cone. That is a geometric argument that matches the logs, not a traced run. A fix would mean a different helper or a different `TARGET`. Either goes beyond Revision 2 item 4, so it needs your decision and probably a brief revision.

## Diff
I wasn't allowed to run `git diff` here, so this is what I changed. Running `git diff godot/tests/test_pins_a7.gd godot/tests/test_burning_tint.gd` will show the exact patch.

**godot/tests/test_pins_a7.gd** (constants only):
```diff
-const D_PAUSE_AT_F := 15                   # (d) P pressed after tick 15 ...
+const D_PAUSE_AT_F := 28                   # (d) P pressed after tick 28 (first release f 19, next draw starts tick 37); moved 2026-11-21: CHANGE-BRIEF.md Revision 2, item 2 ...
-const A_FIRST_SHOT_F := 1      # measured on baseline …
+const A_FIRST_SHOT_F := 19     # re-pinned 2026-11-21 after the approved change: CHANGE-BRIEF.md Revision 2, item 1
-const A_DEATH_F := 118         → 136   (item 1)
-const B_FIRST_SHOT_F := 1      → 19    (item 1)
-const C_FIRST_SHOT_F := 1      → 19    (item 1)
-const C_CD_ZERO_F := 37        → 55    (item 1)
-const C_REENTRY_SHOT_DELAY := 0 → 18   (item 1)
-const D_SHOT1_F := 1           → 19    (item 2)
-const D_SHOT2_F := 67          → 85    (item 2)
-const F_LOSS_F := 104          → 103   (item 3)
-const F_RESTART_SHOT_DELAY := 1 → 19   (item 1)
```
Every re-pinned line now carries the comment "re-pinned 2026-11-21 after the approved change: CHANGE-BRIEF.md Revision 2, item N", with N as shown in brackets.

Two things went slightly beyond your list:
- `F_RESTART_SHOT_DELAY` is the constant I read as "(f) first fired frame".
- `D_PAUSE_AT_F` sits in the "chosen, not measured" section, so its comment explains where the pause moved rather than using the re-pinned wording.

**godot/tests/test_burning_tint.gd** (`_steer_one_arrow` only):
```diff
-## One real arrow: hold D until the archer's own auto-fire looses one, then hold A until the
-## archer is STEER_BACK px back. Keys go in at the start of a physics tick. Returns false if
-## no arrow was fired.
+## One real arrow: hold D until the archer's own auto-fire starts a draw (the first tick
+## game.archer.shot_armed is true), release D there so the archer stops where the arrow used to
+## leave, wait with no key held until the arrow is fired, then hold A until the archer is
+## STEER_BACK px back. Keys go in at the start of a physics tick. Returns false if no arrow was
+## fired. (CHANGE-BRIEF.md Revision 2, item 4.)
 func _steer_one_arrow() -> bool:
 	var start: int = rec.fired
 	_key(KEY_D, true)
 	var n := 0
-	while rec.fired == start and n < MAX_FRAMES:
+	while not game.archer.shot_armed and rec.fired == start and n < MAX_FRAMES:
 		await physics_frame
 		n += 1
 	_key(KEY_D, false)
+	while rec.fired == start and n < MAX_FRAMES:
+		await physics_frame
+		n += 1
 	if rec.fired == start:
```