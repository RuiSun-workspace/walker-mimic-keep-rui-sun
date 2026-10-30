# BUILD-PROMPT — how the A5 reel was produced

Local only: no paid service, no API key, no network call.

| Tool | Version | Where |
| --- | --- | --- |
| Godot | 4.7.2.stable.official.ed1daf0bf | `C:/Users/18500/Desktop/7270/godot-4.7.2/` (portable) |
| Python | 3.11 venv | `F:/7270/film-env/` |
| ffmpeg | 9.0.1 essentials | `F:/7270/tools/ffmpeg-9.0.1-essentials_build/bin/` |
| Remotion / Kokoro | toolkit `runtime/` | `F:/7270/brutalist.art` (`29ba0e8`), Kokoro v1.0 `am_onyx` |

## Steps

```bash
# 0. isolated 4K copy (repository untouched)
git archive 879324b godot | tar -x -C F:/7270/capture-build-a5     # + 3840x2160 window override
# 1. captures: takes idle and fade (CAPTURE.md)
# 2. beat sheet, stills, narration
python build_beats.py
python make_assets.py
python runtime/scripts/generate_audio_kokoro.py REEL
# 3. graphic scenes (from PowerShell), pilot B04 first, then the rest
python runtime/scripts/remotion_scenes.py REEL --only B04
python runtime/scripts/remotion_scenes.py REEL
python patch_beats.py                      # pilot-review fixes, then re-render B01 B03 B11 B18 B20 B22 with --force
# 4. capture cuts (+ burned labels), durations, stills into media/
python cut_clips.py
# 5. evidence ledger and check
python make_evidence.py
PYTHONUTF8=1 python skills/make/godot-gamedev/scripts/verify_gamedev.py REEL --game <repo>/godot
# 6. master
python runtime/scripts/compile.py REEL --height 2160 --fps 30 --out REEL/exports/landscape
```

## Deviations, and why

1. `./art …` entry points were not used; their scripts were called directly (the same `./setup` / `./art doctor`
   guard defect as A1-A3). Remotion was run from PowerShell (Git Bash's npx cannot find node).
2. **One local patch to the toolkit**, not committed upstream: `runtime/remotion/src/scenes/GodotDesignBoard.tsx`
   gains an optional `excerptLabel` prop (schema line 10, label line 49), default unchanged
   (`GDD · DOCUMENT EXCERPT`). This film's boards quote CHANGE-BRIEF.md, CLAUDE.md and FRICTIONAL.md, not a GDD, so
   they pass `DOCUMENT EXCERPT`. (A2's one-line `@NikBearBrown` position patch in the same file is also still there.)
3. `verify_gamedev.py` reads files with the system codec; on this Chinese-locale Windows it needs `PYTHONUTF8=1`.
4. Stills are full-frame `STILL` beats composed by `make_assets.py` from committed evidence files; their provenance
   labels are burned into the image. `compile.py` reads them from `media/<beat>.png`, so `cut_clips.py` copies every
   still there (a first compile showed B08 as a blank slate before that).
5. Pilot-review fixes (`patch_beats.py`): B01's corrected line overflowed; B18 lost its last line; B20 pushed line 19
   out of the panel; the boards' stock label said "GDD".
