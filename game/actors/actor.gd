class_name Actor
extends CharacterBody3D
## Anything that fights. The player and every enemy share this body: the same
## states, the same blows, the same rules for being hit.

enum St { FREE, ATTACK, DASH, BLOCK, HIT, STAGGER, BUSY, DEAD }

const GRAVITY: float = 28.0

var place: Place
var rig: BlockRig
var team: int = 1
var display_name: String = ""
var accent: Color = Color(0.9, 0.9, 0.95)

var max_hp: float = 100.0
var hp: float = 100.0
var posture_max: float = 60.0
var posture: float = 0.0
var posture_rest: float = 0.0
var radius: float = 0.45
var reach_scale: float = 1.0
var parry_window: float = 0.17
var armored: bool = false
var alive: bool = true
var yielded: bool = false

var state: St = St.FREE
var state_t: float = 0.0
var state_len: float = 0.0
var move: Dictionary = {}
var move_hit: bool = false
var move_whoosh: bool = false
var swing: int = 0
var blocking: bool = false
var block_age: float = 9.0
var invuln: float = 0.0
var dash_age: float = 9.0
var counter_t: float = 0.0
var ward_t: float = 0.0

var slow_t: float = 0.0
var weak_t: float = 0.0
var weak_amount: float = 0.0
var dot_t: float = 0.0
var dot_dps: float = 0.0
var dot_from: int = 0
var airborne_t: float = 0.0
var push: Vector3 = Vector3.ZERO
var feral: bool = false


func build_body(spec: Dictionary) -> void:
	rig = BlockRig.new()
	add_child(rig)
	rig.build(spec)
	feral = bool(rig.spec["feral"])
	var s := float(rig.spec["scale"])
	radius = 0.44 * s * float(rig.spec["bulk"]) * (1.15 if feral else 1.0)
	reach_scale = s
	var shape := CapsuleShape3D.new()
	shape.radius = radius
	shape.height = maxf(rig.height, radius * 2.0 + 0.1)
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position.y = shape.height * 0.5
	add_child(col)
	collision_layer = 2
	collision_mask = 1 | 2
	floor_snap_length = 0.4
	# rig is built facing -Z, which is Godot's forward
	rig.play(idle_clip(), 0.0)


func idle_clip() -> String:
	return "f_idle" if feral else "idle"


func run_clip() -> String:
	return "f_run" if feral else "run"


func forward() -> Vector3:
	var f := -global_transform.basis.z
	f.y = 0.0
	return f.normalized() if f.length_squared() > 0.0001 else Vector3.FORWARD


func center() -> Vector3:
	return global_position + Vector3(0, rig.height * 0.55, 0)


func flat_to(point: Vector3) -> Vector3:
	var d := point - global_position
	d.y = 0.0
	return d


func face(dir: Vector3, delta: float, rate: float = 14.0) -> void:
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		return
	var want := atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, want, clampf(rate * delta, 0.0, 1.0))


func face_now(dir: Vector3) -> void:
	face(dir, 1.0, 1.0)


func speed_factor() -> float:
	return 0.6 if slow_t > 0.0 else 1.0


func damage_factor() -> float:
	return (1.0 - weak_amount) if weak_t > 0.0 else 1.0


func set_state(s: St, length: float = 0.0) -> void:
	state = s
	state_t = 0.0
	state_len = length
	if s != St.BLOCK:
		blocking = false


func busy() -> bool:
	return state != St.FREE and state != St.BLOCK


## Begins a blow. `m` carries its timings and what it does when it lands.
func start_attack(m: Dictionary) -> void:
	move = m
	move_hit = false
	move_whoosh = false
	swing += 1
	set_state(St.ATTACK, float(m["startup"]) + float(m["active"]) + float(m["recover"]))
	rig.play_clip(Poses.attack(String(m["clip"]), float(m["startup"]), float(m["active"]), float(m["recover"]),
		Poses.F_IDLE if feral else Poses.IDLE), 0.07)
	if place != null:
		place.on_swing(self, m)


func _tick_attack(delta: float) -> void:
	var startup := float(move["startup"])
	var active := float(move["active"])
	if not move_whoosh and state_t >= startup * 0.8:
		move_whoosh = true
		Sfx.play(String(move.get("sfx", "whoosh")), -6.0, float(move.get("pitch", 1.0)))
	var lunge := float(move.get("lunge", 0.0))
	if lunge > 0.0 and state_t >= startup * 0.55 and state_t <= startup + active:
		var f := forward()
		velocity.x = f.x * lunge * speed_factor()
		velocity.z = f.z * lunge * speed_factor()
	else:
		velocity.x = move_toward(velocity.x, 0.0, 60.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 60.0 * delta)
	if not move_hit and state_t >= startup:
		move_hit = true
		_strike()
	if state_t >= state_len:
		set_state(St.FREE)
		_attack_done()


func _attack_done() -> void:
	pass


## The moment a blow goes active.
func _strike() -> void:
	if place == null:
		return
	var kind := String(move.get("type", "strike"))
	var col: Color = move.get("color", accent)
	match kind:
		"strike":
			var roll := float(move.get("roll", 0.0))
			var reach := float(move["reach"]) * reach_scale
			var t := Transform3D(Basis(Vector3.UP, rotation.y) * Basis(Vector3.FORWARD, deg_to_rad(roll)), global_position + Vector3(0, rig.height * 0.58, 0))
			Fx.slash(t, reach, float(move["arc"]), col, 0.2, reach * 0.36)
			place.sweep(self, move)
		"bolt":
			var origin := global_position + Vector3(0, rig.height * 0.68, 0) + forward() * (0.6 + radius)
			var aim := _aim_dir(origin)
			var count := int(move.get("count", 1))
			var spread := deg_to_rad(float(move.get("spread", 12.0)))
			for i in range(count):
				var turn := (float(i) - float(count - 1) * 0.5) * spread
				place.fire(self, origin, aim.rotated(Vector3.UP, turn), move)
		"ring":
			Fx.ring(global_position + Vector3(0, 0.15, 0), col, 0.4, float(move["reach"]) * reach_scale, 0.4)
			Fx.puff(global_position, Color(0.8, 0.8, 0.82, 0.6), 16, 0.8)
			Fx.add_shake(0.5)
			place.sweep(self, move)
		"wave":
			place.shockwave(self, global_position, move)


func _aim_dir(_origin: Vector3) -> Vector3:
	return forward()


## What the rules need to know about this body when a blow reaches it.
func defence(from: Vector3) -> Dictionary:
	var to := flat_to(from)
	var facing := true
	if to.length_squared() > 0.01:
		facing = forward().dot(to.normalized()) > -0.2
	return {
		"invulnerable": invuln > 0.0 or state == St.DEAD or yielded,
		"dash_age": dash_age,
		"blocking": blocking or counter_t > 0.0,
		"block_age": 0.0 if counter_t > 0.0 else block_age,
		"facing": facing or counter_t > 0.0,
		"parry_window": parry_window,
		"posture": posture,
		"posture_max": posture_max,
		"armored": armored or (state == St.ATTACK and bool(move.get("armor", false)) and state_t > 0.1),
	}


## Takes what the rules decided. Returns true if this body died of it.
func receive(res: Dictionary, attacker: Actor, m: Dictionary) -> bool:
	var outcome := String(res["outcome"])
	if outcome == "dodged" or outcome == "parried":
		return false
	var dmg := float(res["dmg"])
	if ward_t > 0.0:
		dmg *= 0.2
	hp -= dmg
	posture = minf(posture_max, posture + float(res["posture"]))
	posture_rest = 2.2
	rig.flash(1.0 if outcome == "hit" else 0.4)
	if hp <= 0.0:
		if _survive_lethal():
			hp = 1.0
		else:
			hp = 0.0
			# the killing blow still throws the body
			if attacker != null and is_instance_valid(attacker):
				push = -flat_to(attacker.global_position).normalized() * float(m.get("knock", 2.5))
			if float(m.get("launch", 0.0)) > 0.0:
				velocity.y = float(m["launch"])
			die(attacker)
			return true
	if bool(res.get("broke", false)):
		break_stance()
	elif bool(res["stagger"]) and outcome == "hit":
		var knock := float(m.get("knock", 2.5))
		if attacker != null and is_instance_valid(attacker):
			var away := -flat_to(attacker.global_position).normalized()
			push = away * knock
		if float(m.get("launch", 0.0)) > 0.0:
			velocity.y = float(m["launch"])
			airborne_t = 0.9
		rig.flinch = 1.0
		if state != St.STAGGER:
			# a big knock keeps a body helpless for its whole flight
			set_state(St.HIT, maxf(0.34 if not bool(m.get("heavy", false)) else 0.5, 0.2 + knock * 0.04))
			rig.play("hit", 0.04, 1.0, true)
	elif outcome == "blocked":
		rig.flinch = 0.5
		if attacker != null and is_instance_valid(attacker):
			push = -flat_to(attacker.global_position).normalized() * 2.0
	return false


func _survive_lethal() -> bool:
	return false


## A full stance bar: the body is open for a long moment.
func break_stance() -> void:
	posture = 0.0
	set_state(St.STAGGER, stagger_time())
	rig.play("stagger", 0.08, 1.0, true)
	Sfx.play("break", -2.0)
	Fx.word(center() + Vector3(0, rig.height * 0.5, 0), "BROKEN", Color(1.0, 0.85, 0.4), 1.1)
	Fx.ring(center(), Color(1.0, 0.85, 0.4), 0.3, 3.0 * reach_scale, 0.35)


func stagger_time() -> float:
	return 1.5


## A parry landed on this body's blow.
func parried_by(defender: Actor, extra_posture: float) -> void:
	posture = minf(posture_max, posture + extra_posture)
	posture_rest = 2.5
	if posture >= posture_max:
		break_stance()
	elif not armored:
		set_state(St.HIT, 0.55)
		rig.play("hit", 0.04, 1.0, true)
		push = -flat_to(defender.global_position).normalized() * 3.0


func die(_killer: Actor) -> void:
	alive = false
	set_state(St.DEAD)
	rig.play("dead", 0.06, 1.0, true)
	collision_layer = 0
	collision_mask = 1
	# a body keeps what threw it: it slides, flies and settles where it lands
	velocity = Vector3(velocity.x + push.x, maxf(velocity.y, 0.0), velocity.z + push.z) * 0.85
	push = Vector3.ZERO
	_death_bounce = true
	if rig != null:
		rig.rotation.z = randf_range(-0.35, 0.35)
	if place != null:
		place.on_death(self, _killer)


func heal(amount: float) -> void:
	hp = minf(max_hp, hp + amount)


func apply_effect(effect: String, power: float, source: Actor) -> void:
	match effect:
		"dot":
			dot_t = 3.0
			dot_dps = maxf(dot_dps, 5.0 * power)
			dot_from = source.get_instance_id() if source != null else 0
		"slow":
			slow_t = 2.6 * power
		"weaken":
			weak_t = 4.0
			weak_amount = clampf(0.25 * power, 0.0, 0.6)


## Flung bodies tip over backwards while they fly, and right themselves
## with a puff when they land: the genre's ragdoll fling, kept light.
var _tumble: float = 0.0
var _death_bounce: bool = false
var _landed: bool = true

func _tick_tumble(delta: float) -> void:
	if rig == null:
		return
	var flying := (state == St.HIT or state == St.STAGGER or state == St.DEAD) and not is_on_floor() and (airborne_t > 0.0 or Vector2(velocity.x, velocity.z).length() > 6.0)
	if state == St.DEAD and _death_bounce and is_on_floor() and Vector2(velocity.x, velocity.z).length() > 4.0:
		# one limp bounce when a flung body meets the ground
		_death_bounce = false
		velocity.y = 3.0
		Fx.puff(global_position, Color(0.75, 0.74, 0.72, 0.6), 6, 0.5)
	if flying:
		_tumble = minf(1.0, _tumble + delta * 4.0)
	elif _tumble > 0.0:
		if _tumble > 0.6 and is_on_floor() and not _landed:
			_landed = true
			Fx.puff(global_position, Color(0.75, 0.74, 0.72, 0.6), 6, 0.5)
		_tumble = maxf(0.0, _tumble - delta * (6.0 if is_on_floor() else 2.0))
	if flying:
		_landed = false
	rig.rotation.x = -1.1 * _tumble


func _tick_common(delta: float) -> void:
	_tick_tumble(delta)
	state_t += delta
	block_age += delta
	dash_age += delta
	invuln = maxf(0.0, invuln - delta)
	counter_t = maxf(0.0, counter_t - delta)
	ward_t = maxf(0.0, ward_t - delta)
	slow_t = maxf(0.0, slow_t - delta)
	weak_t = maxf(0.0, weak_t - delta)
	airborne_t = maxf(0.0, airborne_t - delta)
	if posture_rest > 0.0:
		posture_rest -= delta
	elif posture > 0.0 and state != St.STAGGER:
		posture = maxf(0.0, posture - posture_max * 0.22 * delta)
	if dot_t > 0.0 and alive:
		dot_t -= delta
		hp -= dot_dps * delta
		if hp <= 0.0:
			hp = 0.0
			var src: Object = instance_from_id(dot_from) if dot_from != 0 else null
			die(src as Actor)
	if push.length_squared() > 0.01:
		velocity.x += push.x
		velocity.z += push.z
		push = Vector3.ZERO


## A body knocked hard into a wall bounces off it: a little harm, a puff of
## dust, and longer on its back foot, open to a follow-up. Once per knock.
var _bounced: bool = false

func _wall_bounce(pre: Vector3) -> void:
	if state != St.HIT and state != St.STAGGER:
		_bounced = false
		return
	var flat := Vector2(pre.x, pre.z)
	if _bounced or flat.length() < 7.0 or not is_on_wall():
		return
	var n := get_wall_normal()
	if Vector2(n.x, n.z).dot(flat.normalized()) > -0.4:
		return
	_bounced = true
	var out := Vector3(pre.x, 0, pre.z).bounce(Vector3(n.x, 0, n.z).normalized()) * 0.45
	velocity.x = out.x
	velocity.z = out.z
	velocity.y = maxf(velocity.y, 4.0)
	hp = maxf(1.0, hp - max_hp * 0.03)
	posture = minf(posture_max, posture + posture_max * 0.15)
	state_len = maxf(state_len, state_t + 0.55)
	rig.flash(0.8)
	Fx.puff(global_position + Vector3(0, 1.0, 0) - Vector3(n.x, 0, n.z) * radius, Color(0.75, 0.74, 0.72, 0.7), 10, 0.7)
	Fx.add_shake(0.35)
	Sfx.play("body", -1.0, 1.1)


func _tick_recover(delta: float) -> void:
	# knocked into the air, a body keeps flying; on the ground it skids
	var drag := 30.0 if is_on_floor() else 5.0
	velocity.x = move_toward(velocity.x, 0.0, drag * delta)
	velocity.z = move_toward(velocity.z, 0.0, drag * delta)
	if state_t >= state_len:
		if state == St.STAGGER:
			posture = 0.0
		set_state(St.FREE)
		rig.play(idle_clip(), 0.18)


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif velocity.y < 0.0:
		velocity.y = -1.0


func _keep_in_world() -> void:
	if place == null:
		return
	var ground := place.height_at(global_position.x, global_position.z)
	if global_position.y < ground - 0.6:
		global_position.y = ground + 0.05
		velocity.y = 0.0
	place.confine(self)
