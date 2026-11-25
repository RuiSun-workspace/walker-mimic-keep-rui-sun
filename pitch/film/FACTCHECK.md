# FACTCHECK — Mimic Keep final project pitch

Every factual claim in the narration, where it can be checked, and its status. Checked by Claude against the
repository at tag `a7` (39f3fe8; `godot/`, `logs/`, `evidence/` unchanged since) on 2026-11-24. "Rui" = a fact
only Rui can supply, taken from Rui's own words in `pitch/brief-answers-zh.md`. "Will" = a plan, said in the
future tense on screen and in the voice, and labelled CONSTRUCTED.

| Beat | Claim | Source | Status |
|---|---|---|---|
| B00 | building Mimic Keep in Godot since October | prototype commit `cab3d5c`, 2026-10-25 | checked |
| B00 | the archer fires on its own; scarecrows walk down to the gate | `godot/game/archer.gd`, `scarecrow.gd`; take play-r0 | checked, shown |
| B01–B02 | elements, damage per enemy, reactions, Windows build, one level, endless mode | — | will (CONSTRUCTED) |
| B03 | only fire exists today | `arrow.gd:6` `element = &"fire"`; no other element in `godot/game/` | checked |
| B03 | a fire arrow sets a scarecrow burning for four seconds | `tuning.gd:26` `BURN_DURATION := 4.0` | checked |
| B03 | tint shader and ember particles | `godot/shaders/burning_tint.gdshader` (a5), `godot/effects/burning_embers.tscn` (a6) | checked, shown |
| B03 | that part is tested | `logs/test_burning_tint_60fps.log` 49 passed, 0 failed; `test_burning_embers_state` 54/0 | checked |
| B04 | ice, lightning, fire-on-chilled extra damage, ice + lightning stun | Rui, round 2 ("反应暂时就冰加火加雷吧") | will (CONSTRUCTED) |
| B05 | "in the level up games I have played, the choice is a bigger number" | Rui, round 1 answer 1 | Rui's opinion, said as one |
| B06 | Genshin Impact has element reactions, triggered by hand in an open world | Rui played it (question card, 2026-11-24); general description, no figures | Rui |
| B06 | a WeChat roguelite, name forgotten, skill choices, no reactions | Rui, round 2 ("我玩过的版本绝对没有属性反应") | Rui |
| B07 | target role technical designer; reader hiring manager | Rui, question card | Rui |
| B07 | the title screen and the build do not exist yet | no `godot/export_presets.cfg`; no title scene in `godot/game/` | checked |
| B07 | A/D to move, archer fires by itself | HUD text in take play-r0 ("A/D or Left/Right: move … the archer fires on its own") | checked, shown |
| B08 | a burning shader Rui wrote by hand, tag a5 | commit `6a2c298` "Burning tint shader, hand-written (Rui)", ancestor of a5 | checked |
| B08 | two particle effects with a GPU reading, a6 | `TEST-REPORT.md` A6.7 | checked |
| B08 | animation state machine with frame-exact tests, a7 | `logs/test_archer_edges_60fps.log` 325 passed, 0 failed | checked |
| B09 | headless tests, mutation runs, checks by eye | `logs/`, `evidence/a7-mutations/`, `TEST-REPORT.md` human-check sections | checked |
| B09 | 0.06–0.07 ms per frame, with and without the effects, RTX 3070 Laptop GPU | `TEST-REPORT.md` lines 533–541 | checked; on screen it says one whole-frame reading, not a per-effect cost |
| B10 | damage table, tuning log | — | will (CONSTRUCTED) |
| B10 | after Rui's first playtest the starting spawn gap went from 2.4 s to 3 s | `tuning.gd:31–33` | checked |
| B11 | in / out lists | `pitch/PROJECT-BRIEF.md` §6 | plan |
| B12 | every arrow already passes its element to the hit | `arrow.gd:22` `s.hit(Tuning.ARROW_DAMAGE, element)` | checked, shown |
| B12 | headless test on an exact tick, captured clip | — | will |
| B13 | a bot simulation exists to extend | `godot/tools/balance_sim.gd` (written by Claude) | checked |
| B14 | Rui's only game before the course: tile matching in C, 2022 | Rui; 2022 report (local, not in the repo: personal data), `pitch/evidence/2022-lianliankan-console.png` | Rui + checked image |
| B14 | it was tested by playing it ten times | report section 4: "游玩10+次，无bug" | checked (report seen by Claude, 2026-11-24) |
| B15 | Godot, shaders, particles, animation, directing an agent are new to Rui | Rui, round 1 answer 3 | Rui |
| B16 | exists list with tags; will-exist list | `pitch/PROJECT-BRIEF.md` Exists today / Will exist | checked |

Not claimed anywhere: players, playtest quotes from anyone but Rui, downloads, wishlists, frame rates, sales,
or any number for the proposed damage, reactions or builds.
