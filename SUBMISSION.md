# SUBMISSION — CSYE 7270 Assignment 7

**Assignment:** Assignment 7 - Doing Animation with Claude and Godot

**Student:** Rui Sun

**Project name:** `walker-mimic-keep-rui-sun` (game: *Mimic Keep*)

**GitHub repository URL:** https://github.com/RuiSun-workspace/walker-mimic-keep-rui-sun

**Git tag and submitted commit SHA:** tag `a7`, on the commit that adds this file. A commit cannot contain
its own SHA: run `git rev-parse a7^{commit}` on the clone, and see the Canvas note.

**Game-source revision shown in the film:** `62d7f72`

> The film was captured from `62d7f72`. Its game files are identical to `0726ae3` (the kept r1 tuning) except
> the added `godot/assets/sprites/ATTRIBUTION.md`. The commits after it add only documentation and the film's
> records (README, SOURCES, FRICTIONAL, `youtube/`, this file). **No file under `godot/` changed after
> `62d7f72`**:
>
> ```bash
> git diff --stat 62d7f72 a7 -- godot/     # expect empty output
> ```

**Godot version, renderer, and operating system:** Godot `4.7.2.stable.official.ed1daf0bf`, Forward+
(Vulkan), on Windows 11 Home China.

**Sprite clip: route, node, scene, frame rate:** Scarecrow walk. Route: **Sprite2D with an AnimationPlayer frame
track**. `Scarecrow/Sprite` (Sprite2D, `hframes = 4`) is keyed by `Scarecrow/AnimationPlayer` in
`godot/game/scarecrow.tscn`. Clips: `walk` (frames 0–3, discrete, LOOP_LINEAR, 0.5 s) and `hold` (frame 0 at
the wall). **8 fps** (one key every 0.125 s).

**Rig clip: route, rig source, node, scene, frame rate:** Archer shot. Route: **keyed cutout rig** (no imported
rig).
- Rig source: `Archer/Rig` with `Body`, `BowPivot/Bow` and `BowPivot/String`. The parts are Sprite2D images
  `archer_{body,bow,string}.png`, written by `godot/tools/make_sprites.gd`.
- Clips: `idle` and `shoot` on `Archer/AnimationPlayer`, played by `Archer/AnimationTree`, in
  `godot/game/archer.tscn`.
- **30 fps** (step 1/30, 15 frames: startup 0–7, active 8, recovery 9–14). Physics runs at 60 ticks/s.

**Which clip loops and which commits:** the scarecrow walk loops (LOOP_LINEAR). Its seam is the gap from the last
key to the clip's end, equal to the key interval. The archer shot commits: once the draw passes startup, the arrow
leaves on the active frame whatever the player does. A target that leaves the cone during startup cancels the
draw with no arrow.

**The one authority over each animated node:**
- **Scarecrow.** Only `Scarecrow/AnimationPlayer` (callback IDLE) writes `Scarecrow/Sprite:frame`.
  `scarecrow_walk_presenter.gd` picks `walk` or `hold` from `at_wall`, comparing `assigned_animation`. It never
  writes the frame, and no gameplay code reads it.
- **Archer.** Only `Archer/AnimationTree` (an AnimationNodeStateMachine, Start → idle → shoot → idle, callback
  PHYSICS) writes the `Archer/Rig` nodes and `release_window`. Its AnimationPlayer never plays on its own.
  `archer.gd` reads the state with `playback.get_current_node()` and reads `release_window` in
  `_physics_process`.

**Sprite sheet source and licence (or model, version, and terms):** `godot/assets/sprites/scarecrow_walk.png` and
the rig parts are written by project code, `godot/tools/make_sprites.gd`. That script was written by agent
sessions using Claude Opus 5.5, directed by Rui. No image is downloaded or model-generated, so no third-party
licence applies. Credits: `godot/assets/sprites/ATTRIBUTION.md`.

**Final film URL and filename:** https://northeastern-my.sharepoint.com/:v:/g/personal/sun_r3_northeastern_edu/IQCRlKXVZwhAT4P2wRN0P9_HAXr9IitGGxW46S-2RUpmeU8?nav=eyJyZWZlcnJhbEluZm8iOnsicmVmZXJyYWxBcHAiOiJPbmVEcml2ZUZvckJ1c2luZXNzIiwicmVmZXJyYWxBcHBQbGF0Zm9ybSI6IldlYiIsInJlZmVycmFsTW9kZSI6InZpZXciLCJyZWZlcnJhbFZpZXciOiJNeUZpbGVzTGlua0NvcHkifX0&e=x0H2f1 — `claude-liam-walker-mimic-keep-a7-gamedev.mp4`

**Final film SHA-256:** `dae506e8e44ebf96a470f4fb343937968c22612b58bad28278d9601a3471454b`

*(3840×2160 H.264, 30 fps, AAC 48 kHz stereo, 327.2 s, 24,932,405 bytes, on Northeastern OneDrive. The MP4 is kept
out of the repository.)*

**Changed games since Assignment 2 (yes/no; if yes, FRICTIONAL.md entry):** yes — from walker-lamplight-rui-sun
to Mimic Keep before Assignment 5; FRICTIONAL.md, "2026-10-25 — Change of game". No change in Assignment 7.

---

## Summary of my work

Drafted by Claude Code from the repository's records; who did what is in SOURCES.md and FRICTIONAL.md.

- **Brief and pins first.** Rui's CHANGE-BRIEF.md was committed before the first setup prompt (`0734c5c`). It
  covers both routes, the phase table in frames, the cycle spec and seam rule, the two clocks, the one authority,
  boundaries, the evidence split and predictions. The behaviour pins (`test_pins_a7.gd`, 38/0) were committed
  before the change (`d6d8596`).
- **Agents built, wired and tested** the sheet, both clips, the AnimationTree and the edge tests (sessions 1–8;
  the wiring was planned first). Every result was committed unedited, then checked by Claude, who reran every
  test.
- **The gameplay change the brief names.** The arrow waits for the active frame. The draw starts 0.3 s early, so
  the 0.6 s cadence is kept. The pins were re-run and re-pinned in their own commit, with the reason (TEST-REPORT
  A7.2).
- **Checks:**
  - read-backs 68 and 166/0;
  - state-machine structure 107/0;
  - edges 325/0 (every boundary × every interrupt at B−1, B and B+1);
  - pins 38/0;
  - four mutations from a worktree: 1a, 1b, 2 and 3 exit 1; 4 passes, as expected for a keyed rig;
  - every earlier suite unchanged.
- **Rui looked first and decided.** Rui wrote a first look at the r0 strip before Claude read it. The one tuning
  change (bow full draw −8° → −16°) came from that observation; it was predicted, compared on the r0 and r1
  strips, and kept by Rui. Rui also judged the phases, the seam and registration in play (TUNING.md, TEST-REPORT
  A7.6).
- **Film.** A 4K Brutalist `godot-gamedev` (walker) explainer. Each code excerpt is followed by real engine
  output (Movie Maker footage or the repository's fixture strips), labelled.

## Known limitations

1. No human has seen a startup cancel, in play or in a fixture. It can only happen to a target near the wall, and
   it comes before the bow's lean is visible. The edge tests and probes establish it.
2. The three phases read as distinct in play (Rui), but only partly in the r1 preview strip: a 0.5 s clip in a
   0.6 s cadence leaves little rest.
3. The rotated walk cells have jagged eyes (nearest-neighbour rotation); Rui accepted this.
4. Arrows do not lead their target, so a far target near the cone's edge can be missed. This predates A7.
5. Mutation 4 (empty cache) cannot fail here: the clips are keyed in `.tscn`, not imported.
6. One playtester (Rui). In the film, both takes place scarecrows by script and the interrupt take sends
   scripted key events; all of this is labelled.

## Where to look

| Document | What it answers |
| --- | --- |
| [README.md](README.md) | Run instructions, controls, what Assignment 7 added, the film link |
| [CHANGE-BRIEF.md](CHANGE-BRIEF.md) · [CLAUDE.md](CLAUDE.md) | The specification (with dated revisions 1–4) and the agent context |
| [TUNING.md](TUNING.md) | Rui's first looks, the r1 change, prediction, comparison and verdicts |
| [TEST-REPORT.md](TEST-REPORT.md) | Assignment 7 sections A7.1–A7.6: suites, pins, edges, mutations, limits, Use It |
| [FRICTIONAL.md](FRICTIONAL.md) · [SOURCES.md](SOURCES.md) | What happened, who did what, sources |
| `godot/assets/sprites/ATTRIBUTION.md` | Sprite credits |
| `prompts/a7/`, `sessions/a7/`, `captures/`, `evidence/`, `logs/` | Prompts and transcripts, frame strips, probes and mutations, test logs |
| [youtube/claude-liam-walker-mimic-keep-a7-gamedev/](youtube/claude-liam-walker-mimic-keep-a7-gamedev/) | Film beat sheet, build scripts, evidence ledger, capture driver and logs |

## Verifying this submission

```bash
git clone https://github.com/RuiSun-workspace/walker-mimic-keep-rui-sun.git a7-check
cd a7-check && git checkout a7
godot --headless --path godot --import                     # first run only
./scripts/run-test.sh test_rules.gd 60                     # 23/0
./scripts/run-test.sh test_input.gd 60                     # 14/0
./scripts/run-test.sh test_materials.gd 60                 # 132/0
./scripts/run-test.sh normal_map_check.gd 60               # 9/0
./scripts/run-test.sh test_burning_tint.gd 30              # 49/0, also at 60 and 144
./scripts/run-test.sh test_wall_targeting.gd 30            # 10/0, also at 60 and 144
./scripts/run-test.sh test_impact_burst_config.gd 60       # 128/0
./scripts/run-test.sh test_impact_burst_state.gd 60        # 29/0
./scripts/run-test.sh test_burning_embers_config.gd 60     # 156/0
./scripts/run-test.sh test_burning_embers_state.gd 60      # 54/0
./scripts/run-test.sh test_pins_a7.gd 60                   # 38/0
./scripts/run-test.sh test_scarecrow_sheet.gd 60           # 36 PASS, 0 failures
./scripts/run-test.sh test_scarecrow_walk_readback.gd 60   # 68 PASS, 0 failures
./scripts/run-test.sh test_archer_parts.gd 60              # 13/0
./scripts/run-test.sh test_archer_shot_readback.gd 60      # 166/0
./scripts/run-test.sh test_archer_state_machine.gd 60      # 107/0
./scripts/run-test.sh test_archer_edges.gd 60              # 325/0
grep -l -E "SHADER ERROR|SCRIPT ERROR|Failed loading resource" logs/*.log   # expect no output
git diff --stat 62d7f72 a7 -- godot/                       # expect no output: the film shows this game source
```
