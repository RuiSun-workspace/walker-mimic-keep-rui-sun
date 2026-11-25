"""Draw the pitch film's 14 picture beats at 3840x2160 (Claude, 2026-11-24).

Two kinds of picture, and every one says which it is in its burned label:
- REAL / REAL STILL: an unedited file, log line or capture frame read from the repository (asserted present, so
  the picture cannot drift from the source). Frames are cropped and scaled with nearest-neighbour only.
- CONSTRUCTED: a plain drawing of something proposed. The only game art in these drawings is the game's own
  code-drawn sprites (godot/assets/sprites, made by godot/tools/make_sprites.gd), used as icons; any tint on
  them (chilled, stunned) is a mock-up and is labelled as one. No numbers are invented: proposed values are
  shown as words or blanks.

    F:/7270/film-env/Scripts/python.exe pitch/build/make_stills.py  ->  REEL/assets/<beat>.png + REEL/media/<BEAT>.png
"""
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

REPO = Path("C:/Users/18500/Desktop/7270/Assignment5/walker-mimic-keep-rui-sun")
PITCH = REPO / "pitch"
REEL = Path("F:/7270/reels/mimic-keep-final-pitch")
W, H = 3840, 2160
BG, INK, DIM, GHOST, CARD = (250, 249, 245), (61, 57, 41), (120, 118, 110), (200, 195, 182), (240, 236, 226)
TERRA, DARK, CODEBG = (217, 119, 87), (34, 31, 27), (30, 28, 26)
FIRE, ICE, BOLT = (226, 110, 40), (70, 150, 220), (220, 180, 30)
F = "C:/Windows/Fonts/"


def font(name, size):
    return ImageFont.truetype(F + name, size)


SERIF, SERIFB = (lambda s: font("georgia.ttf", s)), (lambda s: font("georgiab.ttf", s))
SANS, SANSB = (lambda s: font("segoeui.ttf", s)), (lambda s: font("segoeuib.ttf", s))
MONO, CJK = (lambda s: font("consola.ttf", s)), (lambda s: font("msyh.ttc", s))


def repo_lines(rel, a, b):
    lines = (REPO / rel).read_text(encoding="utf-8").splitlines()
    return lines[a - 1:b]


def repo_has(rel, text):
    assert text in (REPO / rel).read_text(encoding="utf-8"), (rel, text)
    return text


def sprite(name, scale):
    im = Image.open(REPO / "godot/assets/sprites" / name).convert("RGBA")
    return im.resize((im.width * scale, im.height * scale), Image.NEAREST)


def tinted(im, rgb, amount):
    """Mock-up tint for a proposed status (chilled, stunned). Labelled CONSTRUCTED wherever it is used."""
    out = im.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            if a:
                px[x, y] = (int(r + (rgb[0] - r) * amount), int(g + (rgb[1] - g) * amount), int(b + (rgb[2] - b) * amount), a)
    return out


class Canvas:
    def __init__(self, title, kicker):
        self.im = Image.new("RGB", (W, H), BG)
        self.d = ImageDraw.Draw(self.im)
        self.d.text((200, 150), kicker.upper(), font=SANSB(54), fill=TERRA)
        self.d.text((200, 230), title, font=SERIFB(118), fill=INK)

    def text(self, xy, s, f, fill=INK, anchor="la"):
        self.d.text(xy, s, font=f, fill=fill, anchor=anchor)

    def ctext(self, cx, y, s, f, fill=INK):
        self.d.text((cx, y), s, font=f, fill=fill, anchor="ma")

    def box(self, x0, y0, x1, y1, fill=CARD, outline=INK, width=8, r=36):
        self.d.rounded_rectangle([x0, y0, x1, y1], radius=r, fill=fill, outline=outline, width=width)

    def paste(self, im, x, y):
        self.im.paste(im, (int(x), int(y)), im if im.mode == "RGBA" else None)

    def arrow(self, x0, y0, x1, y1, fill=INK, width=14):
        self.d.line([x0, y0, x1, y1], fill=fill, width=width)
        import math
        a = math.atan2(y1 - y0, x1 - x0)
        for s in (-1, 1):
            self.d.line([x1, y1, x1 - 60 * math.cos(a + s * 0.45), y1 - 60 * math.sin(a + s * 0.45)], fill=fill, width=width)

    def label(self, main):
        f = SANSB(60)
        w = self.d.textlength(main, font=f)
        x0, bh = 240, 120
        y0 = 2012 - bh
        self.d.rectangle([x0, y0, x0 + w + 96, y0 + bh], fill=DARK)
        self.d.text((x0 + 48, y0 + 22), main, font=f, fill=(244, 241, 232))
        return [round(x0 / W, 3), round(y0 / H, 3), round((x0 + w + 96) / W, 3), round((y0 + bh) / H, 3)]


def badge(c, cx, cy, kind, r=150, label=True):
    col = {"fire": FIRE, "ice": ICE, "lightning": BOLT}[kind]
    c.d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=col, outline=INK, width=10)
    s = r / 150
    if kind == "fire":
        c.d.polygon([(cx, cy - 95 * s), (cx + 62 * s, cy + 10 * s), (cx + 40 * s, cy + 80 * s), (cx - 40 * s, cy + 80 * s),
                     (cx - 62 * s, cy + 10 * s)], fill=(255, 236, 200), outline=INK)
    elif kind == "ice":
        import math
        for k in range(6):
            a = k * math.pi / 3
            c.d.line([cx, cy, cx + 95 * s * math.cos(a), cy + 95 * s * math.sin(a)], fill=(240, 248, 255), width=int(16 * s))
    else:
        c.d.polygon([(cx + 20 * s, cy - 100 * s), (cx - 55 * s, cy + 15 * s), (cx - 5 * s, cy + 15 * s), (cx - 25 * s, cy + 100 * s),
                     (cx + 55 * s, cy - 20 * s), (cx + 5 * s, cy - 20 * s)], fill=(255, 250, 220), outline=INK)
    if label:
        c.ctext(cx, cy + r + 30, kind, SANSB(64))


def code_panel(c, x0, y0, x1, lines, first, hl=(), size=58, title=None):
    lh = int(size * 1.45)
    y1 = y0 + 70 + lh * len(lines) + (90 if title else 40)
    c.box(x0, y0, x1, y1, fill=CODEBG, outline=INK, width=8, r=28)
    y = y0 + 40
    if title:
        c.text((x0 + 60, y), title, SANSB(50), fill=(200, 196, 186))
        y += 90
    for i, ln in enumerate(lines):
        n = first + i
        if n in hl:
            c.d.rectangle([x0 + 20, y - 8, x1 - 20, y + lh - 14], fill=(70, 58, 44))
        c.text((x0 + 60, y), f"{n:>3}", MONO(size), fill=(130, 126, 116))
        f = CJK(size - 6) if any(ord(ch) > 0x2E80 for ch in ln) else MONO(size)
        c.text((x0 + 60 + size * 2.6, y), ln.replace("\t", "    "), f, fill=(236, 232, 222))
        y += lh
    return y1


SAFE = (192, 108, 3648, 2052)    # Gate V title-safe area at 3840x2160 (layout.ts x96-1824, y54-1026 at 1080p)


def check_safe(im, bid):
    import numpy as np
    a = np.asarray(im).astype(int)
    ink = np.abs(a - np.array(BG)).max(axis=2) > 28
    ys, xs = np.nonzero(ink)
    x0, y0, x1, y1 = xs.min(), ys.min(), xs.max(), ys.max()
    assert x0 >= SAFE[0] and y0 >= SAFE[1] and x1 <= SAFE[2] and y1 <= SAFE[3], (bid, "outside title-safe", (x0, y0, x1, y1))


def save(c, bid, label):
    box = c.label(label)
    check_safe(c.im, bid)
    p = REEL / "assets" / f"{bid.lower()}.png"
    p.parent.mkdir(parents=True, exist_ok=True)
    c.im.save(p)
    (REEL / "media").mkdir(exist_ok=True)
    c.im.save(REEL / "media" / f"{bid}.png")
    return box


def enemy_slot(c, cx, cy, text):
    c.d.rounded_rectangle([cx - 120, cy - 170, cx + 120, cy + 170], radius=60, fill=CARD, outline=DIM, width=8)
    c.ctext(cx, cy - 80, "?", SERIFB(170), fill=DIM)
    c.ctext(cx, cy + 200, text, SANS(52), fill=INK)


# ---------------------------------------------------------------------------------------------------------------
def b01(label):
    c = Canvas("Arrows that carry an element", "the project · one sentence")
    crow = sprite("scarecrow.png", 6)
    arrow = sprite("arrow.png", 8).rotate(-90, expand=True)
    for i, k in enumerate(("fire", "ice", "lightning")):
        badge(c, 700 + i * 520, 760, k, r=170)
    c.paste(arrow, 760, 1250)
    c.arrow(1180, 1310, 1520, 1310)
    c.paste(crow, 2000, 980)
    c.ctext(2000 + crow.width // 2, 1440, "scarecrow (exists)", SANS(52))
    enemy_slot(c, 2850, 1150, "new enemy")
    enemy_slot(c, 3420, 1150, "new enemy")
    c.ctext(2000 + crow.width // 2, 1560, "each enemy takes different damage from each element", SERIF(64))
    return save(c, "B01", label)


def b02(label):
    c = Canvas("What exists when it is done", "the artifact")
    xs = [(260, 1260), (1420, 2420), (2580, 3580)]
    names = ["TITLE", "ONE LEVEL", "END"]
    for (x0, x1), n in zip(xs, names):
        c.box(x0, 620, x1, 1240, fill=CARD, outline=INK, width=10)
        c.ctext((x0 + x1) // 2, 880, n, SANSB(96))
    c.arrow(1270, 930, 1410, 930)
    c.arrow(2430, 930, 2570, 930)
    c.d.arc([1700, 1300, 2140, 1640], start=300, end=240, fill=INK, width=14)
    c.d.line([1920, 1240, 1920, 1300], fill=INK, width=14)
    c.ctext(1920, 1680, "ENDLESS MODE · until the gate falls", SANSB(70))
    c.ctext(1920, 470, "a Windows desktop build", SERIF(72), fill=DIM)
    return save(c, "B02", label)


def b04(label):
    c = Canvas("Two reactions, first version", "the plan")
    crow = sprite("scarecrow.png", 5)
    badge(c, 560, 820, "fire", r=140)
    c.text((760, 760), "+", SERIFB(160))
    c.paste(tinted(crow, ICE, 0.55), 950, 600)
    c.text((1260, 760), "=", SERIFB(160))
    c.text((1430, 700), "extra damage", SERIFB(110), fill=INK)
    c.text((1430, 850), "fire on a chilled enemy", SANS(60), fill=DIM)
    badge(c, 560, 1450, "ice", r=140)
    c.text((760, 1390), "+", SERIFB(160))
    badge(c, 1110, 1450, "lightning", r=140)
    c.text((1300, 1390), "=", SERIFB(160))
    c.paste(tinted(crow, (150, 150, 170), 0.45), 1480, 1230)
    c.text((1850, 1330), "stun", SERIFB(110), fill=INK)
    c.text((1850, 1480), "the enemy stops in place", SANS(60), fill=DIM)
    c.box(2900, 620, 3620, 1700, fill=CARD, outline=DIM, width=6)
    c.ctext(3260, 700, "numbers", SANSB(64), fill=INK)
    for i, t in enumerate(("not set yet", "chosen by tests", "and playtests")):
        c.ctext(3260, 860 + i * 120, t, SANS(60), fill=DIM)
    c.ctext(3260, 1300, "mock-up tints:", SANS(50), fill=DIM)
    c.ctext(3260, 1380, "blue = chilled", SANS(50), fill=DIM)
    c.ctext(3260, 1460, "grey = stunned", SANS(50), fill=DIM)
    return save(c, "B04", label)


def b05(label):
    c = Canvas("The level-up choice depends on the enemies", "why care")
    cards = [("+ damage", None, True), ("ICE", "ice", False), ("LIGHTNING", "lightning", False)]
    for i, (t, k, grey) in enumerate(cards):
        x0 = 300 + i * 760
        hl = (k == "lightning")
        c.box(x0, 620, x0 + 620, 1500, fill=CARD, outline=(TERRA if hl else (GHOST if grey else INK)), width=(18 if hl else 8))
        if k:
            badge(c, x0 + 310, 950, k, r=150, label=False)
        else:
            c.ctext(x0 + 310, 880, "+%", SERIFB(180), fill=GHOST)
        c.ctext(x0 + 310, 1250, t, SANSB(72), fill=(GHOST if grey else INK))
    c.text((2700, 640), "coming next:", SANS(64), fill=DIM)
    crow = sprite("scarecrow.png", 4)
    c.paste(tinted(crow, ICE, 0.55), 2720, 800)
    c.paste(tinted(crow, ICE, 0.55), 3080, 800)
    c.text((2700, 1130), "chilled enemies →", SANSB(64))
    c.text((2700, 1230), "lightning stuns them", SANS(64))
    c.text((2700, 1380), "(illustration, not a rule yet)", SANS(50), fill=DIM)
    return save(c, "B05", label)


def b06(label):
    c = Canvas("Two games Rui has played", "what is different")
    cols = [("Genshin Impact", ["element reactions", "aimed by hand", "open-world action RPG"]),
            ("A WeChat mini-game roguelite", ["name not remembered", "level-up skill choices", "no element reactions"]),
            ("Mimic Keep (proposed)", ["element reactions", "in an auto-fire run", "of a few minutes"])]
    for i, (h, rows) in enumerate(cols):
        x0 = 220 + i * 1160
        c.box(x0, 600, x0 + 1060, 1640, fill=CARD, outline=(TERRA if i == 2 else INK), width=(14 if i == 2 else 8))
        c.text((x0 + 70, 680), h, SERIFB(70) if len(h) < 20 else SERIFB(58))
        for j, r in enumerate(rows):
            c.text((x0 + 70, 900 + j * 190), "· " + r, SANS(66))
    c.ctext(1920, 1700, "text only: no logos or screenshots of other games", SANS(50), fill=DIM)
    return save(c, "B06", label)


def b08(label):
    c = Canvas("What it proves so far", "evidence · tags a5, a6, a7")
    panels = [
        ("evidence/in_play/one_burning.png", (0, 0, 560, 315), "a5 · burning tint shader", "hand-written shader", "65800cd in a5"),
        ("captures/impact_burst/r1/frame00000012.png", (480, 420, 320, 180), "a6 · hit burst + embers", "GPUParticles2D", "53002d1 in a6"),
        ("captures/shoot/r1/frame00000018.png", (560, 515, 160, 90), "a7 · shot state machine", "AnimationTree, full draw", "c6c9b4a in a7"),
    ]
    for i, (rel, crop, h, sub, where) in enumerate(panels):
        im = Image.open(REPO / rel).convert("RGB")
        if crop:
            x, y, w, hh = crop
            im = im.crop((x, y, x + w, y + hh))
        pw = 1060
        im = im.resize((pw, int(im.height * pw / im.width)), Image.NEAREST)
        if im.height > 610:
            im = im.crop((0, (im.height - 610) // 2, pw, (im.height - 610) // 2 + 610))
        x0 = 210 + i * 1180
        c.box(x0 - 10, 590, x0 + pw + 10, 590 + im.height + 20, fill=INK, outline=INK, width=4, r=10)
        c.paste(im, x0, 600)
        c.text((x0, 1270), h, SANSB(66))
        c.text((x0, 1370), sub, SANS(56), fill=DIM)
        c.text((x0, 1450), "frame from " + where, MONO(48), fill=DIM)
    return save(c, "B08", label)


def b09(label):
    c = Canvas("Tests a stranger can rerun", "evidence · headless, mutation, by eye")
    lines = [
        ("logs/test_archer_edges_60fps.log", "RESULT test_archer_edges: 325 passed, 0 failed"),
        ("logs/test_archer_state_machine_60fps.log", "RESULT test_archer_state_machine: 107 passed, 0 failed"),
        ("logs/test_pins_a7_60fps.log", "RESULT test_pins_a7: 38 passed, 0 failed"),
        ("evidence/a7-mutations/m5_bow_frame8_back_to_8deg.log", "RESULT FAIL: 165 passed, 1 failed"),
    ]
    y = 600
    c.box(200, y, 3640, y + 760, fill=CODEBG, outline=INK, width=8, r=28)
    for i, (rel, ln) in enumerate(lines):
        repo_has(rel, ln)
        c.text((280, y + 60 + i * 170), ln, MONO(66), fill=(236, 232, 222) if "FAIL" not in ln else (240, 170, 140))
        c.text((280, y + 140 + i * 170), rel + ("   ← a mutation: the test must fail" if "mutations" in rel else ""), MONO(40), fill=(150, 146, 136))
    gpu = repo_has("TEST-REPORT.md", "frame GPU time 0.06–0.07 ms with and without effects")
    c.text((200, 1450), "GPU (Visual Profiler, RTX 3070 Laptop GPU):", SANSB(62))
    c.text((200, 1550), gpu, MONO(56))
    c.text((200, 1650), "TEST-REPORT.md A6.7 · one whole-frame reading, not a per-effect cost", SANS(48), fill=DIM)
    return save(c, "B09", label)


def b10(label):
    c = Canvas("Numbers, with the reason beside them", "evidence for a technical designer")
    lines = repo_lines("godot/game/tuning.gd", 31, 34)
    assert "SPAWN_INTERVAL_START := 3.0" in lines[2], lines
    code_panel(c, 200, 560, 2200, [ln[:66] + ("…" if len(ln) > 66 else "") for ln in lines], 31, hl=(33,), size=44,
               title="godot/game/tuning.gd · tag a7 (unchanged since mk-prototype)")
    c.text((200, 1210), "Rui's playtest note, then a bot simulation (written by Claude), then the change.", SANS(54), fill=DIM)
    gx, gy, cw, ch = 2380, 640, 330, 190
    c.text((gx, gy - 90), "damage table · will exist", SANSB(60))
    heads = ["", "fire", "ice", "lightning"]
    rows = ["scarecrow", "enemy 2", "enemy 3"]
    for j, hname in enumerate(heads[1:], 1):
        c.ctext(gx + 240 + (j - 1) * cw + cw // 2, gy + 30, hname, SANSB(48))
    for i, r in enumerate(rows):
        y = gy + 120 + i * ch
        c.text((gx, y + 60), r, SANS(48))
        for j in range(3):
            x = gx + 240 + j * cw
            c.d.rectangle([x, y, x + cw - 20, y + ch - 20], fill=CARD, outline=INK, width=6)
            c.ctext(x + (cw - 20) // 2, y + 45, "?", SERIFB(80), fill=DIM)
    c.text((gx, gy + 120 + 3 * ch + 20), "values chosen by tests and playtests", SANS(48), fill=DIM)
    return save(c, "B10", label)


def b11(label):
    c = Canvas("In, out, on purpose", "scope")
    ins = ["3 elements", "2 reactions", "3 enemy types", "level-up cards", "1 level", "endless mode"]
    outs = ["save system", "permanent unlocks", "a second level", "multiplayer"]
    c.box(200, 560, 1880, 1760, fill=CARD, outline=INK, width=10)
    c.box(1960, 560, 3640, 1760, fill=CARD, outline=INK, width=10)
    c.text((280, 610), "IN", SANSB(90))
    c.text((2040, 610), "OUT", SANSB(90))
    for i, t in enumerate(ins):
        y = 790 + i * 155
        c.d.line([300, y + 50, 330, y + 80, 380, y + 20], fill=INK, width=12)
        c.text((420, y), t, SANS(78))
    for i, t in enumerate(outs):
        y = 790 + i * 155
        c.d.line([2065, y + 20, 2115, y + 75], fill=DIM, width=12)
        c.d.line([2115, y + 20, 2065, y + 75], fill=DIM, width=12)
        c.text((2160, y), t, SANS(78), fill=DIM)
    return save(c, "B11", label)


def b12(label):
    c = Canvas("First: ice, on the scarecrow that exists", "the first piece")
    l6 = repo_lines("godot/game/arrow.gd", 6, 6)
    l22 = repo_lines("godot/game/arrow.gd", 20, 23)
    assert 'element: StringName = &"fire"' in l6[0] and "s.hit(Tuning.ARROW_DAMAGE, element)" in l22[2]
    l22 = [ln if len(ln) < 62 else ln[:58] + " …" for ln in l22]
    y = code_panel(c, 200, 560, 2560, l6, 6, hl=(6,), size=56, title="godot/game/arrow.gd · tag a7 (real)")
    code_panel(c, 200, y + 40, 2560, l22, 20, hl=(22,), size=56)
    badge(c, 3000, 820, "fire", r=150, label=False)
    c.ctext(3000, 1000, "fire", SANSB(64))
    c.ctext(3000, 1080, "exists", SANS(52), fill=DIM)
    badge(c, 3400, 820, "ice", r=150, label=False)
    c.ctext(3400, 1000, "ice", SANSB(64))
    c.ctext(3400, 1080, "proposed", SANS(52), fill=DIM)
    c.text((2700, 1400), "will run when:", SANSB(60))
    c.text((2700, 1490), "a headless test checks the", SANS(56))
    c.text((2700, 1570), "reaction damage on an exact tick", SANS(56))
    c.text((2700, 1650), "+ a captured clip in play", SANS(56))
    return save(c, "B12", label)


def b13(label):
    c = Canvas("The risk: one build beats everything", "what could sink it")
    x0, base = 360, 1700
    heights = [520, 600, 470, 560, 1080, 500, 580, 540]
    for i, hgt in enumerate(heights):
        x = x0 + i * 330
        tall = hgt > 1000
        c.d.rectangle([x, base - hgt, x + 230, base], fill=(INK if tall else (170, 165, 152)), outline=INK, width=6)
    c.d.line([x0 - 60, base, x0 + 8 * 330, base], fill=INK, width=10)
    c.text((x0 - 60, base + 30), "builds (illustration, no data)", SANS(54), fill=DIM)
    tx = x0 + 4 * 330 + 115
    c.d.ellipse([tx - 30, base - 1080 - 110, tx + 30, base - 1080 - 50], fill=TERRA)
    c.text((3020, 700), "fix:", SANSB(70))
    for i, t in enumerate(("bot runs report", "time to kill per", "element and enemy,", "and win rate", "per build")):
        c.text((3020, 820 + i * 100), t, SANS(60))
    return save(c, "B13", label)


def b14(label):
    c = Canvas("Before this course", "why this project")
    im = Image.open(PITCH / "evidence/2022-lianliankan-console.png").convert("RGB")
    im = im.crop((0, 0, 250, 150))
    im = im.resize((im.width * 5, im.height * 5), Image.NEAREST)
    c.box(210, 590, 220 + im.width + 10, 600 + im.height + 10, fill=INK, outline=INK, width=4, r=10)
    c.paste(im, 220, 600)
    for i, t in enumerate(("Rui's tile-matching game", "C + EasyX, a 2022 course project", "its board array, printed", "to the console by the game")):
        c.text((1600, 640 + i * 100), t, SANS(64) if i else SANSB(70))
    c.text((1600, 1080), "its tile and background art was not", SANS(56), fill=DIM)
    c.text((1600, 1160), "Rui's, so the game screens are not shown", SANS(56), fill=DIM)
    c.text((1600, 1420), "2022 test plan:", SANSB(64))
    c.text((1600, 1520), "“played 10+ times, no bugs”", SERIF(76))
    c.text((1600, 1630), "translated from the report's 游玩10+次，无bug", CJK(50), fill=DIM)
    return save(c, "B14", label)


def b16(label):
    c = Canvas("Exists today, and will exist", "what is real")
    ex = [("prototype, fire, burning", "mk-prototype"), ("burning tint shader", "a5"), ("two particle effects", "a6"),
          ("animated archer, state machine", "a7"), ("headless tests + mutations", "a5–a7")]
    wl = ["ice, lightning, 2 reactions", "2 new enemy types", "level-up cards", "title + end screens",
          "endless mode", "a Windows build"]
    c.text((240, 580), "EXISTS", SANSB(80))
    c.text((2040, 580), "WILL EXIST", SANSB(80), fill=DIM)
    for i, (t, tag) in enumerate(ex):
        y = 740 + i * 190
        c.box(240, y, 1820, y + 150, fill=CARD, outline=INK, width=8, r=24)
        c.text((290, y + 38), t, SANS(64))
        c.text((1790, y + 38), tag, MONO(58), fill=TERRA, anchor="ra")
    for i, t in enumerate(wl):
        y = 740 + i * 175
        c.d.rounded_rectangle([2040, y, 3620, y + 140], radius=24, outline=GHOST, width=8)
        c.text((2090, y + 33), t, SANS(64), fill=DIM)
    return save(c, "B16", label)


def b17(label):
    c = Canvas("", "")
    c.ctext(1920, 720, "Mimic Keep", SERIFB(260))
    c.ctext(1920, 1060, "final project pitch", SERIF(110), fill=DIM)
    c.ctext(1920, 1300, "Rui Sun", SANSB(120))
    c.ctext(1920, 1480, "walker-mimic-keep-rui-sun · Godot 4.7.2 · Forward+", MONO(64), fill=DIM)
    crow = sprite("scarecrow.png", 5)
    c.paste(crow, 520, 700)
    c.paste(sprite("archer.png", 5), 3100, 760)
    return save(c, "B17", label)


DRAW = {"B01": b01, "B02": b02, "B04": b04, "B05": b05, "B06": b06, "B08": b08, "B09": b09, "B10": b10,
        "B11": b11, "B12": b12, "B13": b13, "B14": b14, "B16": b16, "B17": b17}


def main():
    sheet = json.loads((REEL / "beat_sheet.json").read_text(encoding="utf-8"))
    for b in sheet["beats"]:
        bid = b["beat_id"]
        if bid in DRAW:
            DRAW[bid](b["shot"]["label"])   # pictures are dark ink on a light ground: whole-frame Gate V, no waiver
            b.pop("qc", None)
            print(bid, "drawn")
    (REEL / "beat_sheet.json").write_text(json.dumps(sheet, indent=1, ensure_ascii=False), encoding="utf-8")


if __name__ == "__main__":
    main()
