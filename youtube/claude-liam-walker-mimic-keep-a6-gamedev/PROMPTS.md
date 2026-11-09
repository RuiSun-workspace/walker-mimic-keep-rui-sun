# PROMPTS — what generated what in the A6 film

No paid or remote generation. Nothing in the film is AI-generated imagery.

| Element | How it was made |
|---|---|
| Narration | Kokoro v1.0, voice `am_onyx`, local (`runtime/scripts/generate_audio_kokoro.py`), from the `narration_text` in `build_beats.py`, written by Claude from the repository's records |
| Graphic beats | Remotion scenes of the toolkit (`runtime/scripts/remotion_scenes.py`) with the props in `beat_sheet.json`; code panels quote the repository verbatim |
| Engine footage | Godot 4.7.2 Movie Maker, native 3840×2160, from an isolated copy of `3b99ea6` driven by `capture/capture_a6_film.gd` |
| Stills | `make_assets.py`: committed fixture-strip frames from `captures/` (cropped, nearest-neighbour), Rui's words from TUNING.md, verbatim log lines |
| B00 / B18 prompts | illustrative reconstructions of a Walker ask and a Your Turn prompt, labelled as such; not transcripts |
| Outro jingle | stock @NikBearBrown `bear-brown-3.mp3`, chosen by sha256(slug) mod 6 + 1, −8 dB |
