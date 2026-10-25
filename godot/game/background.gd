extends Node2D
## Meadow, castle wall and gate, drawn in code (flat cartoon colours).

const MEADOW := Color("6da34d")
const TUFT := Color("5a8f3e")
const STONE := Color("8d8f94")
const MORTAR := Color("6f7176")
const WALKWAY := Color("a3a5aa")
const GATE := Color("3b2f2a")


func _draw() -> void:
	var w := Tuning.VIEW.x
	var top := Tuning.WALL_TOP
	draw_rect(Rect2(0, 0, w, Tuning.VIEW.y), MEADOW)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7                                   # same tufts every run
	for i in 70:
		var p := Vector2(rng.randf_range(0, w), rng.randf_range(0, top - 40))
		draw_line(p, p + Vector2(-3, -7), TUFT, 2.0)
		draw_line(p, p + Vector2(3, -8), TUFT, 2.0)
	draw_rect(Rect2(0, top, w, Tuning.VIEW.y - top), STONE)
	draw_rect(Rect2(0, top - 4, w, 10), WALKWAY)
	for row in 4:                                  # brick courses
		var y := top + 6 + row * 28.0
		draw_line(Vector2(0, y), Vector2(w, y), MORTAR, 2.0)
		var offset := 0.0 if row % 2 == 0 else 32.0
		var x := offset
		while x < w:
			draw_line(Vector2(x, y), Vector2(x, y + 28), MORTAR, 2.0)
			x += 64.0
	draw_rect(Rect2(596, top + 34, 88, Tuning.VIEW.y - top - 34), GATE)
	draw_circle(Vector2(640, top + 34), 44, GATE)
