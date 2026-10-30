"""Pilot-review fixes (Claude, 2026-10-29), applied in place so the provenance stamps remotion_scenes.py wrote into
beat_sheet.json and the capture windows cut_clips.py wrote are kept. The same changes are in build_beats.py.
- B01: "the test cannot see the fire." overflowed the frame at 170 px -> three lines at 150 px.
- B03, B11, B22: the board's stock excerpt label reads "GDD · DOCUMENT EXCERPT"; these excerpts are CHANGE-BRIEF,
  CLAUDE.md and FRICTIONAL.md, so excerptLabel = "DOCUMENT EXCERPT" (needs the local one-prop patch).
- B18: lines 9-22 cut line 22 at the panel's bottom -> 10-22.
- B20: lines 7-19 wrap to 16 rows and pushed line 19 (the normal sampler) out of the panel -> code font 19.
Second round, from compile.py's frame QC: B01 underfilled the safe area -> 190 px, line spacing 1.7; B23's verdict
card crossed the bottom safe edge -> the shorter artifact lines now in build_beats.py (read from _rebuilt.json,
which is build_beats.py's output written to a side file so the stamped beat_sheet.json is not replaced).
"""
import json
from pathlib import Path

REEL = Path(__file__).resolve().parent
REPO = Path("C:/Users/18500/Desktop/7270/Assignment5/walker-mimic-keep-rui-sun")
sheet = json.loads((REEL / "beat_sheet.json").read_text(encoding="utf-8"))
for b in sheet["beats"]:
    p = (b.get("shot", {}).get("remotion") or {}).get("props")
    bid = b["beat_id"]
    if bid == "B01":
        p["text"], p["fontSize"], p["lineSpacing"] = "Mimic Keep:\nthe test can\nsee the fire.", 190, 1.7
    elif bid == "B23":   # compile QC: the verdict card crossed the title-safe bottom edge -> shorter lines
        src = {b2["beat_id"]: b2 for b2 in __import__("json").loads(
            Path(REEL / "_rebuilt.json").read_text(encoding="utf-8"))["beats"]}["B23"]["shot"]["remotion"]["props"]
        p["artifactLines"] = src["artifactLines"]
    elif bid in ("B03", "B11", "B22"):
        p["excerptLabel"] = "DOCUMENT EXCERPT"
    elif bid == "B18":
        p["code"] = "\n".join((REPO / "godot/showcase/shield_burned.tres").read_text(encoding="utf-8").splitlines()[9:22])
        p["startLine"] = 10
    elif bid == "B20":
        p["codeFontSize"] = 19
    else:
        continue
    print(bid, "patched")
(REEL / "beat_sheet.json").write_text(json.dumps(sheet, indent=1, ensure_ascii=False), encoding="utf-8")
