# Sign dressing: blade signs, wall box signs, shop fascias, neon tube words, LED screens and
# hologram panels. Colours, density, brightness and words all come from the look preset.
extends RefCounted

var B   # street builder (for kit, preset, lights, rng helpers)
var P: Dictionary
var rng := RandomNumberGenerator.new()
const GLYPH_CELLS := "ABCDEHIKLMNOPRSTUVWXZ0123456789"
const WORDS4 := ["NOVA", "KITE", "HALO", "VOLT", "MIRA", "DATA", "CLUB", "PAWN", "BAR*", "24H*", "LUX*", "ZEN*", "OPEN", "TAXI", "LIVE", "NOOD"]


func _init(builder) -> void:
	B = builder
	P = builder.P
	rng.seed = 4242


func pick_color(r: RandomNumberGenerator) -> Color:
	var a: Array = P.neon_colors
	return a[r.randi() % a.size()]


func pick_panel(r: RandomNumberGenerator) -> Color:
	var a: Array = P.sign_panel_colors
	return a[r.randi() % a.size()]


func is_off(r: RandomNumberGenerator) -> bool:
	return r.randf() < float(P.sign_off_ratio)


# Colour a sign mesh instance (sign face + neon outline) and give it a light.
func style_sign(mi: GeometryInstance3D, r: RandomNumberGenerator, atlas: int, cell: int, light_pos: Vector3, light_range := -1.0) -> Color:
	var main := pick_color(r)
	var acc := pick_color(r)
	if acc == main:
		acc = Color(1, 1, 1).lerp(main, 0.3)
	var mode := 0 if r.randf() < 0.7 else 1
	var off := is_off(r)
	var bright := (0.0 if off else 1.0) * r.randf_range(0.8, 1.2)
	var panel := pick_panel(r) if mode == 0 else Color(0.9, 0.9, 0.85).lerp(main, 0.35)
	mi.set_instance_shader_parameter("sign_a", panel)
	mi.set_instance_shader_parameter("sign_b", main)
	mi.set_instance_shader_parameter("sign_c", acc)
	mi.set_instance_shader_parameter("sign_cell", Vector4(atlas, cell, mode, bright))
	mi.set_instance_shader_parameter("neon_color", acc if atlas != 2 else main)
	mi.set_instance_shader_parameter("neon_on", 0.0 if off else 1.0)
	if not off:
		var c := main if mode == 0 else main.lerp(Color.WHITE, 0.4)
		B.add_omni(light_pos, c, float(P.sign_light_energy) * 1.1, light_range if light_range > 0 else float(P.sign_light_range), float(P.sign_light_fog))
	return main


func word_cells(word: String) -> Vector4:
	var v := [-1.0, -1.0, -1.0, -1.0]
	# cube 0 is the bottom cube, so reverse the word
	for i in 4:
		var ch := word[3 - i] if 3 - i < word.length() else "*"
		var idx := GLYPH_CELLS.find(ch)
		if idx < 0:
			idx = 31 + (i % 7)  # a symbol cell
		v[i] = float(idx)
	return Vector4(v[0], v[1], v[2], v[3])


# Blade sign sticking out of a facade. xf: facade-local mount point (origin on the wall plane, +Z out).
func blade(parent: Node3D, xf: Transform3D, r: RandomNumberGenerator, force_kind := -1.0) -> MeshInstance3D:
	var kind := r.randf()
	if force_kind >= 0.0:
		kind = force_kind
	var reach := float(P.sign_reach)
	var xf2 := xf.scaled_local(Vector3(1.0, 1.0, reach))
	var name := ""
	var atlas := 1
	var cell := r.randi() % 16
	var center := Vector3.ZERO
	if kind < 0.42:
		name = "sign_blade_a"
		center = Vector3(0, 2.0, 0.65 * reach)
	elif kind < 0.66:
		name = "sign_blade_b"
		atlas = 2
		center = Vector3(0, 1.7, 0.7 * reach)
	elif kind < 0.82:
		name = "sign_box_b"
		atlas = 0
		cell = r.randi() % 32
		center = Vector3(0, 0.4, 1.2 * reach)
	else:
		name = "sign_round_a"
		atlas = 2
		cell = 31 + r.randi() % 11
		center = Vector3(0, 0.8, 0.9 * reach)
	var mi: MeshInstance3D = B.kit.spawn(name, parent, xf2)
	var wp: Vector3 = parent.global_transform * (xf * center)
	style_sign(mi, r, atlas, cell, wp)
	if name == "sign_blade_b":
		mi.set_instance_shader_parameter("sign_glyphs", word_cells(WORDS4[r.randi() % WORDS4.size()]))
	return mi


func wall_box(parent: Node3D, xf: Transform3D, r: RandomNumberGenerator) -> void:
	var mi: MeshInstance3D = B.kit.spawn("sign_box_a", parent, xf)
	var wp: Vector3 = parent.global_transform * (xf * Vector3(0, 0.45, 1.2))
	style_sign(mi, r, 0, r.randi() % 32, wp, float(P.sign_light_range) * 0.9)


func fascia(mi: GeometryInstance3D, r: RandomNumberGenerator, light_pos: Vector3) -> void:
	style_sign(mi, r, 0, r.randi() % 32, light_pos, float(P.sign_light_range) * 0.8)


# Neon tube word built from glyph meshes. xf: bottom-left of the word, +X along the text, +Z out.
func neon_word(parent: Node3D, xf: Transform3D, text: String, height: float, color: Color, vertical := false, backing := true, light := true) -> float:
	var x := 0.0
	var spacing := 0.22
	var total := 0.0
	for ch in text:
		total += (B.kit.glyph_w(ch) + spacing) * height
	total -= spacing * height
	if backing:
		var bk := MeshInstance3D.new()
		var bm := BoxMesh.new()
		if vertical:
			bm.size = Vector3(height * 0.95, (height * 1.25) * text.length() + height * 0.3, 0.12)
			bk.transform = xf * Transform3D(Basis(), Vector3(height * 0.3, -bm.size.y * 0.5 + height * 1.15, -0.08))
		else:
			bm.size = Vector3(total + height * 0.5, height * 1.45, 0.12)
			bk.transform = xf * Transform3D(Basis(), Vector3(total * 0.5, height * 0.5, -0.08))
		bk.mesh = bm
		bk.material_override = B.mats.get_mat("sign_body")
		parent.add_child(bk)
	var i := 0
	for ch in text:
		var m: Mesh = B.kit.glyph(ch)
		if m == null:
			x += height * 0.5
			continue
		var gi := MeshInstance3D.new()
		gi.mesh = m
		var pos: Vector3
		if vertical:
			pos = Vector3(-B.kit.glyph_w(ch) * height * 0.5 + height * 0.3, -i * height * 1.25, 0.0)
		else:
			pos = Vector3(x, 0.0, 0.0)
		gi.transform = xf * Transform3D(Basis().scaled(Vector3(height, height, height)), pos)
		gi.set_instance_shader_parameter("neon_color", color)
		gi.set_instance_shader_parameter("neon_on", 1.0)
		parent.add_child(gi)
		x += (B.kit.glyph_w(ch) + spacing) * height
		i += 1
	if light:
		var mid: Vector3
		if vertical:
			mid = xf * Vector3(height * 0.3, -text.length() * height * 0.6 + height, 0.8)
		else:
			mid = xf * Vector3(total * 0.5, height * 0.5, 0.9)
		B.add_omni(parent.global_transform * mid, color, float(P.sign_light_energy) * 1.6, max(height * 4.0, 6.0), float(P.sign_light_fog))
	return total


# LED screen on a wall (12 x 6.75 m piece, scaled).
func screen(parent: Node3D, xf: Transform3D, r: RandomNumberGenerator, scale := 1.0) -> void:
	var s := scale * float(P.billboard_scale)
	var mi: MeshInstance3D = B.kit.spawn("screen_wall", parent, xf.scaled_local(Vector3(s, s, 1.0)))
	style_screen(mi, r)
	var wp: Vector3 = parent.global_transform * (xf * Vector3(0, 3.4 * s, 4.0))
	var cols: Array = P.screen_colors[r.randi() % P.screen_colors.size()]
	B.add_omni(wp, cols[1], 2.0 * float(P.screen_brightness), 14.0 * s, 0.6)


func style_screen(mi: GeometryInstance3D, r: RandomNumberGenerator) -> void:
	var cols: Array = P.screen_colors[r.randi() % P.screen_colors.size()]
	mi.set_instance_shader_parameter("scr_cell", Vector4(r.randi() % 8, 0, r.randf_range(0.85, 1.15), 0))
	mi.set_instance_shader_parameter("sign_a", cols[0])
	mi.set_instance_shader_parameter("sign_b", cols[1])
	mi.set_instance_shader_parameter("sign_c", cols[2])
	mi.set_instance_shader_parameter("sign_cell", Vector4(3, r.randi() % 8, 0, 1.0))


# Hologram panel above an emitter bar. xf: emitter centre on the wall, +Z out from the wall.
func holo(parent: Node3D, xf: Transform3D, r: RandomNumberGenerator, w := 6.0, h := 3.4) -> void:
	B.kit.spawn("holo_emitter", parent, xf.scaled_local(Vector3(w / 6.0, 1.0, 1.0)))
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(w, h)
	q.mesh = qm
	q.material_override = B.mats.get_mat("holo_panel")
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	q.transform = xf * Transform3D(Basis(), Vector3(0, h * 0.5 + 0.05, -0.2))
	var hc: Array = P.holo_colors
	q.set_instance_shader_parameter("holo_a", hc[0])
	q.set_instance_shader_parameter("holo_b", hc[1 % hc.size()])
	q.set_instance_shader_parameter("holo_cell", Vector4(r.randi() % 8, 0, 1.0, float(P.holo_opacity)))
	parent.add_child(q)
	B.add_omni(parent.global_transform * (xf * Vector3(0, h * 0.5, 1.5)), hc[0], 1.2 * float(P.sign_brightness), w * 1.2, 1.0)


# Free-standing hologram quad (used for the big floating ads between towers).
func holo_free(parent: Node3D, xf: Transform3D, r: RandomNumberGenerator, w: float, h: float, mirror := false) -> MeshInstance3D:
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(w, h)
	q.mesh = qm
	q.material_override = B.mats.get_mat("holo_panel")
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	q.transform = xf
	var hc: Array = P.holo_colors
	q.set_instance_shader_parameter("holo_a", hc[0])
	q.set_instance_shader_parameter("holo_b", hc[1 % hc.size()])
	q.set_instance_shader_parameter("holo_cell", Vector4(r.randi() % 8, 1.0 if mirror else 0.0, 3.0, float(P.holo_opacity)))
	parent.add_child(q)
	return q
