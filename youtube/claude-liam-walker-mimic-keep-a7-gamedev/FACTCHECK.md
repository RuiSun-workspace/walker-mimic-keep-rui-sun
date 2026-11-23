# FACTCHECK — A7 explainer narration (Claude, 2026-11-22)

Every factual claim in `build_beats.py`'s narration, with the record it comes from. Checked before voicing.

| Beat | Claim | Source |
|---|---|---|
| B02 | the scarecrow outside the archer's reach stops at the wall; one shot every 0.6 s | `capture/take-play.log` (walker at_wall, `hold`; FIRED every 18 frames), `tuning.gd:10` `FIRE_INTERVAL := 0.6` |
| B03 | walk: Sprite2D sliced 4×1, AnimationPlayer frame track; shot: three-part cutout rig keyed in the scene, AnimationTree; one authority each | CHANGE-BRIEF.md §1, `scarecrow.tscn:60-67`, `archer.tscn:175-197`, CLAUDE.md "One authority" |
| B04 | keys at 0, 0.125, 0.25, 0.375 s; values 0-3; update 1 = discrete; loop_mode 1 | `scarecrow.tscn:18-31` (verbatim on screen) |
| B05 | hframes 4; sheet written by code, no third-party licence; pole foot in one column; 0/−3/+1/−3 px | `scarecrow.tscn:63`, `godot/assets/sprites/ATTRIBUTION.md`, `evidence/a7-probes/walk_foot_position.out.txt`, Rui "没有漂移" (TEST-REPORT A7.6) |
| B06 | mutation 1a renames the property to `frames`; the scene loads with no ERROR line; the read-back reports it | `evidence/a7-mutations/m1a.diff`, `m1a_walk_subname.log` (0 ERROR lines, 2 FAIL) |
| B07 | reference 26 / 1 / 14 frames at 30 fps; table 8 / 1 / 6 at step 1/30 | CHANGE-BRIEF.md §4 |
| B08 | step 1/30; keys at frames 0, 8, 9, 15; transitions 2 / 0.5; full draw −16° after tuning; release_window true for one frame | `archer.tscn:75-88`, `:128-135`; TUNING.md r1 |
| B09 | frame 10 trigger, 18 full draw with release_window true and no arrow, 19 arrow out, 25 idle; the archer reads the key one tick after the tree writes it | `logs/shoot_preview_r1.log` lines 10, 18, 19, 25; CLAUDE.md Headless facts |
| B10 | Rui looked first; one key −8° → −16°; every logged angle as predicted; one frame missed on unseeded particles; Rui kept it, and in play said the phases read clearly | TUNING.md (A7 sections, incl. "r1 in the running game") |
| B11 | only the AnimationTree writes release_window; archer.gd reads it in `_physics_process`; tree callback mode PHYSICS; scarecrow player on IDLE, not read by gameplay | `archer.gd:27-40`, `archer.tscn:194`, CHANGE-BRIEF.md §7 |
| B12 | release_window true on tick 37, fired on tick 38; one tick = 1/60 s, inside the 0.3 s draw lead | `logs/shoot_preview_r1.log` lines 18-19; `archer.gd` `DRAW_LEAD := 0.3` |
| B13 | the presenter reads at_wall, picks walk/hold, never writes the frame; compares assigned_animation because hold empties current_animation | `scarecrow_walk_presenter.gd:2-15` |
| B14 | about a dozen wraps, then hold; Rui watched five wraps, no stutter; strip judged free of drift | `capture/take-play.log` (walker reaches the wall at 6.2 s = 12 wraps of 0.5 s); TEST-REPORT A7.6 (Rui "a没问题", "没有漂移") |
| B15 | P in startup, on the active frame and in recovery; moving does not interrupt; a wall target walked out of the cone cancels with no arrow | `capture/take-interrupts.log`: P at f44, f145 (release_window true, not yet read), f243; D from f329, arrow f342; CANCELLED f446, 12 arrows before and after; checked on the frames (f50, f150, f250, f444-446) |
| B16 | read-backs 68 checks / 166; state 107; edges 325; pins 38; mutations 1a, 1b, 2, 3 exit 1; 4 passes | `logs/*_60fps.log` at `4d2e0a8`; `evidence/a7-mutations/`; TEST-REPORT A7.4, A7.6 |
| B17 | agent reported 72 checks for 68; a mistyped log line (frame 37); Claude's helper fix fired no arrow; Claude's checklist was wrong; Rui overruled −8°; startup cancel never seen by a human | FRICTIONAL.md (Steps 3, 6, Use It), commit `fb1c943` message, TEST-REPORT A7.6 |
| B18 | next: a larger +2° release kick (the agent's next candidate) | `sessions/a7/session-7b-propose.md`, TUNING.md |
