# Language Notes — Mimic Keep

## Contents

- [Part 1 — The generated shader, annotated](#part-1--the-generated-shader-annotated)
- [Part 2 — Questions](#part-2--questions)
  1. [What does `shader_type` decide?](#1-what-does-shader_type-decide)
  2. [Processor functions](#2-processor-functions)
  3. [Built-ins read and written](#3-built-ins-read-and-written)
  4. [Hints: Inspector only, or the value too?](#4-hints-inspector-only-or-the-value-too)
  5. [Does `hint_range` clamp a value set from code?](#5-does-hint_range-clamp-a-value-set-from-code)
  6. [Colour versus data sampling](#6-colour-versus-data-sampling)
  7. [Why `fragment()` cannot see its neighbour](#7-why-fragment-cannot-see-its-neighbour)
  8. [Godot shading language versus plain GLSL](#8-godot-shading-language-versus-plain-glsl)

## Part 1 — The generated shader, annotated

File: `godot/shaders/standard_generated.gdshader`  
This shader was converted from a `StandardMaterial3D` and has not been edited.

| Line | Code (excerpt) | What it does |
|---:|---|---|
| 3 | `shader_type spatial;` | Declares a 3D spatial shader. This makes spatial material outputs such as `ALBEDO`, `ROUGHNESS`, and `NORMAL_MAP` available. |
| 4 | `render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;` | Selects the material's blending, depth, culling, diffuse-lighting, and specular-lighting modes. It is not unshaded, so scene lighting affects it. |
| 6 | `uniform vec4 albedo : source_color;` | Stores the albedo colour selected in the Inspector. `source_color` identifies it as colour rather than arbitrary numeric data. |
| 7 | `uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;` | Declares the albedo texture sampler. `source_color` identifies it as sRGB colour data. The other hints enable linear mipmap filtering and repeating. |
| 19 | `uniform sampler2D texture_normal : hint_roughness_normal, filter_linear_mipmap, repeat_enable;` | Declares the normal texture without `source_color`. `hint_roughness_normal` identifies it as a normal texture used to guide Godot's roughness-limiter import process. |
| 20 | `uniform float normal_scale : hint_range(-16.0, 16.0);` | Stores the normal-map strength selected in the Inspector. It is later assigned to `NORMAL_MAP_DEPTH`. |
| 34 | `vec4 albedo_tex = texture(texture_albedo, base_uv);` | Samples the albedo texture using the transformed UV coordinates. |
| 35 | `ALBEDO = albedo.rgb * albedo_tex.rgb;` | Multiplies the sampled albedo texture by the Inspector albedo colour and writes the final base colour. |
| 42 | `float roughness_tex = dot(texture(texture_roughness, base_uv), roughness_texture_channel);` | Samples the roughness texture and selects the channel containing the roughness data. |
| 43 | `ROUGHNESS = roughness_tex * roughness;` | Combines the roughness texture with the Inspector roughness value and writes the final roughness. |
| 46 | `NORMAL_MAP = texture(texture_normal, base_uv).rgb;` | Samples the normal texture and writes its RGB channels to `NORMAL_MAP`. |
| 47 | `NORMAL_MAP_DEPTH = normal_scale;` | Applies the Inspector normal-map strength to the sampled normal map. |

## Part 2 — Questions

### 1. What does `shader_type` decide?

`shader_type` selects the rendering pipeline used by a shader. It determines which processor functions, built-in inputs, and built-in outputs are available.

The burning shader uses `canvas_item`, so it runs in Godot's 2D rendering pipeline and can work with values such as `COLOR` (`burning_tint.gdshader:1`). The shield shader and hint experiment use `spatial`, so they run in the 3D material pipeline and can write material properties such as `ALBEDO`, `ROUGHNESS`, and `NORMAL_MAP` (`shield_wood.gdshader:1`, `hint_experiment.gdshader:1`).

### 2. Processor functions

I wrote a `fragment()` function in each of my three shaders. A fragment processor runs for every covered fragment after the object has been rasterized.

The burning shader changes the final sprite colour in `fragment()` (`burning_tint.gdshader:6-7`). The shield shader calculates the material's colour, roughness, and normal map in `fragment()` (`shield_wood.gdshader:54`, `shield_wood.gdshader:72-75`). The hint experiment selects one sampler and writes its result to `ALBEDO` in `fragment()` (`hint_experiment.gdshader:12-17`).

I did not write a `vertex()` function in these shaders. If the burning colour calculation were moved into `vertex()`, it would run once for each sprite vertex, and the resulting vertex colours would be interpolated across the sprite. The sprite texture would then be multiplied by the interpolated vertex colour.

The approximate vertex calculation would be:

```text
texture colour × mix(vertex colour, burn colour, burn_mix)
```

The current fragment calculation instead performs:

```text
mix(texture-modulated colour, burn colour, burn_mix)
```

These calculations are not equivalent. Moving the calculation would cause dark and transparent parts of the sprite texture to multiply the tint differently from the current fragment effect (`burning_tint.gdshader:7`).

### 3. Built-ins read and written

The requirement asks for three distinct built-in variables that I read. However, my final three shaders read only two distinct built-ins: `COLOR` and `UV`.

The effects themselves only required those two inputs, and I did not check this later Language Notes requirement when I finalized the shaders. Therefore, there is no third distinct built-in read that I can cite accurately. I am reporting this limitation instead of counting `UV` twice or claiming that the shaders read a variable they do not use.

The two built-ins actually read are:

- `COLOR` is read and then written by the burning shader (`burning_tint.gdshader:7`). In a CanvasItem fragment processor, `COLOR` is an `inout` built-in, so it is not read-only.
- `UV` is read when the wood shader creates the repeated texture coordinates (`shield_wood.gdshader:56`) and samples the scorch mask (`shield_wood.gdshader:65`). It is also read when the hint experiment samples the greyscale texture (`hint_experiment.gdshader:14`, `hint_experiment.gdshader:16`). In these spatial fragment processors, `UV` is an input and is read-only.

Two built-ins written by the shield shader are `ALBEDO`, which receives the final surface colour (`shield_wood.gdshader:72`), and `NORMAL_MAP`, which receives the tangent-space normal-map data (`shield_wood.gdshader:74`). The shield shader also writes `ROUGHNESS` and `NORMAL_MAP_DEPTH` (`shield_wood.gdshader:73`, `shield_wood.gdshader:75`).

### 4. Hints: Inspector only, or the value too?

The hints used in my shaders do not all have the same effect.

For a texture sampler, `source_color` can change the numeric value received by the shader because it enables the appropriate sRGB colour handling. This was measured in the spatial hint experiment. The sampler with `source_color` is declared on lines 4-5, while the sampler without it is declared on lines 7-8 (`hint_experiment.gdshader:4-8`). The first sampler produced the screen values `64`, `128`, and `192`, while the second produced `137`, `188`, and `225` (`evidence/hint_experiment/band_values.txt:6-10`).

`source_color` is also used on colour-vector uniforms. These are `burn_color` (`burning_tint.gdshader:4`), `wood_tint` (`shield_wood.gdshader:23-24`), and `scorch_color` (`shield_wood.gdshader:43-44`).

The controlled-value experiment used a CanvasItem shader with HDR 2D disabled. In that tested configuration, `burn_mix = 1.0` produced the selected display colour `(255, 192, 32)` exactly (`evidence/controlled_values/pixels.txt:22-24`). Therefore, I cannot claim that this CanvasItem colour uniform underwent a measurable conversion. The two spatial colour uniforms were not tested separately, so their internal numeric conversion is not established by my evidence.

`filter_nearest` changes actual texture sampling. It selects the nearest texel instead of interpolating neighbouring texels, which keeps the three greyscale bands separate (`hint_experiment.gdshader:5`, `hint_experiment.gdshader:8`).

`filter_linear_mipmap` changes actual texture sampling by enabling linear filtering with mipmaps. It is used by the shield's albedo, roughness, and normal samplers (`shield_wood.gdshader:7`, `shield_wood.gdshader:10`, `shield_wood.gdshader:13`).

`repeat_enable` and `repeat_disable` change sampling when UV coordinates leave the `0..1` range. The wood textures repeat (`shield_wood.gdshader:7`, `shield_wood.gdshader:10`, `shield_wood.gdshader:13`), while the scorch mask does not (`shield_wood.gdshader:16`). The two hint-experiment samplers also disable repeating (`hint_experiment.gdshader:5`, `hint_experiment.gdshader:8`).

`hint_normal` marks a sampler as a normal-map input (`shield_wood.gdshader:12-13`). It does not perform an sRGB decode or numerically remap the RGB value returned by `texture()`. The shader receives the sampled channels on line 62, and the visible normal effect occurs when those channels are written to `NORMAL_MAP` on line 74 (`shield_wood.gdshader:62`, `shield_wood.gdshader:74`). Normal-map compression is controlled separately by the texture's import settings.

`hint_range` changes the Inspector control, but it does not clamp a value assigned from code (`burning_tint.gdshader:3`). The controlled `burn_mix = 2.0` experiment confirms this (`evidence/controlled_values/pixels.txt:25-27`).

### 5. Does `hint_range` clamp a value set from code?

No. The `burn_mix` uniform declares an Inspector range from `0.0` to `1.0` (`burning_tint.gdshader:3`), but the controlled-value experiment successfully assigned `2.0`.

At `burn_mix = 2.0`, the captured pixels followed the shader's `mix()` calculation using `2.0` rather than a clamped value of `1.0` (`evidence/controlled_values/pixels.txt:25-27`). For example, the straw-body pixel became `(255, 188, 0)`. If Godot had clamped the value to `1.0`, the result would have been `(255, 192, 32)`.

Therefore, `hint_range` provides an Inspector control but does not enforce a runtime limit. When clamping is required, the script or shader must do it explicitly. The normal burning driver uses `clampf()` before sending the value to the shader (`godot/game/burning_tint.gd:12-13`).

### 6. Colour versus data sampling

In the generated shader, the albedo sampler uses `source_color` (`standard_generated.gdshader:7`). It is sampled on line 34 and used in the albedo calculation on line 35 (`standard_generated.gdshader:34-35`). This is appropriate because albedo represents visible colour.

The generated normal sampler uses `hint_roughness_normal` and does not use `source_color` (`standard_generated.gdshader:19`). It is sampled and written to `NORMAL_MAP` on line 46 (`standard_generated.gdshader:46`). `hint_roughness_normal` identifies a normal texture that can guide Godot's roughness-limiter import process.

My shield shader uses the more direct `hint_normal` for its normal sampler (`shield_wood.gdshader:12-13`). This marks the sampler as a normal-map input, but it is not exactly the same hint as the generated shader's `hint_roughness_normal`. The normal texture is sampled on line 62 and written to `NORMAL_MAP` on line 74 (`shield_wood.gdshader:62`, `shield_wood.gdshader:74`).

The corresponding albedo sampler in my shield shader uses `source_color` (`shield_wood.gdshader:6-7`) and is sampled on line 58 (`shield_wood.gdshader:58`). The roughness texture and scorch mask omit `source_color` because their channels represent numeric data rather than visible colour (`shield_wood.gdshader:9-10`, `shield_wood.gdshader:15-16`).

### 7. Why `fragment()` cannot see its neighbour

Fragment invocations run independently and may execute in parallel. A local variable created by one fragment invocation belongs only to that invocation, and there is no guaranteed order in which neighbouring fragments are processed. Therefore, one fragment cannot directly read a temporary value that a neighbouring fragment is currently calculating.

The burning state reaches the shader through a uniform rather than through another fragment. The driver declares the maximum effect strength as `0.65` (`godot/game/burning_tint.gd:7`). It reads `burn_time_left`, divides it by the burn duration, clamps that fraction to `0.0–1.0`, and multiplies it by `BURN_MIX_MAX` (`godot/game/burning_tint.gd:12`). The resulting `burn_mix` range is `0.0–0.65`, not `0.0–1.0`.

The driver sends that effect-strength value to the material with `set_shader_parameter()` (`godot/game/burning_tint.gd:13`). The shader declares `burn_mix` as a uniform (`burning_tint.gdshader:3`). Every fragment on that scarecrow independently reads the same uniform while calculating its own output colour (`burning_tint.gdshader:7`).

### 8. Godot shading language versus plain GLSL

One feature provided by Godot is `shader_type`. It connects a shader to an engine rendering pipeline and provides processor functions such as `fragment()` without requiring me to create, compile, and link separate GLSL stages manually (`shield_wood.gdshader:1`, `shield_wood.gdshader:54`).

A second Godot feature is its uniform hint system. Hints such as `source_color`, `hint_range`, `hint_normal`, `filter_nearest`, and `repeat_enable` connect shader declarations to Godot's Inspector, colour handling, and texture-sampling system (`burning_tint.gdshader:3-4`; `shield_wood.gdshader:6-16`; `hint_experiment.gdshader:4-8`).

Godot also provides `group_uniforms`, which organizes parameters into named Inspector sections (`shield_wood.gdshader:21`, `shield_wood.gdshader:38`). Plain GLSL does not provide these Godot Inspector and resource-pipeline features.