class_name CamRig
extends Node3D
## The camera: behind the right shoulder, pulled toward a locked enemy,
## shaken by hits, widened by speed. It also reports how fast it is turning
## so the motion blur knows which way to smear.

var cam: Camera3D
var target: Actor
var place: Place
var yaw: float = 0.0
var pitch: float = -0.2
var dist: float = 5.4
var ang_vel: Vector2 = Vector2.ZERO
var speed: float = 0.0
var look_enabled: bool = true
var cine_t: float = 0.0
var cine_from: Vector3 = Vector3.ZERO
var cine_look: Vector3 = Vector3.ZERO

var _prev_yaw: float = 0.0
var _prev_pitch: float = 0.0
var _prev_pos: Vector3 = Vector3.ZERO
var _focus: Vector3 = Vector3.ZERO
var _noise_t: float = 0.0
var _cut: int = 0
var _shoulder: float = 0.6


func _ready() -> void:
	cam = Camera3D.new()
	cam.fov = 70.0
	cam.near = 0.15
	cam.far = 900.0
	add_child(cam)
	cam.current = true


func snap() -> void:
	if target == null:
		return
	_focus = target.global_position + Vector3(0, 1.5, 0)
	global_position = _want()
	_prev_pos = global_position
	_prev_yaw = yaw
	_prev_pitch = pitch
	_cut = 3


func cinematic(from: Vector3, look: Vector3, seconds: float) -> void:
	_cut = 3
	cine_from = from
	cine_look = look
	cine_t = seconds


func _unhandled_input(e: InputEvent) -> void:
	if not look_enabled:
		return
	if e is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var mm: InputEventMouseMotion = e
		var sens := float(Settings.get_value("sens"))
		yaw -= mm.relative.x * 0.0026 * sens
		pitch = clampf(pitch - mm.relative.y * 0.0022 * sens, -1.15, 0.55)


func _want() -> Vector3:
	var shoulder := 1.15 if Player.shift_lock and target is Player and (target as Player).lock_target == null else 0.6
	_shoulder = lerpf(_shoulder, shoulder, 0.15)
	var off := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch) * Vector3(_shoulder, 0.0, dist)
	var p := _focus + off
	if place != null:
		p.y = maxf(p.y, place.height_at(p.x, p.z) + 0.5)
	return p


func _process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	var real := delta / maxf(Engine.time_scale, 0.05)
	if look_enabled:
		var stick := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
		if stick.length() > 0.2:
			yaw -= stick.x * 2.6 * real
			pitch = clampf(pitch - stick.y * 1.8 * real, -1.15, 0.55)
	var p := target as Player
	var locked: Actor = p.lock_target if p != null else null
	var focus := target.global_position + Vector3(0, 1.5 * target.reach_scale, 0)
	if locked != null and is_instance_valid(locked):
		var to := locked.global_position - target.global_position
		var want_yaw := atan2(-to.x, -to.z)
		yaw = lerp_angle(yaw, want_yaw, clampf(real * 5.0, 0.0, 1.0))
		var d := Vector2(to.x, to.z).length()
		var want_pitch := clampf(-0.16 - atan2(locked.rig.height * 0.5 + to.y - 1.0, maxf(d, 3.0)) * 0.5, -0.7, 0.1)
		pitch = lerpf(pitch, want_pitch, clampf(real * 3.0, 0.0, 1.0))
		focus = focus.lerp(locked.center(), 0.22)
	_focus = _focus.lerp(focus, clampf(real * 16.0, 0.0, 1.0))
	if cine_t > 0.0:
		cine_t -= real
		global_position = global_position.lerp(cine_from, clampf(real * 4.0, 0.0, 1.0))
		look_at(cine_look, Vector3.UP)
	else:
		global_position = global_position.lerp(_want(), clampf(real * 20.0, 0.0, 1.0))
		look_at(_focus + Basis(Vector3.UP, yaw) * Vector3(_shoulder, 0.0, 0.0), Vector3.UP)
	_noise_t += real * 40.0
	var s := Fx.shake
	cam.h_offset = sin(_noise_t * 1.3) * cos(_noise_t * 0.7) * s * 0.22
	cam.v_offset = sin(_noise_t * 1.7 + 1.0) * s * 0.2
	var v := (global_position - _prev_pos) / maxf(real, 0.0001)
	speed = lerpf(speed, v.length(), clampf(real * 6.0, 0.0, 1.0))
	cam.fov = lerpf(cam.fov, float(Settings.get_value("fov")) + clampf(speed - 8.0, 0.0, 22.0) * 0.55 + Fx.blur * 4.0, clampf(real * 8.0, 0.0, 1.0))
	ang_vel = Vector2(wrapf(yaw - _prev_yaw, -PI, PI), pitch - _prev_pitch) / maxf(real, 0.0001)
	if _cut > 0:
		# a cut is not a movement: nothing to blur
		_cut -= 1
		ang_vel = Vector2.ZERO
		speed = 0.0
	_prev_yaw = yaw
	_prev_pitch = pitch
	_prev_pos = global_position
