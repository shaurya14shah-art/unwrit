extends Node
## The fair duel: a bot fights each grade's trial with real inputs only
## (move, parry, dash, strike, critical, evasive), with the soul each grade
## expects at its cap (skill points spent, gear at the bar). No forced
## damage. It proves the trials can be won by play and measures how long
## that takes; it is not a player, its timing is too good.
## godot --headless --fixed-fps 60 --path game res://tests/Duel.tscn -- --no-title

const FIGHTS: Array = [
	[5, "citadel", "thane"], [5, "town", "drowned_hound"], [4, "ashfall", "many_mouthed"],
	[3, "reach", "vael"], [2, "ashfall", "odrel"], [1, "undermark", "sereth"],
]
const TRIES: int = 3
const LIMIT: float = 240.0

var main: Node
var p: Player
var results: Array = []
var _crit_wait: float = 0.0


func _ready() -> void:
	Fx.quiet = true
	Sfx.muted = true
	WorldPlay.enabled = false
	var scene: PackedScene = load("res://main.tscn")
	main = scene.instantiate()
	add_child(main)
	main.save_path = "user://duel_soul.json"
	main.new_soul(5150)
	await frames(30)
	var lost := 0
	for f: Variant in FIGHTS:
		var fa: Array = f
		var won := false
		var line := ""
		for t in range(TRIES):
			var r: Dictionary = await duel(int(fa[0]), String(fa[1]), String(fa[2]))
			line = "  %-14s grade %d  try %d: %s in %5.1f s, %3d%% vitality left, %d parries, %d dodges, %d hits taken, boss at %d%%  %s" % [String(fa[2]), int(fa[0]), t + 1, "WON " if bool(r["won"]) else "LOST", float(r["time"]), int(r["hp"]), int(r["parries"]), int(r["dodges"]), int(r["hits"]), int(r["boss_hp"]), str(r["hit_by"])]
			print(line)
			if bool(r["won"]):
				won = true
				break
		results.append(line)
		if not won:
			lost += 1
			print("  FAIL  duel: %s was never beaten in %d tries" % [String(fa[2]), TRIES])
	print("duel: %d of %d trials beaten by play" % [FIGHTS.size() - lost, FIGHTS.size()])
	if FileAccess.file_exists(main.save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	get_tree().quit(1 if lost > 0 else 0)


func frames(n: int) -> void:
	for i in range(n + 1):
		await get_tree().physics_frame


## The soul a grade expects at its cap: the balance report's soul.
func seasoned(grade: int) -> Soul:
	var s := Soul.create(99 + grade)
	s.primary = "vigil"
	s.affinity["vigil"] = 80.0
	s.flags["chapter"] = "hub"
	s.flags["hub"] = "citadel"
	s.grade = grade
	s.level = Quests.level_cap(s)
	s.marks = 2 + 2 * (s.level - 1) + 3 * (5 - grade)
	var order: Array = []
	for tier in range(1, SkillTree.TIERS + 1):
		for br: String in ["blade", "speed", "body", "spirit"]:
			order.append(String(SkillTree.nodes_of(br, tier)[0]))
	var guard := 0
	while s.marks > 0 and guard < 200:
		guard += 1
		var took := false
		for id: Variant in order:
			if SkillTree.take(s, String(id)):
				took = true
				break
		if not took:
			break
	var req: Dictionary = Forge.REQUIRE.get(mini(grade + 1, 5), Forge.REQUIRE[5])
	var w_by_tier := {1: "w_bone", 2: "w_oath", 3: "w_bell", 4: "w_brand", 5: "w_unwritten"}
	var a_by_tier := {1: "a_hide", 2: "a_oath", 3: "a_carapace", 4: "a_gaoler", 5: "a_pages"}
	s.gear["weapon"] = Forge.make(String(w_by_tier[clampi(int(req["weapon"]), 1, 5)]), [], "aggression", 5)
	if int(req["armour"]) > 0:
		s.gear["armour"] = Forge.make(String(a_by_tier[clampi(int(req["armour"]), 1, 5)]), [], "aggression", 6)
	s.flags["weather"] = "clear"
	s.flags["weather_left"] = 1.0e9
	s.flags["clock"] = 0.25
	return s


func duel(grade: int, rid: String, boss_kind: String) -> Dictionary:
	main.soul = seasoned(grade)
	main.travel(rid, "town" if rid != "town" else "citadel")
	await frames(30)
	var a: Region = main.place
	if main.board_ui.visible:
		main.board_ui.close()
	for x in a.actors.duplicate():
		if x != a.player and is_instance_valid(x):
			a.actors.erase(x)
			x.queue_free()
	a.boss = null
	a.bosses.clear()
	p = a.player
	p.scripted = true
	p.intent = Player.Intent.new()
	p.refresh_stats(true)
	p.hp = p.max_hp
	await frames(5)
	var at := p.global_position + p.forward() * 9.0
	at.y = a.height_at(at.x, at.z)
	var e: Enemy = a._spawn(boss_kind, at, Region.trial_level(boss_kind, main.soul))
	e.home = at
	e.wake(p)
	var parries0 := int(main.soul.profile.count("parries"))
	var dodges := 0
	var hits := 0
	var hit_by := {}
	var hp_was := p.hp
	var t := 0.0
	var hold_block := 0
	_crit_wait = 2.0
	while t < LIMIT and p.alive and is_instance_valid(e) and e.alive and not e.yielded:
		p.intent.clear_presses()
		var to := e.global_position - p.global_position
		to.y = 0.0
		# distance to its edge, not its middle: great enemies are wide
		var d := maxf(0.0, to.length() - e.radius)
		if p.state == Actor.St.FREE or p.state == Actor.St.BLOCK:
			p.face_now(to)
		if hold_block > 0:
			hold_block -= 1
			p.intent.block = true
		else:
			p.intent.block = false
		p.intent.move = Vector2.ZERO
		var threat := e.state == Actor.St.ATTACK and not e.move_hit and String(e.move.get("type", "strike")) != "wave"
		var wave_in := _wave_eta()
		if wave_in >= 0.0 and wave_in < 0.22 and p.is_on_floor() and (p.state == Actor.St.FREE or p.state == Actor.St.BLOCK):
			# a ring along the ground: hop it as it arrives
			p.intent.block = false
			p.intent.jump = true
			p.intent.jump_held = true
		elif e.state == Actor.St.ATTACK and not e.move_hit and String(e.move.get("type", "")) == "wave":
			# a ring is coming: stop swinging, give it room to be jumped
			p.intent.move = _stick(-to.normalized())
		elif p.state == Actor.St.HIT and p.evasive_cd <= 0.0:
			# caught in a string: break out
			p.intent.dash = true
			p.intent.move = _stick(to.normalized().cross(Vector3.UP))
		elif threat:
			var left := float(e.move["startup"]) - e.state_t
			var typ := String(e.move.get("type", "strike"))
			var reach := float(e.move.get("reach", 3.0)) * e.reach_scale + 1.2
			var parryable := bool(e.move.get("parryable", true)) and typ == "strike"
			if typ == "bolt":
				# strafe across the shot, dash as it leaves
				p.intent.move = _stick(to.normalized().cross(Vector3.UP))
				if left <= 0.05 and p.dash_cd_t <= 0.0 and p.state == Actor.St.FREE:
					p.intent.dash = true
					dodges += 1
			elif parryable and d < reach + float(e.move.get("lunge", 0.0)) * 0.5:
				if left <= 0.1 and hold_block == 0:
					p.intent.block = true
					p.intent.block_pressed = true
					hold_block = 3
			elif d < reach + 6.0:
				if left <= 0.14 and p.dash_cd_t <= 0.0 and (p.state == Actor.St.FREE or p.state == Actor.St.BLOCK):
					p.intent.block = false
					p.intent.dash = true
					# a lunging blow follows you back: step aside from it
					p.intent.move = _stick(to.normalized().cross(Vector3.UP) if float(e.move.get("lunge", 0.0)) > 3.0 else -to.normalized())
					dodges += 1
				elif left > 0.14:
					# red and lunging: get off its line early, not just at the end
					var side := to.normalized().cross(Vector3.UP)
					p.intent.move = _stick(side if float(e.move.get("lunge", 0.0)) > 3.0 else -to.normalized())
					p.intent.sprint = true
		elif d > 1.6:
			p.intent.move = _stick(to.normalized())
			p.intent.sprint = d > 8.0
		else:
			_crit_wait -= 1.0 / 60.0
			if _crit_wait <= 0.0 and p.crit_cd <= 0.0:
				p.intent.crit = true
				_crit_wait = 3.0
			else:
				p.intent.light = true
		await get_tree().physics_frame
		t += 1.0 / 60.0
		if p.hp < hp_was - 0.5:
			hits += 1
			var mid := String(e.move.get("id", "?")) if e.state == Actor.St.ATTACK else "other"
			hit_by[mid] = int(hit_by.get(mid, 0)) + 1
		hp_was = p.hp
		if get_tree().paused:
			main._resume()
		if main.board_ui.visible:
			main.board_ui.close()
	var won := is_instance_valid(e) and (not e.alive or e.yielded)
	var res := {"won": won, "time": t, "hp": int(round(100.0 * p.hp / maxf(p.max_hp, 1.0))) if p.alive else 0,
		"parries": int(main.soul.profile.count("parries")) - parries0, "dodges": dodges, "hits": hits,
		"boss_hp": int(round(100.0 * e.hp / maxf(e.max_hp, 1.0))) if is_instance_valid(e) and e.alive else 0, "hit_by": hit_by}
	if not p.alive:
		await frames(260)
	return res


## Seconds until the nearest enemy shockwave reaches the player, or -1.
func _wave_eta() -> float:
	var best := -1.0
	for c in p.place.get_children():
		if c is Wave and (c as Wave).team != p.team:
			var w := c as Wave
			var to := p.global_position - w.global_position
			to.y = 0.0
			var gap := to.length() - w.r
			if gap > -0.2 and (best < 0.0 or gap / w.speed < best):
				best = maxf(0.0, gap / w.speed)
	return best


## A world direction as a stick input under the camera.
func _stick(world: Vector3) -> Vector2:
	var yaw := p.place.cam.yaw if p.place != null and p.place.cam != null else 0.0
	var local := Basis(Vector3.UP, -yaw) * world
	return Vector2(local.x, -local.z)
