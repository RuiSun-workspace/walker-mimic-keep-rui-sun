extends SceneTree
## Probe (Claude) for Rui's windowed look at a startup cancel, after the walk-away cancel could not be
## isolated in normal play (other scarecrows are always in the cone by then). A fixture, not play:
## the real background, a real archer.tscn at its game position and ONE real scarecrow.tscn that is
## already at the wall. The probe only presses move_right (the player's key); it never calls travel(),
## start() or cancel_shot() and never writes archer, tree or clip state.
##   1 s idle with no target -> scarecrow placed at (600, 530) -> the archer starts the draw -> it
##   draws standing still until the bow is at -4 deg (visible; CHANGE-BRIEF Revision 4 item 3) ->
##   move_right held until the archer is at x 740, well out of the cone -> 2 s hold -> quit.
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
	# Wait on the pose, not on ticks, so --time-scale 0.25 shows the same visible lean before the run.
	var bow := archer.get_node("Rig/BowPivot") as Node2D
	while archer.shot_armed and bow.rotation_degrees > -4.0 and tick < 600:
		await physics_frame
		tick += 1
	print("tick %d: holding move_right, shot_armed %s, bow %.1f deg" % [tick, archer.shot_armed, bow.rotation_degrees])
	var cancel_tick := -1
	while tick < 1200:
		Input.action_press("move_right")   # re-pressed every tick: a real key event cannot release it
		await physics_frame
		tick += 1
		if cancel_tick < 0 and not archer.shot_armed:
			cancel_tick = tick
			print("tick %d: CANCELLED, archer x %.0f, tree node %s, arrows fired %d" % [
				tick, archer.position.x, archer.get_node("AnimationTree").get("parameters/playback").get_current_node(), fired_n])
		if cancel_tick >= 0 and archer.position.x >= 740.0:
			break
	Input.action_release("move_right")
	for i in 120:
		await physics_frame
		tick += 1
	print("tick %d: end; shot_armed %s, arrows fired %d, archer x %.0f" % [tick, archer.shot_armed, fired_n, archer.position.x])
	quit()
