I implemented both steps and nothing is committed. The new test passes 54/0 at 60, and every other test keeps its A6-baseline or committed count. None of your stop conditions came up. Effect A's state test still passes, but some of its INFO counts changed, so I'm reporting that rather than calling it unchanged.

## Files changed
- **New `godot/effects/burning_embers_driver.gd`**: the driver.
  - On `burning_started` it turns both emitters on at ratio 1.0. On `burning_ended` it sets ratio 0 and stops them.
  - Every frame it sets `amount_ratio = clamp(burn_time_left / Tuning.BURN_DURATION, 0, 1)`.
  - On `died` it stops both, sets ratio 0, then `reparent(World/Effects, true)`. It frees itself after `$Smoke.lifetime`, counted in `_process`.
  - It never touches `amount`. The only game state it reads is `burn_time_left`.
- **`godot/game/scarecrow.tscn`**: two new external resources and one `BurningEmbers` instance of `burning_embers.tscn` with the driver script on it. `burning_embers.tscn` itself is unchanged.
- **New `godot/tests/test_burning_embers_state.gd`**.
- **Generated or updated by the runs**: `burning_embers_driver.gd.uid`, the new test's log, and `logs/test_impact_burst_state_60fps.log`.

One fix during Step 2: the first run passed 54/0 but printed a `SCRIPT ERROR` from my own helper `_alive()`, which put the freed S2 into a typed variable. I fixed that helper only. No assertion or tolerance changed.

## Test summary lines (all through `./scripts/run-test.sh`; no `ERROR` or `FAIL` line in any log)
| Test | 30 | 60 | 144 |
|---|---|---|---|
| test_rules | | 23 passed, 0 failed | |
| test_input | | 14 passed, 0 failed | |
| test_materials | | 132 passed, 0 failed | |
| normal_map_check | | 9 passed, 0 failed | |
| test_impact_burst_config | | 128 passed, 0 failed | |
| test_impact_burst_state | | 29 passed, 0 failed | |
| test_burning_embers_config | | 154 passed, 0 failed | |
| test_burning_tint | 49 passed, 0 failed | 49 passed, 0 failed | 49 passed, 0 failed |
| test_wall_targeting | 10 passed, 0 failed | 10 passed, 0 failed | 10 passed, 0 failed |
| **test_burning_embers_state (new)** | | **54 passed, 0 failed** | |

**Effect A's state test (your rule: report if its counts change).** It still passes 29/0 and I changed neither test, but three INFO lines differ from the committed log:
- **Hit 6:** `live_bursts=1` became `live_bursts=2`. N died while burning at frame 177, so its B tail (72 frames) is a child of `World/Effects` when hit 6 lands at frame 236. `_live_bursts()` counts every child, so the B tail counts as a burst.
- **Later frames shift by +24:** burn-out hit 368 → 392, loss 719 → 743. Phase 1 waits for `World/Effects` to empty, and F's B tail outlasts F's burst.

The A3 "three bursts alive at the third impact" check (frame 105) is unaffected, because nothing has died by then. But it now depends on no burning scarecrow dying before the third hit.

## Measured values per scenario (60 fps; ratio tolerance (1/60)/4 + 1e-4 = 0.0043)
1. **Spawn:** both scarecrows have both emitters at `emitting=false`, ratio 0, amount 18 and 8, and each has its own BurningEmbers.
2. **Ignition:** one arrow at S1 (frame 2, x 640) and one at S2 (frame 38, x 892). In both `burning_started` listeners: emitting true, ratio 1.0. The archer stops at x 1240 with no target.
3. **Mapping:** the four set values each give the expected ratio minus one frame:

   | Set to | `burn_time_left` after one tick | Both ratios |
   |---|---|---|
   | 4.0 | 3.9833 | 0.9958 |
   | 3.0 | 2.9833 | 0.7458 |
   | 2.0 | 1.9833 | 0.4958 |
   | 1.0 | 0.9833 | 0.2458 |

   `amount` stayed 18 and 8 at every sample.
4. **Two scarecrows:** S1 4.0 / S2 1.0 gave 0.9958 / 0.2458, and the swap gave 0.2458 / 0.9958. The four emitters are four distinct nodes.
5. **Pause:** for 30 paused frames S1 stayed at 3.9833, S2 at 3.9667 and the ratio at 0.9958, and no emitter could process. Ten frames after resuming: 3.9667 → 3.8000, ratio 0.9500.
6. **Hidden:** S1's Embers was hidden for 30 frames: not visible, still emitting, ratio following the timer (0.8250 at burn 3.3000), Smoke unchanged. Shown again it is the same node, with no new `burning_started`.
7. **Re-ignition:** S2 lowered to 0.4958. A real arrow fired at x 1030 hit at frame 205. At frame 206: burn 4.0000, both ratios 1.0000, no second `burning_started`, emitting true every frame, same nodes.
8. **Burn-out:** `burning_ended` came 60 frames after S1 was set to 1.0. In the listener and for 30 frames after: emitting false, ratio 0, S1 alive (hp 12.20). No arrows fired.
9. **Death while burning:** an arrow (fired at frame 361) killed S2 at frame 365 with `burn_time_left` 4.0 and no `burning_ended`.
   - In the `died` listener the emitters were already under `World/Effects`, at (960, 530), the same as S2, with emitting false and ratio 0.
   - They were freed at frame 436, 71 frames later (limit 72 ± 2). No reparent error occurred.
10. **Game over and restart:**
    - Before the scenario: gate_hp 38.58, run still playing.
    - The archer fired only at T, which it hit once. The run was lost at frame 485 with `World` disabled.
    - For 30 frames T's emitters could not process, and T's values stayed fixed: burn 3.2500, ratio 0.8167, emitting true.
    - After R the run restarted and `World/Effects` (1 child: T's Effect A burst) was empty 3 frames later.

## What the test proves headlessly
- Node state, signal order and node identity for B1 (start and end, plus the initial state), B2 (all five rows, with `amount_ratio` checked, not `amount`), B3, B4 (stop, reparent, position, lifetime), B5 (pause and game over: `can_process()` false, values frozen) and B7.
- Every ignition and hit is a real arrow, and every movement, pause and restart a real key. The test sets only `burn_time_left` and Embers' `visible`.

## What it cannot prove headlessly
No particles are drawn or simulated headlessly. So the test cannot show:
- whether particles survive the reparent and fade (B4);
- whether a hidden emitter's particles keep ageing (B6 is still a prediction);
- whether paused particles look frozen;
- whether re-ignition keeps the particles already in flight.

Scenario 10's restart check is also weak for Effect B: no B tail was alive at R (S2's had already been freed), so the B carry-over after restart was not exercised.

## Human checks still needed
- The windowed B6 test (hide, wait, show).
- The Effect B frame strip from §7: build-up, falling density, the tail after burn-out and after death, and re-ignition around frame 100.
- A visual check that particles freeze on pause and at game over.
- Contrast over grass, wall, walkway and gate at 1280×720, and the visibility-rect edge test.
- GPU cost measured in a windowed run.