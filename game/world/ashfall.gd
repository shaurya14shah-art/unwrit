class_name Ashfall
extends Region
## The Wastes: the Devourers' realm. White dunes under a black sky, about
## 860 metres across. South: the dunes where the tear lets you out. West:
## the Crystal Undergrowth, where the Talls walk and the Many-Mouthed waits.
## East: the bone fields. North: the Bell Court of Odrel, and beyond it the
## Sunken Throne of Sereth. The Hunt Stone by the arrival serves Devourers.

const SIZE: float = 860.0
const CELLS: int = 140
const RIM: float = 392.0
const WAKE := Vector3(0, 0, 330)
const COURT := Vector3(0, 0, -110)
const COURT_R: float = 24.0
const THRONE := Vector3(0, 0, -330)
const MOUTH := Vector3(-260, 0, -20)
const CAIRNS: Array = [Vector3(-16, 0, 322), Vector3(-176, 0, 120), Vector3(34, 0, -44), Vector3(0, 0, -252), Vector3(210, 0, 40)]
const SPAWNS: Array = [
	# the dunes
	["husk", -30, 280, 6], ["husk", -38, 272, 6], ["husk", 40, 268, 6], ["husk", 52, 276, 7],
	["gleaner", 0, 230, 7], ["gleaner", 12, 222, 7], ["husk", -70, 210, 7], ["husk", -80, 200, 7], ["stalker", 90, 210, 8],
	["husk", 120, 260, 7], ["gleaner", -130, 250, 8], ["stalker", -20, 170, 9], ["stalker", 10, 160, 9],
	# the Undergrowth
	["wraith", -160, 60, 11], ["wraith", -170, 40, 11], ["stalker", -220, 90, 12], ["stalker", -240, 70, 12],
	["giant", -300, 100, 12], ["giant", -200, -110, 13], ["wraith", -300, -60, 12], ["gleaner", -150, -40, 11],
	# the bone fields
	["brute", 180, 0, 12], ["brute", 240, -80, 13], ["stalker", 200, 60, 12], ["stalker", 260, 20, 13],
	["husk", 160, -40, 11], ["husk", 170, -50, 11], ["gleaner", 300, -40, 13], ["brute", 280, 120, 12],
	# around the court
	["stalker", -40, -60, 15], ["stalker", 40, -70, 15], ["gleaner", -60, -150, 16], ["gleaner", 60, -160, 16],
	# the throne road
	["stalker", -30, -220, 19], ["stalker", 30, -230, 19], ["brute", 0, -270, 20], ["wraith", -50, -280, 19], ["wraith", 50, -285, 19],
	["giant", -120, -300, 21], ["giant", 120, -300, 21],
]
const RELICS: Array = [
	[-60, 300, "A mask split down the middle. Whoever wore it was a person first."],
	[90, 150, "A bell clapper, bitten through. Something wanted the sound to stop."],
	[-210, -60, "A reaper's badge, worn smooth. Someone came down here to send these souls on, and stayed."],
	[250, -120, "A lantern with no glass. The light it held was gathered by someone else."],
	[-20, -30, "A ledger page with one line struck out. You think the name was yours."],
	[70, -300, "A crown of sand that keeps its shape in your hand. It was made for someone smaller."],
]
const STELES: Array = [
	[14, 312, "THESE ARE THE WASTES, WHERE THE HUNGRY DEAD END. WHAT FELL THROUGH THE WORLD LANDED HERE AND KEPT EATING."],
	[-150, 100, "THE TALL WALK THE UNDERGROWTH. THEY WERE A HUNDRED HUNGERS ONCE. NOW THEY ARE ONE, AND IT IS SLOW, AND IT DOES NOT MISS."],
	[16, -76, "ODREL KEPT THE BELL THAT CALLED SOULS ON. THEN HE ATE IT, SO THAT NO ONE WOULD LEAVE HIM."],
	[20, -270, "SERETH ATE HER WAY TO A THRONE. EVERY DEVOURER WHO CLIMBS FAR ENOUGH MUST TAKE IT FROM HER, OR KNEEL."],
]

var noise: FastNoiseLite = FastNoiseLite.new()
var field: Heightfield
var flats: Array = []
var _ash: GPUParticles3D


func _ready() -> void:
	region_id = "ashfall"
	place_name = "The Wastes"
	bounds = RIM
	level_base = 7
	noise.seed = 7
	noise.frequency = 0.006
	noise.fractal_octaves = 3
	flats = [
		[WAKE.x, WAKE.z, 16.0, 0.5], [COURT.x, COURT.z, COURT_R + 4.0, -2.5], [THRONE.x, THRONE.z, 34.0, 1.0],
		[MOUTH.x, MOUTH.z, 30.0, -1.0], [300.0, 200.0, 8.0, 0.5], [10.0, 330.0, 6.0, 0.5], [-250.0, -250.0, 10.0, 0.5],
	]
	for c: Variant in CAIRNS:
		flats.append([(c as Vector3).x, (c as Vector3).z, 7.0, 0.6])
	field = Heightfield.new(SIZE, CELLS, _raw_height, _tint)
	_build_sky()
	field.build(self, "pale")
	_build_scenery()
	_build_court()
	_build_throne()
	_build_dressing()
	_build_points()
	Fx.root = self
	Sfx.loop("wind", "wind", -16.0)
	Sfx.loop("music", music_name(), -15.0)


func wake_point() -> Vector3:
	return WAKE


func cairn_points() -> Array:
	return CAIRNS


func spawn_list() -> Array:
	return SPAWNS


func boss_list() -> Array:
	return [
		["many_mouthed", MOUTH.x, MOUTH.z, 14, 34.0, 90.0],
		["odrel", COURT.x, COURT.z - COURT_R + 9.0, 16, COURT_R + 10.0, 180.0],
		["sereth", THRONE.x, THRONE.z + 6.0, 24, 30.0, 0.0],
	]


func board_list() -> Array:
	return [[12.0, 322.0, "hunt", 180.0], [28.0, 318.0, "exchange", 180.0], [44.0, 314.0, "forge", 180.0]]


func giver_list() -> Array:
	return [[-14.0, 318.0, 160.0, "g_kesh", "Kesh", "will not eat", {"feral": false, "cloth": Color(0.86, 0.86, 0.84), "trim": Color(0.18, 0.18, 0.2), "coat": 1, "hair": -1, "face": -1, "mask": 0, "mask_seed": 91, "hole": true},
		["I was hungry for a long time. Then I was tired of being hungry.", "The masks talk, if you hold them long enough. Mostly they apologise."]]]


func relic_list() -> Array:
	return RELICS


func stele_list() -> Array:
	return STELES


func portal_list() -> Array:
	return [
		[-8.0, 346.0, "town", "Climb back to the living world", ""],
		[300.0, 200.0, "citadel", "Step through the Breach to the Citadel", "reaper"],
		[-250.0, -250.0, "undermark", "Break the seal and descend into the Undermark", "deep"],
	]


func objective() -> String:
	if soul.primary == "maw" or soul.secondary == "maw":
		return "The Hunt Stone is by the tear. " + Quests.promotion_gap(soul)
	return Quests.promotion_gap(soul)


# ----------------------------------------------------------------- terrain

func _raw_height(x: float, z: float) -> float:
	var h := noise.get_noise_2d(x, z) * 7.0
	h += absf(noise.get_noise_2d(x * 2.3 + 300.0, z * 2.3)) * 2.6
	var d := Vector2(x, z).length()
	if d > RIM - 6.0:
		h += minf(26.0, (d - RIM + 6.0) * 0.45)
	for f: Variant in flats:
		var fl: Array = f
		h = Heightfield.flatten(h, x, z, float(fl[0]), float(fl[1]), float(fl[2]), float(fl[3]))
	return h


func height_at(x: float, z: float) -> float:
	return field.height_at(x, z) if field != null else 0.0


func _tint(mid: Vector3, n: Vector3) -> Color:
	var slope := clampf(1.0 - n.y, 0.0, 1.0)
	var grain := noise.get_noise_2d(mid.x * 6.0, mid.z * 6.0) * 0.04
	var v := 0.72 - slope * 0.35 + grain
	# the Undergrowth floor is darker, the bone fields paler
	if mid.x < -120.0 and absf(mid.z) < 190.0:
		v *= 0.62
	elif mid.x > 130.0 and mid.z < 140.0 and mid.z > -220.0:
		v = minf(0.82, v * 1.08)
	return Color(v, v, v * 1.03)


func _build_sky() -> void:
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.0, 0.0, 0.01)
	sm.sky_horizon_color = Color(0.2, 0.21, 0.24)
	sm.sky_curve = 0.09
	sm.ground_bottom_color = Color(0.02, 0.02, 0.03)
	sm.ground_horizon_color = Color(0.2, 0.21, 0.24)
	sm.sun_angle_max = 0.0
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.52, 0.58)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 1.4
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 1.3
	env.fog_enabled = true
	env.fog_light_color = Color(0.3, 0.31, 0.34)
	env.fog_density = 0.0042
	env.fog_sky_affect = 0.0
	env.adjustment_enabled = true
	env.adjustment_saturation = 0.9
	env.adjustment_contrast = 1.08
	Detail.polish(env)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, 152, 0)
	sun.light_color = Color(0.92, 0.95, 1.0)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	add_child(sun)
	var moon := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 60.0
	sph.height = 120.0
	sph.radial_segments = 16
	sph.rings = 8
	moon.mesh = sph
	var mm := StandardMaterial3D.new()
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mm.albedo_color = Color(1.5, 1.5, 1.6)
	mm.disable_fog = true
	moon.material_override = mm
	add_child(moon)
	moon.position = sun.transform.basis.z * 900.0


func _clear(x: float, z: float, margin: float = 0.0) -> bool:
	for f: Variant in flats:
		var fl: Array = f
		if Vector2(x - float(fl[0]), z - float(fl[1])).length() < float(fl[2]) + margin:
			return false
	if Vector2(x - COURT.x, z - COURT.z).length() < COURT_R + 10.0 + margin:
		return false
	return true


func _on_ground(x: float, z: float, s: float, yaw: float, sink: float = 0.0) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * s), Vector3(x, height_at(x, z) - sink * s, z))


func _build_scenery() -> void:
	var r := Rng.make(["ashfall", "scenery"])
	var stone := ForgeMesh.grain(Color(0.46, 0.47, 0.5), "slate")
	var pale_stone := ForgeMesh.grain(Color(0.6, 0.61, 0.65), "slate")
	var bone := ForgeMesh.grain(Color(0.86, 0.85, 0.8), "slate")
	var dark := ForgeMesh.grain(Color(0.13, 0.13, 0.16), "slate", 0.05)
	var bark := ForgeMesh.mat(Color(0.14, 0.13, 0.14), 0.8)
	var neon := ForgeMesh.glow(Color(0.25, 0.95, 0.9), 2.2)
	# rocks: three shapes, many copies, one draw call each
	var rock_meshes: Array = [ForgeMesh.rock(r, 1.0), ForgeMesh.rock(r, 1.0), ForgeMesh.rock(r, 1.0)]
	var rock_x: Array = [[], [], []]
	for i in range(700):
		var x := r.randf_range(-RIM, RIM)
		var z := r.randf_range(-RIM, RIM)
		if Vector2(x, z).length() > RIM - 4.0:
			continue
		var big := r.randf() > 0.9
		if not _clear(x, z, 8.0 if big else 0.0):
			continue
		var s := r.randf_range(2.6, 5.0) if big else r.randf_range(0.4, 1.8)
		(rock_x[i % 3] as Array).append(_on_ground(x, z, s, r.randf() * TAU, 0.12))
		if big:
			_solid(Vector3(x, height_at(x, z), z), s * 0.8, s * 1.1)
	for k in range(3):
		ForgeMesh.scatter(self, rock_meshes[k], stone, rock_x[k])
	# dead trees across the dunes
	var tree_meshes: Array = [ForgeMesh.dead_tree(r, 7.0), ForgeMesh.dead_tree(r, 8.5), ForgeMesh.dead_tree(r, 6.0)]
	var tree_x: Array = [[], [], []]
	for i in range(160):
		var x := r.randf_range(-RIM, RIM)
		var z := r.randf_range(-RIM, RIM)
		if Vector2(x, z).length() > RIM - 6.0 or not _clear(x, z, 3.0) or (x < -120.0 and absf(z) < 190.0):
			continue
		(tree_x[i % 3] as Array).append(_on_ground(x, z, r.randf_range(0.8, 1.4), r.randf() * TAU, 0.03))
	for k in range(3):
		ForgeMesh.scatter(self, tree_meshes[k], bark, tree_x[k])
	# the Crystal Undergrowth: a forest of tall teal pillars
	var pillar := ForgeMesh.Builder.new()
	pillar.box(Vector3(1.0, 1.0, 1.0), Vector3(0, 0.5, 0))
	var pillar_mesh := pillar.commit()
	var crystal_x: Array = []
	var cap_x: Array = []
	for i in range(520):
		var x := r.randf_range(-RIM + 10.0, -125.0)
		var z := r.randf_range(-185.0, 185.0)
		if not _clear(x, z, 4.0) or Vector2(x - MOUTH.x, z - MOUTH.z).length() < 36.0:
			continue
		var w := r.randf_range(0.9, 2.6)
		var h := r.randf_range(8.0, 34.0)
		var yaw := r.randf() * TAU
		var tilt := Basis(Vector3(r.randf_range(-1, 1), 0, r.randf_range(-1, 1)).normalized(), r.randf_range(0.0, 0.12))
		var b := tilt * Basis(Vector3.UP, yaw).scaled(Vector3(w, h, w))
		crystal_x.append(Transform3D(b, Vector3(x, height_at(x, z) - 0.3, z)))
		if r.randf() < 0.45:
			cap_x.append(Transform3D(tilt * Basis(Vector3.UP, yaw).scaled(Vector3(w * 1.02, 0.6, w * 1.02)), Vector3(x, height_at(x, z) - 0.3, z) + tilt * Vector3(0, h * r.randf_range(0.3, 0.9), 0)))
		if w > 1.6:
			_solid(Vector3(x, height_at(x, z), z), w * 0.6, 6.0)
	ForgeMesh.scatter(self, pillar_mesh, ForgeMesh.grain(Color(0.2, 0.32, 0.34), "slate", 0.12), crystal_x)
	ForgeMesh.scatter(self, pillar_mesh, neon, cap_x)
	var lights := 0
	for i in range(12):
		var x := r.randf_range(-RIM + 30.0, -140.0)
		var z := r.randf_range(-170.0, 170.0)
		var l := OmniLight3D.new()
		l.light_color = Color(0.25, 0.95, 0.9)
		l.light_energy = 2.2
		l.omni_range = 26.0
		l.position = Vector3(x, height_at(x, z) + 8.0, z)
		add_child(l)
		lights += 1
	# small neon clusters elsewhere
	var shard := ForgeMesh.Builder.new()
	for k in range(5):
		var tall := r.randf_range(0.7, 2.6)
		var w := r.randf_range(0.18, 0.36)
		shard.box(Vector3(w, tall, w), Vector3(r.randf_range(-0.5, 0.5), tall * 0.35, r.randf_range(-0.5, 0.5)), Vector3(r.randf_range(-28, 28), r.randf_range(0, 90), r.randf_range(-28, 28)))
	var shard_mesh := shard.commit()
	var shard_x: Array = []
	for i in range(120):
		var x := r.randf_range(-RIM, RIM)
		var z := r.randf_range(-RIM, RIM)
		if Vector2(x, z).length() > RIM - 6.0 or not _clear(x, z):
			continue
		shard_x.append(_on_ground(x, z, r.randf_range(0.8, 1.6), r.randf() * TAU, 0.05))
	ForgeMesh.scatter(self, shard_mesh, neon, shard_x)
	# the bone fields: great ribs standing out of the sand
	var rib := ForgeMesh.Builder.new()
	for k in range(7):
		var a := lerpf(0.15, 2.95, float(k) / 6.0)
		rib.box(Vector3(1.6, 4.0, 1.4), Vector3(cos(a) * 9.0, sin(a) * 11.0, 0), Vector3(0, 0, rad_to_deg(a) + 90.0))
	var rib_mesh := rib.commit()
	var rib_x: Array = []
	for i in range(26):
		var x := r.randf_range(140.0, RIM - 30.0)
		var z := r.randf_range(-210.0, 130.0)
		if not _clear(x, z, 6.0):
			continue
		var s := r.randf_range(0.8, 1.7)
		rib_x.append(Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3.ONE * s), Vector3(x, height_at(x, z) - 2.0, z)))
		_solid(Vector3(x, height_at(x, z), z), 1.5, 4.0)
	ForgeMesh.scatter(self, rib_mesh, bone, rib_x)
	# a spine of ruins along the old road north
	var pillars: Array = []
	for i in range(4):
		pillars.append(ForgeMesh.pillar(r, r.randf_range(6.0, 11.0), 1.3))
	for i in range(34):
		var side := -1.0 if i % 2 == 0 else 1.0
		var z := 300.0 - float(i / 2) * 36.0
		var x := side * r.randf_range(12.0, 18.0)
		if not _clear(x, z, 2.0):
			continue
		var mi := ForgeMesh.inst(pillars[i % pillars.size()], pale_stone, self)
		_place_on_ground(mi, x, z, 0.3)
		mi.rotation = Vector3(r.randf_range(-0.05, 0.05), r.randf() * TAU, r.randf_range(-0.05, 0.05))
		_solid(mi.position, 0.8, 6.0)
	# the rim: stepped black mesas
	for i in range(40):
		var a := TAU * float(i) / 40.0 + r.randf_range(-0.05, 0.05)
		var rad := r.randf_range(RIM + 30.0, RIM + 90.0)
		var mb := ForgeMesh.Builder.new()
		var w := r.randf_range(26.0, 56.0)
		var h := r.randf_range(30.0, 110.0)
		var steps := 2 + int(r.randi() % 3)
		var y := 0.0
		for k in range(steps):
			var sh := h / float(steps) * r.randf_range(0.8, 1.2)
			var sw := w * (1.0 - 0.24 * float(k))
			mb.box(Vector3(sw, sh, sw * r.randf_range(0.7, 1.0)), Vector3(r.randf_range(-2, 2) * float(k), y + sh * 0.5, r.randf_range(-2, 2) * float(k)), Vector3(0, r.randf_range(0, 30) * float(k), 0))
			y += sh
		var mi := ForgeMesh.inst(mb.commit(), dark, self)
		mi.position = Vector3(cos(a) * rad, 8.0, sin(a) * rad)
		mi.rotation.y = r.randf() * TAU
	# clouds: flat pale slabs high up
	var cloud_mat := StandardMaterial3D.new()
	cloud_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cloud_mat.albedo_color = Color(0.5, 0.52, 0.57)
	cloud_mat.disable_fog = true
	for i in range(22):
		var cb := ForgeMesh.Builder.new()
		var w := r.randf_range(60.0, 140.0)
		var d := r.randf_range(30.0, 60.0)
		cb.box(Vector3(w, 5.0, d))
		cb.box(Vector3(w * 0.6, 5.0, d * 0.7), Vector3(w * r.randf_range(-0.3, 0.3), 3.5, d * r.randf_range(-0.3, 0.3)))
		var mi := ForgeMesh.inst(cb.commit(), cloud_mat, self)
		var a := r.randf() * TAU
		var rad := r.randf_range(80.0, 600.0)
		mi.position = Vector3(cos(a) * rad, r.randf_range(150.0, 230.0), sin(a) * rad)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# drifting ash, carried with the camera
	_ash = GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(26, 10, 26)
	pm.direction = Vector3(1, -0.25, 0.3)
	pm.spread = 25.0
	pm.initial_velocity_min = 0.6
	pm.initial_velocity_max = 2.2
	pm.gravity = Vector3(0, -0.25, 0)
	pm.scale_min = 0.5
	pm.scale_max = 1.6
	_ash.process_material = pm
	_ash.amount = 220
	_ash.lifetime = 7.0
	_ash.preprocess = 7.0
	var q := QuadMesh.new()
	q.size = Vector2(0.07, 0.07)
	var qm := ForgeMesh.ghost(Color(0.95, 0.95, 1.0, 0.75), false)
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	q.material = qm
	_ash.draw_pass_1 = q
	_ash.visibility_aabb = AABB(Vector3(-40, -20, -40), Vector3(80, 40, 80))
	add_child(_ash)


## The finer things: ribcages of the long dead, fallen stone, and half-sunk
## masks in the sand.
func _build_dressing() -> void:
	var r := Rng.make(["ashfall", "dressing"])
	var b := ForgeMesh.Builder.new()
	var lit := ForgeMesh.Builder.new()
	var placed := 0
	var tries := 0
	while placed < 9 and tries < 200:
		tries += 1
		var x := r.randf_range(-RIM + 40.0, RIM - 40.0)
		var z := r.randf_range(-RIM + 40.0, RIM - 60.0)
		if Vector2(x, z).length() > RIM - 40.0 or not _clear(x, z, 16.0) or not dress_clear(x, z, 16.0) or (x < -120.0 and absf(z) < 190.0):
			continue
		var span := r.randf_range(12.0, 20.0)
		Detail.bone_arch(b, Vector3(x, height_at(x, z) - 1.2, z), r.randf() * 360.0, span, Color(0.88, 0.86, 0.8).darkened(r.randf() * 0.1))
		placed += 1
	for i in range(70):
		var x := r.randf_range(-RIM, RIM)
		var z := r.randf_range(-RIM, RIM)
		if Vector2(x, z).length() > RIM - 8.0 or not _clear(x, z, 4.0) or not dress_clear(x, z):
			continue
		var s := r.randf_range(1.2, 3.4)
		Detail.rock_pile(b, Vector3(x, height_at(x, z) - 0.2, z), r.randf() * 360.0, s, Color(0.5, 0.51, 0.55).darkened(r.randf() * 0.15), r)
		_solid(Vector3(x, height_at(x, z), z), s * 0.55, s)
	# masks half sunk in the sand, staring up
	for i in range(40):
		var x := r.randf_range(-RIM, RIM)
		var z := r.randf_range(-RIM, RIM)
		if Vector2(x, z).length() > RIM - 8.0 or not _clear(x, z, 2.0) or not dress_clear(x, z, 1.0):
			continue
		var keep := b.xf
		b.xf = Transform3D(Basis(Vector3.UP, r.randf() * TAU) * Basis(Vector3.RIGHT, deg_to_rad(r.randf_range(-70, -40))), Vector3(x, height_at(x, z) + 0.1, z))
		b.col = Color(0.93, 0.92, 0.88)
		b.box(Vector3(0.9, 1.1, 0.25))
		b.box(Vector3(0.7, 0.3, 0.3), Vector3(0, -0.6, 0.02))
		b.col = Color(0.08, 0.08, 0.1)
		b.box(Vector3(0.22, 0.16, 0.1), Vector3(-0.2, 0.15, -0.12))
		b.box(Vector3(0.22, 0.16, 0.1), Vector3(0.2, 0.15, -0.12))
		b.col = Color(0.75, 0.15, 0.2)
		b.box(Vector3(0.08, 0.6, 0.1), Vector3(0.28, 0.0, -0.12), Vector3(0, 0, 12))
		b.xf = keep
	Detail.commit(self, b, lit, _vertex_paint())


func _vertex_paint() -> StandardMaterial3D:
	var m := ForgeMesh.grain(Color(1, 1, 1), "slate", 0.18)
	m.vertex_color_use_as_albedo = true
	return m


func _build_court() -> void:
	var r := Rng.make(["ashfall", "court"])
	var stone := ForgeMesh.grain(Color(0.4, 0.42, 0.46), "slate")
	var pale := ForgeMesh.grain(Color(0.62, 0.64, 0.68), "slate")
	var y := height_at(COURT.x, COURT.z)
	var base := Vector3(COURT.x, y, COURT.z)
	for i in range(3):
		var ring := ForgeMesh.inst(ForgeMesh.ring(0.93, 48), ForgeMesh.mat(Color(0.16, 0.17, 0.2), 1.0), self, base + Vector3(0, 0.04 + 0.01 * float(i), 0))
		ring.scale = Vector3(COURT_R - 1.0 - float(i) * 6.5, 1.0, COURT_R - 1.0 - float(i) * 6.5)
	for i in range(16):
		var a := TAU * float(i) / 16.0
		if absf(wrapf(a - PI * 0.5, -PI, PI)) < 0.3:
			continue
		var p := base + Vector3(cos(a), 0, sin(a)) * (COURT_R + 0.5)
		var h := r.randf_range(7.0, 15.0)
		var mi := ForgeMesh.inst(ForgeMesh.pillar(r, h, 1.6), stone, self, Vector3(p.x, height_at(p.x, p.z) - 0.3, p.z))
		mi.rotation.y = r.randf() * TAU
		_solid(mi.position, 0.9, h)
	var gate_z := COURT.z + COURT_R + 0.5
	for side: float in [-1.0, 1.0]:
		var gx := side * 4.4
		var gy := height_at(gx, gate_z) - 0.3
		_block(self, Vector3(2.4, 1.0, 2.4), Vector3(gx, gy + 0.5, gate_z), stone)
		_block(self, Vector3(1.8, 9.0, 1.8), Vector3(gx, gy + 5.5, gate_z), stone)
		_block(self, Vector3(2.4, 0.8, 2.4), Vector3(gx, gy + 10.4, gate_z), stone)
		_solid(Vector3(gx, gy, gate_z), 1.1, 10.0)
	var ly := height_at(0, gate_z) + 10.9
	_block(self, Vector3(13.0, 1.6, 2.6), Vector3(0, ly, gate_z), stone, Vector3(0, 0, -2.5))
	_block(self, Vector3(8.0, 1.0, 2.0), Vector3(0.4, ly + 1.3, gate_z), stone, Vector3(0, 0, -2.5))
	var sz := COURT.z - COURT_R - 4.0
	var sy := height_at(0, sz)
	var statue := Node3D.new()
	statue.position = Vector3(0, sy, sz)
	add_child(statue)
	_block(statue, Vector3(10.0, 2.0, 8.0), Vector3(0, 1.0, 0), stone)
	_block(statue, Vector3(8.0, 1.2, 6.0), Vector3(0, 2.6, 0), stone)
	_block(statue, Vector3(2.0, 5.0, 2.2), Vector3(-1.1, 5.7, 0), pale)
	_block(statue, Vector3(2.0, 5.0, 2.2), Vector3(1.1, 5.7, 0), pale)
	_block(statue, Vector3(4.6, 5.0, 2.4), Vector3(0, 10.7, 0), pale)
	_block(statue, Vector3(2.4, 2.4, 2.4), Vector3(0, 14.2, 0.5), pale, Vector3(22, 0, 0))
	for side: float in [-1.0, 1.0]:
		var wing := ForgeMesh.inst(ForgeMesh.wing(r, 15.0, 8, side), pale, statue, Vector3(side * 2.0, 12.0, -1.4))
		wing.rotation_degrees = Vector3(-8, side * -22.0, 0)
		_block(statue, Vector3(1.5, 5.0, 1.5), Vector3(side * 3.1, 10.6, 1.4), pale, Vector3(-38, 0, 0))
	_solid(Vector3(0, sy, sz), 4.8, 12.0)
	var yoke_z := COURT.z - COURT_R + 4.0
	for side: float in [-1.0, 1.0]:
		_block(self, Vector3(1.0, 9.0, 1.0), Vector3(side * 3.6, y + 4.5, yoke_z), stone)
	_block(self, Vector3(9.0, 1.0, 1.2), Vector3(0, y + 9.4, yoke_z), stone)
	var cold := OmniLight3D.new()
	cold.light_color = Color(0.7, 0.85, 1.0)
	cold.light_energy = 2.0
	cold.omni_range = 34.0
	cold.position = base + Vector3(0, 12, 0)
	add_child(cold)
	# the Many-Mouthed's clearing: a ring of broken crystal stumps
	var stump := ForgeMesh.grain(Color(0.2, 0.32, 0.34), "slate", 0.12)
	for i in range(12):
		var a := TAU * float(i) / 12.0
		var p := Vector3(MOUTH.x + cos(a) * 34.0, 0, MOUTH.z + sin(a) * 34.0)
		_block(self, Vector3(2.4, r.randf_range(2.0, 6.0), 2.4), Vector3(p.x, height_at(p.x, p.z) + 1.0, p.z), stump, Vector3(r.randf_range(-12, 12), r.randf() * 90.0, r.randf_range(-12, 12)))


## The Sunken Throne: a black palace half under the sand.
func _build_throne() -> void:
	var r := Rng.make(["ashfall", "throne"])
	var black := ForgeMesh.grain(Color(0.1, 0.1, 0.12), "slate", 0.08)
	var gold := ForgeMesh.glow(Color(1.0, 0.75, 0.2), 1.6)
	var y := height_at(THRONE.x, THRONE.z)
	var back := THRONE.z - 44.0
	var hall := ForgeMesh.Builder.new()
	hall.box(Vector3(80, 18, 30), Vector3(0, 9, 0))
	hall.box(Vector3(56, 14, 24), Vector3(0, 25, -2))
	hall.box(Vector3(30, 12, 18), Vector3(0, 38, -4))
	for side: float in [-1.0, 1.0]:
		hall.box(Vector3(12, 60, 12), Vector3(side * 46.0, 30, 6))
		hall.box(Vector3(8, 14, 8), Vector3(side * 46.0, 67, 6))
		hall.box(Vector3(16, 8, 16), Vector3(side * 28.0, 4, 18))
	ForgeMesh.inst(hall.commit(), black, self, Vector3(0, y - 6.0, back))
	_solid_box(Vector3(0, y, back), Vector3(80, 40, 30))
	for side: float in [-1.0, 1.0]:
		_solid(Vector3(side * 46.0, y, back + 6.0), 7.0, 50.0)
	# the throne itself, and steps up to it
	for k in range(4):
		_block(self, Vector3(24.0 - 4.0 * float(k), 0.6, 4.0), Vector3(0, y + 0.3 + 0.6 * float(k), THRONE.z - 18.0 - 3.6 * float(k)), black)
	_block(self, Vector3(6.0, 9.0, 3.0), Vector3(0, y + 6.0, THRONE.z - 32.0), black)
	_block(self, Vector3(7.0, 0.4, 0.3), Vector3(0, y + 10.7, THRONE.z - 30.4), gold)
	# a ring of fallen columns round the floor where Sereth waits
	for i in range(10):
		var a := TAU * float(i) / 10.0
		var p := Vector3(THRONE.x + cos(a) * 32.0, 0, THRONE.z + sin(a) * 32.0)
		if sin(a) < -0.6:
			continue
		var h := r.randf_range(4.0, 12.0)
		_block(self, Vector3(2.6, h, 2.6), Vector3(p.x, height_at(p.x, p.z) + h * 0.5 - 0.6, p.z), black, Vector3(r.randf_range(-8, 8), r.randf() * 90.0, r.randf_range(-8, 8)))
		_solid(Vector3(p.x, height_at(p.x, p.z), p.z), 1.6, h)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.75, 0.35)
	l.light_energy = 2.4
	l.omni_range = 40.0
	l.position = Vector3(THRONE.x, y + 12.0, THRONE.z)
	add_child(l)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _ash != null and cam != null:
		_ash.global_position = cam.global_position
