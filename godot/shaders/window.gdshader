// Facade window glass with a fake room behind it (interior mapping): back wall, side walls, floor,
// ceiling with a lamp, furniture silhouettes, blinds or curtains. A random subset is lit (g_win_lit),
// tinted from the preset palette texture (g_win_palette). Unlit panes are dark reflective glass.
// Needs per-pane UV 0..1 (UV) and pane size in metres (UV2), both written by the Blender kit.
shader_type spatial;
render_mode blend_mix, cull_back, diffuse_burley, specular_schlick_ggx;
#include "res://shaders/common.gdshaderinc"
global uniform sampler2D g_win_palette : filter_linear, repeat_enable;
global uniform float g_win_lit;
global uniform float g_win_bright;
global uniform float g_win_blinds;
instance uniform float lit_bias : instance_index(2) = 0.0;
instance uniform float win_seed : instance_index(3) = 0.0;

varying vec3 v_pos;
varying vec3 v_cam;
varying vec3 v_n;
varying vec3 v_org;

void vertex() {
	v_pos = VERTEX;
	v_n = NORMAL;
	v_cam = (inverse(MODEL_MATRIX) * vec4(CAMERA_POSITION_WORLD, 1.0)).xyz;
	v_org = MODEL_MATRIX[3].xyz;
}

vec3 room_color(vec3 hit, int face, vec2 size, vec2 rw, float depth, vec3 tint, float h1, float h2, float h3) {
	// face: 0 back, 1 floor, 2 ceiling, 3 side
	vec3 lamp = vec3(size.x * (0.3 + 0.4 * h2), size.y + rw.y - 0.05, -depth * (0.35 + 0.3 * h3));
	float d = length(hit - lamp);
	float light = 1.8 / (1.0 + d * d * 0.6);
	vec3 wall = tint * (0.55 + 0.45 * h1);
	vec3 c;
	if (face == 0) {
		c = wall * (0.25 + 0.7 * light);
		// furniture silhouettes against the back wall
		float shelf = step(hit.y, -rw.y + 1.1 + 0.6 * h2) * step(abs(hit.x - size.x * h3), 0.5 + 0.6 * h1);
		c *= 1.0 - 0.75 * shelf;
		// a picture / screen on the wall
		vec2 pc = vec2(size.x * (0.2 + 0.6 * h1), 0.9 + 0.4 * h2);
		vec2 dd = abs(hit.xy - pc) - vec2(0.35, 0.22);
		float pic = step(max(dd.x, dd.y), 0.0);
		c = mix(c, tint.zyx * 1.4 + 0.1, pic * step(0.55, h3));
	} else if (face == 1) {
		c = wall * 0.12 * (0.3 + light);
	} else if (face == 2) {
		c = wall * (0.35 + 1.5 * light);
		c += tint * 4.0 * (1.0 - smoothstep(0.15, 0.4, length(hit.xz - lamp.xz)));
	} else {
		c = wall * (0.2 + 0.7 * light) * 0.7;
	}
	return c;
}

void fragment() {
	vec3 n = normalize(v_n);
	vec3 ut = abs(n.y) > 0.9 ? vec3(1.0, 0.0, 0.0) : normalize(cross(vec3(0.0, 1.0, 0.0), n));
	vec3 vt = cross(n, ut);
	// glTF flips V on every UV set, so the pane height comes back as 1 - h
	vec2 size = max(vec2(UV2.x, 1.0 - UV2.y), vec2(0.2));
	vec2 q = vec2(UV.x, 1.0 - UV.y) * size;
	vec3 dir = normalize(v_pos - v_cam);
	vec3 rd = vec3(dot(dir, ut), dot(dir, vt), dot(dir, n));
	rd.z = min(rd.z, -0.02);

	float seed = hash21(v_org.xz * 0.731 + vec2(v_org.y * 1.37, COLOR.r * 97.0 + win_seed * 13.0));
	float h1 = hash11(seed * 91.7);
	float h2 = hash11(seed * 37.3 + 1.0);
	float h3 = hash11(seed * 13.1 + 2.0);
	float h4 = hash11(seed * 71.9 + 3.0);
	bool lit = seed < clamp(g_win_lit + lit_bias, 0.0, 1.0);
	vec3 tint = texture(g_win_palette, vec2(h1, 0.5)).rgb;

	float depth = 2.5 + 3.0 * h2;
	vec2 rw = vec2(0.5 + 1.0 * h3, 0.9);
	vec3 lo = vec3(-rw.x, -rw.y, -depth);
	vec3 hi = vec3(size.x + rw.x, size.y + 0.35, 0.0);
	vec3 o = vec3(q, 0.0);
	vec3 tx = vec3((rd.x > 0.0 ? hi.x - o.x : lo.x - o.x) / (abs(rd.x) < 1e-4 ? 1e-4 : rd.x),
				   (rd.y > 0.0 ? hi.y - o.y : lo.y - o.y) / (abs(rd.y) < 1e-4 ? 1e-4 : rd.y),
				   (lo.z - o.z) / rd.z);
	float t = min(min(tx.x, tx.y), tx.z);
	vec3 hit = o + rd * t;
	int face = (t == tx.z) ? 0 : ((t == tx.y) ? (rd.y < 0.0 ? 1 : 2) : 3);
	vec3 inner = room_color(hit, face, size, vec2(rw.x, 0.35), depth, tint, h1, h2, h3);
	// soft vignette towards the room's far corners
	inner *= 1.0 - 0.35 * clamp(t / (depth * 2.0), 0.0, 1.0);

	// blinds / curtains a few cm behind the glass
	float tb = -0.05 / rd.z;
	vec2 pb = (o + rd * tb).xy;
	float blind_kind = h4 < g_win_blinds ? (h4 < g_win_blinds * 0.5 ? 1.0 : 2.0) : 0.0;
	float cover = 0.0;
	vec3 cover_col = vec3(0.0);
	if (blind_kind == 1.0) { // venetian blinds lowered to a random height
		float level = size.y * (0.15 + 0.85 * h3);
		if (pb.y > size.y - level) {
			float slat = smoothstep(0.35, 0.5, abs(fract(pb.y / 0.045) - 0.5));
			cover = 1.0 - slat * 0.75;
			cover_col = tint * (0.55 + 0.25 * h1);
		}
	} else if (blind_kind == 2.0) { // curtain drawn from one side
		float cw = size.x * (0.25 + 0.6 * h3);
		bool left = h1 > 0.5;
		if ((left && pb.x < cw) || (!left && pb.x > size.x - cw)) {
			float folds = 0.75 + 0.25 * sin(pb.x * 40.0 + h2 * 6.0);
			cover = 0.92;
			cover_col = tint * vec3(1.0, 0.82, 0.7) * 0.5 * folds;
		}
	}

	float fres = pow(1.0 - clamp(-rd.z, 0.0, 1.0), 4.0);
	vec3 em = vec3(0.0);
	if (lit) {
		vec3 room = mix(inner, cover_col, cover);
		em = room * g_win_bright * (0.7 + 0.6 * h4) * (1.0 - fres * 0.8);
	} else {
		// dark room, faint ambient bounce and occasional TV glow
		float tv = step(0.93, h4) * step(0.5, h2);
		em = (inner * 0.025 + tv * vec3(0.15, 0.3, 0.6) * 0.6) * g_win_bright;
	}
	float dirt = nz(UV * size * 0.35 + seed * 3.0);
	ALBEDO = vec3(0.015);
	ROUGHNESS = mix(0.04, 0.22, dirt * dirt);
	METALLIC = 0.0;
	SPECULAR = 0.6;
	EMISSION = em;
}
