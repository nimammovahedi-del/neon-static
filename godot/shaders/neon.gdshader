// Neon tube: hot white core facing the camera, saturated colour at the rim. Colour per instance.
shader_type spatial;
render_mode blend_mix, cull_back, diffuse_burley, specular_schlick_ggx;
global uniform float g_sign_bright;
instance uniform vec4 neon_color : instance_index(5), source_color = vec4(1.0, 0.2, 0.8, 1.0);
instance uniform float neon_on : instance_index(6) = 1.0;
uniform float energy = 7.0;
void fragment() {
	float f = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	vec3 c = neon_color.rgb;
	vec3 core = mix(c, vec3(1.0) + c * 0.4, pow(f, 2.5) * 0.55);
	float on = neon_on;
	ALBEDO = c * 0.08 + vec3(0.02);
	ROUGHNESS = 0.18;
	SPECULAR = 0.6;
	EMISSION = core * energy * g_sign_bright * on * (0.65 + 0.35 * f) + c * 0.02;
}
