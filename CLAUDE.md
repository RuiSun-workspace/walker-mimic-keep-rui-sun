# CLAUDE.md — Mimic Keep

## Project context

- **Engine:** Godot 4.7.2 stable, `4.7.2.stable.official.ed1daf0bf` (README.md:18); `config/features`
  `"4.7"`, `"Forward Plus"` (godot/project.godot:16). **Renderer:** Forward+, the default, so
  `rendering_method` is absent (README.md:19-20). 1280×720 (godot/project.godot:20-22); main scene
  `res://game/main.tscn` (:15); physics 60/s, no `physics_ticks_per_second` key (whole file).
- No `AGENTS.md` exists, so there is no `@AGENTS.md` line. `godot/animations/` does not exist yet.

### Clip 1 — scarecrow walk (cycle): Sprite2D + AnimationPlayer frame track (CHANGE-BRIEF.md §1-3)
- Node: `Scarecrow/Sprite` (Sprite2D; today single-cell `scarecrow.png`, local-to-scene ShaderMaterial,
  `burning_tint.gd`; godot/game/scarecrow.tscn:11-21). New sheet `godot/assets/sprites/scarecrow_walk.png`,
  4×1 cells of 64×80, from `godot/tools/make_sprites.gd` (brief §2; today's 56×72 is make_sprites.gd:42-43).
- `Scarecrow/AnimationPlayer` holds `walk` (4 keys, step 0.125, 0.5 s, LOOP_LINEAR, discrete) and
  `hold` (frame 0). `Scarecrow/WalkPresenter` (`godot/game/scarecrow_walk_presenter.gd`) picks one
  from `at_wall` (godot/game/scarecrow.gd:18, set at :23, :69) (brief revision 1.4).
- Scene: `godot/game/scarecrow.tscn`, instanced into `World/Enemies` by `Game.spawn_scarecrow()`
  (godot/game/main.gd:51-57). A dead scarecrow is `queue_free()`d at once (scarecrow.gd:72-76).

### Clip 2 — archer shot (committing): 2D cutout rig keyed as resource text (CHANGE-BRIEF.md §1, §4, §6)
- Today: `Archer` (Node2D, `archer.gd`) + one `Sprite` with `archer.png` (godot/game/archer.tscn:6-10),
  instanced as `World/Archer` (godot/game/main.tscn:25-26). `Sprite` gives way to `Rig/Body`,
  `Rig/BowPivot/Bow`, `Rig/BowPivot/String`, `AnimationPlayer`, `AnimationTree` (`idle`, `shoot`);
  keyed on rotation, position, scale; new part images, `archer.png` kept (brief §1, §6, rev. 1.3-1.4).
- **Owner of the player's state machine:** `godot/game/archer.gd`. Today it has no states: it moves
  and fires in one `_physics_process` when `fire_cooldown` hits 0 (archer.gd:14-24). The brief makes it
  push `travel("shoot")` / `playback.start("idle")`, own `shot_armed` and the target, read `release_window` (§5-6).
- Run state (PLAYING/WON/LOST) is `main.gd` (godot/game/main.gd:8): game end disables `World`
  (:94-96), restart only after the end (:81-83), `reset()` (:36-48), which gains one call to
  `archer.cancel_shot()` (brief revision 1.1). Pause toggles `get_tree().paused` (godot/game/hud.gd:17-21).

### Tests — always through scripts/run-test.sh, from the repository root
`scripts/run-test.sh <test-file.gd> <fps|realtime> [timeout-seconds]` (scripts/run-test.sh:2) runs
`godot --headless [--fixed-fps <fps>] --path godot --script res://tests/<file>` under `timeout`
(default 120 s) (:11), tees to `logs/<name>_<fps>fps.log` (:10), and exits 1 on a non-zero exit or a
`SHADER ERROR` / `SCRIPT ERROR` / `Failed loading resource` line (:12-14). **Realtime mode:**
`realtime` drops `--fixed-fps` and logs to `logs/<name>_realtime.log` (:5-6, :10); still headless (:11).

```bash
godot --headless --path godot --import                    # fresh clone / emptied godot/.godot (README.md:60)
bash scripts/run-test.sh test_rules.gd 60                  # also test_input, test_materials, normal_map_check
bash scripts/run-test.sh test_burning_tint.gd 30           # and 60, 144; test_wall_targeting.gd the same
bash scripts/run-test.sh test_impact_burst_config.gd 60    # also _state, embers _config/_state (README.md:61-71)
bash scripts/run-test.sh <new_test>.gd realtime 180        # realtime mode, 180 s timeout
```
- Shot-timing tests count `Archer.fired` (test_burning_tint.gd:114, test_impact_burst_state.gd:142,
  test_burning_embers_state.gd:184), set `fire_cooldown` (test_wall_targeting.gd:52), or disable the archer
  (test_rules.gd:62, test_input.gd:111-118; freezes like pause, rev. 1.2). Re-pin only what §5.6 allows.

### Headless facts (probed on this machine, Godot 4.7.2; logs in evidence/a7-probes/)
- A headless run advances clips and reads their structure. It draws nothing, so whether the motion
  reads is not observable here (probe_headless.log: display `headless`, viewport image null).
- Key times are 32-bit floats; compare them with a tolerance (a saved `.tres` reads 8/30 as 0.26666668).
- `value_track_get_update_mode` applies only to value tracks (elsewhere: `ERROR:` unseen by run-test.sh, returns 0).
- Frame strips come from a windowed Movie Maker run, which I start (headless `--write-movie` crashes).
- `travel("shoot")` → `archer.gd` reads the 8/30 s key 18 ticks later, `.tres` clip too;
  `playback.start("idle")` acts in the same tick (probe_tick_order_tres.log, prompts/a7/probes/).

## Current change

@CHANGE-BRIEF.md

## Ownership

- Files in `godot/shaders/` are hand-written by Rui and never edited by an agent — not created,
  modified, renamed, reformatted or deleted. If a shader looks wrong, report it and stop.
  `scripts/check-session.sh` checks `godot/shaders/` and `scripts/run-test.sh` are unchanged (:29-33).
- Clips (`walk`, `hold`, `idle`, `shoot`), their AnimationLibrary and the state machine live as
  resources: `.tres` in `godot/animations/` or sub-resources of the owning scene (`scarecrow.tscn`,
  `archer.tscn`). Never built in code at runtime (no `Animation.new()`, `add_track()`,
  `track_insert_key()`, `add_transition()` in game or preview scripts); tests only read them back.

## One authority

Exactly one node writes each animated property. Never add a second writer to one that has one.
- `Scarecrow/Sprite.frame`: `Scarecrow/AnimationPlayer` (`walk`, `hold`). `WalkPresenter` only calls
  `play()`; `burning_tint.gd` writes only the material's `burn_mix` (burning_tint.gd:13).
- `Scarecrow.position`: `scarecrow.gd` (:68), set once at spawn (main.gd:53); the hop is in the pixels.
- Rig parts (rotation / position / scale of `Body`, `BowPivot`, `Bow`, `String`): `Archer/AnimationTree`,
  through the clips `Archer/AnimationPlayer` holds. Nothing calls `play()` on that player; no autoplay.
- `Archer.release_window`: the AnimationTree (keyed in `shoot` and `idle`). `archer.gd` only reads it;
  `cancel_shot()` clears `shot_armed` and the target, never `release_window` (brief §5.4, revision 1.1).
- `Archer.position`: `archer.gd` (:16) and `main.gd` `reset()` (:45), as today. No clip keys the root.
- The state machine's current state: only `archer.gd` (`travel`, `start`); a preview script only in its preview.

## Godot 4 names

Godot 4.7.2 only; never Godot 3 names. No boolean `loop` → `Animation.loop_mode` = `LOOP_NONE` /
`LOOP_LINEAR` / `LOOP_PINGPONG`. No `playback_speed` → `speed_scale`. No `AnimatedSprite` (and none of
`AnimatedSprite2D` here, brief §7). No `playback_process_mode` → `callback_mode_process` =
`ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS` / `_IDLE` / `_MANUAL` (on AnimationMixer, shared by
AnimationPlayer and AnimationTree). Both default to IDLE (1), so the archer's tree must set PHYSICS.
- Animation: `length`, `step` (default 1/30), `loop_mode`, `track_set_path`, `value_track_set_update_mode`
  with `UPDATE_CONTINUOUS` / `UPDATE_DISCRETE` / `UPDATE_CAPTURE`, `track_get_key_time`, `track_get_key_value`.
- Sprite2D: `hframes`, `vframes`, `frame`. AnimationTree: `anim_player`, `tree_root`, `active`,
  `advance_expression_base_node` (default `.`), `deterministic`; playback via `get("parameters/playback")`
  → AnimationNodeStateMachinePlayback `travel()`, `start()`, `get_current_node()`, `get_current_play_position()`.
- AnimationNodeStateMachineTransition: `advance_mode` (`ADVANCE_MODE_DISABLED` / `_ENABLED` / `_AUTO`),
  `switch_mode` (`SWITCH_MODE_IMMEDIATE` / `_SYNC` / `_AT_END`), `xfade_time`. States hold
  `AnimationNodeAnimation` (`animation`, `use_custom_timeline`). One transition per from → to pair (brief §6).
- Scene text: player `libraries/ = SubResource(…)`, library `_data = { &"walk": … }`, clip `loop_mode = 1`,
  keys `"times": PackedFloat32Array(…)`, `"update": 1` (evidence/a7-probes/probe_names.log).

## Out of scope

- Any game rule except brief §5 (release on the active frame, draw from `fire_cooldown` ≤ 0.3 s,
  `shot_armed` guard, cancel/restart behaviour). Not HP, damage, burn, speed, cone, `FIRE_INTERVAL`,
  arrow flight and hit radius, gate damage, spawning, win/loss, pause, the input map, collision.
- Editing `scarecrow.gd`, `scarecrow.png`, `archer.png`, `tuning.gd`, `arrow.gd`, `hud.gd`, `project.godot`,
  `scripts/run-test.sh`, `godot/shaders/`, the A6 effects, any other object, or `main.gd` beyond the one
  `cancel_shot()` call. Changing the walk sheet after it is committed.
- Loosening a test expectation, or re-pinning one beyond what §5 forces, or outside its own step.
- Writing `frame`, rig transforms or `release_window` from a script; method tracks for gameplay;
  an AnimatedSprite2D / SpriteFrames route; an imported 3D rig; GDD systems (README.md:187-194).

## Unconfirmed

- Brief §11 strip frame numbers are "Fill after Step 2 pin"; they depend on the measured latency.
