I read all seven frames of the r0 strip. Your observation is a real overlap, but this strip can't show it: it's a fixture ignition with no arrow, so there is no flash in any frame.

## r0 compared with the intent, frame by frame

| Frame | Intent (brief §7) | What r0 shows | Verdict |
|---|---|---|---|
| 10 | Ignition; at most one ember; no smoke | Scarecrow tinted orange; one pinpoint ember low on the body's left (~629, 557); no smoke | Matches |
| 20 | ~6 embers, 1–2 smoke, still on the body | 4–5 pale-yellow dots on the head and body, none above the hat; no smoke visible | Mostly matches: a bit sparse, and smoke can't be seen |
| 40 | Still strong, density starting to drop | ~8–10 embers, three above the hat (~y 487–495); no smoke visible | Embers match; smoke can't be seen |
| 70 | About half density | Tint fading; 3–4 embers, one high to the right of the hat | Matches |
| 100 | Occasional embers, light smoke | 2–3 embers at the hat and mid-body | Embers match; smoke can't be seen |
| 130 | Ratio 0, a few fading leftovers | 1–2 orange specks on the body, tint almost gone | Matches |
| 170 | Clean | Clean | Matches |

The embers follow the intended timing. Two things stand out:
- **Smoke (B2) can't be seen in any frame.** It is 35 % brown under 0.35 alpha, drawn on top of the scarecrow. I'm noting this, not proposing a change.
- **The embers look just like the flash.** Both are `soft_dot.png`, additive, and start pale yellow-white: embers (1, 0.95, 0.63) against the flash's (1, 1, 0.80). Embers are born across the whole body box (±18, ±30), which covers the area the flash spreads into (it starts at the centre and spreads about ±25 px). Every arrow is fire (`godot/game/arrow.gd:6`), so every hit on a burning scarecrow puts a new flash over a full-density stream. Newly born embers merge with the flash into one bright patch. That is the overlap you saw.

## Proposed change: B1 Embers colour ramp (`Gradient_embers`)

Make newly born embers fade in over about the flash's 0.28 s, so for those first frames the flash appears alone. The embers then become visible as they rise out of it.

| Stop | Old | New |
|---|---|---|
| 0.0 | `Color(1.0, 0.95, 0.63, 1.0)` | `Color(1.0, 0.95, 0.63, 0.0)` |
| 0.30 | — | `Color(1.0, 0.95, 0.63, 1.0)` (new: the old first colour, at 0.30 × 0.90 s = 0.27 s) |
| 0.45 | `Color(1.0, 0.54, 0.12, 0.90)` | unchanged |
| 1.0 | `Color(0.85, 0.29, 0.07, 0.0)` | unchanged |

Nothing else changes: not the smoke, not Effect A, not the curves, velocities or amounts.

## Expected r1 strip

The fixture seeds are fixed, so the particles land in the same places as r0. Only their brightness while young changes.

- **10:** Nothing visible. The one newborn ember now has alpha ≈ 0.
- **20:** The ~6 embers that exist are 0–0.33 s old, so only 1–2 near the top of their rise are fully bright. The rest are faint, so this frame looks sparser than r0.
- **40:** About a third fewer bright dots (roughly 6–7 instead of 8–10). Dots low on the body are faint; the bright ones sit higher, so the stream appears to start a little above the middle of the body.
- **70 / 100:** The same pattern at lower density, with 2–3 and 1–2 bright embers.
- **130:** Almost identical to r0. Leftover embers are old, so they use the unchanged orange-to-red part of the ramp.
- **170:** Identical (clean).

**Risks:**
- Frames 10–20 move further from "embers begin rising immediately". The embers still start immediately but are only visible after about a quarter second.
- With fewer bright embers, the stream may look thinner, which could make your earlier "weakening not very noticeable" note slightly worse.
- The fixture strip still has no hit, so it can only show the fade-in. Whether the overlap is fixed has to be judged in the running game.
- If you keep the change, the brief's B1 ramp text needs a dated revision, as r1 had for A.

Once you approve, I'll change only `Gradient_embers` in `godot/effects/burning_embers.tscn`. I'll update `ramp_offsets` and `ramp_colors` for Embers in `godot/tests/test_burning_embers_config.gd` to match, run `./scripts/run-test.sh test_burning_embers_config.gd 60`, and stop without committing.