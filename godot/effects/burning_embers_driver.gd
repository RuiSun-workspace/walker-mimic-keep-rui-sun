extends Node2D
## Presentation only (CHANGE-BRIEF Effect B, Rules B1-B7). Script on the BurningEmbers instance of
## burning_embers.tscn inside each scarecrow.tscn, so every scarecrow owns its own Embers and Smoke (B7).
## Reads the parent Scarecrow's signals and burn_time_left; never writes game state, never changes
## `amount` (all settings stay in burning_embers.tscn).
## - burning_started: emitting on, amount_ratio 1.0 (B1).
## - every frame while attached: amount_ratio = clamp(burn_time_left / BURN_DURATION, 0, 1) (B2). This
##   also covers a refresh while burning, which emits no signal (B3); emitting is not touched there.
## - burning_ended: amount_ratio 0.0, emitting off (B1).
## - died: emitting off, amount_ratio 0.0, reparent to World/Effects keeping the global transform, and
##   free after Smoke's lifetime (B4). The countdown runs in _process, so it inherits World's process
##   mode: it freezes while paused or after the game ends (B5) and finishes after R (A5 carry-over).

var _scarecrow: Scarecrow
var _emitters: Array[GPUParticles2D] = []
var _tail_left := -1.0          # s; >= 0 once detached on death


func _ready() -> void:
	_scarecrow = get_parent() as Scarecrow
	_emitters = [$Embers as GPUParticles2D, $Smoke as GPUParticles2D]
	_scarecrow.burning_started.connect(_on_burning_started)
	_scarecrow.burning_ended.connect(_on_burning_ended)
	_scarecrow.died.connect(_on_died)


func _process(delta: float) -> void:
	if _tail_left >= 0.0:
		_tail_left -= delta
		if _tail_left <= 0.0:
			queue_free()
		return
	if _scarecrow == null:
		return
	_set_ratio(clampf(_scarecrow.burn_time_left / Tuning.BURN_DURATION, 0.0, 1.0))


func _on_burning_started() -> void:
	_set_ratio(1.0)
	_set_emitting(true)


func _on_burning_ended() -> void:
	_set_ratio(0.0)
	_set_emitting(false)


func _on_died() -> void:
	_set_emitting(false)
	_set_ratio(0.0)
	_scarecrow = null
	var effects := get_tree().get_first_node_in_group("effects") as Node2D
	if effects == null:         # a scarecrow outside main.tscn: stopped, freed with its scarecrow
		return
	reparent(effects, true)
	_tail_left = ($Smoke as GPUParticles2D).lifetime


func _set_ratio(r: float) -> void:
	for e in _emitters:
		e.amount_ratio = r


func _set_emitting(on: bool) -> void:
	for e in _emitters:
		e.emitting = on
