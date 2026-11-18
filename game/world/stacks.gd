class_name Stacks
extends Region
## The Stacks: the Binders' realm, down through the back room of the shop.
## An archive the size of a town, about 440 metres across, under a dark
## that has no sky. Shelves taller than houses stand in rows with aisles
## between them; every shelf holds things someone could not let go of.
## Paper lanterns hang on chains from the dark; pages drift. In the middle
## the Binding Wheel turns, a ring of chain round a pillar of light, which
## is where the Binders bind what they keep. Binders take their notices
## from the Shop Ledger here, as in town.

const SIZE: float = 480.0
const CELLS: int = 90
const RIM: float = 212.0
const WAKE := Vector3(0, 0, 190)
const WHEEL := Vector3(0, 0, 0)
const AISLE: float = 9.0
const ESCORT := Vector3(32, 0, -28)
const CAIRNS: Array = [Vector3(-14, 0, 182), Vector3(-120, 0, 70), Vector3(120, 0, -40), Vector3(0, 0, -150)]
const SPAWNS: Array = [
	["wraith", -30, 150, 8], ["wraith", 34, 146, 8], ["gleaner", -90, 120, 9], ["gleaner", 96, 118, 9],
	["hound", -60, 80, 9], ["hound", 64, 74, 9], ["rogue", -130, 30, 10], ["rogue", 136, 20, 10],
	["chainbound", -40, -40, 11], ["chainbound", 44, -46, 11], ["stalker", -150, -60, 12], ["stalker", 150, -70, 12],
	["sentinel", -70, -110, 12], ["sentinel", 76, -116, 12], ["wraith", -20, -170, 13], ["wraith", 24, -176, 13],
	["chainbound", -160, -150, 14], ["rogue", 160, -150, 14],
]
const RELICS: Array = [
	[-150, 140, "A child's shoe, bound with a red thread. The note says only: not yet."],
	[130, 80, "A wedding ring on a chain, and the chain on a hook, and the hook in the wall."],
	[-100, -90, "A ledger page with one name scratched out so hard the paper tore."],
	[140, -150, "A key to a house that burned down. Someone polished it every day."],
]
const STELES: Array = [
	[16, 168, "THE STACKS. BINDERS KEEP WHAT THE DEAD CANNOT LET GO OF, AND FIGHT WITH THE CHAINS THEY KEEP IT ON."],
	[-22, 44, "THE WHEEL BINDS A THING TO A SOUL. WHAT IS BOUND REMEMBERS FOR YOU, AND FIGHTS FOR YOU, AND COSTS YOU."],
	[18, -130, "THE DEEP SHELVES ARE OLDER THAN THE TOWN. SOME OF WHAT IS KEPT THERE HAS STARTED TO KEEP ITSELF."],
]

var noise: FastNoiseLite = FastNoiseLite.new()
var field: Heightfield
var _wheel: Node3D


func _ready() -> void:
	region_id = "stacks"
	place_name = "The Stacks"
	bounds = RIM
	level_base = 8
	noise.seed = 77
	noise.frequency = 0.012
	noise.fractal_octaves = 2
	field = Heightfield.new(SIZE, CELLS, _raw_height, _tint)
	_build_dark()
	field.build(self, "town")
	_build_shelves()
	_build_wheel()
	_build_lanterns()
	_build_dressing()
	_build_points()
	Fx.root = self
	Sfx.loop("wind", "wind", -30.0)
	Sfx.loop("music", music_name(), -15.0)


func wake_point() -> Vector3:
	return WAKE


func cairn_points() -> Array:
	return CAIRNS


func spawn_list() -> Array:
	return SPAWNS


func board_list() -> Array:
	return [[14.0, 178.0, "shop", 180.0], [28.0, 174.0, "exchange", 180.0], [42.0, 170.0, "forge", 180.0]]


func giver_list() -> Array:
	return [[-14.0, 176.0, 170.0, "g_quill", "Quill", "mends the bindings", {"cloth": Color(0.3, 0.22, 0.16), "trim": Color(0.85, 0.7, 0.4), "coat": 1, "hair": 2, "hair_color": Color(0.55, 0.55, 0.58), "hair_seed": 117, "face": 2, "sash": 1, "tether": 2},
		["Every chain frays. I mend them. Mostly.", "Wren runs the Stacks. I run behind Wren with a needle."]]]


func relic_list() -> Array:
	return RELICS


func stele_list() -> Array:
	return STELES


func portal_list() -> Array:
	return [[0.0, 206.0, "town", "Climb the stairs back up to the shop", ""]]


func music_name() -> String:
	return "music_stacks"


func talker_list() -> Array:
	var lines: Array = [
		"So the chain found you. I am Wren Halloway. I keep the Stacks, and the Stacks keep everything else.",
		"The Shop Ledger hangs here as well as upstairs. Same notices, same pay. Climb the grades from either.",
		"The deep shelves, south, past the Wheel: things there have started to keep themselves. Go in bound tight.",
	]
	if soul.primary != "relic" and soul.secondary != "relic":
		lines = ["You are no Binder. The stair let you down, so look around. Touch nothing that hums."]
	return [[6.0, 174.0, 180.0, "Wren Halloway", lines, {"cloth": Color(0.22, 0.16, 0.12), "trim": Color(0.9, 0.78, 0.45), "coat": 2, "hair": 1, "hair_color": Color(0.12, 0.1, 0.09), "hair_seed": 63, "face": 1, "sash": 2, "tether": 3, "accent": Color(1.0, 0.8, 0.45)}]]


func objective() -> String:
	return Quests.promotion_gap(soul)


# ----------------------------------------------------------------- terrain

## A floor of boards, nearly level: shallow reading pits and raised
## landings, a ramped rim where the shelves meet the dark.
func _raw_height(x: float, z: float) -> float:
	var h := noise.get_noise_2d(x, z) * 1.2
	var d := Vector2(x, z).length()
	if d > RIM - 6.0:
		h += minf(30.0, pow((d - RIM + 6.0) * 0.7, 1.4))
	h = Heightfield.flatten(h, x, z, WHEEL.x, WHEEL.z, 26.0, -1.5, 1.4)
	h = Heightfield.flatten(h, x, z, WAKE.x, WAKE.z, 22.0, 0.5)
	for c: Variant in CAIRNS:
		h = Heightfield.flatten(h, x, z, (c as Vector3).x, (c as Vector3).z, 6.0, h)
	return h


func height_at(x: float, z: float) -> float:
	return field.height_at(x, z) if field != null else 0.0


func _tint(mid: Vector3, n: Vector3) -> Color:
	var grain := noise.get_noise_2d(mid.x * 3.0, mid.z * 3.0) * 0.04
	var v := 0.42 + grain
	var near_wheel := 1.0 - clampf(Vector2(mid.x, mid.z).length() / 30.0, 0.0, 1.0)
	var c := Color(v * 1.08, v * 0.8, v * 0.58)
	c = c.lerp(Color(0.5, 0.5, 0.52), near_wheel)
	# boards everywhere, stone flags round the Wheel
	c.a = 0.75 if near_wheel > 0.2 else 0.25
	if n.y < 0.8:
		c.a = 1.0
	return c


func _build_dark() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.025, 0.02)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.7, 0.5)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 1.5
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_hdr_threshold = 1.1
	env.fog_enabled = true
	env.fog_light_color = Color(0.2, 0.14, 0.09)
	env.fog_density = 0.008
	env.fog_sky_affect = 1.0
	Detail.polish(env)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var lamp := DirectionalLight3D.new()
	lamp.rotation_degrees = Vector3(-62, 25, 0)
	lamp.light_color = Color(1.0, 0.82, 0.6)
	lamp.light_energy = 0.55
	lamp.shadow_enabled = true
	lamp.directional_shadow_max_distance = 80.0
	add_child(lamp)


## Rows of shelves with aisles between, east-west, broken by cross aisles
## and the open ground round the hub and the Wheel.
func _build_shelves() -> void:
	var r := Rng.make(["stacks", "shelves"])
	var wood := Color(0.32, 0.21, 0.13)
	var b := ForgeMesh.Builder.new()
	var spines: Array = [Color(0.55, 0.16, 0.12), Color(0.16, 0.26, 0.42), Color(0.2, 0.36, 0.22), Color(0.6, 0.48, 0.26), Color(0.32, 0.2, 0.36), Color(0.75, 0.7, 0.6)]
	var z := -RIM + 20.0
	while z < RIM - 30.0:
		var x := -RIM + 16.0
		while x < RIM - 16.0:
			var run := r.randf_range(14.0, 30.0)
			var cx := x + run * 0.5
			var keep_clear := Vector2(cx - WAKE.x, z - WAKE.z).length() < 40.0 or Vector2(cx, z).length() < 46.0 or absf(cx) < AISLE * 0.8 or _blocks_a_point(cx, z, run)
			if not keep_clear and Vector2(cx, z).length() < RIM - 18.0 and dress_clear(cx, z, run * 0.5) and dress_clear(x + 1.0, z, 3.0) and dress_clear(x + run - 1.0, z, 3.0):
				var tall := r.randf_range(7.0, 15.0)
				var y := minf(height_at(x, z), height_at(x + run, z)) - 0.3
				_shelf(b, Vector3(cx, y, z), run, tall, wood, spines, r)
				_solid_box(Vector3(cx, y + tall * 0.5, z), Vector3(run, tall, 2.4))
			x += run + (AISLE if r.randf() < 0.3 else 3.0)
		z += AISLE + 2.4
	var m := ForgeMesh.mat(Color(1, 1, 1), 0.85)
	m.vertex_color_use_as_albedo = true
	ForgeMesh.inst(b.commit(), m, self)


## Shelves keep off where enemies rise, people stand and the lost wait.
func _blocks_a_point(cx: float, z: float, run: float) -> bool:
	var pts: Array = []
	for sp: Variant in SPAWNS:
		pts.append(Vector2(float(sp[1]), float(sp[2])))
	for g: Variant in giver_list() + talker_list():
		pts.append(Vector2(float(g[0]), float(g[1])))
	pts.append(Vector2(ESCORT.x, ESCORT.z))
	for pt: Variant in pts:
		var v: Vector2 = pt
		if absf(v.x - cx) < run * 0.5 + 3.5 and absf(v.y - z) < 4.5:
			return true
	return false


func _shelf(b: ForgeMesh.Builder, at: Vector3, run: float, tall: float, wood: Color, spines: Array, r: RandomNumberGenerator) -> void:
	b.col = wood
	b.box(Vector3(run, tall, 0.4), at + Vector3(0, tall * 0.5, 0))
	for side: float in [-1.0, 1.0]:
		b.col = wood.darkened(0.15)
		b.box(Vector3(0.5, tall + 0.4, 2.4), at + Vector3(side * run * 0.5, tall * 0.5, 0))
	var shelves := int(tall / 1.6)
	for k in range(shelves + 1):
		var y := 0.2 + float(k) * 1.6
		b.col = wood.lightened(0.05)
		b.box(Vector3(run, 0.14, 2.4), at + Vector3(0, y, 0))
		if k == shelves:
			break
		# a row of spines on each face, with gaps
		for face: float in [-1.0, 1.0]:
			var x := -run * 0.5 + 0.4
			while x < run * 0.5 - 0.5:
				var w := r.randf_range(0.18, 0.5)
				var h := r.randf_range(0.8, 1.35)
				if r.randf() < 0.88:
					b.col = spines[r.randi() % spines.size()]
					b.box(Vector3(w, h, 0.9), at + Vector3(x + w * 0.5, y + 0.07 + h * 0.5, face * 0.7))
				x += w + (0.02 if r.randf() < 0.85 else r.randf_range(0.3, 1.2))


## The Binding Wheel: a pillar of light, a ring of stone, chains between.
func _build_wheel() -> void:
	var y := height_at(WHEEL.x, WHEEL.z)
	var stone := ForgeMesh.grain(Color(0.5, 0.5, 0.52), "slate")
	var ring := ForgeMesh.Builder.new()
	ring.column(22.0, 22.0, -0.4, 0.5, 40)
	ForgeMesh.inst(ring.commit(), stone, self, Vector3(WHEEL.x, y, WHEEL.z))
	var pillar := ForgeMesh.Builder.new()
	pillar.column(2.2, 1.6, 0.0, 60.0, 16)
	ForgeMesh.inst(pillar.commit(), ForgeMesh.glow(Color(1.0, 0.82, 0.5), 1.6), self, Vector3(WHEEL.x, y, WHEEL.z))
	_solid(Vector3(WHEEL.x, y, WHEEL.z), 2.4, 20.0)
	_wheel = Node3D.new()
	_wheel.position = Vector3(WHEEL.x, y + 9.0, WHEEL.z)
	add_child(_wheel)
	var chain := ForgeMesh.Builder.new()
	var metal := Color(0.45, 0.42, 0.4)
	for k in range(12):
		var a := TAU * float(k) / 12.0
		var outer := Vector3(cos(a), 0, sin(a)) * 16.0
		chain.col = metal
		for i in range(14):
			var t := float(i) / 13.0
			var p := outer * t + Vector3(0, -sin(t * PI) * 2.5, 0)
			chain.box(Vector3(0.5, 0.25, 0.25), p, Vector3(0, -rad_to_deg(a), 45.0 if i % 2 == 0 else -45.0))
	chain.col = Color(0.6, 0.55, 0.45)
	chain.column(16.6, 16.6, -0.4, 0.4, 40)
	var cm := ForgeMesh.mat(Color(1, 1, 1), 0.4, 0.6)
	cm.vertex_color_use_as_albedo = true
	ForgeMesh.inst(chain.commit(), cm, _wheel)
	# what the Wheel holds: a few kept things hanging in the light
	for k in range(6):
		var a := TAU * float(k) / 6.0 + 0.3
		_block(_wheel, Vector3(0.9, 0.9, 0.9), Vector3(cos(a) * 9.0, -1.5, sin(a) * 9.0), ForgeMesh.glow(Color(1.0, 0.75, 0.4), 1.4), Vector3(45, 0, 35))
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.8, 0.5)
	l.light_energy = 3.0
	l.omni_range = 45.0
	l.position = Vector3(WHEEL.x, y + 6.0, WHEEL.z)
	add_child(l)


## Paper lanterns on chains down the main aisle and round the hub; a few
## are real lights, the rest only glow.
func _build_lanterns() -> void:
	var r := Rng.make(["stacks", "lanterns"])
	var b := ForgeMesh.Builder.new()
	var lit := ForgeMesh.Builder.new()
	var lights := 0
	var spots: Array = []
	var z := RIM - 30.0
	while z > -RIM + 20.0:
		spots.append(Vector3(r.randf_range(-3.0, 3.0), 0, z))
		z -= 14.0
	for i in range(40):
		var a := r.randf() * TAU
		var d := r.randf_range(30.0, RIM - 20.0)
		spots.append(Vector3(cos(a) * d, 0, sin(a) * d))
	for sp: Variant in spots:
		var p: Vector3 = sp
		var y := height_at(p.x, p.z)
		var hang := r.randf_range(6.0, 11.0)
		b.col = Color(0.3, 0.28, 0.26)
		b.box(Vector3(0.06, 30.0 - hang, 0.06), Vector3(p.x, y + hang + (30.0 - hang) * 0.5, p.z))
		lit.col = Color(1.0, 0.72, 0.4)
		lit.box(Vector3(0.8, 1.1, 0.8), Vector3(p.x, y + hang, p.z))
		b.col = Color(0.25, 0.12, 0.08)
		b.box(Vector3(0.9, 0.12, 0.9), Vector3(p.x, y + hang + 0.6, p.z))
		b.box(Vector3(0.9, 0.12, 0.9), Vector3(p.x, y + hang - 0.6, p.z))
		if lights < 14 and absf(p.x) < 6.0 and int(p.z) % 28 < 14:
			var ol := OmniLight3D.new()
			ol.light_color = Color(1.0, 0.72, 0.42)
			ol.light_energy = 1.6
			ol.omni_range = 16.0
			ol.position = Vector3(p.x, y + hang - 0.8, p.z)
			add_child(ol)
			lights += 1
	var m := ForgeMesh.mat(Color(1, 1, 1), 0.8)
	m.vertex_color_use_as_albedo = true
	Detail.commit(self, b, lit, m)


## Loose paper, open books and reading tables on the floor; pages that
## hang in the air near the hub.
func _build_dressing() -> void:
	var r := Rng.make(["stacks", "dressing"])
	var b := ForgeMesh.Builder.new()
	var tables := 0
	for i in range(60):
		var x := r.randf_range(-RIM + 20.0, RIM - 20.0)
		var z := r.randf_range(-RIM + 20.0, RIM - 20.0)
		if not dress_clear(x, z, 3.0) or not _floor_open(x, z):
			continue
		var y := height_at(x, z)
		if tables < 18 and r.randf() < 0.4:
			tables += 1
			var yaw := r.randf() * 180.0
			b.col = Color(0.36, 0.24, 0.14)
			b.box(Vector3(2.6, 0.12, 1.3), Vector3(x, y + 0.9, z), Vector3(0, yaw, 0))
			for k in range(4):
				var sx := 1.1 if k % 2 == 0 else -1.1
				var sz := 0.5 if k < 2 else -0.5
				var off := Basis(Vector3.UP, deg_to_rad(yaw)) * Vector3(sx, 0, sz)
				b.box(Vector3(0.12, 0.9, 0.12), Vector3(x + off.x, y + 0.45, z + off.z))
			b.col = Color(0.92, 0.88, 0.78)
			b.box(Vector3(0.7, 0.06, 0.5), Vector3(x, y + 0.99, z), Vector3(0, yaw + r.randf_range(-20, 20), 0))
			_solid(Vector3(x, y, z), 1.1, 1.0)
		else:
			# a spill of paper and a few fallen books
			for k in range(int(r.randi() % 5) + 3):
				b.col = Color(0.9, 0.86, 0.76) if r.randf() < 0.7 else Color(0.5, 0.2, 0.14)
				var px := x + r.randf_range(-1.5, 1.5)
				var pz := z + r.randf_range(-1.5, 1.5)
				b.box(Vector3(0.45, 0.04, 0.6), Vector3(px, height_at(px, pz) + 0.03, pz), Vector3(0, r.randf() * 180.0, 0))
	# pages in the air round the hub and the Wheel
	for i in range(120):
		var c: Vector3 = WAKE if i < 50 else WHEEL
		var a := r.randf() * TAU
		var d := r.randf_range(6.0, 34.0)
		var p := c + Vector3(cos(a) * d, r.randf_range(3.0, 14.0), sin(a) * d)
		b.col = Color(0.95, 0.92, 0.84)
		b.box(Vector3(0.4, 0.02, 0.55), p, Vector3(r.randf_range(-40, 40), r.randf() * 180.0, r.randf_range(-40, 40)))
	var m := ForgeMesh.mat(Color(1, 1, 1), 0.9)
	m.vertex_color_use_as_albedo = true
	Detail.commit(self, b, null, m)


## True if no shelf stands at (x, z).
func _floor_open(x: float, z: float) -> bool:
	var space := get_world_3d().direct_space_state if is_inside_tree() else null
	if space == null:
		return true
	var g := height_at(x, z)
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, g + 30.0, z), Vector3(x, g - 1.0, z), 1)
	var hit := space.intersect_ray(q)
	return hit.is_empty() or float((hit["position"] as Vector3).y) < g + 0.5


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _wheel != null:
		_wheel.rotation.y += delta * 0.06
