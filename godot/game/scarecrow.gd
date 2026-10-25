class_name Scarecrow
extends Node2D
## Straw Scarecrow: walks down to the wall and hits the gate. Straw burns.
## Owns the Burning state: burn_time_left > 0 means burning. Fire refreshes it to the full
## BURN_DURATION (a second hit does not stack damage). Timed in physics time, so it follows
## Engine.time_scale and stops while the tree is paused.

signal burning_started
signal burning_ended
signal died
signal attacking_gate(amount: float)

var hp: float = Tuning.SCARECROW_HP
var burn_time_left: float = 0.0
var at_wall := false


func _ready() -> void:
	add_to_group("enemies")
	at_wall = position.y >= Tuning.SCARECROW_STOP_Y


func is_burning() -> bool:
	return burn_time_left > 0.0


func is_dead() -> bool:
	return hp <= 0.0


func hit(damage: float, element: StringName) -> void:
	if is_dead():
		return
	hp -= damage
	if element == &"fire":
		ignite()
	_check_death()


func ignite() -> void:
	var was_burning := is_burning()
	burn_time_left = Tuning.BURN_DURATION
	if not was_burning:
		burning_started.emit()


func _physics_process(delta: float) -> void:
	if is_dead() or is_queued_for_deletion():   # a reset in the same tick must not hit the gate
		return
	if is_burning():
		var burned := minf(delta, burn_time_left)
		hp -= Tuning.BURN_DPS * burned
		burn_time_left -= delta
		if burn_time_left <= 0.0:
			burn_time_left = 0.0
			burning_ended.emit()
		_check_death()
		if is_dead():
			return
	if at_wall:
		attacking_gate.emit(Tuning.SCARECROW_GATE_DPS * delta)
	else:
		position.y = minf(position.y + Tuning.SCARECROW_SPEED * delta, Tuning.SCARECROW_STOP_Y)
		at_wall = position.y >= Tuning.SCARECROW_STOP_Y


func _check_death() -> void:
	if is_dead():
		remove_from_group("enemies")
		died.emit()
		queue_free()
