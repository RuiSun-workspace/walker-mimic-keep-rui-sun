# Gate reports

Produced by the toolkit's own `compile.py` (Brutalist @ 29ba0e8), which refuses to write a master when a gate fails.

| File | What it is |
|---|---|
| `compile-1.log` | first master: refused by Gate V before sampling (regional contrast boxes on the pictures had no written reason) |
| `compile-2.log` | second master: refused by Gate V (28 BLOCKER edge-bleed, 4 MAJOR label contrast); details in `../FRICTIONAL.md` — its full REPORT.md was overwritten by the next run |
| `compile-3.log` | the submitted master: every slot filled, Gate F paperwork present, `beat_lint.py` and `gate_shape.py` clean, Gate V clean |
| `gate-v-REPORT.md` | Gate V (`final_frame_check.py`) on the submitted master: 36 frames sampled, 0 BLOCKER, 0 MAJOR |
| `gate-v-contact_sheet.png` | the frames Gate V sampled |
| `mimic-keep-final-pitch.verified.json` | the toolkit's render-integrity record: master SHA-256, duration, and the SHA-256 of every input clip, picture and sound |

The three `SKIN LINT` lines in `compile-3.log` are advisory and expected: they ask for the instructor-branded
cold open and outro, which this assignment forbids and this film does not use.

Measured on the master by Claude (ffmpeg 9.0.1, 2026-11-24): 3840×2160, 30 fps, h264 + AAC 48 kHz stereo,
216.77 s, integrated loudness −24.4 LUFS, no silence longer than 2 s at −50 dB.
