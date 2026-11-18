// Shop / kiosk / vending glass: mostly clear, strong fresnel reflections, smudges, rain droplets.
shader_type spatial;
render_mode blend_mix, cull_back, depth_draw_opaque, diffuse_burley, specular_schlick_ggx;
#include "res://shaders/common.gdshaderinc"
uniform vec4 tint : source_color = vec4(0.55, 0.65, 0.68, 1.0);
uniform float base_alpha = 0.12;
uniform float opaque = 0.0; // 1 = dark tinted car glass
varying vec3 wpos;
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	vec2 p = wpos.xy + wpos.zz;
	float smudge = nz(p * 0.7);
	// droplets
	vec2 g = p * 9.0;
	vec2 c = floor(g);
	vec2 o = hash22(c);
	float drop = (1.0 - smoothstep(0.08, 0.16, length(fract(g) - o * 0.8 - 0.1))) * step(0.6, hash21(c + 4.0)) * g_rain;
	ALBEDO = mix(tint.rgb * 0.08, vec3(0.01), opaque);
	ROUGHNESS = mix(0.03, 0.18, smudge * smudge) + drop * 0.1;
	SPECULAR = 0.7;
	METALLIC = 0.0;
	ALPHA = mix(clamp(base_alpha + fres * 0.65 + smudge * 0.06 + drop * 0.25, 0.0, 1.0), 1.0, opaque);
}
