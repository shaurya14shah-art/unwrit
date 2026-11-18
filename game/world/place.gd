class_name Place
extends Node3D
## A place where fighting happens. It owns the bodies in it, asks the rules
## what each blow did, and writes what the player did into the soul's ledger.

signal message(text: String, kind: String)

var main: Node
var soul: Soul
var player: Player
var cam: CamRig
var actors: Array[Actor] = []
var records: Array[Profile] = []
var bounds: float = 120.0
var test_mode: bool = false
var paused_input: bool = false
var place_name: String = ""
var _combat_t: float = 0.0


func region_id_of() -> String:
	var v: Variant = get("region_id")
	return String(v) if v != null else ""


func height_at(_x: float, _z: float) -> float:
	return 0.0


func confine(a: Actor) -> void:
	var p := a.global_position
	var d := Vector2(p.x, p.z)
	if d.length() > bounds:
		d = d.normalized() * bounds
		a.global_position = Vector3(d.x, p.y, d.y)


func say(text: String, kind: String = "toast") -> void:
	message.emit(text, kind)


func add_actor(a: Actor, pos: Vector3) -> void:
	a.place = self
	add_child(a)
	a.global_position = Vector3(pos.x, height_at(pos.x, pos.z) + 0.05, pos.z)
	actors.append(a)


func enemies_alive() -> Array[Actor]:
	var out: Array[Actor] = []
	for a in actors:
		if is_instance_valid(a) and a.alive and a.team != 0 and not a.yielded:
			out.append(a)
	return out


func nearest_enemy(from: Vector3, max_dist: float, dir: Vector3 = Vector3.ZERO, cone: float = -1.0) -> Actor:
	var best: Actor = null
	var best_d := max_dist
	for a in enemies_alive():
		var to := a.global_position - from
		to.y = 0.0
		var d := to.length()
		if d > best_d:
			continue
		if cone > -1.0 and d > 0.5 and dir.dot(to / d) < cone:
			continue
		best_d = d
		best = a
	return best


func in_combat() -> bool:
	return _combat_t > 0.0


func touch_combat() -> void:
	_combat_t = 4.0


## Attack tokens: only a few ordinary enemies press the player at once; the
## rest circle and wait their turn. A token lapses a few seconds after its
## holder's last swing, and a holder rests a moment before it may take one
## again, so the pressure rotates round the pack.
const TOKENS: int = 2
var _tokens: Dictionary = {}
var _token_rest: Dictionary = {}


func attack_token(e: Actor) -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	for id: Variant in _tokens.keys():
		var o: Object = instance_from_id(int(id))
		if float(_tokens[id]) < now or o == null or not is_instance_valid(o) or not (o as Actor).alive:
			_tokens.erase(id)
			_token_rest[id] = now + 1.2
	var key := e.get_instance_id()
	if _tokens.has(key):
		return true
	if float(_token_rest.get(key, 0.0)) > now or _tokens.size() >= TOKENS:
		return false
	_tokens[key] = now + 3.5
	return true


func hold_token(e: Actor) -> void:
	var key := e.get_instance_id()
	if _tokens.has(key):
		_tokens[key] = Time.get_ticks_msec() / 1000.0 + 3.5


## Records something the player did: in the soul's ledger, in any open record
## (a trial, a great fight), and in the strain it feeds.
func note(event: String, amount: float = 1.0) -> void:
	if soul == null:
		return
	const LEDGER := {
		"swing": "swings", "light_hit": "light_hits", "heavy_hit": "heavy_hits", "air_hit": "air_hits",
		"ranged_hit": "ranged_hits", "tech": "tech_uses", "parry": "parries", "block": "blocks",
		"dodge": "dodges", "hit_taken": "hits_taken", "kill": "kills", "devour": "devours", "relic": "relics",
	}
	if LEDGER.has(event):
		soul.profile.add(String(LEDGER[event]), amount)
		for r in records:
			r.add(String(LEDGER[event]), amount)
	_on_noted(event)
	var before := Strains.leading(soul.affinity)
	Strains.gain(soul.affinity, event, amount)
	if not soul.written():
		var after := Strains.leading(soul.affinity)
		if after != before and float(soul.affinity[after]) > 12.0 and not bool(soul.flags.get("whisper_" + after, false)):
			soul.flags["whisper_" + after] = true
			say(String(Strains.INFO[after]["whisper"]), "whisper")


func _physics_process(delta: float) -> void:
	if soul == null or player == null:
		return
	_combat_t = maxf(0.0, _combat_t - delta)
	if in_combat():
		soul.profile.time_fighting += delta
		for r in records:
			r.time_fighting += delta
		if player.hp < player.max_hp * 0.35:
			soul.profile.time_low += delta
			for r in records:
				r.time_low += delta
	soul.playtime += delta


func _on_noted(_event: String) -> void:
	pass


func on_swing(attacker: Actor, m: Dictionary) -> void:
	if attacker == player:
		note("swing")
		for a in enemies_alive():
			(a as Enemy).threatened(attacker, m)


## Finds every body a blow reaches and resolves each. Returns how many.
func sweep(attacker: Actor, m: Dictionary) -> int:
	var hits := 0
	var reach := float(m["reach"]) * attacker.reach_scale
	var half := deg_to_rad(float(m["arc"])) * 0.5
	var f := attacker.forward()
	for a: Actor in actors.duplicate():
		if not is_instance_valid(a) or a == attacker or a.team == attacker.team or not a.alive or a.yielded:
			continue
		var to := a.global_position - attacker.global_position
		var dy := absf(to.y)
		to.y = 0.0
		var d := to.length()
		if d - a.radius > reach or dy > 2.4 * maxf(attacker.reach_scale, a.reach_scale):
			continue
		if d > 0.3 and half < PI * 0.99 and f.angle_to(to / d) > half + atan2(a.radius, d):
			continue
		strike(attacker, a, m)
		hits += 1
	if attacker == player:
		on_player_sweep(attacker, m)
	return hits


## Things that are not actors but can be struck (crates, the dummy).
func on_player_sweep(_attacker: Actor, _m: Dictionary) -> void:
	pass


func strike(attacker: Actor, defender: Actor, m: Dictionary) -> Dictionary:
	var dmg := float(m.get("dmg", 10.0))
	var from := attacker.global_position if is_instance_valid(attacker) else defender.global_position
	if m.has("from"):
		from = m["from"]
	var atk := {
		"dmg": dmg * (attacker.damage_factor() if is_instance_valid(attacker) else 1.0),
		"posture": float(m.get("posture", 8.0)),
		"heavy": bool(m.get("heavy", false)),
		"blockable": bool(m.get("blockable", true)),
		"parryable": bool(m.get("parryable", true)),
		"ranged": bool(m.get("ranged", false)),
	}
	var res := CombatRules.resolve(atk, defender.defence(from))
	var outcome := String(res["outcome"])
	var at := defender.center()
	var col: Color = m.get("color", attacker.accent if is_instance_valid(attacker) else Color.WHITE)
	touch_combat()
	match outcome:
		"dodged":
			if defender == player and bool(res["perfect"]):
				note("dodge")
				player.on_perfect_dodge(attacker)
				Fx.word(at + Vector3(0, 0.9, 0), "SLIP", Color(0.7, 1.0, 1.0), 0.8)
				Sfx.play("slip", -4.0)
		"parried":
			Fx.parry_burst(at + defender.forward() * 0.7, defender.accent)
			Sfx.play("parry", 0.0)
			Fx.word(at + Vector3(0, 1.0, 0), "PARRY", Color(1, 1, 1), 1.0)
			if defender == player:
				note("parry")
				player.on_parry(attacker, m)
			defender.rig.play("parry", 0.03, 1.0, true)
			if is_instance_valid(attacker) and not bool(m.get("ranged", false)):
				attacker.parried_by(defender, float(res["attacker_posture"]))
		"blocked":
			Fx.sparks(at + defender.forward() * 0.6, Color(0.9, 0.9, 1.0), 6, 6.0)
			Fx.add_shake(0.15)
			Sfx.play("block", -3.0)
			if defender == player:
				note("block")
		"hit":
			var weight := -1.0
			if attacker == player and defender.max_hp > 0.0:
				weight = clampf(float(res["dmg"]) / defender.max_hp * 2.5, 0.0, 1.0)
				if bool(m.get("heavy", false)):
					weight = maxf(weight, 0.45)
			Fx.impact(at, col, bool(m.get("heavy", false)), weight)
			if bool(m.get("crit", false)):
				Fx.sparks(at, Color(1.0, 0.2, 0.15), 14, 12.0)
				Fx.screen_flash(Color(1.0, 0.9, 0.85), 0.18)
			Sfx.play("hit_heavy" if bool(m.get("heavy", false)) else "hit", -1.0)
			if defender == player:
				note("hit_taken")
				if player.state == Actor.St.ATTACK:
					note("trade")
				Fx.screen_flash(Color(0.9, 0.1, 0.1), 0.25)
	var died := defender.receive(res, attacker, m)
	if is_instance_valid(attacker) and attacker != player and (outcome == "hit" or outcome == "blocked"):
		if bool(m.get("pull", false)) and is_instance_valid(defender) and defender.alive:
			var to := defender.global_position - attacker.global_position
			to.y = 0.0
			defender.push += -to.normalized() * maxf(0.0, to.length() - attacker.radius - 1.6) * 3.2
		var foe := attacker as Enemy
		if foe != null and foe.affix == "leech" and outcome == "hit":
			foe.heal(float(res["dmg"]) * 0.5)
	if bool(m.get("burn", false)) and outcome == "hit" and is_instance_valid(defender) and defender.alive:
		defender.apply_effect("dot", 1.1, attacker if is_instance_valid(attacker) else null)
	if is_instance_valid(attacker):
		attacker_dealt(attacker, defender, m, res, died)
	return res


func attacker_dealt(attacker: Actor, defender: Actor, m: Dictionary, res: Dictionary, died: bool) -> void:
	var outcome := String(res["outcome"])
	if attacker != player:
		return
	if outcome == "hit" or outcome == "blocked":
		var kind := String(m.get("kind", "light"))
		match kind:
			"light": note("light_hit")
			"heavy": note("heavy_hit")
			"air": note("air_hit")
			"ranged": note("ranged_hit")
			"tech":
				if bool(m.get("ranged", false)):
					note("ranged_hit")
				else:
					note("heavy_hit" if bool(m.get("heavy", false)) else "light_hit", 0.5)
		player.on_dealt(defender, m, res, died)
	if outcome == "hit" and float(res["dmg"]) > 0.0:
		Fx.word(defender.center() + Vector3(randf_range(-0.4, 0.4), 0.5, 0), str(int(round(float(res["dmg"])))), Color(1, 1, 1, 0.9), 0.6)


func fire(attacker: Actor, origin: Vector3, dir: Vector3, m: Dictionary) -> Bolt:
	var b := Bolt.new()
	add_child(b)
	b.launch(self, attacker, origin, dir, m)
	Sfx.play("bolt", -5.0)
	return b


func shockwave(attacker: Actor, origin: Vector3, m: Dictionary) -> void:
	var w := Wave.new()
	add_child(w)
	w.launch(self, attacker, origin, m)
	Sfx.play("toll", 0.0)
	Fx.add_shake(0.6)


func on_death(a: Actor, _killer: Actor) -> void:
	if a == player:
		on_player_death()
		return
	Sfx.play("death", -3.0)
	Fx.puff(a.global_position + Vector3(0, 0.5, 0), Color(0.85, 0.85, 0.88, 0.7), 18, 0.9)
	note("kill")
	if player != null and player.hp < player.max_hp * 0.35:
		note("kill_low")
	on_enemy_death(a as Enemy)


## How far enemies see the player, as a share of their range.
func sight_scale() -> float:
	return 1.0


func on_enemy_death(_e: Enemy) -> void:
	pass


func on_player_death() -> void:
	pass


## Called by the player on E. Returns true if something was done.
func interact() -> bool:
	return false


func send_on() -> bool:
	return false


func prompt() -> String:
	return ""
