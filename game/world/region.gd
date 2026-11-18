class_name Region
extends Place
## A place a soul can live in. Each region supplies its own ground and lists
## (spawns, great enemies, boards, cairns, keepsakes, steles, people, ways
## out); this class supplies everything a soul does there: fighting, quests,
## promotions, the tether, sitting and breathing, devouring or sending on.

var region_id: String = "region"
var checkpoint: Vector3 = Vector3.ZERO
var boss: Enemy
var boss_record: Profile
var bosses: Dictionary = {}
var meditation: Meditation
var attract: bool = false
var level_base: int = 1

var _relics: Array = []
var _steles: Array = []
var _cairns: Array = []
var _talkers: Array = []
var _givers: Array = []
var _giver_marks: Array = []
## Lost souls waiting to be found: id -> {rig, following, quest}
var _lost: Dictionary = {}
var _npc_t: float = 0.0
## World events: rifts, marches, storms.
var events: EventDirector = null
## Day and night, where there is a sky to turn.
var daynight: DayNight = null
## Rain, fog, thunderstorms and snow, under an open sky only.
var weather: Weather = null
## Folk, crates, chests, orbs, challenge stones, the dummy, streaks, badges.
var play: WorldPlay = null
var _portals: Array = []
var _boards: Array = []
var _enemy_seed: int = 100
var _respawn_pending: bool = false
var _trial_pending: bool = false
var _stand_t: float = 0.0
var _talk_cd: float = 0.0
var _boss_records: Dictionary = {}
var _rematch: Dictionary = {}
var _loot: Array = []
var _market_t: float = 0.0


# ------------------------------------------------- what each region supplies

func wake_point() -> Vector3:
	return Vector3.ZERO


func cairn_points() -> Array:
	return []


## [kind, x, z] or [kind, x, z, level]
func spawn_list() -> Array:
	return []


## [kind, x, z, level, wake radius, facing degrees]
func boss_list() -> Array:
	return []


## [x, z, board id, facing degrees]
func board_list() -> Array:
	return []


## [x, z, text]
## Night has come by k (0 to 1). Places with people in them react.
## How far enemies see the player, as a share of their range (fog cuts it).
## A swing of the player's also breaks crates and lands on the dummy.
func on_player_sweep(attacker: Actor, m: Dictionary) -> void:
	if play != null:
		play.on_player_sweep(attacker, m)


func sight_scale() -> float:
	return weather.sight() if weather != null else 1.0


func on_night(_k: float) -> void:
	pass


## People who ask for help: [x, z, yaw, board id, name, what they do,
## look, idle lines]. Their notices live in Quests under that board id.
func giver_list() -> Array:
	return []


func relic_list() -> Array:
	return []


## [x, z, text]
func stele_list() -> Array:
	return []


## [x, z, yaw degrees, name, [lines], body spec, action (optional)]
func talker_list() -> Array:
	return []


## [x, z, target region id, label, rule]. Rules: "" open, "named" needs a
## named blade, "reaper" needs the Reaper strain or Grade 3, "prologue" needs
## the prologue done, "hidden" not shown.
func portal_list() -> Array:
	return []


func music_name() -> String:
	return "music_pale"


func objective() -> String:
	return ""


func _spawn_extra() -> void:
	pass


func _special_death(_e: Enemy) -> void:
	pass


func _talk_action(_action: String, _i: int) -> void:
	pass


func _awakening_ready() -> bool:
	return false


func _on_respawn() -> void:
	pass


# ------------------------------------------------------------------ helpers

func _place_on_ground(n: Node3D, x: float, z: float, sink: float = 0.0) -> void:
	n.position = Vector3(x, height_at(x, z) - sink, z)


func _solid(pos: Vector3, radius: float, height: float) -> void:
	var body := StaticBody3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	var col := CollisionShape3D.new()
	col.shape = shape
	body.add_child(col)
	body.collision_layer = 1
	body.position = pos + Vector3(0, height * 0.5, 0)
	add_child(body)


func _solid_box(center: Vector3, size: Vector3, yaw: float = 0.0) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	var col := CollisionShape3D.new()
	col.shape = shape
	body.add_child(col)
	body.collision_layer = 1
	body.position = center
	body.rotation.y = yaw
	add_child(body)
	return body


func _block(parent: Node3D, size: Vector3, pos: Vector3, material: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := ForgeMesh.inst(ForgeMesh.box(size), material, parent, pos)
	mi.rotation_degrees = rot
	return mi


func flag(kind: String, i: int) -> String:
	return "%s_%s_%d" % [kind, region_id, i]


func portal_open(rule: String) -> bool:
	match rule:
		"named":
			return soul.written()
		"reaper":
			return soul.primary == "vigil" or soul.secondary == "vigil" or (soul.written() and soul.grade <= 3)
		"prologue":
			return Quests.prologue_done(soul)
		"archer":
			return soul.primary == "lumen" or soul.secondary == "lumen" or (soul.written() and soul.grade <= 3)
		"binder":
			return soul.primary == "relic" or soul.secondary == "relic" or (soul.written() and soul.grade <= 3)
		"deep":
			return soul.written() and soul.grade <= 2
		"hidden":
			return false
	return true


func portal_refusal(rule: String) -> String:
	match rule:
		"named":
			return "It will not take a soul with no name. Awaken first."
		"reaper":
			return "The gate does not know you. It opens for Reapers, and for anyone of Grade 3."
		"prologue":
			return "Not yet. Finish what the Lingering Board asks."
		"archer":
			return "The Lantern Door opens for Archers, and for anyone of Grade 3."
		"binder":
			return "The stair is chained shut. It opens for Binders, and for anyone of Grade 3."
		"deep":
			return "The seal does not move. It breaks only for a soul of Grade 2."
	return "It will not open."


# ------------------------------------------------------------------- points

func _build_points() -> void:
	var stone := ForgeMesh.grain(Color(0.52, 0.52, 0.56), "slate")
	var r := Rng.make([region_id, "points"])
	for c: Variant in cairn_points():
		var cp: Vector3 = c
		var node := Node3D.new()
		add_child(node)
		_place_on_ground(node, cp.x, cp.z)
		var yy := 0.0
		for k in range(5):
			var w := 1.2 - 0.2 * float(k)
			var th := 0.3 - 0.02 * float(k)
			_block(node, Vector3(w, th, w * r.randf_range(0.8, 1.0)), Vector3(r.randf_range(-0.06, 0.06), yy + th * 0.5, r.randf_range(-0.06, 0.06)), stone, Vector3(r.randf_range(-4, 4), r.randf_range(0, 90), r.randf_range(-4, 4)))
			yy += th
		var flame := _block(node, Vector3(0.3, 0.3, 0.3), Vector3(0, yy + 0.55, 0), ForgeMesh.glow(Color(0.55, 0.8, 1.0), 1.1), Vector3(45, 0, 35))
		flame.name = "flame"
		flame.set_meta("no_ghost", true)
		var l := OmniLight3D.new()
		l.light_color = Color(0.8, 0.92, 1.0)
		l.light_energy = 1.8
		l.omni_range = 11.0
		l.position = Vector3(0, yy + 1.0, 0)
		node.add_child(l)
		_solid(node.position, 0.8, 1.6)
		_cairns.append(node)
	var relics := relic_list()
	for i in range(relics.size()):
		var d: Array = relics[i]
		if soul != null and bool(soul.flags.get(flag("relic", i), false)):
			_relics.append(null)
			continue
		var node := Node3D.new()
		add_child(node)
		_place_on_ground(node, float(d[0]), float(d[1]), -1.25)
		var violet := Color(0.78, 0.55, 1.0)
		_block(node, Vector3(0.42, 0.42, 0.42), Vector3.ZERO, ForgeMesh.glow(violet, 1.4), Vector3(45, 0, 35))
		var halo := ForgeMesh.inst(ForgeMesh.ring(0.82, 24), ForgeMesh.ghost(Color(violet.r, violet.g, violet.b, 0.6)), node)
		halo.scale = Vector3(0.75, 1, 0.75)
		var l := OmniLight3D.new()
		l.light_color = violet
		l.light_energy = 1.4
		l.omni_range = 7.0
		node.add_child(l)
		_relics.append(node)
	var steles := stele_list()
	for i in range(steles.size()):
		var d: Array = steles[i]
		var node := Node3D.new()
		add_child(node)
		_place_on_ground(node, float(d[0]), float(d[1]), 0.2)
		node.rotation.y = r.randf_range(-0.4, 0.4)
		_block(node, Vector3(2.0, 0.4, 0.9), Vector3(0, 0.2, 0), stone)
		_block(node, Vector3(1.6, 3.0, 0.5), Vector3(0, 1.9, 0), ForgeMesh.grain(Color(0.2, 0.2, 0.24), "slate"))
		for k in range(5):
			_block(node, Vector3(1.0 - 0.12 * float(k % 3), 0.06, 0.03), Vector3(0, 3.0 - 0.38 * float(k), 0.26), ForgeMesh.glow(Color(0.85, 0.9, 1.0), 2.0))
		_solid(node.position, 0.9, 3.0)
		_steles.append(node)
	for b: Variant in board_list():
		var d: Array = b
		_boards.append(_build_board(float(d[0]), float(d[1]), String(d[2]), float(d[3]) if d.size() > 3 else 0.0))
	var talkers := talker_list()
	for i in range(talkers.size()):
		var d: Array = talkers[i]
		var rig := BlockRig.new()
		add_child(rig)
		rig.build(d[5])
		_place_on_ground(rig, float(d[0]), float(d[1]))
		rig.rotation.y = deg_to_rad(float(d[2]))
		rig.play("idle", 0.0)
		if (d[5] as Dictionary).has("blade"):
			rig.hold(Gear.sealed_blade(int(d[5]["blade"])))
		for m in rig.mats:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_color.a = 0.88
		_solid(rig.position, 0.4, 1.7)
		_talkers.append(rig)
		_name_plate(rig, String(d[3]), "")
	var givers := giver_list()
	for i in range(givers.size()):
		var g: Array = givers[i]
		var grig := BlockRig.new()
		add_child(grig)
		grig.build(g[6])
		_place_on_ground(grig, float(g[0]), float(g[1]))
		grig.rotation.y = deg_to_rad(float(g[2]))
		grig.play("idle", 0.0)
		if (g[6] as Dictionary).has("blade"):
			grig.hold(Gear.sealed_blade(int(g[6]["blade"])))
		for m in grig.mats:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_color.a = 0.88
		_solid(grig.position, 0.4, 1.7)
		_givers.append(grig)
		_name_plate(grig, String(g[4]), String(g[5]))
		var mark := Label3D.new()
		mark.font = Ink.body_font()
		mark.font_size = 190
		mark.pixel_size = 0.004
		mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		mark.outline_size = 18
		mark.outline_modulate = Color(0.05, 0.04, 0.03)
		mark.modulate = Ink.BRASS
		mark.position = Vector3(0, grig.height + 1.15, 0)
		mark.visibility_range_end = 70.0
		grig.add_child(mark)
		_giver_marks.append(mark)
	var portals := portal_list()
	for i in range(portals.size()):
		var d: Array = portals[i]
		if String(d[4]) == "hidden":
			_portals.append(null)
			continue
		_portals.append(_build_portal(float(d[0]), float(d[1]), String(d[2])))


## Is a spot clear of everything you must reach or fight on? For dressing.
func dress_clear(x: float, z: float, margin: float = 3.0) -> bool:
	var at := Vector2(x, z)
	var w: Vector3 = wake_point()
	if at.distance_to(Vector2(w.x, w.z)) < 14.0 + margin:
		return false
	for c: Variant in cairn_points():
		if at.distance_to(Vector2((c as Vector3).x, (c as Vector3).z)) < 5.0 + margin:
			return false
	for lst: Array in [board_list(), portal_list(), relic_list(), stele_list()]:
		for e: Variant in lst:
			if at.distance_to(Vector2(float(e[0]), float(e[1]))) < 5.0 + margin:
				return false
	for bl: Variant in boss_list():
		if at.distance_to(Vector2(float(bl[1]), float(bl[2]))) < float(bl[4]) * 0.8 + margin:
			return false
	if absf(x) > bounds - 8.0 or absf(z) > bounds - 8.0:
		return false
	return true


func _build_board(x: float, z: float, board_id: String, yaw_deg: float) -> Node3D:
	var node := Node3D.new()
	add_child(node)
	_place_on_ground(node, x, z)
	node.rotation.y = deg_to_rad(yaw_deg)
	if board_id == "forge":
		_build_forge(node)
		return node
	var wood := ForgeMesh.mat(Color(0.32, 0.22, 0.14), 0.8)
	var paper := ForgeMesh.mat(Color(0.92, 0.9, 0.82), 0.9)
	var strain := String((Quests.BOARDS[board_id] as Dictionary)["strain"])
	var accent := Color(1.0, 0.82, 0.4) if strain == "*" else Strains.color_of(strain)
	if board_id == "hunt":
		wood = ForgeMesh.grain(Color(0.86, 0.85, 0.8), "slate")
		paper = ForgeMesh.mat(Color(0.25, 0.05, 0.06), 0.9)
	_block(node, Vector3(0.2, 2.6, 0.2), Vector3(-1.3, 1.3, 0), wood)
	_block(node, Vector3(0.2, 2.6, 0.2), Vector3(1.3, 1.3, 0), wood)
	_block(node, Vector3(3.0, 1.7, 0.14), Vector3(0, 1.95, 0), wood)
	_block(node, Vector3(3.3, 0.2, 0.5), Vector3(0, 2.9, 0), wood)
	var r := Rng.make([region_id, board_id])
	for k in range(6):
		_block(node, Vector3(0.55, 0.65, 0.02), Vector3(-1.05 + 0.42 * float(k), 1.95 + r.randf_range(-0.25, 0.25), -0.09), paper, Vector3(0, 0, r.randf_range(-8, 8)))
	_block(node, Vector3(2.9, 0.08, 0.04), Vector3(0, 2.78, -0.26), ForgeMesh.glow(accent, 1.6))
	_solid(node.position, 1.4, 2.8)
	return node


## The forge: a block furnace with a glowing mouth, an anvil on a stump,
## a quench trough and a rack of hung blanks.
func _build_forge(node: Node3D) -> void:
	var stone := ForgeMesh.grain(Color(0.36, 0.34, 0.33), "slate")
	var iron := ForgeMesh.mat(Color(0.16, 0.16, 0.18), 0.4, 0.8)
	var wood := ForgeMesh.mat(Color(0.32, 0.22, 0.14), 0.8)
	var fire := ForgeMesh.glow(Color(1.0, 0.45, 0.1), 3.0)
	# furnace
	_block(node, Vector3(2.2, 2.0, 1.6), Vector3(-1.6, 1.0, 0.6), stone)
	_block(node, Vector3(1.6, 0.5, 1.2), Vector3(-1.6, 2.25, 0.6), stone)
	_block(node, Vector3(0.6, 1.6, 0.6), Vector3(-1.6, 3.3, 0.8), stone)
	_block(node, Vector3(1.1, 0.7, 0.05), Vector3(-1.6, 0.8, -0.21), fire)
	_block(node, Vector3(1.3, 0.12, 0.3), Vector3(-1.6, 1.22, -0.25), iron)
	# anvil on a stump
	_block(node, Vector3(0.7, 0.6, 0.7), Vector3(0.8, 0.3, 0), wood)
	_block(node, Vector3(0.4, 0.3, 0.3), Vector3(0.8, 0.75, 0), iron)
	_block(node, Vector3(0.95, 0.24, 0.42), Vector3(0.8, 1.0, 0), iron)
	_block(node, Vector3(0.3, 0.14, 0.24), Vector3(1.4, 1.02, 0), iron, Vector3(0, 0, -12))
	_block(node, Vector3(0.5, 0.05, 0.08), Vector3(0.7, 1.15, -0.05), fire)
	# quench trough
	_block(node, Vector3(1.2, 0.5, 0.6), Vector3(2.2, 0.25, 0.4), wood)
	_block(node, Vector3(1.05, 0.04, 0.45), Vector3(2.2, 0.48, 0.4), ForgeMesh.mat(Color(0.12, 0.2, 0.26), 0.1, 0.2))
	# a rack of blanks
	_block(node, Vector3(2.4, 0.12, 0.12), Vector3(0.6, 2.4, 1.2), wood)
	for k in range(5):
		_block(node, Vector3(0.08, 1.0, 0.03), Vector3(-0.3 + 0.42 * float(k), 1.85, 1.2), ForgeMesh.mat(Color(0.7, 0.72, 0.76), 0.3, 0.8), Vector3(0, 0, 4.0 * float(k - 2)))
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.55, 0.2)
	l.light_energy = 2.4
	l.omni_range = 9.0
	l.position = Vector3(-1.4, 1.2, -1.2)
	node.add_child(l)
	_solid(node.position + node.basis * Vector3(-1.6, 0, 0.6), 1.3, 3.0)
	_solid(node.position + node.basis * Vector3(0.8, 0, 0), 0.5, 1.2)


func _build_portal(x: float, z: float, target: String) -> Node3D:
	var node := Node3D.new()
	add_child(node)
	_place_on_ground(node, x, z)
	var c := Color(1.0, 0.15, 0.25)
	if target == "citadel":
		c = Color(0.6, 0.85, 1.0)
	elif target == "undercroft":
		c = Color(1.0, 0.8, 0.4)
	elif target == "town":
		c = Color(0.5, 1.0, 0.6)
	elif target == "reach":
		c = Color(0.55, 0.85, 1.0)
	elif target == "undermark":
		c = Color(1.0, 0.4, 0.05)
	var black := ForgeMesh.mat(Color(0, 0, 0), 1.0)
	var edge := ForgeMesh.glow(c, 2.2)
	_block(node, Vector3(2.4, 5.4, 0.12), Vector3(0, 2.9, 0), black, Vector3(0, 0, 4))
	_block(node, Vector3(0.14, 5.8, 0.16), Vector3(-1.25, 2.9, 0), edge, Vector3(0, 0, 7))
	_block(node, Vector3(0.14, 5.8, 0.16), Vector3(1.3, 2.9, 0), edge, Vector3(0, 0, 1))
	_block(node, Vector3(1.0, 0.14, 0.16), Vector3(-0.3, 5.7, 0), edge, Vector3(0, 0, 24))
	_block(node, Vector3(1.2, 0.14, 0.16), Vector3(0.6, 5.6, 0), edge, Vector3(0, 0, -20))
	var ring := ForgeMesh.inst(ForgeMesh.ring(0.9, 32), ForgeMesh.glow(c, 1.6), node, Vector3(0, 0.05, 0))
	ring.scale = Vector3(3.0, 1, 3.0)
	ring.name = "ring"
	var l := OmniLight3D.new()
	l.light_color = c
	l.light_energy = 1.6
	l.omni_range = 10.0
	l.position = Vector3(0, 2.5, 1.0)
	node.add_child(l)
	return node


# ------------------------------------------------------------------ actors

func populate() -> void:
	checkpoint = start_point()
	_spawn_all()


func _spawn_all() -> void:
	for sp: Variant in spawn_list():
		var d: Array = sp
		_spawn(String(d[0]), Vector3(float(d[1]), 0, float(d[2])), int(d[3]) if d.size() > 3 else level_base)
	_spawn_bosses()
	_spawn_extra()


func _spawn_bosses() -> void:
	bosses.clear()
	for b: Variant in boss_list():
		var d: Array = b
		var kind := String(d[0])
		if bool(soul.flags.get("beat_" + kind, false)):
			_build_rematch(kind, Vector3(float(d[1]), 0, float(d[2])))
			continue
		var e := Enemy.new()
		var blv := int(d[3])
		if soul != null and Quests.trial_boss(soul) == kind:
			blv = trial_level(kind, soul)
		e.setup(kind, blv, hash(kind))
		add_actor(e, Vector3(float(d[1]), 0, float(d[2])))
		e.home = e.global_position
		e.rotation.y = deg_to_rad(float(d[5]) if d.size() > 5 else 180.0)
		e.dormant = true
		e.leash = 999.0
		e.set_meta("wake", float(d[4]))
		bosses[kind] = e
	# the first great enemy stays reachable as `boss` for older callers
	boss = null
	for k: Variant in bosses.keys():
		boss = bosses[k]
		break


## A beaten great enemy leaves its mask where it fell. Touch it to call the
## enemy back, stronger each time, for less essence than the first time.
func _build_rematch(kind: String, at: Vector3) -> void:
	if _rematch.has(kind) and is_instance_valid(_rematch[kind]):
		return
	var node := Node3D.new()
	add_child(node)
	_place_on_ground(node, at.x, at.z)
	var accent: Color = (Bestiary.get_def(kind)["body"] as Dictionary).get("accent", Color(1, 0.2, 0.2))
	_block(node, Vector3(1.6, 0.5, 1.6), Vector3(0, 0.25, 0), ForgeMesh.grain(Color(0.3, 0.3, 0.33), "slate"))
	var mask := Gear.mask(int((Bestiary.get_def(kind)["body"] as Dictionary).get("mask", 0)), Rng.make([kind, "rematch"]), accent)
	_block(node, Vector3(0.24, 1.4, 0.24), Vector3(0, 1.2, 0.1), ForgeMesh.mat(Color(0.25, 0.2, 0.16), 0.8))
	mask.position = Vector3(0, 1.75, -0.05)
	mask.rotation_degrees = Vector3(-8, 0, 0)
	mask.scale = Vector3.ONE * 2.6
	node.add_child(mask)
	var ring := ForgeMesh.inst(ForgeMesh.ring(0.9, 28), ForgeMesh.glow(accent, 1.4), node, Vector3(0, 0.06, 0))
	ring.scale = Vector3(2.4, 1, 2.4)
	node.set_meta("kind", kind)
	_rematch[kind] = node


func rematch_level(kind: String) -> int:
	for b: Variant in boss_list():
		var d: Array = b
		if String(d[0]) == kind:
			return int(d[3]) + 3 * (int(soul.flags.get("rematches_" + kind, 0)) + 1)
	return level_base


func _nearest_rematch() -> String:
	var best := ""
	var best_d := 4.0
	for k: Variant in _rematch.keys():
		var n: Variant = _rematch[k]
		if n == null or not is_instance_valid(n):
			continue
		var d := (n as Node3D).global_position.distance_to(player.global_position)
		if d < best_d:
			best_d = d
			best = String(k)
	return best


func call_back(kind: String) -> Enemy:
	var node: Node3D = _rematch.get(kind)
	if node == null:
		return null
	var at := node.global_position
	node.queue_free()
	_rematch.erase(kind)
	var e := Enemy.new()
	e.setup(kind, rematch_level(kind), hash(kind))
	e.essence *= 0.6
	add_actor(e, at + Vector3(0, 0, -4.0))
	e.home = e.global_position
	e.leash = 999.0
	e.set_meta("rematch", true)
	e.face_now(e.flat_to(player.global_position))
	bosses[kind] = e
	Fx.pillar(e.global_position, e.accent, 30.0, 2.0, 1.2)
	wake_boss(e)
	return e


## Where a soul stands when it arrives with nothing else to go on: its last
## cairn if that cairn is here, else where it first woke.
func start_point() -> Vector3:
	var cairns := cairn_points()
	var i := int(soul.flags.get("checkpoint", -1))
	if String(soul.flags.get("checkpoint_region", "")) == region_id and i >= 0 and i < cairns.size():
		var c: Vector3 = cairns[i]
		return c + Vector3(0, 0, 2.6)
	return wake_point()


## Where a soul steps out when it comes through from another region.
func arrival_point(from_id: String) -> Vector3:
	for p: Variant in portal_list():
		var d: Array = p
		if String(d[2]) == from_id:
			return Vector3(float(d[0]), 0, float(d[1]) + 3.0)
	return wake_point()


## How often an ordinary enemy here is born an elite.
## The level an ordinary enemy stands at: its listed level, but never more
## than three below an awakened soul, so the realms keep pace with the climb
## (the training cavern keeps its own).
static func scaled_level(listed: int, rid: String, s: Soul) -> int:
	if s == null or not s.written() or rid == "undercroft":
		return listed
	return maxi(listed, s.level - 3)


## The level a great enemy stands at: when it is the soul's own trial, at
## the soul's level cap, so a trial is always a trial.
static func trial_level(boss: String, s: Soul) -> int:
	var listed := int(TRIAL_LEVELS.get(boss, 10))
	if s != null and s.written() and Quests.trial_boss(s) == boss:
		return maxi(listed, mini(Quests.level_cap(s), 60))
	return listed


const TRIAL_LEVELS: Dictionary = {"gutter_king": 3, "drowned_hound": 6, "thane": 10, "vael": 20, "many_mouthed": 14, "odrel": 16, "sereth": 24, "ysolde": 13}


func elite_chance() -> float:
	return 0.0 if level_base < 6 else 0.12


func _spawn(kind: String, pos: Vector3, enemy_level: int = -1) -> Enemy:
	var e := Enemy.new()
	_enemy_seed += 1
	var affix := ""
	var roll := Rng.make([soul.seed if soul != null else 0, region_id, _enemy_seed, "elite"])
	var storm_bonus := 0.3 if events != null and events.storming() else 0.0
	if daynight != null and daynight.night() > 0.6:
		storm_bonus += 0.1
	if not Bestiary.is_boss(kind) and kind != "drill" and roll.randf() < elite_chance() + storm_bonus:
		var keys: Array = Bestiary.AFFIXES.keys()
		keys.sort()
		affix = String(keys[roll.randi() % keys.size()])
	var lvl := enemy_level if enemy_level > 0 else level_base
	if not Bestiary.is_boss(kind):
		lvl = scaled_level(lvl, region_id, soul)
	e.setup(kind, lvl, _enemy_seed, {}, affix)
	add_actor(e, pos)
	e.home = e.global_position
	e.rotation.y = Rng.unit([_enemy_seed, "yaw"]) * TAU
	return e


func reset_enemies() -> void:
	for a in actors.duplicate():
		if a != player and is_instance_valid(a):
			actors.erase(a)
			a.queue_free()
	for c in get_children():
		if c is Bolt or c is Wave:
			c.queue_free()
	records.clear()
	boss_record = null
	_boss_records.clear()
	_spawn_all()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if player == null:
		return
	_tick_npcs(delta)
	if events == null and soul != null:
		events = EventDirector.new()
		add_child(events)
		events.setup(self)
	if events != null:
		events.tick(delta)
	if daynight == null and soul != null:
		daynight = DayNight.new()
		add_child(daynight)
		daynight.setup(self)
	if daynight != null:
		daynight.tick(delta)
	if weather == null and soul != null and daynight != null and daynight.has_sky():
		weather = Weather.new()
		add_child(weather)
		weather.setup(self)
	if weather != null:
		weather.tick(delta)
	if play == null and soul != null and WorldPlay.wants(region_id):
		play = WorldPlay.new()
		add_child(play)
		play.setup(self)
	if play != null:
		play.tick(delta)
	for c: Variant in _cairns:
		var flame: Node3D = (c as Node3D).get_node("flame")
		flame.rotation.y += delta * 1.2
	for rl: Variant in _relics:
		if rl != null and is_instance_valid(rl):
			(rl as Node3D).rotation.y += delta * 0.9
	for p: Variant in _portals:
		if p != null:
			var ring: Node3D = (p as Node3D).get_node("ring")
			ring.rotation.y += delta * 0.7
	_talk_cd = maxf(0.0, _talk_cd - delta)
	_tick_loot(delta)
	_market_t += delta
	if _market_t >= 1.0:
		var earned := Market.tick(soul, _market_t)
		_market_t = 0.0
		if earned > 0:
			var lg: Array = Market.state(soul)["log"]
			say("The Exchange: %s" % String(lg[lg.size() - 1]), "gain")
	_tick_bosses()
	_tick_tether(delta)
	if meditation != null:
		_tick_meditation(delta)


# ------------------------------------------------------------- great enemies

func _tick_bosses() -> void:
	if not player.alive:
		return
	for k: Variant in bosses.keys():
		var ev: Variant = bosses[k]
		if not is_instance_valid(ev):
			continue
		var e: Enemy = ev
		if not e.alive or not e.dormant:
			continue
		var wake := float(e.get_meta("wake", 20.0))
		if player.global_position.distance_to(Vector3(e.home.x, player.global_position.y, e.home.z)) < wake:
			wake_boss(e)


func wake_boss(e: Enemy) -> void:
	e.dormant = false
	e.wake(player)
	var rec := Profile.new()
	_boss_records[e.kind] = rec
	records.append(rec)
	boss = e
	boss_record = rec
	say(e.display_name, "boss")
	if Quests.trial_boss(soul) == e.kind:
		say("Your grade trial. Beat it and you can seek promotion.", "whisper")
	Sfx.play("roar", 0.0, 0.8)
	Sfx.loop("music", "music_fight", -11.0)


func _boss_fell(e: Enemy) -> void:
	soul.flags["beat_" + e.kind] = true
	var rec: Profile = _boss_records.get(e.kind)
	if rec != null:
		rec.end_hp_frac = player.hp / maxf(player.max_hp, 1.0)
		soul.flags["record_" + e.kind] = rec.to_dict()
		records.erase(rec)
		_boss_records.erase(e.kind)
	if boss_record == rec:
		boss_record = null
	bosses.erase(e.kind)
	if e.has_meta("rematch"):
		soul.flags["rematches_" + e.kind] = int(soul.flags.get("rematches_" + e.kind, 0)) + 1
	_build_rematch(e.kind, e.home)
	_quest_event("boss", e.kind)
	Sfx.play("write", 0.0)
	Sfx.loop("music", music_name(), -15.0)
	Fx.pillar(e.global_position, Color(1, 1, 1), 60.0, 4.0, 2.5)
	Fx.screen_flash(Color(1, 1, 1), 0.7)
	Fx.hitstop(0.4)
	say(String(e.def.get("death_line", "It is over.")), "boss")
	if Quests.trial_boss(soul) == e.kind:
		say("Trial done. %s" % Quests.promotion_gap(soul), "gain")
	main.save()


# ------------------------------------------------------------------- loot

## A fallen enemy pays shards at once and spills what else it carried as
## loot on the ground: walk over it to take it. A power boss drops a charm.
func _drop_loot(e: Enemy) -> void:
	var drops := Items.roll_drops(e.kind, e.level, e.affix != "", hash([soul.seed, region_id, int(soul.profile.count("kills")), e.kind]))
	var sh := int(drops["shards"])
	if sh > 0:
		soul.shards += sh
		Fx.word(e.center() + Vector3(0.6, 1.0, 0), "+%d" % sh, Color(1.0, 0.82, 0.4), 0.7)
	var mats: Dictionary = drops["materials"]
	var k := 0
	for m: Variant in mats.keys():
		_spawn_loot(e.global_position + Vector3(cos(float(k) * 2.1) * 1.2, 0, sin(float(k) * 2.1) * 1.2), {"materials": {m: mats[m]}})
		k += 1
	var charm: Dictionary = drops["charm"]
	if not charm.is_empty():
		_spawn_loot(e.global_position + Vector3(0, 0, 1.6), {"charm": charm})
		say("%s dropped: %s %s" % [e.display_name, String(charm["rarity"]), String(charm["name"])], "gain")


func _spawn_loot(at: Vector3, what: Dictionary) -> Node3D:
	var node := Node3D.new()
	add_child(node)
	node.position = Vector3(at.x, height_at(at.x, at.z) + 0.7, at.z)
	var col := Color(1.0, 0.82, 0.4)
	var big := what.has("charm")
	if what.has("materials"):
		var m := String((what["materials"] as Dictionary).keys()[0])
		col = (Items.MATERIALS[m] as Dictionary)["color"]
	var gem := _block(node, Vector3.ONE * (0.45 if big else 0.3), Vector3.ZERO, ForgeMesh.glow(col, 2.6 if big else 1.8), Vector3(45, 0, 35))
	gem.name = "gem"
	if big:
		var beam := ForgeMesh.inst(ForgeMesh.box(Vector3(0.12, 6.0, 0.12)), ForgeMesh.ghost(Color(col.r, col.g, col.b, 0.5)), node, Vector3(0, 3.0, 0))
		beam.set_meta("no_ghost", true)
		var l := OmniLight3D.new()
		l.light_color = col
		l.light_energy = 1.8
		l.omni_range = 6.0
		node.add_child(l)
	node.set_meta("what", what)
	node.set_meta("life", 180.0)
	_loot.append(node)
	return node


func _tick_loot(delta: float) -> void:
	if player == null or not player.alive:
		return
	var i := 0
	while i < _loot.size():
		var n: Node3D = _loot[i]
		if not is_instance_valid(n):
			_loot.remove_at(i)
			continue
		var life := float(n.get_meta("life")) - delta
		n.set_meta("life", life)
		var gem: Node3D = n.get_node("gem")
		gem.rotation.y += delta * 2.0
		gem.position.y = sin(life * 3.0) * 0.12
		var d := Vector2(n.global_position.x - player.global_position.x, n.global_position.z - player.global_position.z).length()
		if d < 2.6:
			_take_loot(n)
			_loot.remove_at(i)
			continue
		if life <= 0.0:
			n.queue_free()
			_loot.remove_at(i)
			continue
		i += 1


func _take_loot(n: Node3D) -> void:
	var what: Dictionary = n.get_meta("what")
	Items.gain(soul, what)
	if what.has("charm"):
		var c: Dictionary = what["charm"]
		say("%s|%s|%s   [I] to wear" % [String(c["rarity"]), String(c["name"]), Items.describe(c)], "drop")
		Sfx.play("relic", -2.0, 1.2)
	else:
		var mats: Dictionary = what["materials"]
		var m := String(mats.keys()[0])
		say("%s:%d" % [m, int(mats[m])], "loot")
		Sfx.play("ui_tick", -4.0, 1.6)
	Fx.sparks(n.global_position, Color(1.0, 0.82, 0.4), 8, 4.0)
	n.queue_free()


func loot_count() -> int:
	var n := 0
	for l: Variant in _loot:
		if is_instance_valid(l):
			n += 1
	return n


# --------------------------------------------------------------- the tether

## Before the training, a chain hangs from the soul's chest: what is left of
## its tie to the living. It rusts with time and with every soul devoured.
## When it is gone the hunger is louder. Whatever is left when it is cut
## counts toward the Reaper.
func tether_links() -> int:
	return int(soul.flags.get("tether", 0))


func _tick_tether(delta: float) -> void:
	if String(soul.flags.get("chapter", "")) != "prologue" or tether_links() <= 0:
		return
	soul.flags["tether_t"] = float(soul.flags.get("tether_t", 0.0)) + delta
	if float(soul.flags["tether_t"]) >= 240.0:
		soul.flags["tether_t"] = 0.0
		erode_tether("Another link of your tether rusts away.")


func erode_tether(text: String) -> void:
	var links := tether_links()
	if links <= 0:
		return
	soul.flags["tether"] = links - 1
	if links - 1 <= 0:
		Strains.gain(soul.affinity, "devour", 3.0)
		say("Your tether has rusted through. The hunger is louder now.", "whisper")
	else:
		say("%s %d left." % [text, links - 1], "hint")
	Sfx.play("break", -10.0, 1.6)
	if player != null:
		player.rebuild_body()


# ------------------------------------------------------------------- deaths

func on_enemy_death(e: Enemy) -> void:
	if e == null:
		return
	var diff := soul.level - e.level
	var factor := 1.0 if diff <= 3 else maxf(0.1, 1.0 - 0.18 * float(diff - 3))
	factor *= 1.0 + 0.06 * float(player.style_index())
	if events != null and events.storming():
		factor *= 1.5
	if daynight != null and daynight.night() > 0.6:
		factor *= 1.25
	main.grant_essence(e.essence * factor)
	if play != null:
		play.on_enemy_death(e)
	_drop_loot(e)
	_quest_event("kill", e.kind)
	if e.is_boss and not e.is_echo:
		_boss_fell(e)
	_special_death(e)
	if soul.techniques.is_empty() and soul.profile.count("kills") >= 3.0:
		var kind := AbilityForge.instinct_kind(soul.profile, soul.seed)
		var t := AbilityForge.technique(kind, soul.seed, Stats.base_totals(soul), soul.profile, 0)
		soul.techniques.append(t)
		say("An instinct surfaces: %s" % String(t["name"]), "gain")
		say("%s  %s  [1]" % [String(t["line"]), String(t["quirk"])], "toast")
		Sfx.play("levelup", -3.0)


func on_player_death() -> void:
	if _respawn_pending:
		return
	_respawn_pending = true
	say("You come apart.", "death")
	soul.flags["deaths"] = int(soul.flags.get("deaths", 0)) + 1
	Sfx.play("death", 0.0, 0.6)
	meditation = null
	get_tree().create_timer(2.8, false).timeout.connect(_respawn)


## Dying costs half the essence you carry and a little standing.
func _respawn() -> void:
	_respawn_pending = false
	soul.essence = floorf(soul.essence * 0.5)
	soul.standing = maxf(0.0, soul.standing - 5.0)
	var home := String(soul.flags.get("checkpoint_region", region_id))
	if home != region_id:
		main.enter_region(home)
		main.place.say("Half of what you carried is ash.", "hint")
		return
	reset_enemies()
	_on_respawn()
	Sfx.loop("music", music_name(), -15.0)
	player.revive(checkpoint)
	if cam != null:
		cam.snap()
	say("Half of what you carried is ash.", "hint")


# -------------------------------------------------------------------- quests

func _quest_event(kind: String, target: String = "any") -> void:
	for id: Variant in Quests.event(soul, kind, target, region_id):
		say("Notice complete: %s. Hand it in at the board." % String(Quests.def(String(id))["title"]), "gain")
		Sfx.play("relic", -6.0, 1.3)


func _on_noted(event: String) -> void:
	if play != null:
		play.on_noted(event)
	match event:
		"devour", "send", "relic", "parry", "tech":
			_quest_event(event)


func open_board(board_id: String) -> void:
	if main == null or main.board_ui == null:
		return
	if board_id == "exchange":
		main.board_ui.open_market(self)
	elif board_id == "forge":
		main.board_ui.open_forge(self)
	else:
		main.board_ui.open_board(self, board_id)


## The board's promotion button. Returns true if the soul rose.
func promote() -> bool:
	var before := Quests.title(soul)
	var g := Quests.promote(soul)
	if g < 0:
		return false
	var after := Quests.title(soul)
	if g == 2 and not soul.release.is_empty() and int(soul.release.get("stage", 1)) < 2:
		var boss_id := String((Quests.TRIALS[soul.primary] as Dictionary)[3])
		var rec := Profile.from_dict(soul.flags.get("record_" + boss_id, {}))
		soul.release = AbilityForge.unseal(soul.release, rec)
		say("FULL RELEASE", "release")
		say(String(AbilityForge.SCARS[soul.release["scar"]]), "gain")
	say("%s  →  %s" % [before.to_upper(), after.to_upper()], "release")
	say("Grade %d|Your level can now reach %d. Three skill points  [K]" % [g, Quests.level_cap(soul)], "level")
	Sfx.play("write", 0.0)
	if player != null:
		player.rebuild_body()
		player.refresh_stats(true)
		Fx.pillar(player.global_position, player.current_color(), 30.0, 1.6, 1.4)
	main.save()
	return true


# ------------------------------------------------------------- the compass

## What the compass shows: [position, colour, label].
func markers() -> Array:
	var out: Array = []
	for b: Variant in _boards:
		out.append([(b as Node3D).global_position, Color(1.0, 0.82, 0.4), "board"])
	for c: Variant in _cairns:
		out.append([(c as Node3D).global_position, Color(0.7, 0.9, 1.0), "cairn"])
	var portals := portal_list()
	for i in range(_portals.size()):
		if _portals[i] != null:
			out.append([(_portals[i] as Node3D).global_position, Color(1.0, 0.4, 0.5), String(portals[i][2])])
	for k: Variant in bosses.keys():
		var ev: Variant = bosses[k]
		if is_instance_valid(ev) and (ev as Enemy).alive:
			out.append([(ev as Enemy).global_position, Color(1.0, 0.15, 0.2), "boss"])
	if events != null and not events.ev.is_empty():
		out.append([events.ev["at"], Color(1.0, 0.25, 0.2), "event"])
	if play != null:
		out.append_array(play.markers())
	if player != null and player.sensing:
		for e in enemies_alive():
			if e.global_position.distance_to(player.global_position) > Player.SENSE_RANGE or not (e is Enemy):
				continue
			var th := player.threat_of(e as Enemy)
			var col := Color(0.62, 0.6, 0.57) if th == "weaker" else (Ink.BONE if th == "even" else Color(1.0, 0.3, 0.25))
			out.append([e.global_position, col, "sensed", (e as Enemy).level])
	var givers := giver_list()
	for i in range(_givers.size()):
		var gs := giver_state(i)
		if gs != "":
			out.append([(_givers[i] as Node3D).global_position, Ink.BRASS, "giver"])
	for lid: Variant in _lost.keys():
		var ln: Dictionary = _lost[lid]
		if is_instance_valid(ln["rig"]) and not bool(ln["following"]):
			out.append([(ln["rig"] as Node3D).global_position, Color(0.8, 0.92, 1.0), "lost"])
	# what the active notices want
	for id: String in Quests.active(soul):
		var q := Quests.def(id)
		if Quests.is_ready(soul, id):
			continue
		match String(q["kind"]):
			"kill":
				var t := _nearest_of(String(q["target"]))
				if t != null:
					out.append([t.global_position, Color(1, 1, 1), "notice"])
			"relic":
				var ri := _nearest_index(_relics, 9999.0)
				if ri >= 0:
					out.append([(_relics[ri] as Node3D).global_position, Color(0.78, 0.55, 1.0), "keepsake"])
	return out


func _nearest_of(target: String) -> Actor:
	var best: Actor = null
	var best_d := 400.0
	for a in enemies_alive():
		var e := a as Enemy
		if e == null or e.is_boss:
			continue
		if target != "any" and not target.begins_with("any@") and e.kind != target:
			continue
		var d := e.global_position.distance_to(player.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best


# ------------------------------------------------------------- interacting

func _nearest_remnant() -> Enemy:
	var best: Enemy = null
	var best_d := 3.0 + 0.0
	for a in actors:
		if not is_instance_valid(a) or a.alive or not (a is Enemy):
			continue
		var e: Enemy = a
		if not e.remnant:
			continue
		var d := e.global_position.distance_to(player.global_position) - e.radius
		if d < best_d:
			best_d = d
			best = e
	return best


func _nearest_index(nodes: Array, reach: float) -> int:
	var best := -1
	var best_d := reach
	for i in range(nodes.size()):
		var n: Variant = nodes[i]
		if n == null or not is_instance_valid(n):
			continue
		var p: Vector3 = (n as Node3D).global_position
		var d := Vector2(p.x - player.global_position.x, p.z - player.global_position.z).length()
		if d < best_d:
			best_d = d
			best = i
	return best


func prompt() -> String:
	if player == null or not player.alive:
		return ""
	if meditation != null:
		if meditation.done:
			return ""
		return "Hold SPACE to breathe in. Let go to breathe out.   %d / %d" % [meditation.breaths, Meditation.NEED]
	if player.state != Actor.St.FREE:
		return ""
	if player.carrying != null:
		return "LMB  Throw it   ·   V drop it"
	var gp := _nearest_index(_givers, 3.0)
	if gp >= 0:
		return "E  Talk to %s" % String(giver_list()[gp][4])
	var lp := _nearest_lost(2.8)
	if lp != "" and not bool(_lost[lp]["following"]):
		return "E  Take their hand"
	if play != null:
		var pp := play.prompt()
		if pp != "":
			return pp
	for a in actors:
		if is_instance_valid(a) and a is Enemy and (a as Enemy).knocked and (a as Enemy).alive and a.global_position.distance_to(player.global_position) < 3.4:
			return "B  Grip it   ·   V carry it"
	if _nearest_remnant() != null:
		return "E  Devour   ·   G send on   ·   V carry"
	if _nearest_index(_relics, 2.8) >= 0:
		return "E  Remember"
	var ti := _nearest_index(_talkers, 3.0)
	if ti >= 0:
		return "E  Speak with %s" % String(talker_list()[ti][3])
	var rk := _nearest_rematch()
	if rk != "" and not in_combat():
		return "E  Call back %s (level %d)" % [String(Quests.BOSS_NAMES.get(rk, rk)), rematch_level(rk)]
	var bi := _nearest_index(_boards, 3.2)
	if bi >= 0:
		var bid := String(board_list()[bi][2])
		return "E  %s %s" % ["Work" if bid == "forge" else "Read", String(Quests.BOARDS[bid]["title"])]
	if _nearest_index(_steles, 3.2) >= 0:
		return "E  Read"
	var pi := _nearest_index(_portals, 3.6)
	if pi >= 0 and not in_combat():
		return "E  %s" % String(portal_list()[pi][3])
	if _nearest_index(_cairns, 3.4) >= 0 and not in_combat():
		return "E  Sit"
	return ""


func interact() -> bool:
	var rem := _nearest_remnant()
	if rem != null:
		player.face_now(player.flat_to(rem.global_position))
		player.begin_busy("devour", 0.9, "kneel", _devour.bind(rem.get_instance_id()))
		Sfx.play("devour", -2.0)
		return true
	var ri := _nearest_index(_relics, 2.8)
	if ri >= 0:
		player.begin_busy("relic", 0.8, "kneel", _remember.bind(ri))
		return true
	var gi := _nearest_index(_givers, 3.0)
	if gi >= 0:
		_talk_giver(gi)
		return true
	var lid := _nearest_lost(2.8)
	if lid != "":
		_find_lost(lid)
		return true
	if play != null and play.interact():
		return true
	var ti := _nearest_index(_talkers, 3.0)
	if ti >= 0:
		_speak(ti)
		return true
	var rk := _nearest_rematch()
	if rk != "" and not in_combat():
		call_back(rk)
		return true
	var bi := _nearest_index(_boards, 3.2)
	if bi >= 0:
		if _talk_cd <= 0.0:
			_talk_cd = 0.35
			open_board(String(board_list()[bi][2]))
		return true
	var si := _nearest_index(_steles, 3.2)
	if si >= 0:
		var d: Array = stele_list()[si]
		say(String(d[2]), "stele")
		if not bool(soul.flags.get(flag("stele", si), false)):
			soul.flags[flag("stele", si)] = true
			note("read")
		Sfx.play("ui_open", -6.0)
		return true
	var pi := _nearest_index(_portals, 3.6)
	if pi >= 0:
		_step_through(pi)
		return true
	var ci := _nearest_index(_cairns, 3.4)
	if ci >= 0:
		if in_combat():
			say("Not while something is hunting you.", "hint")
			return true
		_sit(ci)
		return true
	return false


## The dead who linger say one line at a time, then repeat the last. When the
## last line is said, a person with an action does it.
func _speak(i: int) -> void:
	if _talk_cd > 0.0:
		return
	_talk_cd = 0.35
	var d: Array = talker_list()[i]
	var lines: Array = d[4]
	var key := flag("talk", i) + "_" + String(soul.flags.get("chapter", ""))
	var at := int(soul.flags.get(key, 0))
	say("%s|%s" % [String(d[3]), String(lines[mini(at, lines.size() - 1)])], "talk")
	soul.flags[key] = mini(at + 1, lines.size() - 1)
	var rig: BlockRig = _talkers[i]
	var to := player.global_position - rig.global_position
	rig.rotation.y = atan2(-to.x, -to.z)
	player.face_now(-to)
	Sfx.play("ui_open", -6.0)
	if d.size() > 6 and at >= lines.size() - 1:
		_talk_action(String(d[6]), i)


func _step_through(i: int) -> void:
	var d: Array = portal_list()[i]
	if in_combat():
		say("Not while something is hunting you.", "hint")
		return
	if not portal_open(String(d[4])):
		say(portal_refusal(String(d[4])), "whisper")
		Sfx.play("ui_tick", -4.0, 0.6)
		return
	Sfx.play("sever", -2.0, 0.6)
	Fx.screen_flash(Color(0, 0, 0), 0.9)
	main.travel(String(d[2]), region_id)


# --------------------------------------------------------- people who ask

## A small plate over a head: a name and what they do, seen from near.
func _name_plate(rig: BlockRig, who: String, what: String) -> void:
	var l := Label3D.new()
	l.text = who.to_upper() + ("\n" + what if what != "" else "")
	l.font = Ink.caps_font()
	l.font_size = 40
	l.pixel_size = 0.004
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.outline_size = 10
	l.outline_modulate = Color(0.04, 0.035, 0.03, 0.9)
	l.modulate = Ink.PAPER
	l.position = Vector3(0, rig.height + 0.55, 0)
	l.visibility_range_end = 24.0
	rig.add_child(l)


## "!" a giver has something to ask, "?" something is ready to hand in.
func giver_state(i: int) -> String:
	var board := String(giver_list()[i][3])
	Quests.check_deliveries(soul)
	for id: String in Quests.active(soul):
		if String(Quests.def(id)["board"]) == board and Quests.is_ready(soul, id):
			return "?"
	if not Quests.available(soul, board).is_empty() and Quests.active(soul).size() < Quests.MAX_ACTIVE:
		return "!"
	return ""


func _talk_giver(i: int) -> void:
	if _talk_cd > 0.0:
		return
	_talk_cd = 0.35
	var g: Array = giver_list()[i]
	var board := String(g[3])
	var who := String(g[4])
	var rig: BlockRig = _givers[i]
	var to := player.global_position - rig.global_position
	rig.rotation.y = atan2(-to.x, -to.z)
	player.face_now(-to)
	Sfx.play("ui_open", -6.0)
	Quests.check_deliveries(soul)
	# hand in what is done
	for id: String in Quests.active(soul):
		var q := Quests.def(id)
		if String(q["board"]) != board or not Quests.is_ready(soul, id):
			continue
		var r := Quests.claim(soul, id)
		main.grant_essence(float(r["essence"]))
		var line := "Handed in: %s.  +%d essence" % [String(q["title"]), int(r["essence"])]
		if int(r.get("shards", 0)) > 0:
			line += "  +%d shards" % int(r["shards"])
		if float(r["standing"]) > 0.0:
			line += "  +%d standing" % int(r["standing"])
		say(line, "gain")
		say("%s|%s" % [who, "Thank you. I mean it. Not many of the dead stop for anyone."], "talk")
		Sfx.play("quest_done", -3.0)
		main.save()
		return
	# ask for something new
	var offer := Quests.available(soul, board)
	if not offer.is_empty() and Quests.active(soul).size() < Quests.MAX_ACTIVE:
		var q := Quests.def(String(offer[0]))
		var reward := "+%d essence" % int(q["essence"])
		if int(q.get("shards", 0)) > 0:
			reward += ", +%d shards" % int(q["shards"])
		if int(q["standing"]) > 0:
			reward += ", +%d standing" % int(q["standing"])
		main.board_ui.open_choice(self, who, "%s\n\n%s" % [String(q["text"]), reward], ["Accept: %s" % String(q["title"]), "Not now"], func(pick: int) -> void:
			if pick == 0 and Quests.accept(soul, String(q["id"])):
				say("Notice taken: %s" % String(q["title"]), "toast")
				Sfx.play("quest", -4.0)
				_sync_lost())
		return
	if Quests.active(soul).size() >= Quests.MAX_ACTIVE and not offer.is_empty():
		say("%s|%s" % [who, "You are carrying enough already. Come back when you are not."], "talk")
		return
	var lines: Array = g[7]
	say("%s|%s" % [who, String(lines[int(Time.get_ticks_msec() / 1000) % lines.size()])], "talk")


## Lost souls for active escort notices in this region wait at their spot.
func _sync_lost() -> void:
	for id: String in Quests.active(soul):
		var q := Quests.def(id)
		if String(q["kind"]) != "escort" or String(q.get("region", "")) != region_id or Quests.is_ready(soul, id):
			continue
		var lid := String(q["target"])
		if _lost.has(lid):
			continue
		var at: Array = q["find"]
		var r := BlockRig.new()
		add_child(r)
		r.build({"cloth": Color(0.82, 0.86, 0.92), "trim": Color(0.6, 0.7, 0.85), "coat": 1, "hair": int(hash(lid)) % 4, "hair_color": Color(0.2, 0.18, 0.2), "hair_seed": int(hash(lid)) % 97, "face": 2, "scale": 0.82, "tether": 4})
		_place_on_ground(r, float(at[0]), float(at[1]))
		r.play("kneel", 0.0)
		for m in r.mats:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_color.a = 0.6
		_name_plate(r, "a lost soul", "")
		_lost[lid] = {"rig": r, "following": false, "quest": id}


func _nearest_lost(within: float) -> String:
	var best := ""
	var best_d := within
	for lid: Variant in _lost.keys():
		var r: Node3D = _lost[lid]["rig"]
		if not is_instance_valid(r):
			continue
		var d := r.global_position.distance_to(player.global_position)
		if d < best_d:
			best_d = d
			best = String(lid)
	return best


func _find_lost(lid: String) -> void:
	var ln: Dictionary = _lost[lid]
	if bool(ln["following"]):
		return
	ln["following"] = true
	(ln["rig"] as BlockRig).play("idle", 0.3)
	say("%s|%s" % ["A lost soul", "You can see me? Then... will you take me back? I do not remember the way."], "talk")
	Sfx.play("relic", -8.0, 1.4)


func _tick_npcs(delta: float) -> void:
	_npc_t -= delta
	if _npc_t <= 0.0:
		_npc_t = 0.5
		_sync_lost()
		for i in range(_giver_marks.size()):
			var gs := giver_state(i)
			var mk: Label3D = _giver_marks[i]
			mk.text = gs
			mk.modulate = Ink.BRASS if gs == "!" else Color(0.75, 0.9, 1.0)
	for i in range(_giver_marks.size()):
		var mk: Label3D = _giver_marks[i]
		mk.position.y = (_givers[i] as BlockRig).height + 1.15 + sin(Time.get_ticks_msec() / 400.0 + float(i)) * 0.08
	# the found follow you home, through walls: they are dead
	for lid: Variant in _lost.keys():
		var ln: Dictionary = _lost[lid]
		var r: BlockRig = ln["rig"]
		if not is_instance_valid(r) or not bool(ln["following"]):
			continue
		var to := player.global_position - r.global_position
		to.y = 0.0
		if to.length() > 2.6:
			var step := to.normalized() * minf(to.length() - 2.4, maxf(6.0, to.length() * 1.6) * delta)
			r.global_position += step
			r.global_position.y = height_at(r.global_position.x, r.global_position.z) + 0.05
			r.rotation.y = atan2(-to.x, -to.z)
			r.play("run", 0.2)
		else:
			r.play("idle", 0.3)
		# home: close to the one who asked
		var q := Quests.def(String(ln["quest"]))
		var gi := -1
		var givers := giver_list()
		for i in range(givers.size()):
			if String(givers[i][3]) == String(q["board"]):
				gi = i
		if gi >= 0 and r.global_position.distance_to((_givers[gi] as Node3D).global_position) < 4.5:
			Quests.event(soul, "escort", String(lid), region_id)
			say("%s is home. Speak to %s." % ["The lost soul", String(givers[gi][4])], "gain")
			Fx.pillar(r.global_position, Color(0.8, 0.92, 1.0), 8.0, 0.4, 0.8)
			Sfx.play("send", -4.0, 1.2)
			r.queue_free()
			_lost.erase(lid)
			break


func send_on() -> bool:
	var rem := _nearest_remnant()
	if rem == null:
		return false
	player.face_now(player.flat_to(rem.global_position))
	player.begin_busy("send", 0.8, "kneel", _send.bind(rem.get_instance_id()))
	Sfx.play("send", -2.0)
	return true


func _devour(id: int) -> void:
	var e: Object = instance_from_id(id)
	if e == null or not is_instance_valid(e) or not (e as Enemy).remnant:
		return
	var en: Enemy = e
	player.heal(player.max_hp * 0.18)
	main.grant_essence(en.essence * 0.4)
	note("devour")
	Fx.sparks(player.center(), Color(1, 0.15, 0.2), 16, 7.0)
	en.consume(Color(1.0, 0.15, 0.2))
	if String(soul.flags.get("chapter", "")) == "prologue":
		erode_tether("Eating rusts your tether.")


func _send(id: int) -> void:
	var e: Object = instance_from_id(id)
	if e == null or not is_instance_valid(e) or not (e as Enemy).remnant:
		return
	var en: Enemy = e
	player.anima = minf(player.max_anima, player.anima + player.max_anima * 0.4)
	player.gain_swell(12.0)
	main.grant_essence(en.essence * 0.2)
	note("send")
	Fx.pillar(en.global_position, Color(0.8, 0.95, 1.0), 14.0, 0.5, 0.9)
	en.consume(Color(0.8, 0.95, 1.0))


func _remember(i: int) -> void:
	var node: Variant = _relics[i]
	if node == null or not is_instance_valid(node):
		return
	var d: Array = relic_list()[i]
	soul.flags[flag("relic", i)] = true
	note("relic")
	main.grant_essence(30.0)
	say(String(d[2]), "stele")
	Sfx.play("relic", -2.0)
	Fx.sparks((node as Node3D).global_position, Color(0.78, 0.55, 1.0), 20, 6.0)
	Fx.ring((node as Node3D).global_position, Color(0.78, 0.55, 1.0), 0.3, 3.0, 0.5)
	(node as Node3D).queue_free()
	_relics[i] = null


func _sit(ci: int) -> void:
	var c: Node3D = _cairns[ci]
	soul.flags["checkpoint"] = ci
	soul.flags["checkpoint_region"] = region_id
	checkpoint = start_point()
	player.face_now(player.flat_to(c.global_position))
	player.begin_busy("meditate", 0.0, "meditate")
	player.lock_target = null
	meditation = Meditation.new()
	_stand_t = 0.0
	_trial_pending = false
	Sfx.play("ui_open", -6.0)


func _tick_meditation(delta: float) -> void:
	if not player.alive or player.state != Actor.St.BUSY:
		meditation = null
		return
	var ev := meditation.tick(delta, player.intent.jump_held)
	if ev == "in":
		Sfx.play("breath_in", -6.0)
	elif ev != "":
		Sfx.play("breath_out", -6.0)
		soul.profile.add("breaths_" + ev)
		note("breath")
		Fx.ring(player.global_position + Vector3(0, 0.1, 0), Color(0.85, 0.95, 1.0), 0.4, 3.0 if ev == "steady" else (1.6 if ev == "sharp" else 4.6), 0.9)
	if meditation.done:
		if _stand_t == 0.0:
			_rest()
		_stand_t += delta
		if _stand_t > 2.2:
			meditation = null
			player.end_busy()
			if _trial_pending:
				main.enter_trial()
	elif player.intent.interact and meditation.age > 0.5:
		meditation = null
		player.end_busy()


func _rest() -> void:
	player.refresh_stats(true)
	reset_enemies()
	Sfx.play("rest", -3.0)
	Fx.ring(player.global_position + Vector3(0, 0.1, 0), Color(1, 1, 1), 0.5, 9.0, 1.2)
	if not soul.written():
		if _awakening_ready():
			_trial_pending = true
			say("Something in the blade is awake. It wants to be met.", "whisper")
		else:
			say("You are rested. The blade is quiet: it does not know you yet.", "toast")
	elif soul.can_graft():
		offer_graft()
	else:
		say("You are rested. What you killed has returned.", "toast")
	main.save()


## The fusion choice. A second strain has grown strong enough to let in:
## a soul can take it (and become a hybrid) or refuse it for good.
func offer_graft() -> void:
	var second := soul.second_strain()
	var form := Strains.hybrid_name(soul.primary, second)
	var text := "%s has grown in you as strongly as your own strain. Let it in and you become a %s: your body changes, and the art only a %s knows comes with it. Refuse it and you stay as you are, purer and sharper, and it never asks again." % [
		String(Strains.INFO[second]["title"]), form, form]
	if main != null and main.board_ui != null:
		main.board_ui.open_choice(self, "A SECOND VOICE", text, ["Let it in: become a %s" % form, "Refuse it: stay pure"], _graft_chosen)


func _graft_chosen(choice: int) -> void:
	if choice == 0:
		var second := soul.second_strain()
		var form := soul.graft()
		if form == "":
			return
		var art := String(AbilityForge.HYBRID_ART.get(form, "guard"))
		var t := AbilityForge.technique(art, soul.seed, Stats.base_totals(soul), soul.profile, soul.techniques.size())
		soul.techniques.append(t)
		soul.slot_technique(soul.techniques.size() - 1)
		say("A SECOND VOICE", "release")
		say("Two strains run in you now. You are a %s. Your art: %s." % [form, String(t["name"])], "gain")
		Sfx.play("write", 0.0)
		player.rebuild_body()
		player.refresh_stats()
		Fx.pillar(player.global_position, player.current_color(), 30.0, 1.6, 1.4)
	else:
		soul.flags["pure"] = true
		player.refresh_stats()
		say("You refuse it. You stay pure: your cuts are sharper and your spirit pressure gathers faster.", "gain")
		Sfx.play("seal", 0.0)
	main.save()
