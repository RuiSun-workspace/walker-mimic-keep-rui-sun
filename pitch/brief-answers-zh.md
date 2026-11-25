# Rui's answers for PROJECT-BRIEF.md (raw, 2026-11-24)

These are Rui's own words and choices. Claude drafted PROJECT-BRIEF.md from them plus facts read
from this repository; anything in the brief that is Claude's proposal is marked there.

## Free answers (verbatim, Chinese)

1. 我玩过之前类似的肉鸽类的打怪小游戏，但我忘了之前玩的游戏叫什么了，我认为我这个游戏和之前游戏不同的点就是我希望在传统升级技能打怪的游戏基础上加入不同属性，然后不同属性打到不同的怪物上伤害不同，同时不同属性之间也能反应造成伤害或者控制效果。
2. 我目标的应聘岗位是游戏开发和游戏数值分析与策划
3. 我在这门课前只会使用C语言的easyx函数库制作简单的平面游戏，在这个课程中我学会了使用godot等3D游戏的制作技术。我希望通过这个游戏展现我对游戏制作的了解和我控制游戏数值的能力
4. 我对项目的最终期望就是一个有一些关卡还有无尽模式的游戏完成品，同时还需要设计各种不同的可选择的增益，我希望展现我的创意，同时做出来一个我愿意玩的简单小游戏

## Choices from Claude's question card (2026-11-24)

| Question | Rui chose |
|---|---|
| Final-project scope | 一关 + 无尽模式 (one level + endless mode; more levels later) |
| Target role | Technical designer |
| Reader | Hiring manager |
| Comparable game actually played | 原神（我玩过）; 我去查那个肉鸽游戏的名字 (Rui will look up the roguelite's name) |

## Round 2 (verbatim, 2026-11-24)

Answering the TODOs and proposals in draft 1:

> 那个肉鸽是个微信小游戏，应该是抄的什么别的游戏，我玩过的版本绝对没有属性反应，但是我忘了游戏名了，反应暂时就冰加火加雷吧，我之前使用easyx做过一个连连看游戏，源代码可能不太好找了，但是游戏截图应该是还有，需要的话我可以找出来，导出目标就先这样吧

Claude's reading, applied in draft 2: elements = fire, ice, lightning with the two proposed reactions
(fire on chilled = extra damage, ice + lightning = stun); the roguelite stays unnamed; export target
Windows desktop; the EasyX tile-matching (连连看) game is the prior-work evidence, screenshots only.

## Round 3 (2026-11-24)

Rui sent a screenshot of the 连连看 board and then the 2022 course report (a local .docx, not copied
into this repo: it holds a student number and a teacher's name). Rui's words:

> 四年前做的了，我都忘了，我把实验报告发给你，你看看什么能用吧

Facts Claude took from the report into draft 3: hand-in date 2022-05-11; C + EasyX on Windows;
image slicing + shuffle, path check with at most two turns, ms timer on the victory screen, music
via mciSendString; testing "游玩10+次，无bug". Tile portraits and backgrounds are third-party art →
not published.
