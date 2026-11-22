extends Node2D
## Preview for Clip 2, the archer shot (CHANGE-BRIEF.md §11 frame strip).
## The real level background (game/background.gd) at the game's 1:1 scale (no Camera2D, 1280x720),
## and the real game/archer.tscn at its game position (640, 572) with arrows_parent set. The draw,
## the release and the arrow come from archer.gd's own rule and the AnimationTree: this script never
## calls travel(), start() or cancel_shot() and never writes archer, tree or clip state. It only
## places and removes its own real scarecrow (game/scarecrow.tscn) and prints what it reads.
##
## Trigger: one scarecrow is placed inside the cone on physics tick TRIGGER_TICK. archer.gd sees it on
## that same tick (this root runs its _physics_process before its children) and calls travel("shoot"),
## so with --fixed-fps 30 (two 60 Hz physics ticks per movie frame) the draw starts on movie frame 10.
##
## Repeat: once a shot has finished (tree back in idle, no live arrow) the target is removed at once,
## because archer.gd would start the next draw 18 ticks after the release while a target stays in the
## cone (brief §5.2). After REPEAT_GAP_TICKS (1 s) with an empty field a new scarecrow is placed on a
## tick of the same parity as TRIGGER_TICK, so every repeat lands on the same position in its frame.
##
## Every rendered frame prints one line; the header line names the fields. The first field is
## Engine.get_frames_drawn(); a headless run draws nothing, so it stays 0 there. The second, `pframe`,
## counts _process calls from 0 (frame n holds physics ticks 2n and 2n+1 at --fixed-fps 30): the
## frame number a headless run can show, and the one that should match Movie Maker file n.

const SCARECROW_SCENE := preload("res://game/scarecrow.tscn")
const TARGET_POS := Vector2(640, 420)   # straight above the archer, inside the cone; dies only after 4 hits
## Physics tick (Engine.get_physics_frames() inside _physics_process) the target is placed on.
## Measured with --fixed-fps 30: the draw then starts on movie frame 10 (see the run log).
const TRIGGER_TICK := 20
const REPEAT_GAP_TICKS := 60            # 1 s at 60 physics ticks per second

var _next_place_tick := TRIGGER_TICK
var _target: Scarecrow = null
var _seen_fire := false
var _fired_ticks: Array[int] = []
var _pframe := 0

@onready var _arrows: Node2D = $World/Arrows
@onready var _enemies: Node2D = $World/Enemies
@onready var _archer: Archer = $World/Archer
@onready var _tree: AnimationTree = $World/Archer/AnimationTree
@onready var _playback: AnimationNodeStateMachinePlayback = _tree.get("parameters/playback")
@onready var _pivot: Node2D = $World/Archer/Rig/BowPivot
@onready var _string: Node2D = $World/Archer/Rig/BowPivot/String


func _ready() -> void:
	_archer.arrows_parent = _arrows
	_archer.fired.connect(_on_fired)
	print("shoot_preview: target placed on physics tick %d at %s, repeat %d ticks after each shot" % [
			TRIGGER_TICK, TARGET_POS, REPEAT_GAP_TICKS])
	print("frames_drawn | pframe | tick | node | play_pos | release_window | shot_armed | pivot_rot_deg | pivot_pos"
			+ " | string_pos | string_scale | arrows | fired")


func _physics_process(_delta: float) -> void:
	var tick := Engine.get_physics_frames()
	if _target == null:
		if tick == _next_place_tick:
			_place_target()
		return
	if _seen_fire and _playback.get_current_node() == &"idle" and _arrows.get_child_count() == 0:
		_remove_target()
		var next := tick + REPEAT_GAP_TICKS
		if (next - TRIGGER_TICK) % 2 != 0:
			next += 1
		_next_place_tick = next


func _process(_delta: float) -> void:
	var fired := "-"
	if not _fired_ticks.is_empty():
		fired = ",".join(_fired_ticks.map(func(t: int) -> String: return "fired@tick%d" % t))
		_fired_ticks.clear()
	print("%d | %d | %d | %s | %.4f | %s | %s | %.2f | (%.2f, %.2f) | (%.2f, %.2f) | (%.3f, %.3f) | %d | %s" % [
			Engine.get_frames_drawn(), _pframe, Engine.get_physics_frames(),
			_playback.get_current_node(), _playback.get_current_play_position(),
			_archer.release_window, _archer.shot_armed,
			rad_to_deg(_pivot.rotation), _pivot.position.x, _pivot.position.y,
			_string.position.x, _string.position.y, _string.scale.x, _string.scale.y,
			_arrows.get_child_count(), fired])
	_pframe += 1


func _place_target() -> void:
	_target = SCARECROW_SCENE.instantiate() as Scarecrow
	_target.position = TARGET_POS
	_enemies.add_child(_target)
	_seen_fire = false
	print("tick %d: target placed at %s" % [Engine.get_physics_frames(), TARGET_POS])


func _remove_target() -> void:
	if is_instance_valid(_target):
		_target.remove_from_group("enemies")   # gone for archer.gd on this same tick
		_target.queue_free()
	_target = null
	print("tick %d: shot finished, target removed" % Engine.get_physics_frames())


func _on_fired(_arrow: Arrow) -> void:
	_seen_fire = true
	_fired_ticks.append(Engine.get_physics_frames())
