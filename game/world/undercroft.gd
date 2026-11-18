class_name Undercroft
extends Region
## The cellar under Ivo Marsh's shop: a cavern far too big to fit under a
## shop. Here the dead are trained, and here they find out what they are.
##
## Training, in three parts, kept in soul.flags["training"]:
##   0  The Drill: parry three blows, slip two, break three training frames.
##   1  The Cut: Marsh cuts what is left of the tether. In the pit, three
##      waves come while the hunger rises. Fail and you start the Cut again.
##   2  The Stillness: sit at the cairn, breathe, meet the one in your blade.
## The Awakening that follows fixes the strain, and a gate opens to the
## realm where that strain belongs.

const SIZE: float = 320.0
const CELLS: int = 80
const RIM: float = 132.0
const WAKE := Vector3(0, 0, 104)
const PIT := Vector3(0, 0, -30)
const PIT_R: float = 26.0
const YARD := Vector3(0, 0, 58)
const CAIRNS: Array = [Vector3(-26, 0, 92)]
const EROSION_TIME: float = 150.0
const WAVES: Array = [
	[["husk", 3], ["husk", 3], ["husk", 3], ["husk", 4]],
	[["hound", 4], ["hound", 4], ["hound", 4], ["husk", 4], ["husk", 4]],
	[["stalker", 4], ["stalker", 4], ["brute", 4]],
]
const HUBS: Dictionary = {"vigil": "citadel", "maw": "ashfall", "lumen": "reach", "relic": "stacks"}
const HUB_NAMES: Dictionary = {"citadel": "the Citadel", "ashfall": "the Wastes", "town": "Calder Town", "reach": "the Silver Reach", "stacks": "the Stacks"}

var noise: FastNoiseLite = FastNoiseLite.new()
var field: Heightfield
var wave: int = -1
var _wave_wait: float = -1.0


func _ready() -> void:
	region_id = "undercroft"
	place_name = "The Undercroft"
	bounds = RIM - 6.0
	level_base = 3
	noise.seed = 21
	noise.frequency = 0.02
	noise.fractal_octaves = 3
	field = Heightfield.new(SIZE, CELLS, _raw_height, _tint)
	_build_sky()
	field.build(self, "cave")
	_build_cave()
	_build_dressing()
	_build_points()
	Fx.root = self
	Sfx.loop("wind", "wind", -26.0)
	Sfx.loop("music", "music_inner", -16.0)


func stage() -> int:
	return int(soul.flags.get("training", 0))


func wake_point() -> Vector3:
	return WAKE


func cairn_points() -> Array:
	return CAIRNS


func portal_list() -> Array:
	var out: Array = [[0.0, 116.0, "town", "Climb the stairs to the shop", ""]]
	if soul.written():
		var hub := String(HUBS.get(soul.primary, "town"))
		out.append([22.0, 100.0, hub, "Go where you belong: %s" % String(HUB_NAMES[hub]), ""])
	return out


func talker_list() -> Array:
	var lines: Array = []
	var action := ""
	match stage():
		0:
			lines = [
				"Welcome to my cellar. Bigger than the shop, yes. Do not ask.",
				"First, the Drill. The frames in the yard swing slowly. Raise your guard the instant a blow lands: three parries. Dash through a blow as it lands: two slips. Then break all three.",
				"Go on. The yard is just south of here.",
			]
			if _drill_done():
				lines = ["Good. Your hands remember how to live.", "Now the hard part. I am going to cut your tether."]
				action = "cut"
		1:
			lines = ["The pit. Get in it. Survive what comes, and do not let the hunger fill you.", "Kill what comes in the pit. If the hunger fills before the last wave falls, we start again."]
		2:
			lines = ["You are still you. Good. Now sit at the cairn and breathe.", "The one in your blade will come. How you beat it decides what it gives you."]
		_:
			if soul.written():
				var hub := String(HUBS.get(soul.primary, "town"))
				lines = [
					"So. A %s. I thought so, the way you held the blade." % soul.form_name(),
					"You belong in %s now. The gate behind me goes there. There is a board in your realm: do its work, climb the grades, and come back strong." % String(HUB_NAMES[hub]),
				]
	return [[6.0, 96.0, 200.0, "Ivo Marsh", lines, {"cloth": Color(0.24, 0.3, 0.22), "trim": Color(0.9, 0.9, 0.85), "coat": 2, "hair": 4, "hair_color": Color(0.85, 0.82, 0.6), "hair_seed": 33, "face": 3, "sleeves": true, "sash": 2}, action]]


func stele_list() -> Array:
	return [[-12.0, 66.0, "THE DRILL. GUARD AS THE BLOW LANDS TO TURN IT. DASH AS IT LANDS TO SLIP IT. A BLOW THAT GLOWS RED CANNOT BE GUARDED: GET OUT OF THE WAY."]]


func objective() -> String:
	match stage():
		0:
			if _drill_done():
				return "The Drill is done. Speak with Ivo Marsh."
			return "The Drill: parries %d/3   slips %d/2   frames broken %d/3" % [mini(3, int(soul.flags.get("drill_parry", 0))), mini(2, int(soul.flags.get("drill_slip", 0))), mini(3, int(soul.flags.get("drill_kill", 0)))]
		1:
			if wave < 0:
				return "The Cut: get down into the pit."
			return "The Cut: wave %d of 3. Do not let the hunger fill." % (wave + 1)
		2:
			return "Sit at the cairn by the stairs and breathe."
	if soul.written():
		return "Speak with Ivo Marsh, then take the gate to your realm."
	return ""


func _drill_done() -> bool:
	return int(soul.flags.get("drill_parry", 0)) >= 3 and int(soul.flags.get("drill_slip", 0)) >= 2 and int(soul.flags.get("drill_kill", 0)) >= 3


# ----------------------------------------------------------------- terrain

func _raw_height(x: float, z: float) -> float:
	var h := noise.get_noise_2d(x, z) * 2.4
	var d := Vector2(x, z).length()
	if d > RIM - 10.0:
		h += minf(60.0, pow((d - RIM + 10.0) * 0.5, 1.6))
	h = Heightfield.flatten(h, x, z, PIT.x, PIT.z, PIT_R, -9.0, 1.45)
	h = Heightfield.flatten(h, x, z, YARD.x, YARD.z, 18.0, 0.3)
	h = Heightfield.flatten(h, x, z, WAKE.x, WAKE.z, 22.0, 0.5)
	return h


func height_at(x: float, z: float) -> float:
	return field.height_at(x, z) if field != null else 0.0


func _tint(mid: Vector3, n: Vector3) -> Color:
	var slope := clampf(1.0 - n.y, 0.0, 1.0)
	var grain := noise.get_noise_2d(mid.x * 4.0, mid.z * 4.0) * 0.05
	var v := 0.5 - slope * 0.22 + grain
	if mid.y < -4.0:
		v *= 0.75
	return Color(v * 1.08, v * 0.98, v * 0.86)


func _build_sky() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.045, 0.04)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.78, 0.65)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_hdr_threshold = 1.3
	env.fog_enabled = true
	env.fog_light_color = Color(0.25, 0.22, 0.18)
	env.fog_density = 0.006
	Detail.polish(env)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-62, 30, 0)
	key.light_color = Color(1.0, 0.9, 0.75)
	key.light_energy = 0.7
	key.shadow_enabled = false
	add_child(key)


func _build_cave() -> void:
	var r := Rng.make(["undercroft", "cave"])
	var rock := ForgeMesh.grain(Color(0.36, 0.32, 0.27), "slate", 0.12)
	var wood := ForgeMesh.mat(Color(0.4, 0.28, 0.16), 0.8)
	# the ceiling, high above, with blocks hanging down from it
	var ceil := ForgeMesh.Builder.new()
	ceil.box(Vector3(SIZE + 60.0, 6.0, SIZE + 60.0), Vector3(0, 74.0, 0))
	for i in range(70):
		var a := r.randf() * TAU
		var d := r.randf_range(0.0, RIM)
		var w := r.randf_range(4.0, 14.0)
		var h := r.randf_range(8.0, 32.0)
		ceil.box(Vector3(w, h, w * r.randf_range(0.6, 1.0)), Vector3(cos(a) * d, 71.0 - h * 0.5, sin(a) * d), Vector3(0, r.randf() * 90.0, 0))
	var cm := ForgeMesh.inst(ceil.commit(), rock, self)
	cm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# rock pillars and boulders on the floor
	var boulder: Array = [ForgeMesh.rock(r, 1.0), ForgeMesh.rock(r, 1.0)]
	var bx: Array = [[], []]
	for i in range(160):
		var a := r.randf() * TAU
		var d := r.randf_range(20.0, RIM - 12.0)
		var x := cos(a) * d
		var z := sin(a) * d
		if Vector2(x - PIT.x, z - PIT.z).length() < PIT_R + 10.0 or Vector2(x - YARD.x, z - YARD.z).length() < 22.0 or Vector2(x - WAKE.x, z - WAKE.z).length() < 24.0:
			continue
		var s := r.randf_range(0.6, 2.2) if r.randf() < 0.85 else r.randf_range(3.0, 6.0)
		(bx[i % 2] as Array).append(Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3.ONE * s), Vector3(x, height_at(x, z) - 0.2 * s, z)))
		if s > 2.8:
			_solid(Vector3(x, height_at(x, z), z), s * 0.8, s * 1.2)
	for k in range(2):
		ForgeMesh.scatter(self, boulder[k], rock, bx[k])
	for i in range(14):
		var a := TAU * float(i) / 14.0 + r.randf_range(-0.1, 0.1)
		var d := r.randf_range(60.0, 110.0)
		var x := cos(a) * d
		var z := sin(a) * d
		if Vector2(x - YARD.x, z - YARD.z).length() < 24.0 or Vector2(x - WAKE.x, z - WAKE.z).length() < 26.0:
			continue
		var w := r.randf_range(5.0, 10.0)
		var pb := ForgeMesh.Builder.new()
		pb.box(Vector3(w, 76.0, w * 0.8), Vector3(0, 38.0, 0), Vector3(0, r.randf() * 90.0, 0))
		pb.box(Vector3(w * 1.6, 6.0, w * 1.4), Vector3(0, 3.0, 0), Vector3(0, r.randf() * 90.0, 0))
		ForgeMesh.inst(pb.commit(), rock, self, Vector3(x, height_at(x, z) - 1.0, z))
		_solid(Vector3(x, height_at(x, z), z), w * 0.6, 70.0)
	# the stairs down from the shop
	var stairs := ForgeMesh.Builder.new()
	for k in range(12):
		stairs.box(Vector3(5.0, 0.4, 1.2), Vector3(0, 0.2 + 0.6 * float(k), 1.2 * float(k)))
	stairs.box(Vector3(0.3, 8.0, 15.0), Vector3(-2.6, 4.0, 6.5))
	stairs.box(Vector3(0.3, 8.0, 15.0), Vector3(2.6, 4.0, 6.5))
	ForgeMesh.inst(stairs.commit(), wood, self, Vector3(0, height_at(0, 120), 120))
	# the yard: a ring of posts and straw targets
	for i in range(10):
		var a := TAU * float(i) / 10.0
		var p := Vector3(YARD.x + cos(a) * 16.0, 0, YARD.z + sin(a) * 16.0)
		_block(self, Vector3(0.5, 2.4, 0.5), Vector3(p.x, height_at(p.x, p.z) + 1.2, p.z), wood)
	var rope := ForgeMesh.inst(ForgeMesh.ring(0.97, 40), ForgeMesh.mat(Color(0.75, 0.62, 0.36), 0.9), self, Vector3(YARD.x, height_at(YARD.x, YARD.z) + 2.0, YARD.z))
	rope.scale = Vector3(16.0, 1.0, 16.0)
	# lanterns on poles: the only light down here
	var lights := [WAKE + Vector3(-8, 0, -6), WAKE + Vector3(10, 0, -4), YARD + Vector3(18, 0, 0), YARD + Vector3(-18, 0, 0), PIT + Vector3(0, 0, PIT_R + 6.0), PIT + Vector3(PIT_R + 6.0, 0, 0), PIT + Vector3(-PIT_R - 6.0, 0, 0), PIT + Vector3(0, 0, -PIT_R - 6.0), Vector3(-26, 0, 86)]
	for lp: Variant in lights:
		var p: Vector3 = lp
		var y := height_at(p.x, p.z)
		_block(self, Vector3(0.3, 4.4, 0.3), Vector3(p.x, y + 2.2, p.z), wood)
		_block(self, Vector3(0.6, 0.7, 0.6), Vector3(p.x, y + 4.6, p.z), ForgeMesh.glow(Color(1.0, 0.75, 0.4), 2.0))
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.75, 0.45)
		l.light_energy = 2.6
		l.omni_range = 22.0
		l.position = Vector3(p.x, y + 4.4, p.z)
		add_child(l)
	var pit_glow := OmniLight3D.new()
	pit_glow.light_color = Color(0.95, 0.3, 0.3)
	pit_glow.light_energy = 1.2
	pit_glow.omni_range = 34.0
	pit_glow.position = PIT + Vector3(0, 4.0 - 9.0, 0)
	add_child(pit_glow)


# --------------------------------------------------------------- training

## Fallen stone along the cavern floor, and timber props against the walls.
func _build_dressing() -> void:
	var r := Rng.make(["undercroft", "dressing"])
	var b := ForgeMesh.Builder.new()
	for i in range(50):
		var a := r.randf() * TAU
		var rad := r.randf_range(PIT_R + 10.0, RIM - 12.0)
		var x := cos(a) * rad
		var z := sin(a) * rad
		if not dress_clear(x, z, 2.0) or Vector2(x - YARD.x, z - YARD.z).length() < 26.0:
			continue
		var s := r.randf_range(0.8, 2.4)
		Detail.rock_pile(b, Vector3(x, height_at(x, z) - 0.2, z), r.randf() * 360.0, s, Color(0.45, 0.4, 0.34).darkened(r.randf() * 0.2), r)
		_solid(Vector3(x, height_at(x, z), z), s * 0.55, s)
	for i in range(14):
		var a := TAU * float(i) / 14.0 + r.randf_range(-0.1, 0.1)
		var x := cos(a) * (RIM - 8.0)
		var z := sin(a) * (RIM - 8.0)
		var y := height_at(x, z)
		var keep := b.xf
		b.xf = Transform3D(Basis(Vector3.UP, -a + PI * 0.5), Vector3(x, y, z))
		b.col = Color(0.36, 0.25, 0.16)
		b.box(Vector3(0.6, 9.0, 0.6), Vector3(-2.0, 4.5, 0))
		b.box(Vector3(0.6, 9.0, 0.6), Vector3(2.0, 4.5, 0))
		b.box(Vector3(5.4, 0.7, 0.8), Vector3(0, 9.0, 0))
		b.col = Color(0.28, 0.2, 0.13)
		b.box(Vector3(0.4, 2.2, 0.4), Vector3(-1.4, 8.0, 0), Vector3(0, 0, -45))
		b.box(Vector3(0.4, 2.2, 0.4), Vector3(1.4, 8.0, 0), Vector3(0, 0, 45))
		b.xf = keep
	var m := ForgeMesh.grain(Color(1, 1, 1), "slate", 0.2)
	m.vertex_color_use_as_albedo = true
	Detail.commit(self, b, null, m)


func _spawn_extra() -> void:
	wave = -1
	_wave_wait = -1.0
	if stage() == 0:
		for i in range(3):
			var a := TAU * float(i) / 3.0
			var e := _spawn("drill", YARD + Vector3(cos(a) * 6.0, 0, sin(a) * 6.0), 1)
			e.aggro_range = 9.0
			e.leash = 20.0


func _on_noted(event: String) -> void:
	super._on_noted(event)
	if stage() != 0:
		return
	if event == "parry":
		soul.flags["drill_parry"] = int(soul.flags.get("drill_parry", 0)) + 1
	elif event == "dodge":
		soul.flags["drill_slip"] = int(soul.flags.get("drill_slip", 0)) + 1
	if _drill_done() and not bool(soul.flags.get("drill_said", false)):
		soul.flags["drill_said"] = true
		say("The Drill is done. Speak with Ivo Marsh.", "gain")


func _special_death(e: Enemy) -> void:
	if e.kind == "drill":
		soul.flags["drill_kill"] = int(soul.flags.get("drill_kill", 0)) + 1
		if _drill_done() and not bool(soul.flags.get("drill_said", false)):
			soul.flags["drill_said"] = true
			say("The Drill is done. Speak with Ivo Marsh.", "gain")
		elif stage() == 0 and _drill_frames_left() == 0 and not _drill_done():
			# frames come back until the Drill is learnt
			for i in range(3):
				var a := TAU * float(i) / 3.0
				_spawn("drill", YARD + Vector3(cos(a) * 6.0, 0, sin(a) * 6.0), 1)


func _drill_frames_left() -> int:
	var n := 0
	for a in enemies_alive():
		if (a as Enemy).kind == "drill":
			n += 1
	return n


func _talk_action(action: String, _i: int) -> void:
	if action == "cut" and stage() == 0 and _drill_done():
		begin_cut()


## Marsh cuts the tether. What is left of it counts toward the Reaper.
func begin_cut() -> void:
	var links := tether_links()
	if links > 0:
		Strains.gain(soul.affinity, "parry", float(links) * 1.4)
		say("He cuts %d link%s of your tether. You keep what they were." % [links, "" if links == 1 else "s"], "whisper")
	else:
		say("He cuts at your chest and finds nothing left to cut.", "whisper")
	soul.flags["tether"] = 0
	soul.flags["training"] = 1
	soul.flags["erosion"] = 0.0
	for a in enemies_alive():
		actors.erase(a)
		a.queue_free()
	Sfx.play("break", 0.0, 0.7)
	Fx.screen_flash(Color(1, 0.2, 0.2), 0.5)
	Fx.add_shake(0.8)
	player.rebuild_body()
	say("THE CUT", "boss")


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if player == null or stage() != 1 or not player.alive:
		return
	# the hunger rises from the moment the tether is cut
	soul.flags["erosion"] = float(soul.flags.get("erosion", 0.0)) + delta * 100.0 / EROSION_TIME
	if float(soul.flags["erosion"]) >= 100.0:
		soul.flags["erosion"] = 100.0
		say("The hunger fills you. Everything goes red.", "death")
		player.hp = 0.0
		player.die(null)
		return
	var in_pit := Vector2(player.global_position.x - PIT.x, player.global_position.z - PIT.z).length() < PIT_R
	if wave < 0:
		if in_pit:
			_start_wave(0)
		return
	if _wave_wait >= 0.0:
		_wave_wait -= delta
		if _wave_wait < 0.0:
			_start_wave(wave + 1)
		return
	if _wave_left() == 0:
		if wave >= WAVES.size() - 1:
			_finish_cut()
		else:
			_wave_wait = 4.0
			say("Breathe. Another is coming.", "hint")


func _wave_left() -> int:
	var n := 0
	for a in enemies_alive():
		if bool(a.get_meta("wave", false)):
			n += 1
	return n


func _start_wave(i: int) -> void:
	wave = i
	_wave_wait = -1.0
	var list: Array = WAVES[i]
	for k in range(list.size()):
		var d: Array = list[k]
		var a := TAU * float(k) / float(list.size()) + 0.4
		var e := _spawn(String(d[0]), PIT + Vector3(cos(a) * 15.0, 0, sin(a) * 15.0), int(d[1]))
		e.set_meta("wave", true)
		e.leash = 999.0
		e.wake(player)
	say("WAVE %d" % (i + 1), "boss")
	Sfx.play("growl", 0.0, 0.8)


func _finish_cut() -> void:
	soul.flags["training"] = 2
	soul.flags["erosion"] = 0.0
	wave = -1
	say("The hunger falls back. You are still yourself.", "whisper")
	say("Sit at the cairn by the stairs and breathe.", "gain")
	Sfx.play("rest", 0.0)
	main.save()


func _on_respawn() -> void:
	if stage() == 1:
		soul.flags["erosion"] = 0.0
		say("Again. The Cut starts over when you step into the pit.", "whisper")


func _awakening_ready() -> bool:
	return stage() == 2 and not soul.written()
