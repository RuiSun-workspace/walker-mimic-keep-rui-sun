# CLAUDE.md — Mimic Keep

## Project context

- **Engine:** Godot 4.7.2 stable, `4.7.2.stable.official.ed1daf0bf` (README.md:18); `config/features`
  lists `"4.7"`, `"Forward Plus"` (godot/project.godot:16). **Renderer:** Forward+, the default, so
  `rendering_method` is absent (README.md:19-20); no HDR 2D key (godot/project.godot:51-53); 1280×720,
  stretch `canvas_items` (:20-22); main scene `res://game/main.tscn` (:15).

### Effect A — Arrow Impact Burst: two GPUParticles2D, flash A1 + straw A2 (CHANGE-BRIEF.md §3)
- Event owner: `Scarecrow.hit(damage, element)` (godot/game/scarecrow.gd:33-39), called only from
  godot/game/arrow.gd:22 when an arrow is within `ARROW_HIT_RADIUS` 26 px (godot/game/tuning.gd:15).
- `signal hit_taken(position: Vector2)` **does not exist yet**; the brief allows adding it and emitting
  `global_position` between scarecrow.gd:38 (`ignite()`) and :39 (`_check_death()`) (CHANGE-BRIEF.md §5).
- A lethal hit: `_check_death()` removes the group, emits `died`, `queue_free()`s (scarecrow.gd:70-74).
  Fire interval 0.6 s (tuning.gd:10). Appears in: one new burst scene per hit under a new Node2D
  `World/Effects` after `World/Archer` (CHANGE-BRIEF.md §5). Today `World` holds `Enemies`, `Arrows`,
  `Archer` (godot/game/main.tscn:19-26); `reset()` frees only Enemies and Arrows children (main.gd:36-40).

### Effect B — Burning Embers: two GPUParticles2D, embers B1 + smoke B2 (CHANGE-BRIEF.md §3)
- Condition owner: `Scarecrow` (godot/game/scarecrow.gd:1): signals `burning_started`, `burning_ended`,
  `died` (lines 8-10); `burn_time_left` (16); `is_burning()` is `burn_time_left > 0.0` (25-26). `ignite()`
  emits `burning_started` only when not already burning, so a refresh emits nothing (42-46). The
  countdown in `_physics_process` ends at ≤ `BURN_END_EPSILON` (13) with `burning_ended` (49-59); death
  while burning emits `died`, never `burning_ended` (60, 70-74). `BURN_DURATION := 4.0`,
  `BURN_DPS := 4.0` (godot/game/tuning.gd:26-27).
- Appears in: every scarecrow. `godot/game/scarecrow.tscn` = root `Scarecrow` (Node2D) + child `Sprite`
  (Sprite2D, local-to-scene ShaderMaterial on Rui's `burning_tint.gdshader`, driver `burning_tint.gd`)
  (scarecrow.tscn:8-18); instanced by `Game.spawn_scarecrow()` into `World/Enemies` (main.gd:10, 51-57).
  Game end sets `World.process_mode = PROCESS_MODE_DISABLED` (main.gd:95); `reset()` restores it (:47).
- Not present yet: `godot/effects/`, its `textures/*.png` and `godot/tools/make_particle_textures.gd` (brief §3).

### Tests — always through scripts/run-test.sh, from the repository root
`scripts/run-test.sh <test-file.gd> <fps|realtime> [timeout-seconds]` (scripts/run-test.sh:2) runs
`godot --headless [--fixed-fps <fps>] --path godot --script res://tests/<file>` under `timeout` (default
120 s), tees to `logs/<name>_<fps>fps.log`, and exits 1 on a non-zero exit or a `SHADER ERROR` /
`SCRIPT ERROR` log line (lines 3-14). **Realtime mode:** `realtime` drops `--fixed-fps` and logs to
`logs/<name>_realtime.log` (lines 5-6, 10); it is still headless (line 11).

```bash
godot --headless --path godot --import          # after a fresh clone or a deleted godot/.godot (README.md:57)
bash scripts/run-test.sh test_rules.gd 60        # also test_input, test_materials, normal_map_check at 60
bash scripts/run-test.sh test_burning_tint.gd 30 # and 60, 144; test_wall_targeting.gd the same
bash scripts/run-test.sh <test>.gd realtime 180  # realtime mode, 180 s timeout
```
- A6 baseline (commit 056bcc0, evidence/a6-baseline/): test_rules 23/0, test_input 14/0, test_materials
  132/0, normal_map_check 9/0 at 60; test_burning_tint 49/0, test_wall_targeting 10/0 at 30/60/144. One
  PASS/FAIL line per check, exit 1 on failure (godot/tests/test_rules.gd:2-4, 34-35); real keys via
  `Input.parse_input_event` (godot/tests/test_input.gd:2, 51).
- State tests drive real arrows and keys, never `hit()`, `ignite()` or an effect trigger directly; a
  feedback test may set `burn_time_left` (CHANGE-BRIEF.md §6).
- New effect tests: configuration at 60 (prompts/a6/prompt-2.txt:19); state at 60, or realtime if it
  waits on audio (prompts/a6/prompt-3.txt:24-26).

### Headless facts (probed on this machine, Godot 4.7.2)
- A headless run uses a dummy renderer: it draws no particles and runs no GPU particle
  process. Node state (emitting, one_shot, amount_ratio, visibility, instance counts) is
  observable; the look is not. Probe (evidence/a6-probes/headless_particles_probe.txt): empty adapter
  name, display `headless`, empty `capture_rect()`; a 0.3 s one-shot fires `finished` at 0.3 s.
- Frame strips come from a windowed Movie Maker run, which I start.
- `Performance.TIME_PROCESS` read 0.0000 ms with and without 50 × 200 GPU particles: it prices nothing.
- Physics runs at 60 ticks/s whatever `--fixed-fps` says (CHANGE-BRIEF.md at tag a5, revision A).
- GPUParticles2D has `amount_ratio`, `use_fixed_seed`, `seed`, `finished`; CPUParticles2D has no
  `amount_ratio` and no turbulence; `Curve.max_value` defaults to 1.0 (1.2 is stored as 1.0); `direction`
  defaults to (1, 0, 0), `particle_flag_disable_z` to false (FRICTIONAL.md:554-561; probe file).

## Current change

@CHANGE-BRIEF.md

## Ownership

Files in `godot/shaders/` are hand-written by the human (Rui) and are never edited by an agent —
not created, modified, renamed, reformatted or deleted. If a shader looks wrong, report it and stop.
`scripts/check-session.sh` verifies after each session that `godot/shaders/` and
`scripts/run-test.sh` are unchanged (scripts/check-session.sh:29-33).

Effect settings (every value in CHANGE-BRIEF.md §3) live in scene files in `godot/effects/`, with
their ParticleProcessMaterial and CanvasItemMaterial as sub-resources, not in code. Driver scripts
only instance burst scenes, toggle `emitting`, set `amount_ratio`, reparent and free.

## Godot 4 names

Use Godot 4.7.2 names, never Godot 3 ones: `Particles2D` → **GPUParticles2D**, `ParticlesMaterial` →
**ParticleProcessMaterial**, `GradientTexture` → **GradientTexture1D**, `flag_disable_z` →
**`particle_flag_disable_z`**, a single `initial_velocity` / `scale` / `damping` / `angle` → **`_min`/`_max`**.
In 4.7.2 `initial_velocity` and `scale` still exist as editor-only Vector2 ranges that are not stored;
a float assigned to them is silently ignored (FRICTIONAL.md:556-558).
- Node: `amount`, `amount_ratio`, `emitting`, `one_shot`, `explosiveness`, `lifetime`, `preprocess`,
  `local_coords`, `visibility_rect`, `texture`, `process_material`, `material`; signal `finished`.
- ParticleProcessMaterial: `emission_shape` (`EMISSION_SHAPE_SPHERE`/`_BOX`), `emission_sphere_radius`,
  `emission_box_extents`, `direction`, `spread`, `gravity` (Vector3), `initial_velocity_min/max`,
  `damping_min/max`, `scale_min/max`, `angle_min/max`, `color_ramp`, `scale_curve` (CurveTexture),
  `turbulence_enabled`, `turbulence_influence_min/max`, `particle_flag_disable_z`.
- Blend: `CanvasItemMaterial.blend_mode` = `BLEND_MODE_ADD` / `BLEND_MODE_MIX`.
- The rest is the 4.x API, unverified on 4.7.2. `get_property_list()` is no proof (it lists `initial_velocity`):
  check for `PROPERTY_USAGE_STORAGE`, or set the value and read it back. If unsure, report it, don't guess.

## Out of scope

- Game rules: HP, damage, burn length or DPS, the burn timer, movement, targeting, fire rate, arrow
  flight and hit detection, gate damage, spawning, win/loss, pause, restart, the input map. Effect
  code reads `burn_time_left`, `is_burning()` and signals; it never writes game state.
- In `scarecrow.gd`, anything beyond one `hit_taken` signal and its one emit, or reordering damage,
  `ignite()` and `_check_death()`. In `main.tscn`, anything beyond the one `World/Effects` node.
- Editing `tuning.gd`, `main.gd`, `archer.gd`, `arrow.gd`, `project.godot`, any existing test or
  `scripts/run-test.sh`; loosening an existing test expectation.
- Changing `amount` at runtime instead of `amount_ratio`; reusing one one-shot burst node; parenting a
  burst to the scarecrow; CPUParticles2D for either effect.
- The Assignment 5 work (burning tint, shield room, hint experiment), every existing sprite and texture,
  particles on anything but scarecrows and their hits, and GDD systems not built yet (README.md:133-134).

## Unconfirmed

- No `AGENTS.md` exists, so this file has no `@AGENTS.md` line.
- Whether live particles survive reparenting on death (Rule B4) and whether a hidden emitter keeps
  simulating (Rule B6): still predictions (FRICTIONAL.md:585-587).
- Names of the burst scene, the B emitter scene and their driver scripts are not in the brief.
- Whether a GPU effect's headless CPU price is near zero: to be measured by the Step 7 cost script.
