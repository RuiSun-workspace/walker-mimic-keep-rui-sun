# CAPTURE — A6 explainer

| Field | Value |
| --- | --- |
| Source commit at capture | `3b99ea6` (`capture/source-commit.txt`; working tree clean) |
| `build_id` | `capture/build_id.txt` = SHA-256 of `capture/source-manifest.txt` (the isolated copy's files) |
| Engine | Godot 4.7.2.stable.official.ed1daf0bf, Forward+, Vulkan, NVIDIA GeForce RTX 3070 Laptop GPU |
| Isolated copy | `F:/7270/capture-build-a6` = `git archive 3b99ea6 godot`, plus `window_width_override=3840` / `window_height_override=2160` in its `project.godot` (an exact 3× of the 1280×720 viewport) |
| Driver | `capture/capture_a6_film.gd`, copied into the copy's `tests/`. It never sets game state and never teleports; the play take places scarecrows with `spawn_scarecrow()`, as the state tests do. |

```bash
Godot_v4.7.2-stable_win64_console.exe --path F:/7270/capture-build-a6/godot --disable-vsync --fixed-fps 30 \
  --write-movie REEL/_frames/<take>/f.png --script res://tests/capture_a6_film.gd -- --take <take>
```

| Take | Frames | What happens | Used in |
|---|---|---|---|
| play | 480 (16 s) | spawning off; far scarecrow placed at (640, 0), near one at (680, 530) after the archer's first shot, two more at 3.0 s; the archer fires real arrows on its own, no keys. Hits 2 frames apart at 0.60/0.67 s, three bursts under `World/Effects` at 1.27 s. Log: `capture/take-play.log` | B02 frames 60-455 full frame; B08 frames 0-361, cropped to game y 0-600, 1.2× |
| burn | 480 (16 s) | spawning and archer off; middle scarecrow hit through `Scarecrow.hit()` at 1.0 s and 3.0 s, real Esc key at 4.0 s and 5.5 s; it dies while burning; the left one is hit four times from 8.0 s and dies while burning. Log: `capture/take-burn.log` | B13 frames 15-456, cropped to game (240,170)-(1040,620), 1.6× |

Dropped takes, kept honest:
- `idle` (36 s, spawning on, rng seed 7270, no input): every scarecrow died at the top edge, under the HUD, so
  both effects were small and partly covered. Its log is `capture/take-idle.log`; its hit lines carry the frame a
  scarecrow was connected, not the hit frame (a bug in the driver's closure, fixed in the play take).
- A first `burn` take of 12 s was too short for B13's narration (14.7 s); capture beats are never retimed, so it
  was re-recorded at 16 s with the same script.

Movie Maker renders offline and records no game audio here; capture beats carry the narration alone. The
stills are the repository's own fixture strips (`captures/`) and verbatim log lines, composed by `make_assets.py`.
