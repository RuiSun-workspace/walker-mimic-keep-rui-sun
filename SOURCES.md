# SOURCES — Mimic Keep

## Design

- *Mimic Keep GDD v0.1* (Assignment 4, Rui Sun, 2026-10-19). The game's rules and numbers marked
  "GDD" in `godot/game/tuning.gd` come from it.

## Code

| Files | Written by | When |
|---|---|---|
| `godot/game/*`, `godot/showcase/*`, `godot/tests/test_rules.gd`, `godot/tests/test_input.gd`, `godot/tools/*` | Claude Code (Claude Opus 5.5), in an interactive session directed by Rui | 2026-10-25 |

## Art and meshes

No downloaded, purchased or AI-generated assets. Every image and mesh is written by code in this
repository:

| Asset | Made by |
|---|---|
| `godot/assets/sprites/{scarecrow,archer,arrow,mimi}.png` | `godot/tools/make_sprites.gd` (flat colours, 1-px outline) |
| `godot/showcase/shield_mesh.tres` | `godot/tools/make_shield_mesh.gd` (heater shield, planar UVs, tangents) |
| meadow, wall and gate | drawn at runtime by `godot/game/background.gd` |

## Engine and fonts

- Godot Engine 4.7.2, MIT licence. The HUD uses Godot's built-in default font.
