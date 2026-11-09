extends SceneTree
## Configuration test for Effect B, Burning Embers (CHANGE-BRIEF.md §3, B1 and B2).
## Loads godot/effects/burning_embers.tscn and reads back every setting the brief names from the loaded
## nodes and resources; the expected values are the brief's.
##   bash scripts/run-test.sh test_burning_embers_config.gd 60
## Prints one PASS/FAIL line per check and exits 1 on any failure. Headless: this proves the
## configuration, not the look (CLAUDE.md, headless facts). It does not test the driver (Rules B1-B7).

const SCENE_PATH := "res://effects/burning_embers.tscn"
const EPS := 1e-4
const COLOR_EPS := 1e-3          # colours are stored as 32-bit floats

var passed := 0
var failed := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	_check("scene loads", packed != null, SCENE_PATH)
	if packed == null:
		_finish()
		return
	var fx := packed.instantiate()
	root.add_child(fx)
	await process_frame

	_check("root is Node2D", fx is Node2D, fx.get_class())
	var emitters := fx.get_children().filter(func(n): return n is GPUParticles2D or n is CPUParticles2D)
	_check("root holds exactly two emitters", emitters.size() == 2, str(emitters.size()))

	_check_emitter(fx.get_node_or_null("Embers"), {
		"name": "B1 Embers",
		"amount": 18, "lifetime": 0.90,
		"extents": Vector3(18, 30, 0), "spread": 25.0,
		"vel": [25.0, 45.0], "gravity": Vector3(0, -20, 0),
		"damping": [5.0, 10.0], "scale": [0.35, 0.70],
		"ramp_offsets": [0.0, 0.30, 0.45, 1.0],
		"ramp_colors": [Color(1.0, 0.95, 0.63, 0.0), Color(1.0, 0.95, 0.63, 1.0), Color(1.0, 0.54, 0.12, 0.90), Color(0.85, 0.29, 0.07, 0.0)],
		"curve_points": [Vector2(0, 0.60), Vector2(0.5, 1.0), Vector2(1, 0.10)],
		"curve_max": 1.0,
		"turbulence": false, "turb": [0.0, 0.0],
		"texture": "res://effects/textures/soft_dot.png", "tex_size": Vector2i(16, 16),
		"blend": CanvasItemMaterial.BLEND_MODE_ADD,
		"vis": Rect2(-48, -80, 96, 120),
		"rate": 20.0,
	})
	_check_emitter(fx.get_node_or_null("Smoke"), {
		"name": "B2 Smoke",
		"amount": 8, "lifetime": 1.20,
		"extents": Vector3(16, 26, 0), "spread": 35.0,
		"vel": [12.0, 22.0], "gravity": Vector3(0, -8, 0),
		"damping": [1.0, 4.0], "scale": [0.60, 1.0],
		"ramp_offsets": [0.0, 0.55, 1.0],
		"ramp_colors": [Color(0.29, 0.19, 0.15, 0.35), Color(0.22, 0.16, 0.14, 0.20), Color(0.16, 0.13, 0.12, 0.0)],
		"curve_points": [Vector2(0, 0.50), Vector2(0.85, 1.40), Vector2(1, 0)],
		"curve_max": 1.5,
		"turbulence": true, "turb": [0.15, 0.30],
		"texture": "res://effects/textures/smoke_dot.png", "tex_size": Vector2i(32, 32),
		"blend": CanvasItemMaterial.BLEND_MODE_MIX,
		"vis": Rect2(-64, -100, 128, 150),
		"rate": 8.0 / 1.2,
	})

	# Rule B4 / §2 timing: smoke (1.20 s) is the longest tail, the cleanup time after death.
	var embers := fx.get_node_or_null("Embers") as GPUParticles2D
	var smoke := fx.get_node_or_null("Smoke") as GPUParticles2D
	if embers and smoke:
		_check("B4 smoke is the longest-lived emitter (1.20 s tail)", smoke.lifetime > embers.lifetime,
				"%s vs %s" % [smoke.lifetime, embers.lifetime])

	# A non-burning scarecrow begins clean: one frame after loading, still not emitting, ratio 0.
	for e in emitters:
		_check("%s still not emitting after one frame" % e.name, not e.emitting)
		_eq("%s amount_ratio still 0 after one frame" % e.name, e.amount_ratio, 0.0)

	_finish()


func _finish() -> void:
	print("test_burning_embers_config: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


# --- one emitter -------------------------------------------------------------

func _check_emitter(node: Node, x: Dictionary) -> void:
	var n: String = x.name
	_check("%s exists as GPUParticles2D" % n, node is GPUParticles2D, "got %s" % (node.get_class() if node else "null"))
	if not node is GPUParticles2D:
		return
	var p := node as GPUParticles2D

	# Node: emission and simulation settings.
	for prop in ["amount", "amount_ratio", "emitting", "one_shot", "explosiveness", "lifetime", "preprocess",
			"local_coords", "visibility_rect", "texture", "process_material", "material"]:
		_check("%s node %s is a stored property" % [n, prop], _is_stored(p, prop))
	_check("%s emitting = false" % n, p.emitting == false)
	_eq("%s amount_ratio (initial state)" % n, p.amount_ratio, 0.0)
	_check("%s amount = %d" % [n, x.amount], p.amount == x.amount, str(p.amount))
	_check("%s one_shot = false" % n, p.one_shot == false)
	_eq("%s explosiveness" % n, p.explosiveness, 0.0)
	_eq("%s lifetime" % n, p.lifetime, x.lifetime)
	_eq("%s preprocess" % n, p.preprocess, 0.0)
	_check("%s local_coords = true" % n, p.local_coords == true)
	_check("%s visibility_rect = %s" % [n, x.vis], p.visibility_rect.is_equal_approx(x.vis), str(p.visibility_rect))
	_check("%s rate at amount_ratio 1 = amount / lifetime = %.2f /s" % [n, x.rate],
			absf(p.amount / p.lifetime - x.rate) <= 0.01, "%.3f" % (p.amount / p.lifetime))

	# Draw: texture and blend mode.
	var tex := p.texture
	_check("%s texture = %s" % [n, x.texture], tex != null and tex.resource_path == x.texture,
			tex.resource_path if tex else "null")
	if tex:
		_check("%s texture size %s" % [n, x.tex_size], Vector2i(tex.get_size()) == x.tex_size, str(tex.get_size()))
	var cim := p.material as CanvasItemMaterial
	_check("%s material is CanvasItemMaterial" % n, cim != null, str(p.material))
	if cim:
		_check("%s blend_mode = %d" % [n, x.blend], cim.blend_mode == x.blend, str(cim.blend_mode))

	# Process: ParticleProcessMaterial.
	var m := p.process_material as ParticleProcessMaterial
	_check("%s process_material is ParticleProcessMaterial" % n, m != null, str(p.process_material))
	if m == null:
		return
	# Every property read below must be a stored property in 4.7.2, not an editor-only alias.
	for prop in ["particle_flag_disable_z", "emission_shape", "emission_box_extents", "direction", "spread",
			"gravity", "initial_velocity_min", "initial_velocity_max", "damping_min", "damping_max",
			"scale_min", "scale_max", "color_ramp", "scale_curve",
			"turbulence_enabled", "turbulence_influence_min", "turbulence_influence_max"]:
		_check("%s %s is a stored property" % [n, prop], _is_stored(m, prop))
	_check("%s particle_flag_disable_z = true" % n, m.particle_flag_disable_z == true)
	_check("%s emission_shape = BOX" % n, m.emission_shape == ParticleProcessMaterial.EMISSION_SHAPE_BOX,
			str(m.emission_shape))
	_check("%s emission_box_extents = %s" % [n, x.extents], m.emission_box_extents.is_equal_approx(x.extents),
			str(m.emission_box_extents))
	_check("%s direction = (0, -1, 0)" % n, m.direction.is_equal_approx(Vector3(0, -1, 0)), str(m.direction))
	_eq("%s spread" % n, m.spread, x.spread)
	_check("%s gravity = %s" % [n, x.gravity], m.gravity.is_equal_approx(x.gravity), str(m.gravity))
	_eq("%s initial_velocity_min" % n, m.initial_velocity_min, x.vel[0])
	_eq("%s initial_velocity_max" % n, m.initial_velocity_max, x.vel[1])
	_eq("%s damping_min" % n, m.damping_min, x.damping[0])
	_eq("%s damping_max" % n, m.damping_max, x.damping[1])
	_eq("%s scale_min" % n, m.scale_min, x.scale[0])
	_eq("%s scale_max" % n, m.scale_max, x.scale[1])

	# Turbulence: on for the smoke with its influence range, off for the embers.
	_check("%s turbulence_enabled = %s" % [n, x.turbulence], m.turbulence_enabled == x.turbulence)
	if x.turbulence:
		_eq("%s turbulence_influence_min" % n, m.turbulence_influence_min, x.turb[0])
		_eq("%s turbulence_influence_max" % n, m.turbulence_influence_max, x.turb[1])

	# Colour ramp.
	var gt := m.color_ramp as GradientTexture1D
	_check("%s color_ramp is GradientTexture1D" % n, gt != null and gt.gradient != null, str(m.color_ramp))
	if gt and gt.gradient:
		var g := gt.gradient
		_check("%s color ramp has %d stops" % [n, x.ramp_offsets.size()],
				g.get_point_count() == x.ramp_offsets.size(), str(g.get_point_count()))
		for i in mini(g.get_point_count(), x.ramp_offsets.size()):
			_eq("%s ramp stop %d offset" % [n, i], g.get_offset(i), x.ramp_offsets[i])
			_check("%s ramp stop %d colour %s" % [n, i, x.ramp_colors[i]],
					_color_close(g.get_color(i), x.ramp_colors[i]), str(g.get_color(i)))

	# Scale curve.
	var ct := m.scale_curve as CurveTexture
	_check("%s scale_curve is CurveTexture" % n, ct != null and ct.curve != null, str(m.scale_curve))
	if ct and ct.curve:
		var c := ct.curve
		_eq("%s Curve.max_value" % n, c.max_value, x.curve_max)
		_check("%s scale curve has %d points" % [n, x.curve_points.size()],
				c.point_count == x.curve_points.size(), str(c.point_count))
		for i in mini(c.point_count, x.curve_points.size()):
			_check("%s scale curve point %d = %s" % [n, i, x.curve_points[i]],
					c.get_point_position(i).is_equal_approx(x.curve_points[i]), str(c.get_point_position(i)))


# --- helpers -----------------------------------------------------------------

func _check(name: String, ok: bool, detail: String = "") -> void:
	if ok:
		passed += 1
		print("PASS %s" % name)
	else:
		failed += 1
		print("FAIL %s  %s" % [name, detail])


func _eq(name: String, got: float, want: float) -> void:
	_check("%s = %s" % [name, want], absf(got - want) <= EPS, "got %s" % got)


func _color_close(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) <= COLOR_EPS and absf(a.g - b.g) <= COLOR_EPS \
			and absf(a.b - b.b) <= COLOR_EPS and absf(a.a - b.a) <= COLOR_EPS


func _is_stored(obj: Object, prop: String) -> bool:
	for p in obj.get_property_list():
		if p.name == prop:
			return (p.usage & PROPERTY_USAGE_STORAGE) != 0
	return false
