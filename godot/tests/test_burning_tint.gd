extends SceneTree
## Burning-tint checks (CHANGE-BRIEF Rules 1-6), run through the real main scene and game loop.
##   godot --headless --path godot --script res://tests/test_burning_tint.gd --fixed-fps <30|60|144>
## Every ignition is an arrow from the archer's own auto-fire, steered into and out of the cone
## with real A/D key events; pause is a real P key. burn_mix is read from each scarecrow's own
## ShaderMaterial by a Sampler that runs last in every frame. Headless draws nothing: this proves
## the uniform values the renderer is given, not the pixels.
## Prints one PASS/FAIL line per check and exits 1 on any failure.

const MAIN := preload("res://game/main.tscn")
const SHADER_PATH := "res://shaders/burning_tint.gdshader"
const PEAK := 0.65                # Rule 1
const DURATION := 4.0             # Rule 2: burn_mix = 0.65 * clamp(burn_time_left / 4, 0, 1)
const EPS := 1e-6                 # revision A: every frame matches that formula to 1e-6
const GONE := -1.0                # sample of a scarecrow that no longer exists
const UNSET := -2.0               # burn_mix never set on the material (reads back null)
const MAX_FRAMES := 5000
## Just outside the cone of an archer at ARCHER_START: about 60 px of D brings it in, close
## enough that the arrow (aimed at where the scarecrow was) still lands as it walks down.
const TARGET := Vector2(958, 423)
## Higher up, so it is still well above the wall walk when the second arrow is steered in.
const RETRIGGER_TARGET := Vector2(1067, 360)
const STEER_BACK := 40.0          # px of A after the shot; out of the cone long before the cooldown

var passed := 0
var failed := 0
var game: Game
var sampler: Sampler
var rec := {"fired": 0}


## Runs last in every frame (process_priority 1000), also while paused. Holds instance ids and
## numbers only: no reference to a scarecrow, Sprite or material survives between frames.
class Sampler extends Node:
	var ids: Array[int] = []
	var clock := 0.0                         # game time: physics deltas summed while not paused
	var ticks := 0
	var t := PackedFloat64Array()            # clock at each sample
	var dt := PackedFloat64Array()           # game time the physics ticks of this frame advanced
	var frame_dt := PackedFloat64Array()     # _process delta: one frame period, time_scale / fps
	var nticks := PackedInt32Array()
	var paused := PackedByteArray()
	var mix: Array[PackedFloat64Array] = []
	var btl: Array[PackedFloat64Array] = []
	var checked := 0                         # samples of a live scarecrow, over the whole run
	var bad := 0                             # of those: outside [0, 0.65] or off the formula
	var first_bad := PackedFloat64Array()    # [burn_mix, burn_time_left] of the first bad one
	var _clock_last := 0.0
	var _ticks_last := 0

	func _init() -> void:
		process_priority = 1000
		process_mode = Node.PROCESS_MODE_ALWAYS

	func watch(new_ids: Array[int]) -> void:
		ids = new_ids
		t.clear()
		dt.clear()
		frame_dt.clear()
		nticks.clear()
		paused.clear()
		mix = []
		btl = []
		for i in ids.size():
			mix.append(PackedFloat64Array())
			btl.append(PackedFloat64Array())

	func size() -> int:
		return t.size()

	func _physics_process(delta: float) -> void:
		if not get_tree().paused:
			clock += delta
			ticks += 1

	func _process(delta: float) -> void:
		t.append(clock)
		dt.append(clock - _clock_last)
		nticks.append(ticks - _ticks_last)
		frame_dt.append(delta)
		paused.append(1 if get_tree().paused else 0)
		_clock_last = clock
		_ticks_last = ticks
		for i in ids.size():
			var s := instance_from_id(ids[i]) as Scarecrow
			if s == null:
				mix[i].append(GONE)
				btl[i].append(GONE)
				continue
			var mat := (s.get_node("Sprite") as Sprite2D).material as ShaderMaterial
			var v: Variant = mat.get_shader_parameter("burn_mix")
			var m: float = UNSET if v == null else float(v)
			var left := s.burn_time_left
			mix[i].append(m)
			btl[i].append(left)
			checked += 1
			var expect := PEAK * clampf(left / DURATION, 0.0, 1.0)
			if m < 0.0 or m > PEAK or absf(m - expect) > EPS:
				bad += 1
				if first_bad.is_empty():
					first_bad = PackedFloat64Array([m, left])


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	game = MAIN.instantiate() as Game
	game.spawning_enabled = false
	root.add_child(game)
	sampler = Sampler.new()
	root.add_child(sampler)
	game.archer.fired.connect(func(_a: Arrow) -> void: rec.fired += 1)
	await process_frame

	_test_shader_uniforms()
	_test_shader_source()
	await _test_instances_independent()
	await _test_single_burn(1.0)
	await _test_single_burn(0.5)
	await _test_single_burn(2.0)
	await _test_pause_freezes()
	await _test_retrigger_then_death()
	_check("every sample of a live scarecrow: 0 <= burn_mix <= 0.65 and == 0.65*clamp(left/4,0,1) (1e-6)",
			sampler.bad == 0 and sampler.checked > 0,
			"%d of %d bad, first [burn_mix, left] = %s" % [sampler.bad, sampler.checked, sampler.first_bad])

	Engine.time_scale = 1.0
	print("test_burning_tint: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


# --- helpers ---------------------------------------------------------------

func _check(name: String, ok: bool, detail: String = "") -> void:
	if ok:
		passed += 1
		print("PASS %s" % name)
	else:
		failed += 1
		print("FAIL %s  %s" % [name, detail])


func _key(code: Key, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.physical_keycode = code
	ev.pressed = pressed
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


## Clean field at the given time scale: keys up, spawning off, nothing watched.
func _fresh(scale: float) -> void:
	_key(KEY_A, false)
	_key(KEY_D, false)
	Engine.time_scale = scale
	game.spawning_enabled = false
	game.reset()
	sampler.watch([])
	await process_frame
	await process_frame          # a time_scale change applies from the next tick


## Spawns scarecrows the way the game does, lets each driver run once, then samples them.
func _spawn_watched(points: Array[Vector2]) -> Array[int]:
	var ids: Array[int] = []
	for p in points:
		ids.append(game.spawn_scarecrow(p).get_instance_id())
	await process_frame
	sampler.watch(ids)
	await process_frame
	return ids


## One real arrow: hold D until the archer's own auto-fire looses one, then hold A until the
## archer is STEER_BACK px back. Keys go in at the start of a physics tick. Returns false if
## no arrow was fired.
func _steer_one_arrow() -> bool:
	var start: int = rec.fired
	_key(KEY_D, true)
	var n := 0
	while rec.fired == start and n < MAX_FRAMES:
		await physics_frame
		n += 1
	_key(KEY_D, false)
	if rec.fired == start:
		return false
	var x_fire := game.archer.position.x
	_key(KEY_A, true)
	while game.archer.position.x > x_fire - STEER_BACK and n < MAX_FRAMES:
		await physics_frame
		n += 1
	_key(KEY_A, false)
	return true


## Steers one arrow in and returns the sample index of its hit on scarecrow i, or -1.
func _arrow_hit(i: int) -> int:
	var k0 := sampler.size()
	if not await _steer_one_arrow():
		return -1
	return await _await_rise(i, k0)


## First sample index >= from_k at which scarecrow i's burn_mix rose (an arrow hit), or -1.
func _await_rise(i: int, from_k: int) -> int:
	var k := maxi(from_k, 1)
	for n in MAX_FRAMES:
		while k < sampler.size():
			if sampler.mix[i][k] > sampler.mix[i][k - 1]:
				return k
			k += 1
		await process_frame
	return -1


## First sample index >= from_k at which scarecrow i's burn_mix is exactly 0.0, or -1.
func _await_zero(i: int, from_k: int) -> int:
	var k := from_k
	for n in MAX_FRAMES:
		while k < sampler.size():
			if sampler.mix[i][k] == 0.0:
				return k
			k += 1
		await process_frame
	return -1


## Revision A: the first frame after a hit shows >= 0.65*(1 - g/4), g = game time that frame
## advanced; a frame with at most one physics tick shows exactly 0.65.
func _peak_ok(i: int, k: int) -> bool:
	var m := sampler.mix[i][k]
	if sampler.nticks[k] <= 1:
		return absf(m - PEAK) <= EPS
	return m >= PEAK * (1.0 - sampler.dt[k] / DURATION) - EPS and m <= PEAK


func _all_equal(i: int, from_k: int, to_k: int, value: float) -> bool:
	for k in range(from_k, to_k):
		if sampler.mix[i][k] != value:
			return false
	return true


func _fps(k: int) -> int:
	return roundi(Engine.time_scale / sampler.frame_dt[k])


## Material facts as numbers. Not a coroutine, so no reference to a material outlives the call.
## Returns [material id or 0, shader id or 0, shader path ok, burn_color unset].
func _material_info(id: int) -> Array:
	var mat := (instance_from_id(id).get_node("Sprite") as Sprite2D).material as ShaderMaterial
	if mat == null or mat.shader == null:
		return [0, 0, false, false]
	return [mat.get_instance_id(), mat.shader.get_instance_id(), mat.shader.resource_path == SHADER_PATH,
			mat.get_shader_parameter("burn_color") == null]


func _material_ref(id: int) -> WeakRef:
	return weakref((instance_from_id(id).get_node("Sprite") as Sprite2D).material)


# --- checks ----------------------------------------------------------------

func _test_shader_uniforms() -> void:
	var list := (load(SHADER_PATH) as Shader).get_shader_uniform_list()
	var by_name := {}
	for u: Dictionary in list:
		by_name[u.name] = u
	_check("shader reports exactly two uniforms, no sampler", list.size() == 2, str(list))
	var m: Dictionary = by_name.get("burn_mix", {})
	var range_ok := false
	if m.get("hint") == PROPERTY_HINT_RANGE:
		var r := String(m.get("hint_string", "")).split(",")
		range_ok = r.size() >= 2 and float(r[0]) == 0.0 and float(r[1]) == 1.0
	_check("burn_mix is a float with hint_range(0, 1)", m.get("type") == TYPE_FLOAT and range_ok, str(m))
	var c: Dictionary = by_name.get("burn_color", {})
	_check("burn_color is a Color", c.get("type") == TYPE_COLOR, str(c))


## Defaults are not reported headlessly, so they are read from the source text (whitespace collapsed).
func _test_shader_source() -> void:
	var src := RegEx.create_from_string("\\s+").sub(FileAccess.get_file_as_string(SHADER_PATH), " ", true)
	_check("source: burn_mix defaults to 0.0",
			src.contains("uniform float burn_mix : hint_range(0.0, 1.0) = 0.0;"))
	_check("source: burn_color is source_color, default (1.0, 0.752941, 0.125490, 1.0)",
			src.contains("uniform vec4 burn_color : source_color = vec4(1.0, 0.752941, 0.125490, 1.0);"))
	_check("source: the colour line is COLOR.rgb = mix(COLOR.rgb, burn_color.rgb, burn_mix);",
			src.contains("COLOR.rgb = mix(COLOR.rgb, burn_color.rgb, burn_mix);"))
	_check("source: no render_mode, no sampler, no TIME",
			not src.contains("render_mode") and not src.contains("sampler2D") and not src.contains("TIME"))


## Rule 6: three scarecrows, an arrow for the middle one only.
func _test_instances_independent() -> void:
	await _fresh(1.0)
	var ids := await _spawn_watched([Vector2(300, 423), TARGET, Vector2(1240, 423)])
	var mats: Array[int] = []
	var shaders: Array[int] = []
	var setup_ok := true
	var color_unset := true
	for id in ids:
		var info := _material_info(id)
		setup_ok = setup_ok and info[2]
		color_unset = color_unset and info[3]
		mats.append(info[0])
		shaders.append(info[1])
	_check("each Sprite has a ShaderMaterial using %s" % SHADER_PATH, setup_ok)
	if not setup_ok:
		return
	_check("the three scarecrows have three distinct ShaderMaterials",
			mats[0] != mats[1] and mats[1] != mats[2] and mats[0] != mats[2], str(mats))
	_check("all three share the one Shader; burn_color is unset (shader default) on each",
			shaders[0] == shaders[1] and shaders[1] == shaders[2] and color_unset)

	var fired0: int = rec.fired
	var k0 := sampler.size()
	var k_hit := await _arrow_hit(1)
	var k_end := await _await_zero(1, k_hit + 1) if k_hit > 0 else -1
	_check("[3 scarecrows] exactly one auto-fired arrow ignites the middle one",
			k_hit > 0 and k_end > 0 and rec.fired - fired0 == 1,
			"hit at %d, end at %d, arrows %d" % [k_hit, k_end, rec.fired - fired0])
	if k_hit < 0 or k_end < 0:
		return
	_check("[3 scarecrows] at the hit: (%.4f, %.4f, %.4f), expected (0, 0.65, 0)" % [
			sampler.mix[0][k_hit], sampler.mix[1][k_hit], sampler.mix[2][k_hit]],
			sampler.mix[0][k_hit] == 0.0 and _peak_ok(1, k_hit) and sampler.mix[2][k_hit] == 0.0)
	var k2 := k_hit
	while k2 < k_end and sampler.btl[1][k2] > 2.0:
		k2 += 1
	_check("[3 scarecrows] with %.4f s left: (%.4f, %.4f, %.4f), expected (0, ~0.325, 0)" % [
			sampler.btl[1][k2], sampler.mix[0][k2], sampler.mix[1][k2], sampler.mix[2][k2]],
			sampler.mix[0][k2] == 0.0 and absf(sampler.mix[1][k2] - 0.325) <= PEAK * sampler.dt[k2] / DURATION + EPS
			and sampler.mix[2][k2] == 0.0)
	_check("[3 scarecrows] the outer two read 0.0 in all %d frames of the middle one's burn" % (k_end - k0),
			_all_equal(0, 0, k_end + 1, 0.0) and _all_equal(2, 0, k_end + 1, 0.0))


## Rules 1, 2 and 4: one arrow, at the given Engine.time_scale.
func _test_single_burn(scale: float) -> void:
	await _fresh(scale)
	var ids := await _spawn_watched([TARGET])
	var s := instance_from_id(ids[0]) as Scarecrow
	var r := {"ended_k": -1, "started": 0}
	s.burning_ended.connect(func() -> void: r.ended_k = sampler.size())
	s.burning_started.connect(func() -> void: r.started += 1)
	s = null
	var label := "time_scale %.1f" % scale
	var fired0: int = rec.fired
	var k_hit := await _arrow_hit(0)
	var k_end := await _await_zero(0, k_hit + 1) if k_hit > 0 else -1
	_check("[%s] one auto-fired arrow ignites it" % label,
			k_hit > 0 and k_end > 0 and r.started == 1 and rec.fired - fired0 == 1,
			"hit at %d, end at %d, started %d, arrows %d" % [k_hit, k_end, r.started, rec.fired - fired0])
	if k_hit < 0 or k_end < 0:
		return
	var fps := _fps(k_hit)
	var period := sampler.frame_dt[k_hit]
	_check("[%s] burn_mix is 0.0 in every frame before the hit" % label, _all_equal(0, 0, k_hit, 0.0))
	_check("[%s] first frame after the hit: %.6f (%d ticks in it), Rule 1 / revision A" % [
			label, sampler.mix[0][k_hit], sampler.nticks[k_hit]], _peak_ok(0, k_hit))
	_check("[%s] burn_mix is 0.0 in the frame burning_ended is emitted, > 0 the frame before" % label,
			r.ended_k == k_end and sampler.mix[0][k_end] == 0.0 and sampler.mix[0][k_end - 1] > 0.0,
			"ended at %d, zero at %d" % [r.ended_k, k_end])
	var ticks := 0
	for k in range(k_hit + 1, k_end + 1):
		ticks += sampler.nticks[k]
	print("INFO [%s @ %d fps] %d physics ticks from hit to 0.0 (%d = 4 s); burn_time_left the frame before: %s" % [
			label, fps, ticks, roundi(DURATION * 60.0 / scale), String.num_scientific(sampler.btl[0][k_end - 1])])
	var game_time := sampler.t[k_end] - sampler.t[k_hit]
	_check("[%s @ %d fps] 0.65 -> 0.0 takes %.6f s of game time, 4.0 +- one frame (%.6f)" % [
			label, fps, game_time, period], absf(game_time - DURATION) <= period + EPS)
	var real_time := float(k_end - k_hit) / fps
	_check("[%s @ %d fps] that is %d frames = %.4f s real time, 4.0/%.1f = %.4f +- one frame" % [
			label, fps, k_end - k_hit, real_time, scale, DURATION / scale],
			absf(real_time - DURATION / scale) <= 1.0 / fps + EPS)
	await process_frame
	_check("[%s] no further arrow after the burn" % label, rec.fired - fired0 == 1, "arrows %d" % (rec.fired - fired0))


## Rule 4: a real P mid-burn freezes burn_time_left and burn_mix; P again continues from there.
func _test_pause_freezes() -> void:
	await _fresh(1.0)
	var ids := await _spawn_watched([TARGET])
	var s := instance_from_id(ids[0]) as Scarecrow
	var r := {"ended_k": -1}
	s.burning_ended.connect(func() -> void: r.ended_k = sampler.size())
	s = null
	var fired0: int = rec.fired
	var k_hit := await _arrow_hit(0)
	_check("[pause] one auto-fired arrow ignites it", k_hit > 0 and rec.fired - fired0 == 1,
			"arrows %d" % (rec.fired - fired0))
	if k_hit < 0:
		return
	while sampler.t[sampler.size() - 1] - sampler.t[k_hit] < 1.5:
		await process_frame
	await physics_frame            # the game flushes input before the frame's physics
	_key(KEY_P, true)
	_key(KEY_P, false)
	var k_p := sampler.size()
	var was_paused := paused
	for n in 30:
		await process_frame
	await physics_frame
	_key(KEY_P, true)
	_key(KEY_P, false)
	var k_r := sampler.size()
	var resumed := not paused
	for n in 12:                   # samples land at the end of a frame: k_r + 9 exists after 11
		await process_frame
	var frozen_mix := sampler.mix[0][k_p - 1]
	var frozen_left := sampler.btl[0][k_p - 1]
	var frozen := frozen_mix > 0.0
	for k in range(k_p, k_r):
		frozen = frozen and sampler.paused[k] == 1 and sampler.mix[0][k] == frozen_mix \
				and sampler.btl[0][k] == frozen_left
	_check("[pause] P pauses and P resumes", was_paused and resumed)
	_check("[pause] burn_mix %.6f and burn_time_left %.6f identical over %d paused frames" % [
			frozen_mix, frozen_left, k_r - k_p], frozen and k_r - k_p >= 30)
	var first := sampler.btl[0][k_r]
	_check("[pause] after resume it continues from the frozen value (%.6f -> %.6f -> %.6f)" % [
			frozen_left, first, sampler.btl[0][k_r + 9]],
			first <= frozen_left and first >= frozen_left - sampler.dt[k_r] - EPS
			and sampler.btl[0][k_r + 9] < frozen_left)
	var k_end := await _await_zero(0, k_r)
	var game_time := sampler.t[k_end] - sampler.t[k_hit] if k_end > 0 else -1.0
	_check("[pause] the paused burn still takes %.6f s of game time, 4.0 +- one frame" % game_time,
			k_end > 0 and r.ended_k == k_end and absf(game_time - DURATION) <= sampler.frame_dt[k_hit] + EPS)


## Rules 3 and 5: a second real arrow once burn_mix < 0.3, then the scarecrow burns to death.
func _test_retrigger_then_death() -> void:
	await _fresh(1.0)
	var ids := await _spawn_watched([RETRIGGER_TARGET])
	var id := ids[0]
	var s := instance_from_id(id) as Scarecrow
	var sprite_id := s.get_node("Sprite").get_instance_id()
	var mat_ref := _material_ref(id)
	var r := {"died_k": -1, "died_left": -1.0}
	s.died.connect(func() -> void:
		r.died_k = sampler.size()
		r.died_left = (instance_from_id(id) as Scarecrow).burn_time_left)
	s = null
	var fired0: int = rec.fired
	var k1 := await _arrow_hit(0)
	_check("[retrigger] first auto-fired arrow ignites it", k1 > 0 and rec.fired - fired0 == 1,
			"arrows %d" % (rec.fired - fired0))
	if k1 < 0:
		return
	while sampler.mix[0][sampler.size() - 1] >= 0.3:
		await process_frame
	var k2 := await _arrow_hit(0)
	_check("[retrigger] a second auto-fired arrow hits it", k2 > 0 and rec.fired - fired0 == 2,
			"arrows %d" % (rec.fired - fired0))
	if k2 < 0:
		return
	_check("[retrigger] burn_mix %.6f (< 0.3) returns to %.6f in the hit frame (%d ticks), Rule 3" % [
			sampler.mix[0][k2 - 1], sampler.mix[0][k2], sampler.nticks[k2]],
			sampler.mix[0][k2 - 1] < 0.3 and _peak_ok(0, k2))
	var n := 0
	while r.died_k < 0 and n < MAX_FRAMES:
		await process_frame
		n += 1
	_check("[death] it burns to death while still burning (%.4f s left)" % r.died_left,
			r.died_k > 0 and r.died_left > 0.0)
	if r.died_k < 0:
		return
	await process_frame
	_check("[death] the next frame the scarecrow and its Sprite are freed",
			not is_instance_id_valid(id) and not is_instance_id_valid(sprite_id))
	_check("[death] its ShaderMaterial is freed too (weakref is null): nothing keeps the tint",
			mat_ref.get_ref() == null)
	await process_frame
	_check("[death] the sampler finds nothing to read after the death frame",
			sampler.mix[0][r.died_k + 1] == GONE)
	_check("[retrigger] exactly two arrows in this case", rec.fired - fired0 == 2,
			"arrows %d" % (rec.fired - fired0))
