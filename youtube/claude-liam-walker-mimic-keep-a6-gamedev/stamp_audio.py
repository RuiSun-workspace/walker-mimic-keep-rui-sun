"""Re-stamp every narrated beat with its Kokoro file and measured length from mp3/timings.json (Claude, 2026-11-08).
Needed because build_beats.py rewrites beat_sheet.json from scratch after the narration was generated."""
import json
from pathlib import Path
REEL = Path(__file__).resolve().parent
sheet = json.loads((REEL / "beat_sheet.json").read_text(encoding="utf-8"))
t = json.loads((REEL / "mp3" / "timings.json").read_text())
for b in sheet["beats"]:
    if b["narration_text"]:
        b["audio_file"] = f"mp3/beat-{b['beat_id']}.mp3"
        b["actual_duration_s"] = float(t[b["beat_id"]])
(REEL / "beat_sheet.json").write_text(json.dumps(sheet, indent=1, ensure_ascii=False), encoding="utf-8")
print("stamped", sum(1 for b in sheet["beats"] if b["narration_text"]))
# graphic beats: Remotion length = narration length; highlight cues spread over 8-88 %
for b in sheet["beats"]:
    rem = b.get("shot", {}).get("remotion")
    if rem and b.get("actual_duration_s"):
        dur = float(b["actual_duration_s"])
        rem["props"]["durationSeconds"] = dur
        cues = rem["props"].get("cues") or []
        for i, c in enumerate(cues):
            c["at"] = round(dur * (0.08 + 0.8 * i / max(1, len(cues) - 1)), 2)
(REEL / "beat_sheet.json").write_text(json.dumps(sheet, indent=1, ensure_ascii=False), encoding="utf-8")
print("graphic durations set")
