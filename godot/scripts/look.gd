# Look presets: every visual difference between looks lives in ONE file per look, godot/looks/<ID>.gd,
# which returns a Dictionary from a static func get_preset(). Missing keys fall back to DEFAULTS
# below, so a preset may list only what it changes (the neutral preset N lists everything).
# Field meanings are documented in docs/looks/FIELDS.md.
extends RefCounted

const DEFAULTS := {
	"id": "N",
	"name": "Neutral",

	# ---- camera exposure, tonemap, glow (Environment)
	"exposure": 1.0,
	"tonemap": "agx",            # agx | filmic | aces | reinhard | linear
	"tonemap_white": 6.0,        # white point (filmic/aces/reinhard) / AgX white
	"agx_contrast": 1.0,
	"glow": true,
	"glow_intensity": 0.8,
	"glow_strength": 1.0,
	"glow_bloom": 0.04,
	"glow_threshold": 0.9,
	"glow_hdr_scale": 2.0,
	"glow_blend": "screen",      # additive | screen | softlight | replace | mix
	"glow_mix": 0.05,            # only for blend "mix"
	"glow_levels": [0.0, 0.5, 0.9, 1.0, 0.8, 0.5, 0.25],   # levels 1..7

	# ---- sky, ambient, fill light
	"sky_zenith": Color(0.01, 0.012, 0.03),
	"sky_horizon": Color(0.06, 0.05, 0.09),
	"sky_glow": Color(0.42, 0.18, 0.4),
	"sky_glow_energy": 2.4,
	"sky_glow_height": 0.16,
	"sky_energy": 1.0,
	"dawn_color": Color(1.0, 0.45, 0.15),  # directional horizon glow (predawn look)
	"dawn_energy": 0.0,
	"dawn_dir": Vector3(0.0, 0.0, -1.0),
	"dawn_width": 0.6,
	"cloud_amount": 0.55,
	"cloud_color": Color(0.22, 0.14, 0.26),
	"cloud_energy": 1.5,
	"ambient_color": Color(0.16, 0.16, 0.24),
	"ambient_energy": 0.35,
	"ambient_sky": 0.0,          # 0 = flat ambient colour, 1 = ambient from the sky
	"reflection_energy": 1.0,   # strength of the street reflection probes
	"fill_color": Color(0.5, 0.55, 0.8),   # weak directional "sky" light from above
	"fill_energy": 0.04,
	"ssao": 1.2,                 # SSAO intensity (0 = off)
	"ssil": 0.6,                 # SSIL intensity (0 = off)
	"ssr": true,
	"reflection_probes": true,   # box-projected probes along the street (wet road reflections off-screen)
	"sdfgi": false,
	"sdfgi_energy": 1.0,

	# ---- fog and haze
	"fog_density": 0.015,        # volumetric fog density
	"fog_albedo": Color(0.7, 0.72, 0.85),
	"fog_emission": Color(0.04, 0.03, 0.06),
	"fog_emission_energy": 0.25,
	"fog_anisotropy": 0.55,
	"fog_length": 180.0,
	"fog_detail_spread": 1.6,
	"fog_ambient_inject": 0.12,
	"fog_sky_affect": 0.6,
	"haze_density": 0.0016,      # classic depth/height fog for the far distance
	"haze_color": Color(0.13, 0.1, 0.2),
	"haze_energy": 1.0,
	"haze_height": 30.0,
	"haze_height_density": 0.0,
	"haze_sky_affect": 0.3,
	"haze_aerial": 0.4,
	"mist_density": 0.035,        # low ground mist FogVolume over the street
	"mist_height": 1.1,
	"mist_color": Color(0.75, 0.75, 0.85),
	"steam_amount": 1.0,         # 0 = none, 2 = lots of plumes
	"steam_density": 3.0,
	"steam_glow": 0.04,          # self-illumination of steam (keeps plumes from going dark)
	"steam_light": 0.5,          # energy of the light under each nearby plume
	"steam_color": Color(0.9, 0.9, 0.95),

	# ---- rain and wetness
	"rain_amount": 1.0,          # 0 = dry air, 2 = downpour
	"rain_color": Color(0.7, 0.75, 0.85),
	"rain_alpha": 0.38,
	"rain_light": 2.5,           # how much lamps/signs light up the drops
	"rain_length": 0.6,
	"splash_amount": 1.0,
	"wetness": 0.9,              # 0 dry .. 1 soaked (roughness, darkening)
	"puddles": 0.7,              # puddle coverage on road and sidewalk

	# ---- street lamps and other lights
	"lamp_color": Color(1.0, 0.72, 0.45),
	"lamp_energy": 7.0,          # SpotLight energy
	"lamp_lens_energy": 1.2,     # multiplier for the glowing lamp head
	"lamp_fog": 3.5,             # volumetric fog energy of lamp lights (light shafts)
	"lamp_range": 17.0,
	"lamp_angle": 52.0,
	"lamp_shadows": 6,           # how many nearest lamps cast shadows
	"lamp_spacing": 26.0,
	"shop_color": Color(1.0, 0.88, 0.72),
	"shop_energy": 2.2,          # emission of shop interiors
	"shop_light_energy": 1.6,    # light that shops spill onto the sidewalk
	"shop_open_ratio": 0.75,     # open, lit shops vs shuttered
	"sign_light_energy": 1.4,    # coloured light thrown by signs
	"sign_light_fog": 1.5,
	"sign_light_range": 7.0,
	"car_head_color": Color(0.85, 0.92, 1.0),
	"car_tail_color": Color(1.0, 0.03, 0.02),
	"car_light_energy": 3.0,
	"car_paint_colors": [Color(0.03, 0.08, 0.1), Color(0.35, 0.37, 0.4), Color(0.14, 0.02, 0.03), Color(0.02, 0.03, 0.06), Color(0.6, 0.42, 0.04), Color(0.55, 0.56, 0.58)],
	"traffic": 1.0,              # moving cars with lights (0..2)
	"parked_cars": 1.0,
	"blinker_color": Color(1.0, 0.05, 0.02),
	"signal_state": "red",       # red | green | amber

	# ---- signs, neon, screens, holograms
	"neon_colors": [Color(1.0, 0.1, 0.55), Color(0.1, 0.85, 1.0), Color(1.0, 0.55, 0.08), Color(0.65, 0.2, 1.0), Color(0.2, 1.0, 0.5)],
	"sign_panel_colors": [Color(0.04, 0.02, 0.06), Color(0.9, 0.85, 0.75), Color(0.02, 0.04, 0.06)],
	"sign_density": 1.0,         # 0..2 multiplier for blade/box signs
	"sign_brightness": 1.0,
	"sign_off_ratio": 0.08,      # broken/unlit signs
	"sign_reach": 1.0,           # how far blade signs reach out over the sidewalk (scale)
	"big_words": ["HOTEL", "RAMEN", "NOVA", "PAWN", "24H", "DATA", "MOTEL", "LUX"],
	"neon_word_count": 1.0,      # big neon tube words on facades and roofs (multiplier)
	"screen_colors": [[Color(0.2, 0.0, 0.35), Color(1.0, 0.25, 0.75), Color(0.1, 0.8, 1.0)], [Color(0.0, 0.1, 0.25), Color(0.2, 0.9, 1.0), Color(1.0, 0.6, 0.1)]],
	"screen_brightness": 1.0,
	"billboard_count": 1.0,      # big LED screens on walls and roofs (multiplier)
	"billboard_scale": 1.0,
	"holo_colors": [Color(0.2, 0.9, 1.0), Color(1.0, 0.3, 0.8)],
	"holo_count": 1.0,
	"holo_opacity": 0.6,
	"led_color": Color(0.2, 0.85, 1.0),
	"led_energy": 3.0,
	"tower_led": 1.0,            # LED strips on megatowers (0 = off)

	# ---- windows
	"window_lit": 0.36,
	"window_tints": [Color(1.0, 0.82, 0.6), Color(1.0, 0.9, 0.75), Color(0.75, 0.88, 1.0), Color(1.0, 0.6, 0.45), Color(0.6, 0.9, 0.85), Color(1.0, 0.5, 0.8)],
	"window_brightness": 0.9,
	"window_blinds": 0.55,
	"tower_window_lit": 1.0,     # multiplier for tower windows
	"tower_window_brightness": 2.4,

	# ---- materials
	"concrete_tint": Color(0.4, 0.39, 0.38),
	"brick_tint": Color(0.36, 0.17, 0.12),
	"tile_tint": Color(0.45, 0.52, 0.5),
	"panel_tint": Color(0.26, 0.29, 0.31),
	"grime": 0.6,
	"asphalt_color": Color(0.065, 0.065, 0.07),
	"paving_color": Color(0.22, 0.215, 0.21),
	"marking_white": Color(0.85, 0.85, 0.82),
	"marking_yellow": Color(0.85, 0.6, 0.1),
	"facade_styles": {"concrete": 1.0, "brick": 1.0, "tile": 1.0, "panel": 0.8, "glass": 0.25},

	# ---- dressing toggles
	"lanterns": false,
	"lantern_rows": 4,
	"lantern_color": Color(1.0, 0.25, 0.1),
	"pipes": 1.0,                # exposed pipes on facades (0..2)
	"clutter": 1.0,              # bins, boxes, bags, AC units (0..2)
	"ac_units": 1.0,
	"cables": 1.0,               # overhead cables (0..2)
	"fire_escapes": 1.0,
	"awnings": 1.0,
	"rooftop": "mixed",          # mixed | industrial | corporate
	"tower_style": "mixed",      # mixed | glass | industrial
	"tower_count": 1.0,
	"train": true,
	"skybridge": true,

	# ---- final colour grade (after tonemapping)
	"grade_saturation": 1.0,
	"grade_contrast": 1.0,
	"grade_gamma": 1.0,
	"grade_lift": Color(0.0, 0.0, 0.0),
	"grade_gain": Color(1.0, 1.0, 1.0),
	"grade_shadow_tint": Color(1.0, 1.0, 1.0),
	"grade_highlight_tint": Color(1.0, 1.0, 1.0),
	"grade_split": 0.0,
	"grade_keep_hue": 0.0,       # 0..1 hue kept in colour when saturation is low (0 = red)
	"grade_keep_width": 0.0,     # 0 = off
	"grade_keep_saturation": 1.0,
	"grade_vignette": 0.3,
	"grade_grain": 0.02,
	"grade_chroma": 0.0,
}


static func load_preset(id: String) -> Dictionary:
	var path := "res://looks/%s.gd" % id
	var p := DEFAULTS.duplicate(true)
	if not ResourceLoader.exists(path):
		push_error("look preset not found: " + path)
		return p
	var scr: GDScript = load(path)
	var d: Dictionary = scr.get_preset()
	for k in d.keys():
		if not DEFAULTS.has(k):
			push_warning("look %s: unknown preset key '%s'" % [id, k])
		p[k] = d[k]
	p["id"] = id
	return p


static func list_ids() -> PackedStringArray:
	var out := PackedStringArray()
	var dir := DirAccess.open("res://looks")
	if dir:
		for f in dir.get_files():
			if f.ends_with(".gd"):
				out.append(f.get_basename())
	out.sort()
	return out
