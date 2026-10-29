# MATERIALS — Mimic Keep

Audit of the materials named in CHANGE-BRIEF.md §7-8, 2026-10-28, Godot 4.7.2, Forward+.
Everything in the tables is pinned by `godot/tests/test_materials.gd`
(`./scripts/run-test.sh test_materials.gd 60`). No shader, material, scene or `.import` file was
changed by this audit.

Not covered here: the scarecrow's `burning_tint.gdshader` ShaderMaterial
(`godot/game/scarecrow.tscn:8-16`). It binds no texture and has its own test,
`godot/tests/test_burning_tint.gd`.

## Materials

| Material | Used by | Shader | Uniform values it sets | Textures it binds |
|---|---|---|---|---|
| `res://showcase/shield_new.tres` | `ShieldA`, `shield_room.tscn:49-52` | `res://shaders/shield_wood.gdshader` | `wood_tint` = (1, 1, 1, 1), `texture_scale` = 1.0, `roughness_scale` = 0.75, `normal_strength` = 0.8, `scorch_amount` = 0.05, `char_roughness` = 0.95. `scorch_color` not set: shader default (0.08, 0.025, 0.01, 1) | `wood_albedo_texture` = `wood_planks_diff_1k.png`, `wood_roughness_texture` = `wood_planks_rough_1k.png`, `wood_normal_texture` = `wood_planks_nor_gl_1k.png`, `scorch_mask_texture` = `shield_scorch_mask.png` |
| `res://showcase/shield_burned.tres` | `ShieldB`, `shield_room.tscn:59-62` | `res://shaders/shield_wood.gdshader` | `wood_tint` = (0.72, 0.5, 0.34, 1), `texture_scale` = 1.0, `roughness_scale` = 0.95, `normal_strength` = 1.15, `scorch_amount` = 0.7, `char_roughness` = 0.98. `scorch_color` not set: shader default | same four as `shield_new.tres` |
| `res://showcase/hint_source_color.tres` | `QuadSourceColor`, `hint_experiment.tscn:28-31` | `res://shaders/hint_experiment.gdshader` | `use_source_color` = true | `source_color_texture` = `hint_greys_3x1.png`, `raw_texture` = `hint_greys_3x1.png` |
| `res://showcase/hint_raw.tres` | `QuadRaw`, `hint_experiment.tscn:38-41` | `res://shaders/hint_experiment.gdshader` | `use_source_color` = false | `source_color_texture` = `hint_greys_3x1.png`, `raw_texture` = `hint_greys_3x1.png` |

Wood textures are under `res://assets/textures/wood_planks/`; the scorch mask and grey strip are
under `res://assets/textures/`. Each material is a separate resource; the two shield materials
share one Shader object.

### Non-sampler uniforms, as declared

| Shader | Uniform | Type | Group | Hint as written | Default as written | Engine reports |
|---|---|---|---|---|---|---|
| shield_wood | `wood_tint` | vec4 | Surface | `source_color` | `vec4(1.0, 1.0, 1.0, 1.0)` | Color |
| shield_wood | `texture_scale` | float | Surface | `hint_range(0.25, 4.0, 0.05)` | `1.0` | float, range 0.25,4.0,0.05 |
| shield_wood | `roughness_scale` | float | Surface | `hint_range(0.0, 1.0, 0.01)` | `0.85` | float, range 0,1,0.01 |
| shield_wood | `normal_strength` | float | Surface | `hint_range(0.0, 1.0, 0.01)` | `1.0` | float, range 0,1,0.01 |
| shield_wood | `scorch_amount` | float | Damage | `hint_range(0.0, 1.0, 0.01)` | `0.0` | float, range 0,1,0.01 |
| shield_wood | `scorch_color` | vec4 | Damage | `source_color` | `vec4(0.08, 0.025, 0.01, 1.0)` | Color |
| shield_wood | `char_roughness` | float | Damage | `hint_range(0.0, 1.0, 0.01)` | `0.95` | float, range 0,1,0.01 |
| hint_experiment | `use_source_color` | bool | — | — | `true` | bool |

`get_shader_uniform_list()` reports no defaults headlessly and does not show `source_color`, so
defaults and colour hints are read from the source text.

## Samplers

| Shader | Sampler | Hints as written | Bound by `shield_new` / `hint_source_color` | Bound by `shield_burned` / `hint_raw` | compress/mode | compress/normal_map | mipmaps/generate |
|---|---|---|---|---|---|---|---|
| shield_wood (`:6-7`) | `wood_albedo_texture` | `source_color, filter_linear_mipmap, repeat_enable` | `wood_planks_diff_1k.png` | `wood_planks_diff_1k.png` | 2 VRAM Compressed | 2 Disabled | true |
| shield_wood (`:9-10`) | `wood_roughness_texture` | `filter_linear_mipmap, repeat_enable` | `wood_planks_rough_1k.png` | `wood_planks_rough_1k.png` | 2 VRAM Compressed | 2 Disabled | true |
| shield_wood (`:12-13`) | `wood_normal_texture` | `hint_normal, filter_linear_mipmap, repeat_enable` | `wood_planks_nor_gl_1k.png` | `wood_planks_nor_gl_1k.png` | 2 VRAM Compressed | 1 Enabled | true |
| shield_wood (`:15-16`) | `scorch_mask_texture` | `filter_linear_mipmap, repeat_disable` | `shield_scorch_mask.png` | `shield_scorch_mask.png` | 0 Lossless | 2 Disabled | true |
| hint_experiment (`:4-5`) | `source_color_texture` | `source_color, filter_nearest, repeat_disable` | `hint_greys_3x1.png` (sampled) | `hint_greys_3x1.png` (bound, not sampled) | 0 Lossless | 2 Disabled | false |
| hint_experiment (`:7-8`) | `raw_texture` | `filter_nearest, repeat_disable` | `hint_greys_3x1.png` (bound, not sampled) | `hint_greys_3x1.png` (sampled) | 0 Lossless | 2 Disabled | false |
| — (no shader samples it) | — | — | `wood_planks_nor_dx_1k.png`: calibration only | — | 2 VRAM Compressed | 1 Enabled | true |

Import values are from the `[params]` section of each `<texture>.png.import`, read with
ConfigFile. They match the CHANGE-BRIEF §8 Texture Plan row for row.

Normal maps, `curl_ratio()` (stride 4) on the decoded source PNGs:

| Map | directx = false | directx = true |
|---|---|---|
| `wood_planks_nor_gl_1k.png` | 0.6957 | 1.3043 |
| `wood_planks_nor_dx_1k.png` | 1.3043 | 0.6957 |

These are the uncompressed values CHANGE-BRIEF revision C quotes. The imported RGTC maps give
0.6703 / 1.3297 and 1.3286 / 0.6714 (`logs/normal_map_check_60fps.log`). The bound map, nor_gl,
scores lower read as OpenGL, which is what Godot expects.

## Lights and environment

| Setting | `shield_room.tscn` | `hint_experiment.tscn` |
|---|---|---|
| Lights | one DirectionalLight3D `Sun`: energy 1.2, colour white, `shadow_enabled = true`, shining along (−0.433, −0.5, −0.75) (`:35-38`) | none; both quads are `render_mode unshaded` (`hint_experiment.gdshader:2`) |
| Background | colour (0.32, 0.36, 0.42) (`:8-9`) | colour black (`:7-8`) |
| Ambient light | source Color, white, energy 0.3 (`:10-12`) | not set (does not affect unshaded quads) |
| Tonemap | Linear (`tonemap_mode = 0`, `:13`) | Linear (`:9`) |
| Exposure | 1.0, the default: no `tonemap_exposure` key, Camera3D has no CameraAttributes | 1.0, written explicitly (`:10`) |
| Tonemap white | 1.0 (default) | 1.0 (default) |
| Glow, fog, volumetric fog, adjustments, SSAO, SSIL, SSR, SDFGI | all off (defaults) | all off; glow, fog and adjustments written explicitly (`:11-13`) |
| Camera | (0, 0.65, 2.3), fov 45, perspective (`:40-43`) | (0, 0, 2), fov 45 (`:23-26`) |
| Other objects in frame | Floor, StandardMaterial3D albedo (0.42, 0.40, 0.37), roughness 0.9; two plinths, albedo (0.25, 0.25, 0.27) (`:15-28`) | two Label3D captions |

Project: Forward+ (`rendering/renderer/rendering_method` reads `forward_plus`).

## Findings

1. **`normal_strength` range disagrees with the brief, and ShieldB's value lies outside it.**
   `shield_wood.gdshader:32-33` declares `hint_range(0.0, 1.0, 0.01)`. CHANGE-BRIEF §8, Shader
   Uniform Groups, gives the range as 0–2 ("2 exaggerates the grain"). `shield_burned.tres:20`
   sets `normal_strength = 1.15`, as the brief's ShieldB values require. That is above the hint's
   maximum, so the Inspector slider cannot show or produce it. Brief short answer 7 predicts that
   `hint_range` does not clamp a value set from outside, so 1.15 would still reach the GPU; that is
   unverified. FRICTIONAL.md:278-279 says that after Rui's edit "7 uniforms whose types and hint
   ranges match the table"; for `normal_strength` they do not. The shader is Rui's, so this is
   reported, not changed. The test pins the current 0–1 range, so fixing it will fail that one check
   until the table is updated.
2. **CLAUDE.md is out of date about the materials.** It says the scarecrow Sprite2D "has no
   material today", but `scarecrow.tscn:8-16` gives it a local ShaderMaterial. It places the shield
   materials in embedded `PlaceholderA`/`PlaceholderB` sub-resources (lines 20-28) and `ShieldA` at
   lines 57-60. Those placeholders are gone: `ShieldA` is at `shield_room.tscn:49-52` and uses
   `shield_new.tres`. Under "Unconfirmed" it says the spatial shader is not written and that the
   wood textures, credits file, scorch generator and `normal_map_check.gd` are not in the repo. All
   of them now exist.
3. **Each hint-experiment material binds a texture it never samples.** `hint_experiment.gdshader:13-17`
   samples only one sampler, chosen by `use_source_color`. `hint_source_color.tres:11` binds
   `raw_texture` and `hint_raw.tres:10` binds `source_color_texture`, though neither is read. Both
   point at the same 3×1 PNG, so this costs nothing measurable, but the unused binding is not what
   makes each quad differ. The bool does.
4. **`wood_planks_nor_dx_1k.png` is imported as a VRAM-compressed normal map, but nothing binds it.**
   Its `.import` has `compress/mode=2` and `compress/normal_map=1`. This is intended: CHANGE-BRIEF
   §8 keeps it only as the calibration control for `normal_map_check.gd`. It would still be
   exported with the game.
5. **The scorch mask's 0..1 UV holds only on the shield's front face.** The shader samples the mask
   with raw `UV` and `repeat_disable` (`shield_wood.gdshader:15-16, 65`). The back face uses
   mirrored planar UVs (`make_shield_mesh.gd:25, 80-81`), and the rim uses v = 0..0.04
   (`make_shield_mesh.gd:38-40`). So the back shows the mask mirrored, and the rim shows only a
   thin strip of it. CHANGE-BRIEF §8 says "UV coordinates covering 0.0–1.0" without that
   qualification. The camera sees the front face, so the A/B comparison is unaffected.
6. **`scorch_color` is set by neither shield material** (`shield_new.tres` / `shield_burned.tres`,
   lines 13-22), so both use the shader default (0.08, 0.025, 0.01). This is consistent with
   CHANGE-BRIEF §8, which gives no `scorch_color` per shield. Headlessly it reads back `null`
   (FRICTIONAL.md:283-285).
7. **The shield room's exposure is implicit.** `shield_room.tscn:7-13` has no `tonemap_exposure`,
   and the camera has no CameraAttributes, so exposure is the default 1.0 (the test reads 1.0).
   The hint scene writes 1.0 explicitly (`hint_experiment.tscn:10`). The two scenes agree; only
   the shield room's value depends on the engine default.
8. **The credits on file go beyond the brief.** `wood_planks/ATTRIBUTION.md:6-8` and
   `SOURCES.md:19` name an author and a licence. CHANGE-BRIEF.md states neither: it only says
   they go in the credits file. They are not repeated below and were not checked in this audit.
   The brief also gives no source for the grey strip `hint_greys_3x1.png`. The repo says it is
   written by `godot/tools/make_hint_greys.gd:6-7`.

Nothing else is inconsistent with CHANGE-BRIEF.md. Only the albedo sampler has `source_color`
(Failure 4), the normal map is the `_nor_gl` file with `hint_normal`, the two shields differ in tint,
roughness, normal strength and scorch amount, and the hint scene is Linear, exposure 1.0.

## Attribution

From CHANGE-BRIEF.md §8, "Texture Source":

- The base material uses the 1K version of Poly Haven's Wood Planks texture set:
  [Poly Haven Wood Planks](https://polyhaven.com/a/wood_planks). Licence, authors and the date
  checked go in the credits file next to the textures, `godot/assets/textures/wood_planks/ATTRIBUTION.md`.
- The scorch mask is not downloaded. A committed GDScript in `godot/tools/` writes it from seeded
  noise, so its source is that code (`godot/tools/make_scorch_mask.gd`).

## What the test cannot establish headlessly

A headless run uses a dummy renderer that draws nothing. The test proves which resources, values,
hints and import settings the renderer is given, not what it shows. In particular:

- That `source_color` actually sRGB-decodes on the GPU. The hint is read as text;
  `evidence/hint_experiment/band_values.txt` is the windowed proof (64/128/192 vs 137/188/225).
- Whether `hint_range` clamps a value set from outside, such as ShieldB's 1.15 (finding 1).
- That the `.import` settings are what the cached `.ctex` was built with. ConfigFile reads the
  declared settings; it does not inspect the imported data.
- How VRAM compression, mipmaps, filtering, shadows and the normal map look. The test does not
  show whether grooves read as grooves under the Sun, or whether ShieldA and ShieldB look clearly
  different. That is the human A/B judgement in one frame at the real resolution.
- Whether the credits are true, or whether the licence permits the use.
