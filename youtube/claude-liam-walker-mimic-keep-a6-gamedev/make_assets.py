"""Compose the 4K still images for the A6 film (Claude, 2026-11-08).

Every picture is a committed fixture-capture frame from the repository's captures/ (Movie Maker output of the
preview scenes, run by Rui), cropped around the scarecrow and enlarged with nearest-neighbour; every quoted line
is copied verbatim from TUNING.md. Nothing is redrawn. Each panel carries a burned-in provenance label. SHA-256 of
every source is written to assets/sources.json.

    F:/7270/film-env/Scripts/python.exe make_assets.py
"""
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

REEL = Path(__file__).resolve().parent
REPO = Path("C:/Users/18500/Desktop/7270/Assignment5/walker-mimic-keep-rui-sun")
CAP = REPO / "captures"
W, H = 3840, 2160
GROUND, INK, MUTED, ACCENT = (250, 249, 245), (20, 20, 19), (94, 93, 89), (217, 119, 87)
F = "C:/Windows/Fonts/"
bold = lambda s: ImageFont.truetype(F + "segoeuib.ttf", s)
reg = lambda s: ImageFont.truetype(F + "segoeui.ttf", s)
cjk = lambda s: ImageFont.truetype(F + "msyh.ttc", s)
GOLD = (255, 207, 90)

A_FR = [10, 12, 15, 20, 30, 50]
B_FR = [10, 20, 40, 70, 100, 130, 170]
A_BOX = (580, 470, 700, 590)
B_BOX = (575, 440, 705, 590)
used = {}


def frame(set_dir, n):
    p = CAP / set_dir / f"frame{n:08d}.png"
    used[f"{set_dir}/{p.name}"] = {"path": str(p.relative_to(REPO)), "sha256": hashlib.sha256(p.read_bytes()).hexdigest()}
    return p


def canvas(title, kicker):
    img = Image.new("RGB", (W, H), GROUND)
    d = ImageDraw.Draw(img)
    d.text((200, 130), kicker.upper(), font=bold(54), fill=ACCENT)
    d.text((200, 200), title, font=bold(100), fill=INK)
    return img, d


def label(d, x, y, text):
    f = reg(44)
    w = d.textlength(text, font=f)
    d.rounded_rectangle([x, y, x + w + 64, y + 80], radius=20, fill=(12, 12, 18), outline=(154, 163, 191), width=4)
    d.text((x + 32, y + 12), text, font=f, fill=(244, 241, 232))


def strip(img, d, set_dir, frames, box, y, row_label, size):
    x0, gap = 200, 24
    for i, n in enumerate(frames):
        im = Image.open(frame(set_dir, n)).convert("RGB").crop(box)
        im = im.resize((size, round(size * im.height / im.width)), Image.NEAREST)
        x = x0 + i * (size + gap)
        img.paste(im, (x, y))
        d.rectangle([x - 3, y - 3, x + im.width + 2, y + im.height + 2], outline=(200, 198, 190), width=3)
        t = f"frame {n}"
        d.text((x + (size - d.textlength(t, font=bold(36))) / 2, y + im.height + 8), t, font=bold(36), fill=INK)
    d.text((x0 + len(frames) * (size + gap) + 10, y + 20), row_label, font=bold(44), fill=MUTED)
    return y + round(size * (box[3] - box[1]) / (box[2] - box[0])) + 60


def lines(d, x, y, items, width_font=46):
    for kind, text in items:
        if kind == "zh":
            d.text((x, y), text, font=cjk(46), fill=INK)
            y += 70
        elif kind == "h":
            d.text((x, y), text, font=bold(46), fill=INK)
            y += 66
        else:
            d.text((x, y), text, font=reg(width_font), fill=MUTED if kind == "en" else INK)
            y += 62
    return y


out = REEL / "assets"
out.mkdir(exist_ok=True)

# B06 - Effect A first strip (r0) and Rui's first verdict
img, d = canvas("Effect A, first strip: r0", "B06 · first look before Claude reads")
y = strip(img, d, "impact_burst/r0", A_FR, A_BOX, 400, "r0", 520)
lines(d, 200, y + 10, [
    ("h", "Rui, preview windowed at 1280×720, before Claude read anything (TUNING.md):"),
    ("t", "\"…when the flash was flashing, I didn't notice the grass clippings at all, I only noticed the rest of the"),
    ("t", "grass clippings after the flash was over … I couldn't notice the whole movement of the grass clippings.\""),
    ("h", "Claude's reading of the strip:"),
    ("en", "straw's first ramp colour #e8c46b ≈ scarecrow body #e9c46a; the straw stays above the hit point all its life"),
])
label(d, 200, 1960, "Fixture capture · impact_burst_preview.tscn, fixed seed 7270/7370 · hits at frames 10 and 28 · crops 120×120, enlarged")
img.save(out / "b06.png")

# B07 - Effect A revision r1
img, d = canvas("Effect A, revision r1: flash alpha 1.0 / 0.9 → 0.6 / 0.55", "B07 · tuning")
y = strip(img, d, "impact_burst/r0-tinted", A_FR, A_BOX, 380, "before", 440)
y = strip(img, d, "impact_burst/r1", A_FR, A_BOX, y + 10, "after", 440)
lines(d, 200, y, [
    ("zh", "Rui，游戏中：命中时现有较亮的闪光出现…我任务闪光开始时还是有一点亮，可能会阻碍观察到草屑飞出，可以试着调暗一点"),
    ("en", "in play: the flash's start is still a bit bright and may hide the straw flying out; try it a little darker"),
    ("t", "Prediction: softer yellow, fainter halo on grass.   Comparison: dimmer on grass; on the body clipped at (255, 255, 76)."),
    ("zh", "Rui 的判定：保留 —— 闪光亮度变暗后草屑飞出更明显了，同时视觉观感变好了"),
])
label(d, 200, 1990, "Fixture captures · burning-tinted preview, same seeds · frames 20 and 50 pixel-identical before/after")
img.save(out / "b07.png")

# B11 - Effect B first strip (r0)
img, d = canvas("Effect B, first strip: r0", "B11 · first look before Claude reads")
y = strip(img, d, "burning_embers/r0", B_FR, B_BOX, 400, "r0", 430)
lines(d, 200, y + 10, [
    ("h", "Rui, preview windowed at 1280×720, before Claude read anything (TUNING.md):"),
    ("zh", "我看了燃烧过程了，然绕逐渐变弱的过程不太明显"),
    ("en", "I watched the burning; the gradual weakening is not very noticeable."),
    ("h", "Claude's reading of the strip:"),
    ("en", "embers about 1, 5, 10, 6, 4, 3, 0, as the brief predicts; most sit on the tinted body, where additive yellow clips"),
])
label(d, 200, 1960, "Fixture capture · burning_embers_preview.tscn, fixed seeds · ignite frame 10, burn ends frame 130 · crops enlarged")
img.save(out / "b11.png")

# B12 - Effect B revision r1
img, d = canvas("Effect B, revision r1: embers fade in over 0.27 s", "B12 · tuning")
y = strip(img, d, "burning_embers/r0", B_FR, B_BOX, 380, "before", 380)
y = strip(img, d, "burning_embers/r1", B_FR, B_BOX, y + 10, "after", 380)
lines(d, 200, y, [
    ("zh", "Rui，游戏中：我认为命中光效与燃烧特效有点重叠，可能需要修改一下"),
    ("en", "in play: the hit flash and the burning effect overlap a bit"),
    ("t", "Prediction: a third fewer bright embers.   Comparison: much smaller — 0–25 pixels per frame change by more than 20 levels."),
    ("zh", "Rui 的判定：保留 —— 闪光和余烬现在有了一点区分度了"),
])
label(d, 200, 1990, "Fixture captures · same seeds · the preview has no arrow, so the overlap itself is judged only in play")
img.save(out / "b12.png")


# B15 - what the tests proved: verbatim log lines, the cost script, Rui's GPU reading
def logline(rel, needle):
    q = REPO / rel
    used[rel] = {"path": rel, "sha256": hashlib.sha256(q.read_bytes()).hexdigest()}
    return next(l for l in q.read_text(encoding="utf-8").splitlines() if needle in l)


def box(d, x, y, w, title, rows, size=38):
    f = ImageFont.truetype(F + "consola.ttf", size)
    h = 110 + int(size * 1.5) * len(rows)
    d.rounded_rectangle([x, y, x + w, y + h], radius=24, fill=(30, 30, 34))
    d.text((x + 40, y + 26), title, font=bold(44), fill=GOLD)
    for i, (t, c) in enumerate(rows):
        d.text((x + 40, y + 96 + i * int(size * 1.5)), t, font=f, fill=c)
    return y + h + 40


GREEN, RED, WHITE = (120, 220, 140), (255, 120, 110), (236, 233, 224)
img, d = canvas("What the tests proved, and what they cannot", "B15 · recorded output")
tests = ["test_impact_burst_config", "test_impact_burst_state", "test_burning_embers_config", "test_burning_embers_state",
         "test_rules", "test_input", "test_materials", "normal_map_check"]
y = box(d, 200, 360, 1700, "Headless tests at 60 fps (logs/)",
        [(logline(f"logs/{t}_60fps.log", "passed,"), GREEN) for t in tests], 36)
y = box(d, 200, y, 1700, "Mutations (evidence/a6-mutations/)", [
    (logline("evidence/a6-mutations/m1_godot3_name_test_impact_burst_config_60fps.log", "FAIL"), RED),
    (logline("evidence/a6-mutations/m2_value_drift_test_impact_burst_config_60fps.log", "FAIL"), RED),
    (logline("evidence/a6-mutations/b_m1_godot3_name_test_burning_embers_config_60fps.log", "FAIL"), RED),
    (logline("evidence/a6-mutations/b_m2_value_drift_test_burning_embers_config_60fps.log", "FAIL"), RED)], 32)
cost = "evidence/a6-cost/cost_effects_60fps_claude_rerun.log"
yy = box(d, 2000, 360, 1640, "Headless CPU, frame µs (cost_effects.gd)",
         [(logline(cost, k)[:34], WHITE) for k in ("empty ", "off ", "A  ", "B  ")] +
         [("TIME_PROCESS reads 0.0000 in every case", MUTED)], 36)
yy = box(d, 2000, yy, 1640, "GPU time, Visual Profiler (Rui, RTX 3070 Laptop)", [
    ("before any effect:        0.06–0.07 ms", WHITE),
    ("several burning + bursts: 0.06–0.07 ms", WHITE),
    ("budget A 0.25 · B 0.60 · total 0.85 ms", GREEN)], 36)
yy = box(d, 2000, yy, 1640, "No headless run shows", [
    ("particles drawn, or frozen on pause", WHITE), ("tails surviving the reparent", WHITE),
    ("the flash merging with the embers", WHITE)], 36)
label(d, 200, 1990, "Recorded output · lines copied verbatim from committed logs · GPU reading from TEST-REPORT.md A6.7")
img.save(out / "b15.png")

(out / "sources.json").write_text(json.dumps(used, indent=1), encoding="utf-8")
print("5 stills,", len(used), "source frames")
