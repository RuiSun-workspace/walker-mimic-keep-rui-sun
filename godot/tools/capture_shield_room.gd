extends SceneTree
## In-engine captures of the shield room under its stated lighting (CHANGE-BRIEF.md §8), for the
## interface sweep and the one-shader-two-materials check. Must run WITHOUT --headless:
##   godot --path godot --script res://tools/capture_shield_room.gd -- sweep
##   godot --path godot --script res://tools/capture_shield_room.gd -- shot <name>
## "sweep": each uniform of shield_wood.gdshader is set, in memory only, to its minimum, its default
## and its maximum while every other value keeps the material's setting. Surface uniforms are swept on
## ShieldA (shield_new.tres); Damage uniforms on ShieldB (shield_burned.tres), because at ShieldA's
## scorch_amount 0.05 the Damage values barely show. The other shield is the unchanged reference.
## Ranges and defaults are read from the shader source text.
## Writes evidence/sweep/<uniform>_<min|default|max>.png, sweep_sheet.png (swept shield only) and sweep.txt.
## "shot <name>": one frame as saved on disk, written to evidence/two_materials/<name>.png.
## Nothing is saved back to any material or scene.

const SCENE := "res://showcase/shield_room.tscn"
const SHADER := "res://shaders/shield_wood.gdshader"
const SWEEP_DIR := "res://../evidence/sweep/"
const SHOT_DIR := "res://../evidence/two_materials/"
const SETTLE := 6                       # frames after a change before the capture (shadows)
const ON_SHIELD_B := ["scorch_amount", "scorch_color", "char_roughness"]   # group_uniforms Damage


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var room := (load(SCENE) as PackedScene).instantiate()
	root.add_child(room)
	if args.size() >= 2 and args[0] == "shot":
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
		var img := await _frame()
		img.save_png(ProjectSettings.globalize_path(SHOT_DIR + args[1] + ".png"))
		print("saved ", SHOT_DIR + args[1] + ".png")
	elif args.size() >= 1 and args[0] == "sweep":
		await _sweep(room)
	else:
		push_error("usage: -- sweep | -- shot <name>")
	quit(0)


func _sweep(room: Node) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SWEEP_DIR))
	var cam := room.get_node("Camera3D") as Camera3D
	var crop_a := _screen_rect(cam, room.get_node("ShieldA") as MeshInstance3D).grow(12)
	var crop_b := Rect2i(_screen_rect(cam, room.get_node("ShieldB") as MeshInstance3D).grow(12).position, crop_a.size)
	var lines := PackedStringArray()
	lines.append("Interface sweep of shield_wood.gdshader, %s, Godot %s, %s" % [
		Time.get_date_string_from_system(), Engine.get_version_info().string, RenderingServer.get_current_rendering_method()])
	lines.append("Surface uniforms on ShieldA (shield_new.tres), Damage uniforms on ShieldB (shield_burned.tres);")
	lines.append("every other value as in the material. Room lighting as saved: Sun energy 1.2 with shadows,")
	lines.append("ambient 0.3, linear tonemap.")
	lines.append("")

	var uniforms := _uniforms(FileAccess.get_file_as_string(SHADER))
	var tiles: Array[Image] = []
	for u in uniforms:
		var shield := "ShieldB" if ON_SHIELD_B.has(u.name) else "ShieldA"
		var crop := crop_b if shield == "ShieldB" else crop_a
		var mat := (room.get_node(shield) as MeshInstance3D).get_surface_override_material(0) as ShaderMaterial
		lines.append("%s on %s" % [u.name, shield])
		var saved: Variant = mat.get_shader_parameter(u.name)
		for which in ["min", "default", "max"]:
			mat.set_shader_parameter(u.name, u[which])
			var img := await _frame()
			img.save_png(ProjectSettings.globalize_path(SWEEP_DIR + "%s_%s.png" % [u.name, which]))
			tiles.append(img.get_region(crop))
			lines.append("%-16s %-7s = %s" % [u.name, which, str(u[which])])
		mat.set_shader_parameter(u.name, saved)
		lines.append("%-16s back to the material's %s" % [u.name, str(saved)])
		lines.append("")

	# Contact sheet: one row per uniform, columns min / default / max.
	var w := crop_a.size.x
	var h := crop_a.size.y
	var sheet := Image.create(w * 3 + 8, h * uniforms.size() + 4 * (uniforms.size() - 1), false, tiles[0].get_format())
	sheet.fill(Color.WHITE)
	for i in tiles.size():
		sheet.blit_rect(tiles[i], Rect2i(Vector2i.ZERO, crop_a.size), Vector2i((i % 3) * (w + 4), (i / 3) * (h + 4)))
	sheet.save_png(ProjectSettings.globalize_path(SWEEP_DIR + "sweep_sheet.png"))
	lines.append("sweep_sheet.png: rows in the order above, columns min | default | max, the swept shield")
	lines.append("cropped to %s (ShieldA) or %s (ShieldB)." % [str(crop_a), str(crop_b)])
	var f := FileAccess.open(ProjectSettings.globalize_path(SWEEP_DIR + "sweep.txt"), FileAccess.WRITE)
	f.store_string("\n".join(lines) + "\n")
	f.close()
	print("\n".join(lines))


## Every float and vec4 uniform with its range and default, read from the shader text.
func _uniforms(src: String) -> Array:
	var out := []
	var re := RegEx.create_from_string("uniform\\s+(float|vec4)\\s+(\\w+)\\s*:\\s*([^=;]*?)\\s*=\\s*([^;]+);")
	var range_re := RegEx.create_from_string("hint_range\\(\\s*([-\\d.]+)\\s*,\\s*([-\\d.]+)")
	for m in re.search_all(src):
		var u := {"name": m.get_string(2)}
		if m.get_string(1) == "float":
			var r := range_re.search(m.get_string(3))
			u["min"] = float(r.get_string(1))
			u["max"] = float(r.get_string(2))
			u["default"] = float(m.get_string(4))
		else:                                   # vec4 : source_color, each channel 0..1
			var n := m.get_string(4).replace("vec4", "").replace("(", "").replace(")", "").split(",")
			u["min"] = Color(0, 0, 0, 1)
			u["max"] = Color(1, 1, 1, 1)
			u["default"] = Color(float(n[0]), float(n[1]), float(n[2]), float(n[3]))
		out.append(u)
	return out


func _frame() -> Image:
	for i in SETTLE:
		await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


func _screen_rect(cam: Camera3D, mesh: MeshInstance3D) -> Rect2i:
	var box := mesh.get_aabb()
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for i in 8:
		var p := cam.unproject_position(mesh.global_transform * box.get_endpoint(i))
		lo = lo.min(p)
		hi = hi.max(p)
	return Rect2i(Vector2i(lo.floor()), Vector2i((hi - lo).ceil()))
