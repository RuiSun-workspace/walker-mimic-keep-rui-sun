# CHANGE-BRIEF — Assignment 7: Doing Animation

> 提示（整份骨架通用）：这是 Claude 按作业要求列出的**结构**，不是 brief。
> - 标 `TODO(Rui)` 的地方由你写：理由、数字、预测、规则都是你的。
> - 以 `>` 开头的中文"提示"行只是给你参考，写完后全部删掉。
> - 已经填好的只有两类：你已经做过的决定（2026-11-19），以及代码里的事实（带文件和行号）。这些你也要核对。
> - 写完后整个替换仓库根目录的 `CHANGE-BRIEF.md`（A6 版本留在 tag `a6`），然后在发 prompt-1 之前 commit。

**Author:** Rui Sun
**Course:** CSYE 7270, Fall 2026
**Project:** Mimic Keep
**Engine:** Godot 4.7.2 (`4.7.2.stable.official.ed1daf0bf`)
**Renderer:** Forward+

The Assignment 6 version of this brief is preserved at tag a6. This is the original Assignment 7
brief, dated TODO(Rui: date). Revisions are added below the original with their date.

## 1. The two clips

### Clip 1 — Scarecrow walk (the cycle)

- **What it communicates, and why the player needs it:** TODO(Rui)
- **Plays on:** every scarecrow, `godot/game/scarecrow.tscn` (root `Scarecrow`, child `Sprite`, Sprite2D).
- **Route:** Sprite2D with an AnimationPlayer frame track. **Why:** TODO(Rui)
- **Authority:** TODO(Rui: node name, e.g. `Scarecrow/AnimationPlayer`), started by TODO(Rui: which
  script, and which state or signal it reads — e.g. walking while `at_wall == false`,
  `godot/game/scarecrow.gd:18`; what happens at the wall and on death).
- **Cycle or committing:** the cycle.

> 提示：稻草人没有腿（`make_sprites.gd:42-57` 画的是一根杆、横臂、草身、麻袋头和帽子），
> 所以"走路"要你来定义：在杆上跳、左右摇晃，还是上下颠？
> 它的下移速度是 45 px/s（`godot/game/tuning.gd:18`），由 `scarecrow.gd` 的 `_physics_process`
> 移动位置，动画不负责移动。

### Clip 2 — Archer shot (the committing action)

- **What it communicates, and why the player needs it:** TODO(Rui)
- **Plays on:** the archer, `godot/game/archer.tscn` (today: root `Archer` Node2D + one `Sprite`
  Sprite2D with the whole 44×60 `archer.png`).
- **Route:** cutout rig keyed as resource text (or baked by a headless tool script to a committed
  `.tres`). **Why:** TODO(Rui)
- **The rig:** TODO(Rui: which parts are separate pieces and which pivot moves — e.g. body / bow /
  string, a `Node2D` pivot keyed on rotation and position).
- **Authority:** the archer's `AnimationTree` (AnimationNodeStateMachine), TODO(Rui: node path).
  Its `AnimationPlayer` holds the clips and never plays on its own (no autoplay, no `play()` call).
- **Cycle or committing:** the committing action.

> 提示：现在 `archer.png` 是一整张图，弓和弦是画在身体里的（`make_sprites.gd:69-70`）。
> 做 rig 要把它拆成几块部件（代码生成，和图集一样把代码 commit），要拆哪几块由你定。

## 2. The sheet (scarecrow walk)

- **Source:** written by code — TODO(Rui: e.g. a new function in `godot/tools/make_sprites.gd`;
  who writes that code: Claude Code, approved by you). No downloaded or model-generated art.
- **Author / licence / date checked:** TODO(Rui). Still recorded in a credits file next to the
  asset (`godot/assets/sprites/ATTRIBUTION.md` or similar) and in `SOURCES.md`.
- **Cell size:** TODO(Rui) px. Today's single frame is 56×72 (`make_sprites.gd:43`).
- **Grid:** `hframes` = TODO, `vframes` = TODO. Sheet size = cell × grid = TODO.
- **Frame order:** TODO(Rui: cell index → pose, e.g. 0 = …, 1 = …).
- **Original file:** TODO(Rui: path of the PNG exactly as the generator wrote it), committed
  together with the generator code.
- **Registration:** TODO(Rui: which pixel must stay fixed from cell to cell — e.g. the pole's foot —
  and how the frame strip checks it).

## 3. The cycle spec (scarecrow walk)

| Item | Value |
|---|---|
| Frame count | TODO |
| Frame rate | TODO fps |
| `Animation.step` | TODO s (= 1 / frame rate) |
| Clip length | TODO s |
| Loop mode | `Animation.LOOP_LINEAR` |
| Track | value track on `Sprite:frame`, `Animation.UPDATE_DISCRETE` |
| Key times | TODO (one per frame, every key interval) |

**Seam rule (frame track):** no duplicate frame across the wrap, and the gap from the last key to
the clip length equals the key interval. TODO(Rui: say it with your numbers, e.g. "last key at
…, length …, gap … = interval …").

**What a duplicated frame at the wrap would look like in play:** TODO(Rui)

## 4. The phase table (archer shot)

Frame rate: TODO fps. `Animation.step` = TODO s (one frame period).

| Phase | Frames | Begins on frame | What the player may do | What the game reads |
|---|---|---|---|---|
| Startup | TODO | 0 | TODO | TODO |
| Active | TODO | TODO | TODO | TODO (e.g. the arrow is released on this frame) |
| Recovery | TODO | TODO | TODO | TODO |

**Reference:** TODO(Rui: what you measured — a clip of a real or game archer — how you counted the
frames, and the numbers you got).

> 提示：
> - 射击间隔 `FIRE_INTERVAL` = 0.6 s（`tuning.gd:10`），在 30 fps 下是 18 帧、60 Hz 物理帧下是 36 tick。
>   startup + active + recovery 加起来要放得进这个间隔，否则射速会变。
> - 选 30 fps 的话 step 正好等于默认的 1/30，Q3 就只能回答"不变"。选别的帧率，Q3 的答案更有内容。
> - 帧条按 30 fps 录。如果 phase table 用的不是 30 fps，第 11 节要把边界换算成帧条上的帧号。

## 5. The gameplay change: the arrow waits for the active frame

Decided 2026-11-19: the arrow is released on the active frame, not the moment the cooldown ends.
This is the one change to game behaviour this brief allows. Decided 2026-11-19: the draw (startup)
begins early — when a target is in the cone and `fire_cooldown` has no more than the startup time
left — so back-to-back shots keep the 0.6 s cadence and only a first shot (the cooldown was already
0 when a target appeared) is released later than today. Decided 2026-11-19 (round-2 review): the
draw threshold is **0.3 s (18 physics ticks)**, not the 0.2667 s startup length, because a probe in
Godot 4.7.2 (`prompts/a7/probes/probe_tick_order.gd`) measured 18 ticks from `travel("shoot")` to
the archer reading the active-frame key (1 tick parked at position 0 on entering the state, 1 tick
because the parent reads before its child AnimationTree writes within a tick). With 0.2667 s the
cadence would be 38 ticks = 0.633 s. New test: two back-to-back releases are exactly 36 ticks apart.
A first shot is therefore released 0.3 s later than today. TODO(Rui: write the rule exactly, with
your startup length, and answer points 2–4 below.)

> 提示：这是整份 brief 最需要你想清楚的地方。今天的开火逻辑在 `godot/game/archer.gd:14-24`：
> 冷却到 0 且锥形范围内有目标时，**同一个物理 tick** 就生成箭，冷却重置为 0.6 s。
> 至少要定下面四件事：
> 1. **startup 什么时候开始？**
>    - (a) 冷却到 0 才开始拉弓：每一箭都推后 startup 帧，射速从"每 0.6 s"变成"每 0.6 s + startup"。
>      `FIRE_INTERVAL` 是作业要求保持不变的"现有计时"之一，这样会改掉它。
>    - (b) 冷却剩下 ≤ startup 时长、并且有目标时提前开始拉弓：连续射击的节奏仍是 0.6 s，
>      只有"冷却早就到 0、目标刚进入范围"的第一箭会晚 startup 帧。
> 2. **startup 期间目标消失（死了、离开锥形范围、游戏结束）怎么办？** 取消回 Idle？换目标？
> 3. **左右移动算不算打断？** 每个阶段里移动会发生什么？（作业要求每个阶段都要测"打断"，
>    并由 brief 规定结果。）暂停（Esc/P）呢？
> 4. **哪些现有测试的期望会变？** 依赖开火时机的现有测试：`test_rules.gd:112-130`、
>    `test_wall_targeting.gd:49-55`、`test_burning_tint.gd`（按射出箭的数量计数）、
>    A6 的两个 state test（`test_impact_burst_state.gd`、`test_burning_embers_state.gd`，
>    其中有精确到帧的命中时间）。你要预测哪些会变、变多少；没预测到的变化就是一个 finding。

## 6. The state machine (archer, AnimationTree)

`AnimationTree.advance_expression_base_node`: TODO(Rui: node path, e.g. `..` = the Archer).
`AnimationTree.anim_player`: TODO. `tree_root`: an `AnimationNodeStateMachine`.

| State | Clip it plays | Loops? |
|---|---|---|
| TODO (e.g. idle) | TODO | TODO |
| TODO (e.g. shoot) | TODO | no |

| From → To | Condition | `advance_mode` | `switch_mode` | `xfade_time` |
|---|---|---|---|---|
| Start → TODO | TODO | TODO | TODO | TODO |
| TODO | TODO | TODO | TODO | TODO |

> 提示：
> - `advance_mode` 有三个值：Disabled、Enabled（默认，**只在 `travel()` 时使用**）、Auto
>   （advance_condition / advance_expression 为真时自动转换）。第 11 章实录：agent 把表达式转换
>   留在默认的 Enabled，状态机永远卡住。
> - 两种驱动方式选一种：push（弓箭手脚本调 `travel()`，转换用 Enabled）或 pull（Auto + 表达式，
>   表达式在 `advance_expression_base_node` 上求值）。
> - `switch_mode`：Immediate / Sync / At End。"射完回 Idle"一般是 At End；"startup 里取消"是 Immediate。
> - Tree 每帧只评估一次（第 11 章那个"着地后下一 tick 起跳"的 bug 就是这样来的）。

## 7. The two clocks

| Mixer | `callback_mode_process` | Why |
|---|---|---|
| Scarecrow `AnimationPlayer` | TODO (`ANIMATION_CALLBACK_MODE_PROCESS_IDLE` is the default) | TODO |
| Archer `AnimationTree` | TODO | TODO |
| Archer `AnimationPlayer` (under the tree) | TODO | TODO |

- No `AnimatedSprite2D` is used in this project, so no node advances on a tick it cannot choose.
- Physics runs at 60 ticks per second: `godot/project.godot` sets no `physics_ticks_per_second`
  (the default). The archer moves and fires in `_physics_process` (`godot/game/archer.gd:14`).
- **The keyed gameplay fact** (the release) is read on: TODO(Rui: which tick, by which code).
- **Largest disagreement** if the clip and the reader are on different ticks: TODO s.
- Method tracks are deferred, so none is used to make the clocks agree.

## 8. One authority

| Animated node | Its one authority | What else could write to it |
|---|---|---|
| `Scarecrow/Sprite` (`frame`) | TODO | TODO |
| Archer rig parts | Archer `AnimationTree` | TODO |

> 提示：`Scarecrow/Sprite` 上已经有一个写入者：`godot/game/burning_tint.gd`（挂在同一个 Sprite 上，
> `:13` 每帧写材质的 `burn_mix`）。它写的是材质参数，不是 `frame`。你要说明这算不算"第二个
> authority"，以及为什么。另外 preview 场景和测试脚本也是潜在的写入者。

## 9. Boundaries

Unchanged: collision, movement, input, the state machine's existing timings, existing test
expectations, the Assignment 5 shaders in `godot/shaders/`, the Assignment 6 effects, every other
object, and the generated sheet once committed — except: TODO(Rui: list exactly what §5 changes).
Presentation code may read game state; it never writes it.

## 10. The evidence split

| Rule | Checked by (read-back / pin / frame strip / my eyes in play) | How |
|---|---|---|
| Every track resolves to a real node and property | read-back | TODO |
| Key times match §3 and §4 | read-back | TODO |
| `step`, loop mode, discrete update, frame in sheet | read-back | TODO |
| The tree has the states and transitions in §6 | structure test | TODO |
| Existing behaviour holds except §5 | pins | TODO |
| Interrupt in each phase does what §5 says | edge tests | TODO |
| The cycle wraps without a visible seam | TODO | TODO |
| Startup, active and recovery read as distinct | TODO | TODO |
| No drift within the cells (registration) | TODO | TODO |
| TODO | TODO | TODO |

## 11. The frame strip

- **Preview background:** TODO(Rui: a stretch of the real level — e.g. meadow and the wall walk
  around x 640, where the archer stands; `godot/game/background.gd`).
- **Trigger frame:** TODO. **Frames to read (at 30 fps), and what each should show:**

| Strip frame | Phase boundary | Should show |
|---|---|---|
| TODO | trigger | TODO |
| TODO | startup → active | TODO |
| TODO | active → recovery | TODO |
| TODO | end of recovery | TODO |

## 12. Predicted failures (at least three)

| # | Failure | The check that would catch it |
|---|---|---|
| 1 | TODO | TODO |
| 2 | TODO | TODO |
| 3 | TODO | TODO |

> 提示：作业 "What the agent is likely to get wrong" 和第 11 章里的候选：Godot 3 名字（`loop = true`）；
> 帧轨道留在 continuous；step 留默认导致 key 吸附到错误时间；`advance_mode` 留在 Enabled；
> 编造不存在的属性；用 `==` 比较 key 时间；Tree 和弓箭手在不同 tick 上读写导致放箭差一帧。

## 13. Answers

1. **Which route does each clip use, and what does that route's read-back see that the other
   route's does not?** TODO(Rui)
2. **If your frame track is left on continuous updates, what does the sprite show between two keys,
   and why?** TODO(Rui)
3. **What will `Animation.step` be, and what happens to your key times if you leave it at its
   default?** TODO(Rui)
4. **Which node is the one authority over each animated node, and what else in your project could
   write to it?** TODO(Rui)
5. **Which tick does each clip advance on, and which tick does gameplay read the active window on?
   If they differ, what is the largest disagreement in seconds?** TODO(Rui)
6. **For your cycle: what is the seam rule for its track type, and what would a duplicated frame at
   the wrap look like in play?** TODO(Rui)
7. **If your rig is imported: where does loop mode have to live, and how will you prove it survived
   an empty import cache?** TODO(Rui) — the rig is not imported; say so and say what the
   empty-cache mutation (Step 6, mutation 4) still checks for a keyed rig.

## Revisions

(none yet)
