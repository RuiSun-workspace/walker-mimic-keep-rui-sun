extends SceneTree
# Probes for the four A7 "Headless facts" lines, Godot 4.7.2.

class Holder extends Node2D:
	var value := 0.0

var holder: Holder
var player: AnimationPlayer
var ticks := 0

func _initialize() -> void:
	print("display driver: ", DisplayServer.get_name())
	print("rendering method: ", RenderingServer.get_current_rendering_method(), " / adapter: '", RenderingServer.get_video_adapter_name(), "'")

	# Fact 2: key times after a save/load round trip.
	var a := Animation.new()
	var t := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(t, NodePath(".:value"))
	var want := [1.0 / 30.0, 0.1, 8.0 / 30.0, 0.375]
	for k in want:
		a.track_insert_key(t, k, k)
	a.length = 0.5
	print("in memory  key times: ", _times(a, t), " == exact? ", _exact(a, t, want))
	ResourceSaver.save(a, "user://probe_anim.tres")
	var b: Animation = ResourceLoader.load("user://probe_anim.tres", "", ResourceLoader.CACHE_MODE_IGNORE)
	print("after .tres key times: ", _times(b, 0), " == exact? ", _exact(b, 0, want))
	for i in want.size():
		print("  key " + str(i) + ": stored " + String.num(b.track_get_key_time(0, i), 17) + "  want " + String.num(want[i], 17) + "  is_equal_approx " + str(is_equal_approx(b.track_get_key_time(0, i), want[i])))
	var f := FileAccess.open("user://probe_anim.tres", FileAccess.READ)
	for line in f.get_as_text().split("\n"):
		if "times" in line:
			print("  .tres line: ", line.strip_edges())

	# Fact 3: value_track_get_update_mode on non-value tracks.
	var c := Animation.new()
	var vt := c.add_track(Animation.TYPE_VALUE)
	var mt := c.add_track(Animation.TYPE_METHOD)
	var pt := c.add_track(Animation.TYPE_POSITION_3D)
	print("update mode value track: ", c.value_track_get_update_mode(vt))
	print("update mode method track (expect error above/below): ", c.value_track_get_update_mode(mt))
	print("update mode position_3d track: ", c.value_track_get_update_mode(pt))

	# Fact 1: a headless run advances a clip.
	holder = Holder.new()
	player = AnimationPlayer.new()
	holder.add_child(player)
	var lib := AnimationLibrary.new()
	lib.add_animation("probe", a)
	player.add_animation_library("", lib)
	root.add_child(holder)
	player.play("probe")

func _times(an: Animation, tr: int) -> Array:
	var out := []
	for i in an.track_get_key_count(tr):
		out.append(an.track_get_key_time(tr, i))
	return out

func _exact(an: Animation, tr: int, want: Array) -> bool:
	for i in want.size():
		if an.track_get_key_time(tr, i) != want[i]:
			return false
	return true

func _process(_d: float) -> bool:
	ticks += 1
	if ticks == 20:
		print("after 20 frames: position %.4f, holder.value %.4f" % [player.current_animation_position, holder.value])
		var img := root.get_texture().get_image()
		print("viewport image: ", img)
		return true
	return false
