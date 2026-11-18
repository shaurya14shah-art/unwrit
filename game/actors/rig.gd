class_name BlockRig
extends Node3D
## A block avatar: a 2x2x1 torso, 1x2x1 limbs jointed at elbow and knee, and
## a round head with a face set into it. No skeleton, no imported model:
## Poses turns the pivots.

const JOINTS: Array[String] = ["hips", "torso", "head", "sl", "el", "sr", "er", "hl", "kl", "hr", "kr", "w", "wl"]

var spec: Dictionary = {}
var j: Dictionary = {}
var mats: Array[StandardMaterial3D] = []
var hand_r: Node3D
var hand_l: Node3D
var head: Node3D
var chest: Node3D
var hip_y: float = 1.0
var leg_scale: float = 1.0
var height: float = 1.86
var sway: float = 0.0
var flinch: float = 0.0
var clip_name: String = ""
var finished: bool = false
var extra_yaw: float = 0.0

var _clip: Dictionary = {}
var _t: float = 0.0
var _speed: float = 1.0
var _from: Dictionary = {}
var _cur: Dictionary = {}
var _blend_t: float = 0.0
var _blend_len: float = 0.0
var _tails: Array[Node3D] = []
var _flash: float = 0.0


static func default_spec() -> Dictionary:
	return {
		"scale": 1.0, "feral": false, "arm": 1.0, "leg": 1.0, "bulk": 1.0,
		"skin": Color(0.92, 0.78, 0.62), "cloth": Color(0.07, 0.07, 0.09), "trim": Color(0.92, 0.92, 0.94),
		"accent": Color(0.9, 0.9, 0.95), "coat": 2, "sleeves": true, "sash": 0,
		"hair": 0, "hair_color": Color(0.1, 0.1, 0.12), "hair_seed": 1,
		"mask": -1, "mask_seed": 1, "hole": false, "collar": false, "claws": false,
		"fragment": false, "halo": false, "plates": false, "face": 0, "tether": 0,
		"armour": "", "armour_color": Color(0.7, 0.72, 0.78),
	}


## One stud. Torso 2x2x1, each limb 1x2x1, a round head on top.
const S: float = 0.33


func _part(parent: Node3D, size: Vector3, pos: Vector3, material: Material) -> MeshInstance3D:
	return ForgeMesh.inst(ForgeMesh.box(size), material, parent, pos)


func build(s: Dictionary) -> void:
	spec = default_spec()
	for k: Variant in s.keys():
		spec[k] = s[k]
	for c in get_children():
		c.queue_free()
	j.clear()
	mats.clear()
	_tails.clear()
	var feral := bool(spec["feral"])
	var bulk := float(spec["bulk"])
	var arm := float(spec["arm"]) * (1.5 if feral else 1.0)
	leg_scale = float(spec["leg"])
	var cloth := _mat(spec["cloth"])
	var trim := _mat(spec["trim"])
	var skin := _mat(spec["skin"])
	var body_skin := skin if not feral else cloth
	scale = Vector3.ONE * float(spec["scale"])

	var leg_len := S * leg_scale
	hip_y = leg_len * 2.0
	var torso_w := S * 2.0 * bulk * (1.15 if feral else 1.0)
	var torso_h := S * 2.0
	var torso_d := S * bulk
	var limb_w := S * bulk

	var hips := _joint("hips", self, Vector3(0, hip_y, 0))
	var torso := _joint("torso", hips, Vector3.ZERO)
	_part(torso, Vector3(torso_w, torso_h, torso_d), Vector3(0, torso_h * 0.5, 0), cloth)
	chest = Node3D.new()
	chest.position = Vector3(0, torso_h * 0.62, 0)
	torso.add_child(chest)
	# clothing drawn as thin parts: a belt, and an open collar
	var belt_h := 0.12 if int(spec["sash"]) > 0 else 0.07
	_part(torso, Vector3(torso_w + 0.02, belt_h, torso_d + 0.02), Vector3(0, belt_h * 0.5 + 0.02, 0), trim)
	if not feral:
		for side: float in [-1.0, 1.0]:
			var strip := _part(torso, Vector3(0.055, torso_h * 0.72, 0.012), Vector3(side * 0.085, torso_h * 0.6, -torso_d * 0.5 - 0.004), trim)
			strip.rotation_degrees = Vector3(0, 0, side * 13.0)
		_part(torso, Vector3(0.1, torso_h * 0.4, 0.008), Vector3(0, torso_h * 0.78, -torso_d * 0.5 - 0.002), skin)

	# the head: a short round column with softened rims
	head = _joint("head", torso, Vector3(0, torso_h, 0))
	var hr := 0.205
	var hh := 0.4
	var hb := ForgeMesh.Builder.new()
	hb.column(hr * 0.82, hr, 0.0, hh * 0.14, 20)
	hb.column(hr, hr, hh * 0.14, hh * 0.86, 20)
	hb.column(hr, hr * 0.82, hh * 0.86, hh, 20)
	ForgeMesh.inst(hb.commit(), body_skin, head)
	if int(spec["mask"]) < 0 and int(spec["face"]) >= 0:
		_build_face(hr, hh)

	for side_name: String in ["l", "r"]:
		var sx := -1.0 if side_name == "l" else 1.0
		var up_len := S * arm
		var low_len := S * arm
		var sh := _joint("s" + side_name, torso, Vector3(sx * (torso_w * 0.5 + limb_w * 0.5), torso_h - limb_w * 0.5, 0))
		_part(sh, Vector3(limb_w, up_len, limb_w), Vector3(0, limb_w * 0.5 - up_len * 0.5, 0), cloth)
		var el := _joint("e" + side_name, sh, Vector3(0, limb_w * 0.5 - up_len, 0))
		var hand_h := limb_w * 0.42
		var cuff := limb_w * (1.07 if bool(spec["sleeves"]) else 1.0)
		_part(el, Vector3(cuff, low_len - hand_h, cuff), Vector3(0, -(low_len - hand_h) * 0.5, 0), cloth)
		var hand_w := limb_w * (0.98 if not feral else 1.25)
		_part(el, Vector3(hand_w, hand_h * (1.0 if not feral else 1.5), hand_w), Vector3(0, -low_len + hand_h * 0.5, 0), body_skin if not feral else trim)
		var hand := Node3D.new()
		hand.position = Vector3(0, -low_len + hand_h * 0.5, 0)
		el.add_child(hand)
		if bool(spec["claws"]):
			var cb := ForgeMesh.Builder.new()
			for k in range(3):
				var off := (-0.09 + 0.09 * float(k)) * bulk
				cb.box(Vector3(0.06, 0.3, 0.06) * bulk, Vector3(off, -0.2 * bulk, -0.06), Vector3(18, 0, 0))
			ForgeMesh.inst(cb.commit(), trim, hand)
		var slot := _joint("w" if side_name == "r" else "wl", hand, Vector3.ZERO)
		if side_name == "r":
			hand_r = slot
		else:
			hand_l = slot

	for side_name: String in ["l", "r"]:
		var sx := -1.0 if side_name == "l" else 1.0
		var hp := _joint("h" + side_name, hips, Vector3(sx * limb_w * 0.5, 0, 0))
		_part(hp, Vector3(limb_w, leg_len, limb_w), Vector3(0, -leg_len * 0.5, 0), cloth)
		var kn := _joint("k" + side_name, hp, Vector3(0, -leg_len, 0))
		var shoe := 0.1
		_part(kn, Vector3(limb_w, leg_len - shoe, limb_w), Vector3(0, -(leg_len - shoe) * 0.5, 0), cloth)
		_part(kn, Vector3(limb_w + 0.01, shoe, limb_w + 0.05), Vector3(0, -leg_len + shoe * 0.5, -0.02), trim if not feral else cloth)

	_build_coat(hips, cloth, trim)
	_build_head_gear(body_skin)
	if bool(spec["hole"]):
		var hole := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.1
		cm.bottom_radius = 0.1
		cm.height = torso_d + 0.02
		cm.radial_segments = 16
		hole.mesh = cm
		hole.material_override = ForgeMesh.mat(Color(0, 0, 0), 1.0)
		hole.rotation_degrees = Vector3(90, 0, 0)
		chest.add_child(hole)
		var rim := ForgeMesh.inst(ForgeMesh.ring(0.72, 20), ForgeMesh.glow(spec["accent"], 2.0), chest, Vector3(0, 0, -torso_d * 0.5 - 0.012))
		rim.rotation_degrees = Vector3(90, 0, 0)
		rim.scale = Vector3.ONE * 0.14
	if bool(spec["collar"]):
		var cb := ForgeMesh.Builder.new()
		var r := Rng.make([int(spec["hair_seed"]), "collar"])
		for i in range(12):
			var a := TAU * float(i) / 12.0
			var d := Vector3(cos(a), 0.0, sin(a))
			cb.spike(d * 0.14 + Vector3(0, torso_h - 0.03, 0), d * (0.34 + r.randf() * 0.1) + Vector3(0, torso_h + 0.04 + r.randf() * 0.1, 0), 0.08, 4)
		ForgeMesh.inst(cb.commit(), _mat(spec["accent"]), torso)
	var links := int(spec["tether"])
	if links > 0:
		# the tether: what is left of the tie to the living, hanging from the chest
		var chain := ForgeMesh.Builder.new()
		for k in range(links):
			var y := torso_h * 0.6 - 0.11 * float(k)
			var rot := 90.0 if k % 2 == 0 else 0.0
			chain.box(Vector3(0.07, 0.11, 0.02), Vector3(-0.04, y, -torso_d * 0.5 - 0.04 - 0.012 * float(k)), Vector3(0, rot, 0))
		ForgeMesh.inst(chain.commit(), ForgeMesh.mat(Color(0.62, 0.6, 0.56), 0.4, 0.8), torso)
		var plate := _part(torso, Vector3(0.12, 0.12, 0.03), Vector3(-0.04, torso_h * 0.6 + 0.06, -torso_d * 0.5 - 0.02), ForgeMesh.mat(Color(0.5, 0.48, 0.45), 0.4, 0.8))
		plate.rotation_degrees = Vector3(0, 0, 45)
	if bool(spec["plates"]):
		var pl := Gear.plates(Rng.make([int(spec["hair_seed"]), "plates"]), spec["accent"])
		pl.position = Vector3(0, 0.12, 0)
		torso.add_child(pl)
	if String(spec["armour"]) != "":
		_build_armour(torso, torso_w, torso_h, torso_d, limb_w)
	height = (hip_y + torso_h + hh) * float(spec["scale"])
	_cur = Poses.IDLE if not feral else Poses.F_IDLE
	_apply(_cur)


## Forged armour, block-built. Plate: pauldrons, a breastplate and a fauld.
## Robe: a long coat (set in the spec), a mantle and a cord. Hide: straps
## across the chest and furred shoulders.
func _build_armour(torso: Node3D, tw: float, th: float, td: float, lw: float) -> void:
	var col: Color = spec["armour_color"]
	var metal := ForgeMesh.mat(col, 0.35, 0.75)
	var dark := _mat(col.darkened(0.45))
	match String(spec["armour"]):
		"plate":
			_part(torso, Vector3(tw * 0.86, th * 0.46, 0.05), Vector3(0, th * 0.66, -td * 0.5 - 0.02), metal)
			_part(torso, Vector3(tw * 0.5, th * 0.08, 0.06), Vector3(0, th * 0.88, -td * 0.5 - 0.03), dark)
			_part(torso, Vector3(tw + 0.04, th * 0.14, td + 0.06), Vector3(0, th * 0.12, 0), metal)
			for side_name: String in ["l", "r"]:
				var sh: Node3D = j["s" + side_name]
				_part(sh, Vector3(lw * 1.35, lw * 0.5, lw * 1.3), Vector3(0, lw * 0.42, 0), metal)
				_part(sh, Vector3(lw * 1.4, lw * 0.14, lw * 1.36), Vector3(0, lw * 0.12, 0), dark)
		"robe":
			_part(torso, Vector3(tw + 0.08, th * 0.2, td + 0.08), Vector3(0, th * 0.9, 0), _mat(col))
			_part(torso, Vector3(tw + 0.05, 0.05, td + 0.05), Vector3(0, th * 0.18, 0), dark)
			_part(torso, Vector3(0.05, th * 0.32, 0.02), Vector3(tw * 0.22, th * 0.02, -td * 0.5 - 0.03), dark)
		"hide":
			for side: float in [-1.0, 1.0]:
				var strap := _part(torso, Vector3(0.07, th * 1.1, 0.02), Vector3(0, th * 0.55, -td * 0.5 - 0.012), dark)
				strap.rotation_degrees = Vector3(0, 0, side * 32.0)
			for side_name: String in ["l", "r"]:
				var sh: Node3D = j["s" + side_name]
				var fur := ForgeMesh.Builder.new()
				for k in range(4):
					fur.box(Vector3(lw * 0.42, lw * 0.36, lw * 1.2), Vector3(-lw * 0.45 + lw * 0.3 * float(k), lw * 0.5 + 0.03 * float(k % 2), 0), Vector3(0, 0, -20.0 + 13.0 * float(k)))
				ForgeMesh.inst(fur.commit(), _mat(col), sh)


## A face made of small dark parts set into the head: eyes, brows, a mouth.
func _build_face(hr: float, hh: float) -> void:
	var ink := ForgeMesh.mat(Color(0.05, 0.05, 0.06), 0.6)
	var style := int(spec["face"]) % 4
	var fb := ForgeMesh.Builder.new()
	for side: float in [-1.0, 1.0]:
		var ang := side * 22.0
		var dir := Vector3(sin(deg_to_rad(ang)), 0, -cos(deg_to_rad(ang)))
		var eye_h := 0.085 if style != 2 else 0.05
		fb.box(Vector3(0.042, eye_h, 0.012), dir * (hr + 0.001) + Vector3(0, hh * 0.56, 0), Vector3(0, -ang, 0))
		# brows give the stare its weight
		var tilts: Array[float] = [-14.0, -24.0, 0.0, -8.0]
		var brow_tilt: float = tilts[style] * side
		fb.box(Vector3(0.085, 0.02, 0.012), dir * (hr + 0.001) + Vector3(0, hh * 0.56 + eye_h * 0.5 + 0.03, 0), Vector3(0, -ang, brow_tilt))
	var widths: Array[float] = [0.09, 0.07, 0.1, 0.06]
	var mouth_w: float = widths[style]
	fb.box(Vector3(mouth_w, 0.016, 0.012), Vector3(0.01 if style == 3 else 0.0, hh * 0.27, -hr - 0.001), Vector3(0, 0, 6.0 if style == 3 else 0.0))
	ForgeMesh.inst(fb.commit(), ink, head)


func _mat(c: Variant) -> StandardMaterial3D:
	var col: Color = c
	var m := ForgeMesh.mat(col, 0.55)
	m.emission_enabled = true
	m.emission = Color(1, 1, 1)
	m.emission_energy_multiplier = 0.0
	mats.append(m)
	return m


func _joint(joint_name: String, parent: Node3D, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.name = joint_name
	n.position = pos
	parent.add_child(n)
	j[joint_name] = n
	return n


## A long coat as four flat parts hanging from the waist.
func _build_coat(hips: Node3D, cloth: StandardMaterial3D, _trim: StandardMaterial3D) -> void:
	var coat := int(spec["coat"])
	if coat <= 0:
		return
	var bulk := float(spec["bulk"])
	var length := (0.34 if coat == 1 else 0.58) * leg_scale
	var half := S * bulk * 0.5
	var panels: Array = [[-half, -1.0, 4.0], [half, -1.0, -4.0], [-half, 1.0, 5.0], [half, 1.0, -5.0]]
	for p: Variant in panels:
		var d: Array = p
		var pivot := Node3D.new()
		pivot.position = Vector3(float(d[0]), 0.02, float(d[1]) * (S * bulk * 0.5 + 0.018))
		pivot.set_meta("back", float(d[1]) > 0.0)
		pivot.set_meta("splay", float(d[2]))
		hips.add_child(pivot)
		_part(pivot, Vector3(S * bulk + 0.015, length, 0.03), Vector3(0, -length * 0.5, 0), cloth)
		# a notched hem: two shorter tabs under the panel
		_part(pivot, Vector3(S * bulk * 0.42, 0.1, 0.03), Vector3(-S * bulk * 0.27, -length - 0.05, 0), cloth)
		_part(pivot, Vector3(S * bulk * 0.3, 0.16, 0.03), Vector3(S * bulk * 0.3, -length - 0.08, 0), cloth)
		_tails.append(pivot)


func _build_head_gear(_skin: StandardMaterial3D) -> void:
	# gear was cut for a narrower head; one scale fits it to this one
	var fit := 1.5
	var hs := int(spec["hair"])
	if hs >= 0:
		var hair := Gear.hair(hs, Rng.make([int(spec["hair_seed"]), "hair"]), spec["hair_color"])
		hair.scale = Vector3.ONE * fit
		hair.position = Vector3(0, 0.02, 0)
		head.add_child(hair)
	if int(spec["mask"]) >= 0:
		var m := Gear.mask(int(spec["mask"]), Rng.make([int(spec["mask_seed"]), "mask"]), spec["accent"])
		m.position = Vector3(0, 0.2, -0.24)
		m.scale = Vector3.ONE * fit
		head.add_child(m)
	if bool(spec["fragment"]):
		var f := Gear.mask_fragment(Rng.make([int(spec["mask_seed"]), "fragment"]), spec["accent"])
		f.position = Vector3(0, 0.2, -0.225)
		f.scale = Vector3.ONE * fit
		head.add_child(f)
	if bool(spec["halo"]):
		var h := Gear.halo(Rng.make([int(spec["mask_seed"]), "halo"]), spec["accent"])
		h.position = Vector3(0, 0.24, 0.3)
		h.scale = Vector3.ONE * 1.25
		head.add_child(h)


## Puts a weapon in the right hand; a child named `left` goes to the left.
func hold(weapon: Node3D) -> void:
	for slot: Node3D in [hand_r, hand_l]:
		for c in slot.get_children():
			c.queue_free()
	if weapon == null:
		return
	var left := weapon.get_node_or_null("left")
	if left != null:
		weapon.remove_child(left)
		left.scale = weapon.scale
		hand_l.add_child(left)
	hand_r.add_child(weapon)


func play(clip: String, blend: float = 0.12, speed: float = 1.0, restart: bool = false) -> void:
	if clip == clip_name and not restart:
		_speed = speed
		return
	if not Poses.CLIPS.has(clip):
		return
	play_clip(Poses.CLIPS[clip], blend, speed)
	clip_name = clip


func play_clip(clip: Dictionary, blend: float = 0.06, speed: float = 1.0) -> void:
	_from = _cur
	_clip = clip
	_t = 0.0
	_speed = speed
	_blend_t = 0.0
	_blend_len = blend
	clip_name = "*"
	finished = false


func flash(amount: float = 1.0) -> void:
	_flash = amount


func _process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	if _clip.is_empty():
		play("f_idle" if bool(spec.get("feral", false)) else "idle", 0.0)
	_t += delta * _speed
	if not bool(_clip["loop"]) and _t >= float(_clip["len"]):
		finished = true
	var pose := Poses.sample(_clip, _t)
	if _blend_len > 0.0 and _blend_t < _blend_len:
		_blend_t += delta
		var u := clampf(_blend_t / _blend_len, 0.0, 1.0)
		pose = Poses.blend(_from, pose, u * u * (3.0 - 2.0 * u))
	_cur = pose
	_apply(pose)
	flinch = move_toward(flinch, 0.0, delta * 5.0)
	if _flash > 0.0:
		_flash = move_toward(_flash, 0.0, delta * 6.0)
		for m in mats:
			m.emission_energy_multiplier = _flash * 0.3


func _apply(p: Dictionary) -> void:
	for joint_name in JOINTS:
		var n: Node3D = j.get(joint_name)
		if n == null:
			continue
		var v: Vector3 = p.get(joint_name, Vector3.ZERO)
		if joint_name == "wl" and not p.has("wl"):
			v = p.get("w", Vector3.ZERO)
		n.rotation_degrees = v
	var hips: Node3D = j["hips"]
	hips.position.y = hip_y * (1.0 + float(p.get("y", 0.0)))
	hips.rotation_degrees.y += extra_yaw
	if flinch > 0.0:
		var torso: Node3D = j["torso"]
		torso.rotation_degrees.x += flinch * 16.0
		(j["head"] as Node3D).rotation_degrees.x -= flinch * 10.0
	# coat panels trail behind when moving and lift with the thigh in front
	var lift_l: float = maxf(0.0, (p.get("hl", Vector3.ZERO) as Vector3).x)
	var lift_r: float = maxf(0.0, (p.get("hr", Vector3.ZERO) as Vector3).x)
	var tilt: float = (p.get("torso", Vector3.ZERO) as Vector3).x
	var low: float = clampf(-float(p.get("y", 0.0)) * 1.6 - 0.25, 0.0, 1.0)
	# lying down, the coat lies with the body instead of folding
	low *= 1.0 - clampf(absf((p.get("hips", Vector3.ZERO) as Vector3).x) / 45.0, 0.0, 1.0)
	for i in range(_tails.size()):
		var t := _tails[i]
		var back := bool(t.get_meta("back"))
		var splay := float(t.get_meta("splay"))
		var x := 0.0
		if back:
			x = -sway * 42.0 - 6.0 + minf(0.0, tilt) * 0.3 - low * 82.0
		else:
			x = maxf((lift_l if i == 0 else lift_r) * 0.85, low * 86.0) - sway * 10.0
		t.rotation_degrees = Vector3(x, 0, splay * (1.0 + sway))
