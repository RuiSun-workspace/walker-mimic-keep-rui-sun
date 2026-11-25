"""Cut the four gameplay beats from take play-r0, burn their labels, set their durations (Claude, 2026-11-24).

Adapted from the A7 film's cut_clips.py. Timing contract: each capture beat is ONE contiguous interval of the take
at normal speed, never retimed or spliced; its length is the narration plus a 0.4 s tail, in whole frames.
The take was hand-played by Rui (keyboard, not scripted) in Movie Maker at 1280x720, 30 fps, from tag a7.
Movie Maker's game audio is not used; each beat's audio is its narration, padded to the clip.

Windows (all in the second half of the run, as Rui asked; none overlap):
  B00  from frame 1380 (0:46), full frame
  B03  from frame 1710 (0:57), upper meadow cropped below the HUD (game x 427-1280, y 60-540, 4.5x): several
       scarecrows ignite, tint and burn down
  B07  from frame 2020 (1:07), full frame; Rui moves left and right; the HUD shows the A/D hint
  B15  from frame 2470 (1:22), full frame; the win at frame 2700 (1:30) and the banner after it

    F:/7270/film-env/Scripts/python.exe pitch/build/cut_clips.py
"""
import hashlib
import json
import math
import subprocess
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

REEL = Path("F:/7270/reels/mimic-keep-final-pitch")
TAKE = Path("F:/7270/a8-captures/play-r0")
FF = "F:/7270/tools/ffmpeg-9.0.1-essentials_build/bin/"
FPS, TAIL = 30, 0.4
SRC = "39f3fe8"
WINDOWS = {"B00": 1380, "B03": 1710, "B07": 2020, "B15": 2470}
CROP = {"B03": (427, 60, 853, 480)}   # game-frame coords (x, y, w, h) at 1280x720
SUB = "Rui at the keyboard · Movie Maker 1280×720, {scale} · take play-r0 {t0}–{t1}"
LABEL_BOX = {}


def sh(*args):
    subprocess.run([str(a) for a in args], check=True)


def sha(p):
    return hashlib.sha256(Path(p).read_bytes()).hexdigest()


def mmss(frame):
    s = frame / FPS
    return f"{int(s // 60)}:{s % 60:04.1f}"


def label_png(bid, main, sub):
    font = ImageFont.truetype("C:/Windows/Fonts/segoeuib.ttf", 64)
    small = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 42)
    img = Image.new("RGBA", (3840, 2160), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    w = max(d.textlength(main, font=font), d.textlength(sub, font=small))
    x0, bw, bh = 240, int(w) + 96, 196     # left edge inside title-safe (x 192 at 4K)
    y0 = 2012 - bh                          # bottom edge 40 px above the title-safe line (y 2052 at 4K); top
                                            # stays below the archer's feet (game y 600 -> 4K y 1800)
    d.rectangle([x0, y0, x0 + bw, y0 + bh], fill=(12, 12, 18, 235))   # square: Gate V reads the region's corners as its background
    d.text((x0 + 48, y0 + 22), main, font=font, fill=(244, 241, 232, 255))
    d.text((x0 + 48, y0 + 116), sub, font=small, fill=(205, 210, 224, 255))
    p = REEL / "assets" / f"label-{bid}.png"
    p.parent.mkdir(parents=True, exist_ok=True)
    img.save(p)
    LABEL_BOX[bid] = [round(x0 / 3840, 3), round(y0 / 2160, 3), round((x0 + bw) / 3840, 3), round((y0 + bh) / 2160, 3)]
    return p


def main():
    sheet = json.loads((REEL / "beat_sheet.json").read_text(encoding="utf-8"))
    beats = {b["beat_id"]: b for b in sheet["beats"]}
    timings = json.loads((REEL / "mp3" / "timings.json").read_text())
    total = len(list(TAKE.glob("f*.png")))
    windows = {}
    for bid, start in WINDOWS.items():
        n = math.ceil((float(timings[bid]) + TAIL) * FPS - 1e-9)
        assert start + n <= total, (bid, start, n, total)
        b = beats[bid]
        if bid in CROP:
            x, y, w, h = CROP[bid]
            pre, scale = f"[0:v]crop={w}:{h}:{x}:{y},scale=3840:2160:flags=neighbor[c];[c]", "crop 4.5×"
        else:
            pre, scale = "[0:v]scale=3840:2160:flags=neighbor[c];[c]", "3×"
        sub = SUB.format(scale=scale, src=SRC, t0=mmss(start), t1=mmss(start + n))
        media = REEL / "media" / f"{bid}.mp4"
        media.parent.mkdir(exist_ok=True)
        sh(FF + "ffmpeg.exe", "-y", "-v", "error", "-framerate", FPS, "-start_number", start, "-i", TAKE / "f%08d.png",
           "-i", label_png(bid, b["shot"]["label"], sub), "-filter_complex", f"{pre}[1:v]overlay=0:0", "-frames:v", n,
           "-c:v", "libx264", "-preset", "slow", "-crf", 15, "-pix_fmt", "yuv420p", "-r", FPS, "-an", media)
        dur = n / FPS
        (REEL / "mix").mkdir(exist_ok=True)
        audio = REEL / "mix" / f"{bid}.wav"
        sh(FF + "ffmpeg.exe", "-y", "-v", "error", "-i", REEL / "mp3" / f"beat-{bid}.mp3",
           "-af", "aresample=48000,aformat=channel_layouts=stereo,apad", "-t", f"{dur:.6f}",
           "-ar", 48000, "-ac", 2, "-c:a", "pcm_s16le", audio)
        b["audio_file"] = audio.relative_to(REEL).as_posix()
        b["actual_duration_s"] = round(dur, 4)
        b["render_duration_s"] = dur
        b["shot"]["clip_file"] = f"media/{bid}.mp4"
        b["shot"]["label_sub"] = sub
        b["shot"]["capture_window"] = {"take": "play-r0", "frames": [start, start + n],
                                       "start_s": round(start / FPS, 4), "end_s": round((start + n) / FPS, 4),
                                       "crop_game_xywh": list(CROP.get(bid, (0, 0, 1280, 720))),
                                       "media_sha256": sha(media)}
        b.setdefault("qc", {})["full_bleed"] = True
        b["qc"]["full_bleed_reason"] = "Engine capture scaled to 3840x2160 fills the frame by design."
        b["qc"]["contrast_regions"] = [{"label": "burned-in shot label", "box": LABEL_BOX[bid]}]
        b["qc"]["contrast_reason"] = ("Engine footage of a flat green meadow by design; the text a viewer must read is the "
                                      "burned-in label, so contrast is measured there.")
        windows[bid] = b["shot"]["capture_window"]
        print(bid, f"frames {start}-{start + n}", f"{dur:.2f}s", sub)
    (REEL / "beat_sheet.json").write_text(json.dumps(sheet, indent=1, ensure_ascii=False), encoding="utf-8")
    (REEL / "capture").mkdir(exist_ok=True)
    (REEL / "capture" / "windows.json").write_text(json.dumps(windows, indent=1), encoding="utf-8")


if __name__ == "__main__":
    main()
