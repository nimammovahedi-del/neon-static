// Window grid for megatowers and for the plain sides / backs of street buildings.
// coord_mode 0: mesh UV in metres (Blender towers, uvk=2). coord_mode 1: world planar (Godot boxes).
// style 0: glass curtain wall (wide panes, thin spandrels). style 1: punched windows in a wall.
shader_type spatial;
render_mode blend_mix, cull_back, diffuse_burley, specular_schlick_ggx;
#include "res://shaders/common.gdshaderinc"
global uniform sampler2D g_win_palette : filter_linear, repeat_enable;
global uniform float g_win_lit;
global uniform float g_win_bright;
global uniform vec4 g_tower_window; // x floor height, y column width, z lit-ratio multiplier, w brightness multiplier
global uniform vec4 g_tint_concrete : source_color;

uniform int coord_mode = 0;
uniform int style = 0;
uniform vec4 wall_color : source_color = vec4(0.08, 0.09, 0.1, 1.0);
uniform vec4 glass_color : source_color = vec4(0.02, 0.025, 0.03, 1.0);
uniform float use_concrete_tint = 0.0;
uniform float lit_mul = 1.0;
uniform float bright_mul = 1.0;
instance uniform float lit_bias : instance_index(2) = 0.0;
instance uniform vec4 inst_tint : instance_index(0) = vec4(1.0, 1.0, 1.0, 0.0);
instance uniform float tower_seed : instance_index(4) = 0.0;

varying vec3 wpos;
varying vec3 wnrm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 wn = normalize(wnrm);
	vec2 p;
	int axis = 2;
	if (coord_mode == 0) {
		p = vec2(UV.x, -UV.y);
	} else {
		p = plane_uv(wpos, wn, axis);
	}
	float fh = g_tower_window.x;
	float cw = style == 1 ? g_tower_window.y * 1.4 : g_tower_window.y;
	vec2 cell_sz = vec2(cw, fh);
	vec2 g = p / cell_sz;
	vec2 cell = floor(g);
	vec2 f = fract(g);
	vec2 fw = fwidth(g);
	// window rectangle inside the cell
	vec2 wlo = style == 1 ? vec2(0.18, 0.28) : vec2(0.04, 0.22);
	vec2 whi = style == 1 ? vec2(0.82, 0.86) : vec2(0.96, 0.97);
	vec2 aa = max(fw, vec2(0.002));
	float mx = smoothstep(wlo.x - aa.x, wlo.x + aa.x, f.x) * (1.0 - smoothstep(whi.x - aa.x, whi.x + aa.x, f.x));
	float my = smoothstep(wlo.y - aa.y, wlo.y + aa.y, f.y) * (1.0 - smoothstep(whi.y - aa.y, whi.y + aa.y, f.y));
	float win = mx * my;
	// far away: fade to the average so the grid never shimmers
	float far = smoothstep(0.35, 0.9, max(fw.x, fw.y));
	float avg_win = (whi.x - wlo.x) * (whi.y - wlo.y);
	win = mix(win, avg_win, far);
	if (coord_mode == 1 && axis == 0) win = 0.0; // roofs of box masses

	float s = tower_seed * 17.0 + floor(wpos.x * 0.01) * 3.0 + floor(wpos.z * 0.01) * 5.0 + float(axis) * 11.0;
	float block = hash21(vec2(floor(cell.x / 5.0), cell.y) + s);
	float cellh = hash21(cell + s * 1.3);
	float ratio = clamp((g_win_lit + lit_bias) * g_tower_window.z * lit_mul, 0.0, 1.0);
	float lit = step(cellh * 0.55 + block * 0.45, ratio);
	float lit_avg = ratio;
	lit = mix(lit, lit_avg, far);
	vec3 tint = texture(g_win_palette, vec2(hash11(block * 7.0 + cellh * 0.3), 0.5)).rgb;
	vec3 avg_tint = texture(g_win_palette, vec2(0.5, 0.5)).rgb;
	tint = mix(tint, avg_tint, far * 0.6);
	// partly covered windows: vertical gradient inside the pane
	float shade = 0.55 + 0.45 * smoothstep(0.0, 1.0, f.y) * (0.5 + 0.5 * hash11(cellh * 41.0));

	vec3 wallc = mix(wall_color.rgb, g_tint_concrete.rgb * 0.7, use_concrete_tint) * inst_tint.rgb;
	wallc *= 0.8 + 0.35 * fbm(p * 0.02 + tower_seed);
	vec3 alb = mix(wallc, glass_color.rgb, win);
	float rough = mix(0.75, 0.08, win);
	float wet = clamp(g_wetness, 0.0, 1.0);
	rough = mix(rough, rough * 0.6, wet);
	ALBEDO = alb;
	ROUGHNESS = rough;
	METALLIC = 0.0;
	SPECULAR = 0.5;
	EMISSION = tint * win * lit * shade * g_win_bright * g_tower_window.w * bright_mul;
}
