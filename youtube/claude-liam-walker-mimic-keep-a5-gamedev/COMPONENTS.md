# COMPONENTS — what the film explains, and where

All paths are relative to `godot/` at `879324b`. Every authored file is assigned to one component in
`gamedev-evidence.json` (no exclusions).

| Component | Files | Beats | Explained as |
|---|---|---|---|
| game | `project.godot`, `game/*` except `burning_tint.gd` and `scarecrow.tscn`, sprites, `tests/test_rules.gd`, `tests/test_input.gd`, prototype tools | B02, B08 | The prototype the effect lives in: auto-firing archer, fire arrows, Burning owned by `scarecrow.gd` (4 s, 4 dps). Shown running, not taken apart: it predates A5 and A5 forbids changing it. |
| burning-tint | `shaders/burning_tint.gdshader`, `game/burning_tint.gd`, `game/scarecrow.tscn`, `tests/test_burning_tint.gd`, capture tools | B03-B11 | Rui's colour line; the driver from `burn_time_left` to `burn_mix` on each scarecrow's own material; measured pixels; moving result; the test and its mutations; the headless limit. |
| hint-experiment | `shaders/hint_experiment.gdshader`, `showcase/hint_*`, `hint_greys_3x1.png`, `tools/make_hint_greys.gd` | B12, B13 | Why a texture is information: the same pixels read as colour and as data. |
| shield-material | `shaders/shield_wood.gdshader`, `showcase/shield_*`, wood textures + `.import`, scorch mask, mesh, `tests/test_materials.gd`, `tests/normal_map_check.gd`, `MATERIALS.md` | B14-B19, B21 | Colour vs data samplers, the normal map's convention, the interface and its sweep, a material as one set of inputs to one shader. |
| generated-shader | `shaders/standard_generated.gdshader` | B20, B21 | Two annotated lines beside Rui's equivalents, and what the language adds to GLSL. |

The four questions of the assignment: what a shader does (B04, line 7); how a material differs from a shader
(B18, `shield_burned.tres:12`); why a texture is information (B12-B14, `hint_experiment.gdshader:5,8`,
`shield_wood.gdshader:7,13`); what the Godot shading language is (B04 line 1, B16 line 21, B20).
