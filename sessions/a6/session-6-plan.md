I haven't edited anything. This is the plan for wiring Effect B. I've read the scarecrow script and scene, `burning_embers.tscn`, Effect A's spawner and state test, `main.gd`/`main.tscn`, `archer.gd`, `arrow.gd`, `tuning.gd` and `hud.gd`'s pause handling.

## Step 1: the driver (two files)

**New `godot/effects/burning_embers_driver.gd`** (`extends Node2D`). It reads game state and never writes it:

- **Setup:** in `_ready`, it connects to the parent Scarecrow's `burning_started`, `burning_ended` and `died`, and gets references to `$Embers` and `$Smoke`.
- **On `burning_started`:** sets `emitting = true` and `amount_ratio = 1.0` on both emitters (B1).
- **On `burning_ended`:** sets `amount_ratio = 0.0` and `emitting = false` on both (B1).
- **Every frame (`_process`), while attached:** sets `amount_ratio = clamp(burn_time_left / Tuning.BURN_DURATION, 0, 1)` on both (B2). It never touches `amount`, so the setting stays in the scene file.
- **On `died` (B4):** sets `emitting = false` and `amount_ratio = 0`, then calls `reparent(World/Effects, true)` so the global transform is kept. It finds `World/Effects` through the existing `"effects"` group, the same way `impact_spawner.gd` does. It then counts down `$Smoke.lifetime` (1.20 s, read from the scene, not typed in) in `_process` and frees itself.
  - The countdown uses `_process`, not a SceneTreeTimer. That way it inherits `World`'s process mode and freezes behind the result screen (B5), then finishes after R (A5's accepted carry-over).
  - If no `"effects"` node exists (a scarecrow spawned outside `main.tscn`, as `test_rules` does), it only stops emitting and is freed along with the scarecrow.

**Edit `godot/game/scarecrow.tscn`:** add one child, `BurningEmbers`, as an instance of `burning_embers.tscn` at the scarecrow's origin, after `Sprite`, with the driver script set on that instance.
- `burning_embers.tscn` itself stays unchanged, so its config test still loads it on its own.
- Every scarecrow gets its own pair of emitters (B7). They use inherited process mode, so pause and the game-over freeze reach them (B5).

**Retrigger rule (B3):** re-igniting a scarecrow that is already burning emits no signal. The driver doesn't need one: the next frame's `_process` reads `burn_time_left = 4.0` and sets the ratio back to 1.0. `emitting` is only changed by the start and end signals, and the driver never calls `restart()` or changes `amount`, so particles already in flight are kept.

## Step 2: the state test, `godot/tests/test_burning_embers_state.gd`, run at 60

The test spawns two scarecrows at the wall: S1 at x 640 and S2 at x 960. Every ignition comes from a real arrow the archer fires on its own. The archer moves only through real A/D key events, and pause and restart use the real P and R keys. The test never calls `ignite()`, `hit()` or a driver function. It sets `burn_time_left` only where the brief allows that for a feedback test.

| # | Scenario | Assertions | Rule |
|---|---|---|---|
| 1 | Right after spawning, before any arrow | Both emitters have `emitting = false` and `amount_ratio = 0` | B1 (initial state) |
| 2 | First arrow hits S1. Holding D takes the archer through S2's cone, where it fires once, and on to x 1240, outside both cones | In each `burning_started` listener (which runs after the driver's): `emitting` is true and `amount_ratio` is 1.0 on both emitters | B1 start |
| 3 | Set S1's `burn_time_left` to 4, 3, 2 and 1, waiting one frame each | Both ratios are within one frame of 1.00, 0.75, 0.50 and 0.25 (tolerance (1/60)/4 + ε). `amount` stays 18 and 8 at every sample | B2, and amount_ratio rather than amount |
| 4 | Set S1 to 4.0 and S2 to 1.0 in the same frame, then swap | Ratios are 1.0 and 0.25, then 0.25 and 1.0. The four emitter instances are all different | B7 |
| 5 | P to pause, 30 frames, P again | While paused: `paused` is true, the emitters' `can_process()` is false, and `burn_time_left`, both ratios and `emitting` stay the same. After resuming, the timer falls again and the ratio follows | B5 pause |
| 6 | Hide S1's `Embers` for 30 frames, then show it | While hidden: not visible in the tree, still emitting, ratio still follows the timer, Smoke unchanged. After showing: same instance, still emitting, no new `burning_started` | B6, the parts that are node state |
| 7 | Set S2 to 2.0 (ratio about 0.5). Hold A until the archer fires at S2, then D back | Within one frame of the hit, both ratios are 1.0. S2 emits no second `burning_started`, `emitting` is true in every frame, and the node instances are the same | B3 |
| 8 | Set S1 to 1.0 and let it burn out on its own | In the `burning_ended` listener: `emitting` false and ratio 0 on both. For 30 more frames they stay that way while S1 is alive and not burning | B1 end, B2 at 0.0 |
| 9 | Hold A until real arrows kill the burning S2 | In the `died` listener: S2 was still burning and no `burning_ended` was emitted. Both emitters are now under `World/Effects`, global position matches S2's within 1 px, `emitting` false, ratio 0. `emitting` stays false every frame until the node is freed, which happens after 72 ± 2 frames | B4 |
| 10 | 8 scarecrows at the wall far away, plus one T that is hit once while the archer moves off, until the run is lost; then R | When lost: T is still burning and `World` is disabled. For 30 frames T's emitters can't process and T's ratio, `emitting` and `burn_time_left` stay the same. After R: playing, and `World/Effects` is empty within 72 frames | B5 end of game, A5 carry-over |

The test prints `gate_hp` and checks the run is still playing before scenario 10, so an early loss shows up as a setup failure rather than a false pass.

## What only a human or a windowed run can check

Headless runs draw no particles and run no GPU particle process, so the test proves node state, signals, parents, positions, ratios and lifetimes, but not what is on screen. These remain:

- **B6:** whether a hidden emitter keeps simulating (particle age) is still a prediction. It needs the windowed test.
- **B4:** whether particles already in flight survive the reparent and fade out. This is the open question in CLAUDE.md, for the frame strip.
- **B5:** whether particles actually look frozen, not just whether the node is set not to process.
- **B1 and B3:** whether existing particles finish their lifetime and whether re-ignition clears them.
- Contrast on each background, colour, scale and motion, visibility-rect edge cases, and GPU cost.

## Risks

- **Effect A's state test may be affected.** I can't edit it, and B4 puts dying B emitters into the same `World/Effects` node it counts. The 3-live-bursts check should be unaffected, because no scarecrow dies before the third hit. The one at risk is its A5 reset check: "`World/Effects` empty ≤ 72 frames after R". A B tail that starts on the exact frame of the loss would finish right at that limit. I'll rerun that test. If it fails, I'll report it and won't change either test.
- **Reparenting inside `died`:** that signal fires during physics, inside `hit()` or the burn tick. If Godot 4.7.2 refuses to remove the node there, I'll switch to `call_deferred` and tell you.

## How I'll run it

The new test runs at 60 through `scripts/run-test.sh`. It doesn't wait on audio, so it doesn't need realtime. After that, all the existing tests run as CLAUDE.md lists them, including both Effect A tests and the B config test, and I'll show the real output.

Do you approve Step 1 (driver plus the `scarecrow.tscn` instance)?