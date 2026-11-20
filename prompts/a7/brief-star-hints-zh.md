# ★ 题思路（Claude 写的讲解，不是答案）

每题给三样东西：**这题在问什么**、**你需要知道的事实或概念**、**写的时候想清楚哪几点**。
读完用你自己的话写一两句就够，不需要写得很长，写错也没关系，后面审阅会一起改。
这份讲解会和问卷一起 commit，说明我提供了哪些帮助。

---

## A1 ★ 稻草人走路告诉玩家什么？

**在问什么**：这个动画在"沟通"什么信息。不是"它会动"，而是"玩家看到它动，知道了什么"。

**事实**：现在的稻草人是一张静止图片，以每秒 45 px 往下平移（`tuning.gd:18`），到城墙后停下、开始打城门。

**想清楚**：
- 一个不动的图片在平移，和一个"在走"的东西，给人的感觉有什么不同？哪个更像威胁？
- 到城墙以后（你在 A6 题里选了停还是继续），动画变化能不能告诉玩家"它开始打城门了"？
- 玩家为什么需要它：自动射击的游戏里，玩家要一眼判断哪个敌人还在逼近。

## A8 / G6 ★ 循环接缝

**概念**：循环播放时，最后一帧之后紧接着又是第一帧。接缝就是"最后一帧 → 第一帧"这一下。
- 帧轨道的规则（作业原文）：跨过接缝不能有重复帧；最后一个 key 到 clip 结尾的距离，要等于两个 key 之间的间隔。
- 用你的数字算一下：4 帧 @ 8 fps，key 在 0、0.125、0.25、0.375 s，长度 0.5 s，最后一个 key 到结尾也是 0.125 s。
- 常见错误：把第 0 帧在结尾（0.5 s）再 key 一次。这样第 0 帧会连着显示两次。

**想清楚**：某个姿势每循环一次就多停留一倍时间，玩起来像什么？（提示：想想走路时一只脚"卡"了一下。）0.5 s 一个循环，这个毛病一秒出现几次？

## B1 ★ 射箭动作告诉玩家什么？

**在问什么**：同 A1，这个动作在沟通什么。

**事实**：
- 玩家不按射击键，弓箭手是自动射的（`archer.gd:18-24`）。玩家只控制左右移动。
- 你选了"提前拉弓"：拉弓开始，就意味着很快要出箭，而且朝向目标。

**想清楚**：
- 没有按键的游戏里，玩家怎么知道"现在在射"、"下一箭快来了"、"射向哪边"？
- startup（拉弓）对玩家是一个预告（telegraph）；active（放箭）是"箭出去了"的确认；recovery 是"这一箭结束了"。
- 第一箭会晚几帧出，这时玩家看到的是什么？

## B2 ★ 参考测量（这一题必须你亲手做）

**为什么要做**：作业说 "Feel is designed in frames"，phase table 的数字要来自对真实动作的测量，而不是拍脑袋。

**步骤**：
1. 在 YouTube 或 Bilibili 搜 `archery slow motion`、`recurve bow shot 60fps` 或 `射箭 慢动作`。真人或游戏角色都行，最好是侧面、能看清弓的。
2. 记下视频的帧率：YouTube 右键 →"详细统计信息"（Stats for nerds）里看 `@60` 或 `@30`；下载后用 PotPlayer 看属性也行。
   注意：如果是**慢动作**视频，要知道它慢了几倍（比如 240 fps 拍、30 fps 放 = 慢 8 倍），换算时要除回去。
3. 逐帧数（PotPlayer 按 `F`，mpv 按 `.`）三段：
   - 从弓开始拉，到弦松开前最后一帧：startup
   - 弦松开、箭离开弓：active（通常很短，1–3 帧）
   - 从箭离开到手臂回到放松：recovery
4. 换算到 30 fps：`帧数 ÷ 视频帧率 × 30`。
5. 真人射箭的拉弓往往超过 1 秒，放不进 0.6 s 的射击间隔。这很正常：游戏动作一般会**压缩** startup。写下真实的测量值，再写你压缩成几帧、为什么。这本身就是"design feel in frames"。

**记下来**：视频链接、视频帧率、数到的三段帧数、换算后的帧数、你最后选的帧数和理由。

## E1 ★ 预测失败（至少 3 个）

**在问什么**：在 agent 动手之前，你预测哪里会出错，以及哪个检查会抓到它。事后对照，看你的预测准不准。

**候选，各自是什么意思、哪个检查能抓到**：

| 可能的错误 | 会发生什么 | 谁能抓到 |
|---|---|---|
| agent 写了 Godot 3 的 `loop = true` | 文件能加载，但 clip 不循环 | read-back 检查 `loop_mode == LOOP_LINEAR` |
| 帧轨道留在 continuous | 两个 key 之间会扫过中间的帧 | read-back 检查 `UPDATE_DISCRETE` |
| 图集切错网格（比如 hframes 写成 3） | 显示错误的格子，不报错 | read-back 检查"帧号 < hframes × vframes"，以及帧条 |
| 轨道路径写错节点名或属性名 | 这条轨道什么都不动，不报错 | read-back 的 track_problems |
| `advance_mode` 留在默认的 Enabled | 自动转换永远不触发，状态机卡住 | structure test，以及 state test |
| Tree 和弓箭手不在同一个 tick | 放箭差一帧 | 边界测试（前一帧、当帧、后一帧） |
| 稻草人在格子之间漂移 | 走路时整体抖动 | 帧条，以及你在游戏里看 |
| agent 用 `==` 比较 key 时间 | 正确的 clip 也会测试失败 | 读测试代码、读日志 |

**怎么写**：挑 3 个以上**你真的觉得会发生**的，每个写一句"会出什么错"和"哪个检查会抓到"。

## E2 ★ 哪些现有测试会变？

**思路**：对每个测试问自己一句：它检查的是"**有没有**射出、有没有命中"，还是"**在第几帧**射出、命中"？
- 只关心"有没有"的测试，第一箭晚几帧多半还会通过（只要等待时间够长）。
- 关心"第几帧"的测试，结果就会变。

**事实**：
- `test_rules.gd:112-130`：等弓箭手自动射一箭，检查稻草人掉血。
- `test_wall_targeting.gd:49-55`：先把 `fire_cooldown` 设为 0，再看箭能不能打中墙边的稻草人。
- `test_burning_tint.gd`：数射出了几支箭，检查燃烧持续多少 tick。燃烧时长从**命中**开始算。
- `test_impact_burst_state.gd`：A6 记录过命中时间是 0.567 / 0.633 / 1.233 s，精确到帧。
- `test_burning_embers_state.gd`：同样用真实箭，有些场景检查"恰好射了一箭"。

**怎么写**：猜就行，比如"我觉得 X 不会变，因为它只数箭；Y 会变，命中时间会晚 N 帧"。猜错了也是 FRICTIONAL 的好素材。

---

## G1–G7 七个问答：概念讲解

### G1 路线和 read-back

- 你的稻草人走的是"**Sprite2D + AnimationPlayer 帧轨道**"。另一条精灵路线是 **AnimatedSprite2D + SpriteFrames**。
  - 帧轨道的 read-back 读的是 AnimationPlayer 里的 clip：每个 key 的时间、帧号、更新模式（discrete）、loop_mode。
  - SpriteFrames 不在 AnimationPlayer 里，AnimationPlayer 的 read-back **完全看不到**它，只能另外检查 SpriteFrames（动画名、帧数、速度、loop）。
- 你的弓箭手走的是"**用资源文本 key 的 cutout rig**"。另一条 rig 路线是**导入的 3D 模型**。
  - cutout rig 的 read-back：每条轨道指向的节点和属性（rotation、position）是否真实存在，key 时间是否等于 phase table。
  - 导入 rig 的轨道指向的是**骨骼名**（`Skeleton3D:Hips`），要用 `find_bone` 才能检查，而且必须在清空导入缓存后跑。
- 写的时候：每个 clip 说一句"我的路线的 read-back 能看到 ___，另一条路线的 read-back 看不到 ___"。

### G2 continuous 和 discrete

- `frame` 是一个整数。key 只说"0.0 s 时是 0，0.125 s 时是 1"。
- **discrete**：到了 key 的时间才跳到新值，中间保持不变。精灵帧要的就是这个。
- **continuous**：在两个 key 之间做插值，相当于算出 0.3、0.6…… 再取整，所以会在你没 key 的时间点换帧。
  如果两个 key 的帧号差得远（比如接缝处从 3 回到 0），中间会**扫过** 2、1。
- 写的时候：说出会看到什么，以及"为什么"：插值是对数值插值，它不知道这些数字代表图片格子。

### G3 Animation.step

- `step` 是编辑器里移动和插入 key 时的**吸附间隔**，默认 1/30 s。
- 你的走路是 8 fps，key 间隔 0.125 s。0.125 不是 1/30 的整数倍：最近的两个吸附点是 0.1 和 0.133。
  所以如果 step 留在默认值，在编辑器里拖动或插入 key，就会吸附到 brief 没写的时间。
- 射箭如果用 30 fps，step = 1/30 正好等于默认值，所以这个 clip 不受影响。
- 写的时候：两个 clip 的 step 各是多少，留默认会怎样。

### G4 唯一 authority

- **authority**：唯一负责写某个节点某个属性的东西。
- 稻草人 Sprite 的 `frame` ← 稻草人自己的 AnimationPlayer。
  同一个 Sprite 上还挂着 `burning_tint.gd`，每帧写**材质参数** `burn_mix`，不写 `frame`。这算不算第二个 authority，由你判断并说明理由。
- 弓箭手 rig 部件 ← AnimationTree（通过它下面的 AnimationPlayer 取 clip）。
  可能的第二个写入者：有人对那个 AnimationPlayer 直接调用 `play()` 或打开 autoplay；`archer.gd` 如果直接改部件的 rotation；preview 场景的脚本。
- 写的时候：每个节点写"authority 是谁，还有谁**可能**写它，我怎么防止"。

### G5 两个时钟

- **process tick**（`_process`，跟着画面帧）和 **physics tick**（`_physics_process`，固定每秒 60 次）是两个时钟。
- AnimationPlayer 和 AnimationTree 用 `callback_mode_process` 选在哪个时钟上前进。
- 弓箭手在 `_physics_process` 里读"到 active 了没"。如果 Tree 也在 PHYSICS 上，两者在同一个 tick，差 0。
  如果 Tree 在 IDLE（process）上，读到的值可能是上一个画面帧写的，最多差一个画面帧。60 fps 时约 1/60 ≈ 0.0167 s。
- 走路动画游戏不读，用哪个时钟只影响画面。
- 写的时候：两个 clip 各在哪个 tick，游戏在哪个 tick 读，最大差多少秒。

> **更正（Claude，2026-11-19，审阅第二轮）**：上面"两者在同一个 tick，差 0"是错的。在 Godot 4.7.2 里实测
> （父节点在 `_physics_process` 读、子节点 AnimationTree 用 PHYSICS 写）：同一个 physics tick 里父节点先跑、
> Tree 后跑，所以 key 写进去的值要到**下一个 tick** 才被读到；调 Tree 的 `process_priority` /
> `process_physics_priority` 不改变这个顺序。另外 `travel()` 进入新状态后，第一个更新停在位置 0，
> 下一个 tick 才开始前进。合计：`travel("shoot")` 到读到 8/30 s 处的 key 是 **18 个 tick，不是 16 个**。
> `playback.start("idle")` 则在同一个 tick 的 Tree 更新里立即生效。

### G7 导入 rig 不适用

- 导入的 3D 模型，每次重新导入都会从源文件（.glb）重新生成动画。在场景里改的 loop_mode 会被覆盖，所以要写在 `.import` 文件里。
- 你的 rig 是自己 key 在 `.tscn` 或 `.tres` 里的。loop_mode 就保存在这个文件里，重新导入碰不到它。
- 但"删掉 `godot/.godot` 再导入"这个 mutation 对你仍然有意义：图集 PNG 会按 `.import` 设置重新导入；场景要能从零加载（不能出现 "Failed loading resource"）；read-back 在全新缓存上也要通过。
- 写的时候：说明为什么不适用，以及这个 mutation 对你还检查了什么。

---

## 第三轮：英文 brief 里 7 处 TODO 的建议（Claude 在聊天中给出，2026-11-19，这里存档）

Rui 根据这些建议，直接在 `CHANGE-BRIEF.md` 里用英文写了这 7 处。★ 题只给了事实和思路，决定题给了推荐。

1. **★ 稻草人为什么用帧轨道**：事实——只有一根杆，没有能单独转的部件，"跳 + 倾斜"是整体姿势；
   每格由代码一次画好，可以逐像素控制，PNG 测试才能检查杆底；运行时旋转像素图会重采样。
   帧轨道在 AnimationPlayer 里，read-back 看得到，还能选时钟（G1 已写）。
   想清楚：4 帧 8 fps 的小循环值不值得拆部件做 rig。
2. **★ 弓箭手为什么用 cutout rig**：事实——15 帧里弓角度、弦长每帧都变，图集要画 15 张，rig 只 key 阶段边界；
   第 7 步调手感时挪 key 就行，不用重画；A8 的交叉淡入淡出能混合 transform，不能混合帧号。
   想清楚：哪一条是真正的理由。
3. **★ recovery 为什么从 14 帧压到 6 帧**：事实——下一次拉弓在放箭后 18 tick 开始，shoot clip 必须在那之前结束，
   所以 recovery 最多 8 帧；6 帧时两箭之间约 2 帧 idle。想清楚：为什么不是 8（没有停顿）、不是 2–3（收得太快）；
   startup 压到约 31%，recovery 约 43%。
4. **重开局时 `release_window`（推荐 B）**：游戏冻结时 Tree 可能已写 true、弓箭手还没读，重开局后第一个 tick 会补射，
   锁定目标也已被释放。A：`reset()` 直接写 false（authority 表要加例外）。B：弓箭手自己的 `shot_armed`，
   `travel("shoot")` 时置 true，出箭、取消、重开局时清掉（重开局同时清锁定目标），出箭要求两者都为 true；
   `release_window` 仍只有 Tree 写。
5. **第 11 节帧条帧号（推荐先写 clip 帧号）**：clip 第 0 / 8 / 9 / 15 帧，帧条帧号等 Step 2 pin 后填；
   如果 startup 第一个 key 是静止姿势，clip 第 0 帧看起来和 idle 一样。
6. **第 12 节预测 4、6（推荐移走）**：#4 写在实测之后，#6 已算出不会发生（第 20 tick = 0.26666666666666644，
   阈值也已改成 0.3 s）；移到"Known before prompt-1"，剩 4 条。
7. **第 13 节第 5 题（推荐补一句）**：同在 PHYSICS 上，但同一个 tick 里父节点先读、子节点 Tree 后写，
   晚 1 tick = 1/60 ≈ 0.0167 s，已算进 0.3 s 阈值。

审阅时又改了 3 处（Rui 同意"改好并提交"）：开头补来源说明；第 11 节 clip 第 15 帧注明是 clip 结束、第一帧 idle，
第 9 帧改成看得见的描述并指向日志；第 12 节编号改成 1–4，并注明对应问卷的 1、2、3、5。
