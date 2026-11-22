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

## 2026-10-28 — Mutations 1 and 2: does the test catch a broken shader?

Rui: "开始变异". Rui made both edits by hand in `godot/shaders/burning_tint.gdshader` and
restored them by hand; no agent touched the file. Each run went through
`scripts/run-test.sh test_burning_tint.gd 60`. Logs and diffs are in `evidence/mutations/`.

**Mutation 1: delete the `;` at the end of line 3** (`m1_semicolon.diff`). Exit 1, 45 passed,
4 failed (`m1_semicolon_test_burning_tint_60fps.log`). The log has `SHADER ERROR: Expected a ';'`,
pointing at line 4: the parser only notices at the next token. Two things caught it:
`run-test.sh` matched `SHADER ERROR`, and the test saw an empty uniform list `[]` (three
uniform checks plus the source check for `burn_mix`'s default failed).

**Mutation 2: rename `burn_mix` to `burn_amount` in the shader only** (both places, so the
shader still compiles; `m2_rename.diff`). Exit 1, 46 passed, 3 failed
(`m2_rename_test_burning_tint_60fps.log`). No `SHADER ERROR`, so `run-test.sh`'s grep did not
catch it; the test did. The failing checks were `burn_mix is a float with hint_range(0, 1)`
(uniform list from the engine) and two source-text checks.

**What the two runs show.** In both, all behaviour checks still passed (timing, pause,
time_scale, retrigger, death). `set_shader_parameter()` stores a value under any name and reads
it back without an error, even on a shader that failed to compile. So a test that only reads
back `burn_mix` would have passed both mutations; in the game, the scarecrow would burn without
changing colour. The check that matters is the uniform list by name: "exactly two uniforms"
passed under the rename, so counting alone is not enough.

**Restoring.** After mutation 2, Rui's first restore left an extra space in line 3
(`float  burn_mix`); the test passed (49/0), but the file differed from `6a2c298`. Claude
compared the md5 rather than trusting the test. Rui removed the space; a further save was needed
before it reached the disk. Final state: md5 `aa5ca255114e283ac24d1c5dceef69d0`, same as
`6a2c298`, `git status` clean for `godot/shaders/`, test_burning_tint 49/0 at 60 fps.
The third mutation (`source_color`) belongs to the material test and comes in Step 3.

## 2026-10-28 — Step 3 begins: textures, scorch mask, and a normal-map prediction that missed

**Textures.** Rui approved the download ("下载") of Poly Haven's Wood Planks 1K PNGs: diff,
rough, nor_gl, nor_dx, 18.6 MB. Claude downloaded them to a scratch folder first and checked each
md5 against Poly Haven's file API; all four matched. Poly Haven's licence page says CC0.
Credits and md5s are in `godot/assets/textures/wood_planks/ATTRIBUTION.md`. The import settings
in CHANGE-BRIEF §8 are written explicitly in each `.import` file, with `detect_3d` off so the
editor has nothing to change later. A probe of the imported textures read: diff and rough DXT1,
both normal maps RGTC (Godot's normal-map compression), all with mipmaps.

**Scorch mask.** `godot/tools/make_scorch_mask.gd` writes a 512×512 grayscale mask from seeded
noise plus a ramp towards the UV border. Claude tuned it twice by looking at the output. The
first version was a plain frame with a clean middle; the second had flat grey plateaus, from
clamping the noise before the sum. The final mask has a mean of 0.173, and 13.6% of pixels are
above 0.5. Two runs give the same md5.

**Normal-map check.** Claude first wrote its own curl measure: L1, every pixel, z rebuilt from
x and y. It scored 1.22 vs 1.79, nowhere near 0 vs 2. Before changing the brief, Claude
re-read the assignment text and found that it gives `curl_ratio()` as code. Claude switched to
that code, copied unchanged. It measured 0.67 vs 1.33. The direction is right, but the values
are not the brief's "near 0 / near 2". The midpoint threshold the brief implied is always 1.0
for one image, because the two scores always sum to 2. Claude gave two options: A, halfway between
the known-good score and 1.0; B, the midpoint 1.0, which checks the convention only. Rui:
"A：0.836". This is recorded as CHANGE-BRIEF revision C. Before the shields have a material,
Claude checked the threshold by hand with a throwaway probe: bound nor_gl 0.6703 passes,
nor_dx 1.3286 fails, and a noise "normal map" with no surface behind it scores 1.0200 and fails.
`normal_map_check.gd` 3/0 through run-test.sh. Its shield checks start running once the
shields have a ShaderMaterial with a `hint_normal` sampler.

## 2026-10-28 — Rui's spatial shader and the two shield materials

**Shader.** Rui wrote `godot/shaders/shield_wood.gdshader` by hand. Claude only read it and
compared it with the CHANGE-BRIEF §8 table. Two ranges differed: `texture_scale` went to 8.0
instead of 4.0, and `roughness_scale` was 0–2 with default 1.0 instead of 0–1 with 0.85.
Claude listed both, and Rui chose to fix the shader ("我改着色器"). After Rui's edit, a headless
`get_shader_uniform_list(true)` reported 4 samplers, the groups `Surface` and `Damage`, and 7
uniforms whose types and hint ranges match the table. Committed unchanged as `416e5f5`.

**Materials.** Claude wrote `godot/showcase/shield_new.tres` (ShieldA) and `shield_burned.tres`
(ShieldB) with a one-off script, not committed, that called `ResourceSaver` with the brief's
values. Both bind diff, rough, nor_gl and the scorch mask. A headless save writes unset
parameters as `null`, because the dummy renderer has no defaults, so Claude deleted the
`scorch_color = null` line from both files; both use the shader default. In
`shield_room.tscn`, the two placeholder StandardMaterial3Ds are replaced by the two files.
Light, environment, camera and mesh are untouched. A probe read two distinct materials, one
shared shader, and the brief's values.

**Checks.** `normal_map_check.gd` 9/0: its shield checks ran for the first time, nor_gl bound
on both, 0.6703 < 0.8357. test_rules 23/0, test_input 14/0, test_burning_tint 49/0 at 60 fps.
One frame rendered by the real renderer (Forward+, RTX 3070 Laptop) is in
`evidence/materials/shield_room_first_render.png`. It shows that both materials compile on the
GPU and that the scorch shows on ShieldB. It is Claude's render check, not the human visual
judgement, which is still to do.

## 2026-10-28 — The hint experiment

Claude wrote `godot/tools/make_hint_greys.gd`, which makes the 3×1 PNG (64, 128, 192),
imported lossless with no mipmaps. A probe of the imported image read `#404040 #808080 #c0c0c0`.
Rui hand-wrote `godot/shaders/hint_experiment.gdshader`. It is unshaded and has two samplers,
one with `source_color, filter_nearest` and one with `filter_nearest` only, plus the bool
`use_source_color`. Claude only compiled it and read its uniform list. Claude made the two
materials (`hint_source_color.tres`: true, `hint_raw.tres`: false), both bound to the same
PNG, with a one-off `ResourceSaver` script. Claude also wrote `godot/showcase/hint_experiment.tscn`.
It has two quads facing the camera and a WorldEnvironment with a Linear tonemap, exposure 1.0,
and glow, fog and adjustments off.

One frame from the real renderer (`evidence/hint_experiment/`): the source_color quad reads
64/128/192 and the unhinted quad 137/188/225. That is exactly CHANGE-BRIEF §7's prediction, all
six values. Rui's own look at the scene is still part of the human checks.

## 2026-10-28 — Session 3: the material audit, and a range Claude missed

**Run** (`prompts/prompt-3.txt`, the course text verbatim; `sessions/session-3-audit.jsonl`;
35 turns, $2.13). Before the run Claude pointed out that the prompt's "which I checked myself"
speaks for Rui. Rui checked the Poly Haven page and licence against `ATTRIBUTION.md` first:
"核对好了，运行". The run had 6 permission denials, all from running the test as
`bash scripts/run-test.sh` or a compound command. It then used `./scripts/run-test.sh`. No
shader, material, scene or `.import` file changed. Committed unedited as `d6dc475`. Claude read
the test, not only the summary: values come from the materials, hints from the source text,
imports through ConfigFile, plus the engine's uniform list. Claude's own rerun: 132/0.

**Claude's error, caught by the audit.** When Rui fixed `roughness_scale`, the next uniform,
`normal_strength`, also went from `hint_range(0.0, 2.0, …)` to `(0.0, 1.0, …)`. Claude's re-check
grepped only the two uniforms it had asked about. The entry above therefore says "7 uniforms whose
types and hint ranges match the table", which was wrong for `normal_strength`; ShieldB's 1.15 was
above the declared maximum. The agent's finding 1 caught it. Rui's first fix of line 33 also
changed line 30 again. This time Claude diffed the whole file instead of grepping, saw it, and Rui
corrected it. The final diff against `416e5f5` is the single number on line 33. From now on,
Claude checks a shader edit by diffing the whole file.

**The test pinned the wrong value too.** With Rui's fix, test_materials failed exactly the two
`normal_strength` checks (130/2, `evidence/audit/test_materials_shader_fixed_test_not_yet.txt`).
That shows it reads the real hint. Claude then updated the expectation; 132/0.

**Review** (separate commit): MATERIALS.md findings 1–2 marked resolved, plus a section
recording the corrections. The course asks for the enum labels to be checked: Claude measured them
with `get_image().get_format()` (2 → DXT1, normal_map 1 → RGTC, 0 → uncompressed L8/RGB8;
`evidence/audit/import_enums_vs_formats.txt`). CLAUDE.md's outdated material and line references
are updated (finding 2). The agent got the attribution right: it used only the brief's facts and
said that the author and licence are not in the brief, rather than copying or inventing them.

**Fresh cache.** Claude deleted `godot/.godot` and ran `godot --headless --path godot --import`
(exit 0, `evidence/audit/fresh_cache_import.log`). The reimport changed no `.import` file
(`git status`), so the explicit settings hold. From the empty cache: test_materials 132/0,
normal_map_check 9/0, test_rules 23/0, test_input 14/0, test_burning_tint 49/0, all at 60 fps
through run-test.sh.

## 2026-10-28 — Mutation 3: source_color removed from the albedo sampler

Rui removed `source_color, ` from `shield_wood.gdshader:7`, the albedo sampler, by hand. The
whole-file diff showed that one change (`evidence/mutations/m3_source_color.diff`).
`./scripts/run-test.sh test_materials.gd 60` exited 1: 130 passed, 2 failed
(`m3_source_color_test_materials_60fps.log`). Both failures come from reading the source text:
the sampler's hints as written, and the Failure 4 check that only the albedo sampler has
`source_color`. Every check based on `get_shader_uniform_list()` still passed, because the engine
reports a sampler only as a Texture2D resource, with or without `source_color`. As with mutation 2,
the property that matters is caught only by a check written for that property. Rui restored the
line. The whole-file diff against `822d27a` was empty, and test_materials was back at 132/0.

## 2026-10-28 — Controlled-value captures for the Burning tint

`godot/tools/capture_burn_values.gd` (Claude, at Rui's request: "写截图脚本") puts five
scarecrows on the real meadow and freezes them by disabling World, so the driver does not run.
Each scarecrow's own material gets one `burn_mix` value: 0.0, 0.5, 0.65, 1.0, 2.0. The script
saves one frame from the real renderer (Forward+, RTX 3070 Laptop, 1280×720, hdr_2d false) and
reads CHANGE-BRIEF §6's three named pixels on each scarecrow. Output is in
`evidence/controlled_values/`.

- **15 of 15 pixels match** the colour line, within one 8-bit step. Every value at 0.0, 0.65 and
  1.0 is exact, and so is every value at 2.0. At 0.5, the three half-integer channels the brief
  flagged as ±1 (patch green 146.5, patch blue 30.5, head green 188.5) came out 146, 30 and 188.
  They rounded down, inside Rui's ±1.
- **`burn_color` is not linearised.** At 1.0 every pixel is exactly (255, 192, 32), so the
  `source_color` uniform reaches this canvas_item shader as written with HDR 2D off. This was
  the brief's unconfirmed reading of the engine (§6 and CLAUDE.md "Unconfirmed"); it is now
  observed.
- **`hint_range` does not clamp a value set from code.** The material reads back 2.0. The
  captured pixels are the colour line at 2.0 with only the output clamped, for example straw
  (255, 188, 0) and patch (255, 255, 35). They are not the clamped-to-1.0 result, (255, 192, 32).
  That confirms Rui's prediction in short answer 7.
- What it looks like (Claude's description of `burn_values_zoom.png`; Rui's own look is still
  to come): at 1.0 the sprite is a flat silhouette and the outline, face and patch are gone. At 2.0
  the details come back, inverted towards bright yellow. The gameplay maximum, 0.65, keeps the
  details visible.

## 2026-10-29 — LANGUAGE-NOTES, and a question the shaders could not answer

Rui wrote `LANGUAGE-NOTES.md`. Claude checked only that each line reference points where it says,
and pointed out factual problems without writing replacement text. All references were right except
two ranges that stopped one line short of a closing brace. The real problem was question 3, "Name
three built-ins you read": Rui's three shaders read only `COLOR` and `UV`, and the first draft
counted `UV` twice. Rui asked "所以第三题的问题怎么解决" and then "之前为什么没有弄第三个内置变量".
The honest answer is Claude's: the Step 4 questions were in the course text from the start, but
Claude checked each shader only against its own step and never against the later questions that
would cite it. By then the tests, captures and mutations all depended on the shaders as they were,
so Rui chose to state in the notes that only two built-ins are read rather than change a shader.
From now on Claude checks a design against every later question that will cite it, before Rui
writes the code. Committed as Rui's own text, `8626c1a`.

## 2026-10-29 — Rui's playtest: two gameplay faults, fixed off main

Playing normally, Rui found two faults that are not in the tint:
"横向距离远的时候子弹瞄准的过于靠后会导致打空" and
"小怪到墙前面开始打墙后子弹打不中墙了". Rui wanted the second fixed at once and the first later,
together with homing and fixed-trajectory arrows.

Claude reproduced both headlessly. Arrows aim at the scarecrow's current position with no lead: at
600 px sideways the arrow flies 0.77 s, the scarecrow moves 35 px, and the closest approach is 29 px,
outside the 26 px hit radius. Scarecrows stopped at y 570 and the archer stands at 572, so a
scarecrow at the wall is about 90° off the 120° upward fire cone and is targeted only within 3 px.

The A5 boundary (course text, CLAUDE.md "Out of scope") forbids changes to targeting, game logic and
existing tests, so Claude asked where the fix should go. Rui chose a separate branch on the question
card. The fix is on `gameplay-fixes` in its own worktree (`../walker-mimic-keep-rui-sun-fixes`) and
stays out of main until after the `a5` tag. Rui chose to move the stop line up. Claude's first value,
500, worked but Rui wrote: "打得到了，但是停止线太远了，完全看不出怪在打墙，可以适当近一点然后以后给怪加上动辄动作"
("动辄动作" is presumably 攻击动作, an attack animation). Rui picked 530 from renders at 500, 520, 530
and 540, played it, and wrote "可以提交，别的试玩也没什么问题，开始下一步吧". New
`tests/test_wall_targeting.gd`: 3/7 on main's stop line, 10/0 on the branch at 30, 60 and 144 fps.
Every earlier suite kept its count, and balance_sim was unchanged (idle 1/8, chase 8/8). Commit
`dbb4806` on `gameplay-fixes`.

One confusion on the way: Rui first reported "还是打不到正在打墙的怪物". The running editor's
command line showed it had the main project open, not the branch. Claude launched the branch build
directly and the second playtest hit.

## 2026-10-29 — Use It captures, and a screenshot of the whole desktop

Rui's screenshot tool lagged ("我截图有延迟，截不到死亡的那一帧，没有要求我截的话剩下的你想办法截图吧"),
so Claude wrote the remaining capture tools: `capture_in_play.gd` (scripted ignite and kill in the
real game, labelled scripted), `capture_shield_room.gd` (the interface sweep and single shots),
`os_screenshot.ps1` with `compare_os_screenshot.gd` (the course's one OS-screenshot comparison),
and a hold mode in `capture_burn_values.gd`.

**Claude's error.** The first version of `os_screenshot.ps1` grabbed the whole 2560×1600 desktop.
The image showed Rui's name and seat, this chat, the session list and the taskbar, and Claude
committed it (`87e54a0`) before looking at it. Claude found it when opening the image after the
commit. Nothing had been pushed (there is no remote). The script now grabs only the game window's
client area, the comparison was rerun (same result), and the unpushed commit was amended to
`65800cd`, so no commit on main contains the desktop image. From now on Claude crops a screen
capture to the target window when it is taken and looks at every image before committing it.

The comparison itself: the 15 named pixels are identical in the in-engine capture and the OS
screenshot; 618 of 921,600 pixels differ, at the window's rounded bottom corners and along the
archer's face and belt and the gate edges. The cause of the last two is not established.

The sweep first ran every uniform on ShieldA. At its `scorch_amount` of 0.05 the Damage uniforms
barely showed, so Claude moved those three to ShieldB and reran. Claude wanted to delete the old
sweep files first; the deletion was blocked by a safety check, and the rerun overwrote the same
file names instead.

## 2026-10-29 — Human checks and the two edit tests

Rui wrote `my-observations.txt` (committed unedited in `0bd5acb`). Claude checked it against the
images and data and found no factual error. Claude suggested three optional changes: a typo, saying
that the band values come from `band_values.txt` rather than the eye, and recording specific
playtest looks. Rui made the first two. When TEST-REPORT marked five looks from the brief as not
separately recorded, Rui answered: "1.结束时消失了 2.淡出部分比较平滑 3.再次被打中颜色刷新明显
4.暂停时颜色不变5.能看清稻草人的细节".

The two edit tests were done by hand: Rui edited the shader and the material, and Claude captured
the frames and checked each step. Rui multiplied `shield_wood.gdshader:68` by `vec3(0.3, 0.3, 1.0)`.
The whole-file diff showed only that line, and both shields changed (98,610 pixels in each half of
the frame). Rui restored it: md5 `c69c4d88` again, and the frame was byte-identical to the one taken
before. Rui then set `scorch_amount` 0.05 → 0.8 in `shield_new.tres` in the Inspector: only ShieldA
changed (0 pixels in the right half). Saving also made the editor add uids and write the default
`scorch_color`, so after Rui set the value back, Claude restored the file's committed text with git.
The frame was byte-identical again, and test_materials 132/0.

Running `hint_experiment.tscn` from the editor rewrote it: six Environment lines equal to their
defaults were dropped, and uids were added. Claude loaded the rewritten scene and read the same
environment back (black background, Linear tonemap, exposure 1.0, glow, fog and adjustments off,
fov 45), and committed it on its own, `b77e30d`. No `.import` file has been rewritten by the editor.
Rui deleted the scratch scene `godot/node_3d.tscn` from Step 4 ("删掉"); it was never tracked.

TEST-REPORT.md (`5dacf8f`) records every suite at `b77e30d` and the human checks above.

## 2026-10-29 — The film

Rui asked for it ("做影片") and, before going out, for everything that needed approval in one list:
"我马上要出门吃饭，把做影片中要我批准的先列给我让我批准一下". Claude listed nine items (structure, a new
4K capture, the voice, the labels, the five named agent mistakes, the next step, the jingle, where files
go, render time). Rui answered "全部批准" on the question card. Claude then built the film alone; the
records are in `youtube/claude-liam-walker-mimic-keep-a5-gamedev/`.

What did not go to plan (Claude):
- The narration first came to 1,503 words, about ten minutes against the approved five to six. Claude
  cut it to 1,158; the master is 6:13 with 26 beats, slightly over the plan.
- The first in-play take pressed the move keys towards the nearest scarecrow. Every scarecrow died at
  the top edge within about two seconds, so the tint was barely on screen; dropped. The next take, with
  no keys pressed, recorded 75 s of empty meadow because Claude's driver only enabled spawning for the
  first take. After a headless dry run of the fixed driver, the third take (50 s) was used, and the
  narration changed from "the archer slides along the wall" to "running with nobody at the keys".
  The dry run also showed the gate falling at about 56 s with nobody playing: the wall fault Rui found.
- The fade take was 9 s, shorter than its 11 s narration; it was re-recorded at 12 s rather than held.
- Review of the rendered scenes found three layout faults (B01's corrected line overflowed, B18 lost a
  line, B20 pushed the key line 19 out of the code panel), and the board component labels every excerpt
  "GDD", which these are not. Claude added an optional label prop to the toolkit's `GodotDesignBoard.tsx`
  (local, disclosed in `toolkit-local-patch.diff`). The first compile showed Rui's playtest still as a
  blank slate (stills must be copied to `media/`); the second was refused by the frame QC (two
  edge-bleeds, an overlong verdict, an underfilled title). The third passed: 0 BLOCKER, 0 MAJOR.
- `verify_gamedev.py` passed (62 files, 8 excerpts, 8 code → result pairs). It checks hashes and lines,
  not whether the explanation is right; FACTCHECK.md ties each narrated claim to a file.

Rui watched and listened to the master: "我看没有什么问题，在最后提交前再核对一遍作业要求".

## 2026-10-29 — Checking the submission against the assignment text

Claude re-read the course text section by section against the repository. Most requirements were met;
five were not, and Claude fixed them after Rui's "修吧":
- CLAUDE.md had grown to 128 lines, over the 120-line limit, through Claude's own additions after the
  review (it was 118 then). Shortened to 118 without dropping a fact or a reference. Two of its README
  line references had gone stale when Claude added the capture tools to README; both now point at the
  right lines.
- README still said "Burning has no visual yet". It now has "What Assignment 5 added", a "Film" section
  (link still to come from Rui's upload) and current limitations, including the two gameplay faults.
- SOURCES.md did not say which files Rui wrote by hand, which the agent sessions wrote, or which of
  Claude's suggestions Rui adopted; it does now, with the film's tools.
- The film's records were not in the repository; they are now, without media.
- This entry and the one above.

# Assignment 6 — Particle effects

## 2026-11-05 — Before the brief: the wall fix merged, the new wrapper, the baseline

The wall-targeting fix from Rui's 2026-10-29 playtest (`SCARECROW_STOP_Y` 570 → 530, new
`test_wall_targeting.gd`) had been kept off main because Assignment 5 forbade gameplay changes. A6
forbids them too, so it had to land before the A6 baseline or wait until after A6. Rui chose "先合并吧".
Claude merged `gameplay-fixes` with a merge commit (`48886bb`), so the history shows it arrived after
the `a5` tag, which still points at `f71d358`. There were no conflicts; every suite passed on the merge.

Claude then replaced `scripts/run-test.sh` with the assignment's wrapper, verbatim, in its own commit
(`ddaaa53`), and took the baseline through it after `--import` (`056bcc0`, copies in
`evidence/a6-baseline/`): test_rules 23/0, test_input 14/0, test_materials 132/0, normal_map_check
9/0 at 60 fps; test_burning_tint 49/0 and test_wall_targeting 10/0 at 30, 60 and 144 fps. No log
contains SHADER ERROR or SCRIPT ERROR. `check-session.sh` already diffs `godot/shaders/` and
`run-test.sh` against HEAD, so it needed no change.

Effect B: Claude listed four candidates (burning embers, gate smoke, meadow ambience, fire-arrow
trail) with what each would show and where it would be hard. Rui chose burning embers.

## 2026-11-05 — CHANGE-BRIEF: Rui's specification, Claude's review

**Rui** wrote CHANGE-BRIEF.md: both jobs, the `hit_taken` boundary exception, both intent blocks, the
settings for all four emitters, rules A1–A4 and B1–B7, boundaries, evidence split, both frame strips,
nine predicted failures, the price predictions and budgets, and the six answers. Rui's text as saved is
commit `b1d2e08`. The first "改完了" found the file unchanged on disk; Rui had not saved it yet.

**What Claude checked.** Every file and line reference in the brief was correct (`scarecrow.gd:8/9/16/
33-39/42-46`, `arrow.gd:22`, `main.gd:95`). Claude probed Godot 4.7.2 headless for the facts the
settings depend on:
- CPUParticles2D has no `amount_ratio` and no turbulence; GPUParticles2D has `amount_ratio`,
  `use_fixed_seed`, `seed` and `finished`. The brief's node choice holds.
- `ParticleProcessMaterial.initial_velocity` and `scale` still exist in 4.7.2, as editor-only `Vector2`
  range properties that are not stored. Setting a float to them is ignored silently and min/max stay
  0, which is what the brief's Failure 1 predicts. To be confirmed by the Step 2 mutation.
- A `Curve` defaults to the range 0–1 and stores 1.2 as 1.0 without a warning. The brief's scale
  curves peaked at 1.20 and 1.40.
- `direction` defaults to (1, 0, 0), to the right, and `particle_flag_disable_z` to false. The brief
  described "upward" emitters but did not set either.

Claude also computed what the settings would produce: A2's spread of 150° would throw straw about
95 px to each side, over three times the scarecrow's 56 px width the intent allowed; Effect B's first
frame could hold at most one ember (explosiveness 0, 20 embers per second), not the "full density" the
strip predicted; and arrows' different flight times let three A bursts overlap, not two. The reset in
`main.gd:37-40` never clears a new `World/Effects` node, and no rule freed finished bursts. Claude
measured the scarecrow's head at 23–25 px wide, so the flash's 21 px peak stays smaller than the head.

**How the corrections went in.** Rui chose the Assignment 5 way ("按 A5 的办法"): the original stays at
`b1d2e08`, the file is corrected in place before the first prompt, and the Revision Log lists the
changes. Claude converted the file to Markdown and applied the factual corrections; a word-by-word
comparison with `b1d2e08` showed no other wording changes. Claude proposed values for six items;
Rui approved all six ("1–6 都同意"): curve points with `Curve.max_value = 1.5`, A2's colour-ramp stops,
texture paths and sizes, A2 spread 150° → 40°, A2 angle 0–360, and the `World/Effects` node with a
new Rule A5 (cleanup and reset).

**What Rui wrote after the review:** the phase durations in both intent blocks, the emission
rates, the Effect B frame 10 and 20 predictions, Rule A3 and answer 3 for three overlapping bursts
(66 particles), Failure 2, the Effect B peak (ten effect sets, about 260 particles), new budgets
(A 0.25 ms, B 0.60 ms, combined 0.85 ms GPU time), answer 4 (a headless run reports CPU time close to
the empty-scene control), and the Revision Log entry dated 2026-11-05 without "(review)". Claude did not write these.

Still a prediction, to be measured: whether a GPUParticles2D keeps its live particles when it is
reparented to `World/Effects` on death (Rule B4), and whether a hidden GPU emitter keeps simulating
(Rule B6).

## 2026-11-05 — Step 1: the CLAUDE.md draft and its review

The course's `claude` shim pointed at a CLI folder (2.1.308) the desktop app had since removed, so
the command failed before any session ran. Claude changed the shim in `~/bin` (outside the repo) to pick
the newest bundled `claude.exe` at run time; 2.1.317 was logged in already. A6's prompts and transcripts
go in `prompts/a6/` and `sessions/a6/`, because A5's `prompt-1.txt` and `session-1.jsonl` already exist.

Session 1 ran `prompts/a6/prompt-1.txt` (verbatim) with the assignment's read-only allow list.
`check-session.sh`: success, 37 of 40 turns, nothing under `godot/shaders/`, `run-test.sh` unchanged,
only `CLAUDE.md` modified. Two permission denials, both compound Bash commands (reading
`evidence/a6-baseline/`; `wc` + `awk` on CLAUDE.md); the draft's baseline numbers are still right,
taken from commit 056bcc0's message. The draft (119 lines) was committed unedited as `a74efc8`.

**Claude's check of the draft:** every cited line range (README, project.godot, scarecrow.gd, main.gd,
main.tscn, scarecrow.tscn, both tests, check-session.sh, FRICTIONAL) was printed and says what the draft
claims. Claude probed the assignment's three Headless facts lines on this machine
(`evidence/a6-probes/`): the dummy renderer has an empty adapter name and an empty `capture_rect()`,
and a 0.3 s one-shot still fires `finished` and drops `emitting` at 0.3 s, so node state is observable.
The price line could not be confirmed: `Performance.TIME_PROCESS` read 0.0000 ms with 50 × 200 GPU
particles and with none, so that monitor measures nothing here. That line waits for the Step 7 cost
script, which must not use this monitor.

**Review edits, proposed by Claude, approved by Rui ("都同意"):** Headless facts lines 1 and 3 with the
probe as evidence; `finished` and `Curve.max_value` moved from "Unconfirmed" to facts; the draft's advice
to trust `get_property_list()` replaced (that list contains the Godot 3 name `initial_velocity`, so it
cannot catch one); file references for the 60-tick fact (the a5 brief, revision A) and the shim line
removed (no file in the repo records it); "instance burst scenes" added to the driver's duties; the
new tests' frame rates, citing `prompts/a6/prompt-2.txt` and `prompt-3.txt`, which were saved verbatim
for that (`e5a4804`, not sent yet). Claude then shortened lines to stay at 119.

## 2026-11-05 to 11-08 — Step 2: Effect A built by the agent, then checked

Session 2 ran `prompts/a6/prompt-2.txt` (verbatim) non-interactively with the assignment's build
allow list and `--disallowedTools Edit(godot/shaders/**)`. **The allow list had one entry the
assignment does not give:** `Bash(godot --headless --path godot --script
res://tools/make_particle_textures.gd:*)`. The brief (§3) says the particle textures are generated by
that committed script, and the build list has no way to run a Godot tool script, so without it the
agent could only have asked for the PNGs to be made by hand. The entry is limited to that one script
path; it is disclosed in commit `2f5a871`'s message and here.

`check-session.sh`: success, 26 of 60 turns, about 196 s, nothing under `godot/shaders/`,
`run-test.sh` unchanged. Eight permission denials: three compound read commands (PowerShell and Bash
`;` chains), three attempts to write or run a Curve probe script in its scratchpad, `bash scripts/run-test.sh`
(the list allows `./scripts/run-test.sh` only), and a headless run of the preview. The agent then
reran the config test as `./scripts/run-test.sh`, so the output in its report is a real run. The
scene, config test, preview and texture tool were committed unedited as `2f5a871`.

**What the agent said it could not verify, and how each one ended:**
- How 4.7.2 stores `Curve.max_value`: it wrote the line by hand. The config test reads back
  `max_value = 1.5` and the point (0.33, 1.2), so the value loads; how the editor would save it
  is still unchecked.
- The preview had never run: Claude ran it headless after the seed edit (both bursts at frames 10
  and 28, no script error); Rui then ran it windowed.
- Whether frame n of `_process` is Movie Maker file n: in strip r0 the flash first appears in
  `frame00000010.png`, so the numbering holds; the strip needs no offset.
- Generate Visibility Rect is an editor action: Rui did it (below).

**Claude's check.** Config test rerun: 128/0 at 60, exit 0. Every value in the scene was compared
with the brief's §3 line by line and matches. Two gaps: the preview never set `use_fixed_seed`, which
the assignment requires on the preview instance; and the agent's capture command wrote to
`evidence/a6-strips/` with `$PWD`, but the assignment's path is `captures/<effect>/r<N>/`, and in
Git Bash `$PWD` is a `/c/...` path Godot cannot use, so the command uses `$(pwd -W)`. Rui chose
"先加固定种子": Claude added a per-hit seed (7270 + 100 × hit + emitter index) to the preview only
(`f872239`); the effect scene still loads with `use_fixed_seed = false`.

**r0, in the required order.** Rui ran the preview windowed at 1280×720 and wrote what they saw;
Claude added it to TUNING.md verbatim and committed it (`6938b15`) before opening any frame. Rui
captured r0; Claude kept frames 10, 12, 15, 20, 30, 50 and deleted the other 64 and the `frame.wav`
track Movie Maker writes alongside (`06527db`). Claude's reading agreed with Rui's note: the straw's
first ramp colour `#e8c46b` is the scarecrow body's `#e9c46a`, and the straw stays above the hit
point for its whole life. That reading is held for Step 4; no setting has changed.

**Mutations (Rui: "做变异测试"; Claude ran them, TEST-REPORT A6.1, `3776b12`).** The Godot 3 name
`initial_velocity` failed the config test (127/1) and confirmed the brief's Failure 1: 4.7.2 loads
it with no warning and the effect still fires, with `initial_velocity_min` at 0. Value drift (Straw
spread 40 → 55, brief unchanged) also failed it (127/1). To show the mutated effect still fires,
Claude made one windowed Movie Maker run into its scratch folder; only a 3× crop of frame 12 next to
r0 is kept, labelled as a fixture capture.

**Visibility rects (Rui, TEST-REPORT A6.2, `c0ae02b`).** Rui's first screenshots showed the scene's
own values, because the generation had been undone before the screenshot was taken. On the second try
both generated rects fit inside the scene's rects. The editor also wrote `.uid` files for the agent's
two new scripts; they are committed with that check.

## 2026-11-08 — Step 3: Effect A wired, plan first

Two invocations, as in Assignment 5. **Plan run** (`sessions/a6/session-3-plan.jsonl`/`.md`,
`prompts/a6/prompt-3.txt` verbatim, read-only tools with Edit and Write disallowed; 4 turns, 0
denials): a spawner node in `scarecrow.tscn`, `World/Effects` with an `"effects"` group, and a state
test at 60. The plan asked whether the group counts as part of the one allowed `main.tscn` node and
whether the spawner may live in the scarecrow scene.

**Claude's review of the plan** recomputed its timing from the code: arrow 900 px/s from y 548,
26 px hit radius, so the far scarecrow at y 0 is hit after about 0.57 s and the near one at the wall
after about 0.02 s, which leaves three bursts alive at the third impact; the fourth arrow kills N
at about 2.8 HP. Three gaps: no `burning_ended` would ever fire in its scenario (N dies burning, F
keeps being re-hit), so one A1 clause was untested; the spawner set `position` before `add_child`
and relied on `World/Effects` sitting at the origin; and nothing said what to do if the arrow timing
was flaky. Rui: "批准，加三条补充". Claude drafted `prompts/a6/prompt-3b.txt` from that answer
(`13fdb56`), accepting both assumptions and adding the three changes.

**Implementation run** (`sessions/a6/session-3-implement.jsonl`/`.md`, the assignment's build allow
list with no extra entries, 41 of 60 turns, 0 denials, shaders and `run-test.sh` unchanged):
committed unedited as `7296a1d`. Claude read every changed line: `scarecrow.gd` gained only the
signal and its emit, `main.tscn` only `World/Effects`, and the test contains no call to `hit()`,
`ignite()` or the spawner and no write to `hp` or `burn_time_left`. The burn-out case holds up: 0.6 s
after the hit the archer has moved to x ≈ 892, about 69° off vertical from the scarecrow, outside
the 60° half-cone, so exactly one arrow lands. Claude reran all twelve suite runs through
`run-test.sh` and got the agent's numbers (TEST-REPORT A6.3). The agent's own first two runs of the
new test stopped on its parse errors, which it fixed.

One side effect: the agent's edit left `scarecrow.gd`'s working copy with CRLF line endings. The
committed file is LF and identical apart from the two added lines; Claude refreshed the working copy.

**Rui's playtest** confirmed A1, A3, A4 and the freeze at game over (quoted in TEST-REPORT A6.3).
Whether the frozen burst then finishes after R is measured headlessly but was not looked at.

## 2026-11-08 — Step 4, round 1: the burning tint in the fixture, and auto mode

**The fixture did not match the game.** Rui's preview note said the straw could not be seen during
the flash; their in-game note said it could. Claude found one difference: every in-game hit is a fire
arrow and `ignite()` runs before `hit_taken`, so the scarecrow is burning-tinted while its burst plays,
but the preview sprite was plain and the same colour as the straw's first ramp stop. Rui chose "先加染色"
(`c154122`, preview only, Rui's shader referenced and not edited). The r0-tinted strip showed the
tint explains only part of the gap (TUNING.md). Rui asked which steps were required; Claude separated
the assignment's requirements (a strip that matches the current fixture, an in-game observation for
the loop) from its own optional check (a separate windowed look), and Rui did only the capture.

**Round 1.** Rui first said nothing needed changing. Claude explained that at least one revision per
effect is required and may end in "reverted", and that it needs a concrete observation, not a wish
list. Rui watched the game and wrote one: the flash's start may hide the straw flying out; try it
darker. Claude put it verbatim into the assignment's prompt (`946c797`). In Rui's interactive `claude`
session the agent proposed one setting (Flash ramp alpha); Claude checked the values and the test line
before Rui approved. The comparison found the change worked on grass but barely on the tinted body,
and that the straw is drawn on top of the flash, so the flash never hid it. Claude checked two of its
measurements independently. Rui: "保留"; Claude wrote the brief's dated revision (`765b0b4`).

**Auto mode skipped the edit checkpoint.** Claude launched the interactive session without Edit in
the allow list so every file change would ask Rui. Rui's `claude` defaults to auto permission mode:
the agent changed both files with one compound `cd …; sed -i …` Bash command, which auto mode allowed
without a prompt ("Allowed by auto mode"). The approval that matters, of the proposal, came before the
edit, and Claude's diff showed exactly the two approved lines, nothing under `godot/shaders/`. Later
interactive runs add `--permission-mode default`. The session transcript is copied into
`sessions/a6/` when Step 4 ends; the first attempt to copy it was blocked by Claude's own permission
classifier.

## 2026-11-08 — Step 5, Effect B: build, first look, mutations, visibility rects

`prompts/a6/prompt-5.txt` is prompt-2 with the two substitutions Step 5 names ("Effect B"; the
preview starts the condition at frame 10 and ends it at the brief's frame). Claude added a short
block, disclosed in `1a31d26`: the brief's process feature (turbulence) and `amount_ratio` in the
config test, `smoke_dot.png` from the texture tool, a fixed seed on the preview instance only (the
gap Step 2 left in Effect A's preview), and a burning-tinted preview scarecrow plus a re-ignite
export, so the fixture matches the game and the brief's second strip.

Session 5 used the same allow list as session 2, including the one extra entry for the texture tool
script. `check-session.sh`: success, 39 of 60 turns, nothing under `godot/shaders/`, `run-test.sh`
unchanged; 9 denials (compound commands, PowerShell runs of the texture tool, `bash
scripts/run-test.sh`, a python edit, headless preview runs). It ran the tool and the test in allowed
forms. Committed unedited as `df6937c`. Claude compared every scene value with the brief's §3 (all
match), reran the config test (154/0) and ran the preview headless: ignite at frame 10, end at 130;
with `--reignite`, again at 100 and end at 220. Two things the agent chose or got wrong: the draw
order (Smoke first, so the additive embers sit on top; the brief does not say), and the capture path
again (`../evidence/a6-strips/...`); Rui used `captures/burning_embers/r0/` with `$(pwd -W)`.

**First look, in order.** Rui watched the preview windowed and wrote that the gradual weakening is not
very noticeable; Claude committed it (`6a4375e`) before reading the strip (`afb5c4b`). Claude's
reading agrees: the ember counts follow the brief (about 1, 5, 10, 6, 4, 3, 0), but most embers spawn
over the burning-tinted body, where additive yellow clips as Effect A's flash did, and the smoke is
very faint; the fading tint is the strongest cue. Held for Effect B's tuning round.

**Mutations** (TEST-REPORT A6.4, `3ca359b`): the Godot 3 name and a turbulence drift both fail the
config test (153/1); the first again loads silently and the effect still runs.

**Visibility rects** (TEST-REPORT A6.5). The scene stores `amount_ratio = 0`, so Claude told Rui to
set it to 1 before generating. No generation-time dialog appeared, so Claude's instruction to set
2.0 s could not be followed and the default was used. Rui swapped the two screenshots at first and
corrected it; Claude's first comparison was made with the wrong pairing ("12 px below, left edge
touching") and was withdrawn once Rui corrected it. With the right pairing both rects reach 1–2 px
below the scene's rects, which cannot cause culling here; Rui kept the brief's values ("保持原样").

## 2026-11-08 — Step 5, Effect B wired, plan first

`prompts/a6/prompt-6.txt` is prompt-3 with "Effect B" and the four replacement test rules Step 5
gives, plus one sentence of Claude's (do not change Effect A's files). **Plan run**
(`sessions/a6/session-6-plan.*`, read-only, 19 turns, 0 denials): a driver on a `BurningEmbers`
instance in `scarecrow.tscn`, reparenting to `World/Effects` on `died`, and a ten-scenario test.

**Claude's review** found the plan covered B1–B7 and named its own risks (a reparent inside `died`;
Effect A's test counting B tails). Claude added one: the scenario timing rests on real arrows, burn
damage and 10 gate damage per second from two wall scarecrows, so S1 could burn to death before its
burn-out scenario or the run could be lost early. Rui: "批准，加补充"; Claude drafted
`prompts/a6/prompt-6b.txt` (`2acb30d`) with a report-and-stop rule and no writes but `burn_time_left`.

**Implementation run** (`sessions/a6/session-6-implement.*`, build allow list, no extra entries, 47
of 60 turns, 1 denial for a piped `run-test.sh`): committed unedited as `e3fd90f`. No stop condition
came up (S1 burnt out with 12.2 HP; the gate had 38.6 HP before scenario 10; the reparent worked
without `call_deferred`). The agent fixed a `SCRIPT ERROR` in its own helper after a 54/0 run,
changing no assertion. Claude read the driver (reads only signals and `burn_time_left`, never
`amount`) and grepped the test for writes; reran every suite (TEST-REPORT A6.6).

**Effect A's test, as predicted.** The agent reported, without changing either test, that A's INFO
counts moved: N's B tail is a child of `World/Effects` at hit 6. Claude checked the one assertion at
risk with a scratch copy of A's test (outside the repo) that prints `World/Effects` at the loss: the
child was an `ImpactBurst`, so the assertion still holds on a real burst. The counting stays fragile
and is recorded, not changed.

**Rui's playtest** confirmed B1, B2, B3, B4 and the pause freeze (TEST-REPORT A6.6). In the game Rui
saw the density fall, unlike their preview note; that difference is logged in TUNING.md for Effect B's
tuning round.

## 2026-11-08 — Steps 6–7, Effect B tuning, Use It: the deadline evening

Rui said the submission was due that night and asked Claude to stop asking for anything the assignment
does not require of them. From then on Claude asked only for what must be Rui's: one in-game
observation, the approval, the capture, the verdict and its reason, the human checks, and Step 6.

**Step 7** (`prompts/a6/prompt-7.txt`, verbatim; session 7, 26 turns, 1 denial): the chapter's
Example 09 is not in the repository or the course folders, and the agent said so instead of claiming
to adapt it. Its script separates the cases (empty 6 µs, off 57–64, A 77–89, B 106 per frame) and
shows `TIME_PROCESS` reading 0.0000 throughout. It starts the effects with `ignite()` and `hit_taken`
directly, which a cost script may do. Claude reran it (`evidence/a6-cost/`).

**Effect B round 1.** Rui's in-game observation: the hit flash and the burning effect overlap. Claude
ran the loop as `claude -p` invocations instead of an interactive session, which the assignment allows:
a read-only proposal (`bcab840`), Rui's "批准", a `--resume` that made the edit, Rui's capture of r1,
and a read-only `--resume` for the comparison. The agent traced the overlap to shared texture, blend
and colour, and proposed a fade-in on the Embers ramp. Its comparison admitted the change was much
smaller than predicted, for the same clipping reason found in Effect A r1; it could not run pixel
measurements under the read-only list, so Claude measured them. Rui kept the change ("闪光和余烬现在有了
一点区分度了"). Claude wrote the brief's dated revision (`becb508`).

**Use It and Step 6, by Rui.** Rui ran the human checks in the editor and sent them in one message:
GPU time 0.06–0.07 ms with and without effects on the RTX 3070 Laptop GPU; every hit burst present;
sizes, backgrounds, screen edges and scene load fine; smoke the least visible part. Rule B6 came out
against Rui's prediction: the hidden emitter paused rather than kept simulating, and Rui wrote that
down as a difference. Rui generated `particles_generated.gdshader` (`34d1e1d`, committed alone) and
gave nine line references; Claude printed each line and all nine were right. Claude wrote TEST-REPORT
A6.7 around Rui's quoted words.

A long shell heredoc for that section failed to parse and wrote nothing; Claude checked the file,
then appended the same text from a file instead. Earlier, a commit (`d4c2f3f`) went in with Effect A's
verdict reason still blank after an edit failed; `a78fddd` completed it.

## 2026-11-08 — The A6 film

Claude built the film on the A5 reel's scripts, locally (Kokoro, Remotion, Godot Movie Maker), and Rui watched
the final export ("没有什么问题") and uploaded it. What went wrong on the way, all fixed before the master:
- The first in-play take (spawning on, no input) was unusable: every scarecrow died at the top edge under the HUD.
  Claude replaced it with a take that places scarecrows by script, as the state tests do, while the archer fires
  real arrows; the label says so. The dropped take's log also had a closure bug (wrong frame numbers).
- The first burn take was 12 s, shorter than its 14.7 s narration; it was re-recorded at 16 s rather than retimed.
- Fact-checking the narration against the take logs changed three lines (the middle scarecrow dies while
  burning instead of burning out; "one gameplay change", not "line"; the swapped screenshots).
- `verify_gamedev.py` requires each code beat to be followed directly by a result beat with media, which the
  first beat order broke twice; Claude swapped two rendered beats and turned B15 into a still of verbatim log
  lines. The compiler then used B15's stale render until it was moved aside, which Claude found in the compile
  log before anyone watched.
- The toolkit's Gate F blocked the first compile until FACTCHECK, SHOTLIST and PROMPTS were written.
Records: `youtube/claude-liam-walker-mimic-keep-a6-gamedev/` (BUILD-PROMPT.md lists every deviation).

# Assignment 7 — Doing animation

## 2026-11-19 — Before the brief: the new wrapper and the baseline

The A7 `scripts/run-test.sh` replaced A6's verbatim and was committed alone (`1f3fad7`); it adds
`Failed loading resource` to the lines that fail a run. The 14 earlier suite runs went through it unchanged
(`292fe05`, `evidence/a7-baseline/`): the same pass counts as at the A6 tag, no error lines. Rui chose the two
clips (scarecrow walk as the cycle, archer shot as the committing action), a code-generated sheet, the arrow
waiting for the active frame, and an AnimationTree state machine. Claude had recommended a script state
machine for easier frame-exact edge tests; Rui chose the AnimationTree because A8 builds on it.

## 2026-11-19 — CHANGE-BRIEF: Rui's answers, Claude's translation, three probes

**How it was written.** Rui asked Claude to write the brief. Claude declined, because the assignment has the
student write the brief, the phase table, the cycle spec, the predictions and the answers, and lets AI only
organize notes. Instead Claude wrote:
- an English structure with verified file references (`prompts/a7/brief-skeleton.md`);
- a Chinese questionnaire with choices and recommendations (`prompts/a7/brief-questions-zh.md`);
- for the starred items (Rui's own words), concept notes without answers (`prompts/a7/brief-star-hints-zh.md`).

Rui answered in Chinese. Claude reviewed twice, Rui accepted the changes listed at the end of the
questionnaire, and Claude translated the answers into the English brief. Rui then wrote the last seven items
directly in English from suggestions Claude gave in chat (archived at the end of the hints file). Committed
before any setup prompt as `0734c5c`.

**What the reviews changed.**
- 56×72 cells could not hold the hop and lean. Rui made them 64×80, with the pole foot's x fixed and
  y offsets only as designed.
- The new sheet became a new file, because A6 previews load `scarecrow.png`.
- A `hold` clip replaced a script writing `frame`, which would have been a second writer.
- Interrupt rules were written for every phase, not only for target loss in startup.

**Probes that changed the design** (`prompts/a7/probes/`, Godot 4.7.2):
1. Only one transition per from → to pair is allowed. Rui's plan of a second shoot → idle transition for
   cancelling was impossible, and `travel("idle")` would wait for At End, so a cancel uses
   `playback.start("idle")`.
2. `travel("shoot")` to the archer reading the 8/30 s key is 18 physics ticks, not 16. The entered state
   stays at position 0 for one update, and the parent `_physics_process` runs before its child
   AnimationTree in the same tick; the tree's process priority did not change that. With the planned
   0.2667 s draw threshold the cadence would have become 0.633 s. Rui set the threshold to 0.3 s.
3. A Start → idle transition left on Enabled keeps the machine in `Start`.

**Claude's mistake.** Claude's concept note for answer 5 said a tree and a reader on the same PHYSICS clock
differ by 0. Probe 2 showed 1 tick. The note carries a dated correction; the original text is kept.

**Predictions kept honest.** Two of Rui's predictions were answered before prompt-1: one by a probe, and one
because Claude computed that the cooldown error goes downward. Both were moved to "Known before prompt-1",
leaving four genuine predictions. The predicted test changes in §5 were written before the latency probe
and are kept as written.

## 2026-11-21 — Step 1: the CLAUDE.md draft and its review

Session 1 ran `prompts/a7/prompt-1.txt` (verbatim, `4d3918a`) with Assignment 5's read-only command;
the transcript is `sessions/a7/session-1.jsonl`. `check-session.sh`:
- result success, 40 turns;
- one permission denial, a compound `wc` + `awk` Bash command;
- `godot/shaders/` and `run-test.sh` unchanged, only CLAUDE.md modified (119 lines).

The draft was committed unedited as `266593f`. Every file reference was printed and compared with its claim,
and all were exact.

**Found in review** (Rui approved all; Claude edited, `524aa7e`):
1. The draft dropped A6's "Headless facts" block. The four lines the assignment asks for were confirmed on this
   machine first (`evidence/a7-probes/`), and two needed a qualifier:
   - Key times are doubles in memory and become float32 only when saved to `.tres`. A re-run of the latency
     probe with a saved clip still gave 18 ticks.
   - `value_track_get_update_mode` on a non-value track prints an `ERROR:` line that `run-test.sh` does not
     catch, and returns 0.
   - Headless Movie Maker crashes with signal 11, which is why strips need a windowed run.
2. The four names the draft marked "not verified" exist in 4.7.2 (probe). The same probe showed both mixers
   default to the IDLE callback, so the archer's tree must set PHYSICS explicitly. This is now in CLAUDE.md.
3. Three "Unconfirmed" items were gaps in the brief, now settled by brief revision 1 (`a4bd8df`):
   - Restart reaches the archer only through `main.gd` `reset()`. It gets one `cancel_shot()` call.
   - The string's stretch needs `scale` keys.
   - The nodes are named, and a disabled archer freezes like pause.

## 2026-11-21 — Step 2: the pins, and watching them

**The prompt.** The assignment gives requirements for Step 2 but no prompt. Claude drafted
`prompts/a7/prompt-2.txt` from Chapter 10's "pin what exists" prompt: one new file, real keys through
`Input.parse_input_event`, no direct method calls or state writes, one log line per frame, a TIMING group
(numbers the brief changes) and an INVARIANT group, and anomalies reported, not fixed. Rui approved it
unchanged (`b5d4c10`).

**The session** (`sessions/a7/session-2.jsonl`, A6's build allow list):
- success, 39 turns;
- two permission denials, both `run-test.sh` with a `> /dev/null` redirect;
- shaders, `run-test.sh` and every game file unchanged.

The agent's test, `godot/tests/test_pins_a7.gd`, was committed unedited (`d6d8596`). Result:
- 38 passed, 0 failed (16 TIMING, 22 INVARIANT). Claude re-ran it twice; the output was identical line for
  line. The log is in `evidence/a7-pins/`.
- No anomalies. Pinned today:
  - the first shot comes 1 frame after a target appears in the cone with the cooldown at 0;
  - back-to-back shots are 36 ticks apart;
  - a 30-frame pause shifts the next shot by 30;
  - a scarecrow reaches the wall at f 174;
  - the loss is at f 104, and the archer is already frozen on that tick (tick order Main → scarecrows →
    arrows → archer).

The agent also noted two choices in the test:
- Scenario (e) parks the archer at the right edge, because a scarecrow walking down above it is shot dead
  first.
- Enter-restarts-a-loss stays covered only by `test_input`.

**Watching the pins.** Rui ran the windowed replay: Movie Maker, `--debug-collisions`, 60 fps, 1231 frames,
log in `captures/pins/r0/run.log`. The replay log matches the headless log line for line, and it also passes
38/0.

**Claude's reading of the frames (a claim, not a proof).** Capture frame N shows the state of log line N+1,
because a line is printed at the start of a frame and describes the tick before it. Checked at four
boundaries, with `godot/tools/contact_sheet.gd` (written by Claude) cropping and tiling the frames into
`captures/pins/sheets/`:

| Moment | Capture frames | Log lines |
|---|---|---|
| Scarecrow and arrow first appear | 3 | 4 |
| "Paused" shown | 631–660 | 632–661, `paused=true` |
| "The gate fell" banner, gate 1 → 0 | 1188 | 1189, `LOST` |
| Gate 100, field cleared, archer back at centre | 1219 | 1220, `PLAYING` |

Kept in the repository are those 14 frames, the log and the sheets. The rest of the capture was moved to
`F:\7270\a7-captures\pins-r0\`.

`--debug-collisions` drew nothing. The game has no collision shapes: an arrow hits by distance
(`arrow.gd:21`, `ARROW_HIT_RADIUS`). So the flag shows nothing about hits in this project.

## 2026-11-21 — Step 3: the walk sheet and the walk clip

The assignment's Step 3 prompt assumes the sheet already exists; ours is drawn by code. So Step 3 ran as
two prompts, both approved by Rui (`f846546`):
- `prompt-3a.txt`, written by Claude: the sheet only.
- `prompt-3b.txt`: the assignment's template with the placeholders filled, plus a block of project specifics.

**3a, the sheet** (`sessions/a7/session-3a.jsonl`; success, 15 turns, 2 denials for compound commands).
- `make_sprites.gd` moved the old scarecrow drawing unchanged into a shared function and added
  `scarecrow_walk.png`. The four existing PNGs are byte-identical, which proves the move changed nothing.
- `test_scarecrow_sheet.gd` reads the PNG directly and checks four things:
  - the pole foot's x is the same in every cell (31.5);
  - its y is 73/70/74/70, i.e. offsets 0/−3/+1/−3;
  - nothing touches a cell's border;
  - every cell holds the scarecrow's colours.
- 36 PASS, re-run by Claude.
- Rui looked at a 4× preview (`captures/scarecrow_walk_sheet_x4.png`). The 5° lean is a nearest-pixel
  rotation, so in frames 1 and 3 one eye breaks or bends and the hat brim is jagged. Rui accepted it, to be
  judged in play after Step 5. Committed unedited as `8597ff5`.

**3b, the clips** (`sessions/a7/session-3b.jsonl`; success, 25 turns, 4 denials).
- `scarecrow.tscn` gets the sheet (`hframes` 4) and a new `Scarecrow/AnimationPlayer` with a scene-embedded
  library:
  - `walk` matches brief §3 exactly;
  - `hold` is one key on frame 0, `LOOP_NONE`. The brief gave `hold` no length; the agent chose 0.125 s and
    said so.
- No autoplay, and nothing plays the clips yet.
- `test_scarecrow_walk_readback.gd` passes: 68 PASS, 0 failures. The agent's summary said 72; Claude counted
  the PASS lines in the log.
- The pins (38/0), `test_burning_tint` (49/0) and `test_impact_burst_state` (29/0) are unchanged, as expected
  before wiring.
- Two of the four denials were the agent reaching for PowerShell after `bash scripts/run-test.sh` was refused.
  The allow list held, and `./scripts/run-test.sh` was the allowed form.

## 2026-11-21 — Step 4: the archer's part images and the shot clip

As in Step 3, the assignment's prompt assumes the rig exists, and ours had to be cut out of one image first.
So Step 4 ran as two prompts, both approved by Rui (`d954846`):
- `prompt-4a.txt`, written by Claude: the part images only.
- `prompt-4b.txt`: the template with its placeholders filled, plus project specifics.

**4a, the parts** (`sessions/a7/session-4a.jsonl`; success, 13 turns, 1 denial for a compound command).
- `make_sprites.gd` writes `archer_body.png`, `archer_bow.png` and `archer_string.png`, and records their
  rest placements and the grip at (34.5, 26).
- The five existing PNGs are byte-identical.
- `test_archer_parts.gd` passes 13/0.
- Composited at rest, the parts differ from `archer.png` in 56 of 2640 pixels, all from each part carrying its
  own outline:
  - a dark line between the stave and the string;
  - the bow's outline over the cloak.
- Rui looked at a 6× comparison (`captures/archer_parts_rest_x6.png`) and accepted it (`f7076ff`).

**4b, the rig and clips** (`sessions/a7/session-4b.jsonl`; success, 25 turns, 1 denial).
- The single `Sprite` became `Rig/Body`, `Rig/BowPivot/{Bow,String}` plus an `AnimationPlayer`. Claude
  checked the arithmetic of each rest position against the recorded placements.
- `shoot` keys every transform track at frames 0, 8, 9 and 15. The key transitions ease in toward the release
  and ease out through the recovery. `release_window` is discrete: false, true, false.
- `archer.gd` gained only `var release_window := false`.
- **The brief gave timing but no pose amounts.** The agent proposed them and labelled them as proposals for
  Rui to judge in the strip:
  - bow −8°, pulled 1 px left and 3 px down;
  - string +3 px and stretched to 110 %;
  - a +2° kick on release.
- `test_archer_shot_readback.gd` passes 165/0, and Claude counted 165 PASS lines.
- The pins, rules and input suites are unchanged. Claude re-ran every other baseline suite, and all their
  logs came out byte-identical, so the rig changed nothing the tests cover before wiring.
