class_name Bolt
extends Node3D
## A thrown splinter of anima. A parry turns it round.

var place: Place
var owner_id: int = 0
var team: int = 1
var vel: Vector3 = Vector3.ZERO
var m: Dictionary = {}
var life: float = 3.0
var home_id: int = 0
var color: Color = Color.WHITE
var _hit: Dictionary = {}


func launch(p: Place, attacker: Actor, origin: Vector3, dir: Vector3, spec: Dictionary) -> void:
	place = p
	owner_id = attacker.get_instance_id()
	team = attacker.team
	m = spec.duplicate()
	m["ranged"] = true
	color = spec.get("color", attacker.accent)
	vel = dir.normalized() * float(spec.get("speed", 26.0))
	if spec.has("home"):
		home_id = int(spec["home"])
	var mi := ForgeMesh.inst(ForgeMesh.shard(0.9, 0.09, 4), ForgeMesh.glow(color, 6.0), self)
	mi.rotation_degrees = Vector3(-90, 0, 0)
	if bool(spec.get("beam", false)):
		mi.scale = Vector3(3.0, 3.6, 3.0)
	elif bool(spec.get("pierce", false)):
		mi.scale = Vector3(1.6, 2.4, 1.6)
	mi.position = Vector3(0, 0, 0.45)
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 1.6
	light.omni_range = 4.0
	add_child(light)
	global_position = origin
	look_at(origin + vel, Vector3.UP)


func _physics_process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	if home_id != 0:
		var t: Object = instance_from_id(home_id)
		if t != null and is_instance_valid(t) and (t as Actor).alive:
			var want := ((t as Actor).center() - global_position).normalized() * vel.length()
			vel = vel.lerp(want, clampf(delta * 5.0, 0.0, 1.0))
	var step := vel * delta
	var next := global_position + step
	for a in place.actors:
		if not is_instance_valid(a) or not a.alive or a.team == team or a.yielded or _hit.has(a.get_instance_id()):
			continue
		var c := a.center()
		var seg := Geometry3D.get_closest_point_to_segment(c, global_position, next)
		if seg.distance_to(c) <= a.radius + 0.45 and absf(seg.y - c.y) < a.rig.height * 0.6:
			var owner_actor: Object = instance_from_id(owner_id)
			var attacker: Actor = owner_actor as Actor if owner_actor != null and is_instance_valid(owner_actor) else a
			m["from"] = global_position - vel.normalized() * 2.0
			var res := place.strike(attacker, a, m)
			if bool(res.get("reflect", false)):
				_turn_round(a)
				return
			if String(res["outcome"]) == "dodged":
				continue
			if bool(m.get("pierce", false)) and String(res["outcome"]) == "hit":
				_hit[a.get_instance_id()] = true
				continue
			queue_free()
			return
	global_position = next
	if vel.length_squared() > 0.01:
		look_at(global_position + vel, Vector3.UP)
	if global_position.y < place.height_at(global_position.x, global_position.z):
		Fx.puff(global_position, Color(0.8, 0.8, 0.82, 0.5), 5, 0.4)
		queue_free()


func _turn_round(by: Actor) -> void:
	var old: Object = instance_from_id(owner_id)
	team = by.team
	owner_id = by.get_instance_id()
	m["dmg"] = float(m.get("dmg", 10.0)) * 1.6
	m["kind"] = "ranged"
	m["posture"] = float(m.get("posture", 8.0)) + 20.0
	life = 3.0
	var speed := vel.length() * 1.3
	if old != null and is_instance_valid(old) and (old as Actor).alive:
		home_id = old.get_instance_id()
		vel = ((old as Actor).center() - global_position).normalized() * speed
	else:
		vel = -vel.normalized() * speed
