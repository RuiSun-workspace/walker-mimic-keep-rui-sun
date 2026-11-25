# BUILD-PROMPT — how to rebuild the pitch film

Local only: no paid service, no API key, no network call, no upload. Built by Claude on 2026-11-24 with the
local Brutalist checkout. Everything the film says comes from `pitch/beat_sheet.json`; the scripts below only
turn it into pictures, clips and sound.

## Tools

| Tool | Version | Where on the build machine |
|---|---|---|
| Godot | 4.7.2.stable.official.ed1daf0bf (Forward+) | `C:/Users/18500/Desktop/7270/godot-4.7.2/` (portable) |
| Brutalist toolkit | `nikbearbrown/brutalist.art` at `29ba0e8`, two local edits from earlier assignments (`GodotDesignBoard.tsx`, `package-lock.json`); neither is used by this film | `F:/7270/brutalist.art` |
| Kokoro | v1.0, voice `am_onyx` (local ONNX model) | `F:/7270/brutalist.art/runtime/models/kokoro/` |
| Python | 3.11 venv with the toolkit's `requirements.txt` (Pillow, numpy, kokoro-onnx) | `F:/7270/film-env/` |
| ffmpeg | 9.0.1 essentials | `F:/7270/tools/ffmpeg-9.0.1-essentials_build/bin/` |

Shell setup (Git Bash):

```bash
export PATH="/f/7270/tools/bin:/f/7270/tools/ffmpeg-9.0.1-essentials_build/bin:$PATH"
export PYTHONUTF8=1 PYTHONIOENCODING=utf-8      # the toolkit reads JSON without an encoding
PY=/f/7270/film-env/Scripts/python.exe
REEL=/f/7270/reels/mimic-keep-final-pitch
```

## 1. The gameplay take (Rui, by hand)

```bash
git archive a7 godot | tar -x -C /f/7270/capture-build-a8            # isolated copy of tag a7 (39f3fe8)
godot --headless --path /f/7270/capture-build-a8/godot --import
```

```powershell
& "C:\Users\18500\Desktop\7270\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe" --path "F:\7270\capture-build-a8\godot" --fixed-fps 30 --write-movie "F:\7270\a8-captures\play-r0\f.png"
```

Rui played one run with the keyboard and won at 1:30 (3047 frames, 1280×720). The frames stay outside git.

## 2. Sheet, voice, clips, pictures

```bash
$PY pitch/build/build_reel.py                                   # pitch/beat_sheet.json -> $REEL/beat_sheet.json
(cd /f/7270/brutalist.art && $PY runtime/scripts/generate_audio_kokoro.py $REEL)   # mp3/ + timings.json
$PY pitch/build/build_reel.py                                   # again: keeps the measured durations
$PY pitch/build/cut_clips.py                                    # B00 B03 B07 B15 from play-r0, labels burned in
$PY pitch/build/make_stills.py                                  # the 14 picture beats
cp pitch/film/FACTCHECK.md pitch/film/SHOTLIST.md pitch/film/PROMPTS.md $REEL/    # Gate F paperwork
```

## 3. Master and gates

```bash
(cd /f/7270/brutalist.art && $PY runtime/scripts/compile.py $REEL --height 2160 --fps 30 --out $REEL/exports/landscape)
```

`compile.py` runs the toolkit's gates itself and refuses to write a master if one fails: the project and
paperwork checks (`build_safety.py`, Gate F), `beat_lint.py`, `gate_shape.py`, the output probe, and Gate V
(`final_frame_check.py`, every beat's pixels against the title-safe area). Their reports are copied into
`pitch/gates/`.

## Why not `./art final`, show-tell, or the walker bookends

- `./art` stops at its own setup guard on this checkout (a defect logged since Assignment 1), so the scripts it
  wraps are called directly.
- The `show-tell` skill is not in this checkout (it exists only upstream, with Manim and a newer Remotion).
- The toolkit's walker bookends greet as "Liam, in for Bear" and close on the instructor's handle and jingle;
  the assignment forbids the instructor's name, persona and credit line, so this film has its own first beat
  and title card and uses no Remotion scene at all.
