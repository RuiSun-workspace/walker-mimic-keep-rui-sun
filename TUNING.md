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

## 2026-11-08 — Effect A, fixture check: r0 (untinted) vs r0-tinted

Why: Rui's preview note and in-game note disagreed about the straw during the flash. Rui chose to
give the preview scarecrow the in-game burning tint (`c154122`, burn_mix 0.65, body #f7c13a) and
captured r0-tinted with the same settings and seeds. Rui did not write a separate note for this
fixture check (not required: it changes no setting). No effect setting changed.

Claude's reading (fixture captures, same particle positions in both strips because the seeds match;
changed pixels counted against each strip's own frame 50, which shows no particles):

| Frame | Changed px > 8 / > 40, r0 → r0-tinted | What differs |
|---|---|---|
| 10 | 93 / 61 → 139 / 58 | a few tan straw chips now show beside the white flash |
| 12 | 812 / 543 → 816 / 443 | straw at the head slightly clearer; the flash stands out less from the yellower body |
| 15 | 374 / 67 → 345 / 100 | straw chips over the body a little stronger |
| 20 | 133 / 82 → 138 / 76 | about the same: the dark straw reads on both bodies |
| 30 | 619 / 333 → 621 / 261 | second flash less contrasting on the tinted body |
| 50 | 0 / 0 → 0 / 0 | nothing visible in either |

Reading: the tint helps the straw only a little in the first frames and costs the flash some
contrast over the body. It explains part of the difference between Rui's two notes, not all of it;
in the game the draws are unseeded and some scarecrows walk, which this fixture does not show. The
straw is still low-contrast in its first frames and still stays above the hit point. From here on,
r0-tinted is the "before" strip for Effect A tuning.

Strips: captures/impact_burst/r0/, captures/impact_burst/r0-tinted/
Commits: c154122 (fixture), d719bf3 (strip)
