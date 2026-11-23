# CAPTURE — A7 explainer

| Field | Value |
| --- | --- |
| Source commit at capture | `62d7f72` (`capture/source-commit.txt`); its `godot/` game files are identical to `0726ae3` (the r1 tuning) except the added `assets/sprites/ATTRIBUTION.md` |
| `build_id` | `capture/build_id.txt` = SHA-256 of `capture/source-manifest.txt` (the isolated copy's 158 files, without `.godot/` and the driver) |
| Engine | Godot 4.7.2.stable.official.ed1daf0bf, Forward+, Vulkan, NVIDIA GeForce RTX 3070 Laptop GPU |
| Isolated copy | `F:/7270/capture-build-a7` = `git archive 62d7f72 godot`, plus `window_width_override=3840` / `window_height_override=2160` in its `project.godot` (an exact 3× of the 1280×720 viewport) |
| Driver | `capture/capture_a7_film.gd`, copied into the copy's `tests/`. It never sets game state and never teleports: scarecrows are placed with `Game.spawn_scarecrow()`, as the state tests do, and keys are real `InputEventKey`s through `Input.parse_input_event`, each sent when the archer's observed state says so. |

```bash
Godot_v4.7.2-stable_win64_console.exe --path F:/7270/capture-build-a7/godot --disable-vsync --fixed-fps 30 \
  --write-movie REEL/_frames/<take>/f.png --script res://tests/capture_a7_film.gd -- --take <take>
```

| Take | Frames | What happens | Used in |
|---|---|---|---|
| play | 601 (20 s) | spawning off; two scarecrows in the cone, one at (110, 250) outside it; two more in the cone at 6 s; no keys. The archer draws and shoots 16 arrows on its own; the walker reaches the wall at frame 187 and holds. Log: `capture/take-play.log` | B02 frames 0-409, full frame; B14 frames 0-320, cropped to game x 0-853, y 176-656, 1.5× |
| interrupts | 571 (19 s) | one target at a time high in the cone. P at f44 (startup, bow −10.6°), released 2 s later, the shot finishes and fires; P at f145 with release_window true and the arrow not yet read (bow −16°), the arrow leaves on resume; P at f243 in recovery (bow 1.4°); D held through a draw from f329 (no interrupt, arrow at f342); field cleared, one scarecrow at the wall (610, 530), D from f442 at bow −2.3°, CANCELLED at f446 with no arrow. Log: `capture/take-interrupts.log` | B15 frames 0-559, cropped to game x 239-1041, y 230-681, 1.6× |

Dry runs and re-takes, kept honest:
- Headless dry run 1 of `interrupts` (2026-11-22): the recovery pause landed at clip 0.467 (bow 0.1°, nothing to
  see), and the wall-target run started at bow −6.2° so the release beat the cancel (an arrow was fired). The
  driver was changed to wait for a fresh arrow before the recovery pause, and to start running at −2°. Dry run 2
  confirmed both.
- The first windowed `interrupts` take had 541 frames; B15's narration needs 559 (18.22 s + 0.4 s tail), and
  capture beats are never retimed, so the end hold was lengthened by 30 frames and the take re-recorded. Its events
  are frame-identical to the first.

Movie Maker renders offline and records no game audio here; capture beats carry the narration alone. The stills
are the repository's own fixture strips (`captures/shoot/r0`, `r1`, `captures/walk/r0`), the sheet PNG and
verbatim log lines, composed by `make_assets.py`.
