Steps A–D are all in place and nothing is committed. I edited no `.gdshader` file, no existing test, no pin and no clip key. The import ran and created the two new `.uid` files.

**Two results need your decision:**
- **My new test fails one check.** At boot the tree is in `Start` for one tick before it reaches `idle`.
- **`test_burning_tint` fails 15 checks.** The brief predicted that test would still pass.

The diffs for A, B and C are above; D is the new file `godot/tests/test_archer_state_machine.gd`.

## What I built
- **Step A (`archer.tscn`):** the AnimationTree and state machine exactly as in §6.
- **Step B (`archer.gd`):** your order is in: while a shot is armed, the release is checked first, then the cancel. If the target has been freed by the release tick, the arrow aims at its position recorded on the previous tick. `DRAW_LEAD = 0.3` lives in `archer.gd` because `tuning.gd` is out of scope.
- **Step B (`main.gd`):** one line, `archer.cancel_shot()`.
- **Step C:** `Scarecrow/WalkPresenter` with `scarecrow_walk_presenter.gd`. It compares against `assigned_animation`, because `hold` doesn't loop and its `current_animation` goes empty after 0.125 s.

## New test, at 60 fps: 106 passed, 1 failed
It passes on:
- every state, transition, `advance_mode`, `switch_mode`, xfade and tree setting in §6–§7, and every state name `archer.gd` and the presenter request;
- 18 ticks from the draw to the arrow, on all 9 shots;
- a 36-tick gap between back-to-back releases (`[36, 36, 36]`);
- the cooldown threshold: `0.31666666666666643` the tick before the draw, `0.29999999999999977` on it;
- `release_window` false two ticks before each arrow and true one tick before; one arrow per shot, with the stale `true` on the next tick ignored;
- `fired` never arriving outside `shoot`;
- `Archer/AnimationPlayer` never playing;
- the startup cancel by moving: the shot is cancelled at f12, the archer still moves 7 px every tick, and no arrow comes;
- a loss in mid-startup followed by R: back in idle, no late arrow;
- the scarecrow: `walk` (cells 0–3 all seen), then `hold` on the exact tick `at_wall` turns true.

**The FAIL:** `§6 Start -> idle: the tree is in idle after the first tick (got Start)`. Measured: the tree reports `Start` on f1 and `idle` from f2, even though `reset()` calls `start("idle")` in `_ready`. A shot is only delayed if a scarecrow is already in the cone on the very first tick of a fresh scene load, and then by one tick. Restart is not affected; that scenario passes. The brief gives no tick number for "on start", so I left my stricter check failing. Do you want it to read "idle by tick 2", or should I look into why the first update shows `Start`?

I fixed two bugs in my own test along the way. `_live()` is now untyped, because a freed scarecrow fails a typed argument. And the "cooldown already 0" check was wrongly fixed to tick 1; it now checks that the draw starts on the first tick a target is in the cone.

## Existing tests and pins
These all pass: `test_rules` (23/0), `test_input` (14/0), `test_materials`, `normal_map_check`, `test_wall_targeting` at 30, 60 and 144, both `_config` tests, `test_impact_burst_state` (29/0), `test_burning_embers_state` (54/0), and the four read-backs.

**Two of §5.6's predictions were wrong in your favour.** `test_impact_burst_state` was expected to need re-pinning, and the movement scenario in `test_burning_embers_state` might break. Both pass.

**`test_burning_tint` fails 15 checks at each of 30, 60 and 144.** These were **not predicted**: §5.6 said the conclusion would not change.
- Every failure is a second (or third) arrow, plus the extra burn time that arrow causes: `arrows 2` and `takes 4.616667 s` instead of 4.0.
- The cause is the test's steering helper. It holds D until `fired`, then steers back `STEER_BACK = 40 px`. The archer now keeps moving through the 18-tick draw, about 126 px further, so 40 px back leaves the target in the cone and the archer draws again.
- The failing lines: `[3 scarecrows] exactly one…`; for each of time_scale 1.0, 0.5 and 2.0: `one auto-fired arrow ignites it`, two duration lines and `no further arrow after the burn`; `[pause] the paused burn still takes…`; and `[retrigger] a second auto-fired arrow hits it (arrows 3)`.
- Fixing it means changing the helper, not re-pinning a number. That goes beyond what §5.6 allows, so it's your call for Step 6.

**`test_pins_a7` at 60: 26 passed, 12 failed.** The cadence pins (36) and every invariant except one setup check pass.

| FAIL | Predicted? |
|---|---|
| (a), (b), (c) first fired frame 1 → 19; (f) new run fired − spawn 1 → 19; (c) fired − re-entry 0 → 18 | Yes, §5.2: a first shot is 18 ticks later |
| (a) death 118 → 136; (c) cooldown reaches 0 at 37 → 55 | Yes, the same 18-tick shift carried forward |
| (d) first fired 1 → 49; second 67 → 85 | §5.2 gives 19 for the first shot, but the f15 pause now lands mid-draw, adding its 30 frames (49 = 19 + 30). The pause freezing the draw is §5.5's pause row |
| (d) pause shift 30 → 0, and the invariant `(d) P pauses mid-cooldown…` (cd 0.0000) | **Not predicted.** The scenario's setup no longer holds: at f15 the archer is drawing with cooldown 0, so the pause delays shot 1 instead of shot 2. Pausing and resuming themselves still pass |
| (f) frame the run is LOST 104 → 103 | **Not predicted in the brief's text.** The kills come later, so the gate takes slightly more damage |

## What the headless tests can't show
They prove which state is active, the value each key writes and the tick each event lands on. They draw nothing, so you still need to judge by eye:
- whether startup, active and recovery read as separate motions;
- whether the walk loops without a catch and looks different from hold;
- whether clip frame 0 matches the idle pose;
- the §11 strip frame numbers.

The new `.uid` files and the `logs/` changes from these runs are uncommitted, next to the code.