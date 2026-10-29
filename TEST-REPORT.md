# Test Report — Mimic Keep, Assignment 5

| | |
|---|---|
| Source revision tested | `b77e30d` (main; the commit before this report) |
| Godot | 4.7.2.stable.official.ed1daf0bf, portable, Windows 11 |
| Renderer | Forward+ (`forward_plus`), Vulkan 1.4.303, NVIDIA GeForce RTX 3070 Laptop GPU |
| Viewport | 1280×720, `rendering/viewport/hdr_2d` = false |
| Machine checks | `scripts/run-test.sh <test> <fps>`, headless (dummy renderer: draws nothing), run 2026-10-29 |
| Captures | windowed runs of the tools in `godot/tools/`, real renderer, read from the viewport in-engine |
| Human checks | Rui, 2026-10-29; Rui's own notes are `my-observations.txt` (quoted below with line numbers) |

Rui's words in Chinese are given verbatim with an English translation marked *(translated by Claude)*.
Everything Rui wrote in English is quoted as written.

## Summary

| Check (course "Use It") | Result | Evidence |
|---|---|---|
| Baseline | Earlier suites keep their counts: test_rules 23/0, test_input 14/0 at 30, 60 and 144 fps | `evidence/baseline/`, `logs/test_rules_*`, `logs/test_input_*` |
| Shaders parse | Uniform lists asserted for both shaders; no `SHADER ERROR` in any log; both shader mutations exit 1 | `logs/`, `evidence/mutations/` |
| Driver | Sampled every frame at 30, 60, 144 fps through real auto-fired arrows, retrigger included; 4.000000 s of game time each | `logs/test_burning_tint_{30,60,144}fps.log` |
| Controlled values (HUMAN CHECK) | 15 of 15 named pixels match the hand calculation; 2.0 set from code is not clamped | `evidence/controlled_values/` |
| In play (HUMAN CHECK) | Rui's playtest: tint on the hit scarecrow only, gone at the end, smooth fade, obvious refresh, frozen while paused, details legible; two gameplay bugs found (outside A5, see below) | `evidence/in_play/`, Rui's words below |
| Hint experiment (HUMAN CHECK) | Measured 64/128/192 and 137/188/225, as predicted; Rui confirmed the brighter unhinted row in the editor | `evidence/hint_experiment/` |
| Interface sweep (HUMAN CHECK) | 7 uniforms × min/default/max captured; Rui recorded what changed and what breaks | `evidence/sweep/` |
| One shader, two materials (HUMAN CHECK) | Shader edit changed both shields; material edit changed only ShieldA; both restored byte-identical | `evidence/two_materials/` |
| Material wiring | test_materials 132/0; 132/0 after a fresh import; source_color mutation exits 1 (130/2) | `logs/test_materials_60fps.log`, `evidence/audit/`, `evidence/mutations/` |
| Texture data | curl_ratio under both conventions for the calibration pair and both bound maps | `logs/normal_map_check_60fps.log` |
| Import settings | No `.import` file was rewritten by the editor | git history (below) |

## 1. Machine checks

### Suites at `b77e30d`

| Suite | 30 fps | 60 fps | 144 fps | Baseline (`29ebc5b`) |
|---|---|---|---|---|
| `test_rules.gd` | 23/0 | 23/0 | 23/0 | 23/0 at 60 |
| `test_input.gd` | 14/0 | 14/0 | 14/0 | 14/0 at 60 |
| `test_burning_tint.gd` | 49/0 | 49/0 | 49/0 | new in A5 |
| `test_materials.gd` | — | 132/0 | — | new in A5 |
| `normal_map_check.gd` | — | 9/0 | — | new in A5 |

Every run exited 0 and no log contains `SHADER ERROR` or `SCRIPT ERROR`. The 60 fps logs are
byte-identical to the committed ones; the 30 and 144 fps logs of test_rules and test_input are added
with this report. Pinned rates as in CLAUDE.md: earlier suites at 60, the tint at 30, 60 and 144
(CHANGE-BRIEF Rule 2); here the earlier suites were also run at 30 and 144.

### Driver (`test_burning_tint.gd`)

The driver is sampled every frame while real auto-fired arrows hit a scarecrow.

| | 30 fps | 60 fps | 144 fps |
|---|---|---|---|
| First frame after the hit (time_scale 1) | 0.650000 (2 ticks in the frame) | 0.650000 | 0.650000 |
| Last value | 0.0 in the frame `burning_ended` is emitted, > 0 the frame before | same | same |
| Game time 0.65 → 0.0, time_scale 1 / 0.5 / 2 | 4.000000 s each | 4.000000 s each | 4.000000 s each |
| Real time at time_scale 0.5 / 2.0 | 8.0000 s / 2.0000 s | 8.0000 s / 2.0000 s | 8.0000 s / 2.0000 s |
| Retrigger (Rule 3) | 0.167917 → 0.650000 in the hit frame | 0.167917 → 0.650000 | 0.170625 → 0.650000 |
| Pause (Rule 4) | 0.395417 held over 30 paused frames | 0.400833 over 30 | 0.403542 over 31 |
| Three scarecrows, middle hit (Rule 6) | outer two 0.0 in all 134 frames | all 267 frames | all 639 frames |

Also asserted at every rate: death while burning frees the Sprite and its ShaderMaterial the next
frame (Rule 5); every sample of a live scarecrow equals `0.65 × clamp(left / 4, 0, 1)` within 1e-6.
At 30 fps and time_scale 2 the first frame reads 0.644583 because two ticks of 1/30 s game time
pass before the first `_process` (CHANGE-BRIEF revision A).

### Shaders parse, and the mutations

| Mutation (Rui edited the shader by hand) | Test | Result | What caught it |
|---|---|---|---|
| 1. Semicolon deleted in `burning_tint.gdshader` | test_burning_tint @60 | exit 1, 45/4 | `SHADER ERROR`; the uniform list came back empty |
| 2. `burn_mix` renamed `burn_amount` | test_burning_tint @60 | exit 1, 46/3 | uniform-name and source-text checks only |
| 3. `source_color` removed from `wood_albedo_texture` | test_materials @60 | exit 1, 130/2 | source-text hint checks only |

Each shader was restored afterwards and its md5 checked. Mutation 2 passed every behaviour check:
the driver still writes `burn_mix`, and `set_shader_parameter()` accepts an undeclared name
silently, so only the name checks fail. Mutation 3 is invisible to `get_shader_uniform_list()`,
which does not report hints on samplers.

### Material wiring and texture data

- `test_materials.gd` 132/0, and 132/0 again after `godot/.godot` was deleted and reimported
  (`evidence/audit/fresh_cache_import.log`). It checks each uniform's type, group, hint and default
  from the source text, each sampler's hints, both materials' values and bound textures, the import
  settings, and the uniform list.
- `normal_map_check.gd` 9/0, using the course's `curl_ratio()` unchanged (stride 4) on the imported maps:

| Map | directx = false | directx = true | Reads as |
|---|---|---|---|
| `wood_planks_nor_gl_1k.png` (bound on both shields) | 0.6703 | 1.3297 | OpenGL |
| `wood_planks_nor_dx_1k.png` (calibration only) | 1.3286 | 0.6714 | DirectX |

The pair came out the right way round, so the sign convention was not flipped. Threshold
(0.6714 + 1.0) / 2 = 0.8357, CHANGE-BRIEF revision C.

### Import settings

`git log -- '*.import'` lists only the three commits that added textures (`cab3d5c`, `57c89af`,
`100257b`). `git status` was clean of `.import` changes after every editor session, including Rui's
sessions on 2026-10-28 and 2026-10-29, so there is no editor rewrite to explain. The editor did
rewrite two scenes; both were checked and committed separately: `ccb9529` (Step 2) and `b77e30d`
(`hint_experiment.tscn`: six Environment lines equal to their defaults dropped, uids added; loading it
gives the same environment).

## 2. Human checks

### Controlled values

`tools/capture_burn_values.gd` sets `burn_mix` 0.0, 0.5, 0.65, 1.0 and 2.0 from code on five frozen
scarecrows (driver stopped) and samples the three pixels named in CHANGE-BRIEF §6
(`evidence/controlled_values/pixels.txt`):

- 15 of 15 within one step of the hand calculation. 0.0, 0.65 and 1.0 match exactly; at 0.5 the three
  half-integer channels (146.5, 30.5, 188.5) came out 146, 30, 188.
- At 1.0 every pixel is exactly (255, 192, 32): `burn_color` reaches the screen unconverted in a
  canvas_item shader with HDR 2D off.
- **hint_range question:** at 2.0, read back from the material as 2.0, the straw body is (255, 188, 0),
  the patch (255, 255, 35), the sack head (255, 199, 0). Clamped to 1.0 each would be (255, 192, 32).
  `hint_range` does not clamp a value set from code.

**One capture against an OS screenshot.** `tools/os_screenshot.ps1` grabbed the game window with GDI
while the same frame was held; `tools/compare_os_screenshot.gd` compared them
(`evidence/controlled_values/os_compare/os_compare.txt`): the 15 named pixels are identical; 618 of
921,600 pixels differ, at the window's rounded bottom corners and along the archer's face and belt
and the gate edges. The cause of the archer and gate differences is not established. Rui:

> "For exact pixel evidence, I trust the in-engine screenshot more. It comes directly from the game
> renderer at `1280 × 720`. The OS screenshot also goes through the game window and desktop capture
> process, so there are more places where small edge differences could be introduced. Both are fine
> for the 15 test pixels because those values are identical." (`my-observations.txt:26`)

### In play

Rui played the game normally on 2026-10-29 and took `evidence/in_play/one_burning.png` (an OS
screenshot of part of the window) with one scarecrow burning and one not. Rui reported:

> "横向距离远的时候子弹瞄准的过于靠后会导致打空" — *when the sideways distance is large the
> arrow aims too far behind and misses (translated by Claude)*
>
> "小怪到墙前面开始打墙后子弹打不中墙了" — *once a monster reaches the wall and starts attacking it,
> the arrows can no longer hit it (translated by Claude)*
>
> "别的试玩也没什么问题" — *the rest of the playtest had no problems (translated by Claude)*

Both are gameplay faults, not tint faults; see section 5. Asked afterwards about five looks the brief
names (§5), Rui answered from the playtest, numbered as asked (same day, in chat):

> "1.结束时消失了 2.淡出部分比较平滑 3.再次被打中颜色刷新明显 4.暂停时颜色不变5.能看清稻草人的细节"
> — *1. it disappeared at the end; 2. the fade-out is fairly smooth; 3. the colour refresh is obvious
> when hit again; 4. the colour does not change while paused; 5. the scarecrow's details can be seen
> (translated by Claude)*

Rui could not catch a death frame in an OS
screenshot ("我截图有延迟，截不到死亡的那一帧" — *my screenshot lags, I can't catch the death frame;
translated by Claude*), so `tools/capture_in_play.gd` produced **scripted** frames in the real game
(archer and spawning off, driver running, ignite and kill through `Scarecrow.hit()`):
`scripted_1_before.png`, `scripted_2_middle_burning.png` (middle 0.569, outer two 0.0),
`scripted_3_after_death.png` (killed with 3.5 s of burn left; 0 warm pixels where it stood). Rui:

> "In `scripted_2_middle_burning.png`, the middle scarecrow is the only one that turns orange. The
> other two keep their normal colours, so it is easy to tell which one is burning." (`my-observations.txt:5`)
>
> "In `scripted_3_after_death.png`, the middle scarecrow is gone. I do not see any orange colour or
> other effect left behind where it used to be." (`my-observations.txt:6`)

### Hint experiment

`evidence/hint_experiment/band_values.txt`: with `source_color` 64/128/192, without 137/188/225, all
six exactly as predicted in CHANGE-BRIEF §7. Rui ran the scene in the editor:

> "The lower row, labelled `no hint`, is clearly brighter than the upper `source_color` row. [...] The
> three sections also have clear edges, so the texture is not being blurred into a gradient."
> (`my-observations.txt:30`)
>
> "I cannot tell the exact RGB values by looking at the screen. Visually, I can only confirm that the
> lower row is brighter. The exact values come from `band_values.txt` [...]" (`my-observations.txt:32`)

### Interface sweep

`tools/capture_shield_room.gd -- sweep`: each uniform at the minimum, default and maximum read from
the shader source, every other value as in the material; Surface uniforms on ShieldA, Damage uniforms
on ShieldB (at ShieldA's `scorch_amount` 0.05 they barely show). Room lighting as saved; no SSAO,
SSR, SSIL or glow in that environment. `evidence/sweep/sweep_sheet.png`, `sweep.txt`. Rui's notes
(`my-observations.txt:13-19`):

| Uniform | What changed, and what breaks the look (Rui) |
|---|---|
| `wood_tint` | "At the minimum, the shield is almost black and most of the wood detail disappears. The default and maximum look the same because both are white. The minimum is too dark to use." |
| `texture_scale` | "The minimum makes the texture look too large and stretched across the shield. The default looks the most natural. At the maximum, the texture repeats too many times and the tiling becomes obvious." |
| `roughness_scale` | "This difference is fairly hard to see in the screenshots. The minimum has slightly stronger highlights, while the default and maximum look more matte. The minimum looks a little too smooth for old wood, but none of these images looks completely broken." |
| `normal_strength` | "The minimum looks flatter. The default gives the wood some visible depth. At the maximum, the horizontal seams become very dark and look deeper than they should." |
| `scorch_amount` | "The minimum and default look the same because both use zero. At the maximum, the dark scorch pattern is fully visible. Zero makes the burned shield look too clean, but the maximum also looks a little too blotchy. A value between them works better." |
| `scorch_color` | "The minimum and default both make the scorch marks dark. At the maximum, the marks become white, which does not look like burned wood at all." |
| `char_roughness` | "At the minimum, the scorched areas have bright, glossy reflections. The default and maximum are more matte and look very similar. The minimum looks too polished for a burned surface." |

### One shader, two materials

Same lighting and camera throughout (`evidence/two_materials/`). Changed pixels against `0_before.png`,
left half / right half of the frame:

| Step | Who | Change | Left / right |
|---|---|---|---|
| `1_shader_edit.png` | Rui | `shield_wood.gdshader:68` × `vec3(0.3, 0.3, 1.0)` | 98,610 / 98,610 |
| `1b_shader_restored.png` | Rui | line restored, md5 `c69c4d88` again | byte-identical to before |
| `2_material_edit.png` | Rui | `shield_new.tres` `scorch_amount` 0.05 → 0.8 | 48,286 / **0** |
| `2b_material_restored.png` | Rui, then Claude | value set back; Claude restored the file's committed text (the editor had added uids and a default `scorch_color`) | byte-identical to before |

> "After I added the temporary blue multiplier to `shield_wood.gdshader`, both shields changed.
> ShieldA became noticeably blue-purple, while ShieldB became much darker with a cooler colour."
> (`my-observations.txt:46`)
>
> "In `2_material_edit.png`, dark scorch patches appeared across ShieldA on the left. ShieldB on the
> right did not show the same new change and kept its previous dark brown appearance."
> (`my-observations.txt:53`)

### Shield comparison and normal direction

> "ShieldA on the left looks like clean, light-coloured wood. ShieldB on the right is much darker and
> has a reddish-brown burned colour. It also has dark scorch patches, especially near the top."
> (`my-observations.txt:36`)
>
> "The horizontal seams look dark with a small amount of light along their lower edges. That generally
> makes them look recessed instead of raised. The difference is subtle, so I would not say the normal
> direction is completely obvious, but I also do not see a clear sign that the normal map is
> inverted." (`my-observations.txt:39`)

## 3. Specification coverage

| CHANGE-BRIEF rule or prediction | Machine check | Human check |
|---|---|---|
| Uniform names and types (§5) | test_burning_tint, mutations 1-2 | — |
| Rule 1 start and end values | test_burning_tint, 30/60/144 | appears on the hit scarecrow (Rui's screenshot and notes); "结束时消失了" (it disappeared at the end) |
| Rule 2 four-second duration | test_burning_tint, 30/60/144 | "淡出部分比较平滑" (the fade-out is fairly smooth) |
| Rule 3 restart on a second hit | test_burning_tint retrigger, 30/60/144 | "再次被打中颜色刷新明显" (the refresh is obvious when hit again) |
| Rule 4 time scale and pause | test_burning_tint time_scale 0.5/1/2 and pause | "暂停时颜色不变" (no change while paused); time scales other than 1.0 are not reachable in play, so machine-checked only |
| Rule 5 early end | test_burning_tint death case | scripted frame after death, Rui's notes |
| Rule 6 multiple instances | test_burning_tint three scarecrows | Rui's screenshot and scripted frame: only one tinted |
| Exact tint calculation (§6) | not provable headlessly | controlled-value captures, 15/15 |
| Readability (§5) | not provable headlessly | Rui: "it is easy to tell which one is burning" (`my-observations.txt:5`) |
| Colour choice (§5) | not provable headlessly | "能看清稻草人的细节" (the scarecrow's details can be seen) |
| Grayscale prediction (§7) | — | hint experiment, measured and seen |
| Materials differ (§8) | test_materials | shield comparison, two-materials edits |
| Failure 1 re-ignition | test_burning_tint retrigger | — |
| Failure 2 shared material | test_burning_tint three scarecrows | Rui's screenshot |
| Failure 3 time scale | test_burning_tint 0.5/1/2 | — |
| Failure 4 data texture with source_color | test_materials; mutation 3 | hint experiment |
| Failure 5 normal Y direction | normal_map_check 9/0 | Rui: seams read recessed, subtle |

Quotes in this table are Rui's answers from the playtest (section 2, In play), translated by Claude.

## 4. What no headless run can show

The headless runs prove that both shaders parse, that their uniforms are declared as specified, that
the driver writes the specified value every frame at three frame rates, and that the materials are
wired as audited. A headless run uses a dummy renderer and draws nothing, so none of them shows a
colour on screen, whether the tint reads as "burning", whether the fade looks smooth, whether a normal
map reads as grooves, or whether a material looks like wood. Those rest on the captures and Rui's
checks in section 2.

## 5. Inspect-and-revise cycles

Each started from an observation, not from a failing build:

- **Burning timer, 144 fps** (2026-10-28): the new tint test failed 7 checks at 144 fps; every burn
  lasted 241 ticks because of a float residue. Fixed in the game timer with an epsilon (CHANGE-BRIEF
  boundary-exception revision); no expectation was loosened.
- **Scorch mask** (2026-10-28): the first generated mask was a plain frame, the second had flat
  plateaus; retuned until the noise read as burn patches (FRICTIONAL, Step 3).
- **Normal-map prediction** (2026-10-28): the brief predicted curl near 0 and near 2; measured 0.67 and
  1.33; threshold rule A chosen by Rui (CHANGE-BRIEF revision C).
- **`normal_strength` range** (2026-10-28): the agent audit found 0-1 where the brief said 0-2 (Claude
  had missed it in an earlier check); Rui corrected the shader, and the run in which the audit test
  still expected the old range is kept in `evidence/audit/test_materials_shader_fixed_test_not_yet.txt`.
- **Rui's playtest** (2026-10-29): the two gameplay faults quoted in section 2. A5 forbids changes to
  targeting and game logic, so Rui chose to fix the wall case on a separate branch, `gameplay-fixes`
  (`dbb4806`, not merged into this revision): scarecrows now stop at y 530, where the archer can aim at
  them; Rui chose 530 after playing 500 ("停止线太远了，完全看不出怪在打墙" — *the stop line is too far,
  you can't tell the monsters are attacking the wall; translated by Claude*). The long-range miss is
  deferred by Rui to a later change with homing and fixed-trajectory arrows.

## 6. Uncertain or open

- The OS-screenshot differences at the archer and gate edges are unexplained.
- The normal direction looks right to Rui but "the difference is subtle".
- Both gameplay faults remain in this revision; the wall fix exists only on `gameplay-fixes`.
