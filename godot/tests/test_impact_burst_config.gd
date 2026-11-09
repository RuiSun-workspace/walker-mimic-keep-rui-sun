extends SceneTree
## Configuration test for Effect A, the Arrow Impact Burst (CHANGE-BRIEF.md §3, A1 and A2).
## Loads godot/effects/impact_burst.tscn and reads back every setting the brief names from the loaded
## nodes and resources; the expected values are the brief's.
##   bash scripts/run-test.sh test_impact_burst_config.gd 60
## Prints one PASS/FAIL line per check and exits 1 on any failure. Headless: this proves the
## configuration, not the look (CLAUDE.md, headless facts).

const SCENE_PATH := "res://effects/impact_burst.tscn"
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
	var burst := packed.instantiate()
	root.add_child(burst)
	await process_frame

	_check("root is Node2D", burst is Node2D, burst.get_class())
	var emitters := burst.get_children().filter(func(n): return n is GPUParticles2D or n is CPUParticles2D)
	_check("root holds exactly two emitters", emitters.size() == 2, str(emitters.size()))

	_check_emitter(burst.get_node_or_null("Flash"), {
		"name": "A1 Flash",
		"amount": 10, "lifetime": 0.28,
		"radius": 3.0, "spread": 180.0,
		"vel": [80.0, 140.0], "gravity": Vector3(0, 100, 0),
		"damping": [30.0, 50.0], "scale": [0.5, 1.1],
		"angle": [0.0, 0.0],
		"ramp_offsets": [0.0, 0.35, 1.0],
		"ramp_colors": [Color(1.0, 1.0, 0.80, 0.60), Color(1.0, 0.55, 0.08, 0.55), Color(1.0, 0.25, 0.02, 0.0)],
		"curve_points": [Vector2(0, 0.35), Vector2(0.33, 1.20), Vector2(1, 0)],
		"curve_max": 1.5,
		"texture": "res://effects/textures/soft_dot.png", "tex_size": Vector2i(16, 16),
		"blend": CanvasItemMaterial.BLEND_MODE_ADD,
		"vis": Rect2(-64, -64, 128, 128),
	})
	_check_emitter(burst.get_node_or_null("Straw"), {
		"name": "A2 Straw",
		"amount": 12, "lifetime": 0.80,
		"radius": 5.0, "spread": 40.0,
		"vel": [70.0, 130.0], "gravity": Vector3(0, 260, 0),
		"damping": [5.0, 15.0], "scale": [0.4, 0.9],
		"angle": [0.0, 360.0],
		"ramp_offsets": [0.0, 0.5, 1.0],
		"ramp_colors": [Color(0.91, 0.77, 0.42, 1.0), Color(0.55, 0.36, 0.16, 0.90), Color(0.30, 0.18, 0.08, 0.0)],
		"curve_points": [Vector2(0, 0.70), Vector2(0.15, 1.0), Vector2(1, 0)],
		"curve_max": 1.0,
		"texture": "res://effects/textures/straw_chip.png", "tex_size": Vector2i(4, 12),
		"blend": CanvasItemMaterial.BLEND_MODE_MIX,
		"vis": Rect2(-96, -96, 192, 192),
	})

	# Rule A5: the straw (0.80 s) is the longest emitter, so its `finished` ends the burst.
	var flash := burst.get_node_or_null("Flash") as GPUParticles2D
	var straw := burst.get_node_or_null("Straw") as GPUParticles2D
	if flash and straw:
		_check("A5 straw is the longest-lived emitter", straw.lifetime > flash.lifetime,
				"%s vs %s" % [straw.lifetime, flash.lifetime])

	# Nothing exists before a hit: no emission one frame after loading (Rule A1, preprocess 0).
	for e in emitters:
		_check("%s still not emitting after one frame" % e.name, not e.emitting)

	_finish()


func _finish() -> void:
	print("test_impact_burst_config: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


# --- one emitter -------------------------------------------------------------

func _check_emitter(node: Node, x: Dictionary) -> void:
	var n: String = x.name
	_check("%s exists as GPUParticles2D" % n, node is GPUParticles2D, "got %s" % (node.get_class() if node else "null"))
	if not node is GPUParticles2D:
		return
	var p := node as GPUParticles2D

	# Node: emission and simulation settings.
	_check("%s emitting = false" % n, p.emitting == false)
	_check("%s amount = %d" % [n, x.amount], p.amount == x.amount, str(p.amount))
	_check("%s one_shot = true" % n, p.one_shot == true)
	_eq("%s explosiveness" % n, p.explosiveness, 1.0)
	_eq("%s lifetime" % n, p.lifetime, x.lifetime)
	_eq("%s preprocess" % n, p.preprocess, 0.0)
	_check("%s local_coords = false" % n, p.local_coords == false)
	_check("%s visibility_rect = %s" % [n, x.vis], p.visibility_rect.is_equal_approx(x.vis), str(p.visibility_rect))
	_eq("%s amount_ratio (not used by A)" % n, p.amount_ratio, 1.0)

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
	for prop in ["particle_flag_disable_z", "emission_shape", "emission_sphere_radius", "direction", "spread",
			"gravity", "initial_velocity_min", "initial_velocity_max", "damping_min", "damping_max",
			"scale_min", "scale_max", "angle_min", "angle_max", "color_ramp", "scale_curve", "turbulence_enabled"]:
		_check("%s %s is a stored property" % [n, prop], _is_stored(m, prop))
	_check("%s particle_flag_disable_z = true" % n, m.particle_flag_disable_z == true)
	_check("%s emission_shape = SPHERE" % n, m.emission_shape == ParticleProcessMaterial.EMISSION_SHAPE_SPHERE,
			str(m.emission_shape))
	_eq("%s emission_sphere_radius" % n, m.emission_sphere_radius, x.radius)
	_check("%s direction = (0, -1, 0)" % n, m.direction.is_equal_approx(Vector3(0, -1, 0)), str(m.direction))
	_eq("%s spread" % n, m.spread, x.spread)
	_check("%s gravity = %s" % [n, x.gravity], m.gravity.is_equal_approx(x.gravity), str(m.gravity))
	_eq("%s initial_velocity_min" % n, m.initial_velocity_min, x.vel[0])
	_eq("%s initial_velocity_max" % n, m.initial_velocity_max, x.vel[1])
	_eq("%s damping_min" % n, m.damping_min, x.damping[0])
	_eq("%s damping_max" % n, m.damping_max, x.damping[1])
	_eq("%s scale_min" % n, m.scale_min, x.scale[0])
	_eq("%s scale_max" % n, m.scale_max, x.scale[1])
	_eq("%s angle_min" % n, m.angle_min, x.angle[0])
	_eq("%s angle_max" % n, m.angle_max, x.angle[1])
	_check("%s turbulence_enabled = false (not used by A)" % n, m.turbulence_enabled == false)

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
