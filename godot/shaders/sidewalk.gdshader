// Paving slabs 0.6 m: seams, per-slab tone and tilt, cracked slabs, gum spots, grime near walls,
// shallow puddles where slabs sink. Works on any horizontal plane (world XZ).
shader_type spatial;
render_mode blend_mix, cull_back, diffuse_burley, specular_schlick_ggx;
#include "res://shaders/common.gdshaderinc"
uniform vec4 slab_color : source_color = vec4(0.32, 0.31, 0.3, 1.0);
uniform vec2 slab = vec2(0.6, 0.6);
uniform float wall_x = 11.0;
uniform float tactile_z0 = -35.0;
uniform float tactile_z1 = -29.0;
uniform float tactile_x = 7.15;

varying vec3 wpos;
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }

void fragment() {
	vec2 p = wpos.xz;
	vec2 g = p / slab;
	vec2 c = floor(g);
	vec2 f = fract(g);
	float id = hash21(c);
	vec2 e = min(f, 1.0 - f) * slab;
	float edge = min(e.x, e.y);
	float seam = 1.0 - smoothstep(0.003, 0.009, edge);
	vec3 col = slab_color.rgb * (0.8 + 0.35 * id) * (0.88 + 0.24 * nz(p * 3.0));
	col *= 0.9 + 0.2 * fbm(p * 0.1);
	// cracked slabs
	float crk = step(0.9, hash11(id * 7.0)) * (1.0 - smoothstep(0.003, 0.01, abs(f.x + f.y * (0.4 + id) - 0.9) * slab.x));
	col *= 1.0 - crk * 0.6;
	// gum spots
	vec2 gp = fract(p * 1.7) - 0.5;
	float gum = step(0.97, hash21(floor(p * 1.7))) * (1.0 - smoothstep(0.08, 0.12, length(gp)));
	col = mix(col, vec3(0.12), gum * 0.6);
	// grime towards walls and kerb
	float aw = abs(abs(wpos.x) - wall_x);
	float grime = (1.0 - smoothstep(0.0, 1.2, aw)) * 0.5 + smoothstep(0.55, 0.85, fbm(p * 0.25 + 5.0)) * 0.5;
	col *= 1.0 - grime * g_grime * 0.6;
	// tactile paving strip at the crosswalk
	float tz = step(tactile_z0, wpos.z) * step(wpos.z, tactile_z1) * step(abs(abs(wpos.x) - tactile_x - 0.3), 0.3);
	vec2 dp = fract(p / 0.06) - 0.5;
	float dots = 1.0 - smoothstep(0.18, 0.26, length(dp));
	col = mix(col, vec3(0.55, 0.42, 0.08) * (0.8 + 0.4 * dots), tz);
	col = mix(col, col * 0.35, seam);

	float wet = clamp(g_wetness, 0.0, 1.0);
	float sink = hash11(id * 3.3);
	float pm = sink * 0.6 + fbm(p * 0.2 + 2.0) * 0.6 + seam * 0.3;
	float thr = 1.05 - g_puddles * 0.45;
	float puddle = smoothstep(thr, thr + 0.05, pm) * wet;
	col *= mix(1.0, 0.58, wet);
	float rough = mix(0.85, 0.1 + 0.14 * nz(p * 4.0), wet);
	rough = mix(rough, 0.03, puddle);
	col = mix(col, col * 0.6, puddle);
	// slab tilt + seam groove normal
	vec2 tilt = (hash22(c) - 0.5) * 0.03;
	vec2 sd = vec2(f.x < 0.5 ? -1.0 : 1.0, f.y < 0.5 ? -1.0 : 1.0);
	vec2 groove = (e.x < e.y ? vec2(sd.x, 0.0) : vec2(0.0, sd.y)) * seam * 0.6;
	vec2 rip = rain_ripples(p, TIME, g_rain) * puddle;
	vec2 nn = (tilt + groove) * (1.0 - puddle) + rip;
	vec3 nw = normalize(vec3(-nn.x, 1.0, -nn.y));
	ALBEDO = col;
	ROUGHNESS = rough;
	SPECULAR = 0.5;
	NORMAL = normalize((VIEW_MATRIX * vec4(nw, 0.0)).xyz);
}
