# Film records — claude-liam-walker-mimic-keep-a6-gamedev

The text records of the Assignment 6 film, copied from the working reel (`F:/7270/reels/…`) on 2026-11-08.
The MP4, the narration audio, the engine frames and the composed stills are not in this repository (course
rule: no MP3/MP4 or large media in GitHub); the film itself is linked from the top-level README.

| File | What it is |
|---|---|
| `beat_sheet.json` | The 20 beats as rendered: narration, shots, labels, capture windows, provenance stamps |
| `build_beats.py` | The script: every narration line and on-screen card, with the code excerpts read verbatim from the repository |
| `gamedev-evidence.json` | Evidence ledger (schema 1, `code-then-result-v1`): every `godot/` file hashed, 3 verbatim excerpts, 3 code → result pairs |
| `*.verified.json` | The toolkit's verification record for the master |
| `CAPTURE.md`, `capture/` | Capture driver `capture_a6_film.gd`, the take logs, source commit, build id, manifest, chosen windows |
| `BUILD-PROMPT.md`, `*.py`, `jingle.json`, `assets/sources.json` | How the reel was built (with every deviation), and the hashes of every still's inputs |
| `toolkit-local-patch.diff` | The local, uncommitted change to the toolkit's `GodotDesignBoard.tsx` (same as A5's) |

Coverage: B03 jobs, event and condition; B04/B09 intent blocks; B05 the three parts of a particle system
(emitter, process, draw) from `impact_burst.tscn`; B06/B11 first strips with Rui's first verdicts; B07/B12
revisions (observation, prediction, before/after strips, verdict); B08/B13 the effects in play (rapid repeats;
start, refresh, pause, death); B10 the feedback driver; B14 two annotated lines of `particles_generated.gdshader`
beside the brief's settings; B15 tests, mutations, both prices against budget, the headless limit; B16 mistakes
caught, readings overruled, what remains uncertain; B17 verdict, next step, contributions, texture sources, revision.

`verify_gamedev.py … --game godot` passed against commit `3b99ea6`.
