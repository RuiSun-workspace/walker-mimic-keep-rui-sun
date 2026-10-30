extends SceneTree
## Film capture driver for the A5 explainer (Claude, 2026-10-29). Runs in the isolated 4K copy
## (F:/7270/capture-build-a5, copied into its tests/), never in the repository:
##   Godot_v4.7.2-stable_win64_console.exe --path F:/7270/capture-build-a5/godot --disable-vsync --fixed-fps 30 \
##     --write-movie REEL/_frames/<take>/f.png --script res://tests/capture_a5_film.gd -- --take <take>
## Takes:
##   play  the real game with spawning on (rng seed 7270). The player is a script pressing the real
##         move keys (InputEventKey through Input.parse_input_event) towards the nearest scarecrow;
##         the archer fires on its own. Scripted-input capture, 30 s.
##   idle  the real game with spawning on (rng seed 7270) and no input at all: the archer stands at
##         the gate and fires on its own. 50 s (with no player the wall scarecrows break the gate at about 56 s). (The "play" take was dropped: chasing killed every
##         scarecrow at the top edge, so the tint was barely on screen.)
##   fade  spawning and the archer off; three scarecrows walk in. The middle one is hit with fire
##         through Scarecrow.hit() (the call an arrow makes) at 1.0 s and again at 3.5 s, the game is
##         paused with the real Esc key at 4.5 s and resumed at 6.0 s, and it burns down on its own.
##         Scripted capture, 12 s.
## The game, its timers and the tint driver are unchanged; nothing is teleported and no state is set.

const FPS := 30
var take := "play"
var game: Game
var held := ""
var lines := PackedStringArray()


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var i := args.find("--take")
	if i >= 0 and i + 1 < args.size():
		take = args[i + 1]
	_run.call_deferred()


func _run() -> void:
	game = (load("res://game/main.tscn") as PackedScene).instantiate() as Game
	game.spawning_enabled = take == "play" or take == "idle"
	root.add_child(game)
	await process_frame
	game.rng.seed = 7270
	if take == "play":
		await _play(30 * FPS)
	elif take == "idle":
		await _play(50 * FPS, false)
	else:
		await _fade()
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
	e.pressed = pressed
	Input.parse_input_event(e)


func _hold(dir: String) -> void:
	if dir == held:
		return
	if held == "left":
		_key(KEY_A, false)
	elif held == "right":
		_key(KEY_D, false)
	if dir == "left":
		_key(KEY_A, true)
	elif dir == "right":
		_key(KEY_D, true)
	held = dir


func _play(frames: int, chase := true) -> void:
	var burning_before := {}
	for n in frames:
		if not chase:
			for e in get_nodes_in_group("enemies"):
				var s := e as Scarecrow
				var id := s.get_instance_id()
				if s.is_burning() and not burning_before.get(id, false):
					_log(n, "scarecrow at %s starts burning" % str(s.global_position.round()))
				burning_before[id] = s.is_burning()
			if n % 30 == 0:
				var ys := PackedStringArray()
				for e in get_nodes_in_group("enemies"):
					var s := e as Scarecrow
					ys.append("%d%s" % [s.global_position.y, "*" if s.is_burning() else ""])
				_log(n, "scarecrows y: " + ", ".join(ys))
			await process_frame
			continue
		var target: Scarecrow = null
		var best := INF
		for e in get_nodes_in_group("enemies"):
			var s := e as Scarecrow
			var d := absf(s.global_position.x - game.archer.global_position.x) + (720.0 - s.global_position.y) * 0.2
			if s and d < best:
				best = d
				target = s
		var dx := target.global_position.x - game.archer.global_position.x if target else 0.0
		_hold("right" if dx > 10.0 else ("left" if dx < -10.0 else ""))
		for e in get_nodes_in_group("enemies"):
			var s := e as Scarecrow
			var id := s.get_instance_id()
			if s.is_burning() and not burning_before.get(id, false):
				_log(n, "scarecrow at %s starts burning" % str(s.global_position.round()))
			burning_before[id] = s.is_burning()
		await process_frame
	_hold("")
	_log(frames, "end: kills %d, gate %.1f" % [game.kills, game.gate_hp])


func _fade() -> void:
	game.archer.process_mode = Node.PROCESS_MODE_DISABLED
	var crows: Array[Scarecrow] = []
	for x in [480.0, 640.0, 800.0]:
		crows.append(game.spawn_scarecrow(Vector2(x, 210.0)))
	var mid := crows[1]
	for n in 12 * FPS:
		if n == 30:
			mid.hit(Tuning.ARROW_DAMAGE, &"fire")
			_log(n, "middle hit with fire (hp %.1f)" % mid.hp)
		elif n == 105:
			_log(n, "before second hit: burn_time_left %.3f" % mid.burn_time_left)
			mid.hit(Tuning.ARROW_DAMAGE, &"fire")
			_log(n, "middle hit again (hp %.1f, burn_time_left %.3f)" % [mid.hp, mid.burn_time_left])
		elif n == 135 or n == 180:
			_key(KEY_ESCAPE, true)
			_log(n, "Esc pressed: paused=%s" % str(paused))
		elif n == 136 or n == 181:
			_key(KEY_ESCAPE, false)
		if is_instance_valid(mid) and n % 15 == 0:
			var m := (mid.get_node("Sprite") as Sprite2D).material as ShaderMaterial
			_log(n, "middle burn_time_left %.3f burn_mix %.3f" % [mid.burn_time_left, float(m.get_shader_parameter("burn_mix"))])
		elif not is_instance_valid(mid) and not lines[-1].ends_with("gone"):
			_log(n, "middle scarecrow gone")
		await process_frame
