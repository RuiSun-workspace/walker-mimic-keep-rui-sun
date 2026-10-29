extends SceneTree
## Writes the hint experiment's test image: a 3×1 PNG whose texels are the greys 64, 128 and 192
## (CHANGE-BRIEF.md §7). Import it lossless with no mipmaps.
##   godot --headless --path godot --script res://tools/make_hint_greys.gd

const OUT := "res://assets/textures/hint_greys_3x1.png"
const GREYS := [64, 128, 192]


func _init() -> void:
	var img := Image.create(GREYS.size(), 1, false, Image.FORMAT_RGB8)
	for x in GREYS.size():
		var g: int = GREYS[x]
		img.set_pixel(x, 0, Color8(g, g, g))
	var err := img.save_png(ProjectSettings.globalize_path(OUT))
	if err != OK:
		push_error("could not write %s: %s" % [OUT, error_string(err)])
		quit(1)
		return
	print("wrote %s  %dx1 RGB8  greys %s" % [OUT, GREYS.size(), str(GREYS)])
	quit()
