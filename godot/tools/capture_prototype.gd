extends SceneTree
## Saves real rendered frames of the prototype and the shield room to evidence/prototype/.
## Must run WITHOUT --headless (a headless run draws nothing):
##   godot --path godot --script res://tools/capture_prototype.gd
## The game frame is scripted: spawning runs with a fixed seed and the archer stands still.

const OUT := "res://../evidence/prototype/"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var game := (load("res://game/main.tscn") as PackedScene).instantiate() as Game
	root.add_child(game)
	game.rng.seed = 7
	for i in 12 * 60:                        # 12 s of play
		await physics_frame
	await _save("game_12s.png")

	game.queue_free()
	var room := (load("res://showcase/shield_room.tscn") as PackedScene).instantiate()
	root.add_child(room)
	for i in 10:
		await process_frame
	await _save("shield_room.png")
	quit(0)


func _save(file: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var err := img.save_png(ProjectSettings.globalize_path(OUT + file))
	print("%s %s %dx%d" % ["wrote" if err == OK else "FAILED", file, img.get_width(), img.get_height()])
