extends SceneTree
## Step 5 structure test (CHANGE-BRIEF §5, §6, §7, §8, revision 1): the archer's state machine as a
## resource, and the archer's and scarecrow's clips as played through the real game loop.
##   ./scripts/run-test.sh test_archer_state_machine.gd 60
##
## Reads the resources back, then drives the real main scene only with Game.spawn_scarecrow() and
## keyboard events (Input.parse_input_event). Never calls travel(), start(), cancel_shot() or play(),
## never assigns to an archer, scarecrow or tree variable.
##
## Frame model (same as test_pins_a7.gd). --fixed-fps 60, 60 ticks/s: one loop iteration = one physics
## tick. The script resumes on SceneTree.physics_frame, before the nodes' physics step. rec[f] is the
## state left by tick f of the scenario (f = 0 is the setup); an event emitted during tick f (fired)
## is stamped f. Keys and spawns made at a resume take effect in the next tick.

const MAIN := preload("res://game/main.tscn")
const SCARECROW := preload("res://game/scarecrow.tscn")
const ARCHER_SRC := "res://game/archer.gd"
const PRESENTER_SRC := "res://game/scarecrow_walk_presenter.gd"
const TICK := 1.0 / 60.0

# ---- the brief's numbers ----
const TRAVEL_TO_ARROW_TICKS := 18      # §5.2, §6 "Known before prompt-1": travel("shoot") -> first true read
const CADENCE_TICKS := 36              # §5.2: FIRE_INTERVAL 0.6 s at 60 ticks/s
const DRAW_LEAD := 0.3                 # §5.2: draw starts at fire_cooldown <= 0.3 s
const ACTIVE_TIME := 8.0 / 30.0        # §4: active frame 8
const SM_STATES := ["idle", "shoot"]   # §6 state table
const TRANSITIONS := [                 # §6 transition table
	{"from": "Start", "to": "idle",
		"advance": AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO,
		"switch": AnimationNodeStateMachineTransition.SWITCH_MODE_IMMEDIATE},
	{"from": "idle", "to": "shoot",
		"advance": AnimationNodeStateMachineTransition.ADVANCE_MODE_ENABLED,
		"switch": AnimationNodeStateMachineTransition.SWITCH_MODE_IMMEDIATE},
	{"from": "shoot", "to": "idle",
		"advance": AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO,
		"switch": AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END},
]

var game: Game
var archer: Archer
var tree: AnimationTree
var pb: AnimationNodeStateMachinePlayback
var player: AnimationPlayer

var passed := 0
var failed := 0
var scen := ""
var f := 0
var rec: Array[Dictionary] = []
var pending := 0
var shots: Array[Dictionary] = []
var tracked: Array[Scarecrow] = []
var fired_outside_shoot := 0
var fired_outside_detail := ""
var player_plays := 0
var player_detail := ""


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	game = MAIN.instantiate() as Game
	game.spawning_enabled = false
	root.add_child(game)
	archer = game.archer
	tree = archer.get_node("AnimationTree") as AnimationTree
	pb = tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
	player = archer.get_node("AnimationPlayer") as AnimationPlayer
	archer.fired.connect(_on_fired)
	await process_frame

	_structure()
	_scarecrow_structure()

	_begin("boot")
	await _step()
	_check("§6 Start -> idle: the tree is in idle after the first tick (got %s)" % rec[1]["node"],
		rec[1]["node"] == "idle")
	for i in 3:
		await _step()

	await _scen_cadence()
	await _scen_cancel()
	await _scen_walk()
	await _scen_restart()

	_check("§6/§7 fired is never emitted while the tree is not in shoot (%d shots)" % shots.size(),
		fired_outside_shoot == 0 and shots.size() > 0, fired_outside_detail)
	_check("§8 Archer/AnimationPlayer never plays on its own: current_animation \"\" and not playing on every tick",
		player_plays == 0, player_detail)
	print("RESULT test_archer_state_machine: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _check(name: String, ok: bool, detail: String = "") -> void:
	if ok:
		passed += 1
		print("PASS %s" % name)
	else:
		failed += 1
		print("FAIL %s  %s" % [name, detail])


# ---- resource read-back ---------------------------------------------------------------------------

func _structure() -> void:
	var sm := tree.tree_root as AnimationNodeStateMachine
	_check("§6 Archer/AnimationTree tree_root is an AnimationNodeStateMachine", sm != null)
	if sm == null:
		return
	var states: Array[String] = []
	for p in sm.get_property_list():
		var n: String = p["name"]
		if n.begins_with("states/") and n.ends_with("/node"):
			var st := n.trim_prefix("states/").trim_suffix("/node")
			if st != "Start" and st != "End":
				states.append(st)
	states.sort()
	_check("§6 states are exactly %s (got %s)" % [str(SM_STATES), str(states)], states == SM_STATES)
	for st in SM_STATES:
		var node := sm.get_node(st) as AnimationNodeAnimation if sm.has_node(st) else null
		_check("§6 state %s plays clip %s, which the tree's library holds" % [st, st],
			node != null and String(node.animation) == st and tree.has_animation(st),
			"node %s animation %s" % [node, node.animation if node else &""])

	# every state the code requests exists (read from archer.gd's source text)
	var src := FileAccess.get_file_as_string(ARCHER_SRC)
	var re := RegEx.create_from_string("\\.(travel|start)\\(&?\"([A-Za-z_]+)\"\\)")
	var requested := {}
	for m in re.search_all(src):
		requested["%s(%s)" % [m.get_string(1), m.get_string(2)]] = m.get_string(2)
	_check("archer.gd requests travel(shoot) and start(idle) (found %s)" % str(requested.keys()),
		requested.has("travel(shoot)") and requested.has("start(idle)"))
	for k in requested:
		_check("state requested by archer.gd %s exists in the state machine" % k, sm.has_node(requested[k]))

	# transitions: exactly the table, one per pair
	var n_tr := sm.get_transition_count()
	_check("§6 exactly %d transitions (got %d)" % [TRANSITIONS.size(), n_tr], n_tr == TRANSITIONS.size())
	var pairs := {}
	for i in n_tr:
		var key := "%s->%s" % [sm.get_transition_from(i), sm.get_transition_to(i)]
		pairs[key] = int(pairs.get(key, 0)) + 1
	for want in TRANSITIONS:
		var key := "%s->%s" % [want["from"], want["to"]]
		_check("§6 exactly one transition %s (got %d)" % [key, int(pairs.get(key, 0))], int(pairs.get(key, 0)) == 1)
		for i in n_tr:
			if "%s->%s" % [sm.get_transition_from(i), sm.get_transition_to(i)] != key:
				continue
			var t := sm.get_transition(i)
			_check("§6 %s advance_mode %d (got %d)" % [key, want["advance"], t.advance_mode],
				t.advance_mode == want["advance"])
			_check("§6 %s switch_mode %d (got %d)" % [key, want["switch"], t.switch_mode],
				t.switch_mode == want["switch"])
			_check("§6 %s xfade_time 0 (got %s)" % [key, t.xfade_time], t.xfade_time == 0.0)
	var extra := pairs.keys().filter(func(k: String) -> bool:
		return not TRANSITIONS.any(func(w: Dictionary) -> bool: return "%s->%s" % [w["from"], w["to"]] == k))
	_check("§6 no transition outside the table (extra %s)" % str(extra), extra.is_empty())

	# the tree node
	_check("§6 advance_expression_base_node is \"..\" (got \"%s\")" % tree.advance_expression_base_node,
		tree.advance_expression_base_node == NodePath(".."))
	_check("§6 advance_expression_base_node resolves to Archer",
		tree.get_node_or_null(tree.advance_expression_base_node) == archer)
	_check("§6 anim_player resolves to Archer/AnimationPlayer (got \"%s\")" % tree.anim_player,
		tree.get_node_or_null(tree.anim_player) == player)
	_check("§7 tree callback_mode_process is PHYSICS (got %d)" % tree.callback_mode_process,
		tree.callback_mode_process == AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS)
	_check("§6 the tree is active", tree.active)
	_check("§8 Archer/AnimationPlayer autoplay is empty (got \"%s\")" % player.autoplay, player.autoplay == "")


func _scarecrow_structure() -> void:
	var s := SCARECROW.instantiate()   # not added to the tree: nothing runs
	var pres := s.get_node_or_null("WalkPresenter")
	var sp := s.get_node_or_null("AnimationPlayer") as AnimationPlayer
	_check("rev. 1.4 Scarecrow/WalkPresenter exists with %s" % PRESENTER_SRC,
		pres != null and pres.get_script() != null and pres.get_script().resource_path == PRESENTER_SRC)
	var src := FileAccess.get_file_as_string(PRESENTER_SRC)
	var names: Array[String] = []
	for m in RegEx.create_from_string("&\"([A-Za-z_]+)\"").search_all(src):
		names.append(m.get_string(1))
	names.sort()
	_check("the presenter requests exactly hold and walk (found %s)" % str(names), names == ["hold", "walk"])
	for n in names:
		_check("clip requested by the presenter %s exists on Scarecrow/AnimationPlayer" % n,
			sp != null and sp.has_animation(n))
	s.free()


# ---- the loop -------------------------------------------------------------------------------------

func _key(code: Key, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.physical_keycode = code
	ev.pressed = pressed
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


func _sample() -> Dictionary:
	return {"f": f, "armed": archer.shot_armed, "node": String(pb.get_current_node()),
		"pos": pb.get_current_play_position(), "rw": archer.release_window, "cd": archer.fire_cooldown,
		"x": archer.position.x, "has_target": is_instance_valid(archer.locked_target), "fired": 0,
		"state": game.state, "cone": _any_in_cone()}


func _any_in_cone() -> bool:   # the test's own cone check, not archer.nearest_target()
	for n in get_nodes_in_group("enemies"):
		var s := n as Scarecrow
		if s and not s.is_dead() and _in_cone(s):
			return true
	return false


func _begin(name: String) -> void:
	scen = name
	f = 0
	rec = [_sample()]
	print("---- scenario %s ----" % name)


func _step() -> void:
	await physics_frame
	f += 1
	var s := _sample()
	s["fired"] = pending
	pending = 0
	rec.append(s)
	if player.is_playing() or player.current_animation != "":
		player_plays += 1
		player_detail += "[%s f=%d \"%s\"] " % [scen, f, player.current_animation]
	print("%s f=%d | node=%s pos=%.4f armed=%s rw=%s cd=%.6f x=%.1f state=%s | fired=%d" % [
		scen, f, s["node"], s["pos"], s["armed"], s["rw"], s["cd"], s["x"],
		Game.State.keys()[game.state], s["fired"]])


func _on_fired(_arrow: Arrow) -> void:
	pending += 1
	var node := String(pb.get_current_node())
	shots.append({"scen": scen, "f": f + 1, "node": node, "pos": pb.get_current_play_position()})
	if node != "shoot":
		fired_outside_shoot += 1
		fired_outside_detail += "[%s f=%d node=%s] " % [scen, f + 1, node]


func _spawn(at: Vector2) -> Scarecrow:
	var s := game.spawn_scarecrow(at)
	tracked.append(s)
	return s


func _live(s) -> bool:   # untyped (Variant): a freed scarecrow fails even an Object type check
	return is_instance_valid(s) and (s as Scarecrow).is_inside_tree() \
			and not (s as Scarecrow).is_queued_for_deletion() and not (s as Scarecrow).is_dead()


func _in_cone(s: Scarecrow) -> bool:
	var to := s.global_position - archer.global_position
	return absf(Vector2.UP.angle_to(to)) <= deg_to_rad(Tuning.FIRE_CONE_DEG / 2.0)


func _live_arrows() -> int:
	return game.arrows.get_children().filter(func(c: Node) -> bool: return not c.is_queued_for_deletion()).size()


func _fired_ticks() -> Array[int]:
	var out: Array[int] = []
	for r in rec:
		for k in int(r["fired"]):
			out.append(int(r["f"]))
	return out


func _settle() -> void:
	var cap := 900
	while cap > 0:
		var busy := _live_arrows() > 0 or archer.fire_cooldown > 0.0 or archer.shot_armed \
				or String(pb.get_current_node()) != "idle"
		for s in tracked:
			busy = busy or _live(s)
		if not busy:
			break
		await _step()
		cap -= 1
	for i in 3:
		await _step()


## Per shot in rec: the draw tick D (shot_armed first true), the fired tick F, and the edges around them.
func _shot_checks(label: String) -> Array[int]:
	var fs := _fired_ticks()
	for F in fs:
		var D := F - 1
		while D - 1 >= 0 and bool(rec[D - 1]["armed"]):
			D -= 1
		var tag := "(%s) shot fired at f %d, draw at f %d" % [label, F, D]
		_check("%s: travel(\"shoot\") -> arrow is %d ticks (got %d)" % [tag, TRAVEL_TO_ARROW_TICKS, F - D],
			F - D == TRAVEL_TO_ARROW_TICKS and bool(rec[D]["armed"]) and not bool(rec[D - 1]["armed"]))
		_check("%s: idle on the tick before the draw, shoot on the draw tick" % tag,
			rec[D - 1]["node"] == "idle" and rec[D]["node"] == "shoot",
			"%s / %s" % [rec[D - 1]["node"], rec[D]["node"]])
		_check("%s: release_window false 2 ticks before, true 1 tick before (the tree keyed it; archer reads it on f %d)" % [tag, F],
			not bool(rec[F - 2]["rw"]) and bool(rec[F - 1]["rw"]) and bool(rec[F - 1]["armed"]),
			"rw %s/%s armed %s" % [rec[F - 2]["rw"], rec[F - 1]["rw"], rec[F - 1]["armed"]])
		_check("%s: the tree was at the active key (pos >= 8/30 s) when fired" % tag,
			float(rec[F - 1]["pos"]) >= ACTIVE_TIME - 1e-4, "pos %.4f" % float(rec[F - 1]["pos"]))
		var after_ok := not bool(rec[F]["armed"]) and int(rec[F]["fired"]) == 1
		var detail := "armed %s fired %d" % [rec[F]["armed"], rec[F]["fired"]]
		if F + 1 < rec.size():
			after_ok = after_ok and int(rec[F + 1]["fired"]) == 0
			detail += " rw at f+1 %s fired at f+1 %d" % [rec[F + 1]["rw"], rec[F + 1]["fired"]]
		_check("%s: one arrow, shot_armed cleared, no second arrow on the next tick (stale release_window ignored)" % tag,
			after_ok, detail)
		if float(rec[D - 1]["cd"]) > 0.0:
			_check("%s: threshold: cooldown > %.1f on the tick before (%.17f), <= %.1f on the draw tick (%.17f)" % [
				tag, DRAW_LEAD, rec[D - 1]["cd"], DRAW_LEAD, rec[D]["cd"]],
				float(rec[D - 1]["cd"]) > DRAW_LEAD and float(rec[D]["cd"]) <= DRAW_LEAD)
			_check("%s: threshold: still one draw on the tick after (armed, shoot)" % tag,
				bool(rec[D + 1]["armed"]) and rec[D + 1]["node"] == "shoot")
		else:
			_check("%s: cooldown already 0: the draw starts on the first tick a target is in the cone (none after f %d)" % [
				tag, D - 1], not bool(rec[D - 1]["cone"]) and bool(rec[D]["cone"]))
	return fs


# ---- scenarios ------------------------------------------------------------------------------------

## One scarecrow in the cone, cooldown 0: every shot until it dies.
func _scen_cadence() -> void:
	_begin("cadence")
	var s := _spawn(Vector2(640, 300))
	while _live(s) and f < 600:
		await _step()
	var fs := _shot_checks("cadence")
	var gaps := []
	for i in range(1, fs.size()):
		gaps.append(fs[i] - fs[i - 1])
	print("MEASURED cadence: fired at f %s, gaps %s" % [str(fs), str(gaps)])
	_check("§5.2 back-to-back releases are exactly %d ticks apart (gaps %s)" % [CADENCE_TICKS, str(gaps)],
		gaps.size() >= 2 and gaps.all(func(g: int) -> bool: return g == CADENCE_TICKS))
	await _settle()


## A scarecrow at the wall right above the archer; D held during startup moves it out of the cone.
func _scen_cancel() -> void:
	_begin("cancel")
	var x0 := archer.position.x
	var s := _spawn(Vector2(x0, Tuning.SCARECROW_STOP_Y))
	await _step()
	_check("(cancel) setup: the draw starts on tick 1 (armed, shoot)", bool(rec[1]["armed"]) and rec[1]["node"] == "shoot")
	_key(KEY_D, true)
	var cancel_f := -1
	var cone_before := true
	var cone_at := true
	while f < 60:
		var c_prev := _in_cone(s)
		await _step()
		if cancel_f < 0 and not bool(rec[f]["armed"]):
			cancel_f = f
			cone_before = c_prev
			cone_at = _in_cone(s)
		if cancel_f >= 0 and f >= cancel_f + 10:
			break
	_key(KEY_D, false)
	var last_held := f
	print("MEASURED cancel: draw f 1, cancelled at f %d, held D for ticks 2..%d" % [cancel_f, last_held])
	_check("(cancel) §5.5 the shot is cancelled during startup (f %d, before the release at f %d)" % [
		cancel_f, 1 + TRAVEL_TO_ARROW_TICKS], cancel_f > 1 and cancel_f < 1 + TRAVEL_TO_ARROW_TICKS)
	_check("(cancel) it is cancelled on the tick the target leaves the cone", cone_before and not cone_at,
		"in cone before %s at %s" % [cone_before, cone_at])
	if cancel_f > 0:
		var r: Dictionary = rec[cancel_f]
		_check("(cancel) §6 back in idle on the cancel tick, target cleared (node %s, target %s)" % [r["node"], r["has_target"]],
			r["node"] == "idle" and not bool(r["has_target"]))
		_check("(cancel) §5.5 the cooldown continues as normal across the cancel",
			is_equal_approx(float(r["cd"]), maxf(float(rec[cancel_f - 1]["cd"]) - TICK, 0.0)))
		var redraw := false
		for t in range(cancel_f, last_held + 1):
			redraw = redraw or bool(rec[t]["armed"])
		_check("(cancel) no new draw while the target is outside the cone", not redraw)
	_check("(cancel) no arrow from the cancelled shot", _fired_ticks().is_empty(), str(_fired_ticks()))
	var moved_bad := ""
	for t in range(2, last_held + 1):
		var dx := float(rec[t]["x"]) - float(rec[t - 1]["x"])
		if absf(dx - Tuning.ARCHER_SPEED * TICK) > 1e-6:
			moved_bad += "[f=%d dx=%.4f] " % [t, dx]
	_check("(cancel) §5.5 movement: the archer moves %.0f px every tick D is held, through startup and the cancel" % [
		Tuning.ARCHER_SPEED * TICK], moved_bad == "", moved_bad)
	# come back with A for as many ticks; the archer shoots it from the normal rule
	_key(KEY_A, true)
	for i in last_held - 1:
		await _step()
	_key(KEY_A, false)
	while _live(s) and f < 900:
		await _step()
	var fs := _shot_checks("cancel")
	_check("(cancel) after it comes back into the cone the archer draws again and fires", not fs.is_empty(), str(fs))
	await _settle()


## With the archer at the right edge, a scarecrow walks down outside the cone: walk, then hold.
func _scen_walk() -> void:
	_begin("walk-setup")
	_key(KEY_D, true)
	while archer.position.x < Tuning.VIEW.x - Tuning.ARCHER_MARGIN and f < 300:
		await _step()
	_key(KEY_D, false)
	await _step()
	_begin("walk")
	var s := _spawn(Vector2(160, 400))
	var sp := s.get_node("AnimationPlayer") as AnimationPlayer
	var sprite := s.get_node("Sprite") as Sprite2D
	var walk_n := 0
	var walk_bad := ""
	var frames := {}
	var wall_f := -1
	var hold_f := -1
	var ever_cone := false
	while _live(s) and f < 400:
		await _step()
		ever_cone = ever_cone or _in_cone(s)
		if not s.at_wall:
			walk_n += 1
			frames[sprite.frame] = true
			if sp.current_animation != "walk":
				walk_bad += "[f=%d \"%s\"] " % [f, sp.current_animation]
		else:
			if wall_f < 0:
				wall_f = f
			if hold_f < 0 and sp.current_animation == "hold":
				hold_f = f
			if f >= wall_f + 20:
				break
	var fk := frames.keys()
	fk.sort()
	print("MEASURED walk: at_wall at f %d, current_animation hold first at f %d, frames seen while walking %s, after 20 ticks: current \"%s\" assigned \"%s\" frame %d" % [
		wall_f, hold_f, str(fk), sp.current_animation, sp.assigned_animation, sprite.frame])
	_check("(walk) setup: the scarecrow stays outside the cone and no arrow is fired", not ever_cone and _fired_ticks().is_empty())
	_check("§1 current_animation is walk on every tick before the wall (%d ticks)" % walk_n, walk_n > 0 and walk_bad == "", walk_bad)
	_check("§1 the walk shows all four cells 0..3 (got %s)" % str(fk), fk == [0, 1, 2, 3])
	_check("§1 current_animation becomes hold on the tick at_wall turns true (wall f %d, hold f %d)" % [wall_f, hold_f],
		wall_f > 0 and hold_f == wall_f)
	_check("§1 20 ticks later hold is still the assigned clip and the sprite shows frame 0",
		sp.assigned_animation == "hold" and sprite.frame == 0)


## Lose the run while the archer is in startup, then R: no late arrow, back in idle.
func _scen_restart() -> void:
	_begin("restart")
	for x in [100.0, 200.0, 300.0, 400.0, 500.0, 600.0, 700.0, 800.0, 900.0, 1000.0]:
		_spawn(Vector2(x, Tuning.SCARECROW_STOP_Y))
	var target: Scarecrow = null
	var spawn_f := -1
	while game.state == Game.State.PLAYING and f < 900:
		await _step()
		if target == null:
			var at_wall := 0
			for n in get_nodes_in_group("enemies"):
				var e := n as Scarecrow
				if e and e.at_wall and not e.is_dead():
					at_wall += 1
			var rem := ceili(game.gate_hp / (at_wall * Tuning.SCARECROW_GATE_DPS * TICK))
			if rem <= 10:
				target = _spawn(Vector2(archer.position.x, 400))
				spawn_f = f
	var loss_f := f
	var r: Dictionary = rec[loss_f]
	print("MEASURED restart: target spawned at f %d, LOST at f %d, node %s pos %.4f armed %s" % [
		spawn_f, loss_f, r["node"], r["pos"], r["armed"]])
	_check("(restart) setup: the run is lost mid-startup (armed, shoot, pos < 8/30 s, no arrow yet)",
		game.state == Game.State.LOST and bool(r["armed"]) and r["node"] == "shoot"
		and float(r["pos"]) < ACTIVE_TIME - 1e-4 and _fired_ticks().is_empty())
	for i in 5:
		await _step()
	_key(KEY_R, true)
	_key(KEY_R, false)
	_check("(restart) rev. 1.1 R restarts and cancel_shot() cleared shot_armed and the target at once",
		game.state == Game.State.PLAYING and not archer.shot_armed and not is_instance_valid(archer.locked_target))
	var r_f := f
	await _step()
	_check("(restart) §5.5 the tree is back in idle on the first tick of the new run (got %s)" % rec[r_f + 1]["node"],
		rec[r_f + 1]["node"] == "idle")
	for i in 40:
		await _step()
	var armed_any := false
	for t in range(r_f + 1, f + 1):
		armed_any = armed_any or bool(rec[t]["armed"])
	_check("(restart) §5.5 no late arrow and no draw in the 41 ticks after R",
		_fired_ticks().is_empty() and not armed_any, str(_fired_ticks()))
