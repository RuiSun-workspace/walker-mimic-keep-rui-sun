extends SceneTree
## Step 2 pins (CHANGE-BRIEF §5, §10): what the archer does NOW, before any clip exists.
## Drives the real main scene only through keyboard events (Input.parse_input_event); never calls an
## archer or scarecrow method that changes state, never assigns to their variables. It only spawns
## scarecrows with Game.spawn_scarecrow() and reads state.
##   ./scripts/run-test.sh test_pins_a7.gd 60
##
## Frame model. --fixed-fps 60 and 60 physics ticks/s: one main-loop iteration = one physics tick.
## The script resumes on SceneTree.physics_frame, which is emitted BEFORE the nodes' physics step.
## So at each resume the world shows the result of the previous tick, and whatever the script does
## there (keys, spawns) takes effect in the next tick. A scenario's frame f counts game ticks
## completed since the scenario's setup (f = 0 is the setup itself). An event emitted during a
## tick (fired, died) is stamped with that tick's f and shows up in the log line of the same f.
## Every log line begins with Engine.get_process_frames() at the moment it is printed. Measured: an
## event emitted during the tick reports a process frame one lower (line "4 | a f=1" carries
## "fired ... pf 3"), so line P shows the state left by the physics tick of process frame P - 1.
##
## TIMING = numbers the brief changes on purpose (§5); re-pinned in Step 6.
## INVARIANT = must survive the change.

const MAIN := preload("res://game/main.tscn")
const TICK := 1.0 / 60.0
const FIRE_INTERVAL_TICKS := 36            # Tuning.FIRE_INTERVAL (0.6 s) at 60 ticks/s

# ---- scenario design (chosen, not measured) ----------------------------------------------------
const C_HOLD_D_TICKS := 40                 # (c) D held for ticks 1..40, then A for ticks 41..80
const C_HOLD_A_TICKS := 40
const D_PAUSE_AT_F := 28                   # (d) P pressed after tick 28 (first release f 19, next draw starts tick 37); moved 2026-11-21: CHANGE-BRIEF.md Revision 2, item 2 ...
const D_PAUSE_TICKS := 30                  # ... and again 30 ticks later
const E_WALL_HOLD_TICKS := 30              # (e) ticks watched after the scarecrow reaches the wall
const F_FROZEN_TICKS := 30                 # (f) ticks watched after the loss before R

# ---- TIMING: measured on baseline 2026-11-21 ----------------------------------------------------
const A_FIRST_SHOT_F := 19                 # re-pinned 2026-11-21 after the approved change: CHANGE-BRIEF.md Revision 2, item 1
const A_SHOT_GAPS := [36, 36, 36]          # measured on baseline 2026-11-21: (a) shots at f 1, 37, 73, 109
const A_DEATH_F := 136                     # re-pinned 2026-11-21 after the approved change: CHANGE-BRIEF.md Revision 2, item 1
const B_FIRST_SHOT_F := 19                 # re-pinned 2026-11-21 after the approved change: CHANGE-BRIEF.md Revision 2, item 1
const B_SHOT_GAPS := [36, 36, 36, 36, 36, 36, 36]   # measured on baseline 2026-11-21: 4 on B_near, 4 on B_far
const C_FIRST_SHOT_F := 19                 # re-pinned 2026-11-21 after the approved change: CHANGE-BRIEF.md Revision 2, item 1
const C_EXIT_F := 26                       # measured on baseline 2026-11-21: first frame the target is outside the cone
const C_CD_ZERO_F := 55                    # re-pinned 2026-11-21 after the approved change: CHANGE-BRIEF.md Revision 2, item 1
const C_REENTRY_F := 62                    # measured on baseline 2026-11-21: first frame it is back inside the cone
const C_REENTRY_SHOT_DELAY := 18           # re-pinned 2026-11-21 after the approved change: CHANGE-BRIEF.md Revision 2, item 1
const D_SHOT1_F := 19                      # re-pinned 2026-11-21 after the approved change: CHANGE-BRIEF.md Revision 2, item 2
const D_SHOT2_F := 85                      # re-pinned 2026-11-21 after the approved change: CHANGE-BRIEF.md Revision 2, item 2
const D_PAUSE_SHIFT := 30                  # measured on baseline 2026-11-21: (shot2 - shot1) - unpaused cadence
const E_WALL_F := 174                      # measured on baseline 2026-11-21: 130 px at 0.75 px/tick, rounded up
const F_LOSS_F := 103                      # re-pinned 2026-11-21 after the approved change: CHANGE-BRIEF.md Revision 2, item 3
const F_RESTART_SHOT_DELAY := 19           # re-pinned 2026-11-21 after the approved change: CHANGE-BRIEF.md Revision 2, item 1

var game: Game
var timing: Array[String] = []
var invariant: Array[String] = []
var passed := 0
var failed := 0

var scen := ""
var f := 0                 # ticks completed since the scenario's setup
var gt := 0                # ticks completed since the test started
var run_id := 0            # incremented by each restart
var act := 0               # ticks the archer processed (not paused, World enabled) in this run
var next_active := true    # will the archer process the coming tick?
var prev_cd := 0.0
var pending: Array[Dictionary] = []   # fired events since the last log line
var shots: Array[Dictionary] = []     # every fired event
var arrows_added := 0                 # arrows that entered World/Arrows since the last log line
var tracked: Array[int] = []          # scarecrow instance ids
var labels := {}                      # id -> label
var deaths := {}                      # label -> {scen, f}
var wall_prev := {}                   # id -> [at_wall, y] at the previous log line
var transitions: Array[Dictionary] = []
var last_key := -1
var last_key_gt := -1
var dispatching_key := false

# invariant counters, whole run
var inv_inactive_shots := 0
var inv_inactive_cd_changes := 0
var inv_inactive_detail := ""
var inv_arrow_mismatch := 0
var inv_arrow_detail := ""
var inv_wall_moves := 0
var inv_wall_detail := ""


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	game = MAIN.instantiate() as Game
	game.spawning_enabled = false
	root.add_child(game)
	game.archer.fired.connect(_on_fired)
	game.arrows.child_entered_tree.connect(func(_n: Node) -> void: arrows_added += 1)
	game.state_changed.connect(_on_state_changed)
	await process_frame
	scen = "boot"
	for i in 3:
		await _step()

	await _scen_a()
	await _scen_b()
	await _scen_c()
	await _scen_d()
	await _scen_e()
	await _scen_f()
	_global_invariants()

	print("== TIMING (changed on purpose by brief §5; re-pinned in Step 6) ==")
	for line in timing:
		print(line)
	print("== INVARIANT (must survive the change) ==")
	for line in invariant:
		print(line)
	print("RESULT test_pins_a7: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


# ---- checks -------------------------------------------------------------------------------------

func _record(group: Array[String], name: String, ok: bool, detail: String) -> void:
	if ok:
		passed += 1
		group.append("PASS %s" % name)
	else:
		failed += 1
		group.append("FAIL %s  %s" % [name, detail])


func _timing(name: String, measured: Variant, pinned: Variant) -> void:
	_record(timing, "%s = %s" % [name, str(pinned)], measured == pinned, "measured %s" % str(measured))


func _inv(name: String, ok: bool, detail: String = "") -> void:
	_record(invariant, name, ok, detail)


# ---- input --------------------------------------------------------------------------------------

func _key(code: Key, pressed: bool) -> void:
	if pressed:
		last_key = code
		last_key_gt = gt
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.physical_keycode = code
	ev.pressed = pressed
	dispatching_key = true
	Input.parse_input_event(ev)
	Input.flush_buffered_events()
	dispatching_key = false


func _tap(code: Key) -> void:
	_key(code, true)
	_key(code, false)


# ---- reading the world --------------------------------------------------------------------------

func _in_cone(s: Scarecrow) -> bool:
	var to := s.global_position - game.archer.global_position
	return absf(Vector2.UP.angle_to(to)) <= deg_to_rad(Tuning.FIRE_CONE_DEG / 2.0)


func _live(id: int) -> Scarecrow:
	var s := instance_from_id(id) as Scarecrow
	if s == null or not s.is_inside_tree() or s.is_queued_for_deletion() or s.is_dead():
		return null
	return s


func _nearest_in_cone() -> Scarecrow:
	var best: Scarecrow = null
	var best_d := INF
	for n in get_nodes_in_group("enemies"):
		var s := n as Scarecrow
		if s == null or s.is_dead() or not _in_cone(s):
			continue
		var d := (s.global_position - game.archer.global_position).length()
		if d < best_d:
			best_d = d
			best = s
	return best


func _aimed_at(arrow: Arrow) -> Scarecrow:
	var best: Scarecrow = null
	var best_a := INF
	for n in get_nodes_in_group("enemies"):
		var s := n as Scarecrow
		if s == null or s.is_dead():
			continue
		var a := absf(arrow.velocity.angle_to(s.global_position - arrow.position))
		if a < best_a:
			best_a = a
			best = s
	return best if best_a < 1e-3 else null


func _label(s: Scarecrow) -> String:
	return "none" if s == null else str(labels.get(s.get_instance_id(), "?"))


func _live_arrows() -> int:
	var n := 0
	for c in game.arrows.get_children():
		if not c.is_queued_for_deletion():
			n += 1
	return n


func _spawn(at: Vector2, label: String) -> Scarecrow:
	var s := game.spawn_scarecrow(at)
	var id := s.get_instance_id()
	tracked.append(id)
	labels[id] = label
	s.died.connect(func() -> void: deaths[label] = {"scen": scen, "f": f + 1})
	return s


func _shots_in(sc: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s in shots:
		if s["scen"] == sc:
			out.append(s)
	return out


func _gaps(list: Array[Dictionary]) -> Array:
	var out := []
	for i in range(1, list.size()):
		out.append(int(list[i]["f"]) - int(list[i - 1]["f"]))
	return out


# ---- listeners (read only) ----------------------------------------------------------------------

func _on_fired(arrow: Arrow) -> void:
	var tgt := _aimed_at(arrow)
	var near := _nearest_in_cone()
	var ev := {"scen": scen, "f": f + 1, "gt": gt + 1, "act": act + 1, "run": run_id,
		"pf": Engine.get_process_frames(), "target": _label(tgt), "nearest": _label(near),
		"in_cone": tgt != null and _in_cone(tgt), "parent_ok": arrow.get_parent() == game.arrows,
		"paused": paused, "state": game.state}
	pending.append(ev)
	shots.append(ev)


func _on_state_changed(s: Game.State) -> void:
	# Emitted by a key the script sends between ticks (restart; dispatch is synchronous): stamp the
	# current f. Emitted during the nodes' tick (the loss): stamp that tick, f + 1.
	# (Engine.is_in_physics_frame() cannot tell them apart: the script resumes inside the physics step.)
	var in_tick := not dispatching_key
	transitions.append({"scen": scen, "f": f + 1 if in_tick else f, "gt": gt, "state": s,
		"key": last_key, "key_age": -1 if in_tick else gt - last_key_gt})


# ---- one frame ----------------------------------------------------------------------------------

func _step() -> void:
	next_active = not paused and game.world.process_mode != Node.PROCESS_MODE_DISABLED
	await physics_frame
	f += 1
	gt += 1
	if next_active:
		act += 1
	var cd := game.archer.fire_cooldown

	if not next_active:
		if not pending.is_empty():
			inv_inactive_shots += pending.size()
			inv_inactive_detail += "[%s f=%d shot] " % [scen, f]
		if cd != prev_cd:
			inv_inactive_cd_changes += 1
			inv_inactive_detail += "[%s f=%d cd %.6f->%.6f] " % [scen, f, prev_cd, cd]
	if arrows_added != pending.size():
		inv_arrow_mismatch += 1
		inv_arrow_detail += "[%s f=%d arrows=%d fired=%d] " % [scen, f, arrows_added, pending.size()]

	var fired_txt := PackedStringArray()
	for e in pending:
		fired_txt.append("%s(nearest %s, pf %d)" % [e["target"], e["nearest"], e["pf"]])
	var sc_txt := PackedStringArray()
	for id in tracked:
		var s := _live(id)
		if s == null:
			wall_prev.erase(id)
			continue
		sc_txt.append("%s y=%.2f wall=%s hp=%.2f burn=%s cone=%s" % [labels[id], s.position.y,
			s.at_wall, s.hp, s.is_burning(), _in_cone(s)])
		if wall_prev.has(id) and bool(wall_prev[id][0]) and not is_equal_approx(float(wall_prev[id][1]), s.position.y):
			inv_wall_moves += 1
			inv_wall_detail += "[%s %s f=%d y %.2f->%.2f] " % [scen, labels[id], f, wall_prev[id][1], s.position.y]
		if s.at_wall and not is_equal_approx(s.position.y, Tuning.SCARECROW_STOP_Y):
			inv_wall_moves += 1
			inv_wall_detail += "[%s %s f=%d at_wall but y=%.2f] " % [scen, labels[id], f, s.position.y]
		wall_prev[id] = [s.at_wall, s.position.y]

	print("%d | %s f=%d | state=%s paused=%s x=%.2f cd=%.6f arrows=%d | fired=[%s] | %s" % [
		Engine.get_process_frames(), scen, f, Game.State.keys()[game.state], paused,
		game.archer.position.x, cd, _live_arrows(), ", ".join(fired_txt), "; ".join(sc_txt)])
	pending.clear()
	arrows_added = 0
	prev_cd = cd


func _begin(name: String) -> void:
	scen = name
	f = 0
	print("---- scenario %s ----" % name)


## Wait until no tracked scarecrow (except keep_ids) is alive, no arrow flies and the cooldown is 0.
func _settle(keep: Array[int] = []) -> void:
	var cap := 900
	while cap > 0:
		var busy := _live_arrows() > 0 or game.archer.fire_cooldown > 0.0
		for id in tracked:
			if not keep.has(id) and _live(id) != null:
				busy = true
		if not busy:
			break
		await _step()
		cap -= 1
	for i in 3:
		await _step()


# ---- scenarios ----------------------------------------------------------------------------------

## (a) One scarecrow in the cone, cooldown 0: the first shots until it dies.
func _scen_a() -> void:
	_begin("a")
	var cd0 := game.archer.fire_cooldown
	var s := _spawn(Vector2(640, 300), "A1")
	var id := s.get_instance_id()
	var in_cone0 := _in_cone(s)
	while _live(id) != null and f < 600:
		await _step()
	var list := _shots_in("a")
	var first := int(list[0]["f"]) if not list.is_empty() else -1
	print("MEASURED a: cooldown at spawn %.6f, in cone at spawn %s, shots at f %s, gaps %s, died at f %s" % [
		cd0, in_cone0, str(list.map(func(e: Dictionary) -> int: return e["f"])), str(_gaps(list)),
		str(deaths.get("A1", {}).get("f", -1))])
	_inv("(a) setup: cooldown 0 and the scarecrow inside the cone at spawn", cd0 == 0.0 and in_cone0)
	_timing("(a) first fired frame after a spawn in the cone (spawn = f 0)", first, A_FIRST_SHOT_F)
	_timing("(a) frames between consecutive shots", _gaps(list), A_SHOT_GAPS)
	_timing("(a) frame the scarecrow dies", int(deaths.get("A1", {}).get("f", -1)), A_DEATH_F)
	await _settle()


## (b) Two scarecrows in the cone: which one is taken, and the cadence.
func _scen_b() -> void:
	_begin("b")
	var near := _spawn(Vector2(600, 350), "B_near")
	var far := _spawn(Vector2(690, 250), "B_far")
	var ids: Array[int] = [near.get_instance_id(), far.get_instance_id()]
	var both_in := _in_cone(near) and _in_cone(far)
	while (_live(ids[0]) != null or _live(ids[1]) != null) and f < 900:
		await _step()
	var list := _shots_in("b")
	var targets := list.map(func(e: Dictionary) -> String: return e["target"])
	print("MEASURED b: shots at f %s, targets %s, gaps %s, B_near died f %s, B_far died f %s" % [
		str(list.map(func(e: Dictionary) -> int: return e["f"])), str(targets), str(_gaps(list)),
		str(deaths.get("B_near", {}).get("f", -1)), str(deaths.get("B_far", {}).get("f", -1))])
	_inv("(b) setup: both scarecrows inside the cone at spawn", both_in)
	var near_first: bool = not list.is_empty() and list[0]["target"] == "B_near"
	_inv("(b) the first shot takes the nearer scarecrow (B_near)", near_first, "targets %s" % str(targets))
	var b_near_death: int = deaths.get("B_near", {}).get("f", 1 << 30)
	var order_ok := true
	for e in list:
		var expect := "B_near" if int(e["f"]) <= b_near_death else "B_far"
		if e["target"] != expect:
			order_ok = false
	_inv("(b) every shot takes B_near while it lives, then B_far", order_ok and list.size() >= 2,
		"targets %s" % str(targets))
	_timing("(b) first fired frame after the spawn", int(list[0]["f"]) if not list.is_empty() else -1,
		B_FIRST_SHOT_F)
	_timing("(b) frames between consecutive shots", _gaps(list), B_SHOT_GAPS)
	await _settle()


## (c) The target leaves the cone because the archer moves away (D held), and comes back (A held).
func _scen_c() -> void:
	_begin("c")
	var s := _spawn(Vector2(640, 450), "C1")
	var id := s.get_instance_id()
	_key(KEY_D, true)
	var exit_f := -1
	var cd_zero_f := -1
	var reentry_f := -1
	var moved_ok := 0
	var moved_bad := 0
	var moved_detail := ""
	while _live(id) != null and f < 400:
		var x0 := game.archer.position.x
		var cd_before := game.archer.fire_cooldown
		var holding := f < C_HOLD_D_TICKS + C_HOLD_A_TICKS   # a move key is held for tick f + 1
		await _step()
		if holding and cd_before > 1.5 * TICK:
			var dx := absf(game.archer.position.x - x0)
			if absf(dx - Tuning.ARCHER_SPEED * TICK) < 1e-6:
				moved_ok += 1
			else:
				moved_bad += 1
				moved_detail += "[f=%d dx=%.4f] " % [f, dx]
		var c := _live(id)
		if c != null:
			var inc := _in_cone(c)
			if exit_f < 0 and not inc:
				exit_f = f
			elif exit_f >= 0 and reentry_f < 0 and inc:
				reentry_f = f
		if exit_f >= 0 and reentry_f < 0 and cd_zero_f < 0 and game.archer.fire_cooldown == 0.0:
			cd_zero_f = f
		if f == C_HOLD_D_TICKS:
			_key(KEY_D, false)
			_key(KEY_A, true)
		elif f == C_HOLD_D_TICKS + C_HOLD_A_TICKS:
			_key(KEY_A, false)
	_key(KEY_D, false)
	_key(KEY_A, false)
	var list := _shots_in("c")
	var fs := list.map(func(e: Dictionary) -> int: return e["f"])
	var out_shots := 0
	var reentry_shot := -1
	for e in list:
		if exit_f >= 0 and int(e["f"]) >= exit_f and (reentry_f < 0 or int(e["f"]) < reentry_f):
			out_shots += 1
		if reentry_f >= 0 and reentry_shot < 0 and int(e["f"]) >= reentry_f:
			reentry_shot = int(e["f"])
	print("MEASURED c: shots at f %s, exit f %d, cooldown 0 at f %d, re-entry f %d, re-entry shot f %d, died f %s" % [
		str(fs), exit_f, cd_zero_f, reentry_f, reentry_shot, str(deaths.get("C1", {}).get("f", -1))])
	_inv("(c) no shot while the target is outside the cone, though the cooldown is 0",
		exit_f > 0 and reentry_f > exit_f and cd_zero_f >= exit_f and out_shots == 0,
		"exit %d cd0 %d reentry %d shots between %d" % [exit_f, cd_zero_f, reentry_f, out_shots])
	_inv("the archer moves %.0f px per tick while the cooldown runs (%d ticks checked)" % [
		Tuning.ARCHER_SPEED * TICK, moved_ok], moved_ok > 0 and moved_bad == 0, moved_detail)
	_timing("(c) first fired frame after the spawn", int(fs[0]) if not fs.is_empty() else -1, C_FIRST_SHOT_F)
	_timing("(c) frame the target leaves the cone", exit_f, C_EXIT_F)
	_timing("(c) frame the cooldown reaches 0 while it is outside", cd_zero_f, C_CD_ZERO_F)
	_timing("(c) frame the target is back in the cone", reentry_f, C_REENTRY_F)
	_timing("(c) fired frame - re-entry frame", reentry_shot - reentry_f, C_REENTRY_SHOT_DELAY)
	await _settle()


## (d) P pressed mid-cooldown, and again D_PAUSE_TICKS frames later.
func _scen_d() -> void:
	_begin("d")
	var s := _spawn(Vector2(640, 250), "D1")
	var id := s.get_instance_id()
	var paused_ok := false
	var resumed_ok := false
	var frozen_y := true
	var y_at_pause := 0.0
	var cd_at_pause := -1.0
	var cd_after_pause := -1.0
	while _live(id) != null and f < 600:
		await _step()
		var c := _live(id)
		if f == D_PAUSE_AT_F:
			cd_at_pause = game.archer.fire_cooldown
			y_at_pause = c.position.y if c else 0.0
			_tap(KEY_P)
			paused_ok = paused
		elif f > D_PAUSE_AT_F and f <= D_PAUSE_AT_F + D_PAUSE_TICKS:
			if c and not is_equal_approx(c.position.y, y_at_pause):
				frozen_y = false
			if f == D_PAUSE_AT_F + D_PAUSE_TICKS:
				cd_after_pause = game.archer.fire_cooldown
				_tap(KEY_P)
				resumed_ok = not paused
	var list := _shots_in("d")
	var fs := list.map(func(e: Dictionary) -> int: return e["f"])
	var s1 := int(fs[0]) if fs.size() > 0 else -1
	var s2 := int(fs[1]) if fs.size() > 1 else -1
	var paused_shots := 0
	for e in list:
		if int(e["f"]) > D_PAUSE_AT_F and int(e["f"]) <= D_PAUSE_AT_F + D_PAUSE_TICKS:
			paused_shots += 1
	var cadence: int = A_SHOT_GAPS[0] if A_SHOT_GAPS.size() > 0 else FIRE_INTERVAL_TICKS
	print("MEASURED d: shots at f %s, gaps %s, cd at pause %.6f, cd after %d paused ticks %.6f, died f %s" % [
		str(fs), str(_gaps(list)), cd_at_pause, D_PAUSE_TICKS, cd_after_pause,
		str(deaths.get("D1", {}).get("f", -1))])
	_inv("(d) P pauses mid-cooldown and P again resumes", paused_ok and resumed_ok and cd_at_pause > 0.0,
		"paused %s resumed %s cd %.4f" % [paused_ok, resumed_ok, cd_at_pause])
	_inv("(d) while paused: no shot, the cooldown and the scarecrow do not change",
		paused_shots == 0 and cd_after_pause == cd_at_pause and frozen_y,
		"shots %d cd %.6f->%.6f frozen_y %s" % [paused_shots, cd_at_pause, cd_after_pause, frozen_y])
	_timing("(d) first fired frame", s1, D_SHOT1_F)
	_timing("(d) second fired frame (after the pause)", s2, D_SHOT2_F)
	_timing("(d) shift of the second shot by the %d-frame pause" % D_PAUSE_TICKS, s2 - s1 - cadence, D_PAUSE_SHIFT)
	var later := _gaps(list).slice(1)
	var later_ok := true
	for g in later:
		later_ok = later_ok and int(g) == cadence
	_inv("(d) shots after the pause keep the unpaused cadence (%d)" % cadence, later_ok, "gaps %s" % str(_gaps(list)))
	await _settle()


## (e) With the archer at the right edge, a scarecrow walks down to the wall outside the cone and stops.
func _scen_e() -> void:
	_begin("e-setup")
	_key(KEY_D, true)
	while game.archer.position.x < Tuning.VIEW.x - Tuning.ARCHER_MARGIN and f < 300:
		await _step()
	_key(KEY_D, false)
	await _step()
	_begin("e")
	var s := _spawn(Vector2(160, 400), "E1")
	var id := s.get_instance_id()
	var ever_in_cone := _in_cone(s)
	var wall_f := -1
	var hold := 0
	var gate_at_wall := 0.0
	while _live(id) != null and f < 600 and hold < E_WALL_HOLD_TICKS:
		await _step()
		var c := _live(id)
		if c == null:
			break
		ever_in_cone = ever_in_cone or _in_cone(c)
		if wall_f < 0 and c.at_wall:
			wall_f = f
			gate_at_wall = game.gate_hp
		elif wall_f >= 0:
			hold += 1
	var c2 := _live(id)
	var still := c2 != null and c2.at_wall and is_equal_approx(c2.position.y, Tuning.SCARECROW_STOP_Y)
	print("MEASURED e: archer x %.2f, at_wall at f %d, y %.2f after %d more frames, gate %.4f -> %.4f" % [
		game.archer.position.x, wall_f, c2.position.y if c2 else -1.0, hold, gate_at_wall, game.gate_hp])
	_inv("(e) setup: the scarecrow never enters the cone, no shot", not ever_in_cone and _shots_in("e").is_empty())
	_inv("(e) the scarecrow at the wall stays at y %.0f for %d frames and hits the gate" % [
		Tuning.SCARECROW_STOP_Y, E_WALL_HOLD_TICKS], still and hold == E_WALL_HOLD_TICKS and game.gate_hp < gate_at_wall)
	_timing("(e) frame the scarecrow reaches the wall (spawn at y 400 = f 0)", wall_f, E_WALL_F)


## (f) A loss with the archer still firing, then R, then Enter, then the first shot of the new run.
func _scen_f() -> void:
	_begin("f")
	var t0 := transitions.size()
	var ax := game.archer.position.x
	var i := 1
	for dx in [-60.0, -48.0, -36.0, -24.0]:
		_spawn(Vector2(ax + dx, Tuning.SCARECROW_STOP_Y), "F%d" % i)
		i += 1
	i = 1
	for x in [300.0, 400.0, 500.0, 600.0, 700.0, 800.0]:
		_spawn(Vector2(x, Tuning.SCARECROW_STOP_Y), "W%d" % i)
		i += 1
	var r_in_play_ok := true
	while game.state == Game.State.PLAYING and f < 900:
		await _step()
		if f == 10:
			var hp := game.gate_hp
			_tap(KEY_R)
			r_in_play_ok = game.state == Game.State.PLAYING and transitions.size() == t0
			print("INFO (f) R during play at f 10: state %s, gate %.4f (was %.4f)" % [
				Game.State.keys()[game.state], game.gate_hp, hp])
	var loss_f := f
	var lost := game.state == Game.State.LOST
	var list := _shots_in("f")
	var last_shot_f := int(list.back()["f"]) if not list.is_empty() else -1
	var firing := not list.is_empty() and loss_f - last_shot_f < FIRE_INTERVAL_TICKS + 1
	var cd_at_loss := game.archer.fire_cooldown
	var x_at_loss := game.archer.position.x
	var arrows_at_loss := _live_arrows()
	_tap(KEY_D)   # a move key while the game is over (pressed and released at once)
	_key(KEY_A, true)
	for k in F_FROZEN_TICKS:
		await _step()
	_key(KEY_A, false)
	var frozen := game.archer.fire_cooldown == cd_at_loss and game.archer.position.x == x_at_loss \
			and _live_arrows() == arrows_at_loss and game.state == Game.State.LOST
	var shots_after_loss := 0
	for e in _shots_in("f"):
		if int(e["f"]) > loss_f:
			shots_after_loss += 1
	print("MEASURED f: shots at f %s, LOST at f %d, last shot f %d, cd at loss %.6f, %d arrows in flight" % [
		str(list.map(func(e: Dictionary) -> int: return e["f"])), loss_f, last_shot_f, cd_at_loss, arrows_at_loss])

	_tap(KEY_R)
	run_id += 1
	act = 0
	var restarted := game.state == Game.State.PLAYING
	print("INFO (f) R after the loss: state %s, gate %.4f, archer x %.2f, cd %.6f" % [
		Game.State.keys()[game.state], game.gate_hp, game.archer.position.x, game.archer.fire_cooldown])
	for k in 5:
		await _step()
	var t_before_enter := transitions.size()
	_tap(KEY_ENTER)
	var enter_noop := game.state == Game.State.PLAYING and transitions.size() == t_before_enter
	for k in 5:
		await _step()
	var spawn_f := f
	_spawn(Vector2(640, 300), "G1")
	var shot_f := -1
	var n0 := shots.size()
	while f < spawn_f + 120 and shot_f < 0:
		await _step()
		if shots.size() > n0:
			shot_f = int(shots[n0]["f"])
	print("MEASURED f: new run: G1 spawned at f %d, first fired at f %d" % [spawn_f, shot_f])

	var states := transitions.slice(t0).map(func(t: Dictionary) -> int: return t["state"])
	var tr_txt := transitions.slice(t0).map(func(t: Dictionary) -> String:
		return "%s@f%d key=%d age=%d" % [Game.State.keys()[t["state"]], t["f"], t["key"], t["key_age"]])
	print("INFO (f) transitions: %s" % str(tr_txt))
	var via_key: bool = states.size() == 2 and int(transitions[t0 + 1]["key"]) == KEY_R \
			and int(transitions[t0 + 1]["key_age"]) == 0 and int(transitions[t0]["key_age"]) == -1 \
			and int(transitions[t0]["f"]) == loss_f
	_inv("(f) setup: the run is lost with the archer still firing (a shot within %d frames before)" % [
		FIRE_INTERVAL_TICKS + 1], lost and firing, "lost %s last shot f %d loss f %d" % [lost, last_shot_f, loss_f])
	_inv("(f) R during play does nothing", r_in_play_ok)
	_inv("(f) after the loss: no shot, cooldown, archer x and arrows frozen, keys ignored, state stays LOST",
		frozen and shots_after_loss == 0, "frozen %s shots after %d" % [frozen, shots_after_loss])
	_inv("(f) run states go PLAYING -> LOST -> PLAYING, the last only on the R press", restarted and via_key
		and states == [Game.State.LOST, Game.State.PLAYING], str(tr_txt))
	_inv("(f) Enter right after the restart (state PLAYING) does nothing", enter_noop)
	_timing("(f) frame the run is LOST", loss_f, F_LOSS_F)
	_timing("(f) new run: fired frame - spawn frame", shot_f - spawn_f, F_RESTART_SHOT_DELAY)


# ---- invariants over every shot of the whole test ------------------------------------------------

func _global_invariants() -> void:
	var no_target := PackedStringArray()
	var not_nearest := PackedStringArray()
	var bad_parent := 0
	var during_pause := 0
	for e in shots:
		if e["target"] == "none" or not e["in_cone"]:
			no_target.append("%s f%d" % [e["scen"], e["f"]])
		if e["target"] != e["nearest"]:
			not_nearest.append("%s f%d %s!=%s" % [e["scen"], e["f"], e["target"], e["nearest"]])
		if not e["parent_ok"]:
			bad_parent += 1
		if e["paused"] or e["state"] != Game.State.PLAYING:
			during_pause += 1
	var close := PackedStringArray()
	var min_gap := 1 << 30
	for k in range(1, shots.size()):
		if shots[k]["run"] != shots[k - 1]["run"]:
			continue
		var g := int(shots[k]["act"]) - int(shots[k - 1]["act"])
		min_gap = mini(min_gap, g)
		if g * TICK < Tuning.FIRE_INTERVAL - 1e-9:
			close.append("%s f%d gap %d" % [shots[k]["scen"], shots[k]["f"], g])
	print("INFO %d shots in total; smallest gap in archer-active frames within a run: %d" % [shots.size(), min_gap])
	_inv("no shot without a target in the cone (%d shots)" % shots.size(), no_target.is_empty(), str(no_target))
	_inv("never two shots closer than FIRE_INTERVAL in archer-active frames (min %d)" % min_gap, close.is_empty(),
		str(close))
	_inv("exactly one arrow under World/Arrows per fired, in the same frame",
		inv_arrow_mismatch == 0 and bad_parent == 0, inv_arrow_detail)
	_inv("no shot and no cooldown change on a frame the archer is paused or the game has ended",
		inv_inactive_shots == 0 and inv_inactive_cd_changes == 0 and during_pause == 0, inv_inactive_detail)
	_inv("every shot takes the nearest scarecrow in the cone", not_nearest.is_empty(), str(not_nearest))
	_inv("a scarecrow at the wall never moves", inv_wall_moves == 0, inv_wall_detail)
