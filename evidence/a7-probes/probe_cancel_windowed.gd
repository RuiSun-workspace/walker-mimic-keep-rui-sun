extends SceneTree
## Probe (Claude) for Rui's windowed look at a startup cancel, after the walk-away cancel could not be
## isolated in normal play (other scarecrows are always in the cone by then). A fixture, not play:
## the real background, a real archer.tscn at its game position and ONE real scarecrow.tscn that is
## already at the wall. The probe only presses move_right (the player's key); it never calls travel(),
## start() or cancel_shot() and never writes archer, tree or clip state.
##   1 s idle with no target -> scarecrow placed at (600, 530) -> the archer starts the draw -> 8 ticks
##   of draw standing still (the bow first moves visibly on clip frame 3, CHANGE-BRIEF Revision 4) ->
##   move_right held until 10 ticks after the cancel -> 2 s hold -> quit.
## Run windowed (from the repo root):
##   <godot exe> --path godot --script <abs path to this file> [--time-scale 0.25]

var archer: Archer
var target: Scarecrow
var fired_n := 0


func _initialize() -> void:
	var world := Node2D.new()
	root.add_child(world)
	var bg := Node2D.new()
	bg.set_script(load("res://game/background.gd"))
	world.add_child(bg)
	archer = (load("res://game/archer.tscn") as PackedScene).instantiate()
	archer.position = Vector2(640, 572)
	archer.arrows_parent = world
	world.add_child(archer)
	archer.fired.connect(func(_a): fired_n += 1)
	_run(world)


func _run(world: Node2D) -> void:
	var tick := 0
	for i in 60:
		await physics_frame
		tick += 1
	target = (load("res://game/scarecrow.tscn") as PackedScene).instantiate()
	target.position = Vector2(600, 530)
	world.add_child(target)
	print("tick %d: scarecrow placed at (600, 530), at the wall" % tick)
	while not archer.shot_armed and tick < 200:
		await physics_frame
		tick += 1
	print("tick %d: draw starts (shot_armed), archer x %.0f" % [tick, archer.position.x])
	for i in 8:
		await physics_frame
		tick += 1
	print("tick %d: holding move_right, shot_armed %s, bow %.1f deg" % [tick, archer.shot_armed, archer.get_node("Rig/BowPivot").rotation_degrees])
	Input.action_press("move_right")
	var cancel_tick := -1
	while tick < 260:
		await physics_frame
		tick += 1
		if cancel_tick < 0 and not archer.shot_armed:
			cancel_tick = tick
			print("tick %d: CANCELLED, archer x %.0f, tree node %s, arrows fired %d" % [
				tick, archer.position.x, archer.get_node("AnimationTree").get("parameters/playback").get_current_node(), fired_n])
		if cancel_tick >= 0 and tick >= cancel_tick + 10:
			break
	Input.action_release("move_right")
	for i in 120:
		await physics_frame
		tick += 1
	print("tick %d: end; shot_armed %s, arrows fired %d, archer x %.0f" % [tick, archer.shot_armed, fired_n, archer.position.x])
	quit()
