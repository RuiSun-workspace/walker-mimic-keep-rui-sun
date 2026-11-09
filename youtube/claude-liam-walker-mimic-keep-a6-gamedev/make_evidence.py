"""Write gamedev-evidence.json (schema 1, teaching_contract code-then-result-v1) for the Mimic Keep A6 film.

Written by Claude, 2026-11-08, on the A5 film's script. Inventories every authored file in godot/ (except .godot/
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

A6 = {
    "impact-burst": (
        "Effect A: impact_burst.tscn (Flash, additive, and Straw GPUParticles2D, one-shot) instanced per accepted hit by "
        "effects/impact_spawner.gd on Scarecrow.hit_taken, under World/Effects (overlap); configuration and state tests; "
        "the fixed-seed preview fixture; the code-generated textures and their credits.",
        ["B04", "B05", "B06", "B07", "B08"],
        ["effects/impact_burst.tscn", "effects/impact_spawner.gd", "previews/impact_burst_preview.tscn",
         "previews/impact_burst_preview.gd", "tests/test_impact_burst_config.gd", "tests/test_impact_burst_state.gd",
         "tools/make_particle_textures.gd", "effects/textures/soft_dot.png", "effects/textures/soft_dot.png.import",
         "effects/textures/straw_chip.png", "effects/textures/straw_chip.png.import", "effects/textures/ATTRIBUTION.md"]),
    "burning-embers": (
        "Effect B: burning_embers.tscn (Embers, additive, and Smoke with turbulence) on every scarecrow; "
        "effects/burning_embers_driver.gd maps burn_time_left to amount_ratio every frame and moves a dying scarecrow's "
        "emitters to World/Effects; configuration and state tests; the preview fixture; the smoke texture.",
        ["B09", "B10", "B11", "B12", "B13"],
        ["effects/burning_embers.tscn", "effects/burning_embers_driver.gd", "previews/burning_embers_preview.tscn",
         "previews/burning_embers_preview.gd", "tests/test_burning_embers_config.gd", "tests/test_burning_embers_state.gd",
         "effects/textures/smoke_dot.png", "effects/textures/smoke_dot.png.import"]),
    "generated-shader": (
        "particles_generated.gdshader: Effect A Flash's ParticleProcessMaterial converted to code by Rui in the editor, "
        "unused by the game; lines 140, 316 and 329 tied to the brief's velocity and gravity.",
        ["B14", "B15"],
        ["shaders/particles_generated.gdshader"]),
    "price": (
        "tests/cost_effects.gd: the headless CPU cost script (empty control, effects off, Effect A at its peak, Effect B at "
        "its peak); its numbers are shown beside Rui's Visual Profiler GPU reading.",
        ["B15"],
        ["tests/cost_effects.gd"]),
}
GAME_EXPL = ("The Mimic Keep game the effects live in, and the earlier assignments' work kept unchanged: main.gd and the "
             "World tree (with the new World/Effects node), archer.gd, arrow.gd, scarecrow.gd (Burning, and the brief's one "
             "hit_taken signal), the A5 shaders, materials and showcase, sprites, tools and the earlier test suites.")
EXCERPTS = [("B05", "effects/impact_burst.tscn", 77, 88), ("B10", "effects/burning_embers_driver.gd", 27, 40),
            ("B14", "shaders/particles_generated.gdshader", 316, 329)]
PAIRS = [
    ("B05", "B06", "media/B06.png", "The settings on screen in the first fixture strip: a compact flash at frame 10, wider "
     "and saturated at 12, gone by 20; the straw flies out and darkens, still above the hit point."),
    ("B10", "B11", "media/B11.png", "The feedback loop in the fixture strip: embers about 1, 5, 10, 6, 4, 3 and 0 at "
     "frames 10-170 as amount_ratio follows the remaining burn time."),
    ("B14", "B15", "media/B15.png", "The process material's values read back by the configuration tests (128/0, 156/0); "
     "renaming initial_velocity_min to the Godot 3 name leaves line 140's minimum at 0 and fails them."),
]


def sha(p):
    return hashlib.sha256(Path(p).read_bytes()).hexdigest()


def main():
    files = sorted(p.relative_to(GAME).as_posix() for p in GAME.rglob("*") if p.is_file()
                   and not any(x in (".godot", ".git") for x in p.relative_to(GAME).parts) and p.suffix != ".uid")
    owner = {}
    for cid, (_, _, paths) in A6.items():
        for p in paths:
            owner.setdefault(p, []).append(cid)
    unknown = [p for p in owner if p not in files]
    assert not unknown, unknown
    game_files = [f for f in files if f not in owner]
    for f in game_files:
        owner[f] = ["game"]
    components = {"game": (GAME_EXPL, ["B02", "B03"], game_files), **A6}
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
