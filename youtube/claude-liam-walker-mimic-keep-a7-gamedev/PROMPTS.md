# PROMPTS — what generated what in the A7 film

No paid or remote generation. Nothing in the film is AI-generated imagery.

| Element | How it was made |
|---|---|
| Narration | Kokoro v1.0, voice `am_onyx`, local (`runtime/scripts/generate_audio_kokoro.py`, run at Idle priority), from the `narration_text` in `build_beats.py`, written by Claude from the repository's records (`FACTCHECK.md`) |
| Graphic beats | Remotion scenes of the toolkit (`runtime/scripts/remotion_scenes.py`) with the props in `beat_sheet.json`; code panels quote the repository verbatim |
| Engine footage | Godot 4.7.2 Movie Maker, native 3840×2160, from an isolated copy of `62d7f72` driven by `capture/capture_a7_film.gd` |
| Stills | `make_assets.py`: the sheet PNG as loaded by the game, committed fixture-strip frames from `captures/` (cropped, nearest-neighbour), Rui's words from TUNING.md and TEST-REPORT.md, verbatim log lines |
| B00 / B19 prompts | illustrative reconstructions of a Walker ask and a Your Turn prompt, labelled as such; not transcripts |
| Outro jingle | stock @NikBearBrown `bear-brown-1.mp3`, chosen by sha256(slug) mod 6 + 1, −8 dB |
