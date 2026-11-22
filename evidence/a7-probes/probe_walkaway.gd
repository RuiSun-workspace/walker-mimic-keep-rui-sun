extends SceneTree
## Probe (Claude, scratch): a real archer.tscn and one real scarecrow.tscn. Wait until the archer
## starts the draw (shot_armed), then hold move_right (away from the target) and log what happens.
## args: <target x> <target y>
var archer: Archer
var target: Scarecrow
var fired_n := 0
var hit := false

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var root2 := Node2D.new()
	root.add_child(root2)
	archer = (load("res://game/archer.tscn") as PackedScene).instantiate()
	archer.position = Vector2(640, 572)
	archer.arrows_parent = root2
	root2.add_child(archer)
	archer.fired.connect(func(_ar): fired_n += 1)
	target = (load("res://game/scarecrow.tscn") as PackedScene).instantiate()
	target.position = Vector2(float(a[0]), float(a[1]))
	root2.add_child(target)
	target.hit_taken.connect(func(_p): hit = true)
	_run()

func _angle() -> float:
	return rad_to_deg(absf(Vector2.UP.angle_to(target.global_position - archer.global_position)))

func _run() -> void:
	var tick := 0
	while not archer.shot_armed and tick < 300:
		await physics_frame
		tick += 1
	print("draw starts tick %d: archer x %.0f, target (%.0f, %.0f), angle %.1f deg" % [tick, archer.position.x, target.position.x, target.position.y, _angle()])
	Input.action_press("move_right")
	var outcome := "?"
	for i in 40:
		await physics_frame
		tick += 1
		if fired_n > 0:
			outcome = "FIRED on tick %d, archer x %.0f, angle %.1f deg" % [tick, archer.position.x, _angle()]
			break
		if not archer.shot_armed:
			outcome = "CANCELLED on tick %d, archer x %.0f, angle %.1f deg" % [tick, archer.position.x, _angle()]
			break
	Input.action_release("move_right")
	print(outcome)
	if fired_n > 0:
		for i in 180:
			await physics_frame
			if hit:
				break
		print("arrow %s" % ("HIT the target" if hit else "MISSED (no hit within 3 s)"))
	quit()
