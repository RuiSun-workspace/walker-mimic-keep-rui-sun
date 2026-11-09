# BUILD-PROMPT — how the A6 reel was produced

Local only: no paid service, no API key, no network call. Built by Claude on 2026-11-08 on the A5 reel's scripts
(`youtube/claude-liam-walker-mimic-keep-a5-gamedev/`), the same toolkit checkout and the same local patch.

| Tool | Version | Where |
| --- | --- | --- |
| Godot | 4.7.2.stable.official.ed1daf0bf | `C:/Users/18500/Desktop/7270/godot-4.7.2/` (portable) |
| Python | 3.11 venv | `F:/7270/film-env/` |
| ffmpeg | 9.0.1 essentials | `F:/7270/tools/ffmpeg-9.0.1-essentials_build/bin/` |
| Remotion / Kokoro | toolkit `runtime/` | `F:/7270/brutalist.art`, Kokoro v1.0 `am_onyx` |

## Steps

```bash
# 0. isolated 4K copy (repository untouched)
git archive <source> godot | tar -x -C F:/7270/capture-build-a6     # + 3840x2160 window override
# 1. captures: takes burn and idle (CAPTURE.md)
# 2. beat sheet, narration, stills
python build_beats.py
python runtime/scripts/generate_audio_kokoro.py REEL               # then --only B03 B13 B16 after fact-check fixes
python stamp_audio.py                                              # re-stamp lengths after a rebuild
python make_assets.py
# 3. graphic scenes (from PowerShell)
python runtime/scripts/remotion_scenes.py REEL
python patch_beats.py                                              # B04/B05 order, B15 as a still (see the script)
# 4. capture cuts (+ burned labels), durations, stills into media/
python cut_clips.py
# 5. evidence ledger and check
python make_evidence.py
PYTHONUTF8=1 python skills/make/godot-gamedev/scripts/verify_gamedev.py REEL --game <repo>/godot
# 6. master
python runtime/scripts/compile.py REEL --height 2160 --fps 30 --out REEL/exports/landscape
```

## Deviations, and why

1. `./art …` entry points were not used; their scripts were called directly (the `./setup` / `./art doctor`
   guard defect noted since A1). Remotion was run from PowerShell.
2. The local `GodotDesignBoard.tsx` patch from A5 (optional `excerptLabel`) is still in the toolkit checkout; this
   film's boards quote CHANGE-BRIEF.md, TUNING.md and FRICTIONAL.md, so they pass `DOCUMENT EXCERPT`.
3. Fact-check before the master changed three narrations (B03 "one gameplay change", B13 the middle scarecrow
   dies while burning rather than burning out, B16 the swapped screenshots); only those three were re-voiced.
4. Reading `verify_gamedev.py` showed every code beat must be followed directly by a result beat with media.
   `patch_beats.py` swapped the rendered B04/B05 and turned B15 into a still of verbatim log lines.
5. The burn take was first recorded at 12 s; B13's narration needs 14.7 s, and capture beats are never retimed,
   so the take was re-recorded at 16 s with the same script.
