extends SceneTree
## State test for Effect B, Burning Embers (CHANGE-BRIEF §4, Rules B1-B7), through the real game loop.
## Every ignition and every hit is a real arrow auto-fired by the archer; the archer moves only through
## real A/D key events, pause and restart use the real P and R keys (Input.parse_input_event). The test
## never calls hit(), ignite() or a driver function and never writes hp or gate_hp. The only game value
## it writes is burn_time_left, as the brief allows for a feedback-loop test (§6). It also hides and
## shows one Embers node for B6 (a presentation property).
## Headless: proves node state (emitting, amount_ratio, amount, visibility, can_process, parent,
## position, lifetime, instance identity) and signals, not pixels or GPU particle ages.
##   ./scripts/run-test.sh test_burning_embers_state.gd 60

const MAIN := preload("res://game/main.tscn")
const TOL := (1.0 / 60.0) / 4.0 + 1e-4  # amount_ratio: one 60 fps frame of burn time (B2, B3)
const POS_TOL := 1.0                     # px (B4)
const TAIL_FRAMES := 72                  # Smoke lifetime 1.20 s at 60 ticks/s (B4)
const TAIL_FRAMES_TOL := 2
const RESET_LIMIT_FRAMES := 72           # 1.20 s (A5 carry-over)
const AMOUNT_EMBERS := 18
const AMOUNT_SMOKE := 8
const S1_X := 640.0
const S2_X := 960.0
const RIGHT_X := Tuning.VIEW.x - Tuning.ARCHER_MARGIN   # 1240, outside both cones

var passed := 0
var failed := 0
var game: Game
var effects: Node2D
var rec := {}                            # label -> record Dictionary
var fires: Array[Dictionary] = []        # one per Archer.fired: frame, target label, archer x
var hits: Array[Dictionary] = []         # one per hit_taken: frame, label, lethal


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


# ---- records and listeners (read only) -------------------------------------------------------

func _snap(r: Dictionary) -> Dictionary:
	var e: GPUParticles2D = r["embers"]
	var sm: GPUParticles2D = r["smoke"]
	return {"e_emit": e.emitting, "s_emit": sm.emitting, "e_ratio": e.amount_ratio, "s_ratio": sm.amount_ratio,
		"e_amount": e.amount, "s_amount": sm.amount}


func _both_emitting(sn: Dictionary, on: bool) -> bool:
	return sn["e_emit"] == on and sn["s_emit"] == on


func _both_ratio(sn: Dictionary, want: float, tol: float = 1e-6) -> bool:
	return absf(sn["e_ratio"] - want) <= tol and absf(sn["s_ratio"] - want) <= tol


func _amounts_ok(sn: Dictionary) -> bool:
	return sn["e_amount"] == AMOUNT_EMBERS and sn["s_amount"] == AMOUNT_SMOKE


func _spawn(at: Vector2, label: String) -> Scarecrow:
	var s := game.spawn_scarecrow(at)
	var fx := s.get_node("BurningEmbers") as Node2D
	var r := {"s": s, "fx": fx, "embers": fx.get_node("Embers"), "smoke": fx.get_node("Smoke"),
		"started": 0, "ended": 0, "died": 0, "start_snaps": [], "end_snaps": [], "died_snap": {},
		"died_frame": -1, "fx_freed": -1}
	rec[label] = r
	s.burning_started.connect(func() -> void:     # runs after the driver's listener (connected in _ready)
		r["started"] += 1
		(r["start_snaps"] as Array).append(_snap(r)))
	s.burning_ended.connect(func() -> void:
		r["ended"] += 1
		(r["end_snaps"] as Array).append(_snap(r)))
	s.died.connect(func() -> void:
		r["died"] += 1
		r["died_frame"] = _frame()
		var d := _snap(r)
		d["burning"] = s.is_burning()
		d["btl"] = s.burn_time_left
		d["ended"] = r["ended"]
		d["parent_effects"] = fx.get_parent() == effects
		d["fx_pos"] = fx.global_position
		d["s_pos"] = s.global_position
		r["died_snap"] = d)
	s.hit_taken.connect(func(_at: Vector2) -> void:
		hits.append({"frame": _frame(), "label": label, "lethal": s.hp <= 0.0}))
	fx.tree_exited.connect(func() -> void:          # a reparent also exits the tree; only count the free
		if fx.is_queued_for_deletion():
			r["fx_freed"] = _frame())
	return s


func _label_of(s: Scarecrow) -> String:
	if s == null:
		return "none"
	for label in rec:
		if rec[label]["s"] == s:
			return label
	return "?"


func _on_fired(_arrow: Arrow) -> void:
	# Same tick and state as Archer._fire_at, so nearest_target() is the scarecrow just aimed at.
	fires.append({"frame": _frame(), "target": _label_of(game.archer.nearest_target()),
		"x": game.archer.position.x})


func _fires_on(label: String, from: int) -> int:
	var n := 0
	for i in range(from, fires.size()):
		if fires[i]["target"] == label:
			n += 1
	return n


func _hits_on(label: String, from: int) -> int:
	var n := 0
	for i in range(from, hits.size()):
		if hits[i]["label"] == label:
			n += 1
	return n


func _fire_log(from: int) -> String:
	var parts: PackedStringArray = []
	for i in range(from, fires.size()):
		parts.append("%s@%d(x=%.0f)" % [fires[i]["target"], fires[i]["frame"], fires[i]["x"]])
	return "[" + ", ".join(parts) + "]"


func _alive(label: String) -> bool:
	var v: Variant = rec[label]["s"]       # untyped: a freed instance cannot be assigned to a typed var
	if not is_instance_valid(v):
		return false
	var s := v as Scarecrow
	return s.is_inside_tree() and not s.is_dead()


func _s(label: String) -> Scarecrow:
	return rec[label]["s"]


func _info(tag: String) -> void:
	var parts: PackedStringArray = []
	for label in ["S1", "S2"]:
		if _alive(label):
			parts.append("%s hp=%.2f burn=%.3f" % [label, _s(label).hp, _s(label).burn_time_left])
		else:
			parts.append("%s gone" % label)
	print("INFO %s: frame %d gate_hp=%.2f %s" % [tag, _frame(), game.gate_hp, " ".join(parts)])


# ---- run -------------------------------------------------------------------------------------

func _run() -> void:
	game = MAIN.instantiate() as Game
	game.spawning_enabled = false
	root.add_child(game)
	effects = game.get_node_or_null("World/Effects") as Node2D
	game.archer.fired.connect(_on_fired)
	await process_frame

	await _sc1_spawn()
	await _sc2_ignite()
	await _sc3_mapping()
	await _sc4_independent()
	await _sc5_pause()
	await _sc6_hidden()
	await _sc7_refresh()
	await _sc8_burn_out()
	await _sc9_death()
	await _sc10_game_over()

	print("test_burning_embers_state: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


## 1. B1 initial state: a freshly spawned scarecrow has both emitters off at ratio 0.
func _sc1_spawn() -> void:
	_spawn(Vector2(S1_X, Tuning.SCARECROW_STOP_Y), "S1")
	_spawn(Vector2(S2_X, Tuning.SCARECROW_STOP_Y), "S2")
	var ok := true
	var detail := ""
	for label in ["S1", "S2"]:
		var sn := _snap(rec[label])
		detail += "%s %s " % [label, sn]
		ok = ok and _both_emitting(sn, false) and _both_ratio(sn, 0.0) and _amounts_ok(sn)
	_check("B1: spawned scarecrows: Embers and Smoke emitting=false, amount_ratio=0", ok, detail)
	_check("B7: each scarecrow owns its own BurningEmbers, a child of the scarecrow",
			rec["S1"]["fx"] != rec["S2"]["fx"] and (rec["S1"]["fx"] as Node).get_parent() == _s("S1")
			and (rec["S2"]["fx"] as Node).get_parent() == _s("S2"))


## 2. B1 start: real arrows ignite S1, then S2 as the archer (D held) passes through S2's cone.
func _sc2_ignite() -> void:
	var f0 := fires.size()
	var h0 := hits.size()
	await game.archer.fired
	await process_frame
	_key(KEY_D, true)
	var cap := 240
	while cap > 0 and not (game.archer.position.x >= RIGHT_X and rec["S1"]["started"] > 0
			and rec["S2"]["started"] > 0 and game.arrows.get_child_count() == 0):
		await physics_frame
		cap -= 1
		if game.archer.position.x >= RIGHT_X:
			_key(KEY_D, false)
	_key(KEY_D, false)
	await _ticks(2)
	_info("sc2 after ignition, fires " + _fire_log(f0))
	_check("sc2 setup: exactly one arrow fired at S1 and one at S2, both hit",
			fires.size() - f0 == 2 and _fires_on("S1", f0) == 1 and _fires_on("S2", f0) == 1
			and _hits_on("S1", h0) == 1 and _hits_on("S2", h0) == 1,
			"fires=%s hits S1=%d S2=%d" % [_fire_log(f0), _hits_on("S1", h0), _hits_on("S2", h0)])
	_check("sc2 setup: archer at x=%.0f is outside both fire cones" % RIGHT_X,
			game.archer.position.x >= RIGHT_X and game.archer.nearest_target() == null,
			"x=%.1f target=%s" % [game.archer.position.x, _label_of(game.archer.nearest_target())])
	for label in ["S1", "S2"]:
		var r: Dictionary = rec[label]
		var snaps: Array = r["start_snaps"]
		var sn: Dictionary = snaps[0] if not snaps.is_empty() else {}
		_check("B1: %s burning_started: both emitters emitting=true, amount_ratio=1.0 in the signal" % label,
				r["started"] == 1 and _both_emitting(sn, true) and _both_ratio(sn, 1.0),
				"started=%d snap=%s" % [r["started"], sn])


## 3. B2 mapping: S1's burn_time_left set to 4, 3, 2, 1; both ratios follow within one frame.
func _sc3_mapping() -> void:
	var s1 := _s("S1")
	for v in [4.0, 3.0, 2.0, 1.0]:
		s1.burn_time_left = v
		await physics_frame        # one tick of burn, then the driver's _process
		var sn := _snap(rec["S1"])
		var want: float = v / 4.0
		print("INFO sc3 set burn_time_left=%.1f -> now %.4f; Embers ratio %.4f, Smoke ratio %.4f (want %.2f, tol %.4f); amount %d/%d" % [
			v, s1.burn_time_left, sn["e_ratio"], sn["s_ratio"], want, TOL, sn["e_amount"], sn["s_amount"]])
		_check("B2: burn_time_left %.1f -> both amount_ratio %.2f within one frame" % [v, want],
				_both_ratio(sn, want, TOL), str(sn))
		_check("B2: burn_time_left %.1f -> amount unchanged (18 / 8), emitting still true" % v,
				_amounts_ok(sn) and _both_emitting(sn, true), str(sn))
		var s2n := _snap(rec["S2"])
		_check("B2: S2's amount unchanged (18 / 8) while S1 changes", _amounts_ok(s2n), str(s2n))


## 4. B7: two scarecrows with different timers have independent nodes and ratios.
func _sc4_independent() -> void:
	var s1 := _s("S1")
	var s2 := _s("S2")
	for pair in [[4.0, 1.0], [1.0, 4.0]]:
		s1.burn_time_left = pair[0]
		s2.burn_time_left = pair[1]
		await physics_frame
		var a := _snap(rec["S1"])
		var b := _snap(rec["S2"])
		print("INFO sc4 S1=%.1f S2=%.1f -> S1 ratios %.4f/%.4f, S2 ratios %.4f/%.4f" % [pair[0], pair[1],
			a["e_ratio"], a["s_ratio"], b["e_ratio"], b["s_ratio"]])
		_check("B7: S1 %.1f s and S2 %.1f s -> ratios %.2f and %.2f" % [pair[0], pair[1], pair[0] / 4.0, pair[1] / 4.0],
				_both_ratio(a, pair[0] / 4.0, TOL) and _both_ratio(b, pair[1] / 4.0, TOL),
				"S1 %s S2 %s" % [a, b])
	var ids := {}
	for label in ["S1", "S2"]:
		ids[rec[label]["embers"]] = true
		ids[rec[label]["smoke"]] = true
	_check("B7: the four emitters are four distinct instances", ids.size() == 4)


## 5. B5 pause: P freezes the timer, ratios and emitting; resuming continues.
func _sc5_pause() -> void:
	_s("S1").burn_time_left = 4.0     # setup: S1 keeps burning through scenarios 5-7
	await physics_frame
	_info("sc5 before pause")
	_key(KEY_P, true)
	_key(KEY_P, false)
	await physics_frame
	_check("B5 setup: P paused the tree", paused)
	var before := {"S1": _snap(rec["S1"]), "S2": _snap(rec["S2"]),
		"b1": _s("S1").burn_time_left, "b2": _s("S2").burn_time_left}
	var same := true
	var can := false
	for i in 30:
		await physics_frame
		for label in ["S1", "S2"]:
			if _snap(rec[label]) != before[label]:
				same = false
			can = can or (rec[label]["embers"] as Node).can_process() or (rec[label]["smoke"] as Node).can_process()
		same = same and _s("S1").burn_time_left == before["b1"] and _s("S2").burn_time_left == before["b2"]
	print("INFO sc5 paused 30 frames: S1 burn %.4f -> %.4f, S2 burn %.4f -> %.4f, S1 ratio %.4f -> %.4f" % [
		before["b1"], _s("S1").burn_time_left, before["b2"], _s("S2").burn_time_left,
		before["S1"]["e_ratio"], rec["S1"]["embers"].amount_ratio])
	_check("B5: while paused no emitter can process", not can)
	_check("B5: 30 paused frames: burn_time_left, amount_ratio and emitting unchanged on all four emitters", same)
	_key(KEY_P, true)
	_key(KEY_P, false)
	await physics_frame
	_check("B5 setup: P again resumed the tree", not paused)
	var b0 := _s("S1").burn_time_left
	await _ticks(10)
	var sn := _snap(rec["S1"])
	var b1 := _s("S1").burn_time_left
	print("INFO sc5 resumed 10 frames: S1 burn %.4f -> %.4f, ratio %.4f" % [b0, b1, sn["e_ratio"]])
	_check("B5: after resume the timer runs again and both ratios follow it",
			b1 < b0 and _both_ratio(sn, b1 / 4.0, TOL) and _both_emitting(sn, true), "b0=%f b1=%f %s" % [b0, b1, sn])


## 6. B6 (node state only): hidden Embers keeps emitting and following the timer; shown, it is the same node.
func _sc6_hidden() -> void:
	var r: Dictionary = rec["S1"]
	var e: GPUParticles2D = r["embers"]
	var sm: GPUParticles2D = r["smoke"]
	var id := e.get_instance_id()
	var started0: int = r["started"]
	e.visible = false
	var ok := true
	var detail := ""
	for i in 30:
		await physics_frame
		var want := clampf(_s("S1").burn_time_left / 4.0, 0.0, 1.0)
		if e.is_visible_in_tree() or not e.emitting or absf(e.amount_ratio - want) > TOL:
			ok = false
			detail = "frame %d visible=%s emitting=%s ratio=%f want=%f" % [i, e.is_visible_in_tree(), e.emitting, e.amount_ratio, want]
		if not sm.is_visible_in_tree() or not sm.emitting or sm.amount_ratio != e.amount_ratio:
			ok = false
			detail = "frame %d smoke changed" % i
	print("INFO sc6 hidden 30 frames: Embers ratio now %.4f, S1 burn %.4f" % [e.amount_ratio, _s("S1").burn_time_left])
	_check("B6: hidden Embers: not visible in tree, still emitting, ratio follows the timer; Smoke unaffected", ok, detail)
	e.visible = true
	await physics_frame
	_check("B6: shown again: same instance, visible, emitting, no new burning_started",
			is_instance_valid(e) and e.get_instance_id() == id and e.is_visible_in_tree() and e.emitting
			and r["started"] == started0, "started %d -> %d" % [started0, r["started"]])


## 7. B3: a real fire arrow re-ignites the burning S2 -> ratios back to 1.0 within one frame, no restart.
func _sc7_refresh() -> void:
	var r: Dictionary = rec["S2"]
	var e: GPUParticles2D = r["embers"]
	var sm: GPUParticles2D = r["smoke"]
	var ids := [e.get_instance_id(), sm.get_instance_id()]
	var started0: int = r["started"]
	var f0 := fires.size()
	var h0 := hits.size()
	_s("S2").burn_time_left = 2.0
	await physics_frame
	var low := _snap(r)
	print("INFO sc7 S2 lowered: burn %.4f, ratios %.4f/%.4f" % [_s("S2").burn_time_left, low["e_ratio"], low["s_ratio"]])
	_check("B3 setup: S2's ratios lowered to 0.50 within one frame", _both_ratio(low, 0.5, TOL), str(low))
	var emit_ok := true
	_key(KEY_A, true)
	var cap := 120
	while cap > 0 and _hits_on("S2", h0) == 0:
		await physics_frame
		cap -= 1
		emit_ok = emit_ok and e.emitting and sm.emitting
	_key(KEY_A, false)
	var hit_frame: int = hits.back()["frame"] if _hits_on("S2", h0) > 0 else -1
	var after := _snap(r)     # read at the start of the tick after the hit (the driver's _process ran once)
	print("INFO sc7 hit on S2 at frame %d (read at frame %d, archer x=%.0f): burn %.4f, ratios %.4f/%.4f, hp %.2f" % [
		hit_frame, _frame(), game.archer.position.x, _s("S2").burn_time_left, after["e_ratio"], after["s_ratio"], _s("S2").hp])
	_check("B3: one frame after the re-igniting hit both ratios are 1.0",
			hit_frame >= 0 and _both_ratio(after, 1.0, TOL), str(after))
	_key(KEY_D, true)
	cap = 120
	while cap > 0 and game.archer.position.x < RIGHT_X:
		await physics_frame
		cap -= 1
		emit_ok = emit_ok and e.emitting and sm.emitting
	_key(KEY_D, false)
	await _ticks(2)
	_info("sc7 end, fires " + _fire_log(f0))
	_check("sc7 setup: exactly one arrow fired (at S2) and one hit on S2; S2 alive and burning",
			fires.size() - f0 == 1 and _fires_on("S2", f0) == 1 and _hits_on("S2", h0) == 1 and _alive("S2")
			and _s("S2").is_burning(), "fires=%s hits=%d" % [_fire_log(f0), _hits_on("S2", h0)])
	_check("B3: no second burning_started on re-ignition", r["started"] == started0,
			"started %d -> %d" % [started0, r["started"]])
	_check("B3: emitting stayed true on both emitters in every frame (no stop/restart)", emit_ok)
	_check("B3: the same Embers and Smoke instances (not replaced)", is_instance_valid(e) and is_instance_valid(sm)
			and [e.get_instance_id(), sm.get_instance_id()] == ids)


## 8. B1 end and B2 at 0.0: S1 burns out on its own.
func _sc8_burn_out() -> void:
	var r: Dictionary = rec["S1"]
	var f0 := fires.size()
	var ended0: int = r["ended"]
	_check("sc8 setup: S1 alive and burning before its burn-out", _alive("S1") and _s("S1").is_burning())
	_s("S1").burn_time_left = 1.0
	var t0 := _frame()
	var cap := 120
	while cap > 0 and r["ended"] == ended0:
		await physics_frame
		cap -= 1
	print("INFO sc8 S1 burning_ended %d frames after burn_time_left=1.0" % (_frame() - t0))
	var snaps: Array = r["end_snaps"]
	var sn: Dictionary = snaps.back() if not snaps.is_empty() else {}
	_check("B1: S1 burning_ended: both emitters amount_ratio=0 and emitting=false in the signal",
			r["ended"] == ended0 + 1 and _both_emitting(sn, false) and _both_ratio(sn, 0.0), str(sn))
	var ok := true
	for i in 30:
		await physics_frame
		var now := _snap(r)
		ok = ok and _alive("S1") and not _s("S1").is_burning() and _both_emitting(now, false) and _both_ratio(now, 0.0)
	_check("B1/B2: 30 frames after burn-out: S1 alive, not burning, emitting=false, ratio 0.00 on both", ok)
	_check("sc8 setup: no arrow fired during S1's burn-out", fires.size() == f0, "fires=%s" % _fire_log(f0))
	_info("sc8 end")


## 9. B4: real arrows kill the burning S2; its emitters stop and move to World/Effects, then free.
func _sc9_death() -> void:
	var r: Dictionary = rec["S2"]
	var f0 := fires.size()
	var h0 := hits.size()
	_check("sc9 setup: S2 alive and burning", _alive("S2") and _s("S2").is_burning())
	_key(KEY_A, true)
	var cap := 120
	while cap > 0 and game.archer.position.x > S2_X:
		await physics_frame
		cap -= 1
	_key(KEY_A, false)
	cap = 600
	while cap > 0 and r["died"] == 0:
		await physics_frame
		cap -= 1
	var fx: Node2D = r["fx"]
	var e: GPUParticles2D = r["embers"]
	var sm: GPUParticles2D = r["smoke"]
	var stays_off := true
	cap = 150
	while cap > 0 and r["fx_freed"] < 0:
		if is_instance_valid(fx):
			stays_off = stays_off and not e.emitting and not sm.emitting and e.amount_ratio == 0.0 and sm.amount_ratio == 0.0
		await physics_frame
		cap -= 1
	var d: Dictionary = r["died_snap"]
	var lethal_hit := false
	for i in range(h0, hits.size()):
		lethal_hit = lethal_hit or (hits[i]["label"] == "S2" and hits[i]["lethal"])
	var life: int = int(r["fx_freed"]) - int(r["died_frame"])
	print("INFO sc9 S2 died at frame %d (%s), fires %s; died snap %s; BurningEmbers freed at frame %d (%d frames)" % [
		r["died_frame"], "by arrow" if lethal_hit else "by burn tick", _fire_log(f0), d, r["fx_freed"], life])
	_check("sc9 setup: S2 died; no arrow fired at S1", r["died"] == 1 and _fires_on("S1", f0) == 0,
			"died=%d fires=%s" % [r["died"], _fire_log(f0)])
	_check("B4: S2 died while burning, without burning_ended", not d.is_empty() and d["burning"] and d["ended"] == 0
			and r["ended"] == 0, str(d))
	_check("B4: in died: BurningEmbers is under World/Effects", not d.is_empty() and d["parent_effects"])
	var dist: float = (d.get("fx_pos", Vector2.INF) as Vector2).distance_to(d.get("s_pos", Vector2.ZERO))
	_check("B4: in died: its global position == S2's (+-%.0f px)" % POS_TOL, dist <= POS_TOL, "dist=%f" % dist)
	_check("B4: in died: both emitters emitting=false, amount_ratio=0", not d.is_empty() and _both_emitting(d, false)
			and _both_ratio(d, 0.0), str(d))
	_check("B4: emitting stayed false and ratio 0 on both in every frame until freed", stays_off)
	_check("B4: BurningEmbers outlived S2 and freed itself after %d +-%d frames (Smoke lifetime 1.20 s)" % [
			TAIL_FRAMES, TAIL_FRAMES_TOL], r["fx_freed"] > r["died_frame"] and absi(life - TAIL_FRAMES) <= TAIL_FRAMES_TOL,
			"life=%d" % life)
	_check("B4: World/Effects holds no B tail after it finished", effects.get_child_count() == 0,
			"children=%d" % effects.get_child_count())
	_info("sc9 end")


## 10. B5 end of game + A5 carry-over: T burns when the run is lost; World disabled freezes T's emitters.
func _sc10_game_over() -> void:
	_check("sc10 setup: the run is still playing before scenario 10 (gate_hp %.2f)" % game.gate_hp,
			game.state == Game.State.PLAYING, "state=%d" % game.state)
	if game.state != Game.State.PLAYING:
		return
	var f0 := fires.size()
	var h0 := hits.size()
	var t := _spawn(Vector2(game.archer.position.x + 40.0, Tuning.SCARECROW_STOP_Y), "T")
	await game.archer.fired
	await process_frame
	_key(KEY_D, true)
	for x in [80.0, 140.0, 200.0, 260.0, 320.0, 380.0, 440.0, 500.0]:
		_spawn(Vector2(x, Tuning.SCARECROW_STOP_Y), "W")
	var cap := 900
	while cap > 0 and game.state == Game.State.PLAYING:
		await physics_frame
		cap -= 1
		if game.archer.position.x >= RIGHT_X:
			_key(KEY_D, false)
	_key(KEY_D, false)
	var r: Dictionary = rec["T"]
	print("INFO sc10 run lost at frame %d, fires %s, T hits %d, T burn %.4f hp %.2f, World/Effects children %d" % [
		_frame(), _fire_log(f0), _hits_on("T", h0), t.burn_time_left if is_instance_valid(t) else -1.0,
		t.hp if is_instance_valid(t) else -1.0, effects.get_child_count()])
	_check("sc10 setup: the run is lost with T alive and burning, hit by exactly one arrow (the only one fired)",
			game.state == Game.State.LOST and is_instance_valid(t) and t.is_burning() and _hits_on("T", h0) == 1
			and fires.size() - f0 == 1 and _fires_on("T", f0) == 1, "fires=%s" % _fire_log(f0))
	_check("B5: game over sets World to PROCESS_MODE_DISABLED", game.world.process_mode == Node.PROCESS_MODE_DISABLED)
	var before := _snap(r)
	var b0 := t.burn_time_left
	var same := true
	var can := false
	for i in 30:
		await physics_frame
		same = same and _snap(r) == before and t.burn_time_left == b0
		can = can or (r["embers"] as Node).can_process() or (r["smoke"] as Node).can_process()
	print("INFO sc10 30 frames after the loss: T burn %.4f -> %.4f, ratios %.4f -> %.4f, emitting %s" % [
		b0, t.burn_time_left, before["e_ratio"], (r["embers"] as GPUParticles2D).amount_ratio, (r["embers"] as GPUParticles2D).emitting])
	_check("B5: after the loss T's emitters cannot process", not can)
	_check("B5: 30 frames after the loss: T's burn_time_left, ratios and emitting unchanged",
			same and _both_emitting(before, true) and before["e_ratio"] > 0.0, str(before))
	var live_at_r := effects.get_child_count()
	_key(KEY_R, true)
	_key(KEY_R, false)
	var r_frame := _frame()
	await process_frame
	_check("sc10 setup: R restarts the run", game.state == Game.State.PLAYING)
	cap = 120
	while cap > 0 and effects.get_child_count() > 0:
		await physics_frame
		cap -= 1
	var took := _frame() - r_frame
	print("INFO sc10 World/Effects had %d children at R, empty %d frames after R" % [live_at_r, took])
	_check("A5: after R, World/Effects is empty within %d frames (1.20 s)" % RESET_LIMIT_FRAMES,
			effects.get_child_count() == 0 and took <= RESET_LIMIT_FRAMES, "took=%d" % took)
