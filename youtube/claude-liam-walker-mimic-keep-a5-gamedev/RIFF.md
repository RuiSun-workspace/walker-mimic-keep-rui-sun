# RIFF — the commentary's one idea, and what it rests on

**The line:** the test cannot see the fire. Headless runs prove numbers; the real renderer and Rui's eyes prove looks.
Every beat either produces a number a test can hold, or a picture a person has to judge, and says which.

Evidence-led, not imagined play:
- The "cannot see" claim is a probe, not a slogan: a headless run reports an empty video adapter and draws nothing
  (CLAUDE.md Headless facts).
- The surprise worth riffing on is mutation 2: rename `burn_mix` and every behaviour check still passes, because
  `set_shader_parameter()` accepts an undeclared name silently. Only a check written for the name catches it. The same
  shape repeats in mutation 3 (only a source-text check sees `source_color` on a sampler).
- The second surprise is that the hint changes the value, not the Inspector: 64 becomes 137 on screen.
- The honest turn is B22: most of the mistakes were Claude's, and they are on record in FRICTIONAL.md.
- Not riffed on, because not observed: whether the tint "feels" like fire to players other than Rui; no other
  person playtested.
