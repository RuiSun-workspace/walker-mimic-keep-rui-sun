The bow's frame-8 key is now −16°, and the read-back test pins it. All three tests pass, and the headless preview's angles match my predictions exactly. Nothing is committed. I'm stopping here so you can recapture and play.

## Test counts

| Command | Result |
|---|---|
| `./scripts/run-test.sh test_archer_shot_readback.gd 60` | `RESULT PASS: 166 passed, 0 failed` (the new check: `PASS shoot Rig/BowPivot:rotation at frame 8 == deg_to_rad(-16.0) (got -0.27925268)`) |
| `./scripts/run-test.sh test_archer_state_machine.gd 60` | `RESULT test_archer_state_machine: 107 passed, 0 failed` |
| `./scripts/run-test.sh test_pins_a7.gd 60` | `RESULT test_pins_a7: 38 passed, 0 failed` |

I ran the last two with `| tail -3`, which hides the script's exit code. To make up for that, I checked all three logs for the lines `run-test.sh` fails on (`SCRIPT ERROR`, `SHADER ERROR`, `Failed loading resource`): there are none.

## Preview, strip frames 9–25

A headless run draws nothing, so the first field (`frames_drawn`) prints 0 on every line. The rows below are matched by `pframe`, which is the same as the strip frame number in r0.

| pframe | clip | node | play_pos | release_window | predicted rot | **logged rot** | other columns vs r0 |
|---|---|---|---|---|---|---|---|
| 9 | — | idle | 0.0333 | false | 0.00 | **0.00** | same |
| 10 | 0 | shoot | 0.0000 | false | 0.00 | **0.00** | same |
| 11 | 1 | shoot | 0.0333 | false | −0.25 | **−0.25** | same |
| 12 | 2 | shoot | 0.0667 | false | −1.00 | **−1.00** | same |
| 13 | 3 | shoot | 0.1000 | false | −2.25 | **−2.25** | same |
| 14 | 4 | shoot | 0.1333 | false | −4.00 | **−4.00** | same |
| 15 | 5 | shoot | 0.1667 | false | −6.25 | **−6.25** | same |
| 16 | 6 | shoot | 0.2000 | false | −9.00 | **−9.00** | same |
| 17 | 7 | shoot | 0.2333 | false | −12.25 | **−12.25** | same |
| 18 | 8 | shoot | 0.2667 | **true** | −16.00 | **−16.00** | same: pivot (11.50, −1.00), string (5.00, 0) / 1.100 |
| 19 | 9 | shoot | 0.3000 | false | 2.00 | **2.00** | same: `fired@tick38`, arrows 1 |
| 20 | 10 | shoot | 0.3333 | false | 1.39 | **1.39** | same |
| 21 | 11 | shoot | 0.3667 | false | 0.89 | **0.89** | same |
| 22 | 12 | shoot | 0.4000 | false | 0.50 | **0.50** | same |
| 23 | 13 | shoot | 0.4333 | false | 0.22 | **0.22** | same |
| 24 | 14 | shoot | 0.4667 | false | 0.06 | **0.06** | same |
| 25 | 15 | idle | 0.0000 | false | 0.00 | **0.00** | same |

The pivot position, string position and scale, `shot_armed`, the arrow count and the fired tick are all identical to r0. Only `pivot_rot_deg` changed, and only in clip frames 1–8.

## git diff

```diff
--- a/godot/game/archer.tscn
+++ b/godot/game/archer.tscn
@@ -84,7 +84,7 @@ tracks/0/keys = {
 "times": PackedFloat32Array(0, 0.26666668, 0.3, 0.5),
 "transitions": PackedFloat32Array(2, 1, 0.5, 1),
 "update": 0,
-"values": [0.0, -0.13962634, 0.034906585, 0.0]
+"values": [0.0, -0.27925268, 0.034906585, 0.0]
 }
```

```diff
--- a/godot/tests/test_archer_shot_readback.gd
+++ b/godot/tests/test_archer_shot_readback.gd
@@ -147,6 +147,13 @@ func _init() -> void:
 			_check(not _approx(shoot.track_get_key_value(t, 1), shoot.track_get_key_value(t, 0)),
 				"shoot %s: frame 8 differs from rest" % path)
 
+	# Pins the Step 7 tuning (TUNING.md, A7 r1): the bow's full-draw rotation at frame 8 is -16 deg.
+	var bow_rt := shoot.find_track(NodePath("Rig/BowPivot:rotation"), Animation.TYPE_VALUE)
+	_check(bow_rt >= 0 and shoot.track_get_key_count(bow_rt) > 1
+		and absf(float(shoot.track_get_key_value(bow_rt, 1)) - deg_to_rad(-16.0)) < VALUE_TOL,
+		"shoot Rig/BowPivot:rotation at frame 8 == deg_to_rad(-16.0) (got %s)"
+		% (shoot.track_get_key_value(bow_rt, 1) if bow_rt >= 0 and shoot.track_get_key_count(bow_rt) > 1 else "no key"))
+
 	# ---- shoot: release_window ----
```

The headless run checks the numbers but can't show how the frames look. In your recapture, strip 18 should show the stave clearly leaning, with its top crossing the hood's right edge by about 2–3 px. Strip 19 should show an 18° snap back to almost upright.