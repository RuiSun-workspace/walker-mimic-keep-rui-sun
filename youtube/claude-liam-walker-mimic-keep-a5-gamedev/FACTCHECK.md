# FACTCHECK — every number and claim in the narration, against its source

Checked by Claude, 2026-10-29, against the repository at `879324b` (TEST-REPORT.md was written at `b77e30d`;
nothing in `godot/` changed between them). "Rui" claims quote Rui's notes or chat, never paraphrase a judgement Rui
did not make.

| Beat | Claim | Source |
|---|---|---|
| B00 | archer on the wall; scarecrows burn; two hand-written shaders; one textured shield, two materials | README.md; CHANGE-BRIEF §1, §8; `godot/shaders/` (Rui's commits 6a2c298, 416e5f5) |
| B01 | every shader line typed by Rui | CLAUDE.md "Ownership"; `scripts/check-session.sh`; FRICTIONAL Step 2, Rui's spatial shader |
| B01 | three agent sessions | `sessions/session-1.jsonl` (CLAUDE.md draft), `session-2-implement.jsonl` (driver + test), `session-3-audit.jsonl` (material audit) |
| B01 | tests pass at three frame rates; cannot see a pixel | TEST-REPORT §1; CLAUDE.md Headless facts (dummy renderer) |
| B02 | nobody at the keys; archer fires on its own | take `idle`: `capture/capture_a5_film.gd` sends no input; `archer.gd:14-24` auto-fire |
| B02 | Burning: 4 damage a second for 4 s | `tuning.gd:22-23` (BURN_DURATION 4.0, BURN_DPS 4.0) |
| B03 | colour line; (255, 192, 32); 0.65 at the hit, 0 after 4 s of game time | CHANGE-BRIEF §2, §3 Rules 1-2, §6 |
| B03 | Rui predicted three pixels by hand | CHANGE-BRIEF §6 "Predicted Pixel Results" (0.0, 0.5, 1.0) |
| B04 | line 1 canvas_item; lines 3-4 uniforms; line 7 the colour line | `shaders/burning_tint.gdshader:1-8` (shown verbatim) |
| B05 | five frozen scarecrows, 0 / 0.5 / 0.65 / 1 / 2; 15/15 within one step; 1.0 exactly the burn colour; 2.0 not clamped | `evidence/controlled_values/pixels.txt` lines 13-29 |
| B06 | reads burn_time_left, 0..0.65, own material; one copy each | `game/burning_tint.gd:7-13`; `game/scarecrow.tscn:9` (`resource_local_to_scene = true`) |
| B07 | hit at 1.0 s, second hit at 3.5 s (back to 0.65), Esc pause 4.5-6.0 s holds, burns down 7.5 s | take `fade` log `capture/take-fade.log` (burn_mix 0.330 → 0.574 after the second hit; 0.488 over the pause) |
| B08 | the five looks; the two faults | Rui's chat, 2026-10-29, quoted verbatim in TEST-REPORT §2 In play and on the B08 still |
| B09 | samples every live scarecrow every frame at 30/60/144 with real arrows; line 97 = Rule 2; line 98 > 1e-6 fails | `tests/test_burning_tint.gd:90-98`, `EPS`; CHANGE-BRIEF Rule 2 |
| B10 | 49/0 at 30, 60, 144; mutation 1 SHADER ERROR exit 1 (45/4); mutation 2 exit 1 (46/3), only name checks | `logs/test_burning_tint_*fps.log`; `evidence/mutations/m1_*`, `m2_*`; FRICTIONAL "Mutations 1 and 2" |
| B11 | headless draws nothing; what is and is not proved | CLAUDE.md Headless facts; TEST-REPORT §4 |
| B12 | strip 64/128/192; line 5 source_color; line 8 plain | `tools/make_hint_greys.gd`; `shaders/hint_experiment.gdshader:4-17` |
| B13 | Rui predicted; 137/188/225 without the hint; all six exact | CHANGE-BRIEF §7; `evidence/hint_experiment/band_values.txt` |
| B14 | albedo source_color; roughness, normal, mask plain; hint_normal; OpenGL convention | `shaders/shield_wood.gdshader:6-16`; `showcase/shield_*.tres` bind `_nor_gl`; `.import` normal_map=1 |
| B15 | curl 0.6703 vs 1.3297; threshold 0.8357 Rui's rule A; Rui sees grooves, subtly | `logs/normal_map_check_60fps.log`; CHANGE-BRIEF revision C ("A：0.836"); `my-observations.txt:39` |
| B16 | group_uniforms; range, step, default; normal_strength 0-2, once wrong, caught by review | `shield_wood.gdshader:21-33`; FRICTIONAL Session 3 (audit finding 1) |
| B17 | min/default/max under fixed light; Rui's five "what breaks" notes | `evidence/sweep/`; `my-observations.txt:13-19` |
| B18 | line 12 names the shader; darker tint, stronger normals, 70 % scorch | `showcase/shield_burned.tres:9-22` (tint 0.72/0.5/0.34, normal 1.15, scorch 0.7) |
| B19 | shader edit: both change; material edit: only ShieldA, 0 px on the right; restored byte for byte | TEST-REPORT §2 One shader, two materials; `evidence/two_materials/` |
| B20 | generated line 7 source_color (albedo); line 19 normal sampler; Rui's equivalents shield lines 7 and 13 | `shaders/standard_generated.gdshader:7,19`; `shield_wood.gdshader:7,13`; LANGUAGE-NOTES Q6 |
| B21 | source_color removed; 130/2, exit 1; only source-text checks | `evidence/mutations/m3_*`; FRICTIONAL "Mutation 3" |
| B22 | the five mistakes | FRICTIONAL Session 3 (grep), Session 2 (±1 tick), Step 3 (own curl 1.22 vs 1.79), 2026-10-29 (two built-ins; whole desktop, 87e54a0 → 65800cd) |
| B23 | uncertain: OS-screenshot pixels, subtle grooves; next step: the long-range miss | TEST-REPORT §6; FRICTIONAL 2026-10-29 playtest (Rui deferred it, homing / fixed-trajectory arrows) |
| B23 | who made what; Poly Haven Wood Planks, Amal Kumar, CC0 | SOURCES.md (repository); `assets/textures/wood_planks/ATTRIBUTION.md` |

Corrections made while writing: B02 first said "the archer slides along the wall" over footage in which nobody
presses a key; reworded to "running with nobody at the keys" and re-voiced. The play take that chased scarecrows
was dropped because every scarecrow died at the top edge, before the tint could be seen.
