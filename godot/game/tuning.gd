class_name Tuning
## Every gameplay number in one place.
## "GDD" = Mimic Keep GDD v0.1 (Assignment 4); "proto" = chosen for this prototype, to be playtested.

const VIEW := Vector2(1280, 720)
const WALL_TOP := 600.0                # y of the wall walk the archer stands on

const ARCHER_SPEED := 420.0            # px/s, GDD 5.1
const ARCHER_MARGIN := 40.0            # px kept between the archer and the screen edge
const FIRE_INTERVAL := 0.6             # s between auto-fired arrows, proto
const FIRE_CONE_DEG := 120.0           # main weapon targets inside this upward cone, GDD 6.2

const ARROW_SPEED := 900.0             # px/s, proto
const ARROW_DAMAGE := 10.0             # proto
const ARROW_HIT_RADIUS := 26.0         # px from the scarecrow's centre, proto

const SCARECROW_HP := 40.0             # proto
const SCARECROW_SPEED := 45.0          # px/s down the screen, proto
const SCARECROW_GATE_DPS := 5.0        # gate damage per scarecrow at the wall, proto
const SCARECROW_STOP_Y := WALL_TOP - 30.0

const BURN_DURATION := 4.0             # s, GDD 6.3 "Burning: 4 dmg/s for 4 s"
const BURN_DPS := 4.0                  # GDD 6.3

const GATE_HP := 100.0                 # GDD 6.2
const SURVIVE_TIME := 90.0             # s to win the prototype's single wave, proto
# Rui's playtest 2026-10-25 at 2.4 -> 0.9: "目前的怪物数量太多了，很难通关". tools/balance_sim.gd agreed
# (the chasing bot lost 8/8 seeds at ~75 s); at 3.0 -> 1.5 it won 8/8 and standing still lost 7/8.
const SPAWN_INTERVAL_START := 3.0      # s between scarecrows at the start, proto
const SPAWN_INTERVAL_END := 1.5        # s between scarecrows at SURVIVE_TIME, proto
