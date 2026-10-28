# FRICTIONAL — Mimic Keep

An honest log of what was tried, what happened, and who did what. Rui's own words are marked as
Rui's; everything Claude Code did is labelled as Claude's.

## 2026-10-25 — Change of game: walker-lamplight → Mimic Keep

**The change.** Assignments 2–3 were built on walker-lamplight-rui-sun (Wick, a lantern in a
mine). Assignment 4 was the game design document for a new game, Mimic Keep. From Assignment 5 on,
the course game is Mimic Keep, in this repository. 

**Why (Rui):** After completing Assignments 2 and 3, I felt that Lamplight’s main idea had already been explored. Continuing the project would mostly mean adding more levels, assets, and balance adjustments instead of introducing meaningful new gameplay decisions. I was also no longer interested enough in the concept to continue developing it. I chose Mimic Keep because its enemy waves, material and element interactions, upgrades, and shop systems provide a clearer direction for future development.


**What Claude Code (Opus 5.5) did, at Rui's request ("开工做新游戏吧"):** built a playable
prototype from the GDD before any Assignment 5 work. That is a new Godot 4.7.2 project (Forward+),
the archer, fire arrows, Straw Scarecrows with a Burning state, gate HP, win and loss, pause, two
headless test suites, code-drawn sprites, and a 3D showcase scene with a code-built wooden shield
for the later material work.

**What happened and what was checked (Claude):**

- First test run, 60 fps: 19/22 and 13/14 passed. Three failures were real findings:
  - *Same-tick reset.* A restart arriving between physics ticks freed the scarecrows with
    `queue_free`, but they still ran one more `_physics_process` and hit the new gate.
    Fixed in the game: scarecrows and arrows skip a tick once queued for deletion.
  - *Time scale.* At `time_scale` 2 the burn took 122 ticks, not 120. A probe showed the first
    tick after the change still receives the old delta (1/60, then 2/60). The test now sums the
    engine's own deltas instead of counting ticks.
  - *Wall spawn.* A scarecrow spawned at the wall lost its first tick before attacking. It now
    knows it is at the wall from `_ready()`.
- After the fixes: 23/23 and 14/14 at 30, 60 and 144 fps.
- A real windowed render (`tools/capture_prototype.gd`, Vulkan Forward+, RTX 3070 Laptop) wrote
  `evidence/prototype/game_12s.png` and `shield_room.png`. Claude looked at both. The game draws,
  arrows fly, and 4 scarecrows burned down in 12 s with the archer standing still. The shield faces
  the camera with correct winding and casts a shadow.

### Rui's first playtest (2026-10-25)

Rui played the prototype in a window, with the spawn interval going from 2.4 s down to 0.9 s.
Rui's words: "目前的怪物数量太多了，很难通关" (there are too many monsters right now; it is very
hard to win). Rui also noted that the level-up and upgrade-choice mechanics from the GDD are not in.

**Claude's response.**

- Claude wrote `godot/tools/balance_sim.gd` to play whole runs headlessly over 8 seeds with two
  stand-in players. "idle" never moves. "chase" holds the real move actions toward the scarecrow
  closest to the wall. Neither is a human, so the sim only ranks tunings.
- The sim agreed with Rui: at 2.4 → 0.9 s, "chase" lost all 8 runs at 71–78 s.

| spawn interval (start → end) | idle wins | chase wins | chase gate HP left |
|---|---|---|---|
| 2.4 → 0.9 (first build) | 0/8 | 0/8 | lost at 71–78 s |
| 2.6 → 1.1 | 0/8 | 2/8 | — |
| 2.8 → 1.2 | 0/8 | 8/8 | 20–100 |
| 2.8 → 1.35 | 1/8 | 8/8 | 71–100 |
| **3.0 → 1.5 (chosen)** | 1/8 | 8/8 | 100 |
| 3.5 → 2.0 | 2/8 | 8/8 | 100 |

- The difficulty has a sharp edge between 2.6 and 2.8 s. The bot reacts instantly and a person
  does not, so Claude chose 3.0 → 1.5. That is clearly winnable by moving, and standing still still
  loses (7/8).
- Tests after the change: 23/23 and 14/14 at 30, 60 and 144 fps.

**Upgrades:** Rui asked whether they can come after Assignment 5. Claude recommended yes: A5's
boundary forbids changing game rules while the shaders are added. Rui's decision is pending.

### Rui's second playtest (2026-10-25, spawn 3.0 → 1.5)

Rui asked whether "1.5 s at 90 s" meant the speed-up never happened, since the run ends at 90 s.
It does happen: the interval shrinks linearly over the whole run (2.5 s at 30 s, 2.0 s at 60 s).
1.5 s is only the end point, so the densest stretch is about 1.6 s near the end, about 41
scarecrows in all. Claude had described it badly ("90 秒时加快到每 1.5 秒一只"); the code was right.

After replaying, Rui said: "目前的游戏没什么问题，继续下一步吧" (the game is fine for now; on to
the next step).

## 2026-10-26 — CHANGE-BRIEF: Rui's specification, Claude's review

**Rui** wrote CHANGE-BRIEF.md: the Burning state, the shader and its colour line, the six rules,
boundaries, evidence split, all hand calculations (pixel predictions at 0.0 / 0.5 / 0.65 / 1.0,
contrast ratios, and both grayscale-experiment quads), the material plan, five failure cases and the
seven short answers. Rui's first saved draft was a different document: a game-change rationale.
Rui removed it ("不要这份文件了") and wrote the specification instead.

**Claude reviewed it before its first commit.** Claude recomputed every number independently. All
pixel predictions, the 0.65 row, the contrast ratios (1.80 and 1.81) and the grayscale predictions
(64/128/192 and 137/188/225) matched. Claude then found the problems below. Rui chose the fix for
the first one ("改成普通 uniform + 每只一份材质") and asked Claude to apply the rest and convert the
file to Markdown.

**What Claude changed in CHANGE-BRIEF.md (Rui approved; the scratch diff was shown to Rui before commit):**

1. *Formatting only.* Plain text with tab-separated tables became Markdown: headings, pipe tables,
   code fences, and URLs for the four Godot documentation links whose URLs had been lost. A
   word-by-word comparison against Rui's text showed no wording changes in this step.
2. *`instance uniform` → ordinary `uniform` with one ShaderMaterial per scarecrow.* Claude probed
   Godot 4.7.2, both headless and windowed with Forward+. `get_shader_uniform_list()` does not report
   an instance uniform; `set_instance_shader_parameter()` accepts an undeclared name silently. The
   required rename mutation could therefore never fail the test. This changed the uniform table,
   Rule 6, the evidence table, Failure 2 and short answer 6. The brief's claim that the
   documentation confirms canvas_item instance uniforms was removed; it was not checked here.
3. *Tolerance.* "One 60 fps frame / 1/60 s" became "one frame period at the measured frame rate".
   The driver updates once per frame, and at 30 fps a frame is 1/30 s.
4. *Evidence split.* "Exact tint calculation" had a capture in the headless column; headless runs
   draw nothing, so it moved to the human/image column.
5. *Section 6.* Added that three 0.5 values sit exactly on .5 (146.5, 30.5, 188.5) and are
   predicted ±1, and that the arithmetic assumes `burn_color` is not linearised in 2D with HDR 2D
   off. That second point is a reading of the engine, to be checked by the captures. Rui's numbers
   are unchanged.
6. *Normal maps.* The `_nor_dx` calibration and Failure 5 now use the course's curl check
   (`normal_map_check.gd`) instead of a render comparison. `_nor_dx` is not sampled by any shader.
7. *Failure 4.* The check is now the material test reading sampler hints from source, plus the
   `source_color` mutation. The grayscale experiment is kept as the on-screen illustration.
8. *Scorch mask source.* "Authored" became "written by a committed script in `godot/tools/` from
   seeded noise". Claude chose this; Rui can still choose a different source.
9. *Short answer 1.* Added what Forward+ does and does not rule out.
10. Added the Poly Haven URL and a Revision Log section at the end.

**Not yet verified:** the Poly Haven page and file names (`wood_planks_*_1k`) will be checked when
the textures are downloaded.

## 2026-10-26/27 — Session 1: the CLAUDE.md draft and its review

**First attempt failed.** `claude -p` stopped after 355 ms with "Not logged in · Please run /login".
The desktop app was signed in, but its bundled CLI was not. Rui logged the CLI in
(`claude auth login`). The failed transcript is kept: `sessions/session-1-attempt1-not-logged-in.jsonl`.

**Second attempt** (`sessions/session-1.jsonl`, prompt `prompts/prompt-1.txt`, read-only git
tools, `--max-turns 40`): final result event `success`, `is_error` false, 21 turns, no permission
denials. `scripts/check-session.sh` showed `godot/shaders/` and `scripts/run-test.sh` unchanged;
the only new file was CLAUDE.md (117 lines). Committed unedited as `0d0eb9c`.

**Review (Rui reviewed and approved the list; Claude made the edits; separate commit).** Claude
printed every line the draft cites and compared it with the claim. Most were exact. The draft did
not list a build script as a test, which Chapter 6's run did. Found and fixed:

1. The draft said `project.godot:11` lists "only" `"4.7"`; it lists `"4.7"` and `"Forward Plus"`.
2. It told the reader the brief requires the *existing* suites at 30 and 144 fps (citing Rule 2).
   The assignment runs existing tests at 60; only the new effect test runs at 30/60/144.
3. No "Headless facts" block. Added one, every line from a probe on this machine. The headless
   display server draws nothing. `get_shader_uniform_list()` gives names, types and hints but no
   defaults. A broken shader prints SHADER ERROR and gives an empty list. An undeclared
   `set_shader_parameter` is silent. Instance uniforms are not listed. Physics runs at 60 ticks/s.
   `hdr_2d` is false. The shield mesh has tangents.
4. Five "Unconfirmed" items were confirmed by those probes or by the baseline run, and were removed
   or moved. The `source_color`-in-2D question stays unconfirmed until the captures.
5. The `--import` step was added to the test commands. The baseline now cites the logs in
   `evidence/baseline/`, not the README.

Result: 118 lines, still under 120; `@CHANGE-BRIEF.md` is still imported on its own line.

## 2026-10-28 — Step 2: the Burning shader, and the editor's first rewrite

**Rui** created `godot/shaders/burning_tint.gdshader` in the Godot shader editor and typed it from
CHANGE-BRIEF.md section 2. Getting there took three tries. The FileSystem dock's "New" menu in
4.7.2 has no "Shader" entry. Then the Shader Editor panel looked empty until Rui clicked its
"File" menu, which shows as plain text. Claude compared the file with the spec character by
character (identical) and ran `--import`: no SHADER ERROR. Headless `get_shader_uniform_list()`
reports `burn_mix: float` (hint_range 0..1) and `burn_color: Color`. The list does not show
`source_color`, so tests must read hints from source text. Committed alone as `6a2c298`, Rui's.

**Editor rewrite.** `git status` after that first editor session showed two modified files.
- `main.tscn` gained uids and node `unique_id`s and lost `load_steps`. With those removed, every
  line matched, so it was a format-only change.
- `project.godot` got Godot's stock header and lost `renderer/rendering_method="forward_plus"`.
  That value is the default, so the editor omits it. A probe still reads `forward_plus`.

Claude recommended keeping the rewrite rather than restoring the key, because the editor would drop
it again on every save. Rui chose "接受并修正引用". The rewrite is its own commit (`ccb9529`), and
the suites still pass (23/0, 14/0). The follow-up commit moves CLAUDE.md's project.godot line
numbers (+5) and rewords its renderer line. It also updates README's renderer line and adds a dated
CHANGE-BRIEF revision for short answer 1.

## 2026-10-28 — Session 2: the driver, the test, and a game bug the test found

**Plan run** (`sessions/session-2-plan.jsonl`/`.md`, read-only tools, 20 turns): the agent confirmed
Rui's shader matched the spec. It noticed a stale CLAUDE.md line and raised two spec questions.
A: at 30 fps the first frame after a hit can't show exactly 0.65, because one frame holds two
physics ticks. B: under time_scale, "one frame" means time_scale/fps of game time. Rui:
"都批准". Both went in as dated CHANGE-BRIEF revisions (`2dd39a9`). Claude drafted the approval
prompt (`prompts/prompt-2b.txt`) from Rui's answer and added two requirements of its own. The
sampler may keep no references. Every ignition must come from a real arrow: report and stop,
never call `ignite()` or loosen a tolerance.

**Implementation run** (`sessions/session-2-implement.jsonl`/`.md`, 47 turns, 2 denials for
`run-test.sh ...; echo` compound commands, then rerun plainly): the scene material, the driver
and a 49-check test, committed unedited as `69489d8`.

- Claude read the test before trusting the summary. No `ignite()`, no writes to
  `burn_time_left`, no direct driver call. Pause is a real P key; the sampler runs at
  process_priority 1000.
- Claude re-ran everything through `run-test.sh` and got the agent's numbers: 49/0 at 30 and
  60 fps, **42/7 at 144 fps**.

**What the failure was.** Every burn lasted 241 ticks instead of 240. The agent's INFO line
printed `burn_time_left` the frame before zero: `9.2e-15`. That is float residue from 240
subtractions of 1/60, so the game's timer, not the tint, ran one extra tick. It passed at 30 and
60 fps only because one frame there is at least as long as a tick. The agent stopped without
loosening anything, as prompt-2b required.

**Claude's own miss:** `test_rules.gd`, which Claude wrote for the prototype, allows ±1 tick
on the burn duration. That tolerance hid this bug from the start.

**Decision (Rui): "修游戏计时器".** The fix is a one-line epsilon (`BURN_END_EPSILON = 1e-9`) in
`scarecrow.gd`. It is recorded as the single boundary exception in CHANGE-BRIEF. After the fix:
test_rules 23/0 and test_input 14/0 at 60, test_burning_tint 49/0 at 30, 60 and 144. The
INFO lines show 240/480/120 ticks. Not required but run anyway: test_rules and test_input also
pass at 30 and 144. No test expectation was changed.
