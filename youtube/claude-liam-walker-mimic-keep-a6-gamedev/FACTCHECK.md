# FACTCHECK — every number and claim in the narration, against its source

Checked by Claude, 2026-11-08, against the repository at `3b99ea6`. "Rui" claims quote Rui's words in TUNING.md
or TEST-REPORT.md, never a judgement Rui did not make. Three narrations were corrected before the master and
re-voiced (B03, B13, B16; see BUILD-PROMPT.md).

| Beat | Claim | Source |
|---|---|---|
| B00 | archer on a wall shoots fire arrows at scarecrows; one effect per hit, one for burning and time left | README.md; CHANGE-BRIEF §1 |
| B01 | specified by Rui, built and wired by agent sessions, tuned twice by Rui's eyes | CHANGE-BRIEF (Rui, `b1d2e08`); SOURCES.md A6; TUNING.md (A r1, B r1) |
| B01 | tests read every node and see no particle; strips see particles but no hit; overlap only in the game | CLAUDE.md Headless facts; preview scripts fire no arrow; TUNING.md B r1 (Rui's in-game observation) |
| B02 | archer fires on its own; burning lasts four seconds | `game/archer.gd` auto-fire; `game/tuning.gd` BURN_DURATION 4.0; take `play` (no keys) |
| B03 | Effect A from hit_taken, the one gameplay change allowed; Effect B from burn_time_left, read every frame; refresh emits no signal | CHANGE-BRIEF §1, §5 boundary exception; `game/scarecrow.gd` `ignite()` |
| B04 | flash ~8 frames (0.28 s), smaller than the head; straw 0.8 s, may overlap the next hit, never a third | CHANGE-BRIEF §2 Effect A |
| B05 | emitter: amount, lifetime, one-shot; process: velocity, gravity, colour over life; draw: soft dot, additive | `effects/impact_burst.tscn:77-88`, `:24-38` (shown verbatim) |
| B06 | fixture with fixed seed; Rui could not see the straw during the flash; straw colour equals the body | `previews/impact_burst_preview.gd`; TUNING.md r0 note; Claude's sample: #e8c46b vs #e9c46a |
| B07 | Rui saw the flash start bright; prediction softer; dimmer on grass, barely on the body (clipped); kept, straw read better | TUNING.md Effect A r1 (Rui's words, agent prediction and comparison, Claude's pixel (255, 255, 76)) |
| B08 | near and far hits land close together; test measured three bursts alive at the third impact; each freed after its lifetime | take `play` log (hits at 0.60/0.67 s, 3 children at 1.27 s); TEST-REPORT A6.3 (3 live, 47 frames each) |
| B09 | embers pale yellow to orange-red over faint smoke; amount_ratio and turbulence not used by A; on death move to the effects layer and fade | CHANGE-BRIEF §2-§3 Effect B, Rule B4; `effects/burning_embers_driver.gd` |
| B10 | reads burn time every frame into amount_ratio, never amount; refresh jumps back to full next frame | `effects/burning_embers_driver.gd:27-40` (shown verbatim); TEST-REPORT A6.6 B3 |
| B11 | Rui: weakening hard to notice; counts ten, six, four, three; embers on the yellow body clip | TUNING.md Effect B r0 note; FRICTIONAL Step 5 (Claude's reading, counts about 1/5/10/6/4/3/0) |
| B12 | Rui saw flash and embers merge; shared texture, blend, colour; fade-in; changed less than predicted; kept, "a little apart" | TUNING.md Effect B r1 (Rui's words, agent proposal and comparison, Claude's pixel counts) |
| B13 | fire hit starts the embers; second hit refreshes; Esc freezes; they thin; a scarecrow dying while burning leaves embers to fade | take `burn` log: hits 1.0/3.0 s, ratio 0.508 → 0.883, paused 4.0-5.5 s at 0.750; deaths while burning |
| B14 | line 316 force = gravity, brief (0, 100, 0); line 329 velocity += force × DELTA; texture and blend not in the shader | `shaders/particles_generated.gdshader:316-329` (shown verbatim); CHANGE-BRIEF §3 A1; TEST-REPORT A6.7 (Rui's answer) |
| B15 | settings read back; real arrows and keys; four mutations fail, including a silent Godot 3 name; headless GPU price near zero; far under budget | TEST-REPORT A6.1-A6.7; `evidence/a6-mutations/`; `evidence/a6-cost/`; Rui's Visual Profiler reading |
| B16 | no fixed seed in the agent's preview; capture path wrong twice; swapped screenshots, withdrawn; Rui overruled one strip reading; hidden emitter paused | FRICTIONAL Step 2, Step 5; TUNING.md A r1 disagreement; TEST-REPORT A6.5, A6.7 (B6) |
| B17 | shown, uncertain (smoke, B6), next step (smoke), contributions | TEST-REPORT A6.6-A6.7 (Rui: smoke least noticeable); SOURCES.md A6 |
| B18 | Your Turn prompt | illustrative, not a transcript |
