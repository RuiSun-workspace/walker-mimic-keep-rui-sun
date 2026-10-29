extends SceneTree
## Compares the in-engine capture with an OS screenshot of the same frame (course "Use It":
## "Compare one capture against an OS screenshot once"). Run after tools/os_screenshot.ps1:
##   godot --headless --path godot --script res://tools/compare_os_screenshot.gd
## Reads evidence/controlled_values/os_compare/{burn_values.png, os_screenshot.png, window.txt,
## screenshot_origin.txt}, lines the screenshot up with the game window's client area, and writes os_compare.txt:
## the 15 named pixels from both images and a whole-frame difference count.

const CAP := preload("res://tools/capture_burn_values.gd")
const DIR := "res://../evidence/controlled_values/os_compare/"

var lines := PackedStringArray()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var engine := Image.load_from_file(ProjectSettings.globalize_path(DIR + "burn_values.png"))
	var shot := Image.load_from_file(ProjectSettings.globalize_path(DIR + "os_screenshot.png"))
	var win := _read(DIR + "window.txt")
	var shot_origin := _read(DIR + "screenshot_origin.txt")         # where the OS image starts on screen
	var pos := _vec(win["client_position"]) - _vec(shot_origin["image_origin"])
	var size := _vec(win["client_size"])
	_log("In-engine capture %dx%d; OS screenshot %dx%d; game client area at %s size %s (screen_scale %s)." % [
		engine.get_width(), engine.get_height(), shot.get_width(), shot.get_height(), str(pos), str(size),
		win["screen_scale"]])
	if size != Vector2i(engine.get_width(), engine.get_height()):
		_log("Client area and capture differ in size: the OS image is scaled, so pixels cannot be compared 1:1.")
	var os := shot.get_region(Rect2i(pos, Vector2i(engine.get_width(), engine.get_height())))
	os.convert(engine.get_format())
	os.save_png(ProjectSettings.globalize_path(DIR + "os_screenshot_cropped.png"))
	_log("")

	var src := Image.load_from_file(ProjectSettings.globalize_path(CAP.SPRITE))
	var half := Vector2i(src.get_width() / 2, src.get_height() / 2)
	for i in CAP.VALUES.size():
		var origin := Vector2i(CAP.FIRST_X + i * CAP.STEP_X, CAP.ROW_Y) - half
		for label in CAP.PIXELS:
			var p: Vector2i = origin + CAP.PIXELS[label]
			var a := engine.get_pixelv(p)
			var b := os.get_pixelv(p)
			_log("m=%-4s %-20s in-engine %s  OS %s  max diff %d" % [str(CAP.VALUES[i]), label, _rgb(a), _rgb(b), _diff(a, b)])

	var same := 0
	var worst := 0
	var total := engine.get_width() * engine.get_height()
	for y in engine.get_height():
		for x in engine.get_width():
			var d := _diff(engine.get_pixel(x, y), os.get_pixel(x, y))
			worst = maxi(worst, d)
			same += 1 if d == 0 else 0
	_log("")
	_log("Whole frame: %d of %d pixels identical (%.2f%%), largest channel difference %d." % [
		same, total, 100.0 * same / total, worst])

	var f := FileAccess.open(ProjectSettings.globalize_path(DIR + "os_compare.txt"), FileAccess.WRITE)
	f.store_string("\n".join(lines) + "\n")
	f.close()
	quit(0)


func _read(path: String) -> Dictionary:
	var d := {}
	for line in FileAccess.get_file_as_string(ProjectSettings.globalize_path(path)).split("\n", false):
		var at := line.find("=")
		if at > 0:
			d[line.left(at).strip_edges()] = line.substr(at + 1).strip_edges()
	return d


func _vec(s: String) -> Vector2i:
	var n := s.replace("(", "").replace(")", "").split(",")
	return Vector2i(int(n[0]), int(n[1]))


func _diff(a: Color, b: Color) -> int:
	return maxi(absi(a.r8 - b.r8), maxi(absi(a.g8 - b.g8), absi(a.b8 - b.b8)))


func _rgb(c: Color) -> String:
	return "(%3d, %3d, %3d)" % [c.r8, c.g8, c.b8]


func _log(s: String) -> void:
	print(s)
	lines.append(s)
