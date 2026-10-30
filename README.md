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

## Controls

| Key | Action |
|---|---|
| A / D, Left / Right | move the archer along the wall |
| (none) | the archer fires on their own at the nearest scarecrow in a 120° upward cone |
| Esc / P | pause / resume |
| R / Enter | play again after a win or a loss |

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
```

`scripts/run-test.sh` runs one test headless at a pinned frame rate, writes `logs/<test>_<fps>fps.log`
and exits 1 on `SHADER ERROR` or `SCRIPT ERROR`; run it from the repository root.
`test_rules.gd` (23 checks) covers spawning, targeting, the burn's duration, damage, refresh,
time scale and pause, gate damage, losing and winning. `test_input.gd` (14 checks) drives the
real keys through `Input.parse_input_event`. The Assignment 5 suites and their counts are in
TEST-REPORT.md. Every test prints one PASS/FAIL line per check and exits 1 on any failure.

## Assets

One downloaded texture set: Poly Haven's **Wood Planks** (1K PNG, CC0) in
`godot/assets/textures/wood_planks/`, for the shield material. Its credits, md5s and the role of
each file are in `ATTRIBUTION.md` next to it. The material uses the OpenGL normal map
(`_nor_gl`); `_nor_dx` is kept only to calibrate `godot/tests/normal_map_check.gd`.
Nothing is AI-generated. Everything else is written by code in this repository:

```bash
godot --headless --path godot --script res://tools/make_sprites.gd      # 4 sprites
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

## Film

*Mimic Keep: The Test Cannot See the Fire* — Brutalist godot-gamedev explainer (walker), 4K, 6:13.

- File: `claude-liam-walker-mimic-keep-a5-gamedev.mp4`
- SHA-256: `10a99c22d53e31b330393846d9a1ecddd5d1f360e6f78dcf417baa45601d0ec3`
- **[▶ Watch the film](https://northeastern-my.sharepoint.com/:v:/g/personal/sun_r3_northeastern_edu/IQDZY7AdKwcTRaacSlGB4bqyAfG3lmOAaQuQDUvm744kg4A?e=hkY4ve)**
  — Northeastern OneDrive, viewable by anyone signed in with a Northeastern account (the MP4 is not
  in this repository)
- Game source shown: commit `879324b`. Beat sheet, script, captures' driver and evidence ledger:
  `youtube/claude-liam-walker-mimic-keep-a5-gamedev/`.

## Known limitations

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
