extends Sprite2D
## Presentation only: shows the parent Scarecrow's Burning state through burning_tint.gdshader.
## Reads burn_time_left every frame and writes burn_mix to this Sprite's own ShaderMaterial
## (local to each scarecrow instance). Never writes game state; no TIME or frame count, so the
## fade follows the game timer, Engine.time_scale and pause (CHANGE-BRIEF Rules 1-6).

const BURN_MIX_MAX := 0.65


func _process(_delta: float) -> void:
	var s := get_parent() as Scarecrow
	var mix := BURN_MIX_MAX * clampf(s.burn_time_left / Tuning.BURN_DURATION, 0.0, 1.0)
	(material as ShaderMaterial).set_shader_parameter("burn_mix", mix)
