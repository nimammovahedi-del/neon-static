// Rain splash crown on the ground: camera-facing, grows and fades over particle life.
shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_never, shadows_disabled, skip_vertex_transform, diffuse_lambert, specular_disabled;
uniform vec4 tint : source_color = vec4(0.8, 0.85, 0.95, 1.0);
uniform float alpha_mul = 0.5;
uniform float light_gain = 2.0;
varying float v_life;
void vertex() {
	vec3 ctr = MODEL_MATRIX[3].xyz;
	float s = length(MODEL_MATRIX[0].xyz);
	vec3 right = normalize(vec3(INV_VIEW_MATRIX[0].x, 0.0, INV_VIEW_MATRIX[0].z));
	vec3 wp = ctr + right * VERTEX.x * s + vec3(0.0, 1.0, 0.0) * (VERTEX.y + 0.5) * s * 0.6;
	v_life = INSTANCE_CUSTOM.y;
	VERTEX = (VIEW_MATRIX * vec4(wp, 1.0)).xyz;
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
}
void fragment() {
	vec2 d = (UV - vec2(0.5, 1.0)) * vec2(2.0, 1.0);
	float r = length(d);
	float crown = smoothstep(0.55, 0.8, r) * (1.0 - smoothstep(0.85, 1.0, r));
	float spikes = 0.5 + 0.5 * sin(atan(d.y, d.x) * 9.0);
	float life = v_life;
	ALBEDO = tint.rgb;
	ALPHA = crown * (0.6 + 0.4 * spikes) * (1.0 - life) * alpha_mul * COLOR.a;
}
void light() {
	DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * light_gain / 3.14159;
}
