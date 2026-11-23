# SHOTLIST — A7 explainer (DRAFT for Rui's approval, 2026-11-22)

Built like the A6 film (`youtube/claude-liam-walker-mimic-keep-a6-gamedev/`): course `godot-gamedev` skill,
`walker` bookends, Liam (local Kokoro `am_onyx`), native 3840×2160 landscape. Source shown: the game files as of
`0726ae3` (unchanged since; the capture commit is pinned when the takes are recorded). Every code panel is quoted
verbatim from a hashed file; every code beat is followed directly by a result beat with real engine output.

| Beat | Act | Shot | Source and label | Assignment requirement |
|---|---|---|---|---|
| B00 | ASK | ClaudeComposerAsk: "Please use Walker to convert my game design document about Mimic Keep…" | illustrative reconstruction | walker opening |
| B01 | BLUF | BrutalistHesitantWriter: "a passing test proves the motion reads → is built" | — | walker summary |
| B02 | GAME | CAPTURE take `play`: scarecrows walking (walk clip), stopping at the wall (hold), archer drawing and shooting on its own | "Scarecrows placed by the script · no keys pressed" | identify the game and both clips |
| B03 | BRIEF | GodotDesignBoard: the two clips — scarecrow walk = Sprite2D + AnimationPlayer frame track, the cycle; archer shot = keyed cutout rig + AnimationTree, the committing action; one authority each | CHANGE-BRIEF.md §1 | routes, which loops, which commits |
| B04 | CODE | GodotDevWorkbench: `game/scarecrow.tscn:19-31` (walk: `loop_mode = 1`, `Sprite:frame`, times 0/0.125/0.25/0.375, `update: 1`) + `:63` `hframes = 4` | verbatim | **Q1 what a clip is**; the frame track that reads the sheet |
| B05 | RESULT | STILL: the sheet `scarecrow_walk.png` with its 4×1 grid drawn over it, beside walk-strip cells 0-3 | "Fixture capture · walk_preview, camera follows the scarecrow" | the sheet, its slicing |
| B06 | PROOF | STILL: mutation 1a, `Sprite:frame` → `Sprite:frames`: the game raises no error, the read-back fails (verbatim log lines) | "Recorded output" | Q1: why a wrong property fails silently |
| B07 | BRIEF | GodotDesignBoard: phase table (8 / 1 / 6 frames at 30 fps, step 1/30) beside the key times built from it (0, 0.26666668, 0.3, 0.5) and the reference count (26 / 1 / 14 at 30 fps) | CHANGE-BRIEF.md §4 + `game/archer.tscn:84` | **Q4 feel in frames**; phase table beside key times |
| B08 | CODE | GodotDevWorkbench: `game/archer.tscn:80-87` (bow rotation keys, transitions 2 / 1 / 0.5) and the `.:release_window` track (discrete) | verbatim | the keys built from the table |
| B09 | RESULT | STILL: strip r1 frames 10 / 18 / 19 / 25 (trigger, full draw, arrow out, idle) with the log line under each | "Fixture capture · shoot_preview" | strip at each phase boundary |
| B10 | TUNING | STILL: r0 vs r1 at frame 18 (−8° → −16°): Rui's observation, the prediction, the comparison, Rui's verdict in the fixture and in play | "Fixture captures"; TUNING.md | observation-driven revision |
| B11 | CODE | GodotDevWorkbench: `game/archer.gd:28-40` (reads `release_window` in `_physics_process`, never writes it) + `game/archer.tscn:193-196` (`callback_mode_process = 0`, `advance_expression_base_node = ..`) | verbatim | **Q2 one authority**, **Q3 two clocks** |
| B12 | RESULT | STILL: strip frames 18 and 19 with their windowed-capture log lines: `release_window` true on tick 37, `fired@tick38` — one physics tick, 1/60 s | "Fixture capture · log from the same windowed run" | Q3 measured |
| B13 | CODE | GodotDevWorkbench: `game/scarecrow_walk_presenter.gd` (chooses walk/hold, never writes `Sprite.frame`) | verbatim | Q2 for the sprite: the presenter only picks the clip |
| B14 | PLAY | CAPTURE take `interrupts`, cropped on the archer: P in startup (bow freezes half-leaned, resumes, fires), P on the active tick, P in recovery, a move key during the draw (no interrupt), one target walked out of the cone near the wall (draw cancelled). Slowed / held frames where needed | "Scripted-input capture · keys sent by a script"; held frames labelled | state machine in real play, an interrupt in each phase |
| B15 | PLAY | CAPTURE take `play`, cropped on scarecrows: walk at normal speed for 5+ wraps, then hold at the wall | "Scarecrows placed by the script · no keys pressed" | the cycle wraps without a visible seam |
| B16 | PROOF | STILL: verbatim result lines — both read-backs, state machine, edges, pins (before / after), the four mutations exiting 1 (and m4 passing, with why), and "what no headless run can show" | "Recorded output" | what read-backs proved, mutations, headless limit |
| B17 | MISTAKES | GodotDesignBoard: agent mistakes caught (count 72 vs 68, frame-37 typo, PowerShell / `cd …;` attempts, helper that fired nothing — Claude's), Claude readings overruled (−8° amount; "recovery looks like idle" vs play; the walk-away checklist line), still uncertain (startup cancel never seen by a human; fixture vs play on the phases) | FRICTIONAL.md, TUNING.md, TEST-REPORT.md | mistakes, overruled readings, uncertainty |
| B18 | VERDICT | ClaudeVerdictArtifact: implemented / limitations / human judgement; next step; human and AI contributions; sheet source and licence (written by `make_sprites.gd`, no third-party licence); revision shown | — | verdict, next step, contributions, source, revision |
| B19 | HANDOFF | ClaudeComposerAsk: Your Turn — one bounded change with a prediction and a test | illustrative | Your Turn |
| B20 | OUTRO | ClaudeTitleOutro, stock @NikBearBrown jingle by sha256(slug) mod 6 + 1, −8 dB | slug-seeded | regular outro |

## Takes to record (Movie Maker, isolated 4K copy, driver never sets game state or teleports)

| Take | What happens | Used in |
|---|---|---|
| `play` | spawning off; scarecrows placed by the script with `spawn_scarecrow()` (as the state tests do); no keys; the archer shoots on its own; at least one scarecrow reaches the wall and holds | B02, B15 |
| `interrupts` | real key events through `Input.parse_input_event`, timed by the archer's observed state (not fixed frames): P on a startup tick, P on the release tick, P on a recovery tick, a move key held through a draw, one scarecrow near the wall walked out of the cone. Restart (R after a loss) is left to the edge test: a loss takes too long to stage in a take | B14 |

The repository's own fixture strips (`captures/shoot/r0`, `r1`, `captures/walk/r0`) are reused as stills, labelled.
