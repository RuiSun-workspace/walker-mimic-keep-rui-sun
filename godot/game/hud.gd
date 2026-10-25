extends CanvasLayer
## Status line, result banner and pause. Runs while the tree is paused so Esc/P can unpause.

@export var game_path: NodePath = ^".."

@onready var game: Game = get_node(game_path)
@onready var status: Label = $Status
@onready var banner: Label = $Banner


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	game.state_changed.connect(func(_s: Game.State) -> void: _refresh_banner())
	_refresh_banner()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and game.state == Game.State.PLAYING:
		get_tree().paused = not get_tree().paused
		_refresh_banner()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	status.text = "Gate %d / %d     Time %s / %s     Burned down %d" % [
		ceili(game.gate_hp), int(Tuning.GATE_HP), _clock(game.elapsed), _clock(Tuning.SURVIVE_TIME), game.kills]


func _refresh_banner() -> void:
	match game.state:
		Game.State.WON:
			banner.text = "Mimi is safe!\nR / Enter to play again"
		Game.State.LOST:
			banner.text = "The gate fell...\nR / Enter to try again"
		_:
			banner.text = "Paused\nEsc / P to resume" if get_tree().paused else ""


static func _clock(seconds: float) -> String:
	var s := int(seconds)
	return "%d:%02d" % [s / 60, s % 60]
