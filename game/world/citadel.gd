class_name Citadel
extends Region
## The Citadel: the Reapers' realm, about 640 metres across on a plateau.
## South of the great wall are the Lower Rings, poor and overgrown, where
## new Reapers report to the outpost and its duty board. Thane, the living
## gate, keeps the way north. Inside: white-walled lanes, blue-roofed halls,
## stone sentinels turned bad, and the Spire, where Vael Morrow waits.

const SIZE: float = 640.0
const CELLS: int = 110
const RIM: float = 296.0
const WALL_Z: float = 20.0
const WAKE := Vector3(0, 0, 262)
const GATE := Vector3(0, 0, 44)
const SPIRE := Vector3(0, 0, -214)
const CAIRNS: Array = [Vector3(-18, 0, 250), Vector3(150, 0, 120), Vector3(40, 0, -24), Vector3(0, 0, -160)]
const SPAWNS: Array = [
	["rogue", -60, 200, 6], ["rogue", -70, 190, 6], ["hound", 60, 210, 6], ["hound", 70, 200, 6], ["wraith", 0, 170, 7],
	["rogue", -150, 150, 7], ["rogue", -160, 140, 8], ["hound", 160, 80, 7], ["hound", 170, 70, 7], ["wraith", -120, 80, 8],
	["rogue", 100, 140, 8], ["wraith", 110, 150, 8], ["hound", -40, 100, 8], ["rogue", 40, 90, 9], ["rogue", -200, 220, 7],
	# inside the wall
	["sentinel", -40, -30, 12], ["sentinel", 40, -40, 12], ["rogue", -80, -60, 12], ["rogue", 80, -70, 13], ["wraith", 0, -80, 13],
	["sentinel", -120, -110, 14], ["rogue", 120, -120, 14], ["rogue", 130, -110, 14], ["wraith", -140, -140, 14],
	["sentinel", 0, -130, 15], ["rogue", -60, -170, 16], ["rogue", 60, -170, 16], ["sentinel", -50, -200, 17], ["sentinel", 50, -200, 17],
]
const RELICS: Array = [
	[-110, 170, "A reaper's armband, cut through. Whoever wore it left in a hurry."],
	[180, 40, "A practice blade, worn down to the grip. Someone trained here every day for a long time."],
	[-90, -90, "A duty roster with half the names crossed out. Yours is not on it. Not yet."],
	[110, -150, "A broken oath-tablet. The name on it is Vael Morrow."],
]
const STELES: Array = [
	[14, 244, "THE CITADEL. THE REAPERS KEEP THE LEDGER OF THE DEAD HERE, AND SEND ON THOSE IT NAMES. YOU ARE NOT IN IT. THEY WILL WRITE YOU IN, IF YOU EARN IT."],
	[-14, 60, "THANE WAS A GATEKEEPER WHO WOULD NOT LEAVE HIS POST, EVEN WHEN HE DIED AT IT. HE IS THE GATE NOW."],
	[16, -186, "VAEL MORROW SWORE TO SEND ON EVERY SOUL HE MET. THEN HE MET ONE HE COULD NOT LET GO. NOW HE KEEPS THE SPIRE AND SENDS NO ONE."],
]

var noise: FastNoiseLite = FastNoiseLite.new()
var field: Heightfield
## Small parts gathered from every builder into one mesh, and their lit twins.
var _dress: ForgeMesh.Builder = ForgeMesh.Builder.new()
var _lit: ForgeMesh.Builder = ForgeMesh.Builder.new()
var _gate_bar: StaticBody3D
var _gate_mesh: Node3D


func _ready() -> void:
	region_id = "citadel"
	place_name = "The Citadel"
	bounds = RIM
	level_base = 8
	noise.seed = 31
	noise.frequency = 0.008
	noise.fractal_octaves = 3
	field = Heightfield.new(SIZE, CELLS, _raw_height, _tint)
	_build_sky()
	field.build(self, "grass")
	_build_rings()
	_build_wall()
	_build_city()
	_build_spire()
	Detail.commit(self, _dress, _lit, _paint())
	_build_points()
	Fx.root = self
	Sfx.loop("wind", "wind", -22.0)
	Sfx.loop("music", music_name(), -16.0)


func wake_point() -> Vector3:
	return WAKE


func cairn_points() -> Array:
	return CAIRNS


func spawn_list() -> Array:
	return SPAWNS


func boss_list() -> Array:
	return [
		["thane", GATE.x, GATE.z, 10, 20.0, 0.0],
		["vael", SPIRE.x, SPIRE.z + 10.0, 20, 24.0, 0.0],
	]


func board_list() -> Array:
	return [[14.0, 252.0, "citadel", 180.0], [26.0, 246.0, "exchange", 180.0], [40.0, 240.0, "forge", 180.0]]


func giver_list() -> Array:
	return [[-12.0, 250.0, 150.0, "g_hana", "Officer Hana Ves", "keeps the outpost", {"cloth": Color(0.06, 0.06, 0.08), "trim": Color(0.92, 0.92, 0.94), "coat": 2, "hair": 2, "hair_color": Color(0.12, 0.1, 0.1), "hair_seed": 81, "face": 1, "sash": 2, "blade": 81},
		["The gate does not open for the timid. Neither do I.", "Varga thinks I am soft on recruits. Varga was a recruit once."]]]


func relic_list() -> Array:
	return RELICS


func stele_list() -> Array:
	return STELES


func portal_list() -> Array:
	return [
		[0.0, 278.0, "town", "Go back through the Ledger Gate to Calder Town", ""],
		[220.0, 220.0, "ashfall", "Step through the Breach into the Wastes", "named"],
	]


func talker_list() -> Array:
	var lines: Array = [
		"A new one. Captain Ilse Varga, Lower Rings outpost. You will report to me until you are worth more.",
		"The duty board is beside me. Do the work, earn standing, and when you are ready, beat your trial and ask for promotion.",
		"Thane holds the great gate. Until he falls, nobody from the Rings goes north. Most Reapers fight him for their first promotion.",
		"Inside the wall the sentinels have turned. And Vael is in the Spire. Do not go up there before you are a Lieutenant.",
	]
	if soul.primary != "vigil" and soul.secondary != "vigil":
		lines = ["You are no Reaper. The gate let you in, so I will not stop you. The board is not for you."]
	return [[8.0, 242.0, 180.0, "Captain Varga", lines, {"cloth": Color(0.06, 0.06, 0.08), "trim": Color(0.92, 0.92, 0.94), "coat": 2, "hair": 3, "hair_color": Color(0.5, 0.15, 0.12), "hair_seed": 51, "face": 1, "sash": 2, "blade": 51, "collar": false}]]


func music_name() -> String:
	return "music_citadel"


func objective() -> String:
	if not bool(soul.flags.get("beat_thane", false)):
		return "Thane holds the great gate north of the outpost. " + Quests.promotion_gap(soul)
	return Quests.promotion_gap(soul)


# ----------------------------------------------------------------- terrain

func _raw_height(x: float, z: float) -> float:
	var h := 0.0
	if z > WALL_Z + 10.0:
		h = noise.get_noise_2d(x, z) * 5.0 + absf(noise.get_noise_2d(x * 2.0, z * 2.0)) * 1.5
	else:
		h = 1.0 + noise.get_noise_2d(x, z) * 0.6
	var blend := smoothstep(WALL_Z - 6.0, WALL_Z + 14.0, z)
	h = lerpf(1.0 + noise.get_noise_2d(x, z) * 0.6, h, blend)
	var d := Vector2(x, z).length()
	if d > RIM - 8.0:
		h += minf(40.0, pow((d - RIM + 8.0) * 0.6, 1.5))
	h = Heightfield.flatten(h, x, z, WAKE.x, WAKE.z, 20.0, 1.0)
	h = Heightfield.flatten(h, x, z, GATE.x, GATE.z, 18.0, 1.0)
	h = Heightfield.flatten(h, x, z, 220.0, 220.0, 8.0, 1.0)
	for c: Variant in CAIRNS:
		h = Heightfield.flatten(h, x, z, (c as Vector3).x, (c as Vector3).z, 6.0, h if z < WALL_Z else 1.0)
	return h


func height_at(x: float, z: float) -> float:
	return field.height_at(x, z) if field != null else 0.0


func _tint(mid: Vector3, n: Vector3) -> Color:
	var slope := clampf(1.0 - n.y, 0.0, 1.0)
	var grain := noise.get_noise_2d(mid.x * 5.0, mid.z * 5.0) * 0.04
	if mid.z < WALL_Z:
		var v := 0.56 + grain
		return Color(v, v * 0.98, v * 0.95)
	var g := Color(0.24, 0.42, 0.18).lerp(Color(0.42, 0.36, 0.24), clampf(slope * 2.0 + grain * 4.0, 0.0, 1.0))
	return g


func _build_sky() -> void:
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.2, 0.42, 0.85)
	sm.sky_horizon_color = Color(0.78, 0.86, 0.95)
	sm.ground_bottom_color = Color(0.3, 0.3, 0.32)
	sm.ground_horizon_color = Color(0.78, 0.86, 0.95)
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.78, 0.82, 0.92)
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 2.0
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_hdr_threshold = 1.35
	env.fog_enabled = true
	env.fog_light_color = Color(0.78, 0.86, 0.95)
	env.fog_density = 0.00045
	env.fog_sky_affect = 0.0
	env.fog_sun_scatter = 0.15
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.12
	env.adjustment_contrast = 1.07
	Detail.polish(env)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-30, -150, 0)
	sun.light_color = Color(1.0, 0.96, 0.9)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 120.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	add_child(sun)


# ------------------------------------------------------------------- parts

func _paint() -> StandardMaterial3D:
	var m := ForgeMesh.mat(Color(1, 1, 1), 0.75)
	m.vertex_color_use_as_albedo = true
	return m


## A hall: a stepped stone footing, white plaster over a darker skirting,
## a timber frame of posts and a rail, paper screens between the posts, a
## double door, and a blue roof of tile ribs with wide eaves, a ridge and
## turned-up ends. Lanterns hang either side of the door.
func _hall(b: ForgeMesh.Builder, cx: float, cz: float, w: float, d: float, h: float, yaw_deg: float = 0.0) -> void:
	var keep := b.xf
	var base := Vector3(cx, height_at(cx, cz) - 0.2, cz)
	b.xf = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_deg)), base)
	var lk := _lit.xf
	_lit.xf = b.xf
	var timber := Color(0.24, 0.16, 0.11)
	var plaster := Color(0.94, 0.93, 0.89)
	var roof := Color(0.2, 0.32, 0.55)
	b.col = Color(0.55, 0.55, 0.58)
	b.box(Vector3(w + 2.0, 0.8, d + 2.0), Vector3(0, 0.4, 0))
	b.col = Color(0.62, 0.62, 0.64)
	b.box(Vector3(w + 1.4, 0.12, d + 1.4), Vector3(0, 0.86, 0))
	for k in range(3):
		b.col = Color(0.6, 0.6, 0.62).darkened(0.05 * float(k))
		b.box(Vector3(3.6, 0.27, 0.6), Vector3(0, 0.67 - 0.27 * float(k), -d * 0.5 - 1.2 - 0.6 * float(k)))
	b.col = plaster
	b.box(Vector3(w, h, d), Vector3(0, 0.8 + h * 0.5, 0))
	b.col = Color(0.42, 0.4, 0.38)
	b.box(Vector3(w + 0.06, 1.0, d + 0.06), Vector3(0, 1.3, 0))
	b.col = timber
	var posts_w := maxi(2, int(w / 3.2))
	for k in range(posts_w + 1):
		var x := -w * 0.5 + w * float(k) / float(posts_w)
		b.box(Vector3(0.4, h, 0.4), Vector3(x, 0.8 + h * 0.5, -d * 0.5))
		b.box(Vector3(0.4, h, 0.4), Vector3(x, 0.8 + h * 0.5, d * 0.5))
	var posts_d := maxi(2, int(d / 3.2))
	for k in range(posts_d + 1):
		var z := -d * 0.5 + d * float(k) / float(posts_d)
		b.box(Vector3(0.4, h, 0.4), Vector3(-w * 0.5, 0.8 + h * 0.5, z))
		b.box(Vector3(0.4, h, 0.4), Vector3(w * 0.5, 0.8 + h * 0.5, z))
	b.box(Vector3(w + 0.3, 0.32, d + 0.3), Vector3(0, 0.8 + h * 0.62, 0))
	b.box(Vector3(w + 0.5, 0.5, d + 0.5), Vector3(0, 0.8 + h - 0.25, 0))
	# paper screens between the posts, front and back, under the rail
	var sh := h * 0.62 - 1.6
	for k in range(posts_w):
		var x := -w * 0.5 + w * (float(k) + 0.5) / float(posts_w)
		var bay := w / float(posts_w) - 0.6
		if absf(x) < 1.8:
			continue
		for face: float in [-1.0, 1.0]:
			b.col = timber
			b.box(Vector3(bay, 0.1, 0.1), Vector3(x, 1.85, face * (d * 0.5 + 0.03)))
			b.box(Vector3(bay, 0.1, 0.1), Vector3(x, 1.8 + sh, face * (d * 0.5 + 0.03)))
			_lit.col = Color(0.95, 0.88, 0.7)
			_lit.box(Vector3(bay - 0.1, sh - 0.1, 0.03), Vector3(x, 1.8 + sh * 0.5, face * (d * 0.5 + 0.02)))
			b.col = timber
			for g in range(3):
				b.box(Vector3(0.05, sh, 0.06), Vector3(x - bay * 0.5 + bay * float(g + 1) / 4.0, 1.8 + sh * 0.5, face * (d * 0.5 + 0.05)))
			b.box(Vector3(bay, 0.05, 0.06), Vector3(x, 1.8 + sh * 0.5, face * (d * 0.5 + 0.05)))
	# the door
	b.col = timber
	b.box(Vector3(2.8, h * 0.7 + 0.2, 0.3), Vector3(0, 0.8 + h * 0.35 + 0.1, -d * 0.5 - 0.08))
	b.col = Color(0.36, 0.22, 0.14)
	b.box(Vector3(1.1, h * 0.7 - 0.2, 0.34), Vector3(-0.58, 0.8 + h * 0.35, -d * 0.5 - 0.1))
	b.box(Vector3(1.1, h * 0.7 - 0.2, 0.34), Vector3(0.58, 0.8 + h * 0.35, -d * 0.5 - 0.1))
	b.col = Color(0.75, 0.6, 0.3)
	b.box(Vector3(0.1, 0.4, 0.08), Vector3(-0.14, 0.8 + h * 0.35, -d * 0.5 - 0.3))
	b.box(Vector3(0.1, 0.4, 0.08), Vector3(0.14, 0.8 + h * 0.35, -d * 0.5 - 0.3))
	for side: float in [-1.0, 1.0]:
		b.col = timber
		b.box(Vector3(0.06, 0.5, 0.06), Vector3(side * 2.0, 0.8 + h * 0.8, -d * 0.5 - 0.6))
		b.box(Vector3(0.06, 0.06, 0.6), Vector3(side * 2.0, 0.8 + h * 0.8 + 0.25, -d * 0.5 - 0.3))
		b.col = Color(0.75, 0.15, 0.12)
		b.box(Vector3(0.5, 0.06, 0.5), Vector3(side * 2.0, 0.8 + h * 0.8 - 0.28, -d * 0.5 - 0.6))
		b.box(Vector3(0.5, 0.06, 0.5), Vector3(side * 2.0, 0.8 + h * 0.8 - 0.92, -d * 0.5 - 0.6))
		_lit.col = Color(1.0, 0.6, 0.35)
		_lit.box(Vector3(0.42, 0.6, 0.42), Vector3(side * 2.0, 0.8 + h * 0.8 - 0.6, -d * 0.5 - 0.6))
	# the roof
	var top := 0.8 + h
	var rh := h * 0.45
	var depth := d * 0.5 + 1.6
	b.col = roof
	b.wedge(Vector3(w + 3.0, rh, depth), Vector3(0, top + rh * 0.5, -d * 0.25 - 0.8))
	b.wedge(Vector3(w + 3.0, rh, depth), Vector3(0, top + rh * 0.5, d * 0.25 + 0.8), Vector3(0, 180, 0))
	var slope := rad_to_deg(atan2(rh, depth))
	var run := sqrt(rh * rh + depth * depth)
	var ribs := int((w + 3.0) / 0.9)
	b.col = roof.darkened(0.22)
	for k in range(ribs + 1):
		var x := -(w + 3.0) * 0.5 + (w + 3.0) * float(k) / float(ribs)
		for side: float in [-1.0, 1.0]:
			b.box(Vector3(0.16, 0.14, run), Vector3(x, top + rh * 0.5 + 0.08, side * depth * 0.5), Vector3(side * slope, 0, 0))
	b.col = roof.darkened(0.45)
	b.box(Vector3(w + 3.2, 0.5, 0.7), Vector3(0, top + rh, 0))
	for side: float in [-1.0, 1.0]:
		b.box(Vector3(0.7, 1.0, 0.8), Vector3(side * (w * 0.5 + 1.5), top + rh + 0.3, 0), Vector3(0, 0, side * -18.0))
		b.box(Vector3(w + 3.2, 0.22, 0.3), Vector3(0, top + 0.05, side * (d * 0.5 + 1.6)))
	# brackets under the eaves
	b.col = timber
	for k in range(posts_w + 1):
		var x := -w * 0.5 + w * float(k) / float(posts_w)
		for face: float in [-1.0, 1.0]:
			b.box(Vector3(0.3, 0.3, 1.2), Vector3(x, top - 0.3, face * (d * 0.5 + 0.5)))
	b.xf = keep
	_lit.xf = lk
	_solid_box(Vector3(cx, height_at(cx, cz) + h * 0.5, cz), Vector3(w + 0.6, h + 1.6, d + 0.6), deg_to_rad(yaw_deg))


func _shack(b: ForgeMesh.Builder, cx: float, cz: float, r: RandomNumberGenerator) -> void:
	var w := r.randf_range(5.0, 8.0)
	var d := r.randf_range(5.0, 7.0)
	var h := r.randf_range(3.0, 4.0)
	var keep := b.xf
	b.xf = Transform3D(Basis(Vector3.UP, r.randf() * TAU), Vector3(cx, height_at(cx, cz) - 0.3, cz))
	b.col = Color(0.38, 0.28, 0.18).darkened(r.randf() * 0.2)
	b.box(Vector3(w, h, d), Vector3(0, h * 0.5, 0))
	b.col = Color(0.26, 0.22, 0.18)
	b.wedge(Vector3(w + 0.8, 1.6, d * 0.5 + 0.4), Vector3(0, h + 0.8, -d * 0.25 - 0.2))
	b.wedge(Vector3(w + 0.8, 1.6, d * 0.5 + 0.4), Vector3(0, h + 0.8, d * 0.25 + 0.2), Vector3(0, 180, 0))
	b.col = Color(0.1, 0.08, 0.06)
	b.box(Vector3(1.0, 2.0, 0.12), Vector3(0, 1.0, -d * 0.5 - 0.03))
	b.xf = keep
	_solid(Vector3(cx, height_at(cx, cz), cz), maxf(w, d) * 0.45, h)


func _clear(x: float, z: float, margin: float) -> bool:
	var spots: Array = [WAKE, GATE, Vector3(220, 0, 220), Vector3(14, 0, 252)]
	for c: Variant in CAIRNS + spots:
		if Vector2(x - (c as Vector3).x, z - (c as Vector3).z).length() < margin + 8.0:
			return false
	if absf(x) < 10.0 + margin and z > WALL_Z:
		return false
	return true


func _build_rings() -> void:
	var r := Rng.make(["citadel", "rings"])
	var b := ForgeMesh.Builder.new()
	for i in range(70):
		var x := r.randf_range(-RIM + 20.0, RIM - 20.0)
		var z := r.randf_range(WALL_Z + 22.0, RIM - 20.0)
		if Vector2(x, z).length() > RIM - 16.0 or not _clear(x, z, 6.0):
			continue
		_shack(b, x, z, r)
	ForgeMesh.inst(b.commit(), _paint(), self)
	# a dirt road from the outpost to the gate
	var road := ForgeMesh.Builder.new()
	for k in range(24):
		var z := WAKE.z - 10.0 * float(k)
		road.col = Color(0.5, 0.42, 0.3)
		road.box(Vector3(7.0, 0.1, 10.5), Vector3(0, height_at(0, z) + 0.02, z))
		road.col = Color(0.42, 0.35, 0.25)
		road.box(Vector3(0.6, 0.11, 10.5), Vector3(-1.6, height_at(0, z) + 0.025, z))
		road.box(Vector3(0.6, 0.11, 10.5), Vector3(1.6, height_at(0, z) + 0.025, z))
		for i in range(3):
			road.col = Color(0.6, 0.58, 0.54).darkened(r.randf() * 0.2)
			var sx := r.randf_range(-3.6, 3.6)
			var sz := z + r.randf_range(-5, 5)
			road.box(Vector3(0.4, 0.2, 0.32) * r.randf_range(0.7, 1.4), Vector3(sx, height_at(sx, sz) + 0.06, sz), Vector3(0, r.randf() * 90.0, 0))
	ForgeMesh.inst(road.commit(), _paint(), self)
	# tall pines of stacked blocks
	var pine := ForgeMesh.Builder.new()
	pine.col = Color(0.36, 0.24, 0.14)
	pine.box(Vector3(0.7, 4.0, 0.7), Vector3(0, 2.0, 0))
	for k in range(4):
		pine.col = Color(0.12, 0.32, 0.18).lightened(0.05 * float(k))
		var s := 4.2 - 0.9 * float(k)
		pine.box(Vector3(s, 2.2, s), Vector3(0, 3.6 + 1.9 * float(k), 0), Vector3(0, 22.0 * float(k), 0))
	var pine_mesh := pine.commit()
	var px: Array = []
	for i in range(240):
		var x := r.randf_range(-RIM + 10.0, RIM - 10.0)
		var z := r.randf_range(WALL_Z + 16.0, RIM - 10.0)
		if Vector2(x, z).length() > RIM - 10.0 or not _clear(x, z, 4.0):
			continue
		var s := r.randf_range(0.9, 1.7)
		px.append(Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3.ONE * s), Vector3(x, height_at(x, z) - 0.2, z)))
		_solid(Vector3(x, height_at(x, z), z), 0.4 * s, 4.0)
	ForgeMesh.scatter(self, pine_mesh, _paint(), px)
	# the outpost: a small hall and a banner
	var ob := ForgeMesh.Builder.new()
	_hall(ob, 30.0, 262.0, 16.0, 10.0, 5.0, 90.0)
	ForgeMesh.inst(ob.commit(), _paint(), self)
	Detail.banner(_dress, Vector3(-6.0, height_at(-6, 240), 240.0), 0.0, Color(0.92, 0.92, 0.94), Color(0.2, 0.32, 0.55), 9.0)
	_solid(Vector3(-6.0, height_at(-6, 240), 240.0), 0.2, 9.0)
	for k in range(6):
		var lz := WAKE.z - 30.0 - 34.0 * float(k)
		for side: float in [-1.0, 1.0]:
			var lx := side * 5.4
			if _clear(lx, lz, -4.0):
				Detail.stone_lantern(_dress, _lit, Vector3(lx, height_at(lx, lz), lz), 0.0, Color(0.56, 0.55, 0.52))
				_solid(Vector3(lx, height_at(lx, lz), lz), 0.5, 2.6)
	# the rim: pale cliffs
	var cliff := ForgeMesh.grain(Color(0.7, 0.66, 0.6), "slate", 0.06)
	for i in range(36):
		var a := TAU * float(i) / 36.0
		var rad := r.randf_range(RIM + 20.0, RIM + 60.0)
		var mb := ForgeMesh.Builder.new()
		var w := r.randf_range(30.0, 60.0)
		var h := r.randf_range(40.0, 90.0)
		mb.box(Vector3(w, h, w * 0.8), Vector3(0, h * 0.5, 0))
		mb.box(Vector3(w * 0.6, h * 0.4, w * 0.5), Vector3(r.randf_range(-6, 6), h + h * 0.2, 0))
		var mi := ForgeMesh.inst(mb.commit(), cliff, self)
		mi.position = Vector3(cos(a) * rad, 10.0, sin(a) * rad)
		mi.rotation.y = r.randf() * TAU


func _build_wall() -> void:
	var y := height_at(0, WALL_Z)
	var wb := ForgeMesh.Builder.new()
	var stone_c := Color(0.92, 0.92, 0.9)
	var base_c := Color(0.5, 0.5, 0.52)
	var cap_c := Color(0.2, 0.32, 0.55)
	for side: float in [-1.0, 1.0]:
		var x0 := 9.0
		var x1 := RIM + 30.0
		var cx := side * (x0 + x1) * 0.5
		var length := x1 - x0
		wb.col = stone_c
		wb.box(Vector3(length, 16.0, 6.0), Vector3(cx, y + 8.0, WALL_Z))
		# a battered stone base of courses
		for k in range(3):
			wb.col = base_c.darkened(0.04 * float(k))
			wb.box(Vector3(length, 1.4, 6.8 - 0.3 * float(k)), Vector3(cx, y + 0.7 + 1.4 * float(k), WALL_Z))
		wb.col = Color(0.24, 0.16, 0.11)
		wb.box(Vector3(length, 0.4, 6.2), Vector3(cx, y + 12.6, WALL_Z))
		wb.col = cap_c
		wb.box(Vector3(length + 1.0, 1.2, 7.4), Vector3(cx, y + 16.6, WALL_Z))
		wb.col = cap_c.darkened(0.3)
		wb.box(Vector3(length + 1.0, 0.3, 0.4), Vector3(cx, y + 17.3, WALL_Z))
		# arrow slits on both faces
		wb.col = Color(0.08, 0.08, 0.1)
		var slits := int(length / 6.0)
		for k in range(slits):
			var sx := side * (x0 + 3.0 + 6.0 * float(k))
			for face: float in [-1.0, 1.0]:
				wb.box(Vector3(0.3, 1.4, 0.1), Vector3(sx, y + 9.4, WALL_Z + face * 3.02))
		_solid_box(Vector3(cx, y + 8.0, WALL_Z), Vector3(length, 16.0, 6.0))
		for k in range(8):
			var tx := side * (14.0 + 40.0 * float(k))
			wb.col = stone_c
			wb.box(Vector3(8.0, 22.0, 8.0), Vector3(tx, y + 11.0, WALL_Z))
			wb.col = base_c
			wb.box(Vector3(8.8, 4.2, 8.8), Vector3(tx, y + 2.1, WALL_Z))
			wb.col = Color(0.24, 0.16, 0.11)
			wb.box(Vector3(8.2, 0.4, 8.2), Vector3(tx, y + 17.0, WALL_Z))
			wb.col = cap_c
			wb.box(Vector3(9.4, 1.4, 9.4), Vector3(tx, y + 22.6, WALL_Z))
			wb.frustum(Vector2(9.0, 9.0), Vector2(1.4, 1.4), y + 23.3, y + 26.5)
			wb.col = Color(0.1, 0.1, 0.12)
			for face: float in [-1.0, 1.0]:
				wb.box(Vector3(1.4, 2.2, 0.1), Vector3(tx, y + 19.4, WALL_Z + face * 4.02))
				wb.box(Vector3(0.1, 2.2, 1.4), Vector3(tx + face * 4.02, y + 19.4, WALL_Z))
	# the gateway itself
	wb.col = stone_c
	wb.box(Vector3(24.0, 6.0, 8.0), Vector3(0, y + 19.0, WALL_Z))
	wb.col = cap_c
	wb.box(Vector3(25.0, 1.4, 9.0), Vector3(0, y + 22.6, WALL_Z))
	wb.col = Color(0.24, 0.16, 0.11)
	wb.box(Vector3(24.4, 0.6, 8.4), Vector3(0, y + 16.4, WALL_Z))
	for side: float in [-1.0, 1.0]:
		wb.box(Vector3(1.0, 16.0, 1.0), Vector3(side * 9.4, y + 8.0, WALL_Z - 3.6))
		wb.box(Vector3(1.0, 16.0, 1.0), Vector3(side * 9.4, y + 8.0, WALL_Z + 3.6))
		Detail.banner(_dress, Vector3(side * 11.5, y + 3.0, WALL_Z + 4.2), 180.0, Color(0.2, 0.32, 0.55), Color(0.92, 0.92, 0.94), 10.0)
	ForgeMesh.inst(wb.commit(), ForgeMesh.grain(Color(1, 1, 1), "slate", 0.08), self).material_override.set("vertex_color_use_as_albedo", true)
	if not bool(soul.flags.get("beat_thane", false)):
		_gate_mesh = Node3D.new()
		add_child(_gate_mesh)
		for k in range(5):
			_block(_gate_mesh, Vector3(0.8, 15.0, 0.8), Vector3(-7.2 + 3.6 * float(k), y + 7.5, WALL_Z), ForgeMesh.glow(Color(0.5, 0.8, 1.0), 1.2))
		_gate_bar = _solid_box(Vector3(0, y + 8.0, WALL_Z), Vector3(18.0, 16.0, 4.0))


func _build_city() -> void:
	var r := Rng.make(["citadel", "city"])
	var b := ForgeMesh.Builder.new()
	# halls along a grid of lanes
	for gx in range(-5, 6):
		for gz in range(0, 6):
			var cx := float(gx) * 48.0 + r.randf_range(-3, 3)
			var cz := -26.0 - float(gz) * 40.0 + r.randf_range(-3, 3)
			if Vector2(cx, cz).length() > RIM - 30.0 or absf(cx) < 20.0:
				continue
			if Vector2(cx - SPIRE.x, cz - SPIRE.z).length() < 50.0:
				continue
			if not _clear(cx, cz, 12.0):
				continue
			_hall(b, cx, cz, r.randf_range(16.0, 26.0), r.randf_range(12.0, 18.0), r.randf_range(6.0, 11.0), 0.0 if r.randf() < 0.7 else 90.0)
	ForgeMesh.inst(b.commit(), _paint(), self)
	# lane walls: low white walls with blue caps lining the main avenue
	var lw := ForgeMesh.Builder.new()
	for k in range(9):
		var z := 6.0 - 22.0 * float(k)
		if z < SPIRE.z + 40.0:
			break
		for side: float in [-1.0, 1.0]:
			lw.col = Color(0.93, 0.92, 0.88)
			lw.box(Vector3(1.2, 3.0, 16.0), Vector3(side * 14.0, height_at(side * 14.0, z) + 1.3, z))
			lw.col = Color(0.2, 0.32, 0.55)
			lw.box(Vector3(1.8, 0.5, 16.6), Vector3(side * 14.0, height_at(side * 14.0, z) + 3.0, z))
			_solid_box(Vector3(side * 14.0, height_at(side * 14.0, z) + 1.5, z), Vector3(1.2, 3.0, 16.0))
	# pale stone flagstones down the avenue, each slab its own
	for k in range(22):
		var z := 14.0 - 10.0 * float(k)
		for j in range(4):
			for i in range(3):
				lw.col = Color(0.78, 0.76, 0.72).darkened(r.randf() * 0.08)
				lw.box(Vector3(3.9, 0.1, 2.36), Vector3(-4.0 + 4.0 * float(i), height_at(0, z) + 0.05, z - 3.6 + 2.4 * float(j)))
		lw.col = Color(0.5, 0.5, 0.52)
		lw.box(Vector3(0.4, 0.14, 9.6), Vector3(-6.2, height_at(0, z) + 0.05, z))
		lw.box(Vector3(0.4, 0.14, 9.6), Vector3(6.2, height_at(0, z) + 0.05, z))
	for k in range(10):
		var z := 2.0 - 20.0 * float(k)
		if z < SPIRE.z + 46.0:
			break
		for side: float in [-1.0, 1.0]:
			Detail.stone_lantern(_dress, _lit, Vector3(side * 9.0, height_at(side * 9.0, z), z), 0.0)
			_solid(Vector3(side * 9.0, height_at(side * 9.0, z), z), 0.5, 2.6)
			if k % 2 == 1:
				Detail.banner(_dress, Vector3(side * 12.4, height_at(side * 12.4, z), z + 10.0), 90.0 * side, Color(0.92, 0.92, 0.94), Color(0.2, 0.32, 0.55), 7.0)
	ForgeMesh.inst(lw.commit(), _paint(), self)
	# a few trees in courtyards
	var tree := ForgeMesh.Builder.new()
	tree.col = Color(0.36, 0.24, 0.14)
	tree.box(Vector3(0.6, 3.0, 0.6), Vector3(0, 1.5, 0))
	tree.col = Color(0.9, 0.55, 0.65)
	tree.box(Vector3(3.6, 2.2, 3.6), Vector3(0, 3.8, 0))
	tree.box(Vector3(2.4, 1.6, 2.4), Vector3(0.4, 5.2, -0.3), Vector3(0, 30, 0))
	var tx: Array = []
	for i in range(60):
		var x := r.randf_range(-RIM + 40.0, RIM - 40.0)
		var z := r.randf_range(-RIM + 40.0, WALL_Z - 10.0)
		if absf(x) < 18.0 or Vector2(x, z).length() > RIM - 30.0:
			continue
		tx.append(Transform3D(Basis(Vector3.UP, r.randf() * TAU), Vector3(x, height_at(x, z) - 0.1, z)))
	ForgeMesh.scatter(self, tree.commit(), _paint(), tx)


## The Spire: a stepped tower on a raised round floor, at the city's heart.
func _build_spire() -> void:
	var stone := ForgeMesh.mat(Color(0.9, 0.9, 0.88), 0.85)
	var cap := ForgeMesh.mat(Color(0.2, 0.32, 0.55), 0.6)
	var y := height_at(SPIRE.x, SPIRE.z)
	var floor_b := ForgeMesh.Builder.new()
	floor_b.column(30.0, 30.0, -0.6, 0.6, 32)
	ForgeMesh.inst(floor_b.commit(), ForgeMesh.grain(Color(0.7, 0.68, 0.64), "slate", 0.1), self, Vector3(SPIRE.x, y, SPIRE.z))
	var tower := ForgeMesh.Builder.new()
	var h := 0.0
	for k in range(6):
		var w := 22.0 - 3.2 * float(k)
		var sh := 14.0 - 1.4 * float(k)
		tower.box(Vector3(w, sh, w), Vector3(0, h + sh * 0.5, 0), Vector3(0, 12.0 * float(k), 0))
		h += sh
	ForgeMesh.inst(tower.commit(), stone, self, Vector3(SPIRE.x, y, SPIRE.z - 42.0))
	for k in range(6):
		var ring := ForgeMesh.inst(ForgeMesh.ring(0.9, 32), cap, self, Vector3(SPIRE.x, y + 13.5 + 12.2 * float(k), SPIRE.z - 42.0))
		ring.scale = Vector3(13.0 - 1.8 * float(k), 1, 13.0 - 1.8 * float(k))
	_solid(Vector3(SPIRE.x, y, SPIRE.z - 42.0), 12.0, 80.0)
	var l := OmniLight3D.new()
	l.light_color = Color(0.6, 0.45, 1.0)
	l.light_energy = 2.2
	l.omni_range = 40.0
	l.position = Vector3(SPIRE.x, y + 10.0, SPIRE.z)
	add_child(l)


func _special_death(e: Enemy) -> void:
	if e.kind == "thane":
		if _gate_bar != null:
			_gate_bar.queue_free()
			_gate_bar = null
		if _gate_mesh != null:
			_gate_mesh.queue_free()
			_gate_mesh = null
		say("The bars across the great gate fall away.", "whisper")
