# CLAUDE.md — Mimic Keep

## Project context

- **Engine:** Godot 4.7.2 stable, `4.7.2.stable.official.ed1daf0bf` (README.md:18); `config/features`
  `"4.7"`, `"Forward Plus"` (godot/project.godot:16). **Renderer:** Forward+, the default, so
  `rendering_method` is absent (README.md:19-20). 1280×720 (godot/project.godot:20-22); main scene
  `res://game/main.tscn` (:15); physics 60/s, no `physics_ticks_per_second` key (whole file).

### Clip 1 — scarecrow walk (cycle): Sprite2D + AnimationPlayer frame track (CHANGE-BRIEF.md §1-3)
- Node: `Scarecrow/Sprite`, a Sprite2D whose texture today is the single-cell `scarecrow.png`, with a
  local-to-scene ShaderMaterial and the `burning_tint.gd` script (godot/game/scarecrow.tscn:11-21).
- New sheet `godot/assets/sprites/scarecrow_walk.png`, 4×1 cells of 64×80, from
  `godot/tools/make_sprites.gd` (brief §2; today's 56×72 scarecrow is make_sprites.gd:42-43).
- Clips `walk` (4 keys, step 0.125, 0.5 s, LOOP_LINEAR, discrete) and `hold` (frame 0); chosen by a
  new presentation child of `Scarecrow` from `at_wall` (godot/game/scarecrow.gd:18, set at :23, :69).
- Scene: `godot/game/scarecrow.tscn`, instanced into `World/Enemies` by `Game.spawn_scarecrow()`
  (godot/game/main.gd:51-57). A dead scarecrow is `queue_free()`d at once (scarecrow.gd:72-76).

### Clip 2 — archer shot (committing): 2D cutout rig keyed as resource text (CHANGE-BRIEF.md §1, §4, §6)
- Node today: root `Archer` (Node2D, `archer.gd`) + one `Sprite` Sprite2D with `archer.png`
  (godot/game/archer.tscn:6-10). The rig (body, bow pivoting at the grip, string), an
  `AnimationPlayer` and an `AnimationTree` (AnimationNodeStateMachine: `idle`, `shoot`) are added
  under `Archer` (brief §1, §6). Scene `archer.tscn`, instanced as `World/Archer` (main.tscn:25-26).
- **Owner of the player's state machine:** `godot/game/archer.gd`. Today it has no states: it moves
  and fires in one `_physics_process` (archer.gd:14-24) and fires when `fire_cooldown` hits 0
  (:18-24). The brief makes it push the tree with `travel("shoot")` / `playback.start("idle")`,
  own `shot_armed` and the locked target, and read `release_window` (brief §5-6).
- Run state (PLAYING/WON/LOST) is `main.gd` (godot/game/main.gd:8): game end disables `World`
  (:94-96), restart only after the end (:81-83), `reset()` (:36-48). Pause toggles
  `get_tree().paused` in `godot/game/hud.gd:17-21`.

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
- Tests that depend on the shot's timing: they count `Archer.fired` (test_burning_tint.gd:114,
  test_impact_burst_state.gd:142, test_burning_embers_state.gd:184), set `fire_cooldown`
  (test_wall_targeting.gd:52), or disable the archer (test_rules.gd:62, test_input.gd:111-118).
  Re-pin only what brief §5.6 allows. Headless shows node state, not the look; strips are Rui's runs.

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
- `Scarecrow/Sprite.frame`: the scarecrow's own AnimationPlayer (`walk`, `hold`). The new presentation
  child only calls `play()`; `burning_tint.gd` writes only the material's `burn_mix` (burning_tint.gd:13).
- `Scarecrow.position`: `scarecrow.gd` (:68). No clip keys it; the hop is drawn in the sheet's pixels.
- Archer rig parts (rotation / position of body, bow, string): the archer's AnimationTree, through
  the clips its AnimationPlayer holds. Nothing calls `play()` on that player; `autoplay` stays empty.
- `Archer.release_window`: the AnimationTree (keyed in `shoot` and `idle`). `archer.gd` only reads it.
- `Archer.position`: `archer.gd` (:16) and `main.gd` `reset()` (:45), as today. No clip keys the root.
- The state machine's current state: only `archer.gd` (`travel`, `start`); a preview script only in its preview.

## Godot 4 names

Godot 4.7.2 only; never Godot 3 names. No boolean `loop` → `Animation.loop_mode` = `LOOP_NONE` /
`LOOP_LINEAR` / `LOOP_PINGPONG`. No `playback_speed` → `speed_scale`. No `AnimatedSprite` (and none of
`AnimatedSprite2D` here, brief §7). No `playback_process_mode` → `callback_mode_process` =
`ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS` / `_IDLE` / `_MANUAL` (on AnimationMixer, shared by
AnimationPlayer and AnimationTree). Animations live in an `AnimationLibrary` on the player.
- Animation: `length`, `step`, `loop_mode`, `track_set_path`, `value_track_set_update_mode` with
  `UPDATE_CONTINUOUS` / `UPDATE_DISCRETE` / `UPDATE_CAPTURE`, `track_get_key_time`, `track_get_key_value`.
- Sprite2D: `hframes`, `vframes`, `frame`. AnimationTree: `anim_player`, `tree_root`, `active`,
  `advance_expression_base_node`; playback via `get("parameters/playback")` →
  AnimationNodeStateMachinePlayback `travel()`, `start()`, `get_current_node()`.
- AnimationNodeStateMachineTransition: `advance_mode` (`ADVANCE_MODE_DISABLED` / `_ENABLED` / `_AUTO`),
  `switch_mode` (`SWITCH_MODE_IMMEDIATE` / `_SYNC` / `_AT_END`), `xfade_time`. States hold
  `AnimationNodeAnimation` (`animation`). One transition per from → to pair (brief §6, probed).
- Not verified on 4.7.2 by me: `get_current_play_position()`, AnimationTree `deterministic`,
  AnimationNodeAnimation `use_custom_timeline`, and the exact `.tscn` text keys for an
  AnimationLibrary sub-resource. Check by setting and reading back, or report; don't guess.

## Out of scope

- Any game rule except brief §5 (release on the active frame, draw from `fire_cooldown` ≤ 0.3 s,
  `shot_armed` guard, cancel/restart behaviour). Not HP, damage, burn, speed, cone, `FIRE_INTERVAL`,
  arrow flight and hit radius, gate damage, spawning, win/loss, pause, the input map, collision.
- Editing `scarecrow.gd`, `scarecrow.png`, `tuning.gd`, `arrow.gd`, `hud.gd`, `project.godot`,
  `scripts/run-test.sh`, anything in `godot/shaders/`, the A6 effects and their scenes/drivers, or
  any other object. Changing the walk sheet after it is committed.
- Loosening a test expectation, or re-pinning one beyond what §5 forces, or outside its own step.
- Writing `frame`, rig transforms or `release_window` from a script; method tracks for gameplay;
  an AnimatedSprite2D / SpriteFrames route; an imported 3D rig; GDD systems (README.md:187-194).

## Unconfirmed

- No `AGENTS.md` exists, so there is no `@AGENTS.md` line. `godot/animations/` does not exist yet.
- How `archer.gd` learns of a restart to clear `shot_armed` and call `start("idle")`: the only
  restart path is `main.gd` `reset()` (:36-48), and the brief does not say main.gd may change.
- Node names for the scarecrow's AnimationPlayer and presentation child, the rig parts, and whether
  the archer's `Sprite` / `archer.png` is replaced or kept: not in the brief.
- Whether disabling the archer (test_rules.gd:62, test_input.gd:111) leaves its AnimationTree
  in the state the brief expects when it is re-enabled; the brief does not cover this case.
- Brief §11 strip frames are still "Fill after Step 2 pin". The tick-order facts (18 ticks,
  parent before child) come from `prompts/a7/probes/`; I did not re-run them.
