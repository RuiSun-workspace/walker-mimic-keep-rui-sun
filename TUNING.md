# TUNING.md — Assignment 6 particle tuning

Every preview capture in this file is a **fixture capture**: the preview scene
(`godot/previews/<effect>_preview.tscn`) holds a still scarecrow over the real
background and fires the effect on fixed frames with a fixed seed. It is not
gameplay footage.

Strips live in `captures/<effect>/r<N>/`; the frames to read are listed in
CHANGE-BRIEF.md §7. Verdicts are Rui's, made in the running preview or game at
1280×720. Claude's readings are claims.

## 2026-11-08 — Effect A, first look at r0 (before Claude reads anything)

What I saw (preview, windowed, 1280×720):
The flash was very fast and I did see the flash, the flash was very bright, and when the flash was flashing, I didn't notice the grass clippings at all, I only noticed the rest of the grass clippings after the flash was over, and I could see the grass clippings as they fell, and I couldn't notice the whole movement of the grass clippings.

Strip: captures/impact_burst/r0/ (fixture capture, seed 7270 / 7370)
Commits: 6938b15 (this note), 06527db (strip)

## 2026-11-08 — Effect A, r0 settings in the running game (after Step 3 wiring)

What I saw (running game, windowed, 1280×720):
Grass clippings can now be seen during bursts

Note (Claude): this differs from the preview note above with the same settings. One difference
between the fixture and the game, not yet tested: every in-game hit is a fire arrow and ignite()
runs before hit_taken, so the scarecrow is tinted by burning_tint (body about #f7c13a at
burn_mix 0.65) while its burst plays; the preview scarecrow is a plain sprite (#e9c46a, the same
colour as the straw's first ramp stop #e8c46b). In-game draws are also unseeded and some
scarecrows are walking. Until the fixture matches, a preview strip may judge the straw against
the wrong body colour.
