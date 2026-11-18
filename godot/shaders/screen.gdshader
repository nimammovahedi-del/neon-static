// LED billboard / small screens: atlas art recoloured with preset colours, visible RGB pixel grid
// up close, a slow refresh band and slight colour drift.
shader_type spatial;
render_mode blend_mix, cull_back, diffuse_burley, specular_schlick_ggx;
global uniform float g_screen_bright;
uniform sampler2D atlas_b : source_color, filter_linear_mipmap_anisotropic;
uniform float energy = 3.0;
uniform float pixel_density = 160.0;
instance uniform vec4 sign_a : instance_index(7), source_color = vec4(0.1, 0.0, 0.3, 1.0);
instance uniform vec4 sign_b : instance_index(8), source_color = vec4(1.0, 0.3, 0.8, 1.0);
instance uniform vec4 sign_c : instance_index(9), source_color = vec4(0.2, 0.9, 1.0, 1.0);
instance uniform vec4 scr_cell : instance_index(12) = vec4(0.0, 0.0, 1.0, 0.0); // cell, unused, brightness, mirror
void fragment() {
	float cell = mod(floor(scr_cell.x + 0.5), 8.0);
	vec2 uv = clamp(UV, vec2(0.002), vec2(0.998));
	if (scr_cell.w > 0.5) uv.x = 1.0 - uv.x;
	vec2 cuv = (vec2(mod(cell, 2.0), floor(cell / 2.0)) + uv) / vec2(2.0, 4.0);
	vec3 m = texture(atlas_b, cuv).rgb;
	vec3 col = sign_a.rgb * m.r + sign_b.rgb * m.g * 1.3 + sign_c.rgb * m.b;
	// LED pixel grid
	vec2 px = UV * vec2(pixel_density * 1.78, pixel_density);
	vec2 f = fract(px);
	float fw = max(fwidth(px.x), fwidth(px.y));
	float grid = mix(smoothstep(0.0, 0.25, f.x) * smoothstep(0.0, 0.25, f.y) * smoothstep(1.0, 0.75, f.x) * smoothstep(1.0, 0.75, f.y), 0.55, smoothstep(0.3, 0.8, fw));
	float band = 0.88 + 0.12 * smoothstep(0.0, 0.15, abs(fract(UV.y * 0.7 - TIME * 0.05) - 0.5));
	ALBEDO = vec3(0.02);
	ROUGHNESS = 0.25;
	EMISSION = col * energy * scr_cell.z * g_screen_bright * grid * 1.6 * band;
}
