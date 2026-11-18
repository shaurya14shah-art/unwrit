class_name Quality
extends RefCounted
## Graphics quality, one setting with three steps, for machines that
## struggle (the owner's runs showed 11 fps with Low Power Mode on).
##   0 Low     no ambient occlusion, no sun shadows, 75% render scale,
##             a third of the rain and snow, shorter view of small props
##   1 Medium  no ambient occlusion, sun shadows to 60 m, full scale
##   2 High    everything as built
## Applied to the place on entry and whenever the setting changes.

const NAMES: Array = ["Low", "Medium", "High"]
const PROP_RANGE: Array = [55.0, 90.0, 140.0]
const PARTICLES: Array = [0.35, 0.7, 1.0]


static func level() -> int:
	return clampi(int(Settings.get_value("quality")), 0, 2)


static func prop_range() -> float:
	return float(PROP_RANGE[level()])


static func particles() -> float:
	return float(PARTICLES[level()])


static func apply(place: Node) -> void:
	if place == null or not is_instance_valid(place):
		return
	var q := level()
	var vp := place.get_viewport()
	if vp != null:
		vp.scaling_3d_scale = 0.75 if q == 0 else 1.0
	for c in place.get_children():
		if c is WorldEnvironment:
			var env := (c as WorldEnvironment).environment
			if env != null:
				if not env.has_meta("ssao_built"):
					env.set_meta("ssao_built", env.ssao_enabled)
				env.ssao_enabled = bool(env.get_meta("ssao_built")) and q == 2
		elif c is DirectionalLight3D:
			var sun := c as DirectionalLight3D
			if not sun.has_meta("shadow_built"):
				sun.set_meta("shadow_built", sun.shadow_enabled)
				sun.set_meta("shadow_dist", sun.directional_shadow_max_distance)
			sun.shadow_enabled = bool(sun.get_meta("shadow_built")) and q > 0
			sun.directional_shadow_max_distance = float(sun.get_meta("shadow_dist")) if q == 2 else minf(60.0, float(sun.get_meta("shadow_dist")))
	var region := place as Region
	if region != null and region.weather != null:
		region.weather.apply_quality()
	if region != null and region.play != null:
		region.play.apply_quality()
