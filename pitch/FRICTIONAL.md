# FRICTIONAL — final project pitch

Dated entries, written as the work happened. Claude wrote these entries from the session record; Rui's own
words are quoted, never paraphrased into Rui's mouth.

## 2026-11-23 — The assignment, and what the toolkit does not have

- Rui pasted the assignment and asked for the steps. Claude checked the repository (main = tag `a7` = 39f3fe8,
  clean) and the local Brutalist checkout (`29ba0e8`). The `show-tell` skill the assignment recommends is not in
  this checkout; upstream is 98 commits ahead and needs Manim and a newer Remotion.
- The toolkit's show-tell and walker bookends open with "Liam, in for Bear" and close on the instructor's handle
  and jingle. The assignment forbids the instructor's name, persona and credit line, so none of them is used.
- No `export_presets.cfg` exists: no build of the game has ever been exported. The pitch says so.

## 2026-11-24 — Who writes the brief

- Claude first said the seven answers had to be in Rui's own words, copying Assignment 7's rule. Rui pointed out
  this assignment has no such clause ("任务书里没说这七个问题需要我自己回答吧"). Claude was wrong; it drafts the
  brief, and only facts that only Rui knows come from Rui: the comparable games, the target role, what is new
  learning, the direction.
- Rui's answers (verbatim in `brief-answers-zh.md`): one level + endless mode, technical designer, hiring manager,
  Genshin Impact, and a WeChat roguelite whose name Rui no longer remembers. The second comparable stays unnamed
  rather than guessed.
- Rui's first project idea was "some levels and an endless mode". Claude flagged the size against the
  assignment's "one person can finish"; Rui kept one level + endless mode and moved more levels to later.

## 2026-11-24 — Evidence of earlier work

- Rui sent a screenshot of a 2022 tile-matching game. Its tiles and backgrounds are someone else's art, so it is
  not published. Rui then sent the 2022 course report; it holds a student number and a teacher's name, so it
  stays out of the repository. The only image used is the game's own console print of the board array, with the
  title bar (a local path) cropped off.
- Rui offered a second project (a C++ console game) and then withdrew it ("贪吃蛇游戏不要了，就直说连连看吧"). Everything
  drawn from it was deleted.

## 2026-11-24 — An interrupted command

- Claude started `git worktree add` to check out upstream Brutalist on F:. Rui stopped the call. It left a
  partial, locked worktree at `F:/7270/brutalist-a8`, outside this repository. Nothing in the film uses it; it is
  waiting for Rui's decision before it is removed.

## 2026-11-24 — The narration and the take

- Rui approved the narration ("可以定稿"). Claude's estimate from the A7 film's pace was 3.8 minutes; the measured
  Kokoro audio came to 3 min 37 s with the clip tails.
- A 5-second test showed windowed Movie Maker at 1280×720 runs close to real time, so Rui could play by hand.
  Rui recorded one run and won at 1:30 ("录好了，赢了，选择最后的一段时间吧"). The film shows the take scaled 3× with
  nearest-neighbour, never retimed.
- One claim was cut back while checking: "two particle effects with a measured GPU cost" became "with a GPU
  reading", because the A6 measurement was one whole-frame reading and the effects' share was below the
  profiler's precision.

## 2026-11-24 — Faults Claude found by looking at its own renders

- B03's first crop cut the HUD mid-word; it now starts below the HUD.
- The first clip labels were wide enough to cover the gate and the mimic; the sub-line was shortened.
- B08's first a6 and a7 panels showed empty grass and wall: Claude had read crop coordinates off a half-size
  contact sheet. They now show the scarecrow mid-burst and the archer at full draw.
- B11's tick and cross were missing glyphs in the font (drawn as boxes); they are now drawn as lines.
- B12's long code line ran under the element badges; it is shortened with a visible ellipsis.
- B14's console print was a small patch in a large black frame; it is cropped to the printed array.
- The 2022 quote "played 10+ times, no bugs" is Claude's translation; the picture now says so and shows the
  original Chinese.

## 2026-11-24 — The toolkit's gates refused the first two masters

- Compile 1: Gate V refused before sampling a frame: Claude had declared regional contrast boxes on the picture
  beats without a written reason. The picture beats are dark ink on a light ground and need no regional waiver,
  so the boxes were removed and they are checked as whole frames.
- Compile 2: Gate V sampled 36 frames and refused with 28 BLOCKER and 4 MAJOR. Every burned label started at
  x 120, left of the title-safe line (x 192 at 4K): edge-bleed on every picture beat. The clip labels' rounded
  corners let the wall behind them into the corners Gate V reads as the region's background, so the label
  measured 0.20–0.21 against a floor of 0.30 (B00, B15). Labels now start at x 240 with square corners, two
  pictures that sat 2 px past the line were moved in, and `make_stills.py` now asserts every picture's content
  lies inside the title-safe area before saving it. No gate was waived or edited.

## 2026-11-24 — Rui's review of the master

- Claude cannot hear the audio. It checked the master by sampling a frame every 4 seconds and asked Rui to watch
  and listen, naming the lines most likely to be misread by the voice (version tags, "RTX 3070", decimal
  numbers, Genshin Impact, WeChat). Rui watched and listened to the whole film: "看完了，没问题". Nothing was
  re-voiced.
