shader_type canvas_item;
// Motion blur, speed blur, hit flash and vignette in one screen pass.
// dir: how far the view turned this frame, in screen units.
// radial: how hard the edges stretch away from the centre (dash, release).

uniform sampler2D screen_tex : hint_screen_texture, filter_linear, repeat_disable;
uniform vec2 dir = vec2(0.0);
uniform float radial = 0.0;
uniform vec4 flash : source_color = vec4(1.0, 1.0, 1.0, 0.0);
uniform float hurt = 0.0;
uniform float vignette = 0.28;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 to_c = uv - vec2(0.5);
	float edge = smoothstep(0.08, 0.6, length(to_c));
	vec2 v = dir + to_c * radial * edge;
	vec3 col = vec3(0.0);
	float total = 0.0;
	for (int i = 0; i < 11; i++) {
		float t = float(i) / 10.0 - 0.5;
		float w = 1.0 - abs(t) * 1.3;
		col += texture(screen_tex, clamp(uv + v * t, vec2(0.001), vec2(0.999))).rgb * w;
		total += w;
	}
	col /= total;
	float d = dot(to_c, to_c);
	col *= 1.0 - vignette * smoothstep(0.1, 0.55, d);
	col = mix(col, vec3(0.75, 0.03, 0.05), hurt * smoothstep(0.08, 0.5, d));
	col = mix(col, flash.rgb, flash.a);
	COLOR = vec4(col, 1.0);
}
