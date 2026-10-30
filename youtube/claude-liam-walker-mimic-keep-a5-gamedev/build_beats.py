"""Write the beat sheet for the Mimic Keep A5 godot-gamedev (walker) explainer film.

Written by Claude, 2026-10-29, from the plan Rui approved ("全部批准", 2026-10-29): about 26 beats, Liam / Kokoro
am_onyx, the walker bookends, a new scripted 4K capture, labelled stills, the five named agent mistakes, the next
step Rui chose (fix the long-range miss), the slug-seeded stock jingle. Code excerpts are read verbatim from the
repository at the film's source revision; stills are made by make_assets.py from real files; capture windows and
durations are filled in by cut_clips.py.

    F:/7270/film-env/Scripts/python.exe build_beats.py  ->  REEL/beat_sheet.json
"""
import json
from pathlib import Path

REEL = Path(__file__).resolve().parent
REPO = Path("C:/Users/18500/Desktop/7270/Assignment5/walker-mimic-keep-rui-sun")
SLUG = "claude-liam-walker-mimic-keep-a5-gamedev"
TITLE = "Mimic Keep: The Test Cannot See the Fire."
REV = (REEL / "capture" / "source-commit.txt").read_text().strip()
BUILD = (REEL / "capture" / "build_id.txt").read_text().strip()
SHORT = REV[:7]
JINGLE = json.loads((REEL / "jingle.json").read_text())
GREETING = "Kia ora"


def excerpt(path, a, b):
    lines = (REPO / "godot" / path).read_text(encoding="utf-8").splitlines()
    return "\n".join(lines[a - 1:b])


def narrated(bid, act, text, shot, role):
    return {"beat_id": bid, "act": act, "role_note": role, "narration_text": text, "voice": "am_onyx",
            "engine": "kokoro", "estimated_duration_s": max(4, round(len(text.split()) / 2.5)), "shot": shot}


def code_beat(bid, title, path, a, b, cues, notes, text, role, font=None):
    code = excerpt(path, a, b)
    lines = code.split("\n")
    assert len(lines) <= 14, (bid, len(lines))
    return narrated(bid, "MECHANISM", text, {
        "type": "GRAPHIC", "source": "remotion", "motion": "code-cue",
        "remotion": {"pattern": "GodotDevWorkbench", "props": {
            "mode": "code", "title": title, "project": "walker-mimic-keep-rui-sun", "path": "godot/" + path,
            "source": f"Verbatim project source at commit {SHORT} · Godot editor reconstruction (teaching view)",
            "code": code, "startLine": a, "cues": [{"at": 0, "line": ln, "label": lab} for ln, lab in cues],
            "codeFontSize": font or (24 if (len(lines) > 12 or max(map(len, lines)) > 90) else 26),
            "inspectorLabel": "Source notes — not Inspector values", "notes": notes}}}, role)


def still(bid, act, text, label, role, evidence=False):
    shot = {"type": "STILL", "source": "own", "motion": "hold", "label": label}
    if evidence:
        shot["evidence_media"] = f"media/{bid}.png"
    return {**narrated(bid, act, text, shot, role), "image_file": f"assets/{bid.lower()}.png"}


def capture(bid, act, text, label, role, evidence=False):
    shot = {"type": "CAPTURE", "source": "screen", "label": label}
    if evidence:
        shot["evidence_media"] = f"media/{bid}.mp4"
    return narrated(bid, act, text, shot, role)


# excerptLabel needs the local one-prop GodotDesignBoard.tsx patch (BUILD-PROMPT.md); the stock label says "GDD".
def board(bid, act, text, title, section, excerpt_text, source, status, vlabel, cards, role, excerpt_label="DOCUMENT EXCERPT"):
    return narrated(bid, act, text, {"type": "GRAPHIC", "source": "remotion", "motion": "reveal", "remotion": {
        "pattern": "GodotDesignBoard", "props": {
            "title": title, "section": section, "excerptLabel": excerpt_label, "excerpt": excerpt_text, "source": source, "status": status,
            "visualLabel": vlabel, "layout": "cards", "cards": [{"label": l, "text": t} for l, t in cards],
            "cues": [{"at": 0, "card": i} for i in range(len(cards))]}}}, role)


beats = []
beats.append(narrated("B00", "ASK",
    f"{GREETING}, this is Liam, in for Bear. The ask, reconstructed: in Mimic Keep, an archer on a castle wall sets "
    "straw scarecrows burning. Write two shaders by hand: one shows the Burning state, driven by the game; one reads wood "
    "textures onto a shield, used by two materials.",
    {"type": "GRAPHIC", "source": "remotion", "motion": "type-on", "remotion": {"pattern": "ClaudeComposerAsk", "props": {
        "greeting": f"{GREETING}, Liam", "topic": "WALKER · MIMIC KEEP SHADERS", "segment": "walker-mimic-keep-rui-sun",
        "command": "Please use Walker to convert my game design document about Mimic Keep, a castle-defense roguelite where "
                   "an archer on the wall shoots fire arrows at straw scarecrows, into an Assignment 5 change: a hand-written "
                   "canvas_item shader that tints a scarecrow while it is Burning, driven from game state, and a hand-written "
                   "spatial shader that reads wood textures onto a shield, used by two materials. I write every shader line; "
                   "you write the driver, the tests and the evidence.",
        "runningText": "reading CHANGE-BRIEF.md, CLAUDE.md; get_shader_uniform_list()…",
        "output": ["shader 1: burning_tint.gdshader · burn_mix from burn_time_left",
                   "shader 2: shield_wood.gdshader · 4 samplers · 2 materials",
                   "proof: headless 30/60/144 fps, then the real renderer and Rui's eyes"],
        "folderLabel": "@NikBearBrown", "modelLabel": "Claude", "effortLabel": "Opus"}}},
    "COLD OPEN LAW - Claude UI cold open. The prompt is an ILLUSTRATIVE RECONSTRUCTION of the walker ask, never a transcript."))
beats.append(narrated("B01", "BLUF",
    "Two shaders, every line typed by Rui. Claude and three agent sessions wrote the driver, the tests and the "
    "materials. The tests pass at three frame rates, and still cannot see a pixel. So every look here comes from the real "
    "renderer, or from Rui's eyes.",
    {"type": "GRAPHIC", "source": "remotion", "motion": "type-on", "remotion": {"pattern": "BrutalistHesitantWriter", "props": {
        "text": "Mimic Keep:\nthe test can\nsee the fire.", "triggerWords": "can", "replacementWords": "cannot",
        "seed": "mimic-keep-a5-b01", "face": "serif", "fontSize": 190, "lineSpacing": 1.7, "align": "center",
        "charMs": 26, "jitter": 18, "mistakeRate": 0, "hesitateWithin": 0, "hesitateBetween": 0}}},
    "What was built, with one real correction: the tests pass, and they cannot see what the shaders draw."))
beats.append(capture("B02", "GAME",
    "This is the game, running with nobody at the keys. The archer fires on its own, and a fire arrow sets a scarecrow "
    "Burning: four damage a second, for four seconds. The first shader makes that state visible. The second goes on a "
    "wooden shield, in a 3D room of its own.",
    "Unattended run · no keys pressed", "The game, the state the first shader shows, and where the second one lives."))
beats.append(board("B03", "BRIEF",
    "Rui wrote the specification first. One colour line: mix the sprite toward straw yellow, two fifty five, one ninety "
    "two, thirty two, by burn mix. Burn mix is zero point six five at the hit, and reaches zero after four seconds of game "
    "time. Rui also predicted three pixels by hand.",
    "The colour line, written first", "CHANGE-BRIEF.md §2 · The colour line",
    "COLOR.rgb = mix(COLOR.rgb, burn_color.rgb, burn_mix);",
    f"CHANGE-BRIEF.md §2, §3 Rule 2, §6 · Rui's specification · @ {SHORT}",
    "WRITTEN BY RUI BEFORE THE SHADER · 2026-10-26", "What the brief fixed",
    [("burn_color", "(255, 192, 32): a straw yellow, the shader default"),
     ("burn_mix", "0.65 × clamp(burn_time_left / 4, 0, 1): 0.65 at the hit, 0.0 after 4 s of game time"),
     ("Hand calculation", "straw body (233, 196, 106) at 0.5 → (244, 194, 69); at 1.0 → (255, 192, 32)"),
     ("Predicted, not yet seen", "a source_color uniform in 2D, with HDR 2D off, arrives unconverted")],
    "The specification's colour line and Rui's hand calculation, before any code."))
beats.append(code_beat("B04", "Eight lines, typed by Rui.", "shaders/burning_tint.gdshader", 1, 8,
    [(1, "shader_type: a 2D shader; picks the built-ins"), (3, "a knob the game will turn"),
     (4, "the burn colour, marked as colour"), (7, "the whole effect, once per pixel")],
    [{"label": "What a shader is", "value": "a small program the GPU runs\nfor every pixel the sprite covers"},
     {"label": "COLOR on line 7", "value": "already holds the sprite's\ntexture × modulate"}],
    "Rui's shader, eight lines. A shader is a small program the GPU runs for every pixel the sprite covers. Line one, "
    "canvas item, makes it a 2D shader and decides which built-ins exist. Lines three and four are its uniforms. Line "
    "seven is the effect: mix the pixel's colour toward the burn colour.",
    "Code → result 1: the shader, then its measured pixels."))
beats.append(still("B05", "RESULT",
    "A script froze five scarecrows and set burn mix by hand, from zero to two. All fifteen named pixels match Rui's "
    "hand calculation, within one step. At one, every pixel is exactly the burn colour. At two, the pixels follow two: the "
    "hint range does not clamp a value set from code.",
    "Scripted capture · world frozen · in-engine frame",
    "Visible result of B04: the controlled-value capture and its sampled pixels.", evidence=True))
beats.append(code_beat("B06", "Game state in, one number out.", "game/burning_tint.gd", 7, 13,
    [(7, "the peak the brief chose"), (11, "the scarecrow that owns the burn"),
     (12, "burn time left → 0..0.65, every frame"), (13, "this sprite's own material only")],
    [{"label": "Own material", "value": "scarecrow.tscn:9\nresource_local_to_scene = true"},
     {"label": "Never writes back", "value": "reads burn_time_left;\nno TIME, no frame count"}],
    "The shader knows nothing about fire. This driver does. Every frame it reads the scarecrow's burn time left, turns "
    "it into zero to zero point six five, and sets it on this sprite's own material. Each scarecrow has its own copy, so "
    "one cannot tint another.",
    "Code → result 2: the driver, then the effect moving in the game."))
beats.append(capture("B07", "RESULT",
    "In the real game: the middle scarecrow is hit, and fades. Hit again, it jumps back to full. Escape pauses, and the "
    "tint holds. Resumed, it fades until the straw burns down, leaving nothing behind.",
    "Scripted capture", "Visible result of B06: hit, fade, second hit, pause, burn-down.", evidence=True))
beats.append(still("B08", "PLAYTEST",
    "Rui then played it normally, and checked what no test can: the tint vanished at the end, the fade was smooth, a "
    "second hit was obvious, pause froze it, and the details stayed readable. Rui also found two gameplay faults: long "
    "shots miss, and scarecrows at the wall could not be hit.",
    "Screenshot by Rui", "Rui's own playtest, in Rui's words, with the two gameplay faults it found."))
beats.append(code_beat("B09", "Every live scarecrow, every frame.", "tests/test_burning_tint.gd", 90, 98,
    [(90, "this scarecrow's own material"), (93, "the game's own timer"),
     (97, "Rule 2 of the brief, as code"), (98, "off by more than a millionth: a failure")],
    [{"label": "Runs at", "value": "30, 60 and 144 fps\nthrough scripts/run-test.sh"},
     {"label": "Real events", "value": "auto-fired arrows hit;\nthe P key pauses"}],
    "The test samples every live scarecrow every frame, at thirty, sixty and one forty four frames a second, with real "
    "arrows. Line ninety seven is the brief's rule as code; line ninety eight fails on any error above a millionth.",
    "Code → result 3: the test, then its recorded output and the mutations."))
beats.append(still("B10", "RESULT",
    "Forty nine checks, zero failures, at all three rates. Then Rui broke the shader on purpose. A missing semicolon: "
    "shader error, exit one. Burn mix renamed: exit one, but only the name checks noticed. Every behaviour check still "
    "passed.",
    "Headless output, verbatim", "Visible result of B09: actual recorded output, including both shader mutations.",
    evidence=True))
beats.append(board("B11", "LIMIT",
    "That is the limit. A headless run draws nothing. It proves the shaders parse and the driver sends the right "
    "number. It cannot show a colour, a fade, or a groove in the wood. That needs the captures, and Rui's eyes.",
    "What no headless run can show", "CLAUDE.md · Headless facts · TEST-REPORT.md §4",
    "A headless run uses DisplayServer \"headless\" with an empty video adapter: a dummy renderer that draws nothing.",
    f"CLAUDE.md Headless facts (probed on this machine) · TEST-REPORT.md @ {SHORT}",
    "PROBED · GODOT 4.7.2 HEADLESS", "Proved / not proved",
    [("Proved headless", "both shaders parse · uniforms declared · burn_mix right every frame at 30/60/144"),
     ("Proved headless", "materials wired · hints read from source · curl ratio of the normal map"),
     ("Not proved", "any colour on screen · the fade's look · grooves in the wood"),
     ("Who checks it", "in-engine captures, and Rui's eyes")],
    "Gives the tests their limit before the textured shader starts."))
beats.append(code_beat("B12", "Same pixels, two samplers.", "shaders/hint_experiment.gdshader", 4, 17,
    [(5, "read as colour: source_color"), (8, "read as plain data"), (14, "one quad uses the first"),
     (16, "the other quad, the second")],
    [{"label": "The texture", "value": "hint_greys_3x1.png\n64 · 128 · 192, lossless"},
     {"label": "Unshaded", "value": "line 2: no light,\nso the screen shows the value"}],
    "Now textures. Why is a texture information? One grey strip, sixty four, one twenty eight, one ninety two, bound to "
    "two samplers. Line five reads it as colour, with source colour. Line eight reads it as plain data.",
    "Code → result 4: the hint experiment's shader, then its measured screen."))
beats.append(still("B13", "RESULT",
    "Rui predicted the result. With source colour, the screen shows the file's own values. Without it, the numbers are "
    "treated as light, and come out brighter: one thirty seven, one eighty eight, two twenty five. All six measured "
    "exact.",
    "In-engine frame + measured values", "Visible result of B12: predicted vs measured bands.", evidence=True))
beats.append(code_beat("B14", "Colour, and three kinds of data.", "shaders/shield_wood.gdshader", 6, 16,
    [(7, "albedo: colour, so source_color"), (10, "roughness: data"), (13, "normal map: data, hint_normal"),
     (16, "scorch mask: data, no repeat")],
    [{"label": "Textures", "value": "Poly Haven Wood Planks 1K\nAmal Kumar · CC0 · _nor_gl"},
     {"label": "Scorch mask", "value": "written by\ntools/make_scorch_mask.gd"}],
    "The shield follows the rule. Albedo is colour, so it gets source colour. Roughness, normals and the scorch mask are "
    "data, so they don't. The normal map is marked hint normal, and imported in the OpenGL convention.",
    "Code → result 5: the samplers, then the lit shield and the normal-map check."))
beats.append(still("B15", "RESULT",
    "Is it the right convention? The course's curl check reads zero point six seven as OpenGL, against one point three "
    "three the other way, under Rui's threshold of zero point eight three six. On screen, Rui sees the seams as grooves, "
    "but subtly.",
    "In-engine frame + headless output", "Visible result of B14: the shield under the room's light, and the curl check.",
    evidence=True))
beats.append(code_beat("B16", "Knobs, in named groups.", "shaders/shield_wood.gdshader", 21, 33,
    [(21, "group_uniforms: an Inspector section"), (24, "a colour knob, default white"),
     (27, "min, max, step, default"), (33, "0 to 2: once wrong, caught by review")],
    [{"label": "Damage group", "value": "line 38: scorch_amount,\nscorch_color, char_roughness"},
     {"label": "Read from source", "value": "the uniform list has\nno defaults: tests read the text"}],
    "Group uniforms puts the knobs into named Inspector sections, and every float gets a range, a step and a default. "
    "Normal strength runs from zero to two. That line was once wrong, and a review caught it.",
    "Code → result 6: the interface, then the sweep."))
beats.append(still("B17", "RESULT",
    "Each knob at its minimum, default and maximum, under fixed light. Rui noted what breaks: a black tint, obvious "
    "tiling at scale four, seams too deep at normal strength two, white scorch marks, and polished-looking burns at char "
    "roughness zero.",
    "In-engine frames · interface sweep", "Visible result of B16: the sweep, with Rui's notes.", evidence=True))
beats.append(code_beat("B18", "A material is not a shader.", "showcase/shield_burned.tres", 10, 22,
    [(12, "names Rui's one shader"), (17, "its own tint"), (20, "its own normal strength"),
     (21, "its own scorch: 70 %")],
    [{"label": "shield_new.tres", "value": "same shader · white tint\nroughness 0.75 · scorch 0.05"},
     {"label": "Shader", "value": "the program\n(shield_wood.gdshader)"}],
    "So what is a material? This file. It names Rui's one shader on line twelve, and stores its own values: a darker "
    "tint, stronger normals, seventy percent scorch. The shader is the program. A material is one set of inputs to it.",
    "Code → result 7: a material file, then the one-shader-two-materials edits."))
beats.append(still("B19", "RESULT",
    "Rui tested exactly that. Edit one shader line, and both shields change. Edit one value in the new shield's "
    "material, and only that shield changes: zero pixels move on the other side. Both edits undone, each frame came back "
    "byte for byte.",
    "In-engine frames · edits made by Rui", "Visible result of B18: the shader edit and the material edit.", evidence=True))
beats.append(code_beat("B20", "The generated shader, annotated.", "shaders/standard_generated.gdshader", 7, 19,
    [(7, "albedo read as colour: source_color"), (14, "roughness: from the red channel"),
     (19, "normal map read as data")],
    [{"label": "Rui's equivalent", "value": "shield_wood.gdshader:7\nsource_color"},
     {"label": "Rui's equivalent", "value": "shield_wood.gdshader:13\nhint_normal"}],
    "Finally, the language. Rui converted a standard material to code. Its line seven reads albedo as colour; line "
    "nineteen reads the normal map as data. Rui's equivalents are the shield's lines seven and thirteen. Godot's shading "
    "language looks like GLSL, but adds a shader type that picks the pipeline, hints that talk to import and the "
    "Inspector, and group uniforms.",
    "Code → result 8: the generated shader beside Rui's, then the mutation that removes the hint.", font=19))
beats.append(still("B21", "RESULT",
    "Why the hint matters: Rui deleted source colour from the shield's albedo sampler, and the material test failed, a "
    "hundred and thirty to two. Only the source-text checks caught it. The engine's uniform list cannot see a sampler's "
    "hint.",
    "Headless output, verbatim", "Visible result of B20: mutation 3 and the test that caught it.", evidence=True))
beats.append(board("B22", "MISTAKES",
    "The mistakes were mostly Claude's. It checked a shader fix by searching two lines, and missed a third; the audit "
    "agent caught it. A one tick tolerance it wrote hid a timer bug. Its own curl measure was wrong. It never checked the "
    "shaders against the language questions. And it committed a screenshot of the whole desktop, then amended it away "
    "before any push.",
    "Agent mistakes, caught", "FRICTIONAL.md · 2026-10-28 and 2026-10-29",
    "Claude checks a shader edit by diffing the whole file, crops screen captures to the window, and checks a design "
    "against every later question that will cite it.",
    f"FRICTIONAL.md @ {SHORT}", "RECORDED IN FRICTIONAL.md", "Five mistakes",
    [("Grep, not diff", "normal_strength 0–1 missed; audit finding 1"),
     ("Tolerance", "±1 tick in test_rules hid a 241-tick burn"),
     ("Own curl measure", "1.22 vs 1.79; the course's code: 0.67 vs 1.33"),
     ("Two built-ins", "LANGUAGE-NOTES Q3 could cite only COLOR and UV"),
     ("Whole desktop", "committed unseen, amended before any push")],
    "The agent mistakes that were caught, as recorded in FRICTIONAL.md."))
beats.append(narrated("B23", "VERDICT",
    "The verdict. Shown working: both shaders, a driver on game time, controlled pixels within one step, an exact hint "
    "experiment, and two materials from one shader. Uncertain: some pixels differ from an OS screenshot, cause unknown, "
    "and the grooves read only subtly. Next: fix the long-range miss, with aiming lead or homing arrows. Rui wrote every "
    "shader line and made every human check. Claude and the agents wrote the rest.",
    {"type": "GRAPHIC", "source": "remotion", "motion": "reveal", "remotion": {"pattern": "ClaudeVerdictArtifact", "props": {
        "artifactTitle": "Verdict",
        "artifactHeading": f"walker-mimic-keep-rui-sun @ {SHORT} · shown, checked, still open",
        "artifactLines": [
            "shown — tint from burn_time_left; 15/15 pixels; hint test 6/6 exact; one shader, two materials.",
            "checked — tint 49/0 at 30/60/144 fps; materials 132/0, also fresh; normal map 9/0; 3 mutations exit 1.",
            "uncertain — 618 pixels differ from an OS screenshot, cause unknown; the grooves read subtly.",
            "next — fix the long-range miss: aiming lead or homing arrows (wall fix: branch gameplay-fixes).",
            "who — Rui: every shader line, brief, notes, mutations, human checks · Claude + 3 agents: the rest.",
            f"sources — Wood Planks 1K, Amal Kumar, CC0 (Poly Haven) · source {SHORT} · Godot 4.7.2 Forward+."]}}},
    "Verdict: checked, uncertain, next step, contributions, texture sources, source revision."))
beats.append(narrated("B24", "HANDOFF",
    "Your turn. Here is the paste ready prompt. Pick a state your player cannot see. Write its colour line, and the "
    "pixels you expect, before the shader. Let an agent drive it from game time, break it on purpose, and then look "
    "yourself, because the test can't. Liam, in for Bear.",
    {"type": "GRAPHIC", "source": "remotion", "motion": "type-on", "remotion": {"pattern": "ClaudeComposerAsk", "props": {
        "greeting": "Your turn.", "topic": "WALKER · MIMIC KEEP SHADERS", "segment": "your turn",
        "command": "Use Walker. Pick one game state my player cannot see yet. I will write its colour line and the pixel "
                   "values I expect before I write the shader myself. Then write a driver that sets the uniform from game "
                   "time, a headless test at 30, 60 and 144 fps, and an in-engine capture of my controlled values. Break the "
                   "shader on purpose once and show me the test fail. Never edit my shader.",
        "runningText": "reading the brief; get_shader_uniform_list(); sampling every frame…",
        "output": ["a colour line and predicted pixels, before the shader",
                   "a test that fails when the shader is broken",
                   "a capture you look at yourself"],
        "folderLabel": "@NikBearBrown", "modelLabel": "Claude", "effortLabel": "Opus"}}},
    "Your Turn - a paste-ready Walker prompt; Liam signs off here, before the final card."))
beats.append({"beat_id": "B25", "act": "OUTRO",
              "role_note": "OUTRO LOCK - ClaudeTitleOutro, exact title, @NikBearBrown, slug-seeded mascot/jingle.",
              "narration_text": "", "audio_file": JINGLE["audio_file"],
              "jingle": {k: JINGLE[k] for k in ("source", "pick", "gain_db")},
              "estimated_duration_s": JINGLE["duration_s"], "actual_duration_s": JINGLE["duration_s"],
              "shot": {"type": "GRAPHIC", "source": "remotion", "motion": "reveal",
                       "remotion": {"pattern": "ClaudeTitleOutro", "props": {"title": TITLE, "slug": SLUG,
                                                                             "durationSeconds": JINGLE["duration_s"]}}}})

sheet = {"metadata": {
    "title": TITLE, "slug": SLUG, "topic": "WALKER · MIMIC KEEP SHADERS", "kind": "gamedev", "playlist": "Brutalist",
    "brand": "claude-liam", "audience": "CSYE 7270 reviewers and Walker readers", "register": "Teardown",
    "engine": "kokoro", "voice": "am_onyx", "voice_kokoro": "am_onyx", "palette": "claude", "style_preset": "claude",
    "ground": "#FAF9F5", "aspect_ratio": "16:9", "fit": "contain", "captions": False, "channel": "@NikBearBrown",
    "channel_title": "@NikBearBrown", "folderLabel": "@NikBearBrown", "greeting": f"{GREETING}, Liam",
    "greeting_note": "hello lexicon: Kia ora (Māori), not used by any reel in this toolkit's youtube/, examples/ or the "
                     "A1-A3 reels (Zdravo, Kumusta and Mingalaba were).",
    "persona": "Liam (in for Bear)", "presenter": "Liam (in for Bear)", "in_for_bear": True,
    "episode_id": "walker-mimic-keep-a5-gamedev",
    "note": f"godot-gamedev in walker mode over walker-mimic-keep-rui-sun (CSYE 7270 Assignment 5). Source commit {REV}, "
            f"build_id {BUILD}, Godot 4.7.2.stable.official.ed1daf0bf, Forward+. B02 and B07 are native 3840x2160 Godot "
            "Movie Maker output from an isolated copy of that commit, driven by capture/capture_a5_film.gd (B02: scripted "
            "key presses; B07: scripted hits, archer off). Stills are in-engine captures and recorded tool output committed "
            "in the repository, and Rui's own screenshot; all labelled in frame."},
    "beats": beats}
(REEL / "beat_sheet.json").write_text(json.dumps(sheet, indent=1, ensure_ascii=False), encoding="utf-8")
print(len(beats), "beats,", sum(len(b["narration_text"].split()) for b in beats), "words ->", REEL / "beat_sheet.json")
