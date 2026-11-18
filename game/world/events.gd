class_name EventDirector
extends Node
## World events, one at a time, every few minutes of a realm's quiet:
##   raid  : a rift tears open; three waves come through it, then a warden.
##   march : a Tall walks across the realm; bring it down before it leaves.
##   storm : the sky goes red; the dead grow restless and pay half again.
## Only once a soul has awakened, never in the training cavern, never mid-fight.

const ALLOWED: Array = ["town", "citadel", "ashfall", "reach", "undermark"]

var region: Region
var cd: float = 0.0
## The running event: kind, title, line, t, len, at, and per-kind state.
var ev: Dictionary = {}
var _rng: RandomNumberGenerator
var _rift: Node3D
var _env: Environment
var _env_keep: Dictionary = {}


func setup(r: Region) -> void:
	region = r
	_rng = Rng.make([r.soul.seed if r.soul != null else 0, r.region_id, "events"])
	cd = _rng.randf_range(200.0, 360.0)


func allowed() -> bool:
	return region.soul != null and region.soul.written() and ALLOWED.has(region.region_id)


func tick(delta: float) -> void:
	if ev.is_empty():
		if not allowed() or region.in_combat() or region.player == null or region.player.scripted or (region.play != null and region.play.busy()):
			return
		cd -= delta
		if cd <= 0.0:
			var kinds: Array = ["raid", "storm"]
			if region.region_id != "town":
				kinds.append("march")
			start(String(Rng.pick(_rng, kinds)))
		return
	ev["t"] = float(ev["t"]) + delta
	match String(ev["kind"]):
		"raid":
			_tick_raid()
		"march":
			_tick_march()
		"storm":
			_tick_storm(delta)
	if not ev.is_empty() and float(ev["t"]) >= float(ev["len"]):
		finish(String(ev["kind"]) == "storm")


## Where an event happens: some way off, on open ground.
func _spot(near: float, far: float) -> Vector3:
	var p := region.player.global_position
	for i in range(30):
		var a := _rng.randf() * TAU
		var d := _rng.randf_range(near, far)
		var x := p.x + cos(a) * d
		var z := p.z + sin(a) * d
		if region.region_id == "town":
			# in town, out in the street, not in someone's back yard
			var roads: Array = [-160.0, -90.0, 0.0, 90.0, 160.0]
			var bx := 0.0
			var bz := 0.0
			for rv: Variant in roads:
				if absf(float(rv) - x) < absf(bx - x):
					bx = float(rv)
				if absf(float(rv) - z) < absf(bz - z):
					bz = float(rv)
			if absf(bx - x) < absf(bz - z):
				x = bx
			else:
				z = bz
		if absf(x) < region.bounds - 25.0 and absf(z) < region.bounds - 25.0 and region.dress_clear(x, z, 6.0):
			return Vector3(x, region.height_at(x, z), z)
	var f := region.player.forward() * near
	return Vector3(p.x + f.x, region.height_at(p.x + f.x, p.z + f.z), p.z + f.z)


func start(kind: String) -> bool:
	if not ev.is_empty() or region.player == null:
		return false
	match kind:
		"raid":
			var at := _spot(35.0, 70.0)
			ev = {"kind": "raid", "title": "A Rift Tears Open", "line": "Seal it: three waves, then its warden.", "t": 0.0, "len": 240.0, "at": at, "wave": 0, "foes": []}
			_build_rift(at)
			_next_wave()
			region.say("A RIFT TEARS OPEN", "region")
		"march":
			var a := _rng.randf() * TAU
			var r := region.bounds * 0.7
			var from := Vector3(cos(a) * r, 0, sin(a) * r)
			from.y = region.height_at(from.x, from.z)
			var to := Vector3(-from.x, 0, -from.z)
			to.y = region.height_at(to.x, to.z)
			var g: Enemy = region._spawn("giant", from, region.level_base + 2)
			g.max_hp *= 2.0
			g.hp = g.max_hp
			g.essence *= 3.0
			g.display_name = "the Marching Tall"
			g.march_to = to
			g.set_meta("event", true)
			ev = {"kind": "march", "title": "A Tall Is Marching", "line": "Bring it down before it walks out of the realm.", "t": 0.0, "len": 210.0, "at": from, "giant": g}
			region.say("A TALL IS MARCHING", "region")
		"storm":
			ev = {"kind": "storm", "title": "Spirit Storm", "line": "The dead are restless. Every kill pays half again.", "t": 0.0, "len": 120.0, "at": region.player.global_position, "spawn_t": 6.0}
			_storm_sky(true)
			region.say("A SPIRIT STORM", "region")
		_:
			return false
	Sfx.play("horn", 0.0)
	Fx.add_shake(0.6)
	return true


## How it ended. Raids and marches pay only if won.
func finish(won: bool) -> void:
	if ev.is_empty():
		return
	var kind := String(ev["kind"])
	var at: Vector3 = ev["at"]
	match kind:
		"raid":
			for f: Variant in ev["foes"]:
				if is_instance_valid(f) and (f as Enemy).alive:
					(f as Enemy).consume(Color(0.8, 0.2, 0.2))
			if _rift != null:
				Fx.pillar(_rift.global_position, Color(1.0, 0.3, 0.25) if won else Color(0.4, 0.4, 0.45), 18.0, 0.6, 1.0)
				_rift.queue_free()
				_rift = null
			region.say("THE RIFT IS SEALED" if won else "THE RIFT CLOSES", "region")
		"march":
			var g: Variant = ev.get("giant")
			if not won and is_instance_valid(g) and (g as Enemy).alive:
				(g as Enemy).consume(Color(0.6, 0.6, 0.65))
			region.say("THE TALL FALLS" if won else "THE TALL IS GONE", "region")
		"storm":
			_storm_sky(false)
			region.say("THE STORM PASSES", "region")
	if won and kind != "storm":
		_reward(at, kind)
	ev = {}
	cd = _rng.randf_range(300.0, 480.0)


func _reward(at: Vector3, kind: String) -> void:
	var tier := float(region.level_base)
	var essence := 220.0 + tier * 30.0
	var shards := int(150.0 + tier * 25.0)
	region.main.grant_essence(essence)
	region.soul.shards += shards
	var keys: Array = Items.MATERIALS.keys()
	keys.sort()
	for i in range(3):
		var m := String(Rng.pick(_rng, keys))
		region._spawn_loot(at + Vector3(cos(float(i) * 2.1) * 2.0, 0, sin(float(i) * 2.1) * 2.0), {"materials": {m: 2 + int(_rng.randi() % 3)}})
	if _rng.randf() < 0.4:
		var ck: Array = Items.CHARMS.keys()
		ck.sort()
		var c := Items.make_charm(String(Rng.pick(_rng, ck)), hash([region.soul.seed, "event", region.soul.flags.get("events", 0)]))
		region._spawn_loot(at + Vector3(0, 0, 2.5), {"charm": c})
	region.soul.flags["events"] = int(region.soul.flags.get("events", 0)) + 1
	region.say("Event won: +%d essence  +%d shards. Spoils lie where it happened." % [int(essence), shards], "gain")
	Sfx.play("levelup", -2.0, 0.9)


# ---------------------------------------------------------------- raid

func _build_rift(at: Vector3) -> void:
	_rift = Node3D.new()
	region.add_child(_rift)
	_rift.position = at
	var black := ForgeMesh.mat(Color(0, 0, 0), 1.0)
	var red := ForgeMesh.glow(Color(1.0, 0.18, 0.15), 2.4)
	region._block(_rift, Vector3(2.6, 7.0, 0.2), Vector3(0, 4.0, 0), black, Vector3(0, 0, 6))
	region._block(_rift, Vector3(0.2, 7.6, 0.24), Vector3(-1.3, 4.0, 0), red, Vector3(0, 0, 10))
	region._block(_rift, Vector3(0.2, 7.6, 0.24), Vector3(1.35, 4.0, 0), red, Vector3(0, 0, 2))
	var ring := ForgeMesh.inst(ForgeMesh.ring(0.9, 32), ForgeMesh.glow(Color(1.0, 0.2, 0.15), 1.6), _rift, Vector3(0, 0.08, 0))
	ring.scale = Vector3(5.0, 1, 5.0)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.25, 0.2)
	l.light_energy = 2.5
	l.omni_range = 16.0
	l.position = Vector3(0, 3.0, 0)
	_rift.add_child(l)
	Fx.pillar(at, Color(1.0, 0.2, 0.15), 22.0, 0.5, 1.0)
	Sfx.play("rift", -2.0)


func _next_wave() -> void:
	var wave := int(ev["wave"]) + 1
	ev["wave"] = wave
	var at: Vector3 = ev["at"]
	var kinds: Array = []
	for sp: Variant in region.spawn_list():
		var k := String((sp as Array)[0])
		if not Bestiary.is_boss(k) and k != "drill" and not kinds.has(k):
			kinds.append(k)
	if kinds.is_empty():
		kinds = ["husk"]
	var foes: Array = []
	if wave <= 3:
		for i in range(2 + wave):
			var a := TAU * float(i) / float(2 + wave)
			var e: Enemy = region._spawn(String(Rng.pick(_rng, kinds)), at + Vector3(cos(a), 0, sin(a)) * 4.0, region.level_base + 1)
			e.home = at
			e.leash = 80.0
			e.set_meta("event", true)
			if region.player.global_position.distance_to(at) < 60.0:
				e.wake(region.player)
			foes.append(e)
		ev["line"] = "Wave %d of 3." % wave
	else:
		var w: Enemy = region._spawn(String(kinds[kinds.size() - 1]), at + Vector3(0, 0, 3.0), region.level_base + 3)
		w._set_affix("stone")
		w.max_hp *= 3.0
		w.hp = w.max_hp
		w.essence *= 4.0
		w.display_name = "Warden of the Rift"
		w.home = at
		w.leash = 80.0
		w.set_meta("event", true)
		w.wake(region.player)
		foes.append(w)
		ev["line"] = "The warden comes through."
		Sfx.play("roar", 0.0, 0.8)
	ev["foes"] = foes
	Fx.ring(at + Vector3(0, 0.2, 0), Color(1.0, 0.2, 0.15), 0.5, 7.0, 0.5)


func _tick_raid() -> void:
	var left := 0
	for f: Variant in ev["foes"]:
		if is_instance_valid(f) and (f as Enemy).alive:
			left += 1
	if left > 0:
		return
	if int(ev["wave"]) >= 4:
		finish(true)
	else:
		_next_wave()


# --------------------------------------------------------------- march

func _tick_march() -> void:
	var g: Variant = ev.get("giant")
	if not is_instance_valid(g):
		finish(false)
		return
	var giant: Enemy = g
	ev["at"] = giant.global_position
	if not giant.alive:
		finish(true)
		return
	if giant.global_position.distance_to(giant.march_to) < 8.0:
		finish(false)


# --------------------------------------------------------------- storm

func _tick_storm(delta: float) -> void:
	ev["spawn_t"] = float(ev["spawn_t"]) - delta
	if float(ev["spawn_t"]) > 0.0:
		return
	ev["spawn_t"] = 20.0
	# the restless dead come up near you
	var kinds: Array = []
	for sp: Variant in region.spawn_list():
		var k := String((sp as Array)[0])
		if not Bestiary.is_boss(k) and k != "drill":
			kinds.append(k)
	if kinds.is_empty():
		return
	for i in range(2):
		var at := _spot(12.0, 22.0)
		var e: Enemy = region._spawn(String(Rng.pick(_rng, kinds)), at, region.level_base + 1)
		e.set_meta("event", true)
		Fx.pillar(at, Color(0.8, 0.2, 0.4), 6.0, 0.3, 0.5)


func storming() -> bool:
	return not ev.is_empty() and String(ev["kind"]) == "storm"


func _storm_sky(on: bool) -> void:
	if _env == null:
		for c in region.get_children():
			if c is WorldEnvironment:
				_env = (c as WorldEnvironment).environment
	if _env == null:
		return
	if on:
		_env_keep = {"fog": _env.fog_enabled, "fog_c": _env.fog_light_color, "fog_d": _env.fog_density, "sat": _env.adjustment_saturation, "tint": _env.ambient_light_color}
		_env.fog_enabled = true
		_env.fog_light_color = Color(0.55, 0.12, 0.2)
		_env.fog_density = maxf(_env.fog_density, 0.0005) * 4.0
		_env.adjustment_saturation = 0.75
		_env.ambient_light_color = _env.ambient_light_color.lerp(Color(0.9, 0.3, 0.4), 0.45)
	elif not _env_keep.is_empty():
		_env.fog_enabled = bool(_env_keep["fog"])
		_env.fog_light_color = _env_keep["fog_c"]
		_env.fog_density = float(_env_keep["fog_d"])
		_env.adjustment_saturation = float(_env_keep["sat"])
		_env.ambient_light_color = _env_keep["tint"]


## What the HUD shows: a title, a line, and how much time is left.
func info() -> Dictionary:
	if ev.is_empty():
		return {}
	return {"title": String(ev["title"]), "line": String(ev["line"]), "left": 1.0 - float(ev["t"]) / float(ev["len"]), "seconds": int(float(ev["len"]) - float(ev["t"])), "kind": String(ev["kind"])}
