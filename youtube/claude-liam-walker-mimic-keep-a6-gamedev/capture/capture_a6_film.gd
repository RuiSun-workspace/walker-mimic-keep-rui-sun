extends SceneTree
## Film capture driver for the A6 explainer (Claude, 2026-11-08). Runs in the isolated 4K copy
## (F:/7270/capture-build-a6, copied into its tests/), never in the repository:
##   Godot_v4.7.2-stable_win64_console.exe --path F:/7270/capture-build-a6/godot --disable-vsync --fixed-fps 30 \
##     --write-movie REEL/_frames/<take>/f.png --script res://tests/capture_a6_film.gd -- --take <take>
## Takes:
##   idle  the real game with spawning on (rng seed 7270) and no input: the archer fires on its own.
##         Every hit plays Effect A, every burning scarecrow Effect B. 36 s.
##   play  spawning off; the script places scarecrows the way test_impact_burst_state.gd does: one far at the top
##         (640, 0), then, after the archer's first shot, one near at the wall (680, 530), and two more at the wall
##         at 3 s. The archer fires on its own (real arrows, no keys), so near and far hits land close together. 16 s.
##   burn  spawning and the archer off; three scarecrows walk in. The middle one is hit with fire through
##         Scarecrow.hit() (the call an arrow makes) at 1.0 s and again at 3.0 s, the game is paused with the
##         real Esc key at 4.0 s and resumed at 5.5 s, and it burns down. The left one is hit four
##         times from 8.0 s, so it dies while burning. Scripted capture, 16 s.
## The game, its timers and both effect drivers are unchanged; nothing is teleported and no state is set.

const FPS := 30
var take := "idle"
var game: Game
var lines := PackedStringArray()


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var i := args.find("--take")
	if i >= 0 and i + 1 < args.size():
		take = args[i + 1]
	_run.call_deferred()


func _run() -> void:
	game = (load("res://game/main.tscn") as PackedScene).instantiate() as Game
	game.spawning_enabled = take == "idle"
	root.add_child(game)
	await process_frame
	game.rng.seed = 7270
	if take == "idle":
		await _idle(36 * FPS)
	elif take == "play":
		await _play_placed()
	else:
		await _burn()
	var f := FileAccess.open("user://capture_%s.txt" % take, FileAccess.WRITE)
	f.store_string("\n".join(lines) + "\n")
	f.close()
	print("\n".join(lines))
	quit(0)


func _log(frame: int, s: String) -> void:
	lines.append("f%04d t=%6.2fs  %s" % [frame, frame / float(FPS), s])


func _key(code: Key, pressed: bool) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = pressed
	Input.parse_input_event(e)


func _effects() -> Node:
	return game.get_node("World/Effects")


func _idle(frames: int) -> void:
	var seen := {}
	for n in frames:
		for e in get_nodes_in_group("enemies"):
			var s := e as Scarecrow
			var id := s.get_instance_id()
			if not seen.has(id):
				seen[id] = true
				s.hit_taken.connect(func(p: Vector2) -> void: _log(n, "hit at %s (bursts under Effects: %d)" % [str(p.round()), _effects().get_child_count()]))
				s.died.connect(func() -> void: _log(n, "scarecrow died (burning=%s)" % s.is_burning()))
		if n % 60 == 0:
			_log(n, "gate %.1f, kills %d, Effects children %d" % [game.gate_hp, game.kills, _effects().get_child_count()])
		await process_frame
	_log(frames, "end: kills %d, gate %.1f, state %d" % [game.kills, game.gate_hp, game.state])


func _play_placed() -> void:
	var placed := 0
	var fired_frames: Array[int] = []
	var n := 0
	game.archer.fired.connect(func(_a: Arrow) -> void: fired_frames.append(n))
	game.spawn_scarecrow(Vector2(640, 0))
	_log(0, "placed far scarecrow at (640, 0)")
	while n < 16 * FPS:
		if placed == 0 and not fired_frames.is_empty():
			game.spawn_scarecrow(Vector2(680, Tuning.SCARECROW_STOP_Y))
			_log(n, "first shot fired; placed near scarecrow at (680, 530)")
			placed = 1
		if n == 90:
			game.spawn_scarecrow(Vector2(590, Tuning.SCARECROW_STOP_Y))
			game.spawn_scarecrow(Vector2(700, 120))
			_log(n, "placed two more: (590, 530), (700, 120)")
		for e in get_nodes_in_group("enemies"):
			var s := e as Scarecrow
			if not s.has_meta("logged"):
				s.set_meta("logged", true)
				s.hit_taken.connect(func(p: Vector2) -> void: _log(Engine.get_process_frames(), "hit at %s, Effects children %d" % [str(p.round()), _effects().get_child_count()]))
		n += 1
		await process_frame
	_log(n, "end: kills %d, gate %.1f" % [game.kills, game.gate_hp])


func _burn() -> void:
	game.archer.process_mode = Node.PROCESS_MODE_DISABLED
	var crows: Array[Scarecrow] = []
	for x in [480.0, 640.0, 800.0]:
		crows.append(game.spawn_scarecrow(Vector2(x, 230.0)))
	var left := crows[0]
	var mid := crows[1]
	for n in 16 * FPS:
		if n == 30 or n == 90:
			mid.hit(Tuning.ARROW_DAMAGE, &"fire")
			_log(n, "middle hit with fire (hp %.1f, burn_time_left %.3f)" % [mid.hp, mid.burn_time_left])
		elif n == 120 or n == 165:
			_key(KEY_ESCAPE, true)
		elif n == 121 or n == 166:
			_key(KEY_ESCAPE, false)
			_log(n, "Esc pressed: paused=%s" % str(paused))
		elif n in [240, 249, 258, 267] and is_instance_valid(left):
			left.hit(Tuning.ARROW_DAMAGE, &"fire")
			_log(n, "left hit with fire (hp %.1f)" % (left.hp if is_instance_valid(left) else -1.0))
		if is_instance_valid(mid) and n % 15 == 0:
			var fx := mid.get_node("BurningEmbers")
			_log(n, "middle burn_time_left %.3f, embers amount_ratio %.3f, emitting %s" % [mid.burn_time_left,
					(fx.get_node("Embers") as GPUParticles2D).amount_ratio, (fx.get_node("Embers") as GPUParticles2D).emitting])
		if n % 30 == 0:
			_log(n, "Effects children %d" % _effects().get_child_count())
		await process_frame
