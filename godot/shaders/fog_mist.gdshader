// Low ground mist for a big FogVolume box over the street: thick at the ground, thins with height,
// drifting 3D noise.
shader_type fog;
uniform sampler3D noise3d : repeat_enable;
uniform float density = 0.3;
uniform float height = 1.5;
uniform vec4 albedo : source_color = vec4(0.8, 0.82, 0.9, 1.0);
uniform vec4 emission : source_color = vec4(0.0, 0.0, 0.0, 1.0);
void fog() {
	float y = WORLD_POSITION.y;
	float fall = exp(-max(y, 0.0) / max(height, 0.05));
	vec3 q = WORLD_POSITION * vec3(0.06, 0.2, 0.06) + vec3(TIME * 0.02, 0.0, TIME * 0.01);
	float n = texture(noise3d, q).r;
	n = 0.35 + 1.1 * smoothstep(0.25, 0.75, n);
	float edge = smoothstep(0.0, 0.08, UVW.x) * smoothstep(1.0, 0.92, UVW.x) * smoothstep(0.0, 0.05, UVW.z) * smoothstep(1.0, 0.95, UVW.z);
	DENSITY = density * fall * n * edge;
	ALBEDO = albedo.rgb;
	EMISSION = emission.rgb * fall * edge;
}
