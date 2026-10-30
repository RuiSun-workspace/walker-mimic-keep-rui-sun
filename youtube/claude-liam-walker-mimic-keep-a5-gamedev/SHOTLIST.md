# SHOTLIST — Mimic Keep A5 explainer

Slug `claude-liam-walker-mimic-keep-a5-gamedev`, godot-gamedev in walker mode, 4K landscape, Liam (in for Bear),
Kokoro `am_onyx`. Source revision `879324b`. Narration text is in `beat_sheet.json`; code is verbatim from the
repository; every frame that is not a live editor recording says what it is.

| Beat | Visual | Kind | Label on screen |
|---|---|---|---|
| B00 | Claude composer, reconstructed walker ask | Remotion `ClaudeComposerAsk` | reconstructed prompt (role note) |
| B01 | "Mimic Keep: the test can see the fire." → "cannot" | `BrutalistHesitantWriter` | — |
| B02 | the real game, nobody at the keys, scarecrows burning | capture, take `idle`, full frame | "Unattended run · no keys pressed" |
| B03 | the brief's colour line and what it fixed | `GodotDesignBoard` | CHANGE-BRIEF.md source line |
| B04 | `shaders/burning_tint.gdshader:1-8` | `GodotDevWorkbench` code | "Godot editor reconstruction" |
| B05 | the five frozen scarecrows + verbatim pixel lines | still | "Scripted capture · world frozen · in-engine frame" |
| B06 | `game/burning_tint.gd:7-13` | code | "Godot editor reconstruction" |
| B07 | hit, fade, second hit, pause, burn-down | capture, take `fade`, cropped 1.6× | "Scripted capture · hits called by a script, archer off" |
| B08 | Rui's screenshot + Rui's words (Chinese, translated) | still | "Screenshot by Rui" |
| B09 | `tests/test_burning_tint.gd:90-98` | code | "Godot editor reconstruction" |
| B10 | verbatim test output, mutations 1-2 | still | "Headless output, verbatim" |
| B11 | proved / not proved | `GodotDesignBoard` | CLAUDE.md Headless facts |
| B12 | `shaders/hint_experiment.gdshader:4-17` | code | "Godot editor reconstruction" |
| B13 | hint frame + predicted vs measured | still | "In-engine frame" |
| B14 | `shaders/shield_wood.gdshader:6-16` | code | "Godot editor reconstruction" |
| B15 | lit shields + curl output + Rui's groove note | still | "In-engine frame" + headless output |
| B16 | `shaders/shield_wood.gdshader:21-33` | code | "Godot editor reconstruction" |
| B17 | 7 uniforms × min/default/max | still | "In-engine frames · interface sweep" |
| B18 | `showcase/shield_burned.tres:9-22` | code | "Godot editor reconstruction" |
| B19 | before / shader edit / material edit + pixel counts | still | "In-engine frames · edits made by Rui" |
| B20 | `shaders/standard_generated.gdshader:7-19`, Rui's equivalents in the notes | code | "Godot editor reconstruction" |
| B21 | mutation 3 diff + FAIL lines | still | "Headless output, verbatim" |
| B22 | five agent mistakes | `GodotDesignBoard` | FRICTIONAL.md |
| B23 | verdict | `ClaudeVerdictArtifact` | — |
| B24 | Your Turn prompt; Liam signs off | `ClaudeComposerAsk` | — |
| B25 | locked outro, title, @NikBearBrown, jingle 6 | `ClaudeTitleOutro` | — |

Code → result pairs (teaching contract `code-then-result-v1`): B04→B05, B06→B07, B09→B10, B12→B13, B14→B15,
B16→B17, B18→B19, B20→B21.
