No edits made yet. Here's the plan.

## Plan: wire Effect A into gameplay

### Step 1: Trigger code (4 files, 2 of them new)

**`godot/game/scarecrow.gd`**: the one change the brief allows (§5):
```gdscript
signal hit_taken(position: Vector2)
...
	if element == &"fire":
		ignite()
	hit_taken.emit(global_position)   # new: after ignite(), before _check_death()
	_check_death()
```
Damage, `ignite()` and the death check keep their order. A call that returns early because the scarecrow is already dead emits nothing, so only accepted hits send the signal.

**`godot/game/main.tscn`**: add one node, `World/Effects` (Node2D), after `Archer`, in group `"effects"`. That is the only change to this file.

**`godot/effects/impact_spawner.gd`** (new, about 15 lines), attached to a new child node `ImpactSpawner` in `godot/game/scarecrow.tscn`. The brief allows presentation scripts on the scarecrow scene. On `_ready` it connects the parent's `hit_taken`. On each signal it:
1. Instantiates a **new** `impact_burst.tscn`.
2. Sets its `position` to the signal's position. `World/Effects` sits at the origin, so this is also the global position.
3. Adds it to the node in group `"effects"`, so it is not under the scarecrow.
4. Sets `Flash.emitting = true` and `Straw.emitting = true`.
5. Connects `Straw.finished` → `burst.queue_free` (Straw is the longer emitter, 0.80 s).

`impact_burst.tscn` stays untouched, along with every effect setting, `main.gd`, `arrow.gd` and the shaders. The spawner only reads the signal and never writes game state.

**How this implements the retrigger rule (overlap, A3):** every signal creates its own new instance. Nothing is ever reused or restarted, so a second hit cannot affect a burst that is still playing. For a lethal hit, the signal fires before `_check_death()` and the burst goes under `World/Effects`, so it lives past the scarecrow's `queue_free()` (A4).

### Step 2: State test `godot/tests/test_impact_burst_state.gd`, run at 60

It loads `main.tscn` with `spawning_enabled = false`. Every hit comes from arrows the archer fires on its own through the real physics loop. The test never calls `hit()`, `ignite()` or the spawner. Like the existing tests, its setup uses `spawn_scarecrow()`, plus `gate_hp` and real R/Enter keys through `Input.parse_input_event`, as test_input.gd does. The test only *listens* to `hit_taken`, `archer.fired` and `Effects.child_entered_tree`.

**Scenario:**
1. **Scene load:** wait 30 frames with no scarecrows. `World/Effects` has 0 children and 0 bursts were created.
2. **Overlap with uneven impact times:** spawn far scarecrow F directly above the archer at y≈0, so arrow 1 flies ~0.55 s. After arrow 1 is fired, spawn near scarecrow N at the wall about 40 px off the archer. Arrows 2 and 3 then target N and arrive about 0.02 s after firing. Expected impacts are about 0.55, 0.62 and 1.22 s. Burst 1 lives until about 1.35 s, so three bursts are alive at once. Arrows 2 and 3 are also two hits inside one 0.80 s lifetime.
3. **Lethal hit:** N keeps getting hit: 10 per arrow plus 4/s burn. With HP 40, the hit at about 2.42 s kills it (its HP is about 2.8 before that hit). The test records which hit left `hp <= 0`.
4. **Miss:** spawn a far scarecrow, wait for `fired`, then remove it before the arrow arrives, the same way test_wall_targeting.gd does. The arrow leaves the screen.
5. **Reset with a live burst:** set `gate_hp` low as in test_input.gd and let N or a wall scarecrow end the run. While a burst exists, press R, then wait.

| Assertion | Rule |
|---|---|
| 0 bursts after scene load (and before any arrow) | A1 |
| bursts created == `hit_taken` count == arrows freed on-screen (accepted hits) | A1 |
| no burst created during burn-only stretches (count unchanged across frames with no arrow impact) | A1 |
| the miss arrow creates no burst | A1 |
| each burst's `global_position` == signal position, ±1 px; the signal position == the scarecrow's `global_position` at that moment | A2 |
| every burst's parent is `World/Effects`, never a scarecrow | A2/A4 |
| at the third impact, 3 distinct live burst instances (different instance IDs) | A3 |
| when hit 2/3 lands, the earlier bursts are still valid, the same instance, still in the tree, and `Straw.emitting` is still true | A3 |
| each burst frees after 48 frames ±3. Freeing late would mean a restart, freeing early would mean it was cleared | A3, A5 |
| lethal hit: the scarecrow is freed, its burst is still alive the next frame and frees after about 0.80 s | A4 |
| `World/Effects` holds no finished bursts once all have freed | A5 |
| after R/Enter restart with a live burst, `World/Effects` is empty within 1.20 s | A5 |

One thing to note for A5: game end disables `World`, and that also freezes `Effects`. A burst alive at the loss sits frozen until reset and then finishes. The brief's carry-over clause accepts this, and the test will measure it.

I'll then run all existing tests per CLAUDE.md (60, plus 30/60/144 for burning_tint and wall_targeting), and the config test and new test at 60. The test doesn't wait on audio, so realtime isn't needed.

### What headless cannot prove (human / frame strip only)
- That particles are **drawn** at all, at the hit point, and in the right colours, scale and motion. The dummy renderer runs no GPU process, so "emitting = true" is node state, not pixels.
- A3 visually: the second flash appears while the first burst's straw is still visible (strip frames 28–30).
- A4 visually: the straw is still drawn after the scarecrow disappears.
- That `local_coords = false` particles stay put while nothing moves them.
- Contrast and readability over grass, wall, walkway and gate, the timing feel (flash about 8 frames at 30 fps), and the size compared with the scarecrow's head.
- GPU cost: not measured here.

### Assumption to confirm
- I'm assuming two things: the group tag on `World/Effects` counts as part of "the one node", and the spawner can live in the scarecrow scene. The alternative is a script on `World/Effects` that catches scarecrows through `get_tree().node_added`. That keeps `scarecrow.tscn` unchanged but adds a script to `main.tscn`. I recommend the scarecrow-scene spawner.

Approve Step 1 (trigger code) and I'll implement only that and show the diff.