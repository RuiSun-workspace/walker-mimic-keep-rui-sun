# CHANGE-BRIEF — Assignment 6: Particle Effects

**Author:** Rui Sun  
**Course:** CSYE 7270, Fall 2026  
**Project:** Mimic Keep  
**Engine:** Godot 4.7.2  
**Renderer:** Forward+

The Assignment 5 version of this brief is preserved at tag a5. This is the original Assignment 6 brief, dated 2026-11-05. If the design changes after implementation begins, each revision will be added below the original text with its date instead of silently replacing the earlier decision.

## 1. The Jobs

### Effect A — Arrow Impact Burst

This effect tells the player that an arrow actually hit a scarecrow. It separates a successful hit from an arrow that only passed nearby or left the screen.

The current hit occurs in `godot/game/scarecrow.gd:33-39`. `godot/game/arrow.gd:22` calls `Scarecrow.hit()`, but there is currently no hit signal that presentation code can observe.

I will add this presentation-only signal to `scarecrow.gd`:

```gdscript
signal hit_taken(position: Vector2)
```

An accepted call to `hit()` will emit `hit_taken(global_position)` after damage is applied and before the death check: after `ignite()` and before `_check_death()`, between `scarecrow.gd:38` and `:39`. The current collision system does not calculate a precise surface contact point, so the scarecrow's global centre is the defined impact position.

The signal does not change HP, Burning, movement, collision, or any other gameplay state. It only exposes an event that has already happened.

### Effect B — Burning Embers

This effect is a feedback loop. It tells the player that a scarecrow is still Burning and gives a visual indication of how much burn time remains.

Its authoritative state remains in `godot/game/scarecrow.gd`:

- `burning_started` at line 8 marks the first ignition.
- `burning_ended` at line 9 marks normal burnout.
- `burn_time_left` at line 16 stores the remaining time.
- `ignite()` at lines 42–46 refreshes the timer without emitting another `burning_started` signal when the scarecrow is already burning.

The particle driver will therefore read `burn_time_left` every frame. It cannot rely only on the two signals.

Effect B uses value-driven `amount_ratio` and turbulence. Effect A does not use either feature. This is also why Effect B must use GPUParticles2D: CPUParticles2D in Godot 4.7.2 does not provide these properties.

## 2. Intent

### Effect A — Arrow Impact Burst

- **Timing phases:** The first frame should contain a sharp yellow-white flash at the hit point. The flash lasts about 0.28 s, or roughly eight frames at 30 fps. The straw fragments remain for about 0.80 s. They can overlap the next regularly timed hit after 0.60 s, but they disappear before a third regularly timed hit at 1.20 s. The flash communicates the exact moment of impact, while the fragments provide a short visible aftermath.
- **Background contrast:** The bright flash should be visible against meadow grass, grass tufts, and the dark gate. The darker orange-brown straw fragments should remain visible against the gray stone wall and pale walkway. The flash and fragments provide opposite kinds of contrast rather than depending on one color alone.
- **Scale against the character:** The initial flash should be smaller than the scarecrow's head. The fragments may spread to approximately the width of the scarecrow, but the burst should not cover nearby enemies.
- **Change over life:** The flash begins small and bright, briefly expands, changes from pale yellow to orange, and fades. The fragments move outward, fall under gravity, become darker, shrink, and fade.
- **Variation:** Each burst varies the speed, direction, damping, and size of its straw fragments. This prevents repeated hits from looking like the same animation replayed every time.
- **Emitters:** The effect has two emitters. One creates the short additive flash, and the other creates falling straw fragments.

### Effect B — Burning Embers

- **Timing phases:** The first embers begin rising immediately after ignition and take about 0.50 s to reach the top of the scarecrow. The ember stream takes about 0.90 s to become fully established. It then becomes less dense as `amount_ratio` follows the remaining burn time. When Burning ends, emission stops, but existing particles may leave a fading tail for up to 1.20 s, which is the smoke lifetime.
- **Background contrast:** Bright yellow-orange embers should read clearly against the meadow, grass tufts, and dark gate. A second layer of faint dark smoke provides contrast against the brighter stone wall and walkway.
- **Scale against the character:** Most particles should stay close to the scarecrow's body. Embers and smoke may rise above its head, but the effect should not become large enough to look like a separate enemy or environmental fire.
- **Change over life:** Embers rise, change from pale yellow to orange-red, shrink, and disappear. Smoke starts compact, expands slightly, drifts sideways, and fades.
- **Variation:** Particle velocity, size, damping, and direction vary within a limited range. Smoke also uses mild turbulence so that it does not rise in identical straight lines.
- **Emitters:** The effect has two continuous emitters: one for bright embers and one for faint smoke.

## 3. Settings

Both effects use GPUParticles2D. Godot defines `amount_ratio` as a way to vary emission without restarting the particle system, while `local_coords` controls whether existing particles follow their parent. See the [Godot GPUParticles2D documentation](https://docs.godotengine.org/en/stable/classes/class_gpuparticles2d.html). Turbulence is supplied by ParticleProcessMaterial, not by the particle node itself. See the [Godot ParticleProcessMaterial documentation](https://docs.godotengine.org/en/stable/classes/class_particleprocessmaterial.html).

Every emitter's ParticleProcessMaterial sets `particle_flag_disable_z = true`, because these are 2D effects. The 4.7.2 default is `false`, which leaves emission, spread and turbulence in three dimensions. Vectors are written as the material stores them, as `Vector3` with z = 0.

### Effect A — GPUParticles2D

GPUParticles2D is used so that Step 6 can convert and inspect its generated particle shader. Each accepted hit creates a new burst scene under a presentation-only `World/Effects` container. Reusing one one-shot node is not allowed because a second hit could occur before the first one has finished.

#### A1 — Impact Flash

| Area | Setting |
| --- | --- |
| Node | GPUParticles2D |
| Initial state | `emitting = false` |
| Amount | 10 |
| One shot | true |
| Explosiveness | 1.0 |
| Lifetime | 0.28 s |
| Emission shape | `EMISSION_SHAPE_SPHERE`, `emission_sphere_radius = 3` px |
| Direction | `direction = (0, -1, 0)`; with a 180° spread the burst is radial |
| Velocity | `initial_velocity_min = 80`, `initial_velocity_max = 140` |
| Spread | 180° |
| Gravity | `(0, 100, 0)` |
| Damping | `damping_min = 30`, `damping_max = 50` |
| Scale | `scale_min = 0.5`, `scale_max = 1.1` |
| Color ramp | Pale yellow-white at the start, orange near the middle, orange with zero alpha at the end |
| Scale curve | 0.35 at birth, 1.20 near the first third, 0.0 at the end: points (0, 0.35), (0.33, 1.20), (1, 0); `Curve.max_value = 1.5`, because a 4.7.2 Curve defaults to 0–1 and silently stores 1.20 as 1.0 |
| Texture | Code-generated soft white dot, saved as a new particle texture: `godot/effects/textures/soft_dot.png`, 16×16 px (at most about 21 px on screen, smaller than the scarecrow's head) |
| Blend mode | Additive (`CanvasItemMaterial.blend_mode = BLEND_MODE_ADD`) |
| Disable Z | `particle_flag_disable_z = true` |
| `local_coords` | false; emitted particles remain at the impact position |
| `visibility_rect` | `Rect2(-64, -64, 128, 128)`, manually set and then checked with Generate Visibility Rect |
| Preprocess | 0.0; the burst must not exist before a hit |

The color-ramp stops will be:

- 0.0: `Color(1.0, 1.0, 0.80, 0.60)` (revision r1, 2026-11-08; was alpha 1.0)
- 0.35: `Color(1.0, 0.55, 0.08, 0.55)` (revision r1, 2026-11-08; was alpha 0.90)
- 1.0: `Color(1.0, 0.25, 0.02, 0.0)`

**Revision r1 (2026-11-08):** the first two stops' alpha was lowered so the flash adds less light
at its start. Rui saw in the running game that the flash's start was still a little bright and
could hide the straw flying out; Rui approved the change and kept it after playing (TUNING.md,
revision r1).

#### A2 — Straw Fragments

| Area | Setting |
| --- | --- |
| Node | GPUParticles2D |
| Initial state | `emitting = false` |
| Amount | 12 |
| One shot | true |
| Explosiveness | 1.0 |
| Lifetime | 0.80 s |
| Emission shape | `EMISSION_SHAPE_SPHERE`, `emission_sphere_radius = 5` px |
| Direction | Mainly upward: `direction = (0, -1, 0)` |
| Velocity | `initial_velocity_min = 70`, `initial_velocity_max = 130` |
| Spread | 40°; each side reaches about 35 px, so the fragments span about 70 px, roughly the scarecrow's 56 px width, and rise at most about 32 px |
| Gravity | `(0, 260, 0)` |
| Damping | `damping_min = 5`, `damping_max = 15` |
| Scale | `scale_min = 0.4`, `scale_max = 0.9` |
| Rotation | `angle_min = 0`, `angle_max = 360`; every chip starts at a different angle |
| Color ramp | Golden straw at birth, brown later, transparent dark brown at the end |
| Scale curve | 0.70 at birth, 1.0 shortly after birth, 0.0 at the end: points (0, 0.70), (0.15, 1.0), (1, 0) |
| Texture | Code-generated narrow white straw-chip texture: `godot/effects/textures/straw_chip.png`, 4×12 px (about 2–4 × 5–11 px on screen) |
| Blend mode | Mix (`CanvasItemMaterial.blend_mode = BLEND_MODE_MIX`) |
| Disable Z | `particle_flag_disable_z = true` |
| `local_coords` | false; fragments do not follow a moving or dying scarecrow |
| `visibility_rect` | `Rect2(-96, -96, 192, 192)`, manually set and checked |
| Preprocess | 0.0; nothing should appear during scene loading |

Color-ramp stops:

- 0.0: `Color(0.91, 0.77, 0.42, 1.0)`, the scarecrow's straw colour (233, 196, 106)
- 0.5: `Color(0.55, 0.36, 0.16, 0.90)`
- 1.0: `Color(0.30, 0.18, 0.08, 0.0)`

The flash and fragment emitters both have nonzero gravity, a color ramp, and a scale curve. These settings must remain present so the generated shader in Step 6 contains the corresponding logic.

### Effect B — GPUParticles2D

GPUParticles2D is required because the visual density is driven by `amount_ratio`, and the smoke uses turbulence. The emitters belong to each individual scarecrow so every instance can have its own value.

Both emitters use:

```
amount_ratio = clamp(burn_time_left / 4.0, 0.0, 1.0)
```

The driver changes `amount_ratio`, not `amount`. Changing `amount` would restart or reallocate the system instead of smoothly changing the emission density.

#### B1 — Embers

| Area | Setting |
| --- | --- |
| Node | GPUParticles2D |
| Initial state | `emitting = false`, `amount_ratio = 0.0` |
| Amount | 18 |
| One shot | false |
| Explosiveness | 0.0 |
| Lifetime | 0.90 s |
| Emission shape | `EMISSION_SHAPE_BOX`, `emission_box_extents = (18, 30, 0)` |
| Direction | Upward: `direction = (0, -1, 0)` |
| Velocity | `initial_velocity_min = 25`, `initial_velocity_max = 45` |
| Spread | 25° |
| Gravity | `(0, -20, 0)` |
| Damping | `damping_min = 5`, `damping_max = 10` |
| Scale | `scale_min = 0.35`, `scale_max = 0.70` |
| Color ramp | Pale yellow, orange, then transparent red-orange |
| Scale curve | 0.60 at birth, 1.0 near the middle, 0.10 at the end: points (0, 0.60), (0.5, 1.0), (1, 0.10) |
| Texture | The same code-generated soft-dot texture used by the impact flash, `godot/effects/textures/soft_dot.png` (about 6–11 px on screen) |
| Blend mode | Additive (`CanvasItemMaterial.blend_mode = BLEND_MODE_ADD`) |
| Disable Z | `particle_flag_disable_z = true` |
| `local_coords` | true; embers follow the moving scarecrow while it is alive |
| `visibility_rect` | `Rect2(-48, -80, 96, 120)`, manually set and checked |
| Preprocess | 0.0; a non-burning scarecrow must not begin with particles |

Color-ramp stops:

- 0.0: `Color(1.0, 0.95, 0.63, 1.0)`
- 0.45: `Color(1.0, 0.54, 0.12, 0.90)`
- 1.0: `Color(0.85, 0.29, 0.07, 0.0)`

#### B2 — Smoke

| Area | Setting |
| --- | --- |
| Node | GPUParticles2D |
| Initial state | `emitting = false`, `amount_ratio = 0.0` |
| Amount | 8 |
| One shot | false |
| Explosiveness | 0.0 |
| Lifetime | 1.20 s |
| Emission shape | `EMISSION_SHAPE_BOX`, `emission_box_extents = (16, 26, 0)` |
| Direction | Upward: `direction = (0, -1, 0)` |
| Velocity | `initial_velocity_min = 12`, `initial_velocity_max = 22` |
| Spread | 35° |
| Gravity | `(0, -8, 0)` |
| Damping | `damping_min = 1`, `damping_max = 4` |
| Scale | `scale_min = 0.60`, `scale_max = 1.0` |
| Color ramp | Transparent brown-gray smoke that fades completely |
| Scale curve | 0.50 at birth, 1.40 near the end, then 0.0: points (0, 0.50), (0.85, 1.40), (1, 0); `Curve.max_value = 1.5`, for the same reason as A1 |
| Turbulence | `turbulence_enabled = true`; `turbulence_influence_min = 0.15`, `turbulence_influence_max = 0.30` |
| Texture | Code-generated soft smoke dot: `godot/effects/textures/smoke_dot.png`, 32×32 px (about 27–45 px on screen) |
| Blend mode | Mix (`CanvasItemMaterial.blend_mode = BLEND_MODE_MIX`) |
| Disable Z | `particle_flag_disable_z = true` |
| `local_coords` | true; smoke follows the living scarecrow |
| `visibility_rect` | `Rect2(-64, -100, 128, 150)`, manually set and checked |
| Preprocess | 0.0; the system begins only after ignition |

Color-ramp stops:

- 0.0: `Color(0.29, 0.19, 0.15, 0.35)`
- 0.55: `Color(0.22, 0.16, 0.14, 0.20)`
- 1.0: `Color(0.16, 0.13, 0.12, 0.0)`

At `amount_ratio = 1.0`, the Ember emitter produces approximately:

```
18 particles / 0.90 s = 20 embers per second
```

The Smoke emitter produces approximately:

```
8 particles / 1.20 s = 6.67 smoke particles per second
```

These rates explain why the particle stream is sparse on the ignition frame and takes several frames to build up.

The new particle textures will be generated by committed project code, `godot/tools/make_particle_textures.gd`, beside the existing `godot/tools/make_sprites.gd`. No existing sprite or source texture will be edited.

## 4. Measurable Rules

### Rule A1 — Trigger

Every accepted call to `Scarecrow.hit()` emits exactly one `hit_taken` event and creates exactly one impact-burst instance.

The effect must not trigger during scene loading, from movement, from burning damage ticks, when Burning ends, or when an arrow leaves the screen without hitting anything.

### Rule A2 — Position

The burst origin must equal the position carried by `hit_taken`, with a tolerance of 1 px.

For the current collision model, this position is the scarecrow's global centre at the moment the hit is accepted.

### Rule A3 — Retrigger and Overlap

Retrigger behavior is **overlap**. Each hit creates a separate burst instance. A new hit must not restart, clear, or reuse an earlier burst.

The archer fires every 0.60 s, but arrows travel different distances before reaching their targets. Their hit times can therefore be closer together than their firing times. Under the expected gameplay conditions, as many as three burst instances may still be alive at the same time.

```
10 flash particles + 12 straw particles = 22 particles per burst
3 bursts x 22 particles = 66 peak particles
```

The overlap test must count live burst instances when each arrow actually hits. It must not assume that hit times are always exactly 0.60 s apart.

### Rule A4 — Lethal Hit

The hit signal is emitted before the scarecrow's death check. If the hit kills the scarecrow, the burst is created under `World/Effects`, not under the scarecrow.

The scarecrow may be freed in the same frame, but the burst must remain for up to 0.80 s and finish normally.

### Rule A5 — Cleanup and Reset

Each burst frees itself when its longest emitter, the straw fragments (0.80 s), emits `finished`. `World/Effects` must not collect finished bursts.

`reset()` in `godot/game/main.gd:37-40` clears only `World/Enemies` and `World/Arrows`, and `main.gd` stays unchanged. After a restart with R or Enter, a burst or a set of dying B emitters already under `World/Effects` therefore finishes playing, for at most 1.20 s, before freeing itself. This carry-over is accepted.

### Rule B1 — Start and Normal End

When `burning_started` is received:

- Both emitters set `emitting = true`.
- Both emitters set `amount_ratio = 1.0`.

When `burning_ended` is received:

- Both emitters set `amount_ratio = 0.0`.
- Both emitters set `emitting = false`.
- Already-emitted particles may finish their remaining lifetime.
- No new particles may be emitted.

### Rule B2 — Value Mapping

Both B emitters use the same mapping:

| `burn_time_left` | Expected `amount_ratio` |
| --- | --- |
| 4.0 s | 1.00 |
| 3.0 s | 0.75 |
| 2.0 s | 0.50 |
| 1.0 s | 0.25 |
| 0.0 s | 0.00 |

The driver updates the value once per frame. The permitted timing tolerance is one frame at the tested frame rate.

Tests must inspect `amount_ratio`. They must not accept a change to `amount` as equivalent behavior.

### Rule B3 — Ignited Again While Burning

A second fire hit while already Burning does not emit `burning_started`. Gameplay instead resets `burn_time_left` to 4.0 s.

Because the driver reads the timer every frame, both `amount_ratio` values must jump back to 1.0 within one frame. Existing particles are not cleared, and the emitter is not restarted.

### Rule B4 — Death While Burning

A scarecrow killed while Burning emits `died` and is queued for deletion without emitting `burning_ended`.

On `died`, both B emitters must:

1. Preserve their current global transforms.
2. Stop emission immediately.
3. Set `amount_ratio = 0.0`.
4. Move to the presentation-only `World/Effects` container.
5. Allow existing particles to fade.
6. Free themselves after the smoke lifetime of 1.20 s.

No new embers may appear after the scarecrow dies.

### Rule B5 — Pause and End of Game

The particle nodes use inherited process mode.

When the tree is paused with Esc or P:

- Existing particles remain visible but frozen.
- Particle age, movement, and emission do not advance.
- `amount_ratio` and `burn_time_left` do not change.
- Resuming continues from the same state.

When `main.gd:95` sets `World.process_mode` to `PROCESS_MODE_DISABLED`, the effect also freezes. It remains at its last visible state until the game is reset. It does not continue consuming burn time behind the result screen.

### Rule B6 — Hidden Node Prediction

If a B emitter is hidden:

- It draws no particles while hidden.
- My prediction is that its simulation continues unless the tree is also paused or its process mode is disabled.
- When shown again, it displays particles at their current ages instead of restarting from the beginning.

This is a prediction for the implementation test. If Godot 4.7.2 pauses hidden GPU particle simulation instead, the measured result will be recorded in the test report.

### Rule B7 — Independent Scarecrows

Each scarecrow owns separate Ember and Smoke nodes.

If one scarecrow has 4.0 s remaining and another has 1.0 s remaining, their expected ratios are 1.0 and 0.25. Updating one must not change the other.

## 5. Boundaries

This assignment changes presentation only.

The following remain unchanged:

- Collision shapes and collision checks.
- Arrow movement and targeting.
- Scarecrow movement.
- HP values and damage calculations.
- Burning duration and Burning DPS.
- Input and pause controls.
- State-machine behavior.
- Win, loss, restart, and spawn rules.
- Expectations in all existing tests.
- Existing shaders under `godot/shaders/`.
- Original sprite and environment textures.
- Every object not involved in the two new presentation effects.

The particle drivers may read gameplay variables and listen to gameplay signals. They may not write HP, `burn_time_left`, movement state, gate damage, timers, or game state.

### Boundary exception: hit event

Effect A requires a presentation event that does not currently exist. The only gameplay-script change allowed is:

- Add `hit_taken(position: Vector2)` to `godot/game/scarecrow.gd`.
- Emit it once inside an accepted `hit()` call.
- Emit the scarecrow's current `global_position`.
- Do not change the order or result of damage, ignition, or death.

`godot/game/arrow.gd`, `tuning.gd`, `main.gd`, `archer.gd`, existing tests, and the Assignment 5 shaders will otherwise remain unchanged.

Presentation nodes may be added under `World/Effects`, and presentation scripts may be attached to the scarecrow scene. `World/Effects` is a new Node2D added to `godot/game/main.tscn` under World, after Archer, so effects draw above the scarecrows and the archer. It is the only change to `main.tscn`.

## 6. Evidence Split

Every state test drives the game through the real game loop: arrows fired by the archer and real key input. It never calls `hit()`, `ignite()` or an effect's trigger function directly. A feedback-loop test may set `burn_time_left` to controlled values, as the assignment allows for the game value.

A headless run uses a dummy renderer and runs no GPU particle process. It can read node state (`emitting`, `one_shot`, `amount_ratio`, `visible`, process mode, instance counts and positions, `burn_time_left`), but not whether particles are visible, moving or frozen.

| Rule | Evidence | How it will be checked |
| --- | --- | --- |
| A1 — Trigger | Headless state test | Count accepted hits from real arrows, emitted signals, and created burst instances. Verify scene load and burn ticks create none. |
| A2 — Position | Headless state test | Compare the signal position and burst global position with a tolerance of 1 px. |
| A3 — Overlap | Headless state test and frame strip | Fire real arrows from different distances so their impact times become closer together. Verify that three distinct burst instances can coexist and that a newer hit does not restart or delete an older burst. |
| A4 — Lethal hit | Headless state test and frame strip | Kill a scarecrow with one hit, confirm the scarecrow is freed, and confirm its independent burst node remains until its lifetime ends. The frame strip shows that its particles are still drawn after the scarecrow is gone. |
| A5 — Cleanup and reset | Headless state test | After a burst's `finished`, its node is gone from `World/Effects`. After a reset with a live burst, `World/Effects` is empty within 1.20 s. |
| B1 — Start/end | Headless state test | Read `emitting` and `amount_ratio` immediately after `burning_started` and `burning_ended`. |
| B2 — Mapping | Headless configuration/state test | Set controlled remaining times and compare both emitters' `amount_ratio` values to the table. |
| B3 — Re-ignition | Headless state test and frame strip | Lower the ratio, hit the burning scarecrow again with a real fire arrow, and verify the ratio returns to 1.0 without replacing the particle nodes. |
| B4 — Death | Headless state test and frame strip | Headless: kill a burning scarecrow, verify emission stops, the nodes move to `World/Effects`, and they free after at most 1.20 s. Frame strip: the existing embers and smoke are still drawn after the move and fade out. |
| B5 — Pause/end | Headless state test and visual check | Headless: record node state (`emitting`, `amount_ratio`, `burn_time_left`) before and during pause, and with World disabled, and verify it does not advance. Frame strip or running game: particles freeze rather than disappear. |
| B6 — Hidden node | Windowed test | Hide the emitter for a controlled interval, show it again, and record whether particle age advanced. This cannot be established from a headless screenshot. |
| B7 — Independent instances | Headless state test | Create two burning scarecrows with different timers and assert that their nodes and ratios are independent. |
| Contrast and readability | Human check | Play at the real 1280 × 720 size and inspect both effects over grass, wall, walkway, and gate backgrounds. |
| Color, scale, and motion | Frame-strip inspection | Compare captured frames with the visual intent. Headless property tests cannot prove that the effect looks clear or natural. |
| Configuration values | Headless configuration test | Read every node and material property listed in Section 3, including ramps, curves, turbulence, blend modes, Disable Z, and preprocess. |

## 7. Frame Strips

Both strips use the real game background. The scarecrow is positioned near its stopping point at y = 530, above the castle wall, so the capture includes meadow, walkway, and wall colors.

The capture runs at 30 fps.

### Effect A Frame Strip

The first hit occurs at frame 10. A second hit occurs at frame 28, which is the normal 0.60 s firing interval later.

| Frame | Expected image |
| --- | --- |
| 10 | A compact yellow-white flash appears at the hit point, with the first straw pieces beginning to move outward. |
| 12 | The flash is wider and orange at its edges. Straw fragments are visibly separated from the centre. |
| 15 | The flash is fading. Fragments are still moving outward and beginning to fall. |
| 20 | The flash is gone or almost gone. Only darker falling straw fragments remain. |
| 30 | The second impact has created a new bright flash. The final fragments from the first burst are still visible, proving overlap. |
| 50 | The second flash is gone and its last fragments are faint, low, and close to disappearing. |

The capture should continue past frame 52 so it can also confirm that both bursts eventually disappear.

### Effect B Frame Strip

Ignition occurs at frame 10. Four seconds at 30 fps equals 120 frames, so normal Burning ends at approximately frame 130. The capture uses `--quit-after 200` or longer.

| Frame | Expected image |
| --- | --- |
| 10 | Ignition has just occurred. At most one ember is visible, and smoke has not appeared yet. The effect should not look fully formed on its first frame. |
| 20 | About six embers and one or two smoke particles are visible. The embers are still rising around the body and have not all reached the top of the scarecrow. |
| 40 | Burning is still strong, but the emission density has begun to decrease. |
| 70 | The effect is around its middle value. Embers are less frequent, while earlier particles continue fading normally. |
| 100 | Only occasional embers and light smoke remain. The scarecrow still reads as Burning, but close to the end. |
| 130 | `amount_ratio` has reached zero and no new particles are emitted. A few particles from before the endpoint may still be fading. |
| 170 | All embers and smoke are gone. No particle residue remains around the non-burning scarecrow. |

A second version of the strip will call `ignite()` again around frame 100. The next captured frame should show `amount_ratio` back at full value without clearing already-existing particles.

## 8. Predicted Failures

1. **Godot 3 property names are used.**
   Values such as a single floating-point `initial_velocity` or `scale` may be silently ignored, leaving the minimum and maximum at zero. The configuration test will read back `initial_velocity_min`, `initial_velocity_max`, `scale_min`, and `scale_max` and catch this.
2. **A one-shot node is reused for every hit.**
   Setting `emitting = true` again while the original one-shot burst is active may lose a later burst. Rule A3's overlap test will catch this by requiring three separate live burst instances.
3. **The impact burst is parented to the scarecrow.**
   A lethal hit would free the parent and remove the effect immediately. Rule A4's death test and frame strip will catch the missing burst.
4. **Effect B changes `amount` instead of `amount_ratio`.**
   The system may restart when the value changes, causing embers to disappear and reappear unnaturally. The B2 configuration test reads `amount_ratio`, and the frame strip checks continuity.
5. **The driver listens only to `burning_started`.**
   Re-ignition while already Burning would not restore full density because no second signal is emitted. Rule B3 directly tests a timer refresh during Burning.
6. **The driver waits for `burning_ended` after death.**
   A burning scarecrow can die without emitting that signal, leaving an emitter in the wrong state. Rule B4 uses the `died` path and checks cleanup time.
7. **The particles have poor contrast on grass.**
   Orange particles may be too close in brightness to the meadow. The in-game readability check compares the effect against every real background.
8. **The additive material is missing.**
   The flash or embers could appear as gray or dark squares instead of light. The configuration test checks the blend mode, and the frame strip catches the visual result.
9. **The visibility rectangle is too small.**
   Rising particles could disappear early when the emitter approaches a screen edge. The generated-rectangle check and a windowed edge-position test will catch this.

## 9. Price Predictions and Budget

These are predictions written before measurement.

### Effect A

One burst allocates:

```
10 flash particles + 12 straw particles = 22 particles
```

Although arrows are fired at 0.60 s intervals, their flight times vary with target distance. Several arrows can therefore land closer together than their firing times. The expected maximum is three simultaneously living burst instances:

```
22 x 3 = 66 peak particles
```

Predicted prices:

- Headless CPU time: close to the empty-scene control.
- Windowed GPU time: below 0.15 ms.
- Effect A budget: 0.25 ms GPU time.

Because this is a GPU particle effect, the meaningful comparison is measured GPU time against the 0.25 ms GPU budget. The headless CPU result is recorded only as a diagnostic.

### Effect B

One active or fading scarecrow effect allocates:

```
18 ember particles + 8 smoke particles = 26 particles
```

The expected gameplay peak is approximately eight simultaneously burning scarecrows. Up to two additional scarecrows may have died while their detached particles are still completing the 1.20 s smoke tail. The conservative peak is therefore:

```
8 active Burning effects + 2 fading death tails = 10 effect sets
10 x 26 = approximately 260 particles
```

Reducing `amount_ratio` does not reduce the allocation budget, so the calculation uses the full amount.

Predicted prices:

- Headless CPU time: close to the empty-scene control.
- Windowed GPU time: below 0.35 ms.
- Effect B budget: 0.60 ms GPU time.

The larger B budget accounts for the increased peak count, two emitters per effect, and smoke turbulence.

### Combined Budget

```
66 Effect A particles + 260 Effect B particles
= approximately 326 peak allocated particles
```

The combined predicted GPU time is below 0.50 ms, with a combined budget of 0.85 ms.

Both final prices will be compared using windowed GPU measurements because both effects use GPUParticles2D.

## 10. Answers

**1. Which node does each effect use, and which planned features are not properties of that node?**

Both effects use GPUParticles2D.

Effect A uses two GPU particle nodes because the assignment later converts and inspects a generated particle shader. Effect B also uses two GPU particle nodes because it needs `amount_ratio` and turbulence, which CPUParticles2D does not provide in Godot 4.7.2.

Velocity, gravity, damping, ramps, curves, and turbulence are not direct GPUParticles2D properties. They belong to each node's ParticleProcessMaterial. The additive or mix blend mode belongs to a CanvasItemMaterial.

**2. What happens to Effect A if its parent moves after the event?**

Effect A uses `local_coords = false`. Existing particles stay in global space at the original impact location. Moving the parent after the event does not drag the burst across the screen.

The burst is also placed under `World/Effects` instead of under the scarecrow, so deleting the scarecrow does not delete the burst.

**3. How many A bursts can overlap, and what is the peak particle count?**

The retrigger rule is overlap. Although arrows are fired every 0.60 s, they travel different distances, so their impacts do not necessarily remain 0.60 s apart. As many as three burst instances may therefore be alive at the same time.

```
3 x 22 = 66 peak Effect A particles
```

**4. What price does a headless run report, and what happens with VSync?**

A headless performance run reports CPU time, not GPU rendering time. Because the particle drawing and GPU simulation are not measured there, its result should remain close to the empty-scene control. A low headless value does not prove that the particle effect has no GPU cost.

On a 60 Hz display with VSync enabled, both "effects off" and "effects on" should display approximately 60 fps as long as neither version misses the frame budget. Equal VSync-limited FPS does not prove that the particles are free, so GPU frame time must be measured separately.

**5. What does B show on the first frame, while paused, and while hidden?**

The actual design uses `preprocess = 0.0` and begins with `emitting = false`, so the first scene frame contains no embers or smoke.

Without preprocess, an emitter started on that frame begins nearly empty and fills naturally as new particles are emitted. With a positive preprocess value, an emitter that starts active appears as though it has already been running, so the first frame contains particles at different ages. This design does not use that behavior because a non-burning scarecrow must begin clean.

While the tree is paused, existing particles remain visible but frozen. Their age, movement, and emission do not advance.

While the node is hidden, it draws nothing. My prediction is that the simulation continues, so showing it again reveals the current simulation state rather than restarting it. The windowed hidden-node test will verify this prediction.

Preprocess changes the initial warmed-up state; it does not change the selected pause or hidden-node rules.

**6. Which settings belong to emission, process, and draw?**

Emission settings:

- `amount`
- `amount_ratio`
- `emitting`
- `one_shot`
- `explosiveness`
- `lifetime`
- emission shape, radius, or box extents

Process settings:

- direction
- `initial_velocity_min` and `initial_velocity_max`
- spread
- gravity
- `damping_min` and `damping_max`
- `scale_min` and `scale_max`
- color ramp
- scale curve
- turbulence

Draw settings:

- particle texture
- CanvasItemMaterial blend mode

`local_coords`, `visibility_rect`, and `preprocess` are particle-node simulation or culling controls rather than the particle's process motion or draw appearance.

## Revision Log

Changes to the original prediction are recorded below with a date.

- **2026-11-05 (review, before any prompt):** Rui's original text is commit b1d2e08. Claude converted it to Markdown and applied the corrections Rui approved (listed in FRICTIONAL.md, 2026-11-05): `direction`, `particle_flag_disable_z = true` and `Vector3` gravity on every emitter, 4.7.2 property names for emission shapes, turbulence and blend modes, the `hit_taken` emit position, real-arrow test driving and the headless-versus-strip split in Section 6, curve points with `Curve.max_value = 1.5` for A1 and B2, A2's colour-ramp stops, texture paths and sizes, A2 spread 150° → 40° and angle 0–360, the `World/Effects` node, and Rule A5. Added by Claude.
- **2026-11-05:** Added phase durations, corrected the early Effect B frame predictions, and revised the peak counts and performance budgets using the expected maximum of three overlapping A bursts and ten active-or-fading B effect sets.
- **2026-11-08 (tuning r1):** A1 Flash colour-ramp alpha at stops 0.0 and 0.35 lowered from 1.0 and 0.90 to 0.60 and 0.55, kept by Rui in the running game. Section 3 updated so the brief, `impact_burst.tscn` and `test_impact_burst_config.gd` agree. Written by Claude from Rui's verdict.
