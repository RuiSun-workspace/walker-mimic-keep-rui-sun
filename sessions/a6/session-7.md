I wrote `godot/tests/cost_effects.gd` and ran it with `./scripts/run-test.sh cost_effects.gd 60 300`. It exited 0 with no SCRIPT or SHADER ERROR lines. Nothing was committed.

**I couldn't find Example 09.** It isn't in this repo or anywhere under `Desktop/7270`; the only mention is the prompt itself. So the script follows the general pattern of a chapter cost script (warm-up frames, then 5 timed runs of 100 frames per case, mean and spread), not the actual example. Please check it against the chapter's listing.

**Real output:**
```
cost_effects: Godot 4.7.2-stable (official), display 'headless', adapter '', --fixed-fps physics ticks/s 60
warmup 60 frames, 5 runs x 100 frames per case

case   frame us: mean      sd   median     min      max | run means sd | TIME_PROCESS ms mean | TIME_PHYSICS ms mean | particles alloc (min-max), emitting nodes | bursts live | scarecrows alive
empty               5.8     1.7      6.0       5       40 |          0.3 |               0.0000 |               0.0000 |     0-0    ,  0-0  | - | -
off                56.9    14.1     53.0      33      170 |          2.5 |               0.0000 |               0.0000 |     0-0    ,  0-0  | - | 10/10
A                  76.8    19.4     71.0      37      200 |          0.7 |               0.0000 |               0.0000 |    44-66   ,  2-6  | 2-3 | 10/10
B                 105.6    17.2    102.0      57      259 |          1.1 |               0.0000 |               0.0000 |   260-260  , 20-20 | - | 10/10
run means us empty  6.3, 5.8, 5.6, 5.6, 5.6
run means us off    54.7, 58.7, 54.3, 56.4, 60.2
run means us A      77.3, 76.3, 76.5, 76.2, 77.8
run means us B      106.7, 104.3, 104.6, 106.3, 106.1

compare empty -> off   frame mean diff    +51.1 us (noise 2 x run sd = 5.1 us): DIFFERENT
compare off   -> A     frame mean diff    +19.9 us (noise 2 x run sd = 5.1 us): DIFFERENT
compare off   -> B     frame mean diff    +48.7 us (noise 2 x run sd = 5.1 us): DIFFERENT
compare A     -> B     frame mean diff    +28.8 us (noise 2 x run sd = 2.2 us): DIFFERENT
compare empty -> off   TIME_PROCESS identical (0.0000 ms): this monitor does not separate the cases
compare off   -> A     TIME_PROCESS identical (0.0000 ms): this monitor does not separate the cases
compare off   -> B     TIME_PROCESS identical (0.0000 ms): this monitor does not separate the cases
```

**What it shows:**
- **Main timer:** it measures the time between frames with `Time.get_ticks_usec()`. Every case differs from the others by well over twice the run-to-run spread (difference ÷ noise ≈ 4× to 13×). The empty control costs about 6 µs per frame, so this timer is not just timing itself.
- **One measurement that does look like the script timing itself:** `Performance.TIME_PROCESS` and `TIME_PHYSICS_PROCESS` read exactly 0.0000 ms in all four cases, even though frame times run from 6 to 106 µs. Those monitors don't separate the cases at all, which matches the probe noted in CLAUDE.md. Don't use them as the price.
- **Headless CPU price:** Effect A adds about 20 µs per frame and Effect B about 49 µs over the "both effects off" case. That's the cost of the driver scripts, creating burst scenes and the extra nodes. It's small, but it's not "close to the empty-scene control" as the brief predicted (§9), since off itself is about 57 µs against the empty scene's 6. The dummy renderer runs no GPU particle work, so this says nothing about the GPU budgets (0.25 ms and 0.60 ms). Those still need the windowed GPU measurement.

**How the cases are set up:**
- **Same gameplay in every game case:** 10 scarecrows, spawning off, and the archer's processing turned off at runtime so no arrows fly. Every scarecrow is ignited at frame 0, and `burn_time_left` is held at 4.0. The cases differ only in which effect nodes were removed from each scarecrow at runtime.
- **Starting the effects directly:** to start the effects, the script calls `ignite()` and emits `hit_taken` itself instead of using real arrows. That's allowed here because this is a cost script, not a state test, but you may want it noted in the report.
- **Effect A load:** it was held at 3 live bursts but dipped to 2 for one frame each time a burst freed itself before the top-up (44–66 particles). The mean is therefore slightly below a constant 66.
- **Effect B load:** a constant 260 particles across 20 emitting nodes at `amount_ratio` 1.0. I used 10 burning sets rather than 8 burning plus 2 fading death tails, because the tails only last 1.2 s and the load needs to stay constant while it's measured. It's the same particle count as the brief's 10 sets (§9).

No effect or gameplay file was changed. `git status` shows `godot/tests/cost_effects.gd` and `logs/cost_effects_60fps.log` as new, plus `godot/tests/test_burning_embers_state.gd.uid`, which Godot generated during the run.