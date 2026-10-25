class_name Arrow
extends Node2D
## A fire arrow: flies straight, hits the first scarecrow within ARROW_HIT_RADIUS, sets it burning.

var velocity := Vector2.ZERO
var element: StringName = &"fire"


func launch(from: Vector2, direction: Vector2) -> void:
	position = from
	velocity = direction.normalized() * Tuning.ARROW_SPEED
	rotation = velocity.angle() + PI / 2.0     # the sprite points up


func _physics_process(delta: float) -> void:
	if is_queued_for_deletion():
		return
	position += velocity * delta
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var s := enemy as Scarecrow
		if s and s.global_position.distance_to(global_position) <= Tuning.ARROW_HIT_RADIUS:
			s.hit(Tuning.ARROW_DAMAGE, element)
			queue_free()
			return
	if position.y < -60.0 or position.x < -60.0 or position.x > Tuning.VIEW.x + 60.0:
		queue_free()
