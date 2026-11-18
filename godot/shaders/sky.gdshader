// Night sky over the city: zenith/horizon gradient, a city-glow band at the horizon, an optional
// directional glow (predawn), and a low cloud deck lit from below by the city.
shader_type sky;
uniform vec4 zenith : source_color = vec4(0.01, 0.012, 0.03, 1.0);
uniform vec4 horizon : source_color = vec4(0.06, 0.05, 0.09, 1.0);
uniform vec4 glow_color : source_color = vec4(0.5, 0.25, 0.4, 1.0);
uniform float glow_energy = 1.0;
uniform float glow_height = 0.12;
uniform vec3 dir_glow_dir = vec3(0.0, 0.0, -1.0);
uniform vec4 dir_glow_color : source_color = vec4(1.0, 0.5, 0.2, 1.0);
uniform float dir_glow_energy = 0.0;
uniform float dir_glow_width = 0.6;
uniform float cloud_amount = 0.5;
uniform vec4 cloud_color : source_color = vec4(0.25, 0.18, 0.3, 1.0);
uniform float cloud_energy = 1.0;
uniform sampler2D cloud_noise : filter_linear_mipmap, repeat_enable;
uniform float energy = 1.0;
void sky() {
	vec3 d = EYEDIR;
	float h = d.y;
	vec3 col = mix(horizon.rgb, zenith.rgb, smoothstep(-0.02, 0.55, h));
	col += glow_color.rgb * glow_energy * exp(-max(h, 0.0) / max(glow_height, 0.01));
	vec3 gd = normalize(dir_glow_dir);
	float dg = max(dot(normalize(vec3(d.x, 0.0, d.z)), normalize(vec3(gd.x, 0.0, gd.z))), 0.0);
	float dgl = pow(dg, 1.0 / max(dir_glow_width, 0.05)) * exp(-max(h, 0.0) / max(glow_height * 2.0, 0.02));
	col += dir_glow_color.rgb * dir_glow_energy * dgl;
	if (h > 0.0) {
		vec2 uv = d.xz / (h + 0.08) * 0.045;
		float n = texture(cloud_noise, uv + vec2(TIME * 0.0015, 0.0)).r * 0.6 + texture(cloud_noise, uv * 2.7 + 0.3).r * 0.4;
		float cov = smoothstep(1.0 - cloud_amount, 1.15 - cloud_amount * 0.6, n);
		float under = exp(-h * 3.0);
		vec3 cl = cloud_color.rgb * cloud_energy * (0.25 + 1.2 * under) + dir_glow_color.rgb * dir_glow_energy * dgl * 0.6;
		col = mix(col, cl, cov * smoothstep(0.0, 0.08, h) * 0.95);
	}
	COLOR = col * energy;
}
