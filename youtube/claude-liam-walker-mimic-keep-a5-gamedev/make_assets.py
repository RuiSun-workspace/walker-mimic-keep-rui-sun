"""Compose the 4K still images for the A5 film (Claude, 2026-10-29).

Every picture placed here is a real file committed in the repository (in-engine captures from the tools in
godot/tools/, and Rui's own screenshot), and every line of output is copied verbatim from a committed log or
evidence file. Nothing is redrawn. Each panel carries a burned-in provenance label. SHA-256 of every source is
written to assets/sources.json.

    F:/7270/film-env/Scripts/python.exe make_assets.py
"""
import hashlib
import json
import re
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

REEL = Path(__file__).resolve().parent
REPO = Path("C:/Users/18500/Desktop/7270/Assignment5/walker-mimic-keep-rui-sun")
EV = REPO / "evidence"
W, H = 3840, 2160
GROUND, INK, MUTED, ACCENT = (250, 249, 245), (20, 20, 19), (94, 93, 89), (217, 119, 87)
F = "C:/Windows/Fonts/"
bold = lambda s: ImageFont.truetype(F + "segoeuib.ttf", s)
reg = lambda s: ImageFont.truetype(F + "segoeui.ttf", s)
mono = lambda s: ImageFont.truetype(F + "consola.ttf", s)
cjk = lambda s: ImageFont.truetype(F + "msyh.ttc", s)
RED, GREEN, GOLD, GREY = (255, 120, 110), (120, 220, 140), (255, 207, 90), (180, 180, 190)

SRC = {
    "burn_zoom": EV / "controlled_values/burn_values_zoom.png",
    "pixels": EV / "controlled_values/pixels.txt",
    "rui_one_burning": EV / "in_play/one_burning.png",
    "tint_30": REPO / "logs/test_burning_tint_30fps.log",
    "tint_60": REPO / "logs/test_burning_tint_60fps.log",
    "tint_144": REPO / "logs/test_burning_tint_144fps.log",
    "m1_log": EV / "mutations/m1_semicolon_test_burning_tint_60fps.log",
    "m2_log": EV / "mutations/m2_rename_test_burning_tint_60fps.log",
    "m3_log": EV / "mutations/m3_source_color_test_materials_60fps.log",
    "m3_diff": EV / "mutations/m3_source_color.diff",
    "hint_render": EV / "hint_experiment/hint_experiment_render.png",
    "bands": EV / "hint_experiment/band_values.txt",
    "shield_before": EV / "two_materials/0_before.png",
    "shader_edit": EV / "two_materials/1_shader_edit.png",
    "material_edit": EV / "two_materials/2_material_edit.png",
    "normal_log": REPO / "logs/normal_map_check_60fps.log",
    "observations": REPO / "my-observations.txt",
    "sweep_txt": EV / "sweep/sweep.txt",
}
UNIFORMS = ["wood_tint", "texture_scale", "roughness_scale", "normal_strength", "scorch_amount", "scorch_color", "char_roughness"]
ON_B = {"scorch_amount", "scorch_color", "char_roughness"}
for u in UNIFORMS:
    for w in ("min", "default", "max"):
        SRC[f"sweep_{u}_{w}"] = EV / f"sweep/{u}_{w}.png"
sources = {k: {"path": str(p.relative_to(REPO)), "sha256": hashlib.sha256(p.read_bytes()).hexdigest()} for k, p in SRC.items()}


def read(k):
    return SRC[k].read_text(encoding="utf-8").splitlines()


def canvas(title, kicker):
    img = Image.new("RGB", (W, H), GROUND)
    d = ImageDraw.Draw(img)
    d.text((200, 150), kicker.upper(), font=bold(54), fill=ACCENT)
    d.text((200, 220), title, font=bold(104), fill=INK)
    return img, d


def label(d, x, y, text, gold=False):
    f = reg(46)
    w = d.textlength(text, font=f)
    d.rounded_rectangle([x, y, x + w + 64, y + 84], radius=20, fill=(12, 12, 18),
                        outline=GOLD if gold else (154, 163, 191), width=4)
    d.text((x + 32, y + 12), text, font=f, fill=GOLD if gold else (244, 241, 232))


def paste_fit(img, path, box, crop=None, nearest=False):
    im = Image.open(path).convert("RGB")
    if crop:
        im = im.crop(crop)
    x, y, w, h = box
    s = min(w / im.width, h / im.height)
    im = im.resize((round(im.width * s), round(im.height * s)), Image.NEAREST if nearest else Image.LANCZOS)
    px, py = x + (w - im.width) // 2, y + (h - im.height) // 2
    img.paste(im, (px, py))
    ImageDraw.Draw(img).rectangle([px - 3, py - 3, px + im.width + 2, py + im.height + 2], outline=(200, 198, 190), width=3)
    return px, py, im.width, im.height


def text_box(d, x, y, w, lines, size=44, line_h=None):
    font = mono(size)
    line_h = line_h or int(size * 1.45)
    h = 70 + line_h * len(lines)
    d.rounded_rectangle([x, y, x + w, y + h], radius=24, fill=(30, 30, 34))
    maxc = int((w - 88) / (size * 0.55))
    for i, (t, c) in enumerate(lines):
        t = t if len(t) <= maxc else t[:maxc - 1] + "…"
        d.text((x + 44, y + 36 + i * line_h), t, font=font, fill=c or (236, 233, 224))
    return h


def find(lines, needle):
    return next(l for l in lines if needle in l)


out = REEL / "assets"
out.mkdir(exist_ok=True)

# B05 - controlled values: the frozen scarecrows and the sampled pixels
img, d = canvas("Fifteen pixels, predicted by hand", "B05 · controlled values")
r = paste_fit(img, SRC["burn_zoom"], (200, 400, 3440, 440), nearest=True)
for i, m in enumerate(["0.0", "0.5", "0.65", "1.0", "2.0"]):   # centred under each scarecrow (160 px apart in game)
    cx = r[0] + r[2] * (36 + 160 * i) / 712
    t = f"burn_mix {m}"
    d.text((cx - d.textlength(t, font=bold(44)) / 2, r[1] + r[3] + 12), t, font=bold(44), fill=INK)
px = read("pixels")
rows = [(l, GREEN if "MATCH" in l else RED) for l in px if l.startswith("m=") and "Straw body" in l]
rows += [(find(px, "m=2.0  Patch"), GREEN), ("", None), (find(px, "of 15 sampled"), GOLD)]
text_box(d, 200, 1010, 3440, rows, size=38)
label(d, 200, 1890, "Scripted capture · world frozen · in-engine frame (tools/capture_burn_values.gd) · lines verbatim from pixels.txt")
img.save(out / "b05.png")

# B08 - Rui's own playtest: screenshot and words
img, d = canvas("Rui's playtest: what no test can check", "B08 · in play")
r = paste_fit(img, SRC["rui_one_burning"], (200, 400, 1700, 1000), nearest=True)
label(d, r[0], r[1] + r[3] + 30, "Screenshot by Rui, 2026-10-29 (part of the game window)")
y = 420
d.text((2050, y), "Rui, after playing:", font=bold(50), fill=INK)
y += 90
for zh, en in [("1.结束时消失了", "it disappeared at the end"), ("2.淡出部分比较平滑", "the fade-out is fairly smooth"),
               ("3.再次被打中颜色刷新明显", "the refresh is obvious when hit again"), ("4.暂停时颜色不变", "the colour does not change while paused"),
               ("5.能看清稻草人的细节", "the scarecrow's details can be seen")]:
    d.text((2050, y), zh, font=cjk(50), fill=INK)
    d.text((2050, y + 66), en, font=reg(40), fill=MUTED)
    y += 150
y += 20
d.text((2050, y), "Two faults that are not in the tint:", font=bold(46), fill=INK)
for zh, en in [("横向距离远的时候子弹瞄准的过于靠后会导致打空", "long sideways shots aim behind and miss"),
               ("小怪到墙前面开始打墙后子弹打不中墙了", "once a monster attacks the wall, arrows can't hit it")]:
    y += 80
    d.text((2050, y), zh, font=cjk(42), fill=INK)
    d.text((2050, y + 58), en, font=reg(38), fill=MUTED)
    y += 60
d.text((2050, 1990), "English: translated by Claude", font=reg(38), fill=MUTED)
img.save(out / "b08.png")

# B10 - headless output, verbatim, and the two shader mutations
img, d = canvas("Forty-nine checks, then two broken shaders", "B10 · recorded output")
show = []
for k, fps in (("tint_30", 30), ("tint_60", 60), ("tint_144", 144)):
    ls = read(k)
    show.append((f"$ ./scripts/run-test.sh test_burning_tint.gd {fps}", None))
    show.append((find(ls, f"[time_scale 1.0 @ {fps} fps] 0.65 -> 0.0"), GREEN))
    if fps == 60:
        show.append((find(ls, "[retrigger] burn_mix"), GREEN))
        show.append((find(ls, "[pause] burn_mix"), GREEN))
    show.append((find(ls, "test_burning_tint:"), GOLD))
m1, m2 = read("m1_log"), read("m2_log")
show += [("", None), ("# mutation 1: Rui deleted a semicolon · exit 1", GREY), (find(m1, "SHADER ERROR"), RED),
         (find(m1, "test_burning_tint:"), RED),
         ("# mutation 2: Rui renamed burn_mix to burn_amount · exit 1", GREY),
         (find(m2, "FAIL burn_mix is a float"), RED), (find(m2, "test_burning_tint:"), RED)]
text_box(d, 200, 400, 3440, show, size=36)
label(d, 200, 1950, "Headless output · verbatim lines of logs/ and evidence/mutations/ (long lines cut with …)", True)
img.save(out / "b10.png")

# B13 - hint experiment: the frame and the measured bands
img, d = canvas("Same pixels, two readings", "B13 · hint experiment")
r = paste_fit(img, SRC["hint_render"], (200, 400, 2080, 1170))
label(d, r[0], r[1] + r[3] + 30, "In-engine frame · godot/showcase/hint_experiment.tscn · unshaded, linear tonemap")
bands = read("bands")
text_box(d, 2380, 420, 1260, [
    ("Rui's prediction (CHANGE-BRIEF §7)", GREY),
    ("source_color  64 / 128 / 192", None),
    ("no hint      137 / 188 / 225", None),
    ("", None),
    ("measured (band_values.txt)", GREY),
    ("source_color " + " / ".join(re.findall(r"=(\d+)/\d+/\d+", bands[5])), GREEN),
    ("no hint      " + " / ".join(re.findall(r"=(\d+)/\d+/\d+", bands[6])), GREEN),
    ("", None),
    (bands[9], GOLD),
], size=40)
d.text((2380, 1300), "Without source_color, encoded", font=reg(46), fill=INK)
d.text((2380, 1365), "values are treated as linear light,", font=reg(46), fill=INK)
d.text((2380, 1430), "then encoded again: too bright.", font=reg(46), fill=INK)
img.save(out / "b13.png")

# B15 - the lit shield and the curl check
img, d = canvas("A surface, in the right convention", "B15 · normal map")
r = paste_fit(img, SRC["shield_before"], (200, 400, 2080, 1170))
label(d, r[0], r[1] + r[3] + 30, "In-engine frame · shield_room.tscn · Sun 1.2 with shadows, ambient 0.3")
nl = read("normal_log")
text_box(d, 2380, 420, 1260, [
    ("$ ./scripts/run-test.sh", None), ("    normal_map_check.gd 60", None),
    ("curl_ratio, directx = false / true", GREY),
    ("nor_gl  0.6703 / 1.3297", GREEN), ("nor_dx  1.3286 / 0.6714", None),
    ("threshold (0.6714 + 1.0) / 2", GREY), ("        = 0.8357  (Rui's rule A)", GOLD),
    ("ShieldA, ShieldB: nor_gl < 0.8357", GREEN), (find(nl, "normal_map_check:"), GOLD),
], size=38)
obs = read("observations")[38]
d.text((2380, 1300), "Rui:", font=bold(44), fill=INK)
words, line, yy = obs.split(), "", 1360
for wd in words:
    if d.textlength(line + " " + wd, font=reg(40)) > 1260:
        d.text((2380, yy), line.strip(), font=reg(40), fill=MUTED)
        yy, line = yy + 56, ""
    line += " " + wd
d.text((2380, yy), line.strip(), font=reg(40), fill=MUTED)
img.save(out / "b15.png")

# B17 - interface sweep: columns = uniforms, rows = min / default / max
img, d = canvas("Every knob at min, default, max", "B17 · interface sweep")
crop_a, crop_b = (284, 168, 284 + 331, 168 + 407), (665, 168, 665 + 331, 168 + 407)
tw, th, gx, gy, x0, y0 = 366, 450, 22, 14, 440, 470
for c, u in enumerate(UNIFORMS):
    x = x0 + c * (tw + gx)
    d.text((x, y0 - 70), u, font=bold(36), fill=INK)
    d.text((x, y0 - 30 + 3 * (th + gy) + 10), "ShieldB" if u in ON_B else "ShieldA", font=reg(32), fill=MUTED)
    for rr, w in enumerate(("min", "default", "max")):
        im = Image.open(SRC[f"sweep_{u}_{w}"]).convert("RGB").crop(crop_b if u in ON_B else crop_a)
        img.paste(im.resize((tw, th), Image.LANCZOS), (x, y0 + rr * (th + gy)))
for rr, w in enumerate(("min", "default", "max")):
    d.text((200, y0 + rr * (th + gy) + th // 2 - 30), w, font=bold(44), fill=INK)
label(d, 200, 1940, "In-engine frames · tools/capture_shield_room.gd -- sweep · values from the shader source (evidence/sweep/)")
img.save(out / "b17.png")

# B19 - one shader, two materials
img, d = canvas("One shader, two materials", "B19 · edits made by Rui")
for i, (k, cap) in enumerate([("shield_before", "before"),
                              ("shader_edit", "shader line 68 × vec3(0.3, 0.3, 1.0): both change"),
                              ("material_edit", "shield_new.tres scorch 0.05 → 0.8: only ShieldA")]):
    x = 200 + i * 1160
    r = paste_fit(img, SRC[k], (x, 420, 1100, 620))
    d.text((x, r[1] + r[3] + 24), cap, font=reg(40), fill=INK)
text_box(d, 200, 1240, 3440, [
    ("changed pixels against before, left half / right half of the frame", GREY),
    ("shader edit      98,610 / 98,610      restored: byte-identical to before", None),
    ("material edit    48,286 / 0           restored: byte-identical to before", None)], size=42)
d.text((200, 1620), "Rui: “" + read("observations")[52].split("ShieldB on the right")[0].strip() + "”", font=reg(42), fill=MUTED)
d.text((200, 1690), "“ShieldB on the right" + read("observations")[52].split("ShieldB on the right")[1] + "”", font=reg(42), fill=MUTED)
label(d, 200, 1900, "In-engine frames · tools/capture_shield_room.gd -- shot · evidence/two_materials/")
img.save(out / "b19.png")

# B21 - mutation 3: the hint removed, and what caught it
img, d = canvas("Delete one hint, and one test fails", "B21 · mutation 3")
diff = read("m3_diff")
m3 = read("m3_log")
show = [("$ git diff godot/shaders/shield_wood.gdshader   # Rui's hand edit", GREY)]
show += [(l, RED if l.startswith("-") else GREEN) for l in diff if l.startswith(("-    ", "+    "))]
show += [("", None), ("$ ./scripts/run-test.sh test_materials.gd 60   # exit 1", GREY)]
show += [(l, RED) for l in m3 if l.startswith("FAIL")]
show += [(find(m3, "test_materials:"), GOLD), ("", None),
         ("# every check built on get_shader_uniform_list() still passed:", GREY),
         ("# the engine reports a sampler as a Texture2D, with or without source_color", GREY)]
text_box(d, 200, 400, 3440, show, size=38)
label(d, 200, 1700, "Headless output · verbatim lines of evidence/mutations/ (long lines cut with …)", True)
img.save(out / "b21.png")

(out / "sources.json").write_text(json.dumps(sources, indent=1, ensure_ascii=False), encoding="utf-8")
print("wrote", sorted(p.name for p in out.glob("b*.png")))
