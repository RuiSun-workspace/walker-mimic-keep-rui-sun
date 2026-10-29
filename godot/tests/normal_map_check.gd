extends SceneTree
## Normal-map convention check (CHANGE-BRIEF.md §8 and Failure 5).
##   godot --headless --path godot --script res://tests/normal_map_check.gd --fixed-fps 60
## Prints one PASS/FAIL line per check and exits 1 on any failure.
##
## curl_ratio() and its helpers are copied unchanged from the CSYE 7270 Assignment 5 text
## (Step 3, "The normal-map check"). A real tangent-space normal map stores the slopes of a
## surface, so its two mixed partial derivatives agree: ~0 in the right green convention,
## ~2 in the wrong one, ~1 when no surface is behind it. Flat or compressed maps drift towards 1.
##
## The threshold comes from the Poly Haven gl/dx pair of the same texture, whose conventions are
## known (CHANGE-BRIEF.md revision 2026-10-28 C): halfway between the pair's worse
## right-convention score and 1.0, the score of a map with no surface behind it. So a bound map
## fails if it is in the wrong convention or has no surface behind it. The halfway point between
## the right and wrong scores is no use as a threshold: for one image the two scores always sum to
## 2, since (t1 - t2)^2 + (t1 + t2)^2 = 2(t1^2 + t2^2), so it is always 1.0.
## The maps are read as imported (RGTC, red and green only), which is what the GPU samples.
## The shields' bound normal maps are checked only once a ShaderMaterial on them declares a
## `hint_normal` sampler.

const GL := "res://assets/textures/wood_planks/wood_planks_nor_gl_1k.png"
const DX := "res://assets/textures/wood_planks/wood_planks_nor_dx_1k.png"
const SHIELD_ROOM := "res://showcase/shield_room.tscn"
const NO_SURFACE := 1.0           # curl_ratio of a map with no surface behind it (assignment text)

var passed := 0
var failed := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var gl := _imported_image(GL)
	var dx := _imported_image(DX)
	var gl_as_gl := curl_ratio(gl, false)
	var gl_as_dx := curl_ratio(gl, true)
	var dx_as_gl := curl_ratio(dx, false)
	var dx_as_dx := curl_ratio(dx, true)
	print("INFO curl_ratio  nor_gl: directx=false %.4f  directx=true %.4f" % [gl_as_gl, gl_as_dx])
	print("INFO curl_ratio  nor_dx: directx=false %.4f  directx=true %.4f" % [dx_as_gl, dx_as_dx])

	# Calibration. If these come out reversed, the sign convention is backwards.
	_check("calibration: nor_gl scores lower read as OpenGL (directx = false)", gl_as_gl < gl_as_dx,
		"%.4f vs %.4f" % [gl_as_gl, gl_as_dx])
	_check("calibration: nor_dx scores lower read as DirectX (directx = true)", dx_as_dx < dx_as_gl,
		"%.4f vs %.4f" % [dx_as_dx, dx_as_gl])
	var right_max := maxf(gl_as_gl, dx_as_dx)
	_check("calibration: the known-good pair scores below %.1f (a surface is behind it)" % NO_SURFACE,
		right_max < NO_SURFACE, "%.4f" % right_max)
	var threshold := (right_max + NO_SURFACE) / 2.0
	print("INFO threshold from the pair: (%.4f + %.1f) / 2 = %.4f" % [right_max, NO_SURFACE, threshold])

	_check_shields(threshold)

	print("normal_map_check: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


## Each shield whose ShaderMaterial declares a `hint_normal` sampler: the texture bound to it,
## read as OpenGL (what Godot expects), must score below the threshold.
func _check_shields(threshold: float) -> void:
	var room := (load(SHIELD_ROOM) as PackedScene).instantiate()
	for shield_name in ["ShieldA", "ShieldB"]:
		var mi := room.get_node(shield_name) as MeshInstance3D
		var mat := mi.get_surface_override_material(0) as ShaderMaterial
		if mat == null or mat.shader == null:
			print("INFO %s has no ShaderMaterial yet; its normal map is not checked" % shield_name)
			continue
		var names := _hint_normal_samplers(mat.shader.code)
		_check("%s: the shader declares exactly one hint_normal sampler" % shield_name, names.size() == 1,
			str(names))
		if names.size() != 1:
			continue
		var tex := mat.get_shader_parameter(names[0]) as Texture2D
		_check("%s: a texture is bound to %s" % [shield_name, names[0]], tex != null)
		if tex == null:
			continue
		var r := curl_ratio(tex.get_image(), false)
		_check("%s: %s read as OpenGL, curl_ratio %.4f < %.4f" % [shield_name, tex.resource_path.get_file(), r, threshold],
			r < threshold)
	room.free()


## Names of `uniform sampler2D <name> : ... hint_normal ...;` in the shader source.
func _hint_normal_samplers(code: String) -> PackedStringArray:
	var re := RegEx.create_from_string("uniform\\s+sampler2D\\s+(\\w+)\\s*:[^;]*\\bhint_normal\\b")
	var out := PackedStringArray()
	for m in re.search_all(code):
		out.append(m.get_string(1))
	return out


func _imported_image(path: String) -> Image:
	return (load(path) as Texture2D).get_image()


func _check(name: String, ok: bool, detail: String = "") -> void:
	if ok:
		passed += 1
		print("PASS %s" % name)
	else:
		failed += 1
		print("FAIL %s  %s" % [name, detail])


# --- from the assignment text, unchanged -------------------------------------

# ~0: slope field of a real surface in this convention.
# ~1: no surface behind it.
# ~2: real surface, other green convention.
static func curl_ratio(source: Image, directx := false, stride := 4) -> float:
	var img := source.duplicate() as Image
	if img.is_compressed():
		img.decompress()
	var s: float = -1.0 if directx else 1.0
	var curl_sq := 0.0
	var terms_sq := 0.0
	for v in range(1, img.get_height() - 1, stride):
		for u in range(1, img.get_width() - 1, stride):
			var t1 := (_dh_du(img, u, v + 1) - _dh_du(img, u, v - 1)) * 0.5
			var t2 := (_dh_dv(img, u + 1, v, s) - _dh_dv(img, u - 1, v, s)) * 0.5
			curl_sq += (t1 - t2) * (t1 - t2)
			terms_sq += t1 * t1 + t2 * t2
	return curl_sq / maxf(terms_sq, 1e-12)


static func _normal(img: Image, u: int, v: int) -> Vector3:
	var c := img.get_pixel(u, v)
	return Vector3(c.r, c.g, c.b) * 2.0 - Vector3.ONE


static func _dh_du(img: Image, u: int, v: int) -> float:
	var n := _normal(img, u, v)
	return -n.x / maxf(n.z, 0.05)


static func _dh_dv(img: Image, u: int, v: int, s: float) -> float:
	var n := _normal(img, u, v)
	return s * n.y / maxf(n.z, 0.05)
