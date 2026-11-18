class_name Undermark
extends Region
## The Undermark: the hell beneath every realm, where souls struck from the
## Ledger are chained. About 600 metres of black rock and lava under a red
## dark, reached by breaking the seal in the Wastes (Grade 2 and above).
##
## Its rules: every death here brands you, and each brand takes a part of
## your vitality until you leave; lava burns; Gaolers get up again unless
## someone devours them or sends them on. The Branded King holds the west,
## Gaoler Prime the east, and on an island in a lake of fire, behind a seal
## that opens at Grade 1, sits the First Unwrit.

const SIZE: float = 640.0
const CELLS: int = 112
const RIM: float = 288.0
const WAKE := Vector3(0, 0, 258)
const KING := Vector3(-150, 0, -60)
const YARD := Vector3(160, 0, -90)
const THRONE := Vector3(0, 0, -238)
const MOAT_R: float = 44.0
const LAVA_Y: float = -3.0
const CAIRNS: Array = [Vector3(-14, 0, 248), Vector3(-110, 0, 70), Vector3(120, 0, 50), Vector3(0, 0, -150)]
const BRIDGES: Array = [Vector3(0, 0, 70), Vector3(-200, 0, 30), Vector3(200, 0, 110)]
const SPAWNS: Array = [
	["damned", -30, 220, 22], ["damned", 30, 214, 22], ["cinder", -60, 190, 22], ["cinder", 60, 186, 22],
	["chainbound", 0, 160, 23], ["damned", -90, 150, 23], ["damned", 90, 140, 23], ["gaoler", 0, 110, 24],
	["cinder", -150, 120, 24], ["chainbound", 150, 150, 24], ["stalker", -60, 20, 25], ["stalker", 60, 10, 25],
	["damned", -120, -20, 26], ["chainbound", -170, 0, 26], ["gaoler", -110, -110, 27], ["cinder", -190, -100, 26],
	["damned", 120, -30, 26], ["gaoler", 130, -150, 27], ["chainbound", 200, -40, 27], ["cinder", 210, -120, 27],
	["wraith", -40, -120, 28], ["wraith", 40, -125, 28], ["gaoler", -50, -175, 29], ["gaoler", 50, -175, 29],
]
const RELICS: Array = [
	[-80, 200, "A brand-iron, cold. The mark on its face is a name that has been crossed out."],
	[170, 20, "A key the size of your arm. It fits nothing here."],
	[-200, -150, "A crown made of chain links. Whoever wore it was very proud of it once."],
	[60, -190, "A ledger page with every line struck out. At the bottom, in a small hand: 'me too'."],
]
const STELES: Array = [
	[16, 240, "THE UNDERMARK. WHEN THE LEDGER STRIKES A NAME OUT, THE SOUL FALLS HERE. NOTHING HERE CAN DIE PROPERLY. NOT EVEN YOU."],
	[-130, -30, "THE BRANDED KING RULED A REALM ABOVE. WHEN HE FELL HE BROUGHT HIS CROWN, AND MADE THE DAMNED KNEEL TO IT."],
	[140, -60, "THE GAOLERS WERE PUT HERE TO KEEP THE DAMNED IN. NOBODY PUT ANYONE HERE TO KEEP THE GAOLERS IN."],
	[18, -168, "ON THE ISLAND SITS THE FIRST SOUL EVER STRUCK FROM THE LEDGER. IT HAS BEEN WAITING FOR ANOTHER UNWRIT."],
]

var noise: FastNoiseLite = FastNoiseLite.new()
var field: Heightfield
var _seal: StaticBody3D
var _seal_mesh: Node3D
var _burn_t: float = 0.0
var _embers: GPUParticles3D


func _ready() -> void:
	region_id = "undermark"
	place_name = "The Undermark"
	bounds = RIM
	level_base = 24
	soul.flags["brands"] = 0
	noise.seed = 66
	noise.frequency = 0.012
	noise.fractal_octaves = 4
	field = Heightfield.new(SIZE, CELLS, _raw_height, _tint)
	_build_sky()
	field.build(self, "ash")
	_build_lava()
	_build_chains()
	_build_courts()
	_build_throne()
	_build_dressing()
	_build_points()
	Fx.root = self
	Sfx.loop("wind", "wind", -14.0)
	Sfx.loop("music", music_name(), -13.0)


func wake_point() -> Vector3:
	return WAKE


func cairn_points() -> Array:
	return CAIRNS


func spawn_list() -> Array:
	return SPAWNS


func elite_chance() -> float:
	return 0.25


func boss_list() -> Array:
	return [
		["branded_king", KING.x, KING.z, 28, 26.0, 90.0],
		["gaoler_prime", YARD.x, YARD.z, 30, 30.0, -90.0],
		["first_unwrit", THRONE.x, THRONE.z + 6.0, 34, 24.0, 0.0],
	]


func relic_list() -> Array:
	return RELICS


func stele_list() -> Array:
	return STELES


func portal_list() -> Array:
	return [[0.0, 274.0, "ashfall", "Climb back up to the Wastes", ""]]


func music_name() -> String:
	return "music_deep"


func objective() -> String:
	var b := int(soul.flags.get("brands", 0))
	var line := Quests.promotion_gap(soul)
	if b > 0:
		line = "Branded %d time%s: vitality -%d%% until you leave. %s" % [b, "" if b == 1 else "s", 6 * mini(b, 5), line]
	return line


# ----------------------------------------------------------------- terrain

## The lava: a river crossing the middle, and the moat round the island.
func lava_at(x: float, z: float) -> bool:
	if absf(z - (40.0 + 34.0 * sin(x / 60.0))) < 9.0:
		return true
	var d := Vector2(x - THRONE.x, z - THRONE.z).length()
	return d > MOAT_R - 14.0 and d < MOAT_R


func _raw_height(x: float, z: float) -> float:
	var h := noise.get_noise_2d(x, z) * 7.0 + absf(noise.get_noise_2d(x * 2.6, z * 2.6)) * 3.0
	# plain rock never sinks to the lava: only the rivers and the moat do
	h = maxf(h, 0.0)
	var d := Vector2(x, z).length()
	if d > RIM - 8.0:
		h += minf(60.0, pow((d - RIM + 8.0) * 0.7, 1.5))
	var river := absf(z - (40.0 + 34.0 * sin(x / 60.0)))
	h = lerpf(h, -6.0, 1.0 - smoothstep(8.0, 16.0, river))
	var td := Vector2(x - THRONE.x, z - THRONE.z).length()
	if td < MOAT_R + 8.0:
		var ring := absf(td - (MOAT_R - 7.0))
		h = lerpf(h, -6.0, 1.0 - smoothstep(6.0, 12.0, ring))
		if td < MOAT_R - 16.0:
			h = 2.0
	h = Heightfield.flatten(h, x, z, WAKE.x, WAKE.z, 16.0, 1.0)
	h = Heightfield.flatten(h, x, z, KING.x, KING.z, 26.0, 0.5)
	h = Heightfield.flatten(h, x, z, YARD.x, YARD.z, 30.0, 0.5)
	for c: Variant in CAIRNS:
		h = Heightfield.flatten(h, x, z, (c as Vector3).x, (c as Vector3).z, 6.0, h)
	return h


func height_at(x: float, z: float) -> float:
	var h := field.height_at(x, z) if field != null else 0.0
	# the bridges carry you over the lava
	for b: Variant in BRIDGES:
		var bp: Vector3 = b
		if absf(x - bp.x) < 3.2 and absf(z - (40.0 + 34.0 * sin(bp.x / 60.0))) < 14.0:
			return maxf(h, 0.6)
	if absf(x - THRONE.x) < 3.2 and z > THRONE.z + MOAT_R - 20.0 and z < THRONE.z + MOAT_R + 6.0:
		return maxf(h, 1.2)
	return h


func _tint(mid: Vector3, n: Vector3) -> Color:
	var slope := clampf(1.0 - n.y, 0.0, 1.0)
	var grain := noise.get_noise_2d(mid.x * 5.0, mid.z * 5.0) * 0.03
	var v := 0.2 - slope * 0.08 + grain
	if mid.y < -2.0:
		return Color(0.35, 0.12, 0.05)
	return Color(v * 1.15, v * 0.92, v * 0.85)


func _build_sky() -> void:
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.05, 0.0, 0.0)
	sm.sky_horizon_color = Color(0.45, 0.08, 0.04)
	sm.sky_curve = 0.15
	sm.ground_bottom_color = Color(0.05, 0.0, 0.0)
	sm.ground_horizon_color = Color(0.45, 0.08, 0.04)
	sm.sun_angle_max = 0.0
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.45, 0.35)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 1.0
	env.glow_hdr_threshold = 1.0
	env.fog_enabled = true
	env.fog_light_color = Color(0.4, 0.1, 0.05)
	env.fog_density = 0.0055
	env.fog_sky_affect = 0.0
	Detail.polish(env)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-24, 20, 0)
	key.light_color = Color(1.0, 0.45, 0.25)
	key.light_energy = 0.9
	key.shadow_enabled = true
	key.directional_shadow_max_distance = 90.0
	add_child(key)


func _build_lava() -> void:
	var lava := ForgeMesh.mat(Color(1.0, 0.35, 0.05), 0.4)
	lava.emission_enabled = true
	lava.emission = Color(1.0, 0.35, 0.05)
	lava.emission_energy_multiplier = 1.8
	var b := ForgeMesh.Builder.new()
	b.box(Vector3(SIZE, 0.2, SIZE), Vector3(0, LAVA_Y, 0))
	var mi := ForgeMesh.inst(b.commit(), lava, self)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var lights := 0
	for i in range(14):
		var x := -260.0 + 40.0 * float(i)
		var z := 40.0 + 34.0 * sin(x / 60.0)
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.4, 0.1)
		l.light_energy = 2.6
		l.omni_range = 34.0
		l.position = Vector3(x, LAVA_Y + 4.0, z)
		add_child(l)
		lights += 1
	# chain bridges over the river
	var iron := ForgeMesh.mat(Color(0.3, 0.28, 0.26), 0.5, 0.6)
	for bp: Variant in BRIDGES:
		var p: Vector3 = bp
		var cz := 40.0 + 34.0 * sin(p.x / 60.0)
		var bb := ForgeMesh.Builder.new()
		for k in range(14):
			bb.box(Vector3(5.6, 0.3, 1.8), Vector3(0, 0.45, -13.0 + 2.0 * float(k)))
		for sx: float in [-1.0, 1.0]:
			bb.box(Vector3(0.2, 0.2, 28.0), Vector3(sx * 3.0, 1.6, 0))
			for k in range(8):
				bb.box(Vector3(0.18, 1.4, 0.18), Vector3(sx * 3.0, 0.9, -14.0 + 4.0 * float(k)))
		ForgeMesh.inst(bb.commit(), iron, self, Vector3(p.x, 0.0, cz))
		_solid_box(Vector3(p.x, 0.3, cz), Vector3(6.0, 0.6, 28.0))
	var island := ForgeMesh.Builder.new()
	for k in range(14):
		island.box(Vector3(5.6, 0.3, 1.8), Vector3(0, 1.05, float(k) * 2.0))
	ForgeMesh.inst(island.commit(), iron, self, Vector3(THRONE.x, 0.0, THRONE.z + MOAT_R - 20.0))
	_solid_box(Vector3(THRONE.x, 0.9, THRONE.z + MOAT_R - 7.0), Vector3(6.0, 0.6, 28.0))
	_embers = GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(30, 4, 30)
	pm.direction = Vector3(0.1, 1.0, 0.0)
	pm.spread = 30.0
	pm.initial_velocity_min = 0.8
	pm.initial_velocity_max = 2.6
	pm.gravity = Vector3(0, 0.3, 0)
	pm.scale_min = 0.5
	pm.scale_max = 1.5
	_embers.process_material = pm
	_embers.amount = 260
	_embers.lifetime = 7.0
	_embers.preprocess = 7.0
	var q := QuadMesh.new()
	q.size = Vector2(0.08, 0.08)
	var qm := ForgeMesh.ghost(Color(1.0, 0.55, 0.15, 0.9))
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	q.material = qm
	_embers.draw_pass_1 = q
	_embers.visibility_aabb = AABB(Vector3(-40, -20, -40), Vector3(80, 40, 80))
	add_child(_embers)


## Great chains hanging out of the dark, anchored in the rock.
func _build_chains() -> void:
	var r := Rng.make(["undermark", "chains"])
	var iron := ForgeMesh.mat(Color(0.22, 0.2, 0.19), 0.5, 0.6)
	var link := ForgeMesh.Builder.new()
	for k in range(60):
		var y := float(k) * 3.4
		link.box(Vector3(1.6 if k % 2 == 0 else 0.5, 3.0, 0.5 if k % 2 == 0 else 1.6), Vector3(0, y + 1.5, 0))
	var mesh := link.commit()
	var xs: Array = []
	for i in range(18):
		var a := r.randf() * TAU
		var d := r.randf_range(40.0, RIM - 30.0)
		var x := cos(a) * d
		var z := sin(a) * d
		if lava_at(x, z) or Vector2(x - THRONE.x, z - THRONE.z).length() < MOAT_R + 8.0:
			continue
		xs.append(Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3.ONE * r.randf_range(0.8, 1.4)), Vector3(x, height_at(x, z) - 1.0, z)))
		_solid(Vector3(x, height_at(x, z), z), 1.0, 10.0)
		_block(self, Vector3(4.0, 2.0, 4.0), Vector3(x, height_at(x, z) + 0.6, z), ForgeMesh.grain(Color(0.25, 0.22, 0.2), "slate"))
	ForgeMesh.scatter(self, mesh, iron, xs)
	# cages, some with something in them
	var cage := ForgeMesh.Builder.new()
	cage.box(Vector3(4.0, 0.3, 4.0), Vector3(0, 0.15, 0))
	cage.box(Vector3(4.0, 0.3, 4.0), Vector3(0, 4.6, 0))
	for k in range(8):
		var t := float(k) / 8.0 * TAU
		cage.box(Vector3(0.16, 4.4, 0.16), Vector3(cos(t) * 1.9, 2.4, sin(t) * 1.9))
	var cage_mesh := cage.commit()
	var cx: Array = []
	for i in range(30):
		var x := r.randf_range(-RIM + 20.0, RIM - 20.0)
		var z := r.randf_range(-RIM + 20.0, RIM - 20.0)
		if Vector2(x, z).length() > RIM - 20.0 or lava_at(x, z) or Vector2(x - THRONE.x, z - THRONE.z).length() < MOAT_R + 8.0:
			continue
		cx.append(Transform3D(Basis(Vector3.UP, r.randf() * TAU), Vector3(x, height_at(x, z) - 0.1, z)))
		_solid(Vector3(x, height_at(x, z), z), 2.0, 4.6)
	ForgeMesh.scatter(self, cage_mesh, iron, cx)
	# black spires and the rim
	var rock := ForgeMesh.grain(Color(0.16, 0.13, 0.12), "slate", 0.08)
	for i in range(30):
		var a := TAU * float(i) / 30.0
		var rad := r.randf_range(RIM + 20.0, RIM + 70.0)
		var mb := ForgeMesh.Builder.new()
		var w := r.randf_range(24.0, 50.0)
		var h := r.randf_range(50.0, 130.0)
		mb.box(Vector3(w, h, w * 0.8), Vector3(0, h * 0.5, 0), Vector3(r.randf_range(-6, 6), 0, r.randf_range(-6, 6)))
		mb.box(Vector3(w * 0.5, h * 0.5, w * 0.4), Vector3(r.randf_range(-6, 6), h + h * 0.2, 0), Vector3(0, 0, r.randf_range(-14, 14)))
		var mi := ForgeMesh.inst(mb.commit(), rock, self)
		mi.position = Vector3(cos(a) * rad, 6.0, sin(a) * rad)
		mi.rotation.y = r.randf() * TAU
	var rocks: Array = [ForgeMesh.rock(r, 1.0), ForgeMesh.rock(r, 1.0)]
	var rx: Array = [[], []]
	for i in range(300):
		var x := r.randf_range(-RIM, RIM)
		var z := r.randf_range(-RIM, RIM)
		if Vector2(x, z).length() > RIM - 6.0 or lava_at(x, z):
			continue
		var s := r.randf_range(0.6, 2.6)
		(rx[i % 2] as Array).append(Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3.ONE * s), Vector3(x, height_at(x, z) - 0.2 * s, z)))
	for k in range(2):
		ForgeMesh.scatter(self, rocks[k], rock, rx[k])


func _build_courts() -> void:
	var stone := ForgeMesh.grain(Color(0.2, 0.17, 0.15), "slate", 0.1)
	var gold := ForgeMesh.glow(Color(1.0, 0.6, 0.15), 2.2)
	var y := height_at(KING.x, KING.z)
	# the Branded King's court: a ring of braziers round a throne of chains
	for i in range(10):
		var a := TAU * float(i) / 10.0
		var p := Vector3(KING.x + cos(a) * 24.0, 0, KING.z + sin(a) * 24.0)
		_block(self, Vector3(1.6, 4.0, 1.6), Vector3(p.x, height_at(p.x, p.z) + 2.0, p.z), stone)
		_block(self, Vector3(1.2, 0.8, 1.2), Vector3(p.x, height_at(p.x, p.z) + 4.4, p.z), gold, Vector3(0, 45, 0))
		_solid(Vector3(p.x, height_at(p.x, p.z), p.z), 1.0, 4.0)
	_block(self, Vector3(8.0, 2.0, 6.0), Vector3(KING.x - 18.0, y + 1.0, KING.z), stone)
	_block(self, Vector3(4.0, 8.0, 1.2), Vector3(KING.x - 20.4, y + 6.0, KING.z), stone)
	var kl := OmniLight3D.new()
	kl.light_color = Color(1.0, 0.55, 0.2)
	kl.light_energy = 2.4
	kl.omni_range = 40.0
	kl.position = Vector3(KING.x, y + 10.0, KING.z)
	add_child(kl)
	# Gaoler Prime's yard: a great gate in a wall of iron
	var iron := ForgeMesh.mat(Color(0.22, 0.2, 0.19), 0.5, 0.6)
	var gy := height_at(YARD.x, YARD.z)
	var wall := ForgeMesh.Builder.new()
	wall.box(Vector3(2.0, 20.0, 60.0), Vector3(30.0, 10.0, 0))
	wall.box(Vector3(14.0, 34.0, 4.0), Vector3(32.0, 17.0, -20.0))
	wall.box(Vector3(14.0, 34.0, 4.0), Vector3(32.0, 17.0, 20.0))
	for k in range(9):
		wall.box(Vector3(0.6, 18.0, 0.6), Vector3(30.0, 9.0, -16.0 + 4.0 * float(k)))
	ForgeMesh.inst(wall.commit(), iron, self, Vector3(YARD.x, gy, YARD.z))
	_solid_box(Vector3(YARD.x + 30.0, gy + 10.0, YARD.z), Vector3(2.0, 20.0, 60.0))
	var yl := OmniLight3D.new()
	yl.light_color = Color(1.0, 0.35, 0.15)
	yl.light_energy = 2.2
	yl.omni_range = 44.0
	yl.position = Vector3(YARD.x, gy + 12.0, YARD.z)
	add_child(yl)


## The island: a white throne on black rock, behind a seal for Grade 1.
## Black glass spires with burning seams, gibbets, and broken stone.
func _build_dressing() -> void:
	var r := Rng.make(["undermark", "dressing"])
	var b := ForgeMesh.Builder.new()
	var lit := ForgeMesh.Builder.new()
	for i in range(60):
		var x := r.randf_range(-RIM, RIM)
		var z := r.randf_range(-RIM, RIM)
		if Vector2(x, z).length() > RIM - 10.0 or lava_at(x, z) or not dress_clear(x, z, 6.0):
			continue
		var h := r.randf_range(6.0, 22.0)
		Detail.obsidian_spire(b, lit, Vector3(x, height_at(x, z) - 0.5, z), r.randf() * 360.0, h, r)
		_solid(Vector3(x, height_at(x, z), z), h * 0.08, h)
	for i in range(14):
		var x := r.randf_range(-RIM + 20.0, RIM - 20.0)
		var z := r.randf_range(-RIM + 20.0, RIM - 20.0)
		if Vector2(x, z).length() > RIM - 20.0 or lava_at(x, z) or not dress_clear(x, z, 4.0):
			continue
		Detail.gibbet(b, Vector3(x, height_at(x, z), z), r.randf() * 360.0)
		_solid(Vector3(x, height_at(x, z), z), 0.3, 6.0)
	for i in range(60):
		var x := r.randf_range(-RIM, RIM)
		var z := r.randf_range(-RIM, RIM)
		if Vector2(x, z).length() > RIM - 8.0 or lava_at(x, z) or not dress_clear(x, z):
			continue
		var s := r.randf_range(1.0, 3.0)
		Detail.rock_pile(b, Vector3(x, height_at(x, z) - 0.2, z), r.randf() * 360.0, s, Color(0.2, 0.12, 0.1).lightened(r.randf() * 0.08), r)
		_solid(Vector3(x, height_at(x, z), z), s * 0.55, s)
	var m := ForgeMesh.grain(Color(1, 1, 1), "slate", 0.18)
	m.vertex_color_use_as_albedo = true
	Detail.commit(self, b, lit, m, 2.6)


func _build_throne() -> void:
	var y := height_at(THRONE.x, THRONE.z)
	var white := ForgeMesh.mat(Color(0.92, 0.92, 0.95), 0.5)
	var b := ForgeMesh.Builder.new()
	b.box(Vector3(14.0, 1.0, 10.0), Vector3(0, 0.5, -14.0))
	b.box(Vector3(5.0, 1.4, 4.0), Vector3(0, 1.7, -14.0))
	b.box(Vector3(5.0, 9.0, 1.0), Vector3(0, 5.0, -16.0))
	for sx: float in [-1.0, 1.0]:
		b.box(Vector3(1.0, 3.0, 4.0), Vector3(sx * 2.6, 2.5, -14.0))
		b.box(Vector3(1.4, 22.0, 1.4), Vector3(sx * 9.0, 11.0, -10.0))
	ForgeMesh.inst(b.commit(), white, self, Vector3(THRONE.x, y, THRONE.z))
	var halo := ForgeMesh.inst(ForgeMesh.ring(0.9, 40), ForgeMesh.glow(Color(1, 1, 1), 2.0), self, Vector3(THRONE.x, y + 10.0, THRONE.z - 15.8))
	halo.rotation_degrees = Vector3(90, 0, 0)
	halo.scale = Vector3.ONE * 4.0
	var l := OmniLight3D.new()
	l.light_color = Color(0.95, 0.95, 1.0)
	l.light_energy = 2.4
	l.omni_range = 40.0
	l.position = Vector3(THRONE.x, y + 8.0, THRONE.z)
	add_child(l)
	if soul.grade > 1 and not bool(soul.flags.get("beat_first_unwrit", false)):
		var sz := THRONE.z + MOAT_R + 4.0
		_seal_mesh = Node3D.new()
		add_child(_seal_mesh)
		for k in range(5):
			_block(_seal_mesh, Vector3(0.5, 7.0, 0.5), Vector3(-2.4 + 1.2 * float(k), height_at(0, sz) + 3.5, sz), ForgeMesh.glow(Color(1.0, 1.0, 1.0), 1.6))
		_seal = _solid_box(Vector3(0, height_at(0, sz) + 3.5, sz), Vector3(7.0, 7.0, 1.0))


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if player == null:
		return
	if _embers != null and cam != null:
		_embers.global_position = cam.global_position
	# lava burns
	_burn_t -= delta
	var pp := player.global_position
	if player.alive and _burn_t <= 0.0 and lava_at(pp.x, pp.z) and pp.y < LAVA_Y + 1.6:
		_burn_t = 0.4
		player.apply_effect("dot", 2.2, null)
		player.slow_t = 0.6
		Fx.puff(player.global_position, Color(1.0, 0.45, 0.1, 0.6), 4, 0.5)


## Each death here is a brand. Vitality falls a little more each time.
func _on_respawn() -> void:
	var b := int(soul.flags.get("brands", 0)) + 1
	soul.flags["brands"] = b
	player.refresh_stats(true)
	say("You are branded. Vitality -%d%% until you leave the Undermark." % (6 * mini(b, 5)), "whisper")


func _special_death(e: Enemy) -> void:
	if e.kind == "first_unwrit" and not soul.release.is_empty() and int(soul.release.get("stage", 1)) < 3:
		soul.release["stage"] = 3
		soul.release["last"] = "the Last %s" % String(soul.release.get("spirit", "Name"))
		say("LAST RELEASE", "release")
		say("Your blade has its last name. Released, it hits harder and lasts longer, and blades turn about you.", "gain")
		main.save()
