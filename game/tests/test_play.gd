extends Node
## Plays the real game with scripted buttons, headless.
## godot --headless --fixed-fps 60 --path game res://tests/TestPlay.tscn -- --no-title

var passed := 0
var failed := 0
var main: Node
var p: Player


var _ticks := 0


func _physics_process(_delta: float) -> void:
	_ticks += 1
	if _ticks > 60 * 900:
		print("play: WATCHDOG after %d ticks; %d passed, %d failed" % [_ticks, passed, failed])
		get_tree().quit(2)


func ok(cond: bool, what: String) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		print("  FAIL  ", what)


func frames(n: int) -> void:
	for i in range(n + 1):
		await get_tree().physics_frame


func press(field: String, value: Variant = true) -> void:
	var who := p
	who.intent.set(field, value)
	await frames(1)
	if is_instance_valid(who):
		who.intent.set(field, -1 if field == "tech" else false)


func clear_enemies() -> void:
	for a in main.place.actors.duplicate():
		if a != main.place.player and is_instance_valid(a):
			main.place.actors.erase(a)
			a.queue_free()
	(main.place as Region).boss = null
	(main.place as Region).bosses.clear()


func husk_in_front(dist: float, dormant: bool = true, kind: String = "husk") -> Enemy:
	var a: Region = main.place
	var at := p.global_position + p.forward() * dist
	var e := a._spawn(kind, at)
	e.dormant = dormant
	e.passive = dormant
	e.face_now(e.flat_to(p.global_position))
	return e


func kill(e: Enemy) -> void:
	var guard := 0
	while is_instance_valid(e) and e.alive and not e.yielded and guard < 200:
		guard += 1
		main.place.strike(p, e, {"kind": "light", "dmg": 60.0, "posture": 5.0})
		await frames(1)

func clear_all_bosses() -> void:
	clear_enemies()


func use_player() -> void:
	p = main.place.player
	p.scripted = true
	p.intent = Player.Intent.new()


func go(x: float, z: float, settle: int = 20) -> void:
	var a: Region = main.place
	p.global_position = Vector3(x, a.height_at(x, z) + 0.3, z)
	p.velocity = Vector3.ZERO
	await frames(settle)


## Guards a live enemy's blows until `n` more parries land in `counter`.
func parry_vs(e: Enemy, n: int, counter: Callable) -> int:
	var start: int = counter.call()
	var guard := 0
	while guard < 1800 and int(counter.call()) < start + n and p.alive and is_instance_valid(e) and e.alive:
		guard += 1
		await get_tree().physics_frame
		if p.state == Actor.St.FREE or p.state == Actor.St.BLOCK:
			p.face_now(p.flat_to(e.global_position))
		if e.flat_to(p.global_position).length() > 3.0 and e.state == Actor.St.FREE:
			e.global_position = p.global_position + p.forward() * 2.0
		if e.state == Actor.St.ATTACK and not e.move_hit and bool(e.move.get("parryable", true)) and String(e.move.get("type", "strike")) == "strike":
			if float(e.move["startup"]) - e.state_t <= 0.1 and not p.intent.block:
				p.intent.block = true
				p.intent.block_pressed = true
				await get_tree().physics_frame
				await get_tree().physics_frame
				p.intent.block_pressed = false
		elif e.state == Actor.St.ATTACK and not bool(e.move.get("parryable", true)) and p.state == Actor.St.FREE and p.dash_cd_t <= 0.0 and float(e.move["startup"]) - e.state_t <= 0.12:
			p.intent.block = false
			p.intent.move = Vector2(1, 0)
			await press("dash")
			p.intent.move = Vector2.ZERO
		elif p.intent.block and e.state != Actor.St.ATTACK:
			p.intent.block = false
	p.intent.block = false
	p.hp = p.max_hp
	return guard


## Dashes through a live enemy's blows until `n` more perfect dodges land.
func slip_vs(e: Enemy, n: int, counter: Callable) -> int:
	var start: int = counter.call()
	var guard := 0
	while guard < 1800 and int(counter.call()) < start + n and p.alive and is_instance_valid(e) and e.alive:
		guard += 1
		await get_tree().physics_frame
		if p.state == Actor.St.FREE:
			p.face_now(p.flat_to(e.global_position))
		if e.flat_to(p.global_position).length() > 3.0 and e.state == Actor.St.FREE:
			e.global_position = p.global_position + p.forward() * 2.0
		if e.state == Actor.St.ATTACK and not e.move_hit and float(e.move["startup"]) - e.state_t <= 0.06 and p.state == Actor.St.FREE and p.dash_cd_t <= 0.0:
			p.intent.move = Vector2(1, 0)
			await press("dash")
			p.intent.move = Vector2.ZERO
	p.hp = p.max_hp
	return guard


func breathe(count: int, hold: int) -> void:
	for i in range(count):
		p.intent.jump_held = true
		await frames(hold)
		p.intent.jump_held = false
		await frames(25)


func force_kill(e: Enemy) -> void:
	var guard := 0
	while is_instance_valid(e) and e.alive and not e.yielded and guard < 400:
		guard += 1
		p.invuln = 1.0
		e.invuln = 0.0
		main.place.strike(p, e, {"kind": "light", "dmg": 200.0, "posture": 2.0})
		await frames(1)
	p.invuln = 0.0


func _ready() -> void:
	Fx.quiet = true
	Sfx.muted = true
	var scene: PackedScene = load("res://main.tscn")
	main = scene.instantiate()
	add_child(main)
	main.save_path = "user://test_play_soul.json"
	if FileAccess.file_exists(main.save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	await run()
	print("play: %d passed, %d failed" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)


func run() -> void:
	print("== play ==")
	# folk, crates, chests and the rest pay shards and essence on their own;
	# they are off until their own section below
	WorldPlay.enabled = false
	main.new_soul(12345)
	# the sky holds still unless a test turns it
	main.soul.flags["weather"] = "clear"
	main.soul.flags["weather_left"] = 1.0e9
	use_player()
	clear_enemies()
	await frames(40)
	var a: Region = main.place
	var s: Soul = main.soul
	ok(a is Town, "a new soul wakes in the living world, in Calder Town")
	ok(s.form_name() == "Unwrit" and s.release.is_empty(), "with no strain and no named blade")
	ok(String(s.flags.get("chapter", "")) == "prologue" and int(s.flags.get("tether", 0)) == 7, "in the prologue, with seven links of tether")
	ok(p.rig.spec.get("tether", 0) == 7, "and the chain hangs from its chest")
	ok(p.is_on_floor(), "standing on the ground (y %.2f, ground %.2f)" % [p.global_position.y, a.height_at(p.global_position.x, p.global_position.z)])
	ok(a.objective().contains("Lingering Board"), "the story says where to start (%s)" % a.objective())
	ok(a.markers().size() >= 8, "the compass has things to point at (%d)" % a.markers().size())
	var town: Town = a
	ok(town.walkers.size() >= 20 and town.cars.size() >= 10, "the living walk the pavements and drive the roads (%d, %d)" % [town.walkers.size(), town.cars.size()])
	var w0: Vector3 = (town.walkers[0]["rig"] as Node3D).position
	var c0: Vector3 = (town.cars[0]["mesh"] as Node3D).position
	await frames(30)
	ok((town.walkers[0]["rig"] as Node3D).position.distance_to(w0) > 0.3 and (town.cars[0]["mesh"] as Node3D).position.distance_to(c0) > 2.0, "and they move")

	# sprint
	var sz := p.global_position.z
	p.intent.move = Vector2(0, 1)
	p.intent.sprint = true
	await frames(60)
	p.intent.sprint = false
	p.intent.move = Vector2.ZERO
	ok(sz - p.global_position.z > 10.0, "holding the run key runs (%.1f m in a second)" % (sz - p.global_position.z))
	await frames(20)
	await go(8.5, 44.0)

	# move
	var z0 := p.global_position.z
	p.intent.move = Vector2(0, 1)
	await frames(60)
	p.intent.move = Vector2.ZERO
	ok(z0 - p.global_position.z > 4.0, "W walks north (%.1f m)" % (z0 - p.global_position.z))
	ok(p.rig.clip_name == "run", "and plays the run")
	await frames(20)

	# dash
	var x0 := p.global_position
	p.intent.move = Vector2(1, 0)
	await press("dash")
	ok(p.state == Actor.St.DASH and p.invuln > 0.0, "dash starts with a moment of safety")
	await frames(20)
	p.intent.move = Vector2.ZERO
	ok(p.state == Actor.St.FREE and p.global_position.distance_to(x0) > 3.5, "dash covers ground (%.1f m)" % p.global_position.distance_to(x0))
	ok(int(Fx.spawned.get("ghost", 0)) >= 3, "and leaves afterimages")
	await frames(40)

	# the string: five cuts, and a finisher three ways
	ok(p.lights().size() == 5, "a blade string is five cuts long")
	ok(Controls.label("dash") == "Q" and Controls.label("sprint") == "SHIFT" and Controls.label("shiftlock") == "CTRL", "Q dashes, SHIFT runs, CTRL toggles shift lock")
	ok(Player.shift_lock, "shift lock starts on")
	p.face_now(Vector3.FORWARD)
	var fin_t := husk_in_front(2.2)
	fin_t.max_hp = 9999.0
	fin_t.hp = 9999.0
	var a_fin: Region = main.place
	fin_t.global_position.y = a_fin.height_at(fin_t.global_position.x, fin_t.global_position.z)
	var hx0 := fin_t.global_position
	a_fin.strike(p, fin_t, p._finisher(p.light_move(4), "out"))
	await frames(12)
	ok(fin_t.global_position.distance_to(hx0) > 2.0, "the last cut knocks them flying (%.1f m)" % fin_t.global_position.distance_to(hx0))
	await frames(40)
	fin_t.set_state(Actor.St.FREE)
	fin_t.invuln = 0.0
	fin_t.posture = 0.0
	fin_t.global_position = p.global_position + p.forward() * 2.0
	await frames(2)
	a_fin.strike(p, fin_t, p._finisher(p.light_move(4), "up"))
	await frames(2)
	ok(fin_t.velocity.y > 4.0 and p.velocity.y > 4.0, "jump on the last cut launches them, and you go up after (%.1f / %.1f)" % [fin_t.velocity.y, p.velocity.y])
	await frames(60)
	clear_enemies()
	# a feint
	p.set_state(Actor.St.FREE)
	p.start_attack(p.heavy_move())
	await frames(2)
	p.intent.block = true
	p.intent.block_pressed = true
	await frames(2)
	p.intent.block_pressed = false
	ok(p.state == Actor.St.BLOCK, "guarding in a heavy's wind-up feints it")
	p.intent.block = false
	await frames(20)
	# the critical: red, unguardable, on a cooldown
	p.set_state(Actor.St.FREE)
	p.crit_cd = 0.0
	ok(p.try_crit() and bool(p.move.get("crit", false)) and not bool(p.move.get("blockable", true)), "T swings a critical no guard stops")
	ok(not p.try_crit() and p.crit_cd > 8.0, "and it waits on its cooldown")
	await frames(60)
	# the evasive: only while being hit
	p.set_state(Actor.St.FREE)
	p.evasive_cd = 0.0
	ok(not p.evasive(), "the evasive does nothing when you are not being hit")
	var ev_foe := husk_in_front(2.0)
	p.set_state(Actor.St.HIT, 0.5)
	var ev_d0 := ev_foe.global_position.distance_to(p.global_position)
	ok(p.evasive() and p.invuln > 0.3 and p.state == Actor.St.DASH, "being hit, Q bursts out: safe and dashing")
	await frames(12)
	ok(ev_foe.global_position.distance_to(p.global_position) > ev_d0 + 1.0, "and throws the near ones back")
	p.set_state(Actor.St.HIT, 0.5)
	ok(not p.evasive() and p.evasive_cd > 10.0, "then it is spent for a while")
	await frames(40)
	clear_enemies()
	# spirit sense: hold Z, feel what is near, at a cost
	var sf := husk_in_front(12.0)
	sf.level = 1
	var an0 := p.anima
	p.intent.sense = true
	await frames(30)
	var sensed := 0
	for mk: Variant in main.place.markers():
		if String((mk as Array)[2]) == "sensed":
			sensed += 1
	ok(p.sensing and sensed >= 1 and p.anima < an0, "holding Z senses enemies near, for spirit energy (%d felt)" % sensed)
	ok(p.threat_of(sf) == "weaker" or p.threat_of(sf) == "even", "and reads how they stand against you (%s)" % p.threat_of(sf))
	p.intent.sense = false
	await frames(3)
	ok(not p.sensing, "letting go stops it")
	clear_enemies()
	# race powers on X, one strain at a time (put back after)
	var rk_pos := p.global_position
	var rk_profile: Dictionary = s.profile.to_dict()
	var rk_primary := s.primary
	var rk_secondary := s.secondary
	s.secondary = ""
	p.anima = p.max_anima
	s.primary = ""
	p.race_cd = 0.0
	ok(not p.try_race_art(), "before awakening, X does nothing")
	s.primary = "vigil"
	p.refresh_stats()
	var pw0 := float(Stats.compute(Soul.from_dict(s.to_dict()))["parry_window"])
	p.face_now(Vector3.FORWARD)
	var bt := husk_in_front(4.0)
	bt.max_hp = 9999.0
	bt.hp = 9999.0
	ok(p.try_race_art() and p.busy_kind == "bind", "a Reaper's X casts a Binding Art")
	await frames(30)
	ok(bt.state == Actor.St.BUSY and p.race_cd > 10.0, "and it pins the enemy in place")
	clear_enemies()
	p.set_state(Actor.St.FREE)
	p.global_position = rk_pos
	await frames(2)
	s.primary = "maw"
	p.refresh_stats()
	p.race_cd = 0.0
	p.anima = p.max_anima
	ok(p.try_race_art() and p.hide_t > 5.0, "a Devourer's X hardens its hide")
	var hd_hp := p.hp
	var hd_foe := husk_in_front(2.0)
	main.place.strike(hd_foe, p, {"kind": "enemy", "dmg": 20.0, "posture": 5.0})
	ok(hd_hp - p.hp < 13.0 and p.state != Actor.St.HIT, "less harm, and no flinch (%.1f taken)" % (hd_hp - p.hp))
	clear_enemies()
	p.hide_t = 0.0
	p.hp = p.max_hp * 0.5
	p._since_hurt = 6.0
	var rg0 := p.hp
	await frames(30)
	ok(p.hp > rg0, "and a Devourer out of the fight knits back")
	p.set_state(Actor.St.FREE)
	p.global_position = rk_pos
	await frames(2)
	s.primary = "lumen"
	p.refresh_stats()
	p.race_cd = 0.0
	p.anima = p.max_anima
	var rail0 := p.global_position
	ok(p.try_race_art() and p.volley_t > 2.0, "an Archer's X rides a rail of light")
	await frames(24)
	ok(p.global_position.distance_to(rail0) > 6.0, "a long way (%.1f m)" % p.global_position.distance_to(rail0))
	ok(int(p.light_move(0).get("count", 1)) == 3 or p.kit() != "bow", "and the next arrows fly three at a time")
	p.volley_t = 0.0
	p.set_state(Actor.St.FREE)
	p.global_position = rk_pos
	await frames(2)
	s.primary = "relic"
	p.refresh_stats()
	p.race_cd = 0.0
	p.anima = p.max_anima
	p.face_now(Vector3.FORWARD)
	var gt := husk_in_front(12.0)
	gt.max_hp = 9999.0
	gt.hp = 9999.0
	var gp0 := p.global_position
	ok(p.try_race_art() and p.busy_kind == "grapple", "a Binder's X throws its chain")
	await frames(40)
	ok(p.global_position.distance_to(gp0) > 6.0 and gt.hp < 9999.0, "and zips in to strike (%.1f m)" % p.global_position.distance_to(gp0))
	clear_enemies()
	# the power grows: stages, a graft, the hand that uses it
	var rk_grade := s.grade
	s.primary = "vigil"
	s.secondary = ""
	s.grade = 5
	var art1: Dictionary = p.race_art()
	s.grade = 3
	var art2: Dictionary = p.race_art()
	s.grade = 1
	var art3: Dictionary = p.race_art()
	ok(int(art1["tier"]) == 1 and String(art2["name"]).ends_with(" II") and String(art3["name"]).ends_with(" III"), "the power takes new forms as the soul climbs (%s / %s)" % [String(art2["name"]), String(art3["name"])])
	var word := String((AbilityForge.QUIRK[s.profile.dominant()] as Dictionary)["word"])
	ok(String(art1["name"]).begins_with(word), "and is named for the hand that uses it (%s)" % String(art1["name"]))
	s.secondary = "maw"
	var art_h: Dictionary = p.race_art()
	ok(String(art_h["name"]).contains("Devouring") and String(art_h["infusion"]) == "maw", "a graft fuses into it (%s)" % String(art_h["name"]))
	p._art_name = String(art3["name"])
	p._note_art_change()
	ok(String(main.hud.seen.get("level", "")).begins_with("Your power deepens"), "and the change is announced")
	# II binds two
	s.secondary = ""
	s.grade = 3
	p.set_state(Actor.St.FREE)
	p.race_cd = 0.0
	p.anima = p.max_anima
	p.face_now(Vector3.FORWARD)
	var b1 := husk_in_front(4.0)
	var b2 := husk_in_front(5.5)
	for bb: Enemy in [b1, b2]:
		bb.max_hp = 9999.0
		bb.hp = 9999.0
	ok(p.try_race_art(), "a second-form Binding Art")
	await frames(30)
	ok(b1.state == Actor.St.BUSY and b2.state == Actor.St.BUSY, "binds two")
	clear_enemies()
	# an Archer's second form holds two charges
	p.set_state(Actor.St.FREE)
	s.primary = "lumen"
	p.race_cd = 0.0
	p.race_charges = 2
	p.anima = p.max_anima
	ok(p.try_race_art(), "a rail")
	await frames(24)
	p.set_state(Actor.St.FREE)
	ok(p.try_race_art() and p.race_charges == 0, "and another straight after, from its second charge")
	await frames(24)
	# a Devouring infusion heals
	p.set_state(Actor.St.FREE)
	s.primary = "lumen"
	s.secondary = "maw"
	p.race_cd = 0.0
	p.race_charges = 2
	p.anima = p.max_anima
	p.hp = p.max_hp * 0.5
	var inf_hp := p.hp
	ok(p.try_race_art() and p.hp > inf_hp, "a power fused with Devourer heals you")
	await frames(24)
	p.set_state(Actor.St.FREE)
	s.grade = rk_grade
	s.primary = rk_primary
	s.secondary = rk_secondary
	s.profile = Profile.from_dict(rk_profile)
	p.global_position = rk_pos
	p.refresh_stats()
	p.set_state(Actor.St.FREE)
	await frames(10)
	# the second jump
	p.set_state(Actor.St.FREE)
	await frames(20)
	await press("jump")
	var dj_guard := 0
	while dj_guard < 60 and (p.is_on_floor() or p.velocity.y > 6.0):
		dj_guard += 1
		await frames(1)
	await press("jump")
	await frames(1)
	ok(p.air_jumps == 0 and p.velocity.y > 7.0, "a second jump in the air (%.1f up)" % p.velocity.y)
	await frames(90)
	ok(p.is_on_floor() and p.air_jumps == 1, "and it comes back on landing")
	# a wall bounce: knocked into the flats' wall, the body rebounds
	var wb_home := p.global_position
	var wa: Region = main.place
	p.global_position = Vector3(-70.0, wa.height_at(-70.0, -54.5) + 0.3, -54.5)
	p.face_now(Vector3(0, 0, -1))
	await frames(4)
	var wb := husk_in_front(2.6)
	wb.max_hp = 9999.0
	wb.hp = 9999.0
	wa.strike(p, wb, p._finisher(p.light_move(4), "out"))
	var wb_guard := 0
	while wb_guard < 40 and not wb._bounced:
		wb_guard += 1
		await frames(1)
	ok(wb._bounced and wb.hp < 9999.0, "knocked into a wall, a body bounces off it")
	await frames(30)
	clear_enemies()
	p.global_position = wb_home
	await frames(10)
	# knocked, grip, carry, throw (kills and loot here are put back after,
	# so the ledger checks further on count only their own)
	var kills_before: float = main.soul.profile.count("kills")
	p.set_state(Actor.St.FREE)
	p.face_now(Vector3.FORWARD)
	var kn := husk_in_front(1.8)
	kn.hp = 1.0
	var ka: Region = main.place
	ka.strike(p, kn, p.light_move(0))
	await frames(3)
	ok(kn.alive and kn.knocked and kn.state == Actor.St.BUSY, "an ordinary blow knocks an enemy down instead of killing it")
	var sw0 := p.swell
	ok(p.try_grip() and p.busy_kind == "grip", "B grips a knocked enemy")
	await frames(90)
	ok(not kn.alive, "and the grip finishes it")
	var _sw := sw0
	await frames(10)
	clear_enemies()
	p.set_state(Actor.St.FREE)
	var kc := husk_in_front(1.6)
	kc.hp = 1.0
	ka.strike(p, kc, p.light_move(0))
	await frames(3)
	ok(p.try_carry() and p.carrying == kc and kc.carried_by == p, "V carries a knocked enemy over the shoulder")
	var throw_mark := husk_in_front(6.0)
	throw_mark.max_hp = 9999.0
	throw_mark.hp = 9999.0
	await frames(6)
	p.throw_carried()
	ok(p.carrying == null and kc.thrown_t > 0.0, "and a cut throws it")
	var kc_guard := 0
	while kc_guard < 90 and kc.thrown_t > 0.0:
		kc_guard += 1
		await frames(1)
	ok(throw_mark.hp < 9999.0, "the thrown body hits what it is thrown at")
	ok(not kc.alive, "and a knocked body does not survive the landing")
	await frames(10)
	clear_enemies()
	var kr := husk_in_front(2.0)
	kr.hp = 1.0
	ka.strike(p, kr, p.light_move(0))
	await frames(3)
	kr.knocked_t = 0.05
	await frames(10)
	ok(kr.alive and not kr.knocked and kr.hp > 1.0, "left alone, a knocked enemy gets back up, hurt")
	clear_enemies()
	# a finisher kills outright, and the body flies on
	var kf := husk_in_front(2.0)
	kf.hp = 1.0
	var kf0 := kf.global_position
	ka.strike(p, kf, p._finisher(p.light_move(4), "out"))
	await frames(14)
	ok(not kf.alive and kf.global_position.distance_to(kf0) > 1.5, "a finisher kills outright, and the body keeps flying (%.1f m)" % kf.global_position.distance_to(kf0))
	await frames(10)
	clear_enemies()
	# a pack takes turns: never more than two press at once
	var pack: Array = []
	for i in range(4):
		var a_ang := TAU * float(i) / 4.0
		var pe: Enemy = ka._spawn("husk", p.global_position + Vector3(cos(a_ang), 0, sin(a_ang)) * 4.0)
		pe.max_hp = 9999.0
		pe.hp = 9999.0
		pe.wake(p)
		pack.append(pe)
	var most := 0
	for t in range(240):
		p.hp = p.max_hp
		if p.state == Actor.St.HIT and p.state_t > 0.3:
			p.set_state(Actor.St.FREE)
		var n_att := 0
		for pe: Variant in pack:
			if is_instance_valid(pe) and (pe as Enemy).state == Actor.St.ATTACK:
				n_att += 1
		most = maxi(most, n_att)
		await frames(1)
	ok(most >= 1 and most <= 2, "a pack takes turns: at most two attack at once (%d)" % most)
	clear_enemies()
	await frames(5)
	# a great enemy: the grab, the evasive out of it, the rage, the winded pause
	p.set_state(Actor.St.FREE)
	var gb: Enemy = ka._spawn("thane", p.global_position + p.forward() * 4.0, 10)
	gb.dormant = true
	gb.passive = true
	gb.hp = gb.max_hp * 0.45
	gb.set_state(Actor.St.FREE)
	gb._check_phase()
	var has_grab := false
	for mv: Variant in gb.moves:
		if String((mv as Dictionary).get("id", "")) == "grab":
			has_grab = true
	ok(gb.phase == 2 and has_grab, "past half, a great enemy learns to grab")
	ka.strike(gb, p, {"kind": "enemy", "dmg": 10.0, "posture": 0.0, "grab": true, "blockable": false, "parryable": false})
	await frames(2)
	ok(p._grabber == gb and p.state == Actor.St.HIT, "a grab holds you")
	p.evasive_cd = 0.0
	ok(p.evasive() and p._grabber == null, "and the evasive breaks it")
	await frames(30)
	gb.set_state(Actor.St.FREE)
	gb.hp = gb.max_hp * 0.2
	gb._check_phase()
	ok(gb.enraged, "at a quarter it is enraged")
	gb.set_state(Actor.St.FREE)
	gb._swings = 4
	gb._check_phase()
	ok(gb.state == Actor.St.BUSY and gb._swings == 0, "and after four swings it stops, winded")
	clear_all_bosses()
	main.soul.profile.n["kills"] = kills_before
	for ln: Variant in ka._loot:
		if is_instance_valid(ln):
			(ln as Node).queue_free()
	ka._loot.clear()

	# jump and air cut
	await press("jump")
	await frames(6)
	ok(not p.is_on_floor(), "jump leaves the ground")
	await press("light")
	await frames(2)
	ok(p.state == Actor.St.ATTACK and String(p.move.get("kind", "")) == "air", "a cut in the air is an air cut")
	await frames(60)

	# a three-cut combo on a still husk
	p.face_now(Vector3.FORWARD)
	var h := husk_in_front(1.9)
	await frames(5)
	var hp0 := h.hp
	for i in range(3):
		await press("light")
		await frames(22)
	ok(h.hp < hp0 - 15.0, "three light cuts land (%.0f -> %.0f)" % [hp0, h.hp])
	ok(main.soul.profile.count("light_hits") >= 2.0, "the ledger counts them")
	ok(float(main.soul.affinity["vigil"]) > 0.0, "bladework leans toward Vigil")
	ok(int(Fx.spawned.get("slash", 0)) >= 3 and int(Sfx.played.get("whoosh", 0)) >= 3, "each cut has a slash and a sound")
	await frames(40)

	# heavy
	hp0 = h.hp
	await press("heavy")
	await frames(70)
	ok(h.hp < hp0 or not h.alive, "a heavy cut lands")
	ok(main.soul.profile.count("heavy_hits") >= 1.0, "and is counted as heavy")

	# kill, then devour
	await kill(h)
	await frames(10)
	ok(not h.alive and h.remnant, "a fallen husk leaves a remnant")
	ok(main.soul.profile.count("kills") == 1.0 and main.soul.essence > 0.0, "the kill gives essence (%d kills, %.0f essence)" % [int(main.soul.profile.count("kills")), main.soul.essence])
	p.global_position = h.global_position + Vector3(0, 0.1, 1.2)
	await frames(10)
	ok(a.prompt().begins_with("E  Devour"), "the prompt offers to devour or send on")
	p.hp = p.max_hp * 0.5
	await press("interact")
	await frames(70)
	ok(main.soul.profile.count("devours") == 1.0 and float(main.soul.affinity["maw"]) >= 6.0, "devouring feeds the Maw")
	ok(p.hp > p.max_hp * 0.6, "and heals")
	ok(not is_instance_valid(h) or h.is_queued_for_deletion(), "the remnant is gone")

	# send on
	p.face_now(Vector3.FORWARD)
	var h2 := husk_in_front(1.8)
	await kill(h2)
	await frames(10)
	p.global_position = h2.global_position + Vector3(0, 0.1, 1.2)
	await frames(6)
	var lumen0 := float(main.soul.affinity["lumen"])
	await press("send")
	await frames(70)
	ok(float(main.soul.affinity["lumen"]) > lumen0, "sending a soul on leans toward Lumen and Vigil")

	# a real parry against a real swing
	await frames(20)
	p.face_now(Vector3.FORWARD)
	var h3 := husk_in_front(2.0, false)
	var parried := false
	var guard := 0
	while guard < 900 and not parried:
		guard += 1
		await get_tree().physics_frame
		if not is_instance_valid(h3) or not h3.alive:
			break
		p.face_now(p.flat_to(h3.global_position))
		if h3.state == Actor.St.ATTACK and not h3.move_hit and float(h3.move["startup"]) - h3.state_t <= 0.1 and not p.intent.block:
			p.intent.block = true
			p.intent.block_pressed = true
			await get_tree().physics_frame
			await get_tree().physics_frame
			p.intent.block_pressed = false
		elif p.intent.block and h3.state != Actor.St.ATTACK:
			p.intent.block = false
		parried = main.soul.profile.count("parries") >= 1.0
	p.intent.block = false
	ok(parried, "a guard raised as the blow lands is a parry (after %d ticks)" % guard)
	ok(h3.posture > 0.0 or h3.state == Actor.St.HIT or h3.state == Actor.St.STAGGER, "the parried husk's stance suffers")
	ok(p.riposte_t > 0.0, "and the next cut is a riposte")
	ok(int(Sfx.played.get("parry", 0)) >= 1, "with the parry sound")

	# a held guard is only a block
	h3.posture = 0.0
	var blocks0: float = main.soul.profile.count("blocks")
	p.intent.block = true
	guard = 0
	var taken0: float = main.soul.profile.count("hits_taken")
	while guard < 900 and main.soul.profile.count("blocks") == blocks0 and main.soul.profile.count("hits_taken") == taken0:
		guard += 1
		await get_tree().physics_frame
		if is_instance_valid(h3):
			p.face_now(p.flat_to(h3.global_position))
	p.intent.block = false
	ok(main.soul.profile.count("blocks") > blocks0, "a guard held early only blocks")

	# a perfect dodge
	var dodged := false
	guard = 0
	while guard < 900 and not dodged:
		guard += 1
		await get_tree().physics_frame
		if not is_instance_valid(h3) or not h3.alive:
			break
		if p.state == Actor.St.FREE:
			p.face_now(p.flat_to(h3.global_position))
		if h3.state == Actor.St.ATTACK and not h3.move_hit and float(h3.move["startup"]) - h3.state_t <= 0.06 and p.state == Actor.St.FREE and p.dash_cd_t <= 0.0:
			p.intent.move = Vector2(1, 0)
			await press("dash")
			p.intent.move = Vector2.ZERO
		dodged = main.soul.profile.count("dodges") >= 1.0
	ok(dodged, "a dash through the blow is a perfect dodge (after %d ticks)" % guard)
	await kill(h3)
	await frames(30)

	# the first instinct
	ok(main.soul.profile.count("kills") == 3.0, "three kills (%d)" % int(main.soul.profile.count("kills")))
	ok(main.soul.techniques.size() == 1, "an instinct has surfaced: %s" % (String(main.soul.techniques[0]["name"]) if main.soul.techniques.size() > 0 else "none"))
	if main.soul.techniques.size() > 0:
		p.face_now(Vector3.FORWARD)
		var h4 := husk_in_front(2.2)
		await frames(5)
		var anima0 := p.anima
		await press("tech", 0)
		await frames(3)
		ok(p.tech_cd[0] > 0.0 and p.anima < anima0, "the technique costs anima and goes on cooldown")
		ok(main.soul.profile.count("tech_uses") == 1.0 and float(main.soul.affinity["relic"]) > 0.0, "and leans toward Relic")
		await frames(90)
		await kill(h4)
	await frames(20)


	# devouring rusts the tether
	ok(int(s.flags.get("tether", 0)) == 6, "the devour rusted one link of the tether (%d left)" % int(s.flags.get("tether", 0)))

	# loot
	clear_enemies()
	await go(8.5, 44.0)
	p.face_now(Vector3.FORWARD)
	var sh_before := s.shards
	var drops_seen := 0
	for i in range(8):
		var lh := husk_in_front(3.0)
		await force_kill(lh)
		await frames(2)
		drops_seen = maxi(drops_seen, a.loot_count())
	ok(s.shards > sh_before, "every kill pays shards (%d)" % (s.shards - sh_before))
	ok(drops_seen > 0, "and some leave materials on the ground")
	p.global_position += p.forward() * 3.0
	await frames(20)
	ok(a.loot_count() == 0 and int(s.materials.get("ash_bone", 0)) > 0, "walking over loot takes it (%d ash bone, %d left on the ground)" % [int(s.materials.get("ash_bone", 0)), a.loot_count()])
	clear_enemies()
	await go(8.5, 44.0)

	# the Lingering Board
	await go(14.0, 51.0)
	ok(a.prompt().begins_with("E  Read The Lingering Board"), "the Lingering Board stands by the memorial (%s)" % a.prompt())
	await press("interact")
	await frames(5)
	ok(main.board_ui.visible and main.board_ui.mode == "board" and a.paused_input, "it opens and holds the soul still")
	ok(main.board_ui.take(0) and main.board_ui.take(0) and main.board_ui.take(0), "its three notices can all be taken")
	ok(Quests.active(s).size() == 3, "three notices carried")
	main.board_ui.close()
	ok(not a.paused_input, "and closes")
	ok(a.objective().contains("Do what the Lingering Board asks"), "the story moves on")
	for i in range(5):
		p.face_now(Vector3.FORWARD)
		var hk := husk_in_front(2.5)
		await kill(hk)
		await frames(4)
	ok(Quests.is_ready(s, "p_strays"), "five strays put down (%d)" % Quests.progress(s, "p_strays"))
	clear_enemies()
	# levelling and the skill tree
	var lvl: int = main.soul.level
	main.grant_essence(600.0)
	ok(main.soul.level > lvl and main.soul.marks >= 4, "essence levels the soul (level %d, %d marks)" % [main.soul.level, main.soul.marks])
	var foe_hp0 := p.max_hp
	var dmg_before := float(p.stats["light_dmg"])
	main.lattice_ui.open(main.soul)
	var took := 0
	for br: String in ["blade", "body", "speed", "spirit"]:
		if main.lattice_ui.take(br + ".1"):
			took += 1
	main.lattice_ui.close()
	ok(took >= 3, "skill tree skills can be taken (%d)" % took)
	ok(p.max_hp != foe_hp0 or float(p.stats["light_dmg"]) != dmg_before or float(p.stats["parry_window"]) > 0.17, "and they change the body's numbers")

	# relic and stele
	var rel: Array = Town.RELICS[0]
	p.global_position = Vector3(float(rel[0]) + 1.0, a.height_at(float(rel[0]) + 1.0, float(rel[1])) + 0.2, float(rel[1]))
	await frames(20)
	ok(a.prompt() == "E  Remember", "a relic can be remembered")
	var relic0 := float(main.soul.affinity["relic"])
	await press("interact")
	await frames(70)
	ok(float(main.soul.affinity["relic"]) >= relic0 + 9.0 and bool(main.soul.flags.get("relic_town_0", false)), "remembering leans toward Relic")
	var st: Array = Town.STELES[0]
	p.global_position = Vector3(float(st[0]) + 1.6, a.height_at(float(st[0]) + 1.6, float(st[1])) + 0.2, float(st[1]))
	await frames(20)
	await press("interact")
	await frames(5)
	ok(String(main.hud.seen.get("stele", "")).begins_with("NOBODY HERE"), "a stele can be read")

	# the lingering dead
	p.global_position = Vector3(10.5, 0.3, 33.4)
	await frames(20)
	ok(a.prompt() == "E  Speak with the Reaper", "the Reaper can be spoken to (%s)" % a.prompt())
	await press("interact")
	await frames(5)
	ok(String(main.hud.seen.get("talk", "")).begins_with("the Reaper|"), "and she says who you are")
	await frames(30)
	await press("interact")
	await frames(5)
	ok(String(main.hud.seen.get("talk", "")).contains("tether"), "and then what the chain in its chest is")

	# people who ask: Mira's brother, and Pell's bones
	var q_keep: Dictionary = (Quests.state(s) as Dictionary).duplicate(true)
	s.flags["quests"] = {}
	var tw: Region = main.place
	var mi := -1
	var pi_ := -1
	for gi in range(tw.giver_list().size()):
		if String(tw.giver_list()[gi][3]) == "g_mira":
			mi = gi
		if String(tw.giver_list()[gi][3]) == "g_pell":
			pi_ = gi
	ok(mi >= 0 and tw.giver_state(mi) == "!", "Mira has something to ask (!)")
	tw._talk_cd = 0.0
	tw._talk_giver(mi)
	ok(main.board_ui.visible and main.board_ui.mode == "choice", "talking to her offers it")
	main.board_ui.choose(0)
	await frames(30)
	ok(Quests.active(s).has("g_mira_brother") and tw._lost.has("town_brother"), "accepting puts a lost soul out by the water")
	var lost_rig: Node3D = tw._lost["town_brother"]["rig"]
	p.global_position = lost_rig.global_position + Vector3(1.5, 0.3, 0)
	await frames(5)
	ok(tw.prompt() == "E  Take their hand", "the lost soul can be found")
	tw.interact()
	ok(bool(tw._lost["town_brother"]["following"]), "and follows when found")
	var mira_at: Vector3 = (tw._givers[mi] as Node3D).global_position
	p.global_position = mira_at + Vector3(2.0, 0.3, 2.0)
	var led := 0
	while led < 400 and not Quests.is_ready(s, "g_mira_brother"):
		led += 1
		await frames(1)
	ok(Quests.is_ready(s, "g_mira_brother") and tw.giver_state(mi) == "?", "led home, the notice is ready (?) after %d ticks" % led)
	var sh0 := s.shards
	tw._talk_cd = 0.0
	tw._talk_giver(mi)
	ok(Quests.times_done(s, "g_mira_brother") == 1 and s.shards > sh0, "and handing it in pays")
	s.materials["ash_bone"] = int(s.materials.get("ash_bone", 0)) + 8
	tw._talk_cd = 0.0
	tw._talk_giver(pi_)
	main.board_ui.choose(0)
	await frames(2)
	var bone0 := int(s.materials["ash_bone"])
	ok(tw.giver_state(pi_) == "?", "with the bones in hand, Pell's delivery is ready")
	tw._talk_cd = 0.0
	tw._talk_giver(pi_)
	ok(int(s.materials["ash_bone"]) == bone0 - 8 and Quests.times_done(s, "g_pell_bone") == 1, "and talking to him hands them over")
	s.flags["quests"] = q_keep
	await frames(5)

	# day and night
	await frames(3)
	ok(tw.daynight != null and tw.daynight.has_sky(), "Calder Town has a day and a night")
	var clk0 := float(s.flags.get("clock", 0.1))
	await frames(60)
	ok(float(s.flags.get("clock", 0.0)) > clk0, "the clock runs")
	s.flags["clock"] = 0.25
	tw.daynight.apply(0.25)
	var noon_e := tw.daynight.sun.light_energy
	var noon_top := tw.daynight.sky_mat.sky_top_color
	ok(DayNight.phase_name(0.25) == "Day" and tw.daynight.night() < 0.05, "noon is day")
	s.flags["clock"] = 0.75
	tw.daynight.apply(0.75)
	ok(DayNight.phase_name(0.75) == "Night" and tw.daynight.night() > 0.9, "midnight is night")
	ok(tw.daynight.sun.light_energy < noon_e * 0.5 and tw.daynight.sky_mat.sky_top_color.v < noon_top.v, "the light falls and the sky darkens")
	var lit_e := 0.0
	for key: Variant in Detail._lit_cache.keys():
		lit_e = float((Detail._lit_cache[key] as ShaderMaterial).get_shader_parameter("energy")) / float(key)
		break
	ok(lit_e > 1.8, "lamps and windows burn brighter (x%.1f)" % lit_e)
	var hidden := 0
	for wk: Variant in tw.walkers:
		if not ((wk as Dictionary)["rig"] as Node3D).visible:
			hidden += 1
	ok(hidden > tw.walkers.size() / 2, "most of the living go home (%d of %d)" % [hidden, tw.walkers.size()])
	ok(DayNight.phase_name(0.5) == "Dusk" and DayNight.phase_name(0.0) == "Dawn", "dawn and dusk between")
	s.flags["clock"] = 0.1
	tw.daynight.apply(0.1)
	var back := 0
	for wk: Variant in tw.walkers:
		if ((wk as Dictionary)["rig"] as Node3D).visible:
			back += 1
	ok(back == tw.walkers.size(), "and in the morning they are all back")

	# seasons and weather
	await frames(3)
	var days_keep := int(s.flags.get("days", 0))
	s.flags["days"] = 0
	ok(DayNight.season_name(s) == "Spring", "a new soul wakes in spring")
	s.flags["days"] = 9
	ok(DayNight.season_name(s) == "Winter" and DayNight.DAYS_PER_SEASON == 3, "three days a season: day 9 is winter")
	s.flags["days"] = 2
	s.flags["clock"] = 0.9999
	tw.daynight.tick(1.0)
	ok(int(s.flags["days"]) == 3 and DayNight.season_name(s) == "Summer", "midnight turns the day, and the third day turns the season")
	s.flags["days"] = 6
	s.flags["clock"] = 0.25
	tw.daynight.apply(0.25)
	var tint: Vector3 = Detail.ground_value("season_tint")
	ok(tint != null and tint.x > 1.1 and tint.z < 0.7, "autumn browns the grass")
	s.flags["days"] = 9
	tw.daynight.apply(0.25)
	ok(float(Detail.ground_value("snow")) >= 0.45, "and winter lays snow on open ground")
	ok(tw.weather != null, "Calder Town has weather")
	var wsoul := Soul.create(77)
	var seen_w := {}
	for season in range(4):
		for n in range(60):
			wsoul.flags["weather_n"] = n
			seen_w["%d:%s" % [season, Weather.roll(wsoul, season)]] = true
	ok(seen_w.has("3:snow") and not seen_w.has("3:rain") and not seen_w.has("3:storm"), "winter snows and never rains")
	ok(not seen_w.has("0:snow") and not seen_w.has("1:snow") and not seen_w.has("2:snow") and seen_w.has("1:storm"), "snow is winter's alone; summer storms")
	tw.weather.set_kind("snow", 1.0e9)
	tw.daynight.apply(0.25)
	ok(tw.weather.snow_fx.emitting and not tw.weather.rain_fx.emitting, "snow falls round you")
	ok(float(Detail.ground_value("snow")) >= 0.75, "and lies deeper while it falls")
	s.flags["days"] = 0
	tw.weather.tick(0.1)
	ok(tw.weather.kind == "clear", "snow does not outlast the winter")
	tw.weather.set_kind("rain", 1.0e9)
	ok(tw.weather.rain_fx.emitting, "rain falls round you")
	for i in range(30):
		tw.weather.tick(1.0)
	ok(tw.weather.wet > 0.9 and float(Detail.ground_value("wet")) > 0.9, "and the ground goes dark and glossy (wet %.2f)" % tw.weather.wet)
	tw.weather.set_kind("clear", 1.0e9)
	for i in range(30):
		tw.weather.tick(1.0)
	ok(tw.weather.wet > 0.2 and tw.weather.wet < 0.9, "after the rain it dries slowly (wet %.2f)" % tw.weather.wet)
	# fog: enemies see you from two-thirds as far
	clear_enemies()
	var wp := tw.player
	var looker: Enemy = tw._spawn("husk", wp.global_position + Vector3(13.0, 0, 0))
	tw.weather.set_kind("fog", 1.0e9)
	tw.weather.fog_k = 1.0
	ok(absf(tw.sight_scale() - 0.65) < 0.01, "fog cuts how far enemies see to 65%")
	await frames(20)
	ok(not looker.aggro, "a husk 13 m off does not notice you in fog")
	tw.weather.set_kind("clear", 1.0e9)
	tw.weather.fog_k = 0.0
	await frames(20)
	ok(looker.aggro, "and in clear air it does")
	clear_enemies()
	# a thunderstorm: warned strikes that hurt anyone inside the ring
	tw.weather.set_kind("storm", 1.0e9)
	ok(tw.weather.rain_fx.emitting and tw.weather.fog_k >= 0.0, "a thunderstorm brings rain")
	var struck: Enemy = tw._spawn("husk", wp.global_position + Vector3(20.0, 0, 4.0))
	struck.passive = true
	var shp := struck.hp
	var php := wp.hp
	var warns0 := int(Fx.spawned.get("warn", 0))
	tw.weather.strike_at(struck.global_position, 0.15)
	ok(int(Fx.spawned.get("warn", 0)) == warns0 + 1, "a ring on the ground warns where it will fall")
	ok(struck.hp == shp, "nothing is hurt until it falls")
	await frames(20)
	ok(struck.hp < shp - struck.max_hp * 0.2 or not struck.alive, "lightning tears into an enemy (%.0f to %.0f)" % [shp, struck.hp])
	ok(wp.hp == php, "and leaves you, 20 m off, alone")
	wp.invuln = 0.0
	var hurt_n := tw.weather.land(wp.global_position)
	ok(hurt_n >= 1 and wp.hp < php and wp.hp > php - wp.max_hp * 0.2, "standing in it costs you about an eighth of your vitality")
	wp.hp = wp.max_hp
	var strikes0 := tw.weather.strikes
	for i in range(20):
		tw.weather.tick(1.0)
	ok(tw.weather.strikes == strikes0, "no bolts fall on their own while the player is scripted")
	tw.weather.set_kind("clear", 1.0e9)
	tw.weather.fog_k = 0.0
	tw.weather.wet = 0.0
	s.flags["days"] = days_keep
	clear_enemies()
	await frames(5)

	# folk, crates, chests, orbs, challenge stones, the dummy, streaks, badges
	var keep_sh := s.shards
	var keep_ess := s.essence
	var keep_lv := s.level
	var keep_marks := s.marks
	var keep_kills: float = s.profile.count("kills")
	# the weather section's last bolt leaves the player staggered: let it pass
	wp.velocity = Vector3.ZERO
	wp.push = Vector3.ZERO
	await frames(60)
	WorldPlay.enabled = true
	await frames(3)
	ok(tw.play != null, "Calder Town has its pastimes")
	var wpl: WorldPlay = tw.play
	ok(wpl.folk.size() >= 8, "souls linger about town to talk to (%d)" % wpl.folk.size())
	ok(wpl.breakables.size() >= 20 and wpl.chests.size() >= 4 and wpl.orbs.size() >= 25, "crates (%d), chests (%d) and spirit orbs (%d)" % [wpl.breakables.size(), wpl.chests.size(), wpl.orbs.size()])
	ok(wpl.stones.size() == 2 and not wpl.dummy.is_empty(), "two challenge stones and a training dummy")
	var crowding := 0
	for g: Variant in tw.giver_list() + tw.talker_list():
		for fl: Variant in wpl.folk:
			if Vector2(((fl as Dictionary)["node"] as Node3D).position.x - float(g[0]), ((fl as Dictionary)["node"] as Node3D).position.z - float(g[1])).length() < 6.0:
				crowding += 1
	ok(crowding == 0, "nobody new stands on a quest giver's toes")
	ok((s.flags.get("visited", {}) as Dictionary).has("town"), "the realm is marked as visited")
	# talking
	var f0n: Node3D = wpl.folk[0]["node"]
	wp.global_position = f0n.global_position + Vector3(1.6, 0.3, 0)
	await frames(2)
	ok(tw.prompt().begins_with("E  Talk to"), "walking up to one offers a word (%s; state %d)" % [tw.prompt(), wp.state])
	tw._talk_cd = 0.0
	ok(tw.interact() and String(main.hud.seen.get("talk", "")).begins_with(String((wpl.folk[0]["def"] as Array)[0])), "and they speak")
	ok((s.flags.get("folk_met", {}) as Dictionary).size() == 1, "and you have met them")
	var gi_f := -1
	var seer_f := -1
	var track_f := -1
	for i in range(wpl.folk.size()):
		match String((wpl.folk[i]["def"] as Array)[2]):
			"gift": gi_f = i
			"seer": seer_f = i
			"tracker": track_f = i
	var gsh := s.shards
	wpl.talk(gi_f)
	var gsh2 := s.shards
	wpl.talk(gi_f)
	ok(gsh2 > gsh and s.shards == gsh2, "a giver hands you something once a day (+%d)" % (gsh2 - gsh))
	wpl.talk(seer_f)
	ok(String(wpl.hint.get("kind", "")) == "chest", "a seer marks a chest on the compass")
	var hinted := false
	for mk: Variant in tw.markers():
		if String((mk as Array)[2]) == "chest":
			hinted = true
	ok(hinted, "and the mark is there")
	wpl.talk(track_f)
	ok(String(wpl.hint.get("kind", "")) == "orb", "a tracker marks a spirit orb")
	# crates
	var bi0 := 0
	var bn: Node3D = wpl.breakables[bi0]["node"]
	var bpos := bn.global_position
	wp.global_position = bpos + Vector3(1.3, 0.3, 0)
	wp.face_now(Vector3(-1, 0, 0))
	await frames(2)
	var crates0 := int(s.flags.get("crates", 0))
	tw.sweep(wp, {"reach": 2.0, "arc": 90.0, "dmg": 10.0})
	ok(not bool(wpl.breakables[bi0]["alive"]) and int(s.flags.get("crates", 0)) >= crates0 + 1, "a swing breaks a crate (and its neighbours in reach: %d)" % (int(s.flags.get("crates", 0)) - crates0))
	var bi1 := wpl._nearest_breakable(50.0)
	wp.global_position = (wpl.breakables[bi1]["node"] as Node3D).global_position + Vector3(0, 0.3, 1.5)
	await frames(2)
	ok(tw.prompt().begins_with("LMB or E"), "and one beside you can be kicked open too")
	tw.interact()
	ok(not bool(wpl.breakables[bi1]["alive"]), "with E")
	# the dummy
	var dn: Node3D = wpl.dummy["node"]
	wp.global_position = dn.global_position + Vector3(0, 0.3, 1.6)
	wp.face_now(Vector3(0, 0, -1))
	await frames(2)
	for i in range(4):
		tw.sweep(wp, {"reach": 2.2, "arc": 90.0, "dmg": 40.0})
		await frames(6)
	ok(int(s.flags.get("dummy_hits", 0)) == 4 and wpl.dummy_dps() > 0.0, "the dummy counts your blows and your damage a second (%.0f)" % wpl.dummy_dps())
	ok(String((wpl.dummy["label"] as Label3D).text).contains("DPS"), "and shows it over its head")
	# chests
	var ci0 := 0
	var csh := s.shards
	wpl.open_chest(ci0, false)
	ok(wpl.chest_open(ci0) and s.shards > csh and int(s.flags.get("chests", 0)) == 1, "a chest opens and pays (+%d)" % (s.shards - csh))
	var csh2 := s.shards
	wpl.open_chest(ci0, false)
	ok(s.shards == csh2, "and only once a day")
	s.flags["days"] = int(s.flags.get("days", 0)) + 1
	ok(not wpl.chest_open(ci0), "it fills again the next day")
	s.flags["days"] = days_keep
	var ci_m := -1
	for i in range(wpl.chests.size()):
		if String(wpl.chests[i]["tier"]) != "wood" and not wpl.chest_open(i):
			ci_m = i
	wpl.open_chest(ci_m, true, true)
	var mimic: Enemy = null
	for a2: Variant in tw.actors:
		if is_instance_valid(a2) and a2 is Enemy and (a2 as Enemy).has_meta("mimic"):
			mimic = a2
	ok(mimic != null and mimic.display_name == "Mimic", "some chests bite")
	var chests_n := int(s.flags.get("chests", 0))
	await force_kill(mimic)
	await frames(3)
	ok(int(s.flags.get("chests", 0)) == chests_n + 1 and Badges.has(s, "mimic_slayer"), "and a dead mimic pays as a chest, twice over")
	clear_enemies()
	# orbs
	var oi0 := wpl._nearest_orb()
	var osh := s.shards
	wp.global_position = (wpl.orbs[oi0]["node"] as Node3D).global_position - Vector3(0, 0.9, 0)
	await frames(3)
	ok(bool(wpl.orbs[oi0]["taken"]) and s.shards >= osh + 2 and (s.flags.get("orbs_town", {}) as Dictionary).size() == 1, "walking through a spirit orb gathers it")
	for i in range(wpl.orbs.size()):
		wpl.take_orb(i)
	ok(wpl.orbs_left() == 0 and Badges.has(s, "lamplighter"), "gathering them all pays, with a badge")
	# challenge stones: the orb rush
	var rush_i := -1
	var slay_i := -1
	for i in range(wpl.stones.size()):
		if String(wpl.stones[i]["kind"]) == "rush":
			rush_i = i
		else:
			slay_i = i
	ok(wpl.start_challenge(rush_i) and wpl.busy() and (wpl.ch["orbs"] as Array).size() == 10, "a stone starts an orb rush")
	ok(not wpl.info().is_empty(), "with a card on the HUD")
	for o: Variant in (wpl.ch["orbs"] as Array).duplicate():
		if wpl.busy() and is_instance_valid(o):
			wp.global_position = (o as Node3D).global_position - Vector3(0, 0.9, 0)
			await frames(2)
	await frames(2)
	ok(not wpl.busy() and wpl.best_medal(rush_i) == 2, "gathered fast, it pays gold (%d)" % wpl.best_medal(rush_i))
	ok(Badges.has(s, "challenger") and Badges.has(s, "gold_standard"), "with badges")
	# the slay challenge, and running out of time
	tw.events.start("raid")
	ok(not wpl.start_challenge(slay_i), "a challenge waits while a world event runs")
	tw.events.finish(false)
	clear_enemies()
	ok(wpl.start_challenge(slay_i) and (wpl.ch["foes"] as Array).size() == 3, "a slay challenge brings three at a time")
	var slay_guard := 0
	while wpl.busy() and slay_guard < 12:
		slay_guard += 1
		for f2: Variant in (wpl.ch.get("foes", []) as Array).duplicate():
			if is_instance_valid(f2) and (f2 as Enemy).alive:
				await force_kill(f2)
		await frames(3)
	ok(not wpl.busy() and wpl.best_medal(slay_i) >= 0, "six down and it pays a medal (%d)" % wpl.best_medal(slay_i))
	clear_enemies()
	wpl.start_challenge(slay_i)
	wpl.ch["t"] = float(wpl.ch["len"])
	await frames(3)
	var leftovers := 0
	for a3: Variant in tw.actors:
		if is_instance_valid(a3) and a3 is Enemy and (a3 as Enemy).has_meta("challenge") and (a3 as Enemy).alive:
			leftovers += 1
	ok(not wpl.busy() and leftovers == 0, "out of time, the stone clears its foes")
	# kill streaks
	var sk: Enemy = tw._spawn("husk", wp.global_position + Vector3(30, 0, 0))
	var ssh := s.shards
	for i in range(5):
		wpl.on_enemy_death(sk)
	ok(wpl.streak >= 5 and s.shards > ssh and Badges.has(s, "streak"), "kills close together make a streak that pays (+%d)" % (s.shards - ssh))
	clear_enemies()
	# lightning finds the badge too
	tw.weather.land(wp.global_position)
	ok(Badges.has(s, "lightning_rod"), "standing in lightning earns a badge")
	wp.hp = wp.max_hp
	await frames(70)
	ok(Badges.has(s, "first_blood") and Badges.count(s) >= 8, "badges come from what the soul has done (%d)" % Badges.count(s))
	# put it all away for the rest of the run
	tw.play.queue_free()
	tw.play = null
	WorldPlay.enabled = false
	for ln: Variant in tw._loot:
		if is_instance_valid(ln):
			(ln as Node).queue_free()
	tw._loot.clear()
	s.shards = keep_sh
	s.essence = keep_ess
	s.level = keep_lv
	s.marks = keep_marks
	s.profile.n["kills"] = keep_kills
	await frames(5)

	# world events: a rift raid, a storm, a march
	await frames(5)
	ok(tw.events != null, "every realm has an event director")
	ok(tw.events.start("raid") and tw.events._rift != null and (tw.events.ev["foes"] as Array).size() == 3, "a rift tears open with its first wave")
	var raid_guard := 0
	while not tw.events.ev.is_empty() and raid_guard < 12:
		raid_guard += 1
		for f: Variant in (tw.events.ev["foes"] as Array).duplicate():
			if is_instance_valid(f):
				await force_kill(f)
		await frames(6)
	ok(tw.events.ev.is_empty() and int(s.flags.get("events", 0)) == 1, "three waves and a warden seal it, and it pays (%d rounds)" % raid_guard)
	clear_enemies()
	ok(tw.events.start("storm") and tw.events.storming(), "a spirit storm can rise")
	var fog_c: Color = tw.events._env.fog_light_color if tw.events._env != null else Color.BLACK
	tw.events.ev["t"] = float(tw.events.ev["len"])
	await frames(3)
	ok(not tw.events.storming() and (tw.events._env == null or tw.events._env.fog_light_color != fog_c), "and it passes, the sky put back")
	clear_enemies()
	ok(tw.events.start("march"), "a Tall can be sent marching")
	var giant: Enemy = tw.events.ev["giant"]
	ok(giant.march_to != Vector3.INF and giant.display_name == "the Marching Tall", "it walks toward the far side")
	giant.global_position = giant.march_to + Vector3(2, 0, 0)
	await frames(4)
	ok(tw.events.ev.is_empty(), "and if it gets there, it is gone")
	clear_enemies()
	await frames(5)

	var rel2: Array = Town.RELICS[1]
	await go(float(rel2[0]) + 1.0, float(rel2[1]))
	await press("interact")
	await frames(70)
	ok(Quests.is_ready(s, "p_keepsakes"), "two keepsakes remembered")
	# the Gutter King in the flats courtyard
	a._spawn_bosses()
	ok(a.bosses.has("gutter_king") and a.bosses.has("drowned_hound"), "the town has two great enemies")
	var king: Enemy = a.bosses["gutter_king"]
	ok(king.dormant, "the Gutter King sleeps in the courtyard")
	await go(Town.FLATS.x + 8.0, Town.FLATS.z + 8.0, 30)
	ok(not king.dormant and king.aggro, "walking into the courtyard wakes it")
	await force_kill(king)
	await frames(10)
	ok(bool(s.flags.get("beat_gutter_king", false)) and Quests.is_ready(s, "p_king"), "it falls, and the notice is done")
	ok(s.level <= Quests.PROLOGUE_CAP, "an Unwrit soul cannot pass level %d (%d)" % [Quests.PROLOGUE_CAP, s.level])
	clear_enemies()
	await go(14.0, 51.0)
	await press("interact")
	await frames(5)
	ok(main.board_ui.claim_all() == 3, "all three are handed in at the board")
	main.board_ui.close()
	ok(Quests.prologue_done(s) and a.objective().contains("Ivo Marsh"), "the prologue is done: go to the shop")
	# the Gutter King left its mask: call it back
	ok(a._rematch.has("gutter_king"), "the Gutter King leaves its mask where it fell")
	await go(Town.FLATS.x, Town.FLATS.z + 2.0, 270)
	ok(a.prompt().begins_with("E  Call back the Gutter King (level 6)"), "it can be called back, stronger (%s)" % a.prompt())
	await press("interact")
	await frames(10)
	var again: Enemy = a.bosses.get("gutter_king")
	ok(again != null and again.level == 6 and again.aggro, "and comes back at level 6")
	await force_kill(again)
	await frames(10)
	ok(int(s.flags.get("rematches_gutter_king", 0)) == 1 and a._rematch.has("gutter_king"), "beaten again, the mask returns for next time")
	clear_enemies()
	ok(a.portal_open("prologue"), "the cellar stairs are open")

	# the tear will not take an unnamed soul
	await go(70.0, -67.2, 270)
	ok(a.prompt() == "E  Step into the tear", "the tear in the park can be approached (%s)" % a.prompt())
	await press("interact")
	await frames(20)
	ok(main.place is Town and String(main.hud.seen.get("whisper", "")).contains("no name"), "but it will not take a soul with no name")
	# Ivo Marsh
	await go(40.0, 12.6)
	ok(a.prompt() == "E  Speak with Ivo Marsh", "Ivo Marsh is in front of his shop (%s)" % a.prompt())
	await press("interact")
	await frames(30)
	await press("interact")
	await frames(30)
	ok(main.place is Undercroft, "he takes the soul down into the Undercroft")
	ok(String(s.flags.get("chapter", "")) == "training", "the training begins")
	use_player()
	var u: Undercroft = main.place
	a = u
	ok(p.is_on_floor(), "standing in the cellar")
	ok(u.objective().begins_with("The Drill"), "the Drill is explained (%s)" % u.objective())

	# the Drill
	var frames_left: Array = []
	for e in u.enemies_alive():
		if (e as Enemy).kind == "drill":
			frames_left.append(e)
	ok(frames_left.size() == 3, "three training frames stand in the yard")
	var drill: Enemy = frames_left[0]
	for e in frames_left:
		if e != drill:
			(e as Enemy).dormant = true
			(e as Enemy).passive = true
	await go(drill.global_position.x, drill.global_position.z + 2.2, 10)
	drill.wake(p)
	var t1 := await parry_vs(drill, 3, func() -> int: return int(s.flags.get("drill_parry", 0)))
	ok(int(s.flags.get("drill_parry", 0)) >= 3, "three parries against a frame (%d ticks)" % t1)
	var t2 := await slip_vs(drill, 2, func() -> int: return int(s.flags.get("drill_slip", 0)))
	ok(int(s.flags.get("drill_slip", 0)) >= 2, "two slips through its blows (%d ticks)" % t2)
	for e in frames_left:
		await force_kill(e)
	await frames(10)
	ok(u._drill_done() and String(main.hud.seen.get("gain", "")).contains("Drill is done"), "the Drill is done")
	clear_enemies()
	await go(6.0, 98.6)
	await press("interact")
	await frames(30)
	await press("interact")
	await frames(30)
	ok(u.stage() == 1 and int(s.flags.get("tether", 0)) == 0, "Marsh cuts the tether")
	ok(p.rig.spec.get("tether", 0) == 0, "and the chain is gone")
	ok(float(s.affinity["vigil"]) > 0.0, "what was left of it counts toward the Reaper")

	# the Cut
	await go(Undercroft.PIT.x, Undercroft.PIT.z + 4.0, 10)
	ok(u.wave == 0, "stepping into the pit starts the first wave")
	guard = 0
	while u.stage() == 1 and guard < 60:
		guard += 1
		for e in u.enemies_alive():
			await force_kill(e)
		await frames(10)
		if u._wave_wait >= 0.0:
			await frames(int(u._wave_wait * 60.0) + 10)
	ok(u.stage() == 2, "three waves survived: the Cut is done")
	ok(float(s.flags.get("erosion", 0.0)) < 100.0, "before the hunger filled")
	clear_enemies()

	# the Stillness
	var uc: Vector3 = Undercroft.CAIRNS[0]
	await go(uc.x, uc.z + 2.4, 280)
	ok(u.prompt() == "E  Sit", "the cellar cairn can be sat at (%s)" % u.prompt())
	await press("interact")
	await frames(10)
	await breathe(Meditation.NEED, 100)
	ok(s.profile.count("breaths_steady") >= 5.0, "five slow breaths are read as steady")
	await frames(170)
	ok(main.place is InnerWorld, "and the soul is taken into the Stillness")
	if not (main.place is InnerWorld):
		return
	use_player()
	await frames(30)
	var iw: InnerWorld = main.place
	iw.echo.global_position = p.global_position + Vector3(0, 0, -2.4)
	iw.echo.wake(p)
	var t3 := await parry_vs(iw.echo, 3, func() -> int: return int(iw.trial.count("parries")))
	ok(iw.trial.count("parries") >= 3.0, "the spirit's blows can be parried (%d ticks)" % t3)
	await kill(iw.echo)
	ok(iw.echo.yielded, "beaten, the spirit kneels")
	await frames(200)
	ok(main.place is Undercroft, "the soul wakes back in the cellar")
	use_player()
	u = main.place
	a = u
	ok(s.written() and String(s.flags.get("chapter", "")) == "hub", "it has awakened: %s (%s)" % [s.form_name(), s.primary])
	ok(String(s.release.get("verb", "")) == "answer", "a soul that won by parrying is given 'answer' (%s)" % String(s.release.get("verb", "")))
	var hub := String(s.flags.get("hub", ""))
	ok(hub == String(Undercroft.HUBS[s.primary]), "its realm is decided by its strain: %s" % hub)
	ok(Quests.title(s) == String(Quests.TITLES[s.primary][5]), "it starts at Grade 5: %s" % Quests.title(s))
	var gate_i := -1
	for i in range(u.portal_list().size()):
		if String(u.portal_list()[i][2]) == hub:
			gate_i = i
	ok(gate_i >= 0, "Marsh has opened a gate to it")
	ok(p.swell >= 100.0, "the First Release is ready")

	# the release
	clear_enemies()
	await go(0.0, 70.0)
	p.face_now(Vector3.FORWARD)
	var h5 := husk_in_front(3.0)
	await press("release")
	await frames(4)
	ok(p.state == Actor.St.BUSY and p.busy_kind == "release", "R begins the release")
	await frames(120)
	ok(p.released, "the blade is released")
	ok(int(Fx.spawned.get("pillar", 0)) >= 1 and int(Sfx.played.get("release", 0)) >= 1, "with a pillar of light and its sound")
	var sw := p.swell
	await press("release")
	await frames(5)
	ok(p.swell < sw - 20.0, "R again spends spirit pressure on the special (%s)" % String(s.release["special"]["type"]))
	await frames(120)
	if is_instance_valid(h5) and h5.alive:
		await kill(h5)
	p.swell = 0.5
	await frames(40)
	ok(not p.released, "when the pressure runs out the name goes quiet")

	# through the gate to the realm
	var gp: Array = u.portal_list()[gate_i]
	await go(float(gp[0]), float(gp[1]) + 2.6, 270)
	p.intent.interact = true
	await frames(40)
	ok((main.place as Region).region_id == hub, "the gate leads to %s" % hub)
	use_player()
	a = main.place
	clear_enemies()
	await frames(10)
	var board_id := ""
	for b: Variant in a.board_list():
		if String(Quests.BOARDS[String((b as Array)[2])]["strain"]) != "*" and Quests.board_accepts(s, String((b as Array)[2])):
			board_id = String((b as Array)[2])
	ok(board_id != "", "the realm has a board for this strain (%s)" % board_id)

	# the board: take a hunt, do it, hand it in
	main.board_ui.open_board(a, board_id)
	var offered: Array = Quests.available(s, board_id)
	ok(offered.size() >= 3, "it offers notices for Grade 5 (%d)" % offered.size())
	var kill_id := ""
	for id: Variant in offered:
		var q := Quests.def(String(id))
		if String(q["kind"]) == "kill" and not String(q["target"]).begins_with("any") and int(q["count"]) <= 10:
			kill_id = String(id)
			break
	ok(kill_id != "", "one of them is a hunt")
	main.board_ui.take(offered.find(kill_id))
	main.board_ui.close()
	var kq := Quests.def(kill_id)
	for i in range(int(kq["count"])):
		p.face_now(Vector3.FORWARD)
		var prey := husk_in_front(3.0, true, String(kq["target"]))
		await force_kill(prey)
		await frames(3)
	ok(Quests.is_ready(s, kill_id), "the hunt is done (%d / %d)" % [Quests.progress(s, kill_id), int(kq["count"])])
	var standing0 := s.standing
	main.board_ui.open_board(a, board_id)
	ok(main.board_ui.claim_all() == 1 and s.standing > standing0, "handed in for standing (%d)" % int(s.standing))
	ok(Quests.available(s, board_id).has(kill_id), "a bounty can be taken again")
	main.board_ui.close()
	clear_enemies()

	# the cap and the climb
	main.grant_essence(100000.0)
	ok(s.level == 10 and s.at_cap(), "Grade 5 caps the soul at level 10 (%d)" % s.level)
	main.board_ui.open_board(a, board_id)
	ok(not main.board_ui.promote() and s.grade == 5, "promotion is refused without standing and the trial")
	main.board_ui.close()
	s.standing = 70.0
	var trial := Quests.trial_boss(s)
	p.face_now(Vector3.FORWARD)
	var tb: Enemy = a._spawn(trial, p.global_position + p.forward() * 6.0, 10)
	ok(tb.is_boss, "the trial is a great enemy: %s" % tb.display_name)
	await force_kill(tb)
	await frames(10)
	ok(bool(s.flags.get("beat_" + trial, false)), "the trial is beaten")
	var title5 := Quests.title(s)
	main.board_ui.open_board(a, board_id)
	ok(not main.board_ui.promote() and s.grade == 5 and Quests.promotion_gap(s).contains("weapon"), "but the grade also asks for forged gear")
	main.board_ui.close()
	# the forge
	var forge_i := -1
	for bi in range(a.board_list().size()):
		if String(a.board_list()[bi][2]) == "forge":
			forge_i = bi
	ok(forge_i >= 0, "the hub has a forge")
	a.open_board("forge")
	ok(main.board_ui.visible and main.board_ui.mode == "forge", "and working it opens the forge")
	s.materials["ash_bone"] = int(s.materials.get("ash_bone", 0)) + 30
	s.materials["mask_shard"] = int(s.materials.get("mask_shard", 0)) + 10
	s.shards += 400
	main.board_ui.set_forge_tab(0)
	ok(main.board_ui.toggle_temper(main.board_ui.temper_keys().find("ash_bone")), "a temper can be chosen")
	var gear_hp0 := float(p.stats["max_hp"])
	ok(main.board_ui.forge_pick(0) and String(s.items[s.items.size() - 1]["type"]) == "weapon", "a weapon is forged: %s" % String(s.items[s.items.size() - 1]["name"]))
	main.board_ui.close()
	main.board_ui.open_inventory(a)
	ok(main.board_ui.use_item(s.items.size() - 1) and Forge.tier_of(s, "weapon") == 1, "and worn from the pack")
	ok(float(p.stats["max_hp"]) > gear_hp0, "the bone temper adds life (%.0f to %.0f)" % [gear_hp0, float(p.stats["max_hp"])])
	main.board_ui.close()
	main.board_ui.open_board(a, board_id)
	ok(main.board_ui.promote() and s.grade == 4, "promotion to Grade 4")
	main.board_ui.close()
	ok(Quests.title(s) != title5 and Quests.level_cap(s) == 18, "%s becomes %s, and the cap rises to 18" % [title5, Quests.title(s)])
	main.grant_essence(1.0)
	ok(s.level == 11 or s.essence > 0.0, "and levels come again")
	clear_enemies()

	# the fusion choice
	s.grade = 3
	var second := Strains.leading(s.affinity, s.primary)
	s.affinity[second] = 90.0
	ok(s.can_graft(), "a strong second strain at Grade 3 can be let in")
	var cp: Vector3 = a.cairn_points()[0]
	await go(cp.x, cp.z + 2.4, 280)
	await press("interact")
	await frames(10)
	await breathe(Meditation.NEED, 20)
	await frames(20)
	ok(main.board_ui.visible and main.board_ui.mode == "choice", "resting offers the choice")
	var techs := s.techniques.size()
	main.board_ui.choose(0)
	await frames(180)
	ok(s.secondary == second and Strains.HYBRID.values().has(s.form_name()), "letting it in makes a %s" % s.form_name())
	ok(s.techniques.size() == techs + 1, "and brings a new technique")
	var art := String(AbilityForge.HYBRID_ART[s.form_name()])
	var art_i := s.techniques.size() - 1
	ok(String(s.techniques[art_i]["kind"]) == art, "the %s's own art: %s" % [s.form_name(), String(s.techniques[art_i]["name"])])
	var art_slot := s.loadout.find(art_i)
	ok(art_slot >= 0 and art_slot < 4, "and it goes straight onto the hotbar (slot %d)" % (art_slot + 1))
	p.anima = p.max_anima
	p.set_state(Actor.St.FREE)
	p.face_now(Vector3.FORWARD)
	var art_target := husk_in_front(4.0)
	await press("tech", art_slot)
	await frames(3)
	ok(p.tech_cd[art_slot] > 0.0, "the art can be used")
	await frames(120)
	if is_instance_valid(art_target) and art_target.alive:
		await force_kill(art_target)
	clear_enemies()
	ok(s.profile.count("breaths_sharp") >= 5.0, "quick breaths are read as sharp")
	use_player()

	# Full Release at Grade 2
	var trial3 := Quests.trial_boss(s)
	s.flags["beat_" + trial3] = true
	var rec := Profile.new()
	rec.add("dodges", 9.0)
	s.flags["record_" + trial3] = rec.to_dict()
	s.standing = 400.0
	main.board_ui.open_board(a, board_id)
	ok(not main.board_ui.promote() and s.grade == 3, "Grade 3 asks for better gear: %s" % Quests.promotion_gap(s))
	main.board_ui.close()
	s.materials.merge({"bell_bronze": 3, "tall_eye": 3, "oath_steel": 30, "mask_shard": 10, "ash_bone": 8, "lantern_glass": 8}, true)
	s.shards += 2000
	var bell := Forge.forge(s, "w_bell")
	var plate := Forge.forge(s, "a_oath")
	var leech := Forge.forge(s, "r_leech")
	ok(not bell.is_empty() and not plate.is_empty() and not leech.is_empty(), "the forge makes a Bellforged blade, Oath Plate and a Leech Rune")
	main.board_ui.open_inventory(a)
	main.board_ui.use_item(s.items.find(bell))
	main.board_ui.use_item(s.items.find(plate))
	main.board_ui.use_item(s.items.find(leech))
	main.board_ui.close()
	ok(Forge.tier_of(s, "weapon") == 3 and Forge.tier_of(s, "armour") == 2 and Forge.rune_count(s) == 1, "all of it worn, the rune socketed")
	ok(p.rig.spec.get("armour", "") == "plate", "the plate shows on the body")
	ok(p.runes.has("leech"), "and the rune is live")
	use_player()
	p.face_now(Vector3.FORWARD)
	var leech_t := husk_in_front(2.0)
	p.hp = p.max_hp * 0.5
	var leech_hp0 := p.hp
	a.strike(p, leech_t, {"kind": "light", "dmg": 20.0, "posture": 2.0})
	ok(p.hp > leech_hp0, "a hit with a Leech Rune heals (%.1f to %.1f)" % [leech_hp0, p.hp])
	clear_enemies()
	# the chance runes, each forced to fire, in real hits
	var runes_keep: Dictionary = p.runes
	p.runes = {"ember": 1.0}
	var ember_t := husk_in_front(2.0)
	ember_t.max_hp = 9000.0
	ember_t.hp = 9000.0
	a.strike(p, ember_t, {"kind": "light", "dmg": 5.0, "posture": 1.0})
	ok(ember_t.dot_t > 0.0 and ember_t.dot_dps > 0.0, "an Ember Rune sets the target burning")
	var burn_hp := ember_t.hp
	await frames(30)
	ok(ember_t.hp < burn_hp, "and the burn eats at it (%.0f to %.0f)" % [burn_hp, ember_t.hp])
	clear_enemies()
	p.runes = {"frost": 1.0}
	var frost_t := husk_in_front(2.0)
	frost_t.max_hp = 9000.0
	frost_t.hp = 9000.0
	a.strike(p, frost_t, {"kind": "light", "dmg": 5.0, "posture": 1.0})
	ok(frost_t.slow_t > 0.0 and frost_t.speed_factor() < 1.0, "a Frost Rune slows it (x%.2f)" % frost_t.speed_factor())
	clear_enemies()
	p.runes = {"storm": 1.0}
	var storm_a := husk_in_front(2.0)
	storm_a.max_hp = 9000.0
	storm_a.hp = 9000.0
	var storm_b: Enemy = a._spawn("husk", storm_a.global_position + Vector3(3.0, 0, 0))
	storm_b.passive = true
	storm_b.max_hp = 9000.0
	storm_b.hp = 9000.0
	a.strike(p, storm_a, {"kind": "light", "dmg": 40.0, "posture": 1.0})
	ok(storm_b.hp < 9000.0, "a Storm Rune arcs to the next enemy (%.0f)" % (9000.0 - storm_b.hp))
	clear_enemies()
	p.runes = {"ward": 0.4}
	var ward_hp := p.hp
	p.invuln = 0.0
	p.receive({"outcome": "hit", "dmg": 50.0, "posture": 0.0, "stagger": false}, null, {})
	var warded := ward_hp - p.hp
	p.runes = {}
	p.hp = ward_hp
	p.receive({"outcome": "hit", "dmg": 50.0, "posture": 0.0, "stagger": false}, null, {})
	var bare := ward_hp - p.hp
	ok(warded < bare * 0.7, "a Ward Rune takes the edge off blows (%.0f against %.0f)" % [warded, bare])
	p.runes = runes_keep
	p.hp = p.max_hp
	main.board_ui.open_board(a, board_id)
	ok(main.board_ui.promote() and s.grade == 2, "promotion to Grade 2")
	main.board_ui.close()
	ok(int(s.release["stage"]) == 2 and String(s.release["scar"]) == "afterstep", "brings the Full Release, scarred by how the trial was won (%s)" % String(s.release.get("scar", "")))
	await frames(20)

	# death returns the soul to its last cairn
	p.invuln = 0.0
	s.essence = 40.0
	var killer := husk_in_front(2.0)
	p.hp = 1.0
	main.place.strike(killer, p, {"kind": "enemy", "dmg": 30.0, "posture": 5.0})
	await frames(5)
	ok(not p.alive and int(s.flags.get("deaths", 0)) >= 1, "the soul can come apart, and the record counts it")
	await frames(200)
	use_player()
	a = main.place
	ok(p.alive and p.hp == p.max_hp and s.essence == 20.0, "it gathers again, with half its loose essence")
	ok(p.global_position.distance_to(cp) < 8.0, "at the last cairn sat at")
	clear_enemies()

	# to the Wastes, and Odrel
	if a.region_id != "ashfall":
		main.travel("ashfall", "town")
		await frames(30)
		use_player()
	var ash: Ashfall = main.place
	a = ash
	ok(ash.bosses.size() >= 2, "the Wastes keep their great enemies (%s)" % str(ash.bosses.keys()))
	for e in ash.enemies_alive():
		if not (e as Enemy).is_boss:
			ash.actors.erase(e)
			e.queue_free()
	var odrel: Enemy = ash.bosses.get("odrel")
	if odrel != null:
		await go(Ashfall.COURT.x, Ashfall.COURT.z + 12.0, 30)
		ok(not odrel.dormant and odrel.aggro, "entering the Bell Court wakes Odrel")
		guard = 0
		while odrel.hp > odrel.max_hp * 0.5 and guard < 200:
			guard += 1
			p.invuln = 1.0
			main.place.strike(p, odrel, {"kind": "light", "dmg": 80.0, "posture": 2.0})
			await frames(1)
		guard = 0
		while odrel.phase < 2 and guard < 900:
			guard += 1
			p.invuln = 1.0
			await get_tree().physics_frame
		ok(odrel.phase == 2 and String(main.hud.seen.get("boss", "")).contains("bell"), "at half vitality the bell begins to ring")
		guard = 0
		while odrel.state != Actor.St.FREE and guard < 600:
			guard += 1
			p.invuln = 1.0
			await get_tree().physics_frame
		p.global_position = odrel.global_position + odrel.forward() * 9.0 + Vector3(0, 0.2, 0)
		odrel._next = ""
		odrel._commit(odrel.move_def("toll"))
		p.invuln = 0.0
		var taken1: float = s.profile.count("hits_taken")
		var waves := 0
		guard = 0
		while guard < 200 and s.profile.count("hits_taken") == taken1:
			guard += 1
			await get_tree().physics_frame
			for ch in a.get_children():
				if ch is Wave:
					waves += 1
		ok(waves > 0 and s.profile.count("hits_taken") > taken1, "the toll runs along the ground and strikes")
		p.hp = p.max_hp
		p.set_state(Actor.St.FREE)
		odrel.invuln = 0.0
		odrel.posture = odrel.posture_max - 1.0
		odrel.posture_rest = 5.0
		main.place.strike(p, odrel, {"kind": "heavy", "dmg": 5.0, "posture": 20.0, "heavy": true})
		await frames(2)
		ok(odrel.state == Actor.St.STAGGER, "a full stance bar breaks even a great enemy")
		await force_kill(odrel)
		ok(bool(s.flags.get("beat_odrel", false)), "Odrel falls")

	# every new kind of enemy can be fought
	for kind: String in ["hound", "wraith", "rogue", "sentinel", "stalker", "giant"]:
		p.face_now(Vector3.FORWARD)
		var e := husk_in_front(6.0, false, kind)
		var kind_hp0 := p.hp
		e.wake(p)
		p.invuln = 0.0
		guard = 0
		while guard < 600 and p.hp >= kind_hp0:
			guard += 1
			await get_tree().physics_frame
			if e.state == Actor.St.ATTACK and e.move_hit:
				break
		ok(e.state == Actor.St.ATTACK or p.hp < kind_hp0, "%s attacks (%d ticks)" % [kind, guard])
		await force_kill(e)
		p.hp = p.max_hp
		await frames(5)
	clear_enemies()

	# the other realm
	main.travel("citadel", "ashfall")
	await frames(30)
	use_player()
	var cit: Citadel = main.place
	ok(cit.bosses.has("vael") != bool(s.flags.get("beat_vael", false)), "Vael waits in the Spire unless he was beaten")
	if cit.bosses.has("thane"):
		ok(cit._gate_bar != null, "the great gate is barred while Thane stands")
		var thane: Enemy = cit.bosses["thane"]
		for e in cit.enemies_alive():
			if not (e as Enemy).is_boss:
				cit.actors.erase(e)
				e.queue_free()
		await go(Citadel.GATE.x, Citadel.GATE.z + 12.0, 30)
		ok(not thane.dormant, "Thane wakes")
		await force_kill(thane)
		await frames(5)
		ok(cit._gate_bar == null, "and when he falls the gate opens")
	else:
		ok(cit._gate_bar == null, "Thane was beaten earlier, so the gate stands open")

	# every race fights its own way
	clear_enemies()
	await frames(10)
	var keep_primary := s.primary
	var keep_second := s.secondary
	s.secondary = ""
	p.released = false
	s.primary = "lumen"
	p.rebuild_body()
	p.refresh_stats(true)
	ok(p.kit() == "bow" and p.rig.hand_l.get_child_count() > 0, "an Archer holds a bow of light")
	p.face_now(Vector3.FORWARD)
	var mark := husk_in_front(12.0)
	var mark_hp := mark.hp
	await press("light")
	var bolts := 0
	a = main.place
	for i in range(30):
		await get_tree().physics_frame
		for ch in a.get_children():
			if ch is Bolt:
				bolts += 1
	await frames(40)
	ok(bolts > 0 and mark.hp < mark_hp, "and a light attack is an arrow that finds its mark at 12 m")
	p.global_position.y += 4.0
	p.velocity.y = 6.0
	await frames(4)
	p.intent.move = Vector2(0, 1)
	await press("dash")
	await frames(14)
	var dashed_twice := p._air_dashes
	await press("dash")
	await frames(14)
	p.intent.move = Vector2.ZERO
	ok(p._air_dashes >= 2 or dashed_twice >= 1, "an Archer can step twice through the air (%d)" % p._air_dashes)
	await frames(80)
	await force_kill(mark)
	clear_enemies()
	s.primary = "maw"
	p.rebuild_body()
	p.refresh_stats(true)
	ok(p.kit() == "claw" and p.rig.hand_r.get_child_count() == 0, "a Devourer fights bare-clawed")
	p.face_now(Vector3.FORWARD)
	var row1 := husk_in_front(8.0)
	var row2 := husk_in_front(14.0)
	var r1 := row1.hp
	var r2 := row2.hp
	p.anima = p.max_anima
	await press("heavy")
	await frames(70)
	ok(row1.hp < r1 and row2.hp < r2, "its heavy is the Maw Beam, which pierces one to hit the next")
	await force_kill(row1)
	await force_kill(row2)
	clear_enemies()
	p.face_now(Vector3.FORWARD)
	var torn := husk_in_front(4.0)
	var torn_hp := torn.hp
	await frames(30)
	p.intent.move = Vector2(0, 1)
	await press("dash")
	await frames(20)
	p.intent.move = Vector2.ZERO
	ok(torn.hp < torn_hp, "and its dash tears what it passes")
	await force_kill(torn)
	clear_enemies()
	s.primary = "relic"
	p.rebuild_body()
	p.refresh_stats(true)
	ok(p.kit() == "chain", "a Binder whips a bound chain")
	p.face_now(Vector3.FORWARD)
	var far := husk_in_front(6.5)
	var far_d := p.flat_to(far.global_position).length()
	await frames(30)
	await press("heavy")
	await frames(50)
	ok(p.flat_to(far.global_position).length() < far_d - 1.5, "and its heavy yanks an enemy in (%.1f m to %.1f m)" % [far_d, p.flat_to(far.global_position).length()])
	await force_kill(far)
	clear_enemies()
	s.primary = "vigil"
	p.rebuild_body()
	p.refresh_stats(true)
	await frames(40)
	var before_step := p.global_position
	p.intent.move = Vector2(0, 1)
	await press("dash")
	await frames(2)
	p.intent.move = Vector2.ZERO
	ok(p.global_position.distance_to(before_step) > 6.0, "a Reaper Flash Steps: %.1f m in a blink" % p.global_position.distance_to(before_step))
	await frames(40)

	# executions and style
	p.face_now(Vector3.FORWARD)
	var victim := husk_in_front(2.4)
	victim.max_hp = 2000.0
	victim.hp = 2000.0
	await frames(10)
	victim.posture = victim.posture_max - 1.0
	victim.posture_rest = 5.0
	main.place.strike(p, victim, {"kind": "heavy", "dmg": 1.0, "posture": 10.0, "heavy": true})
	await frames(3)
	ok(victim.state == Actor.St.STAGGER, "a broken enemy staggers")
	var vhp := victim.hp
	var words := int(Fx.spawned.get("word", 0))
	await press("heavy")
	await frames(40)
	ok(vhp - victim.hp > float(p.stats["heavy_dmg"]) * 2.5, "heavy on a broken enemy is an execution (%d damage)" % int(vhp - victim.hp))
	ok(int(Fx.spawned.get("word", 0)) > words, "announced as one")
	ok(p.style_rank() != "", "fighting well raises the style rank (%s, %.0f)" % [p.style_rank(), p.style_pts])
	var pts := p.style_pts
	p.invuln = 0.0
	p.set_state(Actor.St.FREE)
	main.place.strike(victim, p, {"kind": "enemy", "dmg": 5.0, "posture": 2.0})
	await frames(2)
	ok(p.style_pts < pts * 0.5, "and being hit drops it")
	await force_kill(victim)
	clear_enemies()
	s.primary = keep_primary
	s.secondary = keep_second
	p.rebuild_body()
	p.refresh_stats(true)

	# the Undermark
	clear_enemies()
	var keep_grade := s.grade
	s.grade = 2
	main.travel("undermark", "ashfall")
	await frames(30)
	use_player()
	var deep: Undermark = main.place
	a = deep
	ok(deep.region_id == "undermark" and p.is_on_floor(), "a soul of Grade 2 can descend into the Undermark")
	ok(deep.bosses.has("branded_king") and deep.bosses.has("gaoler_prime") and deep.bosses.has("first_unwrit"), "three great enemies wait below")
	ok(deep._seal != null, "the island is sealed below Grade 1")
	for e in deep.enemies_alive():
		if not (e as Enemy).is_boss:
			deep.actors.erase(e)
			e.queue_free()
	await frames(10)
	# lava burns
	var lx := 100.0
	var lz := 40.0 + 34.0 * sin(lx / 60.0)
	p.global_position = Vector3(lx, Undermark.LAVA_Y + 0.5, lz)
	p.dot_t = 0.0
	await frames(30)
	ok(p.dot_t > 0.0, "standing in the lava burns")
	p.dot_t = 0.0
	await go(0.0, 200.0, 30)
	# the damned mend unless kept under pressure
	p.face_now(Vector3.FORWARD)
	var dm := husk_in_front(6.0, true, "damned")
	main.place.strike(p, dm, {"kind": "light", "dmg": dm.max_hp * 0.5, "posture": 1.0})
	var dm_hp := dm.hp
	await frames(300)
	ok(dm.hp > dm_hp + 5.0, "the Damned mend when left alone (%d to %d)" % [int(dm_hp), int(dm.hp)])
	await force_kill(dm)
	# a Gaoler gets back up unless taken
	var gl := husk_in_front(6.0, true, "gaoler")
	await force_kill(gl)
	await frames(10)
	ok(not gl.alive and gl.remnant, "a Gaoler falls")
	await frames(60 * 13)
	ok(is_instance_valid(gl) and gl.alive and gl.hp == gl.max_hp, "and gets up again when nobody devours it or sends it on")
	await force_kill(gl)
	await frames(10)
	p.global_position = gl.global_position + Vector3(0, 0.2, 1.2)
	await frames(4)
	await press("send")
	await frames(70)
	ok(not is_instance_valid(gl) or gl.is_queued_for_deletion(), "sent on, it stays gone")
	clear_enemies()
	# chains pull
	var cb := husk_in_front(6.0, true, "chainbound")
	var cb_d := p.flat_to(cb.global_position).length()
	p.invuln = 0.0
	p.set_state(Actor.St.FREE)
	main.place.strike(cb, p, {"kind": "enemy", "dmg": 1.0, "posture": 1.0, "pull": true})
	await frames(20)
	ok(p.flat_to(cb.global_position).length() < cb_d - 1.0, "a Chainbound drags you in")
	await force_kill(cb)
	# elites
	var el := Enemy.new()
	el.setup("husk", 24, 999, {}, "stone")
	ok(el.display_name.begins_with("Stone") and el.armored and el.max_hp > Enemy.new().max_hp, "an elite is born with an affix: %s" % el.display_name)
	el.free()
	# brands
	var hp_full := p.max_hp
	p.invuln = 0.0
	p.hp = 1.0
	main.place.strike(husk_in_front(2.0), p, {"kind": "enemy", "dmg": 30.0, "posture": 5.0})
	await frames(200)
	use_player()
	ok(main.place is Undermark or main.place is Region, "the soul gathers again")
	if main.place is Undermark:
		ok(int(s.flags.get("brands", 0)) == 1 and p.max_hp < hp_full, "dying in the Undermark brands you (vitality %d to %d)" % [int(hp_full), int(p.max_hp)])
	clear_enemies()
	# the Grade 2 trial is the Branded King
	ok(not Quests.POWER_BOSSES.has(Quests.trial_boss(s)), "the Undermark's bosses are optional: the Grade 2 trial is still %s" % Quests.trial_boss(s))
	# the power bosses drop charms
	if not (main.place is Undermark):
		main.travel("undermark", "ashfall")
		await frames(30)
	use_player()
	deep = main.place
	a = deep
	clear_enemies()
	deep._spawn_bosses()
	var king2: Enemy = deep.bosses.get("branded_king")
	if king2 != null:
		var items0 := s.items.size()
		await force_kill(king2)
		await frames(10)
		ok(deep.loot_count() > 0, "the Branded King leaves loot")
		var drop_at := king2.global_position
		p.global_position = drop_at + Vector3(0, 0.3, 1.6)
		await frames(20)
		p.global_position = drop_at + Vector3(1.0, 0.3, 0.0)
		await frames(20)
		ok(s.items.size() > items0 and String(s.items[s.items.size() - 1]["key"]) == "crown_of_brands", "and the Crown of Brands is taken")
		var crown_dmg0 := float(p.stats["light_dmg"])
		main.board_ui.open_inventory(deep)
		ok(main.board_ui.visible and main.board_ui.mode == "inventory", "I opens the charms")
		main.board_ui.toggle_charm(s.items.size() - 1)
		main.board_ui.close()
		ok(float(p.stats["light_dmg"]) > crown_dmg0, "wearing the Crown hits harder (%.1f to %.1f)" % [crown_dmg0, float(p.stats["light_dmg"])])
		s.materials["mask_shard"] = int(s.materials.get("mask_shard", 0)) + 8
		s.shards += 100
		main.board_ui.open_forge(deep)
		main.board_ui.set_forge_tab(3)
		ok(main.board_ui.forge_pick(1), "the forge's charm shelf makes a Mask Charm")
		main.board_ui.close()
	# Grade 1 opens the island; the First Unwrit gives the Last Release
	s.grade = 1
	main.travel("undermark", "ashfall")
	await frames(30)
	use_player()
	deep = main.place
	a = deep
	ok(deep._seal == null, "at Grade 1 the seal on the island is gone")
	var fu: Enemy = deep.bosses.get("first_unwrit")
	ok(fu != null and fu.level >= 30, "the First Unwrit waits on its throne")
	if fu != null:
		await force_kill(fu)
		await frames(10)
		ok(int(s.release.get("stage", 1)) == 3 and String(s.release.get("last", "")) != "", "beating it gives the blade its last name: %s" % String(s.release.get("last", "")))
		p.swell = 100.0
		await press("release")
		await frames(130)
		ok(p.released and p._orbit != null, "the Last Release: blades turn about you")
		p.swell = 0.5
		await frames(40)
	s.grade = keep_grade
	clear_enemies()

	# the Archers' realm
	main.travel("reach", "citadel")
	await frames(30)
	use_player()
	var reach: Reach = main.place
	ok(reach.region_id == "reach" and p.is_on_floor(), "the Silver Reach can be entered")
	ok(reach.bosses.has("ysolde") != bool(s.flags.get("beat_ysolde", false)), "Ysolde keeps the Lantern Spire")
	ok(reach.board_list()[0][2] == "lantern" and reach.talker_list().size() == 1, "the Lantern board and its warden are there")
	var town_door := false
	for pp: Variant in Town.new().portal_list():
		if String((pp as Array)[2]) == "reach":
			town_door = true
	ok(town_door, "Lantern House has a door to it")
	if reach.bosses.has("ysolde"):
		var ys: Enemy = reach.bosses["ysolde"]
		for e in reach.enemies_alive():
			if not (e as Enemy).is_boss:
				reach.actors.erase(e)
				e.queue_free()
		await go(Reach.SPIRE.x, Reach.SPIRE.z + 34.0, 30)
		ok(not ys.dormant and ys.aggro, "climbing to the Spire wakes Ysolde")
		guard = 0
		var fired := false
		while guard < 400 and not fired:
			guard += 1
			p.invuln = 1.0
			await get_tree().physics_frame
			for ch in reach.get_children():
				if ch is Bolt:
					fired = true
		ok(fired, "and she fights from range (%d ticks)" % guard)
		await force_kill(ys)
		ok(bool(s.flags.get("beat_ysolde", false)), "Ysolde falls")

	# the Exchange in Calder Town
	main.travel("town", "reach")
	await frames(30)
	use_player()
	a = main.place
	clear_enemies()
	var ex_at: Array = []
	for b: Variant in a.board_list():
		if String((b as Array)[2]) == "exchange":
			ex_at = b
	ok(ex_at.size() > 0, "Calder Town has an Exchange")
	await go(float(ex_at[0]), float(ex_at[1]) + 2.6, 270)
	ok(a.prompt() == "E  Read The Exchange", "it can be read (%s)" % a.prompt())
	Market.tick(s, Market.TICK * 6.0)
	await press("interact")
	await frames(5)
	ok(main.board_ui.visible and main.board_ui.mode == "market", "and opens the market")
	s.shards += 50000
	var items_b := s.items.size()
	var mats_b: int = 0
	for m: Variant in s.materials.values():
		mats_b += int(m)
	ok(main.board_ui.market_buy(0), "a listing can be bought")
	var mats_a: int = 0
	for m: Variant in s.materials.values():
		mats_a += int(m)
	ok(s.items.size() > items_b or mats_a > mats_b, "and the goods arrive")
	s.materials["ash_bone"] = int(s.materials.get("ash_bone", 0)) + 3
	var shards_b := s.shards
	main.board_ui.market_sell(main.board_ui.owned_materials().find("ash_bone"))
	ok(s.shards > shards_b, "materials sell for shards")
	s.items.append(Items.make_charm("bone_charm", 4242))
	ok(main.board_ui.market_list(main.board_ui.unequipped_charms().size() - 1) or (Market.state(s)["mine"] as Array).size() > 0, "a charm can be listed for other souls")
	main.board_ui.close()

	# the Stacks: the Binders' own realm
	ok(String(Undercroft.HUBS["relic"]) == "stacks", "Binders are sent to the Stacks after training")
	var stair_ok := false
	var tn := Town.new()
	for pt: Variant in tn.portal_list():
		if String((pt as Array)[2]) == "stacks" and String((pt as Array)[4]) == "binder":
			stair_ok = true
	tn.free()
	ok(stair_ok, "a back stair in Calder Town leads down to them")
	var from_rid: String = (main.place as Region).region_id
	main.travel("stacks", "town")
	await frames(30)
	var st_r: Region = main.place
	ok(st_r is Stacks and st_r.region_id == "stacks", "the Stacks can be entered")
	var st_boards: Array = []
	for bd: Variant in st_r.board_list():
		st_boards.append(String((bd as Array)[2]))
	ok(st_boards.has("shop") and st_boards.has("exchange") and st_boards.has("forge"), "with the Shop Ledger, an Exchange and a forge at its hub")
	ok(st_r.giver_list().size() == 1 and st_r.talker_list().size() == 1 and Quests.BOARDS.has("g_quill"), "a quest giver and a keeper to talk to")
	var walled := 0
	for sp: Variant in Stacks.SPAWNS:
		if not (st_r as Stacks)._floor_open(float(sp[1]), float(sp[2])):
			walled += 1
	ok(walled == 0, "no shelf stands where an enemy rises (%d walled in)" % walled)
	ok((st_r as Stacks)._floor_open(Stacks.ESCORT.x, Stacks.ESCORT.z), "nor where the lost reader waits")
	var st_enemies := st_r.enemies_alive().size()
	ok(st_enemies >= 10, "and the shelves are not empty (%d)" % st_enemies)
	main.travel(from_rid, "stacks")
	await frames(30)
	a = main.place
	use_player()

	# save, title, continue
	main.save()
	var loaded := Soul.load_from(main.save_path)
	ok(loaded != null and loaded.grade == s.grade and loaded.secondary == s.secondary and String(loaded.release["spirit"]) == String(s.release["spirit"]), "the soul is saved, grade and all")
	ok(loaded.shards == s.shards and loaded.items.size() == s.items.size() and loaded.equipped == s.equipped and Forge.tier_of(loaded, "weapon") == Forge.tier_of(s, "weapon") and Forge.rune_count(loaded) == Forge.rune_count(s), "with its shards, charms, gear and runes")
	main.show_title()
	await frames(20)
	ok(main.in_title and main.menus.visible, "the title shows over the town")
	main.continue_soul()
	await frames(30)
	ok(not main.in_title and main.soul.written() and main.soul.form_name() == s.form_name(), "continue brings the same soul back")
	main._pause(false)
	ok(get_tree().paused and main.menus.mode == "pause", "pause opens")
	main._resume()
	ok(not get_tree().paused, "and closes")
	# settings and controls
	main._pause(false)
	main._menu("settings")
	ok(main.menus.mode == "settings", "the pause menu opens settings")
	var vol0 := Sfx.master_db
	main._menu("set_master")
	ok(Sfx.master_db != vol0, "stepping master volume changes it (%.1f to %.1f dB)" % [vol0, Sfx.master_db])
	var sens0 := float(Settings.get_value("sens"))
	main._menu("set_sens")
	ok(float(Settings.get_value("sens")) != sens0, "mouse sensitivity steps")
	var q_env: Environment = null
	var q_sun: DirectionalLight3D = null
	for qc in main.place.get_children():
		if qc is WorldEnvironment:
			q_env = (qc as WorldEnvironment).environment
		elif qc is DirectionalLight3D and q_sun == null:
			q_sun = qc
	ok(Quality.level() == 2 and Settings.label("quality").ends_with("High"), "graphics start on High")
	main._menu("set_quality")
	main._menu("set_quality")
	ok(Quality.level() == 0 and main.get_viewport().scaling_3d_scale < 1.0, "and step down to Low, which renders smaller")
	ok((q_env == null or not q_env.ssao_enabled) and (q_sun == null or not q_sun.shadow_enabled), "with no ambient occlusion and no sun shadows")
	main._menu("set_quality")
	ok(Quality.level() == 2 and main.get_viewport().scaling_3d_scale == 1.0 and (q_sun == null or q_sun.shadow_enabled == bool(q_sun.get_meta("shadow_built"))), "and round to High again, as built")
	main._menu("controls")
	ok(main.menus.mode == "controls", "settings lead to the controls page")
	main._menu("back")
	ok(main.menus.mode == "settings", "and back")
	main._menu("back")
	ok(main.menus.mode == "pause", "and back to the pause menu")
	main._resume()

	var kinds := ["slash", "ring", "sparks", "ghost", "pillar", "puff", "word"]
	var missing: Array = []
	for k: String in kinds:
		if int(Fx.spawned.get(k, 0)) == 0:
			missing.append(k)
	ok(missing.is_empty(), "every kind of effect fired (missing %s)" % str(missing))
	var sounds := ["whoosh", "hit", "parry", "block", "dash", "death", "devour", "send", "relic", "levelup", "release", "release_charge", "special", "toll", "roar", "breath_in", "breath_out", "rest", "write", "slip", "step", "jump", "land", "seal", "break"]
	var silent: Array = []
	for k: String in sounds:
		if int(Sfx.played.get(k, 0)) == 0:
			silent.append(k)
	ok(silent.is_empty(), "every sound was asked for (never played: %s)" % str(silent))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
