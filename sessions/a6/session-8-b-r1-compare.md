I compared each r1 frame with the prediction I made before the change. **The change shows up, but it's much smaller than I predicted.** Frames 10, 130 and 170 match. Frames 20–100 look almost the same as r0 to the eye, where I had predicted noticeably fewer bright embers.

**What I could and couldn't measure:** frames 10–130 differ from r0 at the byte level, and frame 170 is byte-identical. The pixel-measurement commands (Python and ImageMagick) needed approval and didn't run. So the readings below are by eye from the full 1280×720 frames, and I can't give exact pixel counts.

| Frame | My prediction | r1 | Verdict |
|---|---|---|---|
| 10 | Nothing visible | The ember low on the body's left (~629, 557) is still there but clearly dimmer than r0's white dot | Mostly matches: dim, not invisible |
| 20 | 1–2 fully bright, the rest faint; sparser than r0 | Same dots as r0 on the head (~627, 512; 640, 510) and body (~626, 542; 655, 540), and they look about as bright | Doesn't match |
| 40 | About a third fewer bright dots; the stream starts higher | The three embers above the hat look the same as r0 (expected, since they're old). I can't see fewer bright dots on the body | Partly: the old embers match, the drop doesn't show |
| 70 | 2–3 bright | Looks like r0, including the high ember right of the hat (~661, 491) | Partly |
| 100 | 1–2 bright | Looks like r0 | Partly |
| 130 | Almost identical to r0 | Almost identical (the bytes differ) | Matches |
| 170 | Identical | Byte-identical | Matches |

## What explains the gap

1. **I overstated how long embers stay faint.** The fade from 0 to full is a straight line over 0.27 s, so an ember is already past half brightness at about 0.135 s. Only embers younger than about 0.1 s are really faint. At 20 embers per second that's about 2 at a time, not a third of the stream. At frame 20 most of the ~6 embers are 0.1–0.33 s old, so they're already bright.
2. **Additive light clips on these backgrounds.** Most embers sit on the burning-tinted body, roughly (247, 193, 58). Adding pale yellow (255, 242, 161) at even half strength pushes red and green to 255, so only blue changes. A half-faded ember therefore looks about as bright as a full one, just a little more yellow and less white. The bright grass also clips green quickly. This is the same effect TUNING.md recorded for Effect A r1, and I didn't carry it into this prediction.
3. **Frame 10 is not the ember's birth frame.** The ember is a frame or two old there, about 4–7 % of its life, so its brightness is around 0.12–0.25 rather than 0. On the body that is still a faint visible dot.
4. **Frame 130 differs only in bytes:** the last embers are born just before the ratio reaches 0, so a few young, faded ones are still present. **Frame 170 is identical:** it has no particles. That shows the background and scarecrow render the same in both captures. It doesn't prove the particles themselves are deterministic, but with fixed seeds the differences in frames 10–130 are most likely from the ramp change.

## What this means for your overlap observation

The overlap you saw happens under the flash, on the body, which is where clipping is worst. The flash itself already reaches about (255, 255, 76) there (TUNING.md, Effect A r1). This fade-in probably makes only a small difference in the running game. This strip can't show that either way, because it has no hit. Whether to keep r1 is your call from the game.

If you approve the pixel-measurement command, I can give exact changed-pixel counts per frame.