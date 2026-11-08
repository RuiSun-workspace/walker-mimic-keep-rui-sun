extends Node
## Presentation only (CHANGE-BRIEF Effect A): on the parent Scarecrow's hit_taken, instances a NEW
## impact_burst.tscn under World/Effects (group "effects"), never under the scarecrow, so a lethal
## hit cannot free it (Rule A4). One instance per hit, never reused: retrigger = overlap (Rule A3).
## The burst frees itself on Straw.finished, the longer 0.80 s emitter (Rule A5).
## Reads the signal only; never writes game state.

const BURST_SCENE := preload("res://effects/impact_burst.tscn")


func _ready() -> void:
	(get_parent() as Scarecrow).hit_taken.connect(_on_hit_taken)


func _on_hit_taken(at: Vector2) -> void:
	var effects := get_tree().get_first_node_in_group("effects") as Node2D
	if effects == null:          # a scarecrow outside main.tscn has nowhere to put a burst
		return
	var burst := BURST_SCENE.instantiate() as Node2D
	effects.add_child(burst)
	burst.global_position = at   # set after add_child: does not assume World/Effects at the origin
	var straw := burst.get_node("Straw") as GPUParticles2D
	straw.finished.connect(burst.queue_free)
	(burst.get_node("Flash") as GPUParticles2D).emitting = true
	straw.emitting = true
