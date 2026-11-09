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

## 2026-11-08 — Effect A, revision r1

What I saw (running game, 1280×720):
命中时现有较亮的闪光出现，然后能看到有草屑飞出，在闪光结束后落下，我任务闪光开始时还是有一点亮，可能会阻碍观察到草屑飞出，可以试着调暗一点
(English, translated by Claude: on a hit a fairly bright flash appears first, then I can see straw
flying out, and it falls after the flash ends. I think the flash is still a bit bright when it
starts, which may make it harder to see the straw flying out; it could be tried a little darker.)

Claude's reading of r0-tinted (interactive agent session; summary): frame 10 matches (small ring,
chips weak, tan on tan); frame 12 only partly: the flash is a large blob as wide as the body with
no orange edge, and the straw on the face is washed out — "the frame you described"; frame 15
mostly matches; frame 20 matches apart from "falling" (straw still at or above the hit point);
frame 30 flash matches but the first burst's straw is barely visible, so the overlap barely shows;
frame 50 shows nothing where the brief expects faint straw.

Change: A1 Flash colour ramp (Gradient_flash) stop 0.0 alpha 1.0 → 0.60, stop 0.35 alpha 0.90 →
0.55; colours, offsets and every other setting unchanged. Approved by me before the edit.

Claude's prediction for r1: same particle positions (fixed seeds); frame 10 same-size ring with a
weaker glow and slightly clearer chips; frame 12 same size, softer yellow, fainter halo on the grass,
maybe orange edges, chips less washed out; frame 15 leftover flash dots fainter; frames 20 and 50
identical; frame 30 dimmed like frame 12. Risk it named: the straw's first colour (#e8c46b) is close
to the tinted body (#f7c13a), so the straw may still not stand out from the body.

Claude's comparison of r1 with its prediction (measured pixel by pixel against each strip's own
frame 50): frames 10 and 15 match; frames 20 and 50 are pixel-identical to r0-tinted; frames 12 and
30 match only partly: on the grass the added light fell about 21–40 %, but on the body only about
13–17 %, and the blob stays saturated yellow, because the tinted body (about 247, 193, 58) leaves
little headroom and most of the cut removed light that was already clipped at 255. The straw is
drawn on top of the flash (Straw follows Flash in the scene, mix blending), so the flash never
covered it; what hides the straw in frame 12 is tan on a similar body colour, the risk named before
the change. The agent also corrected its r0-tinted reading: frame 12 was saturated yellow, not
"nearly white". Claude (main session) checked frames 20/50 (0 pixels differ) and the clipped body
pixel (255, 255, 76) in r1 frame 12.

My verdict (running game, 1280×720): kept, because

Strips: captures/impact_burst/r0-tinted/, captures/impact_burst/r1/ (fixture captures)
Commits: 946c797 (prompt), a88d821 (scene + test), f6bdbef (r1 strip), 765b0b4 (brief revision)
