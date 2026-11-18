class_name ForgeMesh
extends RefCounted
## Every shape in the game is built here from code: flat-shaded, low-poly,
## no imported models. Front faces wind clockwise; each triangle is turned to
## face `outward` and carries that face normal, so shading is always faceted.

class Builder:
	var st: SurfaceTool = SurfaceTool.new()
	var xf: Transform3D = Transform3D.IDENTITY
	var col: Color = Color.WHITE
	var tris: int = 0

	func _init() -> void:
		st.begin(Mesh.PRIMITIVE_TRIANGLES)

	func tri(a: Vector3, b: Vector3, c: Vector3, outward: Vector3) -> void:
		a = xf * a
		b = xf * b
		c = xf * c
		var n := (c - a).cross(b - a)
		if n.length_squared() < 1e-14:
			return
		if n.dot(xf.basis * outward) < 0.0:
			var t := b
			b = c
			c = t
			n = -n
		n = n.normalized()
		for v: Vector3 in [a, b, c]:
			st.set_normal(n)
			st.set_color(col)
			st.add_vertex(v)
		tris += 1

	func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, outward: Vector3) -> void:
		tri(a, b, c, outward)
		tri(a, c, d, outward)

	## A triangle with its own corner normals, for smooth surfaces.
	func tri_n(a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3) -> void:
		a = xf * a
		b = xf * b
		c = xf * c
		na = (xf.basis * na).normalized()
		nb = (xf.basis * nb).normalized()
		nc = (xf.basis * nc).normalized()
		var n := (c - a).cross(b - a)
		if n.length_squared() < 1e-14:
			return
		if n.dot(na + nb + nc) < 0.0:
			var t := b
			b = c
			c = t
			var tn := nb
			nb = nc
			nc = tn
		st.set_normal(na); st.set_color(col); st.add_vertex(a)
		st.set_normal(nb); st.set_color(col); st.add_vertex(b)
		st.set_normal(nc); st.set_color(col); st.add_vertex(c)
		tris += 1

	## A plain part: a box centred on `at`, turned by `rot` (degrees).
	func box(size: Vector3, at: Vector3 = Vector3.ZERO, rot: Vector3 = Vector3.ZERO) -> void:
		var keep := xf
		var r := Basis.from_euler(Vector3(deg_to_rad(rot.x), deg_to_rad(rot.y), deg_to_rad(rot.z)))
		xf = keep * Transform3D(r, at)
		frustum(Vector2(size.x, size.z), Vector2(size.x, size.z), -size.y * 0.5, size.y * 0.5)
		xf = keep

	## A wedge part: a ramp that rises toward +Z.
	func wedge(size: Vector3, at: Vector3 = Vector3.ZERO, rot: Vector3 = Vector3.ZERO) -> void:
		var keep := xf
		var r := Basis.from_euler(Vector3(deg_to_rad(rot.x), deg_to_rad(rot.y), deg_to_rad(rot.z)))
		xf = keep * Transform3D(r, at)
		var hx := size.x * 0.5
		var hy := size.y * 0.5
		var hz := size.z * 0.5
		var a0 := Vector3(-hx, -hy, -hz)
		var a1 := Vector3(hx, -hy, -hz)
		var b0 := Vector3(-hx, -hy, hz)
		var b1 := Vector3(hx, -hy, hz)
		var c0 := Vector3(-hx, hy, hz)
		var c1 := Vector3(hx, hy, hz)
		quad(a0, a1, b1, b0, Vector3.DOWN)
		quad(b0, b1, c1, c0, Vector3.BACK)
		quad(a0, a1, c1, c0, Vector3(0, hz, -hy))
		tri(a0, b0, c0, Vector3.LEFT)
		tri(a1, b1, c1, Vector3.RIGHT)
		xf = keep

	## A round column with smooth sides, like a cylinder part.
	func column(r0: float, r1: float, y0: float, y1: float, sides: int = 16) -> void:
		var slope := (r0 - r1) / maxf(0.0001, y1 - y0)
		for i in range(sides):
			var a0 := TAU * float(i) / float(sides)
			var a1 := TAU * float(i + 1) / float(sides)
			var d0 := Vector3(cos(a0), 0.0, sin(a0))
			var d1 := Vector3(cos(a1), 0.0, sin(a1))
			var n0 := (d0 + Vector3(0, slope, 0)).normalized()
			var n1 := (d1 + Vector3(0, slope, 0)).normalized()
			var p00 := d0 * r0 + Vector3(0, y0, 0)
			var p10 := d1 * r0 + Vector3(0, y0, 0)
			var p11 := d1 * r1 + Vector3(0, y1, 0)
			var p01 := d0 * r1 + Vector3(0, y1, 0)
			tri_n(p00, p10, p11, n0, n1, n1)
			tri_n(p00, p11, p01, n0, n1, n0)
			tri(Vector3(0, y1, 0), p01, p11, Vector3.UP)
			tri(Vector3(0, y0, 0), p00, p10, Vector3.DOWN)

	## A box whose top and bottom can differ in size and be offset.
	func frustum(bottom: Vector2, top: Vector2, y0: float, y1: float, top_shift: Vector2 = Vector2.ZERO, bottom_shift: Vector2 = Vector2.ZERO) -> void:
		var bx := bottom.x * 0.5
		var bz := bottom.y * 0.5
		var tx := top.x * 0.5
		var tz := top.y * 0.5
		var bs := Vector3(bottom_shift.x, 0.0, bottom_shift.y)
		var ts := Vector3(top_shift.x, 0.0, top_shift.y)
		var b0 := Vector3(-bx, y0, -bz) + bs
		var b1 := Vector3(bx, y0, -bz) + bs
		var b2 := Vector3(bx, y0, bz) + bs
		var b3 := Vector3(-bx, y0, bz) + bs
		var t0 := Vector3(-tx, y1, -tz) + ts
		var t1 := Vector3(tx, y1, -tz) + ts
		var t2 := Vector3(tx, y1, tz) + ts
		var t3 := Vector3(-tx, y1, tz) + ts
		quad(b0, b1, b2, b3, Vector3.DOWN)
		quad(t0, t1, t2, t3, Vector3.UP)
		quad(b0, b1, t1, t0, Vector3.FORWARD)
		quad(b2, b3, t3, t2, Vector3.BACK)
		quad(b1, b2, t2, t1, Vector3.RIGHT)
		quad(b3, b0, t0, t3, Vector3.LEFT)

	## Extrudes an XY outline along Z from z0 to z1.
	func prism(profile: PackedVector2Array, z0: float, z1: float) -> void:
		var idx := Geometry2D.triangulate_polygon(profile)
		for i in range(0, idx.size(), 3):
			var p0 := profile[idx[i]]
			var p1 := profile[idx[i + 1]]
			var p2 := profile[idx[i + 2]]
			tri(Vector3(p0.x, p0.y, z1), Vector3(p1.x, p1.y, z1), Vector3(p2.x, p2.y, z1), Vector3.BACK)
			tri(Vector3(p0.x, p0.y, z0), Vector3(p1.x, p1.y, z0), Vector3(p2.x, p2.y, z0), Vector3.FORWARD)
		var sign_ccw := -1.0 if Geometry2D.is_polygon_clockwise(profile) else 1.0
		var n := profile.size()
		for i in range(n):
			var a := profile[i]
			var b := profile[(i + 1) % n]
			var e := b - a
			var out := Vector3(e.y, -e.x, 0.0) * sign_ccw
			quad(Vector3(a.x, a.y, z0), Vector3(b.x, b.y, z0), Vector3(b.x, b.y, z1), Vector3(a.x, a.y, z1), out)

	## A faceted spike from a base to a tip.
	func spike(base: Vector3, tip: Vector3, radius: float, sides: int = 4, twist: float = 0.0) -> void:
		var axis := (tip - base).normalized()
		var side := axis.cross(Vector3.UP)
		if side.length_squared() < 0.001:
			side = axis.cross(Vector3.RIGHT)
		side = side.normalized()
		var up := side.cross(axis).normalized()
		var ring: Array[Vector3] = []
		for i in range(sides):
			var a := twist + TAU * float(i) / float(sides)
			ring.append(base + (side * cos(a) + up * sin(a)) * radius)
		for i in range(sides):
			var p := ring[i]
			var q := ring[(i + 1) % sides]
			tri(p, q, tip, (p + q) * 0.5 - base)
			tri(p, q, base, -axis)

	## A many-sided frustum around the Y axis.
	func round_frustum(r0: float, r1: float, y0: float, y1: float, sides: int = 8, cap: bool = true) -> void:
		for i in range(sides):
			var a0 := TAU * float(i) / float(sides)
			var a1 := TAU * float(i + 1) / float(sides)
			var d0 := Vector3(cos(a0), 0.0, sin(a0))
			var d1 := Vector3(cos(a1), 0.0, sin(a1))
			var out := (d0 + d1)
			quad(d0 * r0 + Vector3(0, y0, 0), d1 * r0 + Vector3(0, y0, 0), d1 * r1 + Vector3(0, y1, 0), d0 * r1 + Vector3(0, y1, 0), out)
			if cap:
				tri(Vector3(0, y1, 0), d0 * r1 + Vector3(0, y1, 0), d1 * r1 + Vector3(0, y1, 0), Vector3.UP)
				tri(Vector3(0, y0, 0), d0 * r0 + Vector3(0, y0, 0), d1 * r0 + Vector3(0, y0, 0), Vector3.DOWN)

	func commit() -> ArrayMesh:
		return st.commit()


static var _cache: Dictionary = {}


static func _keyed(key: String, make: Callable) -> ArrayMesh:
	if not _cache.has(key):
		_cache[key] = make.call()
	return _cache[key]


## A limb segment hanging down from the origin.
static func limb(top: Vector2, bottom: Vector2, length: float) -> ArrayMesh:
	var key := "limb|%s|%s|%.3f" % [top, bottom, length]
	return _keyed(key, func() -> ArrayMesh:
		var b := Builder.new()
		b.frustum(bottom, top, -length, 0.0)
		return b.commit())


## A block rising from the origin.
static func block(bottom: Vector2, top: Vector2, height: float, shift: Vector2 = Vector2.ZERO) -> ArrayMesh:
	var key := "block|%s|%s|%.3f|%s" % [bottom, top, height, shift]
	return _keyed(key, func() -> ArrayMesh:
		var b := Builder.new()
		b.frustum(bottom, top, 0.0, height, shift)
		return b.commit())


static func box(size: Vector3) -> ArrayMesh:
	var key := "box|%s" % size
	return _keyed(key, func() -> ArrayMesh:
		var b := Builder.new()
		b.frustum(Vector2(size.x, size.z), Vector2(size.x, size.z), -size.y * 0.5, size.y * 0.5)
		return b.commit())


## A flat ribbon arc in the XZ plane, opening toward -Z. For slashes.
static func arc(inner: float, outer: float, arc_deg: float, segs: int = 10) -> ArrayMesh:
	var key := "arc|%.2f|%.2f|%.1f" % [inner, outer, arc_deg]
	return _keyed(key, func() -> ArrayMesh:
		var b := Builder.new()
		var half := deg_to_rad(arc_deg) * 0.5
		for i in range(segs):
			var t0 := float(i) / float(segs)
			var t1 := float(i + 1) / float(segs)
			var a0 := lerpf(-half, half, t0)
			var a1 := lerpf(-half, half, t1)
			# the ribbon thins toward both ends, like a brush stroke
			var w0 := sin(t0 * PI)
			var w1 := sin(t1 * PI)
			var i0 := lerpf(outer, inner, w0)
			var i1 := lerpf(outer, inner, w1)
			var d0 := Vector3(sin(a0), 0.0, -cos(a0))
			var d1 := Vector3(sin(a1), 0.0, -cos(a1))
			b.quad(d0 * i0, d1 * i1, d1 * outer, d0 * outer, Vector3.UP)
		return b.commit())


## A flat ring of outer radius 1 in the XZ plane.
static func ring(inner: float = 0.86, segs: int = 28) -> ArrayMesh:
	var key := "ring|%.2f|%d" % [inner, segs]
	return _keyed(key, func() -> ArrayMesh:
		var b := Builder.new()
		for i in range(segs):
			var a0 := TAU * float(i) / float(segs)
			var a1 := TAU * float(i + 1) / float(segs)
			var d0 := Vector3(cos(a0), 0.0, sin(a0))
			var d1 := Vector3(cos(a1), 0.0, sin(a1))
			b.quad(d0 * inner, d1 * inner, d1, d0, Vector3.UP)
		return b.commit())


static func shard(length: float, radius: float, sides: int = 4) -> ArrayMesh:
	var key := "shard|%.2f|%.2f|%d" % [length, radius, sides]
	return _keyed(key, func() -> ArrayMesh:
		var b := Builder.new()
		b.spike(Vector3(0, length * 0.3, 0), Vector3(0, length, 0), radius, sides)
		b.spike(Vector3(0, length * 0.3, 0), Vector3(0, 0, 0), radius, sides)
		return b.commit())


## A rock: two or three slate blocks jammed together at odd angles.
static func rock(r: RandomNumberGenerator, size: float) -> ArrayMesh:
	var b := Builder.new()
	var count := 2 + int(r.randi() % 2)
	for i in range(count):
		var sz := Vector3(r.randf_range(0.8, 1.5), r.randf_range(0.6, 1.2), r.randf_range(0.8, 1.5)) * size * (1.0 - 0.22 * float(i))
		var at := Vector3(r.randf_range(-0.4, 0.4), sz.y * 0.3 + 0.2 * size * float(i), r.randf_range(-0.4, 0.4)) * (size if i > 0 else 0.0) + Vector3(0, sz.y * 0.25, 0)
		b.box(sz, at, Vector3(r.randf_range(-16, 16), r.randf_range(0, 90), r.randf_range(-16, 16)))
	return b.commit()


## A dead tree built from square beams.
static func dead_tree(r: RandomNumberGenerator, height: float) -> ArrayMesh:
	var b := Builder.new()
	var w := height * 0.07
	var lean := Vector3(r.randf_range(-5, 5), r.randf_range(0, 90), r.randf_range(-5, 5))
	b.box(Vector3(w, height * 0.6, w), Vector3(0, height * 0.3, 0), lean)
	var top := Vector3(0, height * 0.58, 0)
	var limbs := 3 + int(r.randi() % 3)
	for i in range(limbs):
		var yaw := 360.0 * float(i) / float(limbs) + r.randf_range(-30, 30)
		var tilt := r.randf_range(32, 62)
		var length := height * r.randf_range(0.28, 0.46)
		var rot := Basis.from_euler(Vector3(0, deg_to_rad(yaw), 0)) * Basis.from_euler(Vector3(0, 0, deg_to_rad(tilt)))
		var start := top - Vector3(0, height * 0.1 * float(i % 3), 0)
		var mid := start + rot * Vector3(0, length * 0.5, 0)
		b.xf = Transform3D(rot, mid)
		b.frustum(Vector2(w * 0.7, w * 0.7), Vector2(w * 0.7, w * 0.7), -length * 0.5, length * 0.5)
		# a twig off each limb
		var tip := start + rot * Vector3(0, length, 0)
		var rot2 := rot * Basis.from_euler(Vector3(deg_to_rad(r.randf_range(-50, 50)), 0, deg_to_rad(r.randf_range(-70, -30))))
		var tl := length * 0.5
		b.xf = Transform3D(rot2, tip + rot2 * Vector3(0, tl * 0.5, 0))
		b.frustum(Vector2(w * 0.45, w * 0.45), Vector2(w * 0.45, w * 0.45), -tl * 0.5, tl * 0.5)
		b.xf = Transform3D.IDENTITY
	return b.commit()


## A column part on a square plinth, snapped off below its capital.
static func pillar(r: RandomNumberGenerator, height: float, width: float) -> ArrayMesh:
	var b := Builder.new()
	b.box(Vector3(width * 1.5, height * 0.06, width * 1.5), Vector3(0, height * 0.03, 0))
	b.box(Vector3(width * 1.25, height * 0.04, width * 1.25), Vector3(0, height * 0.08, 0))
	b.column(width * 0.5, width * 0.5, height * 0.1, height * 0.86, 16)
	if r.randf() < 0.55:
		b.box(Vector3(width * 1.3, height * 0.05, width * 1.3), Vector3(0, height * 0.885, 0))
		b.box(Vector3(width * 1.55, height * 0.07, width * 1.55), Vector3(0, height * 0.945, 0))
	else:
		b.box(Vector3(width * 0.8, height * 0.1, width * 0.7), Vector3(r.randf_range(-0.1, 0.1) * width, height * 0.89, 0), Vector3(r.randf_range(-14, 14), r.randf_range(0, 90), r.randf_range(-14, 14)))
	return b.commit()


## A plain block standing on the ground. `taper` is kept for old callers
## and ignored: parts are square.
static func slab(size: Vector3, _taper: float = 1.0) -> ArrayMesh:
	var b := Builder.new()
	b.box(size, Vector3(0, size.y * 0.5, 0))
	return b.commit()


## A wing of long flat plates fanned in the XY plane.
static func wing(r: RandomNumberGenerator, span: float, feathers: int = 7, side: float = 1.0) -> ArrayMesh:
	var b := Builder.new()
	for i in range(feathers):
		var t := float(i) / float(feathers - 1)
		var ang := lerpf(55.0, -75.0, t)
		var length := span * lerpf(0.55, 1.0, sin(t * PI * 0.9 + 0.2)) * r.randf_range(0.9, 1.05)
		var a := deg_to_rad(ang)
		var dir := Vector3(cos(a) * side, sin(a), 0.0)
		var mid := dir * (span * 0.12 + length * 0.5)
		var rot_z := ang if side > 0.0 else 180.0 - ang
		b.box(Vector3(length, span * 0.13, span * 0.05), mid + Vector3(0, 0, 0.03 * span * float(i % 2)), Vector3(0, 0, rot_z))
	return b.commit()


## A bell: stepped rings around Y, mouth down, crown at the origin.
static func bell(radius: float, height: float) -> ArrayMesh:
	var b := Builder.new()
	b.round_frustum(radius * 0.25, radius * 0.2, -height * 0.08, 0.0, 8)
	b.round_frustum(radius * 0.62, radius * 0.3, -height * 0.45, -height * 0.08, 8)
	b.round_frustum(radius * 0.8, radius * 0.62, -height * 0.85, -height * 0.45, 8)
	b.round_frustum(radius, radius * 0.8, -height, -height * 0.85, 8)
	return b.commit()


## Terrain from a height function, one flat-shaded quad pair per cell.
## Returns [mesh, PackedVector3Array faces] so collision uses the same shape.
static func terrain(size: float, cells: int, height_at: Callable, tint_at: Callable, normal_at: Callable = Callable()) -> Array:
	var b := Builder.new()
	var faces := PackedVector3Array()
	var step := size / float(cells)
	var half := size * 0.5
	for iz in range(cells):
		for ix in range(cells):
			var x0 := -half + float(ix) * step
			var z0 := -half + float(iz) * step
			var x1 := x0 + step
			var z1 := z0 + step
			var p00 := Vector3(x0, height_at.call(x0, z0), z0)
			var p10 := Vector3(x1, height_at.call(x1, z0), z0)
			var p11 := Vector3(x1, height_at.call(x1, z1), z1)
			var p01 := Vector3(x0, height_at.call(x0, z1), z1)
			var flip := (ix + iz) % 2 == 0
			var tris: Array = [[p00, p10, p11], [p00, p11, p01]] if flip else [[p00, p10, p01], [p10, p11, p01]]
			for t: Variant in tris:
				var tr: Array = t
				var a: Vector3 = tr[0]
				var c: Vector3 = tr[1]
				var d: Vector3 = tr[2]
				var mid := (a + c + d) / 3.0
				b.col = tint_at.call(mid, (d - a).cross(c - a).normalized())
				if normal_at.is_valid():
					b.tri_n(a, c, d, normal_at.call(a.x, a.z), normal_at.call(c.x, c.z), normal_at.call(d.x, d.z))
				else:
					b.tri(a, c, d, Vector3.UP)
				# collision wants clockwise faces too
				var n := (d - a).cross(c - a)
				if n.y >= 0.0:
					faces.append(a); faces.append(c); faces.append(d)
				else:
					faces.append(a); faces.append(d); faces.append(c)
	return [b.commit(), faces]


# ---------------------------------------------------------------- materials

static var _noise: Dictionary = {}


static func _noise_tex(kind: String) -> NoiseTexture2D:
	if _noise.has(kind):
		return _noise[kind]
	var n := FastNoiseLite.new()
	var ramp := Gradient.new()
	if kind == "slate":
		n.noise_type = FastNoiseLite.TYPE_CELLULAR
		n.frequency = 0.035
		n.fractal_octaves = 3
		ramp.set_color(0, Color(0.72, 0.72, 0.72))
		ramp.set_color(1, Color(1, 1, 1))
	else:
		n.noise_type = FastNoiseLite.TYPE_SIMPLEX
		n.frequency = 0.12
		n.fractal_octaves = 4
		ramp.set_color(0, Color(0.88, 0.88, 0.88))
		ramp.set_color(1, Color(1, 1, 1))
	var t := NoiseTexture2D.new()
	t.width = 256
	t.height = 256
	t.seamless = true
	t.noise = n
	t.color_ramp = ramp
	_noise[kind] = t
	return t


## A part material with a faint surface grain, mapped in world space so
## blocks of any size share one scale: "slate" for stone, "sand" for ground.
static func grain(color: Color, kind: String = "slate", scale: float = 0.22) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.albedo_texture = _noise_tex(kind)
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE * scale
	m.roughness = 0.95
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


static func mat(color: Color, rough: float = 0.9, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metal
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


static func glow(color: Color, energy: float = 2.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


## Unshaded, additive, see-through: slashes, rings, afterimages.
static func ghost(color: Color, additive: bool = true) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if additive:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	return m


## Many copies of one mesh in one draw call. For rocks, trees, crystals.
static func scatter(parent: Node3D, mesh: Mesh, material: Material, xforms: Array) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in range(xforms.size()):
		mm.set_instance_transform(i, xforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = material
	parent.add_child(mmi)
	return mmi


static func inst(mesh: Mesh, material: Material, parent: Node3D = null, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	if parent != null:
		parent.add_child(mi)
	return mi
