# CLAUDE.md — Mimic Keep

## Project context

- **Engine:** Godot 4.7.2 stable, `4.7.2.stable.official.ed1daf0bf` (README.md:18).
  `godot/project.godot:11` lists only the feature tag `"4.7"`.
- **Renderer:** Forward+, `renderer/rendering_method="forward_plus"` (godot/project.godot:48).
  2D default texture filter is nearest (godot/project.godot:49). No HDR 2D key is set, so it is
  at the engine default (godot/project.godot:46-49).
- **Viewport:** 1280×720, stretch mode `canvas_items` (godot/project.godot:15-17).
- **Main scene:** `res://game/main.tscn` (godot/project.godot:10). Root `Main` (Node2D,
  script `game/main.gd`); scarecrows are added under `World/Enemies` (godot/game/main.tscn:9-21).
  The scene has no Light2D or CanvasModulate node (godot/game/main.tscn:1-63).

### The shaded object: the Straw Scarecrow sprite
- Scene `godot/game/scarecrow.tscn`: root `Scarecrow` (Node2D, script `res://game/scarecrow.gd`)
  with one child `Sprite` of type **Sprite2D**, texture `res://assets/sprites/scarecrow.png`
  (godot/game/scarecrow.tscn:6-10). The Sprite2D has **no material** today.
- No script draws it: `scarecrow.gd` has no `_draw()`; the engine draws the Sprite2D
  (godot/game/scarecrow.gd:1-71).
- Instances are created by `Game.spawn_scarecrow()`, which instantiates `SCARECROW_SCENE` and
  adds it to `enemies` (godot/game/main.gd:10, 51-57). Every instance shares the one scene file,
  so a material set in `scarecrow.tscn` is shared unless made local or duplicated
  (CHANGE-BRIEF.md Rule 6).
- The sprite PNG is written by `godot/tools/make_sprites.gd` (README.md:71).

### Game state that drives the effect
- Owner: `godot/game/scarecrow.gd` (class `Scarecrow`, godot/game/scarecrow.gd:1-6).
  - `var burn_time_left: float = 0.0` (line 14); `is_burning()` returns `burn_time_left > 0.0`
    (lines 23-24).
  - `signal burning_started` / `signal burning_ended` (lines 8-9). `ignite()` sets
    `burn_time_left = Tuning.BURN_DURATION` and emits `burning_started` only if it was not
    already burning (lines 40-44).
  - Counted down in `_physics_process(delta)`, clamped to 0.0, then `burning_ended` (lines 47-57),
    so it follows `Engine.time_scale` and stops when paused.
  - On death: `died` is emitted and the node is `queue_free()`d (lines 67-71).
- Constants: `BURN_DURATION := 4.0`, `BURN_DPS := 4.0` (godot/game/tuning.gd:22-23).

### 3D object for the textured shader
- Scene `godot/showcase/shield_room.tscn`. Nodes `ShieldA` (lines 57-60) and `ShieldB`
  (lines 67-70), both MeshInstance3D with `mesh = res://showcase/shield_mesh.tres` (line 3).
- Material today comes from `surface_material_override/0` on each node, pointing at embedded
  StandardMaterial3D sub-resources `PlaceholderA` (lines 20-23) and `PlaceholderB` (lines 25-28).
  The mesh resource itself declares no material (godot/showcase/shield_mesh.tres:1-14).
- Mesh source: `godot/tools/make_shield_mesh.gd` writes `res://showcase/shield_mesh.tres`
  (line 7, 44); front face has planar UVs over 0..1 (line 3) and tangents are generated (line 41).
- Lighting: one DirectionalLight3D `Sun`, `light_energy = 1.2`, `shadow_enabled = true`
  (lines 43-46); Environment `ambient_light_energy = 0.3`, `tonemap_mode = 0` (Linear) (lines 5-11);
  Camera3D at (0, 0.65, 2.3), fov 45 (lines 48-51).

### Tests — always through scripts/run-test.sh
`scripts/run-test.sh <test-file.gd> <fps>` runs
`timeout 120 godot --headless --path godot --script res://tests/<file> --fixed-fps <fps>`, tees
to `logs/<name>_<fps>fps.log`, and exits 1 if the log contains `SHADER ERROR` or `SCRIPT ERROR`
(scripts/run-test.sh:1-9). It uses relative paths, so run it from the repository root.

```bash
bash scripts/run-test.sh test_rules.gd 60
bash scripts/run-test.sh test_input.gd 60
# the brief requires 30 and 144 fps as well (CHANGE-BRIEF.md Rule 2):
bash scripts/run-test.sh test_rules.gd 30
bash scripts/run-test.sh test_rules.gd 144
bash scripts/run-test.sh test_input.gd 30
bash scripts/run-test.sh test_input.gd 144
```

- `godot/tests/test_rules.gd`: game-rule checks through the real main scene; one PASS/FAIL line
  per check, exits 1 on failure (lines 1-4, 34-35).
- `godot/tests/test_input.gd`: real key events via `Input.parse_input_event` (lines 1-4, 46-52).
- Baseline: test_rules 23/0, test_input 14/0 at 60 fps (README.md:61-64; commit 29ebc5b).

## Current change

@CHANGE-BRIEF.md

## Ownership

Files in `godot/shaders/` are hand-written by the human (Rui) and are never edited by an agent —
not created, modified, renamed, reformatted or deleted. If a shader looks wrong, report it and stop.
`scripts/check-session.sh` verifies after each session that `godot/shaders/` and
`scripts/run-test.sh` are unchanged (scripts/check-session.sh:29-33).

## Out of scope

- Anything that alters gameplay: HP, burn duration or damage, the burn timer, movement,
  targeting, firing, arrows and hit detection, collision, gate damage, spawning, win/loss,
  pause/restart, input actions. Presentation code may only *read* `burn_time_left`,
  `is_burning()` and the two signals; nothing may write back into game state.
- Editing `godot/game/tuning.gd`, `main.gd`, `archer.gd`, `arrow.gd`, `godot/tests/test_rules.gd`,
  `godot/tests/test_input.gd`, or `scripts/run-test.sh`. Changing or loosening any existing
  test expectation.
- Using `TIME` or a frame count to decide how long the tint lasts.
- Using an `instance uniform` for `burn_mix`, or sharing one ShaderMaterial between scarecrows.
- Tinting any object other than the scarecrow sprite (archer, arrows, Mimi, background, HUD).
- Changing the shield room's light, environment, camera or mesh during the A/B material comparison.
- GDD systems not in this change (gold, XP, level-ups, shop, other elements, bosses) (README.md:80-87).

## Unconfirmed

- No `AGENTS.md` exists, so this file has no `@AGENTS.md` line.
- `godot/shaders/` does not exist yet; `burning_tint.gdshader` and the spatial shield shader are
  not written. The scarecrow Sprite2D and both shields have no ShaderMaterial yet.
- The presentation driver's file and node location are not named in the brief.
- Not in the repo yet: the Poly Haven wood textures and their credits file, the scorch-mask
  generator in `godot/tools/`, and `godot/tests/normal_map_check.gd` (CHANGE-BRIEF.md §8).
- The exact Godot patch version comes only from README.md; project.godot says just `"4.7"`.
- I did not run the tests. That `godot` and `timeout` are on PATH in this Windows/Git Bash
  setup, and that the 23/14 results still hold, are not checked here.
- `run-test.sh` does not run `godot --headless --path godot --import` (README.md:56); whether a
  fresh checkout needs that first was not checked.
- HDR 2D is assumed off only because project.godot has no key for it; the claim that
  `source_color` is not linearised for canvas_item with HDR 2D off is the brief's own unverified
  reading (CHANGE-BRIEF.md §6).
- The shield's UVs cover 0..1 on the front face only; the back and rim use other mappings
  (make_shield_mesh.gd:25, 38-40). That the stored tangents are valid was not checked at runtime.
- `test_rules.gd` hard-codes `TICK := 1.0 / 60.0` (line 7); how that behaves at 30/144 fps
  depends on `--fixed-fps` semantics, which I did not verify (README.md:64 says they passed).
