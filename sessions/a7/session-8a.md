I wrote the walk preview and checked it headless. The scarecrow's screen origin is **(640.000, 360.000) on all 90 lines**. At `--fixed-fps 30` each cycle is 15 movie frames: **cell 0 gets 3 frames and cells 1, 2 and 3 get 4 each**. The exception is the very first cell 0, which gets 5 (explained below). The game is unchanged: the walk read-back passes 68/68 and `test_pins_a7` passes 38/0. Nothing is committed.

## Files (both new)
- **`godot/previews/walk_preview.tscn`** contains:
  - the real `Background` (`game/background.gd`);
  - one instance of `game/scarecrow.tscn` placed once in the scene file at (640, 200);
  - a `Camera2D` with zoom 1, centre anchor and no smoothing.

  The scarecrow stops at y = 530 at 45 px/s, so it walks for 7.33 s before `at_wall` turns true.
- **`godot/previews/walk_preview.gd`** moves only its own camera. In `_process` it sets the camera to the scarecrow's global position and calls `force_update_scroll()`, then prints. The scarecrow only moves in `_physics_process`, and both 60 Hz ticks of a movie frame run before `_process`.
  - The preview's `process_priority` is set to 1000, so it runs after the AnimationPlayer's IDLE advance, the WalkPresenter and the camera's own update. Each line therefore shows the frame that gets drawn.
  - It never writes scarecrow, sprite, player or clip state, and never calls `play()`.

## Headless run, frames 1–40
`frames_drawn` stays 0 because headless draws nothing. The third column, `pframe`, is the frame number.
```
frames_drawn | tick | pframe | global_pos | screen_origin | sprite_frame | animation | anim_pos | at_wall
0 | 3 | 1 | (640.000, 202.250) | (640.000, 360.000) | 0 | walk | 0.0000 | false
0 | 5 | 2 | (640.000, 203.750) | (640.000, 360.000) | 0 | walk | 0.0417 | false
0 | 7 | 3 | (640.000, 205.250) | (640.000, 360.000) | 0 | walk | 0.0708 | false
0 | 9 | 4 | (640.000, 206.750) | (640.000, 360.000) | 0 | walk | 0.1008 | false
0 | 11 | 5 | (640.000, 208.250) | (640.000, 360.000) | 1 | walk | 0.1333 | false
0 | 13 | 6 | (640.000, 209.750) | (640.000, 360.000) | 1 | walk | 0.1667 | false
0 | 15 | 7 | (640.000, 211.250) | (640.000, 360.000) | 1 | walk | 0.2000 | false
0 | 17 | 8 | (640.000, 212.750) | (640.000, 360.000) | 1 | walk | 0.2333 | false
0 | 19 | 9 | (640.000, 214.250) | (640.000, 360.000) | 2 | walk | 0.2667 | false
0 | 21 | 10 | (640.000, 215.750) | (640.000, 360.000) | 2 | walk | 0.3000 | false
0 | 23 | 11 | (640.000, 217.250) | (640.000, 360.000) | 2 | walk | 0.3333 | false
0 | 25 | 12 | (640.000, 218.750) | (640.000, 360.000) | 2 | walk | 0.3667 | false
0 | 27 | 13 | (640.000, 220.250) | (640.000, 360.000) | 3 | walk | 0.4000 | false
0 | 29 | 14 | (640.000, 221.750) | (640.000, 360.000) | 3 | walk | 0.4333 | false
0 | 31 | 15 | (640.000, 223.250) | (640.000, 360.000) | 3 | walk | 0.4667 | false
0 | 33 | 16 | (640.000, 224.750) | (640.000, 360.000) | 3 | walk | 0.5000 | false
0 | 35 | 17 | (640.000, 226.250) | (640.000, 360.000) | 0 | walk | 0.0333 | false
0 | 37 | 18 | (640.000, 227.750) | (640.000, 360.000) | 0 | walk | 0.0667 | false
0 | 39 | 19 | (640.000, 229.250) | (640.000, 360.000) | 0 | walk | 0.1000 | false
0 | 41 | 20 | (640.000, 230.750) | (640.000, 360.000) | 1 | walk | 0.1333 | false
0 | 43 | 21 | (640.000, 232.250) | (640.000, 360.000) | 1 | walk | 0.1667 | false
0 | 45 | 22 | (640.000, 233.750) | (640.000, 360.000) | 1 | walk | 0.2000 | false
0 | 47 | 23 | (640.000, 235.250) | (640.000, 360.000) | 1 | walk | 0.2333 | false
0 | 49 | 24 | (640.000, 236.750) | (640.000, 360.000) | 2 | walk | 0.2667 | false
0 | 51 | 25 | (640.000, 238.250) | (640.000, 360.000) | 2 | walk | 0.3000 | false
0 | 53 | 26 | (640.000, 239.750) | (640.000, 360.000) | 2 | walk | 0.3333 | false
0 | 55 | 27 | (640.000, 241.250) | (640.000, 360.000) | 2 | walk | 0.3667 | false
0 | 57 | 28 | (640.000, 242.750) | (640.000, 360.000) | 3 | walk | 0.4000 | false
0 | 59 | 29 | (640.000, 244.250) | (640.000, 360.000) | 3 | walk | 0.4333 | false
0 | 61 | 30 | (640.000, 245.750) | (640.000, 360.000) | 3 | walk | 0.4667 | false
0 | 63 | 31 | (640.000, 247.250) | (640.000, 360.000) | 3 | walk | 0.5000 | false
0 | 65 | 32 | (640.000, 248.750) | (640.000, 360.000) | 0 | walk | 0.0333 | false
0 | 67 | 33 | (640.000, 250.250) | (640.000, 360.000) | 0 | walk | 0.0667 | false
0 | 69 | 34 | (640.000, 251.750) | (640.000, 360.000) | 0 | walk | 0.1000 | false
0 | 71 | 35 | (640.000, 253.250) | (640.000, 360.000) | 1 | walk | 0.1333 | false
0 | 73 | 36 | (640.000, 254.750) | (640.000, 360.000) | 1 | walk | 0.1667 | false
0 | 75 | 37 | (640.000, 255.250) | (640.000, 360.000) | 1 | walk | 0.2000 | false
0 | 77 | 38 | (640.000, 257.750) | (640.000, 360.000) | 1 | walk | 0.2333 | false
0 | 79 | 39 | (640.000, 259.250) | (640.000, 360.000) | 2 | walk | 0.2667 | false
0 | 81 | 40 | (640.000, 260.750) | (640.000, 360.000) | 2 | walk | 0.3000 | false
```
Frame 0, not shown above, is tick 1, y 200.750, cell 0, position 0.0000. Every line runs exactly 2 physics ticks after the one before, and y rises 1.5 px per frame.

## Which cell is on which frame
| Cycle | Cell 0 | Cell 1 | Cell 2 | Cell 3 |
|---|---|---|---|---|
| 1 | 0–4 (**5**) | 5–8 (4) | 9–12 (4) | 13–16 (4) |
| 2 | 17–19 (**3**) | 20–23 (4) | 24–27 (4) | 28–31 (4) |
| 3 and after | 32–34 (3) | 35–38 (4) | … | … |

- **Cell 0 gets 3 frames and cells 1–3 get 4.** That totals 15 frames, exactly 0.5 s per cycle, and the pattern repeats the same way every cycle through frame 89. The reason is that the clip position falls on multiples of 1/30 s:
  - Cell 0 shows at positions 0.0333, 0.0667 and 0.1000.
  - The wrap lands on 0.5000, which shows cell 3, so position 0 never appears again after the start.
- **Only cycle 1's cell 0 gets 5 frames.** The startup steps are uneven: the position goes 0, 0, 0.0417, 0.0708, 0.1008. From frame 5 onwards it settles on exact 1/30 s steps.
- **For the strip:** take cycles from frame 17 onwards. Cycle 1 is a startup artefact.

## Screen origin
It is the same on every line, all 90 of them. The camera holds the scarecrow at the screen centre, and the background scrolls by 1.5 px per frame.

One thing to know before capturing: the level is only 720 px tall. With the scarecrow held at screen y 360, the view runs past the level's top edge early in the walk. Its top 160 px start out as clear colour and shrink as the walk goes on. This doesn't affect the cells, but it will show in a windowed strip. Also, this proof comes from a headless run. A windowed Movie Maker capture should show the same thing, but that is for you to confirm when you run it.

## Game unchanged
- `godot --headless --path godot --import` completed with no errors.
- `./scripts/run-test.sh test_scarecrow_walk_readback.gd 60` gives `RESULT PASS (0 failures)`, with 68 `PASS` lines in `logs/test_scarecrow_walk_readback_60fps.log`.
- `./scripts/run-test.sh test_pins_a7.gd 60` gives `RESULT test_pins_a7: 38 passed, 0 failed`.

`git status` shows only the new `walk_preview.gd`, `walk_preview.gd.uid`, `walk_preview.tscn` and the two session files that were already there.