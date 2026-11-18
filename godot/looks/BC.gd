# Look BC "Sodium Acid": Sodium Noir's darkness and amber lamps, with Acid Industrial's green haze, steam, pipes and industrial rooftops.
extends RefCounted

static func get_preset() -> Dictionary:
	var p: Dictionary = preload("res://looks/B.gd").get_preset()
	p.merge({
		"name": "Sodium Acid",
		"sky_glow": Color(0.3, 0.36, 0.08),
		"sky_glow_energy": 1.8,
		"cloud_color": Color(0.14, 0.17, 0.05),
		"ambient_color": Color(0.07, 0.13, 0.06),
		"fog_albedo": Color(0.75, 0.8, 0.45),
		"fog_emission": Color(0.025, 0.035, 0.0),
		"fog_density": 0.018,
		"haze_color": Color(0.1, 0.13, 0.04),
		"mist_color": Color(0.65, 0.8, 0.4),
		"mist_density": 0.04,
		"steam_amount": 1.8,
		"steam_density": 3.5,
		"steam_color": Color(0.8, 0.95, 0.45),
		"neon_colors": [Color(0.55, 1.0, 0.05), Color(1.0, 0.45, 0.1), Color(0.85, 1.0, 0.1)],
		"sign_density": 0.5,
		"led_color": Color(0.6, 1.0, 0.05),
		"grime": 1.4,
		"facade_styles": {"concrete": 1.0, "brick": 1.5, "tile": 0.2, "panel": 2.0, "glass": 0.0},
		"pipes": 2.0,
		"clutter": 1.8,
		"ac_units": 1.8,
		"cables": 2.0,
		"rooftop": "industrial",
		"tower_style": "industrial",
		"grade_shadow_tint": Color(0.8, 1.08, 0.75),
	}, true)
	return p
