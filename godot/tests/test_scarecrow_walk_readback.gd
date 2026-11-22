extends SceneTree
## Read-back of the scarecrow walk (CHANGE-BRIEF.md §1-3, revision 1.4): reads the clips and the
## sprite slicing back out of godot/game/scarecrow.tscn and checks them against the brief.
## Route: Sprite2D + AnimationPlayer frame track (not SpriteFrames). Reads only; never plays a clip.
##   bash scripts/run-test.sh test_scarecrow_walk_readback.gd 60

const SCENE := "res://game/scarecrow.tscn"
const SHEET := "res://assets/sprites/scarecrow_walk.png"

# ---- the brief's numbers (§2, §3) ----
const HFRAMES := 4
const VFRAMES := 1
const SHEET_W := 256
const SHEET_H := 80
const FPS := 8.0
const FRAME_PERIOD := 1.0 / FPS                     # 0.125 s
const KEY_TOL := FRAME_PERIOD / 2.0                 # half a frame period, for key times
const EXACT_TOL := 1e-4                             # step / length: float32 storage only
const WALK_TIMES := [0.0, 0.125, 0.25, 0.375]
const WALK_FRAMES := [0, 1, 2, 3]
const WALK_LENGTH := 0.5
const HOLD_TIMES := [0.0]
const HOLD_FRAMES := [0]
const TRACK_PATH := "Sprite:frame"

var failures := 0


func _init() -> void:
	var packed := load(SCENE) as PackedScene
	_check(packed != null, "%s loads" % SCENE)
	if packed == null:
		_finish()
		return
	# Instanced but not added to the tree: no _ready, no _process, nothing advances.
	var root := packed.instantiate()

	# ---- route: frame track, no AnimatedSprite2D / SpriteFrames ----
	_check(_find_class(root, "AnimatedSprite2D") == 0,
		"route is Sprite2D + AnimationPlayer: no AnimatedSprite2D in the scene")

	# ---- sprite slicing ----
	var sprite := root.get_node_or_null("Sprite") as Sprite2D
	_check(sprite != null, "Scarecrow/Sprite is a Sprite2D")
	var player := root.get_node_or_null("AnimationPlayer") as AnimationPlayer
	_check(player != null, "Scarecrow/AnimationPlayer is an AnimationPlayer")
	if sprite == null or player == null:
		root.free()
		_finish()
		return

	var tex := sprite.texture
	_check(tex != null and tex.resource_path == SHEET,
		"Sprite texture is %s (got %s)" % [SHEET, tex.resource_path if tex else "null"])
	if tex != null:
		_check(tex.get_width() == SHEET_W and tex.get_height() == SHEET_H,
			"texture is %dx%d (got %dx%d)" % [SHEET_W, SHEET_H, tex.get_width(), tex.get_height()])
	_check(sprite.hframes == HFRAMES, "hframes == %d (got %d)" % [HFRAMES, sprite.hframes])
	_check(sprite.vframes == VFRAMES, "vframes == %d (got %d)" % [VFRAMES, sprite.vframes])
	_check(sprite.frame == 0, "Sprite.frame starts at 0 (got %d)" % sprite.frame)
	_check(sprite.material is ShaderMaterial and sprite.material.resource_local_to_scene,
		"Sprite keeps its local-to-scene ShaderMaterial")
	_check(sprite.get_script() != null and sprite.get_script().resource_path == "res://game/burning_tint.gd",
		"Sprite keeps burning_tint.gd")
	var cells := sprite.hframes * sprite.vframes

	# ---- player ----
	_check(player.autoplay == "", "autoplay is empty (got \"%s\")" % player.autoplay)
	_check(not player.is_playing() and player.current_animation == "",
		"nothing is playing after instancing")
	_check(player.callback_mode_process == AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE,
		"callback_mode_process is IDLE (brief §7; got %d)" % player.callback_mode_process)
	_check(player.get_animation_library_list() == [&""],
		"one AnimationLibrary, the default \"\" (got %s)" % [player.get_animation_library_list()])
	var lib := player.get_animation_library(&"")
	_check(lib != null and lib.resource_path.begins_with(SCENE + "::"),
		"the library is a sub-resource of scarecrow.tscn (path \"%s\")" % (lib.resource_path if lib else "null"))
	var names := player.get_animation_list()
	names.sort()
	_check(names == PackedStringArray(["hold", "walk"]), "clips are exactly hold, walk (got %s)" % [names])

	var anchor := player.get_node_or_null(player.root_node)
	_check(anchor == root, "AnimationPlayer root_node resolves to Scarecrow")

	_check_clip(player, anchor, cells, "walk", WALK_TIMES, WALK_FRAMES, WALK_LENGTH, Animation.LOOP_LINEAR)
	_check_clip(player, anchor, cells, "hold", HOLD_TIMES, HOLD_FRAMES, -1.0, Animation.LOOP_NONE)

	# ---- seam rule (§3): frame 0 not re-keyed at the end; last key -> length == key interval ----
	var walk := player.get_animation(&"walk")
	if walk != null and walk.get_track_count() == 1 and walk.track_get_key_count(0) == WALK_TIMES.size():
		var n := walk.track_get_key_count(0)
		var last_t := walk.track_get_key_time(0, n - 1)
		var gap := walk.length - last_t
		var interval := walk.track_get_key_time(0, 1) - walk.track_get_key_time(0, 0)
		_check(absf(gap - interval) < KEY_TOL and absf(gap - FRAME_PERIOD) < KEY_TOL,
			"seam: last key %.6f -> length %.6f gap %.6f equals key interval %.6f" % [last_t, walk.length, gap, interval])
		for i in range(1, n):
			var d := walk.track_get_key_time(0, i) - walk.track_get_key_time(0, i - 1)
			_check(absf(d - FRAME_PERIOD) < KEY_TOL, "walk key interval %d->%d is %.6f" % [i - 1, i, d])
		_check(int(walk.track_get_key_value(0, n - 1)) != int(walk.track_get_key_value(0, 0)),
			"seam: the last key is not frame 0 again")

	root.free()
	_finish()


func _check_clip(player: AnimationPlayer, anchor: Node, cells: int, clip: String,
		times: Array, frames: Array, length: float, loop: int) -> void:
	var a := player.get_animation(StringName(clip))
	_check(a != null, "%s exists" % clip)
	if a == null:
		return
	print("%s: length %.6f step %.6f loop_mode %d tracks %d" % [clip, a.length, a.step, a.loop_mode, a.get_track_count()])
	_check(absf(a.step - FRAME_PERIOD) < EXACT_TOL, "%s step == 1/%d = %.6f (got %.6f)" % [clip, int(FPS), FRAME_PERIOD, a.step])
	if length >= 0.0:
		_check(absf(a.length - length) < EXACT_TOL, "%s length == %.3f (got %.6f)" % [clip, length, a.length])
	_check(a.loop_mode == loop, "%s loop_mode == %d (got %d)" % [clip, loop, a.loop_mode])
	_check(a.get_track_count() == 1, "%s has exactly one track (got %d)" % [clip, a.get_track_count()])
	if a.get_track_count() < 1:
		return

	var t := 0
	_check(a.track_get_type(t) == Animation.TYPE_VALUE, "%s track 0 is a value track" % clip)
	var path := a.track_get_path(t)
	_check(str(path) == TRACK_PATH, "%s track 0 path is %s (got %s)" % [clip, TRACK_PATH, path])

	# The path resolves against the player's root_node, in the instanced scene.
	var node := anchor.get_node_or_null(NodePath(path.get_concatenated_names())) if anchor else null
	_check(node != null, "%s track node \"%s\" resolves (%s)" % [clip, path.get_concatenated_names(), node])
	var prop := path.get_concatenated_subnames()
	if node != null:
		var found := false
		for p in node.get_property_list():
			if p.name == prop:
				found = true
				break
		_check(found, "%s track property \"%s\" exists on %s" % [clip, prop, node.get_class()])

	if a.track_get_type(t) == Animation.TYPE_VALUE:
		_check(a.value_track_get_update_mode(t) == Animation.UPDATE_DISCRETE,
			"%s track 0 update mode is UPDATE_DISCRETE (got %d)" % [clip, a.value_track_get_update_mode(t)])

	var n := a.track_get_key_count(t)
	_check(n == times.size(), "%s has %d keys (got %d)" % [clip, times.size(), n])
	for i in mini(n, times.size()):
		var kt := a.track_get_key_time(t, i)
		var kv: Variant = a.track_get_key_value(t, i)
		print("%s key %d: t=%.8f frame=%s" % [clip, i, kt, kv])
		_check(absf(kt - float(times[i])) < KEY_TOL,
			"%s key %d time %.6f within %.4f of %.3f" % [clip, i, kt, KEY_TOL, times[i]])
		_check(typeof(kv) == TYPE_INT, "%s key %d value is an int (type %d)" % [clip, i, typeof(kv)])
		_check(int(kv) == int(frames[i]), "%s key %d frame == %d (got %s)" % [clip, i, frames[i], kv])
		_check(int(kv) >= 0 and int(kv) < cells,
			"%s key %d frame %s inside the sheet (0..%d)" % [clip, i, kv, cells - 1])
		if length >= 0.0:
			_check(kt < a.length, "%s key %d time %.6f is before the clip end" % [clip, i, kt])


func _find_class(n: Node, cls: String) -> int:
	var count := 1 if n.is_class(cls) else 0
	for c in n.get_children():
		count += _find_class(c, cls)
	return count


func _check(ok: bool, what: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", what])
	if not ok:
		failures += 1


func _finish() -> void:
	print("RESULT %s (%d failure%s)" % ["PASS" if failures == 0 else "FAIL", failures, "" if failures == 1 else "s"])
	quit(1 if failures > 0 else 0)
