"""After the Remotion renders (Claude, 2026-11-08): apply the two structural fixes found by reading verify_gamedev.py,
which requires every code beat to be followed directly by a result beat with media.

1. The three-parts code beat (rendered as B04) and the Effect A intent board (rendered as B05) trade places and ids,
   so the code beat B05 is followed by the first strip B06. Their rendered clips and narration files are renamed
   with them; nothing is re-rendered or re-voiced.
2. B15 (rendered as a GodotDesignBoard) becomes a STILL composed by make_assets.py from verbatim log lines, so the
   generated-shader code beat B14 is followed by recorded output. Its narration is unchanged.
build_beats.py already holds the final order, so a fresh build gives the same sheet.

    F:/7270/film-env/Scripts/python.exe patch_beats.py
"""
import json
import os
from pathlib import Path

REEL = Path(__file__).resolve().parent
sheet = json.loads((REEL / "beat_sheet.json").read_text(encoding="utf-8"))
beats = sheet["beats"]
ids = [b["beat_id"] for b in beats]
i4, i5 = ids.index("B04"), ids.index("B05")
code, intent = beats[i4], beats[i5]
assert code["shot"]["remotion"]["pattern"] == "GodotDevWorkbench" and intent["shot"]["remotion"]["pattern"] == "GodotDesignBoard"


def swap_files(a, b):
    a, b = REEL / a, REEL / b
    tmp = a.with_suffix(a.suffix + ".swap")
    os.replace(a, tmp)
    os.replace(b, a)
    os.replace(tmp, b)


swap_files("media/B04.mp4", "media/B05.mp4")
swap_files("mp3/beat-B04.mp3", "mp3/beat-B05.mp3")
t = json.loads((REEL / "mp3/timings.json").read_text())
t["B04"], t["B05"] = t["B05"], t["B04"]
(REEL / "mp3/timings.json").write_text(json.dumps(t, indent=2))


def retag(beat, old, new):
    s = json.dumps(beat, ensure_ascii=False).replace(f"/{old}.", f"/{new}.").replace(f"beat-{old}.", f"beat-{new}.")
    b = json.loads(s)
    b["beat_id"] = new
    return b


beats[i4], beats[i5] = retag(intent, "B05", "B04"), retag(code, "B04", "B05")

i15 = ids.index("B15")
b15 = beats[i15]
b15["shot"] = {"type": "STILL", "source": "own", "motion": "hold", "label": "Recorded output · test logs and cost script"}
b15["image_file"] = "assets/b15.png"
b15["role_note"] = "Tests, mutations, both prices against budget, the headless limit."
(REEL / "beat_sheet.json").write_text(json.dumps(sheet, indent=1, ensure_ascii=False), encoding="utf-8")
print([(b["beat_id"], b["shot"].get("remotion", {}).get("pattern", b["shot"]["type"])) for b in beats])
