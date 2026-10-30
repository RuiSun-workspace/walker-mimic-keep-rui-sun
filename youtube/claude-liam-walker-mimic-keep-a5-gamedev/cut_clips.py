"""Cut the two moving-picture beats, burn their labels, and set every beat's duration (Claude, 2026-10-29).

Timing contract (godot-waikthrough capture reference, as in A2 and A3): each capture beat is ONE contiguous
interval of a take at normal speed, never retimed or spliced; its length is the narration plus a 0.4 s tail,
rounded up to whole frames. The game's own sound is not recorded (Movie Maker writes no audio here), so the
audio is the narration alone.
- B02: take "idle" (no keys pressed). Window chosen from capture/take-idle.log so that burning scarecrows are on
  screen; full frame.
- B07: take "fade" (scripted hits, archer off). Window from 0.5 s, containing the first hit (1.0 s), the second
  hit (3.5 s), the pause (4.5-6.0 s) and the burn-down (7.5 s). Cropped to the middle of the meadow and scaled
  1.6x so the sprites are readable; the crop is stated in the label.
Graphic beats get props.durationSeconds = narration length; their highlight cues are spread over 8-88 %.

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
    "B02": ("Unattended run · no keys pressed", f"real game, archer fires on its own · Movie Maker 3840×2160 · source {SRC7}"),
    "B07": ("Scripted capture · hits called by a script, archer off",
            f"real game, timer and driver running · cropped to the meadow, scaled 1.6× · source {SRC7}"),
}
CROP = {"B07": (720, 510, 2400, 1350)}   # 4K frame coords (x, y, w, h) = game (240, 170) .. (1040, 620)


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
    return p


def cut(bid, frames_dir, start, n, narration):
    total = len(list(frames_dir.glob("f*.png")))
    assert 0 <= start and start + n <= total, (bid, start, n, total)
    media = REEL / "media" / f"{bid}.mp4"
    media.parent.mkdir(exist_ok=True)
    pre = "[0:v]"
    if bid in CROP:
        x, y, w, h = CROP[bid]
        pre = f"[0:v]crop={w}:{h}:{x}:{y},scale=3840:2160:flags=lanczos[c];[c]"
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
    win = json.loads((REEL / "capture" / "chosen-windows.json").read_text())
    windows = {}
    n = frames_for(float(timings["B02"]))
    windows["B02"] = cut("B02", REEL / "_frames/idle", win["B02_start"], n, "mp3/beat-B02.mp3")
    windows["B02"]["take"] = "idle"
    n = frames_for(float(timings["B07"]))
    windows["B07"] = cut("B07", REEL / "_frames/fade", 15, n, "mp3/beat-B07.mp3")
    windows["B07"]["take"] = "fade"
    assert windows["B07"]["frames"][1] >= 240, "B07 must reach the burn-down (frame 226)"
    for bid, w in windows.items():
        b = beats[bid]
        b["audio_file"] = w["audio_file"]
        b["actual_duration_s"] = round(w["duration"], 4)
        b["render_duration_s"] = w["duration"]
        b["shot"]["clip_file"] = w["media"]
        b["shot"]["capture_window"] = {k: w[k] for k in ("take", "start_s", "end_s", "frames")}
        b["shot"]["capture_window"]["media_sha256"] = sha(REEL / w["media"])
        b.setdefault("qc", {})["full_bleed"] = True
        b["qc"]["full_bleed_reason"] = "Native 3840x2160 engine capture fills the frame by design."
        b["qc"]["contrast_regions"] = [{"label": "burned-in shot label", "box": [0.028, 0.85, 0.66, 0.945]}]
        b["qc"]["contrast_reason"] = ("Engine footage of a flat green meadow by design; the text a viewer must read is the "
                                      "burned-in label, so contrast is measured there.")
    for b in sheet["beats"]:
        rem = b.get("shot", {}).get("remotion")
        if rem and b.get("actual_duration_s"):
            dur = float(b["actual_duration_s"])
            rem["props"]["durationSeconds"] = dur
            cues = rem["props"].get("cues") or []
            for i, c in enumerate(cues):
                c["at"] = round(dur * (0.08 + 0.8 * i / max(1, len(cues) - 1)), 2)
    for b in sheet["beats"]:   # compile.py reads stills from media/<beat>.png, evidence or not
        if b.get("image_file"):
            (REEL / "media" / f"{b['beat_id']}.png").write_bytes((REEL / b["image_file"]).read_bytes())
    (REEL / "beat_sheet.json").write_text(json.dumps(sheet, indent=1, ensure_ascii=False), encoding="utf-8")
    (REEL / "capture" / "windows.json").write_text(json.dumps(windows, indent=1), encoding="utf-8")
    for bid, w in windows.items():
        print(bid, w["take"], f"{w['start_s']:.2f}-{w['end_s']:.2f}s", f"{w['duration']:.2f}s", w["audio_file"])


if __name__ == "__main__":
    main()
