This is the plan only. I haven't edited anything or run any tests yet.

## Is your shader fine?

Yes. `godot/shaders/burning_tint.gdshader` matches CHANGE-BRIEF §2 character for character: the two uniforms with their hints and defaults, no `render_mode`, no sampler, and the single colour line. I see nothing wrong with it, so I'm not stopping.

There is one stale line in CLAUDE.md. Under "Unconfirmed" it says `godot/shaders/` does not exist yet, but it does (commit 6a2c298, with a `.uid` file).

## Step 1: give each scarecrow its own ShaderMaterial (`godot/game/scarecrow.tscn`)

- Add an `ext_resource` for `res://shaders/burning_tint.gdshader`.
- Add a `ShaderMaterial` sub-resource with `resource_local_to_scene = true` and `shader = ExtResource(...)`, set as `material` on `Sprite`.
- That's all the scene change. Rule 6 requires each scarecrow to have its own material: `instantiate()` gives each instance its own copy because the material is local to the scene. The test checks this directly. If the check fails, I'll ask you before changing anything; the fallback is to have the driver `duplicate()` the material in `_ready()`.

## Step 2: the driver that sets the uniform from game state (new file `godot/game/burning_tint.gd`)

This is a script on the existing `Sprite` node (`extends Sprite2D`), so the scene gets no new node. `scarecrow.gd` stays untouched.

```gdscript
const BURN_MIX_MAX := 0.65
func _process(_delta: float) -> void:
    var s := get_parent() as Scarecrow
    var mix := BURN_MIX_MAX * clampf(s.burn_time_left / Tuning.BURN_DURATION, 0.0, 1.0)
    (material as ShaderMaterial).set_shader_parameter("burn_mix", mix)
```

- **Read-only:** it reads `burn_time_left` and nothing else, and writes only to its own material.
- **No `TIME`, no frame count:** the value comes entirely from the game timer.
- **`burn_color` is never set**, so every copy uses the shader's default.
- **Pause:** it runs in `_process` with the inherited process mode, so it stops while the tree is paused.
- **Death:** it gets freed along with the scarecrow, so it can't keep fading on its own.

## Step 3: the new test (`godot/tests/test_burning_tint.gd`)

It follows the same `_check` / PASS / FAIL pattern as `test_rules.gd`, and runs the real `main.tscn` with `spawning_enabled = false`.

**How it drives the game.** Scarecrows come from `game.spawn_scarecrow()`, which is what the existing tests use. Nothing calls `ignite()` or the driver directly:
- Every ignition is a real fire arrow from the archer's own auto-fire.
- The archer is positioned with real `InputEventKey` events for A/D through `Input.parse_input_event`.
- To land exactly one arrow, the test steers the archer into the firing cone with D, and presses A as soon as `archer.fired` is emitted to steer it back out.
- Pause and resume use real P key presses.

**How it samples.** A `Sampler` node has `process_priority = 1000` and `PROCESS_MODE_ALWAYS`, so it reads last in every frame, even while paused. Each frame it records: frame index, game time (the sum of physics deltas, like `GameClock` in test_rules), `burn_time_left`, and `get_shader_parameter("burn_mix")` from each scarecrow's own material.

| # | Assertion | Rule |
|---|---|---|
| 1 | `get_shader_uniform_list()` lists exactly `burn_mix` (`TYPE_FLOAT`, `PROPERTY_HINT_RANGE` 0..1) and `burn_color` (`TYPE_COLOR`), and nothing else (no sampler) | §2, Rule 6 (naming) |
| 2 | The shader source text has default `0.0` for `burn_mix`, `source_color` on `burn_color` with default `vec4(1.0, 0.752941, 0.125490, 1.0)`, the colour line exactly, and no `render_mode` | §2 |
| 3 | The Sprite's material is a `ShaderMaterial` whose shader path is `res://shaders/burning_tint.gdshader` | §2 |
| 4 | Before ignition `burn_mix == 0.0`; within one frame of the arrow hit it is at its peak (see issue A); after `burning_ended` it is `0.0` | Rule 1 |
| 5 | Every sample is in `[0, 0.65]` and equals `0.65·clamp(btl/4,0,1)` within 1e-6 | Rules 1, 2 |
| 6 | Game time from the first peak sample to the first 0.0 sample is 4.0 s, give or take one frame period | Rule 2 (run at 30/60/144) |
| 7 | Single-arrow burns at `time_scale` 0.5, 1 and 2: game-time duration is 4.0 s each time, and frame count ≈ 4/scale × fps (unscaled time) | Rule 4 |
| 8 | P pressed mid-burn: `burn_mix` and `burn_time_left` stay identical over 30 paused frames; after P again the burn continues from the frozen value | Rule 4 (pause) |
| 9 | Retrigger: once `burn_mix` < 0.3, a second real arrow brings it back to its peak within one frame | Rule 3 |
| 10 | That same scarecrow later dies while still burning: the next frame the scarecrow and Sprite are freed, and a `weakref` to its material comes back null, so nothing else is holding the tint | Rule 5 |
| 11 | Three scarecrows, only the middle one in the cone: the three materials are distinct objects; values read ≈ (0, 0.65, 0), the outer two stay at 0.0; `burn_color` is unset (null, so the shader default) on all three | Rule 6 |

**Health check.** One arrow plus a full burn is 10 + 16 = 26 damage, which is under the scarecrow's 40 HP. So each duration case gets a fresh scarecrow, and only the retrigger case is meant to die (this is where check 10 comes from). The test also counts `fired` per case, so an extra stray arrow fails loudly instead of quietly breaking the timing.

**Runs.**
```bash
bash scripts/run-test.sh test_rules.gd 60
bash scripts/run-test.sh test_input.gd 60
bash scripts/run-test.sh test_burning_tint.gd 30
bash scripts/run-test.sh test_burning_tint.gd 60
bash scripts/run-test.sh test_burning_tint.gd 144
```

## Two spec issues to decide before Step 3

**A. Rule 1's "0.65 within one frame" can't be exact at 30 fps.**
- Physics always runs at 60 ticks/s, so at `--fixed-fps 30` each frame contains 2 ticks.
- If the arrow hits on the first of the two, the gameplay timer itself is already 4.0 − 1/60 by the time any `_process` runs.
- So the earliest value any frame-rate driver can show is 0.65 × (1 − 1/240) ≈ 0.6473.
- I propose asserting "first sample after the hit ≥ 0.65·(1 − frame_game_time/4)" together with the exact formula in check 5. Exactly 0.65 will hold at 60 and 144 fps.

**B. Tolerance under time scale.**
- One frame advances `time_scale/fps` game seconds. At 30 fps and scale 2, that's 1/15 s, which is more than the literal 1/30.
- I propose tolerance = one frame's worth of game time (`time_scale / fps`). Tell me if you want the literal 1/fps instead.

## What headless proves, and what it can't

**What it proves:** the uniform names and types, and the defaults as written in the source. That each scarecrow's own material gets the right `burn_mix` every frame, derived from game time, at 30/60/144 fps and under time scale, pause, retrigger and death. That the materials aren't shared.

**What it can't prove:** anything about pixels. Headless uses a dummy renderer that draws nothing. A `burn_mix` value sitting on a material doesn't show that the GPU applied it, or that `burn_color` reached the shader unconverted.

**Human checks (windowed, 1280×720):**
1. Controlled `burn_mix` of 0.0, 0.5 and 1.0, captured in-engine, with the three named pixels sampled against the §6 table (±1 on the three half-integer channels). This also tests the `source_color`/HDR-off assumption.
2. A 2.0 assignment with a screenshot, to check short answer 7 (whether `hint_range` clamps).
3. The tint appears and clears clearly; the fade doesn't look abrupt; a refresh is noticeable.
4. No visible change while paused.
5. A frame captured after a burning death shows no leftover tint.
6. Three scarecrows in one frame, with only the ignited one tinted.
7. Readability against the green field, and whether straw, patch, head and hat details stay legible at 0.65.

## Before you approve

- `logs/test_rules_60fps.log` and `logs/test_input_60fps.log` are tracked in git, and `run-test.sh` overwrites them. I left them untouched in this run. Running the tests in Step 3 will change them; the baseline copies in `evidence/baseline/` aren't affected.
- I won't commit anything.

Which step should I start with, and how do you want issues A and B decided?