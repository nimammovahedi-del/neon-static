// Wet asphalt: aggregate, repair patches, cracks, polished wheel paths, worn lane markings,
// crosswalk stripes, puddles (near-mirror, rain ripples) so neon smears along the road via SSR.
shader_type spatial;
render_mode blend_mix, cull_back, diffuse_burley, specular_schlick_ggx;
#include "res://shaders/common.gdshaderinc"

uniform vec4 asphalt : source_color = vec4(0.07, 0.07, 0.075, 1.0);
uniform vec4 mark_white : source_color = vec4(0.75, 0.75, 0.72, 1.0);
uniform vec4 mark_yellow : source_color = vec4(0.75, 0.55, 0.1, 1.0);
uniform float half_width = 7.0;
uniform float along_axis = 0.0; // 0: road runs along Z, 1: along X (cross street)
uniform vec2 crosswalk_a = vec2(-34.0, -30.0);
uniform vec2 crosswalk_b = vec2(-104.0, -100.0);
uniform vec2 crosswalk_c = vec2(-84.0, -80.0);
uniform vec2 junction = vec2(-100.0, -84.0);
uniform float markings = 1.0;
uniform float puddle_scale = 1.0;

varying vec3 wpos;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float box1(float x, float a, float b, float aa) { return smoothstep(a - aa, a + aa, x) * (1.0 - smoothstep(b - aa, b + aa, x)); }

void fragment() {
	vec2 p = along_axis > 0.5 ? vec2(wpos.z, wpos.x) : wpos.xz; // p.x across the road, p.y along it
	float ax = abs(p.x);
	float aa = fwidth(p.x) * 1.5 + 0.004;
	// --- asphalt base
	float big = fbm(p * 0.045);
	float agg = nz(p * 7.0);
	float agg2 = nz(p * 23.0);
	vec3 col = asphalt.rgb * (0.7 + 0.6 * big) * (0.85 + 0.3 * agg) * (0.9 + 0.2 * agg2);
	float rough = 0.78 - 0.12 * agg2;
	// repair patches
	vec2 pc = floor(p / vec2(3.5, 7.0));
	float ph = hash21(pc + 17.0);
	vec2 pf = fract(p / vec2(3.5, 7.0));
	float patch = step(0.82, ph) * box1(pf.x, 0.1, 0.1 + 0.6 * hash11(ph * 9.0) + 0.2, 0.01) * box1(pf.y, 0.15, 0.85, 0.01);
	col = mix(col, asphalt.rgb * (0.55 + 0.9 * hash11(ph * 3.0)), patch);
	// cracks
	float cr = abs(nz(p * 0.31 + 4.0) - 0.5);
	float crack = 1.0 - smoothstep(0.004, 0.012, cr);
	crack *= smoothstep(0.45, 0.7, nz(p * 0.08 + 1.3));
	col *= 1.0 - crack * 0.7;
	// polished wheel paths in each lane
	float lane_c = (ax < 3.5) ? 1.75 : 5.25;
	float wheel = box1(abs(ax - lane_c), 0.45, 1.05, 0.25);
	rough -= wheel * 0.1;
	col *= 1.0 - wheel * 0.12;
	// oil stains near the kerb (parking lane)
	float oil = smoothstep(0.62, 0.8, nz(p * vec2(0.6, 0.25) + 9.0)) * box1(ax, 4.2, 6.6, 0.4);
	col *= 1.0 - oil * 0.45;
	// --- markings
	float in_junction = box1(p.y, junction.x, junction.y, 0.05);
	float m_white = 0.0;
	float m_yellow = 0.0;
	if (markings > 0.5) {
		float dash = step(fract(p.y / 9.0), 0.36);
		m_white += box1(ax, 3.44, 3.56, aa) * dash;
		m_white += box1(ax, half_width - 0.45, half_width - 0.33, aa);
		m_yellow += box1(ax, 0.07, 0.19, aa);
		m_white *= 1.0 - in_junction;
		m_yellow *= 1.0 - in_junction;
		// crosswalk stripes
		vec2 cws[3] = vec2[](crosswalk_a, crosswalk_b, crosswalk_c);
		for (int i = 0; i < 3; i++) {
			vec2 cw = cws[i];
			float inside = box1(p.y, cw.x, cw.y, 0.02) * (1.0 - step(half_width - 0.3, ax));
			float stripes = step(0.5, fract(p.x / 1.1 + 0.25));
			m_white = max(m_white, inside * stripes);
			// stop line
			m_white = max(m_white, box1(p.y, cw.y + 1.5, cw.y + 1.9, 0.01) * step(p.x, 0.0) * step(-half_width + 0.4, p.x));
			m_white = max(m_white, box1(p.y, cw.x - 1.9, cw.x - 1.5, 0.01) * step(0.0, p.x) * step(p.x, half_width - 0.4));
		}
	}
	float wear = smoothstep(0.25, 0.7, nz(p * vec2(1.3, 0.4) + 2.0)) * 0.7 + agg2 * 0.3;
	float mw = m_white * (1.0 - wear * 0.45);
	float my = m_yellow * (1.0 - wear * 0.35);
	col = mix(col, mark_white.rgb, mw);
	col = mix(col, mark_yellow.rgb, my);
	rough = mix(rough, 0.45, max(mw, my));

	// --- wetness and puddles
	float wet = clamp(g_wetness, 0.0, 1.0);
	float gutter = 1.0 - smoothstep(0.0, 1.4, half_width - ax);
	float rut = wheel * 0.25;
	float pm = fbm(p * 0.075 * puddle_scale + 31.0) * 0.8 + nz(p * 0.4 + 3.0) * 0.25 + gutter * 0.45 + rut + patch * 0.2;
	float thr = 1.0 - g_puddles * 0.55;
	float puddle = smoothstep(thr, thr + 0.06, pm) * wet;
	float damp = wet * (0.7 + 0.3 * nz(p * 0.5));
	col *= mix(1.0, mix(0.6, 0.85, max(mw, my)), damp);
	rough = mix(rough, 0.07 + 0.12 * agg2, damp);
	col = mix(col, col * 0.45, puddle);
	rough = mix(rough, 0.012, puddle);

	// --- normals: aggregate bump everywhere, ripples on puddles
	vec2 nrm = vec2(nz(p * 23.0 + vec2(0.02, 0.0)) - agg2, nz(p * 23.0 + vec2(0.0, 0.02)) - agg2) * 0.6 * (1.0 - puddle);
	vec2 rip = rain_ripples(p, TIME, g_rain) * (0.25 + 0.75 * puddle) * wet;
	nrm += rip;
	vec3 nw = along_axis > 0.5 ? normalize(vec3(-nrm.y, 1.0, -nrm.x)) : normalize(vec3(-nrm.x, 1.0, -nrm.y));
	ALBEDO = col;
	ROUGHNESS = clamp(rough, 0.01, 1.0);
	SPECULAR = 0.5;
	METALLIC = 0.0;
	NORMAL = normalize((VIEW_MATRIX * vec4(nw, 0.0)).xyz);
}
