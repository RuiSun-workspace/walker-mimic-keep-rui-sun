extends SceneTree
## Read-back of the archer's cutout rig and its clips (CHANGE-BRIEF.md §1, §4, §6, revision 1.3-1.4):
## reads idle and shoot back out of godot/game/archer.tscn and checks them against the brief.
## Route: 2D cutout rig keyed as resource text (not an imported rig). Reads only; never plays a clip.
##   ./scripts/run-test.sh test_archer_shot_readback.gd 60

const SCENE := "res://game/archer.tscn"

# ---- the brief's numbers (§4) ----
const FPS := 30.0
const FRAME_PERIOD := 1.0 / FPS                     # one frame period, 0.0333 s
const KEY_TOL := 1.0 / 60.0                         # half a frame period, for key times
const EXACT_TOL := 1e-4                             # step / length: float32 storage only
const VALUE_TOL := 1e-5                             # key values: float32 storage only
const SHOOT_FRAMES := 15
const SHOOT_LENGTH := SHOOT_FRAMES / FPS            # 0.5 s
const BOUNDARY_FRAMES := [0, 8, 9, 15]              # startup, active, recovery, end
const RELEASE_FRAMES := [0, 8, 9]
const RELEASE_VALUES := [false, true, false]
const RELEASE_PATH := ".:release_window"

# Rig parts and where each part image's top-left pixel sits at rest, in Archer-local pixels.
# make_sprites.gd places them at archer.png pixels (0,0), (32,3), (35,5); the old Sprite was centred
# on the Archer's origin, so archer.png pixel (x, y) is Archer-local (x - 22, y - 30).
const PARTS := {
	"Rig/Body": {"size": Vector2(44, 60), "top_left": Vector2(-22, -30)},
	"Rig/BowPivot/Bow": {"size": Vector2(5, 46), "top_left": Vector2(10, -27)},
	"Rig/BowPivot/String": {"size": Vector2(3, 42), "top_left": Vector2(13, -25)},
}
const GRIP := Vector2(12.5, -4.0)                   # archer.png (34.5, 26.0), make_sprites.gd:139
const RIG_NODES := ["Rig/Body", "Rig/BowPivot", "Rig/BowPivot/Bow", "Rig/BowPivot/String"]
const TRANSFORM_PROPS := ["position", "rotation", "scale"]

var passes := 0
var failures := 0


func _init() -> void:
	var packed := load(SCENE) as PackedScene
	_check(packed != null, "%s loads" % SCENE)
	if packed == null:
		_finish()
		return
	# Instanced but not added to the tree: no _ready, no _process, nothing advances.
	var root := packed.instantiate()

	# ---- route and rig ----
	_check(_find_class(root, "AnimatedSprite2D") == 0, "no AnimatedSprite2D in the scene")
	_check(_find_class(root, "Skeleton3D") == 0 and _find_class(root, "Skeleton2D") == 0,
		"route is a keyed cutout: no skeleton in the scene")
	_check(root.get_node_or_null("Sprite") == null, "the single Archer/Sprite is gone")
	_check(root.get_node_or_null("Rig") is Node2D, "Archer/Rig is a Node2D")
	var pivot := root.get_node_or_null("Rig/BowPivot") as Node2D
	_check(pivot != null and pivot.get_class() == "Node2D", "Archer/Rig/BowPivot is a Node2D")
	if pivot != null:
		_check(pivot.position.is_equal_approx(GRIP), "BowPivot sits at the grip %s (got %s)" % [GRIP, pivot.position])
	for p in PARTS:
		var s := root.get_node_or_null(p) as Sprite2D
		_check(s != null, "Archer/%s is a Sprite2D" % p)
		if s == null or s.texture == null:
			continue
		var want_size: Vector2 = PARTS[p]["size"]
		_check(Vector2(s.texture.get_size()) == want_size, "%s texture is %s (got %s)" % [p, want_size, s.texture.get_size()])
		# Top-left of the image in Archer-local space, at the scene's rest transforms.
		var local_tl := (-want_size / 2.0 if s.centered else Vector2.ZERO) + s.offset
		var tl := _xform_to_root(s, root) * local_tl
		_check(tl.is_equal_approx(PARTS[p]["top_left"]),
			"%s top-left at rest is %s, where make_sprites.gd places it (got %s)" % [p, PARTS[p]["top_left"], tl])
	var body := root.get_node_or_null("Rig/Body")
	var bow := root.get_node_or_null("Rig/BowPivot/Bow")
	var string := root.get_node_or_null("Rig/BowPivot/String")
	if body and bow and string:
		_check(body.get_index() < pivot.get_index() and bow.get_index() < string.get_index(),
			"draw order is body, bow, string (make_sprites.gd:134)")

	# ---- player ----
	var player := root.get_node_or_null("AnimationPlayer") as AnimationPlayer
	_check(player != null, "Archer/AnimationPlayer is an AnimationPlayer")
	if player == null:
		root.free()
		_finish()
		return
	_check(player.autoplay == "", "autoplay is empty (got \"%s\")" % player.autoplay)
	_check(not player.is_playing() and player.current_animation == "", "nothing is playing after instancing")
	_check(player.get_animation_library_list() == [&""],
		"one AnimationLibrary, the default \"\" (got %s)" % [player.get_animation_library_list()])
	var lib := player.get_animation_library(&"")
	_check(lib != null and lib.resource_path.begins_with(SCENE + "::"),
		"the library is a sub-resource of archer.tscn (path \"%s\")" % (lib.resource_path if lib else "null"))
	var names := player.get_animation_list()
	names.sort()
	_check(names == PackedStringArray(["idle", "shoot"]), "clips are exactly idle, shoot (got %s)" % [names])
	var anchor := player.get_node_or_null(player.root_node)
	_check(anchor == root, "AnimationPlayer root_node resolves to Archer")

	var shoot := player.get_animation(&"shoot")
	var idle := player.get_animation(&"idle")
	_check(shoot != null and idle != null, "idle and shoot exist")
	if shoot == null or idle == null or anchor == null:
		root.free()
		_finish()
		return

	# ---- clip settings ----
	for a in [idle, shoot]:
		print("INFO %s: length %.8f step %.8f loop_mode %d tracks %d"
			% [a.resource_name, a.length, a.step, a.loop_mode, a.get_track_count()])
		_check(absf(a.step - FRAME_PERIOD) < EXACT_TOL, "%s step == 1/30 (got %.8f)" % [a.resource_name, a.step])
		_check(a.loop_mode == Animation.LOOP_NONE, "%s loop_mode == LOOP_NONE (got %d)" % [a.resource_name, a.loop_mode])
	_check(absf(shoot.length - SHOOT_LENGTH) < EXACT_TOL,
		"shoot length == 15 frames == %.4f s (got %.8f)" % [SHOOT_LENGTH, shoot.length])
	_check(absf(shoot.length / FRAME_PERIOD - SHOOT_FRAMES) < 0.01,
		"shoot length is %d frame periods (got %.4f)" % [SHOOT_FRAMES, shoot.length / FRAME_PERIOD])

	# ---- every track resolves; branch on track type ----
	for a in [idle, shoot]:
		for t in a.get_track_count():
			_check_track_resolves(a, t, anchor)

	# ---- same tracks in both clips ----
	var shoot_paths := _paths(shoot)
	var idle_paths := _paths(idle)
	_check(shoot_paths == idle_paths, "idle and shoot key the same properties (%s / %s)" % [idle_paths, shoot_paths])
	_check(shoot_paths.has(RELEASE_PATH), "shoot keys %s" % RELEASE_PATH)
	_check(shoot_paths.size() >= 2, "shoot keys at least one rig transform (got %d tracks)" % shoot_paths.size())

	# ---- shoot: transform tracks keyed at every phase boundary ----
	for t in shoot.get_track_count():
		var path := str(shoot.track_get_path(t))
		if path == RELEASE_PATH:
			continue
		_check(shoot.value_track_get_update_mode(t) == Animation.UPDATE_CONTINUOUS,
			"shoot %s is UPDATE_CONTINUOUS (got %d)" % [path, shoot.value_track_get_update_mode(t)])
		var n := shoot.track_get_key_count(t)
		_check(n == BOUNDARY_FRAMES.size(), "shoot %s has %d keys (got %d)" % [path, BOUNDARY_FRAMES.size(), n])
		for i in mini(n, BOUNDARY_FRAMES.size()):
			var want: float = BOUNDARY_FRAMES[i] / FPS
			var kt := shoot.track_get_key_time(t, i)
			_check(absf(kt - want) < KEY_TOL,
				"shoot %s key %d at frame %d: %.8f within 1/60 of %.8f" % [path, i, BOUNDARY_FRAMES[i], kt, want])
		if n == BOUNDARY_FRAMES.size():
			# Startup accelerates into frame 8 (ease in, transition > 1); recovery settles into 15 (ease out, 0..1).
			_check(shoot.track_get_key_transition(t, 0) > 1.0,
				"shoot %s: frame 0 -> 8 eases in (transition %.3f > 1)" % [path, shoot.track_get_key_transition(t, 0)])
			var rec := shoot.track_get_key_transition(t, 2)
			_check(rec > 0.0 and rec < 1.0, "shoot %s: frame 9 -> 15 eases out (transition %.3f in 0..1)" % [path, rec])
			_check(not _approx(shoot.track_get_key_value(t, 1), shoot.track_get_key_value(t, 0)),
				"shoot %s: frame 8 differs from rest" % path)

	# ---- shoot: release_window ----
	var rt := shoot.find_track(NodePath(RELEASE_PATH), Animation.TYPE_VALUE)
	_check(rt >= 0, "shoot has a value track on %s" % RELEASE_PATH)
	if rt >= 0:
		_check(shoot.value_track_get_update_mode(rt) == Animation.UPDATE_DISCRETE,
			"release_window track is UPDATE_DISCRETE (got %d)" % shoot.value_track_get_update_mode(rt))
		var n := shoot.track_get_key_count(rt)
		_check(n == RELEASE_FRAMES.size(), "release_window has %d keys (got %d)" % [RELEASE_FRAMES.size(), n])
		for i in mini(n, RELEASE_FRAMES.size()):
			var want: float = RELEASE_FRAMES[i] / FPS
			var kt := shoot.track_get_key_time(rt, i)
			var kv: Variant = shoot.track_get_key_value(rt, i)
			_check(absf(kt - want) < KEY_TOL,
				"release_window key %d at frame %d: %.8f within 1/60 of %.8f" % [i, RELEASE_FRAMES[i], kt, want])
			_check(typeof(kv) == TYPE_BOOL and kv == RELEASE_VALUES[i],
				"release_window key %d == %s (got %s)" % [i, RELEASE_VALUES[i], kv])

	# ---- idle: one key at 0 per property, equal to shoot's frame 0 and frame 15 ----
	for t in idle.get_track_count():
		var path := idle.track_get_path(t)
		_check(idle.track_get_key_count(t) == 1 and absf(idle.track_get_key_time(t, 0)) < KEY_TOL,
			"idle %s has one key at 0 s" % path)
		var iv: Variant = idle.track_get_key_value(t, 0)
		var st := shoot.find_track(path, Animation.TYPE_VALUE)
		if st < 0 or shoot.track_get_key_count(st) == 0:
			continue
		_check(_approx(iv, shoot.track_get_key_value(st, 0)),
			"idle %s == shoot frame 0 (%s / %s)" % [path, iv, shoot.track_get_key_value(st, 0)])
		if str(path) == RELEASE_PATH:
			_check(idle.value_track_get_update_mode(t) == Animation.UPDATE_DISCRETE, "idle release_window is UPDATE_DISCRETE")
			_check(typeof(iv) == TYPE_BOOL and iv == false, "idle keys release_window false (got %s)" % iv)
			continue
		var last := shoot.track_get_key_count(st) - 1
		_check(absf(shoot.track_get_key_time(st, last) - shoot.length) < KEY_TOL,
			"shoot %s last key is at the clip end" % path)
		_check(_approx(iv, shoot.track_get_key_value(st, last)),
			"idle %s == shoot frame 15 (%s / %s)" % [path, iv, shoot.track_get_key_value(st, last)])
		# The scene's own rest values are the idle pose, so the rig sits at rest before anything plays.
		var node := anchor.get_node_or_null(NodePath(path.get_concatenated_names()))
		if node:
			var scene_v: Variant = node.get(path.get_concatenated_subnames())
			_check(_approx(iv, scene_v), "scene rest %s == idle (%s / %s)" % [path, scene_v, iv])

	_print_pose_table(shoot)
	root.free()
	_finish()


func _check_track_resolves(a: Animation, t: int, anchor: Node) -> void:
	var clip := a.resource_name
	var type := a.track_get_type(t)
	var path := a.track_get_path(t)
	var node := anchor.get_node_or_null(NodePath(path.get_concatenated_names()))
	var sub := path.get_concatenated_subnames()
	match type:
		Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D, Animation.TYPE_SCALE_3D:
			# A 3D transform track names a bone of a Skeleton3D.
			var skel := node as Skeleton3D
			_check(skel != null and skel.find_bone(sub) >= 0, "%s track %d %s names a real bone" % [clip, t, path])
			_check(false, "%s track %d is a 3D transform track (type %d): this rig is 2D" % [clip, t, type])
		Animation.TYPE_BLEND_SHAPE:
			var mesh := node as MeshInstance3D
			_check(mesh != null and mesh.find_blend_shape_by_name(StringName(sub)) >= 0,
				"%s track %d %s names a real blend shape" % [clip, t, path])
			_check(false, "%s track %d is a blend-shape track: this rig has none" % [clip, t])
		Animation.TYPE_VALUE:
			_check(node != null, "%s track %d node \"%s\" resolves (%s)"
				% [clip, t, path.get_concatenated_names(), node.get_class() if node else "null"])
			if node == null:
				return
			var prop: Dictionary = {}
			for p in node.get_property_list():
				if p.name == sub:
					prop = p
					break
			_check(not prop.is_empty(), "%s track %d property \"%s\" exists on %s" % [clip, t, sub, node.get_class()])
			if prop.is_empty():
				return
			for i in a.track_get_key_count(t):
				var kv: Variant = a.track_get_key_value(t, i)
				_check(typeof(kv) == int(prop.type), "%s %s key %d value type %d matches the property's %d"
					% [clip, path, i, typeof(kv), prop.type])
			var is_root := node == anchor
			if str(path) == RELEASE_PATH:
				_check(is_root, "%s release_window track keys the Archer itself" % clip)
			else:
				_check(not is_root, "%s track %s does not key the Archer root (archer.gd owns its position)" % [clip, path])
				_check(RIG_NODES.has(str(path.get_concatenated_names())) and TRANSFORM_PROPS.has(sub),
					"%s track %s keys rotation/position/scale of a rig part" % [clip, path])
		_:
			_check(false, "%s track %d %s has unexpected type %d (only value tracks here)" % [clip, t, path, type])


func _print_pose_table(a: Animation) -> void:
	print("INFO shoot pose table (keys as stored; rotation also in degrees)")
	var header := "INFO | frame | time (s)    "
	for t in a.get_track_count():
		header += " | %s" % a.track_get_path(t)
	print(header)
	for i in BOUNDARY_FRAMES.size():
		var row := "INFO | %5d | %.8f" % [BOUNDARY_FRAMES[i], BOUNDARY_FRAMES[i] / FPS]
		for t in a.get_track_count():
			var k := -1
			for j in a.track_get_key_count(t):
				if absf(a.track_get_key_time(t, j) - BOUNDARY_FRAMES[i] / FPS) < KEY_TOL:
					k = j
			if k < 0:
				row += " | (held)"
				continue
			var v: Variant = a.track_get_key_value(t, k)
			if str(a.track_get_path(t)).ends_with(":rotation"):
				row += " | %.6f rad (%.1f deg), trans %.2f" % [v, rad_to_deg(v), a.track_get_key_transition(t, k)]
			elif typeof(v) == TYPE_BOOL:
				row += " | %s" % v
			else:
				row += " | %s, trans %.2f" % [v, a.track_get_key_transition(t, k)]
		print(row)


func _paths(a: Animation) -> Array:
	var out := []
	for t in a.get_track_count():
		out.append(str(a.track_get_path(t)))
	out.sort()
	return out


func _xform_to_root(n: Node, root: Node) -> Transform2D:
	var x := Transform2D.IDENTITY
	var cur := n
	while cur != null and cur != root:
		if cur is Node2D:
			x = (cur as Node2D).transform * x
		cur = cur.get_parent()
	return x


func _approx(a: Variant, b: Variant) -> bool:
	if typeof(a) != typeof(b):
		return false
	match typeof(a):
		TYPE_FLOAT:
			return absf(a - b) < VALUE_TOL
		TYPE_VECTOR2:
			return (a - b).length() < VALUE_TOL
		_:
			return a == b


func _find_class(n: Node, cls: String) -> int:
	var count := 1 if n.is_class(cls) else 0
	for c in n.get_children():
		count += _find_class(c, cls)
	return count


func _check(ok: bool, what: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", what])
	if ok:
		passes += 1
	else:
		failures += 1


func _finish() -> void:
	print("RESULT %s: %d passed, %d failed" % ["PASS" if failures == 0 else "FAIL", passes, failures])
	quit(1 if failures > 0 else 0)
