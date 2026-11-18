class_name DayNight
extends Node
## Day and night for the realms that have a sky to turn: Calder Town and the
## Citadel. One clock for the whole soul, kept in soul.flags["clock"]:
## 0 dawn, 0.25 noon, 0.5 dusk, 0.75 midnight. A day is DAY_SECONDS long.
## By day the light is the place's own; by night the sun sinks, a pale moon
## stands in, the sky goes deep blue, lamps and windows burn brighter, and
## the dead walk: more of them, more elites, better pay.

const DAY_SECONDS: float = 1440.0
const HAS_SKY: Array = ["town", "citadel"]

var region: Region
var env: Environment
var sun: DirectionalLight3D
var sky_mat: ProceduralSkyMaterial
var _day: Dictionary = {}
var _wander_t: float = 20.0


static func clock_of(soul: Soul) -> float:
	return fposmod(float(soul.flags.get("clock", 0.1)), 1.0)


## How high the sun stands: 1 at noon, 0 at dawn and dusk, -1 at midnight.
static func sun_height(clock: float) -> float:
	return sin(clock * TAU)


## How much of the night has come: 0 by day, 1 deep in it.
static func night_k(clock: float) -> float:
	return clampf(-sun_height(clock) * 2.2 + 0.25, 0.0, 1.0)


static func phase_name(clock: float) -> String:
	var h := sun_height(clock)
	if h > 0.25:
		return "Day"
	if h > -0.15:
		return "Dawn" if clock < 0.25 or clock > 0.75 else "Dusk"
	return "Night"


func setup(r: Region) -> void:
	region = r
	for c in r.get_children():
		if c is WorldEnvironment and env == null:
			env = (c as WorldEnvironment).environment
		elif c is DirectionalLight3D and sun == null:
			sun = c
	if env != null and env.sky != null and env.sky.sky_material is ProceduralSkyMaterial:
		sky_mat = env.sky.sky_material
	_day = {
		"sun_e": sun.light_energy if sun != null else 1.0,
		"sun_c": sun.light_color if sun != null else Color.WHITE,
		"sun_r": sun.rotation_degrees if sun != null else Vector3(-50, -40, 0),
		"amb_c": env.ambient_light_color if env != null else Color.WHITE,
		"amb_e": env.ambient_light_energy if env != null else 0.5,
		"top": sky_mat.sky_top_color if sky_mat != null else Color.BLUE,
		"hor": sky_mat.sky_horizon_color if sky_mat != null else Color.WHITE,
		"fog_c": env.fog_light_color if env != null else Color.WHITE,
	}
	apply(clock_of(r.soul))


func has_sky() -> bool:
	return HAS_SKY.has(region.region_id)


func clock() -> float:
	return clock_of(region.soul)


func night() -> float:
	return night_k(clock()) if has_sky() else 0.0


const SEASONS: Array = ["Spring", "Summer", "Autumn", "Winter"]
const DAYS_PER_SEASON: int = 3
const SEASON_TINT: Array = [Color(0.96, 1.06, 0.92), Color(1.0, 1.0, 1.0), Color(1.28, 0.86, 0.55), Color(0.86, 0.9, 0.96)]


static func season_of(soul: Soul) -> int:
	return (int(soul.flags.get("days", 0)) / DAYS_PER_SEASON) % 4


static func season_name(soul: Soul) -> String:
	return String(SEASONS[season_of(soul)])


func tick(delta: float) -> void:
	var s := region.soul
	var before := float(s.flags.get("clock", 0.1))
	var after := fposmod(before + delta / DAY_SECONDS, 1.0)
	if after < before:
		s.flags["days"] = int(s.flags.get("days", 0)) + 1
	s.flags["clock"] = after
	if not has_sky():
		return
	apply(clock())
	_night_play(delta)


## Puts the clock into the light, the sky and the lamps.
func apply(c: float) -> void:
	if not has_sky():
		return
	var k := night_k(c)
	var h := sun_height(c)
	var dusk := clampf(1.0 - absf(h) * 4.0, 0.0, 1.0) * (1.0 - k * 0.5)
	if sun != null:
		var day_r: Vector3 = _day["sun_r"]
		# the sun climbs and sinks; at night the same light is a low pale moon
		sun.rotation_degrees = Vector3(lerpf(-10.0, day_r.x, clampf(h, 0.0, 1.0)) if k < 0.5 else -38.0, day_r.y + (c - 0.25) * 120.0, 0)
		sun.light_energy = lerpf(float(_day["sun_e"]), 0.28, k)
		sun.light_color = (_day["sun_c"] as Color).lerp(Color(1.0, 0.62, 0.38), dusk * 0.7).lerp(Color(0.62, 0.72, 1.0), k)
	var storm := region.events != null and region.events.storming()
	if env != null and not storm:
		env.ambient_light_color = (_day["amb_c"] as Color).lerp(Color(0.28, 0.34, 0.6), k)
		env.ambient_light_energy = lerpf(float(_day["amb_e"]), float(_day["amb_e"]) * 0.55, k)
		env.fog_light_color = (_day["fog_c"] as Color).lerp(Color(0.95, 0.55, 0.35), dusk * 0.5).lerp(Color(0.08, 0.1, 0.2), k)
	if sky_mat != null:
		sky_mat.sky_top_color = (_day["top"] as Color).lerp(Color(0.02, 0.03, 0.09), k)
		sky_mat.sky_horizon_color = (_day["hor"] as Color).lerp(Color(0.98, 0.55, 0.32), dusk).lerp(Color(0.07, 0.09, 0.18), k)
		sky_mat.ground_horizon_color = sky_mat.sky_horizon_color
	Detail.set_night(k)
	region.on_night(k)
	var se := season_of(region.soul)
	var extra := 0.0
	if region.weather != null and region.weather.kind == "snow":
		extra = 0.35
	Detail.set_season(SEASON_TINT[se], (0.45 if se == 3 else 0.0) + extra)


## The dead walk at night: now and then one comes up near you.
func _night_play(delta: float) -> void:
	if night() < 0.6 or region.player == null or region.player.scripted or region.soul == null or not region.soul.written():
		return
	_wander_t -= delta
	if _wander_t > 0.0:
		return
	_wander_t = 30.0
	if region.enemies_alive().size() >= 10 or region.in_combat():
		return
	var kinds: Array = []
	for sp: Variant in region.spawn_list():
		var kk := String((sp as Array)[0])
		if not Bestiary.is_boss(kk) and kk != "drill":
			kinds.append(kk)
	if kinds.is_empty():
		return
	var p := region.player.global_position
	var a := randf() * TAU
	var at := p + Vector3(cos(a), 0, sin(a)) * randf_range(18.0, 28.0)
	if absf(at.x) > region.bounds - 10.0 or absf(at.z) > region.bounds - 10.0:
		return
	var e: Enemy = region._spawn(String(kinds[randi() % kinds.size()]), at, region.level_base + 1)
	e.set_meta("night", true)
	Fx.pillar(at, Color(0.4, 0.5, 0.9), 6.0, 0.3, 0.5)
