"""Write gamedev-evidence.json (schema 1, teaching_contract code-then-result-v1) for the Mimic Keep A7 film.

Written by Claude, 2026-11-22, on the A6 film's script. Inventories every authored file in godot/ (except .godot/
and .uid), hashes it, assigns every file to a component, records the verbatim excerpts shown on screen, and
pairs each code beat with the next beat's hashed media. Run AFTER cut_clips.py.

    F:/7270/film-env/Scripts/python.exe make_evidence.py
"""
import hashlib
import json
from pathlib import Path

REEL = Path(__file__).resolve().parent
REPO = Path("C:/Users/18500/Desktop/7270/Assignment5/walker-mimic-keep-rui-sun")
GAME = REPO / "godot"

A7 = {
    "walk-cycle": (
        "The scarecrow walk, the cycle: scarecrow_walk.png (4x1, 64x80 cells, written by tools/make_sprites.gd) sliced by "
        "Sprite.hframes = 4; the walk and hold clips in scarecrow.tscn (Sprite:frame, UPDATE_DISCRETE, LOOP_LINEAR); "
        "scarecrow_walk_presenter.gd picks the clip from at_wall and never writes the frame; the sheet and walk "
        "read-backs; the camera-follow walk preview behind the registration strip.",
        ["B04", "B05", "B06", "B13", "B14"],
        ["game/scarecrow.tscn", "game/scarecrow_walk_presenter.gd", "assets/sprites/scarecrow_walk.png",
         "assets/sprites/scarecrow_walk.png.import", "assets/sprites/ATTRIBUTION.md", "tools/make_sprites.gd",
         "previews/walk_preview.tscn", "previews/walk_preview.gd", "tests/test_scarecrow_sheet.gd",
         "tests/test_scarecrow_walk_readback.gd"]),
    "archer-shot": (
        "The archer shot, the committing action: a cutout rig (Rig/Body, Rig/BowPivot/Bow, Rig/BowPivot/String) keyed in "
        "archer.tscn at the phase table's boundaries, with release_window keyed true for one frame; the AnimationTree "
        "state machine (PHYSICS, advance_expression_base_node ..) plays idle and shoot; archer.gd travels, cancels and "
        "reads release_window in _physics_process; read-back, state-machine and edge tests; the shoot preview fixture.",
        ["B07", "B08", "B09", "B10", "B11", "B12", "B15"],
        ["game/archer.tscn", "game/archer.gd", "assets/sprites/archer_body.png", "assets/sprites/archer_body.png.import",
         "assets/sprites/archer_bow.png", "assets/sprites/archer_bow.png.import", "assets/sprites/archer_string.png",
         "assets/sprites/archer_string.png.import", "tools/make_sprites.gd", "previews/shoot_preview.tscn",
         "previews/shoot_preview.gd", "tests/test_archer_parts.gd", "tests/test_archer_shot_readback.gd",
         "tests/test_archer_state_machine.gd", "tests/test_archer_edges.gd"]),
    "pins": (
        "tests/test_pins_a7.gd: behaviour pins committed before the change and re-pinned only where the brief predicted; "
        "shown with the read-backs, edges and mutations in the proof still.",
        ["B16"],
        ["tests/test_pins_a7.gd"]),
}
GAME_EXPL = ("The Mimic Keep game the clips live in, and the earlier assignments' work kept unchanged: main.gd (whose "
             "reset() now also calls archer.cancel_shot()), arrow.gd, scarecrow.gd, the HUD's pause, the A5 shaders and "
             "materials, the A6 effects, sprites, tools and the earlier test suites.")
EXCERPTS = [("B04", "game/scarecrow.tscn", 18, 31), ("B08", "game/archer.tscn", 75, 88),
            ("B11", "game/archer.gd", 27, 40), ("B13", "game/scarecrow_walk_presenter.gd", 2, 15)]
PAIRS = [
    ("B04", "B05", "media/B05.png", "The four keyed integers on screen: the sheet's four cells, frame 0 to 3, sliced 4x1 by "
     "hframes, and the walk strip showing cells 0-3 with the pole foot in one column (x 638-641)."),
    ("B08", "B09", "media/B09.png", "The keys at frames 0, 8, 9 and 15 in the fixture strip: trigger at strip frame 10, "
     "full draw at -16 deg with release_window true at 18, arrow out at 19, idle at 25, each with its log line."),
    ("B11", "B12", "media/B12.png", "The read in _physics_process measured: release_window true on tick 37, fired on "
     "tick 38, one physics tick (1/60 s) after the tree writes it."),
    ("B13", "B14", "media/B14.mp4", "The presenter's choice in play: a scarecrow outside the cone walks about a dozen "
     "wraps on the walk clip, then switches to hold when at_wall turns true."),
]


def sha(p):
    return hashlib.sha256(Path(p).read_bytes()).hexdigest()


def main():
    files = sorted(p.relative_to(GAME).as_posix() for p in GAME.rglob("*") if p.is_file()
                   and not any(x in (".godot", ".git") for x in p.relative_to(GAME).parts) and p.suffix != ".uid")
    owner = {}
    for cid, (_, _, paths) in A7.items():
        for p in paths:
            owner.setdefault(p, []).append(cid)
    unknown = [p for p in owner if p not in files]
    assert not unknown, unknown
    game_files = [f for f in files if f not in owner]
    for f in game_files:
        owner[f] = ["game"]
    components = {"game": (GAME_EXPL, ["B02", "B03"], game_files), **A7}
    roles = {".gd": "script", ".gdshader": "shader", ".import": "import settings", ".tscn": "scene",
             ".tres": "resource", ".png": "texture", ".md": "documentation", ".ps1": "script", ".godot": "config"}
    sheet = json.loads((REEL / "beat_sheet.json").read_text(encoding="utf-8"))
    beat = {b["beat_id"]: b for b in sheet["beats"]}
    ex = []
    for bid, p, a, z in EXCERPTS:
        text = "\n".join((GAME / p).read_text(encoding="utf-8").splitlines()[a - 1:z])
        assert beat[bid]["shot"]["remotion"]["props"]["code"] == text, bid
        ex.append({"beat_id": bid, "path": p, "start_line": a, "end_line": z, "text": text})
    data = {
        "schema_version": 1, "teaching_contract": "code-then-result-v1",
        "source_revision": (REEL / "capture" / "source-commit.txt").read_text().strip(),
        "build_id": (REEL / "capture" / "build_id.txt").read_text().strip(),
        "files": [{"path": f, "sha256": sha(GAME / f), "role": roles.get(Path(f).suffix, "data"), "component_ids": owner[f]}
                  for f in files],
        "components": [{"id": cid, "explanation": e, "beat_ids": b, "files": paths} for cid, (e, b, paths) in components.items()],
        "excerpts": ex,
        "exclusions": [],
        "code_result_pairs": [{"code_beat": c, "result_beat": r, "observation": o, "media": {"path": m, "sha256": sha(REEL / m)}}
                              for c, r, m, o in PAIRS],
    }
    (REEL / "gamedev-evidence.json").write_text(json.dumps(data, indent=1, ensure_ascii=False), encoding="utf-8")
    print(len(data["files"]), "files,", len(ex), "excerpts,", len(PAIRS), "pairs")


if __name__ == "__main__":
    main()
