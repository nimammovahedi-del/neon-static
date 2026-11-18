// Translucent hologram panel: additive, scanlines, flicker bands, edge fade, chromatic split.
// Uses the billboard mask atlas; colours from the preset (holo colours) per instance.
shader_type spatial;
render_mode blend_add, cull_disabled, unshaded, depth_draw_never, shadows_disabled;
global uniform float g_sign_bright;
uniform sampler2D atlas_b : source_color, filter_linear_mipmap;
uniform float energy = 2.2;
instance uniform vec4 holo_a : instance_index(7), source_color = vec4(0.2, 0.9, 1.0, 1.0);
instance uniform vec4 holo_b : instance_index(8), source_color = vec4(1.0, 0.3, 0.9, 1.0);
instance uniform vec4 holo_cell : instance_index(10) = vec4(0.0, 0.0, 1.0, 0.6); // cell, mirror, brightness, opacity
float h11(float p) { return fract(sin(p * 127.1) * 43758.5453); }
void fragment() {
	float cell = mod(floor(holo_cell.x + 0.5), 8.0);
	vec2 uv = UV;
	if (holo_cell.y > 0.5) uv.x = 1.0 - uv.x;
	float band = floor(uv.y * 40.0 + TIME * 3.0);
	float jitter = (h11(band) - 0.5) * 0.006 * step(0.85, h11(band * 3.1 + floor(TIME * 8.0)));
	vec2 cbase = vec2(mod(cell, 2.0), floor(cell / 2.0));
	vec2 u0 = (cbase + clamp(uv + vec2(jitter, 0.0), 0.002, 0.998)) / vec2(2.0, 4.0);
	vec2 u1 = (cbase + clamp(uv + vec2(jitter + 0.004, 0.0), 0.002, 0.998)) / vec2(2.0, 4.0);
	vec3 m0 = texture(atlas_b, u0).rgb;
	vec3 m1 = texture(atlas_b, u1).rgb;
	vec3 col = holo_a.rgb * (m0.g * 1.2 + m0.r * 0.12) + holo_b.rgb * m1.b * 0.9;
	float scan = 0.65 + 0.35 * sin(UV.y * 900.0);
	float flick = 0.85 + 0.15 * sin(TIME * 17.0 + UV.y * 3.0);
	float edge = smoothstep(0.0, 0.08, UV.x) * smoothstep(1.0, 0.92, UV.x) * smoothstep(0.0, 0.05, 1.0 - UV.y) * (0.35 + 0.65 * smoothstep(0.0, 0.25, UV.y));
	float frame = (1.0 - smoothstep(0.0, 0.012, min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y)))) * 0.6;
	ALBEDO = (col * scan * flick * edge + holo_a.rgb * frame) * energy * holo_cell.z * holo_cell.w * g_sign_bright;
}
