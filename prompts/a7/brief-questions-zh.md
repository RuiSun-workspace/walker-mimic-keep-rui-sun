# A7 brief 问卷（Rui 回答 → Claude 整理成英文 CHANGE-BRIEF.md）

**怎么用：** 直接在每题下面的 `答：` 后面写，中文就行，几个字也可以。
- **选择题**：写字母；同意建议就写"按建议"。也可以在最上面写一句"选择题全部按建议"。
- **标 ★ 的题**：必须是你自己的想法和你自己的话。作业规定 brief、phase table、预测和答案都由学生写。
  我可以给你讲概念，但不会替你写这几题的答案。
- 我会把你的回答原样翻译、整理成 brief 格式，不加你没说过的内容。你的这份原始回答会和 brief 一起
  commit。FRICTIONAL 里写明：内容是 Rui 的，翻译和排版是 Claude 做的。

---

## A. 稻草人走路（循环 clip）

**A1 ★** 这个动画告诉玩家什么？玩家为什么需要它？
答：它告诉玩家这个稻草人还在向城墙逼近，是当前要优先处理的威胁；停在城墙后不再走，则能让我一眼看出它已经开始攻击城门。

**A2** 稻草人没有腿，"走路"是什么样子？
(a) 在杆上一跳一跳 (b) 左右摇摆 (c) 上下颠 (d) 其他：____
答：a，在杆上一跳一跳，同时有一点左右倾斜。

**A3** 几帧、每秒几帧？建议 **4 帧 @ 8 fps**：一个循环 0.5 s，`step` = 0.125 s（不是默认的 1/30，第 3 个问答因此有内容可写）。
答：4 帧 @ 8 fps，一个循环 0.5 s，step = 0.125 s。

**A4** 格子大小和网格。建议 **56×72 px**（和现在单帧一样），**4 列 × 1 行**（hframes 4、vframes 1），整张图 224×72。
答：改为每格 64×80 px，4 列 × 1 行，整张图 256×80，hframes = 4，vframes = 1。原来的 56×72 四边只有约 1 px 空间，装不下跳起和倾斜；放大后仍把稻草人的原中心放在格子中心，所以游戏里的位置不变。图集沿用项目现有来源写法：由 `godot/tools/make_sprites.gd` 用代码生成，Claude Code 在 Rui 指导下编写，无第三方许可证，日期为 2026-11-19。

**A5** 帧顺序：每个格子是什么姿势？（例：0 = 站直，1 = 向左倾，2 = 站直但抬高，3 = 向右倾）
答：0 = 杆底着地并站直，y 偏移 0；1 = 身体向左倾、整体向上 3 px，y 偏移 -3；2 = 回到站直并向下压 1 px，y 偏移 +1；3 = 身体向右倾、整体向上 3 px，y 偏移 -3；然后回到 0。

**A6** 稻草人到了城墙（`at_wall`）以后，动画怎么办？
(a) 停在第 0 帧 (b) 继续循环 (c) 其他：____
答：a，停在第 0 帧，让“继续前进”和“已经在打城门”看起来不同。在稻草人节点上增加一个纯表现脚本，只读 `at_wall` 来决定播放 walk 或停止并设为第 0 帧；不修改负责游戏规则的 `scarecrow.gd`。

**A7** registration（每格里固定不动的点）选哪里？建议**杆的底端**，每一格都在同一个像素位置。
答：以杆底为 registration 参考：杆底的 x 在四格中完全相同；y 只允许 A5 规定的 0、-3、+1、-3 px 偏移，不能再有额外漂移。

**A8 ★** 如果循环接缝处多了一帧重复，玩起来会看到什么？
答：第 0 帧会在接缝处停留两倍时间，稻草人的跳动会每个循环卡一下；0.5 秒一循环，所以一秒会卡两次。

---

## B. 弓箭手射箭（蓄力 clip）

**B1 ★** 这个动画告诉玩家什么？玩家为什么需要它？
答：拉弓是在预告弓箭手马上会朝目标射击，放箭确认箭已经出手，收弓说明这一箭结束。因为射击是自动的，玩家需要靠这个动作判断下一箭的时间和方向。

**B2 ★ 参考测量**：找一段射箭视频（真人或游戏都行），逐帧数一遍：
从开始拉弓到放箭几帧，放箭那一下几帧，放箭后收弓几帧。写下视频来源（链接）、视频帧率，以及你数到的帧数。
（逐帧方法：PotPlayer 按 `F`、mpv 按 `.`、VLC 按 `E`。）
答：来源：https://www.youtube.com/watch?v=wwbc7yBwDBs（Recurve Bow Super Slow Motion Archery - Shooting Arrows at Different Speeds）。视频说明写明以 60 fps 拍摄。我只数视频开头约 0:00–0:03 的实时速度镜头，没有数后面重复播放的慢放镜头；这一段逐帧数到约：开始拉弓到松弦前 52 帧，松弦和箭离弓 2 帧，放箭后手臂回落 28 帧。因为所选段是实时速度，不除慢放倍数；换算到 30 fps 是 26、1、14 帧。真人动作太长，游戏里需要压缩。

**B3** phase table 用什么帧率？建议 **30 fps**，和 Movie Maker 帧条一帧对一帧。
答：30 fps。

**B4** startup / active / recovery 各几帧？由 B2 的测量换算到 B3 的帧率。
**限制**：三段加起来不超过 18 帧（30 fps 下等于 0.6 s 的射击间隔）；startup 必须短于 0.6 s。
答：startup 8 帧，active 1 帧，recovery 6 帧，共 15 帧。真人拉弓换算后有 26 帧，我把它压到 8 帧，使自动射击仍然利落并能放进 0.6 s 间隔。

**B5** rig 拆成哪几块？建议：**身体**（不动）+ **弓**（绕握把旋转、往后拉）+ **弦**（拉伸）。其他想法：____
答：身体（保持稳定）+ 弓（以握把为轴旋转并向后拉）+ 弦（随拉弓伸缩）。

**B6** 射箭的每个阶段里，玩家能不能左右移动？
(a) 三个阶段都能移动，移动不打断射箭（建议）
(b) startup 里移动会取消这一箭
(c) 其他：____
答：a，startup、active、recovery 三个阶段都能左右移动，而且移动在三个阶段都不打断射箭。

**B7** startup（拉弓）期间目标没了（死了、离开射程范围），怎么办？
(a) 取消，回 Idle，冷却照常（建议）
(b) 换最近的新目标继续拉
(c) 照原方向放箭
答：a。开始拉弓时锁定一个目标；如果它在 startup 中死亡或离开锥形范围，就取消并立即回到 Idle，冷却照常，也不换新目标。进入 active 后箭已经出手，目标消失不影响；recovery 中也继续收弓。真正放箭时朝锁定目标在该时刻的位置射。

**B8** 射箭中途按暂停（Esc/P）：动画冻结在当前帧，恢复后从那一帧继续。同意吗？
答：同意；无论暂停发生在 startup、active 还是 recovery，都冻结当前帧，恢复后从该帧继续。

**B9** 射箭中途游戏结束（赢或输）：`World` 被禁用（`main.gd:95`），动画冻结、箭不射出。同意吗？
答：同意。若射箭中途用 R/Enter 重新开局，AnimationTree 立即回 idle，`release_window` 复位为 false，并且不能补射一支箭。

**B10** 箭在 active 的哪一帧出？建议 **active 的第一帧**。
答：active 的第一帧。

---

## C. 状态机（AnimationTree）

**C1** 驱动方式？
(a) **push（建议）**：弓箭手脚本在拉弓开始时调 `travel("shoot")`，取消时 `travel("idle")`，这两条转换设为 Enabled；射完回 idle 那条设为 Auto + At End。时机完全由脚本控制，帧边界测试最稳。
(b) **pull**：所有转换都是 Auto + advance_expression，由 Tree 自己判断。
答：a，push。idle 使用只有一个静止姿势 key 的 clip，`LOOP_NONE`。开始拉弓时脚本调 `travel("shoot")`；状态机中只保留一条 `shoot → idle` 转换，设为 Auto + At End，让完整射击自然返回。startup 取消时不能调 `travel("idle")`，因为它会沿这条 At End 转换等到 clip 末尾；要调 `playback.start("idle")` 立即跳回 idle，不经过转换。同一对状态不能再添加第二条转换。

**C2** `advance_expression_base_node` 设在哪？建议设为 **Archer 节点**。push 方式其实不用表达式，但 brief 里照样写明，防止以后加表达式时它默默失效。
答：设为 Archer 节点（AnimationTree 的上一级，路径 `..`）。

**C3** 状态之间的交叉淡入淡出 `xfade_time`：建议**全部 0**，切换要干脆，帧条也好读。
答：全部设为 0。

---

## D. 两个时钟

**D1** 稻草人 AnimationPlayer 的 `callback_mode_process`：建议 **IDLE**（默认值；游戏不读走路动画的任何东西）。
答：IDLE。

**D2** 弓箭手 AnimationTree 的 `callback_mode_process`：建议 **PHYSICS**，和弓箭手 `_physics_process` 读放箭时机用同一个 tick。
答：PHYSICS。

**D3** 游戏怎么知道"到 active 了"？
(a) **clip 里 key 一个属性（建议）**：比如弓箭手的 `release_window`，弓箭手在 `_physics_process` 里读它，第一次变成 true 时出箭。这正是作业说的 "keyed gameplay fact"，课程例子 `02-hitbox-window` 也是这么做的。
(b) 读当前播放位置，和 phase table 的时间比较。
答：a，在 shoot clip 里 key 弓箭手的 `release_window` 属性：active 第一帧设为 true，recovery 第一帧 key 回 false，idle clip 也 key 为 false。弓箭手在 `_physics_process` 第一次读到 true 时生成箭；AnimationTree 是这个属性的唯一写入者，`archer.gd` 只读。

---

## E. 预测 ★

**E1 ★** 至少写 3 个你觉得会出错的地方，每个配一个能抓到它的检查。可以参考这些候选，但要用你自己的话写、写你真的觉得会发生的：
Godot 3 名字（`loop = true`）、帧轨道留在 continuous、`step` 留默认、`advance_mode` 留在 Enabled 导致卡住、
编造不存在的属性、用 `==` 比较 key 时间、Tree 和弓箭手不在同一个 tick 导致放箭差一帧、
新图集切错网格、稻草人在格子里漂移、`burning_tint.gd` 和 AnimationPlayer 同时写一个 Sprite。
答：1）我觉得最容易把帧轨道留成 continuous，结果帧号会在 key 之间乱跳；read-back 检查轨道是否为 UPDATE_DISCRETE。2）新图集可能切成错误的 hframes，画面会显示错格；read-back 检查网格和帧号范围，再看帧条。3）AnimationTree 和弓箭手脚本如果不在同一个 tick，箭可能晚一帧；用 active 前一帧、当帧、后一帧的边界测试检查。4）agent 可能尝试给 `shoot → idle` 建两条转换，Godot 会拒绝第二条；结构测试检查这对状态之间恰好一条 Auto + At End 转换，并用 startup 取消测试确认 `playback.start("idle")` 能立刻回 idle。5）四个走路格子的杆底可能没有按 0、-3、+1、-3 px 对齐，播放时会额外抖动；写一个读取 PNG 的测试检查每格杆底 x 和规定的 y 偏移，再用帧条目测。6）冷却逐 tick 相减后可能比 0.2667 s 多一点点，导致开始拉弓条件晚一个 physics tick 才成立；在阈值前一 tick、阈值 tick、后一 tick 做边界测试，并使用带 epsilon 的 `<=` 判断。

**E2 ★** 哪些现有测试的结果会因为"第一箭晚 startup 帧"而改变？怎么变？凭感觉猜就行，pin 之后会验证；猜错了正好是 FRICTIONAL 的素材。
涉及开火时机的测试：`test_rules`、`test_wall_targeting`、`test_burning_tint`、`test_impact_burst_state`、`test_burning_embers_state`。
答：startup 的 8 帧按 30 fps 算是 0.267 s，也就是 60 Hz 下约 16 个 physics tick。我猜 `test_rules` 和 `test_wall_targeting` 仍会通过，因为它们给命中留的等待时间足够，只是第一次伤害晚 8 帧（0.267 s）。`test_burning_tint` 的命中采样序号会后移约 16 个 physics tick，但它从真实命中开始检查颜色和只射一箭，所以结论应不变。`test_impact_burst_state` 记录了精确命中时间，0.567 / 0.633 / 1.233 s 这些绝对时间会因对应射击晚 8 帧（0.267 s）而后移，相关帧边界需要重新 pin；三次 burst 是否重叠可能仍不变。`test_burning_embers_state` 里真实箭的 fired/hit 帧也会晚 8 帧（0.267 s），但多数场景是等信号再检查“恰好一箭”，我猜仍会通过；最可能出问题的是有固定 120 physics tick 上限的移动场景。

---

## F. 帧条

**F1** 预览场景用真实关卡的哪一段做背景？建议 **x ≈ 640 处的草地 + 城墙走道**，也就是弓箭手平时站的地方。
答：用 x ≈ 640 处的草地和城墙走道，保持真实关卡的 1280×720、1:1 比例。

**F2** 触发帧（开始拉弓）设在帧条第几帧？建议**第 10 帧**，前面留一段 idle 做对比。
答：第 10 帧触发。帧 10：刚开始拉弓，弓和弦从 idle 姿势开始后移；帧 18：进入 active，弦松开，箭在这一帧离开弓；帧 19：`release_window` 回 false，开始收弓；帧 25：收弓结束，身体、弓和弦都回到 idle 静止姿势。

---

## G. 七个问答 ★（用你自己的话，中文即可）

不懂的概念可以先问我，我讲清楚后你再写。

**G1** 两个 clip 各走哪条路线？这条路线的 read-back 能看到什么、另一条路线的 read-back 看不到？
答：稻草人走 Sprite2D + AnimationPlayer 的 frame 轨道，read-back 能看到 key 时间、帧号、discrete 更新、step 和 loop_mode；如果改用 AnimatedSprite2D + SpriteFrames，这些内容不在 AnimationPlayer 里，原 read-back 看不到。弓箭手走资源文本里 key 的 2D cutout rig，read-back 能验证每条 rotation/position 轨道的节点、属性和 key 时间；导入的 3D rig 要另外按 Skeleton3D 的骨骼名检查，普通属性检查看不到骨骼是否存在。

**G2** 如果帧轨道留在 continuous（连续更新），两个 key 之间精灵会显示什么？为什么？
答：它会在两个整数帧号之间插值并取整，可能在没有 key 的时刻提前换格；从 3 回到 0 时还会倒着扫过 2、1。因为插值器只把 frame 当数字，不知道每个整数代表一张独立图片。

**G3** 你的 `Animation.step` 是多少？如果留在默认值 1/30，你的 key 时间会怎样？
答：走路 clip 的 step 是 0.125 s，射箭 clip 的 step 是 1/30 s。走路如果留默认 1/30，0.125 s 不是它的整数倍，编辑器插 key 或拖 key 时会吸到约 0.100 或 0.133 s，破坏 8 fps 的等间隔；射箭本来就是 30 fps，所以不受影响。

**G4** 每个动画节点唯一的 authority 是谁？项目里还有什么东西可能写它？
答：稻草人 Sprite.frame 的唯一 authority 是它自己的 AnimationPlayer；纯表现脚本只决定播放 walk 还是停在第 0 帧，`burning_tint.gd` 只写同一 Sprite 材质里的 `burn_mix`，不写 frame。弓箭手 rig 部件 rotation/position 的唯一 authority 是 AnimationTree 通过其 AnimationPlayer 播放的 clip；`release_window` 的唯一写入者也是 AnimationTree，`archer.gd` 只读。要禁止别的脚本直接改 rig 部件或 `release_window`，也不对 AnimationPlayer 调 play()、不开 autoplay，预览脚本只驱动状态机。

**G5** 每个 clip 在哪个 tick 上前进？游戏在哪个 tick 上读 active 窗口？如果两者不同，最大差多少秒？
答：稻草人走路在 IDLE/process tick 前进，游戏不读取它。弓箭手 shoot 在 PHYSICS tick 前进，`archer.gd` 也在 `_physics_process` 读取 active 窗口，所以设计上没有跨时钟延迟；如果 Tree 错放到 IDLE，最坏会差一个画面帧，按 60 fps 约 0.0167 s。

**G6** 你的循环用什么接缝规则（按轨道类型）？接缝处多一帧重复，玩起来是什么样？
答：离散 frame 轨道不在结尾重复第 0 帧：key 放在 0、0.125、0.25、0.375 s，clip 长 0.5 s，让最后一个 key 到结尾仍是 0.125 s。若以后有循环的 transform 轨道，末尾姿势也必须能平滑回到开头，不能突然跳；shoot clip 不循环。接缝多一帧会让第 0 姿势每圈停两倍久，看起来每 0.5 s 卡一下。

**G7** 你的 rig 不是导入的。为什么 loop mode 要放在 importer 设置里这条对你不适用？Step 6 的"清空导入缓存"那个 mutation 对你的 keyed rig 还能检查到什么？
答：我的 cutout rig 和动画 key 直接保存在 `.tscn`/`.tres` 资源文本里，不会由 `.glb` 重新导入覆盖，所以 loop_mode 也保存在这个资源中，不需要写 importer 的逐动画设置。清空 `godot/.godot` 后仍会重新导入 PNG 图集，并能检查场景能否从零加载、资源路径是否缺失、网格导入是否正确，以及 fresh cache 下 read-back 是否仍通过。

---

## 审阅第二轮之后的决定（Claude 记录，Rui 2026-11-19 回复"改成 0.3 s"和"全部按建议"）

以下是 Claude 在审阅中提出、Rui 同意的修改，不是 Rui 原来写的答案。上面的原始回答保持不动。

1. **开始拉弓的阈值是 0.3 s（18 个 physics tick），不是 0.2667 s。** 依据：`probes/probe_tick_order.gd` 实测
   从 `travel("shoot")` 到弓箭手读到 active 帧的 key 是 18 个 tick（进入状态时在位置 0 停 1 个 tick；同一个 tick 里
   父节点先读、子节点 Tree 后写，再晚 1 个 tick）。用 0.2667 s 的话两箭间隔会变成 38 tick = 0.633 s。
   新增测试：连续两次出箭恰好相隔 36 tick。
2. **C1 补充**：Start → idle 这条转换设为 Auto（测试里它留在默认的 Enabled 时，状态机一直停在 Start）。
3. **A6 补充**：稻草人在城墙时播放一个只有一个 key（frame 0）的 `hold` clip；表现脚本只调用
   `play("walk")` 或 `play("hold")`，不直接写 `Sprite.frame`，AnimationPlayer 仍是 frame 的唯一写入者。
4. **A4 补充**：新图集是新文件 `godot/assets/sprites/scarecrow_walk.png`；原来的 `scarecrow.png` 不变
   （A6 的两个 preview 场景和 `tools/capture_burn_values.gd` 都直接用它）。
5. **A5 补充**：第 1、3 帧的倾斜是以杆底为轴旋转 5°（两端草把横移约 4 px，帽顶约 6 px；放进 64×80 后左右各剩约 1 px），向左为第 1 帧、向右为第 3 帧。
6. **B9 措辞**：游戏进行中 R/Enter 不起作用（`main.gd:82`），所以这条规则是"游戏在射箭中途结束、
   画面冻结之后，再按 R/Enter 重新开局"。
