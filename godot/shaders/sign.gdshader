// Lightbox sign face. Art is an RGB mask atlas (R panel, G text/shape, B accent) recoloured per
// instance with three preset colours. atlas: 0 horizontal (4x8), 1 vertical (8x2), 2 glyph cells (8x8),
// 3 billboards (2x4). mode 0: dark panel + glowing text, 1: bright panel + dark text.
shader_type spatial;
render_mode blend_mix, cull_back, diffuse_burley, specular_schlick_ggx;
global uniform float g_sign_bright;
uniform sampler2D atlas_h : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D atlas_v : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D atlas_g : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D atlas_b : source_color, filter_linear_mipmap_anisotropic;
uniform float energy = 3.5;
instance uniform vec4 sign_a : instance_index(7), source_color = vec4(0.05, 0.02, 0.1, 1.0); // panel colour
instance uniform vec4 sign_b : instance_index(8), source_color = vec4(1.0, 0.2, 0.7, 1.0);   // text colour
instance uniform vec4 sign_c : instance_index(9), source_color = vec4(0.2, 0.9, 1.0, 1.0);   // accent colour
instance uniform vec4 sign_cell : instance_index(10) = vec4(0.0, 0.0, 0.0, 1.0);             // atlas, cell, mode, brightness
instance uniform vec4 sign_glyphs : instance_index(11) = vec4(-1.0);                          // glyph-cell index per cube (blade_b)
void fragment() {
	int at = int(sign_cell.x + 0.5);
	float cell = floor(sign_cell.y + 0.5);
	if (at == 2 && sign_glyphs.x >= 0.0) {
		int k = int(COLOR.r * 4.0 + 0.5);
		cell = k == 0 ? sign_glyphs.x : (k == 1 ? sign_glyphs.y : (k == 2 ? sign_glyphs.z : sign_glyphs.w));
	}
	vec2 grid = at == 0 ? vec2(4.0, 8.0) : (at == 1 ? vec2(8.0, 2.0) : (at == 2 ? vec2(8.0, 8.0) : vec2(2.0, 4.0)));
	float n = grid.x * grid.y;
	cell = mod(cell, n);
	vec2 cuv = (vec2(mod(cell, grid.x), floor(cell / grid.x)) + clamp(UV, vec2(0.002), vec2(0.998))) / grid;
	vec3 m;
	if (at == 0) m = texture(atlas_h, cuv).rgb;
	else if (at == 1) m = texture(atlas_v, cuv).rgb;
	else if (at == 2) m = texture(atlas_g, cuv).rgb;
	else m = texture(atlas_b, cuv).rgb;
	float mode = sign_cell.z;
	vec3 col;
	if (mode < 0.5) {
		col = sign_a.rgb * m.r * 0.35 + sign_b.rgb * m.g * 1.6 + sign_c.rgb * m.b;
	} else {
		col = mix(sign_a.rgb * (0.4 + 0.8 * m.r), sign_b.rgb * 0.08, m.g) + sign_c.rgb * m.b * 0.8;
	}
	// lightbox hot spots: fluorescent tubes behind the face
	float tubes = 0.85 + 0.15 * sin(UV.y * 3.14159 * 3.0);
	float edge = smoothstep(0.0, 0.06, min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y)));
	float b = sign_cell.w;
	ALBEDO = col * 0.15;
	ROUGHNESS = 0.6; // diffuser plastic: matte, so faces never mirror bright surroundings
	SPECULAR = 0.3;
	EMISSION = col * energy * b * g_sign_bright * tubes * (0.75 + 0.25 * edge);
}
