extends SceneTree
## Game-rule checks for the Mimic Keep prototype, run through the real main scene and game loop.
##   godot --headless --path godot --script res://tests/test_rules.gd --fixed-fps 60
## Prints one PASS/FAIL line per check and exits 1 on any failure.

const MAIN := preload("res://game/main.tscn")
const TICK := 1.0 / 60.0          # physics ticks per second is the project default, 60

var passed := 0
var failed := 0
var game: Game


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	game = MAIN.instantiate() as Game
	game.spawning_enabled = false
	root.add_child(game)
	await process_frame

	await _test_spawning()
	await _test_holds_fire_without_target()
	await _test_fire_arrow_ignites_and_kills()
	await _test_burn_duration_and_damage()
	await _test_burn_retrigger_refreshes()
	await _test_burn_under_time_scale()
	await _test_burn_frozen_while_paused()
	await _test_gate_damage_and_loss()
	await _test_survive_to_win()

	print("test_rules: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


# --- helpers ---------------------------------------------------------------

func _check(name: String, ok: bool, detail: String = "") -> void:
	if ok:
		passed += 1
		print("PASS %s" % name)
	else:
		failed += 1
		print("FAIL %s  %s" % [name, detail])


func _ticks(n: int) -> void:
	for i in n:
		await physics_frame


func _seconds(s: float) -> void:
	await _ticks(roundi(s / TICK))


## Clean field, archer on or off, spawning off.
func _fresh(archer_on: bool) -> void:
	game.spawning_enabled = false
	game.reset()
	game.archer.process_mode = Node.PROCESS_MODE_INHERIT if archer_on else Node.PROCESS_MODE_DISABLED
	await process_frame


## Game time, summed from the delta the engine hands to _physics_process (so it follows
## Engine.time_scale exactly, including the one tick a time_scale change takes to apply).
class GameClock extends Node:
	var total := 0.0
	var ticks := 0
	func _physics_process(delta: float) -> void:
		total += delta
		ticks += 1


## Runs until the scarecrow's Burning ends; returns [game seconds, physics ticks] since the call.
func _measure_burn(s: Scarecrow, max_ticks: int = 2000) -> Array:
	var clock := GameClock.new()
	root.add_child(clock)
	var rec := {"done": false}
	s.burning_ended.connect(func() -> void: rec.done = true, CONNECT_ONE_SHOT)
	while not rec.done and clock.ticks < max_ticks:
		await physics_frame
	var out := [clock.total, clock.ticks]
	clock.queue_free()
	return out


# --- checks ----------------------------------------------------------------

func _test_spawning() -> void:
	await _fresh(false)
	game.rng.seed = 7
	game.spawning_enabled = true
	await _seconds(1.1)
	_check("first scarecrow spawns after 1 s", game.enemies.get_child_count() == 1,
			"got %d" % game.enemies.get_child_count())
	game.spawning_enabled = false
	game.elapsed = 0.0
	_check("spawn interval starts at %.1f s" % Tuning.SPAWN_INTERVAL_START,
			is_equal_approx(game.spawn_interval(), Tuning.SPAWN_INTERVAL_START))
	game.elapsed = Tuning.SURVIVE_TIME
	_check("spawn interval reaches %.1f s at the end" % Tuning.SPAWN_INTERVAL_END,
			is_equal_approx(game.spawn_interval(), Tuning.SPAWN_INTERVAL_END))
	game.spawning_enabled = false


func _test_holds_fire_without_target() -> void:
	await _fresh(true)
	var rec := {"shots": 0}
	var count := func(_a: Arrow) -> void: rec.shots += 1
	game.archer.fired.connect(count)
	await _seconds(1.0)
	_check("archer holds fire with no scarecrow in the cone", rec.shots == 0, "shots=%d" % rec.shots)
	game.spawn_scarecrow(Vector2(40, 560))                 # beside the archer, far outside the cone
	await _seconds(1.0)
	_check("archer ignores a scarecrow outside the 120 degree cone", rec.shots == 0, "shots=%d" % rec.shots)
	game.archer.fired.disconnect(count)


func _test_fire_arrow_ignites_and_kills() -> void:
	await _fresh(true)
	var s := game.spawn_scarecrow(Vector2(640, 250))
	var rec := {"started": 0}
	s.burning_started.connect(func() -> void: rec.started += 1)
	var t := 0.0
	while s.hp >= Tuning.SCARECROW_HP and t < 2.0:
		await physics_frame
		t += TICK
	_check("an auto-fired arrow hits the scarecrow", s.hp < Tuning.SCARECROW_HP, "hp=%.1f" % s.hp)
	_check("a fire arrow sets it Burning", s.is_burning() and rec.started == 1)
	t = 0.0
	while is_instance_valid(s) and not s.is_dead() and t < 8.0:
		await physics_frame
		t += TICK
	await process_frame
	_check("arrows and fire burn the scarecrow down", not is_instance_valid(s))
	_check("the kill is counted", game.kills == 1, "kills=%d" % game.kills)


func _test_burn_duration_and_damage() -> void:
	await _fresh(false)
	var s := game.spawn_scarecrow(Vector2(200, 100))
	await physics_frame
	var hp0 := s.hp
	s.ignite()
	var t: float = (await _measure_burn(s))[0]
	_check("Burning lasts %.1f s of game time (+-1 tick)" % Tuning.BURN_DURATION,
			absf(t - Tuning.BURN_DURATION) <= TICK + 1e-4, "measured %.4f s" % t)
	var expect := Tuning.BURN_DPS * Tuning.BURN_DURATION
	_check("Burning deals %.0f damage in total" % expect, absf((hp0 - s.hp) - expect) < 0.05,
			"dealt %.3f" % (hp0 - s.hp))
	_check("Burning ends: is_burning() false", not s.is_burning())


func _test_burn_retrigger_refreshes() -> void:
	await _fresh(false)
	var s := game.spawn_scarecrow(Vector2(200, 100))
	var rec := {"started": 0}
	s.burning_started.connect(func() -> void: rec.started += 1)
	s.ignite()
	await _seconds(2.0)
	s.ignite()                                             # second fire hit mid-burn
	var t: float = 2.0 + (await _measure_burn(s))[0]
	_check("re-ignite mid-burn refreshes to a full %.1f s (ends at 6 s)" % Tuning.BURN_DURATION,
			absf(t - 6.0) <= TICK + 1e-4, "ended at %.4f s" % t)
	_check("re-ignite does not emit burning_started again", rec.started == 1, "started=%d" % rec.started)


func _test_burn_under_time_scale() -> void:
	await _fresh(false)
	var s := game.spawn_scarecrow(Vector2(200, 100))
	Engine.time_scale = 2.0
	s.ignite()
	var m: Array = await _measure_burn(s)
	Engine.time_scale = 1.0
	_check("at time_scale 2 Burning still lasts %.1f s of scaled game time (+-1 scaled tick)" % Tuning.BURN_DURATION,
			absf(m[0] - Tuning.BURN_DURATION) <= 2.0 * TICK + 1e-4, "measured %.4f s" % m[0])
	_check("at time_scale 2 that takes about half the physics ticks",
			absi(m[1] - roundi(Tuning.BURN_DURATION / TICK / 2.0)) <= 2, "ticks=%d" % m[1])


func _test_burn_frozen_while_paused() -> void:
	await _fresh(false)
	var s := game.spawn_scarecrow(Vector2(200, 100))
	s.ignite()
	await _seconds(1.0)
	paused = true
	var left := s.burn_time_left
	var hp := s.hp
	await _ticks(60)
	_check("Burning timer stops while the tree is paused",
			is_equal_approx(s.burn_time_left, left) and is_equal_approx(s.hp, hp))
	paused = false
	await _seconds(0.5)
	_check("Burning resumes after unpause", s.burn_time_left < left)


func _test_gate_damage_and_loss() -> void:
	await _fresh(false)
	game.spawn_scarecrow(Vector2(1000, Tuning.SCARECROW_STOP_Y))
	await _seconds(2.0)
	var expect := Tuning.GATE_HP - Tuning.SCARECROW_GATE_DPS * 2.0
	_check("one scarecrow at the wall takes %.0f gate HP per second" % Tuning.SCARECROW_GATE_DPS,
			absf(game.gate_hp - expect) <= Tuning.SCARECROW_GATE_DPS * TICK * 2.0,
			"gate=%.3f expected %.1f" % [game.gate_hp, expect])
	for i in 9:
		game.spawn_scarecrow(Vector2(100 + i * 100, Tuning.SCARECROW_STOP_Y))
	await _seconds(2.5)
	_check("gate at 0 HP loses the run", game.state == Game.State.LOST and game.gate_hp == 0.0,
			"state=%d gate=%.2f" % [game.state, game.gate_hp])
	_check("the field freezes after a loss", game.world.process_mode == Node.PROCESS_MODE_DISABLED)


func _test_survive_to_win() -> void:
	await _fresh(false)
	await _seconds(Tuning.SURVIVE_TIME + 0.1)
	_check("surviving %.0f s wins the run" % Tuning.SURVIVE_TIME, game.state == Game.State.WON,
			"state=%d elapsed=%.2f" % [game.state, game.elapsed])
	game.reset()
	_check("reset restores the gate and the clock",
			game.state == Game.State.PLAYING and game.gate_hp == Tuning.GATE_HP and game.elapsed == 0.0)
