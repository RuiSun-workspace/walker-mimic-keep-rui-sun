# Film records — claude-liam-walker-mimic-keep-a7-gamedev

The text records of the Assignment 7 film, copied from the working reel (`F:/7270/reels/…`) on 2026-11-22. The
MP4, the narration audio, the engine frames and the composed stills are not in this repository (course rule: no
MP3/MP4 or large media in GitHub); the film itself is linked from the top-level README.

| | |
|---|---|
| Master | `claude-liam-walker-mimic-keep-a7-gamedev.mp4`, 3840×2160, 30 fps, H.264 + AAC, 327.2 s, 24,932,405 bytes |
| SHA-256 | `dae506e8e44ebf96a470f4fb343937968c22612b58bad28278d9601a3471454b` |
| Game source shown | `62d7f72` (game files identical to `0726ae3`, the kept r1 tuning, plus `assets/sprites/ATTRIBUTION.md`) |
| Checks | `verify_gamedev.py … --game godot`: PASS (107 files, 4 exact excerpts, 4 code→result pairs); Gate V: 0 BLOCKER, 0 MAJOR over 42 sampled frames; −24.6 LUFS integrated |

| File | What it is |
|---|---|
| `SHOTLIST.md` | The 21 beats, approved by Rui before anything was recorded |
| `beat_sheet.json` | The beats as rendered: narration, shots, labels, capture windows, provenance stamps |
| `build_beats.py` | The script: every narration line and on-screen card, with the code excerpts read verbatim from the repository |
| `FACTCHECK.md` | Each claim in the narration and the record it comes from |
| `gamedev-evidence.json` | Evidence ledger (schema 1, `code-then-result-v1`): every `godot/` file hashed, 4 verbatim excerpts, 4 code → result pairs |
| `*.verified.json` | The toolkit's verification record for the master |
| `CAPTURE.md`, `capture/` | Capture driver `capture_a7_film.gd`, the take logs, source commit, build id, manifest, chosen windows |
| `BUILD-PROMPT.md`, `PROMPTS.md`, `*.py`, `jingle.json`, `assets/sources.json` | How the reel was built (with every deviation), what generated what, and the hashes of every still's inputs |
| `toolkit-local-patch.diff` | The local, uncommitted change to the toolkit's `GodotDesignBoard.tsx` (same as A5/A6) |

Coverage, against the assignment's film list: B02-B03 the game, both clips, routes, which loops and which commits;
B04-B06 Q1 (what a clip is; a missing property fails silently), the sheet, its slicing and the frame track; B07-B09
Q4 (feel in frames), the phase table beside the key times, the strip at each boundary; B10 the observation-driven
revision; B11-B13 Q2 (one authority) and Q3 (two clocks, measured); B14 the cycle in play; B15 the state machine in
real play with an interrupt in each phase (scripted keys, labelled); B16 read-backs, mutations, the headless limit;
B17 mistakes caught, readings overruled, what remains uncertain; B18 verdict, next step, contributions, the sheet's
source and licence, the revision shown.
