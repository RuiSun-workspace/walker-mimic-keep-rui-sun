extends SceneTree
## Reads the archer's three cutout-rig part images straight from disk (not through the importer)
## and checks them against godot/tools/make_sprites.gd: size, which colours each part holds,
## and how closely the parts, stacked at their rest placements, rebuild today's archer.png.
##   bash scripts/run-test.sh test_archer_parts.gd 60

const DIR := "res://assets/sprites/"

# Size the generator writes, and the pixel of the 44x60 archer.png where the part image's
# top-left sits at rest. Listed in stacking order (body, bow, string), as in make_sprites.gd.
const PARTS := [
	{"file": "archer_body.png", "size": Vector2i(44, 60), "at": Vector2i(0, 0)},
	{"file": "archer_bow.png", "size": Vector2i(5, 46), "at": Vector2i(32, 3)},
	{"file": "archer_string.png", "size": Vector2i(3, 42), "at": Vector2i(35, 5)},
]

# Source colours, the same values as godot/tools/make_sprites.gd.
const HOOD := Color("3a7d44")
const SKIN := Color("f1c27d")
const BOW := Color("6b3e1f")
const LEATHER := Color("5a3a22")
const WHITE := Color("f7f3e8")

var passes := 0
var failures := 0


func _init() -> void:
	var imgs := {}
	for part in PARTS:
		var path := ProjectSettings.globalize_path(DIR + part["file"])
		var ok := FileAccess.file_exists(path)
		_check(ok, "%s exists" % part["file"])
		if not ok:
			continue
		var img := Image.load_from_file(path)
		if img == null:
			_check(false, "%s loads" % part["file"])
			continue
		img.convert(Image.FORMAT_RGBA8)
		var want: Vector2i = part["size"]
		_check(img.get_size() == want, "%s is %dx%d (got %dx%d)"
			% [part["file"], want.x, want.y, img.get_width(), img.get_height()])
		imgs[part["file"]] = img

	if imgs.has("archer_body.png"):
		var body: Image = imgs["archer_body.png"]
		_check(_count(body, HOOD) > 0, "archer_body.png holds HOOD")
		_check(_count(body, LEATHER) > 0, "archer_body.png holds LEATHER")
		_check(_count(body, SKIN) > 0, "archer_body.png holds SKIN")
		_check(_count(body, BOW) == 0, "archer_body.png holds no BOW pixel (found %d)" % _count(body, BOW))
		_check(_count(body, WHITE) == 0, "archer_body.png holds no WHITE pixel (found %d)" % _count(body, WHITE))
	if imgs.has("archer_bow.png"):
		_check(_count(imgs["archer_bow.png"], BOW) > 0, "archer_bow.png holds BOW")
	if imgs.has("archer_string.png"):
		_check(_count(imgs["archer_string.png"], WHITE) > 0, "archer_string.png holds WHITE")

	# Composite at rest, compared with archer.png. Reported, not judged: each part has its own
	# outline, so pixels differ where parts touch.
	var archer := Image.load_from_file(ProjectSettings.globalize_path(DIR + "archer.png"))
	if archer == null:
		_check(false, "archer.png loads")
	elif imgs.size() == PARTS.size():
		archer.convert(Image.FORMAT_RGBA8)
		var comp := Image.create(44, 60, false, Image.FORMAT_RGBA8)
		comp.fill(Color(0, 0, 0, 0))
		for part in PARTS:
			var img: Image = imgs[part["file"]]
			comp.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), part["at"])
		var diffs := 0
		for y in 60:
			for x in 44:
				if comp.get_pixel(x, y).to_rgba32() != archer.get_pixel(x, y).to_rgba32():
					diffs += 1
					print("INFO diff at (%d, %d): composite %s, archer.png %s"
						% [x, y, comp.get_pixel(x, y).to_html(), archer.get_pixel(x, y).to_html()])
		print("INFO composite at rest vs archer.png: %d of %d pixels differ" % [diffs, 44 * 60])

	print("RESULT %s: %d passed, %d failed" % ["PASS" if failures == 0 else "FAIL", passes, failures])
	quit(1 if failures > 0 else 0)


func _count(img: Image, c: Color) -> int:
	var want := c.to_rgba32()
	var n := 0
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).to_rgba32() == want:
				n += 1
	return n


func _check(ok: bool, what: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", what])
	if ok:
		passes += 1
	else:
		failures += 1
