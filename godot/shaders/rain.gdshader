// Rain streak for GPUParticles3D (QuadMesh 1x1, particle Y axis aligned to velocity).
// The quad turns around its own axis to face the camera. Streaks pick up nearby lights through
// light() so drops glitter in lamp and sign light; a little emission keeps distant rain visible.
shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_never, shadows_disabled, skip_vertex_transform, diffuse_lambert, specular_disabled;
uniform vec4 tint : source_color = vec4(0.75, 0.8, 0.9, 1.0);
uniform float width = 0.012;
uniform float length_scale = 0.55;
uniform float alpha_mul = 0.5;
uniform float light_gain = 2.5;
uniform float self_glow = 0.05;
varying float v_fade;
void vertex() {
	vec3 axis = MODEL_MATRIX[1].xyz;
	float len = length(axis);
	axis = len > 0.0 ? axis / len : vec3(0.0, 1.0, 0.0);
	vec3 ctr = MODEL_MATRIX[3].xyz;
	vec3 to_cam = normalize(CAMERA_POSITION_WORLD - ctr);
	vec3 side = normalize(cross(axis, to_cam));
	float dist = length(CAMERA_POSITION_WORLD - ctr);
	float w = width * (1.0 + dist * 0.03);
	v_fade = smoothstep(1.2, 4.0, dist);
	vec3 wp = ctr + side * VERTEX.x * w + axis * VERTEX.y * length_scale;
	VERTEX = (VIEW_MATRIX * vec4(wp, 1.0)).xyz;
	NORMAL = normalize((VIEW_MATRIX * vec4(to_cam, 0.0)).xyz);
}
void fragment() {
	float x = abs(UV.x - 0.5) * 2.0;
	float y = UV.y;
	float a = (1.0 - x * x) * smoothstep(0.0, 0.35, y) * smoothstep(1.0, 0.6, y);
	ALBEDO = tint.rgb;
	EMISSION = tint.rgb * self_glow;
	ALPHA = clamp(a * alpha_mul * COLOR.a * v_fade, 0.0, 1.0);
}
void light() {
	DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * light_gain / 3.14159;
}
