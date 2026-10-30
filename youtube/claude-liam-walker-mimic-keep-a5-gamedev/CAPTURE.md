# CAPTURE — A5 explainer

| Field | Value |
| --- | --- |
| Source commit at capture | `879324b` (`capture/source-commit.txt`; working tree clean) |
| `build_id` | `capture/build_id.txt` = SHA-256 of `capture/source-manifest.txt` (89 files of the isolated copy) |
| Engine | Godot 4.7.2.stable.official.ed1daf0bf, Forward+, Vulkan, NVIDIA GeForce RTX 3070 Laptop GPU |
| Isolated copy | `F:/7270/capture-build-a5` = `git archive 879324b godot`, plus `window_width_override=3840` / `window_height_override=2160` in its `project.godot` (an exact 3× of the 1280×720 viewport) |
| Driver | `capture/capture_a5_film.gd`, copied into the copy's `tests/`. It never sets game state and never teleports. |

```bash
Godot_v4.7.2-stable_win64_console.exe --path F:/7270/capture-build-a5/godot --disable-vsync --fixed-fps 30 \
  --write-movie REEL/_frames/<take>/f.png --script res://tests/capture_a5_film.gd -- --take <take>
```

| Take | Frames | What happens | Used in |
|---|---|---|---|
| idle | 1500 (50 s) | spawning on, rng seed 7270, no input; the archer fires on its own. Log: `capture/take-idle.log` | B02, frames 990-1443 (33.0-48.1 s) |
| fade | 360 (12 s) | spawning and archer off; middle scarecrow hit with fire through `Scarecrow.hit()` at 1.0 s and 3.5 s, real Esc key at 4.5 s and 6.0 s, burns down at 7.53 s. Log: `capture/take-fade.log` | B07, frames 15-358 (0.5-11.93 s), cropped to game (240,170)-(1040,620) and scaled 1.6× |

Dropped takes, kept honest:
- `play` (30 s, scripted key presses towards the nearest scarecrow): every scarecrow died at the top edge within
  about two seconds of appearing, so the tint was barely on screen. Its log is `capture/take-play.log`.
- A first `idle` run had spawning off by a bug in the driver and recorded 75 s of empty meadow.
- With no player the idle take loses at about 56 s: scarecrows at the wall cannot be shot on this revision (the
  fault Rui found; fixed only on branch `gameplay-fixes`). The take stops at 50 s and B02 ends at 48.1 s.

Movie Maker renders offline, so the takes say nothing about real-time frame rate, and it records no game audio;
the capture beats' audio is the narration alone. The stills are not captured for the film: they are the
in-engine captures already committed in the repository's `evidence/`, plus Rui's screenshot.
