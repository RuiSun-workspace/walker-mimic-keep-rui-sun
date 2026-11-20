# CHANGE-BRIEF — Assignment 7: Doing Animation

**Author:** Rui Sun  
**Course:** CSYE 7270, Fall 2026  
**Project:** Mimic Keep  
**Engine:** Godot 4.7.2 (`4.7.2.stable.official.ed1daf0bf`)  
**Renderer:** Forward+

The Assignment 6 version of this brief is preserved at tag a6. This is the original Assignment 7
brief, dated 2026-11-19. If the design changes after implementation begins, each revision is added
under "Revisions" with its date instead of replacing the earlier decision.

**How this brief was written.** The content is Rui's: every decision, number, prediction and answer
comes from Rui's answers in `prompts/a7/brief-questions-zh.md` (Chinese, committed alongside).
Claude Code translated those answers into English and laid them out in this structure
(`prompts/a7/brief-skeleton.md`). Claude also reviewed the answers twice; the changes Rui accepted
from those reviews are listed at the end of the questionnaire, and the concept notes Claude gave for
the starred questions are in `prompts/a7/brief-star-hints-zh.md`. The remaining items (§1 Why ×2,
§4 recovery, §5 release guard, §11, §12, §13 Q5) were written by Rui directly in English on
2026-11-19, using suggestions Claude gave in chat; those suggestions are recorded at the end of
`prompts/a7/brief-star-hints-zh.md`. The two probe scripts cited below are in `prompts/a7/probes/`.

## 1. The two clips

### Clip 1 — Scarecrow walk (the cycle)

- **What it communicates, and why the player needs it:** it tells the player that this scarecrow is
  still advancing on the wall, so it is the threat to deal with first. When it stops at the wall and
  no longer walks, I can see at a glance that it has started attacking the gate.
- **Plays on:** every scarecrow, `godot/game/scarecrow.tscn` (root `Scarecrow`, child `Sprite`,
  Sprite2D).
- **Route:** Sprite2D with an AnimationPlayer frame track. **Why:** the scarecrow has no separately
  articulated parts: its four-frame hop and lean move the whole body, so drawing each complete pose
  gives direct pixel control without adding a rig that this short 8 fps cycle does not need.
- **The walk:** the scarecrow has no legs, so it hops on its pole, with a slight lean left and right
  (§2 frame order).
- **Authority:** the scarecrow's own `AnimationPlayer` is the only writer of `Sprite.frame`. A
  presentation-only script on a new child node of `Scarecrow` (the root already carries
  `scarecrow.gd`) reads `at_wall` (`godot/game/scarecrow.gd:18`) and calls `play("walk")` while it
  is false and `play("hold")` once it is true. `hold` is a one-key clip on frame 0, so "still
  advancing" and "already hitting the gate" look different, and the script never writes
  `Sprite.frame` itself. `scarecrow.gd`, which owns the game rules, is not changed. A dead
  scarecrow is freed at once (`scarecrow.gd`, `_check_death`), so there is no death pose.
- **Cycle or committing:** the cycle.

### Clip 2 — Archer shot (the committing action)

- **What it communicates, and why the player needs it:** the draw announces that the archer is
  about to shoot at a target, the release confirms the arrow is away, and the recovery says this
  shot is over. Firing is automatic, so the player needs this motion to judge when the next arrow
  comes and in which direction.
- **Plays on:** the archer, `godot/game/archer.tscn` (today: root `Archer` Node2D + one `Sprite`
  Sprite2D with the whole 44×60 `archer.png`).
- **Route:** a 2D cutout rig keyed as resource text. **Why:** the bow angle and string length change
  throughout the 15-frame shot, so a rig can interpolate between a few phase-boundary keys and can
  be retimed by moving those keys instead of redrawing a 15-cell sheet.
- **The rig:** body (stays steady) + bow (rotates about the grip as its pivot and pulls back) +
  string (stretches as the bow is drawn). Keyed on rotation and position.
- **Authority:** the archer's `AnimationTree` (AnimationNodeStateMachine), child of `Archer`. It plays
  the clips through its `AnimationPlayer`, which never plays on its own: no `play()` call and no
  autoplay.
- **Cycle or committing:** the committing action.

## 2. The sheet (scarecrow walk)

- **Source:** written by code in `godot/tools/make_sprites.gd`, following the project's existing
  source record. Claude Code writes the code under Rui's direction. No downloaded or
  model-generated art, no third-party licence.
- **Author / licence / date checked:** Rui Sun (directing) and Claude Code (code); no third-party
  licence; 2026-11-19. Recorded in `SOURCES.md` in the "Art and meshes written by code" table, like
  the existing sprites.
- **Cell size:** 64×80 px. Today's single frame is 56×72 (`make_sprites.gd:43`) with only about
  1 px to spare on each side, which cannot hold the hop and the lean. The scarecrow's original centre
  stays at the centre of the cell, so its position in the game does not change.
- **Grid:** `hframes` = 4, `vframes` = 1. Sheet size = 256×80.
- **Frame order:**
  - 0 = pole foot on the ground, standing straight; y offset 0.
  - 1 = leaning left, whole body up 3 px; y offset −3.
  - 2 = back to straight, pressed down 1 px; y offset +1.
  - 3 = leaning right, whole body up 3 px; y offset −3.
  - Then back to 0.
  - The lean in frames 1 and 3 is a 5° rotation about the pole foot. The straw tufts move about
    4 px sideways and the hat top about 6 px, which leaves about 1 px to each side in a 64-px cell.
- **Original file:** a new file, `godot/assets/sprites/scarecrow_walk.png`, committed together with
  the generator code. The existing `scarecrow.png` is not changed: the two A6 preview scenes and
  `godot/tools/capture_burn_values.gd` load it directly.
- **Registration:** the pole foot. Its x is exactly the same in all four cells. Its y may differ only
  by the offsets in the frame order (0, −3, +1, −3 px), with no other drift.

## 3. The cycle spec (scarecrow walk)

| Item | Value |
|---|---|
| Frame count | 4 |
| Frame rate | 8 fps |
| `Animation.step` | 0.125 s (= 1 / frame rate) |
| Clip length | 0.5 s |
| Loop mode | `Animation.LOOP_LINEAR` |
| Track | value track on `Sprite:frame`, `Animation.UPDATE_DISCRETE` |
| Key times | 0, 0.125, 0.25, 0.375 s → frames 0, 1, 2, 3 |

**Seam rule (frame track):** frame 0 is not keyed again at the end. The keys are at 0, 0.125, 0.25
and 0.375 s and the clip is 0.5 s long, so the gap from the last key to the end is still 0.125 s.

**What a duplicated frame at the wrap would look like in play:** frame 0 would stay on screen twice
as long at the seam, and the hop would catch once every cycle. One cycle is 0.5 s, so it would
catch twice a second.

## 4. The phase table (archer shot)

Frame rate: 30 fps. `Animation.step` = 1/30 s (one frame period). Clip length 15 frames = 0.5 s.

| Phase | Frames | Begins on frame (time) | What the player may do | What the game reads |
|---|---|---|---|---|
| Startup (draw) | 8 | 0 (0 s) | Move left and right; movement does not interrupt | The locked target. If it dies or leaves the cone, the shot is cancelled (§5) |
| Active (release) | 1 | 8 (0.2667 s) | Move; does not interrupt | `release_window` is keyed true on this frame; the arrow spawns on the first physics tick the archer reads it true |
| Recovery | 6 | 9 (0.3 s) | Move; does not interrupt | `release_window` is keyed false on this frame; nothing else |

**Reference:** "Recurve Bow Super Slow Motion Archery - Shooting Arrows at Different Speeds",
https://www.youtube.com/watch?v=wwbc7yBwDBs. The description says it was filmed at 60 fps. I counted
only the real-speed shot at the start of the video, about 0:00–0:03, not the slow-motion replays
after it. Frame by frame I counted about:

- 52 frames from the start of the draw to the last frame before the string is loosed;
- 2 frames for the loose, with the arrow leaving the bow;
- 28 frames for the arm coming down after the release.

The counted shot is at real speed, so nothing is divided by a slow-motion factor. At 30 fps that is
26, 1 and 14 frames. A real archer's motion is too long for the game and must be compressed. The
real draw converts to 26 frames; I compressed it to 8 so the automatic shot stays crisp and fits in
the 0.6 s interval. The recovery has a hard maximum of 8 frames because the next draw begins 18
ticks (0.3 s) after release; I chose 6 so about 2 frames of readable idle remain between shots. A
2–3-frame recovery would snap back unnaturally, so I compressed the recovery less severely than the
draw and kept enough follow-through for the player to see that the shot has ended.

## 5. The gameplay change: the arrow waits for the active frame

Today (`godot/game/archer.gd:14-24`) the archer fires in the same physics tick that `fire_cooldown`
reaches 0 with a target in the cone, and resets the cooldown to `FIRE_INTERVAL` = 0.6 s
(`godot/game/tuning.gd:10`). This is the one change to game behaviour this brief allows:

1. **The arrow is released on the first active frame**, not the moment the cooldown ends.
2. **The draw starts early.** It starts when the archer is idle, a target is in the cone, and
   `fire_cooldown` is at most **0.3 s (18 physics ticks)**. The cooldown still resets to
   `FIRE_INTERVAL` when the arrow spawns, as today. Back-to-back shots therefore keep the 0.6 s
   cadence (36 ticks). Only a first shot, where the cooldown was already 0 when a target appeared,
   is released later than today, by 0.3 s.
   - Why 0.3 s and not the 0.2667 s startup length: a probe in Godot 4.7.2
     (`prompts/a7/probes/probe_tick_order.gd`) measured 18 physics ticks from `travel("shoot")` to
     the archer reading the key at 8/30 s.
     - 1 tick: the newly entered state stays at position 0 for its first update.
     - 1 tick: within one physics tick the parent (`Archer`) runs before its child AnimationTree, so
       the value the tree writes is read on the next tick. Changing the tree's `process_priority` or
       `process_physics_priority` did not change this order.
   - With a 0.2667 s threshold the cadence would be 38 ticks = 0.633 s.
3. **Target.** The target is locked when the draw starts: the nearest scarecrow in the cone, as
   today. At release the arrow is aimed at the locked target's position at that moment.
4. **Release guard.** `archer.gd` owns a `shot_armed` flag. It sets the flag true only when it starts
   a draw with `travel("shoot")`; an arrow may spawn only when both `shot_armed` and the AnimationTree's
   `release_window` are true. Firing, cancellation and restart clear the flag. Restart also clears
   the locked target and calls `playback.start("idle")`, but does not write `release_window`; therefore
   a stale true left from the frozen end tick is ignored until the idle clip keys it false.
5. **Interrupts, in each phase:**

   | Event | Startup | Active | Recovery |
   |---|---|---|---|
   | Locked target dies or leaves the cone | Cancel, return to idle at once, cooldown continues as normal, no new target taken | No effect: the arrow is already away | No effect: the recovery plays out |
   | Move left / right | Allowed, does not interrupt | Allowed, does not interrupt | Allowed, does not interrupt |
   | Pause (Esc / P) | Freezes on the current frame, resumes from it | Same | Same |
   | Game ends (win or lose): `World` is disabled (`godot/game/main.gd:95`) | Animation freezes, no arrow is released | Same | Same |
   | R / Enter after the game has ended mid-shot (restart is only possible after the end, `main.gd:82`) | Clear `shot_armed` and the locked target, then return the AnimationTree to idle at once; do not write `release_window`, and no arrow is fired late | Same | Same |

6. **Predicted changes to existing tests** (my prediction, written 2026-11-19 before the tick-order
   probe; kept as written):
   - The 8 startup frames at 30 fps are 0.267 s, about 16 physics ticks at 60 Hz.
   - `test_rules` and `test_wall_targeting` will still pass, because they leave enough waiting time
     for a hit. Only the first damage is 8 frames (0.267 s) later.
   - In `test_burning_tint` the sample index of the hit shifts by about 16 physics ticks. It checks
     the colour and the single shot from the real hit onward, so its conclusion should not change.
   - `test_impact_burst_state` records exact hit times. The absolute times 0.567 / 0.633 / 1.233 s
     will shift because the matching shots are 8 frames (0.267 s) later, and the related frame
     boundaries need re-pinning. Whether the three bursts overlap may stay the same.
   - In `test_burning_embers_state` the real arrow's fired/hit frames are also 8 frames (0.267 s)
     later. Most scenarios wait for a signal and then check "exactly one arrow", so I guess they
     still pass. The one most likely to break is the movement scenario with a fixed 120-physics-tick
     cap.

## 6. The state machine (archer, AnimationTree)

Driven by push: `archer.gd` decides when, and the tree only plays.

- `AnimationTree.advance_expression_base_node`: the `Archer` node (the tree's parent, path `..`).
  Push uses no expressions; it is stated so an expression added later cannot silently fail.
- `tree_root`: an `AnimationNodeStateMachine`.

| State | Clip it plays | Loops? |
|---|---|---|
| idle | `idle`: one key, the rest pose; `release_window` keyed false | no (`LOOP_NONE`) |
| shoot | `shoot`: the phase table in §4 | no |

| From → To | Condition | `advance_mode` | `switch_mode` | `xfade_time` |
|---|---|---|---|---|
| Start → idle | on start | Auto | Immediate | 0 |
| idle → shoot | `archer.gd` calls `travel("shoot")` when the draw starts (§5) | Enabled | Immediate | 0 |
| shoot → idle | the clip ends: a full shot returns by itself | Auto | At End | 0 |

**Cancel in startup is not a transition.** `archer.gd` calls `playback.start("idle")`, which jumps
to idle at once. `travel("idle")` would follow the shoot → idle At End transition and wait for the
end of the clip. A second shoot → idle transition cannot be added, because Godot 4.7.2 allows only
one transition per from → to pair.

**Known before prompt-1** (probes in `prompts/a7/probes/`, 2026-11-19):

- A second `add_transition("shoot", "idle")` fails with
  `Condition "transitions[i].from == p_from && transitions[i].to == p_to" is true`. Only one
  transition remains (`probe_duplicate_transition.gd`).
- `playback.start("idle")` takes effect in the same tick's tree update (`probe_tick_order.gd`).
- With Start → idle left on the default Enabled, the machine stays in `Start` until the first
  `travel()` (`probe_tick_order.gd`).
- `travel("shoot")` → the archer reads the 8/30 s key 18 ticks later (§5).
- Subtracting the cooldown tick by tick gives `0.26666666666666644` on tick 20, so the earlier
  prediction that it could remain just above 0.2667 s is false; the chosen threshold is 0.3 s in
  any case.

## 7. The two clocks

| Mixer | `callback_mode_process` | Why |
|---|---|---|
| Scarecrow `AnimationPlayer` | `ANIMATION_CALLBACK_MODE_PROCESS_IDLE` | Gameplay reads nothing from the walk |
| Archer `AnimationTree` | `ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS` | Same tick type as `archer.gd`'s `_physics_process`, which reads the release |
| Archer `AnimationPlayer` (under the tree) | not used to play | It never plays on its own (§8) |

- No `AnimatedSprite2D` is used in this project, so no node advances on a tick it cannot choose.
- Physics runs at 60 ticks per second: `godot/project.godot` sets no `physics_ticks_per_second`
  (the default). The archer moves and fires in `_physics_process` (`godot/game/archer.gd:14`).
- **The keyed gameplay fact:** the shoot clip keys the archer's `release_window` property. It is
  true on the first active frame and keyed back to false on the first recovery frame, and the idle
  clip keys it false. `archer.gd` reads it in `_physics_process` and spawns the arrow the first time
  it reads true.
- **Largest disagreement:** see answer 5 in §13.
- Method tracks are deferred, so none is used to make the clocks agree.

## 8. One authority

| Animated node / property | Its one authority | What else could write to it, and how that is prevented |
|---|---|---|
| `Scarecrow/Sprite` `frame` | the scarecrow's `AnimationPlayer` (`walk`, `hold`) | The presentation script only chooses which clip plays. `burning_tint.gd` (on the same Sprite, `:13`) writes the material's `burn_mix`, not `frame`. |
| Archer rig parts (rotation / position) | the archer's `AnimationTree`, through the clips its `AnimationPlayer` holds | No other script changes the rig parts directly. Nothing calls `play()` on the `AnimationPlayer`, and autoplay is off. Preview scripts only drive the state machine. |
| `Archer.release_window` | the archer's `AnimationTree` (keyed in `shoot` and `idle`) | `archer.gd` only reads it. On restart it clears its own `shot_armed` flag and locked target, then calls `playback.start("idle")`; it never writes `release_window`. The guard ignores any stale true until the idle clip keys the property false. |

## 9. Boundaries

**Unchanged:**
- collision, movement and input;
- existing test expectations, except as in §5;
- the Assignment 5 shaders in `godot/shaders/` and the Assignment 6 effects;
- `scarecrow.gd`'s rules and `scarecrow.png`;
- every other object;
- the generated sheet, once it is committed.

**Changed, and only this:** the rule in §5. The arrow is released on the first active frame; the
draw starts when `fire_cooldown` ≤ 0.3 s; a first shot is 0.3 s later than today; the cadence stays
at 36 ticks.

Presentation code may read game state; it never writes it.

## 10. The evidence split

| Rule | Checked by | How |
|---|---|---|
| Every track resolves to a real node and property | read-back | For both clips, and for `idle` and `hold` |
| Key times match §3 and §4 | read-back | Every key time against the tables |
| `step`, loop mode, discrete update, frame within the sheet | read-back | `step` 0.125 / (1/30); `LOOP_LINEAR` / `LOOP_NONE`; `UPDATE_DISCRETE`; frame < `hframes` × `vframes` |
| The tree has the states and transitions in §6 | structure test | Exactly one shoot → idle transition (Auto + At End); Start → idle Auto; `xfade_time` 0 |
| Existing behaviour holds except §5 | pins | Re-pinned only in their own step |
| Back-to-back releases keep the cadence | edge test | Two consecutive releases exactly 36 ticks apart |
| The draw-start threshold | edge test | The tick before, the tick of, and the tick after `fire_cooldown` reaches 0.3 s |
| The arrow spawns on the first active frame | edge test | The tick before, the tick of, and the tick after the first true read |
| Interrupts in each phase do what §5 says | edge tests | Target lost, movement, pause, game end, and restart in each of startup, active and recovery |
| The cycle wraps without a visible seam | read-back + my eyes in play | The last-key-to-end gap equals the key interval; I watch the walk loop |
| Startup, active and recovery read as distinct | frame strip + my eyes in play | §11 |
| No drift within the cells (registration) | PNG test + frame strip | A test reads the PNG: the pole-foot x is the same in each cell and y follows 0 / −3 / +1 / −3 |

## 11. The frame strip

- **Preview background:** the real level's meadow and wall walk around x ≈ 640, where the archer
  normally stands, kept at the real 1280×720 at 1:1.
- **Clip boundaries to read (at 30 fps):** the final frame-strip numbers will be filled in after
  the Step 2 boundary test pins the observed latency.

| Clip frame | Strip frame | Phase boundary | Should show |
|---|---|---|---|
| 0 | Fill after Step 2 pin | trigger | The pose still looks the same as idle on this first key; the bow and string first visibly move back on clip frame 1 |
| 8 | Fill after Step 2 pin | startup → active | The string is loosed and the arrow leaves the bow on this frame |
| 9 | Fill after Step 2 pin | active → recovery | The bow starts to come back; the log line for the same frame shows `release_window` = false |
| 15 (clip end, 0.5 s; first idle frame) | Fill after Step 2 pin | end of recovery | The recovery is done: body, bow and string are all back in the idle rest pose |

## 12. Predicted failures (at least three)

Numbered 1–4 here; in the questionnaire (E1) these are items 1, 2, 3 and 5. Its items 4 and 6 were
moved to "Known before prompt-1" in §6, because a probe or a calculation had already answered them.

| # | Failure | The check that would catch it |
|---|---|---|
| 1 | I think the most likely mistake is leaving the frame track on continuous, so the frame number jumps between keys. | The read-back checks that the track is `UPDATE_DISCRETE`. |
| 2 | The new sheet may be sliced with the wrong `hframes`, so the wrong cell is shown. | The read-back checks the grid and the frame range; then the frame strip. |
| 3 | If the AnimationTree and the archer script are not on the same tick, the arrow may be one frame late. | An edge test on the frame before, the frame of, and the frame after active. |
| 4 | The pole foot in the four walk cells may not follow 0, −3, +1, −3 px, so the walk shakes. | A test that reads the PNG and checks each cell's pole-foot x and the specified y offset, then the frame strip by eye. |

## 13. Answers

1. **Which route does each clip use, and what does that route's read-back see that the other
   route's does not?**
   - The scarecrow uses a Sprite2D + AnimationPlayer frame track. Its read-back sees the key times,
     frame numbers, discrete update, step and loop_mode. With AnimatedSprite2D + SpriteFrames
     instead, none of this would be in the AnimationPlayer, and this read-back would not see it.
   - The archer uses a 2D cutout rig keyed in resource text. Its read-back can verify each
     rotation/position track's node, property and key times. An imported 3D rig has to be checked
     separately by its Skeleton3D bone names; a plain property check cannot see whether a bone
     exists.
2. **If your frame track is left on continuous updates, what does the sprite show between two keys,
   and why?** It interpolates between two integer frame numbers and rounds, so it can change cell
   at a moment with no key. Going from 3 back to 0, it also sweeps backwards through 2 and 1. The
   interpolator treats `frame` only as a number; it does not know that each integer is a separate
   picture.
3. **What will `Animation.step` be, and what happens to your key times if you leave it at its
   default?** The walk clip's step is 0.125 s and the shot clip's is 1/30 s. If the walk were left
   at the default 1/30, 0.125 s is not a whole multiple of it, so inserting or dragging a key in the
   editor would snap to about 0.100 or 0.133 s and break the even 8 fps spacing. The shot is already
   30 fps, so it is not affected.
4. **Which node is the one authority over each animated node, and what else in your project could
   write to it?**
   - Scarecrow `Sprite.frame`: the scarecrow's own AnimationPlayer. The presentation script only
     decides whether walk plays or it holds frame 0. `burning_tint.gd` writes only `burn_mix` in
     the same Sprite's material, not `frame`.
   - Archer rig parts' rotation/position: the AnimationTree, through the clips its AnimationPlayer
     plays. The only writer of `release_window` is also the AnimationTree; `archer.gd` only reads it.
   - What is forbidden: other scripts changing the rig parts or `release_window` directly, calling
     `play()` on the AnimationPlayer, and turning on autoplay. The preview script only drives the
     state machine.
5. **Which tick does each clip advance on, and which tick does gameplay read the active window on?
   If they differ, what is the largest disagreement in seconds?**
   - The scarecrow walk advances on the IDLE/process tick, and gameplay does not read it.
   - The archer's shoot clip advances on the PHYSICS tick, and `archer.gd` also reads the active
     window in `_physics_process`, so by design there is no cross-clock disagreement. There is still
     one physics tick of ordering delay because the parent archer reads before the child tree writes;
     at 60 Hz this is 1/60 s, about 0.0167 s, and it is already included in the 0.3 s draw-start
     threshold.
   - If the tree were put on IDLE by mistake, the worst case would be one rendered frame, about
     0.0167 s at 60 fps.
6. **For your cycle: what is the seam rule for its track type, and what would a duplicated frame at
   the wrap look like in play?**
   - The discrete frame track does not repeat frame 0 at the end. Keys are at 0, 0.125, 0.25 and
     0.375 s and the clip is 0.5 s long, so the last key to the end is still 0.125 s.
   - If a looping transform track is added later, its end pose must also return smoothly to the
     start, without a jump. The shoot clip does not loop.
   - A duplicated frame at the seam would hold pose 0 twice as long every cycle, which looks like a
     catch every 0.5 s.
7. **If your rig is imported: where does loop mode have to live, and how will you prove it survived
   an empty import cache?**
   - My cutout rig and its keys are stored directly in `.tscn`/`.tres` resource text. A `.glb`
     re-import cannot overwrite them, so loop_mode lives in that resource too and needs no
     per-animation importer setting.
   - After `godot/.godot` is emptied, the PNG sheet is still re-imported. The mutation still checks
     that the scenes load from nothing, that no resource path is missing, that the grid imports
     correctly, and that the read-backs still pass on a fresh cache.

## Revisions

(none yet)
