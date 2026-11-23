# BUILD-PROMPT — how the A7 reel was produced

Local only: no paid service, no API key, no network call. Built by Claude on 2026-11-22 on the A6 reel's scripts
(`youtube/claude-liam-walker-mimic-keep-a6-gamedev/`), the same toolkit checkout and the same local patch. The shot
list (`SHOTLIST.md`) was approved by Rui before anything was recorded.

| Tool | Version | Where |
| --- | --- | --- |
| Godot | 4.7.2.stable.official.ed1daf0bf | `C:/Users/18500/Desktop/7270/godot-4.7.2/` (portable) |
| Python | 3.11 venv | `F:/7270/film-env/` |
| ffmpeg | 9.0.1 essentials | `F:/7270/tools/ffmpeg-9.0.1-essentials_build/bin/` |
| Remotion / Kokoro | toolkit `runtime/` | `F:/7270/brutalist.art`, Kokoro v1.0 `am_onyx` |

## Steps

```bash
# 0. isolated 4K copy (repository untouched)
git archive 62d7f72 godot | tar -x -C F:/7270/capture-build-a7      # + 3840x2160 window override
# 1. driver dry runs headless, then the takes play and interrupts (CAPTURE.md)
# 2. beat sheet, narration, stills
python build_beats.py
python runtime/scripts/generate_audio_kokoro.py REEL               # Idle priority
python stamp_audio.py
python make_assets.py
# 3. graphic scenes (from PowerShell, with the venv's python.exe)
python runtime/scripts/remotion_scenes.py REEL
python runtime/scripts/remotion_scenes.py REEL --only B04|B08|B11|B13 --force   # after the font/notes fix
# 4. capture cuts (+ burned labels), durations, stills into media/
python cut_clips.py
# 5. evidence ledger and check
python make_evidence.py
python skills/make/godot-gamedev/scripts/verify_gamedev.py REEL --game <repo>/godot      # PASS
# 6. master
python runtime/scripts/compile.py REEL --height 2160 --fps 30 --out REEL/exports/landscape
```

## Deviations, and why

1. `./art …` entry points were not used; their scripts were called directly (the `./setup` / `./art doctor`
   guard defect noted since A1). Remotion was run from PowerShell. The first Remotion run did nothing: `python`
   in PowerShell did not resolve to the venv; it was re-run with `F:/7270/film-env/Scripts/python.exe`.
2. The local `GodotDesignBoard.tsx` patch from A5 (optional `excerptLabel`) is still in the toolkit checkout.
3. Inspecting the first renders showed the four 14-line code panels clipped (B11 lost line 40, the cancel line the
   narration points at) and their third note cut off. `codeFontSize` was lowered to 21 (B04, B08) and 19 (B11,
   B13), the notes were shortened, `build_beats.py` was changed to match, and only those four scenes re-rendered.
4. Stills were inspected before use: B05's frame labels sat on the art and moved above the sheet; B06's "the game
   does not complain" was cut back to what was checked (no ERROR line while the scene loads); B10 had shortened
   Rui's fixture verdict with an ellipsis that dropped "很难完全区分三个阶段", and now quotes it in full.
5. The `interrupts` take was re-recorded 30 frames longer to cover B15's narration (CAPTURE.md).
6. The first two compiles were refused by Gate F (no SHOTLIST.md, then no PROMPTS.md in the reel); the approved
   shot list was copied in and PROMPTS.md written.
7. The third compile was refused by Gate V: the provenance labels on stills B05, B06, B09 and B16 crossed the
   title-safe bottom line (y 2052 at 4K). Every still's label moved up to y 1940.
8. Watching the first passing master (a frame every 8 s) showed the burned-in label covering the archer in B15
   and the walker at the wall in B14; both crops were moved so the subject sits above the label. B03's and B17's
   document excerpts had been taken as whole hard-wrapped lines (one ended "… A", one began mid-sentence); they
   are now exact sentences, and both boards were re-rendered.
