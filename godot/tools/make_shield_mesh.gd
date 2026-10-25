extends SceneTree
## Builds the Shield Goblin's wooden heater shield as an ArrayMesh resource.
## The front face gets planar UVs over the whole 0..1 square, so a texture maps onto it once,
## undistorted. Tangents are generated because a normal map needs them.
##   godot --headless --path godot --script res://tools/make_shield_mesh.gd

const OUT := "res://showcase/shield_mesh.tres"
const WIDTH := 0.8          # m
const HEIGHT := 1.0         # m, top edge to bottom point
const THICK := 0.05         # m
const CURVE_STEPS := 12


func _init() -> void:
	var outline := _outline()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var zf := THICK / 2.0
	var tris := Geometry2D.triangulate_polygon(outline)
	for i in range(0, tris.size(), 3):
		var a := outline[tris[i]]
		var b := outline[tris[i + 1]]
		var c := outline[tris[i + 2]]
		_tri(st, _v(a, zf), _v(b, zf), _v(c, zf), Vector3.BACK, [_uv(a), _uv(b), _uv(c)])
		_tri(st, _v(a, -zf), _v(b, -zf), _v(c, -zf), Vector3.FORWARD, [_uv_back(a), _uv_back(b), _uv_back(c)])
	var perimeter := 0.0
	for i in outline.size():
		perimeter += outline[i].distance_to(outline[(i + 1) % outline.size()])
	var run := 0.0
	for i in outline.size():
		var a := outline[i]
		var b := outline[(i + 1) % outline.size()]
		var d := b - a
		var outward := Vector3(d.y, -d.x, 0).normalized()   # outline is counter-clockwise
		var u0 := run / perimeter
		run += d.length()
		var u1 := run / perimeter
		var rim := 0.04                                    # the rim samples a thin band of the texture
		_tri(st, _v(a, zf), _v(b, zf), _v(b, -zf), outward, [Vector2(u0, 0), Vector2(u1, 0), Vector2(u1, rim)])
		_tri(st, _v(a, zf), _v(b, -zf), _v(a, -zf), outward, [Vector2(u0, 0), Vector2(u1, rim), Vector2(u0, rim)])
	st.generate_tangents()
	var mesh := st.commit()
	mesh.resource_name = "shield"
	var err := ResourceSaver.save(mesh, OUT)
	print("%s %s: %d vertices" % ["wrote" if err == OK else "FAILED", OUT, mesh.surface_get_array_len(0)])
	quit(0 if err == OK else 1)


## Heater shield, counter-clockwise, y up, origin at the centre of the shape's bounding box.
func _outline() -> PackedVector2Array:
	var hw := WIDTH / 2.0
	var top := HEIGHT / 2.0
	var shoulder := 0.05
	var tip := Vector2(0, -top)
	var pts := PackedVector2Array()
	pts.append(Vector2(-hw, top))
	pts.append(Vector2(-hw, shoulder))
	for i in range(1, CURVE_STEPS):                        # left curve down to the tip
		pts.append(_bezier(Vector2(-hw, shoulder), Vector2(-hw, -0.3), tip, float(i) / CURVE_STEPS))
	pts.append(tip)
	for i in range(1, CURVE_STEPS):                        # right curve back up
		pts.append(_bezier(tip, Vector2(hw, -0.3), Vector2(hw, shoulder), float(i) / CURVE_STEPS))
	pts.append(Vector2(hw, shoulder))
	pts.append(Vector2(hw, top))
	return pts


func _bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	return p0.lerp(p1, t).lerp(p1.lerp(p2, t), t)


func _v(p: Vector2, z: float) -> Vector3:
	return Vector3(p.x, p.y, z)


func _uv(p: Vector2) -> Vector2:
	return Vector2(p.x / WIDTH + 0.5, 0.5 - p.y / HEIGHT)


func _uv_back(p: Vector2) -> Vector2:
	return Vector2(0.5 - p.x / WIDTH, 0.5 - p.y / HEIGHT)


## Adds one triangle facing `normal`. Godot treats clockwise-as-seen-from-the-front as the front
## face, so the order is swapped when the geometric normal points toward the viewer.
func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, normal: Vector3, uvs: Array) -> void:
	var order := [0, 1, 2]
	if (b - a).cross(c - a).dot(normal) > 0.0:
		order = [0, 2, 1]
	var verts := [a, b, c]
	for k in order:
		st.set_normal(normal)
		st.set_uv(uvs[k])
		st.add_vertex(verts[k])
