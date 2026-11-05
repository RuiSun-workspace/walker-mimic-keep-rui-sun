extends SceneTree
## Writes the particle textures for the Assignment 6 effects as white PNGs; each emitter's colour ramp
## tints them. Every pixel comes from this code. No existing sprite or texture is touched.
##   godot --headless --path godot --script res://tools/make_particle_textures.gd
##   godot --headless --path godot --import          # then import the new PNGs
## Effect A (CHANGE-BRIEF.md §3): soft_dot.png 16x16 (A1 flash, later reused by B1), straw_chip.png 4x12 (A2).

const OUT_DIR := "res://effects/textures/"


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_save(_soft_dot(16), "soft_dot.png")
	_save(_straw_chip(), "straw_chip.png")
	quit(0)


func _save(img: Image, file: String) -> void:
	var err := img.save_png(OUT_DIR + file)
	print("%s %s %dx%d" % ["wrote" if err == OK else "FAILED", file, img.get_width(), img.get_height()])


## White disc whose alpha falls smoothly from 1 at the centre to 0 at the edge.
func _soft_dot(size: int) -> Image:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := (size - 1) / 2.0
	var r := size / 2.0
	for y in size:
		for x in size:
			var d := Vector2(x - c, y - c).length() / r
			var a := 1.0 - smoothstep(0.0, 1.0, d)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return img


## Narrow white chip, 4x12: opaque core, half-transparent outer columns and rounded ends.
func _straw_chip() -> Image:
	var img := Image.create(4, 12, false, Image.FORMAT_RGBA8)
	for y in 12:
		for x in 4:
			var a := 1.0 if x in [1, 2] else 0.6
			if y == 0 or y == 11:
				a = 0.6 if x in [1, 2] else 0.0
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return img
