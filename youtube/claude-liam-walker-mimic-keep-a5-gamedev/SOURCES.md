# SOURCES — what is on screen, and where it came from

## Source revision

`walker-mimic-keep-rui-sun` at `879324b` (capture/source-commit.txt). Every code panel is verbatim from that commit;
`gamedev-evidence.json` holds the SHA-256 of all 62 authored files under `godot/` and of every result medium.

## Engine captures made for this film

`_frames/idle` and `_frames/fade`, native 3840×2160 Godot Movie Maker output of the isolated copy (CAPTURE.md).
The cut clips `media/B02.mp4` and `media/B07.mp4`, with their windows and SHA-256, are in `capture/windows.json`
and in each beat's `shot.capture_window`.

## Stills (assets/sources.json has the SHA-256 of every input)

| Beat | Inputs (repository paths) |
|---|---|
| B05 | `evidence/controlled_values/burn_values_zoom.png`, `pixels.txt` (tools/capture_burn_values.gd) |
| B08 | `evidence/in_play/one_burning.png` (Rui's screenshot); Rui's chat words as recorded in TEST-REPORT.md |
| B10 | `logs/test_burning_tint_{30,60,144}fps.log`, `evidence/mutations/m1_*`, `m2_*` |
| B13 | `evidence/hint_experiment/hint_experiment_render.png`, `band_values.txt` |
| B15 | `evidence/two_materials/0_before.png`, `logs/normal_map_check_60fps.log`, `my-observations.txt:39` |
| B17 | `evidence/sweep/*_{min,default,max}.png` (crops from `sweep.txt`) |
| B19 | `evidence/two_materials/{0_before,1_shader_edit,2_material_edit}.png`, `my-observations.txt:53` |
| B21 | `evidence/mutations/m3_source_color.diff`, `m3_source_color_test_materials_60fps.log` |

## Textures shown

Poly Haven, Wood Planks 1K (diff, rough, nor_gl; nor_dx for calibration only), by Amal Kumar, CC0; provenance and
md5 in the repository's `godot/assets/textures/wood_planks/ATTRIBUTION.md`. The scorch mask and the grey strip are
written by `godot/tools/make_scorch_mask.gd` and `make_hint_greys.gd`.

## Audio

Narration: Kokoro v1.0 `am_onyx`, local. Outro: `logos/bear-brown/bear-brown-6.mp3` from the toolkit, −8 dB
(jingle.json). No game audio.

## Documentation consulted

None beyond the repository and the toolkit's skill files (`skills/make/godot-gamedev/SKILL.md`,
`references/evidence.md`).
