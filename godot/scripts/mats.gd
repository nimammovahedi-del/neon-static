# Material library. Every kit surface is matched by its Blender material NAME (a role such as
# "concrete" or "neon") and replaced by one of the shaders in godot/shaders. Look-wide values are
# pushed into global shader uniforms so a single preset recolours the whole kit.
extends RefCounted

var P: Dictionary
var cache := {}
var noise_tex: NoiseTexture2D
var noise3d: NoiseTexture3D
var cloud_tex: NoiseTexture2D
var _shaders := {}


func _init(preset: Dictionary) -> void:
	P = preset
	_make_noise()
	apply_globals()


func sh(name: String) -> Shader:
	if not _shaders.has(name):
		_shaders[name] = load("res://shaders/%s.gdshader" % name)
	return _shaders[name]


func _make_noise() -> void:
	var fn := FastNoiseLite.new()
	fn.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	fn.frequency = 0.012
	fn.fractal_type = FastNoiseLite.FRACTAL_FBM
	fn.fractal_octaves = 4
	fn.seed = 11
	noise_tex = NoiseTexture2D.new()
	noise_tex.width = 512
	noise_tex.height = 512
	noise_tex.seamless = true
	noise_tex.generate_mipmaps = true
	noise_tex.normalize = true
	noise_tex.noise = fn
	var fn3 := FastNoiseLite.new()
	fn3.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	fn3.frequency = 0.05
	fn3.fractal_octaves = 3
	fn3.seed = 5
	noise3d = NoiseTexture3D.new()
	noise3d.width = 64
	noise3d.height = 64
	noise3d.depth = 64
	noise3d.seamless = true
	noise3d.normalize = true
	noise3d.noise = fn3
	var fc := FastNoiseLite.new()
	fc.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	fc.frequency = 0.008
	fc.fractal_octaves = 5
	fc.seed = 21
	cloud_tex = NoiseTexture2D.new()
	cloud_tex.width = 512
	cloud_tex.height = 512
	cloud_tex.seamless = true
	cloud_tex.generate_mipmaps = true
	cloud_tex.normalize = true
	cloud_tex.noise = fc


func _palette_texture(colors: Array) -> ImageTexture:
	var img := Image.create(64, 1, false, Image.FORMAT_RGBF)
	var n := colors.size()
	for x in 64:
		var c: Color = colors[int(x * n / 64.0) % n] if n > 0 else Color(1, 0.85, 0.6)
		img.set_pixel(x, 0, c)
	return ImageTexture.create_from_image(img)


func apply_globals() -> void:
	var g := RenderingServer
	g.global_shader_parameter_set("g_noise", noise_tex)
	g.global_shader_parameter_set("g_win_palette", _palette_texture(P.window_tints))
	g.global_shader_parameter_set("g_wetness", float(P.wetness))
	g.global_shader_parameter_set("g_puddles", float(P.puddles))
	g.global_shader_parameter_set("g_rain", float(P.rain_amount))
	g.global_shader_parameter_set("g_grime", float(P.grime))
	g.global_shader_parameter_set("g_win_lit", float(P.window_lit))
	g.global_shader_parameter_set("g_win_bright", float(P.window_brightness))
	g.global_shader_parameter_set("g_win_blinds", float(P.window_blinds))
	g.global_shader_parameter_set("g_sign_bright", float(P.sign_brightness))
	g.global_shader_parameter_set("g_shop_light", P.shop_color)
	g.global_shader_parameter_set("g_shop_energy", float(P.shop_energy))
	g.global_shader_parameter_set("g_lamp_color", P.lamp_color)
	g.global_shader_parameter_set("g_lamp_energy", float(P.lamp_lens_energy) * 6.0)
	g.global_shader_parameter_set("g_led_color", P.led_color)
	g.global_shader_parameter_set("g_led_energy", float(P.led_energy))
	g.global_shader_parameter_set("g_blinker", P.blinker_color)
	g.global_shader_parameter_set("g_holo_color", P.holo_colors[0])
	g.global_shader_parameter_set("g_tail_color", P.car_tail_color)
	g.global_shader_parameter_set("g_head_color", P.car_head_color)
	g.global_shader_parameter_set("g_fog_color", P.fog_albedo)
	g.global_shader_parameter_set("g_tint_concrete", P.concrete_tint)
	g.global_shader_parameter_set("g_tint_brick", P.brick_tint)
	g.global_shader_parameter_set("g_tint_tile", P.tile_tint)
	g.global_shader_parameter_set("g_tint_panel", P.panel_tint)
	g.global_shader_parameter_set("g_tower_window", Vector4(4.0, 2.2, float(P.tower_window_lit), float(P.tower_window_brightness)))
	g.global_shader_parameter_set("g_screen_bright", float(P.screen_brightness))


func _surf(pattern: int, color: Color, rough: float, metal := 0.0, tint_source := 0, extra := {}, two_sided := false) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = sh("surface_2s" if two_sided else "surface")
	m.set_shader_parameter("pattern", pattern)
	m.set_shader_parameter("base_color", color)
	m.set_shader_parameter("roughness", rough)
	m.set_shader_parameter("metallic", metal)
	m.set_shader_parameter("tint_source", tint_source)
	for k in extra:
		m.set_shader_parameter(k, extra[k])
	return m


func _glow(source: int, color: Color, energy: float, albedo_mix := 0.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = sh("glow")
	m.set_shader_parameter("source", source)
	m.set_shader_parameter("color", color)
	m.set_shader_parameter("energy", energy)
	m.set_shader_parameter("albedo_mix", albedo_mix)
	return m


func get_mat(role: String) -> Material:
	if cache.has(role):
		return cache[role]
	var m: Material = _make(role)
	m.resource_name = role
	cache[role] = m
	return m


func _make(role: String) -> Material:
	match role:
		"concrete": return _surf(0, Color(0.4, 0.4, 0.4), 0.88, 0.0, 1)
		"concrete_dark": return _surf(0, Color(0.4, 0.4, 0.4), 0.9, 0.0, 1, {"dark": 0.55})
		"brick": return _surf(1, Color(0.36, 0.17, 0.12), 0.9, 0.0, 2)
		"tile": return _surf(2, Color(0.5, 0.55, 0.55), 0.3, 0.0, 3)
		"metal_panel": return _surf(3, Color(0.3, 0.3, 0.3), 0.5, 0.3, 4)
		"metal_dark": return _surf(4, Color(0.045, 0.045, 0.05), 0.42, 0.55)
		"metal_bare": return _surf(4, Color(0.34, 0.35, 0.36), 0.38, 0.8)
		"metal_rust": return _surf(5, Color(0.3, 0.15, 0.07), 0.9, 0.2)
		"sign_body": return _surf(4, Color(0.025, 0.025, 0.03), 0.35, 0.5, 0, {"grime_amount": 0.4})
		"paint_yellow": return _surf(4, Color(0.55, 0.38, 0.04), 0.5, 0.05)
		"wood": return _surf(6, Color(0.26, 0.16, 0.09), 0.85)
		"plastic_dark": return _surf(7, Color(0.03, 0.03, 0.035), 0.5)
		"rubber": return _surf(7, Color(0.018, 0.018, 0.02), 0.85, 0.0, 0, {"wet_amount": 0.5})
		"cable": return _surf(7, Color(0.012, 0.012, 0.014), 0.45, 0.0, 0, {"grime_amount": 0.0})
		"grate": return _surf(9, Color(0.06, 0.06, 0.065), 0.5, 0.6)
		"chrome": return _surf(11, Color(0.8, 0.8, 0.82), 0.12, 1.0, 0, {"grime_amount": 0.0, "wet_amount": 0.0})
		"car_paint": return _surf(10, Color(0.2, 0.2, 0.22), 0.25, 0.45, 0, {"grime_amount": 0.15, "wet_amount": 0.0})
		"fabric": return _surf(8, Color(0.45, 0.08, 0.06), 0.95, 0.0, 0, {"grime_amount": 0.4}, true)
		"glass_car": return _surf(7, Color(0.004, 0.005, 0.007), 0.04, 0.0, 0, {"grime_amount": 0.0, "wet_amount": 0.0, "bump": 0.0})
		"asphalt":
			var a := ShaderMaterial.new()
			a.shader = sh("road")
			return a
		"paving":
			var s := ShaderMaterial.new()
			s.shader = sh("sidewalk")
			s.set_shader_parameter("slab_color", P.paving_color)
			return s
		"glass_window":
			var w := ShaderMaterial.new()
			w.shader = sh("window")
			return w
		"glass_shop":
			var gl := ShaderMaterial.new()
			gl.shader = sh("glass")
			return gl
		"tower_glass":
			var t := ShaderMaterial.new()
			t.shader = sh("tower")
			t.set_shader_parameter("coord_mode", 0)
			t.set_shader_parameter("style", 0)
			return t
		"interior": return _glow(8, Color(0.85, 0.8, 0.72), 0.14, 0.3)
		"goods": return _glow(9, Color.WHITE, 0.55, 0.45)
		"interior_dark": return _glow(8, Color(0.25, 0.22, 0.2), 0.06, 0.25)
		"shop_light": return _glow(4, Color.WHITE, 3.0)
		"vend_panel": return _glow(0, Color(0.8, 0.9, 1.0), 3.2)
		"lamp_lens": return _glow(1, Color.WHITE, 1.0)
		"light_head": return _glow(6, Color.WHITE, 9.0 * float(P.car_light_energy) / 3.0)
		"light_tail": return _glow(5, Color.WHITE, 7.0 * float(P.car_light_energy) / 3.0)
		"light_amber": return _glow(0, Color(1.0, 0.45, 0.05), 3.0)
		"signal_red": return _glow(0, Color(1.0, 0.05, 0.02), 8.0 if P.signal_state == "red" else 0.08)
		"signal_amber": return _glow(0, Color(1.0, 0.5, 0.02), 8.0 if P.signal_state == "amber" else 0.08)
		"signal_green": return _glow(0, Color(0.1, 1.0, 0.55), 8.0 if P.signal_state == "green" else 0.08)
		"led_strip": return _glow(2, Color.WHITE, 1.0)
		"blinker": return _glow(3, Color.WHITE, 30.0)
		"holo": return _glow(7, Color.WHITE, 3.0)
		"lantern": return _glow(0, P.lantern_color, 3.0, 0.3)
		"neon":
			var n := ShaderMaterial.new()
			n.shader = sh("neon")
			return n
		"sign_face":
			var s2 := ShaderMaterial.new()
			s2.shader = sh("sign")
			s2.set_shader_parameter("atlas_h", load("res://assets/tex/signs_h.png"))
			s2.set_shader_parameter("atlas_v", load("res://assets/tex/signs_v.png"))
			s2.set_shader_parameter("atlas_g", load("res://assets/tex/glyph_cells.png"))
			s2.set_shader_parameter("atlas_b", load("res://assets/tex/billboards.png"))
			return s2
		"screen":
			var sc := ShaderMaterial.new()
			sc.shader = sh("screen")
			sc.set_shader_parameter("atlas_b", load("res://assets/tex/billboards.png"))
			return sc
		"holo_panel":
			var hp := ShaderMaterial.new()
			hp.shader = sh("holo")
			hp.set_shader_parameter("atlas_b", load("res://assets/tex/billboards.png"))
			return hp
		"building_mass":
			var bm := ShaderMaterial.new()
			bm.shader = sh("tower")
			bm.set_shader_parameter("coord_mode", 1)
			bm.set_shader_parameter("style", 1)
			bm.set_shader_parameter("use_concrete_tint", 1.0)
			bm.set_shader_parameter("lit_mul", 0.7)
			return bm
		"backrow_mass":
			var bk := ShaderMaterial.new()
			bk.shader = sh("tower")
			bk.set_shader_parameter("coord_mode", 1)
			bk.set_shader_parameter("style", 0)
			bk.set_shader_parameter("wall_color", Color(0.06, 0.065, 0.07))
			return bk
	push_warning("no material for role '%s'" % role)
	return _surf(4, Color(0.5, 0.0, 0.5), 0.5)
