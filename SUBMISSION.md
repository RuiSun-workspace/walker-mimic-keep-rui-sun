# SUBMISSION — CSYE 7270 Assignment 5

**Assignment:** Assignment 5 - Shaders, Materials, and the Godot Shading Language

**Student:** Rui Sun

**Project name:** `walker-mimic-keep-rui-sun` (game: *Mimic Keep*)

**GitHub repository URL:** https://github.com/RuiSun-workspace/walker-mimic-keep-rui-sun

**Git tag and submitted commit SHA:** tag `a5`, on the commit that adds this file. A commit cannot contain
its own SHA: run `git rev-parse a5^{commit}` on the clone, and see the Canvas note.

**Game-source revision shown in the film:** `879324b`

> The film was captured from `879324b`. The commits after it add only documentation and the film's records
> (CLAUDE.md shortened, README, SOURCES, FRICTIONAL, `youtube/`, this file). **No file under `godot/`
> changed after `879324b`**:
>
> ```bash
> git diff --stat 879324b a5 -- godot/     # expect empty output
> ```

**Godot version, renderer, and operating system:** Godot `4.7.2.stable.official.ed1daf0bf`, Forward+
(Vulkan), on Windows 11 Home China, NVIDIA GeForce RTX 3070 Laptop GPU.

**Game state the shader from code communicates:** *Burning* — a Straw Scarecrow hit by a fire arrow burns
for 4 s of game time (`godot/game/scarecrow.gd`, `burn_time_left`). `godot/shaders/burning_tint.gdshader`
mixes its sprite toward (255, 192, 32) by `burn_mix`, which `godot/game/burning_tint.gd` sets every frame
to `0.65 × clamp(burn_time_left / 4, 0, 1)` on that scarecrow's own material.

**3D object and scene given the textured shader:** two wooden shields (`ShieldA`, `ShieldB`, mesh
`godot/showcase/shield_mesh.tres`) in `godot/showcase/shield_room.tscn`, using
`godot/shaders/shield_wood.gdshader` through `shield_new.tres` and `shield_burned.tres`.

**Texture sources and licences:** Poly Haven, *Wood Planks* 1K by Amal Kumar, CC0 1.0
(https://polyhaven.com/a/wood_planks; checked 2026-10-28; `_nor_gl` used, `_nor_dx` for calibration only;
`godot/assets/textures/wood_planks/ATTRIBUTION.md`). The scorch mask and the hint-experiment grey strip are
written by code (`godot/tools/make_scorch_mask.gd`, `make_hint_greys.gd`). No generated textures.

**Final film URL and filename:**
https://northeastern-my.sharepoint.com/:v:/g/personal/sun_r3_northeastern_edu/IQDZY7AdKwcTRaacSlGB4bqyAfG3lmOAaQuQDUvm744kg4A?e=hkY4ve
— `claude-liam-walker-mimic-keep-a5-gamedev.mp4`

**Final film SHA-256:** `10a99c22d53e31b330393846d9a1ecddd5d1f360e6f78dcf417baa45601d0ec3`

*(3840×2160 H.264, 30 fps, AAC 48 kHz stereo, 372.97 s, 29,255,840 bytes. Northeastern OneDrive, view-only
for Northeastern accounts. The MP4 is kept out of the repository.)*

**Changed games since Assignment 2:** yes — from walker-lamplight-rui-sun to Mimic Keep, after the Assignment 4
GDD; FRICTIONAL.md, "2026-10-25 — Change of game", with Rui's reason in Rui's words.

---

## Summary of the work

Drafted by Claude Code from the repository's records for Rui's review; who did what is in SOURCES.md and
FRICTIONAL.md.

- **Specification first.** Rui wrote CHANGE-BRIEF.md (colour line, uniform table, measurable rules, boundaries,
  evidence split, hand-computed pixel and hint-experiment predictions) and it was committed (`0f80b58`) before any
  shader or prompt. CLAUDE.md was drafted by an agent session, committed unedited, and corrected in a separate
  commit after Rui's review; it imports the brief with `@CHANGE-BRIEF.md`.
- **Shaders by hand.** Rui typed every line of `burning_tint.gdshader`, `shield_wood.gdshader` and
  `hint_experiment.gdshader`; no agent session changed `godot/shaders/`. Rui also converted a StandardMaterial3D
  (`standard_generated.gdshader`) and wrote LANGUAGE-NOTES.md, annotating it and answering the eight questions
  with line references.
- **Driver, tests, materials (agents and Claude Code).** The driver and `test_burning_tint.gd` (agent session 2)
  check the tint every frame at 30, 60 and 144 fps through real arrows, with retrigger, time scale and pause;
  the test found a one-tick timer bug, fixed as the brief's one boundary exception. The material audit
  `test_materials.gd` (agent session 3) and `normal_map_check.gd` check hints, values, import settings and the
  normal map's convention.
- **Mutations.** Rui broke each shader by hand: a missing semicolon and a renamed `burn_mix` both make the tint
  test exit 1; removing `source_color` from the albedo sampler makes the material test exit 1.
- **Human checks.** Controlled-value captures (15/15 pixels within one step; 2.0 is not clamped by `hint_range`),
  one comparison with an OS screenshot, the hint experiment (64/128/192 vs 137/188/225, as predicted), the
  interface sweep, the one-shader-two-materials edits, the shield comparison, and Rui's playtest — all recorded
  in TEST-REPORT.md with Rui's own words.
- **Film.** A 4K Brutalist `godot-gamedev` (walker) explainer; each code excerpt is followed by real engine
  output (Movie Maker footage of the game, or the repository's in-engine captures), labelled; checker PASS.

## Known limitations

1. Two gameplay faults found in Rui's playtest remain in this revision, because Assignment 5 may not change game
   rules: long sideways shots can miss (no aiming lead), and a scarecrow attacking the wall cannot be shot. The
   wall fix exists on the local branch `gameplay-fixes` (`dbb4806`), to be merged after `a5`.
2. 618 of 921,600 pixels differ between the in-engine capture and the OS screenshot of the same frame; the 15
   measured pixels are identical, and the cause of the rest is not established.
3. The normal map's depth reads only subtly in the shield room (Rui: "the difference is subtle").
4. LANGUAGE-NOTES question 3 names two built-ins read, not three: the shaders read only `COLOR` and `UV`.
5. One playtester (Rui). The film's in-play footage runs with no keys pressed, and its fade sequence is a
   scripted capture; both are labelled.

## Where to look

| Document | What it answers |
| --- | --- |
| [README.md](README.md) | Run instructions, controls, what Assignment 5 added, the film link |
| [CHANGE-BRIEF.md](CHANGE-BRIEF.md) · [CLAUDE.md](CLAUDE.md) | The specification (with dated revisions) and the agent context |
| [LANGUAGE-NOTES.md](LANGUAGE-NOTES.md) · [godot/MATERIALS.md](godot/MATERIALS.md) | The language answers; the materials, textures and import settings |
| [TEST-REPORT.md](TEST-REPORT.md) | Every machine and human check at the tested revision |
| [FRICTIONAL.md](FRICTIONAL.md) · [SOURCES.md](SOURCES.md) | What happened, who did what, sources and licences |
| `prompts/`, `sessions/`, `evidence/`, `logs/` | Agent prompts and transcripts, captures, mutation records, test logs |
| [youtube/claude-liam-walker-mimic-keep-a5-gamedev/](youtube/claude-liam-walker-mimic-keep-a5-gamedev/) | Film beat sheet, shot list, fact check, evidence ledger, capture driver and logs, QC |

## Verifying this submission

```bash
git clone --branch a5 https://github.com/RuiSun-workspace/walker-mimic-keep-rui-sun.git
cd walker-mimic-keep-rui-sun
godot --headless --path godot --import        # first run only
./scripts/run-test.sh test_rules.gd 60        # 23/0
./scripts/run-test.sh test_input.gd 60        # 14/0
./scripts/run-test.sh test_burning_tint.gd 30 # 49/0, also at 60 and 144
./scripts/run-test.sh test_materials.gd 60    # 132/0
./scripts/run-test.sh normal_map_check.gd 60  # 9/0
grep -l "SHADER ERROR" logs/*.log             # expect no output
git diff --stat 879324b a5 -- godot/          # expect no output: the film shows this game source
```

A fresh clone of `89311fa` (the commit before this file, with the same game source), made from the local
repository before upload, gave exactly these counts at 30, 60 and 144 fps for every suite, with no
`SHADER ERROR` and no `.import` file changed.
