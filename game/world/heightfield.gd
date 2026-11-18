class_name Heightfield
extends RefCounted
## Smooth sand ground for the big open regions. A region gives a function
## from (x, z) to height; this samples it on a grid, builds one mesh and one
## collision shape from the same triangles, and answers height_at() exactly
## as the mesh has it.

var size: float = 300.0
var cells: int = 96
var raw: Callable
var tint: Callable
var grid: PackedFloat32Array = PackedFloat32Array()


func _init(world_size: float, grid_cells: int, height_fn: Callable, tint_fn: Callable) -> void:
	size = world_size
	cells = grid_cells
	raw = height_fn
	tint = tint_fn
	var n := cells + 1
	grid.resize(n * n)
	var step := size / float(cells)
	for iz in range(n):
		for ix in range(n):
			grid[iz * n + ix] = float(raw.call(-size * 0.5 + float(ix) * step, -size * 0.5 + float(iz) * step))


func _h(ix: int, iz: int) -> float:
	var n := cells + 1
	return grid[clampi(iz, 0, cells) * n + clampi(ix, 0, cells)]


func grid_height(x: float, z: float) -> float:
	var step := size / float(cells)
	return _h(int(round((x + size * 0.5) / step)), int(round((z + size * 0.5) / step)))


func height_at(x: float, z: float) -> float:
	var step := size / float(cells)
	var fx := clampf((x + size * 0.5) / step, 0.0, float(cells) - 0.0001)
	var fz := clampf((z + size * 0.5) / step, 0.0, float(cells) - 0.0001)
	var ix := int(floor(fx))
	var iz := int(floor(fz))
	var u := fx - float(ix)
	var v := fz - float(iz)
	var h00 := _h(ix, iz)
	var h10 := _h(ix + 1, iz)
	var h11 := _h(ix + 1, iz + 1)
	var h01 := _h(ix, iz + 1)
	if (ix + iz) % 2 == 0:
		if u >= v:
			return h00 + u * (h10 - h00) + v * (h11 - h10)
		return h00 + u * (h11 - h01) + v * (h01 - h00)
	if u + v <= 1.0:
		return h00 + u * (h10 - h00) + v * (h01 - h00)
	return h11 + (1.0 - u) * (h01 - h11) + (1.0 - v) * (h10 - h11)


func normal(x: float, z: float) -> Vector3:
	var e := size / float(cells)
	return Vector3(grid_height(x - e, z) - grid_height(x + e, z), 2.0 * e, grid_height(x, z - e) - grid_height(x, z + e)).normalized()


func build(parent: Node3D, grain_kind: String = "sand", grain_scale: float = 0.5) -> MeshInstance3D:
	var made := ForgeMesh.terrain(size, cells, grid_height, tint, normal)
	var m: Material
	if Detail.KINDS.has(grain_kind):
		m = Detail.ground(grain_kind)
	else:
		var gm := ForgeMesh.grain(Color(1, 1, 1), grain_kind, grain_scale)
		gm.vertex_color_use_as_albedo = true
		gm.cull_mode = BaseMaterial3D.CULL_BACK
		m = gm
	var mi := ForgeMesh.inst(made[0], m, parent)
	mi.name = "Ground"
	var body := StaticBody3D.new()
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(made[1])
	shape.backface_collision = true
	var col := CollisionShape3D.new()
	col.shape = shape
	body.add_child(col)
	body.collision_layer = 1
	parent.add_child(body)
	return mi


## A smooth blend toward `target` inside radius r, fading out by r * fade.
static func flatten(h: float, x: float, z: float, cx: float, cz: float, r: float, target: float, fade: float = 1.9) -> float:
	var d := Vector2(x - cx, z - cz).length()
	var k := 1.0 - smoothstep(r, r * fade, d)
	return lerpf(h, target, k)
