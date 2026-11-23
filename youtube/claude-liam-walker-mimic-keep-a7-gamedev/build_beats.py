"""Write the beat sheet for the Mimic Keep A7 godot-gamedev (walker) explainer film.

Written by Claude, 2026-11-22, on the A6 film's pattern (Liam / Kokoro am_onyx, walker bookends, labelled
stills and captures, slug-seeded stock jingle). Shot list approved by Rui: SHOTLIST.md. Code excerpts are read
verbatim from the repository at the film's source revision; stills are made by make_assets.py from committed
files; capture windows and durations are filled in by cut_clips.py.

    F:/7270/film-env/Scripts/python.exe build_beats.py  ->  REEL/beat_sheet.json
"""
import json
from pathlib import Path

REEL = Path(__file__).resolve().parent
REPO = Path("C:/Users/18500/Desktop/7270/Assignment5/walker-mimic-keep-rui-sun")
SLUG = "claude-liam-walker-mimic-keep-a7-gamedev"
TITLE = "Mimic Keep: A Clip Is a List of Keys."
REV = (REEL / "capture" / "source-commit.txt").read_text().strip()
BUILD = (REEL / "capture" / "build_id.txt").read_text().strip()
SHORT = REV[:7]
JINGLE = json.loads((REEL / "jingle.json").read_text())
GREETING = "Merhaba"


def excerpt(path, a, b):
    lines = (REPO / "godot" / path).read_text(encoding="utf-8").splitlines()
    return "\n".join(lines[a - 1:b])


def doc_line(path, needle):
    """A verbatim line from a repository document (asserted present)."""
    for line in (REPO / path).read_text(encoding="utf-8").splitlines():
        if needle in line:
            return line.strip().lstrip("-").strip()
    raise AssertionError((path, needle))


def doc_sub(path, text):
    """A verbatim sentence from a repository document (asserted present; a line may hold more)."""
    assert text in (REPO / path).read_text(encoding="utf-8"), (path, text)
    return text


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
    "fire arrows at straw scarecrows. Give the scarecrows a walk cycle from a sprite sheet, and give the archer a shot "
    "that draws, releases and recovers.",
    {"type": "GRAPHIC", "source": "remotion", "motion": "type-on", "remotion": {"pattern": "ClaudeComposerAsk", "props": {
        "greeting": f"{GREETING}, Liam", "topic": "WALKER · MIMIC KEEP ANIMATION", "segment": "walker-mimic-keep-rui-sun",
        "command": "Please use Walker to convert my game design document about Mimic Keep, a castle-defense game where an "
                   "archer on the wall shoots fire arrows at straw scarecrows, into two animations: a looping scarecrow walk "
                   "from a sprite sheet, and an archer shot on a keyed cutout rig, driven by a state machine. I write the "
                   "brief, the phase table, every prediction and verdict; agents build and test; I judge the motion in play.",
        "runningText": "reading CHANGE-BRIEF.md; release_window keyed on clip frame 8…",
        "output": ["walk: Sprite2D + AnimationPlayer frame track · the cycle",
                   "shoot: keyed cutout rig + AnimationTree · the committing action",
                   "proof: read-backs, fixture strips, then Rui's eyes"],
        "folderLabel": "@NikBearBrown", "modelLabel": "Claude", "effortLabel": "Opus"}}},
    "COLD OPEN LAW - Claude UI cold open. The prompt is an ILLUSTRATIVE RECONSTRUCTION of the walker ask, never a transcript."))
beats.append(narrated("B01", "BLUF",
    "Two clips. Rui wrote the brief and the phase table; agent sessions built the keys, the state machine and the tests. "
    "The tests proved the structure. Only Rui's eyes could say the draw was too small, so eight degrees became sixteen.",
    {"type": "GRAPHIC", "source": "remotion", "motion": "type-on", "remotion": {"pattern": "BrutalistHesitantWriter", "props": {
        "text": "Mimic Keep:\nthe bow drew\neight degrees.", "triggerWords": "eight", "replacementWords": "sixteen",
        "seed": "mimic-keep-a7-b01", "face": "serif", "fontSize": 190, "lineSpacing": 1.7, "align": "center",
        "charMs": 26, "jitter": 18, "mistakeRate": 0, "hesitateWithin": 0, "hesitateBetween": 0}}},
    "What was built, with one real correction: the full-draw key went from -8 to -16 degrees after Rui's look."))
beats.append(capture("B02", "GAME",
    "This is the game, with nobody at the keys. The scarecrows walk down on a four cell cycle, and the one outside the "
    "archer's reach stops at the wall. The archer draws, releases and recovers on its own, one shot every point six seconds.",
    "Scarecrows placed by the script · no keys pressed", "The game and both clips in play."))
beats.append(board("B03", "BRIEF",
    "The brief names both clips. The scarecrow walk is the cycle: a Sprite2D sliced four by one, keyed by an "
    "AnimationPlayer frame track. The archer's shot is the committing action: a three part cutout rig, keyed in the "
    "scene file and played by an AnimationTree state machine. Each has exactly one authority.",
    "Two clips, two routes, one authority each", "CHANGE-BRIEF.md §1 · The two clips",
    doc_sub("CHANGE-BRIEF.md", "**Authority:** the scarecrow's own `AnimationPlayer` is the only writer of `Sprite.frame`."),
    f"CHANGE-BRIEF.md §1, §6, §8 · Rui's specification · @ {SHORT}",
    "WRITTEN BY RUI BEFORE ANY BUILD · 2026-11-19", "What the brief fixed",
    [("Walk · the cycle", "Sprite2D + AnimationPlayer frame track · 4 cells at 8 fps · LOOP_LINEAR"),
     ("Its authority", "Scarecrow/AnimationPlayer writes Sprite.frame · WalkPresenter only picks walk or hold"),
     ("Shot · the committing action", "cutout rig: Body, BowPivot/Bow, BowPivot/String · keyed in archer.tscn · LOOP_NONE"),
     ("Its authority", "Archer/AnimationTree plays idle and shoot · archer.gd travels, cancels and reads")],
    "Both clips, their routes, which loops and which commits, and the one authority over each."))
beats.append(code_beat("B04", "What a clip is: a list of keys.", "game/scarecrow.tscn", 18, 31,
    [(19, "loop_mode = 1: Animation.LOOP_LINEAR"), (20, "step = 1/8 s: one frame period at 8 fps"),
     (24, "the track names a node and a property"), (28, "four key times, 1/8 s apart"),
     (30, "update 1: UPDATE_DISCRETE, the frame holds"), (31, "the values: integers 0 to 3")],
    [{"label": "Slicing", "value": "hframes = 4 (line 63)"}, {"label": "Seam", "value": "no frame 0 at 0.5 s"}, {"label": "Read-back", "value": "68 checks pass"}],
    "What is a clip? This one. An Animation resource holding tracks. A track names a node and a property: sprite, "
    "colon, frame. Four keys at zero, point one two five, point two five and point three seven five seconds set the "
    "integers zero to three. Update one is discrete, so each frame holds. Nothing here knows about scarecrows.",
    "Q1: what a clip is, pointed at the walk clip's own lines; the frame track that reads the sheet.", font=21))
beats.append(still("B05", "RESULT",
    "Which cell is frame three is decided by the slicing, h frames four, not by the image. The sheet is written by code, "
    "so no third party licence applies. In the walk preview a camera holds the scarecrow still: its pole foot stays in "
    "one column, and hops zero, minus three, plus one, minus three pixels.",
    "Fixture capture · walk_preview, camera follows the scarecrow", "The sheet, its 4×1 slicing, and the walk strip's cells.",
    evidence=True))
beats.append(still("B06", "PROOF",
    "And why a wrong property fails silently. Mutation one renamed the property to frames. The scene still loads with "
    "no error, and the track would key nothing. Only the read-back saw it: no property called frames on a Sprite2D.",
    "Recorded output · evidence/a7-mutations/m1a", "Q1: a track that names a missing property is silently inert."))
beats.append(board("B07", "BRIEF",
    "Feel is designed in frames. Rui counted a real archer, converted to thirty frames per second: twenty six frames "
    "of draw, one of loose, fourteen of follow through. The game compresses that to eight, one and six, at a step of "
    "one thirtieth of a second. The key times come from that table, not the other way round.",
    "The phase table, then the keys", "CHANGE-BRIEF.md §4 · The phase table",
    doc_line("CHANGE-BRIEF.md", "Frame rate: 30 fps. `Animation.step` = 1/30 s"),
    f"CHANGE-BRIEF.md §4 · Rui's measurement and table · @ {SHORT}", "WRITTEN BY RUI BEFORE ANY KEY", "Phase → key time",
    [("Startup · 8 frames", "begins frame 0 → key 0 s · draw; may move; a lost target cancels"),
     ("Active · 1 frame", "begins frame 8 → key 0.26666668 s · release_window true"),
     ("Recovery · 6 frames", "begins frame 9 → key 0.3 s · release_window false; ends 15 → 0.5 s"),
     ("Reference (real archer)", "52 / 2 / 28 frames at 60 fps = 26 / 1 / 14 at 30 · compressed to 8 / 1 / 6")],
    "Q4: feel designed in frames; the phase table beside the key times built from it."))
beats.append(code_beat("B08", "The keys, built from the table.", "game/archer.tscn", 75, 88,
    [(76, "step = 1/30 s: one frame period"), (80, "the bow pivot's rotation"),
     (84, "frames 0, 8, 9, 15 → 0, 8/30, 9/30, 0.5 s"), (85, "2: ease into full draw · 0.5: settle"),
     (87, "full draw -0.279 rad = -16° (tuned)")],
    [{"label": "release_window", "value": "lines 128-135: F, T, F"}, {"label": "float32", "value": "8/30 → 0.26666668"}, {"label": "Read-back", "value": "166/0, −16° pinned"}],
    "The keys, built from the table. Step is one thirtieth. The bow's rotation is keyed at frames zero, eight, nine and "
    "fifteen. Transition two accelerates into full draw; point five settles through recovery. The full draw value is "
    "minus sixteen degrees, after tuning. The same clip keys release window, true for one frame.",
    "The committing action keyed at its phase boundaries, verbatim.", font=21))
beats.append(still("B09", "RESULT",
    "The fixture strip at each boundary. Frame ten is the trigger, still looking idle. Eighteen is full draw, release "
    "window true, no arrow yet. Nineteen: the arrow is out, because the archer reads the key one tick after the tree "
    "writes it. Twenty five is idle again.",
    "Fixture capture · shoot_preview r1", "The frame strip at each phase boundary, with the log line for each frame.",
    evidence=True))
beats.append(still("B10", "TUNING",
    "The revision came from Rui's eyes, not Claude's. Rui watched first: the draw moved too little, and the phases were "
    "hard to tell apart. The agent proposed one key, minus eight degrees to minus sixteen, and predicted every logged "
    "angle. The log matched; one frame missed, on unseeded particles. Rui kept it, and in play said the three phases "
    "read clearly.",
    "Fixture captures · r0 → r1", "The observation-driven revision: observation, prediction, two strips, verdict."))
beats.append(code_beat("B11", "One authority, one clock.", "game/archer.gd", 27, 40,
    [(27, "_physics_process: the physics tick"), (33, "reads release_window, never writes it"),
     (36, "the arrow on the first true read"), (40, "startup only: a lost target cancels")],
    [{"label": "Authority", "value": "the tree writes release_window"}, {"label": "Clock", "value": "archer.tscn:194 → PHYSICS"}, {"label": "Base node", "value": "archer.tscn:196 \"..\""}],
    "One authority. Only the AnimationTree writes release window, keyed in the clip. The archer reads it here, in "
    "physics process, and never writes it. Two clocks: the tree's callback mode is physics, so the clip and this read "
    "share a tick type. The scarecrow's player runs on idle, and no gameplay reads it.",
    "Q2 one authority and Q3 two clocks, pointed at the archer's own lines.", font=19))
beats.append(still("B12", "RESULT",
    "Measured, from the same windowed run as the strip: release window turns true on tick thirty seven, and the arrow "
    "fires on tick thirty eight. The largest disagreement is one physics tick, a sixtieth of a second, already inside "
    "the point three second draw lead.",
    "Fixture capture · log lines from the same windowed run", "Q3 measured: one physics tick between the key and the read.",
    evidence=True))
beats.append(code_beat("B13", "The walk's one writer.", "game/scarecrow_walk_presenter.gd", 2, 15,
    [(4, "never writes Sprite.frame"), (13, "reads at_wall: game state in"), (14, "assigned_animation, not current"),
     (15, "play(): only chooses the clip")],
    [{"label": "Authority", "value": "only the player writes frame"}, {"label": "Clock", "value": "IDLE · no gameplay reads it"}, {"label": "Why assigned", "value": "hold ends → current is \"\""}],
    "The walk's authority. The presenter reads at wall and picks walk or hold. It never writes the frame: the "
    "AnimationPlayer is the frame's only writer. It compares the assigned animation, because a one key hold clip "
    "empties current animation when it ends.",
    "Q2 for the sprite: the presenter only picks the clip; the AnimationPlayer is the one writer.", font=19))
beats.append(capture("B14", "PLAY",
    "In play, at normal speed: a dozen wraps with no catch at the seam, then the hold at the wall. Rui watched five "
    "wraps and saw no stutter, and judged the fixture strip free of drift.",
    "Scarecrows placed by the script · no keys pressed", "The cycle wrapping in play, then walk to hold.", evidence=True))
beats.append(capture("B15", "PLAY",
    "Interrupts in each phase, keys sent by a script into the real game. P in startup freezes the bow half drawn; P "
    "again, and it finishes and fires. P on the active frame holds full draw; on resume the arrow leaves. P in recovery "
    "freezes the swing back. Moving does not interrupt. A target at the wall, walked out of the cone, cancels the draw: "
    "no arrow.",
    "Scripted-input capture · keys sent by a script", "The state machine in real play, with an interrupt in each phase."))
beats.append(still("B16", "PROOF",
    "What the tests proved. Both read-backs pass, sixty eight and one sixty six checks. The state machine test, one oh "
    "seven, drives real keys. The edge test, three twenty five, hits every boundary before, on and after. The pins pass "
    "again. Mutations one to three failed their read-backs; four passed, as a keyed rig should. No headless run draws a "
    "frame, so none of this says the motion reads.",
    "Recorded output · test logs and mutations", "What the read-backs proved, the mutations, what no headless run shows.",
    evidence=True))
beats.append(board("B17", "MISTAKES",
    "Mistakes caught. An agent reported seventy two checks where there were sixty eight, and mistyped a log line. "
    "Claude's own helper fix fired no arrow, and its playtest checklist was wrong: walking away cancels a draw only "
    "near the wall. Rui overruled the agent's minus eight degrees. Still uncertain: no human has seen a startup cancel.",
    "Caught, overruled, uncertain", "FRICTIONAL.md · TUNING.md · TEST-REPORT.md · 2026-11-19 to 11-22",
    doc_sub("FRICTIONAL.md", "A human instruction needs the same geometry check as a test."),
    f"FRICTIONAL.md, TUNING.md, TEST-REPORT.md @ {SHORT}", "RECORDED, NOT HIDDEN", "Five points",
    [("Agent", "68 checks reported as 72 · a mistyped log line · PowerShell and cd-chain attempts, denied"),
     ("Claude", "a test-helper fix that fired no arrow · reverted before commit"),
     ("Claude", "playtest checklist: walk away to cancel · true only near the wall"),
     ("Overruled", "agent's −8° full draw: Rui saw it as too small · −16° kept"),
     ("Uncertain", "a startup cancel, never seen by a human · fixture vs play on the phases")],
    "Agent mistakes caught, Claude's readings overruled, what remains uncertain."))
beats.append(narrated("B18", "VERDICT",
    "The verdict. Shown working: a clean walk cycle, and a shot whose phases read in play. Limits: a startup cancel "
    "comes too early to see, and the fixture and the game disagree on the phases. Next: a larger release kick, so "
    "recovery reads. Rui wrote the brief, the table, every verdict and capture. Claude and the agents built and tested "
    "the rest.",
    {"type": "GRAPHIC", "source": "remotion", "motion": "reveal", "remotion": {"pattern": "ClaudeVerdictArtifact", "props": {
        "artifactTitle": "Verdict",
        "artifactHeading": f"walker-mimic-keep-rui-sun @ {SHORT} · shown, checked, still open",
        "artifactLines": [
            "shown — walk cycle with no seam or drift; shot phases read in play (Rui).",
            "checked — read-backs 68 and 166/0; state 107/0; edges 325/0; pins 38/0; mutations 1–3 exit 1.",
            "uncertain — startup cancel unseen by a human; fixture vs play on the phases.",
            "next — a larger +2° release kick, so the recovery reads (the agent's next candidate).",
            "who — Rui: brief, phase table, verdicts, captures · Claude + agent sessions: keys, tests, tools.",
            f"sources — sheet and rig parts written by make_sprites.gd, no third-party licence · {SHORT} · Godot 4.7.2 Forward+."]}}},
    "Verdict: shown, checked, uncertain, next step, contributions, sheet source and licence, source revision."))
beats.append(narrated("B19", "HANDOFF",
    "Your turn. Here is the paste ready prompt. Write your phase table in frames before any key exists. Let an agent "
    "key it and read it back, then judge the motion in the running game yourself, because no test can see it. Liam, "
    "in for Bear.",
    {"type": "GRAPHIC", "source": "remotion", "motion": "type-on", "remotion": {"pattern": "ClaudeComposerAsk", "props": {
        "greeting": "Your turn.", "topic": "WALKER · MIMIC KEEP ANIMATION", "segment": "your turn",
        "command": "Use Walker. I will write one committing action's phase table in frames, with the frame rate and "
                   "Animation.step, before any key exists. Key it at every phase boundary, add a read-back that pins the "
                   "times with a half-frame tolerance, and give me a fixture preview to capture. I judge the motion in "
                   "the running game.",
        "runningText": "reading the phase table; keys at 0, 8/30, 9/30, 0.5 s…",
        "output": ["the phase table, before the keys",
                   "a read-back that fails on a missing property",
                   "a verdict made in the running game"],
        "folderLabel": "@NikBearBrown", "modelLabel": "Claude", "effortLabel": "Opus"}}},
    "Your Turn - a paste-ready Walker prompt; Liam signs off here, before the final card."))
beats.append({"beat_id": "B20", "act": "OUTRO",
              "role_note": "OUTRO LOCK - ClaudeTitleOutro, exact title, @NikBearBrown, slug-seeded mascot/jingle.",
              "narration_text": "", "audio_file": JINGLE["audio_file"],
              "jingle": {k: JINGLE[k] for k in ("source", "pick", "gain_db")},
              "estimated_duration_s": JINGLE["duration_s"], "actual_duration_s": JINGLE["duration_s"],
              "shot": {"type": "GRAPHIC", "source": "remotion", "motion": "reveal",
                       "remotion": {"pattern": "ClaudeTitleOutro", "props": {"title": TITLE, "slug": SLUG,
                                                                             "durationSeconds": JINGLE["duration_s"]}}}})

sheet = {"metadata": {
    "title": TITLE, "slug": SLUG, "topic": "WALKER · MIMIC KEEP ANIMATION", "kind": "gamedev", "playlist": "Brutalist",
    "brand": "claude-liam", "audience": "CSYE 7270 reviewers and Walker readers", "register": "Teardown",
    "engine": "kokoro", "voice": "am_onyx", "voice_kokoro": "am_onyx", "palette": "claude", "style_preset": "claude",
    "ground": "#FAF9F5", "aspect_ratio": "16:9", "fit": "contain", "captions": False, "channel": "@NikBearBrown",
    "channel_title": "@NikBearBrown", "folderLabel": "@NikBearBrown", "greeting": f"{GREETING}, Liam",
    "greeting_note": "hello lexicon: Merhaba (Turkish), not used by the A1-A6 reels (Kia ora, Zdravo, Kumusta, Mingalaba, Sawubona were).",
    "persona": "Liam (in for Bear)", "presenter": "Liam (in for Bear)", "in_for_bear": True,
    "episode_id": "walker-mimic-keep-a7-gamedev",
    "note": f"godot-gamedev in walker mode over walker-mimic-keep-rui-sun (CSYE 7270 Assignment 7). Source commit {REV}, "
            f"build_id {BUILD}, Godot 4.7.2.stable.official.ed1daf0bf, Forward+. B02, B14 and B15 are native 3840x2160 Godot "
            "Movie Maker output from an isolated copy of that commit, driven by capture/capture_a7_film.gd (B02, B14: no "
            "input; B15: key events sent by the script). Stills compose the repository's fixture strips, logs and recorded "
            "words; all labelled in frame."},
    "beats": beats}
(REEL / "beat_sheet.json").write_text(json.dumps(sheet, indent=1, ensure_ascii=False), encoding="utf-8")
print(len(beats), "beats,", sum(len(b["narration_text"].split()) for b in beats), "words ->", REEL / "beat_sheet.json")
