class_name Weather
extends Node
## Weather for the realms under an open sky (Calder Town, the Citadel). It
## turns every few minutes, with odds set by the season, and it is kept in
## soul.flags so it is still raining when you come back.
##   clear   the place as built
##   rain    streaks round you, wet glossy ground, its own sound
##   fog     thick grey; enemies notice you from only two-thirds as far
##   storm   rain, and lightning every few seconds: a pale ring warns where
##           it will fall, and it hurts whatever stands there, enemies too
##   snow    winter only: flakes, and snow lying deeper on open ground

const KINDS: Array = ["clear", "rain", "fog", "storm", "snow"]
const NAMES: Dictionary = {"clear": "Clear", "rain": "Rain", "fog": "Fog", "storm": "Thunderstorm", "snow": "Snow"}
## Odds per season (spring, summer, autumn, winter).
const ODDS: Array = [
	{"clear": 4.0, "rain": 3.0, "fog": 2.0, "storm": 1.0},
	{"clear": 6.0, "rain": 1.0, "fog": 0.5, "storm": 2.0},
	{"clear": 3.0, "rain": 3.0, "fog": 3.0, "storm": 1.0},
	{"clear": 3.0, "fog": 2.0, "snow": 4.0},
]
const SPELL_MIN: float = 180.0
const SPELL_MAX: float = 360.0
## How far an enemy can see you, as a share of its usual range.
const SIGHT: Dictionary = {"clear": 1.0, "rain": 0.85, "fog": 0.65, "storm": 0.8, "snow": 0.85}
const FOG_DENSITY: Dictionary = {"clear": 0.0, "rain": 0.004, "fog": 0.016, "storm": 0.007, "snow": 0.008}
const OVERCAST: Dictionary = {"clear": 0.0, "rain": 0.5, "fog": 0.35, "storm": 0.75, "snow": 0.4}
const BOLT_RADIUS: float = 3.0
const BOLT_WARN: float = 1.1
const BOLT_EVERY: Vector2 = Vector2(4.0, 8.0)

var region: Region
var kind: String = "clear"
var wet: float = 0.0
var overcast: float = 0.0
var fog_k: float = 0.0
var strikes: int = 0
var pending: Array = []   # [position, seconds left]
var env: Environment
var sun: DirectionalLight3D
var sky_mat: ProceduralSkyMaterial
var rain_fx: GPUParticles3D
var snow_fx: GPUParticles3D
var _base: Dictionary = {}
var _bolt_t: float = 5.0
var _rng := RandomNumberGenerator.new()


static func name_of(k: String) -> String:
	return String(NAMES.get(k, "Clear"))


## A season's draw: deterministic from the soul, the day and the spell.
static func roll(soul: Soul, season: int) -> String:
	var n := int(soul.flags.get("weather_n", 0))
	var r := Rng.make([soul.seed, "weather", int(soul.flags.get("days", 0)), n])
	var odds: Dictionary = ODDS[clampi(season, 0, 3)]
	var total := 0.0
	for k: Variant in odds.keys():
		total += float(odds[k])
	var x := r.randf() * total
	for k: Variant in odds.keys():
		x -= float(odds[k])
		if x <= 0.0:
			return String(k)
	return "clear"


func setup(r: Region) -> void:
	region = r
	_rng.seed = hash([r.soul.seed, r.region_id, "bolts"])
	for c in r.get_children():
		if c is WorldEnvironment and env == null:
			env = (c as WorldEnvironment).environment
		elif c is DirectionalLight3D and sun == null:
			sun = c
	if env != null and env.sky != null and env.sky.sky_material is ProceduralSkyMaterial:
		sky_mat = env.sky.sky_material
	if env != null:
		_base = {"fog": env.fog_enabled, "fog_d": env.fog_density, "fog_sky": env.fog_sky_affect}
	_build_particles()
	apply_quality()
	var s := r.soul
	if not s.flags.has("weather") or not KINDS.has(String(s.flags["weather"])):
		s.flags["weather"] = "clear"
		s.flags["weather_left"] = 120.0
	kind = String(s.flags["weather"])
	if kind == "snow" and DayNight.season_of(s) != 3:
		kind = "clear"
		s.flags["weather"] = kind
	# coming back into weather: it is already wet, already foggy
	wet = 1.0 if kind == "rain" or kind == "storm" else 0.0
	fog_k = 1.0 if kind != "clear" else 0.0
	overcast = float(OVERCAST.get(kind, 0.0))
	_start(kind)


func apply_quality() -> void:
	if rain_fx != null:
		rain_fx.amount_ratio = Quality.particles() * (1.0 if kind == "storm" else 0.7)
	if snow_fx != null:
		snow_fx.amount_ratio = Quality.particles()


func _exit_tree() -> void:
	Sfx.stop_loop("weather")
	Detail.set_wet(0.0)


## Turns the weather now (tests, and the turn of a spell).
func set_kind(k: String, spell: float = -1.0) -> void:
	if not KINDS.has(k):
		return
	kind = k
	region.soul.flags["weather"] = k
	region.soul.flags["weather_left"] = spell if spell > 0.0 else _rng.randf_range(SPELL_MIN, SPELL_MAX)
	_start(k)
	if k != "clear":
		region.say("%s · %s" % [DayNight.season_name(region.soul), name_of(k)], "toast")


func _start(k: String) -> void:
	pending.clear()
	_bolt_t = _rng.randf_range(BOLT_EVERY.x, BOLT_EVERY.y)
	if rain_fx != null:
		rain_fx.emitting = k == "rain" or k == "storm"
		rain_fx.amount_ratio = Quality.particles() * (1.0 if k == "storm" else 0.7)
	if snow_fx != null:
		snow_fx.emitting = k == "snow"
	if k == "rain" or k == "storm":
		Sfx.loop("weather", "rain", -12.0 if k == "storm" else -15.0)
	else:
		Sfx.stop_loop("weather")


func tick(delta: float) -> void:
	var s := region.soul
	s.flags["weather_left"] = float(s.flags.get("weather_left", 120.0)) - delta
	if float(s.flags["weather_left"]) <= 0.0:
		s.flags["weather_n"] = int(s.flags.get("weather_n", 0)) + 1
		set_kind(roll(s, DayNight.season_of(s)))
	if kind == "snow" and DayNight.season_of(s) != 3:
		set_kind("clear")
	# the ground wets fast and dries slowly; fog and cloud come and go
	var wet_to := 1.0 if kind == "rain" or kind == "storm" else 0.0
	wet = move_toward(wet, wet_to, delta / (20.0 if wet_to > wet else 90.0))
	fog_k = move_toward(fog_k, 1.0 if kind != "clear" else 0.0, delta / 15.0)
	overcast = move_toward(overcast, float(OVERCAST.get(kind, 0.0)), delta / 15.0)
	_follow()
	_apply()
	_tick_bolts(delta)


## Weather sits on top of the light the clock has just set.
func _apply() -> void:
	Detail.set_wet(wet)
	var storm_event := region.events != null and region.events.storming()
	if env != null and not _base.is_empty() and not storm_event:
		var dens := float(FOG_DENSITY.get(kind, 0.0)) * fog_k
		env.fog_enabled = bool(_base["fog"]) or dens > 0.0
		env.fog_density = maxf(float(_base["fog_d"]), dens)
		env.fog_sky_affect = lerpf(float(_base["fog_sky"]), 0.7, clampf(dens / 0.016, 0.0, 1.0))
		env.ambient_light_color = env.ambient_light_color.lerp(Color(0.6, 0.64, 0.7), overcast * 0.4)
	if sun != null:
		sun.light_energy *= 1.0 - overcast * 0.55
	if sky_mat != null:
		var grey := Color(0.42, 0.45, 0.5) * (1.0 - (region.daynight.night() if region.daynight != null else 0.0) * 0.8)
		sky_mat.sky_top_color = sky_mat.sky_top_color.lerp(grey, overcast * 0.8)
		sky_mat.sky_horizon_color = sky_mat.sky_horizon_color.lerp(grey * 1.2, overcast * 0.7)
		sky_mat.ground_horizon_color = sky_mat.sky_horizon_color


## How far enemies see you now, as a share of their usual range.
func sight() -> float:
	return lerpf(1.0, float(SIGHT.get(kind, 1.0)), fog_k)


func label() -> String:
	return name_of(kind)


# --- lightning -------------------------------------------------------------

func _tick_bolts(delta: float) -> void:
	for i in range(pending.size() - 1, -1, -1):
		var b: Array = pending[i]
		b[1] = float(b[1]) - delta
		if float(b[1]) <= 0.0:
			pending.remove_at(i)
			land(b[0])
	if kind != "storm" or region.player == null or region.player.scripted:
		return
	_bolt_t -= delta
	if _bolt_t > 0.0:
		return
	_bolt_t = _rng.randf_range(BOLT_EVERY.x, BOLT_EVERY.y)
	strike_at(_pick_spot())


func _pick_spot() -> Vector3:
	var p := region.player.global_position
	# now and then it finds an enemy nearby; mostly it falls round you
	if _rng.randf() < 0.4:
		var near: Array = []
		for e: Variant in region.enemies_alive():
			if is_instance_valid(e) and (e as Actor).global_position.distance_to(p) < 25.0:
				near.append(e)
		if not near.is_empty():
			return (near[_rng.randi() % near.size()] as Actor).global_position
	var a := _rng.randf() * TAU
	var at := p + Vector3(cos(a), 0, sin(a)) * _rng.randf_range(3.0, 11.0)
	at.y = region.height_at(at.x, at.z)
	return at


## Marks a spot; lightning falls there BOLT_WARN seconds later.
func strike_at(pos: Vector3, warn: float = BOLT_WARN) -> void:
	pending.append([pos, warn])
	Fx.warn(pos, BOLT_RADIUS, Color(0.75, 0.85, 1.0), warn)


## The bolt itself: light, sound and harm to everything inside the ring.
func land(pos: Vector3) -> int:
	strikes += 1
	Fx.pillar(pos, Color(0.72, 0.82, 1.0), 40.0, 0.35, 0.3)
	Fx.ring(pos + Vector3(0, 0.1, 0), Color(0.8, 0.88, 1.0), 0.3, BOLT_RADIUS + 1.0, 0.35)
	Fx.sparks(pos + Vector3(0, 0.3, 0), Color(0.8, 0.9, 1.0), 16, 9.0)
	Fx.screen_flash(Color(0.85, 0.9, 1.0), 0.25)
	Fx.add_shake(0.35)
	Sfx.play("thunder", -4.0)
	var hurt := 0
	for a: Variant in region.actors.duplicate():
		if a == null or not is_instance_valid(a):
			continue
		var act := a as Actor
		if not act.alive or act.global_position.distance_to(pos) > BOLT_RADIUS:
			continue
		var share := 0.12
		if act is Enemy:
			share = 0.08 if (act as Enemy).is_boss else 0.25
		var res := {"outcome": "hit", "dmg": act.max_hp * share, "posture": 15.0, "stagger": true}
		var away := (act.global_position - pos)
		away.y = 0.0
		act.receive(res, null, {"kind": "lightning", "knock": 5.0, "launch": 4.0})
		if region.play != null:
			if act == region.player:
				region.play.give_badge("lightning_rod")
			elif act is Enemy and (not act.alive or (act as Enemy).knocked):
				region.play.give_badge("storm_caller")
		if act.alive:
			act.push = away.normalized() * 5.0 if away.length() > 0.1 else Vector3.ZERO
		hurt += 1
	return hurt


# --- rain and snow ---------------------------------------------------------

func _build_particles() -> void:
	rain_fx = _particles(1800, Vector3(0, -38.0, 0), 1.0, _streak_mesh(), Vector3(22, 1, 22))
	snow_fx = _particles(1100, Vector3(0, -1.6, 0), 9.0, _flake_mesh(), Vector3(24, 1, 24))
	(snow_fx.process_material as ParticleProcessMaterial).turbulence_enabled = true
	(snow_fx.process_material as ParticleProcessMaterial).turbulence_noise_strength = 0.6


func _particles(amount: int, gravity: Vector3, life: float, mesh: Mesh, box: Vector3) -> GPUParticles3D:
	var g := GPUParticles3D.new()
	g.amount = amount
	g.lifetime = life
	g.preprocess = life
	g.local_coords = false
	g.emitting = false
	g.visibility_aabb = AABB(Vector3(-30, -40, -30), Vector3(60, 60, 60))
	g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = box
	pm.gravity = gravity
	pm.direction = Vector3(0.15, -1, 0.05)
	pm.spread = 4.0
	pm.initial_velocity_min = absf(gravity.y) * 0.3
	pm.initial_velocity_max = absf(gravity.y) * 0.4
	g.process_material = pm
	g.draw_pass_1 = mesh
	add_child(g)
	return g


func _streak_mesh() -> Mesh:
	var q := QuadMesh.new()
	q.size = Vector2(0.025, 0.7)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.78, 0.84, 0.92, 0.35)
	m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	m.disable_receive_shadows = true
	q.material = m
	return q


func _flake_mesh() -> Mesh:
	var q := QuadMesh.new()
	q.size = Vector2(0.09, 0.09)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.96, 0.97, 1.0, 0.85)
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	q.material = m
	return q


## The falling rain is a column over the player, not over the whole map.
func _follow() -> void:
	if region.player == null:
		return
	var p := region.player.global_position
	if rain_fx != null:
		rain_fx.global_position = p + Vector3(0, 14.0, 0)
	if snow_fx != null:
		snow_fx.global_position = p + Vector3(0, 12.0, 0)
