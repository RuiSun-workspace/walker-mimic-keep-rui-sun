extends Node2D
## Preview for Effect B, Burning Embers (CHANGE-BRIEF.md §7, Effect B frame strip).
## The real game background at the game's 1:1 scale (the game has no Camera2D; 1280x720 viewport),
## a still scarecrow at its stopping point y = 530, and one burning_embers.tscn instance at the
## scarecrow's centre, laid out like the game scene (root Node2D -> Sprite + effect).
## Ignites at frame 10: burn time is set to 4.0 s and counts down by the frame delta (1/30 s under
## Movie Maker at 30 fps), so it reaches 0 at frame 130. Every frame both emitters get
## amount_ratio = clamp(burn_time_left / 4.0, 0, 1) (Rule B2), and at 0 emission stops (Rule B1).
## With `reignite` on (off by default; or pass `-- --reignite`), burn time goes back to 4.0 s at
## frame 100 (the brief's second strip, Rule B3): no restart, emitting stays true, only the ratio
## jumps back to 1.0; burning then ends at frame 220.
## The scarecrow sprite uses Rui's burning_tint.gdshader (referenced, not edited) with
## burn_mix = 0.65 * the same ratio, as the game's burning_tint.gd does.
## Not gameplay: nothing here is wired to Scarecrow; this fixture owns its own burn time.
## Frame n = the n-th _process call, counted from 0, which should be Movie Maker file n.
## Fixed seed (preview only, never in burning_embers.tscn): this instance's emitters get
## use_fixed_seed = true and seed = base_seed + emitter index, so strip r<N> and r<N+1> show the
## same random draw and only the tuned setting differs.

const BURN_DURATION := 4.0       # CHANGE-BRIEF §3 mapping divisor (= Tuning.BURN_DURATION)
const BURN_MIX_MAX := 0.65       # burning_tint.gd BURN_MIX_MAX
const END_EPSILON := 1e-4        # absorbs float drift so 120 steps of 1/30 end exactly at frame 130

@export var ignite_frame := 10
@export var reignite := false
@export var reignite_frame := 100
@export var fixed_seed := true
@export var base_seed := 7270

var burn_time_left := 0.0
var _frame := 0
var _emitters: Array[GPUParticles2D] = []

@onready var _sprite: Sprite2D = $Scarecrow/Sprite
@onready var _fx: Node2D = $Scarecrow/BurningEmbers


func _ready() -> void:
	if "--reignite" in OS.get_cmdline_user_args():
		reignite = true
	var i := 0
	for e in _fx.get_children():
		var p := e as GPUParticles2D
		if fixed_seed:
			p.use_fixed_seed = true
			p.seed = base_seed + i
		_emitters.append(p)
		i += 1
	_apply(0.0)
	print("burning_embers_preview: ignite at frame %d%s, seeds %s" % [ignite_frame,
			(", reignite at frame %d" % reignite_frame) if reignite else "",
			("fixed from %d" % base_seed) if fixed_seed else "random"])


func _process(delta: float) -> void:
	if _frame == ignite_frame or (reignite and _frame == reignite_frame):
		var first := burn_time_left <= 0.0
		burn_time_left = BURN_DURATION
		_apply(1.0)
		if first:
			for p in _emitters:
				p.emitting = true
		print("frame %d: %s, burn_time_left = %.3f" % [_frame, "ignite" if first else "reignite", burn_time_left])
	elif burn_time_left > 0.0:
		burn_time_left -= delta
		if burn_time_left <= END_EPSILON:
			burn_time_left = 0.0
			_apply(0.0)
			for p in _emitters:
				p.emitting = false
			print("frame %d: burning ended, emission stopped" % _frame)
		else:
			_apply(clampf(burn_time_left / BURN_DURATION, 0.0, 1.0))
	_frame += 1


func _apply(ratio: float) -> void:
	for p in _emitters:
		p.amount_ratio = ratio
	(_sprite.material as ShaderMaterial).set_shader_parameter("burn_mix", BURN_MIX_MAX * ratio)
