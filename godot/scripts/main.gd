# Entry point of the look test. Reads command-line options after "--":
#   look=<ID>      preset file godot/looks/<ID>.gd (default N)
#   out=<path>     write a PNG after the scene has settled, then quit (omit to just look around)
#   frames=<n>     frames to wait before the capture (default 150)
#   w=<px> h=<px>  render size (default 2560 x 1440)
#   ss=<scale>     3D supersampling factor (default 1.5)
#   mode=street|kit   kit = the kit sheet shots (scripts/kit_sheet.gd)
extends Node

const Look = preload("res://scripts/look.gd")
const Mats = preload("res://scripts/mats.gd")
const Kit = preload("res://scripts/kit.gd")
const Street = preload("res://scripts/street.gd")
const Atmos = preload("res://scripts/atmos.gd")
const KitSheet = preload("res://scripts/kit_sheet.gd")

# The fixed camera: right-hand sidewalk near the kerb, eye height 1.7 m above the sidewalk.
const CAM_POS := Vector3(7.75, 0.15 + 1.7, 0.0)
const CAM_YAW := 5.5      # degrees to the left (towards the street centre)
const CAM_PITCH := 6.5    # degrees up
const CAM_FOV := 62.0     # vertical

var args := {}
var sv: SubViewport
var world: Node3D
var cam: Camera3D
var frame := 0
var frames := 150
var out := ""
var t0 := 0
var sheet = null


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var id: String = args.get("look", "N")
	out = args.get("out", "")
	frames = int(args.get("frames", "150"))
	var w := int(args.get("w", "2560"))
	var h := int(args.get("h", "1440"))
	var ss := float(args.get("ss", "1.5"))
	var P := Look.load_preset(id)
	print("LOOK %s \"%s\"" % [id, P.name])
	t0 = Time.get_ticks_msec()

	sv = SubViewport.new()
	sv.size = Vector2i(w, h)
	sv.own_world_3d = true
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sv.msaa_3d = Viewport.MSAA_4X
	sv.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	sv.use_taa = false
	sv.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	sv.scaling_3d_scale = ss
	sv.positional_shadow_atlas_size = 8192
	sv.positional_shadow_atlas_16_bits = true
	sv.positional_shadow_atlas_quad_0 = Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_4
	sv.positional_shadow_atlas_quad_1 = Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_16
	sv.positional_shadow_atlas_quad_2 = Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_64
	sv.positional_shadow_atlas_quad_3 = Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_64
	sv.mesh_lod_threshold = 0.0
	sv.use_debanding = true
	sv.anisotropic_filtering_level = Viewport.ANISOTROPY_16X
	add_child(sv)
	var tr := TextureRect.new()
	tr.texture = sv.get_texture()
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(tr)

	world = Node3D.new()
	world.name = "World"
	sv.add_child(world)
	cam = Camera3D.new()
	cam.fov = CAM_FOV
	cam.near = 0.05
	cam.far = 2500.0
	cam.fov = float(args.get("fov", str(CAM_FOV)))
	cam.position = Vector3(float(args.get("cx", str(CAM_POS.x))), float(args.get("cy", str(CAM_POS.y))), float(args.get("cz", str(CAM_POS.z))))
	cam.rotation_degrees = Vector3(float(args.get("pitch", str(CAM_PITCH))), float(args.get("yaw", str(CAM_YAW))), 0.0)
	world.add_child(cam)
	cam.current = true

	var mats = Mats.new(P)
	var kit = Kit.new(mats)
	var atm = Atmos.new(P, mats)
	if args.get("mode", "street") == "kit":
		sheet = KitSheet.new(P, kit, mats, world, cam, sv, args)
		sheet.build()
		atm.build(world, [], cam)
		sheet.after_atmos(atm)
	else:
		var st = Street.new(P, kit, mats, world, CAM_POS)
		st.build()
		atm.build(world, st.steam_spots, cam)
		print("BUILD look=%s lights=%d nodes=%d ms=%d" % [id, st.light_count, _count(world), Time.get_ticks_msec() - t0])
	sv.add_child(atm.grade_layer())


func _count(n: Node) -> int:
	var c := 1
	for k in n.get_children():
		c += _count(k)
	return c


func _process(_delta: float) -> void:
	frame += 1
	if sheet:
		sheet.process(frame)
		return
	if frame == 30:
		print("FPS ~%.1f after 30 frames" % Engine.get_frames_per_second())
	if out != "" and frame == frames:
		capture(out)


func capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	var img := sv.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var err := img.save_png(path)
	print("SAVED %s err=%d size=%dx%d total_ms=%d" % [path, err, img.get_width(), img.get_height(), Time.get_ticks_msec() - t0])
	get_tree().quit()
