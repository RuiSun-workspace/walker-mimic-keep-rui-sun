extends SceneTree
## Step 6 edge tests (CHANGE-BRIEF §4, §5.4-5.5, revision 1.1-1.2): the archer's committing shot at
## each phase boundary, with each interrupt arriving one tick before the boundary, on it, and one after.
##   ./scripts/run-test.sh test_archer_edges.gd 60
##
## Drives the real main scene only as the state tests do: spawning_enabled = false, scarecrows placed
## with Game.spawn_scarecrow(), keys through Input.parse_input_event (D move, P pause, R restart).
## Never calls travel(), start(), cancel_shot(), _fire_at() or reset(); never assigns to an archer,
## tree or scarecrow variable. Reads state only. Every scenario starts from a fresh run: the previous
## run is ended by the gate falling (scarecrows placed at the wall, out of the cone) and R is pressed.
##
## Frame model (same as test_pins_a7.gd / test_archer_state_machine.gd). --fixed-fps 60, 60 ticks/s:
## one loop iteration = one physics tick. The script resumes on SceneTree.physics_frame, before the
## nodes' physics step. rec[f] is the state left by tick f (f = 0 is the setup); a fired signal emitted
## during tick f is stamped f. A key or spawn made at resume f takes effect in tick f + 1, so an
## interrupt "on tick t" is sent at resume t - 1. Node order inside a tick (main.tscn): Enemies (walk,
## burn, gate damage), Arrows (flight, hits), Archer (archer.gd), then its child AnimationTree.

const MAIN := preload("res://game/main.tscn")
const TICK := 1.0 / 60.0
const STEP_PX := Tuning.ARCHER_SPEED / 60.0     # 7 px per tick while a move key is held
const CADENCE := 36                              # §5.2: FIRE_INTERVAL 0.6 s at 60 ticks/s

# ---- scenario design (chosen, not measured) -------------------------------------------------------
const WALKER_AT := Vector2(640, 300)    # straight above the archer, far: stays in the cone while D moves it
const CONE_AT := Vector2(570, Tuning.SCARECROW_STOP_Y)   # at the wall 70 px left: in the cone at archer
										# x 640 (59.0 deg), out after one 7-px step to x 647 (61.4 deg > 60)
const WALL_N := 40                      # scarecrows placed at the wall, out of the cone, to end a run
const CONE_HOLD_TICKS := 6              # D held for ticks t .. t+5 in the cone scenarios
const PAUSE_TICKS := 10                 # P on tick t, P again 10 ticks later
const RESTART_AFTER := 10               # ticks watched frozen after the loss, then R
const RESPAWN_AFTER := 3                # new run: target placed 3 resumes after R

# ---- boundaries of the shot under test, in ticks from the setup: measured 2026-11-21 --------------
const SHOT1_DRAW := 1                   # measured 2026-11-21: target in the cone at f 0, cooldown 0 -> draw
const SHOT2_DRAW := 37                  # measured 2026-11-21: T, the second (back-to-back) shot's draw
const ACTIVE_OFF := 18                  # measured 2026-11-21: A - T, fired is emitted
const RECOVERY_OFF := 19                # measured 2026-11-21: R - T, the tick after fired
const END_OFF := 31                     # measured 2026-11-21: E - T, first tick the tree reports idle again
const LOSS_TICKS := 31                  # measured 2026-11-21: 40 wall scarecrows placed at f s -> LOST on f s+31
const RECOVERY_TIME := 9.0 / 30.0       # §4: recovery begins on clip frame 9 (0.3 s)
const BT := SHOT2_DRAW
const BA := SHOT2_DRAW + ACTIVE_OFF
const BR := SHOT2_DRAW + RECOVERY_OFF
const BE := SHOT2_DRAW + END_OFF

const SHOT_KEYS := ["armed", "node", "pos", "rw", "cd", "fired"]
const FREEZE_KEYS := ["armed", "node", "pos", "rw", "cd", "x", "lock", "world"]

var game: Game
var archer: Archer
var tree: AnimationTree
var pb: AnimationNodeStateMachinePlayback

var passed := 0
var failed := 0
var inexact: Array[String] = []
var scen := ""
var f := 0
var rec: Array[Dictionary] = []
var pending := 0
var verbose := false
var named := {}                         # name -> Scarecrow placed in the current scenario
var base_w: Array[Dictionary] = []      # baseline: walker only
var base_c: Array[Dictionary] = []      # baseline: cone target + walker
var death_runs := {}                    # "BOUNDARY:off" -> run
var death_all: Array[Dictionary] = []   # every (boundary, offset) seen in the scan, for the nearest fallback


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	game = MAIN.instantiate() as Game
	game.spawning_enabled = false
	root.add_child(game)
	archer = game.archer
	tree = archer.get_node("AnimationTree") as AnimationTree
	pb = tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
	archer.fired.connect(_on_fired)
	await process_frame
	for i in 3:
		await physics_frame   # the tree leaves Start in its first update

	await _measure()
	await _death_scan()

	var bounds := [["START", BT], ["ACTIVE", BA], ["RECOVERY", BR], ["END", BE]]
	for b in bounds:
		var bname: String = b[0]
		var B: int = b[1]
		print("")
		print("==== boundary %s: tick %d (T%+d) ====" % [bname, B, B - BT])
		print("---- %s / the locked target leaves the cone ----" % bname)
		for d in [-1, 0, 1]:
			await _scen_cone(bname, B, B + d)
		print("---- %s / a move key pressed and held ----" % bname)
		for d in [-1, 0, 1]:
			await _scen_move(bname, B, B + d)
		print("---- %s / pause (P, then P %d ticks later) ----" % [bname, PAUSE_TICKS])
		for d in [-1, 0, 1]:
			await _scen_pause(bname, B, B + d)
		print("---- %s / the game ends (the gate falls), then R ----" % bname)
		for d in [-1, 0, 1]:
			await _scen_gameend(bname, B, B + d)
		print("---- %s / the locked target dies ----" % bname)
		for d in [-1, 0, 1]:
			_death_checks(bname, d)

	print("")
	await _info_restart_first_tick()

	print("")
	if inexact.is_empty():
		print("NOT AT THE EXACT TICK: none")
	else:
		print("NOT AT THE EXACT TICK:")
		for s in inexact:
			print("  %s" % s)
	print("RESULT test_archer_edges: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _check(name: String, ok: bool, detail: String = "") -> void:
	if ok:
		passed += 1
		print("PASS %s" % name)
	else:
		failed += 1
		print("FAIL %s  %s" % [name, detail])


# ---- the loop -------------------------------------------------------------------------------------

func _key(code: Key, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.physical_keycode = code
	ev.pressed = pressed
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


func _tap(code: Key) -> void:
	_key(code, true)
	_key(code, false)


func _sample() -> Dictionary:
	var lock := ""
	var lt = archer.locked_target
	if is_instance_valid(lt):
		lock = "?"
		for k in named:
			if is_instance_valid(named[k]) and named[k] == lt:
				lock = k
	var d := {"f": f, "armed": archer.shot_armed, "node": String(pb.get_current_node()),
		"pos": pb.get_current_play_position(), "rw": archer.release_window, "cd": archer.fire_cooldown,
		"x": archer.position.x, "lock": lock, "fired": 0, "state": game.state, "paused": paused,
		"arrows": _live_arrows(), "world": _world_sig()}
	for k in named:
		var live := _live(named[k])
		d[k + "_live"] = live
		d[k + "_cone"] = live and _in_cone(named[k])
	return d


func _world_sig() -> String:
	var parts := PackedStringArray()
	for c in game.enemies.get_children():
		if not c.is_queued_for_deletion():
			parts.append("s%.5f,%.5f,%.5f" % [c.position.x, c.position.y, (c as Scarecrow).hp])
	for c in game.arrows.get_children():
		if not c.is_queued_for_deletion():
			parts.append("a%.5f,%.5f" % [c.position.x, c.position.y])
	return ";".join(parts)


func _line(s: Dictionary, label := "") -> String:
	return "%s f=%d | node=%s pos=%.4f armed=%s rw=%s cd=%.6f x=%.1f lock=%s state=%s paused=%s | fired=%d" % [
		label if label != "" else scen, s["f"], s["node"], s["pos"], s["armed"], s["rw"], s["cd"], s["x"], s["lock"],
		Game.State.keys()[s["state"]], s["paused"], s["fired"]]


func _begin(name: String, loud: bool) -> void:
	scen = name
	verbose = loud
	f = 0
	pending = 0
	rec = [_sample()]
	if loud:
		print("---- scenario %s ----" % name)


func _step() -> void:
	await physics_frame
	f += 1
	var s := _sample()
	s["fired"] = pending
	pending = 0
	rec.append(s)
	if verbose:
		print(_line(s))


func _on_fired(_arrow: Arrow) -> void:
	pending += 1


## Runs one scenario: act(f) is called at the setup (f = 0) and at every resume after the sample.
func _run_scen(name: String, n: int, act: Callable, loud := false, stop := Callable()) -> Array[Dictionary]:
	named = {}
	_begin(name, loud)
	act.call(0)
	for i in n:
		await _step()
		act.call(f)
		if stop.is_valid() and stop.call(f):
			break
	return rec.duplicate()


func _trace(r: Array[Dictionary], t: int, label: String) -> void:
	for k in range(maxi(t - 2, 0), mini(t + 3, r.size())):
		print("  " + _line(r[k], label))


func _spawn(at: Vector2) -> Scarecrow:
	return game.spawn_scarecrow(at)


## WALL_N scarecrows at the wall, far from the archer (out of the cone); each hits the gate every tick.
func _spawn_wall() -> void:
	var base := archer.position.x - 420.0 if archer.position.x >= 560.0 else archer.position.x + 420.0
	for i in WALL_N:
		game.spawn_scarecrow(Vector2(base - (i % 10) * 10.0, Tuning.SCARECROW_STOP_Y))


func _live(s) -> bool:   # untyped (Variant): a freed scarecrow fails even an Object type check
	return is_instance_valid(s) and (s as Scarecrow).is_inside_tree() \
			and not (s as Scarecrow).is_queued_for_deletion() and not (s as Scarecrow).is_dead()


func _in_cone(s: Scarecrow) -> bool:   # the test's own cone check, not archer.nearest_target()
	var to := s.global_position - archer.global_position
	return absf(Vector2.UP.angle_to(to)) <= deg_to_rad(Tuning.FIRE_CONE_DEG / 2.0)


func _live_arrows() -> int:
	return game.arrows.get_children().filter(func(c: Node) -> bool: return not c.is_queued_for_deletion()).size()


## Ends the current run by the gate falling, then R: the next scenario starts from a fresh run.
func _clean_slate() -> void:
	_begin("clean", false)
	_key(KEY_A, false)
	_key(KEY_D, false)
	if paused:
		_tap(KEY_P)
	if game.state == Game.State.PLAYING:
		_spawn_wall()
		while game.state == Game.State.PLAYING and f < 400:
			await _step()
	await _restart_clean()


func _restart_clean() -> void:
	_tap(KEY_R)
	for i in 2:
		await _step()
	var ok := game.state == Game.State.PLAYING and not paused and archer.fire_cooldown == 0.0 \
			and archer.position == Game.ARCHER_START and not archer.shot_armed \
			and String(pb.get_current_node()) == "idle" and game.enemies.get_child_count() == 0 \
			and game.arrows.get_child_count() == 0 and game.gate_hp == Tuning.GATE_HP
	if not ok:
		_check("(setup) a fresh run after R", false, "state %s paused %s cd %f x %s armed %s node %s enemies %d arrows %d gate %f" % [
			game.state, paused, archer.fire_cooldown, archer.position, archer.shot_armed, pb.get_current_node(),
			game.enemies.get_child_count(), game.arrows.get_child_count(), game.gate_hp])


# ---- analysis helpers -----------------------------------------------------------------------------

func _draws(r: Array[Dictionary]) -> Array[int]:
	var out: Array[int] = []
	for k in range(1, r.size()):
		if bool(r[k]["armed"]) and not bool(r[k - 1]["armed"]):
			out.append(k)
	return out


func _fires(r: Array[Dictionary], from := 0, to := 1 << 30) -> Array[int]:
	var out: Array[int] = []
	for k in range(maxi(from, 0), mini(to + 1, r.size())):
		for n in int(r[k]["fired"]):
			out.append(k)
	return out


## Start of recovery as observed: the first tick after fired on which the tree has played past the
## active frame (play position >= 9/30 s). In an unpaused run this is fired + 1 (checked in _measure).
func _recovery_after(r: Array[Dictionary], fired_at: int) -> int:
	for k in range(fired_at + 1, r.size()):
		if r[k]["node"] == "shoot" and float(r[k]["pos"]) >= RECOVERY_TIME - 1e-4:
			return k
	return -1


func _first_idle_after(r: Array[Dictionary], k0: int) -> int:
	for k in range(k0 + 1, r.size()):
		if r[k]["node"] == "idle":
			return k
	return -1


func _diff(a: Dictionary, b: Dictionary, keys: Array) -> String:
	var out := ""
	for k in keys:
		var x = a.get(k)
		var y = b.get(k)
		var same: bool = absf(float(x) - float(y)) < 1e-9 if (x is float and y is float) else x == y
		if not same:
			out += "%s %s/%s " % [k, str(x).left(60), str(y).left(60)]
	return out


## rec[k + shift] against base[k] for k in from..to.
func _seq_diff(r: Array[Dictionary], base: Array[Dictionary], from: int, to: int, shift := 0,
		keys: Array = SHOT_KEYS) -> String:
	var out := ""
	for k in range(maxi(from, 0), to + 1):
		if k + shift >= r.size() or k >= base.size():
			out += "[f=%d out of range] " % (k + shift)
			break
		var d := _diff(r[k + shift], base[k], keys)
		if d != "":
			out += "[f=%d vs base f=%d: %s] " % [k + shift, k, d]
			if out.length() > 500:
				break
	return out


func _armed_ticks(r: Array[Dictionary], from: int, to: int) -> String:
	var out := ""
	for k in range(maxi(from, 0), mini(to + 1, r.size())):
		if bool(r[k]["armed"]):
			out += "%d " % k
	return out


## Brief §5.5, startup row: cancel, back to idle at once, cooldown continues, no new target that tick.
func _check_cancel(tag: String, r: Array[Dictionary], t: int, other_target: String) -> void:
	var a: Dictionary = r[t - 1]
	var c: Dictionary = r[t]
	_check("%s §5.5 startup: drawing on tick %d (armed, shoot), cancelled on tick %d (shot_armed false)" % [tag, t - 1, t],
		bool(a["armed"]) and a["node"] == "shoot" and not bool(c["armed"]),
		"armed %s/%s node %s" % [a["armed"], c["armed"], a["node"]])
	_check("%s §5.5 startup: back in idle at once on tick %d, locked target cleared (node %s, lock \"%s\")" % [
		tag, t, c["node"], c["lock"]], c["node"] == "idle" and c["lock"] == "")
	_check("%s §5.5 startup: the cooldown continues as normal (%.6f -> %.6f)" % [tag, a["cd"], c["cd"]],
		is_equal_approx(float(c["cd"]), maxf(float(a["cd"]) - TICK, 0.0)))
	var late := _fires(r, t, t + ACTIVE_OFF)
	_check("%s §5.5 startup: no arrow from the cancelled shot (none on ticks %d..%d)" % [tag, t, t + ACTIVE_OFF],
		late.is_empty(), str(late))
	if other_target != "":
		_check("%s §5.5 no new target on the cancel tick, although %s is in the cone on it" % [tag, other_target],
			bool(c[other_target + "_cone"]) and not bool(c["armed"]))
		var n: Dictionary = r[t + 1]
		_check("%s §5.2 the next tick (%d) draws on %s by the normal rule: idle, in the cone, cooldown %.4f <= 0.3" % [
			tag, t + 1, other_target, n["cd"]],
			bool(n["armed"]) and n["node"] == "shoot" and n["lock"] == other_target and float(n["cd"]) <= 0.3,
			"armed %s node %s lock %s" % [n["armed"], n["node"], n["lock"]])
	else:
		var armed := _armed_ticks(r, t, r.size() - 1)
		_check("%s no draw after the cancel: no target is left (ticks %d..%d)" % [tag, t, r.size() - 1],
			armed == "", armed)


## Brief §5.5, active and recovery rows: no effect. The shot releases once on A and plays out to E.
func _check_no_effect(tag: String, r: Array[Dictionary], t: int, bt: int, ba: int, be: int,
		base: Array[Dictionary]) -> void:
	if not base.is_empty():
		var dd := _seq_diff(r, base, t, be + 1)
		_check("%s §5.5 no effect: armed/node/pos/rw/cd/fired equal the baseline on ticks %d..%d" % [tag, t, be + 1],
			dd == "", dd)
	var fs := _fires(r, bt, be + 1)
	_check("%s §5.5 the shot released exactly once, on A=%d (fired on %s)" % [tag, ba, str(fs)], fs == [ba])
	var armed := _armed_ticks(r, ba, be)
	_check("%s §5.5 the recovery plays out: shoot through %d, idle on E=%d, never re-armed (%s / %s)" % [
		tag, be - 1, be, r[be - 1]["node"], r[be]["node"]],
		r[be - 1]["node"] == "shoot" and r[be]["node"] == "idle" and armed == "", "armed on " + armed)


# ---- measurement ----------------------------------------------------------------------------------

func _measure() -> void:
	print("==== measuring the boundaries (no interrupt) ====")
	_begin("calib-loss", false)
	named = {}
	_spawn_wall()
	while game.state == Game.State.PLAYING and f < 300:
		await _step()
	print("MEASURED loss: %d scarecrows placed at the wall at f 0 of a fresh run -> LOST on f %d" % [WALL_N, f])
	_check("[measure] %d wall scarecrows end a fresh run on f %d (got %d)" % [WALL_N, LOSS_TICKS, f], f == LOSS_TICKS)
	await _restart_clean()

	var act_w := func(fr: int) -> void:
		if fr == 0:
			named["walker"] = _spawn(WALKER_AT)
	base_w = await _run_scen("baseline-walker", BE + 45, act_w, true)
	await _clean_slate()
	var act_c := func(fr: int) -> void:
		if fr == 0:
			named["wall"] = _spawn(CONE_AT)
			named["walker"] = _spawn(WALKER_AT)
	base_c = await _run_scen("baseline-cone", BE + 45, act_c, true)
	await _clean_slate()

	for pair in [["walker", base_w], ["cone", base_c]]:
		var r: Array[Dictionary] = pair[1]
		var ds := _draws(r)
		var fs := _fires(r)
		if ds.size() < 2 or fs.size() < 2:
			_check("[measure] (%s) two shots in the baseline" % pair[0], false, "draws %s fires %s" % [ds, fs])
			continue
		var e1 := _first_idle_after(r, ds[0])
		var e2 := _first_idle_after(r, ds[1])
		print("MEASURED (%s) shot 1: T %d, A %d, R %d, E %d | shot 2: T %d, A %d, R %d, E %d | release_window on R: %s, on R+1: %s; play position on R %.4f" % [
			pair[0], ds[0], fs[0], fs[0] + 1, e1, ds[1], fs[1], fs[1] + 1, e2,
			r[fs[1] + 1]["rw"], r[fs[1] + 2]["rw"], r[fs[1] + 1]["pos"]])
		print("MEASURED (%s) offsets from T: A %+d, R %+d, E %+d" % [pair[0], fs[1] - ds[1], fs[1] + 1 - ds[1], e2 - ds[1]])
		_check("[measure] (%s) shot 1 draws on f %d (got %d)" % [pair[0], SHOT1_DRAW, ds[0]], ds[0] == SHOT1_DRAW)
		_check("[measure] (%s) shot 2 draws on T = f %d (got %d)" % [pair[0], SHOT2_DRAW, ds[1]], ds[1] == SHOT2_DRAW)
		_check("[measure] (%s) fired on A = T%+d for both shots (got %+d, %+d)" % [pair[0], ACTIVE_OFF, fs[0] - ds[0], fs[1] - ds[1]],
			fs[0] - ds[0] == ACTIVE_OFF and fs[1] - ds[1] == ACTIVE_OFF)
		var rs := _recovery_after(r, fs[1])
		_check("[measure] (%s) recovery starts on R = T%+d, the tick after fired: the tree has played to 9/30 s, shot_armed already false (got %+d, pos %.4f)" % [
			pair[0], RECOVERY_OFF, rs - ds[1], r[fs[1] + 1]["pos"]],
			rs - ds[1] == RECOVERY_OFF and rs == fs[1] + 1 and not bool(r[rs]["armed"]))
		_check("[measure] (%s) the tree reports idle again on E = T%+d for both shots (got %+d, %+d)" % [pair[0], END_OFF, e1 - ds[0], e2 - ds[1]],
			e1 - ds[0] == END_OFF and e2 - ds[1] == END_OFF)
		_check("[measure] (%s) §5.2 back-to-back releases %d ticks apart (got %d)" % [pair[0], CADENCE, fs[1] - fs[0]],
			fs[1] - fs[0] == CADENCE)
	print("BOUNDARIES of the shot under test (shot 2): START T=%d, ACTIVE A=%d, RECOVERY R=%d, END E=%d" % [BT, BA, BR, BE])


# ---- target leaves the cone -----------------------------------------------------------------------

func _scen_cone(bname: String, B: int, t: int) -> void:
	var tag := "[%s] cone t=%d (B%+d)" % [bname, t, t - B]
	var act := func(fr: int) -> void:
		if fr == 0:
			named["wall"] = _spawn(CONE_AT)
			named["walker"] = _spawn(WALKER_AT)
		if fr == t - 1:
			_key(KEY_D, true)
		if fr == t - 1 + CONE_HOLD_TICKS:
			_key(KEY_D, false)
	var r: Array[Dictionary] = await _run_scen(tag, BE + 22, act)
	await _clean_slate()
	_trace(r, t, tag)
	_check("%s setup: the locked target is in the cone on tick %d and out on tick %d (D from tick %d)" % [tag, t - 1, t, t],
		bool(r[t - 1]["wall_cone"]) and not bool(r[t]["wall_cone"]) and bool(r[t]["walker_cone"]))
	var dd := _seq_diff(r, base_c, 0, t - 1)
	_check("%s nothing differs from the baseline before tick %d" % [tag, t], dd == "", dd)
	if t <= BT:
		var locked := ""
		for k in range(t, r.size()):
			if r[k]["lock"] == "wall":
				locked += "%d " % k
		_check("%s §5.2/§5.3 no draw locks the departed target on tick %d or later" % [tag, t], locked == "", locked)
		_check("%s §5.2 the draw still starts on T=%d (cooldown <= 0.3, idle) and locks the walker, the target left in the cone" % [tag, BT],
			not bool(r[BT - 1]["armed"]) and bool(r[BT]["armed"]) and r[BT]["node"] == "shoot" and r[BT]["lock"] == "walker",
			"armed %s/%s lock %s" % [r[BT - 1]["armed"], r[BT]["armed"], r[BT]["lock"]])
		_check("%s that draw releases on A=%d as usual" % [tag, BA], _fires(r, BT, BA) == [BA], str(_fires(r, BT, BA)))
	elif t < BA:
		_check_cancel(tag, r, t, "walker")
	else:
		_check_no_effect(tag, r, t, BT, BA, BE, base_c)
		if t == BA:
			_check("%s §5.5 the arrow released on the tick the target leaves still goes (fired on %d, target outside the cone on it, arrow in flight)" % [tag, BA],
				int(r[BA]["fired"]) == 1 and not bool(r[BA]["wall_cone"]) and int(r[BA]["arrows"]) >= 1)


# ---- move -----------------------------------------------------------------------------------------

func _scen_move(bname: String, B: int, t: int) -> void:
	var tag := "[%s] move t=%d (B%+d)" % [bname, t, t - B]
	var last := BE + 3
	var act := func(fr: int) -> void:
		if fr == 0:
			named["walker"] = _spawn(WALKER_AT)
		if fr == t - 1:
			_key(KEY_D, true)
		if fr == last:
			_key(KEY_D, false)
	var r: Array[Dictionary] = await _run_scen(tag, last + 2, act)
	await _clean_slate()
	_trace(r, t, tag)
	var bad := ""
	for k in range(1, last + 1):
		var dx := float(r[k]["x"]) - float(r[k - 1]["x"])
		var want := STEP_PX if k >= t else 0.0
		if absf(dx - want) > 1e-6:
			bad += "[f=%d dx=%.4f] " % [k, dx]
	_check("%s §5.5 move: the archer moves %.0f px on every tick %d..%d held, through every phase, and not before" % [
		tag, STEP_PX, t, last], bad == "", bad)
	var dd := _seq_diff(r, base_w, 0, last)
	_check("%s §5.5 move never interrupts: armed/node/pos/rw/cd/fired equal the baseline on ticks 0..%d (T %d, A %d, R %d, E %d unchanged)" % [
		tag, last, BT, BA, BR, BE], dd == "", dd)
	var out := ""
	for k in range(t, last + 1):
		if not bool(r[k]["walker_cone"]):
			out += "%d " % k
	_check("%s setup: the target stays in the cone while the archer moves" % tag, out == "", out)


# ---- pause ----------------------------------------------------------------------------------------

func _scen_pause(bname: String, B: int, t: int) -> void:
	var tag := "[%s] pause t=%d (B%+d)" % [bname, t, t - B]
	var act := func(fr: int) -> void:
		if fr == 0:
			named["walker"] = _spawn(WALKER_AT)
		if fr == t - 1 or fr == t - 1 + PAUSE_TICKS:
			_tap(KEY_P)
	var r: Array[Dictionary] = await _run_scen(tag, BE + PAUSE_TICKS + 6, act)
	await _clean_slate()
	_trace(r, t, tag)
	var pflags := true
	for k in range(t, t + PAUSE_TICKS):
		pflags = pflags and bool(r[k]["paused"])
	_check("%s setup: paused on ticks %d..%d, running on %d and %d" % [tag, t, t + PAUSE_TICKS - 1, t - 1, t + PAUSE_TICKS],
		pflags and not bool(r[t - 1]["paused"]) and not bool(r[t + PAUSE_TICKS]["paused"]))
	var dd := _seq_diff(r, base_w, 0, t - 1)
	_check("%s nothing differs from the baseline before tick %d" % [tag, t], dd == "", dd)
	var frozen := ""
	for k in range(t, t + PAUSE_TICKS):
		var d := _diff(r[k], r[t - 1], FREEZE_KEYS)
		if d != "" or int(r[k]["fired"]) != 0:
			frozen += "[f=%d: %s fired %d] " % [k, d, r[k]["fired"]]
	_check("%s §5.5 pause: everything freezes on ticks %d..%d (tree node and play position %.4f, release_window %s, shot_armed, cooldown, target, scarecrows, arrows), no arrow" % [
		tag, t, t + PAUSE_TICKS - 1, r[t - 1]["pos"], r[t - 1]["rw"]], frozen == "", frozen)
	var sd := _seq_diff(r, base_w, t, BE + 5, PAUSE_TICKS)
	_check("%s §5.5 pause: the shot resumes from the same frame: tick k+%d equals baseline tick k for k = %d..%d" % [
		tag, PAUSE_TICKS, t, BE + 5], sd == "", sd)
	# the four boundaries, read from the paused run
	var ds := _draws(r)
	var fs := _fires(r)
	var got := [-1, -1, -1, -1]
	if ds.size() >= 2 and fs.size() >= 2:
		got = [ds[1], fs[1], _recovery_after(r, fs[1]), _first_idle_after(r, ds[1])]
	var want := []
	for b in [BT, BA, BR, BE]:
		want.append(b + PAUSE_TICKS if b >= t else b)
	print("MEASURED %s boundaries T, A, R, E: %s (unpaused %s)" % [tag, str(got), str([BT, BA, BR, BE])])
	_check("%s §5.5 pause: each boundary on or after tick %d moves by exactly %d ticks, earlier ones stay (want %s, got %s)" % [
		tag, t, PAUSE_TICKS, str(want), str(got)], got == want)


# ---- game end -------------------------------------------------------------------------------------

func _scen_gameend(bname: String, B: int, t: int) -> void:
	var tag := "[%s] gameend t=%d (B%+d)" % [bname, t, t - B]
	var s_w := t - LOSS_TICKS
	if s_w < 0:
		inexact.append("%s: wall scarecrows cannot be placed before the setup" % tag)
		s_w = 0
	var r_at := t + RESTART_AFTER
	var sp := r_at + RESPAWN_AFTER
	var after_r := {}
	var act := func(fr: int) -> void:
		if fr == 0:
			named["walker"] = _spawn(WALKER_AT)
		if fr == s_w:
			_spawn_wall()
		if fr == r_at:
			_tap(KEY_R)
			after_r["state"] = game.state
			after_r["armed"] = archer.shot_armed
			after_r["target"] = is_instance_valid(archer.locked_target)
		if fr == sp:
			named["walker2"] = _spawn(WALKER_AT)
	var r: Array[Dictionary] = await _run_scen(tag, sp + ACTIVE_OFF + 6, act)
	await _clean_slate()
	var L := -1
	for k in r.size():
		if r[k]["state"] != Game.State.PLAYING:
			L = k
			break
	_trace(r, maxi(L, 1), tag)
	if L != t:
		inexact.append("%s: the gate fell on tick %d instead of %d" % [tag, L, t])
		print("NOT AT THE EXACT TICK %s: the gate fell on tick %d" % [tag, L])
	_check("%s setup: the gate falls on tick %d (LOST first on f %d)" % [tag, t, L], L == t)
	if L < 1:
		return
	var dd := _seq_diff(r, base_w, 0, L - 1)
	_check("%s nothing differs from the baseline before tick %d" % [tag, L], dd == "", dd)
	var frozen := ""
	for k in range(L, r_at + 1):
		var d := _diff(r[k], r[L - 1], ["armed", "node", "pos", "rw", "cd", "x", "lock"])
		if d != "" or int(r[k]["fired"]) != 0:
			frozen += "[f=%d: %s fired %d] " % [k, d, r[k]["fired"]]
	_check("%s §5.5 game end: the shot freezes as it was after tick %d (node %s, pos %.4f, armed %s, rw %s) and no arrow is released on ticks %d..%d" % [
		tag, L - 1, r[L - 1]["node"], r[L - 1]["pos"], r[L - 1]["armed"], r[L - 1]["rw"], L, r_at], frozen == "", frozen)
	_check("%s rev. 1.1 R: the run restarts and shot_armed and the locked target are cleared at once (state %s, armed %s, target %s)" % [
		tag, after_r.get("state"), after_r.get("armed"), after_r.get("target")],
		after_r.get("state") == Game.State.PLAYING and after_r.get("armed") == false and after_r.get("target") == false)
	var n: Dictionary = r[r_at + 1]
	_check("%s §5.5 R: the tree is in idle on the first tick of the new run (%d), release_window false, not armed (node %s, rw %s, armed %s)" % [
		tag, r_at + 1, n["node"], n["rw"], n["armed"]], n["node"] == "idle" and not bool(n["rw"]) and not bool(n["armed"]))
	var late := _fires(r, L, sp + ACTIVE_OFF)
	_check("%s §5.5 R: no late arrow (none on ticks %d..%d)" % [tag, L, sp + ACTIVE_OFF], late.is_empty(), str(late))
	_check("%s §5.2 new run: the first shot draws on the first tick its target is in the cone (%d), cooldown 0, by the normal rule" % [tag, sp + 1],
		not bool(r[sp]["armed"]) and bool(r[sp + 1]["armed"]) and r[sp + 1]["node"] == "shoot"
		and r[sp + 1]["lock"] == "walker2" and float(r[sp + 1]["cd"]) == 0.0,
		"armed %s/%s node %s lock %s cd %f" % [r[sp]["armed"], r[sp + 1]["armed"], r[sp + 1]["node"], r[sp + 1]["lock"], r[sp + 1]["cd"]])
	var fs := _fires(r, sp, r.size() - 1)
	_check("%s §5.2 new run: that shot releases %d ticks after its draw (on %d; got %s)" % [tag, ACTIVE_OFF, sp + 1 + ACTIVE_OFF, str(fs)],
		fs == [sp + 1 + ACTIVE_OFF])


# ---- the locked target dies -----------------------------------------------------------------------

## A target straight above the archer is shot until it dies, by real arrows and burn. Its height sets
## the arrows' flight time and so the tick it dies on; the scan steps the height 5 px at a time
## (about a third of a tick of flight) and keeps the first run whose death lands on each boundary +-1.
func _death_scan() -> void:
	print("")
	print("==== placing a target so its death lands on each boundary (scan of its start height) ====")
	var y := 430.0
	var runs := 0
	while y >= -220.0 and death_runs.size() < 12:
		var yy := y
		var dead := {"at": -1}
		var act := func(fr: int) -> void:
			if fr == 0:
				named["walker"] = _spawn(Vector2(640, yy))
		var stop := func(fr: int) -> bool:
			if int(dead["at"]) < 0 and not bool(rec[fr]["walker_live"]):
				dead["at"] = fr
			return int(dead["at"]) >= 0 and fr >= int(dead["at"]) + 24
		var r: Array[Dictionary] = await _run_scen("death y=%.0f" % y, 330, act, false, stop)
		await _clean_slate()
		runs += 1
		var D: int = dead["at"]
		var found := []
		if D > 0:
			for F in _fires(r):
				var nt := F + CADENCE - ACTIVE_OFF     # the next shot's draw
				var ot := F - ACTIVE_OFF               # this shot's draw
				for c in [["START", nt, nt, F + CADENCE, nt + END_OFF], ["ACTIVE", F + CADENCE, nt, F + CADENCE, nt + END_OFF],
						["RECOVERY", F + CADENCE + 1, nt, F + CADENCE, nt + END_OFF], ["RECOVERY", F + 1, ot, F, ot + END_OFF],
						["END", ot + END_OFF, ot, F, ot + END_OFF]]:
					var off: int = D - int(c[1])
					var run := {"rec": r, "t": D, "B": c[1], "bt": c[2], "ba": c[3], "be": c[4], "y": yy, "off": off, "b": c[0]}
					if absf(off) <= 3:
						death_all.append(run)
					if absf(off) <= 1 and not death_runs.has("%s:%d" % [c[0], off]):
						death_runs["%s:%d" % [c[0], off]] = run
						found.append("%s%+d" % [c[0], off])
		print("death scan y=%.0f: fired %s, died on f %d%s" % [y, str(_fires(r)), D,
			("  -> " + ", ".join(PackedStringArray(found))) if not found.is_empty() else ""])
		y -= 5.0
	print("death scan: %d runs, found %s" % [runs, str(death_runs.keys())])


func _death_checks(bname: String, d: int) -> void:
	var key := "%s:%d" % [bname, d]
	var run: Dictionary = death_runs.get(key, {})
	if run.is_empty():
		var best := {}
		for c in death_all:
			if c["b"] == bname and (best.is_empty() or absi(int(c["off"]) - d) < absi(int(best["off"]) - d)):
				best = c
		if best.is_empty():
			inexact.append("[%s] death B%+d: no run put the death within 3 ticks of this boundary; not tested" % [bname, d])
			print("NOT AT THE EXACT TICK [%s] death B%+d: not reachable, not tested" % [bname, d])
			return
		inexact.append("[%s] death B%+d: nearest reachable is B%+d (y %.0f, tick %d)" % [bname, d, best["off"], best["y"], best["t"]])
		print("NOT AT THE EXACT TICK [%s] death B%+d: testing the nearest, B%+d" % [bname, d, best["off"]])
		run = best
	var r: Array[Dictionary] = run["rec"]
	var t: int = run["t"]
	var bt: int = run["bt"]
	var ba: int = run["ba"]
	var be: int = run["be"]
	var tag := "[%s] death t=%d (B%+d; target from y %.0f; this shot T %d, A %d, E %d)" % [bname, t, t - int(run["B"]), run["y"], bt, ba, be]
	_trace(r, t, "death y=%.0f" % run["y"])
	_check("%s setup: the target is alive after tick %d and dead on tick %d (killed by a real arrow or burn)" % [tag, t - 1, t],
		bool(r[t - 1]["walker_live"]) and not bool(r[t]["walker_live"]))
	if t <= bt:
		var armed := _armed_ticks(r, t, r.size() - 1)
		_check("%s §5.2 no draw on T=%d or later: no target is left (armed on: %s)" % [tag, bt, armed],
			armed == "" and r[bt]["node"] == "idle")
		_check("%s no arrow after the death" % tag, _fires(r, t, r.size() - 1).is_empty(), str(_fires(r, t, r.size() - 1)))
	elif t < ba:
		_check_cancel(tag, r, t, "")
	else:
		var no_base: Array[Dictionary] = []
		_check_no_effect(tag, r, t, bt, ba, be, no_base)
		if t == ba:
			_check("%s §5.5 the arrow released on the tick the target dies still goes (fired on %d)" % [tag, ba],
				int(r[ba]["fired"]) == 1)
		var armed := _armed_ticks(r, be, r.size() - 1)
		_check("%s no new draw after the shot: no target is left" % tag, armed == "", armed)


# ---- information only -----------------------------------------------------------------------------

## The game clears every scarecrow on R and spawns the first one 1 s later, so a target on the very first
## tick of a new run cannot occur in real play. Reported, not asserted.
func _info_restart_first_tick() -> void:
	var t := BT + 5
	var r_at := t + RESTART_AFTER
	var act := func(fr: int) -> void:
		if fr == 0:
			named["walker"] = _spawn(WALKER_AT)
		if fr == t - LOSS_TICKS:
			_spawn_wall()
		if fr == r_at:
			_tap(KEY_R)
			named["walker2"] = _spawn(WALKER_AT)
	var r: Array[Dictionary] = await _run_scen("info-restart", r_at + 25, act)
	await _clean_slate()
	var ds := _draws(r)
	var first := -1
	for dt in ds:
		if dt > r_at:
			first = dt
			break
	print("INFO restart mid-startup (gate fell on tick %d, node %s), R at resume %d with a target placed in the same resume: tree on tick %d is %s; the new run's first draw is on tick %d (= R + %d)" % [
		t, r[t - 1]["node"], r_at, r_at + 1, r[r_at + 1]["node"], first, first - r_at])
