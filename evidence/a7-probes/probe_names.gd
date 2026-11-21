extends SceneTree
# Probe for CLAUDE.md "Unconfirmed" items, Godot 4.7.2: property existence and .tscn text for an AnimationLibrary.

func _has(obj: Object, prop: String) -> bool:
	for p in obj.get_property_list():
		if p.name == prop:
			return true
	return false

func _initialize() -> void:
	var tree := AnimationTree.new()
	print("AnimationTree.deterministic: ", _has(tree, "deterministic"), " default ", tree.get("deterministic"))
	print("AnimationTree.callback_mode_process default: ", tree.callback_mode_process)
	print("AnimationTree.advance_expression_base_node default: ", tree.advance_expression_base_node)
	var na := AnimationNodeAnimation.new()
	print("AnimationNodeAnimation.use_custom_timeline: ", _has(na, "use_custom_timeline"))
	print("AnimationNodeStateMachinePlayback.get_current_play_position: ", AnimationNodeStateMachinePlayback.new().has_method("get_current_play_position"))
	var player := AnimationPlayer.new()
	print("AnimationPlayer.callback_mode_process default: ", player.callback_mode_process)
	print("Animation.step default: ", Animation.new().step)
	# .tscn text for a player with a library holding one discrete frame clip
	var root2 := Node2D.new(); root2.name = "Probe"
	var spr := Sprite2D.new(); spr.name = "Sprite"; root2.add_child(spr); spr.owner = root2
	root2.add_child(player); player.name = "AnimationPlayer"; player.owner = root2
	var a := Animation.new(); a.length = 0.5; a.step = 0.125; a.loop_mode = Animation.LOOP_LINEAR
	var t := a.add_track(Animation.TYPE_VALUE); a.track_set_path(t, NodePath("Sprite:frame"))
	a.value_track_set_update_mode(t, Animation.UPDATE_DISCRETE)
	for i in 4: a.track_insert_key(t, i * 0.125, i)
	var lib := AnimationLibrary.new(); lib.add_animation("walk", a); player.add_animation_library("", lib)
	var ps := PackedScene.new(); ps.pack(root2); ResourceSaver.save(ps, "user://probe_scene.tscn")
	print("---- saved .tscn ----")
	print(FileAccess.open("user://probe_scene.tscn", FileAccess.READ).get_as_text())
	quit()
