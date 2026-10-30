# Film records — claude-liam-walker-mimic-keep-a5-gamedev

The text records of the Assignment 5 film, copied from the working reel (`F:/7270/reels/…`) on 2026-10-29.
The MP4, the narration audio, the engine frames and the composed stills are not in this repository
(course rule: no MP3/MP4 or large media in GitHub); the film itself is linked from the top-level README.

| File | What it is |
|---|---|
| `beat_sheet.json` | The 26 beats as rendered: narration, shots, labels, capture windows, provenance stamps |
| `SHOTLIST.md`, `COMPONENTS.md`, `FACTCHECK.md`, `RIFF.md`, `PROMPTS.md`, `SOURCES.md` | Script and coverage records; FACTCHECK ties every narrated claim to a file |
| `gamedev-evidence.json` | Evidence ledger (schema 1, `code-then-result-v1`): every `godot/` file hashed, 8 verbatim excerpts, 8 code → result pairs |
| `claude-liam-walker-mimic-keep-a5-gamedev.verified.json` | The toolkit's verification record for the master |
| `qc/frame-qc-REPORT.md` | The toolkit's frame QC on the final candidate (0 BLOCKER, 0 MAJOR) |
| `CAPTURE.md`, `capture/` | Capture driver `capture_a5_film.gd`, the take logs, source commit, build id, manifest, cut windows |
| `BUILD-PROMPT.md`, `*.py`, `jingle.json`, `assets/sources.json` | How the reel was built, and the hashes of every still's inputs |
| `toolkit-local-patch.diff` | The local, uncommitted change to the toolkit's `GodotDesignBoard.tsx` (includes A2's earlier one-line patch) |

`gamedev-evidence.json` and `beat_sheet.json` name media under `media/`; those files stay with the reel.
The checker run (`verify_gamedev.py … --game godot`) passed against commit `879324b`.
