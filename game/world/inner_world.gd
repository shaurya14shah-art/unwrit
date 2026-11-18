class_name InnerWorld
extends Place
## The Stillness: the place inside a blade. A soul meets what lives there,
## in its own shape, and how it wins decides what the spirit will do for it.

const RADIUS: float = 22.0

var trial: Profile = Profile.new()
var echo: Enemy
var aspect: String = "ash"
var tint: Color = Color(0.8, 0.8, 0.85)
var finished: bool = false
var _spin: Array = []


func _ready() -> void:
	place_name = "The Stillness"
	bounds = RADIUS - 1.0
	aspect = AbilityForge.predict_aspect(soul.seed, soul.profile)
	tint = AbilityForge.ASPECTS[aspect]["color"]
	records = [trial]
	_build()
	Fx.root = self
	Sfx.loop("wind", "", 0.0)
	Sfx.loop("music", "music_inner", -11.0)


func _build() -> void:
	var r := Rng.make([soul.seed, "inner"])
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = tint.darkened(0.82)
	sm.sky_horizon_color = tint.lerp(Color(1, 1, 1), 0.55)
	sm.sky_curve = 0.3
	sm.ground_bottom_color = tint.darkened(0.9)
	sm.ground_horizon_color = tint.lerp(Color(1, 1, 1), 0.55)
	sm.sun_angle_max = 0.0
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = tint.lerp(Color(1, 1, 1), 0.6)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 1.0
	env.glow_hdr_threshold = 1.0
	env.fog_enabled = true
	env.fog_light_color = tint.lerp(Color(1, 1, 1), 0.5)
	env.fog_density = 0.012
	env.fog_sky_affect = 0.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 30, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 60.0
	add_child(sun)
	# a floor like still black water
	var floor_mat := ForgeMesh.mat(Color(0.03, 0.03, 0.05), 0.12, 0.8)
	var b := ForgeMesh.Builder.new()
	b.column(RADIUS, RADIUS, -1.2, 0.0, 48)
	ForgeMesh.inst(b.commit(), floor_mat, self)
	var body := StaticBody3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = RADIUS
	shape.height = 1.2
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position.y = -0.6
	body.add_child(col)
	body.collision_layer = 1
	add_child(body)
	var edge := ForgeMesh.inst(ForgeMesh.ring(0.985, 48), ForgeMesh.glow(tint, 3.0), self, Vector3(0, 0.03, 0))
	edge.scale = Vector3(RADIUS, 1, RADIUS)
	for k in range(3):
		var ring := ForgeMesh.inst(ForgeMesh.ring(0.992, 40), ForgeMesh.glow(tint, 1.2), self, Vector3(0, 0.02, 0))
		ring.scale = Vector3(5.0 + 5.0 * float(k), 1, 5.0 + 5.0 * float(k))
	# every blade this soul might have carried, hanging point down
	var steel := ForgeMesh.mat(Color(0.75, 0.77, 0.82), 0.2, 0.8)
	for i in range(26):
		var a := TAU * float(i) / 26.0 + r.randf_range(-0.08, 0.08)
		var rad := RADIUS + r.randf_range(4.0, 26.0)
		var h := r.randf_range(8.0, 26.0)
		var holder := Node3D.new()
		holder.position = Vector3(cos(a) * rad, r.randf_range(2.0, 20.0), sin(a) * rad)
		holder.rotation = Vector3(PI + r.randf_range(-0.15, 0.15), r.randf() * TAU, r.randf_range(-0.15, 0.15))
		add_child(holder)
		var bb := ForgeMesh.Builder.new()
		bb.box(Vector3(h * 0.08, h * 0.9, h * 0.014), Vector3(0, h * 0.45, 0))
		bb.box(Vector3(h * 0.056, h * 0.056, h * 0.014), Vector3(0, h * 0.9, 0), Vector3(0, 0, 45))
		bb.box(Vector3(h * 0.22, h * 0.03, h * 0.035), Vector3(0, -h * 0.015, 0))
		bb.box(Vector3(h * 0.035, h * 0.2, h * 0.035), Vector3(0, -h * 0.13, 0))
		ForgeMesh.inst(bb.commit(), steel, holder)
		_spin.append(holder)
	var glow := OmniLight3D.new()
	glow.light_color = tint
	glow.light_energy = 2.0
	glow.omni_range = 40.0
	glow.position = Vector3(0, 9, 0)
	add_child(glow)


func height_at(_x: float, _z: float) -> float:
	return 0.0


func populate() -> void:
	echo = Enemy.new()
	var look := player.look_spec()
	echo.setup("echo", 1, soul.seed, {"hair": look["hair"], "hair_seed": soul.seed, "hair_color": Color(0.95, 0.95, 0.97),
		"coat": 2, "accent": tint, "scale": look["scale"]})
	echo.patience = soul.profile.trait_of("patience")
	echo.mobility = soul.profile.trait_of("mobility")
	echo.max_hp = 150.0 + 12.0 * float(soul.level)
	echo.hp = echo.max_hp
	add_actor(echo, Vector3(0, 0, -7))
	echo.home = echo.global_position
	echo.leash = 999.0
	echo.aggro_range = 9.0
	echo.rig.hold(Gear.sealed_blade(soul.seed))
	echo.rotation.y = PI
	say("THE STILLNESS", "boss")
	say("It has your shape. It is waiting to see how you fight.", "whisper")


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	for h: Variant in _spin:
		(h as Node3D).rotation.y += delta * 0.05


func on_enemy_death(e: Enemy) -> void:
	if e != echo or finished:
		return
	finished = true
	trial.end_hp_frac = player.hp / maxf(player.max_hp, 1.0)
	player.invuln = 6.0
	Fx.hitstop(0.3)
	Fx.screen_flash(Color(1, 1, 1), 0.6)
	Sfx.play("write", 0.0)
	say("It lowers its blade.", "whisper")
	get_tree().create_timer(2.6, false).timeout.connect(_finish)


func _finish() -> void:
	main.finish_trial(trial, aspect)


func on_player_death() -> void:
	if finished:
		return
	finished = true
	say("Not yet. It does not give its name to this.", "death")
	get_tree().create_timer(2.6, false).timeout.connect(main.fail_trial)
