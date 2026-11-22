**This pass was read-only. I haven't edited any files.** Sources: the five kept frames, the ×4 crop `captures/shoot/sheets/r0_boundaries_x4.png`, the matching lines of `logs/shoot_preview_r0.log`, and the keys in `godot/game/archer.tscn:84-123`.

## Where the motion and the phase table disagree

Scale matters here. The bow stave is 46 px tall with the grip at its centre, so each tip sits 23 px from the pivot. At −8° a tip moves sideways only 23·sin 8° ≈ 3 px. That's about one stave width at 1:1.

| Boundary | Strip / clip | Log | What the frame shows | Agrees with the table? |
|---|---|---|---|---|
| Trigger | 10 / 0 | `shoot 0.0000`, rot 0.00 | Same as strip 9 (idle) | Yes, as §11 says |
| Inside startup | 11–14 / 1–4 | rot −0.12, −0.50, −1.13, −2.00 | Frames not kept. The log shows tips move under 1 px by clip 4 | **No.** The frame-0 key's transition is 2 (ease-in, x²), so half the startup reaches only 25 % of the pose. The 8-frame draw reads as about 4 frames (clip 5–8, ≈0.13 s) |
| Startup → active | 18 / 8 | `release_window true`, rot −8.00, string +3 px / 110 % | Full draw. The tilt is visible at ×4 but only about 3 px at 1:1. No arrow yet | Pose matches. §11's "arrow leaves the bow on this frame" doesn't match: the arrow first shows on strip 19 (`fired@tick38`, between ticks 37 and 39). That comes from the 18-tick latency, and you said the arrow's moment is fine, so I won't touch it |
| Active → recovery | 19 / 9 | `release_window false`, rot **+2.00**, string 1 px | The bow is already upright, arrow in flight | **No.** The table says the bow *starts* to come back here. In fact the whole return (10°) happens in this one frame |
| Recovery | 20–24 / 10–14 | rot 1.39 → 0.06, pivot ≤ 1 px | Not kept. A 2° peak moves a tip about 0.8 px | **No.** The 6 recovery frames can't be told from idle at 1:1 |
| End | 25 / 15 | `idle`, all at rest | Same as strip 9 | Yes |

At normal speed the shot reads as roughly 0.13 s of idle-looking draw, a small lean, a snap, and then idle. That fits your note: the draw is small and the three phases run together.

## Proposed change (one key)

**Change the `Rig/BowPivot:rotation` key at clip frame 8 from −8° to −16°** (`-0.13962634` → `-0.27925268`). Times, transitions, the +2° kick, the pivot, the string and `release_window` all stay as they are.

- **Why this one:** your complaint was the size of the draw, and the bow's rotation moves the most pixels in this rig. Doubling it doubles the tip travel to about 6 px. It also makes the release snap 18° instead of 10°, which sharpens the startup → active → recovery boundary.
- **Why not more:** at −16° the stave's upper part crosses the hood's right edge by about 2–3 px, drawn over it. Going further would push it well into the head.
- **What it won't fix:** recovery (clip 9–14) will still look like idle, and clip 1–3 will still move under about 1 px. If the recapture shows that, the next single-change candidate is the +2° kick, the rotation key at clip frame 9.

## What the recapture should show

- **Log:** `pivot_rot_deg` for clip 1–8 should read −0.25, −1.00, −2.25, −4.00, −6.25, −9.00, −12.25, **−16.00**. Every other column should be identical to r0, including clip 9 at +2.00, the recovery values from 1.39 down to 0.06, `release_window` true only at strip 18, `fired@tick38` and idle at strip 25.
- **Strip 9, 10, 25:** pixel-identical to r0.
- **Strip 18:** the stave clearly leans. Its top is about 6 px left of rest and overlaps the hood's right edge, and its bottom is about 6 px right.
- **Strip 19:** a visible 18° snap back to almost upright, with the arrow out.

## The read-back test

`godot/tests/test_archer_shot_readback.gd` pins no pose values. For this key it only checks that frame 8 differs from rest (:147) and that the transition is above 1, so it passes before and after the change with nothing to update. I suggest adding one expected value: the rotation key at frame 8 equals `deg_to_rad(-16.0)` within `VALUE_TOL`. That way the read-back records the tuned key. It would be new, not a change to an existing check, so I'll add it only if you say so.

When you approve, I'll change that one value in `archer.tscn`, add the read-back pin if you want it, run `bash scripts/run-test.sh test_archer_shot_readback.gd 60`, and stop without committing.