# Kit sheet mode (mode=kit): lines the kit pieces up in groups on a wet studio floor, frames each
# group with the camera and saves one PNG per group plus a names file. tools/kit_sheet.py then
# assembles docs/looks/kit_sheet.png with captions. Uses the look's materials (default N).
extends RefCounted

const GROUPS := [
	["Facade storeys A", ["fac_concrete_a", "fac_concrete_b", "fac_brick_a", "fac_brick_b", "fac_blank_a"]],
	["Facade storeys B", ["fac_panel_a", "fac_balcony_a", "fac_tile_a", "fac_glass_a", "fire_escape"]],
	["Ground floors", ["shop_window_a", "shop_food_a", "shop_shutter_half", "shop_shutter_a", "entry_a", "wall_service_a"]],
	["Wall attachments + parapets", ["cornice_a", "cornice_b", "awning_a", "awning_b", "ac_unit_a", "ac_unit_b", "pipe_v", "pipe_cluster", "conduit_h"]],
	["Street furniture", ["lamp_a", "lamp_b", "traffic_light", "vending_a", "vending_b", "kiosk_a", "utility_box", "bin_a", "hydrant", "bollard", "parking_meter", "street_sign", "barrier", "clutter_boxes", "manhole", "vent_street", "curb"]],
	["Signs + neon tube letters", ["sign_blade_a", "sign_blade_b", "sign_box_a", "sign_box_b", "sign_round_a", "neon_word"]],
	["Cars", ["car_sedan", "car_van", "car_wedge"]],
	["Rooftops", ["water_tank", "roof_hvac", "antenna_mast", "dish_a", "roof_stairhouse", "stack_industrial", "duct_run", "cooling_unit", "lantern"]],
	["Screens, holograms, billboards", ["screen_wall", "billboard_roof", "holo_emitter", "sign_frame_roof"]],
	["Rail, bridge, megatowers (towers at 1:8)", ["rail_pillar", "rail_girder", "train_car", "skybridge", "tower_a", "tower_b", "tower_c", "tower_d"]],
]
const SCENES := ["car_sedan", "car_van", "car_wedge"]
const BACKED := ["cornice_a", "cornice_b", "ac_unit_a", "ac_unit_b", "pipe_v", "pipe_cluster", "conduit_h", "fire_escape",
	"awning_a", "awning_b", "sign_blade_a", "sign_blade_b", "sign_box_a", "sign_box_b", "sign_round_a", "holo_emitter", "screen_wall"]

var P: Dictionary
var kit
var mats
var world: Node3D
var cam: Camera3D
var sv: SubViewport
var out_dir := ""
var groups: Array = []   # [title, Node3D, AABB, names]
var shot := 0
var wait := 0
var settle := 45
var Signs = preload("res://scripts/signs.gd")
var signs
# signs.gd expects a builder with these members
var lights_root: Node3D
var light_count := 0
var _args: Dictionary


func _init(preset: Dictionary, kit_, mats_, world_: Node3D, cam_: Camera3D, sv_: SubViewport, args: Dictionary) -> void:
	P = preset
	# a clean studio: no rain, no steam, light haze only
	P["rain_amount"] = 0.0
	P["steam_amount"] = 0.0
	P["mist_density"] = 0.0
	P["fog_density"] = 0.004
	P["haze_density"] = 0.0
	P["reflection_probes"] = false
	P["grade_vignette"] = 0.15
	kit = kit_
	mats = mats_
	world = world_
	cam = cam_
	sv = sv_
	out_dir = args.get("out", "")
	_args = args
	settle = int(args.get("frames", "45"))
	sv.size = Vector2i(int(args.get("w", "1600")), int(args.get("h", "900")))
	sv.scaling_3d_scale = float(args.get("ss", "2.0"))
	cam.fov = 32.0
	signs = Signs.new(self)


func add_omni(pos: Vector3, color: Color, energy: float, rng_: float, fog := 1.0, _shadow := false) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = color
	l.light_energy = energy * 0.6
	l.omni_range = rng_
	l.light_volumetric_fog_energy = fog
	lights_root.add_child(l)
	return l


func build() -> void:
	lights_root = Node3D.new()
	world.add_child(lights_root)
	var r := RandomNumberGenerator.new()
	r.seed = 12
	var floor_mat := ShaderMaterial.new()
	floor_mat.shader = load("res://shaders/surface.gdshader")
	floor_mat.set_shader_parameter("pattern", 0)
	floor_mat.set_shader_parameter("base_color", Color(0.05, 0.05, 0.055))
	floor_mat.set_shader_parameter("roughness", 0.6)
	floor_mat.set_shader_parameter("wet_amount", 0.35)
	floor_mat.set_shader_parameter("grime_amount", 0.3)
	var gi := 0
	var only: String = _args.get("groups", "")
	for gidx in GROUPS.size():
		var g: Array = GROUPS[gidx]
		if only != "" and not (str(gidx) in only.split(",")):
			continue
		var root := Node3D.new()
		root.position = Vector3(gi * 600.0, 0, 0)
		world.add_child(root)
		var big: bool = String(g[0]).begins_with("Rail")
		var gap := 5.0 if big else 1.2
		var items: Array = []   # [holder, bounds]
		var k := 0
		for name in g[1]:
			var holder := Node3D.new()
			root.add_child(holder)
			if name in SCENES:
				var n: Node3D = kit.spawn_scene(name, holder, Transform3D(Basis(Vector3.UP, -0.55), Vector3.ZERO))
				var cols: Array = P.car_paint_colors
				var cc: Color = cols[(k * 2 + 1) % cols.size()]
				_set_tree(n, "inst_color", Color(cc.r + 0.08, cc.g + 0.08, cc.b + 0.1, 1.0))
				_set_tree(n, "sign_b", signs.pick_color(r))
				_set_tree(n, "sign_a", Color(0.03, 0.03, 0.04))
				_set_tree(n, "sign_cell", Vector4(0, r.randi() % 32, 0, 1.0))
			elif name == "neon_word":
				signs.neon_word(holder, Transform3D(Basis(), Vector3(0, 0.3, 0.2)), "NEON 24H", 0.9, signs.pick_color(r), false, true, false)
				signs.neon_word(holder, Transform3D(Basis(), Vector3(0, 1.7, 0.2)), "ABCDEHKLMNOPRSTUVXZ", 0.5, signs.pick_color(r), false, true, false)
			else:
				var mi: MeshInstance3D = kit.spawn(name, holder, Transform3D())
				if String(name).begins_with("tower"):
					mi.scale = Vector3.ONE * 0.125
				_style(mi, name, r)
			if name == "holo_emitter":
				signs.holo(holder, Transform3D(Basis(), Vector3(0, 0.3, 0.2)), r, 6.0, 3.4)
			var bb := _bounds(holder)
			if name in BACKED:
				# a short wall behind wall-mounted pieces so they read in context
				var wall := MeshInstance3D.new()
				var bm := BoxMesh.new()
				bm.size = Vector3(bb.size.x + 0.6, bb.size.y + 0.6, 0.3)
				wall.mesh = bm
				wall.material_override = mats.get_mat("concrete")
				wall.position = Vector3(bb.get_center().x, bb.get_center().y, -0.16)
				holder.add_child(wall)
				bb = _bounds(holder)
			items.append([holder, bb])
			k += 1
		# rows: tallest pieces at the back, rows roughly 16:9 overall
		items.sort_custom(func(a, b): return a[1].size.y > b[1].size.y)
		var total_w := 0.0
		var hs: Array = []
		for it in items:
			total_w += it[1].size.x + gap
			hs.append(it[1].size.y)
		hs.sort()
		var med_h: float = hs[hs.size() / 2]
		var rows := clampi(int(round(sqrt(total_w / maxf(med_h * 2.4, 1.0)))), 1, 3)
		var row_w := total_w / rows
		var row := 0
		var x := 0.0
		var zrow := 0.0
		var row_depth := 0.0
		var row_items: Array = [[]]
		for it in items:
			if x > row_w * 0.92 and row < rows - 1:
				row += 1
				x = 0.0
				row_items.append([])
			row_items[row].append(it)
			x += it[1].size.x + gap
		# place rows back (row 0) to front, each row centred on x = 0
		var depth_acc := 0.0
		for ri in row_items.size():
			var rw := 0.0
			var rd := 0.0
			for it in row_items[ri]:
				rw += it[1].size.x + gap
				rd = maxf(rd, it[1].size.z)
			var xx := -rw * 0.5
			for it in row_items[ri]:
				var holder: Node3D = it[0]
				var bb: AABB = it[1]
				holder.position = Vector3(xx - bb.position.x, 0.0, depth_acc - bb.end.z)
				xx += bb.size.x + gap
			depth_acc += rd + (6.0 if big else 2.0)
		var aabb := _bounds(root)
		var fl := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(aabb.size.x + 80.0, 80.0)
		fl.mesh = pm
		fl.material_override = floor_mat
		fl.position = Vector3(aabb.get_center().x, 0.0, 0.0)
		root.add_child(fl)
		groups.append([g[0], root, aabb, g[1]])
		gi += 1
	_show(0)


func after_atmos(atm) -> void:
	var env: Environment = atm.env
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.012, 0.012, 0.018)
	env.reflected_light_source = Environment.REFLECTION_SOURCE_BG
	env.ambient_light_color = Color(0.35, 0.36, 0.45)
	env.ambient_light_energy = 0.5
	env.volumetric_fog_enabled = false
	env.fog_enabled = false
	env.ssr_enabled = true
	# studio: cool key with soft shadows, magenta rim from behind, cyan fill
	_dir(Vector3(-38.0, -35.0, 0.0), Color(0.9, 0.93, 1.0), 1.6, true)
	_dir(Vector3(-40.0, 150.0, 0.0), Color(1.0, 0.3, 0.75), 0.4, false)
	_dir(Vector3(-15.0, 50.0, 0.0), Color(0.25, 0.8, 1.0), 0.45, false)


func _dir(rot: Vector3, col: Color, e: float, shadow: bool) -> void:
	var l := DirectionalLight3D.new()
	l.rotation_degrees = rot
	l.light_color = col
	l.light_energy = e
	l.shadow_enabled = shadow
	l.light_angular_distance = 1.5
	l.directional_shadow_max_distance = 400.0
	world.add_child(l)


func _light(parent: Node3D, pos: Vector3, target: Vector3, col: Color, e: float, rng_: float, shadow: bool) -> void:
	var l := SpotLight3D.new()
	l.light_color = col
	l.light_energy = e
	l.spot_range = rng_
	l.spot_angle = 55.0
	l.spot_attenuation = 0.5
	l.shadow_enabled = shadow
	l.light_size = 0.6
	l.light_volumetric_fog_energy = 0.5
	parent.add_child(l)
	l.look_at_from_position(parent.global_position + pos, parent.global_position + target, Vector3.UP)


func _style(mi: MeshInstance3D, name: String, r: RandomNumberGenerator) -> void:
	mi.set_instance_shader_parameter("lit_bias", 0.25)
	mi.set_instance_shader_parameter("win_seed", float(r.randi() % 100))
	var main: Color = signs.pick_color(r)
	var atlas := 0
	var cell := r.randi() % 32
	if name == "sign_blade_a":
		atlas = 1
		cell = r.randi() % 16
	elif name == "sign_blade_b" or name == "sign_round_a":
		atlas = 2
		cell = 33
	mi.set_instance_shader_parameter("sign_a", Color(0.03, 0.02, 0.05))
	mi.set_instance_shader_parameter("sign_b", main)
	mi.set_instance_shader_parameter("sign_c", signs.pick_color(r))
	mi.set_instance_shader_parameter("sign_cell", Vector4(atlas, cell, 0, 1.0))
	mi.set_instance_shader_parameter("neon_color", main)
	mi.set_instance_shader_parameter("sign_glyphs", signs.word_cells("NOVA"))
	if name in ["screen_wall", "billboard_roof", "tower_c", "kiosk_a", "parking_meter", "entry_a", "shop_window_a"] or name.begins_with("vending"):
		var cols: Array = P.screen_colors[r.randi() % P.screen_colors.size()]
		mi.set_instance_shader_parameter("scr_cell", Vector4(r.randi() % 8, 0, 1.0, 0))
		if name in ["screen_wall", "billboard_roof", "tower_c"]:
			mi.set_instance_shader_parameter("sign_a", cols[0])
			mi.set_instance_shader_parameter("sign_b", cols[1])
			mi.set_instance_shader_parameter("sign_c", cols[2])
	if String(name).begins_with("vending"):
		var c: Color = signs.pick_color(r)
		mi.set_instance_shader_parameter("inst_color", Color(c.r * 0.3 + 0.02, c.g * 0.3 + 0.02, c.b * 0.3 + 0.02, 1.0))
		mi.set_instance_shader_parameter("sign_cell", Vector4(3, r.randi() % 8, 0, 1.0))
	if String(name).begins_with("awning"):
		var fc: Color = main.lerp(Color(0.3, 0.05, 0.04), 0.5)
		mi.set_instance_shader_parameter("inst_color", Color(fc.r, fc.g, fc.b, 1.0))
	if String(name).begins_with("tower"):
		mi.set_instance_shader_parameter("tower_seed", float(r.randi() % 50))


func _set_tree(n: Node, key: String, v) -> void:
	if n is GeometryInstance3D:
		n.set_instance_shader_parameter(key, v)
	for c in n.get_children():
		_set_tree(c, key, v)


# Bounds of all meshes under n, in n's parent space (n is only ever translated).
func _bounds(n: Node3D) -> AABB:
	var acc := AABB()
	var first := true
	for mi in _meshes(n):
		var a: AABB = _xf_to(n, mi) * mi.get_aabb()
		if first:
			acc = a
			first = false
		else:
			acc = acc.merge(a)
	if first:
		return AABB(Vector3.ZERO, Vector3.ONE)
	return acc


func _xf_to(top: Node3D, n: Node3D) -> Transform3D:
	var t := Transform3D()
	var cur: Node = n
	while cur != top and cur is Node3D:
		t = (cur as Node3D).transform * t
		cur = cur.get_parent()
	return t


func _meshes(n: Node) -> Array:
	var out: Array = []
	if n is MeshInstance3D and not (n.mesh is PlaneMesh) and not (n.mesh is QuadMesh):
		out.append(n)
	for c in n.get_children():
		out.append_array(_meshes(c))
	return out


func _show(i: int) -> void:
	for k in groups.size():
		groups[k][1].visible = k == i
	var g: Array = groups[i]
	var root: Node3D = g[1]
	var bb: AABB = _bounds(root)
	var c: Vector3 = root.global_position + bb.get_center()
	var aspect := float(sv.size.x) / float(sv.size.y)
	var vf := deg_to_rad(cam.fov)
	var hf := 2.0 * atan(tan(vf * 0.5) * aspect)
	var dir := Vector3(-0.22, 0.2 + 0.12 * minf(bb.size.z / maxf(bb.size.y, 1.0), 2.0), 1.0).normalized()
	var w: float = bb.size.x * 0.5 + bb.size.z * 0.12
	var h: float = bb.size.y * 0.5 + bb.size.z * 0.08
	var dist: float = maxf(w / tan(hf * 0.5), h / tan(vf * 0.5)) * 1.12 + bb.size.z * 0.5
	cam.global_position = c + dir * dist
	cam.look_at(c + Vector3(0, bb.size.y * 0.05, 0), Vector3.UP)
	cam.far = dist * 4.0 + 300.0
	wait = 0


func process(_frame: int) -> void:
	wait += 1
	if wait == settle:
		_capture()


func _capture() -> void:
	await RenderingServer.frame_post_draw
	var img := sv.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(out_dir)
	var path := "%s/shot_%02d.png" % [out_dir, shot]
	img.save_png(path)
	var f := FileAccess.open("%s/shot_%02d.txt" % [out_dir, shot], FileAccess.WRITE)
	f.store_string(String(groups[shot][0]) + "\n" + ", ".join(PackedStringArray(groups[shot][3])))
	f.close()
	print("SAVED ", path)
	shot += 1
	if shot >= groups.size():
		world.get_tree().quit()
	else:
		_show(shot)
