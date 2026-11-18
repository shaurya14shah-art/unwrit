class_name Detail
extends RefCounted
## The finer grain of the world: surface shaders that give flat ground
## patches, speckle, paving seams, ripples and glowing veins, and the small
## props a place is furnished with. Props write into a ForgeMesh.Builder so a
## whole street of them is one mesh; lit parts go into a second builder.
##
## Ground surfaces read vertex alpha as a surface code:
##   1.0 natural ground (patches)   0.75 paving (square seams)
##   0.5 asphalt (fine speckle)     0.25 boards (seams one way)

const GROUND_SHADER := """
shader_type spatial;
render_mode cull_back;
uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform float patch_amount = 0.14;
uniform float patch_scale = 0.025;
uniform float speck_amount = 0.06;
uniform float speck_scale = 1.4;
uniform float seam_tile = 2.0;
uniform float ripple_amount = 0.0;
uniform float ripple_scale = 0.7;
uniform float sparkle = 0.0;
uniform vec3 vein_color = vec3(1.0, 0.4, 0.08);
uniform float vein_amount = 0.0;
uniform float roughness_base = 0.95;
uniform vec3 season_tint = vec3(1.0);
uniform float snow = 0.0;
uniform float wet = 0.0;
varying vec3 wpos;
varying vec3 wnorm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

float seam(vec2 p, float tile, float w) {
	vec2 g = abs(fract(p / tile) - 0.5) * tile;
	float d = min(tile * 0.5 - g.x, tile * 0.5 - g.y);
	return 1.0 - smoothstep(w * 0.5, w, d);
}

void fragment() {
	vec3 base = COLOR.rgb;
	float code = COLOR.a;
	float n1 = texture(noise_tex, wpos.xz * patch_scale).r;
	float n2 = texture(noise_tex, wpos.xz * speck_scale + vec2(0.37, 0.11)).r;
	float n3 = texture(noise_tex, wpos.xz * patch_scale * 4.0 + vec2(0.71, 0.29)).r;
	float up = smoothstep(0.6, 0.9, wnorm.y);
	float k = 1.0 + (n1 - 0.5) * 2.0 * patch_amount + (n3 - 0.5) * patch_amount;
	float rough = roughness_base;
	if (code > 0.87) {
		k += (n2 - 0.5) * 2.0 * speck_amount;
		if (ripple_amount > 0.0) {
			float r = sin(wpos.x * ripple_scale + wpos.z * ripple_scale * 0.35 + n1 * 9.0);
			k += r * ripple_amount * up;
		}
	} else if (code > 0.62) {
		// paving: square slabs, each a touch different, dark seams between
		vec2 cell = floor(wpos.xz / seam_tile);
		float jitter = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
		k = 1.0 + (jitter - 0.5) * 0.08 + (n2 - 0.5) * 0.06;
		k *= 1.0 - 0.28 * seam(wpos.xz, seam_tile, 0.07) * up;
	} else if (code > 0.37) {
		// asphalt: fine grit and darker patched areas
		k = 1.0 + (n2 - 0.5) * 0.22 + (n1 - 0.5) * 0.18 + (n3 - 0.5) * 0.08;
		rough = 0.85;
	} else {
		// boards: long seams one way, short breaks the other
		float lane = floor(wpos.x / 0.5);
		float off = fract(sin(lane * 17.13) * 911.7) * 3.0;
		float g = abs(fract(wpos.x / 0.5) - 0.5) * 0.5;
		float g2 = abs(fract((wpos.z + off) / 3.0) - 0.5) * 3.0;
		float s = max(1.0 - smoothstep(0.012, 0.03, 0.25 - g), 1.0 - smoothstep(0.012, 0.03, 1.5 - g2));
		k = (1.0 + (fract(sin(lane * 3.7) * 437.1) - 0.5) * 0.12) * (1.0 - 0.35 * s * up);
	}
	ALBEDO = base * k;
	ROUGHNESS = rough;
	if (code > 0.87) {
		// the season shows on natural ground; snow lies where it is open and up
		ALBEDO *= season_tint;
		float cover = snow * up * smoothstep(0.35, 0.65, n1 + snow * 0.5);
		ALBEDO = mix(ALBEDO, vec3(0.9, 0.92, 0.96), cover);
	}
	// rain darkens and glosses everything it falls on
	ALBEDO *= 1.0 - 0.28 * wet * up;
	ROUGHNESS = mix(ROUGHNESS, 0.25, wet * up);
	if (sparkle > 0.0) {
		float sp = smoothstep(0.86, 0.9, n2) * sparkle;
		EMISSION = vec3(sp);
	}
	if (vein_amount > 0.0) {
		float band = 1.0 - smoothstep(0.0, 0.012, abs(n3 - 0.5));
		band *= smoothstep(0.62, 0.78, n1);
		EMISSION += vein_color * band * vein_amount * up;
		ALBEDO = mix(ALBEDO, vein_color * 0.3, band * 0.5 * up);
	}
}
"""

## Windows: vertex colour is the pane; alpha under 1 lights it from inside.
const GLASS_SHADER := """
shader_type spatial;
render_mode cull_disabled;
uniform float lit_energy = 1.6;
void fragment() {
	ALBEDO = COLOR.rgb * 0.55;
	METALLIC = 0.35;
	ROUGHNESS = 0.08;
	SPECULAR = 0.7;
	EMISSION = COLOR.rgb * (1.0 - COLOR.a) * lit_energy;
}
"""

const LIT_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled;
uniform float energy = 2.4;
void fragment() {
	ALBEDO = COLOR.rgb * energy;
}
"""

static var _noise: NoiseTexture2D
static var _lit_shader: Shader
static var _lit_cache: Dictionary = {}
static var _glass_all: Array = []
static var _grounds: Array = []   # weak references: regions come and go


static func _each_ground(key: String, value: Variant) -> void:
	var keep: Array = []
	for w: Variant in _grounds:
		var g: Variant = (w as WeakRef).get_ref()
		if g != null:
			(g as ShaderMaterial).set_shader_parameter(key, value)
			keep.append(w)
	_grounds = keep


## The season on the ground: a tint for natural surfaces and a snow cover.
static func set_season(tint: Color, snow_cover: float) -> void:
	_each_ground("season_tint", Vector3(tint.r, tint.g, tint.b))
	_each_ground("snow", snow_cover)


## Rain on everything: darker, glossier ground.
static func set_wet(w: float) -> void:
	_each_ground("wet", w)


static var _ground_shader: Shader
static var _glass_shader: Shader

const KINDS: Dictionary = {
	"town": {},
	"grass": {"patch_amount": 0.18, "speck_amount": 0.07},
	"sand": {"patch_amount": 0.1, "speck_amount": 0.05, "ripple_amount": 0.035, "ripple_scale": 0.8},
	"pale": {"patch_amount": 0.13, "speck_amount": 0.05, "ripple_amount": 0.07, "ripple_scale": 0.5, "sparkle": 0.3},
	"snow": {"patch_amount": 0.06, "speck_amount": 0.03, "sparkle": 0.5, "roughness_base": 0.7},
	"rock": {"patch_amount": 0.2, "speck_amount": 0.1, "patch_scale": 0.04},
	"ash": {"patch_amount": 0.22, "speck_amount": 0.09, "vein_amount": 0.9, "patch_scale": 0.03, "vein_color": Vector3(0.9, 0.22, 0.04)},
	"cave": {"patch_amount": 0.2, "speck_amount": 0.08, "patch_scale": 0.05},
}


static func noise() -> NoiseTexture2D:
	if _noise == null:
		var n := FastNoiseLite.new()
		n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		n.frequency = 0.02
		n.fractal_octaves = 4
		_noise = NoiseTexture2D.new()
		_noise.width = 512
		_noise.height = 512
		_noise.seamless = true
		_noise.generate_mipmaps = true
		_noise.noise = n
	return _noise


## A ground material that reads vertex colour (and alpha as a surface code).
static func ground(kind: String = "town") -> ShaderMaterial:
	if _ground_shader == null:
		_ground_shader = Shader.new()
		_ground_shader.code = GROUND_SHADER
	var m := ShaderMaterial.new()
	m.shader = _ground_shader
	m.set_shader_parameter("noise_tex", noise())
	_grounds.append(weakref(m))
	var k: Dictionary = KINDS.get(kind, {})
	for p: Variant in k.keys():
		m.set_shader_parameter(String(p), k[p])
	return m


## Lamps, lit windows, signs: vertex colour pushed past white so it blooms.
static func lit_material(energy: float = 2.4) -> ShaderMaterial:
	var key := snappedf(energy, 0.1)
	if _lit_cache.has(key):
		return _lit_cache[key]
	if _lit_shader == null:
		_lit_shader = Shader.new()
		_lit_shader.code = LIT_SHADER
	var m := ShaderMaterial.new()
	_lit_cache[key] = m
	m.shader = _lit_shader
	m.set_shader_parameter("energy", energy)
	return m


static func glass(lit_energy: float = 1.6) -> ShaderMaterial:
	if _glass_shader == null:
		_glass_shader = Shader.new()
		_glass_shader.code = GLASS_SHADER
	var m := ShaderMaterial.new()
	m.shader = _glass_shader
	m.set_shader_parameter("lit_energy", lit_energy)
	m.set_meta("base", lit_energy)
	_glass_all.append(m)
	return m


## Night brightens every lamp, sign, screen and lit window: k from 0 to 1.
static func set_night(k: float) -> void:
	for key: Variant in _lit_cache.keys():
		var m: ShaderMaterial = _lit_cache[key]
		m.set_shader_parameter("energy", float(key) * (1.0 + 1.1 * k))
	var keep: Array = []
	for g: Variant in _glass_all:
		if is_instance_valid(g):
			(g as ShaderMaterial).set_shader_parameter("lit_energy", float((g as ShaderMaterial).get_meta("base", 1.4)) * (1.0 + 2.2 * k))
			keep.append(g)
	_glass_all = keep


## Lighting every place shares: ambient occlusion in the corners where
## parts meet, a little more glow discipline, and a gentle grade.
static func polish(env: Environment, ao: float = 1.0) -> void:
	env.ssao_enabled = true
	env.ssao_radius = 1.4
	env.ssao_intensity = 1.8 * ao
	env.ssao_power = 1.4
	env.ssao_detail = 0.6
	env.ssao_light_affect = 0.05
	env.ssao_ao_channel_affect = 0.0
	env.adjustment_enabled = true
	if is_equal_approx(env.adjustment_contrast, 1.0):
		env.adjustment_contrast = 1.05


# ------------------------------------------------------------------ props
# Every prop is built about its foot at (0, 0, 0), facing -Z, then placed.

static func _push(b: ForgeMesh.Builder, at: Vector3, yaw_deg: float) -> Transform3D:
	var keep := b.xf
	b.xf = keep * Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_deg)), at)
	return keep


## A town street lamp: plinth, two-stage pole, arm and a lit head.
static func street_lamp(b: ForgeMesh.Builder, lit: ForgeMesh.Builder, at: Vector3, yaw: float) -> void:
	var k := _push(b, at, yaw)
	var lk := _push(lit, at, yaw)
	b.col = Color(0.2, 0.21, 0.24)
	b.box(Vector3(0.56, 0.5, 0.56), Vector3(0, 0.25, 0))
	b.box(Vector3(0.44, 0.12, 0.44), Vector3(0, 0.56, 0))
	b.box(Vector3(0.26, 3.0, 0.26), Vector3(0, 2.1, 0))
	b.box(Vector3(0.18, 2.6, 0.18), Vector3(0, 4.9, 0))
	b.box(Vector3(0.14, 0.14, 1.6), Vector3(0, 6.1, -0.7))
	b.box(Vector3(0.1, 0.5, 0.1), Vector3(0, 5.85, -0.2), Vector3(-40, 0, 0))
	b.box(Vector3(0.62, 0.22, 0.86), Vector3(0, 6.05, -1.5))
	lit.col = Color(1.0, 0.93, 0.74)
	lit.box(Vector3(0.48, 0.06, 0.7), Vector3(0, 5.92, -1.5))
	b.xf = k
	lit.xf = lk


static func bin(b: ForgeMesh.Builder, at: Vector3, yaw: float, colour: Color = Color(0.2, 0.32, 0.24)) -> void:
	var k := _push(b, at, yaw)
	b.col = colour
	b.box(Vector3(0.62, 0.9, 0.62), Vector3(0, 0.5, 0))
	b.col = colour.darkened(0.35)
	b.box(Vector3(0.7, 0.1, 0.7), Vector3(0, 1.0, 0))
	b.box(Vector3(0.66, 0.06, 0.66), Vector3(0, 0.1, 0))
	b.col = Color(0.08, 0.08, 0.09)
	b.box(Vector3(0.36, 0.12, 0.04), Vector3(0, 0.86, -0.32))
	b.xf = k


static func hydrant(b: ForgeMesh.Builder, at: Vector3, yaw: float) -> void:
	var k := _push(b, at, yaw)
	b.col = Color(0.78, 0.16, 0.12)
	b.box(Vector3(0.44, 0.12, 0.44), Vector3(0, 0.06, 0))
	b.box(Vector3(0.32, 0.62, 0.32), Vector3(0, 0.43, 0))
	b.box(Vector3(0.38, 0.1, 0.38), Vector3(0, 0.78, 0))
	b.box(Vector3(0.2, 0.16, 0.2), Vector3(0, 0.9, 0))
	b.box(Vector3(0.5, 0.14, 0.14), Vector3(0, 0.5, 0))
	b.col = Color(0.85, 0.8, 0.7)
	b.box(Vector3(0.16, 0.16, 0.12), Vector3(0, 0.5, -0.2))
	b.xf = k


static func bollard(b: ForgeMesh.Builder, at: Vector3) -> void:
	var k := _push(b, at, 0.0)
	b.col = Color(0.22, 0.23, 0.26)
	b.box(Vector3(0.26, 0.9, 0.26), Vector3(0, 0.45, 0))
	b.col = Color(0.85, 0.75, 0.25)
	b.box(Vector3(0.28, 0.1, 0.28), Vector3(0, 0.74, 0))
	b.xf = k


static func mailbox(b: ForgeMesh.Builder, at: Vector3, yaw: float) -> void:
	var k := _push(b, at, yaw)
	b.col = Color(0.18, 0.28, 0.55)
	b.box(Vector3(0.6, 0.9, 0.5), Vector3(0, 0.75, 0))
	b.box(Vector3(0.64, 0.12, 0.54), Vector3(0, 1.24, 0))
	b.col = Color(0.1, 0.1, 0.12)
	b.box(Vector3(0.4, 0.06, 0.04), Vector3(0, 1.0, -0.26))
	b.box(Vector3(0.08, 0.3, 0.08), Vector3(-0.2, 0.15, 0))
	b.box(Vector3(0.08, 0.3, 0.08), Vector3(0.2, 0.15, 0))
	b.xf = k


## A street-name sign on a thin pole: two blades crossed.
static func street_sign(b: ForgeMesh.Builder, at: Vector3, yaw: float) -> void:
	var k := _push(b, at, yaw)
	b.col = Color(0.55, 0.56, 0.6)
	b.box(Vector3(0.1, 3.2, 0.1), Vector3(0, 1.6, 0))
	b.col = Color(0.12, 0.42, 0.24)
	b.box(Vector3(1.3, 0.28, 0.04), Vector3(0.45, 3.0, 0))
	b.box(Vector3(0.04, 0.28, 1.3), Vector3(0, 2.68, 0.45))
	b.col = Color(0.9, 0.92, 0.9)
	b.box(Vector3(1.0, 0.04, 0.045), Vector3(0.45, 3.0, 0))
	b.box(Vector3(0.045, 0.04, 1.0), Vector3(0, 2.68, 0.45))
	b.xf = k


## A traffic light on an L arm reaching over the road (along -Z).
static func traffic_light(b: ForgeMesh.Builder, lit: ForgeMesh.Builder, at: Vector3, yaw: float, which: int) -> void:
	var k := _push(b, at, yaw)
	var lk := _push(lit, at, yaw)
	b.col = Color(0.22, 0.23, 0.26)
	b.box(Vector3(0.5, 0.4, 0.5), Vector3(0, 0.2, 0))
	b.box(Vector3(0.22, 6.0, 0.22), Vector3(0, 3.2, 0))
	b.box(Vector3(0.14, 0.14, 4.0), Vector3(0, 6.0, -2.0))
	b.col = Color(0.12, 0.12, 0.13)
	b.box(Vector3(0.5, 1.4, 0.44), Vector3(0, 5.15, -3.4))
	b.box(Vector3(0.36, 0.9, 0.3), Vector3(0.0, 2.4, -0.3))
	var cols: Array = [Color(1.0, 0.18, 0.12), Color(1.0, 0.75, 0.15), Color(0.2, 1.0, 0.45)]
	for i in range(3):
		var c: Color = cols[i]
		if i == which:
			lit.col = c
			lit.box(Vector3(0.26, 0.26, 0.05), Vector3(0, 5.6 - 0.44 * float(i), -3.64))
		else:
			b.col = c.darkened(0.75)
			b.box(Vector3(0.26, 0.26, 0.05), Vector3(0, 5.6 - 0.44 * float(i), -3.64))
	b.xf = k
	lit.xf = lk


## A wooden power pole with a crossarm and insulators. Returns the two
## points the wires hang from, in world space.
static func power_pole(b: ForgeMesh.Builder, at: Vector3, yaw: float) -> Array:
	var k := _push(b, at, yaw)
	b.col = Color(0.34, 0.24, 0.16)
	b.box(Vector3(0.32, 8.4, 0.32), Vector3(0, 4.2, 0))
	b.box(Vector3(2.6, 0.18, 0.18), Vector3(0, 7.6, 0))
	b.box(Vector3(0.1, 1.0, 0.1), Vector3(0.6, 7.3, 0), Vector3(0, 0, 40))
	b.box(Vector3(0.1, 1.0, 0.1), Vector3(-0.6, 7.3, 0), Vector3(0, 0, -40))
	b.col = Color(0.82, 0.85, 0.8)
	for x: float in [-1.1, 1.1]:
		b.box(Vector3(0.12, 0.2, 0.12), Vector3(x, 7.78, 0))
	b.col = Color(0.3, 0.32, 0.3)
	b.box(Vector3(0.6, 0.8, 0.6), Vector3(0, 6.4, 0.32))
	var out: Array = [b.xf * Vector3(-1.1, 7.86, 0), b.xf * Vector3(1.1, 7.86, 0)]
	b.xf = k
	return out


## A sagging wire from a to b, in world space, built as short segments.
static func wire(b: ForgeMesh.Builder, from: Vector3, to: Vector3, sag: float = 0.6) -> void:
	b.col = Color(0.08, 0.08, 0.09)
	var segs := 6
	var prev := from
	for i in range(1, segs + 1):
		var t := float(i) / float(segs)
		var p := from.lerp(to, t) - Vector3(0, sag * 4.0 * t * (1.0 - t), 0)
		var mid := (prev + p) * 0.5
		var d := p - prev
		var length := d.length()
		var basis := Basis.looking_at(d.normalized(), Vector3.UP if absf(d.normalized().y) < 0.95 else Vector3.RIGHT)
		var keep := b.xf
		b.xf = Transform3D(basis, mid)
		b.box(Vector3(0.04, 0.04, length))
		b.xf = keep
		prev = p


static func planter(b: ForgeMesh.Builder, at: Vector3, yaw: float, length: float = 2.0) -> void:
	var k := _push(b, at, yaw)
	b.col = Color(0.52, 0.5, 0.47)
	b.box(Vector3(length, 0.6, 0.9), Vector3(0, 0.3, 0))
	b.col = Color(0.3, 0.22, 0.15)
	b.box(Vector3(length - 0.2, 0.08, 0.7), Vector3(0, 0.6, 0))
	var greens: Array = [Color(0.16, 0.42, 0.18), Color(0.2, 0.5, 0.2), Color(0.13, 0.36, 0.16)]
	var n := maxi(2, int(length / 0.7))
	for i in range(n):
		b.col = greens[i % 3]
		var s := 0.5 + 0.12 * float(i % 2)
		b.box(Vector3(s, s, s), Vector3(-length * 0.5 + 0.4 + (length - 0.8) * float(i) / float(maxi(1, n - 1)), 0.75 + 0.05 * float(i % 3), 0.0), Vector3(0, 20.0 * float(i), 0))
	if n > 2:
		b.col = Color(0.9, 0.35, 0.4)
		b.box(Vector3(0.14, 0.14, 0.14), Vector3(-0.3, 1.02, -0.12))
		b.col = Color(0.95, 0.85, 0.3)
		b.box(Vector3(0.14, 0.14, 0.14), Vector3(0.4, 0.98, 0.1))
	b.xf = k


## A bus stop: two posts, a roof, a back pane, a bench and a lit map panel.
static func bus_stop(b: ForgeMesh.Builder, lit: ForgeMesh.Builder, at: Vector3, yaw: float) -> void:
	var k := _push(b, at, yaw)
	var lk := _push(lit, at, yaw)
	b.col = Color(0.24, 0.26, 0.3)
	for x: float in [-1.6, 1.6]:
		b.box(Vector3(0.14, 2.6, 0.14), Vector3(x, 1.3, 0.5))
	b.box(Vector3(3.6, 0.14, 1.5), Vector3(0, 2.66, 0.0))
	b.col = Color(0.55, 0.65, 0.72)
	b.box(Vector3(3.2, 1.8, 0.05), Vector3(0, 1.4, 0.55))
	b.col = Color(0.4, 0.28, 0.18)
	b.box(Vector3(2.4, 0.1, 0.42), Vector3(-0.2, 0.5, 0.25))
	b.col = Color(0.24, 0.26, 0.3)
	b.box(Vector3(0.1, 0.45, 0.4), Vector3(-1.3, 0.25, 0.25))
	b.box(Vector3(0.1, 0.45, 0.4), Vector3(0.9, 0.25, 0.25))
	lit.col = Color(0.95, 0.95, 0.88)
	lit.box(Vector3(0.9, 1.5, 0.06), Vector3(1.55, 1.3, 0.5))
	b.xf = k
	lit.xf = lk


static func manhole(b: ForgeMesh.Builder, at: Vector3) -> void:
	var k := _push(b, at, 0.0)
	b.col = Color(0.2, 0.2, 0.21, 1.0)
	b.box(Vector3(0.9, 0.02, 0.9), Vector3(0, 0.0, 0), Vector3(0, 45, 0))
	b.box(Vector3(0.9, 0.02, 0.9), Vector3(0, 0.0, 0))
	b.col = Color(0.14, 0.14, 0.15, 1.0)
	for i in range(3):
		b.box(Vector3(0.7, 0.025, 0.06), Vector3(0, 0.002, -0.2 + 0.2 * float(i)))
	b.xf = k


static func bike_rack(b: ForgeMesh.Builder, at: Vector3, yaw: float) -> void:
	var k := _push(b, at, yaw)
	b.col = Color(0.6, 0.62, 0.66)
	for i in range(3):
		var x := -0.8 + 0.8 * float(i)
		b.box(Vector3(0.06, 0.8, 0.06), Vector3(x, 0.4, -0.3))
		b.box(Vector3(0.06, 0.8, 0.06), Vector3(x, 0.4, 0.3))
		b.box(Vector3(0.06, 0.06, 0.66), Vector3(x, 0.8, 0))
	b.xf = k


# ----------------------------------------------------------- on buildings

## A window set into a wall facing -Z: frame, sill, lintel, and the pane
## into `g` (alpha under 1 means a light is on inside).
static func window(b: ForgeMesh.Builder, g: ForgeMesh.Builder, at: Vector3, yaw: float, w: float, h: float, frame: Color, pane: Color, mullion: bool = true) -> void:
	var k := _push(b, at, yaw)
	var gk := _push(g, at, yaw)
	b.col = frame
	b.box(Vector3(w + 0.2, 0.12, 0.16), Vector3(0, h * 0.5 + 0.06, -0.04))
	b.box(Vector3(0.1, h, 0.12), Vector3(-w * 0.5 - 0.05, 0, -0.03))
	b.box(Vector3(0.1, h, 0.12), Vector3(w * 0.5 + 0.05, 0, -0.03))
	b.col = frame.darkened(0.15)
	b.box(Vector3(w + 0.34, 0.1, 0.3), Vector3(0, -h * 0.5 - 0.05, -0.12))
	if mullion:
		b.col = frame
		b.box(Vector3(0.06, h, 0.08), Vector3(0, 0, -0.03))
		if h > 1.2:
			b.box(Vector3(w, 0.06, 0.08), Vector3(0, h * 0.12, -0.03))
	g.col = pane
	g.box(Vector3(w, h, 0.04), Vector3(0, 0, 0.0))
	b.xf = k
	g.xf = gk


static func ac_unit(b: ForgeMesh.Builder, at: Vector3, yaw: float) -> void:
	var k := _push(b, at, yaw)
	b.col = Color(0.78, 0.78, 0.76)
	b.box(Vector3(1.6, 0.9, 1.0), Vector3(0, 0.45, 0))
	b.col = Color(0.3, 0.31, 0.33)
	b.box(Vector3(0.9, 0.04, 0.9), Vector3(-0.2, 0.92, 0), Vector3(0, 45, 0))
	b.box(Vector3(0.7, 0.6, 0.04), Vector3(0.3, 0.45, -0.51))
	b.col = Color(0.5, 0.5, 0.52)
	b.box(Vector3(0.12, 0.12, 1.4), Vector3(0.7, 0.2, 0.9))
	b.xf = k


static func water_tank(b: ForgeMesh.Builder, at: Vector3) -> void:
	var k := _push(b, at, 0.0)
	b.col = Color(0.3, 0.26, 0.22)
	for sx: float in [-0.8, 0.8]:
		for sz: float in [-0.8, 0.8]:
			b.box(Vector3(0.14, 2.2, 0.14), Vector3(sx, 1.1, sz))
	b.box(Vector3(2.0, 0.14, 2.0), Vector3(0, 2.2, 0))
	b.col = Color(0.5, 0.38, 0.28)
	b.column(1.05, 1.05, 2.3, 4.4, 12)
	b.col = Color(0.32, 0.3, 0.3)
	b.column(1.12, 0.1, 4.4, 5.2, 12)
	b.col = Color(0.4, 0.3, 0.22)
	for i in range(3):
		b.column(1.08, 1.08, 2.7 + 0.6 * float(i), 2.78 + 0.6 * float(i), 12)
	b.xf = k


static func antenna(b: ForgeMesh.Builder, at: Vector3, height: float = 4.0) -> void:
	var k := _push(b, at, 0.0)
	b.col = Color(0.55, 0.56, 0.58)
	b.box(Vector3(0.1, height, 0.1), Vector3(0, height * 0.5, 0))
	for i in range(3):
		var y := height * (0.5 + 0.16 * float(i))
		b.box(Vector3(1.4 - 0.3 * float(i), 0.05, 0.05), Vector3(0, y, 0))
	b.col = Color(0.8, 0.2, 0.15)
	b.box(Vector3(0.16, 0.16, 0.16), Vector3(0, height, 0))
	b.xf = k


static func roof_hatch(b: ForgeMesh.Builder, at: Vector3, yaw: float) -> void:
	var k := _push(b, at, yaw)
	b.col = Color(0.62, 0.6, 0.57)
	b.box(Vector3(2.4, 2.4, 2.6), Vector3(0, 1.2, 0))
	b.col = Color(0.35, 0.34, 0.33)
	b.box(Vector3(2.6, 0.2, 2.8), Vector3(0, 2.5, 0))
	b.col = Color(0.3, 0.24, 0.2)
	b.box(Vector3(1.0, 1.9, 0.08), Vector3(0, 0.95, -1.32))
	b.xf = k


static func vent(b: ForgeMesh.Builder, at: Vector3) -> void:
	var k := _push(b, at, 0.0)
	b.col = Color(0.6, 0.62, 0.64)
	b.column(0.18, 0.18, 0.0, 0.9, 8)
	b.column(0.32, 0.05, 0.9, 1.15, 8)
	b.xf = k


## A striped canvas awning over a door or window, facing -Z.
static func awning(b: ForgeMesh.Builder, at: Vector3, yaw: float, w: float, a: Color, c: Color) -> void:
	var k := _push(b, at, yaw)
	var n := maxi(2, int(w / 0.55))
	var sw := w / float(n)
	for i in range(n):
		b.col = a if i % 2 == 0 else c
		b.box(Vector3(sw, 0.08, 1.5), Vector3(-w * 0.5 + sw * (float(i) + 0.5), 0, -0.68), Vector3(18, 0, 0))
		b.box(Vector3(sw, 0.34, 0.06), Vector3(-w * 0.5 + sw * (float(i) + 0.5), -0.38, -1.4))
	b.col = a.darkened(0.4)
	b.box(Vector3(w + 0.1, 0.1, 0.12), Vector3(0, 0.2, 0.0))
	b.xf = k


# --------------------------------------------------------- other realms

## A stone lantern in the Citadel's style: footing, post, firebox, cap.
static func stone_lantern(b: ForgeMesh.Builder, lit: ForgeMesh.Builder, at: Vector3, yaw: float, stone: Color = Color(0.62, 0.62, 0.6)) -> void:
	var k := _push(b, at, yaw)
	var lk := _push(lit, at, yaw)
	b.col = stone.darkened(0.1)
	b.box(Vector3(1.0, 0.25, 1.0), Vector3(0, 0.12, 0))
	b.col = stone
	b.box(Vector3(0.36, 1.1, 0.36), Vector3(0, 0.8, 0))
	b.box(Vector3(0.8, 0.14, 0.8), Vector3(0, 1.4, 0))
	b.box(Vector3(0.12, 0.6, 0.12), Vector3(-0.28, 1.76, -0.28))
	b.box(Vector3(0.12, 0.6, 0.12), Vector3(0.28, 1.76, -0.28))
	b.box(Vector3(0.12, 0.6, 0.12), Vector3(-0.28, 1.76, 0.28))
	b.box(Vector3(0.12, 0.6, 0.12), Vector3(0.28, 1.76, 0.28))
	b.col = stone.darkened(0.2)
	b.frustum(Vector2(1.2, 1.2), Vector2(0.2, 0.2), 2.06, 2.5)
	b.box(Vector3(0.18, 0.2, 0.18), Vector3(0, 2.6, 0))
	lit.col = Color(1.0, 0.82, 0.5)
	lit.box(Vector3(0.42, 0.42, 0.42), Vector3(0, 1.76, 0))
	b.xf = k
	lit.xf = lk


## A tall cloth banner on a pole with a crossbar, facing -Z.
static func banner(b: ForgeMesh.Builder, at: Vector3, yaw: float, cloth: Color, mark: Color, height: float = 5.0) -> void:
	var k := _push(b, at, yaw)
	b.col = Color(0.25, 0.2, 0.16)
	b.box(Vector3(0.14, height, 0.14), Vector3(0, height * 0.5, 0))
	b.box(Vector3(1.4, 0.1, 0.1), Vector3(0.6, height - 0.2, 0))
	b.col = cloth
	b.box(Vector3(1.1, height * 0.55, 0.04), Vector3(0.65, height - 0.25 - height * 0.275, -0.04))
	b.box(Vector3(0.5, 0.3, 0.04), Vector3(0.4, height - 0.25 - height * 0.55 - 0.1, -0.04))
	b.box(Vector3(0.5, 0.3, 0.04), Vector3(0.9, height - 0.25 - height * 0.55 - 0.16, -0.04))
	b.col = mark
	b.box(Vector3(0.12, height * 0.32, 0.05), Vector3(0.65, height - 0.25 - height * 0.26, -0.065))
	b.box(Vector3(0.6, 0.1, 0.05), Vector3(0.65, height - 0.25 - height * 0.16, -0.065))
	b.xf = k


## Fallen rocks: a big stone and its smaller pieces about it.
static func rock_pile(b: ForgeMesh.Builder, at: Vector3, yaw: float, size: float, colour: Color, r: RandomNumberGenerator) -> void:
	var k := _push(b, at, yaw)
	b.col = colour
	b.box(Vector3(size, size * 0.7, size * 0.85), Vector3(0, size * 0.3, 0), Vector3(r.randf_range(-8, 8), r.randf_range(0, 60), r.randf_range(-10, 10)))
	for i in range(4):
		var s := size * r.randf_range(0.2, 0.42)
		var a := r.randf() * TAU
		b.col = colour.darkened(r.randf() * 0.15).lightened(r.randf() * 0.08)
		b.box(Vector3(s, s * 0.7, s), Vector3(cos(a) * size * 0.75, s * 0.3, sin(a) * size * 0.75), Vector3(r.randf_range(-20, 20), r.randf() * 90.0, r.randf_range(-20, 20)))
	b.xf = k


## An arch of great ribs, the bones of something that died lying down.
static func bone_arch(b: ForgeMesh.Builder, at: Vector3, yaw: float, span: float, bone: Color) -> void:
	var k := _push(b, at, yaw)
	b.col = bone
	var ribs := 5
	for i in range(ribs):
		var z := -span * 0.4 + span * 0.8 * float(i) / float(ribs - 1)
		var hgt := span * (0.55 - 0.08 * absf(float(i) - 2.0))
		for side: float in [-1.0, 1.0]:
			b.box(Vector3(0.5, hgt, 0.5), Vector3(side * span * 0.3, hgt * 0.45, z), Vector3(0, 0, side * -18.0))
			b.box(Vector3(0.42, hgt * 0.4, 0.42), Vector3(side * span * 0.15, hgt * 0.92, z), Vector3(0, 0, side * -62.0))
	b.col = bone.darkened(0.1)
	b.box(Vector3(0.7, 0.7, span * 0.95), Vector3(0, span * 0.5, 0), Vector3(4, 0, 0))
	for i in range(8):
		b.box(Vector3(0.9, 0.6, 0.6), Vector3(0, span * 0.5 + 0.1, -span * 0.45 + span * 0.9 * float(i) / 7.0))
	b.xf = k


## A spire of black glass with a glowing seam, for the Undermark.
static func obsidian_spire(b: ForgeMesh.Builder, lit: ForgeMesh.Builder, at: Vector3, yaw: float, height: float, r: RandomNumberGenerator) -> void:
	var k := _push(b, at, yaw)
	var lk := _push(lit, at, yaw)
	b.col = Color(0.08, 0.06, 0.07)
	var w := height * 0.16
	b.frustum(Vector2(w, w * 0.8), Vector2(w * 0.2, w * 0.15), 0.0, height, Vector2(r.randf_range(-0.5, 0.5), r.randf_range(-0.5, 0.5)))
	b.col = Color(0.12, 0.08, 0.08)
	b.frustum(Vector2(w * 0.6, w * 0.5), Vector2(0.05, 0.05), 0.0, height * 0.55, Vector2(0, 0), Vector2(w * 0.55, w * 0.2))
	lit.col = Color(1.0, 0.36, 0.06)
	lit.box(Vector3(0.08, height * 0.5, 0.08), Vector3(w * 0.12, height * 0.32, -w * 0.38), Vector3(4, 0, 3))
	b.xf = k
	lit.xf = lk


## A hanging gibbet cage on an iron post.
static func gibbet(b: ForgeMesh.Builder, at: Vector3, yaw: float) -> void:
	var k := _push(b, at, yaw)
	b.col = Color(0.16, 0.14, 0.14)
	b.box(Vector3(0.3, 6.0, 0.3), Vector3(0, 3.0, 0))
	b.box(Vector3(2.4, 0.2, 0.2), Vector3(1.0, 5.9, 0))
	b.box(Vector3(0.05, 1.0, 0.05), Vector3(2.0, 5.3, 0))
	var cy := 3.8
	for i in range(8):
		var a := TAU * float(i) / 8.0
		b.box(Vector3(0.06, 1.6, 0.06), Vector3(2.0 + cos(a) * 0.5, cy, sin(a) * 0.5))
	b.box(Vector3(1.2, 0.08, 1.2), Vector3(2.0, cy - 0.8, 0))
	b.box(Vector3(1.0, 0.08, 1.0), Vector3(2.0, cy + 0.8, 0))
	b.col = Color(0.85, 0.82, 0.74)
	b.box(Vector3(0.3, 0.3, 0.3), Vector3(2.0, cy - 0.6, 0.1))
	b.xf = k


## A shard of ice standing out of snow.
static func ice_shard(b: ForgeMesh.Builder, at: Vector3, yaw: float, height: float, r: RandomNumberGenerator) -> void:
	var k := _push(b, at, yaw)
	b.col = Color(0.72, 0.86, 0.96)
	b.frustum(Vector2(height * 0.3, height * 0.22), Vector2(0.04, 0.04), 0.0, height, Vector2(r.randf_range(-0.3, 0.3), r.randf_range(-0.3, 0.3)))
	b.col = Color(0.85, 0.94, 1.0)
	b.frustum(Vector2(height * 0.16, height * 0.12), Vector2(0.02, 0.02), 0.0, height * 0.55, Vector2(0, 0), Vector2(height * 0.2, 0.0))
	b.col = Color(0.95, 0.96, 0.98)
	b.box(Vector3(height * 0.6, 0.18, height * 0.5), Vector3(0, 0.05, 0))
	b.xf = k


## Commits a prop builder and its lit twin under a parent.
static func commit(parent: Node3D, b: ForgeMesh.Builder, lit: ForgeMesh.Builder, paint: Material, glow_energy: float = 2.4) -> void:
	if b.tris > 0:
		var mi := ForgeMesh.inst(b.commit(), paint, parent)
		mi.name = "Dressing"
	if lit != null and lit.tris > 0:
		var li := ForgeMesh.inst(lit.commit(), lit_material(glow_energy), parent)
		li.name = "DressingLit"
		li.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## What the live ground materials hold for a uniform (tests read this).
static func ground_value(key: String) -> Variant:
	for w: Variant in _grounds:
		var g: Variant = (w as WeakRef).get_ref()
		if g != null:
			return (g as ShaderMaterial).get_shader_parameter(key)
	return null
