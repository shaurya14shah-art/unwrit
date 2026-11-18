class_name Gear
extends RefCounted
## What a body carries and wears: blades, masks, hair, horns. Each is cut from
## a seed, so a soul's sealed blade and its released form are its own.

static func _pv(points: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p: Variant in points:
		out.append(p)
	return out


## Maps a profile drawn as (along the blade, across the blade) onto a blade
## that runs along -Z with its edge up and down.
static func _blade_builder() -> ForgeMesh.Builder:
	var b := ForgeMesh.Builder.new()
	b.xf = Transform3D(Basis(Vector3(0, 0, -1), Vector3(0, 1, 0), Vector3(1, 0, 0)), Vector3.ZERO)
	return b


static func _steel(color: Color, lit: float) -> StandardMaterial3D:
	var m := ForgeMesh.mat(Color(0.86, 0.88, 0.92).lerp(color, 0.25 if lit > 0.0 else 0.0), 0.25, 0.7)
	if lit > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = lit
	return m


static func _grip(parent: Node3D, length: float, guard: float, dark: Color) -> void:
	var b := _blade_builder()
	b.prism(_pv([Vector2(-length, -0.02), Vector2(0.0, -0.02), Vector2(0.0, 0.02), Vector2(-length, 0.02)]), -0.02, 0.02)
	b.prism(_pv([Vector2(-0.01, -guard), Vector2(0.03, -guard), Vector2(0.03, guard), Vector2(-0.01, guard)]), -0.045, 0.045)
	ForgeMesh.inst(b.commit(), ForgeMesh.mat(dark, 0.8), parent)


## The sealed blade every soul arrives with: plain, but its length, curve and
## notches come from the seed.
static func sealed_blade(soul_seed: int, tint: Color = Color.WHITE, length_k: float = 1.0, tier: int = 0) -> Node3D:
	var r := Rng.make([soul_seed, "blade"])
	var root := Node3D.new()
	var length := r.randf_range(0.86, 1.08) * length_k
	var curve := r.randf_range(0.0, 0.07)
	var width := r.randf_range(0.055, 0.075)
	var pts: Array = []
	var n := 6
	for i in range(n + 1):
		var t := float(i) / float(n)
		pts.append(Vector2(t * length, width * 0.5 * (1.0 - t * 0.35) + curve * sin(t * PI * 0.5)))
	pts.append(Vector2(length + 0.06, curve * 1.0))
	for i in range(n, -1, -1):
		var t := float(i) / float(n)
		pts.append(Vector2(t * length, -width * 0.5 * (1.0 - t * 0.2) + curve * sin(t * PI * 0.5)))
	var b := _blade_builder()
	b.prism(_pv(pts), -0.008, 0.008)
	var steel := _steel(Color.WHITE, 0.0)
	if tint != Color.WHITE:
		steel = ForgeMesh.mat(Color(0.86, 0.88, 0.92).lerp(tint, 0.55), 0.25, 0.75)
		if tier >= 3:
			# higher-tier forged steel holds a glow in its edge
			steel.emission_enabled = true
			steel.emission = tint
			steel.emission_energy_multiplier = 0.25 * float(tier - 2)
	ForgeMesh.inst(b.commit(), steel, root)
	_grip(root, 0.24, r.randf_range(0.05, 0.08) * (1.0 + 0.12 * float(tier)), Color(0.08, 0.08, 0.1) if tier == 0 else tint.darkened(0.7))
	root.set_meta("reach", 1.0)
	root.scale = Vector3(2.4, 1.8, 1.08)
	return root


## The released weapon. Returns the right-hand piece; a `left` child node, if
## present, belongs in the other hand.
static func released_blade(spec: Dictionary, soul_seed: int) -> Node3D:
	var r := Rng.make([soul_seed, "released"])
	var color := AbilityForge.color_of(spec)
	var form := String(spec.get("form", "greatblade"))
	var root := Node3D.new()
	var steel := _steel(color, 1.4)
	var edge := ForgeMesh.glow(color, 3.5)
	var dark := Color(0.06, 0.06, 0.08)
	var b := _blade_builder()
	match form:
		"greatblade":
			var l := r.randf_range(1.55, 1.8)
			var w := r.randf_range(0.2, 0.26)
			b.prism(_pv([Vector2(0, -w * 0.4), Vector2(l * 0.55, -w * 0.5), Vector2(l * 0.86, -w * 0.5), Vector2(l, w * 0.2),
				Vector2(l * 0.8, w * 0.5), Vector2(l * 0.62, w * 0.28), Vector2(l * 0.5, w * 0.5), Vector2(0, w * 0.4)]), -0.018, 0.018)
			ForgeMesh.inst(b.commit(), steel, root)
			var e := _blade_builder()
			e.prism(_pv([Vector2(0.1, -w * 0.5 - 0.01), Vector2(l * 0.86, -w * 0.5 - 0.012), Vector2(l * 0.86, -w * 0.5 + 0.02), Vector2(0.1, -w * 0.4 + 0.02)]), -0.02, 0.02)
			ForgeMesh.inst(e.commit(), edge, root)
			_grip(root, 0.42, 0.12, dark)
		"twinfang":
			for hand in range(2):
				var holder := root if hand == 0 else Node3D.new()
				if hand == 1:
					holder.name = "left"
					root.add_child(holder)
				var l := r.randf_range(0.6, 0.72)
				var fb := _blade_builder()
				fb.prism(_pv([Vector2(0, -0.035), Vector2(l * 0.6, -0.05), Vector2(l, 0.07), Vector2(l * 0.62, 0.045), Vector2(0, 0.035)]), -0.012, 0.012)
				ForgeMesh.inst(fb.commit(), steel, holder)
				var fe := _blade_builder()
				fe.prism(_pv([Vector2(0.05, -0.05), Vector2(l * 0.6, -0.062), Vector2(l, 0.07), Vector2(l * 0.6, -0.04)]), -0.014, 0.014)
				ForgeMesh.inst(fe.commit(), edge, holder)
				_grip(holder, 0.18, 0.05, dark)
		"glaive":
			var shaft := r.randf_range(1.15, 1.35)
			b.prism(_pv([Vector2(-0.5, -0.018), Vector2(shaft, -0.018), Vector2(shaft, 0.018), Vector2(-0.5, 0.018)]), -0.018, 0.018)
			ForgeMesh.inst(b.commit(), ForgeMesh.mat(dark, 0.7), root)
			var gb := _blade_builder()
			gb.prism(_pv([Vector2(shaft - 0.05, -0.03), Vector2(shaft + 0.35, -0.13), Vector2(shaft + 0.7, 0.05), Vector2(shaft + 0.36, 0.1), Vector2(shaft - 0.05, 0.05)]), -0.014, 0.014)
			ForgeMesh.inst(gb.commit(), steel, root)
			var ge := _blade_builder()
			ge.prism(_pv([Vector2(shaft, -0.045), Vector2(shaft + 0.35, -0.145), Vector2(shaft + 0.7, 0.05), Vector2(shaft + 0.35, -0.1)]), -0.016, 0.016)
			ForgeMesh.inst(ge.commit(), edge, root)
		"chain":
			var segs := 6 + int(r.randi() % 3)
			var x := 0.05
			for i in range(segs):
				var sl := r.randf_range(0.2, 0.27)
				var sw := 0.07 - float(i) * 0.004
				var cb := _blade_builder()
				cb.prism(_pv([Vector2(x, -sw), Vector2(x + sl * 0.8, -sw * 0.8), Vector2(x + sl, 0.0), Vector2(x + sl * 0.8, sw * 0.8), Vector2(x, sw)]), -0.012, 0.012)
				ForgeMesh.inst(cb.commit(), steel if i % 2 == 0 else edge, root)
				x += sl + 0.045
			_grip(root, 0.26, 0.07, dark)
		"gauntlet":
			for hand in range(2):
				var holder := root if hand == 0 else Node3D.new()
				if hand == 1:
					holder.name = "left"
					root.add_child(holder)
				var fist := ForgeMesh.inst(ForgeMesh.box(Vector3(0.24, 0.3, 0.26)), steel, holder, Vector3(0, 0.06, 0))
				fist.rotation_degrees = Vector3(0, 0, 0)
				var kb := ForgeMesh.Builder.new()
				for k in range(3):
					kb.spike(Vector3(-0.08 + 0.08 * float(k), -0.06, -0.1), Vector3(-0.08 + 0.08 * float(k), -0.12, -0.42), 0.035, 4)
				ForgeMesh.inst(kb.commit(), edge, holder)
		"needle":
			var l := r.randf_range(1.2, 1.38)
			b.prism(_pv([Vector2(0, -0.02), Vector2(l * 0.9, -0.012), Vector2(l, 0.0), Vector2(l * 0.9, 0.012), Vector2(0, 0.02)]), -0.01, 0.01)
			ForgeMesh.inst(b.commit(), edge, root)
			var nb := ForgeMesh.Builder.new()
			nb.round_frustum(0.09, 0.03, -0.01, 0.06, 6)
			var cup := ForgeMesh.inst(nb.commit(), steel, root)
			cup.rotation_degrees = Vector3(90, 0, 0)
			_grip(root, 0.2, 0.03, dark)
		_:
			var rad := r.randf_range(0.55, 0.68)
			var pts: Array = []
			var n := 9
			for i in range(n + 1):
				var a := lerpf(-1.25, 1.25, float(i) / float(n))
				pts.append(Vector2(0.25 + cos(a) * rad, sin(a) * rad))
			for i in range(n, -1, -1):
				var a := lerpf(-1.25, 1.25, float(i) / float(n))
				var thick := 0.16 * cos(a * 1.25)
				pts.append(Vector2(0.25 + cos(a) * (rad - thick), sin(a) * (rad - thick * 0.4)))
			b.prism(_pv(pts), -0.014, 0.014)
			ForgeMesh.inst(b.commit(), steel, root)
			_grip(root, 0.22, 0.04, dark)
	root.set_meta("reach", float(spec.get("reach", 1.0)))
	root.scale = Vector3(1.9, 1.35, 1.08)
	return root


## A bow of light, held in the left hand: a curved stave and a glowing string.
static func bow(color: Color, soul_seed: int) -> Node3D:
	var r := Rng.make([soul_seed, "bow"])
	var root := Node3D.new()
	var left := Node3D.new()
	left.name = "left"
	root.add_child(left)
	var stave := ForgeMesh.Builder.new()
	var n := 7
	var span := r.randf_range(1.7, 1.95)
	for i in range(n):
		var t := float(i) / float(n - 1) - 0.5
		var a := t * 2.1
		stave.box(Vector3(0.1, span / float(n) * 1.3, 0.12), Vector3(0, sin(a) * span * 0.5, -0.18 + cos(a) * 0.3), Vector3(-rad_to_deg(a), 0, 0))
	ForgeMesh.inst(stave.commit(), _steel(color, 1.0), left)
	var string := ForgeMesh.Builder.new()
	string.box(Vector3(0.025, span * 0.86, 0.025), Vector3(0, 0, -0.18 + cos(1.05) * 0.3 - 0.02))
	ForgeMesh.inst(string.commit(), ForgeMesh.glow(color, 3.0), left)
	left.rotation_degrees = Vector3(0, 90, 0)
	root.set_meta("reach", 1.0)
	return root


## A mask. style 0 skull, 1 beak, 2 beast, 3 the bell-jawed king.
static func mask(style: int, r: RandomNumberGenerator, accent: Color, bone: Color = Color(0.93, 0.93, 0.9)) -> Node3D:
	var root := Node3D.new()
	var b := ForgeMesh.Builder.new()
	var eyes := ForgeMesh.Builder.new()
	var marks := ForgeMesh.Builder.new()
	var w := 0.15
	match style:
		1:
			b.prism(_pv([Vector2(-w, 0.14), Vector2(w, 0.14), Vector2(w * 0.9, 0.0), Vector2(0.05, -0.1), Vector2(-0.05, -0.1), Vector2(-w * 0.9, 0.0)]), 0.0, 0.03)
			b.spike(Vector3(0, -0.02, 0.02), Vector3(0, -0.2, -0.2), 0.06, 4)
		2:
			b.prism(_pv([Vector2(-w, 0.12), Vector2(-w * 0.5, 0.16), Vector2(w * 0.5, 0.16), Vector2(w, 0.12), Vector2(w * 0.85, -0.06), Vector2(0.0, -0.17), Vector2(-w * 0.85, -0.06)]), 0.0, 0.035)
			b.spike(Vector3(-w * 0.8, 0.12, 0.0), Vector3(-w * 1.4, 0.4 + r.randf() * 0.1, 0.06), 0.035, 3)
			b.spike(Vector3(w * 0.8, 0.12, 0.0), Vector3(w * 1.4, 0.4 + r.randf() * 0.1, 0.06), 0.035, 3)
			for k in range(5):
				b.spike(Vector3(-0.08 + 0.04 * float(k), -0.1, -0.02), Vector3(-0.08 + 0.04 * float(k), -0.17, -0.03), 0.014, 3)
		3:
			b.prism(_pv([Vector2(-w * 1.1, 0.16), Vector2(w * 1.1, 0.16), Vector2(w * 1.2, 0.0), Vector2(w * 0.8, -0.1), Vector2(-w * 0.8, -0.1), Vector2(-w * 1.2, 0.0)]), 0.0, 0.04)
			b.prism(_pv([Vector2(-w * 0.9, -0.12), Vector2(w * 0.9, -0.12), Vector2(w * 0.6, -0.26), Vector2(-w * 0.6, -0.26)]), -0.01, 0.035)
			for k in range(6):
				b.spike(Vector3(-0.1 + 0.04 * float(k), -0.1, -0.02), Vector3(-0.1 + 0.04 * float(k), -0.16, -0.04), 0.014, 3)
			b.spike(Vector3(-w, 0.14, 0.0), Vector3(-w * 2.0, 0.52, 0.1), 0.05, 4)
			b.spike(Vector3(w, 0.14, 0.0), Vector3(w * 2.0, 0.52, 0.1), 0.05, 4)
			b.spike(Vector3(0, 0.16, 0.0), Vector3(0, 0.44, 0.04), 0.04, 4)
		_:
			b.prism(_pv([Vector2(-w, 0.15), Vector2(w, 0.15), Vector2(w, 0.0), Vector2(w * 0.55, -0.15), Vector2(-w * 0.55, -0.15), Vector2(-w, 0.0)]), 0.0, 0.03)
	# eyes: slits that glow
	var ey := 0.045
	var tilt := 0.03 + r.randf() * 0.03
	eyes.prism(_pv([Vector2(-0.11, ey + tilt), Vector2(-0.035, ey - 0.012), Vector2(-0.04, ey - 0.035), Vector2(-0.1, ey)]), -0.012, 0.004)
	eyes.prism(_pv([Vector2(0.11, ey + tilt), Vector2(0.1, ey), Vector2(0.04, ey - 0.035), Vector2(0.035, ey - 0.012)]), -0.012, 0.004)
	# markings, different on every face
	var count := 1 + int(r.randi() % 3)
	for k in range(count):
		var x := 0.03 + r.randf() * 0.08
		var top := 0.09 + r.randf() * 0.05
		var bot := -0.04 - r.randf() * 0.08
		marks.prism(_pv([Vector2(x, top), Vector2(x + 0.022, top), Vector2(x + 0.008, bot)]), -0.008, 0.002)
		marks.prism(_pv([Vector2(-x, top), Vector2(-x - 0.008, bot), Vector2(-x - 0.022, top)]), -0.008, 0.002)
	var face := Node3D.new()
	root.add_child(face)
	ForgeMesh.inst(b.commit(), ForgeMesh.mat(bone, 0.6), face)
	var em := ForgeMesh.inst(eyes.commit(), ForgeMesh.glow(accent, 5.0), face)
	em.name = "eyes"
	ForgeMesh.inst(marks.commit(), ForgeMesh.mat(accent.darkened(0.35), 0.7), face)
	return root


## Half a mask, for a soul the Maw has touched.
static func mask_fragment(r: RandomNumberGenerator, accent: Color) -> Node3D:
	var root := Node3D.new()
	var b := ForgeMesh.Builder.new()
	b.prism(_pv([Vector2(0.0, 0.15), Vector2(0.15, 0.15), Vector2(0.15, 0.0), Vector2(0.09, -0.13), Vector2(0.03, -0.05), Vector2(0.05, 0.03)]), 0.0, 0.03)
	b.spike(Vector3(0.13, 0.14, 0.0), Vector3(0.22, 0.36 + r.randf() * 0.1, 0.06), 0.03, 3)
	ForgeMesh.inst(b.commit(), ForgeMesh.mat(Color(0.93, 0.93, 0.9), 0.6), root)
	var e := ForgeMesh.Builder.new()
	e.prism(_pv([Vector2(0.11, 0.075), Vector2(0.1, 0.045), Vector2(0.04, 0.01), Vector2(0.035, 0.033)]), -0.012, 0.004)
	ForgeMesh.inst(e.commit(), ForgeMesh.glow(accent, 5.0), root)
	return root


## Hair as a cluster of spikes. style 0 swept, 1 wild, 2 long, 3 knot, 4 crop.
static func hair(style: int, r: RandomNumberGenerator, color: Color) -> MeshInstance3D:
	var b := ForgeMesh.Builder.new()
	var top := 0.26
	b.column(0.142, 0.125, top - 0.07, top + 0.02, 14)
	match style:
		0:
			for i in range(9):
				var x := lerpf(-0.12, 0.12, float(i % 5) / 4.0)
				var base := Vector3(x, top, 0.02 + 0.05 * float(i / 5))
				b.spike(base, base + Vector3(x * 0.6, 0.1 + r.randf() * 0.1, 0.22 + r.randf() * 0.16), 0.055, 3)
			for i in range(3):
				var x := lerpf(-0.09, 0.09, float(i) / 2.0)
				b.spike(Vector3(x, top - 0.01, -0.12), Vector3(x * 1.3, top - 0.1 - r.randf() * 0.05, -0.19), 0.04, 3)
		1:
			for i in range(13):
				var a := TAU * float(i) / 13.0
				var base := Vector3(cos(a) * 0.09, top, sin(a) * 0.09)
				b.spike(base, base + Vector3(cos(a) * (0.12 + r.randf() * 0.12), 0.14 + r.randf() * 0.2, sin(a) * (0.12 + r.randf() * 0.12)), 0.06, 3)
			b.spike(Vector3(0, top, 0), Vector3(r.randf_range(-0.05, 0.05), top + 0.34, 0.02), 0.07, 4)
		2:
			for i in range(5):
				var x := lerpf(-0.11, 0.11, float(i) / 4.0)
				b.spike(Vector3(x, top, 0.1), Vector3(x * 1.2, -0.42 - r.randf() * 0.25, 0.2 + r.randf() * 0.06), 0.06, 3)
			for i in range(4):
				var x := lerpf(-0.1, 0.1, float(i) / 3.0)
				b.spike(Vector3(x, top - 0.01, -0.12), Vector3(x * 1.4, top - 0.2 - r.randf() * 0.08, -0.17), 0.04, 3)
			b.spike(Vector3(-0.13, top, 0.0), Vector3(-0.17, -0.1, 0.03), 0.045, 3)
			b.spike(Vector3(0.13, top, 0.0), Vector3(0.17, -0.1, 0.03), 0.045, 3)
		3:
			b.frustum(Vector2(0.08, 0.08), Vector2(0.1, 0.1), top + 0.02, top + 0.12, Vector2(0, 0.06))
			for i in range(4):
				b.spike(Vector3(0, top + 0.1, 0.07), Vector3(r.randf_range(-0.08, 0.08), top - 0.25 - r.randf() * 0.2, 0.3 + r.randf() * 0.1), 0.05, 3)
			for i in range(3):
				var x := lerpf(-0.09, 0.09, float(i) / 2.0)
				b.spike(Vector3(x, top - 0.01, -0.12), Vector3(x * 1.5, top - 0.14, -0.18), 0.04, 3)
		_:
			for i in range(7):
				var x := lerpf(-0.11, 0.11, float(i) / 6.0)
				b.spike(Vector3(x, top, -0.1), Vector3(x * 1.2 + r.randf_range(-0.03, 0.03), top - 0.1 - r.randf() * 0.06, -0.2), 0.04, 3)
			for i in range(5):
				var x := lerpf(-0.1, 0.1, float(i) / 4.0)
				b.spike(Vector3(x, top, 0.04), Vector3(x, top + 0.07 + r.randf() * 0.05, 0.1), 0.05, 3)
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit()
	mi.material_override = ForgeMesh.mat(color, 0.85)
	return mi


## A broken ring of shards behind the head, for a soul the Lumen has touched.
static func halo(r: RandomNumberGenerator, color: Color) -> MeshInstance3D:
	var b := ForgeMesh.Builder.new()
	var n := 7 + int(r.randi() % 4)
	for i in range(n):
		if r.randf() < 0.2:
			continue
		var a := TAU * float(i) / float(n)
		var d := Vector3(cos(a), sin(a), 0.0)
		b.spike(d * 0.26, d * (0.42 + r.randf() * 0.14), 0.035, 3)
	var mi := MeshInstance3D.new()
	mi.mesh = b.commit()
	mi.material_override = ForgeMesh.glow(color, 4.0)
	mi.set_meta("no_ghost", true)
	return mi


## Plates that hang by the shoulders, for a soul the Relic has touched.
static func plates(r: RandomNumberGenerator, color: Color) -> Node3D:
	var root := Node3D.new()
	for side: float in [-1.0, 1.0]:
		var b := ForgeMesh.Builder.new()
		var h := r.randf_range(0.3, 0.42)
		b.prism(_pv([Vector2(-0.1, 0.0), Vector2(0.1, 0.0), Vector2(0.13, -h * 0.6), Vector2(0.0, -h), Vector2(-0.13, -h * 0.6)]), -0.015, 0.015)
		var mi := ForgeMesh.inst(b.commit(), ForgeMesh.mat(Color(0.12, 0.1, 0.16), 0.5, 0.4), root, Vector3(side * 0.46, 0.5, 0.05))
		mi.rotation_degrees = Vector3(0, side * -70.0, side * -12.0)
		var e := ForgeMesh.Builder.new()
		e.prism(_pv([Vector2(-0.03, -0.08), Vector2(0.03, -0.08), Vector2(0.0, -h * 0.75)]), -0.02, 0.02)
		ForgeMesh.inst(e.commit(), ForgeMesh.glow(color, 3.0), mi)
	return root
