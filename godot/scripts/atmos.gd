# Atmosphere and rendering setup from the look preset: Environment (tonemap, glow, SSR, SSAO,
# SSIL, SDFGI, volumetric fog, depth haze), sky shader, fill light, ground mist and steam
# FogVolumes, rain streak + splash particles, and the final colour grade layer.
extends RefCounted

var P: Dictionary
var mats
var env: Environment


func _init(preset: Dictionary, mats_) -> void:
	P = preset
	mats = mats_


const TONEMAPS := {"linear": 0, "reinhard": 1, "filmic": 2, "aces": 3, "agx": 4}
const GLOW_BLEND := {"additive": 0, "screen": 1, "softlight": 2, "replace": 3, "mix": 4}


func make_environment() -> Environment:
	env = Environment.new()
	# sky
	var sky_mat := ShaderMaterial.new()
	sky_mat.shader = load("res://shaders/sky.gdshader")
	sky_mat.set_shader_parameter("zenith", P.sky_zenith)
	sky_mat.set_shader_parameter("horizon", P.sky_horizon)
	sky_mat.set_shader_parameter("glow_color", P.sky_glow)
	sky_mat.set_shader_parameter("glow_energy", float(P.sky_glow_energy))
	sky_mat.set_shader_parameter("glow_height", float(P.sky_glow_height))
	sky_mat.set_shader_parameter("dir_glow_dir", P.dawn_dir)
	sky_mat.set_shader_parameter("dir_glow_color", P.dawn_color)
	sky_mat.set_shader_parameter("dir_glow_energy", float(P.dawn_energy))
	sky_mat.set_shader_parameter("dir_glow_width", float(P.dawn_width))
	sky_mat.set_shader_parameter("cloud_amount", float(P.cloud_amount))
	sky_mat.set_shader_parameter("cloud_color", P.cloud_color)
	sky_mat.set_shader_parameter("cloud_energy", float(P.cloud_energy))
	sky_mat.set_shader_parameter("cloud_noise", mats.cloud_tex)
	sky_mat.set_shader_parameter("energy", float(P.sky_energy))
	var sky := Sky.new()
	sky.sky_material = sky_mat
	sky.radiance_size = Sky.RADIANCE_SIZE_256
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	# ambient + reflections
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR if float(P.ambient_sky) <= 0.0 else Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = P.ambient_color
	env.ambient_light_energy = float(P.ambient_energy)
	env.ambient_light_sky_contribution = float(P.ambient_sky)
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	# tonemap
	env.tonemap_mode = TONEMAPS.get(P.tonemap, 4)
	env.tonemap_exposure = float(P.exposure)
	env.tonemap_white = float(P.tonemap_white)
	env.tonemap_agx_white = float(P.tonemap_white)
	env.tonemap_agx_contrast = float(P.agx_contrast)
	# glow
	env.glow_enabled = bool(P.glow)
	env.glow_intensity = float(P.glow_intensity)
	env.glow_strength = float(P.glow_strength)
	env.glow_bloom = float(P.glow_bloom)
	env.glow_hdr_threshold = float(P.glow_threshold)
	env.glow_hdr_scale = float(P.glow_hdr_scale)
	env.glow_blend_mode = GLOW_BLEND.get(P.glow_blend, 1)
	env.glow_mix = float(P.glow_mix)
	var lv: Array = P.glow_levels
	for i in 7:
		env.set("glow_levels/%d" % (i + 1), float(lv[i]) if i < lv.size() else 0.0)
	# screen-space effects
	env.ssr_enabled = bool(P.ssr)
	env.ssr_max_steps = 128
	env.ssr_fade_in = 0.08
	env.ssr_fade_out = 1.6
	env.ssr_depth_tolerance = 0.4
	env.ssao_enabled = float(P.ssao) > 0.0
	env.ssao_intensity = float(P.ssao)
	env.ssao_radius = 1.4
	env.ssao_power = 1.4
	env.ssao_light_affect = 0.15
	env.ssil_enabled = float(P.ssil) > 0.0
	env.ssil_intensity = float(P.ssil)
	env.ssil_radius = 6.0
	env.sdfgi_enabled = bool(P.sdfgi)
	env.sdfgi_energy = float(P.sdfgi_energy)
	env.sdfgi_use_occlusion = true
	env.sdfgi_cascades = 6
	env.sdfgi_min_cell_size = 0.3
	# volumetric fog
	env.volumetric_fog_enabled = float(P.fog_density) > 0.0
	env.volumetric_fog_density = float(P.fog_density)
	env.volumetric_fog_albedo = P.fog_albedo
	env.volumetric_fog_emission = P.fog_emission
	env.volumetric_fog_emission_energy = float(P.fog_emission_energy)
	env.volumetric_fog_anisotropy = float(P.fog_anisotropy)
	env.volumetric_fog_length = float(P.fog_length)
	env.volumetric_fog_detail_spread = float(P.fog_detail_spread)
	env.volumetric_fog_ambient_inject = float(P.fog_ambient_inject)
	env.volumetric_fog_sky_affect = float(P.fog_sky_affect)
	env.volumetric_fog_temporal_reprojection_enabled = true
	env.volumetric_fog_temporal_reprojection_amount = 0.9
	# distance haze (non-volumetric fog, reaches the far towers)
	env.fog_enabled = float(P.haze_density) > 0.0
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.fog_light_color = P.haze_color
	env.fog_light_energy = float(P.haze_energy)
	env.fog_density = float(P.haze_density)
	env.fog_height = float(P.haze_height)
	env.fog_height_density = float(P.haze_height_density)
	env.fog_sky_affect = float(P.haze_sky_affect)
	env.fog_aerial_perspective = float(P.haze_aerial)
	env.fog_sun_scatter = 0.0
	# adjustments are left to the grade layer
	env.adjustment_enabled = false
	return env


func build(root: Node3D, steam_spots: Array, cam: Camera3D) -> void:
	var we := WorldEnvironment.new()
	we.environment = make_environment()
	root.add_child(we)
	# weak fill light from the sky so unlit forms still read
	var fill := DirectionalLight3D.new()
	fill.light_color = P.fill_color
	fill.light_energy = float(P.fill_energy)
	fill.light_volumetric_fog_energy = 0.0
	fill.shadow_enabled = false
	fill.rotation_degrees = Vector3(-70.0, 25.0, 0.0)
	fill.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	root.add_child(fill)
	_mist(root)
	_steam(root, steam_spots)
	_rain(root, cam)
	if bool(P.reflection_probes):
		_probes(root)


func _probes(root: Node3D) -> void:
	# Box-projected probes along the canyon: the wet road and glass pick up signs that are
	# outside the screen (SSR only sees what is on screen).
	for z in [-14.0, -48.0, -100.0, -170.0]:
		var rp := ReflectionProbe.new()
		rp.size = Vector3(22.4, 40.0, 36.0 if z > -60.0 else 70.0)
		rp.position = Vector3(0.0, 19.0, z)
		rp.origin_offset = Vector3(0.0, -15.0, 0.0)
		rp.box_projection = true
		rp.update_mode = ReflectionProbe.UPDATE_ONCE
		rp.intensity = float(P.reflection_energy)
		rp.max_distance = 400.0
		rp.ambient_mode = ReflectionProbe.AMBIENT_DISABLED
		rp.enable_shadows = false
		rp.blend_distance = 4.0
		root.add_child(rp)


func _mist(root: Node3D) -> void:
	if float(P.mist_density) <= 0.0:
		return
	var fv := FogVolume.new()
	fv.shape = RenderingServer.FOG_VOLUME_SHAPE_BOX
	fv.size = Vector3(30.0, 8.0, 300.0)
	fv.position = Vector3(0.0, 3.0, -140.0)
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/fog_mist.gdshader")
	m.set_shader_parameter("noise3d", mats.noise3d)
	m.set_shader_parameter("density", float(P.mist_density))
	m.set_shader_parameter("height", float(P.mist_height))
	m.set_shader_parameter("albedo", P.mist_color)
	fv.material = m
	root.add_child(fv)


func _steam(root: Node3D, spots: Array) -> void:
	var amt := float(P.steam_amount)
	if amt <= 0.0:
		return
	var r := RandomNumberGenerator.new()
	r.seed = 3
	var shader: Shader = load("res://shaders/fog_plume.gdshader")
	var n := int(round(spots.size() * clampf(amt, 0.0, 1.0)))
	for i in n:
		var p: Vector3 = spots[i]
		var big := amt > 1.0
		var fv := FogVolume.new()
		fv.shape = RenderingServer.FOG_VOLUME_SHAPE_BOX
		var h := r.randf_range(4.5, 8.0) * (1.4 if big else 1.0)
		var w := r.randf_range(1.8, 2.6) * (1.3 if big else 1.0)
		fv.size = Vector3(w, h, w)
		fv.position = p + Vector3(0.0, h * 0.5 - 0.3, 0.0)
		var m := ShaderMaterial.new()
		m.shader = shader
		m.set_shader_parameter("noise3d", mats.noise3d)
		m.set_shader_parameter("density", float(P.steam_density) * clampf(amt, 0.3, 2.0))
		m.set_shader_parameter("albedo", P.steam_color)
		var sc: Color = P.steam_color
		m.set_shader_parameter("emission", sc * float(P.steam_glow))
		m.set_shader_parameter("seed", r.randf_range(0.0, 10.0))
		m.set_shader_parameter("rise", r.randf_range(0.4, 0.8))
		fv.material = m
		root.add_child(fv)
		# billowing steam puffs (particles) so the plume reads as rising steam up close
		if p.distance_to(Vector3(7.75, 1.85, 0.0)) < 110.0:
			_steam_particles(root, p, amt, r)
		# a light just above the vent makes the plume glow like street light caught in it
		if float(P.steam_light) > 0.0 and p.distance_to(Vector3(7.75, 1.85, 0.0)) < 90.0:
			var l := OmniLight3D.new()
			l.light_color = P.lamp_color.lerp(P.steam_color, 0.5)
			l.light_energy = float(P.steam_light)
			l.omni_range = h * 0.6
			l.light_volumetric_fog_energy = 1.2
			l.light_specular = 0.2
			l.position = p + Vector3(0.0, 0.6, 0.0)
			root.add_child(l)


func _steam_particles(root: Node3D, p: Vector3, amt: float, r: RandomNumberGenerator) -> void:
	var ps := GPUParticles3D.new()
	ps.amount = int(36 * clampf(amt, 0.3, 2.0))
	ps.lifetime = r.randf_range(4.5, 6.5)
	ps.preprocess = 8.0
	ps.randomness = 0.6
	ps.local_coords = false
	ps.visibility_aabb = AABB(Vector3(-6, -1, -6), Vector3(12, 14, 12))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(0.45, 0.05, 0.3)
	pm.direction = Vector3(0.12, 1.0, 0.0)
	pm.spread = 14.0
	pm.initial_velocity_min = 0.7
	pm.initial_velocity_max = 1.3
	pm.gravity = Vector3(0.15, 0.25, 0.0)
	pm.damping_min = 0.1
	pm.damping_max = 0.3
	pm.scale_min = 0.9
	pm.scale_max = 1.5
	var sc := Curve.new()
	sc.add_point(Vector2(0.0, 0.5))
	sc.add_point(Vector2(1.0, 3.2))
	var sct := CurveTexture.new()
	sct.curve = sc
	pm.scale_curve = sct
	pm.angle_min = 0.0
	pm.angle_max = 360.0
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.6
	pm.turbulence_noise_scale = 3.0
	ps.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(1.6, 1.6)
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/smoke.gdshader")
	m.set_shader_parameter("tint", P.steam_color)
	m.set_shader_parameter("alpha_mul", 0.28 * clampf(amt, 0.4, 1.6))
	m.set_shader_parameter("self_glow", float(P.steam_glow) * 0.6)
	q.material = m
	ps.draw_pass_1 = q
	ps.position = p + Vector3(0.0, 0.05, 0.0)
	ps.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(ps)


func _rain(root: Node3D, cam: Camera3D) -> void:
	var amt := float(P.rain_amount)
	if amt <= 0.0:
		return
	var cp := cam.global_position
	var rain := GPUParticles3D.new()
	rain.amount = int(26000 * amt)
	rain.lifetime = 2.2
	rain.preprocess = 3.0
	rain.fixed_fps = 60
	rain.explosiveness = 0.0
	rain.randomness = 1.0
	rain.local_coords = false
	rain.transform_align = GPUParticles3D.TRANSFORM_ALIGN_DISABLED
	rain.visibility_aabb = AABB(Vector3(-40, -40, -100), Vector3(80, 80, 120))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(16.0, 2.0, 30.0)
	pm.direction = Vector3(0.12, -1.0, 0.05)
	pm.spread = 3.0
	pm.initial_velocity_min = 11.0
	pm.initial_velocity_max = 14.0
	pm.gravity = Vector3(0, -2.0, 0)
	pm.particle_flag_align_y = true
	pm.scale_min = 0.7
	pm.scale_max = 1.3
	rain.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(1.0, 1.0)
	var rm := ShaderMaterial.new()
	rm.shader = load("res://shaders/rain.gdshader")
	rm.set_shader_parameter("tint", P.rain_color)
	rm.set_shader_parameter("alpha_mul", float(P.rain_alpha))
	rm.set_shader_parameter("light_gain", float(P.rain_light))
	rm.set_shader_parameter("length_scale", float(P.rain_length))
	q.material = rm
	rain.draw_pass_1 = q
	rain.position = Vector3(cp.x - 4.0, cp.y + 24.0, cp.z - 26.0)
	rain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(rain)
	# a second, sparser far layer so rain keeps going down the street
	var far: GPUParticles3D = rain.duplicate()
	far.amount = int(14000 * amt)
	var pm2: ParticleProcessMaterial = pm.duplicate()
	pm2.emission_box_extents = Vector3(18.0, 3.0, 60.0)
	far.process_material = pm2
	far.position = Vector3(cp.x - 4.0, cp.y + 26.0, cp.z - 110.0)
	far.visibility_aabb = AABB(Vector3(-40, -50, -80), Vector3(80, 90, 160))
	root.add_child(far)
	# splashes on the ground near the camera
	if float(P.splash_amount) > 0.0:
		var sp := GPUParticles3D.new()
		sp.amount = int(2500 * amt * float(P.splash_amount))
		sp.lifetime = 0.25
		sp.preprocess = 1.0
		sp.local_coords = false
		sp.visibility_aabb = AABB(Vector3(-20, -2, -40), Vector3(40, 6, 50))
		var spm := ParticleProcessMaterial.new()
		spm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		spm.emission_box_extents = Vector3(10.0, 0.0, 22.0)
		spm.gravity = Vector3.ZERO
		spm.initial_velocity_min = 0.0
		spm.initial_velocity_max = 0.0
		spm.scale_min = 0.035
		spm.scale_max = 0.08
		sp.process_material = spm
		var sq := QuadMesh.new()
		var sm := ShaderMaterial.new()
		sm.shader = load("res://shaders/splash.gdshader")
		sm.set_shader_parameter("tint", P.rain_color)
		sm.set_shader_parameter("alpha_mul", float(P.rain_alpha) * 0.7)
		sm.set_shader_parameter("light_gain", float(P.rain_light))
		sq.material = sm
		sp.draw_pass_1 = sq
		sp.position = Vector3(0.0, 0.02, cp.z - 20.0)
		sp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(sp)


func grade_layer() -> CanvasLayer:
	var cl := CanvasLayer.new()
	var cr := ColorRect.new()
	cr.set_anchors_preset(Control.PRESET_FULL_RECT)
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/grade.gdshader")
	m.set_shader_parameter("saturation", float(P.grade_saturation))
	m.set_shader_parameter("contrast", float(P.grade_contrast))
	m.set_shader_parameter("gamma", float(P.grade_gamma))
	m.set_shader_parameter("lift", P.grade_lift)
	m.set_shader_parameter("gain", P.grade_gain)
	m.set_shader_parameter("shadow_tint", P.grade_shadow_tint)
	m.set_shader_parameter("highlight_tint", P.grade_highlight_tint)
	m.set_shader_parameter("split_amount", float(P.grade_split))
	m.set_shader_parameter("keep_hue", float(P.grade_keep_hue))
	m.set_shader_parameter("keep_width", float(P.grade_keep_width))
	m.set_shader_parameter("keep_saturation", float(P.grade_keep_saturation))
	m.set_shader_parameter("vignette", float(P.grade_vignette))
	m.set_shader_parameter("grain", float(P.grade_grain))
	m.set_shader_parameter("chroma", float(P.grade_chroma))
	cr.material = m
	cl.add_child(cr)
	return cl
