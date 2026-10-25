class_name Game
extends Node2D
## One prototype run: survive SURVIVE_TIME seconds of scarecrows without losing the gate.
## Owns the run state (gate HP, elapsed time, kills, win/lose). Restart with R/Enter at the end.

signal state_changed(new_state: State)

enum State { PLAYING, WON, LOST }

const SCARECROW_SCENE := preload("res://game/scarecrow.tscn")
const ARCHER_START := Vector2(640, 572)

@export var spawning_enabled := true
## (start, end) spawn interval used instead of Tuning's when non-zero; only tools/balance_sim.gd sets it.
var spawn_interval_override := Vector2.ZERO

var state: State = State.PLAYING
var gate_hp: float = Tuning.GATE_HP
var elapsed := 0.0
var kills := 0
var spawn_timer := 0.0
var rng := RandomNumberGenerator.new()

@onready var world: Node2D = $World
@onready var enemies: Node2D = $World/Enemies
@onready var arrows: Node2D = $World/Arrows
@onready var archer: Archer = $World/Archer


func _ready() -> void:
	rng.randomize()
	archer.arrows_parent = arrows
	reset()


func reset() -> void:
	for child in enemies.get_children() + arrows.get_children():
		if child.is_in_group("enemies"):
			child.remove_from_group("enemies")
		child.queue_free()
	gate_hp = Tuning.GATE_HP
	elapsed = 0.0
	kills = 0
	spawn_timer = 1.0
	archer.position = ARCHER_START
	archer.fire_cooldown = 0.0
	world.process_mode = Node.PROCESS_MODE_INHERIT
	_set_state(State.PLAYING)


func spawn_scarecrow(at: Vector2) -> Scarecrow:
	var s := SCARECROW_SCENE.instantiate() as Scarecrow
	s.position = at
	s.died.connect(func() -> void: kills += 1)
	s.attacking_gate.connect(_on_attacking_gate)
	enemies.add_child(s)
	return s


func spawn_interval() -> float:
	var t := clampf(elapsed / Tuning.SURVIVE_TIME, 0.0, 1.0)
	if spawn_interval_override != Vector2.ZERO:
		return lerpf(spawn_interval_override.x, spawn_interval_override.y, t)
	return lerpf(Tuning.SPAWN_INTERVAL_START, Tuning.SPAWN_INTERVAL_END, t)


func _physics_process(delta: float) -> void:
	if state != State.PLAYING:
		return
	elapsed += delta
	if elapsed >= Tuning.SURVIVE_TIME:
		_end(State.WON)
		return
	if spawning_enabled:
		spawn_timer -= delta
		if spawn_timer <= 0.0:
			spawn_timer += spawn_interval()
			spawn_scarecrow(Vector2(rng.randf_range(60.0, Tuning.VIEW.x - 60.0), -40.0))


func _unhandled_input(event: InputEvent) -> void:
	if state != State.PLAYING and event.is_action_pressed("restart"):
		reset()


func _on_attacking_gate(amount: float) -> void:
	if state != State.PLAYING:
		return
	gate_hp = maxf(gate_hp - amount, 0.0)
	if gate_hp <= 0.0:
		_end(State.LOST)


func _end(result: State) -> void:
	world.process_mode = Node.PROCESS_MODE_DISABLED   # freeze the field; HUD shows the result
	_set_state(result)


func _set_state(s: State) -> void:
	state = s
	state_changed.emit(s)
