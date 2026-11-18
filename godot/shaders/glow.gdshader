// Generic emissive part (lamp lenses, LED strips, car lights, signal lamps, blinkers, shop lights,
// interiors). Colour comes from a global (source) or the material colour, times energy.
shader_type spatial;
render_mode blend_mix, cull_back, diffuse_burley, specular_schlick_ggx;
global uniform vec4 g_lamp_color : source_color;
global uniform float g_lamp_energy;
global uniform vec4 g_led_color : source_color;
global uniform float g_led_energy;
global uniform vec4 g_blinker : source_color;
global uniform vec4 g_shop_light : source_color;
global uniform float g_shop_energy;
global uniform vec4 g_tail_color : source_color;
global uniform vec4 g_head_color : source_color;
global uniform vec4 g_holo_color : source_color;
global uniform float g_sign_bright;
global uniform sampler2D g_noise : filter_linear_mipmap, repeat_enable;
// 0 own colour, 1 lamp, 2 led, 3 blinker, 4 shop light, 5 tail, 6 head, 7 holo, 8 interior (shop-lit albedo),
// 9 goods (random pastel hue per part from vertex colour, lit by the shop light)
uniform int source = 0;
uniform vec4 color : source_color = vec4(1.0);
uniform float energy = 1.0;
uniform float albedo_mix = 0.0; // interiors: lit surface instead of pure emission
instance uniform vec4 inst_glow : instance_index(13) = vec4(0.0); // rgb override colour when a > 0, a = energy multiplier
varying vec3 wpos;
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec3 c = color.rgb;
	float e = energy;
	if (source == 1) { c = g_lamp_color.rgb; e *= g_lamp_energy; }
	else if (source == 2) { c = g_led_color.rgb; e *= g_led_energy; }
	else if (source == 3) { c = g_blinker.rgb; }
	else if (source == 4) { c = g_shop_light.rgb; e *= g_shop_energy; }
	else if (source == 5) { c = g_tail_color.rgb; }
	else if (source == 6) { c = g_head_color.rgb; }
	else if (source == 7) { c = g_holo_color.rgb; e *= g_sign_bright; }
	else if (source == 8) { c = color.rgb * g_shop_light.rgb; e *= g_shop_energy; }
	else if (source == 9) {
		float h = fract(COLOR.r * 7.31);
		vec3 hue = clamp(abs(mod(h * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
		c = mix(vec3(1.0), hue, 0.65) * mix(g_shop_light.rgb, vec3(1.0), 0.4);
		e *= g_shop_energy * (0.6 + 0.8 * fract(COLOR.r * 13.7));
	}
	if (inst_glow.a > 0.0) { c = inst_glow.rgb; e *= inst_glow.a; }
	if (source == 8) {
		float n = texture(g_noise, wpos.xy * 1.7 + wpos.zz * 0.9).r;
		c *= 0.6 + 0.8 * n;
	}
	ALBEDO = mix(c * 0.05, c, albedo_mix);
	ROUGHNESS = 0.35;
	EMISSION = c * e;
}
