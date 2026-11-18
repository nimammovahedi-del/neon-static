// Soft steam / smoke puff for GPUParticles3D (camera-facing quad). Lit by nearby lights with a
// wrapped, translucent response so plumes glow where lamps and signs hit them.
shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_never, shadows_disabled, diffuse_lambert, specular_disabled;
global uniform sampler2D g_noise : filter_linear_mipmap, repeat_enable;
uniform vec4 tint : source_color = vec4(0.9, 0.9, 0.95, 1.0);
uniform float alpha_mul = 0.35;
uniform float light_gain = 1.6;
uniform float self_glow = 0.03;
varying vec2 v_rnd;
varying float v_life;
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	v_rnd = vec2(INSTANCE_CUSTOM.x, float(INSTANCE_ID) * 0.137);
	v_life = INSTANCE_CUSTOM.y;
}
void fragment() {
	vec2 c = UV - 0.5;
	float r = length(c) * 2.0;
	vec2 nuv = UV * 0.35 + v_rnd + vec2(0.0, -v_life * 0.15);
	float n = texture(g_noise, nuv).r * 0.65 + texture(g_noise, nuv * 2.7 + 0.3).r * 0.35;
	float a = (1.0 - smoothstep(0.25, 1.0, r + (n - 0.5) * 0.6)) * smoothstep(0.25, 0.65, n + 0.2);
	float life = smoothstep(0.0, 0.15, v_life) * (1.0 - smoothstep(0.45, 1.0, v_life));
	ALBEDO = tint.rgb;
	EMISSION = tint.rgb * self_glow;
	ALPHA = clamp(a * life * alpha_mul * COLOR.a, 0.0, 1.0);
}
void light() {
	DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * light_gain * (0.5 + 0.5 * max(dot(NORMAL, LIGHT), 0.0)) / 3.14159;
}
