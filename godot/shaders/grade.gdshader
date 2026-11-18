// Final colour grade (after tonemapping): saturation with one hue kept (Mono Red), split toning,
// lift/gamma/gain, contrast, vignette, grain, chromatic aberration. All values come from the preset.
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float saturation = 1.0;
uniform float contrast = 1.0;
uniform float gamma = 1.0;
uniform vec4 lift : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 gain : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 shadow_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 highlight_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float split_amount = 0.0;
uniform float keep_hue = 0.0;
uniform float keep_width = 0.0;
uniform float keep_saturation = 1.0;
uniform float vignette = 0.3;
uniform float grain = 0.03;
uniform float chroma = 0.0;
vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + 1e-10)), d / (q.x + 1e-10), q.x);
}
float h21(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 dc = uv - 0.5;
	vec3 c;
	if (chroma > 0.0) {
		vec2 o = dc * chroma * 0.01;
		c = vec3(texture(screen_tex, uv + o).r, texture(screen_tex, uv).g, texture(screen_tex, uv - o).b);
	} else {
		c = texture(screen_tex, uv).rgb;
	}
	float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
	float sat = saturation;
	if (keep_width > 0.0) {
		vec3 hsv = rgb2hsv(c);
		float dh = abs(fract(hsv.x - keep_hue + 0.5) - 0.5);
		float m = (1.0 - smoothstep(keep_width * 0.5, keep_width, dh)) * smoothstep(0.12, 0.35, hsv.y) * smoothstep(0.03, 0.12, hsv.z);
		sat = mix(saturation, keep_saturation, m);
	}
	c = mix(vec3(l), c, sat);
	vec3 tone = mix(shadow_tint.rgb, highlight_tint.rgb, smoothstep(0.05, 0.7, l));
	c = mix(c, c * tone * 1.0, split_amount);
	c = c * (gain.rgb - lift.rgb) + lift.rgb;
	c = pow(max(c, vec3(0.0)), vec3(1.0 / max(gamma, 0.05)));
	c = (c - 0.5) * contrast + 0.5;
	c *= 1.0 - vignette * smoothstep(0.25, 0.9, length(dc * vec2(1.0, 0.75)) * 1.25);
	c += (h21(uv * 1000.0 + fract(TIME)) - 0.5) * grain;
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
