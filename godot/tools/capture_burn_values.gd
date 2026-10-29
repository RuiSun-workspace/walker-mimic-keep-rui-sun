extends SceneTree
## Controlled-value captures for the Burning tint (CHANGE-BRIEF.md §5 "Exact tint calculation", §6,
## short answer 7). Must run WITHOUT --headless (a headless run draws nothing):
##   godot --path godot --script res://tools/capture_burn_values.gd
## Five scarecrows stand on the real meadow, frozen, each with its own material set to one burn_mix
## value. The driver is not running (World is disabled), so nothing overwrites the values. One frame
## is saved, the brief's named sprite pixels are read from it, and each is compared with the colour
## line computed here: result = original * (1 - burn_mix) + burn_color * burn_mix.
## Writes evidence/controlled_values/{burn_values.png, burn_values_zoom.png, pixels.txt}.
## With "-- --hold" it writes the same files to evidence/controlled_values/os_compare/ instead, adds
## window.txt (the client area on screen) and keeps the window open HOLD_S seconds so an OS screenshot
## of the same frame can be taken and compared with tools/compare_os_screenshot.gd.

const OUT := "res://../evidence/controlled_values/"
const SPRITE := "res://assets/sprites/scarecrow.png"
const VALUES := [0.0, 0.5, 0.65, 1.0, 2.0]
const ROW_Y := 300                       # px, middle of the meadow, away from the wall
const FIRST_X := 320
const STEP_X := 160
const BURN_COLOR := Color8(255, 192, 32) # the shader default, CHANGE-BRIEF §6
const PIXELS := {                        # CHANGE-BRIEF §6 named pixels, in sprite texels
	"Straw body (28, 46)": Vector2i(28, 46),
	"Patch (33, 47)": Vector2i(33, 47),
	"Sack head (28, 22)": Vector2i(28, 22),
}
const ZOOM := 4
const HOLD_S := 12.0

var lines := PackedStringArray()
var out := OUT


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var hold := OS.get_cmdline_user_args().has("--hold")
	if hold:
		out = OUT + "os_compare/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var game := (load("res://game/main.tscn") as PackedScene).instantiate() as Game
	game.spawning_enabled = false
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	game.world.process_mode = Node.PROCESS_MODE_DISABLED   # archer, arrows, scarecrows and the driver stop

	var src := Image.load_from_file(ProjectSettings.globalize_path(SPRITE))
	var half := Vector2i(src.get_width() / 2, src.get_height() / 2)   # Sprite2D is centred
	var crows := []
	for i in VALUES.size():
		var s := game.spawn_scarecrow(Vector2(FIRST_X + i * STEP_X, ROW_Y))
		var mat := (s.get_node("Sprite") as Sprite2D).material as ShaderMaterial
		mat.set_shader_parameter("burn_mix", VALUES[i])
		crows.append(s)
	for i in 10:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(out + "burn_values.png"))

	_log("Controlled-value capture, %s, Godot %s" % [Time.get_date_string_from_system(), Engine.get_version_info().string])
	_log("renderer=%s adapter=%s frame=%dx%d hdr_2d=%s" % [RenderingServer.get_current_rendering_method(),
		RenderingServer.get_video_adapter_name(), img.get_width(), img.get_height(),
		ProjectSettings.get_setting("rendering/viewport/hdr_2d")])
	_log("burn_color as set in the shader: (255, 192, 32). Values read back from each material:")
	for i in VALUES.size():
		var mat := ((crows[i] as Node).get_node("Sprite") as Sprite2D).material as ShaderMaterial
		_log("  scarecrow %d at x=%d: burn_mix = %s" % [i, FIRST_X + i * STEP_X, str(mat.get_shader_parameter("burn_mix"))])
	_log("")
	_log("Prediction = original*(1-m) + burn_color*m, clamped to 0..1 on output, rounded to 8 bit.")
	_log("For m = 2.0 the line also shows what m clamped to 1.0 would give.")
	_log("")

	var matches := 0
	var total := 0
	for i in VALUES.size():
		var m: float = VALUES[i]
		var origin := Vector2i(FIRST_X + i * STEP_X, ROW_Y) - half
		for label in PIXELS:
			var t: Vector2i = PIXELS[label]
			var orig := src.get_pixelv(t)
			var got := img.get_pixelv(origin + t)
			var want := _predict(orig, m)
			var ok := _close(got, want)
			total += 1
			matches += 1 if ok else 0
			var line := "m=%-4s %-20s original %s  predicted %s  captured %s  %s" % [str(m), label,
				_rgb(orig), _rgb(want), _rgb(got), "MATCH" if ok else "DIFFERS"]
			if m > 1.0:
				line += "   (if clamped to 1.0: %s)" % _rgb(_predict(orig, 1.0))
			_log(line)
	_log("")
	_log("%d of %d sampled pixels match the colour-line prediction within 1 step." % [matches, total])

	var x0 := FIRST_X - half.x - 8
	var crop := img.get_region(Rect2i(x0, ROW_Y - half.y - 8, (VALUES.size() - 1) * STEP_X + 2 * half.x + 16, 2 * half.y + 16))
	crop.resize(crop.get_width() * ZOOM, crop.get_height() * ZOOM, Image.INTERPOLATE_NEAREST)
	crop.save_png(ProjectSettings.globalize_path(out + "burn_values_zoom.png"))

	var f := FileAccess.open(ProjectSettings.globalize_path(out + "pixels.txt"), FileAccess.WRITE)
	f.store_string("\n".join(lines) + "\n")
	f.close()
	if hold:
		var w := FileAccess.open(ProjectSettings.globalize_path(out + "window.txt"), FileAccess.WRITE)
		w.store_string("client_position=%s\nclient_size=%s\nscreen=%d\nscreen_scale=%s\n" % [
			str(DisplayServer.window_get_position()), str(DisplayServer.window_get_size()),
			DisplayServer.window_get_current_screen(), str(DisplayServer.screen_get_scale())])
		w.close()
		print("HOLDING %.0f s" % HOLD_S)
		await create_timer(HOLD_S).timeout
	quit(0)


func _predict(orig: Color, m: float) -> Color:
	var c := orig * (1.0 - m) + BURN_COLOR * m
	return Color(clampf(c.r, 0.0, 1.0), clampf(c.g, 0.0, 1.0), clampf(c.b, 0.0, 1.0))


func _close(a: Color, b: Color) -> bool:
	return absi(a.r8 - b.r8) <= 1 and absi(a.g8 - b.g8) <= 1 and absi(a.b8 - b.b8) <= 1


func _rgb(c: Color) -> String:
	return "(%3d, %3d, %3d)" % [c.r8, c.g8, c.b8]


func _log(s: String) -> void:
	print(s)
	lines.append(s)
