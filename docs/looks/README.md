# Neon Static look test: one street, one camera, one preset per look
Preset = `godot/looks/<ID>.gd` returning a Dictionary; missing keys fall back to DEFAULTS in `godot/scripts/look.gd`. Copy `N.gd` (lists every field) to start a new look.
Field groups (full per-field notes in `FIELDS.md`):
- Exposure/tonemap/glow: `exposure tonemap tonemap_white agx_contrast glow glow_intensity glow_strength glow_bloom glow_threshold glow_hdr_scale glow_blend glow_levels`
- Sky/ambient: `sky_zenith sky_horizon sky_glow sky_glow_energy dawn_color dawn_energy dawn_dir cloud_amount cloud_color ambient_color ambient_energy fill_color fill_energy ssao ssil ssr reflection_probes`
- Fog/haze/steam: `fog_density fog_albedo fog_emission fog_anisotropy haze_density haze_color mist_density mist_color steam_amount steam_density steam_color`
- Rain/wetness: `rain_amount rain_color rain_alpha rain_light splash_amount wetness puddles`
- Lamps/lights: `lamp_color lamp_energy lamp_fog lamp_spacing shop_color shop_energy shop_open_ratio sign_light_energy car_head_color car_tail_color traffic parked_cars signal_state`
- Signs/screens: `neon_colors sign_panel_colors sign_density sign_brightness sign_off_ratio big_words neon_word_count screen_colors billboard_count holo_colors holo_count led_color tower_led`
- Windows/materials: `window_lit window_tints window_brightness tower_window_lit concrete_tint brick_tint tile_tint panel_tint grime asphalt_color facade_styles`
- Dressing toggles: `lanterns lantern_rows lantern_color pipes clutter ac_units cables fire_escapes awnings rooftop tower_style tower_count train skybridge`
- Final grade: `grade_saturation grade_contrast grade_gamma grade_lift grade_gain grade_shadow_tint grade_highlight_tint grade_keep_hue grade_keep_width grade_vignette grade_grain`
Render (from the project folder; goes through tools/gslot.sh): `sh tools/render_looks.sh N` -> `neutral.png`, `sh tools/render_looks.sh A` -> `look_A.png`, `sh tools/render_looks.sh all` -> every preset + `contact_sheet.png`.
Options: `FRAMES=150 SS=1.5 W=1920 H=1080` (draft: `FRAMES=60 SS=1.0`). About 30 s per look plus the slot wait; an empty log in `build/logs` means a slot time-out, run again.
Rendering needs a real window (Forward+), never --headless. Sign words are invented; keep them that way.
