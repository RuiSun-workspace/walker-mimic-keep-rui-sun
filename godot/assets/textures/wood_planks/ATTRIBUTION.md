# Wood Planks — Poly Haven

| | |
|---|---|
| Asset | Wood Planks, https://polyhaven.com/a/wood_planks |
| Author | Amal Kumar (Poly Haven lists "All" for this author) |
| Published | 2023-11-23 (Poly Haven API `date_published`) |
| Licence | CC0 1.0. Poly Haven's licence page (https://polyhaven.com/license) states that all its assets are CC0. No attribution is required; it is given here anyway. |
| Checked | 2026-10-28, licence page and `https://api.polyhaven.com/info/wood_planks` |
| Downloaded | 2026-10-28 by Claude Code, with Rui's approval, from `https://dl.polyhaven.org/file/ph-assets/Textures/png/1k/wood_planks/` |
| Resolution | 1K PNG, 1024×1024, 16 bits per channel (Godot stores 8-bit after import) |

The files are unmodified. Each md5 matches the one Poly Haven's file API
(`https://api.polyhaven.com/files/wood_planks`) lists:

| File | Bytes | md5 | Use in this project |
|---|---|---|---|
| `wood_planks_diff_1k.png` | 5,272,102 | `8308a169ed23e5912ef27eb5a54b1543` | albedo (`source_color`) |
| `wood_planks_rough_1k.png` | 1,622,337 | `1d46baf0758ea215e32d332bf4786ab5` | roughness data |
| `wood_planks_nor_gl_1k.png` | 5,880,709 | `5e1006892b116203e732984d0c0a09a4` | normal map (OpenGL, the one the material uses) |
| `wood_planks_nor_dx_1k.png` | 5,879,991 | `53fef9d9fa1f0e6f57ef42cdbd7dc36e` | calibration control for `godot/tests/normal_map_check.gd` only; no shader samples it |

Import settings follow CHANGE-BRIEF.md §8 "Texture Plan" and are set explicitly in each
`.import` file.
