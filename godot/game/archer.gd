class_name Archer
extends Node2D
## The hero on the wall walk: slides along X only and fires on its own (GDD 5.1, 6.2).
## Aims at the nearest scarecrow inside the upward cone; holds fire when there is none.

signal fired(arrow: Arrow)

const ARROW_SCENE := preload("res://game/arrow.tscn")

var arrows_parent: Node
var fire_cooldown := 0.0


func _physics_process(delta: float) -> void:
	var axis := Input.get_axis("move_left", "move_right")
	position.x = clampf(position.x + axis * Tuning.ARCHER_SPEED * delta,
			Tuning.ARCHER_MARGIN, Tuning.VIEW.x - Tuning.ARCHER_MARGIN)
	fire_cooldown = maxf(fire_cooldown - delta, 0.0)
	if fire_cooldown > 0.0:
		return
	var target := nearest_target()
	if target:
		_fire_at(target)
		fire_cooldown = Tuning.FIRE_INTERVAL


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


func _fire_at(target: Scarecrow) -> void:
	var arrow := ARROW_SCENE.instantiate() as Arrow
	var from := global_position + Vector2(0, -24)
	arrow.launch(from, target.global_position - from)
	(arrows_parent if arrows_parent else get_parent()).add_child(arrow)
	fired.emit(arrow)
