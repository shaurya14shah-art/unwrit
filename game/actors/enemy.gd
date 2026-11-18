class_name Enemy
extends Actor
## One AI for every enemy. It closes or keeps distance, picks a blow by
## weight and range, shows it coming, and commits. Bosses add phases.

var kind: String = "husk"
var def: Dictionary = {}
var home: Vector3 = Vector3.ZERO
var leash: float = 34.0
var aggro_range: float = 17.0
var aggro: bool = false
var target: Actor
var essence: float = 10.0
var is_boss: bool = false
var is_echo: bool = false
var phase: int = 1
var moves: Array = []
var remnant: bool = false
## How an enemy grows with its own level (balance pass, 2026-11-16).
const HP_GROW: float = 0.08
const DMG_GROW: float = 0.05
const ESS_GROW: float = 0.14
## Knocked: beaten by an ordinary blow, an ordinary enemy kneels instead of
## dying. Any blow finishes it; a grip finishes it for more; left alone it
## gets back up. Bodies can also be carried and thrown.
const KNOCK_TIME: float = 7.0
var knocked: bool = false
var knocked_t: float = 0.0
var gripped: bool = false
var gripped_by: Actor = null
var carried_by: Actor = null
var thrown_by: Actor = null
var thrown_t: float = 0.0
var remnant_t: float = 0.0
var dormant: bool = false
var passive: bool = false

var _cool: float = 1.0
## Pack and boss behaviour: a gap-closing dash, a count of swings before a
## boss runs out of breath, and whether it has been driven to its last rage.
var _gap_cd: float = 3.0
var _swings: int = 0
var enraged: bool = false
## A marching Tall walks here unless something picks a fight with it.
var march_to: Vector3 = Vector3.INF
var _strafe: float = 1.0
var _strafe_t: float = 0.0
var _next: String = ""
var _react_t: float = -1.0
var _react_kind: String = ""
var _block_t: float = 0.0
var _leap_from: Vector3 = Vector3.ZERO
var _leap_to: Vector3 = Vector3.ZERO
var _leaping: bool = false
var _warned: bool = false
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var patience: float = 0.5
var mobility: float = 0.5
var level: int = 1
var reacts: bool = false
var affix: String = ""
var _since_hurt: float = 99.0
var _wisp: MeshInstance3D


func setup(enemy_kind: String, enemy_level: int = 1, seed_value: int = 1, body_override: Dictionary = {}, enemy_affix: String = "") -> void:
	kind = enemy_kind
	def = Bestiary.get_def(kind)
	_rng.seed = hash([seed_value, kind])
	display_name = String(def["name"])
	var body: Dictionary = (def["body"] as Dictionary).duplicate()
	if not body.has("mask_seed"):
		body["mask_seed"] = seed_value
	if not body.has("hair_seed"):
		body["hair_seed"] = seed_value
	for k: Variant in body_override.keys():
		body[k] = body_override[k]
	build_body(body)
	accent = body.get("accent", Color.WHITE)
	level = maxi(1, enemy_level)
	# vitality and harm grow with the enemy's own level, never with yours:
	# a stronger soul really is stronger against the same ground
	var grow := 1.0 + HP_GROW * float(level - 1)
	max_hp = float(def["hp"]) * grow
	hp = max_hp
	posture_max = float(def["posture"])
	armored = bool(def.get("armored", false))
	essence = float(def["essence"]) * (1.0 + ESS_GROW * float(level - 1))
	is_boss = bool(def.get("boss", false))
	is_echo = bool(def.get("echo", false))
	reacts = bool(def.get("reacts", false))
	patience = float(def.get("patience", patience))
	mobility = float(def.get("mobility", mobility))
	if bool(def.get("blade", false)):
		if kind == "vael":
			rig.hold(Gear.released_blade({"form": "glaive", "color": [0.55, 0.3, 1.0], "reach": 1.2}, 44))
		else:
			rig.hold(Gear.sealed_blade(seed_value))
	moves = (def["moves"] as Array).duplicate()
	team = 1
	parry_window = 0.0
	_cool = _rng.randf_range(0.4, 1.2)
	_strafe = 1.0 if _rng.randf() < 0.5 else -1.0
	if enemy_affix != "" and not is_boss:
		_set_affix(enemy_affix)


## An elite: one affix, more vitality and more essence, and a glow to warn you.
func _set_affix(a: String) -> void:
	affix = a
	var info: Dictionary = Bestiary.AFFIXES[a]
	display_name = "%s %s" % [String(info["word"]), display_name]
	max_hp *= 1.35
	essence *= 1.8
	match a:
		"stone":
			max_hp *= 1.5
			posture_max *= 1.5
			armored = true
		"swift":
			pass
	hp = max_hp
	var col: Color = info["color"]
	var ring := ForgeMesh.inst(ForgeMesh.ring(0.8, 24), ForgeMesh.glow(col, 2.0), self, Vector3(0, 0.08, 0))
	ring.scale = Vector3.ONE * (radius + 0.6)
	ring.set_meta("no_ghost", true)
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = 1.4
	l.omni_range = 5.0
	l.position = Vector3(0, 1.2, 0)
	add_child(l)


func _aim_dir(origin: Vector3) -> Vector3:
	if target != null and is_instance_valid(target):
		return (target.center() - origin).normalized()
	return forward()


func move_def(id: String) -> Dictionary:
	for m: Variant in moves:
		if String((m as Dictionary)["id"]) == id:
			return m
	return {}


func stagger_time() -> float:
	return 3.2 if is_boss and not is_echo else (2.0 if is_echo else 1.7)


func wake(by: Actor) -> void:
	if not aggro and alive and not dormant and not passive:
		aggro = true
		target = by
		if not is_boss:
			Sfx.play("growl", -8.0, 1.0, 0.2)


## The player has begun a swing. Humanoid enemies may answer it.
func threatened(attacker: Actor, m: Dictionary) -> void:
	if not alive or state != St.FREE or _react_t >= 0.0 or dormant or knocked:
		return
	var d := flat_to(attacker.global_position).length()
	if d > float(m.get("reach", 2.5)) * attacker.reach_scale + 2.0:
		return
	if bool(m.get("crit", false)):
		# a red blow is not blocked; those who can, get out of its way
		if reacts and _rng.randf() < 0.25 + 0.5 * mobility:
			_react_kind = "dash"
			_react_t = _rng.randf_range(0.05, 0.16)
		return
	if not reacts:
		# ordinary fighters with hands guard the back half of a string
		var pl := attacker as Player
		var feral := bool((def["body"] as Dictionary).get("feral", false))
		if not feral and not is_boss and pl != null and pl.combo_i >= 2 and _rng.randf() < 0.22:
			_react_kind = "block"
			_react_t = _rng.randf_range(0.02, 0.12)
		return
	var roll := _rng.randf()
	if roll < 0.22 + 0.4 * patience:
		_react_kind = "block"
		_react_t = _rng.randf_range(0.0, 0.14)
	elif roll < 0.22 + 0.4 * patience + 0.3 * mobility:
		_react_kind = "dash"
		_react_t = _rng.randf_range(0.02, 0.1)


func _physics_process(delta: float) -> void:
	if place == null:
		return
	_tick_common(delta)
	if carried_by != null:
		_tick_carried()
		return
	if thrown_t > 0.0:
		_tick_thrown(delta)
		return
	if knocked and alive:
		_tick_knocked(delta)
		return
	if not alive:
		_tick_remnant(delta)
		_apply_gravity(delta)
		velocity.x = move_toward(velocity.x, 0.0, 30.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 30.0 * delta)
		move_and_slide()
		return
	if yielded:
		velocity = Vector3.ZERO
		return
	_since_hurt += delta
	var regen := float(def.get("regen", 0.0))
	if regen > 0.0 and _since_hurt > 3.0 and hp < max_hp and dot_t <= 0.0:
		hp = minf(max_hp, hp + max_hp * regen * delta)
	_cool -= delta
	match state:
		St.FREE:
			_think(delta)
		St.BLOCK:
			_block_t -= delta
			blocking = true
			velocity.x = move_toward(velocity.x, 0.0, 40.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 40.0 * delta)
			if target != null and is_instance_valid(target):
				face(flat_to(target.global_position), delta, 12.0)
			if _block_t <= 0.0:
				set_state(St.FREE)
				rig.play(idle_clip(), 0.15)
		St.ATTACK:
			_tick_attack_enemy(delta)
		St.DASH:
			if state_t >= state_len:
				collision_mask = 1 | 2
				set_state(St.FREE)
				rig.play(idle_clip(), 0.15)
		St.HIT, St.STAGGER:
			_tick_recover(delta)
		St.BUSY:
			velocity.x = move_toward(velocity.x, 0.0, 40.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 40.0 * delta)
			if state_len > 0.0 and state_t >= state_len:
				set_state(St.FREE)
				rig.play(idle_clip(), 0.2)
	if not _leaping:
		_apply_gravity(delta)
		var pre := velocity
		move_and_slide()
		_wall_bounce(pre)
		_keep_in_world()
	rig.sway = clampf(Vector2(velocity.x, velocity.z).length() / 8.0, 0.0, 1.2)
	_check_phase()


func _think(delta: float) -> void:
	if dormant:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var p := place.player
	if not aggro and march_to != Vector3.INF:
		var mto := flat_to(march_to)
		var mdir := mto.normalized()
		velocity.x = move_toward(velocity.x, mdir.x * float(def["speed"]) * 0.8, 20.0 * delta)
		velocity.z = move_toward(velocity.z, mdir.z * float(def["speed"]) * 0.8, 20.0 * delta)
		face(mdir, delta, 3.0)
		rig.play(run_clip(), 0.2, 0.7)
		home = global_position
		if p != null and p.alive and flat_to(p.global_position).length() < aggro_range * place.sight_scale():
			wake(p)
		return
	if not aggro:
		velocity.x = move_toward(velocity.x, 0.0, 30.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 30.0 * delta)
		rig.play(idle_clip(), 0.2)
		if p != null and p.alive and flat_to(p.global_position).length() < aggro_range * place.sight_scale():
			wake(p)
		return
	if target == null or not is_instance_valid(target) or not target.alive:
		aggro = false
		target = null
		return
	place.touch_combat()
	var to := flat_to(target.global_position)
	var d := to.length()
	if not is_boss and flat_to(home).length() > leash:
		aggro = false
		hp = max_hp
		return
	if _react_t >= 0.0:
		_react_t -= delta
		if _react_t < 0.0:
			_do_react(to)
			return
	var dir := to / maxf(d, 0.01)
	face(dir, delta, 7.0)
	var want := float(def["range"])
	var keep := float(def.get("keep", 0.0))
	# only a few press at once; the rest hold a ring round the fight
	var pressing := is_boss or keep > 0.0 or place.attack_token(self)
	if not pressing:
		want = maxf(want, 4.5) + 3.0
	# a swing that missed is an opening
	var pl := target as Player
	if pressing and pl != null and pl.state == St.ATTACK and not pl.move_hit and pl.state_t > float(pl.move.get("startup", 0.2)) + float(pl.move.get("active", 0.1)) and d < float(def["range"]) + 1.5:
		_cool = minf(_cool, 0.05)
	# the quick ones close a long gap in a burst
	_gap_cd -= delta
	if pressing and not is_boss and keep <= 0.0 and mobility >= 0.45 and _gap_cd <= 0.0 and d > 6.0 and d < 15.0:
		_gap_cd = _rng.randf_range(4.0, 7.0)
		velocity.x = dir.x * 22.0
		velocity.z = dir.z * 22.0
		set_state(St.DASH, 0.22)
		collision_mask = 1
		rig.play("dash", 0.04, 1.0, true)
		Fx.ghost(rig, accent)
		Sfx.play("dash", -8.0)
		return
	var speed := float(def["speed"]) * speed_factor() * (1.25 if phase >= 2 else 1.0) * (1.35 if affix == "swift" else 1.0)
	var v := Vector3.ZERO
	if keep > 0.0 and d < keep:
		v = -dir * speed * 0.8
	elif d > want * 0.85:
		v = dir * speed
	else:
		_strafe_t -= delta
		if _strafe_t <= 0.0:
			_strafe_t = _rng.randf_range(0.8, 1.8)
			_strafe = -_strafe if _rng.randf() < 0.5 else _strafe
		v = dir.cross(Vector3.UP) * _strafe * speed * 0.45
	velocity.x = move_toward(velocity.x, v.x, 30.0 * delta)
	velocity.z = move_toward(velocity.z, v.z, 30.0 * delta)
	if Vector2(velocity.x, velocity.z).length() > 0.6:
		rig.play(run_clip(), 0.15, clampf(Vector2(velocity.x, velocity.z).length() / 5.0, 0.5, 1.4))
	else:
		rig.play(idle_clip(), 0.2)
	if _cool <= 0.0 and pressing:
		var m := _choose(d)
		if not m.is_empty():
			_commit(m)
			place.hold_token(self)


func _choose(d: float) -> Dictionary:
	if _next != "":
		var m := move_def(_next)
		_next = ""
		return m
	var weights := {}
	for mv: Variant in moves:
		var m: Dictionary = mv
		var w := float(m.get("w", 1.0))
		if w <= 0.0:
			continue
		if d < float(m.get("min", 0.0)) or d > float(m.get("max", 999.0)):
			continue
		var kind_of := String(m.get("type", "strike"))
		var reach := float(m["reach"]) * reach_scale + float(m.get("lunge", 0.0)) * 0.3
		if kind_of == "strike" and d > reach + 0.6:
			continue
		if kind_of == "ring" and d > float(m["reach"]) * reach_scale * 0.9:
			continue
		weights[String(m["id"])] = w
	if weights.is_empty():
		return {}
	return move_def(Rng.weighted(_rng, weights))


func _commit(m: Dictionary) -> void:
	var out := m.duplicate()
	var haste := (1.18 if phase >= 2 else 1.0) / (1.35 if slow_t > 0.0 else 1.0) * (1.25 if affix == "swift" else 1.0) * (1.15 if enraged else 1.0)
	out["startup"] = float(m["startup"]) / haste
	out["recover"] = float(m["recover"]) / haste
	out["dmg"] = float(m["dmg"]) * (1.0 + DMG_GROW * float(level - 1))
	out["color"] = accent
	out["kind"] = "enemy"
	_warned = false
	_next = String(m.get("then", ""))
	var cool: Array = def["cool"]
	_cool = float(out["startup"]) + float(out["active"]) + float(out["recover"]) + (_rng.randf_range(float(cool[0]), float(cool[1])) * (0.6 if enraged else 1.0) if _next == "" else 0.0)
	if is_boss and _next == "":
		_swings += 1
	if target != null and is_instance_valid(target):
		face_now(flat_to(target.global_position))
	if String(out.get("type", "")) == "leap":
		_leap_from = global_position
		var tp := target.global_position if target != null else global_position
		_leap_to = Vector3(tp.x, place.height_at(tp.x, tp.z), tp.z)
		Fx.warn(_leap_to, float(out["reach"]) * reach_scale, Color(1, 0.1, 0.1), float(out["startup"]))
		Sfx.play("growl", -2.0, 0.7)
	start_attack(out)
	# the tell: a glint on the mask. Red means it cannot be guarded.
	var red := bool(out.get("red", false))
	Fx.sparks(global_position + Vector3(0, rig.height * 0.92, 0) + forward() * radius, Color(1, 0.1, 0.1) if red else Color(1, 1, 1), 5 if red else 3, 3.0)
	if red:
		Sfx.play("warn", -3.0)
		Fx.word(center() + Vector3(0, rig.height * 0.55, 0), "!", Color(1, 0.15, 0.15), 1.3)


func _tick_attack_enemy(delta: float) -> void:
	var startup := float(move["startup"])
	if state_t < startup * 0.7 and target != null and is_instance_valid(target):
		face(flat_to(target.global_position), delta, 6.0)
	if String(move.get("type", "")) == "leap":
		_tick_leap(delta)
		return
	_tick_attack(delta)


func _tick_leap(delta: float) -> void:
	var startup := float(move["startup"])
	var lift := startup * 0.3
	if state_t < lift:
		velocity = Vector3.ZERO
	elif state_t < startup:
		if not _leaping:
			_leaping = true
			collision_mask = 0
			rig.play("f_leap", 0.1, 1.0, true)
			Sfx.play("jump", -2.0, 0.6)
		var u := clampf((state_t - lift) / (startup - lift), 0.0, 1.0)
		var flat := _leap_from.lerp(_leap_to, u)
		global_position = Vector3(flat.x, lerpf(_leap_from.y, _leap_to.y, u) + sin(u * PI) * 7.0, flat.z)
	elif not move_hit:
		_leaping = false
		collision_mask = 1 | 2
		global_position = _leap_to + Vector3(0, 0.05, 0)
		velocity = Vector3.ZERO
		move_hit = true
		rig.play_clip(Poses.attack("f_slam", 0.01, 0.05, float(move["recover"]), Poses.F_IDLE), 0.04)
		var reach := float(move["reach"]) * reach_scale
		Fx.ring(global_position + Vector3(0, 0.15, 0), Color(1, 0.2, 0.2), 0.5, reach, 0.45)
		Fx.ring(global_position + Vector3(0, 0.3, 0), Color(1, 1, 1), 0.3, reach * 1.4, 0.6, 0.94)
		Fx.puff(global_position, Color(0.85, 0.85, 0.88, 0.7), 30, 1.4)
		Fx.add_shake(1.0)
		Fx.hitstop(0.08)
		Sfx.play("slam", 2.0)
		place.sweep(self, move)
	elif state_t >= state_len:
		set_state(St.FREE)


func _do_react(to: Vector3) -> void:
	if state != St.FREE:
		return
	if _react_kind == "block":
		set_state(St.BLOCK)
		blocking = true
		block_age = 0.0
		parry_window = 0.03 + 0.11 * patience
		_block_t = _rng.randf_range(0.45, 0.8)
		rig.play("block", 0.05, 1.0, true)
	else:
		var side := to.normalized().cross(Vector3.UP) * (1.0 if _rng.randf() < 0.5 else -1.0)
		var dir := (side - to.normalized() * 0.6).normalized()
		velocity.x = dir.x * 19.0
		velocity.z = dir.z * 19.0
		set_state(St.DASH, 0.2)
		invuln = 0.18
		dash_age = 0.2
		collision_mask = 1
		rig.play("dash", 0.04, 1.0, true)
		Fx.ghost(rig, accent)
		Sfx.play("dash", -8.0)


func _check_phase() -> void:
	if not is_boss or is_echo or not alive:
		return
	# out of breath: after every few swings a great enemy stops, open
	if _swings >= 4 and state == St.FREE and _next == "":
		_swings = 0
		set_state(St.BUSY, 1.4 if not enraged else 1.0)
		rig.play("hit", 0.2)
		posture = minf(posture_max, posture + posture_max * 0.08)
		Fx.puff(center() + Vector3(0, rig.height * 0.3, 0), Color(0.85, 0.85, 0.88, 0.5), 6, 0.8)
		Fx.word(center() + Vector3(0, rig.height * 0.6, 0), "WINDED", Color(0.84, 0.81, 0.75), 0.9)
		return
	# the last rage: at a quarter it speeds up and stops resting as long
	if phase >= 2 and not enraged and hp <= max_hp * 0.25 and state == St.FREE:
		enraged = true
		set_state(St.BUSY, 1.0)
		invuln = 1.1
		rig.play("f_roar", 0.1, 1.0, true)
		Sfx.play("roar", 2.0, 0.85)
		Fx.ring(global_position + Vector3(0, 0.3, 0), Color(1.0, 0.25, 0.15), 1.0, 14.0, 0.7)
		Fx.add_shake(0.9)
		rig.flash(1.0)
		place.say("%s is enraged." % display_name, "toast")
		return
	if phase >= 2:
		return
	if hp <= max_hp * 0.5 and state == St.FREE:
		phase = 2
		for m: Variant in def.get("phase2", []):
			moves.append(m)
		# every great enemy learns to grab: red, unguardable, only dodged
		if not bool(def.get("no_grab", false)):
			var base_dmg := 20.0
			for mv: Variant in moves:
				base_dmg = maxf(base_dmg, float((mv as Dictionary).get("dmg", 0.0)))
			moves.append({"id": "grab", "clip": "thrust", "type": "strike", "startup": 0.62, "active": 0.12, "recover": 1.0, "dmg": base_dmg * 0.9, "posture": 0.0, "reach": 2.0, "arc": 70.0, "lunge": 8.0, "grab": true, "red": true, "blockable": false, "parryable": false, "w": 1.4, "sfx": "whoosh_heavy"})
		set_state(St.BUSY, 1.8)
		invuln = 1.9
		_cool = 2.2
		rig.play("f_roar", 0.1, 1.0, true)
		Sfx.play("roar", 3.0)
		Fx.pillar(global_position, accent, 40.0, 3.0, 1.6)
		Fx.ring(global_position + Vector3(0, 0.3, 0), accent, 1.0, 22.0, 0.9)
		Fx.add_shake(1.2)
		Fx.add_blur(0.8)
		Fx.screen_flash(accent, 0.3)
		place.say(String(def.get("phase_line", "It changes.")), "boss")
		var p := place.player
		if p != null and p.alive and flat_to(p.global_position).length() < 9.0:
			p.push += -p.flat_to(global_position).normalized() * 16.0


func parried_by(defender: Actor, extra_posture: float) -> void:
	super.parried_by(defender, extra_posture)
	_next = ""
	_cool = maxf(_cool, 0.5)


func receive(res: Dictionary, attacker: Actor, m: Dictionary) -> bool:
	if float(res.get("dmg", 0.0)) > 0.0:
		_since_hurt = 0.0
	if not aggro and not passive and attacker != null and is_instance_valid(attacker):
		dormant = false
		wake(attacker)
	var outcome := String(res["outcome"])
	if knocked and alive and outcome != "dodged" and outcome != "parried" and float(res.get("dmg", 0.0)) > 0.0:
		# a kneeling body is finished by anything
		hp = 0.0
		knocked = false
		die(attacker)
		return true
	if _can_be_knocked(m) and hp - float(res.get("dmg", 0.0)) * (1.0 if ward_t <= 0.0 else 0.2) <= 0.0 and outcome == "hit":
		knock_down()
		return false
	if is_echo and hp - float(res.get("dmg", 0.0)) <= 0.0 and String(res["outcome"]) != "dodged" and String(res["outcome"]) != "parried":
		# the spirit does not die. It kneels.
		hp = 1.0
		yielded = true
		set_state(St.BUSY)
		rig.play("kneel", 0.3, 1.0, true)
		place.on_death(self, attacker)
		return true
	return super.receive(res, attacker, m)


## Which blows knock rather than kill: ordinary ones on ordinary enemies.
## Finishers, criticals, executions, techniques and releases kill outright.
func _can_be_knocked(m: Dictionary) -> bool:
	if is_boss or is_echo or knocked or not alive:
		return false
	if m.has("finisher") or bool(m.get("crit", false)) or bool(m.get("execution", false)):
		return false
	return String(m.get("kind", "")) in ["light", "heavy", "air", "ranged"]


func knock_down() -> void:
	knocked = true
	knocked_t = KNOCK_TIME
	gripped = false
	hp = 1.0
	posture = 0.0
	velocity = Vector3(velocity.x, maxf(velocity.y, 0.0), velocity.z) * 0.5
	set_state(St.BUSY, 0.0)
	rig.play("kneel", 0.15, 1.0, true)
	Fx.puff(global_position, Color(0.75, 0.74, 0.72, 0.6), 8, 0.5)
	Fx.word(center() + Vector3(0, rig.height * 0.5, 0), "KNOCKED", Color(0.84, 0.81, 0.75), 0.9)
	Sfx.play("knocked", -3.0)


func _tick_knocked(delta: float) -> void:
	if gripped:
		var g := gripped_by as Player
		if g == null or not is_instance_valid(g) or g.state != St.BUSY or g.busy_kind != "grip":
			gripped = false
	if not gripped:
		knocked_t -= delta
	velocity.x = move_toward(velocity.x, 0.0, 30.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 30.0 * delta)
	rig.flinch = 0.2 + 0.1 * sin(state_t * 3.0)
	_apply_gravity(delta)
	move_and_slide()
	_keep_in_world()
	if knocked_t <= 0.0:
		# nobody finished it: it gets back up, hurt
		knocked = false
		hp = max_hp * 0.25
		set_state(St.FREE)
		rig.play(idle_clip(), 0.3)
		Fx.puff(global_position, Color(0.75, 0.74, 0.72, 0.6), 6, 0.5)


## Carried over a shoulder: it goes where the carrier goes.
func _tick_carried() -> void:
	if not is_instance_valid(carried_by) or not carried_by.alive:
		carried_by = null
		return
	var c := carried_by
	global_position = c.global_position + Vector3(0, c.rig.height * 0.78, 0) - c.forward() * 0.15
	rotation.y = c.rotation.y + PI * 0.5
	rig.rotation.x = 0.0
	rig.rotation.z = -1.45
	velocity = Vector3.ZERO


func pick_up(by: Actor) -> void:
	carried_by = by
	collision_layer = 0
	collision_mask = 0
	Sfx.play("guard", -6.0, 0.8)


func put_down() -> void:
	if carried_by == null:
		return
	var c := carried_by
	carried_by = null
	global_position = c.global_position + c.forward() * 1.2 + Vector3(0, 0.3, 0)
	rig.rotation.z = 0.0
	collision_mask = 1
	collision_layer = 2 if alive else 0


## Thrown: a body in flight that hits the first enemy it reaches.
func throw_from(by: Actor, dir: Vector3) -> void:
	carried_by = null
	thrown_by = by
	thrown_t = 1.6
	global_position = by.global_position + Vector3(0, 1.0, 0) + dir * 1.0
	velocity = dir * 20.0 + Vector3(0, 2.0, 0)
	collision_mask = 1
	collision_layer = 0
	Sfx.play("whoosh_heavy", -2.0, 0.8)


func _tick_thrown(delta: float) -> void:
	thrown_t -= delta
	rig.rotation.z = lerpf(rig.rotation.z, -1.45, 0.2)
	rig.rotation.x += delta * 6.0
	velocity.y -= GRAVITY * delta
	move_and_slide()
	_keep_in_world()
	for a in place.enemies_alive():
		if a == self or not is_instance_valid(thrown_by):
			continue
		var gap := Vector2(a.global_position.x - global_position.x, a.global_position.z - global_position.z).length()
		if gap < 1.3 + a.radius and absf(a.global_position.y - global_position.y) < 2.5:
			var p := thrown_by as Player
			var dmg := float(p.stats["light_dmg"]) * 1.8 if p != null else 20.0
			place.strike(thrown_by, a, {"kind": "thrown", "dmg": dmg, "posture": 22.0, "knock": 9.0, "launch": 4.0, "heavy": true, "from": global_position, "color": Color(0.9, 0.9, 0.88)})
			Fx.add_shake(0.5)
			_land_thrown()
			return
	if thrown_t <= 0.0 or (is_on_floor() and thrown_t < 1.45):
		_land_thrown()


func _land_thrown() -> void:
	thrown_t = 0.0
	rig.rotation.x = 0.0
	rig.rotation.z = 0.0
	Fx.puff(global_position, Color(0.75, 0.74, 0.72, 0.7), 10, 0.6)
	Sfx.play("body", -2.0)
	velocity = Vector3.ZERO
	if knocked and alive:
		# thrown into the ground, a kneeling body does not get up
		knocked = false
		hp = 0.0
		die(thrown_by)
	elif alive:
		collision_layer = 2
	thrown_by = null


func die(killer: Actor) -> void:
	_leaping = false
	knocked = false
	carried_by = null
	super.die(killer)
	remnant = not is_boss
	remnant_t = 14.0
	if bool(def.get("reforms", false)):
		remnant_t = 12.0
	if affix == "volatile" and place != null:
		var at := global_position
		var pl := place
		Fx.warn(at, 3.6, Color(1, 0.4, 0.1), 0.7)
		get_tree().create_timer(0.7, false).timeout.connect(func() -> void:
			if is_instance_valid(pl) and pl.player != null and pl.player.alive:
				Fx.ring(at + Vector3(0, 0.3, 0), Color(1, 0.5, 0.1), 0.4, 3.6, 0.4)
				Fx.sparks(at + Vector3(0, 0.6, 0), Color(1, 0.5, 0.1), 20, 10.0)
				Sfx.play("slam", -2.0, 1.3)
				var pp: Player = pl.player
				if pp.global_position.distance_to(at) < 3.6 and pp.invuln <= 0.0:
					pp.receive({"outcome": "hit", "dmg": 22.0, "posture": 18.0, "stagger": true}, null, {"knock": 6.0})
					Fx.impact(pp.center(), Color(1, 0.5, 0.1), true))
	if remnant:
		_wisp = ForgeMesh.inst(ForgeMesh.shard(0.5, 0.12, 4), ForgeMesh.glow(Color(0.85, 0.95, 1.0), 4.0), self, Vector3(0, 1.2, 0))
		_wisp.set_meta("no_ghost", true)


func _tick_remnant(delta: float) -> void:
	if not remnant:
		if is_boss and state_t > 6.0:
			pass
		return
	remnant_t -= delta
	if _wisp != null:
		_wisp.rotation.y += delta * 2.0
		_wisp.position.y = 1.2 + sin(remnant_t * 2.0) * 0.12
	if remnant_t <= 0.0:
		if bool(def.get("reforms", false)):
			_reform()
		else:
			consume(Color(0.8, 0.8, 0.85))


## A Gaoler that nobody devoured or sent on gets up again.
func _reform() -> void:
	remnant = false
	if _wisp != null:
		_wisp.queue_free()
		_wisp = null
	alive = true
	hp = max_hp
	posture = 0.0
	collision_layer = 2
	collision_mask = 1 | 2
	set_state(St.BUSY, 1.4)
	rig.play("release", 0.2, 1.0, true)
	Fx.pillar(global_position, accent, 16.0, 1.2, 0.9)
	Sfx.play("growl", 0.0, 0.6)
	if place != null:
		place.say("The Gaoler pulls itself back together.", "hint")


## The body goes: devoured, sent on, or simply blown away.
func consume(color: Color) -> void:
	remnant = false
	Fx.puff(global_position + Vector3(0, 0.4, 0), Color(color.r, color.g, color.b, 0.7), 20, 0.8)
	Fx.sparks(global_position + Vector3(0, 0.6, 0), color, 14, 6.0)
	if place != null:
		place.actors.erase(self)
	queue_free()
