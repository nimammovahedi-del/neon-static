# Look CX "Acid Cyber": Acid Industrial pushed towards cyberpunk: dense neon and holograms, heavy rain, mirror-wet road, magenta accents against the acid green.
extends RefCounted

static func get_preset() -> Dictionary:
	var p: Dictionary = preload("res://looks/C.gd").get_preset()
	p.merge({
		"name": "Acid Cyber",
		"fog_density": 0.014,
		"haze_density": 0.0025,
		"mist_density": 0.03,
		"steam_amount": 1.4,
		"rain_amount": 1.8,
		"rain_alpha": 0.42,
		"rain_light": 3.0,
		"splash_amount": 1.8,
		"wetness": 1.0,
		"puddles": 0.95,
		"ambient_energy": 0.22,
		"sign_light_energy": 2.2,
		"neon_colors": [Color(0.55, 1.0, 0.05), Color(1.0, 0.9, 0.05), Color(1.0, 0.05, 0.6), Color(0.2, 1.0, 0.25), Color(0.05, 0.9, 1.0)],
		"sign_density": 1.8,
		"sign_off_ratio": 0.03,
		"neon_word_count": 1.6,
		"screen_colors": [[Color(0.05, 0.1, 0.0), Color(0.6, 1.0, 0.1), Color(1.0, 0.1, 0.65)], [Color(0.1, 0.0, 0.12), Color(1.0, 0.1, 0.65), Color(0.7, 1.0, 0.1)]],
		"billboard_count": 1.5,
		"holo_colors": [Color(0.6, 1.0, 0.1), Color(1.0, 0.15, 0.7)],
		"holo_count": 1.6,
		"tower_led": 1.0,
		"window_lit": 0.3,
		"glow_intensity": 1.0,
		"grade_saturation": 1.2,
		"grade_contrast": 1.1,
	}, true)
	return p
