# SOURCES — Mimic Keep

## Design

- *Mimic Keep GDD v0.1* (Assignment 4, Rui Sun, 2026-10-19). The game's rules and numbers marked
  "GDD" in `godot/game/tuning.gd` come from it.

## Code

| Files | Written by | When |
|---|---|---|
| `godot/game/*`, `godot/showcase/*`, `godot/tests/test_rules.gd`, `godot/tests/test_input.gd`, `godot/tools/*` | Claude Code (Claude Opus 5.5), in an interactive session directed by Rui | 2026-10-25 |
| `godot/tools/make_scorch_mask.gd`, `godot/tests/normal_map_check.gd` (except `curl_ratio()` and its three helpers, copied unchanged from the CSYE 7270 Assignment 5 text) | Claude Code (Claude Opus 5.5), in an interactive session directed by Rui | 2026-10-28 |

## Downloaded textures

| Asset | Source | Licence | Credits file |
|---|---|---|---|
| `godot/assets/textures/wood_planks/wood_planks_{diff,rough,nor_gl,nor_dx}_1k.png` | Poly Haven, Wood Planks by Amal Kumar, https://polyhaven.com/a/wood_planks, downloaded 2026-10-28 | CC0 1.0 (checked 2026-10-28) | `godot/assets/textures/wood_planks/ATTRIBUTION.md` |

## Art and meshes written by code

No purchased or AI-generated assets. Every other image and mesh is written by code in this
repository:

| Asset | Made by |
|---|---|
| `godot/assets/sprites/{scarecrow,archer,arrow,mimi}.png` | `godot/tools/make_sprites.gd` (flat colours, 1-px outline) |
| `godot/showcase/shield_mesh.tres` | `godot/tools/make_shield_mesh.gd` (heater shield, planar UVs, tangents) |
| `godot/assets/textures/shield_scorch_mask.png` | `godot/tools/make_scorch_mask.gd` (seeded FastNoiseLite FBM plus an edge ramp; 512×512 grayscale data) |
| meadow, wall and gate | drawn at runtime by `godot/game/background.gd` |

## Engine and fonts

- Godot Engine 4.7.2, MIT licence. The HUD uses Godot's built-in default font.
