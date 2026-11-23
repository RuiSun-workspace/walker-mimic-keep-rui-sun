extends SceneTree
## Film capture driver for the A7 explainer (Claude, 2026-11-22). Runs in the isolated 4K copy
## (F:/7270/capture-build-a7, copied into its tests/), never in the repository:
##   Godot_v4.7.2-stable_win64_console.exe --path F:/7270/capture-build-a7/godot --disable-vsync --fixed-fps 30 \
##     --write-movie REEL/_frames/<take>/f.png --script res://tests/capture_a7_film.gd -- --take <take>
## Takes:
##   play        spawning off. The script places scarecrows with Game.spawn_scarecrow(), as the state tests do:
##               two inside the archer's cone, which it draws on and shoots by itself, and one far to the left,
##               outside the cone, which walks the whole way down (walk clip) and stops at the wall (hold clip).
##               Two more targets in the cone at 6 s. No keys. 20 s.
##   interrupts  spawning off; one target at a time is placed high in the cone, so the archer keeps shooting by
##               itself. Real key events (Input.parse_input_event), each sent when the archer's observed state
##               says so, never at a fixed frame:
##                 1. P while drawing (bow past -8 deg), held 2 s, P again;
##                 2. P on the frame release_window turns true, before the archer reads it, held 2 s, P again;
##                 3. P during recovery (after a fresh arrow, shoot clip past 0.33 s), held 2 s, P again;
##                 4. D held through a whole draw (moving does not interrupt), then A back;
##                 5. with no other target left, one scarecrow placed at the wall 30 px left of the archer;
##                    once the bow is past -2 deg, D is held until the archer is 100 px away: the target leaves
##                    the cone and the draw is cancelled with no arrow.
## The game, its clips and its timers are unchanged; nothing is teleported and no state is set.

const FPS := 30
const HOLD := 60                     # frames a pause is held (2 s; B15 narration is 18.2 s)
var take := "play"
var game: Game
var lines := PackedStringArray()
var n := 0                           # movie frame counter (one per process frame)
var fired_n := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var i := args.find("--take")
	if i >= 0 and i + 1 < args.size():
		take = args[i + 1]
	_run.call_deferred()


func _run() -> void:
	game = (load("res://game/main.tscn") as PackedScene).instantiate() as Game
	game.spawning_enabled = false
	root.add_child(game)
	await process_frame
	game.archer.fired.connect(func(_a: Arrow) -> void:
		fired_n += 1
		_log("FIRED arrow %d" % fired_n))
	if take == "play":
		await _play()
	else:
		await _interrupts()
	var f := FileAccess.open("user://capture_%s.txt" % take, FileAccess.WRITE)
	f.store_string("\n".join(lines) + "\n")
	f.close()
	print("\n".join(lines))
	quit(0)


func _bow() -> float:
	return (game.archer.get_node("Rig/BowPivot") as Node2D).rotation_degrees


func _node() -> String:
	var pb: AnimationNodeStateMachinePlayback = game.archer.get_node("AnimationTree").get("parameters/playback")
	return "%s@%.3f" % [pb.get_current_node(), pb.get_current_play_position()]


func _state() -> String:
	return "archer x %.0f, %s, armed %s, release_window %s, bow %.1f deg, paused %s" % [game.archer.position.x,
			_node(), game.archer.shot_armed, game.archer.release_window, _bow(), paused]


func _log(s: String) -> void:
	lines.append("f%04d t=%6.2fs  %s" % [n, n / float(FPS), s])


func _key(code: Key, pressed: bool) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = pressed
	Input.parse_input_event(e)


func _frame() -> void:
	n += 1
	await process_frame


func _frames(k: int) -> void:
	for i in k:
		await _frame()


func _tap(code: Key) -> void:
	_key(code, true)
	await _frame()
	_key(code, false)


func _alive() -> int:
	return get_nodes_in_group("enemies").size()


func _play() -> void:
	game.spawn_scarecrow(Vector2(560, 40))
	game.spawn_scarecrow(Vector2(730, 140))
	var walker := game.spawn_scarecrow(Vector2(110, 250))   # 63 deg off vertical: outside the 120 deg cone
	_log("placed (560, 40), (730, 140) in the cone; walker at (110, 250) outside it")
	var held := false
	while n < 20 * FPS:
		if n == 6 * FPS:
			game.spawn_scarecrow(Vector2(600, -40))
			game.spawn_scarecrow(Vector2(690, 60))
			_log("placed (600, -40), (690, 60)")
		if is_instance_valid(walker):
			if n % 15 == 0:
				_log("walker y %.1f, frame %d, clip %s, at_wall %s" % [walker.position.y,
						(walker.get_node("Sprite") as Sprite2D).frame,
						(walker.get_node("AnimationPlayer") as AnimationPlayer).assigned_animation, walker.at_wall])
			if walker.at_wall and not held:
				held = true
				_log("walker reached the wall: clip %s" % (walker.get_node("AnimationPlayer") as AnimationPlayer).assigned_animation)
		await _frame()
	_log("end: kills %d, gate %.1f, arrows fired %d" % [game.kills, game.gate_hp, fired_n])


## Keeps one target high in the cone while events 1-4 run.
func _feed() -> void:
	if _alive() == 0:
		game.spawn_scarecrow(Vector2(640, 60))
		_log("placed target (640, 60)")


func _wait_for(cond: Callable, limit: int, what: String) -> bool:
	var start := n
	while not cond.call():
		_feed()
		if n - start > limit:
			_log("TIMEOUT waiting for %s" % what)
			return false
		await _frame()
	return true


func _pause_hold(what: String) -> void:
	_key(KEY_P, true)
	_log("P pressed (%s): %s" % [what, _state()])
	await _frame()
	_key(KEY_P, false)
	_log("one frame later: %s" % _state())
	await _frames(HOLD - 1)
	_log("still paused after %d frames: %s" % [HOLD, _state()])
	await _tap(KEY_P)
	_log("P pressed again: %s" % _state())
	for i in 3:
		await _frame()
		_log("  after resume: %s" % _state())


func _interrupts() -> void:
	_feed()
	var a := game.archer
	# One ordinary shot first.
	await _wait_for(func() -> bool: return fired_n >= 1, 300, "first shot")
	await _frames(20)
	# 1. Startup.
	await _wait_for(func() -> bool: return a.shot_armed and not a.release_window and _bow() <= -8.0, 300, "draw past -8")
	await _pause_hold("startup")
	await _wait_for(func() -> bool: return not a.shot_armed, 120, "the shot to end")
	await _frames(20)
	# 2. Active: release_window keyed true, the archer has not read it yet.
	await _wait_for(func() -> bool: return a.shot_armed and a.release_window, 300, "release_window true")
	await _pause_hold("active")
	await _frames(20)
	# 3. Recovery: wait for a fresh arrow, then pause on the first visible recovery frames (clip 10-11).
	var before := fired_n
	await _wait_for(func() -> bool: return fired_n > before, 300, "an arrow")
	await _wait_for(func() -> bool: return _node().begins_with("shoot") \
			and float(_node().get_slice("@", 1)) >= 0.33, 30, "recovery")
	await _pause_hold("recovery")
	await _frames(20)
	# 4. Moving through a draw.
	await _wait_for(func() -> bool: return a.shot_armed, 300, "a draw")
	var shots := fired_n
	_key(KEY_D, true)
	_log("D held from the draw's start: %s" % _state())
	await _wait_for(func() -> bool: return fired_n > shots, 120, "the arrow while moving")
	_key(KEY_D, false)
	_log("D released after the arrow: %s" % _state())
	_key(KEY_A, true)
	await _wait_for(func() -> bool: return a.position.x <= 640.0, 120, "back to 640")
	_key(KEY_A, false)
	_log("A released: %s" % _state())
	# 5. Target lost in startup: clear the field first (no new targets), then one at the wall.
	while _alive() > 0 or a.shot_armed:
		await _frame()
	await _frames(30)
	game.spawn_scarecrow(Vector2(a.position.x - 30.0, Tuning.SCARECROW_STOP_Y))
	_log("field clear; placed one scarecrow at the wall (%.0f, %.0f)" % [a.position.x - 30.0, Tuning.SCARECROW_STOP_Y])
	var x0 := a.position.x
	# Run from the first visible lean (clip frame 3, about -2 deg): the key acts one frame later, and the
	# cancel has to beat the release on tick 18 (dry run 2026-11-22: from -6.2 deg the arrow won).
	var ok := await _wait_for(func() -> bool: return a.shot_armed and _bow() <= -2.0, 120, "draw past -2")
	if ok:
		_key(KEY_D, true)
		_log("D held: %s" % _state())
		var cancelled := false
		while a.position.x < x0 + 100.0:
			await _frame()
			if not cancelled and not a.shot_armed:
				cancelled = true
				_log("CANCELLED: %s, arrows %d" % [_state(), fired_n])
		_key(KEY_D, false)
		_log("D released at x %.0f: %s" % [a.position.x, _state()])
	await _frames(120)   # B15 needs 559 frames (18.22 s narration + 0.4 s tail)
	_log("end: arrows fired %d, %s" % [fired_n, _state()])
