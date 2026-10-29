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
godot --headless --path godot --script res://tests/test_rules.gd --fixed-fps 60
godot --headless --path godot --script res://tests/test_input.gd --fixed-fps 60
```

`test_rules.gd` (23 checks) covers spawning, targeting, the burn's duration, damage, refresh,
time scale and pause, gate damage, losing and winning. `test_input.gd` (14 checks) drives the
real keys through `Input.parse_input_event`. Both print one PASS/FAIL line per check and exit 1
on any failure. Both passed at 30, 60 and 144 fps on 2026-10-25.

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
```

## Known limitations

- Burning has **no visual** yet. A burning scarecrow looks the same as one that is not. Assignment 5
  adds the shader that shows it.
- One enemy type and one wave. No gold, XP, level-ups, Mimi's moods or shop, other elements, or
  bosses from the GDD.
- Placeholder art: flat code-drawn sprites, not final art.
- Balance: the spawn rate was eased after Rui's first playtest (see FRICTIONAL.md);
  `godot --headless --path godot --script res://tools/balance_sim.gd --fixed-fps 60 -- 3.0 1.5`
  compares tunings with two stand-in players.
- Level-ups, upgrade cards and other GDD systems are planned for after Assignment 5, so that
  Assignment 5 changes only presentation, not game rules.
