// Steam plume / vent smoke for a FogVolume (box). Rises, widens with height, broken up by 3D noise.
shader_type fog;
uniform sampler3D noise3d : repeat_enable;
uniform float density = 2.0;
uniform vec4 albedo : source_color = vec4(0.9, 0.9, 0.92, 1.0);
uniform vec4 emission : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float rise = 0.6;
uniform float seed = 0.0;
void fog() {
	vec3 u = UVW;
	float y = u.y;
	vec2 c = (u.xz - 0.5) * 2.0;
	float spread = mix(0.25, 1.0, pow(y, 0.6));
	float r = length(c) / spread;
	float shape = (1.0 - smoothstep(0.35, 1.0, r)) * smoothstep(0.0, 0.08, y) * (1.0 - smoothstep(0.55, 1.0, y));
	vec3 q = WORLD_POSITION * vec3(0.45, 0.22, 0.45) + vec3(seed, -TIME * rise, seed * 0.7);
	float n = texture(noise3d, q).r * 0.6 + texture(noise3d, q * vec3(2.3, 1.6, 2.3) + 0.37).r * 0.4;
	n = smoothstep(0.12, 0.7, n);
	DENSITY = density * shape * n;
	ALBEDO = albedo.rgb;
	EMISSION = emission.rgb * shape * n;
}
