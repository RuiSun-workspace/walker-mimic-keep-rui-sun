extends SceneTree
## Plays whole runs headlessly to compare spawn tunings. Two stand-in players:
##   "idle"  never moves;
##   "chase" holds move_left/move_right (real input actions) toward the nearest scarecrow's x.
## Neither is a human. This only ranks tunings; Rui's playtest decides.
##   godot --headless --path godot --script res://tools/balance_sim.gd --fixed-fps 60 -- 2.4 0.9
## The two numbers after "--" override SPAWN_INTERVAL_START and SPAWN_INTERVAL_END for this run.

const MAIN := preload("res://game/main.tscn")
const SEEDS := [1, 2, 3, 4, 5, 6, 7, 8]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var start := float(args[0]) if args.size() > 0 else Tuning.SPAWN_INTERVAL_START
	var end := float(args[1]) if args.size() > 1 else Tuning.SPAWN_INTERVAL_END
	var game := MAIN.instantiate() as Game
	game.spawn_interval_override = Vector2(start, end)
	root.add_child(game)
	await process_frame
	for player in ["idle", "chase"]:
		var wins := 0
		var gates: Array[String] = []
		for s in SEEDS:
			game.reset()
			game.rng.seed = s
			while game.state == Game.State.PLAYING:
				if player == "chase":
					_steer(game)
				await physics_frame
			_release()
			if game.state == Game.State.WON:
				wins += 1
				gates.append("%d" % ceili(game.gate_hp))
			else:
				gates.append("lost@%ds" % int(game.elapsed))
			await process_frame
		print("spawn %.2f->%.2f  %-5s wins %d/%d  gate: %s" % [start, end, player, wins, SEEDS.size(), ", ".join(gates)])
	quit(0)


func _steer(game: Game) -> void:
	var best: Scarecrow = null
	for e in get_nodes_in_group("enemies"):
		var s := e as Scarecrow
		if s and (best == null or s.position.y > best.position.y):
			best = s                                    # chase the one closest to the wall
	_release()
	if best == null:
		return
	var dx := best.position.x - game.archer.position.x
	if dx > 8.0:
		Input.action_press("move_right")
	elif dx < -8.0:
		Input.action_press("move_left")


func _release() -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
