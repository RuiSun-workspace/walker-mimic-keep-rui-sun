extends SceneTree
## Keyboard checks: real InputEventKey events through Input.parse_input_event, into the main scene.
##   godot --headless --path godot --script res://tests/test_input.gd --fixed-fps 60
## Prints one PASS/FAIL line per check and exits 1 on any failure.

const MAIN := preload("res://game/main.tscn")
const TICK := 1.0 / 60.0

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

	await _test_move(KEY_D, 1.0, "D")
	await _test_move(KEY_RIGHT, 1.0, "Right arrow")
	await _test_move(KEY_A, -1.0, "A")
	await _test_move(KEY_LEFT, -1.0, "Left arrow")
	await _test_clamp()
	await _test_pause(KEY_ESCAPE, "Esc")
	await _test_pause(KEY_P, "P")
	await _test_restart()

	print("test_input: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _check(name: String, ok: bool, detail: String = "") -> void:
	if ok:
		passed += 1
		print("PASS %s" % name)
	else:
		failed += 1
		print("FAIL %s  %s" % [name, detail])


func _key(code: Key, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.physical_keycode = code
	ev.pressed = pressed
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


func _seconds(s: float) -> void:
	for i in roundi(s / TICK):
		await physics_frame


func _test_move(code: Key, sign_x: float, label: String) -> void:
	game.reset()
	await process_frame
	var x0 := game.archer.position.x
	_key(code, true)
	await _seconds(0.5)
	_key(code, false)
	await _seconds(0.1)
	var moved := game.archer.position.x - x0
	var expect := sign_x * Tuning.ARCHER_SPEED * 0.5
	_check("%s moves the archer %+.0f px in 0.5 s" % [label, expect],
			absf(moved - expect) <= Tuning.ARCHER_SPEED * TICK + 0.01, "moved %.2f" % moved)


func _test_clamp() -> void:
	game.reset()
	await process_frame
	_key(KEY_D, true)
	await _seconds(3.0)
	_key(KEY_D, false)
	_check("the archer stops at the right edge",
			is_equal_approx(game.archer.position.x, Tuning.VIEW.x - Tuning.ARCHER_MARGIN),
			"x=%.2f" % game.archer.position.x)


func _test_pause(code: Key, label: String) -> void:
	game.reset()
	await process_frame
	_key(code, true)
	_key(code, false)
	await process_frame
	_check("%s pauses" % label, paused)
	var t := game.elapsed
	await _seconds(0.5)
	_check("%s: the run clock stops while paused" % label, game.elapsed == t)
	_key(code, true)
	_key(code, false)
	await process_frame
	_check("%s resumes" % label, not paused)


func _test_restart() -> void:
	game.reset()
	await process_frame
	game.gate_hp = 50.0
	_key(KEY_R, true)
	_key(KEY_R, false)
	await process_frame
	_check("R does nothing during play", game.gate_hp == 50.0 and game.state == Game.State.PLAYING)
	for i in 10:
		game.spawn_scarecrow(Vector2(100 + i * 100, Tuning.SCARECROW_STOP_Y))
	game.archer.process_mode = Node.PROCESS_MODE_DISABLED
	await _seconds(2.0)
	_check("the run is lost (setup for restart)", game.state == Game.State.LOST)
	_key(KEY_ENTER, true)
	_key(KEY_ENTER, false)
	await process_frame
	_check("Enter restarts after a loss", game.state == Game.State.PLAYING and game.gate_hp == Tuning.GATE_HP)
	game.archer.process_mode = Node.PROCESS_MODE_INHERIT
