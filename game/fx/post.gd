class_name Post
extends CanvasLayer
## The screen pass. Reads how the camera moved and what Fx asked for, and
## hands the shader its numbers. Sits under the HUD so words stay sharp.

var cam: CamRig
var player: Player
var enabled: bool = true
var strength: float = 1.0
var _mat: ShaderMaterial
var _rect: ColorRect
var _dir: Vector2 = Vector2.ZERO


func _ready() -> void:
	layer = 1
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://fx/motion_blur.gdshader")
	_rect.material = _mat
	add_child(_rect)


func _process(delta: float) -> void:
	_rect.visible = enabled
	if not enabled:
		return
	var want := Vector2.ZERO
	var radial := Fx.blur * 0.045 * strength
	if cam != null and is_instance_valid(cam) and cam.cam != null:
		var fov_v := deg_to_rad(cam.cam.fov)
		var size := get_viewport().get_visible_rect().size
		var fov_h := 2.0 * atan(tan(fov_v * 0.5) * size.x / maxf(size.y, 1.0))
		var shutter := 0.0045
		want = Vector2(cam.ang_vel.x / fov_h, -cam.ang_vel.y / fov_v) * shutter * strength
		if want.length() > 0.03 * strength:
			want = want.normalized() * 0.03 * strength
		if want.length() < 0.0015:
			want = Vector2.ZERO
		radial += clampf((cam.speed - 12.0) / 30.0, 0.0, 1.0) * 0.025 * strength
	var real := delta / maxf(Engine.time_scale, 0.05)
	_dir = _dir.lerp(want, clampf(real * 22.0, 0.0, 1.0))
	_mat.set_shader_parameter("dir", _dir)
	_mat.set_shader_parameter("radial", radial)
	_mat.set_shader_parameter("flash", Fx.flash)
	var hurt := 0.0
	if player != null and is_instance_valid(player) and player.max_hp > 0.0:
		var frac := player.hp / player.max_hp
		hurt = clampf((0.4 - frac) / 0.4, 0.0, 1.0) * (0.3 + 0.08 * sin(Time.get_ticks_msec() * 0.006))
	_mat.set_shader_parameter("hurt", hurt)
