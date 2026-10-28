# CHANGE-BRIEF

**Author:** Rui Sun  
**Course:** CSYE 7270, Fall 2026  
**Project:** Mimic Keep  
**Engine:** Godot 4.7.2  
**Renderer:** Forward+

## 1. The State

The visual effect represents the Burning state of a Straw Scarecrow. It tells the player which scarecrow is currently taking fire damage and distinguishes that enemy from an ordinary scarecrow.

The player needs this information because burning lasts for several seconds after an arrow hits. Without visible feedback, the player cannot tell whether an enemy is already burning, whether another fire hit refreshed the effect, or which enemy should be targeted next. In the current prototype, a burning scarecrow looks identical to a non-burning scarecrow.

The authoritative gameplay state belongs to `godot/game/scarecrow.gd`:

- `burn_time_left: float` stores the remaining burn time in seconds.
- A value greater than 0.0 means the scarecrow is burning.
- `is_burning()` returns the same condition.
- `burning_started` is emitted when a non-burning scarecrow begins burning.
- `burning_ended` is emitted when the timer reaches zero.

The gameplay values are defined in `godot/game/tuning.gd`:

- `Tuning.BURN_DURATION` = 4.0 seconds.
- `Tuning.BURN_DPS` = 4.0 damage per second.

The shader will not own or calculate the Burning state. A presentation-only driver will read `burn_time_left` and send a normalized visual value to the scarecrow Sprite2D. TIME will not determine how long the effect lasts.

## 2. Effect Specification

### Shader

Path: `godot/shaders/burning_tint.gdshader`

```glsl
shader_type canvas_item;

uniform float burn_mix : hint_range(0.0, 1.0) = 0.0;
uniform vec4 burn_color : source_color = vec4(1.0, 0.752941, 0.125490, 1.0);

void fragment() {
    COLOR.rgb = mix(COLOR.rgb, burn_color.rgb, burn_mix);
}
```

The shader has no `render_mode`. It uses the normal CanvasItem blending behavior.

It declares no sampler uniform. The scarecrow sprite texture is already included in the fragment-stage `COLOR`. The shader changes only RGB and leaves alpha unchanged.

### Uniforms

| Name | Type | Hint | Default | Set by |
| --- | --- | --- | --- | --- |
| `burn_mix` | float | `hint_range(0.0, 1.0)` | 0.0 | Presentation driver reading `Scarecrow.burn_time_left`, set on that scarecrow's own ShaderMaterial |
| `burn_color` | vec4 | `source_color` | (1.0, 0.752941, 0.125490, 1.0), equivalent to RGB (255, 192, 32) | Shader default; the same value in every scarecrow's material copy |

### The colour line

The exact color-changing line is:

```glsl
COLOR.rgb = mix(COLOR.rgb, burn_color.rgb, burn_mix);
```

At `burn_mix` = 0.0, the original sprite color is unchanged. At `burn_mix` = 1.0, every opaque pixel reaches the selected burn color. Normal gameplay begins at 0.65, rather than 1.0, so the straw, patch, head, and hat details remain visible.

Godot documents that fragment-stage CanvasItem `COLOR` already contains the vertex color, CanvasItem modulation, self-modulation, and default texture sample. ([Godot CanvasItem shader documentation](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/canvas_item_shader.html))

## 3. Measurable Rules

### Rule 1 — Start and End Values

- Before ignition: `burn_mix = 0.0`
- Immediately after ignition, allowing at most one frame for the presentation driver: `burn_mix = 0.65`
- When Burning ends: `burn_mix = 0.0`

The value must never become negative or exceed 0.65 during normal gameplay.

### Rule 2 — Duration

The visual value is calculated from the gameplay timer:

```
burn_mix = 0.65 × clamp(burn_time_left / 4.0, 0.0, 1.0)
```

Expected values include:

| Burn time left | Expected `burn_mix` |
| --- | --- |
| 4.0 s | 0.6500 |
| 3.0 s | 0.4875 |
| 2.0 s | 0.3250 |
| 1.0 s | 0.1625 |
| 0.0 s | 0.0000 |

The transition lasts exactly four seconds of game time, with a tolerance of one frame period at the frame rate being measured (1/30 s at 30 fps, 1/60 s at 60 fps, 1/144 s at 144 fps), because the driver updates `burn_mix` once per frame. Runs at 30, 60, and 144 fps must produce the same four-second game-time duration.

### Rule 3 — Ignited Again While Burning

The behavior is **restart**.

The gameplay logic already refreshes `burn_time_left` to 4.0 when another fire arrow hits. Therefore, a second fire hit must return `burn_mix` to 0.65, even if the previous tint had already faded.

For example, if `burn_mix` has fallen to 0.1625, a new fire hit must return it to 0.65 within one frame.

### Rule 4 — Time Scale and Pause

The effect follows scaled game time because it is derived from `burn_time_left`, which is reduced using physics delta.

- At `Engine.time_scale = 0.5`, four seconds of game time take approximately eight seconds of real time.
- At `Engine.time_scale = 2.0`, four seconds of game time take approximately two seconds of real time.
- When the scene tree is paused, both `burn_time_left` and `burn_mix` stop changing.
- Resuming continues from the same value.

TIME may later be used for a small visual flicker, but it must never determine burn duration or remaining burn time.

### Rule 5 — Early End

If Burning ends before a fade completes, `burn_mix` becomes 0.0 immediately.

If the scarecrow dies while burning, the scarecrow and its Sprite2D are removed, so no tint may remain visible after deletion. The presentation layer must not continue a separate fade after the gameplay object has died.

### Rule 6 — Multiple Instances

Each scarecrow must have its own `burn_mix`.

The shader will use an ordinary uniform:

```glsl
uniform float burn_mix : hint_range(0.0, 1.0) = 0.0;
```

Every scarecrow gets its own ShaderMaterial: the material on the scarecrow's Sprite2D is local to each scarecrow instance (`resource_local_to_scene`, or duplicated by the driver when the scarecrow enters the tree). The driver calls `set_shader_parameter("burn_mix", ...)` on that scarecrow's own material only. All copies use the same shader, so `burn_color` has the same value in each.

An `instance uniform` was considered and rejected: on Godot 4.7.2, `get_shader_uniform_list()` does not report an instance uniform, and `set_instance_shader_parameter()` accepts an undeclared name without an error (probe, 2026-10-26). A test could then not catch a renamed `burn_mix`.

For example, if scarecrow A has two seconds left and scarecrow B has never been ignited:

- A `burn_mix` = 0.325
- B `burn_mix` = 0.000

Changing A must not change B.

## 4. Boundaries

This change is limited to presentation.

The presentation code may read `burn_time_left`, call `is_burning()`, and listen to `burning_started` and `burning_ended`. It must never change HP, burn duration, damage, movement, targeting, input, gate damage, win or loss conditions, or any other gameplay state.

The following files will not be modified:

- `godot/game/tuning.gd`
- `godot/game/main.gd`
- `godot/game/archer.gd`
- `godot/game/arrow.gd`
- `godot/tests/test_rules.gd`
- `godot/tests/test_input.gd`

The following behavior must remain unchanged:

- Collision shapes and collision checks.
- Scarecrow movement and wall attacks.
- Archer movement and automatic targeting.
- Arrow movement, hit detection, and fire damage.
- Burning duration and damage.
- Input actions.
- Pause and restart behavior.
- Win and loss states.
- Every existing test expectation.
- Every object other than the scarecrow's visual presentation.

The effect reads gameplay state and sends a value to the renderer. No shader or visual driver is allowed to write back into gameplay state.

## 5. Evidence Split

| Rule or claim | Headless evidence | Human or image evidence |
| --- | --- | --- |
| Uniform names and types | `get_shader_uniform_list()` reports `burn_mix` as a float and `burn_color` as a Color; defaults are read from the shader source text | Not required |
| Start and end values | Ignite a scarecrow and read `burn_mix`; verify 0.65, then advance until Burning ends and verify 0.0 | Confirm the tint appears and disappears clearly |
| Four-second duration | Run at 30, 60, and 144 fps; measure game time from 0.65 to 0.0, tolerance one frame period at that frame rate | Confirm the visual fade does not appear abrupt |
| Re-ignition | Let the value fall below 0.65, hit with fire again, and verify it returns to 0.65 | Confirm the renewed effect is noticeable |
| Time scale and pause | Test at time_scale 0.5, 1.0, and 2.0; pause halfway and verify the value freezes | Confirm there is no visible change while paused |
| Early ending | Kill a burning scarecrow and verify its Sprite2D is removed without a surviving effect | Inspect a captured frame after death |
| Independent instances | Spawn at least two scarecrows, ignite one, assert their materials are different objects, and compare both `burn_mix` values | Capture both in one frame and confirm only one is tinted |
| Exact tint calculation | Not provable headlessly: a headless run uses a dummy renderer and draws nothing | In a windowed run, set controlled values 0.0, 0.5, and 1.0, capture the frame in-engine, sample the named pixels, and compare against the hand calculations in Section 6 |
| Readability | Not provable by a headless rule test | View at the real 1280×720 resolution and decide whether a burning enemy is distinguishable |
| Color choice | Not provable by a headless rule test | Compare the tint against the green field and confirm that sprite details remain legible |

Headless tests can prove state synchronization and numerical behavior. They cannot prove that the chosen color communicates "Burning" clearly to a person.

## 6. Controlled Inputs and Hand Calculations

The selected burn color is:

- RGB = (255, 192, 32)
- Normalized = (1.000000, 0.752941, 0.125490)

The shader calculation is:

```
result = original × (1 − burn_mix) + burn_color × burn_mix
```

Alpha is unchanged.

### Predicted Pixel Results

| Pixel | Original RGB | `burn_mix` = 0.0 | `burn_mix` = 0.5 | `burn_mix` = 1.0 |
| --- | --- | --- | --- | --- |
| Straw body (28, 46) | (233, 196, 106) | (233, 196, 106) | (244, 194, 69) | (255, 192, 32) |
| Patch (33, 47) | (181, 101, 29) | (181, 101, 29) | (218, 147, 31) | (255, 192, 32) |
| Sack head (28, 22) | (217, 185, 138) | (217, 185, 138) | (236, 189, 85) | (255, 192, 32) |

Three values at `burn_mix` = 0.5 fall exactly halfway between two integers: patch green 146.5, patch blue 30.5, and head green 188.5. The table rounds them up; 8-bit output may round either way, so these three are predicted ±1.

For the straw-body red channel at `burn_mix` = 0.5:

```
233 × (1 − 0.5) + 255 × 0.5
= 116.5 + 127.5
= 244
```

For its green channel:

```
196 × 0.5 + 192 × 0.5
= 98 + 96
= 194
```

For its blue channel:

```
106 × 0.5 + 32 × 0.5
= 53 + 16
= 69
```

The normal gameplay starting value is 0.65. At that value:

| Pixel | Predicted RGB |
| --- | --- |
| Straw body (28, 46) | (247, 193, 58) |
| Patch (33, 47) | (229, 160, 31) |
| Sack head (28, 22) | (242, 190, 69) |

These direct calculations are valid because the 2D game scene contains no Light2D or CanvasModulate, HDR 2D is disabled, and the selected sprite pixels are fully opaque.

They also assume that `burn_color` reaches the shader as written, (255, 192, 32). With HDR 2D off, a `source_color` uniform in a canvas_item shader should not be converted to linear. This is a reading of the engine, not an observation; the controlled-value captures will check it.

Using standard relative luminance, the straw-body pixel has approximately 1.80:1 contrast against the grass before tinting and 1.81:1 at `burn_mix` = 0.65. The main straw area therefore keeps approximately the same luminance separation from the background, while its hue changes strongly toward yellow-orange.

## 7. Grayscale Experiment Prediction

The test image contains three grayscale cells: 64, 128, 192.

Two unshaded spatial quads sample the same image:

1. Source-color quad: sampler declared with `source_color`.
2. Unhinted quad: sampler declared without `source_color`.

The test uses Forward+, Linear tonemapping, and exposure 1.0.

The sRGB functions are:

```
decode(c) =
    c / 12.92                                  when c ≤ 0.04045
    ((c + 0.055) / 1.055) ^ 2.4              otherwise

encode(x) =
    12.92x                                     when x ≤ 0.0031308
    1.055 × x^(1 / 2.4) − 0.055              otherwise
```

### Quad With source_color

The texture sample is decoded from sRGB to linear before it is assigned to `ALBEDO`.

| File value | Value ÷ 255 | Decoded linear value | Encoded screen value |
| --- | --- | --- | --- |
| 64 | 0.250980 | 0.051269 | 64 |
| 128 | 0.501961 | 0.215861 | 128 |
| 192 | 0.752941 | 0.527115 | 192 |

The final visible values are: 64, 128, 192.

### Quad Without source_color

The texture sample is treated as if the stored sRGB number were already linear.

| File value | Value written to ALBEDO | Encoded result | Final 0–255 |
| --- | --- | --- | --- |
| 64 | 0.250980 | 0.538065 | 137 |
| 128 | 0.501961 | 0.736647 | 188 |
| 192 | 0.752941 | 0.882352 | 225 |

The final visible values are: 137, 188, 225.

Therefore, the quad using `source_color` displays the original file values. Its sRGB decode and final display encode are inverse operations. The unhinted quad incorrectly treats encoded color values as linear data, so it appears too bright.

Godot requires `source_color` for sRGB color textures in Forward+ and recommends leaving it off data textures such as roughness and normal maps. ([Godot shading-language documentation](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/shading_language.html))

## 8. Material Plan

### Objects and Lighting

The material comparison uses:

- `ShieldA` in `godot/showcase/shield_room.tscn` for the first material.
- `ShieldB` for the second material.
- `godot/showcase/shield_mesh.tres` for both objects.
- UV coordinates covering 0.0–1.0.
- Existing mesh tangents for the normal map.

The visual judgment will use the existing scene lighting:

- One DirectionalLight3D.
- Light energy 1.2.
- Shadows enabled.
- Environment light energy 0.3.
- Linear tonemapping.
- Existing camera position and exposure.

These settings will not be changed during the A/B comparison. Both shields must be visible in the same frame so that material differences are judged under identical light and camera conditions.

### Texture Source

The base material will use the 1K version of Poly Haven's Wood Planks texture set: [Poly Haven Wood Planks](https://polyhaven.com/a/wood_planks). Licence, authors and the date checked go in the credits file next to the textures.

The scorch mask is not downloaded. A committed GDScript in `godot/tools/` writes it from seeded noise, so its source is that code.

### Texture Plan

| Texture | Purpose and numeric meaning | Shader hint | compress/mode | compress/normal_map | mipmaps/generate |
| --- | --- | --- | --- | --- | --- |
| `wood_planks_diff_1k.png` | Albedo color. RGB stores visible wood color | `source_color` | VRAM Compressed | Disabled | true |
| `wood_planks_rough_1k.png` | Roughness data. 0 = smooth, 1 = rough | None | VRAM Compressed | Disabled | true |
| `wood_planks_nor_gl_1k.png` | OpenGL tangent-space normal. RGB encodes XYZ direction | `hint_normal` | VRAM Compressed | Enabled | true |
| `wood_planks_nor_dx_1k.png` | DirectX normal used only to calibrate the normal-map check; not used in the final material | Not sampled by any shader | VRAM Compressed | Enabled | true |
| `shield_scorch_mask.png` | Code-generated grayscale mask. 0 = clean wood, 1 = fully scorched | None | Lossless | Disabled | true |

The `_nor_gl` texture is the final normal map because Godot expects OpenGL-style normal maps. The `_nor_dx` version is retained only as a calibration control for `godot/tests/normal_map_check.gd`. With `curl_ratio()`, `_nor_gl` should come out near 0 with `directx = false` and near 2 with `directx = true`, and `_nor_dx` the other way round. The pass threshold is set from this known pair, not by feel.

Albedo uses `source_color` because it is visible color. Roughness, normal, and scorch-mask textures are numeric data and do not use `source_color`. Godot recommends mipmaps for 3D textures and special normal-map compression for normal data. ([Godot image-import documentation](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html))

### Shader Uniform Groups

The spatial shader will use two groups:

```glsl
group_uniforms Surface;
group_uniforms Damage;
```

It will remain shaded; it will not use `render_mode unshaded`, because the assignment comparison must respond to the room's DirectionalLight3D, shadows, and environment light.

| Group | Uniform | Type and hint | Range | Default | Effect at minimum and maximum |
| --- | --- | --- | --- | --- | --- |
| Surface | `wood_tint` | `vec4 : source_color` | Each RGB channel 0–1 | (1, 1, 1, 1) | Black at (0,0,0); original albedo at white |
| Surface | `texture_scale` | `float : hint_range(0.25, 4.0)` | 0.25–4.0 | 1.0 | 0.25 makes grain appear larger; 4.0 produces smaller repeated grain |
| Surface | `roughness_scale` | `float : hint_range(0.0, 1.0)` | 0–1 | 0.85 | 0 produces a glossy surface; 1 uses the full roughness texture |
| Surface | `normal_strength` | `float : hint_range(0.0, 2.0)` | 0–2 | 1.0 | 0 removes normal-map relief; 2 exaggerates the grain |
| Damage | `scorch_amount` | `float : hint_range(0.0, 1.0)` | 0–1 | 0.0 | 0 is clean wood; 1 applies the complete scorch mask |
| Damage | `scorch_color` | `vec4 : source_color` | Each RGB channel 0–1 | (0.08, 0.025, 0.01, 1) | Dark brown by default; lighter values make the burn less severe |
| Damage | `char_roughness` | `float : hint_range(0.0, 1.0)` | 0–1 | 0.95 | 0 makes scorched areas glossy; 1 makes them fully rough |

### Difference Between the Two Materials

Both shields use the same mesh and texture set, but separate ShaderMaterial resources.

#### ShieldA — New Wooden Shield

```
wood_tint       = (1.00, 1.00, 1.00, 1.00)
texture_scale   = 1.00
roughness_scale = 0.75
normal_strength = 0.80
scorch_amount   = 0.05
char_roughness  = 0.95
```

ShieldA represents a relatively new shield. It keeps the original wood color, has moderate surface relief, and shows only very small scorch marks.

#### ShieldB — Burned Wooden Shield

```
wood_tint       = (0.72, 0.50, 0.34, 1.00)
texture_scale   = 1.00
roughness_scale = 0.95
normal_strength = 1.15
scorch_amount   = 0.70
char_roughness  = 0.98
```

ShieldB represents a shield that has been exposed to fire. It is darker, rougher, has stronger visible grain, and uses much more of the scorch mask.

The two materials therefore differ in at least four controlled values: tint, roughness, normal strength, and scorch amount.

## 9. Predicted Failure Cases

### Failure 1 — Re-ignition Does Not Refresh the Effect

**Possible error:** A second fire arrow refreshes gameplay Burning to four seconds, but the visual value continues fading from its old value.

**Check:** Ignite a scarecrow, wait until `burn_mix` is below 0.3, ignite it again, and assert that the value returns to 0.65 within one frame.

### Failure 2 — Shared Material Changes Every Scarecrow

**Possible error:** Calling `ShaderMaterial.set_shader_parameter()` on one scarecrow changes every scarecrow using that material.

**Check:** Spawn three scarecrows, ignite only the middle one, assert that the three materials are different objects, and read `burn_mix` from each scarecrow's own material. Expected values are approximately 0.0, 0.65, and 0.0. Capture all three in the same image.

### Failure 3 — Time Scale Produces the Wrong Game-Time Duration

**Possible error:** The visual effect uses unscaled real time, so changing `Engine.time_scale` separates the visual duration from gameplay Burning.

**Check:** Measure the effect at time_scale values 0.5, 1.0, and 2.0. Each must last four seconds of game time, with a tolerance of one frame period.

### Failure 4 — Data Texture Incorrectly Uses source_color

**Possible error:** Roughness, normal, or scorch-mask data is sRGB-decoded because the sampler was incorrectly marked `source_color`.

**Check:** The material test reads each sampler's hints from the shader source text and asserts that the roughness, normal, and scorch-mask samplers have no `source_color` and the albedo sampler has it. A mutation that deletes `source_color` from the albedo sampler must make that test exit 1. The grayscale experiment shows on screen what the wrong path does: 64, 128, 192 become 137, 188, 225.

### Failure 5 — Normal Map Uses the Wrong Y Direction

**Possible error:** The `_nor_dx` map is used without converting its green channel, causing grooves to appear raised or highlights to move in the wrong direction.

**Check:** `normal_map_check.gd` prints `curl_ratio()` for the bound normal map under both conventions; the map in use must come out near 0 with `directx = false`. By eye, under the fixed DirectionalLight3D, grooves should read as grooves and highlights should fall on the side facing the light.

## 10. Short Answers

**1. Which renderer does project.godot use, and what does that exclude?**

The project uses `renderer/rendering_method="forward_plus"`. Therefore, the active rendering path is Forward+, not Compatibility or Mobile. Forward+ supports decals, compute shaders, VoxelGI, SDFGI, and SSIL, so none of these is ruled out. What it rules out is running on targets that only support Compatibility, such as web exports and older GPUs without Vulkan, Direct3D 12, or Metal.

**2. What color is available at the start of fragment(), and what would the more convenient-looking alternative return?**

In a CanvasItem `fragment()`, `COLOR` already contains the vertex color multiplied by modulate, self_modulate, and the default texture sample. Calling `texture(TEXTURE, UV)` manually returns only the default texture sample and excludes the existing vertex and node modulation.

**3. In a CanvasItem shader, what happens if texture(TEXTURE, UV) is used instead of COLOR?**

It samples the sprite texture again but does not include the vertex color, modulate, or self_modulate already present in `COLOR`. Replacing `COLOR` with that sample can therefore discard tint and opacity applied by the CanvasItem.

**4. In a spatial shader, what is ALBEDO if it is never written, and what is in COLOR?**

`ALBEDO` defaults to white. Spatial `COLOR` contains the mesh's interpolated vertex color from the vertex stage; it does not automatically contain an albedo texture sample. ([Godot spatial-shader documentation](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html))

**5. What happens if the four-second effect is implemented using a fixed number of frames?**

At 60 fps, four seconds equals 240 frames. A fixed 240-frame implementation would last:

- 240 / 30 = 8.0 seconds at 30 fps.
- 240 / 60 = 4.0 seconds at 60 fps.
- 240 / 144 ≈ 1.67 seconds at 144 fps.

This is why the effect must use the gameplay timer rather than counting frames.

**6. Where are uniform defaults and current values stored, and what happens when two objects share a material?**

The declared default belongs to the Shader resource represented by the `.gdshader` code. An ordinary uniform's current override belongs to the ShaderMaterial. If two objects share that ShaderMaterial, changing the ordinary uniform changes both objects.

In this design, every scarecrow has its own copy of the ShaderMaterial, so `burn_mix` set on one copy changes only that scarecrow. `burn_color` keeps the same value in every copy.

**7. Does hint_range clamp a value assigned by driver code?**

My prediction is no. `hint_range` controls the Inspector editing interface but does not replace explicit runtime clamping. If the driver assigns 2.0, I predict the shader receives 2.0. The implementation stage will verify this using a controlled 2.0 assignment and screenshot; the driver will still use `clamp()` explicitly.

## Revision Log

Later changes are added below with a date; the text above is not rewritten.

- **2026-10-26:** Original brief, written by Rui. Before its first commit, Claude Code converted it to Markdown and applied the review corrections Rui approved (listed in FRICTIONAL.md, 2026-10-26). The hand calculations are Rui's and were not recomputed in this file.
- **2026-10-28:** Short answer 1 quotes `renderer/rendering_method="forward_plus"` from `project.godot`. Rui's first editor session removed that key from the file because Forward+ is the default (commit ccb9529). The renderer is unchanged: a headless probe still reads `forward_plus`, and `config/features` still lists "Forward Plus". The answer stands; the key is now implicit. (Added by Claude at Rui's request.)
- **2026-10-28 (A, Rule 1 peak at low frame rates):** Physics runs at 60 ticks/s whatever the frame rate. At 30 fps one frame holds two ticks, so an arrow that hits on the first tick has already burned 1/60 s before any `_process` runs. The first frame after a hit must therefore show `burn_mix ≥ 0.65 × (1 − g / 4)`, where g is the game time that frame advanced. Every frame must also match `0.65 × clamp(burn_time_left / 4, 0, 1)` exactly (1e-6). At 60 and 144 fps the first frame still shows exactly 0.65. Raised by the agent's driver plan (sessions/session-2-plan.md); Rui approved; added by Claude.
- **2026-10-28 (B, tolerance under time scale):** "One frame period" in Rules 2 and 4 and Failure 3 means the game time one frame advances: `Engine.time_scale / fps`. For example, 1/15 s at 30 fps and time_scale 2. Same origin and approval as A.
