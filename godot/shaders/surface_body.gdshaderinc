// Uber shader for every opaque, non-emissive kit surface (walls, metal, plastic, rubber, paint...).
// Patterns are procedural in world space, so modules tile seamlessly and need no textures.
#include "res://shaders/common.gdshaderinc"
global uniform vec4 g_tint_concrete : source_color;
global uniform vec4 g_tint_brick : source_color;
global uniform vec4 g_tint_tile : source_color;
global uniform vec4 g_tint_panel : source_color;

// 0 concrete, 1 brick, 2 tile, 3 metal panel, 4 painted metal, 5 rust, 6 wood, 7 plastic/rubber,
// 8 fabric, 9 grate, 10 car paint, 11 chrome
uniform int pattern = 0;
uniform vec4 base_color : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform int tint_source = 0; // 0 base_color, 1 concrete, 2 brick, 3 tile, 4 panel (global look tints)
uniform float roughness = 0.8;
uniform float metallic = 0.0;
uniform float grime_amount = 1.0;
uniform float wet_amount = 1.0;
uniform float bump = 1.0;
uniform float dark = 1.0; // multiplier (concrete_dark etc.)
instance uniform vec4 inst_tint : instance_index(0) = vec4(1.0, 1.0, 1.0, 0.0); // rgb multiply, a = extra grime
instance uniform vec4 inst_color : instance_index(1) = vec4(0.0); // overrides colour for car paint / fabric when a > 0

varying vec3 wpos;
varying vec3 wnrm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

float brick_h(vec2 p, out float id) {
	float bw = 0.25, bh = 0.075, m = 0.011;
	float row = floor(p.y / bh);
	float x = p.x / bw + row * 0.5;
	float col = floor(x);
	id = hash21(vec2(col, row));
	vec2 f = vec2(fract(x) * bw, fract(p.y / bh) * bh);
	float e = min(min(f.x, bw - f.x), min(f.y, bh - f.y));
	return smoothstep(m * 0.4, m, e);
}

float tile_h(vec2 p, out float id) {
	float s = 0.1, m = 0.004;
	vec2 c = floor(p / s);
	id = hash21(c);
	vec2 f = fract(p / s) * s;
	float e = min(min(f.x, s - f.x), min(f.y, s - f.y));
	return smoothstep(m * 0.3, m, e);
}

float height_at(vec2 p, int pat, out float id) {
	id = 0.0;
	if (pat == 1) return brick_h(p, id) * 0.9 + nz(p * 3.1) * 0.1;
	if (pat == 2) return tile_h(p, id);
	if (pat == 0) return nz(p * 2.3) * 0.6 + nz(p * 9.0) * 0.4;
	if (pat == 5) return nz(p * 4.0);
	if (pat == 6) return nz(vec2(p.x * 0.3, p.y * 12.0)) * 0.7 + smoothstep(0.0, 0.02, abs(fract(p.y * 6.0) - 0.5) - 0.47);
	if (pat == 9) return step(0.5, fract(p.x * 18.0));
	return nz(p * 5.0) * 0.3;
}

void fragment() {
	int axis;
	vec3 wn = normalize(wnrm);
	if (!FRONT_FACING) wn = -wn;
	vec2 p = plane_uv(wpos, wn, axis);
	float id;
	float h0 = height_at(p, pattern, id);
	float id2;
	float e = 0.006;
	float hx = height_at(p + vec2(e, 0.0), pattern, id2);
	float hy = height_at(p + vec2(0.0, e), pattern, id2);
	vec2 grad = vec2(hx - h0, hy - h0) / e;

	vec3 base = base_color.rgb;
	if (tint_source == 1) base = g_tint_concrete.rgb;
	else if (tint_source == 2) base = g_tint_brick.rgb;
	else if (tint_source == 3) base = g_tint_tile.rgb;
	else if (tint_source == 4) base = g_tint_panel.rgb;
	if (inst_color.a > 0.0) base = inst_color.rgb;
	base *= inst_tint.rgb * dark;

	float big = fbm(p * 0.07 + 0.37);
	float mid = nz(p * 0.9);
	float rough = roughness;
	float met = metallic;
	vec3 alb = base;
	float bump_k = 0.0015;

	if (pattern == 0) { // concrete
		alb *= 0.78 + 0.42 * big;
		alb *= 0.9 + 0.2 * mid;
		alb *= 0.93 + 0.14 * nz(p * 7.0);
		bump_k = 0.006;
	} else if (pattern == 1) { // brick
		vec3 bc = base * (0.62 + 0.62 * id) * vec3(1.0 + 0.12 * (id - 0.5), 1.0, 1.0 - 0.15 * (id - 0.5));
		vec3 mc = vec3(luma(base)) * 1.25 + 0.04;
		alb = mix(mc, bc, h0) * (0.85 + 0.3 * big);
		rough = mix(0.95, rough, h0);
		bump_k = 0.0025;
	} else if (pattern == 2) { // glazed tile
		vec3 tc = base * (0.82 + 0.36 * id);
		if (id > 0.965) tc = g_tint_concrete.rgb * 0.6;
		alb = mix(vec3(luma(base)) * 0.6, tc, h0) * (0.9 + 0.2 * big);
		rough = mix(0.9, 0.22, h0);
		bump_k = 0.0015;
	} else if (pattern == 3) { // painted metal panel
		alb *= 0.85 + 0.25 * big;
		alb *= 0.95 + 0.1 * nz(vec2(p.x * 0.5, p.y * 6.0));
		float rust = smoothstep(0.62, 0.78, fbm(p * 0.35 + 5.0)) * grime_amount;
		alb = mix(alb, vec3(0.22, 0.1, 0.05), rust * 0.7);
		rough = mix(rough, 0.95, rust);
		met = 0.35 * (1.0 - rust);
	} else if (pattern == 4) { // painted metal
		alb *= 0.85 + 0.3 * mid;
		met = metallic;
	} else if (pattern == 5) { // rust
		alb = mix(vec3(0.24, 0.11, 0.05), vec3(0.42, 0.2, 0.08), nz(p * 2.0)) * (0.7 + 0.5 * big);
		rough = 0.9;
		met = 0.2;
		bump_k = 0.006;
	} else if (pattern == 6) { // wood
		alb *= 0.7 + 0.5 * nz(vec2(p.x * 0.4, p.y * 9.0));
		rough = 0.85;
	} else if (pattern == 7) { // plastic / rubber
		alb *= 0.85 + 0.3 * mid;
	} else if (pattern == 8) { // fabric with stripes from vertex colour
		float stripe = step(0.5, COLOR.r);
		alb = mix(alb, mix(alb, vec3(0.85, 0.82, 0.75), 0.75), stripe);
		alb *= 0.85 + 0.25 * nz(p * 3.0);
		rough = 0.95;
		bump_k = 0.003;
	} else if (pattern == 9) { // grate
		alb *= 0.6 + 0.4 * h0;
		met = 0.6;
	} else if (pattern == 10) { // car paint
		alb *= 0.95 + 0.1 * mid;
		met = 0.45;
		rough = 0.22;
		CLEARCOAT = 1.0;
		CLEARCOAT_ROUGHNESS = 0.05;
		bump_k = 0.0;
	} else if (pattern == 11) { // chrome
		met = 1.0;
		rough = 0.12;
		bump_k = 0.0;
	}

	// grime: vertical streaks, ground dirt, blotches
	float gr = clamp(g_grime * grime_amount + inst_tint.a, 0.0, 2.0);
	if (gr > 0.0 && axis != 0) {
		float streak = nz(vec2(p.x * 0.9, wpos.y * 0.035 + p.x * 0.05));
		streak = smoothstep(0.45, 0.85, streak);
		float ground = 1.0 - smoothstep(0.0, 2.2, wpos.y);
		float blot = smoothstep(0.5, 0.8, fbm(p * 0.18 + 11.0));
		float g = clamp((streak * 0.55 + ground * 0.5 + blot * 0.4) * gr, 0.0, 0.85);
		alb *= 1.0 - g * 0.7;
		alb = mix(alb, alb * vec3(0.9, 0.85, 0.7), g * 0.5);
		rough = mix(rough, 0.95, g * 0.4);
	} else if (gr > 0.0) {
		float blot = smoothstep(0.4, 0.8, fbm(p * 0.25 + 3.0));
		alb *= 1.0 - blot * 0.45 * gr;
	}

	// wetness: darker albedo, glossy films, more on up-facing surfaces and low down
	float up = clamp(wn.y, 0.0, 1.0);
	float wet = clamp(g_wetness * wet_amount, 0.0, 1.0);
	float wcov = wet * clamp(0.45 + 0.55 * up + 0.35 * nz(vec2(p.x * 0.6, wpos.y * 0.15)) + (1.0 - smoothstep(0.0, 3.0, wpos.y)) * 0.3, 0.0, 1.0);
	if (pattern != 10 && pattern != 11) {
		alb *= mix(1.0, 0.55, wcov * (1.0 - met * 0.6));
		rough = mix(rough, mix(0.32, 0.06, up), wcov);
	}

	ALBEDO = alb;
	ROUGHNESS = clamp(rough, 0.03, 1.0);
	METALLIC = met;
	SPECULAR = 0.5;
	// world-space normal perturbation from the procedural height
	vec3 t1 = plane_t1(axis);
	vec3 t2 = plane_t2(axis);
	vec3 nwp = normalize(wn - bump * bump_k * (grad.x * t1 + grad.y * t2));
	NORMAL = normalize((VIEW_MATRIX * vec4(nwp, 0.0)).xyz);
}
