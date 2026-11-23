"""Cut the three moving-picture beats, burn their labels, and set every beat's duration (Claude, 2026-11-22).

Timing contract (as in the A5/A6 films): each capture beat is ONE contiguous interval of a take at normal speed,
never retimed or spliced; its length is the narration plus a 0.4 s tail, rounded up to whole frames. Movie Maker
writes no game audio here, so the audio is the narration alone.
- Crops keep each subject above the burned-in label (bottom 15 %); the first cut hid the archer and the walker.
- B02: take "play" (scarecrows placed by the script, the archer shoots on its own, no keys), full frame.
- B14: take "play" from frame 0, cropped on the walker outside the cone (game x 0-853, y 176-656, 1.5x): it walks
  about a dozen wraps and switches to hold at the wall (frame 187).
- B15: take "interrupts" from frame 0 (key events sent by the script), cropped on the archer and the pause banner
  (game x 239-1041, y 230-681, 1.6x): P in startup (f44), on the active frame (f145), in recovery (f243), D
  through a draw (f329), the wall target walked out of the cone and the draw cancelled with no arrow (f442-446).

    F:/7270/film-env/Scripts/python.exe cut_clips.py
"""
import hashlib
import json
import math
import subprocess
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

REEL = Path(__file__).resolve().parent
FF = "F:/7270/tools/ffmpeg-9.0.1-essentials_build/bin/"
FPS, TAIL = 30, 0.4
SRC7 = (REEL / "capture/source-commit.txt").read_text()[:7]
LABELS = {
    "B02": ("Scarecrows placed by the script · no keys pressed",
            f"real game, the archer draws and shoots on its own · Movie Maker 3840×2160 · source {SRC7}"),
    "B14": ("Scarecrows placed by the script · no keys pressed",
            f"real game at normal speed · cropped to game x 0-853, y 176-656, scaled 1.5× · source {SRC7}"),
    "B15": ("Scripted-input capture · keys sent by a script",
            f"real key events (Input.parse_input_event), timed by the archer's state · cropped, scaled 1.6× · source {SRC7}"),
}
CROP = {"B14": (0, 528, 2560, 1440), "B15": (717, 690, 2406, 1353)}   # 4K frame coords (x, y, w, h)
LABEL_BOX = {}   # each beat's burned-in label, as fractions of the frame (the contrast region)
WINDOWS = (("B02", "play", 0), ("B14", "play", 0), ("B15", "interrupts", 0))


def sh(*args):
    subprocess.run([str(a) for a in args], check=True)


def sha(p):
    return hashlib.sha256(Path(p).read_bytes()).hexdigest()


def frames_for(seconds):
    return math.ceil((seconds + TAIL) * FPS - 1e-9)


def label_png(bid):
    main, sub = LABELS[bid]
    font = ImageFont.truetype("C:/Windows/Fonts/segoeuib.ttf", 64)
    small = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 46)
    img = Image.new("RGBA", (3840, 2160), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    w = max(d.textlength(main, font=font), d.textlength(sub, font=small))
    x0, y0, bw, bh = 120, 2160 - 120 - 196, int(w) + 96, 196
    d.rounded_rectangle([x0, y0, x0 + bw, y0 + bh], radius=24, fill=(12, 12, 18, 215), outline=(154, 163, 191, 255), width=4)
    d.text((x0 + 48, y0 + 22), main, font=font, fill=(244, 241, 232, 255))
    d.text((x0 + 48, y0 + 112), sub, font=small, fill=(200, 205, 220, 255))
    p = REEL / "assets" / f"label-{bid}.png"
    img.save(p)
    LABEL_BOX[bid] = [round(x0 / 3840, 3), round(y0 / 2160, 3), round((x0 + bw) / 3840, 3), round((y0 + bh) / 2160, 3)]
    return p


def cut(bid, frames_dir, start, n, narration):
    total = len(list(frames_dir.glob("f*.png")))
    assert 0 <= start and start + n <= total, (bid, start, n, total)
    media = REEL / "media" / f"{bid}.mp4"
    media.parent.mkdir(exist_ok=True)
    pre = "[0:v]"
    if bid in CROP:
        x, y, w, h = CROP[bid]
        pre = f"[0:v]crop={w}:{h}:{x}:{y},scale=3840:2160:flags=neighbor[c];[c]"
    sh(FF + "ffmpeg.exe", "-y", "-v", "error", "-framerate", FPS, "-start_number", start, "-i", frames_dir / "f%08d.png",
       "-i", label_png(bid), "-filter_complex", f"{pre}[1:v]overlay=0:0", "-frames:v", n,
       "-c:v", "libx264", "-preset", "slow", "-crf", 15, "-pix_fmt", "yuv420p", "-an", media)
    dur, t0 = n / FPS, start / FPS
    (REEL / "mix").mkdir(exist_ok=True)
    audio = REEL / "mix" / f"{bid}.wav"
    sh(FF + "ffmpeg.exe", "-y", "-v", "error", "-i", REEL / narration, "-af", "aresample=48000,aformat=channel_layouts=stereo,apad",
       "-t", f"{dur:.6f}", "-ar", 48000, "-ac", 2, "-c:a", "pcm_s16le", audio)
    return {"media": f"media/{bid}.mp4", "audio_file": audio.relative_to(REEL).as_posix(), "duration": dur,
            "start_s": round(t0, 4), "end_s": round(t0 + dur, 4), "frames": [start, start + n]}


def main():
    sheet = json.loads((REEL / "beat_sheet.json").read_text(encoding="utf-8"))
    beats = {b["beat_id"]: b for b in sheet["beats"]}
    timings = json.loads((REEL / "mp3" / "timings.json").read_text())
    windows = {}
    for bid, take, start in WINDOWS:
        n = frames_for(float(timings[bid]))
        windows[bid] = cut(bid, REEL / "_frames" / take, start, n, f"mp3/beat-{bid}.mp3")
        windows[bid]["take"] = take
    assert windows["B14"]["frames"][1] > 200, "B14 must reach the walker's hold at the wall (frame 187)"
    assert windows["B15"]["frames"][1] > 470, "B15 must include the cancel (frame 446) and the 0.8 s after it"
    for bid, w in windows.items():
        b = beats[bid]
        b["audio_file"] = w["audio_file"]
        b["shot"]["label"] = LABELS[bid][0]
        b["actual_duration_s"] = round(w["duration"], 4)
        b["render_duration_s"] = w["duration"]
        b["shot"]["clip_file"] = w["media"]
        b["shot"]["capture_window"] = {k: w[k] for k in ("take", "start_s", "end_s", "frames")}
        b["shot"]["capture_window"]["media_sha256"] = sha(REEL / w["media"])
        b.setdefault("qc", {})["full_bleed"] = True
        b["qc"]["full_bleed_reason"] = "Native 3840x2160 engine capture fills the frame by design."
        b["qc"]["contrast_regions"] = [{"label": "burned-in shot label", "box": LABEL_BOX[bid]}]
        b["qc"]["contrast_reason"] = ("Engine footage of a flat green meadow by design; the text a viewer must read is the "
                                      "burned-in label, so contrast is measured there.")
    for b in sheet["beats"]:   # compile.py reads stills from media/<beat>.png
        if b.get("image_file"):
            (REEL / "media").mkdir(exist_ok=True)
            (REEL / "media" / f"{b['beat_id']}.png").write_bytes((REEL / b["image_file"]).read_bytes())
    (REEL / "beat_sheet.json").write_text(json.dumps(sheet, indent=1, ensure_ascii=False), encoding="utf-8")
    (REEL / "capture" / "windows.json").write_text(json.dumps(windows, indent=1), encoding="utf-8")
    for bid, w in windows.items():
        print(bid, w["take"], f"{w['start_s']:.2f}-{w['end_s']:.2f}s", f"{w['duration']:.2f}s", w["audio_file"])


if __name__ == "__main__":
    main()
