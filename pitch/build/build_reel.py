"""Turn the approved pitch beat sheet into the toolkit's beat sheet (Claude, 2026-11-24).

Source of truth: pitch/beat_sheet.json (narration approved by Rui, 2026-11-24). This script only adds the fields
the local Brutalist toolkit (F:/7270/brutalist.art @ 29ba0e8) needs to voice and compile it; it never changes a
word of narration. Every non-capture beat becomes a picture made by make_stills.py (media/<beat>.png); every
capture beat is cut from the take by cut_clips.py (media/<beat>.mp4).

    F:/7270/film-env/Scripts/python.exe pitch/build/build_reel.py   ->  REEL/beat_sheet.json
"""
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
PITCH = HERE.parent
REEL = Path("F:/7270/reels/mimic-keep-final-pitch")


def main():
    src = json.loads((PITCH / "beat_sheet.json").read_text(encoding="utf-8"))
    md = src["metadata"]
    beats = []
    for b in src["beats"]:
        shot = dict(b["shot"])
        out = {"beat_id": b["beat_id"], "act": b["act"], "narration_text": b["narration_text"],
               "voice": md["voice"], "engine": md["engine"], "estimated_duration_s": b["estimated_duration_s"]}
        if "tail_silence_s" in b:
            out["tail_silence_s"] = b["tail_silence_s"]
        if shot["type"] == "CAPTURE":
            shot["source"] = "screen"
        else:
            shot["motion"] = "hold"          # no Ken Burns drift over text
            out["image_file"] = f"assets/{b['beat_id'].lower()}.png"
        out["shot"] = shot
        beats.append(out)
    sheet = {"metadata": {
        "title": md["title"], "slug": md["slug"], "kind": "pitch", "author": md["author"],
        "audience": md["audience"], "engine": md["engine"], "voice": md["voice"], "voice_kokoro": md["voice"],
        "voice_note": md["voice_note"], "palette": "claude", "ground": "#FAF9F5", "aspect_ratio": "16:9",
        "fit": "crop", "captions": False, "game": md["game"], "captures": md["captures"],
        "label_rule": md["label_rule"],
        "note": "Final project pitch for walker-mimic-keep-rui-sun. Narration approved by Rui (2026-11-24). "
                "No instructor name, persona, handle, mascot or jingle: the walker bookends are deliberately not used."},
        "beats": beats}
    timings = REEL / "mp3" / "timings.json"     # re-runs keep the measured narration (generate_audio_kokoro.py)
    if timings.is_file():
        t = json.loads(timings.read_text())
        for b in beats:
            b["audio_file"] = f"mp3/beat-{b['beat_id']}.mp3"
            b["actual_duration_s"] = float(t[b["beat_id"]])
    REEL.mkdir(parents=True, exist_ok=True)
    (REEL / "beat_sheet.json").write_text(json.dumps(sheet, indent=1, ensure_ascii=False), encoding="utf-8")
    print(len(beats), "beats,", sum(len(b["narration_text"].split()) for b in beats), "words ->", REEL / "beat_sheet.json")


if __name__ == "__main__":
    main()
