extends SceneTree
## args: <dir> <frame>... ; in the crop x 600..680, y 330..440, finds the lowest row with a pixel that is not
## meadow (6da34d) or tuft (5a8f3e), and that row's leftmost/rightmost such x (the pole foot), screen px.
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var meadow := Color("6da34d"); var tuft := Color("5a8f3e")
	for f in a.slice(1):
		var img := Image.load_from_file("%s/frame%08d.png" % [a[0], int(f)])
		if img == null:
			print("cannot load ", f); continue
		var by := -1; var lx := 9999; var rx := -1
		for y in range(440, 330, -1):
			for x in range(600, 680):
				var c := img.get_pixel(x, y)
				if c.is_equal_approx(meadow) or c.is_equal_approx(tuft): continue
				if maxf(absf(c.r - meadow.r), maxf(absf(c.g - meadow.g), absf(c.b - meadow.b))) < 6.0 / 255.0: continue
				by = y; lx = mini(lx, x); rx = maxi(rx, x)
			if by >= 0: break
		print("frame %s: foot bottom y %d, x %d..%d (centre %.1f)" % [f, by, lx, rx, (lx + rx) / 2.0])
	quit()
