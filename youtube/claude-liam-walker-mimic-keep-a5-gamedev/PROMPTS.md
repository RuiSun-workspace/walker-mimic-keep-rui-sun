# PROMPTS

## What Rui asked for (verbatim, in chat, 2026-10-29)

- "做影片"
- Plan approval on a question card: "全部批准 (Recommended)" for: about 23 beats, 5-6 minutes; a new scripted 4K
  capture; Liam / Kokoro am_onyx, English, Rui referred to as Rui or they; the four on-screen labels; the five named
  agent mistakes; the next step "fix the long-range miss (aiming lead, homing and fixed-trajectory arrows)"; the
  slug-seeded stock jingle; working files on F:, text records copied into the repository, no MP4 in GitHub; long
  renders on this machine.

The final cut has 26 beats and about 6¼ minutes of narration plus the outro, slightly over the plan.

## On-screen prompts (illustrative reconstructions, not transcripts)

B00, the walker ask:

> Please use Walker to convert my game design document about Mimic Keep, a castle-defense roguelite where an archer
> on the wall shoots fire arrows at straw scarecrows, into an Assignment 5 change: a hand-written canvas_item shader
> that tints a scarecrow while it is Burning, driven from game state, and a hand-written spatial shader that reads
> wood textures onto a shield, used by two materials. I write every shader line; you write the driver, the tests
> and the evidence.

B24, Your Turn:

> Use Walker. Pick one game state my player cannot see yet. I will write its colour line and the pixel values I
> expect before I write the shader myself. Then write a driver that sets the uniform from game time, a headless
> test at 30, 60 and 144 fps, and an in-engine capture of my controlled values. Break the shader on purpose once and
> show me the test fail. Never edit my shader.

## Real prompts behind the work shown

The agent sessions' prompts are committed in the repository: `prompts/prompt-1.txt` (CLAUDE.md draft),
`prompts/prompt-2.txt` and `prompt-2b.txt` (driver and test), `prompts/prompt-3.txt` (material audit, the course
text verbatim), with their transcripts in `sessions/`.

## Voice

Kokoro v1.0, voice `am_onyx`, local (`runtime/scripts/generate_audio_kokoro.py`), $0.00. Greeting "Kia ora"
(not used by any other reel in the toolkit or in A1-A3).
