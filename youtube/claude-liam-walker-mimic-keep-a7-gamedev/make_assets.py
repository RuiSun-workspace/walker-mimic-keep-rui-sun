"""Compose the 4K still images for the A7 film (Claude, 2026-11-22).

Every picture is a committed file from the repository: the sheet PNG as the game loads it, or a committed
fixture-capture frame (Movie Maker output of the preview scenes, run by Rui), cropped and enlarged with
nearest-neighbour. Every quoted line is copied verbatim from a committed log, TUNING.md or TEST-REPORT.md. Nothing
is redrawn; grid lines and boxes are drawn over the pictures as annotations. Each panel carries a burned-in
provenance label. SHA-256 of every source is written to assets/sources.json.

    F:/7270/film-env/Scripts/python.exe make_assets.py
"""
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

REEL = Path(__file__).resolve().parent
REPO = Path("C:/Users/18500/Desktop/7270/Assignment5/walker-mimic-keep-rui-sun")
W, H = 3840, 2160
GROUND, INK, MUTED, ACCENT = (250, 249, 245), (20, 20, 19), (94, 93, 89), (217, 119, 87)
F = "C:/Windows/Fonts/"
bold = lambda s: ImageFont.truetype(F + "segoeuib.ttf", s)
reg = lambda s: ImageFont.truetype(F + "segoeui.ttf", s)
cjk = lambda s: ImageFont.truetype(F + "msyh.ttc", s)
mono = lambda s: ImageFont.truetype(F + "consola.ttf", s)
GOLD, GREEN, RED, WHITE = (255, 207, 90), (120, 220, 140), (255, 120, 110), (236, 233, 224)
SHOOT_BOX = (590, 520, 690, 610)       # the archer, as in captures/shoot/sheets/
WALK_BOX = (590, 320, 690, 440)        # the scarecrow held at (640, 360), as in captures/walk/sheets/
used = {}


def src(rel):
    p = REPO / rel
    used[rel] = {"path": rel, "sha256": hashlib.sha256(p.read_bytes()).hexdigest()}
    return p


def logline(rel, pred):
    lines = src(rel).read_text(encoding="utf-8").splitlines()
    hit = [l for l in lines if pred(l)]
    assert hit, (rel, pred)
    return hit[0].rstrip()


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


def tile(img, d, rel, box, x, y, size, caption):
    im = Image.open(src(rel)).convert("RGB").crop(box)
    im = im.resize((size, round(size * im.height / im.width)), Image.NEAREST)
    img.paste(im, (x, y))
    d.rectangle([x - 3, y - 3, x + im.width + 2, y + im.height + 2], outline=(200, 198, 190), width=3)
    d.text((x + (size - d.textlength(caption, font=bold(38))) / 2, y + im.height + 10), caption, font=bold(38), fill=INK)
    return y + im.height + 70


def text_lines(d, x, y, items):
    for kind, t in items:
        if kind == "zh":
            d.text((x, y), t, font=cjk(46), fill=INK); y += 72
        elif kind == "h":
            d.text((x, y), t, font=bold(46), fill=INK); y += 68
        else:
            d.text((x, y), t, font=reg(44), fill=MUTED if kind == "en" else INK); y += 62
    return y


def box(d, x, y, w, title, rows, size=34):
    step = int(size * 1.5)
    h = 110 + step * len(rows)
    d.rounded_rectangle([x, y, x + w, y + h], radius=24, fill=(30, 30, 34))
    d.text((x + 40, y + 26), title, font=bold(44), fill=GOLD)
    for i, (t, c) in enumerate(rows):
        d.text((x + 40, y + 96 + i * step), t, font=mono(size), fill=c)
    return y + h + 36


def pv(rel, frame):
    """The shoot_preview log line whose first field is the movie frame."""
    return logline(rel, lambda l, f=frame: l.startswith(f"{f} | "))


def short(line):
    """frame | tick | node | play_pos | release_window | armed | bow deg | arrows | fired."""
    c = [s.strip() for s in line.split("|")]
    return f"f{c[0]} tick {c[2]} · {c[3]} @{c[4]} · release_window {c[5]} · bow {c[7]}° · arrows {c[11]} · {c[12]}"


out = REEL / "assets"
out.mkdir(exist_ok=True)

# B05 - the sheet, its 4x1 slicing, and the walk strip's cells
img, d = canvas("The sheet, sliced 4 × 1: cell = frame number", "B05 · the sheet and the walk strip")
sheet = Image.open(src("godot/assets/sprites/scarecrow_walk.png")).convert("RGBA")
k = 7
big = sheet.resize((sheet.width * k, sheet.height * k), Image.NEAREST)
bg = Image.new("RGBA", big.size, (226, 224, 216, 255))
bg.alpha_composite(big)
SY = 450
img.paste(bg.convert("RGB"), (200, SY))
cw = 64 * k
for i in range(5):
    d.line([200 + i * cw, SY, 200 + i * cw, SY + big.height], fill=ACCENT, width=6)
d.rectangle([200, SY, 200 + big.width, SY + big.height], outline=ACCENT, width=6)
for i in range(4):
    d.text((200 + i * cw + 150, 380), f"frame {i}", font=bold(48), fill=ACCENT)
d.text((200, SY + big.height + 20), "godot/assets/sprites/scarecrow_walk.png · 256×80 · cells 64×80 · "
       "hframes = 4, vframes = 1 (scarecrow.tscn:63) · written by make_sprites.gd", font=reg(40), fill=MUTED)
y0 = 1120
for i, (fr, cell) in enumerate([(17, 0), (20, 1), (24, 2), (28, 3)]):
    tile(img, d, f"captures/walk/r0/frame{fr:08d}.png", WALK_BOX, 200 + i * 470, y0, 420, f"cell {cell} · frame {fr}")
text_lines(d, 2150, y0 + 10, [
    ("h", "Registration, measured (Claude):"),
    ("t", "pole foot x = 638–641 px on every frame"),
    ("t", "bottom y = 394 / 391 / 395 / 391"),
    ("t", "= 0 / −3 / +1 / −3 px (brief §3)"),
    ("t", "screen origin (640, 360) on all 100 lines"),
    ("h", "Rui, on the strip:"),
    ("zh", "没有漂移"),
    ("en", "\"No drift.\""),
])
src("evidence/a7-probes/walk_foot_position.out.txt")
label(d, 200, 1940, "Fixture capture · walk_preview.tscn, camera follows the scarecrow · Movie Maker 30 fps · crops 100×120, enlarged")
img.save(out / "b05.png")

# B06 - mutation 1a: a property that does not exist
img, d = canvas("Mutation 1a: a property that does not exist", "B06 · why it fails silently")
diff = src("evidence/a7-mutations/m1a.diff").read_text(encoding="utf-8").splitlines()
rows = [(l, RED if l.startswith("-") else GREEN) for l in diff if l.startswith(("-tracks", "+tracks"))]
y = box(d, 200, 380, 3440, "The change, in the clip only (evidence/a7-mutations/m1a.diff)", rows, 54)
m1a = "evidence/a7-mutations/m1a_walk_subname.log"
log = src(m1a).read_text(encoding="utf-8").splitlines()
errs = [l for l in log if "ERROR" in l]
y = box(d, 200, y, 3440, "The read-back (test_scarecrow_walk_readback.gd, 60 fps)", [
    (logline(m1a, lambda l: l.startswith("FAIL walk track 0 path")), RED),
    (logline(m1a, lambda l: l.startswith("FAIL walk track property")), RED),
    (logline(m1a, lambda l: l.startswith("RESULT")), RED),
    (f"ERROR lines in the same log while the scene loaded: {len(errs)}", WHITE)], 54)
text_lines(d, 200, y + 10, [
    ("h", "No error while the scene loads: the path names nothing real, and nothing says so."),
    ("h", "Only a read-back that checks the property exists sees it."),
])
label(d, 200, 1940, "Recorded output · lines copied verbatim from committed mutation evidence (worktree ../a7-mutate, removed after)")
img.save(out / "b06.png")

# B09 - the r1 strip at each phase boundary, with the log line for each frame
img, d = canvas("Strip r1 at each phase boundary", "B09 · fixture strip, read against the phase table")
r1 = "logs/shoot_preview_r1.log"
cols = [(10, "trigger · clip 0"), (18, "full draw · clip 8"), (19, "arrow out · clip 9"), (25, "idle · clip 15")]
for i, (fr, cap) in enumerate(cols):
    tile(img, d, f"captures/shoot/r1/frame{fr:08d}.png", SHOOT_BOX, 200 + i * 880, 380, 800, f"frame {fr} · {cap}")
y = box(d, 200, 1290, 3440, "logs/shoot_preview_r1.log, the same windowed run (frame | tick | node | play | release_window …)",
        [(short(pv(r1, fr)), GOLD if fr in (18, 19) else WHITE) for fr, _ in cols], 36)
label(d, 200, 1940, "Fixture capture · shoot_preview.tscn · Movie Maker 30 fps, run by Rui · target placed on tick 20 · crops 100×90, enlarged")
img.save(out / "b09.png")

# B10 - the revision: r0 vs r1, observation, prediction, comparison, verdicts
img, d = canvas("Revision r1: full-draw key −8° → −16°", "B10 · tuning, driven by Rui's eyes")
tile(img, d, "captures/shoot/r0/frame00000018.png", SHOOT_BOX, 200, 360, 780, "r0 · frame 18 · −8°")
tile(img, d, "captures/shoot/r1/frame00000018.png", SHOOT_BOX, 1060, 360, 780, "r1 · frame 18 · −16°")
tile(img, d, "captures/shoot/r0/frame00000019.png", SHOOT_BOX, 1920, 360, 780, "r0 · frame 19")
tile(img, d, "captures/shoot/r1/frame00000019.png", SHOOT_BOX, 2780, 360, 780, "r1 · frame 19")
src("TUNING.md")
text_lines(d, 200, 1140, [
    ("h", "Rui, watching first (r0):"),
    ("zh", "感觉拉弓的幅度有点小，在正常状态下难以看清三个阶段，箭出来的时机没问题"),
    ("en", "the draw's movement feels a bit small; at normal speed the three phases are hard to tell apart; the arrow's moment is fine"),
    ("t", "Agent's prediction: pivot_rot_deg −0.25 … −12.25, −16.00 on clip 1–8; everything else as r0; frames 9, 10, 25 identical."),
    ("t", "Comparison (Claude): every logged angle as predicted; archer pixels as predicted; frame 25 missed — unseeded particles."),
    ("h", "Rui's verdicts:"),
    ("zh", "预览：录完了，先这样吧，如果不调整攻速的话很难完全区分三个阶段了，压到边缘我认为可以接受"),
    ("en", "fixture: leave it here; without changing the fire rate the three phases cannot be fully told apart; the overlap is acceptable"),
    ("zh", "游戏中：暂停和恢复后动画接得上，能明显看出拉弓和射箭后回正还有弓不动三个阶段"),
    ("en", "in play: pause and resume continue correctly; the draw, the return to upright and the still bow are clearly three phases"),
])
label(d, 200, 1940, "Fixture captures · shoot_preview.tscn r0 and r1, same trigger tick · words from TUNING.md")
img.save(out / "b10.png")

# B12 - two clocks, measured: the key and the read, one tick apart
img, d = canvas("Two clocks, measured: one physics tick", "B12 · the key and the read")
tile(img, d, "captures/shoot/r1/frame00000018.png", SHOOT_BOX, 200, 380, 1000, "frame 18 · release_window true")
tile(img, d, "captures/shoot/r1/frame00000019.png", SHOOT_BOX, 1260, 380, 1000, "frame 19 · fired@tick38")
y = box(d, 2340, 380, 1300, "logs/shoot_preview_r1.log", [
    ("frame | pframe | tick | node | play |", MUTED), ("  release_window | armed | bow …", MUTED),
    (" | ".join(s.strip() for s in pv(r1, 18).split("|")[:8]), GOLD),
    (" | ".join(s.strip() for s in pv(r1, 19).split("|")[:8]), GOLD),
    ("… arrows " + pv(r1, 19).split("|")[11].strip() + " | " + pv(r1, 19).split("|")[12].strip(), GOLD)], 36)
text_lines(d, 2340, y + 10, [
    ("t", "tree writes release_window: tick 37"),
    ("t", "archer reads it, arrow out: tick 38"),
    ("h", "1 tick = 1/60 s ≈ 0.0167 s"),
    ("en", "parent archer runs before its child tree;"),
    ("en", "the 0.3 s draw lead already includes it"),
])
label(d, 200, 1940, "Fixture capture · frames and log lines from the same windowed Movie Maker run (Rui) · crops enlarged")
img.save(out / "b12.png")

# B16 - what the tests proved, the mutations, and what no headless run can show
img, d = canvas("What the tests proved, and what they cannot", "B16 · recorded output")
walk_pass = sum(1 for l in src("logs/test_scarecrow_walk_readback_60fps.log").read_text(encoding="utf-8").splitlines() if l.startswith("PASS"))
res = lambda t: logline(f"logs/{t}_60fps.log", lambda l: l.startswith("RESULT"))
y = box(d, 200, 380, 2280, "Headless suites at 60 fps (logs/, rerun at 4d2e0a8)", [
    ("walk read-back   " + res("test_scarecrow_walk_readback") + f" · {walk_pass} PASS lines", GREEN),
    ("shot read-back   " + res("test_archer_shot_readback"), GREEN),
    (res("test_archer_state_machine"), GREEN),
    (res("test_archer_edges"), GREEN),
    (res("test_pins_a7"), GREEN)], 42)
mut = lambda f: logline(f"evidence/a7-mutations/{f}", lambda l: l.startswith("RESULT"))
y = box(d, 200, y, 2280, "Mutations, each in a git worktree (Step 6, evidence/a7-mutations/)", [
    ("1a Sprite:frame → frames      " + mut("m1a_walk_subname.log"), RED),
    ("1b String:scale → scal        " + mut("m1b_rig_subname.log"), RED),
    ("2  walk LOOP_LINEAR → NONE    " + mut("m2_walk_loop_none.log"), RED),
    ("3  frame key 3 → 4 (= 4 × 1)  " + mut("m3_frame_out_of_sheet.log"), RED),
    ("4  empty .godot, --import     " + mut("m4_test_archer_shot_readback.log"), WHITE),
    ("   keyed .tscn text: nothing imported to lose", MUTED)], 42)
box(d, 2560, 380, 1080, "No headless run shows", [
    ("whether the motion reads", WHITE), ("whether the cycle wraps cleanly", WHITE),
    ("whether the shot feels committed", WHITE), ("a frame at all: headless", WHITE),
    ("  draws nothing", WHITE), ("→ fixture strips (Rui's", MUTED), ("  captures) and Rui's eyes", MUTED),
    ("  in the running game", MUTED)], 42)
src("TEST-REPORT.md")
label(d, 200, 1940, "Recorded output · lines copied verbatim from committed logs · suites rerun at 4d2e0a8 (21 runs, exit 0), mutations from Step 6 · TEST-REPORT.md A7.4, A7.6")
img.save(out / "b16.png")

(out / "sources.json").write_text(json.dumps(used, indent=1), encoding="utf-8")
print("6 stills,", len(used), "sources")
