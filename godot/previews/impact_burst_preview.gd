extends Node2D
## Preview for Effect A, the Arrow Impact Burst (CHANGE-BRIEF.md §7, Effect A frame strip).
## The real game background at the game's 1:1 scale (the game has no Camera2D; 1280x720 viewport),
## a still scarecrow sprite at its stopping point y = 530, and the burst at the scarecrow's centre.
## Fires at frame 10 and, with `retrigger` on, again at frame 28 (0.60 s later at 30 fps).
## Each trigger instances a new burst under Effects (the brief's overlap rule: never reuse a one-shot
## node); a burst frees itself when its straw emitter, the longest one, finishes (Rule A5).
## Not gameplay: nothing here is wired to Scarecrow.hit().
## Frame n = the n-th _process call, counted from 0, which should be Movie Maker file n.
## Pass `-- --no-retrigger` on the command line to turn the second hit off.
## Fixed seed (preview only, never in impact_burst.tscn): every burst instance gets
## use_fixed_seed = true and seed = base_seed + 100 * hit + emitter index, so strip r<N> and
## r<N+1> show the same random draw and only the tuned setting differs. The two hits get
## different seeds so the overlapping bursts do not look identical.

const BURST := preload("res://effects/impact_burst.tscn")

@export var retrigger := true
@export var first_frame := 10
@export var retrigger_frame := 28
@export var fixed_seed := true
@export var base_seed := 7270

var _frame := 0
var _hit := 0

@onready var _target: Node2D = $Scarecrow
@onready var _effects: Node2D = $Effects


func _ready() -> void:
	if "--no-retrigger" in OS.get_cmdline_user_args():
		retrigger = false
	print("impact_burst_preview: retrigger=%s, hits at frame %d%s" % [
			retrigger, first_frame, (" and %d" % retrigger_frame) if retrigger else ""])


func _process(_delta: float) -> void:
	if _frame == first_frame or (retrigger and _frame == retrigger_frame):
		_fire(_target.global_position)
	_frame += 1


func _fire(at: Vector2) -> void:
	var burst := BURST.instantiate() as Node2D
	_effects.add_child(burst)
	burst.global_position = at
	var straw := burst.get_node("Straw") as GPUParticles2D
	straw.finished.connect(burst.queue_free)
	var i := 0
	for e in burst.get_children():
		var p := e as GPUParticles2D
		if fixed_seed:
			p.use_fixed_seed = true
			p.seed = base_seed + 100 * _hit + i
		p.emitting = true
		i += 1
	print("frame %d: burst %d at %s, seeds %s" % [_frame, _hit, at,
			"fixed from %d" % (base_seed + 100 * _hit) if fixed_seed else "random"])
	_hit += 1
