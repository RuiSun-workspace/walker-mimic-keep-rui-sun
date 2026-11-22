extends SceneTree
## Crops the same rectangle out of several Movie Maker frames and tiles them left to right, so a
## reader can compare frame N with log line N. A 2-px white gap separates the tiles.
##   godot --headless --path godot --script res://tools/contact_sheet.gd -- \
##       <frames-dir> <x> <y> <w> <h> <out.png> <frame> [<frame> ...]
## Frames are read as <frames-dir>/frameNNNNNNNN.png (Movie Maker's PNG naming).

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() < 7:
		push_error("usage: <frames-dir> <x> <y> <w> <h> <out.png> <frame>...")
		quit(1)
		return
	var dir := a[0]
	var rect := Rect2i(int(a[1]), int(a[2]), int(a[3]), int(a[4]))
	var out := a[5]
	var frames := a.slice(6)
	var gap := 2
	var sheet := Image.create(frames.size() * (rect.size.x + gap) - gap, rect.size.y, false, Image.FORMAT_RGB8)
	sheet.fill(Color.WHITE)
	for i in frames.size():
		var path := "%s/frame%08d.png" % [dir, int(frames[i])]
		var img := Image.load_from_file(path)
		if img == null:
			push_error("cannot load " + path)
			quit(1)
			return
		img.convert(Image.FORMAT_RGB8)
		sheet.blit_rect(img, rect, Vector2i(i * (rect.size.x + gap), 0))
	var err := sheet.save_png(out)
	print("%s %s (%d tiles, frames %s)" % ["wrote" if err == OK else "FAILED", out, frames.size(), ", ".join(frames)])
	quit(0 if err == OK else 1)
