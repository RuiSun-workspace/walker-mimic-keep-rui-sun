class_name Archer
extends Node2D
## The hero on the wall walk: slides along X only and fires on its own (GDD 5.1, 6.2).
## Aims at the nearest scarecrow inside the upward cone; holds fire when there is none.
## Owns the shot state machine (CHANGE-BRIEF §5, §6): it decides when to draw (travel("shoot")) and
## when to cancel (playback.start("idle")); the AnimationTree only plays the clips and keys
## release_window, which this script reads and never writes.

signal fired(arrow: Arrow)

const ARROW_SCENE := preload("res://game/arrow.tscn")
## s; the draw starts when fire_cooldown is at most this (brief §5.2: 18 ticks from travel("shoot")
## to the first true read of release_window, so back-to-back shots keep the 36-tick cadence).
## Here, not in tuning.gd, because tuning.gd is out of scope for this change.
const DRAW_LEAD := 0.3

var arrows_parent: Node
var fire_cooldown := 0.0
var release_window := false          # written only by Archer/AnimationTree (idle and shoot clips)
var shot_armed := false              # true from travel("shoot") until the arrow, a cancel or a restart
var locked_target: Scarecrow = null  # taken when the draw starts (brief §5.3)
var _locked_pos := Vector2.ZERO      # locked target's global position, recorded every armed tick

@onready var _playback: AnimationNodeStateMachinePlayback = $AnimationTree.get("parameters/playback")


func _physics_process(delta: float) -> void:
	var axis := Input.get_axis("move_left", "move_right")
	position.x = clampf(position.x + axis * Tuning.ARCHER_SPEED * delta,
			Tuning.ARCHER_MARGIN, Tuning.VIEW.x - Tuning.ARCHER_MARGIN)
	fire_cooldown = maxf(fire_cooldown - delta, 0.0)
	if shot_armed:
		if release_window:
			# Active frame: the arrow goes even if the target was lost on this same tick (§5.5).
			var aim := locked_target.global_position if is_instance_valid(locked_target) else _locked_pos
			_fire_at(aim)
			fire_cooldown = Tuning.FIRE_INTERVAL
			shot_armed = false
			locked_target = null
		elif not _target_held():
			cancel_shot()   # startup: target died or left the cone; no new draw on this tick
		else:
			_locked_pos = locked_target.global_position
		return
	if fire_cooldown > DRAW_LEAD or _playback.get_current_node() != &"idle":
		return
	var target := nearest_target()
	if target:
		locked_target = target
		_locked_pos = target.global_position
		shot_armed = true
		_playback.travel(&"shoot")


## Ends a shot that has not released: clears the guard and the target, returns the tree to idle at
## once. Never writes release_window (§5.4); a stale true is ignored because shot_armed is false.
func cancel_shot() -> void:
	shot_armed = false
	locked_target = null
	_playback.start(&"idle")


func nearest_target() -> Scarecrow:
	var best: Scarecrow = null
	var best_dist := INF
	var half_cone := deg_to_rad(Tuning.FIRE_CONE_DEG / 2.0)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var s := enemy as Scarecrow
		if s == null or s.is_dead():
			continue
		var to := s.global_position - global_position
		if absf(Vector2.UP.angle_to(to)) > half_cone:
			continue
		if to.length() < best_dist:
			best_dist = to.length()
			best = s
	return best


## The locked target is alive and still inside the cone (same test as nearest_target()).
func _target_held() -> bool:
	if not is_instance_valid(locked_target) or locked_target.is_queued_for_deletion() or locked_target.is_dead():
		return false
	var to := locked_target.global_position - global_position
	return absf(Vector2.UP.angle_to(to)) <= deg_to_rad(Tuning.FIRE_CONE_DEG / 2.0)


func _fire_at(target_pos: Vector2) -> void:
	var arrow := ARROW_SCENE.instantiate() as Arrow
	var from := global_position + Vector2(0, -24)
	arrow.launch(from, target_pos - from)
	(arrows_parent if arrows_parent else get_parent()).add_child(arrow)
	fired.emit(arrow)
