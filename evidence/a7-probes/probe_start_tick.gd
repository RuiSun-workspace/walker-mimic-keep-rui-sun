extends SceneTree
## Why does test_archer_state_machine see "Start" on its first tick? Records the archer tree's
## current node at three moments of each of the first ticks of a fresh main.tscn:
## when SceneTree.physics_frame fires (where the test resumes), inside a node that runs its
## _physics_process after the archer's AnimationTree, and on the following process_frame.

const MAIN := preload("res://game/main.tscn")

class Late extends Node:
	var pb: AnimationNodeStateMachinePlayback
	func _physics_process(_d: float) -> void:
		print("  tick %d late _physics_process (after the tree): %s" % [Engine.get_physics_frames(), pb.get_current_node()])

var game: Game

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	game = MAIN.instantiate() as Game
	game.spawning_enabled = false
	root.add_child(game)
	var pb: AnimationNodeStateMachinePlayback = game.archer.get_node("AnimationTree").get("parameters/playback")
	print("after add_child (_ready ran): %s" % pb.get_current_node())
	var late := Late.new()
	late.pb = pb
	late.process_physics_priority = 1000
	root.add_child(late)
	for i in 4:
		await physics_frame
		print("tick %d physics_frame signal (test resumes here): %s" % [Engine.get_physics_frames(), pb.get_current_node()])
		await process_frame
		print("  frame %d process_frame: %s" % [Engine.get_process_frames(), pb.get_current_node()])
	quit()
