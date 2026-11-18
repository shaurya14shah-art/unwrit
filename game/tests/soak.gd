extends Node
## A long, careless bot: it plays every realm with a random hand on every
## key while enemies, bosses and world events come at it. It is not a test
## of skill; it hunts for script errors, bodies that fall out of the world,
## a player stuck in one state, and scenes that pile up nodes.
## godot --headless --fixed-fps 60 --path game res://tests/Soak.tscn -- --no-title [seconds per realm]

const REALMS: Array = ["town", "citadel", "ashfall", "reach", "undermark", "stacks", "undercroft"]

var main: Node
var p: Player
var problems: Array = []
var actions := 0
var deaths := 0
var kills0 := 0.0
var _rng := RandomNumberGenerator.new()


func frames(n: int) -> void:
	for i in range(n + 1):
		await get_tree().physics_frame


func problem(what: String) -> void:
	if problems.size() < 40:
		problems.append(what)
	print("  PROBLEM  ", what)


func _ready() -> void:
	Fx.quiet = true
	Sfx.muted = true
	_rng.seed = 777
	var scene: PackedScene = load("res://main.tscn")
	main = scene.instantiate()
	add_child(main)
	main.save_path = "user://soak_soul.json"
	if FileAccess.file_exists(main.save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	var secs := 40
	for a in OS.get_cmdline_user_args():
		if a.is_valid_int():
			secs = int(a)
	await run(secs)
	print("soak: %d realms, %d actions, %d kills, %d deaths, %d problems" % [REALMS.size(), actions, int(main.soul.profile.count("kills") - kills0), deaths, problems.size()])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	get_tree().quit(1 if problems.size() > 0 else 0)


## A soul that has been everywhere: awakened, high grade, techniques, gear.
func _seasoned() -> void:
	var s: Soul = main.soul
	s.affinity["vigil"] = 80.0
	s.primary = "vigil"
	s.flags["chapter"] = "hub"
	s.flags["hub"] = "citadel"
	s.grade = 1
	s.level = 30
	s.marks = 0
	for k: String in ["sever", "lance", "toll", "guard"]:
		s.techniques.append(AbilityForge.technique(k, s.seed, Stats.base_totals(s), s.profile, s.techniques.size()))
	s.loadout = [0, 1, 2, 3]
	s.gear["weapon"] = Forge.make("w_brand", [], "aggression", 1)
	s.gear["armour"] = Forge.make("a_gaoler", [], "patience", 2)
	kills0 = s.profile.count("kills")


func _use_player() -> void:
	p = main.place.player
	p.scripted = true
	p.intent = Player.Intent.new()


func run(secs: int) -> void:
	print("== soak: %d s per realm ==" % secs)
	main.new_soul(4747)
	await frames(30)
	_seasoned()
	for rid: String in REALMS:
		main.travel(rid, "town" if rid != "town" else "citadel")
		await frames(30)
		if main.board_ui.visible:
			main.board_ui.close()
		_use_player()
		p.refresh_stats(true)
		print("-- %s" % rid)
		await _play(rid, secs * 60)
		_check_scene(rid)


func _play(rid: String, ticks: int) -> void:
	var a: Region = main.place
	var kinds: Array = []
	for sp: Variant in a.spawn_list():
		var k := String((sp as Array)[0])
		if not Bestiary.is_boss(k) and k != "drill" and not kinds.has(k):
			kinds.append(k)
	if kinds.is_empty():
		kinds = ["husk"]
	var stuck_state := ""
	var stuck_t := 0
	var next_act := 0
	var hold_block := 0
	for t in range(ticks):
		if not is_instance_valid(main.place) or main.place != a:
			# died and came back, or travelled: pick the new place up
			a = main.place
			_use_player()
		if p == null or not is_instance_valid(p):
			_use_player()
		# the world comes at it
		if t % 240 == 10 and a.enemies_alive().size() < 8:
			for i in range(3):
				var ang := _rng.randf() * TAU
				var at := p.global_position + Vector3(cos(ang), 0, sin(ang)) * _rng.randf_range(5.0, 10.0)
				var e: Enemy = a._spawn(String(kinds[_rng.randi() % kinds.size()]), at)
				e.wake(p)
		if a.weather != null and t % (ticks / 5) == 30:
			a.weather.set_kind(String(Weather.KINDS[(t / (ticks / 5)) % Weather.KINDS.size()]))
		if a.weather != null and a.weather.kind == "storm" and t % 120 == 60:
			a.weather.strike_at(p.global_position + Vector3(_rng.randf_range(-6, 6), 0, _rng.randf_range(-6, 6)), 0.5)
		if a.play != null and t == ticks / 8 and not a.play.stones.is_empty() and a.events != null and a.events.ev.is_empty():
			a.play.start_challenge(t % a.play.stones.size())
		if a.play != null and t % 300 == 150:
			for ci in range(a.play.chests.size()):
				a.play.open_chest(ci)
			for bi in range(mini(4, a.play.breakables.size())):
				a.play.break_at(bi)
			if not a.play.folk.is_empty():
				a.play.talk(t % a.play.folk.size())
		if t == ticks / 3:
			main.soul.flags["clock"] = 0.75
		if t == ticks * 5 / 6:
			main.soul.flags["clock"] = 0.2
		if t == ticks / 5 and a.events != null and a.region_id != "undercroft":
			a.events.start("raid")
		if t == ticks / 2 and a.events != null and a.region_id != "undercroft":
			if not a.events.ev.is_empty():
				a.events.finish(false)
			a.events.start("storm")
		if t == ticks * 3 / 4 and a.events != null and a.region_id != "undercroft" and a.region_id != "town":
			if not a.events.ev.is_empty():
				a.events.finish(false)
			a.events.start("march")
		if t == ticks * 2 / 3:
			# a great enemy of this realm, if it has one
			var bl: Array = a.boss_list()
			if not bl.is_empty():
				var bk := String((bl[0] as Array)[0])
				var b: Enemy = a._spawn(bk, p.global_position + p.forward() * 8.0, a.level_base + 2)
				b.wake(p)
		# a random hand on the keys
		p.intent.clear_presses()
		if hold_block > 0:
			hold_block -= 1
			p.intent.block = true
		else:
			p.intent.block = false
		if t >= next_act:
			next_act = t + _rng.randi_range(4, 18)
			actions += 1
			var ang2 := _rng.randf() * TAU
			p.intent.move = Vector2(cos(ang2), sin(ang2)) if _rng.randf() < 0.7 else Vector2.ZERO
			p.intent.sprint = _rng.randf() < 0.3
			p.intent.jump_held = _rng.randf() < 0.2
			match _rng.randi() % 16:
				0, 1, 2, 3: p.intent.light = true
				4: p.intent.heavy = true
				5: p.intent.dash = true
				6: p.intent.jump = true
				7: p.intent.crit = true
				8:
					p.intent.block_pressed = true
					hold_block = _rng.randi_range(5, 40)
				9: p.intent.tech = _rng.randi() % 4
				10: p.intent.grip = true
				11: p.intent.carry = true
				12: p.intent.interact = true
				13: p.intent.lock = true
				14, 15: p.intent.race = true
		# close any screen the bot opened by walking into a board or giver
		if main.board_ui.visible:
			main.board_ui.close()
		if get_tree().paused:
			main._resume()
		await get_tree().physics_frame
		# invariants
		if p != null and is_instance_valid(p):
			var pos := p.global_position
			if not (is_finite(pos.x) and is_finite(pos.y) and is_finite(pos.z)):
				problem("%s: player position is not a number" % rid)
				p.global_position = Vector3(0, 5, 0)
			elif absf(pos.x) > a.bounds + 15.0 or absf(pos.z) > a.bounds + 15.0 or pos.y < a.height_at(pos.x, pos.z) - 3.0:
				problem("%s: player left the world at (%.0f, %.0f, %.0f)" % [rid, pos.x, pos.y, pos.z])
				p.global_position = Vector3(0, a.height_at(0, 0) + 1.0, 0)
			if not p.alive:
				deaths += 1
				await frames(240)
				_use_player()
				continue
			var st := "%d/%s" % [p.state, p.busy_kind]
			if st == stuck_state:
				stuck_t += 1
				if stuck_t == 60 * 12 and p.state != Actor.St.FREE:
					problem("%s: player stuck in state %s for 12 s" % [rid, st])
			else:
				stuck_state = st
				stuck_t = 0
			if p.hp < p.max_hp * 0.2:
				p.hp = p.max_hp
	if a.events != null and not a.events.ev.is_empty():
		a.events.finish(false)


func _check_scene(rid: String) -> void:
	var a: Region = main.place
	var n_actors := a.actors.size()
	if n_actors > 120:
		problem("%s: %d actors left in the scene" % [rid, n_actors])
	var nodes := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	print("   %s: %d actors, %d nodes" % [rid, n_actors, int(nodes)])
