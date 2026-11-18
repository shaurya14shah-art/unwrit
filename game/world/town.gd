class_name Town
extends Region
## Calder Town, in the living world: where every soul wakes, about 420 metres
## across. A river on the west with a weir, downtown towers to the north, the
## flats, the school, the park with its cairn and its tear, and the shop
## where Ivo Marsh trains the dead who can still be saved. Archers and
## Binders live here after their Awakening: Lantern House and the shop keep
## their boards.

const HALF: float = 210.0
const WAKE := Vector3(8.5, 0, 44)
const CAIRNS: Array = [Vector3(52, 0, -48), Vector3(-120, 0, 44), Vector3(150, 0, 128), Vector3(-205, 0, 40), Vector3(140, 0, -128)]
const FLATS := Vector3(-45, 0, -45)
const WEIR := Vector3(-185, 0, -125)
const SPAWNS: Array = [
	["husk", -30, 40, 1], ["husk", -36, 48, 1], ["husk", 24, 63, 1], ["husk", -22, 63, 2], ["husk", 30, -22, 1], ["husk", 38, -30, 2],
	["husk", 120, 40, 2], ["husk", 130, 50, 2], ["husk", -120, 120, 2], ["husk", 60, 130, 2],
	["hound", -160, 30, 3], ["hound", -160, -40, 3], ["hound", -150, 120, 4], ["hound", -160, -170, 4], ["hound", -210 + 6, -60, 4],
	["wraith", -70, -70, 3], ["wraith", -20, -72, 3], ["wraith", -72, -18, 3],
	["gleaner", -40, -130, 4], ["gleaner", 40, -130, 4], ["gleaner", 0, -190, 5], ["wraith", 60, -180, 5], ["husk", -60, -180, 4], ["husk", -70, -190, 4],
	["hound", 150, -60, 4], ["hound", 160, -70, 4], ["gleaner", 170, -170, 5], ["wraith", 120, -190, 5],
	["husk", 140, 180, 3], ["husk", -40, 180, 3], ["hound", 0, 190, 4],
]
const RELICS: Array = [
	[-2, 10, "A child's shoe at the crossing. You remember running, and a horn."],
	[40, -30, "A ring under the bench, too small for you now. You remember a promise."],
	[-118, 60, "A key on a doorstep. You remember being afraid of a room in that house."],
	[-22, 28, "A cracked lens by the court. You remember watching for someone to come."],
	[64, -56, "A length of red cord on a grave. You remember it tied to another wrist."],
	[150, 140, "A bicycle bell, rusted silent. You remember riding too fast down this hill."],
	[-190, 20, "A paper boat, stuck in the reeds. You remember making two."],
]
const STELES: Array = [
	[11.8, 41.5, "NOBODY HERE CAN SEE YOU. NOBODY WROTE YOU DOWN. YOU ARE UNWRIT, AND WHAT YOU DO IN THIS TOWN IS WHAT YOU WILL BE."],
	[30, -42, "FOUR HUNGERS WEAR THE DEAD: TO GUARD, TO DEVOUR, TO GATHER, TO REMEMBER. NONE IS CHOSEN FROM A LIST. ALL ARE EARNED."],
	[74, -78, "THE TEAR GOES DOWN TO THE WASTES, WHERE THE HUNGRY END. IT TAKES ONLY A SOUL WHOSE BLADE HAS A NAME."],
	[182, -178, "THE LEDGER GATE. BEYOND IT IS THE CITADEL, WHERE REAPERS KEEP THE BOOK OF THE DEAD."],
]
# roads as [x0, z0, x1, z1]
const ROADS: Array = [
	[-6, -210, 6, 210], [-96, -210, -84, 210], [84, -210, 96, 210], [-166, -210, -154, 210],
	[-210, -6, 210, 6], [-210, -96, 210, -84], [-210, 84, 210, 96], [-210, -166, 210, -154], [-210, 154, 210, 166],
]
const XS: Array = [[-154, -96], [-84, -6], [6, 84], [96, 210]]
const ZS: Array = [[-210, -166], [-154, -96], [-84, -6], [6, 84], [96, 154], [166, 210]]
const RIVER: Array = [-198.0, -172.0]
const BRIDGES: Array = [0.0, -90.0, 90.0, -160.0, 160.0]

const GRASS := Color(0.2, 0.46, 0.17)
const WALK := Color(0.47, 0.48, 0.51)
const ROAD := Color(0.14, 0.15, 0.17)
const BARK := Color(0.42, 0.27, 0.16)

var paint: StandardMaterial3D
var glass: StandardMaterial3D
## Window glass that takes its pane colour from the mesh (some lit).
var panes: ShaderMaterial
var _r: RandomNumberGenerator
## the living: they cannot see you, and you pass through them
var walkers: Array = []
var cars: Array = []


func _ready() -> void:
	region_id = "town"
	place_name = "Calder Town"
	bounds = HALF
	level_base = 2
	_r = Rng.make(["town", "build"])
	paint = ForgeMesh.mat(Color(1, 1, 1), 0.7)
	paint.vertex_color_use_as_albedo = true
	glass = ForgeMesh.mat(Color(0.16, 0.36, 0.7), 0.15, 0.3)
	glass.emission_enabled = true
	glass.emission = Color(0.4, 0.65, 1.0)
	glass.emission_energy_multiplier = 0.08
	panes = Detail.glass(1.4)
	_build_sky()
	_build_ground()
	_build_blocks()
	_build_street()
	_build_skyline()
	_build_points()
	_build_living()
	Fx.root = self
	Sfx.loop("wind", "wind", -24.0)
	Sfx.loop("music", music_name(), -17.0)


# ------------------------------------------------------------- the living

const LIVING_SKINS: Array = [Color(0.96, 0.84, 0.7), Color(0.9, 0.72, 0.55), Color(0.76, 0.56, 0.4), Color(0.55, 0.38, 0.27), Color(0.36, 0.25, 0.19)]
const LIVING_CLOTHES: Array = [Color(0.2, 0.3, 0.55), Color(0.6, 0.2, 0.2), Color(0.25, 0.45, 0.3), Color(0.85, 0.75, 0.3), Color(0.5, 0.5, 0.55), Color(0.9, 0.9, 0.92), Color(0.35, 0.25, 0.45), Color(0.15, 0.15, 0.17)]


func _block_ring(xi: int, zi: int) -> Rect2:
	var x0 := float(XS[xi][0]) + 1.5
	var x1 := float(XS[xi][1]) - 1.5
	var z0 := float(ZS[zi][0]) + 1.5
	var z1 := float(ZS[zi][1]) - 1.5
	return Rect2(x0, z0, x1 - x0, z1 - z0)


## A point on a rectangle's edge, `d` metres round from its corner.
static func _round_rect(r: Rect2, d: float) -> Vector2:
	var w := r.size.x
	var h := r.size.y
	d = fposmod(d, 2.0 * (w + h))
	if d < w:
		return Vector2(r.position.x + d, r.position.y)
	d -= w
	if d < h:
		return Vector2(r.end.x, r.position.y + d)
	d -= h
	if d < w:
		return Vector2(r.end.x - d, r.end.y)
	d -= w
	return Vector2(r.position.x, r.end.y - d)


func _build_living() -> void:
	var r := Rng.make(["town", "living"])
	for i in range(26):
		var xi := int(r.randi() % XS.size())
		var zi := int(r.randi() % ZS.size())
		var rig := BlockRig.new()
		add_child(rig)
		var hair := int(r.randi() % 5)
		rig.build({
			"cloth": LIVING_CLOTHES[r.randi() % LIVING_CLOTHES.size()], "trim": LIVING_CLOTHES[r.randi() % LIVING_CLOTHES.size()].darkened(0.3),
			"skin": LIVING_SKINS[r.randi() % LIVING_SKINS.size()], "coat": 0 if r.randf() < 0.6 else 1, "sleeves": false,
			"hair": hair, "hair_color": [Color(0.1, 0.08, 0.06), Color(0.35, 0.22, 0.12), Color(0.8, 0.7, 0.45), Color(0.6, 0.6, 0.6)][r.randi() % 4],
			"hair_seed": 900 + i, "face": int(r.randi() % 4), "scale": r.randf_range(0.88, 1.05),
		})
		rig.play("run", 0.0, 0.42)
		walkers.append({"rig": rig, "ring": _block_ring(xi, zi), "d": r.randf() * 300.0, "speed": r.randf_range(1.2, 1.8) * (1.0 if r.randf() < 0.5 else -1.0)})
	var colours: Array = [Color(0.75, 0.15, 0.15), Color(0.2, 0.3, 0.7), Color(0.85, 0.85, 0.88), Color(0.2, 0.2, 0.22), Color(0.8, 0.7, 0.2), Color(0.3, 0.5, 0.3), Color(0.5, 0.3, 0.6)]
	for i in range(16):
		var rd: Array = ROADS[r.randi() % ROADS.size()]
		var along_z := (float(rd[3]) - float(rd[1])) > (float(rd[2]) - float(rd[0]))
		var lane := 3.0 if r.randf() < 0.5 else -3.0
		var mi := ForgeMesh.inst(_car_mesh(colours[i % colours.size()]), paint, self)
		cars.append({"mesh": mi, "road": rd, "z": along_z, "lane": lane, "t": r.randf_range(-HALF, HALF), "speed": r.randf_range(9.0, 15.0) * (1.0 if lane > 0.0 else -1.0)})


func _car_mesh(colour: Color) -> ArrayMesh:
	var b := ForgeMesh.Builder.new()
	b.col = colour
	b.box(Vector3(2.0, 0.8, 4.4), Vector3(0, 0.75, 0))
	b.col = Color(0.12, 0.14, 0.18)
	b.box(Vector3(1.8, 0.75, 2.2), Vector3(0, 1.5, 0.2))
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			b.col = Color(0.06, 0.06, 0.07)
			b.box(Vector3(0.3, 0.7, 0.7), Vector3(sx * 0.95, 0.35, sz * 1.4))
	b.col = Color(1.0, 0.95, 0.75)
	b.box(Vector3(0.4, 0.2, 0.06), Vector3(-0.65, 0.85, -2.2))
	b.box(Vector3(0.4, 0.2, 0.06), Vector3(0.65, 0.85, -2.2))
	b.col = Color(0.9, 0.1, 0.1)
	b.box(Vector3(0.4, 0.2, 0.06), Vector3(-0.65, 0.85, 2.2))
	b.box(Vector3(0.4, 0.2, 0.06), Vector3(0.65, 0.85, 2.2))
	return b.commit()


func _process(delta: float) -> void:
	var eye := cam.global_position if cam != null else Vector3.ZERO
	for w: Variant in walkers:
		var d: Dictionary = w
		var rig: BlockRig = d["rig"]
		d["d"] = float(d["d"]) + float(d["speed"]) * delta
		var p := _round_rect(d["ring"], float(d["d"]))
		var ahead := _round_rect(d["ring"], float(d["d"]) + signf(float(d["speed"])) * 0.5)
		rig.position = Vector3(p.x, 0.07, p.y)
		var far := rig.position.distance_to(eye) > 110.0
		rig.visible = not far
		rig.set_process(not far)
		if not far:
			rig.rotation.y = atan2(-(ahead.x - p.x), -(ahead.y - p.y))
	for c: Variant in cars:
		var d: Dictionary = c
		var rd: Array = d["road"]
		d["t"] = float(d["t"]) + float(d["speed"]) * delta
		if float(d["t"]) > HALF:
			d["t"] = -HALF
		elif float(d["t"]) < -HALF:
			d["t"] = HALF
		var mi: MeshInstance3D = d["mesh"]
		var cx := (float(rd[0]) + float(rd[2])) * 0.5
		var cz := (float(rd[1]) + float(rd[3])) * 0.5
		if bool(d["z"]):
			mi.position = Vector3(cx + float(d["lane"]), 0.07, float(d["t"]))
			mi.rotation.y = 0.0 if float(d["speed"]) < 0.0 else PI
		else:
			mi.position = Vector3(float(d["t"]), 0.07, cz + float(d["lane"]))
			mi.rotation.y = PI * 0.5 if float(d["speed"]) < 0.0 else -PI * 0.5
		mi.visible = mi.position.distance_to(eye) < 220.0


## The town is square: its edge is the last pavement, not a circle.
## At night most of the living go home: two walkers in three leave the
## pavements until morning.
func on_night(k: float) -> void:
	var home := k > 0.55
	for i in range(walkers.size()):
		var rig: Node3D = walkers[i]["rig"]
		if is_instance_valid(rig):
			rig.visible = not (home and i % 3 != 0)


func confine(a: Actor) -> void:
	var p := a.global_position
	var lim := HALF - 3.0
	if absf(p.x) > lim or absf(p.z) > lim:
		a.global_position = Vector3(clampf(p.x, -lim, lim), p.y, clampf(p.z, -lim, lim))


func wake_point() -> Vector3:
	return WAKE


func cairn_points() -> Array:
	return CAIRNS


func spawn_list() -> Array:
	return SPAWNS


func boss_list() -> Array:
	return [
		["gutter_king", FLATS.x, FLATS.z, 3, 15.0, 45.0],
		["drowned_hound", WEIR.x, WEIR.z, 6, 22.0, 90.0],
	]


func board_list() -> Array:
	return [[14.0, 54.0, "lingering", 90.0], [150.0, -22.0, "lantern", 180.0], [24.0, 11.0, "shop", 180.0], [-12.0, 30.0, "exchange", 180.0], [56.0, 11.0, "forge", 180.0]]


func giver_list() -> Array:
	return [
		[21.0, 60.0, 200.0, "g_mira", "Mira Okafor", "lost her brother", {"cloth": Color(0.5, 0.22, 0.3), "coat": 1, "hair": 2, "hair_color": Color(0.08, 0.06, 0.05), "hair_seed": 71, "face": 0, "sash": 0, "scale": 0.86},
			["He was walking home. That is all. He was walking home.", "Some of us stay because someone has to wait."]],
		[12.0, 9.0, 160.0, "g_pell", "Old Pell", "fires charms", {"cloth": Color(0.32, 0.27, 0.22), "trim": Color(0.75, 0.7, 0.6), "coat": 2, "hair": 1, "hair_color": Color(0.85, 0.85, 0.85), "hair_seed": 72, "face": 2, "sash": 1},
			["The kiln does not care that I am dead. Neither do I, mostly.", "Marsh pretends he does not know me. We were young together."]],
	]


func relic_list() -> Array:
	return RELICS


func stele_list() -> Array:
	return STELES


func portal_list() -> Array:
	return [
		[70.0, -70.0, "ashfall", "Step into the tear", "named"],
		[62.0, 10.5, "undercroft", "Go down to the cellar under the shop", "prologue"],
		[190.0, -190.0, "citadel", "Pass through the Ledger Gate", "reaper"],
		[150.0, -38.5, "reach", "Open the Lantern Door to the Silver Reach", "archer"],
		[-30.0, 10.5, "stacks", "Take the back stair down to the Stacks", "binder"],
	]


func music_name() -> String:
	return "music_town"


func objective() -> String:
	var chapter := String(soul.flags.get("chapter", "prologue"))
	if chapter == "prologue":
		if Quests.prologue_done(soul):
			return "Go to the shop on the main road. Ivo Marsh is waiting."
		if Quests.active(soul).is_empty():
			return "Read the Lingering Board beside your memorial."
		return "Do what the Lingering Board asks. Hand each notice in when it is done."
	if chapter == "training":
		return "Go down to the cellar under the shop."
	if soul.primary == "lumen":
		return "Your realm is the Silver Reach, through the Lantern Door at Lantern House. " + Quests.promotion_gap(soul)
	if soul.primary == "relic":
		return "Your board is at the shop on the main road. " + Quests.promotion_gap(soul)
	return Quests.promotion_gap(soul)


func talker_list() -> Array:
	var chapter := String(soul.flags.get("chapter", "prologue"))
	var reaper_lines: Array = [
		"You can see me. Then you died here, and nobody came for you. That makes you Unwrit. I am a Reaper: I send the dead on.",
		"That chain in your chest is your tether. It is what is left of your life. It rusts on its own, and faster every time you eat one of them.",
		"The pale things in the streets are strays. They eat the dead who linger. Cut them. Guard with F, and raise it the instant a blow lands to turn it.",
		"Send the ones you put down on, or eat them. It changes what you become. The board by your memorial has work for you.",
		"When the board is done, go to the shop on the main road. Ask for Ivo Marsh. He trains the ones who can still be saved.",
	]
	if chapter == "hub":
		reaper_lines = ["You came back. %s now. Good." % Quests.title(soul), "The Ledger Gate is in the north-east corner. It lets Reapers through, and anyone of Grade 3."]
	var marsh_lines: Array = [
		"Customer? No. You are dead. I can tell, the bell does not ring for you.",
		"I train the dead, sometimes. Not yet. Do what the Lingering Board asks first.",
	]
	var marsh_action := ""
	if Quests.prologue_done(soul) and not soul.written():
		marsh_lines = [
			"So you did it. The Gutter King, even. Then you are worth the trouble.",
			"Downstairs. I will cut your tether, and we will see what you are without it. Come on.",
		]
		marsh_action = "train"
	elif soul.written():
		marsh_lines = ["Back again. %s, is it." % Quests.title(soul), "If you ever want to fight in the cellar again, the stairs are open."]
	var old_lines: Array = [
		"I have sat here since before the benches were painted. I am not hungry yet.",
		"The ones who stay too long start to eat. First each other. Then they fall through, down to the Wastes.",
		"There is a tear behind the trees. It goes where they went. It will not take you without a name.",
	]
	var keeper_lines: Array = [
		"Lantern House. We gather what light the dead leave behind, and we shoot it back at what eats them.",
		"If you came out of Marsh's cellar as an Archer, this is your house. The door behind me goes to the Silver Reach, where the rest of us live.",
	]
	return [
		[10.5, 31, 180, "the Reaper", reaper_lines, {"cloth": Color(0.06, 0.06, 0.08), "coat": 2, "hair": 3, "hair_color": Color(0.85, 0.85, 0.9), "hair_seed": 31, "sash": 1, "face": 1, "blade": 31}],
		[40, 10, 0, "Ivo Marsh", marsh_lines, {"cloth": Color(0.24, 0.3, 0.22), "trim": Color(0.9, 0.9, 0.85), "coat": 2, "hair": 4, "hair_color": Color(0.85, 0.82, 0.6), "hair_seed": 33, "face": 3, "sleeves": true, "sash": 2}, marsh_action],
		[44, -36, 90, "the old soul", old_lines, {"cloth": Color(0.35, 0.33, 0.3), "trim": Color(0.6, 0.58, 0.5), "coat": 1, "hair": 4, "hair_color": Color(0.8, 0.8, 0.8), "hair_seed": 32, "face": 2, "skin": Color(0.8, 0.66, 0.52), "sleeves": false}],
		[150, -32, 0, "the Lantern Keeper", keeper_lines, {"cloth": Color(0.9, 0.92, 0.96), "trim": Color(0.2, 0.4, 0.8), "coat": 2, "hair": 2, "hair_color": Color(0.2, 0.2, 0.25), "hair_seed": 34, "face": 0, "halo": true, "accent": Color(0.4, 0.8, 1.0)}],
	]


func _talk_action(action: String, _i: int) -> void:
	if action == "train" and Quests.prologue_done(soul) and not soul.written():
		soul.flags["chapter"] = "training"
		main.travel("undercroft", "town")


# --------------------------------------------------------------------- sky

func _build_sky() -> void:
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.13, 0.36, 0.85)
	sm.sky_horizon_color = Color(0.55, 0.74, 0.98)
	sm.ground_bottom_color = Color(0.4, 0.5, 0.45)
	sm.ground_horizon_color = Color(0.55, 0.74, 0.98)
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.72, 0.95)
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 2.2
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.2
	env.adjustment_contrast = 1.06
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.03
	env.glow_hdr_threshold = 1.35
	env.fog_enabled = true
	env.fog_light_color = Color(0.5, 0.68, 0.95)
	env.fog_density = 0.0005
	env.fog_sky_affect = 0.0
	Detail.polish(env)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -38, 0)
	sun.light_color = Color(1.0, 0.97, 0.9)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 120.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	add_child(sun)
	var cloud_mat := StandardMaterial3D.new()
	cloud_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cloud_mat.albedo_color = Color(0.97, 0.98, 1.0)
	cloud_mat.disable_fog = true
	for i in range(26):
		var cb := ForgeMesh.Builder.new()
		var w := _r.randf_range(40.0, 90.0)
		var d := _r.randf_range(22.0, 46.0)
		cb.box(Vector3(w, 7.0, d))
		cb.box(Vector3(w * 0.6, 7.0, d * 0.7), Vector3(w * _r.randf_range(-0.3, 0.3), 5.0, d * _r.randf_range(-0.3, 0.3)))
		cb.box(Vector3(w * 0.4, 6.0, d * 0.5), Vector3(w * _r.randf_range(-0.4, 0.4), 9.0, d * _r.randf_range(-0.2, 0.2)))
		var mi := ForgeMesh.inst(cb.commit(), cloud_mat, self)
		var a := _r.randf() * TAU
		var rad := _r.randf_range(80.0, 620.0)
		mi.position = Vector3(cos(a) * rad, _r.randf_range(140.0, 210.0), sin(a) * rad)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


# ------------------------------------------------------------------ ground

# ------------------------------------------------------------------ ground

func _build_ground() -> void:
	var b := ForgeMesh.Builder.new()
	b.col = GRASS.darkened(0.12)
	b.box(Vector3(1200, 1.0, 1200), Vector3(0, -0.5, 0))
	for rd: Variant in ROADS:
		var r: Array = rd
		var x0 := float(r[0]); var z0 := float(r[1]); var x1 := float(r[2]); var z1 := float(r[3])
		b.col = Color(ROAD, 0.5)
		b.box(Vector3(x1 - x0, 0.03, z1 - z0), Vector3((x0 + x1) * 0.5, 0.0, (z0 + z1) * 0.5))
		b.col = Color(0.85, 0.78, 0.35, 0.5)
		var along_z := (z1 - z0) > (x1 - x0)
		var length := (z1 - z0) if along_z else (x1 - x0)
		var n := int(length / 7.0)
		for k in range(n):
			var t := -length * 0.5 + 3.5 + 7.0 * float(k)
			var at := Vector3((x0 + x1) * 0.5, 0.012, (z0 + z1) * 0.5 + t) if along_z else Vector3((x0 + x1) * 0.5 + t, 0.012, (z0 + z1) * 0.5)
			if _on_crossing(at.x, at.z, r) or (not along_z and at.x > RIVER[0] - 2.0 and at.x < RIVER[1] + 2.0):
				continue
			b.box(Vector3(0.22, 0.03, 3.0) if along_z else Vector3(3.0, 0.03, 0.22), at)
	b.col = Color(0.88, 0.88, 0.9, 0.5)
	for k in range(6):
		var o := -5.0 + 2.0 * float(k)
		b.box(Vector3(1.0, 0.03, 3.2), Vector3(o, 0.014, 8.4))
		b.box(Vector3(1.0, 0.03, 3.2), Vector3(o, 0.014, -8.4))
		b.box(Vector3(3.2, 0.03, 1.0), Vector3(8.4, 0.014, o))
		b.box(Vector3(3.2, 0.03, 1.0), Vector3(-8.4, 0.014, o))
	for xi in range(XS.size()):
		for zi in range(ZS.size()):
			var x0 := float(XS[xi][0]); var x1 := float(XS[xi][1])
			var z0 := float(ZS[zi][0]); var z1 := float(ZS[zi][1])
			b.col = Color(WALK, 0.75)
			b.box(Vector3(x1 - x0, 0.12, z1 - z0), Vector3((x0 + x1) * 0.5, 0.0, (z0 + z1) * 0.5))
			# the kerb: a paler lip round the pavement
			b.col = Color(0.62, 0.62, 0.64, 0.5)
			var cxm := (x0 + x1) * 0.5
			var czm := (z0 + z1) * 0.5
			b.box(Vector3(x1 - x0, 0.15, 0.3), Vector3(cxm, 0.0, z0 + 0.15))
			b.box(Vector3(x1 - x0, 0.15, 0.3), Vector3(cxm, 0.0, z1 - 0.15))
			b.box(Vector3(0.3, 0.15, z1 - z0), Vector3(x0 + 0.15, 0.0, czm))
			b.box(Vector3(0.3, 0.15, z1 - z0), Vector3(x1 - 0.15, 0.0, czm))
			var gcol := _block_ground(xi, zi)
			b.col = Color(gcol, 1.0 if gcol.g > gcol.r + 0.05 else 0.75)
			b.box(Vector3(x1 - x0 - 6.0, 0.14, z1 - z0 - 6.0), Vector3((x0 + x1) * 0.5, 0.0, (z0 + z1) * 0.5))
			if gcol.g > gcol.r + 0.05:
				# a low garden edging where grass meets pavement
				b.col = Color(0.55, 0.53, 0.5, 0.75)
				b.box(Vector3(x1 - x0 - 6.0, 0.2, 0.2), Vector3(cxm, 0.0, z0 + 3.1))
				b.box(Vector3(x1 - x0 - 6.0, 0.2, 0.2), Vector3(cxm, 0.0, z1 - 3.1))
				b.box(Vector3(0.2, 0.2, z1 - z0 - 6.0), Vector3(x0 + 3.1, 0.0, czm))
				b.box(Vector3(0.2, 0.2, z1 - z0 - 6.0), Vector3(x1 - 3.1, 0.0, czm))
	# the river: banks of grass, stone walls, water between, bridges across
	b.col = GRASS.lightened(0.04)
	b.box(Vector3(12.0, 0.13, 420.0), Vector3(-204.0, 0.0, 0.0))
	b.box(Vector3(6.0, 0.13, 420.0), Vector3(-169.0, 0.0, 0.0))
	b.col = Color(0.15, 0.36, 0.62)
	b.box(Vector3(RIVER[1] - RIVER[0], 0.05, 420.0), Vector3((RIVER[0] + RIVER[1]) * 0.5, -0.03, 0.0))
	b.col = Color(0.5, 0.5, 0.53, 0.75)
	for z: float in BRIDGES:
		b.box(Vector3(RIVER[1] - RIVER[0] + 2.0, 0.5, 12.0), Vector3((RIVER[0] + RIVER[1]) * 0.5, 0.2, z))
		b.box(Vector3(RIVER[1] - RIVER[0] + 2.0, 1.1, 0.4), Vector3((RIVER[0] + RIVER[1]) * 0.5, 0.75, z - 6.0))
		b.box(Vector3(RIVER[1] - RIVER[0] + 2.0, 1.1, 0.4), Vector3((RIVER[0] + RIVER[1]) * 0.5, 0.75, z + 6.0))
	# the weir: a broad stone floor over the water, where the hound lies
	b.col = Color(0.42, 0.44, 0.47)
	b.box(Vector3(RIVER[1] - RIVER[0] + 4.0, 0.45, 40.0), Vector3(WEIR.x, 0.18, WEIR.z))
	b.col = Color(0.85, 0.9, 0.95)
	b.box(Vector3(RIVER[1] - RIVER[0] + 4.0, 0.06, 1.2), Vector3(WEIR.x, 0.43, WEIR.z - 20.0))
	ForgeMesh.inst(b.commit(), Detail.ground("town"), self).name = "Ground"
	_solid_box(Vector3(0, -0.5 + 0.04, 0), Vector3(1200, 1.0, 1200))
	# stone walls along both banks, open at the bridges and the weir
	var wall := ForgeMesh.grain(Color(0.46, 0.47, 0.5), "slate")
	var gaps: Array = []
	for z: float in BRIDGES:
		gaps.append([z - 6.0, z + 6.0])
	gaps.append([WEIR.z - 20.0, WEIR.z + 20.0])
	gaps.sort_custom(func(a: Array, c: Array) -> bool: return float(a[0]) < float(c[0]))
	for bank: float in [RIVER[0], RIVER[1]]:
		var from := -HALF
		for g: Variant in gaps + [[HALF, HALF]]:
			var gp: Array = g
			var to := float(gp[0])
			if to - from > 0.5:
				var mid := (from + to) * 0.5
				_block(self, Vector3(0.8, 1.0, to - from), Vector3(bank, 0.5, mid), wall)
				_solid_box(Vector3(bank, 1.0, mid), Vector3(0.8, 2.0, to - from))
			from = float(gp[1])
	# and the water itself cannot be walked: a floor of walls in the channel
	var from_z := -HALF
	for g: Variant in gaps + [[HALF, HALF]]:
		var gp: Array = g
		var to := float(gp[0])
		if to - from_z > 0.5:
			_solid_box(Vector3((RIVER[0] + RIVER[1]) * 0.5, 1.0, (from_z + to) * 0.5), Vector3(RIVER[1] - RIVER[0] - 1.0, 2.0, to - from_z))
		from_z = float(gp[1])


func _on_crossing(x: float, z: float, own: Array) -> bool:
	for rd: Variant in ROADS:
		var r: Array = rd
		if r == own:
			continue
		if x > float(r[0]) - 4.0 and x < float(r[2]) + 4.0 and z > float(r[1]) - 4.0 and z < float(r[3]) + 4.0:
			return true
	return false


func height_at(_x: float, _z: float) -> float:
	return 0.04


## What each block's ground is: park, plaza, lot, or yards.
func _block_ground(xi: int, zi: int) -> Color:
	match [xi, zi]:
		[2, 2], [3, 4]:
			return GRASS
		[1, 2]:
			return Color(0.44, 0.44, 0.47)
		[1, 1], [2, 1], [1, 0], [2, 0]:
			return Color(0.5, 0.5, 0.53)
		[3, 0], [3, 1], [0, 0], [0, 1]:
			return Color(0.32, 0.33, 0.35)
		[2, 3]:
			return Color(0.42, 0.47, 0.38)
		[3, 2]:
			return Color(0.48, 0.44, 0.36)
	return GRASS.lightened(0.06)


func _commit(b: ForgeMesh.Builder, at: Vector3, yaw: float = 0.0, material: Material = null) -> MeshInstance3D:
	var mi := ForgeMesh.inst(b.commit(), material if material != null else paint, self, at)
	mi.rotation.y = yaw
	return mi


## A flat-roofed block: plinth, a glazed ground floor on its street face,
## a band at every floor, corner piers, framed windows on all four sides and
## a roof with a parapet and its machinery.
func _tower(cx: float, cz: float, w: float, d: float, h: float, wall: Color, solid: bool = true) -> void:
	var b := ForgeMesh.Builder.new()
	var g := ForgeMesh.Builder.new()
	var lit := ForgeMesh.Builder.new()
	var r := Rng.make([cx, cz, "tower"])
	var trim := wall.darkened(0.32)
	var frame := wall.lightened(0.35) if r.randf() < 0.6 else wall.darkened(0.5)
	b.col = wall
	b.box(Vector3(w, h, d), Vector3(0, h * 0.5, 0))
	b.col = trim
	b.box(Vector3(w + 0.3, 1.1, d + 0.3), Vector3(0, 0.55, 0))
	# corner piers
	b.col = wall.lightened(0.06)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			b.box(Vector3(0.7, h, 0.7), Vector3(sx * (w * 0.5 - 0.2), h * 0.5, sz * (d * 0.5 - 0.2)))
	# the parapet and the roof
	b.col = trim
	b.box(Vector3(w + 0.5, 0.25, d + 0.5), Vector3(0, h + 0.1, 0))
	for side: float in [-1.0, 1.0]:
		b.box(Vector3(w + 0.5, 0.9, 0.3), Vector3(0, h + 0.65, side * (d * 0.5 + 0.1)))
		b.box(Vector3(0.3, 0.9, d + 0.5), Vector3(side * (w * 0.5 + 0.1), h + 0.65, 0))
	b.col = Color(0.3, 0.3, 0.32)
	b.box(Vector3(w - 0.2, 0.06, d - 0.2), Vector3(0, h + 0.24, 0))
	# the ground floor: a shopfront and a canopy over the door
	var gf := 4.2
	var panes_c: Array = [Color(0.18, 0.26, 0.36), Color(0.22, 0.3, 0.42), Color(0.16, 0.22, 0.3)]
	g.col = Color(0.2, 0.28, 0.36)
	g.box(Vector3(w - 2.4, 2.6, 0.06), Vector3(0, 2.0, -d * 0.5 - 0.02))
	b.col = Color(0.15, 0.15, 0.17)
	for k in range(int((w - 2.4) / 2.2) + 1):
		b.box(Vector3(0.12, 2.6, 0.12), Vector3(-(w - 2.4) * 0.5 + 2.2 * float(k), 2.0, -d * 0.5 - 0.06))
	b.box(Vector3(w - 2.2, 0.16, 0.16), Vector3(0, 3.36, -d * 0.5 - 0.06))
	b.col = trim.darkened(0.3)
	b.box(Vector3(4.4, 0.18, 2.2), Vector3(0, 3.7, -d * 0.5 - 1.1))
	b.box(Vector3(0.1, 0.9, 0.1), Vector3(-2.0, 4.2, -d * 0.5 - 2.0), Vector3(-45, 0, 0))
	b.box(Vector3(0.1, 0.9, 0.1), Vector3(2.0, 4.2, -d * 0.5 - 2.0), Vector3(-45, 0, 0))
	lit.col = Color(1.0, 0.92, 0.76)
	lit.box(Vector3(3.6, 0.04, 0.1), Vector3(0, 3.6, -d * 0.5 - 2.1))
	b.col = trim
	b.box(Vector3(w + 0.2, 0.3, d + 0.2), Vector3(0, gf, 0))
	# the floors above
	var floors := maxi(1, int((h - gf) / 3.4))
	var cols_w := maxi(1, int(w / 3.2))
	var cols_d := maxi(1, int(d / 3.2))
	for f in range(floors):
		var y := gf + 1.8 + 3.4 * float(f)
		if y + 1.2 > h:
			break
		if f > 0:
			b.col = trim
			b.box(Vector3(w + 0.16, 0.2, d + 0.16), Vector3(0, y - 1.7, 0))
		for c in range(cols_w):
			var x := -w * 0.5 + 0.6 + (w - 1.2) * (float(c) + 0.5) / float(cols_w)
			for face: float in [-1.0, 1.0]:
				var pc: Color = panes_c[(c + f) % 3]
				var roll := r.randf()
				if roll < 0.12:
					pc = Color(0.72, 0.62, 0.48)
				elif roll < 0.2:
					pc = Color(1.0, 0.82, 0.55, 0.55)
				Detail.window(b, g, Vector3(x, y, face * (d * 0.5 + 0.02)), 0.0 if face < 0.0 else 180.0, 1.5, 1.7, frame, pc, w > 6.0)
		for c in range(cols_d):
			var z := -d * 0.5 + 0.6 + (d - 1.2) * (float(c) + 0.5) / float(cols_d)
			for face: float in [-1.0, 1.0]:
				var pc2: Color = panes_c[(c + f + 1) % 3]
				if r.randf() < 0.15:
					pc2 = Color(1.0, 0.82, 0.55, 0.55)
				Detail.window(b, g, Vector3(face * (w * 0.5 + 0.02), y, z), -90.0 if face > 0.0 else 90.0, 1.5, 1.7, frame, pc2, false)
	# the roof's machinery
	var ry := h + 0.27
	Detail.roof_hatch(b, Vector3(-w * 0.25, ry, d * 0.18), 0.0)
	for i in range(1 + int(r.randi() % 3)):
		Detail.ac_unit(b, Vector3(r.randf_range(-w * 0.3, w * 0.3), ry, r.randf_range(-d * 0.35, -d * 0.05)), r.randf_range(0, 2) * 90.0)
	for i in range(2):
		Detail.vent(b, Vector3(r.randf_range(-w * 0.4, w * 0.4), ry, r.randf_range(-d * 0.4, d * 0.4)))
	if h > 20.0 and r.randf() < 0.55:
		Detail.water_tank(b, Vector3(w * 0.22, ry, d * 0.2))
	if h > 40.0:
		Detail.antenna(b, Vector3(-w * 0.2, ry + 2.5, d * 0.2), 5.0)
	_commit(b, Vector3(cx, 0.07, cz))
	_commit(g, Vector3(cx, 0.07, cz), 0.0, panes)
	var lm := ForgeMesh.inst(lit.commit(), Detail.lit_material(2.0), self, Vector3(cx, 0.07, cz))
	lm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if solid:
		_solid_box(Vector3(cx, h * 0.5, cz), Vector3(w, h, d))


## A small house: footing, siding bands, framed windows with shutters, a
## door with a step and a lamp, a pitched roof with fascia and a ridge, and
## a chimney.
func _house(cx: float, cz: float, w: float, d: float, wall: Color, roof: Color, yaw_deg: float = 0.0) -> void:
	var b := ForgeMesh.Builder.new()
	var g := ForgeMesh.Builder.new()
	var lit := ForgeMesh.Builder.new()
	var r := Rng.make([cx, cz, "house"])
	var h := 4.4
	b.col = wall.darkened(0.4)
	b.box(Vector3(w + 0.2, 0.5, d + 0.2), Vector3(0, 0.25, 0))
	b.col = wall
	b.box(Vector3(w, h, d), Vector3(0, h * 0.5, 0))
	# siding: faint horizontal lines
	b.col = wall.darkened(0.08)
	for k in range(5):
		b.box(Vector3(w + 0.04, 0.06, d + 0.04), Vector3(0, 0.9 + 0.75 * float(k), 0))
	b.col = Color(0.92, 0.92, 0.9)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			b.box(Vector3(0.24, h, 0.24), Vector3(sx * w * 0.5, h * 0.5, sz * d * 0.5))
	b.col = roof
	b.wedge(Vector3(w + 0.8, 2.6, d * 0.5 + 0.4), Vector3(0, h + 1.3, -d * 0.25 - 0.2))
	b.wedge(Vector3(w + 0.8, 2.6, d * 0.5 + 0.4), Vector3(0, h + 1.3, d * 0.25 + 0.2), Vector3(0, 180, 0))
	b.col = roof.darkened(0.3)
	b.box(Vector3(w + 0.9, 0.22, 0.26), Vector3(0, h + 2.62, 0))
	b.box(Vector3(w + 0.85, 0.24, 0.14), Vector3(0, h + 0.02, -d * 0.5 - 0.45))
	b.box(Vector3(w + 0.85, 0.24, 0.14), Vector3(0, h + 0.02, d * 0.5 + 0.45))
	# gable ends: a triangle of wall closed with stacked boards
	b.col = wall.lightened(0.04)
	for side: float in [-1.0, 1.0]:
		for k in range(4):
			var gw := d * (1.0 - float(k) / 4.0) * 0.98
			b.box(Vector3(0.1, 0.62, gw), Vector3(side * (w * 0.5 + 0.01), h + 0.31 + 0.62 * float(k), 0))
	# chimney
	b.col = Color(0.5, 0.3, 0.24)
	var chx := w * 0.3 * (1.0 if r.randf() < 0.5 else -1.0)
	b.box(Vector3(0.9, 3.0, 0.9), Vector3(chx, h + 2.0, d * 0.18))
	b.col = Color(0.32, 0.22, 0.2)
	b.box(Vector3(1.1, 0.2, 1.1), Vector3(chx, h + 3.55, d * 0.18))
	# the door: frame, panel, step, lamp
	b.col = Color(0.92, 0.92, 0.9)
	b.box(Vector3(1.5, 2.6, 0.12), Vector3(0, 1.3, -d * 0.5 - 0.04))
	b.col = [Color(0.3, 0.2, 0.14), Color(0.2, 0.3, 0.45), Color(0.55, 0.15, 0.14), Color(0.2, 0.36, 0.26)][r.randi() % 4]
	b.box(Vector3(1.1, 2.3, 0.14), Vector3(0, 1.15, -d * 0.5 - 0.06))
	b.col = Color(0.8, 0.7, 0.3)
	b.box(Vector3(0.08, 0.08, 0.08), Vector3(0.38, 1.15, -d * 0.5 - 0.14))
	b.col = wall.darkened(0.3)
	b.box(Vector3(2.2, 0.2, 1.2), Vector3(0, 0.1, -d * 0.5 - 0.6))
	b.box(Vector3(1.8, 0.2, 0.7), Vector3(0, 0.3, -d * 0.5 - 0.4))
	b.col = Color(0.12, 0.12, 0.13)
	b.box(Vector3(0.2, 0.32, 0.18), Vector3(1.0, 2.3, -d * 0.5 - 0.1))
	lit.col = Color(1.0, 0.85, 0.55)
	lit.box(Vector3(0.14, 0.2, 0.06), Vector3(1.0, 2.28, -d * 0.5 - 0.2))
	var shutter := [Color(0.18, 0.3, 0.22), Color(0.22, 0.26, 0.4), Color(0.45, 0.18, 0.16), Color(0.28, 0.28, 0.3)][r.randi() % 4] as Color
	for side: float in [-1.0, 1.0]:
		for face: float in [-1.0, 1.0]:
			var pc := Color(0.2, 0.28, 0.38) if r.randf() < 0.7 else Color(0.85, 0.75, 0.55, 0.6)
			var at := Vector3(side * w * 0.3, 2.5, face * (d * 0.5 + 0.02))
			Detail.window(b, g, at, 0.0 if face < 0.0 else 180.0, 1.2, 1.3, Color(0.94, 0.94, 0.92), pc)
			if face < 0.0:
				b.col = shutter
				b.box(Vector3(0.46, 1.4, 0.06), at + Vector3(-0.9, 0, -0.06))
				b.box(Vector3(0.46, 1.4, 0.06), at + Vector3(0.9, 0, -0.06))
				b.col = Color(0.35, 0.24, 0.16)
				b.box(Vector3(1.3, 0.3, 0.36), at + Vector3(0, -0.9, -0.24))
				b.col = Color(0.85, 0.3, 0.35) if r.randf() < 0.5 else Color(0.95, 0.85, 0.35)
				b.box(Vector3(1.1, 0.16, 0.24), at + Vector3(0, -0.68, -0.24))
	var yaw := deg_to_rad(yaw_deg)
	_commit(b, Vector3(cx, 0.07, cz), yaw)
	_commit(g, Vector3(cx, 0.07, cz), yaw, panes)
	var lm := ForgeMesh.inst(lit.commit(), Detail.lit_material(2.2), self, Vector3(cx, 0.07, cz))
	lm.rotation.y = yaw
	lm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_solid_box(Vector3(cx, h * 0.5, cz), Vector3(w, h, d), yaw)


## A shop: brick-coloured front, a framed shop window with mullions, a
## striped awning, a lit sign board, a door with a frame, and a cornice.
func _shop(cx: float, cz: float, w: float, d: float, colour: Color) -> void:
	var b := ForgeMesh.Builder.new()
	var g := ForgeMesh.Builder.new()
	var lit := ForgeMesh.Builder.new()
	var h := 5.2
	b.col = Color(0.58, 0.55, 0.5)
	b.box(Vector3(w, h, d), Vector3(0, h * 0.5, 0))
	b.col = Color(0.5, 0.36, 0.3)
	b.box(Vector3(w + 0.1, h - 0.4, 0.12), Vector3(0, (h - 0.4) * 0.5, -d * 0.5 - 0.02))
	b.col = Color(0.3, 0.3, 0.33)
	b.box(Vector3(w + 0.6, 0.3, d + 0.6), Vector3(0, h + 0.15, 0))
	b.box(Vector3(w + 0.4, 0.2, d + 0.4), Vector3(0, h - 0.1, 0))
	b.col = Color(0.36, 0.34, 0.33)
	b.box(Vector3(w + 0.2, 0.5, 0.3), Vector3(0, 0.25, -d * 0.5 - 0.1))
	Detail.awning(b, Vector3(0, 3.25, -d * 0.5 - 0.1), 0.0, w - 0.8, colour, Color(0.95, 0.94, 0.9))
	# sign board with letters picked out in light
	b.col = colour.darkened(0.55)
	b.box(Vector3(w * 0.62, 1.0, 0.22), Vector3(0, 4.35, -d * 0.5 - 0.12))
	b.col = colour
	b.box(Vector3(w * 0.66, 0.08, 0.26), Vector3(0, 4.88, -d * 0.5 - 0.12))
	b.box(Vector3(w * 0.66, 0.08, 0.26), Vector3(0, 3.82, -d * 0.5 - 0.12))
	var r := Rng.make([cx, cz, "sign"])
	var letters := 4 + int(r.randi() % 4)
	lit.col = Color(1.0, 0.95, 0.85)
	for k in range(letters):
		var lw := r.randf_range(0.3, 0.55)
		lit.box(Vector3(lw, r.randf_range(0.42, 0.56), 0.05), Vector3(-w * 0.24 + w * 0.48 * (float(k) + 0.5) / float(letters), 4.35, -d * 0.5 - 0.25))
	# shop window and door on the street face
	b.col = Color(0.16, 0.16, 0.18)
	b.box(Vector3(w * 0.52, 2.1, 0.16), Vector3(-w * 0.14, 1.65, -d * 0.5 - 0.06))
	g.col = Color(0.3, 0.4, 0.46, 0.7)
	g.box(Vector3(w * 0.5, 1.9, 0.12), Vector3(-w * 0.14, 1.65, -d * 0.5 - 0.1))
	b.col = Color(0.14, 0.14, 0.16)
	for k in range(3):
		b.box(Vector3(0.08, 1.9, 0.14), Vector3(-w * 0.14 - w * 0.25 + w * 0.5 * float(k + 1) / 4.0, 1.65, -d * 0.5 - 0.13))
	b.col = Color(0.9, 0.9, 0.88)
	b.box(Vector3(1.5, 2.6, 0.16), Vector3(w * 0.32, 1.3, -d * 0.5 - 0.06))
	b.col = Color(0.25, 0.2, 0.16)
	b.box(Vector3(1.2, 2.3, 0.18), Vector3(w * 0.32, 1.15, -d * 0.5 - 0.08))
	g.col = Color(0.3, 0.4, 0.46, 0.7)
	g.box(Vector3(0.7, 1.0, 0.04), Vector3(w * 0.32, 1.6, -d * 0.5 - 0.18))
	# the back
	g.col = Color(0.2, 0.28, 0.36)
	g.box(Vector3(1.6, 1.0, 0.12), Vector3(-w * 0.28, 3.4, d * 0.5 + 0.02))
	g.box(Vector3(1.6, 1.0, 0.12), Vector3(w * 0.1, 3.4, d * 0.5 + 0.02))
	b.col = Color(0.2, 0.2, 0.22)
	b.box(Vector3(1.1, 2.2, 0.14), Vector3(w * 0.34, 1.1, d * 0.5 + 0.03))
	b.col = colour.darkened(0.25)
	b.box(Vector3(w, 0.5, 0.16), Vector3(0, h - 0.6, d * 0.5 + 0.04))
	b.col = Color(0.22, 0.3, 0.24)
	b.box(Vector3(2.0, 1.3, 1.1), Vector3(-w * 0.3, 0.65, d * 0.5 + 0.9))
	Detail.ac_unit(b, Vector3(w * 0.2, h + 0.3, 0.0), 0.0)
	# an A-frame board out front
	b.col = Color(0.2, 0.2, 0.22)
	b.box(Vector3(0.7, 1.0, 0.06), Vector3(-w * 0.42, 0.5, -d * 0.5 - 1.6), Vector3(12, 0, 0))
	b.col = Color(0.9, 0.9, 0.86)
	b.box(Vector3(0.5, 0.06, 0.07), Vector3(-w * 0.42, 0.75, -d * 0.5 - 1.66), Vector3(12, 0, 0))
	b.box(Vector3(0.4, 0.06, 0.07), Vector3(-w * 0.42, 0.55, -d * 0.5 - 1.62), Vector3(12, 0, 0))
	_commit(b, Vector3(cx, 0.07, cz))
	_commit(g, Vector3(cx, 0.07, cz), 0.0, panes)
	var lm := ForgeMesh.inst(lit.commit(), Detail.lit_material(2.6), self, Vector3(cx, 0.07, cz))
	lm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_solid_box(Vector3(cx, h * 0.5, cz), Vector3(w, h, d))


func _tree_mesh() -> ArrayMesh:
	var b := ForgeMesh.Builder.new()
	var th := _r.randf_range(2.6, 3.8)
	b.col = BARK
	b.box(Vector3(0.6, th, 0.6), Vector3(0, th * 0.5, 0))
	var green := Color(0.13, 0.4, 0.15)
	var y := th
	for k in range(2 + int(_r.randi() % 2)):
		var s := _r.randf_range(2.6, 3.8) * (1.0 - 0.22 * float(k))
		var hh := _r.randf_range(1.5, 2.2)
		b.col = green.lightened(0.08 * float(k) + _r.randf() * 0.06)
		b.box(Vector3(s, hh, s * _r.randf_range(0.85, 1.0)), Vector3(_r.randf_range(-0.5, 0.5), y + hh * 0.5, _r.randf_range(-0.5, 0.5)), Vector3(0, _r.randf_range(0, 40), 0))
		y += hh * 0.85
	return b.commit()


func _bench(x: float, z: float, yaw_deg: float) -> void:
	var b := ForgeMesh.Builder.new()
	b.col = Color(0.45, 0.3, 0.18)
	b.box(Vector3(2.2, 0.14, 0.6), Vector3(0, 0.5, 0))
	b.box(Vector3(2.2, 0.6, 0.12), Vector3(0, 0.95, 0.28), Vector3(-8, 0, 0))
	b.col = Color(0.18, 0.18, 0.2)
	b.box(Vector3(0.12, 0.5, 0.5), Vector3(-0.9, 0.25, 0))
	b.box(Vector3(0.12, 0.5, 0.5), Vector3(0.9, 0.25, 0))
	_commit(b, Vector3(x, 0.07, z), deg_to_rad(yaw_deg))
	_solid_box(Vector3(x, 0.5, z), Vector3(2.2, 0.9, 0.7), deg_to_rad(yaw_deg))


func _lamp(x: float, z: float) -> void:
	var b := ForgeMesh.Builder.new()
	b.col = Color(0.16, 0.17, 0.2)
	b.box(Vector3(0.24, 5.6, 0.24), Vector3(0, 2.8, 0))
	b.box(Vector3(0.5, 0.3, 0.5), Vector3(0, 0.15, 0))
	b.box(Vector3(1.4, 0.16, 0.2), Vector3(0.6, 5.5, 0))
	_commit(b, Vector3(x, 0.07, z))
	_block(self, Vector3(0.6, 0.2, 0.36), Vector3(x + 1.1, 5.4, z), ForgeMesh.glow(Color(1.0, 0.92, 0.7), 1.3))
	_solid(Vector3(x, 0, z), 0.2, 5.0)


func _car(x: float, z: float, yaw_deg: float, colour: Color) -> void:
	var b := ForgeMesh.Builder.new()
	b.col = colour
	b.box(Vector3(2.0, 0.8, 4.4), Vector3(0, 0.75, 0))
	b.col = Color(0.12, 0.14, 0.18)
	b.box(Vector3(1.8, 0.75, 2.2), Vector3(0, 1.5, 0.2))
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			b.col = Color(0.06, 0.06, 0.07)
			b.box(Vector3(0.3, 0.7, 0.7), Vector3(sx * 0.95, 0.35, sz * 1.4))
	b.col = Color(1.0, 0.95, 0.75)
	b.box(Vector3(0.4, 0.2, 0.06), Vector3(-0.65, 0.85, -2.2))
	b.box(Vector3(0.4, 0.2, 0.06), Vector3(0.65, 0.85, -2.2))
	_commit(b, Vector3(x, 0.07, z), deg_to_rad(yaw_deg))
	_solid_box(Vector3(x, 0.9, z), Vector3(2.0, 1.8, 4.4), deg_to_rad(yaw_deg))


func _rail(x0: float, z0: float, x1: float, z1: float) -> void:
	var b := ForgeMesh.Builder.new()
	b.col = Color(0.9, 0.9, 0.92)
	var from := Vector3(x0, 0, z0)
	var to := Vector3(x1, 0, z1)
	var length := from.distance_to(to)
	var dir := (to - from) / length
	var yaw := rad_to_deg(atan2(dir.x, dir.z))
	var mid := (from + to) * 0.5
	b.box(Vector3(0.08, 0.08, length), mid + Vector3(0, 1.0, 0), Vector3(0, yaw, 0))
	b.box(Vector3(0.08, 0.08, length), mid + Vector3(0, 0.55, 0), Vector3(0, yaw, 0))
	var posts := int(length / 2.0) + 1
	for k in range(posts):
		b.box(Vector3(0.1, 1.1, 0.1), from + dir * (length * float(k) / float(maxi(1, posts - 1))) + Vector3(0, 0.55, 0))
	_commit(b, Vector3(0, 0.07, 0))


# ------------------------------------------------------------------ blocks

# ------------------------------------------------------------------ blocks

func _warehouse(cx: float, cz: float, w: float, d: float, colour: Color) -> void:
	var b := ForgeMesh.Builder.new()
	var h := 9.0
	b.col = colour
	b.box(Vector3(w, h, d), Vector3(0, h * 0.5, 0))
	b.col = colour.darkened(0.3)
	b.wedge(Vector3(w + 0.6, 2.2, d * 0.5 + 0.3), Vector3(0, h + 1.1, -d * 0.25 - 0.15))
	b.wedge(Vector3(w + 0.6, 2.2, d * 0.5 + 0.3), Vector3(0, h + 1.1, d * 0.25 + 0.15), Vector3(0, 180, 0))
	b.col = Color(0.28, 0.3, 0.33)
	b.box(Vector3(w * 0.4, h * 0.6, 0.2), Vector3(0, h * 0.3, -d * 0.5 - 0.05))
	b.col = Color(0.9, 0.75, 0.2)
	b.box(Vector3(w * 0.42, 0.3, 0.22), Vector3(0, h * 0.62, -d * 0.5 - 0.06))
	_commit(b, Vector3(cx, 0.07, cz))
	_solid_box(Vector3(cx, h * 0.5, cz), Vector3(w, h, d))


func _crates(cx: float, cz: float) -> void:
	var b := ForgeMesh.Builder.new()
	for k in range(5):
		b.col = Color(0.5, 0.36, 0.2).darkened(_r.randf() * 0.2)
		var s := _r.randf_range(1.0, 1.6)
		b.box(Vector3(s, s, s), Vector3(_r.randf_range(-2, 2), s * 0.5 + (1.2 if k == 4 else 0.0), _r.randf_range(-2, 2)), Vector3(0, _r.randf_range(0, 40), 0))
	_commit(b, Vector3(cx, 0.07, cz))
	_solid(Vector3(cx, 0, cz), 2.2, 2.0)


func _block_center(xi: int, zi: int) -> Vector2:
	return Vector2((float(XS[xi][0]) + float(XS[xi][1])) * 0.5, (float(ZS[zi][0]) + float(ZS[zi][1])) * 0.5)


func _build_blocks() -> void:
	var walls: Array = [Color(0.66, 0.56, 0.42), Color(0.5, 0.58, 0.5), Color(0.64, 0.46, 0.4), Color(0.5, 0.54, 0.66), Color(0.6, 0.6, 0.6)]
	var roofs: Array = [Color(0.5, 0.2, 0.16), Color(0.25, 0.28, 0.36), Color(0.36, 0.24, 0.16)]
	var towers: Array = [Color(0.6, 0.6, 0.64), Color(0.46, 0.54, 0.66), Color(0.64, 0.55, 0.44), Color(0.54, 0.57, 0.6), Color(0.42, 0.46, 0.5)]
	var tree_meshes: Array = []
	for i in range(6):
		tree_meshes.append(_tree_mesh())
	var trees: Array = [[], [], [], [], [], []]
	var add_tree := func(x: float, z: float) -> void:
		if not _free(x, z, 4.0):
			return
		var k := int(_r.randi() % 6)
		(trees[k] as Array).append(Transform3D(Basis(Vector3.UP, _r.randf() * TAU).scaled(Vector3.ONE * _r.randf_range(0.9, 1.35)), Vector3(x, 0.07, z)))
		_solid(Vector3(x, 0, z), 0.35, 3.0)

	# downtown: towers, north of the flats and the park
	for xi in [1, 2]:
		for zi in [0, 1]:
			var c := _block_center(xi, zi)
			var bw := float(XS[xi][1]) - float(XS[xi][0])
			var bd := float(ZS[zi][1]) - float(ZS[zi][0])
			var n := 2
			for a in range(n):
				for bb in range(n):
					var tx := c.x - bw * 0.25 + bw * 0.5 * float(a)
					var tz := c.y - bd * 0.25 + bd * 0.5 * float(bb)
					var w := _r.randf_range(14.0, bw * 0.38)
					var d := _r.randf_range(12.0, bd * 0.36)
					_tower(tx, tz, w, d, _r.randf_range(24.0, 62.0) if zi == 0 else _r.randf_range(18.0, 40.0), towers[(xi + zi + a + bb) % towers.size()])
	# the flats: four blocks of flats round a courtyard, where the Gutter King nests
	_tower(-70, -70, 18, 16, 22, towers[0])
	_tower(-20, -72, 18, 14, 26, towers[1])
	_tower(-72, -20, 16, 18, 18, towers[2])
	_tower(-18, -18, 16, 14, 20, towers[3])
	var court := ForgeMesh.Builder.new()
	court.col = Color(0.36, 0.37, 0.4)
	court.box(Vector3(34, 0.05, 34), Vector3.ZERO)
	court.col = Color(0.62, 0.62, 0.66)
	for k in range(4):
		court.box(Vector3(34, 0.06, 0.2), Vector3(0, 0, -17.0 + 11.3 * float(k)))
		court.box(Vector3(0.2, 0.06, 34), Vector3(-17.0 + 11.3 * float(k), 0, 0))
	_commit(court, Vector3(FLATS.x, 0.1, FLATS.z))
	for sp: Variant in [[-50, -84], [-84, -50], [-12, -50], [-50, -12]]:
		_crates(float(sp[0]) + 4.0, float(sp[1]) + 4.0)
	# the park: trees, a pond, the cairn among graves, the tear behind
	for i in range(46):
		add_tree.call(_r.randf_range(12, 80), _r.randf_range(-80, -12))
	var pb := ForgeMesh.Builder.new()
	pb.col = Color(0.5, 0.5, 0.54)
	pb.column(8.6, 8.6, 0.0, 0.25, 24)
	pb.col = Color(0.2, 0.45, 0.75)
	pb.column(7.8, 7.8, 0.0, 0.3, 24)
	_commit(pb, Vector3(28, 0.07, -66))
	_solid(Vector3(28, 0, -66), 8.0, 1.0)
	var pathb := ForgeMesh.Builder.new()
	pathb.col = Color(0.7, 0.66, 0.56)
	pathb.box(Vector3(3.0, 0.04, 46.0), Vector3(52, 0.08, -29))
	pathb.box(Vector3(46.0, 0.04, 3.0), Vector3(32, 0.08, -14))
	pathb.box(Vector3(26.0, 0.04, 3.0), Vector3(62, 0.08, -60), Vector3(0, 40, 0))
	_commit(pathb, Vector3(0, 0.07, 0))
	var gb := ForgeMesh.Builder.new()
	for i in range(10):
		gb.col = Color(0.55, 0.56, 0.6).darkened(_r.randf() * 0.2)
		var gx := 58.0 + 3.0 * float(i % 5)
		var gz := -52.0 - 4.0 * float(i / 5)
		gb.box(Vector3(1.0, 1.5, 0.3), Vector3(gx, 0.75, gz), Vector3(_r.randf_range(-4, 4), 0, _r.randf_range(-3, 3)))
		gb.box(Vector3(1.3, 0.2, 0.6), Vector3(gx, 0.1, gz))
	_commit(gb, Vector3(0, 0.07, 0))
	_bench(44, -38, 90)
	_bench(24, -16, 0)
	_bench(40, -16, 0)
	var db := ForgeMesh.Builder.new()
	db.col = Color(0.2, 0.19, 0.2)
	db.column(7.0, 7.0, 0.0, 0.05, 20)
	_commit(db, Vector3(70, 0.08, -70))
	_rail(9.5, -9.5, 9.5, -81)
	_rail(9.5, -9.5, 22, -9.5)
	_rail(40, -9.5, 81, -9.5)
	# Lantern House: a long pale hall hung with lanterns, east of the park
	var lh := ForgeMesh.Builder.new()
	lh.col = Color(0.86, 0.88, 0.92)
	lh.box(Vector3(46, 9, 22), Vector3(0, 4.5, 0))
	lh.col = Color(0.22, 0.36, 0.6)
	lh.wedge(Vector3(48, 4, 12), Vector3(0, 11.0, -5.5))
	lh.wedge(Vector3(48, 4, 12), Vector3(0, 11.0, 5.5), Vector3(0, 180, 0))
	lh.col = Color(0.2, 0.2, 0.24)
	lh.box(Vector3(4, 5, 0.3), Vector3(0, 2.5, 11.1))
	_commit(lh, Vector3(150, 0.07, -52))
	_solid_box(Vector3(150, 4.5, -52), Vector3(46, 9, 22))
	for k in range(7):
		_block(self, Vector3(0.6, 0.8, 0.6), Vector3(130.0 + 6.6 * float(k), 7.2, -40.6), ForgeMesh.glow(Color(0.5, 0.85, 1.0), 1.6))
	for i in range(14):
		add_tree.call(_r.randf_range(100, 205), _r.randf_range(-24, -12))
	# the school and its court, south-west of the junction
	_tower(-45, 18, 70, 10, 11, Color(0.66, 0.58, 0.44))
	var cb := ForgeMesh.Builder.new()
	cb.col = Color(0.62, 0.25, 0.2)
	cb.box(Vector3(28, 0.05, 16), Vector3.ZERO)
	cb.col = Color(0.2, 0.5, 0.42)
	cb.box(Vector3(8, 0.06, 6), Vector3(-10, 0, 0))
	cb.box(Vector3(8, 0.06, 6), Vector3(10, 0, 0))
	cb.col = Color(0.92, 0.92, 0.94)
	cb.box(Vector3(0.14, 0.07, 16), Vector3.ZERO)
	cb.box(Vector3(28, 0.07, 0.14), Vector3(0, 0, -7.9))
	cb.box(Vector3(28, 0.07, 0.14), Vector3(0, 0, 7.9))
	for side: float in [-1.0, 1.0]:
		cb.col = Color(0.16, 0.17, 0.2)
		cb.box(Vector3(0.2, 3.6, 0.2), Vector3(side * 14.4, 1.8, 0))
		cb.box(Vector3(1.2, 0.14, 0.14), Vector3(side * 13.8, 3.5, 0))
		cb.col = Color(0.95, 0.95, 0.97)
		cb.box(Vector3(0.1, 1.2, 1.8), Vector3(side * 13.2, 3.6, 0))
	_commit(cb, Vector3(-30, 0.09, 50))
	_rail(-80, 32, -80, 80)
	_rail(-80, 80, -10, 80)
	_bench(-20, 34, 0)
	_bench(-44, 34, 0)
	# the main road shops; Ivo Marsh's is the green one
	var colours: Array = [Color(0.8, 0.2, 0.2), Color(0.25, 0.5, 0.3), Color(0.85, 0.65, 0.15), Color(0.35, 0.3, 0.7)]
	for i in range(4):
		_shop(16.0 + 18.0 * float(i), 20.0, 14.0, 12.0, colours[i])
	_car(30, 46, 90, Color(0.75, 0.15, 0.15))
	_car(46, 46, 90, Color(0.2, 0.3, 0.7))
	_car(70, 46, -90, Color(0.85, 0.85, 0.88))
	for sp: Variant in [[12, 12], [12, 80], [80, 12]]:
		_lamp(float(sp[0]), float(sp[1]))
	# the east: warehouses and yards, the Ledger Gate in the far corner
	var wcol: Array = [Color(0.5, 0.42, 0.34), Color(0.4, 0.44, 0.48), Color(0.56, 0.5, 0.42)]
	for i in range(6):
		_warehouse(110.0 + 34.0 * float(i % 3), -120.0 - 30.0 * float(i / 3) + (0.0 if i < 3 else -10.0), 26.0, 18.0, wcol[i % 3])
	for i in range(5):
		_crates(_r.randf_range(100, 200), _r.randf_range(-150, -100))
	var shrine := ForgeMesh.Builder.new()
	shrine.col = Color(0.85, 0.85, 0.88)
	shrine.box(Vector3(10, 0.6, 10), Vector3(0, 0.3, 0))
	shrine.box(Vector3(8, 0.6, 8), Vector3(0, 0.9, 0))
	for sx: float in [-1.0, 1.0]:
		shrine.col = Color(0.22, 0.24, 0.3)
		shrine.box(Vector3(0.8, 8, 0.8), Vector3(sx * 3.4, 4.6, 0))
	shrine.col = Color(0.22, 0.24, 0.3)
	shrine.box(Vector3(9.5, 0.8, 1.2), Vector3(0, 8.8, 0))
	shrine.box(Vector3(7.5, 0.5, 1.0), Vector3(0, 7.6, 0))
	_commit(shrine, Vector3(190, 0.07, -190))
	# the far west and the south: houses with yards, gardens, more trees
	var house_rows: Array = []
	for zi in range(ZS.size()):
		for xi in range(XS.size()):
			var key := "%d,%d" % [xi, zi]
			if key in ["0,2", "0,3", "0,4", "0,5", "1,4", "1,5", "2,4", "2,5", "3,3", "3,5"]:
				house_rows.append([xi, zi])
	for hr: Variant in house_rows:
		var h: Array = hr
		var xi := int(h[0])
		var zi := int(h[1])
		var x0 := float(XS[xi][0]) + 10.0
		var x1 := float(XS[xi][1]) - 10.0
		var z0 := float(ZS[zi][0]) + 9.0
		var z1 := float(ZS[zi][1]) - 9.0
		var cols := maxi(1, int((x1 - x0) / 18.0))
		for c in range(cols + 1):
			var x := lerpf(x0, x1, float(c) / float(maxi(1, cols)))
			_house(x, z0, 11.0, 9.0, walls[(c + zi) % walls.size()], roofs[(c + xi) % roofs.size()], 180.0)
			if z1 - z0 > 26.0:
				_house(x, z1, 11.0, 9.0, walls[(c + zi + 2) % walls.size()], roofs[(c + xi + 1) % roofs.size()], 0.0)
			add_tree.call(x + _r.randf_range(-6, 6), (z0 + z1) * 0.5 + _r.randf_range(-4, 4))
	# the warehouses' neighbours and the west industrial blocks
	for i in range(4):
		_warehouse(-125.0, -190.0 + 34.0 * float(i % 2) + (0.0 if i < 2 else 60.0), 40.0, 18.0, wcol[i % 3])
	for i in range(3):
		_crates(-125.0 + _r.randf_range(-20, 20), -60.0 + _r.randf_range(-10, 10))
	# the river banks: reeds and trees on the west bank
	for i in range(40):
		add_tree.call(_r.randf_range(-209, -200), _r.randf_range(-205, 205))
	for k in range(6):
		ForgeMesh.scatter(self, tree_meshes[k], paint, trees[k])
	for sp: Variant in [[-150, 10], [-150, -80], [-150, 100], [100, 10], [100, 100], [-80, 100], [-10, -100], [10, -150]]:
		_lamp(float(sp[0]), float(sp[1]))
	# where you died: flowers, a candle and a picture, under a lamp
	_lamp(9.6, 47)
	var mb := ForgeMesh.Builder.new()
	var petals: Array = [Color(0.9, 0.2, 0.3), Color(0.95, 0.8, 0.2), Color(0.95, 0.95, 0.95), Color(0.6, 0.3, 0.8)]
	for i in range(9):
		mb.col = Color(0.15, 0.45, 0.2)
		var fx := _r.randf_range(-0.5, 0.5)
		var fz := _r.randf_range(-0.3, 0.3)
		mb.box(Vector3(0.04, 0.3, 0.04), Vector3(fx, 0.15, fz), Vector3(_r.randf_range(-25, 25), 0, _r.randf_range(-25, 25)))
		mb.col = petals[i % petals.size()]
		mb.box(Vector3(0.14, 0.12, 0.14), Vector3(fx, 0.33, fz))
	mb.col = Color(0.3, 0.2, 0.14)
	mb.box(Vector3(0.36, 0.46, 0.05), Vector3(0.0, 0.25, 0.38), Vector3(-14, 0, 0))
	mb.col = Color(0.85, 0.85, 0.82)
	mb.box(Vector3(0.28, 0.36, 0.055), Vector3(0.0, 0.25, 0.375), Vector3(-14, 0, 0))
	mb.col = Color(0.92, 0.9, 0.84)
	mb.box(Vector3(0.1, 0.24, 0.1), Vector3(0.55, 0.12, 0.2))
	_commit(mb, Vector3(9.8, 0.07, 45.6), deg_to_rad(90))
	_block(self, Vector3(0.05, 0.08, 0.05), Vector3(9.6, 0.35, 45.05), ForgeMesh.glow(Color(1.0, 0.75, 0.3), 2.0))


func _free(x: float, z: float, margin: float) -> bool:
	for c: Variant in CAIRNS:
		if Vector2(x - (c as Vector3).x, z - (c as Vector3).z).length() < margin + 3.0:
			return false
	if Vector2(x - 70.0, z + 70.0).length() < 9.0 or Vector2(x - 28.0, z + 66.0).length() < 10.5:
		return false
	if x > 54.0 and x < 74.0 and z > -60.0 and z < -48.0:
		return false
	if absf(x - 52.0) < 3.0 and z > -54.0 and z < -6.0:
		return false
	if Vector2(x - FLATS.x, z - FLATS.z).length() < 22.0:
		return false
	for d: Variant in [[44, -36], [30, -42], [74, -78], [150, -32], [150, -22]]:
		if absf(x - float(d[0])) < 6.0 and absf(z - float(d[1])) < 6.0:
			return false
	return true


## A far ring of tall blocks, so the town sits in a city.
func _build_skyline() -> void:
	var b := ForgeMesh.Builder.new()
	var g := ForgeMesh.Builder.new()
	for i in range(46):
		var a := TAU * float(i) / 34.0 + _r.randf_range(-0.06, 0.06)
		var rad := _r.randf_range(275.0, 345.0)
		var w := _r.randf_range(16.0, 30.0)
		var d := _r.randf_range(14.0, 26.0)
		var h := _r.randf_range(24.0, 80.0)
		var at := Vector3(cos(a) * rad, 0, sin(a) * rad)
		var yaw := _r.randf_range(0, 90)
		var shade := _r.randf_range(0.34, 0.52)
		b.col = Color(shade, shade + 0.03, shade + 0.1)
		b.box(Vector3(w, h, d), at + Vector3(0, h * 0.5, 0), Vector3(0, yaw, 0))
		var bands := int(h / 5.0)
		for k in range(bands):
			g.box(Vector3(w + 0.1, 1.0, d + 0.1), at + Vector3(0, 3.5 + 5.0 * float(k), 0), Vector3(0, yaw, 0))
	_commit(b, Vector3.ZERO)
	_commit(g, Vector3.ZERO, 0.0, glass)


# ------------------------------------------------------------ the street

## Is a spot on the pavement free of anything you must walk to?
func _prop_clear(x: float, z: float) -> bool:
	if not _free(x, z, 2.0):
		return false
	if Vector2(x - WAKE.x, z - WAKE.z).length() < 6.0:
		return false
	var pts: Array = []
	for bd: Variant in board_list():
		pts.append(Vector2(float(bd[0]), float(bd[1])))
	for pt: Variant in portal_list():
		pts.append(Vector2(float(pt[0]), float(pt[1])))
	for rl: Variant in RELICS:
		pts.append(Vector2(float(rl[0]), float(rl[1])))
	for st: Variant in STELES:
		pts.append(Vector2(float(st[0]), float(st[1])))
	for p: Variant in pts:
		if Vector2(x, z).distance_to(p) < 5.0:
			return false
	if x > 8.0 and x < 84.0 and z > 13.0 and z < 27.0:
		return false
	return true


## Lamps, bins, hydrants, signs, lights at the crossings, poles and wires
## along the houses, a bus stop on the main road, manholes in the roads.
func _build_street() -> void:
	var b := ForgeMesh.Builder.new()
	var lit := ForgeMesh.Builder.new()
	var r := Rng.make(["town", "street"])
	for xi in range(XS.size()):
		for zi in range(ZS.size()):
			var x0 := float(XS[xi][0]); var x1 := float(XS[xi][1])
			var z0 := float(ZS[zi][0]); var z1 := float(ZS[zi][1])
			# corner signs and bollards
			for corner: Vector2 in [Vector2(x0 + 1.2, z0 + 1.2), Vector2(x1 - 1.2, z0 + 1.2), Vector2(x0 + 1.2, z1 - 1.2), Vector2(x1 - 1.2, z1 - 1.2)]:
				if _prop_clear(corner.x, corner.y) and r.randf() < 0.6:
					Detail.street_sign(b, Vector3(corner.x, 0.13, corner.y), r.randf_range(0, 4) * 90.0)
					_solid(Vector3(corner.x, 0, corner.y), 0.12, 3.0)
			# along each edge: lamps every ~32 m, bins and hydrants between
			var edges: Array = [
				[Vector2(x0, z0 + 1.0), Vector2(x1, z0 + 1.0), 0.0], [Vector2(x0, z1 - 1.0), Vector2(x1, z1 - 1.0), 180.0],
				[Vector2(x0 + 1.0, z0), Vector2(x0 + 1.0, z1), 90.0], [Vector2(x1 - 1.0, z0), Vector2(x1 - 1.0, z1), -90.0],
			]
			for e: Variant in edges:
				var ea: Vector2 = e[0]
				var eb: Vector2 = e[1]
				var yaw := float(e[2])
				var length := ea.distance_to(eb)
				var n := int(length / 32.0)
				for k in range(n):
					var t := (float(k) + 0.5) / float(n)
					var p := ea.lerp(eb, t)
					if _prop_clear(p.x, p.y):
						Detail.street_lamp(b, lit, Vector3(p.x, 0.13, p.y), yaw)
						_solid(Vector3(p.x, 0, p.y), 0.25, 6.0)
					var q := ea.lerp(eb, t + 0.5 / float(n) * 0.5)
					if _prop_clear(q.x, q.y):
						var roll := r.randf()
						if roll < 0.35:
							Detail.bin(b, Vector3(q.x, 0.13, q.y), yaw)
							_solid(Vector3(q.x, 0, q.y), 0.35, 1.0)
						elif roll < 0.55:
							Detail.hydrant(b, Vector3(q.x, 0.13, q.y), yaw)
							_solid(Vector3(q.x, 0, q.y), 0.25, 1.0)
						elif roll < 0.65:
							Detail.mailbox(b, Vector3(q.x, 0.13, q.y), yaw)
							_solid(Vector3(q.x, 0, q.y), 0.35, 1.3)
	# traffic lights at the big crossings, bollards at their corners
	for c: Vector2 in [Vector2(0, 0), Vector2(0, 90), Vector2(90, 0), Vector2(-90, 0), Vector2(0, -90)]:
		var spots: Array = [[Vector2(c.x + 7.4, c.y + 7.4), 0.0], [Vector2(c.x - 7.4, c.y - 7.4), 180.0], [Vector2(c.x - 7.4, c.y + 7.4), -90.0], [Vector2(c.x + 7.4, c.y - 7.4), 90.0]]
		for i in range(spots.size()):
			var sp: Vector2 = spots[i][0]
			if not _prop_clear(sp.x, sp.y):
				continue
			Detail.traffic_light(b, lit, Vector3(sp.x, 0.13, sp.y), float(spots[i][1]), 0 if i % 2 == 0 else 2)
			_solid(Vector3(sp.x, 0, sp.y), 0.25, 6.0)
			for o: Vector2 in [Vector2(2.0, 0), Vector2(0, 2.0)]:
				var bp := sp + o * (1.0 if sp.x < c.x else -1.0)
				Detail.bollard(b, Vector3(bp.x, 0.13, bp.y))
	# manholes along the roads
	for rd: Variant in ROADS:
		var x0 := float(rd[0]); var z0 := float(rd[1]); var x1 := float(rd[2]); var z1 := float(rd[3])
		var along_z := (z1 - z0) > (x1 - x0)
		var length := (z1 - z0) if along_z else (x1 - x0)
		for k in range(int(length / 46.0)):
			var t := -length * 0.5 + 23.0 + 46.0 * float(k)
			var off := 2.6 * (1.0 if k % 2 == 0 else -1.0)
			var at := Vector3((x0 + x1) * 0.5 + off, 0.045, (z0 + z1) * 0.5 + t) if along_z else Vector3((x0 + x1) * 0.5 + t, 0.045, (z0 + z1) * 0.5 + off)
			if at.x > RIVER[0] - 3.0 and at.x < RIVER[1] + 3.0:
				continue
			Detail.manhole(b, at)
	# poles and wires behind the houses (the southern rows)
	for zi in [3, 4]:
		var zline := float(ZS[zi][1]) - 1.0
		var prev: Array = []
		var x := -150.0
		while x < 205.0:
			if _prop_clear(x, zline) and not (x > -9.0 and x < 9.0) and not (x > -99.0 and x < -81.0) and not (x > 81.0 and x < 99.0):
				var tops := Detail.power_pole(b, Vector3(x, 0.13, zline), 0.0)
				_solid(Vector3(x, 0, zline), 0.25, 8.0)
				if not prev.is_empty() and x - float(prev[2]) < 40.0:
					Detail.wire(b, prev[0], tops[0], 0.8)
					Detail.wire(b, prev[1], tops[1], 0.8)
				prev = [tops[0], tops[1], x]
			x += 30.0
	# a bus stop on the main road, a bike rack by the school, planters downtown
	Detail.bus_stop(b, lit, Vector3(-9.6, 0.13, 60.0), -90.0)
	_solid_box(Vector3(-9.2, 1.3, 60.0), Vector3(1.4, 2.6, 3.6))
	Detail.bike_rack(b, Vector3(-60.0, 0.13, 33.6), 90.0)
	for k in range(6):
		var px := 12.0 + 12.0 * float(k)
		if _prop_clear(px, -8.8):
			Detail.planter(b, Vector3(px, 0.13, -8.8), 0.0, 2.4)
			_solid_box(Vector3(px, 0.4, -8.8), Vector3(2.4, 0.8, 0.9))
	Detail.commit(self, b, lit, paint)
