# SOURCES — Mimic Keep final project pitch

## What Rui made

- The game Mimic Keep as it stands at tag `a7`, built across Assignments 5–7 with Claude Code (see the repo's
  root `SOURCES.md` for who wrote what in each assignment). The burning tint shader is Rui's own hand-written code
  (`6a2c298`).
- Every choice in the pitch: the project direction (one level + endless mode), the three elements and two
  reactions, the target role (technical designer), the reader (hiring manager), the comparable games, and the
  account of what is new learning. Rui's words are kept verbatim in `brief-answers-zh.md`.
- The gameplay take `play-r0`: Rui played it by hand on 2026-11-24 and chose the late part of the run.
- The 2022 tile-matching game and its console screenshot (`evidence/2022-lianliankan-console.png`).
- Approval of the narration ("可以定稿", 2026-11-24).

## What Claude contributed (Claude Code, Opus 5.5, 2026-11-23 to 11-24)

- Drafted `PROJECT-BRIEF.md` and the narration in `beat_sheet.json` from Rui's answers and repository facts;
  every `[proposed]` detail is marked in the brief. The narration speaks as Rui, in the first person.
- Wrote the build scripts in `build/`, drew the picture beats, cut and labelled the clips, cropped the 2022
  screenshot, wrote `film/FACTCHECK.md`, `film/SHOTLIST.md`, `film/PROMPTS.md`, `BUILD-PROMPT.md` and this file.
- Checked every claim against the repository (`film/FACTCHECK.md`).
- Earlier: wrote `godot/tools/balance_sim.gd`, the bot simulation the film mentions (Assignment 5).

## Third-party tools and assets

| What | Licence | Used for |
|---|---|---|
| Brutalist toolkit (`nikbearbrown/brutalist.art` @ 29ba0e8) | as published by its author for the course | compile pipeline and gates |
| Kokoro-82M v1.0 (kokoro-onnx), voice `am_onyx` | Apache-2.0 | the narration voice |
| Godot Engine 4.7.2 | MIT | the game and the Movie Maker capture |
| ffmpeg 9.0.1 | LGPL/GPL build | encoding, cropping, scaling |
| Pillow | MIT-CMU (HPND) | drawing the picture beats |
| Georgia, Segoe UI, Consolas, Microsoft YaHei | Windows system fonts, used as installed | on-screen text |

No third-party image, video or music is in the film. The game's sprites are drawn by code in the repository
(`godot/tools/make_sprites.gd`; see `godot/assets/sprites/ATTRIBUTION.md`). Genshin Impact and the WeChat
mini-game are named as comparables in text only; no logo, screenshot or footage of either appears. The 2022
game's tile and background art was not made by Rui and is deliberately not shown.
