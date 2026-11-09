extends SceneTree
## Step 7 cost script (adapted from the chapter's cost-script pattern, Example 09): headless CPU time
## per frame for four cases, each in a fresh scene, at a fixed rate:
##   empty   - a bare Node2D, no game: the control. Whatever this reports is the script's own floor.
##   off     - main.tscn with 10 scarecrows, both effects removed from every scarecrow.
##   A       - the same game with Effect A only, held at 3 live bursts (CHANGE-BRIEF §4 A3, §9: 66 particles).
##   B       - the same game with Effect B only, 10 sets at amount_ratio 1.0 (§9: 8 burning + 2 fading
##             tails = 10 x 26 = 260 allocated particles; held as 10 burning sets so the load is steady).
## Every game case runs identical gameplay: spawning off, archer not processing (no arrows), the same
## 10 scarecrows ignited at frame 0 with burn_time_left held at 4.0 (the brief lets a test set it), so
## the only difference between off, A and B is the effect nodes.
## Effect A bursts are started through the real ImpactSpawner by emitting the scarecrow's hit_taken
## signal; this is a price fixture, not a state test, so it does not need real arrows.
## Per frame it times one whole main-loop iteration with Time.get_ticks_usec() between successive
## process_frame signals, and also reads Performance.TIME_PROCESS and TIME_PHYSICS_PROCESS.
## Headless = dummy renderer: GPU particle simulation and drawing are not run, so this prices only
## the CPU side (node processing, driver scripts, instancing). It is a diagnostic, not the GPU budget.
##   ./scripts/run-test.sh cost_effects.gd 60 300
## Changes no effect or gameplay file; only removes nodes from its own runtime instances.

const MAIN := preload("res://game/main.tscn")
const WARMUP_FRAMES := 60
const RUNS := 5
const FRAMES_PER_RUN := 100        # 60 + 5 x 100 = 560 frames = 9.3 s < 10 s for a held burn to kill (40 HP / 4 dps)
const SCARECROWS := 10
const A_BURSTS := 3
const START_Y := 80.0              # walks 45 px/s: y 500 after 9.3 s, short of the wall at 530

var results := {}                  # case -> Dictionary


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	print("cost_effects: Godot %s, display '%s', adapter '%s', --fixed-fps physics ticks/s %d" % [
		Engine.get_version_info()["string"], DisplayServer.get_name(),
		RenderingServer.get_video_adapter_name(), Engine.physics_ticks_per_second])
	print("warmup %d frames, %d runs x %d frames per case" % [WARMUP_FRAMES, RUNS, FRAMES_PER_RUN])
	for c in ["empty", "off", "A", "B"]:
		await _measure(c)
	_report()
	quit(0)


# ---- case setup ------------------------------------------------------------------------------

func _build(c: String) -> Dictionary:
	var ctx := {"root": null, "game": null, "scarecrows": [], "effects": null, "next_hit": 0}
	if c == "empty":
		var n := Node2D.new()
		root.add_child(n)
		ctx["root"] = n
		return ctx
	var game := MAIN.instantiate() as Game
	game.spawning_enabled = false
	root.add_child(game)
	ctx["root"] = game
	ctx["game"] = game
	ctx["effects"] = game.get_node("World/Effects")
	(game.get_node("World/Archer") as Node).process_mode = Node.PROCESS_MODE_DISABLED
	for i in SCARECROWS:
		var s := game.spawn_scarecrow(Vector2(100.0 + i * 120.0, START_Y))
		if c != "A":
			s.get_node("ImpactSpawner").free()
		if c != "B":
			s.get_node("BurningEmbers").free()
		s.ignite()                 # same gameplay in every game case; only B has a driver listening
		ctx["scarecrows"].append(s)
	return ctx


func _tick(c: String, ctx: Dictionary) -> void:
	if c == "empty":
		return
	for s: Scarecrow in ctx["scarecrows"]:
		s.burn_time_left = Tuning.BURN_DURATION      # B at its heaviest: amount_ratio stays 1.0
	if c == "A":
		var live := _live_bursts(ctx)
		if live < A_BURSTS:                         # top up one per frame so births stay staggered
			var s: Scarecrow = ctx["scarecrows"][ctx["next_hit"] % SCARECROWS]
			ctx["next_hit"] += 1
			s.hit_taken.emit(s.global_position)


func _live_bursts(ctx: Dictionary) -> int:
	var n := 0
	for b in (ctx["effects"] as Node).get_children():
		if not b.is_queued_for_deletion():
			n += 1
	return n


func _particle_load(node: Node) -> Vector2i:
	## x: allocated particles (sum of `amount`), y: GPUParticles2D nodes currently emitting.
	var load := Vector2i.ZERO
	if node is GPUParticles2D and not node.is_queued_for_deletion():
		var p := node as GPUParticles2D
		load.x += p.amount
		if p.emitting:
			load.y += 1
	for child in node.get_children():
		load += _particle_load(child)
	return load


# ---- measurement -----------------------------------------------------------------------------

func _measure(c: String) -> void:
	var ctx := _build(c)
	await process_frame
	for i in WARMUP_FRAMES:
		_tick(c, ctx)
		await process_frame
	var frame_us: Array[float] = []
	var proc_ms: Array[float] = []
	var phys_ms: Array[float] = []
	var run_means: Array[float] = []
	var load_min := Vector2i(1 << 30, 1 << 30)
	var load_max := Vector2i.ZERO
	var bursts_min := 1 << 30
	var bursts_max := 0
	for r in RUNS:
		var run: Array[float] = []
		var t0 := Time.get_ticks_usec()
		for f in FRAMES_PER_RUN:
			_tick(c, ctx)
			await process_frame
			var t1 := Time.get_ticks_usec()
			var dt := float(t1 - t0)
			t0 = t1
			run.append(dt)
			frame_us.append(dt)
			proc_ms.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
			phys_ms.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
			var ld := _particle_load(ctx["root"])
			load_min = Vector2i(mini(load_min.x, ld.x), mini(load_min.y, ld.y))
			load_max = Vector2i(maxi(load_max.x, ld.x), maxi(load_max.y, ld.y))
			if ctx["effects"] != null:
				var nb := _live_bursts(ctx)
				bursts_min = mini(bursts_min, nb)
				bursts_max = maxi(bursts_max, nb)
		run_means.append(_mean(run))
	var alive := 0
	for s in ctx["scarecrows"]:
		if is_instance_valid(s) and not (s as Scarecrow).is_dead():
			alive += 1
	results[c] = {"frame_us": frame_us, "run_means": run_means, "proc_ms": proc_ms, "phys_ms": phys_ms,
		"load_min": load_min, "load_max": load_max, "bursts": Vector2i(bursts_min, bursts_max),
		"alive": alive, "game": ctx["game"] != null}
	ctx["root"].queue_free()
	for i in 5:
		await process_frame


# ---- statistics and report ---------------------------------------------------------------------

func _mean(a: Array[float]) -> float:
	var s := 0.0
	for v in a:
		s += v
	return s / maxf(a.size(), 1)


func _sd(a: Array[float]) -> float:
	var m := _mean(a)
	var s := 0.0
	for v in a:
		s += (v - m) * (v - m)
	return sqrt(s / maxf(a.size() - 1, 1))


func _median(a: Array[float]) -> float:
	var b := a.duplicate()
	b.sort()
	return b[b.size() / 2]


func _report() -> void:
	print("")
	print("case   frame us: mean      sd   median     min      max | run means sd | TIME_PROCESS ms mean | TIME_PHYSICS ms mean | particles alloc (min-max), emitting nodes | bursts live | scarecrows alive")
	for c in ["empty", "off", "A", "B"]:
		var r: Dictionary = results[c]
		var f: Array[float] = r["frame_us"]
		var b: Vector2i = r["bursts"]
		print("%-6s %16.1f %7.1f %8.1f %7.0f %8.0f | %12.1f | %20.4f | %20.4f | %5d-%-5d, %2d-%-2d | %s | %s" % [
			c, _mean(f), _sd(f), _median(f), f.min(), f.max(), _sd(r["run_means"]),
			_mean(r["proc_ms"]), _mean(r["phys_ms"]),
			r["load_min"].x, r["load_max"].x, r["load_min"].y, r["load_max"].y,
			("%d-%d" % [b.x, b.y]) if c == "A" else "-",
			(str(r["alive"]) + "/" + str(SCARECROWS)) if r["game"] else "-"])
	for c in ["empty", "off", "A", "B"]:
		var rm: Array[float] = results[c]["run_means"]
		var parts: PackedStringArray = []
		for v in rm:
			parts.append("%.1f" % v)
		print("run means us %-6s %s" % [c, ", ".join(parts)])
	print("")
	# Pairs that should differ. "Same" = mean difference within 2 x the larger run-to-run sd.
	for pair in [["empty", "off"], ["off", "A"], ["off", "B"], ["A", "B"]]:
		var a: Dictionary = results[pair[0]]
		var b: Dictionary = results[pair[1]]
		var d := _mean(b["frame_us"]) - _mean(a["frame_us"])
		var noise := 2.0 * maxf(_sd(a["run_means"]), _sd(b["run_means"]))
		var verdict := "DIFFERENT" if absf(d) > noise else "SAME within noise: the script may be measuring itself"
		print("compare %-5s -> %-5s frame mean diff %+8.1f us (noise 2 x run sd = %.1f us): %s" % [
			pair[0], pair[1], d, noise, verdict])
	for pair in [["empty", "off"], ["off", "A"], ["off", "B"]]:
		var pa: float = _mean(results[pair[0]]["proc_ms"])
		var pb: float = _mean(results[pair[1]]["proc_ms"])
		if is_equal_approx(pa, pb):
			print("compare %-5s -> %-5s TIME_PROCESS identical (%.4f ms): this monitor does not separate the cases" % [
				pair[0], pair[1], pa])
