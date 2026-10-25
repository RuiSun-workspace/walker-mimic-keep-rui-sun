# FRICTIONAL — Mimic Keep

An honest log of what was tried, what happened, and who did what. Rui's own words are marked as
Rui's; everything Claude Code did is labelled as Claude's.

## 2026-10-25 — Change of game: walker-lamplight → Mimic Keep

**The change.** Assignments 2–3 were built on walker-lamplight-rui-sun (Wick, a lantern in a
mine). Assignment 4 was the game design document for a new game, Mimic Keep. From Assignment 5 on,
the course game is Mimic Keep, in this repository. This is the course's one allowed change of game.

**Why (Rui):**

> _To be written by Rui._

**What Claude Code (Opus 5.5) did, at Rui's request ("开工做新游戏吧"):** built a playable
prototype from the GDD before any Assignment 5 work. That is a new Godot 4.7.2 project (Forward+),
the archer, fire arrows, Straw Scarecrows with a Burning state, gate HP, win and loss, pause, two
headless test suites, code-drawn sprites, and a 3D showcase scene with a code-built wooden shield
for the later material work.

**What happened and what was checked (Claude):**

- First test run, 60 fps: 19/22 and 13/14 passed. Three failures were real findings:
  - *Same-tick reset.* A restart arriving between physics ticks freed the scarecrows with
    `queue_free`, but they still ran one more `_physics_process` and hit the new gate.
    Fixed in the game: scarecrows and arrows skip a tick once queued for deletion.
  - *Time scale.* At `time_scale` 2 the burn took 122 ticks, not 120. A probe showed the first
    tick after the change still receives the old delta (1/60, then 2/60). The test now sums the
    engine's own deltas instead of counting ticks.
  - *Wall spawn.* A scarecrow spawned at the wall lost its first tick before attacking. It now
    knows it is at the wall from `_ready()`.
- After the fixes: 23/23 and 14/14 at 30, 60 and 144 fps.
- A real windowed render (`tools/capture_prototype.gd`, Vulkan Forward+, RTX 3070 Laptop) wrote
  `evidence/prototype/game_12s.png` and `shield_room.png`. Claude looked at both. The game draws,
  arrows fly, and 4 scarecrows burned down in 12 s with the archer standing still. The shield faces
  the camera with correct winding and casts a shadow.

### Rui's first playtest (2026-10-25)

Rui played the prototype in a window, with the spawn interval going from 2.4 s down to 0.9 s.
Rui's words: "目前的怪物数量太多了，很难通关" (there are too many monsters right now; it is very
hard to win). Rui also noted that the level-up and upgrade-choice mechanics from the GDD are not in.

**Claude's response.**

- Claude wrote `godot/tools/balance_sim.gd` to play whole runs headlessly over 8 seeds with two
  stand-in players. "idle" never moves. "chase" holds the real move actions toward the scarecrow
  closest to the wall. Neither is a human, so the sim only ranks tunings.
- The sim agreed with Rui: at 2.4 → 0.9 s, "chase" lost all 8 runs at 71–78 s.

| spawn interval (start → end) | idle wins | chase wins | chase gate HP left |
|---|---|---|---|
| 2.4 → 0.9 (first build) | 0/8 | 0/8 | lost at 71–78 s |
| 2.6 → 1.1 | 0/8 | 2/8 | — |
| 2.8 → 1.2 | 0/8 | 8/8 | 20–100 |
| 2.8 → 1.35 | 1/8 | 8/8 | 71–100 |
| **3.0 → 1.5 (chosen)** | 1/8 | 8/8 | 100 |
| 3.5 → 2.0 | 2/8 | 8/8 | 100 |

- The difficulty has a sharp edge between 2.6 and 2.8 s. The bot reacts instantly and a person
  does not, so Claude chose 3.0 → 1.5. That is clearly winnable by moving, and standing still still
  loses (7/8).
- Tests after the change: 23/23 and 14/14 at 30, 60 and 144 fps.

**Upgrades:** Rui asked whether they can come after Assignment 5. Claude recommended yes: A5's
boundary forbids changing game rules while the shaders are added. Rui's decision is pending.

### Rui's second playtest (2026-10-25, spawn 3.0 → 1.5)

Rui asked whether "1.5 s at 90 s" meant the speed-up never happened, since the run ends at 90 s.
It does happen: the interval shrinks linearly over the whole run (2.5 s at 30 s, 2.0 s at 60 s).
1.5 s is only the end point, so the densest stretch is about 1.6 s near the end, about 41
scarecrows in all. Claude had described it badly ("90 秒时加快到每 1.5 秒一只"); the code was right.

After replaying, Rui said: "目前的游戏没什么问题，继续下一步吧" (the game is fine for now; on to
the next step).
