extends Node
## Presentation only (CHANGE-BRIEF §1, revision 1.4): picks which clip Scarecrow/AnimationPlayer plays
## from the scarecrow's at_wall. walk while it advances, hold (frame 0) once it hits the gate.
## Reads game state, never writes it; never writes Sprite.frame (the AnimationPlayer is its one writer).
## Compares against assigned_animation, not current_animation: hold is a one-key LOOP_NONE clip, so
## current_animation turns "" once it ends and would otherwise make this call play() every frame.

@onready var _scarecrow: Scarecrow = get_parent() as Scarecrow
@onready var _player: AnimationPlayer = $"../AnimationPlayer"


func _process(_delta: float) -> void:
	var clip := &"hold" if _scarecrow.at_wall else &"walk"
	if _player.assigned_animation != clip:
		_player.play(clip)
