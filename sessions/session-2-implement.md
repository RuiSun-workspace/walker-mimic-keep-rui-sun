I implemented all three steps. The new test passes at 30 and 60 fps and **fails 7 checks at 144 fps**. Every failure has the same cause, which comes from the game's burn timer, not from the tint. I've stopped there without loosening any tolerance. Nothing is committed and no `.gdshader` file was touched.

## Steps
1. **`godot/game/scarecrow.tscn`**: added a ShaderMaterial using your shader, with `resource_local_to_scene = true`, set on `Sprite`. It works: the test sees three distinct materials for three scarecrows. **I did not need the `duplicate()` fallback.**
2. **New `godot/game/burning_tint.gd`**, attached to `Sprite`. Each frame it sets `burn_mix = 0.65 × clamp(burn_time_left / 4, 0, 1)` on that sprite's own material. It only reads `burn_time_left`, never writes game state, and uses no `TIME` or frame count.
3. **New `godot/tests/test_burning_tint.gd`**: 49 checks.
   - The sampler stores only numbers and instance ids. The test reaches the material only inside two helpers that return before any `await`, so the Rule 5 weakref check can't be kept alive by the test itself.
   - Every ignition is a real auto-fired arrow steered with A/D key events. Pause is a real P key. Nothing calls `ignite()` or the driver, or writes `burn_time_left`.
   - Steering fired exactly the expected arrows in every case at every frame rate: 1 per single-burn case, 2 in the retrigger case. Nothing was flaky.

While writing the test I fixed two bugs in it: an out-of-range read (a `SCRIPT ERROR` on the first 60 fps run) and an unsupported `%g` format in an INFO line. Neither changed a check.

## Test runs (all through `./scripts/run-test.sh`)
| Test | fps | Summary line |
|---|---|---|
| test_rules.gd | 60 | `test_rules: 23 passed, 0 failed` (same as baseline) |
| test_input.gd | 60 | `test_input: 14 passed, 0 failed` (same as baseline) |
| test_burning_tint.gd | 30 | `test_burning_tint: 49 passed, 0 failed` |
| test_burning_tint.gd | 60 | `test_burning_tint: 49 passed, 0 failed` |
| test_burning_tint.gd | 144 | `test_burning_tint: 42 passed, 7 failed` (exit 1) |

No `SHADER ERROR` appeared in any run.

## The 144 fps failure
Every burn lasts **4 s plus one 60 Hz physics tick**: 241 ticks instead of 240 at time scale 1, 481 at 0.5, 121 at 2.0. The real output shows why: in the frame before the tint reaches zero, `burn_time_left` is still `9.207912210484892e-15`. That's float residue from `burn_time_left -= delta` in `scarecrow.gd:53-54`, so the timer ends one tick late.

The tint follows the timer exactly (every sample matches the formula within 1e-6), so the extra tick belongs to the game. Revision B's tolerance is one frame of game time. That's one tick or more at 30 and 60 fps, so the extra tick fits (at 60 fps it sits exactly on the limit). At 144 fps one frame is 1/144 s, smaller than the 1/60 s tick, so the five game-time duration checks and the two real-time frame-count checks fail.

Ways to resolve it, your call:
- revise the brief's tolerance to "one frame or one physics tick, whichever is larger"; or
- make the game's timer end cleanly (gameplay change, out of scope for me).

Small caveat: the INFO line's tick count over-counts by one at 30 fps, where frames hold 2 ticks. It's only a diagnostic, not a check.

## What the test proves headlessly
- **Rule 6, §2:** the uniform names and types; the defaults and colour line read from the source text; no `render_mode`, sampler or `TIME`. Each scarecrow has its own ShaderMaterial on the one shared shader, with `burn_color` left at the default. With three scarecrows and one hit, the readings are (0, 0.65, 0), and the other two stay at 0.0 in every frame.
- **Rules 1–2:** 0.0 before the hit, the peak in the hit frame (revision A), and 0.0 in exactly the frame `burning_ended` fires. Every sample is within [0, 0.65] and matches the formula. Durations are measured in game time at 30, 60 and 144 fps.
- **Rule 4:** time scales 0.5, 1 and 2 take about 8, 4 and 2 s of real time. A real P freezes both values for 30+ frames, and they carry on from the frozen value after resuming.
- **Rule 3:** a second real arrow brings the value back from 0.168 to 0.65 in the hit frame.
- **Rule 5:** the scarecrow burns to death while still burning, and the next frame the scarecrow, its Sprite and its material are all freed.

## What it cannot prove
Anything about pixels. Headless runs a dummy renderer, so the test shows only the value handed to the material. It can't show that the GPU applied the shader, what colour `burn_color` arrives as (the `source_color` / HDR-off assumption), or whether `hint_range` clamps a value of 2.0.

## Human checks still needed (windowed, 1280×720)
1. Set `burn_mix` to 0.0, 0.5 and 1.0, capture the frame in-engine, and sample the three named pixels against §6 (±1 on the three half-integer channels).
2. Assign 2.0 and take a screenshot (short answer 7).
3. The tint appears and clears clearly, the fade isn't abrupt, and a refresh is noticeable.
4. Nothing visibly changes while paused.
5. A frame captured after a burning death shows no leftover tint.
6. Three scarecrows in one frame, only one tinted.
7. A burning scarecrow reads clearly against the green field, and the straw, patch, head and hat stay legible at 0.65.

## Files
- **Changed:** `godot/game/scarecrow.tscn`
- **New:** `godot/game/burning_tint.gd`, `godot/tests/test_burning_tint.gd`
- **New logs** written by `run-test.sh`: `logs/test_burning_tint_{30,60,144}fps.log`
- The tracked logs `test_rules_60fps.log` and `test_input_60fps.log` were rewritten with identical content, so git shows no change.