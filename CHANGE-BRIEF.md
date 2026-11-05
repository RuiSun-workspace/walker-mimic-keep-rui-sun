CHANGE-BRIEF — Assignment 6: Particle Effects
Author: Rui Sun
Course: CSYE 7270, Fall 2026
Project: Mimic Keep
Engine: Godot 4.7.2
Renderer: Forward+

The Assignment 5 version of this brief is preserved at tag a5. This is the original Assignment 6 brief, dated 2026-11-05. If the design changes after implementation begins, each revision will be added below the original text with its date instead of silently replacing the earlier decision.
1. The Jobs
Effect A — Arrow Impact Burst
This effect tells the player that an arrow actually hit a scarecrow. It separates a successful hit from an arrow that only passed nearby or left the screen.

The current hit occurs in godot/game/scarecrow.gd:33-39. godot/game/arrow.gd:22 calls Scarecrow.hit(), but there is currently no hit signal that presentation code can observe.

I will add this presentation-only signal to scarecrow.gd:
signal hit_taken(position: Vector2)
An accepted call to hit() will emit hit_taken(global_position) after damage is applied and before the death check. The current collision system does not calculate a precise surface contact point, so the scarecrow’s global centre is the defined impact position.

The signal does not change HP, Burning, movement, collision, or any other gameplay state. It only exposes an event that has already happened.
Effect B — Burning Embers
This effect is a feedback loop. It tells the player that a scarecrow is still Burning and gives a visual indication of how much burn time remains.

Its authoritative state remains in godot/game/scarecrow.gd:
- burning_started at line 8 marks the first ignition.
- burning_ended at line 9 marks normal burnout.
- burn_time_left at line 16 stores the remaining time.
- ignite() at lines 42–46 refreshes the timer without emitting another burning_started signal when the scarecrow is already burning.
The particle driver will therefore read burn_time_left every frame. It cannot rely only on the two signals.

Effect B uses value-driven amount_ratio and turbulence. Effect A does not use either feature. This is also why Effect B must use GPUParticles2D: CPUParticles2D in Godot 4.7.2 does not provide these properties.
2. Intent
Effect A — Arrow Impact Burst
- Timing phases: The first frame should contain a sharp yellow-white flash at the hit point. The flash should expand and disappear quickly, while a few straw fragments remain briefly and fall away. The whole effect should be almost gone before the following hit, although the last fragments may overlap the start of the next burst.
- Background contrast: The bright flash should be visible against meadow grass, grass tufts, and the dark gate. The darker orange-brown straw fragments should remain visible against the gray stone wall and pale walkway. The flash and fragments provide opposite kinds of contrast rather than depending on one color alone.
- Scale against the character: The initial flash should be smaller than the scarecrow’s head. The fragments may spread to approximately the width of the scarecrow, but the burst should not cover nearby enemies.
- Change over life: The flash begins small and bright, briefly expands, changes from pale yellow to orange, and fades. The fragments move outward, fall under gravity, become darker, shrink, and fade.
- Variation: Each burst varies the speed, direction, damping, and size of its straw fragments. This prevents repeated hits from looking like the same animation replayed every time.
- Emitters: The effect has two emitters. One creates the short additive flash, and the other creates falling straw fragments.
Effect B — Burning Embers
- Timing phases: Ignition begins with a full but readable flow of embers. The flow becomes less dense as the remaining burn time decreases. When Burning ends, no new particles are created, while particles that already exist are allowed to finish fading.
- Background contrast: Bright yellow-orange embers should read clearly against the meadow, grass tufts, and dark gate. A second layer of faint dark smoke provides contrast against the brighter stone wall and walkway.
- Scale against the character: Most particles should stay close to the scarecrow’s body. Embers and smoke may rise above its head, but the effect should not become large enough to look like a separate enemy or environmental fire.
- Change over life: Embers rise, change from pale yellow to orange-red, shrink, and disappear. Smoke starts compact, expands slightly, drifts sideways, and fades.
- Variation: Particle velocity, size, damping, and direction vary within a limited range. Smoke also uses mild turbulence so that it does not rise in identical straight lines.
- Emitters: The effect has two continuous emitters: one for bright embers and one for faint smoke.
3. Settings
Both effects use GPUParticles2D. Godot defines amount_ratio as a way to vary emission without restarting the particle system, while local_coords controls whether existing particles follow their parent. See the Godot GPUParticles2D documentation. Turbulence is supplied by ParticleProcessMaterial, not by the particle node itself. See the Godot ParticleProcessMaterial documentation.
Effect A — GPUParticles2D
GPUParticles2D is used so that Step 6 can convert and inspect its generated particle shader. Each accepted hit creates a new burst scene under a presentation-only World/Effects container. Reusing one one-shot node is not allowed because a second hit could occur before the first one has finished.
A1 — Impact Flash
Area	Setting
Node	GPUParticles2D
Initial state	emitting = false
Amount	10
One shot	true
Explosiveness	1.0
Lifetime	0.28 s
Emission shape	Sphere/circle with radius 3 px
Direction and velocity	Radial spread; initial_velocity_min = 80, initial_velocity_max = 140
Spread	180°
Gravity	(0, 100)
Damping	damping_min = 30, damping_max = 50
Scale	scale_min = 0.5, scale_max = 1.1
Color ramp	Pale yellow-white at the start, orange near the middle, orange with zero alpha at the end
Scale curve	0.35 at birth, 1.20 near the first third, 0.0 at the end
Texture	Code-generated soft white dot, saved as a new particle texture
Blend mode	Additive
local_coords	false; emitted particles remain at the impact position
visibility_rect	Rect2(-64, -64, 128, 128), manually set and then checked with Generate Visibility Rect
Preprocess	0.0; the burst must not exist before a hit


The color-ramp stops will be:
- 0.0: Color(1.0, 1.0, 0.80, 1.0)
- 0.35: Color(1.0, 0.55, 0.08, 0.90)
- 1.0: Color(1.0, 0.25, 0.02, 0.0)
A2 — Straw Fragments
Area	Setting
Node	GPUParticles2D
Initial state	emitting = false
Amount	12
One shot	true
Explosiveness	1.0
Lifetime	0.80 s
Emission shape	Sphere/circle with radius 5 px
Direction and velocity	Mainly upward; initial_velocity_min = 70, initial_velocity_max = 130
Spread	150°
Gravity	(0, 260)
Damping	damping_min = 5, damping_max = 15
Scale	scale_min = 0.4, scale_max = 0.9
Color ramp	Golden straw at birth, brown later, transparent dark brown at the end
Scale curve	0.70 at birth, 1.0 shortly after birth, 0.0 at the end
Texture	Code-generated narrow white straw-chip texture
Blend mode	Mix
local_coords	false; fragments do not follow a moving or dying scarecrow
visibility_rect	Rect2(-96, -96, 192, 192), manually set and checked
Preprocess	0.0; nothing should appear during scene loading


The flash and fragment emitters both have nonzero gravity, a color ramp, and a scale curve. These settings must remain present so the generated shader in Step 6 contains the corresponding logic.
Effect B — GPUParticles2D
GPUParticles2D is required because the visual density is driven by amount_ratio, and the smoke uses turbulence. The emitters belong to each individual scarecrow so every instance can have its own value.

Both emitters use:
amount_ratio = clamp(burn_time_left / 4.0, 0.0, 1.0)
The driver changes amount_ratio, not amount. Changing amount would restart or reallocate the system instead of smoothly changing the emission density.
B1 — Embers
Area	Setting
Node	GPUParticles2D
Initial state	emitting = false, amount_ratio = 0.0
Amount	18
One shot	false
Explosiveness	0.0
Lifetime	0.90 s
Emission shape	Box with extents (18, 30, 0)
Direction and velocity	Upward; initial_velocity_min = 25, initial_velocity_max = 45
Spread	25°
Gravity	(0, -20)
Damping	damping_min = 5, damping_max = 10
Scale	scale_min = 0.35, scale_max = 0.70
Color ramp	Pale yellow, orange, then transparent red-orange
Scale curve	0.60 at birth, 1.0 near the middle, 0.10 at the end
Texture	The same code-generated soft-dot texture used by the impact flash
Blend mode	Additive
local_coords	true; embers follow the moving scarecrow while it is alive
visibility_rect	Rect2(-48, -80, 96, 120), manually set and checked
Preprocess	0.0; a non-burning scarecrow must not begin with particles


Color-ramp stops:
- 0.0: Color(1.0, 0.95, 0.63, 1.0)
- 0.45: Color(1.0, 0.54, 0.12, 0.90)
- 1.0: Color(0.85, 0.29, 0.07, 0.0)
B2 — Smoke
Area	Setting
Node	GPUParticles2D
Initial state	emitting = false, amount_ratio = 0.0
Amount	8
One shot	false
Explosiveness	0.0
Lifetime	1.20 s
Emission shape	Box with extents (16, 26, 0)
Direction and velocity	Upward; initial_velocity_min = 12, initial_velocity_max = 22
Spread	35°
Gravity	(0, -8)
Damping	damping_min = 1, damping_max = 4
Scale	scale_min = 0.60, scale_max = 1.0
Color ramp	Transparent brown-gray smoke that fades completely
Scale curve	0.50 at birth, 1.40 near the end, then 0.0
Turbulence	Enabled; influence minimum 0.15, maximum 0.30
Texture	Code-generated soft smoke dot
Blend mode	Mix
local_coords	true; smoke follows the living scarecrow
visibility_rect	Rect2(-64, -100, 128, 150), manually set and checked
Preprocess	0.0; the system begins only after ignition


Color-ramp stops:
- 0.0: Color(0.29, 0.19, 0.15, 0.35)
- 0.55: Color(0.22, 0.16, 0.14, 0.20)
- 1.0: Color(0.16, 0.13, 0.12, 0.0)
The new particle textures will be generated by committed project code. No existing sprite or source texture will be edited.
4. Measurable Rules
Rule A1 — Trigger
Every accepted call to Scarecrow.hit() emits exactly one hit_taken event and creates exactly one impact-burst instance.

The effect must not trigger during scene loading, from movement, from burning damage ticks, when Burning ends, or when an arrow leaves the screen without hitting anything.
Rule A2 — Position
The burst origin must equal the position carried by hit_taken, with a tolerance of 1 px.

For the current collision model, this position is the scarecrow’s global centre at the moment the hit is accepted.
Rule A3 — Retrigger and Overlap
Retrigger behavior is overlap. Each hit creates a separate burst instance. A new hit must not restart, clear, or reuse an earlier burst.

The longest emitter lifetime is 0.80 s, while automatic arrows are fired at intervals of 0.60 s. Therefore, normal gameplay can contain at most:
ceil(0.80 / 0.60) = 2 impact bursts
at the same time.

Each burst has 10 + 12 = 22 particles, so the normal peak is 44 allocated Effect A particles.
Rule A4 — Lethal Hit
The hit signal is emitted before the scarecrow’s death check. If the hit kills the scarecrow, the burst is created under World/Effects, not under the scarecrow.

The scarecrow may be freed in the same frame, but the burst must remain for up to 0.80 s and finish normally.
Rule B1 — Start and Normal End
When burning_started is received:
- Both emitters set emitting = true.
- Both emitters set amount_ratio = 1.0.
When burning_ended is received:
- Both emitters set amount_ratio = 0.0.
- Both emitters set emitting = false.
- Already-emitted particles may finish their remaining lifetime.
- No new particles may be emitted.
Rule B2 — Value Mapping
Both B emitters use the same mapping:
burn_time_left	Expected amount_ratio
4.0 s	1.00
3.0 s	0.75
2.0 s	0.50
1.0 s	0.25
0.0 s	0.00


The driver updates the value once per frame. The permitted timing tolerance is one frame at the tested frame rate.

Tests must inspect amount_ratio. They must not accept a change to amount as equivalent behavior.
Rule B3 — Ignited Again While Burning
A second fire hit while already Burning does not emit burning_started. Gameplay instead resets burn_time_left to 4.0 s.

Because the driver reads the timer every frame, both amount_ratio values must jump back to 1.0 within one frame. Existing particles are not cleared, and the emitter is not restarted.
Rule B4 — Death While Burning
A scarecrow killed while Burning emits died and is queued for deletion without emitting burning_ended.

On died, both B emitters must:
1. Preserve their current global transforms.
2. Stop emission immediately.
3. Set amount_ratio = 0.0.
4. Move to the presentation-only World/Effects container.
5. Allow existing particles to fade.
6. Free themselves after the smoke lifetime of 1.20 s.
No new embers may appear after the scarecrow dies.
Rule B5 — Pause and End of Game
The particle nodes use inherited process mode.

When the tree is paused with Esc or P:
- Existing particles remain visible but frozen.
- Particle age, movement, and emission do not advance.
- amount_ratio and burn_time_left do not change.
- Resuming continues from the same state.
When main.gd:95 sets World.process_mode to PROCESS_MODE_DISABLED, the effect also freezes. It remains at its last visible state until the game is reset. It does not continue consuming burn time behind the result screen.
Rule B6 — Hidden Node Prediction
If a B emitter is hidden:
- It draws no particles while hidden.
- My prediction is that its simulation continues unless the tree is also paused or its process mode is disabled.
- When shown again, it displays particles at their current ages instead of restarting from the beginning.
This is a prediction for the implementation test. If Godot 4.7.2 pauses hidden GPU particle simulation instead, the measured result will be recorded in the test report.
Rule B7 — Independent Scarecrows
Each scarecrow owns separate Ember and Smoke nodes.

If one scarecrow has 4.0 s remaining and another has 1.0 s remaining, their expected ratios are 1.0 and 0.25. Updating one must not change the other.
5. Boundaries
This assignment changes presentation only.

The following remain unchanged:
- Collision shapes and collision checks.
- Arrow movement and targeting.
- Scarecrow movement.
- HP values and damage calculations.
- Burning duration and Burning DPS.
- Input and pause controls.
- State-machine behavior.
- Win, loss, restart, and spawn rules.
- Expectations in all existing tests.
- Existing shaders under godot/shaders/.
- Original sprite and environment textures.
- Every object not involved in the two new presentation effects.
The particle drivers may read gameplay variables and listen to gameplay signals. They may not write HP, burn_time_left, movement state, gate damage, timers, or game state.
Boundary exception: hit event
Effect A requires a presentation event that does not currently exist. The only gameplay-script change allowed is:
- Add hit_taken(position: Vector2) to godot/game/scarecrow.gd.
- Emit it once inside an accepted hit() call.
- Emit the scarecrow’s current global_position.
- Do not change the order or result of damage, ignition, or death.
godot/game/arrow.gd, tuning.gd, main.gd, archer.gd, existing tests, and the Assignment 5 shaders will otherwise remain unchanged.

Presentation nodes may be added under World/Effects, and presentation scripts may be attached to the scarecrow scene.
6. Evidence Split
Rule	Evidence	How it will be checked
A1 — Trigger	Headless state test	Count accepted hit() calls, emitted signals, and created burst instances. Verify scene load and burn ticks create none.
A2 — Position	Headless state test	Compare the signal position and burst global position with a tolerance of 1 px.
A3 — Overlap	Headless state test and frame strip	Trigger hits 0.60 s apart and verify two distinct burst instances coexist. The frame strip must show the old fragments behind the new burst.
A4 — Lethal hit	Headless state test and frame strip	Kill a scarecrow with one hit, confirm the scarecrow is freed, and confirm its independent burst remains until its lifetime ends.
B1 — Start/end	Headless state test	Read emitting and amount_ratio immediately after burning_started and burning_ended.
B2 — Mapping	Headless configuration/state test	Set controlled remaining times and compare both emitters’ amount_ratio values to the table.
B3 — Re-ignition	Headless state test and frame strip	Lower the ratio, call ignite() again, and verify it returns to 1.0 without replacing the particle nodes.
B4 — Death	Headless state test and frame strip	Kill a burning scarecrow, verify emission stops, the nodes move to World/Effects, and they free after at most 1.20 s.
B5 — Pause/end	Headless state test and visual check	Record particle state before and during pause. Disable World and verify the state no longer advances. Visually confirm particles freeze rather than disappear.
B6 — Hidden node	Windowed test	Hide the emitter for a controlled interval, show it again, and record whether particle age advanced. This cannot be established from a headless screenshot.
B7 — Independent instances	Headless state test	Create two burning scarecrows with different timers and assert that their nodes and ratios are independent.
Contrast and readability	Human check	Play at the real 1280 × 720 size and inspect both effects over grass, wall, walkway, and gate backgrounds.
Color, scale, and motion	Frame-strip inspection	Compare captured frames with the visual intent. Headless property tests cannot prove that the effect looks clear or natural.
Configuration values	Headless configuration test	Read every node and material property listed in Section 3, including ramps, curves, turbulence, blend modes, and preprocess.


7. Frame Strips
Both strips use the real game background. The scarecrow is positioned near its stopping point at y = 530, above the castle wall, so the capture includes meadow, walkway, and wall colors.

The capture runs at 30 fps.
Effect A Frame Strip
The first hit occurs at frame 10. A second hit occurs at frame 28, which is the normal 0.60 s firing interval later.
Frame	Expected image
10	A compact yellow-white flash appears at the hit point, with the first straw pieces beginning to move outward.
12	The flash is wider and orange at its edges. Straw fragments are visibly separated from the centre.
15	The flash is fading. Fragments are still moving outward and beginning to fall.
20	The flash is gone or almost gone. Only darker falling straw fragments remain.
30	The second impact has created a new bright flash. The final fragments from the first burst are still visible, proving overlap.
50	The second flash is gone and its last fragments are faint, low, and close to disappearing.


The capture should continue past frame 52 so it can also confirm that both bursts eventually disappear.
Effect B Frame Strip
Ignition occurs at frame 10. Four seconds at 30 fps equals 120 frames, so normal Burning ends at approximately frame 130. The capture uses --quit-after 200 or longer.
Frame	Expected image
10	Burning has just begun. Ember and smoke emission are at full density close to the scarecrow.
20	The first particles have risen above the head. The effect looks established instead of like a single burst.
40	Burning is still strong, but the emission density has begun to decrease.
70	The effect is around its middle value. Embers are less frequent, while earlier particles continue fading normally.
100	Only occasional embers and light smoke remain. The scarecrow still reads as Burning, but close to the end.
130	amount_ratio has reached zero and no new particles are emitted. A few particles from before the endpoint may still be fading.
170	All embers and smoke are gone. No particle residue remains around the non-burning scarecrow.


A second version of the strip will call ignite() again around frame 100. The next captured frame should show amount_ratio back at full value without clearing already-existing particles.
8. Predicted Failures
1. Godot 3 property names are used.
   Values such as a single floating-point initial_velocity or scale may be silently ignored, leaving the minimum and maximum at zero. The configuration test will read back initial_velocity_min, initial_velocity_max, scale_min, and scale_max and catch this.
2. A one-shot node is reused for every hit.
   Setting emitting = true again while the original one-shot burst is active may lose the second burst. Rule A3’s overlap test will catch this by requiring two separate live burst instances.
3. The impact burst is parented to the scarecrow.
   A lethal hit would free the parent and remove the effect immediately. Rule A4’s death test and frame strip will catch the missing burst.
4. Effect B changes amount instead of amount_ratio.
   The system may restart when the value changes, causing embers to disappear and reappear unnaturally. The B2 configuration test reads amount_ratio, and the frame strip checks continuity.
5. The driver listens only to burning_started.
   Re-ignition while already Burning would not restore full density because no second signal is emitted. Rule B3 directly tests a timer refresh during Burning.
6. The driver waits for burning_ended after death.
   A burning scarecrow can die without emitting that signal, leaving an emitter in the wrong state. Rule B4 uses the died path and checks cleanup time.
7. The particles have poor contrast on grass.
   Orange particles may be too close in brightness to the meadow. The in-game readability check compares the effect against every real background.
8. The additive material is missing.
   The flash or embers could appear as gray or dark squares instead of light. The configuration test checks the blend mode, and the frame strip catches the visual result.
9. The visibility rectangle is too small.
   Rising particles could disappear early when the emitter approaches a screen edge. The generated-rectangle check and a windowed edge-position test will catch this.
9. Price Predictions and Budget
These are predictions written before measurement.
Effect A
One burst allocates:
10 flash particles + 12 straw particles = 22 particles
The longest lifetime is 0.80 s, and the normal hit interval is 0.60 s, so at most two normal bursts overlap:
22 × 2 = 44 peak particles
Predicted prices:
- Headless CPU price: approximately 0.00–0.02 ms.
- Windowed GPU time: below 0.10 ms.
- Effect A budget: 0.20 ms GPU time.
Because this is a GPU particle effect, the meaningful comparison is measured GPU time against the 0.20 ms GPU budget. The headless CPU result is recorded only as a diagnostic.
Effect B
One burning scarecrow allocates:
18 ember particles + 8 smoke particles = 26 particles
Burning lasts four seconds and arrows are fired every 0.60 s. A conservative upper bound is seven different scarecrows ignited within one rolling burn duration:
hits at 0.0, 0.6, 1.2, 1.8, 2.4, 3.0, and 3.6 seconds
7 × 26 = 182 peak particles
Reducing amount_ratio does not reduce the allocation budget, so the calculation uses the full amount.

Predicted prices:
- Headless CPU price: approximately 0.00–0.03 ms.
- Windowed GPU time: below 0.25 ms.
- Effect B budget: 0.50 ms GPU time.
The larger B budget allows for turbulence, which is expected to cost more than the simple A process materials.
Combined Budget
44 + 182 = 226 peak allocated particles
The combined predicted GPU time is below 0.35 ms, with a combined budget of 0.70 ms.

Both final prices will be compared using windowed GPU measurements because both effects use GPUParticles2D.
10. Answers
1. Which node does each effect use, and which planned features are not properties of that node?
Both effects use GPUParticles2D.

Effect A uses two GPU particle nodes because the assignment later converts and inspects a generated particle shader. Effect B also uses two GPU particle nodes because it needs amount_ratio and turbulence, which CPUParticles2D does not provide in Godot 4.7.2.

Velocity, gravity, damping, ramps, curves, and turbulence are not direct GPUParticles2D properties. They belong to each node’s ParticleProcessMaterial. The additive or mix blend mode belongs to a CanvasItemMaterial.
2. What happens to Effect A if its parent moves after the event?
Effect A uses local_coords = false. Existing particles stay in global space at the original impact location. Moving the parent after the event does not drag the burst across the screen.

The burst is also placed under World/Effects instead of under the scarecrow, so deleting the scarecrow does not delete the burst.
3. How many A bursts can overlap, and what is the peak particle count?
The retrigger rule is overlap. The longest lifetime is 0.80 s, and the firing interval is 0.60 s.
ceil(0.80 / 0.60) = 2 simultaneous bursts
Each burst allocates 22 particles:
2 × 22 = 44 peak Effect A particles
4. What price does a headless run report, and what happens with VSync?
A headless run has no active GPU renderer, so it should report approximately 0 ms of GPU effect price. Its small CPU-side node cost does not measure the real rendering cost.

On a 60 Hz display with VSync enabled, both “effects off” and “effects on” should display approximately 60 fps as long as neither version misses the frame budget. Equal VSync-limited FPS does not prove that the particles are free, so GPU frame time must be measured separately.
5. What does B show on the first frame, while paused, and while hidden?
The actual design uses preprocess = 0.0 and begins with emitting = false, so the first scene frame contains no embers or smoke.

Without preprocess, an emitter started on that frame begins nearly empty and fills naturally as new particles are emitted. With a positive preprocess value, an emitter that starts active appears as though it has already been running, so the first frame contains particles at different ages. This design does not use that behavior because a non-burning scarecrow must begin clean.

While the tree is paused, existing particles remain visible but frozen. Their age, movement, and emission do not advance.

While the node is hidden, it draws nothing. My prediction is that the simulation continues, so showing it again reveals the current simulation state rather than restarting it. The windowed hidden-node test will verify this prediction.

Preprocess changes the initial warmed-up state; it does not change the selected pause or hidden-node rules.
6. Which settings belong to emission, process, and draw?
Emission settings:
- amount
- amount_ratio
- emitting
- one_shot
- explosiveness
- lifetime
- emission shape, radius, or box extents
Process settings:
- direction
- initial_velocity_min and initial_velocity_max
- spread
- gravity
- damping_min and damping_max
- scale_min and scale_max
- color ramp
- scale curve
- turbulence
Draw settings:
- particle texture
- CanvasItemMaterial blend mode
local_coords, visibility_rect, and preprocess are particle-node simulation or culling controls rather than the particle’s process motion or draw appearance.