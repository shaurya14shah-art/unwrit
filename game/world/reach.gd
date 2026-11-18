class_name Reach
extends Region
## The Silver Reach: the Archers' realm, about 520 metres across. Snow under
## a twilight that never ends, a frozen lake ringed by lantern towers, pine
## woods on either shore, and the Lantern Spire to the north where Ysolde
## keeps the last light. Archers gather here and take their notices from the
## Lantern board.

const SIZE: float = 560.0
const CELLS: int = 100
const RIM: float = 252.0
const WAKE := Vector3(0, 0, 226)
const LAKE_R: float = 70.0
const SPIRE := Vector3(0, 0, -186)
const CAIRNS: Array = [Vector3(-16, 0, 216), Vector3(-130, 0, 40), Vector3(118, 0, -50), Vector3(0, 0, -132)]
const SPAWNS: Array = [
	["hound", -40, 180, 9], ["hound", -48, 172, 9], ["wraith", 40, 170, 10], ["wraith", 52, 176, 10],
	["gleaner", -110, 120, 10], ["gleaner", 110, 110, 10], ["hound", 150, 140, 11], ["hound", 160, 130, 11],
	["wraith", -60, 60, 11], ["wraith", 60, 50, 11], ["stalker", -150, 20, 12], ["stalker", 150, -10, 12],
	["wraith", -40, -30, 12], ["wraith", 40, -40, 12], ["giant", -170, -90, 14], ["giant", 170, -110, 14],
	["sentinel", -30, -150, 14], ["sentinel", 30, -150, 14], ["stalker", -60, -160, 15], ["stalker", 60, -165, 15],
]
const RELICS: Array = [
	[-150, 150, "A lantern cracked down one side. Its owner kept it lit for a hundred years, and then stopped."],
	[100, 60, "A bowstring of light, still taut, tied to nothing."],
	[-90, -110, "A ring of keys, one for every tower on the lake. One is missing."],
	[150, -150, "A letter in Ysolde's hand: 'If the lights go out, it will be because I let them.'"],
]
const STELES: Array = [
	[16, 210, "THE SILVER REACH. ARCHERS GATHER WHAT LIGHT THE DEAD LEAVE BEHIND, AND SHOOT IT BACK INTO WHAT EATS THEM."],
	[-22, 96, "THE LANTERNS ON THE LAKE ARE THE LIGHTS OF ARCHERS WHO FELL. WHILE THEY BURN, THE DEVOURERS STAY AWAY."],
	[18, -118, "YSOLDE WAS THE LAST TO LIGHT HER LANTERN. NOW SHE WILL NOT LET ANY OTHER BURN BESIDE IT."],
]

var noise: FastNoiseLite = FastNoiseLite.new()
var field: Heightfield
var _snow: GPUParticles3D


func _ready() -> void:
	region_id = "reach"
	place_name = "The Silver Reach"
	bounds = RIM
	level_base = 10
	noise.seed = 41
	noise.frequency = 0.009
	noise.fractal_octaves = 3
	field = Heightfield.new(SIZE, CELLS, _raw_height, _tint)
	_build_sky()
	field.build(self, "snow")
	_build_lake()
	_build_towers()
	_build_woods()
	_build_spire()
	_build_dressing()
	_build_points()
	Fx.root = self
	Sfx.loop("wind", "wind", -18.0)
	Sfx.loop("music", music_name(), -15.0)


func wake_point() -> Vector3:
	return WAKE


func cairn_points() -> Array:
	return CAIRNS


func spawn_list() -> Array:
	return SPAWNS


func boss_list() -> Array:
	return [["ysolde", SPIRE.x, SPIRE.z + 18.0, 13, 26.0, 0.0]]


func board_list() -> Array:
	return [[14.0, 218.0, "lantern", 180.0], [28.0, 214.0, "exchange", 180.0], [42.0, 210.0, "forge", 180.0]]


func giver_list() -> Array:
	return [[-14.0, 214.0, 170.0, "g_odile", "Odile", "keeps the lamps", {"cloth": Color(0.92, 0.94, 0.98), "trim": Color(0.6, 0.5, 0.3), "coat": 2, "hair": 4, "hair_color": Color(0.9, 0.88, 0.8), "hair_seed": 95, "face": 3, "halo": true, "accent": Color(1.0, 0.85, 0.5)},
		["The lake is only frozen because we keep it lit.", "Sela fights. I keep the lamps. Both are the same job."]]]


func relic_list() -> Array:
	return RELICS


func stele_list() -> Array:
	return STELES


func portal_list() -> Array:
	return [[0.0, 242.0, "town", "Go back through the Lantern Door to Calder Town", ""]]


func music_name() -> String:
	return "music_reach"


func talker_list() -> Array:
	var lines: Array = [
		"Welcome to the Reach. I am Sela, Warden of the Lanterns. Mind the ice.",
		"The Lantern board is behind me. Bring the notices back done and you will climb.",
		"Ysolde is at the Spire, north, past the lake. She was the best of us. Do not go to her until you are ready.",
	]
	if soul.primary != "lumen" and soul.secondary != "lumen":
		lines = ["You are no Archer. The door let you through, so be welcome. The board is not for you."]
	return [[6.0, 210.0, 180.0, "Sela", lines, {"cloth": Color(0.92, 0.94, 0.98), "trim": Color(0.2, 0.4, 0.8), "coat": 2, "hair": 3, "hair_color": Color(0.3, 0.22, 0.16), "hair_seed": 61, "face": 0, "halo": true, "accent": Color(0.45, 0.85, 1.0), "sash": 1}]]


func objective() -> String:
	return Quests.promotion_gap(soul)


# ----------------------------------------------------------------- terrain

func _raw_height(x: float, z: float) -> float:
	var h := noise.get_noise_2d(x, z) * 6.0 + absf(noise.get_noise_2d(x * 2.4, z * 2.4)) * 2.0
	var d := Vector2(x, z).length()
	if d > RIM - 8.0:
		h += minf(40.0, pow((d - RIM + 8.0) * 0.6, 1.5))
	h = Heightfield.flatten(h, x, z, 0.0, 0.0, LAKE_R, -1.0, 1.25)
	h = Heightfield.flatten(h, x, z, WAKE.x, WAKE.z, 18.0, 1.0)
	h = Heightfield.flatten(h, x, z, SPIRE.x, SPIRE.z + 12.0, 30.0, 2.0)
	for c: Variant in CAIRNS:
		h = Heightfield.flatten(h, x, z, (c as Vector3).x, (c as Vector3).z, 6.0, h)
	return h


func height_at(x: float, z: float) -> float:
	return field.height_at(x, z) if field != null else 0.0


func _tint(mid: Vector3, n: Vector3) -> Color:
	var slope := clampf(1.0 - n.y, 0.0, 1.0)
	var grain := noise.get_noise_2d(mid.x * 5.0, mid.z * 5.0) * 0.03
	var v := 0.86 - slope * 0.3 + grain
	return Color(v * 0.93, v * 0.96, v)


func _build_sky() -> void:
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.04, 0.05, 0.16)
	sm.sky_horizon_color = Color(0.42, 0.36, 0.6)
	sm.sky_curve = 0.2
	sm.ground_bottom_color = Color(0.1, 0.1, 0.16)
	sm.ground_horizon_color = Color(0.42, 0.36, 0.6)
	sm.sun_angle_max = 0.0
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.6, 0.85)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 1.6
	env.glow_enabled = true
	env.glow_intensity = 0.85
	env.glow_hdr_threshold = 1.2
	env.fog_enabled = true
	env.fog_light_color = Color(0.4, 0.4, 0.6)
	env.fog_density = 0.003
	env.fog_sky_affect = 0.0
	Detail.polish(env)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-34, 40, 0)
	moon.light_color = Color(0.75, 0.82, 1.0)
	moon.light_energy = 0.9
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 90.0
	add_child(moon)
	# the aurora: wide soft ribbons high over the lake
	for k in range(3):
		var b := ForgeMesh.Builder.new()
		for i in range(18):
			var x := -360.0 + 40.0 * float(i)
			var z := -160.0 + 50.0 * float(k) + sin(float(i) * 0.6 + float(k)) * 30.0
			b.box(Vector3(42.0, 60.0, 1.0), Vector3(x, 230.0 + sin(float(i) * 0.4) * 10.0, z), Vector3(0, 10.0 * sin(float(i)), 0))
		var col: Color = [Color(0.3, 1.0, 0.7), Color(0.5, 0.6, 1.0), Color(0.8, 0.4, 1.0)][k]
		var m := ForgeMesh.ghost(Color(col.r, col.g, col.b, 0.12))
		m.disable_fog = true
		var mi := ForgeMesh.inst(b.commit(), m, self)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# stars
	var stars := ForgeMesh.Builder.new()
	var r := Rng.make(["reach", "stars"])
	for i in range(260):
		var a := r.randf() * TAU
		var e := r.randf_range(0.25, 1.4)
		var p := Vector3(cos(a) * cos(e), sin(e), sin(a) * cos(e)) * 800.0
		stars.box(Vector3.ONE * r.randf_range(1.2, 2.6), p)
	var sm2 := StandardMaterial3D.new()
	sm2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm2.albedo_color = Color(1.4, 1.4, 1.6)
	sm2.disable_fog = true
	var st := ForgeMesh.inst(stars.commit(), sm2, self)
	st.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _build_lake() -> void:
	var ice := ForgeMesh.mat(Color(0.62, 0.78, 0.92), 0.08, 0.2)
	ice.emission_enabled = true
	ice.emission = Color(0.2, 0.35, 0.6)
	ice.emission_energy_multiplier = 0.25
	var b := ForgeMesh.Builder.new()
	b.column(LAKE_R, LAKE_R, -0.95, -0.82, 48)
	ForgeMesh.inst(b.commit(), ice, self)
	var cracks := ForgeMesh.Builder.new()
	var r := Rng.make(["reach", "cracks"])
	for i in range(30):
		var a := r.randf() * TAU
		var d := r.randf_range(4.0, LAKE_R - 6.0)
		cracks.box(Vector3(r.randf_range(4.0, 14.0), 0.02, 0.12), Vector3(cos(a) * d, -0.8, sin(a) * d), Vector3(0, r.randf() * 180.0, 0))
	ForgeMesh.inst(cracks.commit(), ForgeMesh.mat(Color(0.9, 0.96, 1.0), 0.3), self)
	# small lanterns set on the ice, for the Archers who fell
	var lamp := ForgeMesh.glow(Color(1.0, 0.85, 0.5), 2.0)
	var lb := ForgeMesh.Builder.new()
	for i in range(40):
		var a := r.randf() * TAU
		var d := r.randf_range(8.0, LAKE_R - 4.0)
		lb.box(Vector3(0.35, 0.5, 0.35), Vector3(cos(a) * d, -0.55, sin(a) * d))
	ForgeMesh.inst(lb.commit(), lamp, self)


func _build_towers() -> void:
	var white := ForgeMesh.mat(Color(0.88, 0.9, 0.95), 0.6)
	var blue := ForgeMesh.mat(Color(0.2, 0.32, 0.6), 0.5)
	var lamp := ForgeMesh.glow(Color(0.55, 0.85, 1.0), 2.4)
	var r := Rng.make(["reach", "towers"])
	for i in range(9):
		var a := TAU * float(i) / 9.0 + 0.2
		var p := Vector3(cos(a) * (LAKE_R + 20.0), 0, sin(a) * (LAKE_R + 20.0))
		if p.z > LAKE_R and absf(p.x) < 20.0:
			continue
		var h := r.randf_range(28.0, 48.0)
		var y := height_at(p.x, p.z)
		var b := ForgeMesh.Builder.new()
		b.box(Vector3(7.0, 2.0, 7.0), Vector3(0, 1.0, 0))
		b.column(2.6, 2.0, 2.0, h, 12)
		b.box(Vector3(5.6, 1.0, 5.6), Vector3(0, h + 0.5, 0))
		ForgeMesh.inst(b.commit(), white, self, Vector3(p.x, y - 0.5, p.z))
		var cap := ForgeMesh.Builder.new()
		cap.wedge(Vector3(5.6, 3.0, 2.8), Vector3(0, h + 6.0, -1.4))
		cap.wedge(Vector3(5.6, 3.0, 2.8), Vector3(0, h + 6.0, 1.4), Vector3(0, 180, 0))
		ForgeMesh.inst(cap.commit(), blue, self, Vector3(p.x, y - 0.5, p.z))
		_block(self, Vector3(3.2, 3.2, 3.2), Vector3(p.x, y + h + 2.6, p.z), lamp, Vector3(0, 45, 0))
		var l := OmniLight3D.new()
		l.light_color = Color(0.55, 0.85, 1.0)
		l.light_energy = 2.4
		l.omni_range = 34.0
		l.position = Vector3(p.x, y + h + 2.0, p.z)
		add_child(l)
		_solid(Vector3(p.x, y, p.z), 3.0, h)
	# the road from the door to the lake, lined with low lamps
	for k in range(10):
		var z := WAKE.z - 14.0 - 13.0 * float(k)
		if z < LAKE_R + 4.0:
			break
		for side: float in [-1.0, 1.0]:
			var x := side * 6.0
			_block(self, Vector3(0.4, 2.4, 0.4), Vector3(x, height_at(x, z) + 1.2, z), white)
			_block(self, Vector3(0.7, 0.7, 0.7), Vector3(x, height_at(x, z) + 2.7, z), lamp)


func _build_woods() -> void:
	var r := Rng.make(["reach", "woods"])
	var pine := ForgeMesh.Builder.new()
	pine.col = Color(0.3, 0.22, 0.16)
	pine.box(Vector3(0.7, 4.0, 0.7), Vector3(0, 2.0, 0))
	for k in range(4):
		var s := 4.4 - 0.95 * float(k)
		pine.col = Color(0.1, 0.24, 0.2).lightened(0.04 * float(k))
		pine.box(Vector3(s, 2.2, s), Vector3(0, 3.6 + 1.9 * float(k), 0), Vector3(0, 22.0 * float(k), 0))
		pine.col = Color(0.92, 0.95, 1.0)
		pine.box(Vector3(s * 0.8, 0.35, s * 0.8), Vector3(0, 4.85 + 1.9 * float(k), 0), Vector3(0, 22.0 * float(k), 0))
	var mesh := pine.commit()
	var m := ForgeMesh.mat(Color(1, 1, 1), 0.8)
	m.vertex_color_use_as_albedo = true
	var xs: Array = []
	for i in range(420):
		var x := r.randf_range(-RIM, RIM)
		var z := r.randf_range(-RIM, RIM)
		var d := Vector2(x, z).length()
		if d > RIM - 8.0 or d < LAKE_R + 30.0:
			continue
		if absf(x) < 14.0 and z > 0.0:
			continue
		if Vector2(x - SPIRE.x, z - SPIRE.z).length() < 44.0:
			continue
		var near := false
		for c: Variant in CAIRNS:
			if Vector2(x - (c as Vector3).x, z - (c as Vector3).z).length() < 9.0:
				near = true
		if near:
			continue
		var s := r.randf_range(0.9, 1.8)
		xs.append(Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3.ONE * s), Vector3(x, height_at(x, z) - 0.2, z)))
		_solid(Vector3(x, height_at(x, z), z), 0.4 * s, 4.0)
	ForgeMesh.scatter(self, mesh, m, xs)
	_snow = GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(30, 12, 30)
	pm.direction = Vector3(0.3, -1.0, 0.1)
	pm.spread = 15.0
	pm.initial_velocity_min = 0.8
	pm.initial_velocity_max = 1.8
	pm.gravity = Vector3(0, -0.4, 0)
	pm.scale_min = 0.6
	pm.scale_max = 1.8
	_snow.process_material = pm
	_snow.amount = 380
	_snow.lifetime = 9.0
	_snow.preprocess = 9.0
	var q := QuadMesh.new()
	q.size = Vector2(0.09, 0.09)
	var qm := ForgeMesh.ghost(Color(1, 1, 1, 0.85), false)
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	q.material = qm
	_snow.draw_pass_1 = q
	_snow.visibility_aabb = AABB(Vector3(-40, -20, -40), Vector3(80, 40, 80))
	add_child(_snow)


## The Lantern Spire: a tall white tower on a round terrace, its top lit.
## Ice standing out of the snow in clusters, and drifts against the stones.
func _build_dressing() -> void:
	var r := Rng.make(["reach", "dressing"])
	var b := ForgeMesh.Builder.new()
	for i in range(50):
		var x := r.randf_range(-RIM, RIM)
		var z := r.randf_range(-RIM, RIM)
		if Vector2(x, z).length() > RIM - 10.0 or Vector2(x, z).length() < LAKE_R + 6.0 or not dress_clear(x, z, 4.0):
			continue
		for k in range(1 + int(r.randi() % 3)):
			var ox := x + r.randf_range(-2.5, 2.5)
			var oz := z + r.randf_range(-2.5, 2.5)
			Detail.ice_shard(b, Vector3(ox, height_at(ox, oz) - 0.2, oz), r.randf() * 360.0, r.randf_range(1.5, 5.5), r)
		_solid(Vector3(x, height_at(x, z), z), 1.4, 3.0)
	for i in range(50):
		var x := r.randf_range(-RIM, RIM)
		var z := r.randf_range(-RIM, RIM)
		if Vector2(x, z).length() > RIM - 8.0 or Vector2(x, z).length() < LAKE_R + 4.0 or not dress_clear(x, z):
			continue
		var s := r.randf_range(1.0, 2.6)
		Detail.rock_pile(b, Vector3(x, height_at(x, z) - 0.2, z), r.randf() * 360.0, s, Color(0.42, 0.44, 0.5), r)
		b.col = Color(0.93, 0.95, 0.98)
		b.box(Vector3(s * 1.6, s * 0.35, s * 1.2), Vector3(x, height_at(x, z) + s * 0.05, z + s * 0.5), Vector3(0, r.randf() * 90.0, 0))
		_solid(Vector3(x, height_at(x, z), z), s * 0.55, s)
	var m := ForgeMesh.mat(Color(1, 1, 1), 0.35, 0.05)
	m.vertex_color_use_as_albedo = true
	Detail.commit(self, b, null, m)


func _build_spire() -> void:
	var white := ForgeMesh.mat(Color(0.88, 0.9, 0.95), 0.6)
	var blue := ForgeMesh.mat(Color(0.2, 0.32, 0.6), 0.5)
	var y := height_at(SPIRE.x, SPIRE.z)
	var terrace := ForgeMesh.Builder.new()
	terrace.column(28.0, 28.0, -1.0, 0.6, 36)
	ForgeMesh.inst(terrace.commit(), ForgeMesh.mat(Color(0.7, 0.74, 0.82), 0.7), self, Vector3(SPIRE.x, y, SPIRE.z + 12.0))
	var t := ForgeMesh.Builder.new()
	var h := 0.0
	for k in range(5):
		var w := 14.0 - 2.2 * float(k)
		var sh := 16.0 - 1.5 * float(k)
		t.column(w * 0.5, w * 0.46, h, h + sh, 14)
		t.box(Vector3(w * 1.15, 0.8, w * 1.15), Vector3(0, h + sh, 0))
		h += sh + 0.8
	ForgeMesh.inst(t.commit(), white, self, Vector3(SPIRE.x, y, SPIRE.z - 14.0))
	var cap := ForgeMesh.Builder.new()
	cap.wedge(Vector3(6, 6, 3), Vector3(0, h + 3.0, -1.5))
	cap.wedge(Vector3(6, 6, 3), Vector3(0, h + 3.0, 1.5), Vector3(0, 180, 0))
	ForgeMesh.inst(cap.commit(), blue, self, Vector3(SPIRE.x, y, SPIRE.z - 14.0))
	_block(self, Vector3(4.0, 4.0, 4.0), Vector3(SPIRE.x, y + h - 2.0, SPIRE.z - 14.0), ForgeMesh.glow(Color(1.0, 0.9, 0.6), 3.0), Vector3(0, 45, 0))
	_solid(Vector3(SPIRE.x, y, SPIRE.z - 14.0), 7.5, h)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.9, 0.65)
	l.light_energy = 3.0
	l.omni_range = 50.0
	l.position = Vector3(SPIRE.x, y + 12.0, SPIRE.z + 6.0)
	add_child(l)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _snow != null and cam != null:
		_snow.global_position = cam.global_position
