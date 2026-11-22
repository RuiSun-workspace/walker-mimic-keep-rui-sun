extends SceneTree
## Writes the prototype's placeholder sprites as PNGs. Every pixel comes from this code:
## flat cartoon colours plus a dark outline, no generated or downloaded art.
##   godot --headless --path godot --script res://tools/make_sprites.gd

const OUTLINE := Color("2b2b2b")
const OUT_DIR := "res://assets/sprites/"

# Named colours, so later work (shader predictions) can refer to exact source values.
const STRAW := Color("e9c46a")
const BURLAP := Color("d9b98a")
const POLE := Color("8b5a2b")
const HAT := Color("7a4e2d")
const PATCH := Color("b5651d")
const HOOD := Color("3a7d44")
const SKIN := Color("f1c27d")
const BOW := Color("6b3e1f")
const LEATHER := Color("5a3a22")
const CHEST := Color("9c6b3c")
const LID := Color("7a4e2d")
const GOLD := Color("e2b33c")
const WHITE := Color("f7f3e8")
const FLAME := Color("ff7a1a")
const STEEL := Color("9aa3ab")
const FLETCH := Color("c0392b")


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_save(_scarecrow(), "scarecrow.png")
	_save(_archer(), "archer.png")
	_save(_arrow(), "arrow.png")
	_save(_mimi(), "mimi.png")
	_save(_scarecrow_walk(), "scarecrow_walk.png")
	_save(_archer_body(), "archer_body.png")
	_save(_archer_bow(), "archer_bow.png")
	_save(_archer_string(), "archer_string.png")
	quit(0)


func _save(img: Image, file: String) -> void:
	var err := img.save_png(OUT_DIR + file)
	print("%s %s %dx%d" % ["wrote" if err == OK else "FAILED", file, img.get_width(), img.get_height()])


func _scarecrow() -> Image:
	var img := _blank(56, 72)
	_scarecrow_parts(img, 0, 0)
	return _outlined(img)


## The scarecrow's flat parts (no outline) with its 56x72 frame's top-left at (ox, oy).
func _scarecrow_parts(img: Image, ox: int, oy: int) -> void:
	_rect(img, ox + 26, oy + 30, 4, 40, POLE)            # pole
	_rect(img, ox + 4, oy + 30, 48, 4, POLE)             # cross-stick arms
	_rect(img, ox + 2, oy + 28, 5, 8, STRAW)             # straw tufts at the hands
	_rect(img, ox + 49, oy + 28, 5, 8, STRAW)
	_ellipse(img, ox + 28, oy + 46, 14, 16, STRAW)       # straw-stuffed body
	_rect(img, ox + 31, oy + 45, 6, 6, PATCH)            # sewn patch
	_ellipse(img, ox + 28, oy + 22, 11, 11, BURLAP)      # sack head
	_rect(img, ox + 12, oy + 12, 32, 4, HAT)             # hat brim
	_rect(img, ox + 18, oy + 2, 20, 11, HAT)             # hat crown
	_rect(img, ox + 23, oy + 20, 3, 3, OUTLINE)          # eyes
	_rect(img, ox + 31, oy + 20, 3, 3, OUTLINE)
	for x in range(23, 34, 2):                           # stitched mouth
		img.set_pixel(ox + x, oy + 27, OUTLINE)


# Walk sheet (CHANGE-BRIEF.md §2): 4x1 cells of 64x80. The 56x72 scarecrow sits with its
# centre at the cell centre (offset 4, 4), so the pole foot is the bottom edge of the pole,
# the continuous point (32, 74) in each cell.
const WALK_CELL := Vector2i(64, 80)
const WALK_FOOT := Vector2(32.0, 74.0)
const WALK_LEAN_DEG := 5.0
# Per frame: lean (-1 left, 0 upright, +1 right) and y offset in px.
const WALK_POSES := [[0, 0], [-1, -3], [0, 1], [1, -3]]


func _scarecrow_walk() -> Image:
	var upright := _blank(WALK_CELL.x, WALK_CELL.y)
	_scarecrow_parts(upright, 4, 4)
	var sheet := _blank(WALK_CELL.x * WALK_POSES.size(), WALK_CELL.y)
	for i in WALK_POSES.size():
		var cell := _walk_pose(upright, WALK_POSES[i][0], WALK_POSES[i][1])
		sheet.blit_rect(_outlined(cell), Rect2i(Vector2i.ZERO, WALK_CELL), Vector2i(i * WALK_CELL.x, 0))
	return sheet


## One pose: the flat upright parts rotated by lean * 5 degrees about the pole foot
## (nearest pixel, so the palette stays exact), then moved down by dy px.
## A negative angle in screen space (y down) tips the top to the left.
func _walk_pose(upright: Image, lean: int, dy: int) -> Image:
	var cell := _blank(WALK_CELL.x, WALK_CELL.y)
	var angle := deg_to_rad(WALK_LEAN_DEG) * lean
	var c := cos(angle)
	var s := sin(angle)
	for y in WALK_CELL.y:
		for x in WALK_CELL.x:
			# Inverse map: this pixel's centre, un-moved and un-rotated, back to the upright pose.
			var d := Vector2(x + 0.5, y - dy + 0.5) - WALK_FOOT
			var src := WALK_FOOT + Vector2(d.x * c + d.y * s, -d.x * s + d.y * c)
			var sx := floori(src.x)
			var sy := floori(src.y)
			if sx >= 0 and sy >= 0 and sx < WALK_CELL.x and sy < WALK_CELL.y:
				var p := upright.get_pixel(sx, sy)
				if p.a > 0.0:
					cell.set_pixel(x, y, p)
	return cell


func _archer() -> Image:
	# Seen from behind and below: the archer faces up the screen, toward the enemies.
	var img := _blank(44, 60)
	_rect(img, 14, 46, 6, 12, LEATHER)         # legs
	_rect(img, 24, 46, 6, 12, LEATHER)
	_ellipse(img, 22, 36, 12, 13, HOOD)        # cloak
	_rect(img, 10, 40, 24, 3, LEATHER)         # belt
	_ellipse(img, 22, 16, 10, 11, HOOD)        # hood
	_rect(img, 18, 24, 8, 4, SKIN)             # neck
	_rect(img, 33, 4, 3, 44, BOW)              # bow stave
	_rect(img, 36, 6, 1, 40, WHITE)            # bowstring
	return _outlined(img)


# Cutout-rig parts (CHANGE-BRIEF.md §1, revision 1.4): today's archer split into three PNGs,
# drawn with the same rectangles as _archer() above, each outlined on its own. archer.png
# itself is unchanged. All coordinates below are pixels of today's 44x60 archer.png; "placed
# at" is where the part image's top-left pixel (0, 0) sits when the rig is at rest.
#   archer_body.png    44x60  placed at (0, 0)   everything except the stave and the string
#   archer_bow.png      5x46  placed at (32, 3)  the stave (33..35, 4..47) plus its outline
#   archer_string.png   3x42  placed at (35, 5)  the string (36, 6..45) plus its outline
# Grip (the bow's pivot): the centre of the stave, the continuous point (34.5, 26.0) in
# archer.png, which is (2.5, 23.0) in archer_bow.png and (-0.5, 21.0) in archer_string.png.
# Stacking order at rest: body, then bow, then string (a string drawn under the bow would be
# hidden by the stave's right outline at x = 36).
const ARCHER_BODY_AT := Vector2i(0, 0)
const ARCHER_BOW_AT := Vector2i(32, 3)
const ARCHER_STRING_AT := Vector2i(35, 5)
const ARCHER_GRIP := Vector2(34.5, 26.0)


func _archer_body() -> Image:
	var img := _blank(44, 60)
	_rect(img, 14, 46, 6, 12, LEATHER)         # legs
	_rect(img, 24, 46, 6, 12, LEATHER)
	_ellipse(img, 22, 36, 12, 13, HOOD)        # cloak
	_rect(img, 10, 40, 24, 3, LEATHER)         # belt
	_ellipse(img, 22, 16, 10, 11, HOOD)        # hood
	_rect(img, 18, 24, 8, 4, SKIN)             # neck
	return _outlined(img)


func _archer_bow() -> Image:
	var img := _blank(5, 46)
	_rect(img, 33 - ARCHER_BOW_AT.x, 4 - ARCHER_BOW_AT.y, 3, 44, BOW)          # bow stave
	return _outlined(img)


func _archer_string() -> Image:
	var img := _blank(3, 42)
	_rect(img, 36 - ARCHER_STRING_AT.x, 6 - ARCHER_STRING_AT.y, 1, 40, WHITE)  # bowstring
	return _outlined(img)


func _arrow() -> Image:
	var img := _blank(10, 30)
	_rect(img, 4, 6, 2, 20, POLE)              # shaft
	_rect(img, 3, 2, 4, 5, STEEL)              # head
	_rect(img, 4, 0, 2, 3, FLAME)              # fire tip
	_rect(img, 2, 24, 2, 5, FLETCH)            # fletching
	_rect(img, 6, 24, 2, 5, FLETCH)
	return _outlined(img)


func _mimi() -> Image:
	var img := _blank(76, 60)
	_rect(img, 6, 26, 64, 30, CHEST)           # chest body
	_rect(img, 6, 6, 64, 14, LID)              # lid, raised a little: Mimi is peeking
	_rect(img, 6, 20, 64, 6, OUTLINE)          # dark mouth gap
	for x in range(10, 68, 8):                 # teeth
		_rect(img, x, 20, 4, 3, WHITE)
	_ellipse(img, 26, 13, 5, 5, WHITE)         # eyes on the lid
	_ellipse(img, 50, 13, 5, 5, WHITE)
	_rect(img, 25, 13, 3, 3, OUTLINE)
	_rect(img, 49, 13, 3, 3, OUTLINE)
	_rect(img, 14, 26, 5, 30, GOLD)            # gold bands
	_rect(img, 57, 26, 5, 30, GOLD)
	_rect(img, 33, 30, 10, 10, GOLD)           # lock
	_rect(img, 37, 33, 2, 4, OUTLINE)
	return _outlined(img)


func _blank(w: int, h: int) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


func _rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	img.fill_rect(Rect2i(x, y, w, h), c)


func _ellipse(img: Image, cx: int, cy: int, rx: int, ry: int, c: Color) -> void:
	for y in range(cy - ry, cy + ry + 1):
		for x in range(cx - rx, cx + rx + 1):
			var dx := float(x - cx) / rx
			var dy := float(y - cy) / ry
			if dx * dx + dy * dy <= 1.0 and x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
				img.set_pixel(x, y, c)


## Adds a 1-pixel dark outline around every opaque pixel (4-neighbour), in place.
func _outlined(img: Image) -> Image:
	var src := img.duplicate() as Image
	for y in img.get_height():
		for x in img.get_width():
			if src.get_pixel(x, y).a > 0.0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var p: Vector2i = Vector2i(x, y) + d
				if p.x >= 0 and p.y >= 0 and p.x < img.get_width() and p.y < img.get_height() and src.get_pixelv(p).a > 0.0:
					img.set_pixel(x, y, OUTLINE)
					break
	return img
