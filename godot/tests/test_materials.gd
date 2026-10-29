extends SceneTree
## Material audit checks (godot/MATERIALS.md, CHANGE-BRIEF.md §7-8 and Failure 4).
##   godot --headless --path godot --script res://tests/test_materials.gd --fixed-fps 60
## Pins the audited tables: which scene node uses which material, each material's shader,
## uniform values and bound textures, each sampler's hints as written in the source, each
## uniform's type, group, hint and default, the uniform list the engine reports, each texture's
## import settings, and the lights, camera and environment of the two scenes. For each normal
## map it decodes the source PNG and prints curl_ratio under both conventions.
## Headless draws nothing: this proves what the renderer is given, not what it shows.
## Prints one PASS/FAIL line per check and exits 1 on any failure.

const NormalMapCheck := preload("res://tests/normal_map_check.gd")

const WOOD_SHADER := "res://shaders/shield_wood.gdshader"
const HINT_SHADER := "res://shaders/hint_experiment.gdshader"
const SHIELD_ROOM := "res://showcase/shield_room.tscn"
const HINT_SCENE := "res://showcase/hint_experiment.tscn"
const SHIELD_MESH := "res://showcase/shield_mesh.tres"
const SHIELD_NEW := "res://showcase/shield_new.tres"
const SHIELD_BURNED := "res://showcase/shield_burned.tres"
const HINT_SRGB := "res://showcase/hint_source_color.tres"
const HINT_RAW := "res://showcase/hint_raw.tres"

const DIFF := "res://assets/textures/wood_planks/wood_planks_diff_1k.png"
const ROUGH := "res://assets/textures/wood_planks/wood_planks_rough_1k.png"
const NOR_GL := "res://assets/textures/wood_planks/wood_planks_nor_gl_1k.png"
const NOR_DX := "res://assets/textures/wood_planks/wood_planks_nor_dx_1k.png"
const SCORCH := "res://assets/textures/shield_scorch_mask.png"
const GREYS := "res://assets/textures/hint_greys_3x1.png"

const EPS := 1e-6

## Every uniform as declared in the source: [type, group, hints as written, default as written].
const WOOD_UNIFORMS := {
	"wood_albedo_texture": ["sampler2D", "", "source_color, filter_linear_mipmap, repeat_enable", ""],
	"wood_roughness_texture": ["sampler2D", "", "filter_linear_mipmap, repeat_enable", ""],
	"wood_normal_texture": ["sampler2D", "", "hint_normal, filter_linear_mipmap, repeat_enable", ""],
	"scorch_mask_texture": ["sampler2D", "", "filter_linear_mipmap, repeat_disable", ""],
	"wood_tint": ["vec4", "Surface", "source_color", "vec4(1.0, 1.0, 1.0, 1.0)"],
	"texture_scale": ["float", "Surface", "hint_range(0.25, 4.0, 0.05)", "1.0"],
	"roughness_scale": ["float", "Surface", "hint_range(0.0, 1.0, 0.01)", "0.85"],
	"normal_strength": ["float", "Surface", "hint_range(0.0, 1.0, 0.01)", "1.0"],
	"scorch_amount": ["float", "Damage", "hint_range(0.0, 1.0, 0.01)", "0.0"],
	"scorch_color": ["vec4", "Damage", "source_color", "vec4(0.08, 0.025, 0.01, 1.0)"],
	"char_roughness": ["float", "Damage", "hint_range(0.0, 1.0, 0.01)", "0.95"],
}
const HINT_UNIFORMS := {
	"source_color_texture": ["sampler2D", "", "source_color, filter_nearest, repeat_disable", ""],
	"raw_texture": ["sampler2D", "", "filter_nearest, repeat_disable", ""],
	"use_source_color": ["bool", "", "", "true"],
}

## What each material sets. null: not set in the file, so the shader default applies.
const SHIELD_NEW_PARAMS := {
	"wood_albedo_texture": DIFF,
	"wood_roughness_texture": ROUGH,
	"wood_normal_texture": NOR_GL,
	"scorch_mask_texture": SCORCH,
	"wood_tint": Color(1, 1, 1, 1),
	"texture_scale": 1.0,
	"roughness_scale": 0.75,
	"normal_strength": 0.8,
	"scorch_amount": 0.05,
	"scorch_color": null,
	"char_roughness": 0.95,
}
const SHIELD_BURNED_PARAMS := {
	"wood_albedo_texture": DIFF,
	"wood_roughness_texture": ROUGH,
	"wood_normal_texture": NOR_GL,
	"scorch_mask_texture": SCORCH,
	"wood_tint": Color(0.72, 0.5, 0.34, 1),
	"texture_scale": 1.0,
	"roughness_scale": 0.95,
	"normal_strength": 1.15,
	"scorch_amount": 0.7,
	"scorch_color": null,
	"char_roughness": 0.98,
}
const HINT_SRGB_PARAMS := {
	"source_color_texture": GREYS,
	"raw_texture": GREYS,
	"use_source_color": true,
}
const HINT_RAW_PARAMS := {
	"source_color_texture": GREYS,
	"raw_texture": GREYS,
	"use_source_color": false,
}

## [compress/mode, compress/normal_map, mipmaps/generate] from each .import file.
## compress/mode: 0 Lossless, 2 VRAM Compressed. compress/normal_map: 1 Enable, 2 Disable.
const IMPORTS := {
	DIFF: [2, 2, true],
	ROUGH: [2, 2, true],
	NOR_GL: [2, 1, true],
	NOR_DX: [2, 1, true],
	SCORCH: [0, 2, true],
	GREYS: [0, 2, false],
}

var passed := 0
var failed := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_check("project renderer is forward_plus",
		ProjectSettings.get_setting("rendering/renderer/rendering_method") == "forward_plus",
		str(ProjectSettings.get_setting("rendering/renderer/rendering_method")))

	var room := (load(SHIELD_ROOM) as PackedScene).instantiate()
	var hint := (load(HINT_SCENE) as PackedScene).instantiate()

	var new_mat := _node_material(room, "ShieldA", SHIELD_NEW)
	var burned_mat := _node_material(room, "ShieldB", SHIELD_BURNED)
	var srgb_mat := _node_material(hint, "QuadSourceColor", HINT_SRGB)
	var raw_mat := _node_material(hint, "QuadRaw", HINT_RAW)
	if new_mat == null or burned_mat == null or srgb_mat == null or raw_mat == null:
		_finish(room, hint)
		return

	_check("ShieldA and ShieldB have different ShaderMaterial objects", new_mat != burned_mat)
	_check("both shield materials reference %s" % WOOD_SHADER,
		new_mat.shader.resource_path == WOOD_SHADER and burned_mat.shader.resource_path == WOOD_SHADER,
		"%s, %s" % [new_mat.shader.resource_path, burned_mat.shader.resource_path])
	_check("both shield materials share one Shader object", new_mat.shader == burned_mat.shader)
	_check("both hint materials reference %s" % HINT_SHADER,
		srgb_mat.shader.resource_path == HINT_SHADER and raw_mat.shader.resource_path == HINT_SHADER,
		"%s, %s" % [srgb_mat.shader.resource_path, raw_mat.shader.resource_path])

	_check_source(WOOD_SHADER, new_mat.shader, WOOD_UNIFORMS)
	_check_source(HINT_SHADER, srgb_mat.shader, HINT_UNIFORMS)
	_check_failure_4(WOOD_UNIFORMS)
	_check_uniform_list(WOOD_SHADER, new_mat.shader, WOOD_UNIFORMS)
	_check_uniform_list(HINT_SHADER, srgb_mat.shader, HINT_UNIFORMS)

	_check_params(SHIELD_NEW, new_mat, SHIELD_NEW_PARAMS)
	_check_params(SHIELD_BURNED, burned_mat, SHIELD_BURNED_PARAMS)
	_check_params(HINT_SRGB, srgb_mat, HINT_SRGB_PARAMS)
	_check_params(HINT_RAW, raw_mat, HINT_RAW_PARAMS)

	for path in IMPORTS:
		_check_import(path, IMPORTS[path])

	_check_shield_mesh(room)
	_check_shield_room_lighting(room)
	_check_hint_lighting(hint)
	_check_greys()
	_check_normal_maps(new_mat, burned_mat)

	_finish(room, hint)


func _finish(room: Node, hint: Node) -> void:
	room.free()
	hint.free()
	print("test_materials: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


## The node's surface override 0 must be the ShaderMaterial loaded from `path`.
func _node_material(scene: Node, node_name: String, path: String) -> ShaderMaterial:
	var mi := scene.get_node_or_null(node_name) as MeshInstance3D
	var mat: ShaderMaterial = null
	if mi != null:
		mat = mi.get_surface_override_material(0) as ShaderMaterial
	var ok := mat != null and mat.shader != null and mat.resource_path == path
	_check("%s surface_material_override/0 is %s" % [node_name, path], ok,
		"got %s" % (mat.resource_path if mat != null else "no ShaderMaterial"))
	return mat if ok else null


# --- shader source text ---------------------------------------------------------

## Every `uniform` in the source, in order: name -> [type, group, hints, default].
## Comments are stripped and whitespace collapsed, so hints compare as written.
func _parse_uniforms(code: String) -> Dictionary:
	code = RegEx.create_from_string("/\\*[\\s\\S]*?\\*/").sub(code, " ", true)
	code = RegEx.create_from_string("//[^\\n]*").sub(code, " ", true)
	var ws := RegEx.create_from_string("\\s+")
	var group_re := RegEx.create_from_string("^group_uniforms\\s*(\\w*)$")
	var uniform_re := RegEx.create_from_string(
		"^uniform (\\w+) (\\w+)(?: ?: ?([^=]*?))?(?: ?= ?(.*))?$")
	var out := {}
	var group := ""
	for stmt in code.split(";"):
		var s := ws.sub(stmt, " ", true).strip_edges()
		var g := group_re.search(s)
		if g != null:
			group = g.get_string(1)
			continue
		var m := uniform_re.search(s)
		if m != null:
			out[m.get_string(2)] = [m.get_string(1), group, m.get_string(3), m.get_string(4)]
	return out


func _check_source(path: String, shader: Shader, expected: Dictionary) -> void:
	var file := FileAccess.get_file_as_string(path)
	_check("%s: Shader.code is the file on disk" % path.get_file(), shader.code == file)
	var found := _parse_uniforms(file)
	_check("%s: declares exactly %s" % [path.get_file(), str(expected.keys())],
		_same_keys(found, expected), str(found.keys()))
	for name in expected:
		var e: Array = expected[name]
		var f: Array = found.get(name, [])
		var what := "hints [%s]" % e[2] if e[0] == "sampler2D" else "hint [%s] default [%s]" % [e[2], e[3]]
		_check("%s: %s %s in group [%s], %s" % [path.get_file(), e[0], name, e[1], what], f == e, str(f))


## CHANGE-BRIEF Failure 4: only the albedo sampler is sRGB-decoded; the data samplers are not.
func _check_failure_4(expected: Dictionary) -> void:
	var found := _parse_uniforms(FileAccess.get_file_as_string(WOOD_SHADER))
	for name in ["wood_albedo_texture", "wood_roughness_texture", "wood_normal_texture", "scorch_mask_texture"]:
		var hints := PackedStringArray()
		for h in (found.get(name, ["", "", "", ""])[2] as String).split(","):
			hints.append(h.strip_edges())
		var want: bool = name == "wood_albedo_texture"
		_check("Failure 4: %s %s source_color" % [name, "has" if want else "has no"],
			hints.has("source_color") == want, str(hints))


## The engine's view: get_shader_uniform_list() names, types and range hints. Defaults are not
## reported headlessly (CLAUDE.md, Headless facts), so they come from the source text above.
func _check_uniform_list(path: String, shader: Shader, expected: Dictionary) -> void:
	var list := shader.get_shader_uniform_list()
	var by_name := {}
	for u in list:
		by_name[u.name] = u
		print("INFO %s uniform list: %s type %d hint %d hint_string \"%s\"" % [
			path.get_file(), u.name, u.type, u.hint, u.hint_string])
	_check("%s: get_shader_uniform_list() reports exactly the declared uniforms" % path.get_file(),
		_same_keys(by_name, expected), str(by_name.keys()))
	for name in expected:
		var e: Array = expected[name]
		if not by_name.has(name):
			continue
		var u: Dictionary = by_name[name]
		var want_type: int = {"sampler2D": TYPE_OBJECT, "float": TYPE_FLOAT, "bool": TYPE_BOOL,
			"vec4": TYPE_COLOR if (e[2] as String).contains("source_color") else TYPE_VECTOR4}[e[0]]
		_check("%s: %s reported as %s" % [path.get_file(), name, type_string(want_type)],
			u.type == want_type, type_string(u.type))
		if e[0] == "sampler2D":
			_check("%s: %s reported as a Texture2D resource" % [path.get_file(), name],
				u.hint == PROPERTY_HINT_RESOURCE_TYPE and u.hint_string == "Texture2D",
				"hint %d \"%s\"" % [u.hint, u.hint_string])
		elif (e[2] as String).begins_with("hint_range("):
			var src := (e[2] as String).trim_prefix("hint_range(").trim_suffix(")").split(",")
			var rep := (u.hint_string as String).split(",")
			var same: bool = u.hint == PROPERTY_HINT_RANGE and rep.size() >= src.size()
			for i in src.size():
				same = same and is_equal_approx(float(src[i]), float(rep[i]))
			_check("%s: %s reported with range %s" % [path.get_file(), name, e[2]], same,
				"hint %d \"%s\"" % [u.hint, u.hint_string])


# --- materials --------------------------------------------------------------------

func _check_params(path: String, mat: ShaderMaterial, expected: Dictionary) -> void:
	# The .tres text: which parameters the file sets. An undeclared name would raise no error.
	var text := FileAccess.get_file_as_string(path)
	var set_re := RegEx.create_from_string("(?m)^shader_parameter/(\\w+)\\s*=")
	var in_file := {}
	for m in set_re.search_all(text):
		in_file[m.get_string(1)] = true
	var want_set := {}
	for name in expected:
		if expected[name] != null:
			want_set[name] = true
	_check("%s: sets exactly %s" % [path.get_file(), str(want_set.keys())],
		_same_keys(in_file, want_set), str(in_file.keys()))
	for name in expected:
		var want = expected[name]
		var got = mat.get_shader_parameter(name)
		var ok := false
		if want == null:
			ok = got == null
		elif want is String:
			ok = got is Texture2D and (got as Texture2D).resource_path == want
		elif want is float:
			ok = (got is float or got is int) and absf(got - want) < EPS
		elif want is Color:
			ok = got is Color and (got as Color).is_equal_approx(want)
		else:
			ok = typeof(got) == typeof(want) and got == want
		var shown = "not set (shader default)" if want == null else want
		var got_shown = (got as Texture2D).resource_path if got is Texture2D else got
		_check("%s: %s = %s" % [path.get_file(), name, shown], ok, "got %s" % str(got_shown))


func _check_import(path: String, want: Array) -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(path + ".import")
	_check("%s.import loads" % path.get_file(), err == OK, error_string(err))
	if err != OK:
		return
	_check("%s.import: source_file is the PNG" % path.get_file(),
		cfg.get_value("deps", "source_file", "") == path, str(cfg.get_value("deps", "source_file", "")))
	var got := [cfg.get_value("params", "compress/mode", null), cfg.get_value("params", "compress/normal_map", null),
		cfg.get_value("params", "mipmaps/generate", null)]
	_check("%s.import: compress/mode=%d compress/normal_map=%d mipmaps/generate=%s"
		% [path.get_file(), want[0], want[1], want[2]], got == want, str(got))


# --- scenes -------------------------------------------------------------------------

func _check_shield_mesh(room: Node) -> void:
	for shield_name in ["ShieldA", "ShieldB"]:
		var mi := room.get_node(shield_name) as MeshInstance3D
		_check("%s mesh is %s" % [shield_name, SHIELD_MESH], mi.mesh.resource_path == SHIELD_MESH,
			mi.mesh.resource_path)
	var mesh := load(SHIELD_MESH) as Mesh
	var fmt: int = mesh.surface_get_format(0)
	_check("shield mesh has UVs and tangents (normal map needs both)",
		(fmt & Mesh.ARRAY_FORMAT_TEX_UV) != 0 and (fmt & Mesh.ARRAY_FORMAT_TANGENT) != 0, str(fmt))
	_check("shield mesh resource declares no material", mesh.surface_get_material(0) == null)


func _check_shield_room_lighting(room: Node) -> void:
	var lights := room.find_children("*", "Light3D", true, false)
	_check("shield room has exactly one Light3D", lights.size() == 1, str(lights.size()))
	var sun := room.get_node("Sun") as DirectionalLight3D
	_check("Sun is a DirectionalLight3D, energy 1.2, white, shadows on",
		sun != null and is_equal_approx(sun.light_energy, 1.2) and sun.light_color == Color(1, 1, 1, 1)
			and sun.shadow_enabled)
	var sun_xf := Transform3D(Basis(Vector3(0.866025, 0, -0.5), Vector3(-0.25, 0.866025, -0.433013),
		Vector3(0.433013, 0.5, 0.75)), Vector3(0, 3, 0))
	_check("Sun transform is the scene's", sun.transform.is_equal_approx(sun_xf), str(sun.transform))
	print("INFO Sun shines along %s" % str(-sun.transform.basis.z))

	var cam := room.get_node("Camera3D") as Camera3D
	_check("shield room camera at (0, 0.65, 2.3), fov 45, perspective, no CameraAttributes",
		cam.position.is_equal_approx(Vector3(0, 0.65, 2.3)) and is_equal_approx(cam.fov, 45.0)
			and cam.projection == Camera3D.PROJECTION_PERSPECTIVE and cam.attributes == null)

	var env := (room.get_node("WorldEnvironment") as WorldEnvironment).environment
	_check("shield room background: colour (0.32, 0.36, 0.42)",
		env.background_mode == Environment.BG_COLOR
			and env.background_color.is_equal_approx(Color(0.32, 0.36, 0.42, 1)))
	_check("shield room ambient: colour source, white, energy 0.3",
		env.ambient_light_source == Environment.AMBIENT_SOURCE_COLOR
			and env.ambient_light_color == Color(1, 1, 1, 1) and is_equal_approx(env.ambient_light_energy, 0.3))
	_check_tonemap("shield room", env)
	_check_effects_off("shield room", env)


func _check_hint_lighting(hint: Node) -> void:
	_check("hint scene has no Light3D (both quads unshaded)",
		hint.find_children("*", "Light3D", true, false).is_empty())
	var cam := hint.get_node("Camera3D") as Camera3D
	_check("hint camera at (0, 0, 2), fov 45, no CameraAttributes",
		cam.position.is_equal_approx(Vector3(0, 0, 2)) and is_equal_approx(cam.fov, 45.0)
			and cam.attributes == null)
	var env := (hint.get_node("WorldEnvironment") as WorldEnvironment).environment
	_check("hint background: black colour",
		env.background_mode == Environment.BG_COLOR and env.background_color == Color(0, 0, 0, 1))
	_check_tonemap("hint scene", env)
	_check_effects_off("hint scene", env)


func _check_tonemap(label: String, env: Environment) -> void:
	_check("%s tonemap Linear, exposure 1.0, white 1.0" % label,
		env.tonemap_mode == Environment.TONE_MAPPER_LINEAR and is_equal_approx(env.tonemap_exposure, 1.0)
			and is_equal_approx(env.tonemap_white, 1.0),
		"mode %d exposure %f white %f" % [env.tonemap_mode, env.tonemap_exposure, env.tonemap_white])


func _check_effects_off(label: String, env: Environment) -> void:
	var on := []
	for prop in ["glow_enabled", "fog_enabled", "volumetric_fog_enabled", "adjustment_enabled",
			"ssao_enabled", "ssil_enabled", "ssr_enabled", "sdfgi_enabled"]:
		if env.get(prop):
			on.append(prop)
	_check("%s: glow, fog, volumetric fog, adjustments, SSAO, SSIL, SSR, SDFGI all off" % label,
		on.is_empty(), str(on))


# --- images -----------------------------------------------------------------------

## CHANGE-BRIEF §7: the experiment image holds the greys 64, 128, 192.
func _check_greys() -> void:
	var img := Image.load_from_file(ProjectSettings.globalize_path(GREYS))
	var got := []
	if img != null:
		for x in img.get_width():
			var c := img.get_pixel(x, 0)
			got.append([c.r8, c.g8, c.b8])
	_check("hint_greys_3x1.png source texels are 64, 128, 192",
		got == [[64, 64, 64], [128, 128, 128], [192, 192, 192]], str(got))


## Each normal map's source PNG, decoded (not the RGTC import), under both conventions.
func _check_normal_maps(new_mat: ShaderMaterial, burned_mat: ShaderMaterial) -> void:
	var scores := {}
	for path in [NOR_GL, NOR_DX]:
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		_check("%s decodes from the source file" % path.get_file(), img != null and not img.is_empty())
		if img == null or img.is_empty():
			return
		var as_gl := NormalMapCheck.curl_ratio(img, false)
		var as_dx := NormalMapCheck.curl_ratio(img, true)
		scores[path] = [as_gl, as_dx]
		print("INFO curl_ratio %s (source PNG, %dx%d, format %d): directx=false %.4f  directx=true %.4f"
			% [path.get_file(), img.get_width(), img.get_height(), img.get_format(), as_gl, as_dx])
	_check("source nor_gl scores lower read as OpenGL", scores[NOR_GL][0] < scores[NOR_GL][1])
	_check("source nor_dx scores lower read as DirectX", scores[NOR_DX][1] < scores[NOR_DX][0])
	# Same rule as normal_map_check.gd (CHANGE-BRIEF revision C), applied to the source pair.
	var threshold := (maxf(scores[NOR_GL][0], scores[NOR_DX][1]) + 1.0) / 2.0
	for mat in [new_mat, burned_mat]:
		var bound := (mat.get_shader_parameter("wood_normal_texture") as Texture2D).resource_path
		var r: float = scores[bound][0] if scores.has(bound) else 1.0
		_check("%s: bound normal map %s read as OpenGL, curl_ratio %.4f < %.4f"
			% [mat.resource_path.get_file(), bound.get_file(), r, threshold], r < threshold)


# --- helpers ----------------------------------------------------------------------

func _same_keys(a: Dictionary, b: Dictionary) -> bool:
	if a.size() != b.size():
		return false
	for k in b:
		if not a.has(k):
			return false
	return true


func _check(name: String, ok: bool, detail: String = "") -> void:
	if ok:
		passed += 1
		print("PASS %s" % name)
	else:
		failed += 1
		print("FAIL %s  %s" % [name, detail])
