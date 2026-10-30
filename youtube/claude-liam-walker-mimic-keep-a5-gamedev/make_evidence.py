"""Write gamedev-evidence.json (schema 1, teaching_contract code-then-result-v1) for the Mimic Keep A5 film.

Written by Claude, 2026-10-29. Inventories every authored file in godot/ (except .godot/ and .uid), hashes it,
assigns every file to a component, records the verbatim excerpts shown on screen, and pairs each code beat with
the next beat's hashed media. Run AFTER cut_clips.py.

    F:/7270/film-env/Scripts/python.exe make_evidence.py
"""
import hashlib
import json
from pathlib import Path

REEL = Path(__file__).resolve().parent
REPO = Path("C:/Users/18500/Desktop/7270/Assignment5/walker-mimic-keep-rui-sun")
GAME = REPO / "godot"
WOOD = [f"assets/textures/wood_planks/wood_planks_{m}_1k.png{x}" for m in ("diff", "rough", "nor_gl", "nor_dx") for x in ("", ".import")]

COMPONENTS = {
    "game": (
        "The Mimic Keep prototype the effect lives in: main.gd owns the run, archer.gd auto-fires at the nearest scarecrow "
        "in a 120 degree cone, arrow.gd hits and ignites, scarecrow.gd owns Burning (burn_time_left, 4 s, 4 dps); sprites "
        "drawn by tools/make_sprites.gd; earlier suites test_rules and test_input; balance_sim and capture_prototype are "
        "prototype tools.",
        ["B02", "B08"],
        ["project.godot", "game/main.tscn", "game/main.gd", "game/archer.gd", "game/archer.tscn", "game/arrow.gd",
         "game/arrow.tscn", "game/scarecrow.gd", "game/tuning.gd", "game/hud.gd", "game/background.gd",
         "assets/sprites/archer.png", "assets/sprites/archer.png.import", "assets/sprites/arrow.png",
         "assets/sprites/arrow.png.import", "assets/sprites/mimi.png", "assets/sprites/mimi.png.import",
         "assets/sprites/scarecrow.png", "assets/sprites/scarecrow.png.import", "tests/test_rules.gd",
         "tests/test_input.gd", "tools/make_sprites.gd", "tools/balance_sim.gd", "tools/capture_prototype.gd"]),
    "burning-tint": (
        "Rui's burning_tint.gdshader (canvas_item; burn_mix, burn_color, one colour line), driven every frame by "
        "game/burning_tint.gd from burn_time_left on each scarecrow's own local-to-scene ShaderMaterial "
        "(scarecrow.tscn); test_burning_tint.gd samples it at 30/60/144 fps; capture_burn_values.gd, capture_in_play.gd, "
        "os_screenshot.ps1 and compare_os_screenshot.gd make the in-engine evidence.",
        ["B03", "B04", "B05", "B06", "B07", "B08", "B09", "B10", "B11"],
        ["shaders/burning_tint.gdshader", "game/burning_tint.gd", "game/scarecrow.tscn", "tests/test_burning_tint.gd",
         "tools/capture_burn_values.gd", "tools/capture_in_play.gd", "tools/os_screenshot.ps1",
         "tools/compare_os_screenshot.gd"]),
    "hint-experiment": (
        "hint_experiment.gdshader (Rui; unshaded, one source_color sampler and one plain sampler) on two quads in "
        "hint_experiment.tscn, bound to the same 3x1 grey strip written by tools/make_hint_greys.gd.",
        ["B12", "B13"],
        ["shaders/hint_experiment.gdshader", "showcase/hint_experiment.tscn", "showcase/hint_source_color.tres",
         "showcase/hint_raw.tres", "assets/textures/hint_greys_3x1.png", "assets/textures/hint_greys_3x1.png.import",
         "tools/make_hint_greys.gd"]),
    "shield-material": (
        "Rui's shield_wood.gdshader (spatial; albedo with source_color, roughness, hint_normal normal map, scorch mask; "
        "Surface and Damage groups) used by shield_new.tres and shield_burned.tres on two shields in shield_room.tscn; "
        "Poly Haven Wood Planks textures with explicit .import settings; generated scorch mask and shield mesh; "
        "test_materials.gd audits the wiring, normal_map_check.gd the normal map; capture_shield_room.gd makes the "
        "sweep and edit frames.",
        ["B14", "B15", "B16", "B17", "B18", "B19", "B21"],
        ["shaders/shield_wood.gdshader", "showcase/shield_new.tres", "showcase/shield_burned.tres",
         "showcase/shield_room.tscn", "showcase/shield_mesh.tres", "assets/textures/shield_scorch_mask.png",
         "assets/textures/shield_scorch_mask.png.import", "assets/textures/wood_planks/ATTRIBUTION.md", *WOOD,
         "tools/make_scorch_mask.gd", "tools/make_shield_mesh.gd", "tools/capture_shield_room.gd",
         "tests/test_materials.gd", "tests/normal_map_check.gd", "MATERIALS.md"]),
    "generated-shader": (
        "standard_generated.gdshader: a StandardMaterial3D converted to code by Rui in the editor, unedited, annotated "
        "against shield_wood.gdshader (source_color on the albedo sampler, a normal hint on the normal sampler).",
        ["B20", "B21"],
        ["shaders/standard_generated.gdshader"]),
}
EXCERPTS = [("B04", "shaders/burning_tint.gdshader", 1, 8), ("B06", "game/burning_tint.gd", 7, 13),
            ("B09", "tests/test_burning_tint.gd", 90, 98), ("B12", "shaders/hint_experiment.gdshader", 4, 17),
            ("B14", "shaders/shield_wood.gdshader", 6, 16), ("B16", "shaders/shield_wood.gdshader", 21, 33),
            ("B18", "showcase/shield_burned.tres", 10, 22), ("B20", "shaders/standard_generated.gdshader", 7, 19)]
PAIRS = [
    ("B04", "B05", "media/B05.png", "Line 7 measured: five frozen scarecrows at burn_mix 0, 0.5, 0.65, 1, 2; 15/15 named "
     "pixels within one step of Rui's hand calculation; at 2.0 the pixels follow 2.0 (no hint_range clamp)."),
    ("B06", "B07", "media/B07.mp4", "The driver in the running game: the middle scarecrow tints at the fire hit, fades, "
     "jumps back to full at the second hit, holds still while Esc pauses, and leaves nothing when it burns down."),
    ("B09", "B10", "media/B10.png", "Recorded output: 49/0 at 30, 60 and 144 fps (4.000000 s of game time, retrigger, "
     "pause); mutation 1 SHADER ERROR 45/4 and mutation 2 46/3, both exit 1."),
    ("B12", "B13", "media/B13.png", "The two samplers on screen: source_color 64/128/192, no hint 137/188/225, as Rui "
     "predicted; all six measured exact."),
    ("B14", "B15", "media/B15.png", "The shields under the room's light, and normal_map_check: nor_gl 0.6703 as OpenGL vs "
     "1.3297, below Rui's threshold 0.8357; 9/0."),
    ("B16", "B17", "media/B17.png", "Every uniform at min, default and max, Surface on ShieldA and Damage on ShieldB, in "
     "the room's fixed light."),
    ("B18", "B19", "media/B19.png", "Rui's shader edit changed both shields (98,610 px each half); the material edit "
     "changed only ShieldA (0 px on the right); both restored byte-identical."),
    ("B20", "B21", "media/B21.png", "Mutation 3: source_color removed from the albedo sampler; test_materials 130/2, "
     "exit 1, caught only by the source-text checks."),
]


def sha(p):
    return hashlib.sha256(Path(p).read_bytes()).hexdigest()


def main():
    files = sorted(p.relative_to(GAME).as_posix() for p in GAME.rglob("*") if p.is_file()
                   and not any(x in (".godot", ".git") for x in p.relative_to(GAME).parts) and p.suffix != ".uid")
    owner = {}
    for cid, (_, _, paths) in COMPONENTS.items():
        for p in paths:
            owner.setdefault(p, []).append(cid)
    unknown = [p for p in owner if p not in files]
    missing = [f for f in files if f not in owner]
    assert not unknown and not missing, (unknown, missing)
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
        "components": [{"id": cid, "explanation": e, "beat_ids": b, "files": paths} for cid, (e, b, paths) in COMPONENTS.items()],
        "excerpts": ex,
        "exclusions": [],
        "code_result_pairs": [{"code_beat": c, "result_beat": r, "observation": o, "media": {"path": m, "sha256": sha(REEL / m)}}
                              for c, r, m, o in PAIRS],
    }
    (REEL / "gamedev-evidence.json").write_text(json.dumps(data, indent=1, ensure_ascii=False), encoding="utf-8")
    print(len(data["files"]), "files,", len(ex), "excerpts,", len(PAIRS), "pairs")


if __name__ == "__main__":
    main()
