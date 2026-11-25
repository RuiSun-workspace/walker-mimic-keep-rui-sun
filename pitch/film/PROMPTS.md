# PROMPTS — Mimic Keep final project pitch

No generative model made any picture, sound or clip in this film. There is no paid service, API key or
network call in the build.

- **Voice:** local Kokoro v1.0 (`am_onyx`), run by the toolkit's `generate_audio_kokoro.py`. Its input is the
  narration text in `pitch/beat_sheet.json`, nothing else.
- **Narration text:** drafted by Claude (Claude Code, Opus 5.5) on 2026-11-24 from `pitch/PROJECT-BRIEF.md` and
  Rui's answers (`pitch/brief-answers-zh.md`); read and approved by Rui the same day ("可以定稿"). It speaks in the
  first person as Rui.
- **Pictures:** drawn by `pitch/build/make_stills.py` (Pillow), using the game's own code-drawn sprites and
  verbatim repository text; no image model.
- **Gameplay:** Godot Movie Maker recording of Rui playing by hand (take play-r0, tag a7).
- **No Claude response is shown in the film.** The prompts that drove this work were Rui's chat messages in the
  Claude Code session (2026-11-23 to 11-24); the decisions they carried are quoted in `pitch/brief-answers-zh.md`
  and the beat sheet metadata. The rebuild commands are in `pitch/BUILD-PROMPT.md`.
