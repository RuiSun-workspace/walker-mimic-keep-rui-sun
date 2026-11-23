# Mimic Keep (walker-mimic-keep-rui-sun)

Defend Mimi, the treasure-chest mimic, from the castle wall. The archer slides along the wall
and fires on their own; fire arrows set Straw Scarecrows burning before they reach the gate.

This repository is the game for CSYE 7270 from Assignment 5 on. It follows the Assignment 4
game design document (*Mimic Keep GDD v0.1*). It replaces walker-lamplight-rui-sun, the game of
Assignments 2–3: this is the course's one allowed change of game, recorded in FRICTIONAL.md.

## Starting point

A new, empty Godot 4.7.2 project. No starter code was copied: the walker-jumpman platformer code
does not fit a fixed-screen defense game. The test idiom (headless `SceneTree` scripts, real key
events, pinned frame rate) follows the earlier walker projects.

## Engine and renderer

- Godot **4.7.2** stable (`4.7.2.stable.official.ed1daf0bf`)
- Renderer: **Forward+**, Godot's default. The editor leaves `rendering/renderer/rendering_method`
  out of `godot/project.godot` because it equals the default; `config/features` lists "Forward Plus".
- Viewport 1280×720, stretch mode `canvas_items`; 2D textures use nearest filtering

## Run

Open `godot/project.godot` in Godot 4.7.2 and press F5, or:

```bash
godot --path godot
```

The 3D showcase scene (Shield Goblin's wooden shield, used for the material work) is
`res://showcase/shield_room.tscn`; open it and press F6.

The Assignment 7 preview scenes (fixtures, not the game) show one clip at a time:

```bash
godot --path godot res://previews/shoot_preview.tscn   # the archer's shot, one target, repeated
godot --path godot res://previews/walk_preview.tscn    # one walking scarecrow, camera on its origin
# frame strips as captured (windowed Movie Maker, 30 fps):
godot --path godot res://previews/shoot_preview.tscn --write-movie "$PWD/captures/shoot/rN/frame.png" --fixed-fps 30 --quit-after 90
```

## Controls

| Key | Action |
|---|---|
| A / D, Left / Right | move the archer along the wall |
| (none) | the archer fires on their own at the nearest scarecrow in a 120° upward cone |
| Esc / P | pause / resume |
| R / Enter | play again after a win or a loss |

There is no vsync debug key: Assignment 6 priced the effects with the Visual Profiler's GPU time
and made no FPS comparison (TEST-REPORT.md A6.7).

## The prototype's rules

One wave of Straw Scarecrows for 90 s. Every number lives in `godot/game/tuning.gd`, marked as
from the GDD or chosen for this prototype.

- A fire arrow deals 10 damage and sets the scarecrow **Burning**: 4 damage per second for 4 s of
  game time (GDD 6.3). Another fire hit refreshes the burn to a full 4 s; damage does not stack.
  Burning follows `Engine.time_scale` and stops while the game is paused.
- A scarecrow at the wall takes 5 HP per second from the gate. The gate has 100 HP (GDD 6.2).
- Survive 90 s to win; lose when the gate reaches 0.

## Tests

```bash
godot --headless --path godot --import
./scripts/run-test.sh test_rules.gd 60
./scripts/run-test.sh test_input.gd 60
./scripts/run-test.sh test_burning_tint.gd 30    # also 60 and 144
./scripts/run-test.sh test_materials.gd 60
./scripts/run-test.sh normal_map_check.gd 60
./scripts/run-test.sh test_wall_targeting.gd 30   # also 60 and 144
./scripts/run-test.sh test_impact_burst_config.gd 60
./scripts/run-test.sh test_impact_burst_state.gd 60
./scripts/run-test.sh test_burning_embers_config.gd 60
./scripts/run-test.sh test_burning_embers_state.gd 60
./scripts/run-test.sh cost_effects.gd 60 300      # headless CPU price, not a pass/fail test
./scripts/run-test.sh test_pins_a7.gd 60          # Assignment 7: behaviour pins
./scripts/run-test.sh test_scarecrow_sheet.gd 60
./scripts/run-test.sh test_scarecrow_walk_readback.gd 60
./scripts/run-test.sh test_archer_parts.gd 60
./scripts/run-test.sh test_archer_shot_readback.gd 60
./scripts/run-test.sh test_archer_state_machine.gd 60
./scripts/run-test.sh test_archer_edges.gd 60
```

`scripts/run-test.sh` runs one test headless at a pinned frame rate, writes `logs/<test>_<fps>fps.log`
and exits 1 on `SHADER ERROR`, `SCRIPT ERROR` or `Failed loading resource`; run it from the repository root.
`test_rules.gd` (23 checks) covers spawning, targeting, the burn's duration, damage, refresh,
time scale and pause, gate damage, losing and winning. `test_input.gd` (14 checks) drives the
real keys through `Input.parse_input_event`. The suites of Assignments 5–7 and their counts are in
TEST-REPORT.md (Assignment 7: A7.1 and A7.6). Every test prints one PASS/FAIL line per check and exits 1 on any failure.

## Assets

One downloaded texture set: Poly Haven's **Wood Planks** (1K PNG, CC0) in
`godot/assets/textures/wood_planks/`, for the shield material. Its credits, md5s and the role of
each file are in `ATTRIBUTION.md` next to it. The material uses the OpenGL normal map
(`_nor_gl`); `_nor_dx` is kept only to calibrate `godot/tests/normal_map_check.gd`.
Nothing is AI-generated. Everything else is written by code in this repository; the
sprite credits are in `godot/assets/sprites/ATTRIBUTION.md`:

```bash
godot --headless --path godot --script res://tools/make_sprites.gd      # sprites, walk sheet, archer rig parts
godot --headless --path godot --script res://tools/make_shield_mesh.gd  # shield mesh
godot --headless --path godot --script res://tools/make_scorch_mask.gd  # shield scorch mask
godot --path godot --script res://tools/capture_prototype.gd            # evidence frames (not headless)
godot --path godot --script res://tools/capture_burn_values.gd         # burn_mix 0/0.5/0.65/1/2 captures (not headless)
godot --path godot --script res://tools/capture_in_play.gd             # scripted ignite/kill frames (not headless)
godot --path godot --script res://tools/capture_shield_room.gd -- sweep  # interface sweep, 21 frames (not headless)
godot --path godot --script res://tools/capture_shield_room.gd -- shot <name>  # one shield-room frame
powershell -ExecutionPolicy Bypass -File godot/tools/os_screenshot.ps1 -Godot <Godot .exe>  # OS screenshot of the burn frame
godot --headless --path godot --script res://tools/compare_os_screenshot.gd  # in-engine vs OS screenshot
```

## What Assignment 5 added

Two hand-written shaders (every line by Rui) and everything around them (by Claude Code and three
agent sessions, reviewed and checked by Rui). Details: CHANGE-BRIEF.md, MATERIALS.md, TEST-REPORT.md.

- **Burning tint** — `godot/shaders/burning_tint.gdshader` (canvas_item). While a scarecrow is Burning,
  its sprite is mixed toward (255, 192, 32) by `burn_mix`, 0.65 at the hit and 0 after 4 s of game time.
  The driver `godot/game/burning_tint.gd` sets it every frame from `burn_time_left` on each scarecrow's
  own material; `godot/tests/test_burning_tint.gd` checks it at 30, 60 and 144 fps.
- **Wooden shield** — `godot/shaders/shield_wood.gdshader` (spatial): Poly Haven albedo with
  `source_color`, roughness, an OpenGL normal map with `hint_normal`, and a code-generated scorch mask;
  seven uniforms in two groups. Two materials, `godot/showcase/shield_new.tres` and `shield_burned.tres`,
  on two shields in `res://showcase/shield_room.tscn`. Audited by `godot/tests/test_materials.gd`
  and `normal_map_check.gd`.
- **Hint experiment** — `godot/shaders/hint_experiment.gdshader` in `res://showcase/hint_experiment.tscn`:
  one grey strip read with and without `source_color` (64/128/192 vs 137/188/225).
- **The language** — `godot/shaders/standard_generated.gdshader` (an unedited StandardMaterial3D
  conversion) and LANGUAGE-NOTES.md.
- Evidence (in-engine captures, logs, mutations) in `evidence/`; the agent prompts in `prompts/` and their
  transcripts in `sessions/`; the record of who did what in FRICTIONAL.md and SOURCES.md.

## What Assignment 7 added

Two animation clips, specified by Rui in CHANGE-BRIEF.md (revisions 1–4) and built, wired and tested by
agent sessions that Claude Code reviewed. Rui's look-first verdicts and the one tuning change are in
TUNING.md; tests, mutations and Rui's human checks are in TEST-REPORT.md (A7.1–A7.6); who did what is in
FRICTIONAL.md and SOURCES.md.

- **Scarecrow walk — the loop.** Route: Sprite2D with an AnimationPlayer frame track.
  `godot/assets/sprites/scarecrow_walk.png` (4×1 sheet of 64×80 cells, written by
  `godot/tools/make_sprites.gd`) is sliced with `hframes = 4` on `Scarecrow/Sprite`
  (`godot/game/scarecrow.tscn`). The `walk` clip keys `Sprite:frame` 0–3 at 8 fps (discrete, LOOP_LINEAR,
  0.5 s); `hold` keys frame 0 while the scarecrow stands at the wall. `godot/game/scarecrow_walk_presenter.gd` reads `at_wall` and picks
  the clip; it never writes the frame.
- **Archer shot — the committing action.** Route: a keyed cutout rig. `Archer/Rig` with `Body` and
  `BowPivot/Bow`, `BowPivot/String` (`godot/game/archer.tscn`; parts `archer_{body,bow,string}.png`). The
  `idle` and `shoot` clips are keyed at 30 fps on the phase table: startup frames 0–7, active frame 8
  (`release_window` true), recovery 9–14. Full draw −16° after tuning r1.
- **One authority each.** `Archer/AnimationTree` (state machine Start → idle → shoot → idle, callback
  PHYSICS) is the only thing that plays the archer's AnimationPlayer. `Scarecrow/AnimationPlayer` (IDLE) is the
  only writer of the sprite's frame.
- **Gameplay change named by the brief.** The arrow now leaves on the active frame: the archer starts the draw
  0.3 s before the cooldown ends, so the 0.6 s cadence is kept and only the first shot is later. A target that
  leaves the cone during startup cancels the draw with no arrow. Pins re-run and re-pinned (TEST-REPORT A7.2).
- **Tests.** Behaviour pins, the sheet check, two read-backs, the state-machine structure test, the edge tests
  (every phase boundary × every interrupt) and four mutations (TEST-REPORT A7.1–A7.4).
- **Previews** (`godot/previews/shoot_preview.*`, `walk_preview.*`): fixtures used for the frame strips in
  `captures/shoot/` and `captures/walk/`, captured by Rui in windowed Movie Maker.

## What Assignment 6 added

Two GPU particle effects (GPUParticles2D), specified by Rui in CHANGE-BRIEF.md and built, wired and
tested by agent sessions that Claude Code reviewed. Tuning verdicts are Rui's, from the running game
(TUNING.md); tests and prices are in TEST-REPORT.md; who did what is in FRICTIONAL.md and SOURCES.md.

- **Effect A, Arrow Impact Burst** (`godot/effects/impact_burst.tscn`): an additive flash and falling
  straw, one-shot. Every accepted `Scarecrow.hit()` emits the new `hit_taken(position)` signal (the
  brief's one gameplay-script exception); `godot/effects/impact_spawner.gd` instances a new burst under
  the new `World/Effects` node (retrigger rule: overlap, up to three bursts alive). Revision r1 lowered
  the flash's colour-ramp alpha.
- **Effect B, Burning Embers** (`godot/effects/burning_embers.tscn`): additive embers and faint smoke
  with turbulence on every scarecrow. `godot/effects/burning_embers_driver.gd` sets
  `amount_ratio = clamp(burn_time_left / 4, 0, 1)` every frame (a feedback loop; `amount` never
  changes) and moves a dying scarecrow's emitters to `World/Effects` for their 1.2 s tail. Revision r1
  made new embers fade in so they separate from the hit flash.
- **Previews** (`godot/previews/`): fixture scenes over the real background with a fixed seed and the
  burning tint, used for the frame strips in `captures/`.
- **Process shader**: `godot/shaders/particles_generated.gdshader`, generated by Rui from Effect A's
  material (unused by the game); line references in TEST-REPORT.md A6.7.
- **Tests**: two configuration tests, two state tests driven by real arrows and keys, and a headless
  cost script. Particle textures are generated by `godot/tools/make_particle_textures.gd`
  (`godot/effects/textures/ATTRIBUTION.md`).
- The wall-targeting fix from `gameplay-fixes` was merged before the A6 baseline (`48886bb`).

## Film

**Assignment 7:** *Mimic Keep: A Clip Is a List of Keys.* — Brutalist godot-gamedev explainer (walker), 4K, 5:27.

- File: `claude-liam-walker-mimic-keep-a7-gamedev.mp4`
- SHA-256: `dae506e8e44ebf96a470f4fb343937968c22612b58bad28278d9601a3471454b`
- **[▶ Watch the film](https://northeastern-my.sharepoint.com/:v:/g/personal/sun_r3_northeastern_edu/IQCRlKXVZwhAT4P2wRN0P9_HAXr9IitGGxW46S-2RUpmeU8?nav=eyJyZWZlcnJhbEluZm8iOnsicmVmZXJyYWxBcHAiOiJPbmVEcml2ZUZvckJ1c2luZXNzIiwicmVmZXJyYWxBcHBQbGF0Zm9ybSI6IldlYiIsInJlZmVycmFsTW9kZSI6InZpZXciLCJyZWZlcnJhbFZpZXciOiJNeUZpbGVzTGlua0NvcHkifX0&e=x0H2f1)** — Northeastern OneDrive (the MP4 is not in this repository)
- Game source shown: commit `62d7f72`. Beat sheet, script, capture driver and evidence ledger:
  `youtube/claude-liam-walker-mimic-keep-a7-gamedev/`.

**Assignment 6:** *Mimic Keep: The Strip Cannot See the Hit.* — Brutalist godot-gamedev explainer (walker), 4K, 4:45.

- File: `claude-liam-walker-mimic-keep-a6-gamedev.mp4`
- SHA-256: `388222786f85f8aa6113a4cd187f5b441b3d755cbfce02315720b5bc1262c81f`
- **[▶ Watch the film](https://northeastern-my.sharepoint.com/:v:/g/personal/sun_r3_northeastern_edu/IQAJ0UjoQFYBSJ3DWpWLl6KNAVwJJhedRseP5MhIfsFeqXw?nav=eyJyZWZlcnJhbEluZm8iOnsicmVmZXJyYWxBcHAiOiJPbmVEcml2ZUZvckJ1c2luZXNzIiwicmVmZXJyYWxBcHBQbGF0Zm9ybSI6IldlYiIsInJlZmVycmFsTW9kZSI6InZpZXciLCJyZWZlcnJhbFZpZXciOiJNeUZpbGVzTGlua0NvcHkifX0&e=hiUXoZ)** — Northeastern OneDrive (the MP4 is not in this repository)
- Game source shown: commit `3b99ea6`. Beat sheet, script, capture driver and evidence ledger:
  `youtube/claude-liam-walker-mimic-keep-a6-gamedev/`.

**Assignment 5:** *Mimic Keep: The Test Cannot See the Fire* — Brutalist godot-gamedev explainer (walker), 4K, 6:13.

- File: `claude-liam-walker-mimic-keep-a5-gamedev.mp4`
- SHA-256: `10a99c22d53e31b330393846d9a1ecddd5d1f360e6f78dcf417baa45601d0ec3`
- **[▶ Watch the film](https://northeastern-my.sharepoint.com/:v:/g/personal/sun_r3_northeastern_edu/IQDZY7AdKwcTRaacSlGB4bqyAfG3lmOAaQuQDUvm744kg4A?e=hkY4ve)**
  — Northeastern OneDrive, viewable by anyone signed in with a Northeastern account (the MP4 is not
  in this repository)
- Game source shown: commit `879324b`. Beat sheet, script, captures' driver and evidence ledger:
  `youtube/claude-liam-walker-mimic-keep-a5-gamedev/`.

## Known limitations

Assignment 7:

- A startup cancel (the target leaving the cone mid-draw) has not been seen by a human, in play or in a
  fixture: in 0.3 s the archer can walk only a target near the wall out of the cone, and the cancel comes
  before the bow's lean is visible. It is established by `test_archer_edges.gd` and the probes in
  `evidence/a7-probes/` (TEST-REPORT A7.6).
- The three phases are clearly distinct in play (Rui), but only partly in the r1 preview: a 0.5 s clip in a
  0.6 s cadence leaves little rest between shots (TUNING.md).
- The rotated walk cells (1 and 3) have jagged eyes from nearest-neighbour rotation; accepted by Rui.
- Arrows fly straight at where the target was at release and do not lead, so a far target near the cone's
  edge can be missed. This predates A7.
- The active frame (1/30 s) cannot be paused on by hand; it is covered by the edge tests.
- One playtester (Rui). The film's interrupt take uses scripted key events, labelled as such.

Assignment 6:

- The smoke layer of Effect B is barely visible (Rui's playtest); the embers carry the Burning state.
- Additive particles over the burning-tinted scarecrow clip to full yellow, so both tuning rounds
  changed the fixture strips less than predicted (TUNING.md).
- A hidden GPU emitter pauses its simulation in Godot 4.7.2, unlike the brief's prediction (B6).
- The effects' GPU time was below the Visual Profiler's displayed precision; no per-effect
  isolation at the exact peak, and no FPS comparison.
- The chapter's Example 09 cost script was not available; `cost_effects.gd` is the agent's own.

Assignment 5 (kept for the record; the wall fix has since been merged):

- Two gameplay faults found in Rui's playtest are still in this revision, because Assignment 5 may
  not change game rules: long sideways shots aim at where a scarecrow was and can miss, and a
  scarecrow attacking the wall stands level with the archer, outside the fire cone, so it cannot be
  shot. The wall fix is on branch `gameplay-fixes` (commit `dbb4806`), to be merged after `a5`.
- The tint was checked by Rui in play and in captures; nobody else has playtested it.
- One enemy type and one wave. No gold, XP, level-ups, Mimi's moods or shop, other elements, or
  bosses from the GDD.
- Placeholder art: flat code-drawn sprites, not final art.
- Balance: the spawn rate was eased after Rui's first playtest (see FRICTIONAL.md);
  `godot --headless --path godot --script res://tools/balance_sim.gd --fixed-fps 60 -- 3.0 1.5`
  compares tunings with two stand-in players.
- Level-ups, upgrade cards and other GDD systems are planned for after Assignment 5, so that
  Assignment 5 changes only presentation, not game rules.
