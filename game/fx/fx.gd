extends Node
## Everything that makes a hit feel like a hit: hit-stop, shake, slashes,
## rings, sparks, afterimages. Effects are small nodes that fade and free
## themselves. `quiet` turns off hit-stop for headless tests.

var root: Node3D
var quiet: bool = false
var shake: float = 0.0
var blur: float = 0.0
var flash: Color = Color(1, 1, 1, 0)
var spawned: Dictionary = {}

var _stopping: bool = false
var _stop_until: int = 0
var _font: Font


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if ResourceLoader.exists("res://assets/fonts/Cinzel.ttf"):
		_font = load("res://assets/fonts/Cinzel.ttf")


func _process(delta: float) -> void:
	var real := delta / maxf(Engine.time_scale, 0.01)
	shake = move_toward(shake, 0.0, real * 2.6)
	blur = move_toward(blur, 0.0, real * 2.4)
	flash.a = move_toward(flash.a, 0.0, real * 3.2)
	if _stopping and Time.get_ticks_msec() >= _stop_until:
		Engine.time_scale = 1.0
		_stopping = false


func _ok() -> bool:
	return root != null and is_instance_valid(root) and root.is_inside_tree()


func _note(kind: String) -> void:
	spawned[kind] = int(spawned.get(kind, 0)) + 1


func hitstop(seconds: float) -> void:
	if quiet:
		return
	Engine.time_scale = 0.05
	_stop_until = maxi(_stop_until, Time.get_ticks_msec() + int(seconds * 1000.0))
	_stopping = true


func add_shake(amount: float) -> void:
	shake = minf(1.2, shake + amount)


func add_blur(amount: float) -> void:
	blur = minf(1.0, maxf(blur, amount))


func screen_flash(color: Color, strength: float = 0.35) -> void:
	flash = Color(color.r, color.g, color.b, strength)


func _fade(node: Node3D, mat: StandardMaterial3D, life: float, grow: Vector3 = Vector3.ONE) -> void:
	var tw := node.create_tween()
	tw.set_parallel(true)
	tw.tween_property(mat, "albedo_color:a", 0.0, life).set_ease(Tween.EASE_IN)
	if grow != Vector3.ONE:
		tw.tween_property(node, "scale", node.scale * grow, life).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.chain().tween_callback(node.queue_free)


## A brush-stroke arc where a blade passed. `at` faces -Z; roll it for angle.
func slash(at: Transform3D, radius: float, arc_deg: float, color: Color, life: float = 0.18, width: float = 0.75) -> void:
	_note("slash")
	if not _ok():
		return
	var m := ForgeMesh.ghost(Color(color.r, color.g, color.b, 0.95))
	var mi := ForgeMesh.inst(ForgeMesh.arc(maxf(0.05, radius - width), radius, arc_deg), m, root)
	mi.global_transform = at
	mi.scale = Vector3.ONE * 0.8
	_fade(mi, m, life, Vector3.ONE * 1.3)
	# a white core makes the stroke read on any background
	var m2 := ForgeMesh.ghost(Color(1, 1, 1, 0.9))
	var core := ForgeMesh.inst(ForgeMesh.arc(maxf(0.05, radius - width * 0.35), radius * 0.985, arc_deg * 0.86), m2, root)
	core.global_transform = at
	core.scale = Vector3.ONE * 0.8
	_fade(core, m2, life * 0.7, Vector3.ONE * 1.3)


func ring(pos: Vector3, color: Color, r0: float, r1: float, life: float = 0.4, inner: float = 0.86) -> void:
	_note("ring")
	if not _ok():
		return
	var m := ForgeMesh.ghost(Color(color.r, color.g, color.b, 0.9))
	var mi := ForgeMesh.inst(ForgeMesh.ring(inner), m, root)
	mi.global_position = pos
	mi.scale = Vector3(r0, 1.0, r0)
	_fade(mi, m, life, Vector3(r1 / maxf(r0, 0.01), 1.0, r1 / maxf(r0, 0.01)))


func sparks(pos: Vector3, color: Color, count: int = 10, speed: float = 9.0) -> void:
	_note("sparks")
	if not _ok():
		return
	var p := CPUParticles3D.new()
	p.mesh = ForgeMesh.shard(0.34, 0.03, 3)
	p.material_override = ForgeMesh.ghost(color)
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = count
	p.lifetime = 0.42
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, -16, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.4
	p.particle_flag_align_y = true
	root.add_child(p)
	p.global_position = pos
	p.emitting = true
	var tw := p.create_tween()
	tw.tween_interval(0.9)
	tw.tween_callback(p.queue_free)


func puff(pos: Vector3, color: Color = Color(0.8, 0.8, 0.82, 0.5), count: int = 8, size: float = 0.5) -> void:
	_note("puff")
	if not _ok():
		return
	var p := CPUParticles3D.new()
	p.mesh = ForgeMesh.box(Vector3.ONE * size * 0.4)
	p.material_override = ForgeMesh.ghost(color, false)
	p.one_shot = true
	p.explosiveness = 0.9
	p.amount = count
	p.lifetime = 0.7
	p.direction = Vector3.UP
	p.spread = 80.0
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 3.2
	p.gravity = Vector3(0, -2.5, 0)
	p.scale_amount_min = 0.4
	p.scale_amount_max = 1.3
	p.angular_velocity_max = 180.0
	var curve := Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	p.scale_amount_curve = curve
	root.add_child(p)
	p.global_position = pos
	p.emitting = true
	var tw := p.create_tween()
	tw.tween_interval(1.2)
	tw.tween_callback(p.queue_free)


## A still copy of a body's blocks, left behind by a dash.
func ghost(body: Node3D, color: Color, life: float = 0.28) -> void:
	_note("ghost")
	if not _ok() or body == null:
		return
	var holder := Node3D.new()
	root.add_child(holder)
	var m := ForgeMesh.ghost(Color(color.r, color.g, color.b, 0.26))
	for n: Node in body.find_children("*", "MeshInstance3D", true, false):
		var src: MeshInstance3D = n
		if not src.is_visible_in_tree() or src.has_meta("no_ghost"):
			continue
		var mi := MeshInstance3D.new()
		mi.mesh = src.mesh
		mi.material_override = m
		holder.add_child(mi)
		mi.global_transform = src.global_transform
	var tw := holder.create_tween()
	tw.tween_property(m, "albedo_color:a", 0.0, life)
	tw.tween_callback(holder.queue_free)


func pillar(pos: Vector3, color: Color, height: float = 26.0, radius: float = 1.6, life: float = 1.2) -> void:
	_note("pillar")
	if not _ok():
		return
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	mesh.rings = 1
	mesh.cap_top = false
	mesh.cap_bottom = false
	var m := ForgeMesh.ghost(Color(color.r, color.g, color.b, 0.8))
	var mi := ForgeMesh.inst(mesh, m, root)
	mi.global_position = pos + Vector3(0, height * 0.5, 0)
	_fade(mi, m, life, Vector3(0.15, 1.0, 0.15))
	var m2 := ForgeMesh.ghost(Color(1, 1, 1, 0.9))
	var core := ForgeMesh.inst(mesh, m2, root)
	core.global_position = mi.global_position
	core.scale = Vector3(0.45, 1.0, 0.45)
	_fade(core, m2, life * 0.8, Vector3(0.1, 1.0, 0.1))


## A word that rises off a body: PARRY, BROKEN, a number.
func word(pos: Vector3, text: String, color: Color, size: float = 1.0) -> void:
	_note("word")
	if not _ok():
		return
	var l := Label3D.new()
	l.text = text
	l.font = _font
	l.font_size = int(72 * size)
	l.pixel_size = 0.0055
	l.modulate = color
	l.outline_size = 14
	l.outline_modulate = Color(0, 0, 0, 0.9)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.fixed_size = false
	root.add_child(l)
	l.global_position = pos
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "global_position", pos + Vector3(0, 1.1, 0), 0.7).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(l, "modulate:a", 0.0, 0.7).set_ease(Tween.EASE_IN)
	tw.tween_property(l, "outline_modulate:a", 0.0, 0.7).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(l.queue_free)


## A red or pale circle on the ground that warns where a blow will land.
func warn(pos: Vector3, radius: float, color: Color, life: float) -> void:
	_note("warn")
	if not _ok():
		return
	var m := ForgeMesh.ghost(Color(color.r, color.g, color.b, 0.0), false)
	var mi := ForgeMesh.inst(ForgeMesh.ring(0.0, 24), m, root)
	mi.global_position = pos + Vector3(0, 0.06, 0)
	mi.scale = Vector3(radius, 1.0, radius)
	var tw := mi.create_tween()
	tw.tween_property(m, "albedo_color:a", 0.45, life)
	tw.tween_callback(mi.queue_free)


## A blow landing. `weight` (0 to 1) is how much of the body it took: a
## big share stops time longer, shakes harder and throws more sparks.
func impact(pos: Vector3, color: Color, heavy: bool = false, weight: float = -1.0) -> void:
	var w := clampf(weight, 0.0, 1.0) if weight >= 0.0 else (0.5 if heavy else 0.2)
	sparks(pos, color, int(8.0 + 14.0 * w), 8.0 + 6.0 * w)
	ring(pos, color, 0.2, 1.4 + 2.0 * w, 0.22)
	add_shake(0.2 + 0.5 * w)
	hitstop(0.04 + 0.08 * w)


func parry_burst(pos: Vector3, color: Color) -> void:
	sparks(pos, Color(1, 1, 1), 18, 14.0)
	ring(pos, Color(1, 1, 1), 0.2, 3.4, 0.28, 0.9)
	ring(pos, color, 0.1, 2.2, 0.36, 0.7)
	add_shake(0.55)
	add_blur(0.5)
	screen_flash(Color(1, 1, 1), 0.22)
	hitstop(0.11)
