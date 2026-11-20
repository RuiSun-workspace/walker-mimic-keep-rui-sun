extends SceneTree
func _init() -> void:
	var sm := AnimationNodeStateMachine.new()
	sm.add_node(&"idle", AnimationNodeAnimation.new())
	sm.add_node(&"shoot", AnimationNodeAnimation.new())
	var a := AnimationNodeStateMachineTransition.new()
	a.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END
	a.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
	var b := AnimationNodeStateMachineTransition.new()
	b.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_IMMEDIATE
	sm.add_transition(&"shoot", &"idle", a)
	sm.add_transition(&"shoot", &"idle", b)
	print("transitions after two shoot->idle adds: ", sm.get_transition_count())
	for i in sm.get_transition_count():
		print("  ", sm.get_transition_from(i), "->", sm.get_transition_to(i), " switch=", sm.get_transition(i).switch_mode)
	var t := AnimationTree.new()
	print("advance_expression_base_node default: '", t.advance_expression_base_node, "'")
	print("callback_mode_process default: ", t.callback_mode_process)
	var pb := AnimationNodeStateMachinePlayback.new()
	print("playback has start/travel: ", pb.has_method("start"), " ", pb.has_method("travel"))
	quit(0)
