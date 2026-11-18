# Procedural street assembler. Lays out ONE fixed street (same massing for every look) from the kit:
# road, sidewalks, kerbs, building lots with modular facades, shopfronts, signs, roof clutter,
# street furniture, cars, the elevated rail, overhead cables, back rows and megatowers.
# Look presets only change materials, lights, density of dressing and toggles, never the massing.
#
# World frame: the street runs along -Z, the camera stands on the right (+X) sidewalk at z = 0.
# Road |x| < 7, sidewalks 7..11 (top at y = 0.15), building line |x| = 11.
# Mid-block crosswalk z -34..-30, junction with a cross street z -100..-84 under the elevated rail.
extends RefCounted

const Signs = preload("res://scripts/signs.gd")

const ROAD := 7.0
const FRONT := 11.0
const WALK_Y := 0.15
const BAY := 4.0
const STOREY := 3.5
const GROUND := 5.0
const JUNCTION := Vector2(-100.0, -84.0)
const CROSSWALK := Vector2(-34.0, -30.0)
const RAIL_Z := -92.0
const RAIL_Y := 13.0
const STREET_END := -262.0

var P: Dictionary
var kit
var mats
var root: Node3D
var cam_pos: Vector3
var signs
var lights_root: Node3D
var light_count := 0
var shadow_lamps := 0
var steam_spots: Array = []   # Vector3 positions for steam plumes (vents, manholes, roofs)
var lot_infos: Array = []


func _init(preset: Dictionary, kit_, mats_, root_: Node3D, cam: Vector3) -> void:
	P = preset
	kit = kit_
	mats = mats_
	root = root_
	cam_pos = cam
	signs = Signs.new(self)
	lights_root = Node3D.new()
	lights_root.name = "Lights"
	root.add_child(lights_root)


# ---------------------------------------------------------------------------- helpers
static func facing(normal: Vector3) -> Basis:
	var z := normal.normalized()
	var x := Vector3.UP.cross(z).normalized()
	return Basis(x, Vector3.UP, z)


static func rng_for(a: float, b: float, salt: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = hash(Vector3(a, b, float(salt)))
	return r


func node(name: String, parent: Node3D = null) -> Node3D:
	var n := Node3D.new()
	n.name = name
	(parent if parent else root).add_child(n)
	return n


func add_omni(pos: Vector3, color: Color, energy: float, rng_: float, fog := 1.0, shadow := false) -> OmniLight3D:
	if pos.distance_to(cam_pos) > 140.0 or energy <= 0.0:
		return null
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = color
	l.light_energy = energy
	l.omni_range = rng_
	l.omni_attenuation = 1.6
	l.light_volumetric_fog_energy = fog * near_fog(pos)
	l.shadow_enabled = shadow
	l.light_specular = 0.8
	l.distance_fade_enabled = true
	l.distance_fade_begin = 110.0
	l.distance_fade_length = 30.0
	lights_root.add_child(l)
	light_count += 1
	return l


func add_spot(pos: Vector3, dir: Vector3, color: Color, energy: float, rng_: float, angle: float, fog := 1.0, shadow := false) -> SpotLight3D:
	if pos.distance_to(cam_pos) > 160.0 or energy <= 0.0:
		return null
	var l := SpotLight3D.new()
	l.light_color = color
	l.light_energy = energy
	l.spot_range = rng_
	l.spot_angle = angle
	l.spot_attenuation = 1.0
	l.spot_angle_attenuation = 1.4
	l.light_volumetric_fog_energy = fog * near_fog(pos)
	l.shadow_enabled = shadow
	l.shadow_blur = 1.5
	l.light_size = 0.25
	l.shadow_bias = 0.04
	l.distance_fade_enabled = true
	l.distance_fade_begin = 130.0
	l.distance_fade_length = 30.0
	lights_root.add_child(l)
	l.global_transform = Transform3D(Basis.looking_at(dir.normalized(), Vector3.FORWARD if abs(dir.normalized().y) > 0.9 else Vector3.UP), pos)
	light_count += 1
	return l


# Lights right next to the lens would fill the frame with lit fog: fade their fog share out
# within ~10 m of the camera (they still light surfaces normally).
func near_fog(pos: Vector3) -> float:
	return clampf((pos.distance_to(cam_pos) - 3.0) / 9.0, 0.12, 1.0)


func box(parent: Node3D, size: Vector3, xf: Transform3D, role: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.transform = xf
	mi.material_override = mats.get_mat(role)
	parent.add_child(mi)
	return mi


func plane(parent: Node3D, size: Vector2, center: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = size
	mi.mesh = pm
	mi.position = center
	mi.material_override = mat
	parent.add_child(mi)
	return mi


# Tube mesh along a polyline (cables).
static func tube_mesh(pts: PackedVector3Array, r: float, segs := 5) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := pts.size()
	var rings: Array = []
	for i in n:
		var t: Vector3
		if i == 0:
			t = pts[1] - pts[0]
		elif i == n - 1:
			t = pts[i] - pts[i - 1]
		else:
			t = pts[i + 1] - pts[i - 1]
		t = t.normalized()
		var side := t.cross(Vector3.UP)
		if side.length() < 0.01:
			side = t.cross(Vector3.RIGHT)
		side = side.normalized()
		var up := side.cross(t).normalized()
		var ring: Array = []
		for k in segs:
			var a := TAU * k / segs
			ring.append([pts[i] + (side * cos(a) + up * sin(a)) * r, side * cos(a) + up * sin(a)])
		rings.append(ring)
	for i in n - 1:
		for k in segs:
			var k2 := (k + 1) % segs
			var a0: Array = rings[i][k]
			var a1: Array = rings[i][k2]
			var b0: Array = rings[i + 1][k]
			var b1: Array = rings[i + 1][k2]
			for v in [a0, b0, b1, a0, b1, a1]:
				st.set_normal(v[1])
				st.add_vertex(v[0])
	return st.commit()


static func catenary(a: Vector3, b: Vector3, sag: float, n := 20) -> PackedVector3Array:
	var pts := PackedVector3Array()
	for i in n + 1:
		var t := float(i) / n
		var p := a.lerp(b, t)
		p.y -= sag * 4.0 * t * (1.0 - t)
		pts.append(p)
	return pts


func cable(parent: Node3D, a: Vector3, b: Vector3, sag: float, r := 0.02) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = tube_mesh(catenary(a, b, sag), r)
	mi.material_override = mats.get_mat("cable")
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


# ---------------------------------------------------------------------------- build
func build() -> void:
	build_ground()
	build_lots()
	build_cross_street()
	build_back_rows()
	build_street_props()
	build_cars()
	build_rail()
	build_overhead()
	build_towers()


# ---------------------------------------------------------------------------- ground
func build_ground() -> void:
	var g := node("Ground")
	var road: ShaderMaterial = mats.get_mat("asphalt")
	road.set_shader_parameter("asphalt", P.asphalt_color)
	road.set_shader_parameter("mark_white", P.marking_white)
	road.set_shader_parameter("mark_yellow", P.marking_yellow)
	road.set_shader_parameter("crosswalk_a", CROSSWALK)
	road.set_shader_parameter("crosswalk_b", Vector2(JUNCTION.x - 4.0, JUNCTION.x))
	road.set_shader_parameter("crosswalk_c", Vector2(JUNCTION.y, JUNCTION.y + 4.0))
	road.set_shader_parameter("junction", JUNCTION)
	plane(g, Vector2(ROAD * 2.0, 420.0), Vector3(0, 0, -160.0), road)
	# cross street (runs along X), markings off inside it
	var cross: ShaderMaterial = road.duplicate()
	cross.set_shader_parameter("along_axis", 1.0)
	cross.set_shader_parameter("half_width", 5.0)
	cross.set_shader_parameter("junction", Vector2(-ROAD, ROAD))
	cross.set_shader_parameter("crosswalk_a", Vector2(-ROAD - 4.5, -ROAD - 0.5))
	cross.set_shader_parameter("crosswalk_b", Vector2(ROAD + 0.5, ROAD + 4.5))
	cross.set_shader_parameter("crosswalk_c", Vector2(900, 901))
	for s in [-1, 1]:
		var mi := plane(g, Vector2(200.0, 10.0), Vector3(s * (ROAD + 100.0), 0.0, RAIL_Z), cross)
		mi.position.z = RAIL_Z
	# sidewalks (boxes so the kerb face exists), along the main street and the cross street
	var walk: ShaderMaterial = mats.get_mat("paving")
	walk.set_shader_parameter("wall_x", FRONT)
	walk.set_shader_parameter("tactile_z0", CROSSWALK.x - 0.5)
	walk.set_shader_parameter("tactile_z1", CROSSWALK.y + 0.5)
	var segs := [[40.0, JUNCTION.y - 0.0], [JUNCTION.x, -360.0]]
	for s in [-1, 1]:
		for seg in segs:
			var z0: float = seg[0]
			var z1: float = seg[1]
			var mi := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(FRONT + 30.0 - ROAD, 0.3, z0 - z1)
			mi.mesh = bm
			mi.material_override = walk
			mi.position = Vector3(s * (ROAD + bm.size.x * 0.5), WALK_Y - 0.15, (z0 + z1) * 0.5)
			g.add_child(mi)
		# corner + cross-street sidewalks
		for zz in [[JUNCTION.y, JUNCTION.y - 3.0], [JUNCTION.x + 3.0, JUNCTION.x]]:
			var mi2 := MeshInstance3D.new()
			var bm2 := BoxMesh.new()
			bm2.size = Vector3(200.0, 0.3, 3.0)
			mi2.mesh = bm2
			mi2.material_override = walk
			mi2.position = Vector3(s * (ROAD + 100.0), WALK_Y - 0.15, (zz[0] + zz[1]) * 0.5)
			g.add_child(mi2)
	# kerbs along the main street edges
	var kz := 40.0
	while kz > -360.0:
		if not (kz < JUNCTION.y + 0.5 and kz > JUNCTION.x - 0.5):
			for s in [-1, 1]:
				var b := facing(Vector3(-s, 0, 0))
				kit.spawn("curb", g, Transform3D(b, Vector3(s * ROAD, 0.0, kz - 1.0)))
		kz -= 2.0
	# cross street kerbs
	for s in [-1, 1]:
		var kx := ROAD + 1.0
		while kx < 120.0:
			kit.spawn("curb", g, Transform3D(facing(Vector3(0, 0, -1)), Vector3(s * kx, 0.0, JUNCTION.y - 3.0)))
			kit.spawn("curb", g, Transform3D(facing(Vector3(0, 0, 1)), Vector3(s * kx, 0.0, JUNCTION.x + 3.0)))
			kx += 2.0
	# far plaza ground beyond the street end
	var far := plane(g, Vector2(1200.0, 900.0), Vector3(0, -0.02, -700.0), walk)
	far.position.y = -0.02


# ---------------------------------------------------------------------------- building lots
const STYLE_MODULES := {
	"concrete": [["fac_concrete_a", 3.0], ["fac_concrete_b", 2.0], ["fac_balcony_a", 1.2], ["fac_blank_a", 0.4]],
	"brick": [["fac_brick_a", 2.0], ["fac_brick_b", 2.0], ["fac_blank_a", 0.3]],
	"tile": [["fac_tile_a", 3.0], ["fac_balcony_a", 1.0], ["fac_concrete_b", 0.6]],
	"panel": [["fac_panel_a", 3.0], ["fac_blank_a", 0.8], ["fac_concrete_b", 0.6]],
	"glass": [["fac_glass_a", 1.0]],
}
const SHOP_MODULES := ["shop_window_a", "shop_food_a", "shop_shutter_half", "shop_shutter_a", "wall_service_a"]


static func weighted(r: RandomNumberGenerator, items: Array) -> String:
	var total := 0.0
	for it in items:
		total += float(it[1])
	var x := r.randf() * total
	for it in items:
		x -= float(it[1])
		if x <= 0.0:
			return it[0]
	return items[0][0]


func pick_style(r: RandomNumberGenerator) -> String:
	var items: Array = []
	var fs: Dictionary = P.facade_styles
	for k in fs.keys():
		if float(fs[k]) > 0.0:
			items.append([k, float(fs[k])])
	if items.is_empty():
		return "concrete"
	return weighted(r, items)


func build_lots() -> void:
	var lots := node("Lots")
	var idx := 0
	for side in [1, -1]:
		for seg in [[16.0, JUNCTION.y], [JUNCTION.x, STREET_END]]:
			var z: float = seg[0]
			var zend: float = seg[1]
			while z - zend > 8.0:
				var r := rng_for(side, z, 1)
				var bays := r.randi_range(3, 6)
				bays = mini(bays, int((z - zend) / BAY))
				if (z - zend) - bays * BAY < 8.0:
					bays = int((z - zend) / BAY)
				var w := bays * BAY
				var setback := 0.0 if r.randf() < 0.65 else r.randf_range(0.4, 1.6)
				var floors := r.randi_range(4, 11)
				if r.randf() < 0.28:
					floors = r.randi_range(13, 24)
				var depth := r.randf_range(18.0, 26.0)
				var normal := Vector3(-side, 0, 0)
				var origin := Vector3(side * (FRONT + setback), WALK_Y, z - w * 0.5)
				var corner_near := absf(z - JUNCTION.x) < 0.1  # lot starting right after the junction shows its side
				build_lot(lots, idx, origin, facing(normal), bays, floors, depth, corner_near, side)
				idx += 1
				z -= w


func build_lot(parent: Node3D, idx: int, origin: Vector3, basis: Basis, bays: int, floors: int, depth: float, corner_near: bool, side: int) -> void:
	var lot := Node3D.new()
	lot.name = "Lot%d" % idx
	lot.transform = Transform3D(basis, origin)
	parent.add_child(lot)
	var rm := rng_for(origin.x, origin.z, 2)  # massing-independent dressing stream
	var rs := rng_for(origin.x, origin.z, 3)  # style stream
	var r_sign := rng_for(origin.x, origin.z, 4)
	var style := pick_style(rs)
	var w := bays * BAY
	var top := GROUND + floors * STOREY
	var dist := origin.distance_to(cam_pos)
	var lit_bias := rs.randf_range(-0.18, 0.15)
	var tint := Color(1, 1, 1).lerp(Color(rs.randf_range(0.8, 1.15), rs.randf_range(0.85, 1.1), rs.randf_range(0.8, 1.15)), 0.6)
	lot_infos.append({"origin": origin, "basis": basis, "w": w, "top": top, "depth": depth, "side": side, "node": lot})

	# --- building mass behind the facade (sides/back/roof)
	var mass := box(lot, Vector3(w - 0.04, top + 1.0, depth), Transform3D(Basis(), Vector3(0, (top + 1.0) * 0.5 - 0.5, -0.45 - depth * 0.5)), "building_mass")
	mass.set_instance_shader_parameter("lit_bias", lit_bias - 0.1)
	mass.set_instance_shader_parameter("inst_tint", Color(tint.r, tint.g, tint.b, 0.0))
	mass.set_instance_shader_parameter("tower_seed", float(idx) * 1.37)

	# --- column plan: each bay column keeps one module type all the way up
	var mods: Array = STYLE_MODULES[style]
	var col_mod: Array = []
	var a := weighted(rs, mods)
	var b := weighted(rs, mods)
	for i in bays:
		col_mod.append(a if (i % 2 == 0 or rs.randf() < 0.3) else b)
	var cornice := "cornice_b" if style in ["panel", "glass", "tile"] else "cornice_a"
	if style == "glass":
		cornice = "cornice_b"

	for i in bays:
		var x := (i - (bays - 1) * 0.5) * BAY
		# ground floor
		var shop := "entry_a" if i == (idx % bays) else _pick_shop(rm)
		var smi: MeshInstance3D = kit.spawn(shop, lot, Transform3D(Basis(), Vector3(x, 0, 0)))
		smi.set_instance_shader_parameter("inst_tint", Color(tint.r, tint.g, tint.b, 0.0))
		if shop != "entry_a" and shop != "wall_service_a":
			var lp: Vector3 = lot.transform * Vector3(x, 4.4, 1.0)
			signs.fascia(smi, r_sign, lp)
			if shop != "shop_shutter_a" and dist < 120.0:
				add_omni(lot.transform * Vector3(x, 2.4, 0.9), P.shop_color, float(P.shop_light_energy), 7.5, 0.8)
		# storeys
		for f in floors:
			var y := GROUND + f * STOREY
			var mod: String = col_mod[i]
			if style == "concrete" and f > 0 and f % 4 == 3 and mod != "fac_balcony_a":
				mod = "fac_balcony_a"
			var mi: MeshInstance3D = kit.spawn(mod, lot, Transform3D(Basis(), Vector3(x, y, 0)))
			mi.set_instance_shader_parameter("lit_bias", lit_bias)
			mi.set_instance_shader_parameter("win_seed", float(idx * 31 + f * 7 + i))
			mi.set_instance_shader_parameter("inst_tint", Color(tint.r, tint.g, tint.b, 0.0))
		# parapet
		var ci: MeshInstance3D = kit.spawn(cornice, lot, Transform3D(Basis(), Vector3(x, top, 0)))
		ci.set_instance_shader_parameter("inst_tint", Color(tint.r, tint.g, tint.b, 0.0))

	# --- corner lot: wrap modules around the exposed side facing the camera (+Z world)
	if corner_near:
		var sb := Basis(Vector3(0, 1, 0).cross(Vector3(0, 0, 1)), Vector3.UP, Vector3(0, 0, 1))
		var nb := int(depth / BAY)
		var side_node := Node3D.new()
		# side wall plane at the lot's +Z end, running from the facade line back into the block
		side_node.transform = Transform3D(sb, Vector3(origin.x + side * (0.45 + nb * BAY * 0.5), WALK_Y, origin.z + w * 0.5))
		root.add_child(side_node)
		for i in nb:
			var x := (i - (nb - 1) * 0.5) * BAY
			kit.spawn(_pick_shop(rm) if i > 0 else "wall_service_a", side_node, Transform3D(Basis(), Vector3(x, 0, 0)))
			for f in floors:
				var mi: MeshInstance3D = kit.spawn(col_mod[i % col_mod.size()], side_node, Transform3D(Basis(), Vector3(x, GROUND + f * STOREY, 0)))
				mi.set_instance_shader_parameter("lit_bias", lit_bias)
				mi.set_instance_shader_parameter("win_seed", float(idx * 17 + f * 3 + i))
			kit.spawn(cornice, side_node, Transform3D(Basis(), Vector3(x, top, 0)))
		if r_sign.randf() < 0.9:
			signs.screen(side_node, Transform3D(Basis(), Vector3(0, GROUND + STOREY * 1.2, 0.2)), r_sign, 0.75)

	dress_facade(lot, idx, style, bays, floors, top, rm, r_sign, dist, side)
	dress_roof(lot, idx, style, w, top, depth, rm, r_sign)


func _pick_shop(r: RandomNumberGenerator) -> String:
	var open := float(P.shop_open_ratio)
	var items := [["shop_window_a", 2.0 * open], ["shop_food_a", 1.2 * open], ["shop_shutter_half", 1.0], ["shop_shutter_a", 1.6 * (1.0 - open) + 0.2], ["wall_service_a", 0.5]]
	return weighted(r, items)


func dress_facade(lot: Node3D, idx: int, style: String, bays: int, floors: int, top: float, _r: RandomNumberGenerator, _rsg: RandomNumberGenerator, dist: float, side: int) -> void:
	# every feature has its own random stream, so a preset that changes one density never
	# reshuffles the others: the street stays the same between looks
	var o: Vector3 = lot.position
	var w := bays * BAY
	var dens := float(P.sign_density)
	var r := rng_for(o.x, o.z, 11)
	var rsg := rng_for(o.x, o.z, 12)
	# awnings over shops
	for i in bays:
		var x := (i - (bays - 1) * 0.5) * BAY
		if r.randf() < 0.45 * float(P.awnings):
			var aw := "awning_a" if r.randf() < 0.6 else "awning_b"
			var ai: MeshInstance3D = kit.spawn(aw, lot, Transform3D(Basis(), Vector3(x, 0, 0)))
			var fc: Color = signs.pick_color(r).lerp(Color(0.3, 0.05, 0.04), 0.55)
			ai.set_instance_shader_parameter("inst_color", Color(fc.r, fc.g, fc.b, 1.0))
	# AC units
	r = rng_for(o.x, o.z, 13)
	var ac_ch := 0.16 * float(P.ac_units) * float(P.clutter)
	for i in bays:
		for f in floors:
			if r.randf() < ac_ch:
				var x := (i - (bays - 1) * 0.5) * BAY + (1.55 if r.randf() < 0.5 else -1.55)
				var y := GROUND + f * STOREY + r.randf_range(0.1, 0.6)
				kit.spawn("ac_unit_a" if r.randf() < 0.7 else "ac_unit_b", lot, Transform3D(Basis(), Vector3(x, y, 0)))
	# vertical pipe runs
	r = rng_for(o.x, o.z, 14)
	var npipes := int(round(r.randf_range(0.0, 1.6) * float(P.pipes)))
	for k in npipes:
		var x := (r.randi_range(0, bays) - bays * 0.5) * BAY + r.randf_range(-0.2, 0.2)
		x = clampf(x, -w * 0.5 + 0.3, w * 0.5 - 0.3)
		var heavy := style in ["panel", "brick"] and r.randf() < 0.5 * float(P.pipes)
		for f in floors:
			kit.spawn("pipe_cluster" if heavy else "pipe_v", lot, Transform3D(Basis(), Vector3(x, GROUND + f * STOREY, 0)))
	# conduit runs along a floor line
	r = rng_for(o.x, o.z, 15)
	if r.randf() < 0.5 * float(P.cables):
		var f := r.randi_range(0, mini(floors - 1, 3))
		for i in bays:
			kit.spawn("conduit_h", lot, Transform3D(Basis(), Vector3((i - (bays - 1) * 0.5) * BAY, GROUND + f * STOREY + 3.2, 0)))
	# fire escape column on brick/tile buildings
	r = rng_for(o.x, o.z, 16)
	if style in ["brick", "tile"] and r.randf() < 0.7 * float(P.fire_escapes) and floors > 2:
		var i := r.randi_range(0, bays - 1)
		for f in range(1, floors):
			kit.spawn("fire_escape", lot, Transform3D(Basis(), Vector3((i - (bays - 1) * 0.5) * BAY, GROUND + f * STOREY - 0.02, 0)))
	# blade signs at bay edges on the lower floors
	var max_f := mini(floors, 5)
	for e in range(bays + 1):
		var x := (e - bays * 0.5) * BAY
		if absf(x) > w * 0.5 - 0.3:
			x = signf(x) * (w * 0.5 - 0.4)
		for f in max_f:
			var chance := 0.42 * dens * (1.0 - f * 0.13)
			if rsg.randf() < chance:
				var y := GROUND + f * STOREY + rsg.randf_range(0.0, 0.6) - 0.3
				signs.blade(lot, Transform3D(Basis(), Vector3(x, y, 0.0)), rsg)
				break
	# wall box signs
	rsg = rng_for(o.x, o.z, 17)
	for i in bays:
		if rsg.randf() < 0.18 * dens:
			var f := rsg.randi_range(0, mini(2, floors - 1))
			signs.wall_box(lot, Transform3D(Basis(), Vector3((i - (bays - 1) * 0.5) * BAY, GROUND + f * STOREY + 2.55, 0)), rsg)
	# big vertical neon word on some facades
	rsg = rng_for(o.x, o.z, 18)
	if rsg.randf() < 0.32 * float(P.neon_word_count) and floors >= 4:
		var word: String = P.big_words[rsg.randi() % P.big_words.size()]
		var hgt := 1.15
		var x := (rsg.randi_range(0, bays) - bays * 0.5) * BAY
		x = clampf(x, -w * 0.5 + 0.8, w * 0.5 - 0.8)
		signs.neon_word(lot, Transform3D(Basis(), Vector3(x - 0.35, GROUND + STOREY * 1.0 + word.length() * hgt * 1.25, 0.55)), word, hgt, signs.pick_color(rsg), true)
	# flat LED screen on the facade (mid-distance lots), covering a couple of storeys
	rsg = rng_for(o.x, o.z, 19)
	if rsg.randf() < 0.22 * float(P.billboard_count) and floors >= 6 and dist > 30.0 and dist < 170.0 and w >= 16.0:
		var sx := (rsg.randi_range(0, bays - 3) - (bays - 3) * 0.5) * BAY
		signs.screen(lot, Transform3D(Basis(), Vector3(sx, GROUND + STOREY * rsg.randi_range(2, 4) + 0.3, 0.75)), rsg, 0.8)
	# hologram panel
	rsg = rng_for(o.x, o.z, 20)
	if rsg.randf() < 0.14 * float(P.holo_count) and floors >= 4 and dist > 25.0:
		var y := GROUND + STOREY * rsg.randi_range(1, 3)
		signs.holo(lot, Transform3D(Basis(), Vector3(0, y, 0.45)), rsg, minf(w - 2.0, 9.0), 4.2)


func dress_roof(lot: Node3D, idx: int, style: String, w: float, top: float, depth: float, _r: RandomNumberGenerator, _rsg: RandomNumberGenerator) -> void:
	var o: Vector3 = lot.position
	var r := rng_for(o.x, o.z, 21)
	var rsg := rng_for(o.x, o.z, 22)
	var y := top + 0.0
	var mode: String = P.rooftop
	var clutter := float(P.clutter)
	var cz := -0.45 - depth * 0.5
	var items: Array
	if mode == "industrial":
		items = [["stack_industrial", 1.5], ["cooling_unit", 2.0], ["duct_run", 2.0], ["water_tank", 1.5], ["roof_hvac", 1.5], ["antenna_mast", 0.8]]
	elif mode == "corporate":
		items = [["roof_hvac", 2.0], ["dish_a", 1.0], ["antenna_mast", 0.6], ["roof_stairhouse", 1.0]]
	else:
		items = [["water_tank", 1.6], ["roof_hvac", 1.6], ["antenna_mast", 1.0], ["dish_a", 1.0], ["roof_stairhouse", 1.0], ["duct_run", 0.8], ["stack_industrial", 0.3], ["cooling_unit", 0.4]]
	var n := int(round(r.randf_range(1.0, 3.5) * clutter * (w / 16.0)))
	for k in n:
		var piece := weighted(r, items)
		var px := r.randf_range(-w * 0.5 + 2.5, w * 0.5 - 2.5)
		var pz := cz + r.randf_range(-depth * 0.35, depth * 0.35)
		kit.spawn(piece, lot, Transform3D(Basis(Vector3.UP, r.randf_range(0, TAU)), Vector3(px, y, pz)))
		if piece == "stack_industrial" and r.randf() < 0.8:
			steam_spots.append(lot.transform * Vector3(px, y + 12.0, pz))
	# rooftop billboard or neon word frame
	var roll := rsg.randf()
	if roll < 0.2 * float(P.billboard_count):
		var bi: MeshInstance3D = kit.spawn("billboard_roof", lot, Transform3D(Basis(Vector3.UP, rsg.randf_range(-0.25, 0.25)), Vector3(rsg.randf_range(-w * 0.15, w * 0.15), y, -2.5)).scaled_local(Vector3.ONE * float(P.billboard_scale)))
		signs.style_screen(bi, rsg)
		var cols: Array = P.screen_colors[0]
		add_omni(lot.transform * Vector3(0, y + 6.0, 4.0), cols[1], 2.5, 18.0, 0.8)
	elif roll < 0.42 * float(P.neon_word_count):
		kit.spawn("sign_frame_roof", lot, Transform3D(Basis(), Vector3(0, y, -2.0)))
		var word: String = P.big_words[rsg.randi() % P.big_words.size()]
		var hgt := 2.4
		var tw := 0.0
		for ch in word:
			tw += (kit.glyph_w(ch) + 0.22) * hgt
		signs.neon_word(lot, Transform3D(Basis(), Vector3(-tw * 0.5, y + 0.6, -1.4)), word, hgt, signs.pick_color(rsg), false, false)


# ---------------------------------------------------------------------------- cross street
func build_cross_street() -> void:
	var cs := node("CrossStreet")
	var idx := 500
	for s in [1, -1]:
		var x := FRONT + 24.0
		while x < 70.0:
			var r := rng_for(s, x, 9)
			var bays := r.randi_range(3, 5)
			var w := bays * BAY
			var floors := r.randi_range(5, 14)
			var origin := Vector3(s * (x + w * 0.5), WALK_Y, JUNCTION.x)
			build_lot(cs, idx, origin, facing(Vector3(0, 0, 1)), bays, floors, 20.0, false, s)
			idx += 1
			x += w
		# near side (faces -Z, mostly hidden) as plain masses
		var mi := box(cs, Vector3(90.0, 40.0, 20.0), Transform3D(Basis(), Vector3(s * (FRONT + 24.0 + 45.0), 20.0, JUNCTION.y + 10.5)), "building_mass")
		mi.set_instance_shader_parameter("tower_seed", 77.0 + s)


# ---------------------------------------------------------------------------- back rows
func build_back_rows() -> void:
	var br := node("BackRows")
	var r := RandomNumberGenerator.new()
	r.seed = 99
	for s in [1, -1]:
		var z := 10.0
		while z > -330.0:
			var wz := r.randf_range(18.0, 34.0)
			var wx := r.randf_range(16.0, 30.0)
			var h := r.randf_range(35.0, 95.0)
			if r.randf() < 0.25:
				h = r.randf_range(100.0, 150.0)
			var x: float = s * (FRONT + 27.0 + wx * 0.5 + r.randf_range(0.0, 8.0))
			if absf(z - RAIL_Z) < 14.0:
				z -= 16.0
				continue
			var mi := box(br, Vector3(wx, h, wz), Transform3D(Basis(), Vector3(x, h * 0.5, z - wz * 0.5)), "backrow_mass" if r.randf() < 0.5 else "building_mass")
			mi.set_instance_shader_parameter("tower_seed", r.randf_range(0, 100))
			mi.set_instance_shader_parameter("lit_bias", r.randf_range(-0.15, 0.1))
			# crown details
			var topn := Node3D.new()
			topn.position = Vector3(x, h, z - wz * 0.5)
			br.add_child(topn)
			var k := r.randi_range(1, 3)
			for i in k:
				var pc: String = ["water_tank", "antenna_mast", "roof_hvac", "dish_a"][r.randi() % 4]
				if P.rooftop == "industrial" and r.randf() < 0.5:
					pc = ["stack_industrial", "cooling_unit"][r.randi() % 2]
				kit.spawn(pc, topn, Transform3D(Basis(Vector3.UP, r.randf_range(0, TAU)), Vector3(r.randf_range(-wx * 0.3, wx * 0.3), 0, r.randf_range(-wz * 0.3, wz * 0.3))))
			# LED crown strip + street-facing screen on some
			if r.randf() < 0.35 * float(P.tower_led):
				var led := box(br, Vector3(wx + 0.3, 0.35, wz + 0.3), Transform3D(Basis(), Vector3(x, h - 1.0, z - wz * 0.5)), "led_strip")
				led.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if r.randf() < 0.3 * float(P.billboard_count) and h > 40.0:
				var sx := Transform3D(facing(Vector3(-s, 0, 0)), Vector3(x - s * wx * 0.5 - 0.1, h * r.randf_range(0.55, 0.8), z - wz * 0.5))
				var scr: MeshInstance3D = kit.spawn("screen_wall", br, sx.scaled_local(Vector3(1.3, 1.3, 1.0) * float(P.billboard_scale)))
				signs.style_screen(scr, r)
			z -= wz + r.randf_range(0.0, 6.0)


# ---------------------------------------------------------------------------- street furniture
func build_street_props() -> void:
	var pr := node("Props")
	var r := RandomNumberGenerator.new()
	r.seed = 7
	var lamp_dir := Vector3(0, -1, 0)
	var spacing := float(P.lamp_spacing)
	var lamps: Array = []
	for s in [1, -1]:
		var z := 2.0 if s == 1 else -12.0
		while z > STREET_END:
			if absf(z - RAIL_Z) > 9.0:
				lamps.append(Vector3(s * (ROAD + 0.55), WALK_Y, z))
			z -= spacing
	lamps.sort_custom(func(a, b): return a.distance_to(cam_pos) < b.distance_to(cam_pos))
	var shadowed := 0
	for p in lamps:
		var s := signf(p.x)
		var b := Basis(Vector3.UP, PI if s > 0 else 0.0)
		kit.spawn("lamp_a", pr, Transform3D(b, p))
		var head: Vector3 = p + b * Vector3(2.75, 8.15, 0.0)
		var sh := shadowed < int(P.lamp_shadows)
		# a lamp right over the lens would fill the whole frame with lit fog: keep its light, thin its fog
		var l := add_spot(head, lamp_dir, P.lamp_color, float(P.lamp_energy), float(P.lamp_range), float(P.lamp_angle), float(P.lamp_fog), sh)
		if l and sh:
			shadowed += 1
	# traffic lights at the crosswalk (mirrored so the arm reaches over the road)
	var tl: MeshInstance3D = kit.spawn("traffic_light", pr, Transform3D(Basis().scaled(Vector3(-1, 1, 1)), Vector3(ROAD + 0.6, WALK_Y, CROSSWALK.y + 1.6)))
	tl.set_instance_shader_parameter("sign_cell", Vector4(0, 13, 1, 0.6))
	var tl2: MeshInstance3D = kit.spawn("traffic_light", pr, Transform3D(Basis().scaled(Vector3(1, 1, -1)), Vector3(-ROAD - 0.6, WALK_Y, CROSSWALK.x - 1.6)))
	tl2.set_instance_shader_parameter("sign_cell", Vector4(0, 7, 1, 0.6))
	var sig_col: Color = Color(1, 0.05, 0.02) if P.signal_state == "red" else (Color(0.1, 1, 0.5) if P.signal_state == "green" else Color(1, 0.5, 0.02))
	add_omni(Vector3(ROAD - 2.8, 5.9, CROSSWALK.y + 1.3), sig_col, 1.2, 5.0, 1.0)
	add_omni(Vector3(ROAD - 5.6, 5.9, CROSSWALK.y + 1.3), sig_col, 1.2, 5.0, 1.0)
	# traffic lights at the junction
	kit.spawn("traffic_light", pr, Transform3D(Basis().scaled(Vector3(-1, 1, 1)), Vector3(ROAD + 0.6, WALK_Y, JUNCTION.y + 0.8)))
	kit.spawn("traffic_light", pr, Transform3D(Basis().scaled(Vector3(1, 1, -1)), Vector3(-ROAD - 0.6, WALK_Y, JUNCTION.x - 0.8)))
	# bollards near the crosswalk
	for s in [1, -1]:
		for i in 4:
			kit.spawn("bollard", pr, Transform3D(Basis(), Vector3(s * (ROAD + 0.45), WALK_Y, CROSSWALK.x - 1.0 - i * 1.4)))
			kit.spawn("bollard", pr, Transform3D(Basis(), Vector3(s * (ROAD + 0.45), WALK_Y, CROSSWALK.y + 2.2 + i * 1.4)))
	# foreground hero props on the right sidewalk (camera side)
	var vm: MeshInstance3D = kit.spawn("vending_a", pr, Transform3D(facing(Vector3(-1, 0, 0.75)), Vector3(FRONT - 0.75, WALK_Y, -6.0)))
	_style_vending(vm, r)
	var vm2: MeshInstance3D = kit.spawn("vending_b", pr, Transform3D(facing(Vector3(-1, 0, 0.75)), Vector3(FRONT - 0.6, WALK_Y, -7.15)))
	_style_vending(vm2, r)
	add_omni(Vector3(FRONT - 2.0, 1.2, -5.6), Color(0.75, 0.88, 1.0).lerp(signs.pick_color(r), 0.35), 1.6, 5.0, 0.6, true)
	# frame-edge pedestrian lamp and a hero blade sign hanging into the top right of the frame
	kit.spawn("lamp_b", pr, Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(FRONT - 1.05, WALK_Y, -2.7)))
	add_spot(Vector3(FRONT - 1.05, WALK_Y + 4.1, -2.0), Vector3(-0.2, -1, -0.15), P.lamp_color, float(P.lamp_energy) * 0.3, 9.0, 60.0, float(P.lamp_fog) * 0.6, true)
	var hero := Node3D.new()
	hero.transform = Transform3D(facing(Vector3(-1, 0, 0)), Vector3(FRONT, WALK_Y, -4.6))
	pr.add_child(hero)
	var hs: MeshInstance3D = signs.blade(hero, Transform3D(Basis(), Vector3(0, 4.0, 0.0)), r, 0.1)
	# it hangs 3-5 m from the lens: dimmer tubes and face so its bloom frames the corner instead of flooding it
	hs.set_instance_shader_parameter("sign_cell", Vector4(1, 0, 0, 0.45))
	hs.set_instance_shader_parameter("neon_on", 0.3)
	hs.set_instance_shader_parameter("sign_a", Color(0.02, 0.01, 0.04))
	# its light sits right beside the lens: keep the colour spill, drop the fog glow that washes the corner
	var hl := lights_root.get_child(lights_root.get_child_count() - 1) as OmniLight3D
	if hl:
		hl.light_volumetric_fog_energy = 0.15
		hl.light_energy *= 0.7
	kit.spawn("bin_a", pr, Transform3D(facing(Vector3(-1, 0, 0)), Vector3(FRONT - 0.5, WALK_Y, -8.6)))
	kit.spawn("clutter_boxes", pr, Transform3D(facing(Vector3(-1, 0, 0)), Vector3(FRONT - 0.8, WALK_Y, -11.5)))
	kit.spawn("hydrant", pr, Transform3D(Basis(), Vector3(ROAD + 0.7, WALK_Y, -9.0)))
	kit.spawn("parking_meter", pr, Transform3D(facing(Vector3(-1, 0, 0)), Vector3(ROAD + 0.5, WALK_Y, -13.0)))
	kit.spawn("street_sign", pr, Transform3D(facing(Vector3(0, 0, 1)), Vector3(ROAD + 0.5, WALK_Y, -20.0)))
	kit.spawn("utility_box", pr, Transform3D(facing(Vector3(-1, 0, 0)), Vector3(FRONT - 0.45, WALK_Y, -17.0)))
	# kiosk on the left sidewalk, more vending machines down the street
	var ki: MeshInstance3D = kit.spawn("kiosk_a", pr, Transform3D(facing(Vector3(1, 0, 0)), Vector3(-ROAD - 2.2, WALK_Y, -46.0)))
	signs.style_sign(ki, r, 0, r.randi() % 32, Vector3(-ROAD - 1.0, 2.6, -46.0))
	ki.set_instance_shader_parameter("scr_cell", Vector4(3, 0, 1, 0))
	add_omni(Vector3(-ROAD - 0.6, 1.8, -46.0), P.shop_color, 1.5, 6.0, 0.8)
	for z in [-58.0, -128.0]:
		var v: MeshInstance3D = kit.spawn("vending_a", pr, Transform3D(facing(Vector3(1, 0, 0)), Vector3(-FRONT + 0.5, WALK_Y, z)))
		_style_vending(v, r)
		add_omni(Vector3(-FRONT + 1.5, 1.3, z), Color(0.8, 0.9, 1.0), 1.2, 4.5, 0.8)
	# clutter along both sidewalks
	var cl := float(P.clutter)
	for s in [1, -1]:
		var z := -14.0
		while z > STREET_END + 10.0:
			z -= r.randf_range(6.0, 16.0) / maxf(cl, 0.2)
			if absf(z - RAIL_Z) < 10.0 or (z < CROSSWALK.y + 2.0 and z > CROSSWALK.x - 2.0):
				continue
			var roll := r.randf()
			var pos := Vector3(s * (FRONT - 0.6), WALK_Y, z)
			var b := facing(Vector3(-s, 0, 0))
			if roll < 0.35:
				kit.spawn("bin_a", pr, Transform3D(b, pos))
			elif roll < 0.6:
				kit.spawn("clutter_boxes", pr, Transform3D(b, pos))
			elif roll < 0.72:
				kit.spawn("utility_box", pr, Transform3D(b, pos))
			elif roll < 0.82:
				kit.spawn("hydrant", pr, Transform3D(Basis(), Vector3(s * (ROAD + 0.7), WALK_Y, z)))
			elif roll < 0.9:
				kit.spawn("parking_meter", pr, Transform3D(b, Vector3(s * (ROAD + 0.5), WALK_Y, z)))
			else:
				kit.spawn("barrier", pr, Transform3D(facing(Vector3(0, 0, 1)), Vector3(s * (ROAD + 1.2), WALK_Y, z)))
	# manholes and steam vents in the road
	for m in [Vector3(-1.4, 0.0, -16.5), Vector3(-2.8, 0.0, -57.0), Vector3(1.6, 0.0, -118.0), Vector3(-1.5, 0.0, -160.0)]:
		kit.spawn("manhole", pr, Transform3D(Basis(Vector3.UP, r.randf_range(0, TAU)), m))
		steam_spots.append(m)
	for v in [Vector3(3.4, 0.0, -10.5), Vector3(-5.0, 0.0, -38.0), Vector3(4.6, 0.0, -72.0), Vector3(-4.8, 0.0, -140.0)]:
		kit.spawn("vent_street", pr, Transform3D(Basis(), v))
		steam_spots.append(v)
	# sidewalk vents near walls
	for v in [Vector3(-FRONT + 1.0, WALK_Y, -26.0), Vector3(FRONT - 1.0, WALK_Y, -30.0)]:
		kit.spawn("vent_street", pr, Transform3D(Basis(Vector3.UP, PI * 0.5), v))
		steam_spots.append(v)


func _style_vending(mi: GeometryInstance3D, r: RandomNumberGenerator) -> void:
	signs.style_sign(mi, r, 0, r.randi() % 32, Vector3.ZERO, 0.01)
	mi.set_instance_shader_parameter("sign_cell", Vector4(3, r.randi() % 8, 0, 1.0))
	mi.set_instance_shader_parameter("scr_cell", Vector4(r.randi() % 8, 0, 1, 0))
	var c: Color = signs.pick_color(r)
	mi.set_instance_shader_parameter("inst_color", Color(c.r * 0.3 + 0.02, c.g * 0.3 + 0.02, c.b * 0.3 + 0.02, 1.0))


# ---------------------------------------------------------------------------- cars
func build_cars() -> void:
	var cars := node("Cars")
	var r := RandomNumberGenerator.new()
	r.seed = 31
	var kinds := ["car_sedan", "car_van", "car_wedge"]
	var parked := [
		[1, -11.0, 0], [1, -17.5, 1], [1, -40.0, 2], [1, -47.0, 0], [1, -61.0, 0], [1, -110.0, 1], [1, -126.0, 0], [1, -152.0, 2],
		[-1, -9.0, 2], [-1, -21.0, 0], [-1, -27.0, 1], [-1, -52.0, 0], [-1, -66.0, 2], [-1, -73.0, 0], [-1, -116.0, 0], [-1, -138.0, 1], [-1, -170.0, 0],
	]
	var npark := int(round(parked.size() * clampf(float(P.parked_cars), 0.0, 1.0)))
	for i in npark:
		var c: Array = parked[i]
		_car(cars, kinds[c[2]], Vector3(c[0] * 5.55, 0.0, c[1]), c[0] > 0, r, false)
	# moving traffic: right lanes drive away (tail lights), left lanes come towards us (headlights)
	var moving := [[1.8, -24.6, 0], [1.8, -66.0, 2], [5.0, -95.0, 1], [1.8, -150.0, 0], [-1.8, -48.0, 2], [-1.8, -88.0, 0], [-1.8, -125.0, 1], [-1.8, -190.0, 0]]
	var nmove := int(round(moving.size() * clampf(float(P.traffic) * 0.5, 0.0, 1.0)))
	for i in nmove:
		var c: Array = moving[i]
		_car(cars, kinds[c[2]], Vector3(c[0], 0.0, c[1]), c[0] > 0, r, true)


func _car(parent: Node3D, kind: String, pos: Vector3, away: bool, r: RandomNumberGenerator, moving: bool) -> void:
	var b := Basis(Vector3.UP, PI if away else 0.0)
	var car: Node3D = kit.spawn_scene(kind, parent, Transform3D(b, pos))
	var cols: Array = P.car_paint_colors
	var col: Color = cols[r.randi() % cols.size()]
	_set_tree_param(car, "inst_color", Color(col.r, col.g, col.b, 1.0))
	var sc: Color = signs.pick_color(r)
	_set_tree_param(car, "sign_a", Color(0.05, 0.05, 0.05))
	_set_tree_param(car, "sign_b", sc)
	_set_tree_param(car, "sign_c", Color(1, 1, 1))
	_set_tree_param(car, "sign_cell", Vector4(0, r.randi() % 32, 0, 0.8))
	var fwd: Vector3 = b * Vector3(0, 0, 1)
	var d := pos.distance_to(cam_pos)
	var e := float(P.car_light_energy)
	if d < 120.0:
		# headlights
		if not away and moving:
			add_spot(pos + fwd * 2.4 + Vector3(0, 0.7, 0), fwd + Vector3(0, -0.08, 0), P.car_head_color, e * 2.0, 26.0, 28.0, 1.2, d < 60.0)
		elif not away:
			add_omni(pos + fwd * 2.6 + Vector3(0, 0.7, 0), P.car_head_color, e * 0.25, 4.0, 0.5)
		# tail glow
		add_omni(pos - fwd * 2.6 + Vector3(0, 0.8, 0), P.car_tail_color, e * (0.5 if moving else 0.25), 4.5 if moving else 3.0, 0.8)


func _set_tree_param(n: Node, key: String, v) -> void:
	if n is GeometryInstance3D:
		n.set_instance_shader_parameter(key, v)
	for c in n.get_children():
		_set_tree_param(c, key, v)


# ---------------------------------------------------------------------------- elevated rail
func build_rail() -> void:
	var rl := node("Rail")
	var r := RandomNumberGenerator.new()
	r.seed = 55
	var x := -168.0
	while x <= 168.0:
		var gm: MeshInstance3D = kit.spawn("rail_girder", rl, Transform3D(Basis(), Vector3(x, RAIL_Y, RAIL_Z)))
		signs.style_sign(gm, r, 0, r.randi() % 32, Vector3(x, RAIL_Y - 1.3, RAIL_Z + 4.0), 9.0)
		x += 24.0
	for px in [-60.0, -36.0, 36.0, 60.0, -84.0, 84.0, -108.0, 108.0]:
		var pm: MeshInstance3D = kit.spawn("rail_pillar", rl, Transform3D(Basis(), Vector3(px, 0.0, RAIL_Z)))
		pm.scale = Vector3(1, (RAIL_Y - 2.1) / 12.0, 1)
	# portal frames on the main street sidewalks hold the span over the street
	for s in [-1, 1]:
		var pm2: MeshInstance3D = kit.spawn("rail_pillar", rl, Transform3D(Basis(), Vector3(s * 16.0, 0.0, RAIL_Z)))
		pm2.scale = Vector3(1, (RAIL_Y - 2.1) / 12.0, 1)
	if P.train:
		for i in 3:
			var tm: MeshInstance3D = kit.spawn("train_car", rl, Transform3D(Basis(), Vector3(-34.0 + i * 18.4, RAIL_Y + 0.22, RAIL_Z - 1.1)))
			tm.set_instance_shader_parameter("inst_tint", Color(0.9, 0.92, 1.0, 0.0))
		add_omni(Vector3(-16.0, RAIL_Y + 2.0, RAIL_Z + 2.5), P.shop_color, 1.2, 10.0, 0.6)
	# light strips under the deck throw light down on the junction
	for lx in [-8.0, 0.0, 8.0]:
		add_omni(Vector3(lx, RAIL_Y - 2.8, RAIL_Z), P.led_color, 1.0, 10.0, 1.0)


# ---------------------------------------------------------------------------- overhead
func build_overhead() -> void:
	var oh := node("Overhead")
	var r := RandomNumberGenerator.new()
	r.seed = 66
	var nc := int(round(14.0 * float(P.cables)))
	for i in nc:
		var z := r.randf_range(-8.0, -180.0)
		var y1 := r.randf_range(6.0, 16.0)
		var y2 := y1 + r.randf_range(-2.5, 2.5)
		var dz := r.randf_range(-6.0, 6.0)
		var a := Vector3(FRONT - 0.2, y1, z)
		var b := Vector3(-FRONT + 0.2, y2, z + dz)
		for k in r.randi_range(1, 3):
			cable(oh, a + Vector3(0, k * 0.12, k * 0.1), b + Vector3(0, k * 0.1, k * 0.12), r.randf_range(0.8, 2.6), r.randf_range(0.014, 0.03))
	# cables running along the facades
	for s in [-1, 1]:
		var z := 10.0
		while z > -200.0:
			var z2 := z - r.randf_range(14.0, 30.0)
			var y := r.randf_range(4.6, 9.0)
			cable(oh, Vector3(s * (FRONT - 0.3), y, z), Vector3(s * (FRONT - 0.3), y + r.randf_range(-0.5, 0.5), z2), r.randf_range(0.4, 1.2), 0.018)
			z = z2
	if P.skybridge:
		var sb: MeshInstance3D = kit.spawn("skybridge", oh, Transform3D(Basis().scaled(Vector3(1.12, 1, 1)), Vector3(0, 21.0, -150.0)))
		signs.style_sign(sb, r, 0, r.randi() % 32, Vector3(0, 20.4, -147.0), 10.0)
	if P.lanterns:
		var rows := int(P.lantern_rows)
		for k in rows:
			var z := -6.0 - k * 7.5
			var y := 6.5 + (k % 2) * 1.2
			var a := Vector3(FRONT - 0.3, y, z)
			var b := Vector3(-FRONT + 0.3, y + 0.4, z - 1.0)
			var sag := 1.6
			cable(oh, a, b, sag, 0.012)
			var n := 11
			for i in range(1, n):
				var t := float(i) / n
				var p := a.lerp(b, t)
				p.y -= sag * 4.0 * t * (1.0 - t)
				var lm: MeshInstance3D = kit.spawn("lantern", oh, Transform3D(Basis().scaled(Vector3.ONE * 1.3), p))
				lm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				if i % 3 == 1:
					add_omni(p + Vector3(0, -0.6, 0), P.lantern_color, 0.9, 5.0, 1.0)


# ---------------------------------------------------------------------------- megatowers
func build_towers() -> void:
	var tw := node("Towers")
	var r := RandomNumberGenerator.new()
	r.seed = 77
	var style: String = P.tower_style
	var list := [
		["tower_c", Vector3(-18.0, 0, -360.0), 0.0, 1.0],
		["tower_a", Vector3(58.0, 0, -320.0), 0.3, 1.05],
		["tower_b", Vector3(-90.0, 0, -430.0), 0.0, 1.0],
		["tower_d", Vector3(28.0, 0, -520.0), 0.2, 1.3],
		["tower_a", Vector3(-48.0, 0, -640.0), 0.78, 1.5],
		["tower_b", Vector3(130.0, 0, -500.0), 0.0, 1.2],
		["tower_d", Vector3(-70.0, 0, -210.0), 0.0, 0.85],
		["tower_a", Vector3(78.0, 0, -170.0), 0.1, 0.8],
		["tower_c", Vector3(150.0, 0, -700.0), -0.4, 1.4],
		["tower_b", Vector3(-160.0, 0, -620.0), 0.0, 1.3],
		["tower_d", Vector3(85.0, 0, -380.0), 0.6, 1.1],
	]
	var count := int(round(list.size() * clampf(float(P.tower_count), 0.0, 1.0)))
	for i in count:
		var t: Array = list[i]
		var kind: String = t[0]
		if style == "glass" and kind == "tower_d":
			kind = "tower_a"
		elif style == "industrial" and kind == "tower_a":
			kind = "tower_d"
		var mi: MeshInstance3D = kit.spawn(kind, tw, Transform3D(Basis(Vector3.UP, t[2]).scaled(Vector3.ONE * t[3]), t[1]))
		mi.set_instance_shader_parameter("tower_seed", float(i) * 3.7)
		mi.set_instance_shader_parameter("lit_bias", r.randf_range(-0.1, 0.1))
		mi.set_instance_shader_parameter("sign_cell", Vector4(3, r.randi() % 8, 0, 1))
		signs.style_screen(mi, r)
	# a big street-facing screen low on the tower that closes the end of the street: the focal glow
	if count > 0:
		var es := Transform3D(Basis().scaled(Vector3(2.4, 2.4, 1.0) * float(P.billboard_scale)), Vector3(-6.0, 22.0, -347.4))
		var scr: MeshInstance3D = kit.spawn("screen_wall", tw, es)
		signs.style_screen(scr, r)
		scr.set_instance_shader_parameter("scr_cell", Vector4(0, 0, 1.6, 0))
	# giant floating hologram ads between the towers
	var hn := int(round(2.0 * float(P.holo_count)))
	var spots := [Transform3D(Basis(), Vector3(12.0, 58.0, -250.0)), Transform3D(Basis(Vector3.UP, 0.25), Vector3(-26.0, 92.0, -330.0)), Transform3D(Basis(), Vector3(30.0, 120.0, -440.0))]
	for i in mini(hn, spots.size()):
		signs.holo_free(tw, spots[i], r, 46.0 * float(P.billboard_scale), 24.0 * float(P.billboard_scale), i % 2 == 1)
