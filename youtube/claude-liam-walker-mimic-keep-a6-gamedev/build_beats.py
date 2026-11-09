"""Write the beat sheet for the Mimic Keep A6 godot-gamedev (walker) explainer film.

Written by Claude, 2026-11-08, on the A5 film's pattern (Liam / Kokoro am_onyx, walker bookends, labelled
stills and captures, slug-seeded stock jingle). Code excerpts are read verbatim from the repository at the
film's source revision; stills are made by make_assets.py from committed files; capture windows and
durations are filled in by cut_clips.py.

    F:/7270/film-env/Scripts/python.exe build_beats.py  ->  REEL/beat_sheet.json
"""
import json
from pathlib import Path

REEL = Path(__file__).resolve().parent
REPO = Path("C:/Users/18500/Desktop/7270/Assignment5/walker-mimic-keep-rui-sun")
SLUG = "claude-liam-walker-mimic-keep-a6-gamedev"
TITLE = "Mimic Keep: The Strip Cannot See the Hit."
REV = (REEL / "capture" / "source-commit.txt").read_text().strip()
BUILD = (REEL / "capture" / "build_id.txt").read_text().strip()
SHORT = REV[:7]
JINGLE = json.loads((REEL / "jingle.json").read_text())
GREETING = "Sawubona"


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


def board(bid, act, text, title, section, excerpt_text, source, status, vlabel, cards, role, excerpt_label="DOCUMENT EXCERPT"):
    return narrated(bid, act, text, {"type": "GRAPHIC", "source": "remotion", "motion": "reveal", "remotion": {
        "pattern": "GodotDesignBoard", "props": {
            "title": title, "section": section, "excerptLabel": excerpt_label, "excerpt": excerpt_text, "source": source, "status": status,
            "visualLabel": vlabel, "layout": "cards", "cards": [{"label": l, "text": t} for l, t in cards],
            "cues": [{"at": 0, "card": i} for i in range(len(cards))]}}}, role)


beats = []
beats.append(narrated("B00", "ASK",
    f"{GREETING}, this is Liam, in for Bear. The ask, reconstructed: in Mimic Keep, an archer on a castle wall shoots "
    "fire arrows at straw scarecrows. Add two particle effects: one says an arrow hit, one says a scarecrow is still "
    "burning, and how long it has left.",
    {"type": "GRAPHIC", "source": "remotion", "motion": "type-on", "remotion": {"pattern": "ClaudeComposerAsk", "props": {
        "greeting": f"{GREETING}, Liam", "topic": "WALKER · MIMIC KEEP PARTICLES", "segment": "walker-mimic-keep-rui-sun",
        "command": "Please use Walker to add two GPU particle effects to Mimic Keep, my castle-defense game where an "
                   "archer on the wall shoots fire arrows at straw scarecrows: a one-shot impact burst on every arrow hit, "
                   "and burning embers whose density follows each scarecrow's remaining burn time. I write the brief, the "
                   "predictions and every verdict; agents build, wire and test; I judge the look in the running game.",
        "runningText": "reading CHANGE-BRIEF.md, CLAUDE.md; capture_rect() is empty headless…",
        "output": ["Effect A: impact_burst.tscn · hit_taken · overlap",
                   "Effect B: burning_embers.tscn · amount_ratio from burn_time_left",
                   "proof: headless node state, fixture strips, then Rui's eyes"],
        "folderLabel": "@NikBearBrown", "modelLabel": "Claude", "effortLabel": "Opus"}}},
    "COLD OPEN LAW - Claude UI cold open. The prompt is an ILLUSTRATIVE RECONSTRUCTION of the walker ask, never a transcript."))
beats.append(narrated("B01", "BLUF",
    "Two effects, specified by Rui, built and wired by agent sessions, and tuned twice by Rui's eyes. The tests can read "
    "every node, and see no particle. The fixture strips see particles, but no hit. So the overlap Rui found was only "
    "visible in the running game.",
    {"type": "GRAPHIC", "source": "remotion", "motion": "type-on", "remotion": {"pattern": "BrutalistHesitantWriter", "props": {
        "text": "Mimic Keep:\nthe strip can\nsee the hit.", "triggerWords": "can", "replacementWords": "cannot",
        "seed": "mimic-keep-a6-b01", "face": "serif", "fontSize": 190, "lineSpacing": 1.7, "align": "center",
        "charMs": 26, "jitter": 18, "mistakeRate": 0, "hesitateWithin": 0, "hesitateBetween": 0}}},
    "What was built, with one real correction: the fixture strips cannot show the hit-on-burning overlap."))
beats.append(capture("B02", "GAME",
    "This is the game, running with nobody at the keys. The archer fires on its own. Every hit throws a flash and straw. "
    "Every fire hit sets a scarecrow burning for four seconds, and embers rise from it, thinning as the burn runs out.",
    "Unattended run · no keys pressed", "The game and both effects in play."))
beats.append(board("B03", "BRIEF",
    "Rui wrote the brief first. Effect A answers an event: an accepted hit, through a new signal, hit taken, the one "
    "gameplay change the brief allows. Effect B answers a condition: burn time left, read every frame, because a second "
    "fire hit refreshes the burn without any signal.",
    "Two jobs, one event, one condition", "CHANGE-BRIEF.md §1 · The jobs",
    "amount_ratio = clamp(burn_time_left / 4.0, 0.0, 1.0)",
    f"CHANGE-BRIEF.md §1, §3, §5 · Rui's specification · @ {SHORT}",
    "WRITTEN BY RUI BEFORE ANY BUILD · 2026-11-05", "What the brief fixed",
    [("Effect A · event", "every accepted Scarecrow.hit() emits hit_taken(position) → one new burst"),
     ("Retrigger rule", "overlap: a new instance per hit, up to 3 alive, never reused"),
     ("Effect B · condition", "burn_time_left 4 → 0 s drives amount_ratio 1 → 0 on each scarecrow"),
     ("Node type", "GPUParticles2D for both: CPUParticles2D has no amount_ratio, no turbulence")],
    "The brief's two jobs, event and condition, before any code."))
beats.append(board("B04", "INTENT",
    "Effect A's intent block. A sharp yellow white flash at the hit point, about eight frames, smaller than the "
    "scarecrow's head. Straw fragments fly out, fall, darken and fade within point eight seconds, so they can overlap "
    "the next hit, but never a third.",
    "Effect A · Arrow Impact Burst", "CHANGE-BRIEF.md §2 · Intent",
    "The flash communicates the exact moment of impact; the fragments provide a short visible aftermath.",
    f"CHANGE-BRIEF.md §2 · Rui · @ {SHORT}", "INTENT BEFORE BUILDING", "Intent",
    [("Timing", "flash 0.28 s (≈ 8 frames at 30 fps) · straw 0.80 s"),
     ("Contrast", "bright flash on grass and gate · dark straw on wall and walkway"),
     ("Scale", "flash smaller than the head · straw about the scarecrow's width"),
     ("Change over life", "flash: small → wider → orange → gone · straw: out, fall, darken, fade")],
    "Effect A's intent block: timing, contrast, scale, change over life."))
beats.append(code_beat("B05", "Three parts of a particle system.", "effects/impact_burst.tscn", 77, 88,
    [(77, "the emitter: a GPUParticles2D node"), (78, "draw: additive CanvasItemMaterial"),
     (80, "emitter: how many, how long, one shot"), (81, "draw: the texture each particle shows"),
     (88, "process: the ParticleProcessMaterial")],
    [{"label": "Emitter", "value": "the node: amount 10, lifetime 0.28 s,\none_shot, explosiveness 1"},
     {"label": "Process", "value": "ParticleProcessMaterial: velocity 80–140,\ngravity (0, 100, 0), ramps — a GPU shader"},
     {"label": "Draw", "value": "soft_dot.png + blend_mode 1 (add):\nwhat each particle looks like"}],
    "Every particle system has three parts. The emitter decides how many particles and for how long. The process "
    "material moves each one: velocity, gravity, colour over life. The draw step decides what each particle looks like: "
    "here a soft dot, added as light.",
    "The three parts of a particle system, each tied to a line of the effect's scene file."))
beats.append(still("B06", "STRIP",
    "The first strip, from a preview fixture with a fixed seed. Rui looked first, and wrote that during the flash the "
    "straw could not be seen. The strip agreed, and showed why: the straw's first colour equals the scarecrow's body.",
    "Fixture capture · preview scene, fixed seed", "Effect A's first strip and Rui's first verdict.", evidence=True))
beats.append(still("B07", "TUNING",
    "Revision one. In the running game Rui saw the flash start a little bright, and asked for it darker. The agent "
    "predicted a softer flash. The after strip dimmed it on the grass, but barely on the burning body, where added light "
    "was already clipped at full yellow. Rui kept it: in play, the straw read better.",
    "Fixture captures · r0 tinted → r1", "Effect A revision r1: observation, prediction, before and after, verdict."))
beats.append(capture("B08", "PLAY",
    "In play: hits from near and far land close together, so bursts overlap. The state test fired real arrows, measured "
    "three bursts alive at the third impact, and every one freed itself after its lifetime.",
    "Unattended run · no keys pressed", "Effect A in play, including rapid repeats."))
beats.append(board("B09", "INTENT",
    "Effect B's intent. Embers rise from the body, pale yellow to orange red, over faint smoke. It uses two things "
    "Effect A doesn't: amount ratio, so density follows the burn, and turbulence on the smoke. When the scarecrow dies, "
    "the embers move to the effects layer and fade.",
    "Effect B · Burning Embers", "CHANGE-BRIEF.md §2–§3 · Intent and feature",
    "Smoke also uses mild turbulence so that it does not rise in identical straight lines.",
    f"CHANGE-BRIEF.md §2, §3, §4 · Rui · @ {SHORT}", "INTENT BEFORE BUILDING", "Intent and feature",
    [("Timing", "0.5 s to the head · stream full after 0.9 s · tail ≤ 1.2 s"),
     ("Feature A lacks", "amount_ratio (feedback) · smoke turbulence 0.15–0.30"),
     ("Start / stop", "burning_started → on, ratio 1 · burning_ended → off, ratio 0"),
     ("Pause / death", "paused: frozen · died: stop, move to World/Effects, free after 1.2 s")],
    "Effect B's intent, the feature Effect A doesn't use, start/stop/pause behaviour."))
beats.append(code_beat("B10", "Game state in, density out.", "effects/burning_embers_driver.gd", 27, 40,
    [(35, "every frame: ratio from burn time left"), (38, "burning_started: on, at full density"),
     (40, "only the start and end signals touch emitting")],
    [{"label": "Feedback loop", "value": "4 s → 1.00 · 3 s → 0.75\n2 s → 0.50 · 1 s → 0.25"},
     {"label": "Never", "value": "changes amount, or writes game state"},
     {"label": "Measured", "value": "test 54/0 at 60 fps · re-ignite: ratio 1.0\nthe next frame"}],
    "The driver reads burn time left every frame and turns it into amount ratio, never amount. A refresh needs no "
    "signal: the next frame reads four seconds and the density jumps back to full.",
    "The feedback driver, verbatim."))
beats.append(still("B11", "STRIP",
    "Effect B's first strip. Rui watched first: the weakening was hard to notice. The strip's counts follow the brief, "
    "ten, six, four, three, but most embers sit on the yellow burning body, where added light clips.",
    "Fixture capture · preview scene, fixed seed", "Effect B's first strip and Rui's first verdict.", evidence=True))
beats.append(still("B12", "TUNING",
    "Revision one for B came from the game: Rui saw the hit flash and the embers merge. The agent traced it to a shared "
    "texture, blend and colour, and made new embers fade in over the flash's time. The strip changed less than predicted, "
    "for the same clipping reason. Rui kept it: now the two read a little apart.",
    "Fixture captures · r0 → r1", "Effect B revision r1: observation, prediction, before and after, verdict."))
beats.append(capture("B13", "PLAY",
    "Start, refresh, pause and death, scripted on the real game. A fire hit starts the embers. A second hit refreshes "
    "them to full. Escape freezes them. They thin as the burn runs down, and a scarecrow that dies while burning leaves "
    "its embers behind to fade.",
    "Scripted capture · hits called by a script, archer off", "Effect B start, refresh, pause, burn-out and death."))
beats.append(code_beat("B14", "The generated process shader, annotated.", "shaders/particles_generated.gdshader", 316, 329,
    [(316, "force starts as gravity ← brief A1: (0, 100, 0)"), (329, "velocity += force × DELTA, every step")],
    [{"label": "Brief A1 gravity", "value": "gravity = Vector3(0, 100, 0)\nflash dots sag as they fade"},
     {"label": "Line 140", "value": "mix(initial_linear_velocity_min, _max)\n= 80 … 140 px/s (brief A1)"},
     {"label": "Not in here", "value": "amount, lifetime, texture, blend:\nnode and draw step"}],
    "Rui converted the flash's process material into code. Line three sixteen starts the force as gravity, the brief's "
    "zero, one hundred. Line three twenty nine adds force times delta to the velocity. Texture and blend are not in here: "
    "they belong to drawing.",
    "Two annotated lines of the generated process shader beside the brief's settings."))
beats.append(still("B15", "PROOF",
    "What the tests proved: every setting read back, every trigger and condition driven by real arrows and keys. Four "
    "mutations failed them, including a silent Godot three name. A GPU effect's headless price is near zero by design: "
    "the dummy renderer runs no particle work. On the real GPU, both stayed far under budget.",
    "Recorded output · test logs and cost script", "Tests, mutations, both prices against budget, the headless limit.", evidence=True))
beats.append(board("B16", "MISTAKES",
    "Mistakes caught. The agent's preview had no fixed seed, and its capture path was wrong twice. Claude's first "
    "rectangle check used swapped screenshots, and was withdrawn. Rui overruled one strip reading: the strip said the straw was no clearer, the "
    "game said it was. Still uncertain: a hidden emitter paused, against Rui's prediction.",
    "Caught, overruled, uncertain", "FRICTIONAL.md · TUNING.md · 2026-11-05 to 11-08",
    "When Claude and Rui disagree about a strip, Rui's verdict in the running game decides.",
    f"FRICTIONAL.md, TUNING.md @ {SHORT}", "RECORDED, NOT HIDDEN", "Five points",
    [("Agent", "no fixed seed in the preview · capture path wrong in two sessions"),
     ("Claude", "visibility rects compared with swapped screenshots · withdrawn"),
     ("Auto mode", "an edit ran without the planned prompt · diff checked line by line"),
     ("Overruled", "A r1: strip saw no clearer straw; Rui, in play, did"),
     ("Uncertain", "B6: hidden GPU particles paused in 4.7.2, not as predicted")],
    "Agent mistakes caught, Claude's readings overruled, what remains uncertain."))
beats.append(narrated("B17", "VERDICT",
    "The verdict. Shown working: both effects on their event and condition, overlap, feedback, pause and death. "
    "Uncertain: the smoke barely reads, and a hidden emitter pauses. Next: make the smoke readable. Rui wrote the brief, "
    "every observation and verdict, and the process shader references. Claude and the agents built, wired and tested.",
    {"type": "GRAPHIC", "source": "remotion", "motion": "reveal", "remotion": {"pattern": "ClaudeVerdictArtifact", "props": {
        "artifactTitle": "Verdict",
        "artifactHeading": f"walker-mimic-keep-rui-sun @ {SHORT} · shown, checked, still open",
        "artifactLines": [
            "shown — burst per hit, 3 overlapping; embers follow burn time, refresh, freeze, fade after death.",
            "checked — config 128/0, 156/0; state 29/0, 54/0; 4 mutations exit 1; GPU far under budget.",
            "uncertain — smoke barely visible; hidden GPU emitter pauses (B6); profiler precision.",
            "next — make the smoke readable over the burning body (Rui's playtest).",
            "who — Rui: brief, observations, verdicts, captures, shader refs · Claude + agent sessions: the rest.",
            f"sources — particle textures generated by project code · source {SHORT} · Godot 4.7.2 Forward+."]}}},
    "Verdict: checked, uncertain, next step, contributions, texture sources, source revision."))
beats.append(narrated("B18", "HANDOFF",
    "Your turn. Here is the paste ready prompt. Give one event and one condition an effect each. Write the intent and "
    "the predicted strip before the build. Let an agent build and test it, then watch it in the game yourself, because "
    "the strip can't see what play does. Liam, in for Bear.",
    {"type": "GRAPHIC", "source": "remotion", "motion": "type-on", "remotion": {"pattern": "ClaudeComposerAsk", "props": {
        "greeting": "Your turn.", "topic": "WALKER · MIMIC KEEP PARTICLES", "segment": "your turn",
        "command": "Use Walker. Pick one event and one condition in my game. I will write each effect's intent, settings "
                   "and predicted frame strip before anything is built. Build each as a GPUParticles2D scene with a "
                   "configuration test, wire it with a state test driven by real input, and give me a fixed-seed preview to "
                   "capture. I judge every tuning change in the running game.",
        "runningText": "reading the brief; amount_ratio from game state; capturing the fixture…",
        "output": ["intent and predicted strip, before the build",
                   "tests that fail on a Godot 3 name",
                   "a verdict made in the running game"],
        "folderLabel": "@NikBearBrown", "modelLabel": "Claude", "effortLabel": "Opus"}}},
    "Your Turn - a paste-ready Walker prompt; Liam signs off here, before the final card."))
beats.append({"beat_id": "B19", "act": "OUTRO",
              "role_note": "OUTRO LOCK - ClaudeTitleOutro, exact title, @NikBearBrown, slug-seeded mascot/jingle.",
              "narration_text": "", "audio_file": JINGLE["audio_file"],
              "jingle": {k: JINGLE[k] for k in ("source", "pick", "gain_db")},
              "estimated_duration_s": JINGLE["duration_s"], "actual_duration_s": JINGLE["duration_s"],
              "shot": {"type": "GRAPHIC", "source": "remotion", "motion": "reveal",
                       "remotion": {"pattern": "ClaudeTitleOutro", "props": {"title": TITLE, "slug": SLUG,
                                                                             "durationSeconds": JINGLE["duration_s"]}}}})

sheet = {"metadata": {
    "title": TITLE, "slug": SLUG, "topic": "WALKER · MIMIC KEEP PARTICLES", "kind": "gamedev", "playlist": "Brutalist",
    "brand": "claude-liam", "audience": "CSYE 7270 reviewers and Walker readers", "register": "Teardown",
    "engine": "kokoro", "voice": "am_onyx", "voice_kokoro": "am_onyx", "palette": "claude", "style_preset": "claude",
    "ground": "#FAF9F5", "aspect_ratio": "16:9", "fit": "contain", "captions": False, "channel": "@NikBearBrown",
    "channel_title": "@NikBearBrown", "folderLabel": "@NikBearBrown", "greeting": f"{GREETING}, Liam",
    "greeting_note": "hello lexicon: Sawubona (isiZulu), not used by the A1-A5 reels (Kia ora, Zdravo, Kumusta, Mingalaba were).",
    "persona": "Liam (in for Bear)", "presenter": "Liam (in for Bear)", "in_for_bear": True,
    "episode_id": "walker-mimic-keep-a6-gamedev",
    "note": f"godot-gamedev in walker mode over walker-mimic-keep-rui-sun (CSYE 7270 Assignment 6). Source commit {REV}, "
            f"build_id {BUILD}, Godot 4.7.2.stable.official.ed1daf0bf, Forward+. B02, B08 and B13 are native 3840x2160 Godot "
            "Movie Maker output from an isolated copy of that commit, driven by capture/capture_a6_film.gd (B02, B08: no "
            "input; B13: scripted hits, archer off). Stills compose the repository's fixture strips and recorded words; all "
            "labelled in frame."},
    "beats": beats}
(REEL / "beat_sheet.json").write_text(json.dumps(sheet, indent=1, ensure_ascii=False), encoding="utf-8")
print(len(beats), "beats,", sum(len(b["narration_text"].split()) for b in beats), "words ->", REEL / "beat_sheet.json")
