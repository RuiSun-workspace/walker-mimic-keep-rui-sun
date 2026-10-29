extends SceneTree
## Scripted in-play captures for the Burning tint (CHANGE-BRIEF.md §5 "Independent instances" and
## "Early ending"). Must run WITHOUT --headless (a headless run draws nothing):
##   godot --path godot --script res://tools/capture_in_play.gd
## The real game runs with its driver; only spawning and the archer are switched off so the script
## decides who burns and when. Three scarecrows walk in; the middle one is set burning through
## Scarecrow.hit() (the call an arrow makes), then killed while burning. One frame is saved before,
## while burning and after the death. These are scripted captures, not normal play.
## Writes evidence/in_play/scripted_{1_before,2_middle_burning,3_after_death}.png and scripted_capture.txt.

const OUT := "res://../evidence/in_play/"
const ROW_Y := 250.0
const XS := [480.0, 640.0, 800.0]

var lines := PackedStringArray()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := (load("res://game/main.tscn") as PackedScene).instantiate() as Game
	game.spawning_enabled = false
	root.add_child(game)
	await process_frame
	game.archer.process_mode = Node.PROCESS_MODE_DISABLED   # no arrows: the script picks the target

	var crows: Array[Scarecrow] = []
	for x in XS:
		crows.append(game.spawn_scarecrow(Vector2(x, ROW_Y)))
	_log("Scripted in-play capture, %s, Godot %s, renderer=%s" % [Time.get_date_string_from_system(),
		Engine.get_version_info().string, RenderingServer.get_current_rendering_method()])
	_log("Archer and spawning off; scarecrows, the Burning timer and the tint driver run as in play.")
	_log("")

	await _frames(10)
	await _save(game, "scripted_1_before.png", crows)

	var middle := crows[1]
	middle.hit(Tuning.ARROW_DAMAGE, &"fire")                 # what a fire arrow does on contact
	await _frames(30)                                         # half a second of burning
	await _save(game, "scripted_2_middle_burning.png", crows)

	var last_pos := middle.global_position
	_log("Middle scarecrow killed at %s with burn_time_left=%.3f." % [str(last_pos), middle.burn_time_left])
	middle.hit(middle.hp + 1.0, &"none")                      # killed while still burning
	await _frames(3)
	var img := await _save(game, "scripted_3_after_death.png", crows)

	# Anything left of the sprite or its tint would have red above green; meadow and tufts do not.
	var half := Vector2i(28, 36)
	var box := Rect2i(Vector2i(last_pos) - half, half * 2)
	var warm := 0
	for y in range(box.position.y, box.end.y):
		for x in range(box.position.x, box.end.x):
			var c := img.get_pixel(x, y)
			if c.r > c.g:
				warm += 1
	_log("Pixels with red > green inside the dead scarecrow's last sprite box %s: %d (0 = nothing left)." % [str(box), warm])
	_log("Middle scarecrow node still valid: %s." % str(is_instance_valid(middle)))

	var f := FileAccess.open(ProjectSettings.globalize_path(OUT + "scripted_capture.txt"), FileAccess.WRITE)
	f.store_string("\n".join(lines) + "\n")
	f.close()
	quit(0)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _save(game: Game, file: String, crows: Array[Scarecrow]) -> Image:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT + file))
	var parts := PackedStringArray()
	for i in crows.size():
		var s := crows[i]
		if is_instance_valid(s):
			var mat := (s.get_node("Sprite") as Sprite2D).material as ShaderMaterial
			parts.append("#%d burn_time_left=%.3f burn_mix=%.3f" % [i, s.burn_time_left, float(mat.get_shader_parameter("burn_mix"))])
		else:
			parts.append("#%d gone" % i)
	_log("%s (gate %.1f): %s" % [file, game.gate_hp, ", ".join(parts)])
	return img


func _log(s: String) -> void:
	print(s)
	lines.append(s)
