extends Node2D
## Preview for Clip 1, the scarecrow walk: the registration strip (CHANGE-BRIEF.md §2-3, §10
## "No drift within the cells"). The real level background (game/background.gd) at the project's
## 1280x720, 1:1 (camera zoom 1). One real game/scarecrow.tscn, placed once in the scene file at
## START_POS like Game.spawn_scarecrow() places one, walks down by its own scarecrow.gd; its own
## AnimationPlayer and WalkPresenter pick and play the clip. This script never writes scarecrow,
## sprite, player or clip state and never calls play(): it only moves its own Camera2D and prints.
##
## Walk time: SCARECROW_STOP_Y (530) - START_POS.y (200) = 330 px at SCARECROW_SPEED 45 px/s
## = 7.33 s before at_wall turns true (more than the 6 s asked for).
##
## Camera: Camera2D, no smoothing, zoom 1, anchored at the screen centre. Once per rendered frame,
## in _process, it is set to the scarecrow's global position and force_update_scroll() pushes the
## canvas transform at once, so the scarecrow's node origin is the screen centre (640, 360) on every
## line. The scarecrow moves only in _physics_process, and with --fixed-fps 30 all the frame's
## physics ticks (two at 60 Hz) run before _process, so nothing moves it between this update and the
## draw. The log's `screen_origin` column is the proof. The level is only 720 px tall, so the
## camera's view extends past its top early in the walk (clear colour there) and past its bottom
## late in the walk; the scarecrow's surroundings are level ground throughout.
##
## Every rendered frame prints one line; the header line names the fields. The first field is
## Engine.get_frames_drawn() (stays 0 headless, which draws nothing); the third, `pframe`, counts
## _process calls from 0, the frame number a headless run can show and the one that should match
## Movie Maker file n.

@onready var _scarecrow: Scarecrow = $World/Enemies/Scarecrow
@onready var _sprite: Sprite2D = $World/Enemies/Scarecrow/Sprite
@onready var _player: AnimationPlayer = $World/Enemies/Scarecrow/AnimationPlayer
@onready var _camera: Camera2D = $Camera2D

var _pframe := 0


func _ready() -> void:
	# Run _process after every other node's process step (WalkPresenter, the AnimationPlayer's
	# IDLE advance, Camera2D's own update), so each line reads the frame that is drawn.
	process_priority = 1000
	_camera.position_smoothing_enabled = false
	_camera.zoom = Vector2.ONE
	_camera.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	_camera.make_current()
	print("walk_preview: scarecrow starts at %s, stops at y %.1f, walks %.2f s; camera follows its origin" % [
			_scarecrow.position, Tuning.SCARECROW_STOP_Y,
			(Tuning.SCARECROW_STOP_Y - _scarecrow.position.y) / Tuning.SCARECROW_SPEED])
	print("frames_drawn | tick | pframe | global_pos | screen_origin | sprite_frame | animation | anim_pos | at_wall")


func _process(_delta: float) -> void:
	_camera.global_position = _scarecrow.global_position
	_camera.force_update_scroll()
	var origin := _scarecrow.get_global_transform_with_canvas().origin
	print("%d | %d | %d | (%.3f, %.3f) | (%.3f, %.3f) | %d | %s | %.4f | %s" % [
			Engine.get_frames_drawn(), Engine.get_physics_frames(), _pframe,
			_scarecrow.global_position.x, _scarecrow.global_position.y,
			origin.x, origin.y, _sprite.frame,
			_player.current_animation, _player.current_animation_position, _scarecrow.at_wall])
	_pframe += 1
