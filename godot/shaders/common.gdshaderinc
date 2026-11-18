// Shared helpers + global uniforms (set from the look preset by scripts/mats.gd).
global uniform sampler2D g_noise : filter_linear_mipmap, repeat_enable;
global uniform float g_wetness;
global uniform float g_puddles;
global uniform float g_rain;
global uniform float g_grime;

float hash11(float p) { p = fract(p * 0.1031); p *= p + 33.33; p *= p + p; return fract(p); }
float hash21(vec2 p) { vec3 p3 = fract(vec3(p.xyx) * 0.1031); p3 += dot(p3, p3.yzx + 33.33); return fract((p3.x + p3.y) * p3.z); }
vec2 hash22(vec2 p) { vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973)); p3 += dot(p3, p3.yzx + 33.33); return fract((p3.xx + p3.yz) * p3.zy); }
float hash31(vec3 p) { p = fract(p * 0.1031); p += dot(p, p.zyx + 31.32); return fract((p.x + p.y) * p.z); }

float nz(vec2 uv) { return texture(g_noise, uv).r; }
float fbm(vec2 uv) { return nz(uv) * 0.55 + nz(uv * 2.13 + 0.31) * 0.3 + nz(uv * 4.37 + 0.71) * 0.15; }

// Dominant-axis planar coordinates in metres; axis: 0 = horizontal surface (x,z), 1 = faces X (z,y), 2 = faces Z (x,y)
vec2 plane_uv(vec3 wp, vec3 wn, out int axis) {
	vec3 a = abs(wn);
	if (a.y > 0.6) { axis = 0; return wp.xz; }
	if (a.x > a.z) { axis = 1; return vec2(wp.z, wp.y); }
	axis = 2; return vec2(wp.x, wp.y);
}

vec3 plane_t1(int axis) { return axis == 0 ? vec3(1.0, 0.0, 0.0) : (axis == 1 ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0)); }
vec3 plane_t2(int axis) { return axis == 0 ? vec3(0.0, 0.0, 1.0) : vec3(0.0, 1.0, 0.0); }

float luma(vec3 c) { return dot(c, vec3(0.2126, 0.7152, 0.0722)); }

// Expanding rain ripple rings on a horizontal surface; returns a 2D normal offset.
vec2 rain_ripples(vec2 p, float t, float amount) {
	vec2 acc = vec2(0.0);
	for (int layer = 0; layer < 2; layer++) {
		float sc = layer == 0 ? 1.7 : 2.9;
		vec2 q = p * sc + float(layer) * 7.3;
		vec2 cell = floor(q);
		for (int j = -1; j <= 1; j++) {
			for (int i = -1; i <= 1; i++) {
				vec2 c = cell + vec2(float(i), float(j));
				vec2 rnd = hash22(c);
				float ph = fract(t * (0.55 + rnd.y * 0.5) + rnd.x * 7.0);
				vec2 ctr = c + 0.15 + 0.7 * hash22(c + 3.1);
				vec2 d = q - ctr;
				float r = length(d);
				float rad = ph * 0.75;
				float ring = sin(clamp((r - rad) * 28.0, -6.2832, 6.2832)) * (1.0 - smoothstep(0.0, 0.12, abs(r - rad)));
				float fade = (1.0 - ph) * (1.0 - ph);
				acc += (r > 0.001 ? d / r : vec2(0.0)) * ring * fade;
			}
		}
	}
	return acc * amount * 0.35;
}
