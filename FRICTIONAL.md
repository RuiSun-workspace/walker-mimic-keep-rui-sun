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
