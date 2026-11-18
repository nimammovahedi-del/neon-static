# Kit loader: loads the Blender GLBs from res://assets/kit, swaps every surface material for the
# shader material of the same role name (see mats.gd) and hands out meshes / spawns instances.
extends RefCounted

const KIT_DIR := "res://assets/kit/"
var mats
var _meshes := {}
var _scenes := {}
var _glyphs := {}
var glyph_width := {}


func _init(m) -> void:
	mats = m
	var f := FileAccess.open(KIT_DIR + "neon_glyphs.json", FileAccess.READ)
	if f:
		glyph_width = JSON.parse_string(f.get_as_text())


func _remap(mesh: Mesh) -> Mesh:
	var m: Mesh = mesh.duplicate()
	for i in m.get_surface_count():
		var src := m.surface_get_material(i)
		var role := src.resource_name if src else ""
		m.surface_set_material(i, mats.get_mat(role))
	return m


func _first_mesh(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D:
		return n
	for c in n.get_children():
		var r := _first_mesh(c)
		if r:
			return r
	return null


func mesh(name: String) -> Mesh:
	if _meshes.has(name):
		return _meshes[name]
	var ps: PackedScene = load(KIT_DIR + name + ".glb")
	if ps == null:
		push_error("kit piece missing: " + name)
		return null
	var inst := ps.instantiate()
	var mi := _first_mesh(inst)
	var m: Mesh = _remap(mi.mesh) if mi else null
	inst.free()
	_meshes[name] = m
	return m


func spawn(name: String, parent: Node, xf: Transform3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh(name)
	mi.transform = xf
	parent.add_child(mi)
	return mi


# Multi-object pieces (cars with wheels): instance the GLB and remap every mesh.
func spawn_scene(name: String, parent: Node, xf: Transform3D) -> Node3D:
	if not _scenes.has(name):
		_scenes[name] = load(KIT_DIR + name + ".glb")
	var inst: Node3D = _scenes[name].instantiate()
	_remap_tree(inst)
	inst.transform = xf
	parent.add_child(inst)
	return inst


func _remap_tree(n: Node) -> void:
	if n is MeshInstance3D:
		var key: String = "scn:" + str(n.mesh.get_instance_id())
		if not _meshes.has(key):
			_meshes[key] = _remap(n.mesh)
		n.mesh = _meshes[key]
	for c in n.get_children():
		_remap_tree(c)


func glyph(ch: String) -> Mesh:
	if _glyphs.is_empty():
		var ps: PackedScene = load(KIT_DIR + "neon_glyphs.glb")
		var inst := ps.instantiate()
		_collect_glyphs(inst)
		inst.free()
	return _glyphs.get(ch)


func _collect_glyphs(n: Node) -> void:
	if n is MeshInstance3D and String(n.name).begins_with("g_"):
		_glyphs[String(n.name).substr(2)] = _remap(n.mesh)
	for c in n.get_children():
		_collect_glyphs(c)


func glyph_w(ch: String) -> float:
	return float(glyph_width.get(ch, 0.6))
