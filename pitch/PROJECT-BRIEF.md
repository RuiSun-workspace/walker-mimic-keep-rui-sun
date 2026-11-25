# Mimic Keep — final project brief

Rui Sun · CSYE 7270 · draft 3, 2026-11-24

Drafted by Claude from Rui's answers (`brief-answers-zh.md`, kept verbatim) and from facts read in
this repository. `[proposed]` = a design detail Claude suggested that Rui has not yet confirmed.
`TODO(Rui)` = a fact only Rui can supply.

Stack: Godot 4.7.2, GDScript, Forward+ renderer, export target Windows desktop.

## 1. What is it?

Mimic Keep is a short 2D wall-defence roguelite in which the archer's arrows carry elements, each
enemy type takes different damage from each element, and two elements on the same enemy react.
When it is done, it will be a Windows desktop build with one level that runs from a title screen
to an end screen, plus an endless mode that keeps going until the gate falls.

## 2. Why would anyone care?

Most level-up-and-fight games ask the player to pick bigger numbers. In Mimic Keep the level-up
choice will be which element to add or strengthen, and the right answer will depend on which
enemies are coming and what the elements do together.

## 3. What does it give the player, and what makes it different?

It will give a player who likes short runs a reason to think about matchups instead of only stats:
three elements — fire, ice and lightning — where fire burns straw, ice chills, fire on a chilled
enemy deals extra damage, and ice plus lightning stuns. The reaction rules are a first version and
may change after playtests; any change will be logged in FRICTIONAL.md.

Comparables Rui has played:

- **Genshin Impact.** It has element reactions, but inside an open-world action RPG where the player
  triggers them with hand-aimed character skills. Mimic Keep will put reactions into an auto-fire run
  of a few minutes, where the player's only decisions are position and which upgrade to take.
- **A level-up roguelite on WeChat Mini Games.** Rui played it but no longer remembers its name, so it
  cannot be named here. It had level-up skill choices; the version Rui played had no element
  reactions. Mimic Keep keeps the level-up loop and adds elements that change damage per enemy and
  react with each other.

## 4. Who opens it, and what do they do?

Target role: **technical designer** (systems and numbers, implemented by the designer).
Reader: **hiring manager**.

First sixty seconds: double-click the exe, press Enter on the title screen, move with A/D. The archer
fires on its own, so the reader is playing within seconds without reading anything. The first
level-up card choice will appear inside the first minute `[proposed timing]`.

## 5. What does it prove?

Already shown in earlier assignments (see *Exists today*): a hand-written shader, two particle effects
with a GPU reading, an AnimationTree state machine with frame-exact edge tests, mutation tests, and
human checks recorded in Rui's own words, with agent sessions run on scoped tool lists.

New for the final project: a damage table (element × enemy) that will be pinned by headless tests, so
a reader can rerun it, and a tuning log that will record each balance change with the playtest note
or simulation run that caused it. A reviewer could fairly conclude that Rui can build a combat system
and tune its numbers with evidence. They could not conclude anything about art or audio, which stay
placeholder.

## 6. What is in, what is out, what comes first?

- **In:** three elements (fire, ice, lightning), two reactions, 3 enemy types with different
  resistances `[proposed]`, level-up cards, one level, endless mode.
- **Out (deliberately):** no save system and no permanent unlocks between runs; no second level; no
  multiplayer.
- **First:** ice and the fire-on-chilled reaction on the existing scarecrow, in the existing room. Someone
  would know it ran because a headless test checks the reaction damage at an exact tick, and a
  captured clip shows the reaction in play.

## 7. What could sink it?

Balance. Elements × enemies × upgrade cards multiply, so one build may beat everything and make the
choice meaningless. What Rui will do: keep the first version at three elements, and extend
`godot/tools/balance_sim.gd` (bot runs over fixed seeds) to report time-to-kill per element and enemy
and win rate per build, so a dominant build shows up as a number before a playtest.

## 8. Why this project?

Mostly new learning. Before this course Rui's game-making was a university course project: a
tile-matching (Lianliankan) game in C with the EasyX library, handed in 2022-05-11 — tiles sliced from
one image and shuffled, a path check of at most two turns, a millisecond timer, music. The source may
be lost and the game's art is not Rui's, so only its console print of the board array is shown
(`pitch/evidence/2022-lianliankan-console.png`).

Its report says it was tested by "playing 10+ times, no bugs". In this course testing came to
mean pinned headless tests, mutation runs and recorded human checks. Godot, GDScript, shaders,
particles, animation and directing an agent are all new from this course; the tags below are the
evidence. What Rui wants to show is game-making knowledge and control of game numbers; the tuning
evidence in this repository so far is one spawn-rate change after Rui's first playtest, checked with
a simulation Claude wrote.

## Exists today

| What | Where |
|---|---|
| Playable prototype: archer slides on X and auto-fires fire arrows; scarecrows descend; Burning 4 s; gate 100 HP; survive 90 s to win; restart | tag `mk-prototype` (`cab3d5c`) |
| Every gameplay number in one file, `godot/game/tuning.gd` | `mk-prototype` onward |
| Spawn interval 2.4→0.9 s changed to 3.0→1.5 s after Rui's playtest ("目前的怪物数量太多了，很难通关"), checked with `balance_sim.gd` (written by Claude): chasing bot 8/8 wins, idle bot 1/8 | `mk-prototype`; FRICTIONAL.md |
| Burning tint shader (Rui hand-wrote it) and a 3D wooden-shield material showcase | tag `a5` (`f71d358`) |
| Hit burst and burning embers (GPUParticles2D); frame GPU time 0.06–0.07 ms with and without effects, Visual Profiler, RTX 3070 Laptop GPU | tag `a6` (`6046ae6`); TEST-REPORT A6.7 |
| Scarecrow walk sprite sheet; archer cutout rig with an AnimationTree state machine; arrow released on the shot's active frame | tag `a7` (`39f3fe8`) |
| Headless checks (16 test suites + 2 check scripts in `godot/tests/`), incl. edge tests 325/0 and pins 38/0; mutation runs; Rui's human checks | tag `a7`; TEST-REPORT.md |
| `element` parameter already passed from arrow to `Scarecrow.hit()` (only `fire` exists) | `godot/game/arrow.gd:22` |

## Will exist

Ice and lightning; the two reactions; two more enemy types with resistances; level-up cards; title
and end screens; endless mode; the pinned damage-table test; the extended balance simulation; a tuning
log; a Windows export that a stranger can download and run.
