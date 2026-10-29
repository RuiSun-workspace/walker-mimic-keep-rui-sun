extends SceneTree
## Writes the shield's scorch mask: a grayscale PNG where 0 = clean wood and 1 = fully scorched.
## Data, not colour: sample it without source_color (CHANGE-BRIEF.md §8). Seeded noise plus a
## ramp towards the outer edge of the 0..1 UV square, because fire chars a shield's rim first.
## The same seed always writes the same file.
##   godot --headless --path godot --script res://tools/make_scorch_mask.gd

const OUT := "res://assets/textures/shield_scorch_mask.png"
const SIZE := 512           # px, square
const SEED := 7270
const NOISE_FREQ := 4.0     # noise cycles across the texture
const EDGE_WIDTH := 0.22    # UV distance from the border over which the edge ramp fades to 0
const EDGE_WEIGHT := 0.45
const NOISE_WEIGHT := 1.0
const BIAS := -0.6          # pulls the middle of the shield towards clean wood
const NOISE_CONTRAST := 1.3   # FBM noise rarely leaves -0.4..0.4; this stretches it


func _init() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = SEED
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 4
	noise.frequency = NOISE_FREQ / SIZE

	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_L8)
	var sum := 0.0
	var over_half := 0
	for y in SIZE:
		for x in SIZE:
			var u := (x + 0.5) / SIZE
			var v := (y + 0.5) / SIZE
			var edge_dist := minf(minf(u, 1.0 - u), minf(v, 1.0 - v))
			var edge := 1.0 - clampf(edge_dist / EDGE_WIDTH, 0.0, 1.0)
			var n := noise.get_noise_2d(x, y) * NOISE_CONTRAST + 0.5   # centred on 0.5, not clamped
			var m := clampf(EDGE_WEIGHT * edge + NOISE_WEIGHT * n + BIAS, 0.0, 1.0)
			m = smoothstep(0.0, 1.0, m)
			img.set_pixel(x, y, Color(m, m, m))
			sum += m
			if m > 0.5:
				over_half += 1
	var err := img.save_png(ProjectSettings.globalize_path(OUT))
	if err != OK:
		push_error("could not write %s: %s" % [OUT, error_string(err)])
		quit(1)
		return
	print("wrote %s  %dx%d L8  seed %d  mean %.3f  pixels > 0.5: %.1f%%"
		% [OUT, SIZE, SIZE, SEED, sum / (SIZE * SIZE), 100.0 * over_half / (SIZE * SIZE)])
	quit()
