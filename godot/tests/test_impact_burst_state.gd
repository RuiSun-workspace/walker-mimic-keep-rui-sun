extends SceneTree
## State test for Effect A, Arrow Impact Burst (CHANGE-BRIEF §4, Rules A1-A5), through the real game
## loop. Every hit is a real arrow auto-fired by the archer; the archer moves only through real key
## events (Input.parse_input_event). The test never calls hit(), ignite() or the spawner and never
## writes hp or burn_time_left; it only listens (hit_taken, burning_ended, Archer.fired,
## SceneTree.node_added, tree_exited) and reads node state.
## Headless: proves node state, instance counts, parents, positions and lifetimes, not pixels.
##   ./scripts/run-test.sh test_impact_burst_state.gd 60

const MAIN := preload("res://game/main.tscn")
const BURST_PATH := "res://effects/impact_burst.tscn"
const BURST_FRAMES := 48            # Straw lifetime 0.80 s at 60 ticks/s
const BURST_FRAMES_TOL := 3
const POS_TOL := 1.0                # px, Rule A2
const RESET_LIMIT_FRAMES := 72      # 1.20 s, Rule A5

var passed := 0
var failed := 0
var game: Game
var effects: Node2D

var bursts: Array[Dictionary] = []      # one record per burst instance that entered the tree
var hits: Array[Dictionary] = []        # one record per hit_taken
var arrow_ends: Array[Dictionary] = []  # one record per arrow leaving the tree while tracked
var fired_count := 0
var track_arrows := true
var labels := {}                        # scarecrow instance id -> label
var freed_at := {}                      # scarecrow instance id -> physics frame it left the tree
var burn_end_frame := -1
var bursts_at_burn_end := -1


func _initialize() -> void:
	_run.call_deferred()


func _check(name: String, ok: bool, detail: String = "") -> void:
	if ok:
		passed += 1
		print("PASS %s" % name)
	else:
		failed += 1
		print("FAIL %s  %s" % [name, detail])


func _frame() -> int:
	return Engine.get_physics_frames()


func _key(code: Key, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.physical_keycode = code
	ev.pressed = pressed
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


func _ticks(n: int) -> void:
	for i in n:
		await physics_frame


# ---- listeners (read only) -------------------------------------------------------------------

func _on_node_added(n: Node) -> void:
	if n.scene_file_path != BURST_PATH:
		return
	var rec := {"node": n, "parent_ok": n.get_parent() == effects, "created": _frame(), "freed": -1}
	bursts.append(rec)
	n.tree_exited.connect(func() -> void: rec["freed"] = _frame())


func _on_fired(arrow: Arrow) -> void:
	fired_count += 1
	arrow.tree_exiting.connect(func() -> void:
		if not track_arrows:
			return
		var p := arrow.position
		var off := p.y < -60.0 or p.x < -60.0 or p.x > Tuning.VIEW.x + 60.0
		arrow_ends.append({"on_screen": not off, "pos": p}))


func _on_hit_taken(at: Vector2, s: Scarecrow) -> void:
	# The scarecrow's own ImpactSpawner connected first (in _ready), so its burst already exists.
	var now := _frame()
	var b: Dictionary = bursts.back() if not bursts.is_empty() else {}
	var burst_pos := Vector2.INF
	if not b.is_empty() and b["created"] == now and is_instance_valid(b["node"]):
		burst_pos = (b["node"] as Node2D).global_position
	# Rule A3: every earlier burst still inside its lifetime must be alive, the same instance, emitting.
	var earlier_ok := true
	var earlier_detail := ""
	for e in bursts:
		if e == b or now - int(e["created"]) >= BURST_FRAMES - BURST_FRAMES_TOL:
			continue
		var node: Node = e["node"]
		var alive := is_instance_valid(node) and node.is_inside_tree() and not node.is_queued_for_deletion()
		var emitting := alive and (node.get_node("Straw") as GPUParticles2D).emitting
		if not (alive and emitting):
			earlier_ok = false
			earlier_detail += "[burst from frame %d alive=%s emitting=%s] " % [e["created"], alive, emitting]
	hits.append({"frame": now, "label": labels.get(s.get_instance_id(), "?"), "sid": s.get_instance_id(),
		"at": at, "s_pos": s.global_position, "lethal": s.hp <= 0.0, "burst": b, "burst_pos": burst_pos,
		"bursts_total": bursts.size(), "live": _live_bursts(), "earlier_ok": earlier_ok,
		"earlier_detail": earlier_detail})


func _live_bursts() -> int:
	var n := 0
	for c in effects.get_children():
		if not c.is_queued_for_deletion():
			n += 1
	return n


func _spawn(at: Vector2, label: String) -> Scarecrow:
	var s := game.spawn_scarecrow(at)
	var sid := s.get_instance_id()
	labels[sid] = label
	s.hit_taken.connect(_on_hit_taken.bind(s))
	s.tree_exited.connect(func() -> void: freed_at[sid] = _frame())
	return s


func _hits_on(label: String, from: int) -> int:
	var n := 0
	for i in range(from, hits.size()):
		if hits[i]["label"] == label:
			n += 1
	return n


# ---- run -------------------------------------------------------------------------------------

func _run() -> void:
	node_added.connect(_on_node_added)
	game = MAIN.instantiate() as Game
	game.spawning_enabled = false
	root.add_child(game)
	effects = game.get_node_or_null("World/Effects") as Node2D
	game.archer.fired.connect(_on_fired)
	await process_frame

	await _phase_load()
	await _phase_overlap_and_lethal()
	await _phase_miss()
	await _phase_burn_out()
	await _phase_reset()

	print("test_impact_burst_state: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


## Rule A1: nothing on scene load.
func _phase_load() -> void:
	_check("World/Effects exists, a Node2D after World/Archer", effects != null
			and effects.get_index() > game.archer.get_index())
	await _ticks(30)
	_check("A1: scene load + 30 frames, no scarecrow: 0 bursts created", bursts.is_empty(),
			"created=%d" % bursts.size())
	_check("A1: scene load: World/Effects is empty", effects.get_child_count() == 0)


## Rules A1-A4 with real arrows at uneven flight times: far F (long flight), then near N at the wall
## (short flight). Runs until every scarecrow, arrow and burst is gone.
func _phase_overlap_and_lethal() -> void:
	var h0 := hits.size()
	var b0 := bursts.size()
	var a0 := arrow_ends.size()
	var f0 := fired_count
	var t0 := _frame()
	_spawn(Vector2(640, 0), "F")
	await game.archer.fired
	_spawn(Vector2(680, Tuning.SCARECROW_STOP_Y), "N")
	var cap := 900
	while cap > 0 and (not get_nodes_in_group("enemies").is_empty()
			or game.arrows.get_child_count() > 0 or effects.get_child_count() > 0):
		await physics_frame
		cap -= 1
	_check("phase 1 finished: all scarecrows, arrows and bursts gone within 15 s", cap > 0)

	for i in range(h0, hits.size()):
		var h := hits[i]
		print("INFO hit %d on %s at frame %d (t=%.3f s) pos=%s lethal=%s live_bursts=%d" % [i - h0 + 1,
			h["label"], h["frame"], (int(h["frame"]) - t0) / 60.0, h["at"], h["lethal"], h["live"]])
	for i in range(b0, bursts.size()):
		var b := bursts[i]
		print("INFO burst %d created frame %d freed frame %d lifetime %d frames" % [i - b0 + 1,
			b["created"], b["freed"], int(b["freed"]) - int(b["created"])])

	var n_hits := hits.size() - h0
	var n_bursts := bursts.size() - b0
	var on_screen := 0
	for i in range(a0, arrow_ends.size()):
		if arrow_ends[i]["on_screen"]:
			on_screen += 1
	_check("A1: bursts created == hit_taken count == arrows ended on a hit", n_hits > 0
			and n_bursts == n_hits and on_screen == n_hits,
			"bursts=%d hits=%d on_screen_arrow_ends=%d" % [n_bursts, n_hits, on_screen])
	_check("A1: every fired arrow is accounted for", arrow_ends.size() - a0 == fired_count - f0,
			"ended=%d fired=%d" % [arrow_ends.size() - a0, fired_count - f0])

	var one_each := true
	var pos_ok := true
	var sig_ok := true
	var pos_detail := ""
	for i in range(h0, hits.size()):
		var h := hits[i]
		var b: Dictionary = h["burst"]
		if b.is_empty() or int(b["created"]) != int(h["frame"]) or int(h["bursts_total"]) - b0 != i - h0 + 1:
			one_each = false
		var d: float = (h["burst_pos"] as Vector2).distance_to(h["at"])
		if not d <= POS_TOL:
			pos_ok = false
			pos_detail += "[hit %d: burst %s signal %s] " % [i - h0 + 1, h["burst_pos"], h["at"]]
		if (h["s_pos"] as Vector2).distance_to(h["at"]) > POS_TOL:
			sig_ok = false
	_check("A1: each hit_taken created exactly one burst, in the same frame", one_each)
	_check("A2: burst global_position == hit_taken position (+-%.0f px)" % POS_TOL, pos_ok, pos_detail)
	_check("A2: hit_taken position == the scarecrow's global_position at the hit", sig_ok)

	var parents_ok := true
	for i in range(b0, bursts.size()):
		parents_ok = parents_ok and bool(bursts[i]["parent_ok"])
	_check("A2/A4: every burst was added under World/Effects, none under a scarecrow", parents_ok)

	# Rule A3: overlap.
	if n_hits >= 3:
		var gap := int(hits[h0 + 1]["frame"]) - int(hits[h0]["frame"])
		_check("A3 setup: hits 1 and 2 land inside one burst lifetime (%d frames apart)" % gap,
				gap < BURST_FRAMES, "gap=%d" % gap)
		_check("A3: three distinct bursts are alive at the third impact", int(hits[h0 + 2]["live"]) == 3,
				"live=%d" % int(hits[h0 + 2]["live"]))
		var ids := {}
		for i in range(h0, h0 + 3):
			ids[(hits[i]["burst"] as Dictionary)["node"]] = true
		_check("A3: the first three hits made three different instances", ids.size() == 3)
	else:
		_check("A3: at least three hits happened", false, "hits=%d" % n_hits)
	var earlier_ok := true
	var earlier_detail := ""
	for i in range(h0, hits.size()):
		if not hits[i]["earlier_ok"]:
			earlier_ok = false
			earlier_detail += hits[i]["earlier_detail"]
	_check("A3: no hit cleared, freed or stopped an earlier live burst", earlier_ok, earlier_detail)
	var life_ok := true
	var life_detail := ""
	for i in range(b0, bursts.size()):
		var life := int(bursts[i]["freed"]) - int(bursts[i]["created"])
		if int(bursts[i]["freed"]) < 0 or absi(life - BURST_FRAMES) > BURST_FRAMES_TOL:
			life_ok = false
			life_detail += "[burst %d: %d frames] " % [i - b0 + 1, life]
	_check("A3/A5: every burst freed itself after %d +-%d frames (no restart, no early clear)" % [
			BURST_FRAMES, BURST_FRAMES_TOL], life_ok, life_detail)

	# Rule A4: lethal hit.
	var lethal := 0
	var lethal_ok := true
	var lethal_detail := ""
	for i in range(h0, hits.size()):
		var h := hits[i]
		if not h["lethal"]:
			continue
		lethal += 1
		var b: Dictionary = h["burst"]
		var s_freed: int = freed_at.get(h["sid"], -1)
		var b_life := int(b["freed"]) - int(b["created"])
		print("INFO lethal hit on %s at frame %d: scarecrow left the tree at frame %d, its burst at frame %d" % [
			h["label"], h["frame"], s_freed, b["freed"]])
		if s_freed != int(h["frame"]) or int(b["freed"]) <= s_freed or absi(b_life - BURST_FRAMES) > BURST_FRAMES_TOL:
			lethal_ok = false
			lethal_detail += "[%s s_freed=%d b_freed=%d life=%d] " % [h["label"], s_freed, b["freed"], b_life]
	_check("A4 setup: at least one real arrow hit was lethal", lethal > 0, "lethal=%d" % lethal)
	_check("A4: lethal hit: scarecrow freed that frame, its burst outlived it and ran its full lifetime",
			lethal > 0 and lethal_ok, lethal_detail)
	_check("A5: World/Effects holds no finished bursts", effects.get_child_count() == 0,
			"children=%d" % effects.get_child_count())


## Rule A1: an arrow that leaves the screen creates nothing.
func _phase_miss() -> void:
	var h0 := hits.size()
	var b0 := bursts.size()
	var a0 := arrow_ends.size()
	var m := _spawn(Vector2(640, 100), "M")
	var arrow: Arrow = await game.archer.fired
	m.remove_from_group("enemies")     # target removed in flight, as test_wall_targeting.gd does
	m.queue_free()
	var cap := 120
	while cap > 0 and is_instance_valid(arrow):
		await physics_frame
		cap -= 1
	await _ticks(2)
	var ended_off: bool = arrow_ends.size() - a0 == 1 and not arrow_ends[a0]["on_screen"]
	_check("A1 setup: the arrow left the screen without hitting", ended_off,
			"ends=%s" % str(arrow_ends.slice(a0)))
	_check("A1: an arrow leaving the screen creates no hit_taken and no burst",
			hits.size() == h0 and bursts.size() == b0, "hits=%d bursts=%d" % [hits.size() - h0, bursts.size() - b0])


## Rule A1: Burning ending on its own creates nothing. One fire arrow, then real D key events take the
## archer away until the scarecrow is outside the fire cone; wait for its own burning_ended.
func _phase_burn_out() -> void:
	var h0 := hits.size()
	var f0 := fired_count
	var b := _spawn(Vector2(640, 450), "B")
	b.burning_ended.connect(func() -> void:
		burn_end_frame = _frame()
		bursts_at_burn_end = bursts.size())
	await game.archer.fired
	await process_frame
	_key(KEY_D, true)
	var cap := 120
	while cap > 0 and _hits_on("B", h0) == 0:
		await physics_frame
		cap -= 1
	var hit_frame := _frame()
	var bursts_after_hit := bursts.size()
	cap = 420
	while cap > 0 and burn_end_frame < 0:
		await physics_frame
		cap -= 1
		if game.archer.position.x >= Tuning.VIEW.x - Tuning.ARCHER_MARGIN:
			_key(KEY_D, false)
	_key(KEY_D, false)
	var ended := burn_end_frame >= 0
	var out_of_cone := ended and is_instance_valid(b) and game.archer.nearest_target() != b
	var alive := ended and is_instance_valid(b) and not b.is_dead() and not b.is_burning()
	await _ticks(10)
	print("INFO burn-out: hit at frame %d, burning_ended at frame %d (%d frames), archer x=%.0f" % [
		hit_frame, burn_end_frame, burn_end_frame - hit_frame, game.archer.position.x])
	_check("burn-out setup: exactly one arrow fired and one hit on the scarecrow",
			fired_count - f0 == 1 and _hits_on("B", h0) == 1,
			"fired=%d hits=%d" % [fired_count - f0, _hits_on("B", h0)])
	_check("burn-out setup: burning_ended fired with the scarecrow alive and outside the fire cone",
			ended and alive and out_of_cone, "ended=%s alive=%s out_of_cone=%s" % [ended, alive, out_of_cone])
	_check("A1: no burst created in the burning_ended frame", ended and bursts_at_burn_end == bursts_after_hit,
			"at_end=%d after_hit=%d" % [bursts_at_burn_end, bursts_after_hit])
	_check("A1: no burst created while it burned on its own (burn ticks, movement) or 10 frames after",
			bursts.size() == bursts_after_hit and hits.size() - h0 == 1,
			"new bursts=%d" % (bursts.size() - bursts_after_hit))


## Rule A5: a burst alive when the run is lost survives the R restart and frees itself within 1.20 s.
func _phase_reset() -> void:
	var h0 := hits.size()
	var b0 := bursts.size()
	var ax := game.archer.position.x
	for dx in [-40.0, -50.0, -60.0]:
		_spawn(Vector2(ax + dx, Tuning.SCARECROW_STOP_Y), "R")
	for x in [100.0, 200.0, 300.0, 400.0, 500.0]:
		_spawn(Vector2(x, Tuning.SCARECROW_STOP_Y), "W")
	var cap := 900
	while cap > 0 and game.state == Game.State.PLAYING:
		await physics_frame
		cap -= 1
	var live_at_loss := _live_bursts()
	print("INFO reset: run lost at frame %d, %d bursts live" % [_frame(), live_at_loss])
	_check("A5 setup: the run is lost with a live burst", game.state == Game.State.LOST and live_at_loss > 0,
			"state=%d live=%d" % [game.state, live_at_loss])
	await _ticks(30)
	print("INFO reset: 30 frames after the loss (World disabled), %d bursts still live" % _live_bursts())
	track_arrows = false
	var b_before_r := bursts.size()
	_check("A1: every hit in this phase made exactly one burst", b_before_r - b0 == hits.size() - h0,
			"bursts=%d hits=%d" % [b_before_r - b0, hits.size() - h0])
	_key(KEY_R, true)
	_key(KEY_R, false)
	var r_frame := _frame()
	await process_frame
	_check("A5 setup: R restarts the run", game.state == Game.State.PLAYING)
	cap = 120
	while cap > 0 and effects.get_child_count() > 0:
		await physics_frame
		cap -= 1
	var took := _frame() - r_frame
	print("INFO reset: World/Effects empty %d frames after R" % took)
	_check("A5: after R with a live burst, World/Effects is empty within %d frames (1.20 s)" % RESET_LIMIT_FRAMES,
			effects.get_child_count() == 0 and took <= RESET_LIMIT_FRAMES, "took=%d" % took)
	_check("A1: the reset itself creates no burst", bursts.size() == b_before_r,
			"new=%d" % (bursts.size() - b_before_r))
