extends SceneTree
## Reads godot/assets/sprites/scarecrow_walk.png straight from disk (not through the importer)
## and checks the walk sheet against CHANGE-BRIEF.md §2: size, pole-foot registration,
## no clipping at any cell edge, and the scarecrow's colours in every cell.
##   bash scripts/run-test.sh test_scarecrow_sheet.gd 60

const SHEET := "res://assets/sprites/scarecrow_walk.png"
const CELL_W := 64
const CELL_H := 80
const CELLS := 4
const Y_OFFSETS := [0, -3, 1, -3]   # brief §2 frame order, relative to frame 0

# Source colours, the same values as godot/tools/make_sprites.gd.
const COLOURS := {
	"STRAW": Color("e9c46a"),
	"BURLAP": Color("d9b98a"),
	"POLE": Color("8b5a2b"),
	"HAT": Color("7a4e2d"),
	"OUTLINE": Color("2b2b2b"),
}

var failures := 0


func _init() -> void:
	var img := Image.load_from_file(ProjectSettings.globalize_path(SHEET))
	if img == null:
		_check(false, "sheet loads from %s" % SHEET)
		_finish()
		return
	img.convert(Image.FORMAT_RGBA8)
	_check(img.get_width() == CELL_W * CELLS and img.get_height() == CELL_H,
		"sheet is 256x80 (got %dx%d)" % [img.get_width(), img.get_height()])

	# Pole foot: in each cell, the lowest row that holds any pixel of exactly the POLE colour
	# (opaque, alpha 1) is the bottom of the pole; the foot's y is that row and its x is the
	# midpoint of the leftmost and rightmost POLE pixels in that row. The x is kept doubled
	# (min + max) so a half-pixel midpoint compares exactly as an integer.
	var feet := []
	for i in CELLS:
		feet.append(_pole_foot(img, i))
		print("cell %d: pole foot x2=%d (x=%.1f) y=%d" % [i, feet[i].x, feet[i].x / 2.0, feet[i].y])
	for i in CELLS:
		_check(feet[i].y >= 0, "cell %d has POLE pixels" % i)
	if feet[0].y >= 0:
		for i in range(1, CELLS):
			_check(feet[i].x == feet[0].x,
				"cell %d pole-foot x %.1f equals cell 0's %.1f" % [i, feet[i].x / 2.0, feet[0].x / 2.0])
		for i in CELLS:
			var want: int = feet[0].y + Y_OFFSETS[i]
			_check(feet[i].y == want,
				"cell %d pole-foot y %d equals cell 0's %d %+d = %d" % [i, feet[i].y, feet[0].y, Y_OFFSETS[i], want])

	for i in CELLS:
		var edge := _edge_opaque_count(img, i)
		_check(edge == 0, "cell %d: no opaque pixel on its outer row or column (found %d)" % [i, edge])

	for i in CELLS:
		for name in COLOURS:
			_check(_cell_has(img, i, COLOURS[name]), "cell %d contains %s" % [i, name])

	_finish()


func _pole_foot(img: Image, cell: int) -> Vector2i:
	var pole: int = COLOURS["POLE"].to_rgba32()
	for y in range(CELL_H - 1, -1, -1):
		var lo := -1
		var hi := -1
		for x in CELL_W:
			if img.get_pixel(cell * CELL_W + x, y).to_rgba32() == pole:
				if lo < 0:
					lo = x
				hi = x
		if lo >= 0:
			return Vector2i(lo + hi, y)
	return Vector2i(-1, -1)


func _edge_opaque_count(img: Image, cell: int) -> int:
	var n := 0
	for y in CELL_H:
		for x in CELL_W:
			if x != 0 and y != 0 and x != CELL_W - 1 and y != CELL_H - 1:
				continue
			if img.get_pixel(cell * CELL_W + x, y).a > 0.0:
				n += 1
	return n


func _cell_has(img: Image, cell: int, c: Color) -> bool:
	var want := c.to_rgba32()
	for y in CELL_H:
		for x in CELL_W:
			if img.get_pixel(cell * CELL_W + x, y).to_rgba32() == want:
				return true
	return false


func _check(ok: bool, what: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", what])
	if not ok:
		failures += 1


func _finish() -> void:
	print("RESULT %s (%d failure%s)" % ["PASS" if failures == 0 else "FAIL", failures, "" if failures == 1 else "s"])
	quit(1 if failures > 0 else 0)
