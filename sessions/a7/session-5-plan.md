I've read everything the plan needs. Here it is. Nothing has been edited.

# Plan: Step 5 (state machine, clip playback, structure test)

I checked the scenes for authority conflicts first. **I found none.** `Archer/AnimationPlayer` has no autoplay and nothing plays it. No script writes the rig parts, `release_window` or `Sprite.frame`. `archer.gd:11` already declares `release_window` as a plain var. Nothing keys `Archer.position`.

## Step A: `archer.tscn`, the AnimationTree (§6, §7, rev. 1.4)
I add sub-resources and one node. No clip keys change.
- `Archer/AnimationTree` settings:
  - `anim_player = ../AnimationPlayer`
  - `tree_root` = AnimationNodeStateMachine
  - `callback_mode_process = PHYSICS` (0)
  - `advance_expression_base_node = ".."`
  - `active` and `deterministic` left at their defaults (true)
- States: `idle` → AnimationNodeAnimation `idle`; `shoot` → `shoot`. There are no other states besides the built-in Start/End.
- Transitions, one per pair:
  - Start→idle: `advance_mode` AUTO
  - idle→shoot: ENABLED, IMMEDIATE, xfade 0
  - shoot→idle: AUTO, AT_END, xfade 0
- A startup cancel is `playback.start("idle")`, not a transition (§6).

## Step B: `archer.gd` + one line in `main.gd` (§5, rev. 1.1)
- New: `const DRAW_LEAD := 0.3` (§5.2). It goes in `archer.gd` because `tuning.gd` is out of scope. Also new: `shot_armed`, `locked_target`, and `_playback` read in `@onready`.
- `_physics_process` order:
  1. Movement and the cooldown decrement stay byte-for-byte as they are.
  2. If `shot_armed`:
     - If the locked target is freed, dead or outside the cone → `cancel_shot()` and return.
     - Otherwise, if `release_window` is true → `_fire_at(locked_target)`. The aim uses the target's position at that moment. `fired` is emitted as today, inside `_fire_at`. Then `fire_cooldown = FIRE_INTERVAL` and the flag and target are cleared.
     - Return either way.
  3. Otherwise, if `get_current_node() == "idle"`, `fire_cooldown <= DRAW_LEAD` and `nearest_target()` finds a target → lock it, set `shot_armed`, call `travel("shoot")`.
  - Because only an armed shot can be cancelled, a target that dies during active or recovery has no effect (§5.5).
- `cancel_shot()` clears `shot_armed` and the target and calls `_playback.start("idle")`. It never writes `release_window` (§5.4).
- A new `_in_cone()` helper reuses the same math as `nearest_target()`. `nearest_target()` itself stays untouched.
- `main.gd` `reset()` gets one line, `archer.cancel_shot()`, next to `archer.fire_cooldown = 0.0`.

## Step C: Scarecrow presenter (§1, rev. 1.4)
- New node `Scarecrow/WalkPresenter` (Node) with `godot/game/scarecrow_walk_presenter.gd`.
- In `_process` it picks `"hold" if parent.at_wall else "walk"` and calls `play()` only when that differs from the player's `assigned_animation`.
- It reads `at_wall` and writes nothing. The player stays on IDLE (§7, already the default). `scarecrow.gd` is not changed.

## Step D: `godot/tests/test_archer_state_machine.gd`, run at 60 fps (no audio)
The test drives the real `main.tscn`. It spawns scarecrows with `Game.spawn_scarecrow()`, as the pins do, and sends keys only through `Input.parse_input_event`. It never calls `travel`, `start` or `cancel_shot`.

| Assertion | Brief rule |
|---|---|
| `tree_root` is a state machine; its states are exactly idle and shoot, each pointing at a clip that exists in the library | §6 |
| Every state name in a `travel`/`start` call in `archer.gd` exists, and every `play()` name in the presenter exists in the scarecrow library (both read from the source text) | template, §6 |
| There are exactly 3 transitions with no duplicate pair, each with the `advance_mode`, `switch_mode` and `xfade_time` from the table above | §6 |
| `advance_expression_base_node == ".."` and it resolves to `Archer`; `anim_player` resolves to `Archer/AnimationPlayer`; `callback_mode_process == PHYSICS` | §6, §7 |
| `Archer/AnimationPlayer` has empty autoplay, and `current_animation == ""` and `is_playing()` is false for the **whole** run | §8 one authority |
| `get_current_node() == "idle"` after the first tick | §6 Start→idle |
| From the first tick `shot_armed` is true (the travel) to `fired` is exactly 18 ticks. `release_window` reads false two ticks before the shot and true one tick before; `fired` comes on the tick of the first true read; `shot_armed` is false after | §5.1, §5.2, §4, §12 #3 |
| Back-to-back `fired` gaps are exactly 36 ticks | §5.2 |
| Each later draw starts on the tick the cooldown first reaches ≤ 0.3 s, checked on the tick before, the tick of and the tick after | §5.2, §10 |
| Every `fired` arrives while `get_current_node() == "shoot"` | §6, §7 |
| A scarecrow's `current_animation` is `walk` while walking and `hold` when `at_wall` turns true; after that `assigned_animation == "hold"` and `Sprite.frame == 0` | §1 |
| **Recommended extra 1:** D is held during startup so the target leaves the cone. Then: no `fired`, the state is idle on the next tick, the archer still moves 7 px per tick, and the cooldown continues | §5.5 |
| **Recommended extra 2:** the run is lost mid-startup, then R is pressed. Then: `shot_armed` is false, the target is null, the state is idle, and no late arrow appears. The setup's precondition is checked too, so the scenario cannot pass without actually ending mid-startup | §5.4, §5.5, rev. 1.1 |

After that I run every existing test at the fps CLAUDE.md gives, and the pins at 60. I list every FAIL line and say whether §5.2 or §5.6 predicted it. I edit no test.

## Points you should decide on or know about
1. **"No new target taken" after a startup cancel (§5.5) is ambiguous.** I read it as: the cancelled shot is never redirected to another target, and nothing is drawn on the tick of the cancel. From the next tick the normal draw rule applies, so another scarecrow already in the cone can start a new draw at once. If you meant "no draw at all until …", tell me until what.
2. **`hold` loses its `current_animation`.** `hold` is a 0.125 s `LOOP_NONE` clip, so `current_animation` becomes `""` after it ends. That's why the presenter compares against `assigned_animation`, and why the test reads `current_animation` only in that first window. The alternatives would be making `hold` loop or calling `play()` every frame. The first changes a clip, and you've ruled that out.
3. **The archer's route is an AnimationTree.** Its current clip is read with `playback.get_current_node()`. Its `AnimationPlayer.current_animation` stays `""` on purpose, and that's what the authority row asserts.
4. **The 36-tick cadence depends on float rounding.** The cooldown must reach ≤ 0.3 on exactly tick 18 after a release. Your probe found float drift downwards (0.26666666666666644 at tick 20), so I expect 36. The test measures it rather than assuming it.
5. **These §10 edge tests are not in this test:** pause, and game end in each of the three phases; target lost or restart during active and recovery. I'd leave them for the edge-test step unless you want them now.

## Only a human can check these
- That startup, active and recovery read as distinct motions (§11 strip, and in play).
- That the walk loops with no visible catch, and that walk and hold look different at the wall.
- That clip frame 0 looks like the idle pose.
- The §11 strip frame numbers.

A headless run draws nothing, so all the test can prove is which state is active, the key values and the tick each event happens on.

I'd implement A → B → C → D one approval at a time, with a diff after each. Which step should I start with, and how do you want points 1 and 5 handled?