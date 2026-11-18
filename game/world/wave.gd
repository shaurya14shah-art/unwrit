class_name Wave
extends Node3D
## A ring that runs along the ground. Jump it, slip through it, or parry it.

var place: Place
var owner_id: int = 0
var team: int = 1
var m: Dictionary = {}
var r: float = 0.5
var speed: float = 13.0
var max_r: float = 26.0
var done: Dictionary = {}
var _ring: MeshInstance3D
var _mat: StandardMaterial3D


func launch(p: Place, attacker: Actor, origin: Vector3, spec: Dictionary) -> void:
	place = p
	owner_id = attacker.get_instance_id()
	team = attacker.team
	m = spec.duplicate()
	speed = float(spec.get("wave_speed", 13.0))
	max_r = float(spec.get("wave_reach", 26.0))
	var col: Color = spec.get("color", attacker.accent)
	_mat = ForgeMesh.ghost(Color(col.r, col.g, col.b, 0.9))
	_ring = ForgeMesh.inst(ForgeMesh.ring(0.9, 40), _mat, self)
	var wall := ForgeMesh.inst(ForgeMesh.ring(0.97, 40), ForgeMesh.ghost(Color(1, 1, 1, 0.8)), _ring, Vector3(0, 0.4, 0))
	wall.set_meta("no_ghost", true)
	global_position = origin + Vector3(0, 0.25, 0)


func _physics_process(delta: float) -> void:
	var before := r
	r += speed * delta
	_ring.scale = Vector3(r, 1.0, r)
	_mat.albedo_color.a = 0.9 * clampf((max_r - r) / 6.0, 0.0, 1.0)
	if r >= max_r:
		queue_free()
		return
	for a in place.actors:
		if not is_instance_valid(a) or not a.alive or a.team == team or done.has(a.get_instance_id()):
			continue
		var to := a.global_position - global_position
		var ground_gap := a.global_position.y - place.height_at(a.global_position.x, a.global_position.z)
		to.y = 0.0
		var d := to.length()
		if d >= before - 0.3 and d <= r + 0.3:
			done[a.get_instance_id()] = true
			if ground_gap > 0.9:
				if a == place.player:
					Fx.word(a.center() + Vector3(0, 0.8, 0), "OVER", Color(0.7, 1.0, 1.0), 0.8)
				continue
			var owner_actor: Object = instance_from_id(owner_id)
			var attacker: Actor = owner_actor as Actor if owner_actor != null and is_instance_valid(owner_actor) else a
			m["from"] = global_position
			place.strike(attacker, a, m)
