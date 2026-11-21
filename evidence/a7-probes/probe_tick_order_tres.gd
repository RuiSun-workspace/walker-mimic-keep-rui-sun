extends SceneTree
# Probe: parent reads a property its child AnimationTree (PHYSICS) keys. Which tick does it see it?

class Reader extends Node2D:
	var release_window := false:
		set(v):
			if v != release_window:
				print("  [%s] release_window -> %s written during tick %d (after reader ran: %s)" % [name, v, tick, true])
			release_window = v
	var tree: AnimationTree
	var trigger_frame := -1
	var first_true := -1
	var tick := 0
	var cancel_at := -1
	func _physics_process(_d: float) -> void:
		tick += 1
		if name == "A" and (tick >= 9 and tick <= 13 or tick >= 26 and tick <= 29 or tick >= 40 and tick <= 46 or tick >= 69 and tick <= 78):
			var pb = tree.get("parameters/playback")
			print("  [%s] tick %d start: node=%s pos=%.4f rw=%s" % [name, tick, pb.get_current_node(), pb.get_current_play_position(), release_window])
		if release_window and first_true < 0:
			first_true = tick
		if tick == 10:
			trigger_frame = tick
			tree.get("parameters/playback").travel("shoot")
		if tick == 70:
			tree.get("parameters/playback").travel("shoot")
		if tick == 75:
			tree.get("parameters/playback").start("idle")


func _make(priority_tree: int) -> Reader:
	var r := Reader.new()
	var lib := AnimationLibrary.new()
	for clip in ["idle", "shoot"]:
		var a := Animation.new()
		var t := a.add_track(Animation.TYPE_VALUE)
		a.track_set_path(t, NodePath(".:release_window"))
		a.value_track_set_update_mode(t, Animation.UPDATE_DISCRETE)
		if clip == "idle":
			a.length = 0.1
			a.track_insert_key(t, 0.0, false)
		else:
			a.length = 15.0 / 30.0
			a.track_insert_key(t, 0.0, false)
			a.track_insert_key(t, 8.0 / 30.0, true)
			a.track_insert_key(t, 9.0 / 30.0, false)
		ResourceSaver.save(a, "user://probe_%s_%s.tres" % [clip, priority_tree])
		a = ResourceLoader.load("user://probe_%s_%s.tres" % [clip, priority_tree], "", ResourceLoader.CACHE_MODE_IGNORE)
		lib.add_animation(clip, a)
	var sm := AnimationNodeStateMachine.new()
	var ni := AnimationNodeAnimation.new(); ni.animation = "idle"
	var ns := AnimationNodeAnimation.new(); ns.animation = "shoot"
	sm.add_node("idle", ni); sm.add_node("shoot", ns)
	var st := AnimationNodeStateMachineTransition.new()
	sm.add_transition("Start", "idle", st)
	var t1 := AnimationNodeStateMachineTransition.new()
	t1.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_ENABLED
	sm.add_transition("idle", "shoot", t1)
	var t2 := AnimationNodeStateMachineTransition.new()
	t2.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
	t2.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END
	sm.add_transition("shoot", "idle", t2)
	var tree := AnimationTree.new()
	tree.add_animation_library("", lib)
	tree.tree_root = sm
	tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	tree.process_priority = priority_tree
	tree.process_physics_priority = priority_tree
	r.add_child(tree)
	r.tree = tree
	return r


var a: Reader
var b: Reader
var frames := 0

func _initialize() -> void:
	a = _make(0)
	a.name = "A"
	b = _make(-10)
	b.name = "B"
	root.add_child(a)
	root.add_child(b)

func _physics_process(_d: float) -> bool:
	frames += 1
	if frames >= 90:
		print("default order: travel at tick %d, first true read at tick %d (delta %d ticks; key 8/30 s = 16 ticks)" % [a.trigger_frame, a.first_true, a.first_true - a.trigger_frame])
		print("tree priority -10: travel at tick %d, first true read at tick %d (delta %d ticks)" % [b.trigger_frame, b.first_true, b.first_true - b.trigger_frame])
		return true
	return false
