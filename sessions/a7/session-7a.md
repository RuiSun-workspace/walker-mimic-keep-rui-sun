I've written `godot/previews/shoot_preview.tscn` and `godot/previews/shoot_preview.gd`. Driven only by `archer.gd`'s own rule, the draw starts on frame 10, the arrow appears on frame 19 and the archer is back in idle on frame 25. Both test suites still pass (107/0 and 38/0). Two things differ from what you asked for: an extra frame-number column, and when the target is removed (both below).

**What the preview does.** It shows the real background, and the real `archer.tscn` at (640, 572) with `arrows_parent` set to its own `World/Arrows`. The preview only places and removes its own scarecrow, connects to `fired`, and reads values. It never calls `travel()`, `start()` or `cancel_shot()` and never writes archer, tree or clip state.

**Trigger.** One scarecrow is placed at (640, 420) on physics tick 20. The preview's root runs before the archer within a tick, so `archer.gd` calls `travel("shoot")` on that same tick. I picked tick 20 rather than 21, the other tick of frame 10, because then every rendered frame falls exactly on a 1/30 s key of the clip, so strip frame 10+k shows clip frame k.

Measured landings with `--fixed-fps 30`:

| Event | Frame (tick) |
|---|---|
| Draw starts (shot_armed true, clip frame 0) | **10** (tick 20) |
| `release_window` true, full draw pose (clip frame 8) | **18** (tick 37) |
| Arrow spawns, `fired` (pose already clip frame 9, `release_window` false) | **19** (tick 38) |
| Back in idle (clip end, frame 15) | **25** (tick 51) |
| Repeat: target placed again, draw starts | tick 112, frame **56** |

**Decision for you: the arrow shows one strip frame late.** The tree writes `release_window` true on tick 37, but `archer.gd` reads it on tick 38, which is in frame 19. So in the strip, frame 18 shows the full draw with no arrow, and frame 19 shows the first recovery pose with the arrow just leaving. §11's row for clip frame 8 says the arrow should leave on that frame. This is the 1-tick read delay that brief §5.2 already accounts for, and fixing it would mean changing game files, which this step doesn't allow. Triggering on tick 21 instead puts the arrow on frame 19 together with an in-between pose that isn't on a key. So the §11 row's wording needs your call.

**Deviations from your spec:**
1. **Frame number.** Headless, `Engine.get_frames_drawn()` stays at **0** because nothing is drawn. I kept it as the first field and added `pframe`, a count of `_process` calls from 0, as the second. Frame n holds ticks 2n and 2n+1. I couldn't check headless that `get_frames_drawn()` equals `pframe` in a windowed Movie Maker run.
2. **Target removed before the 1 s wait, not after.** If the target stays in the cone, `archer.gd` starts the next draw 18 ticks after the release (§5.2), so you'd get back-to-back shots instead of one. The preview therefore removes the target as soon as the tree is idle and no arrow is left (tick 52). It then waits 60 ticks with nothing on the field and places a new one on a tick of the same parity as tick 20, so each repeat lines up with frames the same way.

**Frames 8–28** from `godot --headless --path godot res://previews/shoot_preview.tscn --fixed-fps 30 --quit-after 90`. Header: `frames_drawn | pframe | tick | node | play_pos | release_window | shot_armed | pivot_rot_deg | pivot_pos | string_pos | string_scale | arrows | fired`
```
0 | 8 | 17 | idle | 0.0333 | false | false | 0.00 | (12.50, -4.00) | (2.00, 0.00) | (1.000, 1.000) | 0 | -
0 | 9 | 19 | idle | 0.0333 | false | false | 0.00 | (12.50, -4.00) | (2.00, 0.00) | (1.000, 1.000) | 0 | -
tick 20: target placed at (640.0, 420.0)
0 | 10 | 21 | shoot | 0.0000 | false | true | 0.00 | (12.50, -4.00) | (2.00, 0.00) | (1.000, 1.000) | 0 | -
0 | 11 | 23 | shoot | 0.0333 | false | true | -0.12 | (12.48, -3.95) | (2.05, 0.00) | (1.000, 1.002) | 0 | -
0 | 12 | 25 | shoot | 0.0667 | false | true | -0.50 | (12.44, -3.81) | (2.19, 0.00) | (1.000, 1.006) | 0 | -
0 | 13 | 27 | shoot | 0.1000 | false | true | -1.13 | (12.36, -3.58) | (2.42, 0.00) | (1.000, 1.014) | 0 | -
0 | 14 | 29 | shoot | 0.1333 | false | true | -2.00 | (12.25, -3.25) | (2.75, 0.00) | (1.000, 1.025) | 0 | -
0 | 15 | 31 | shoot | 0.1667 | false | true | -3.13 | (12.11, -2.83) | (3.17, 0.00) | (1.000, 1.039) | 0 | -
0 | 16 | 33 | shoot | 0.2000 | false | true | -4.50 | (11.94, -2.31) | (3.69, 0.00) | (1.000, 1.056) | 0 | -
0 | 17 | 35 | shoot | 0.2333 | false | true | -6.12 | (11.73, -1.70) | (4.30, 0.00) | (1.000, 1.077) | 0 | -
0 | 18 | 37 | shoot | 0.2667 | true | true | -8.00 | (11.50, -1.00) | (5.00, 0.00) | (1.000, 1.100) | 0 | -
0 | 19 | 39 | shoot | 0.3000 | false | false | 2.00 | (12.50, -5.00) | (1.00, 0.00) | (1.000, 1.000) | 1 | fired@tick38
0 | 20 | 41 | shoot | 0.3333 | false | false | 1.39 | (12.50, -4.69) | (1.31, 0.00) | (1.000, 1.000) | 1 | -
0 | 21 | 43 | shoot | 0.3667 | false | false | 0.89 | (12.50, -4.44) | (1.56, 0.00) | (1.000, 1.000) | 1 | -
0 | 22 | 45 | shoot | 0.4000 | false | false | 0.50 | (12.50, -4.25) | (1.75, 0.00) | (1.000, 1.000) | 0 | -
0 | 23 | 47 | shoot | 0.4333 | false | false | 0.22 | (12.50, -4.11) | (1.89, 0.00) | (1.000, 1.000) | 0 | -
0 | 24 | 49 | shoot | 0.4667 | false | false | 0.06 | (12.50, -4.03) | (1.97, 0.00) | (1.000, 1.000) | 0 | -
0 | 25 | 51 | idle | 0.0000 | false | false | 0.00 | (12.50, -4.00) | (2.00, 0.00) | (1.000, 1.000) | 0 | -
tick 52: shot finished, target removed
0 | 26 | 53 | idle | 0.0167 | false | false | 0.00 | (12.50, -4.00) | (2.00, 0.00) | (1.000, 1.000) | 0 | -
0 | 27 | 55 | idle | 0.0333 | false | false | 0.00 | (12.50, -4.00) | (2.00, 0.00) | (1.000, 1.000) | 0 | -
0 | 28 | 57 | idle | 0.0333 | false | false | 0.00 | (12.50, -4.00) | (2.00, 0.00) | (1.000, 1.000) | 0 | -
```
The second shot (frames 56–71) repeats this exactly. The arrow hits the target and is gone by frame 22.

**Checks:**
- `godot --headless --path godot --import` finished.
- `./scripts/run-test.sh test_archer_state_machine.gd 60` → `RESULT test_archer_state_machine: 107 passed, 0 failed`
- `./scripts/run-test.sh test_pins_a7.gd 60` → `RESULT test_pins_a7: 38 passed, 0 failed`

`git status` shows only the new `shoot_preview.gd`, `shoot_preview.gd.uid` (Godot made it on import) and `shoot_preview.tscn`, plus the two session files that were already there. No game file, scene, clip, test or shader changed, and nothing is committed.