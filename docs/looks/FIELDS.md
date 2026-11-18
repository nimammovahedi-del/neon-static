# Neon Static: look test (stage 1)

One fixed street, one fixed camera, one preset file per look. Everything that differs between
looks lives in `godot/looks/<ID>.gd`. This file explains how the scene is built, every preset
field, the dressing toggles and the exact render commands, so the eight looks (A to H) can be tuned
from the presets alone.

Files in this folder:

| File | What it is |
|---|---|
| `neutral.png` | look N (the reference), 2560x1440 |
| `kit_sheet.png` | every kit piece in a studio setup, rendered with look N materials |
| `look_<ID>.png` | the looks you render (A..H) |
| `contact_sheet.png` | all rendered looks side by side (made by `render_looks.sh all`) |

## 1. Render commands

Run from the project folder `/Users/nimamovahedi/Projects/neon-static`:

```sh
sh tools/render_looks.sh N            # -> docs/looks/neutral.png
sh tools/render_looks.sh A            # -> docs/looks/look_A.png   (preset godot/looks/A.gd)
sh tools/render_looks.sh A B C        # several looks
sh tools/render_looks.sh all          # every preset in godot/looks + docs/looks/contact_sheet.png
sh tools/render_looks.sh kit          # -> docs/looks/kit_sheet.png
```

Options (environment variables, put them in front of the command):

| Variable | Default | Meaning |
|---|---|---|
| `FRAMES` | 150 | frames the scene runs before the capture (volumetric fog, particles, reflections settle) |
| `SS` | 1.5 | 3D supersampling (render scale). 1.0 for quick drafts, 1.5 final, 2.0 is very heavy |
| `W`, `H` | 1920, 1080 | output size |
| `OUT_DIR` | docs/looks | where PNGs go |

Fast draft: `FRAMES=60 SS=1.0 W=1280 H=720 sh tools/render_looks.sh A` (about 10 s of rendering).
A final 2560x1440 frame takes about 40 s plus the wait for a Godot slot.

How it works: the script first runs `godot --headless --path godot --import` (needed after any change
to GLBs, textures or new scripts), then for each look runs Godot in a window:
`godot --path godot --windowed --resolution 1280x720 -- look=<ID> out=<png> frames=<n> w=<w> h=<h> ss=<s>`.
The scene renders into a 2560x1440 SubViewport (the window only shows a preview), waits `frames`
frames and saves the PNG. Logs go to `build/logs/look_<ID>.log`; the script prints the lines with
`LOOK`, `BUILD`, `FPS`, `SAVED` and any errors.

Machine rule: every Godot run goes through `tools/gslot.sh` (a copy of Umbara's slot script that uses
the same lock folder `$TMPDIR/umbara-gslots`), so at most two Godot copies run on this Mac at once.
If a render prints "no image" and its log is empty, the slot wait timed out: run it again.

To look at a preset interactively (no capture): `sh tools/gslot.sh 600 godot --path godot -- look=A`.

## 2. Folder map

```
godot/project.godot          Forward+, shader globals, render quality settings
godot/scenes/street.tscn     one Node with scripts/main.gd
godot/looks/N.gd             the neutral preset (lists every field). Add A.gd ... H.gd here.
godot/scripts/main.gd        reads look=/out=/frames=..., SubViewport + fixed camera, capture
godot/scripts/look.gd        DEFAULTS (fallback for every field) + preset loader
godot/scripts/street.gd      the street assembler (layout, buildings, props, cars, rail, towers)
godot/scripts/signs.gd       blade/box signs, fascias, neon tube words, LED screens, holograms
godot/scripts/atmos.gd       Environment, sky, fog volumes, steam, rain, probes, colour grade
godot/scripts/mats.gd        material library (by Blender material name) + global shader uniforms
godot/scripts/kit.gd         loads kit GLBs and swaps their materials
godot/scripts/kit_sheet.gd   kit sheet mode (mode=kit)
godot/shaders/*.gdshader     all materials are procedural shaders (see section 4)
godot/assets/kit/*.glb       the model kit (generated, do not edit by hand)
godot/assets/tex/*.png       generated sign / billboard mask art
tools/blender/               kit generator (kitlib.py + kit_*.py, build_kit.py, preview.py, glyphs.py)
tools/gen_textures.py        regenerates godot/assets/tex
tools/render_looks.sh        the renderer;  tools/kit_sheet.py, tools/contact_sheet.py assemble sheets
tools/gslot.sh               the shared Godot slot limiter
```

## 3. The scene

**Camera (fixed, `main.gd`)**: position (7.75, 1.85, 0): right-hand sidewalk near the kerb, eye
1.7 m above the sidewalk; yaw 5.5 degrees left, pitch 6.5 degrees up, vertical FOV 62. Do not change
it per look.

**Street layout (fixed, `street.gd`)**: the street runs along -Z. Road |x| < 7 m (two lanes each
way, dashed lane lines, double yellow centre line), sidewalks 7..11 m at +0.15 m, building line at
|x| = 11. Mid-block crosswalk at z -34..-30 with traffic lights and bollards; a cross street junction
at z -100..-84 under the elevated rail (deck top 13 m, a three-car train on it); a pedestrian
skybridge at z -150 (21 m up); lots continue to z -262, then a plaza and the megatowers.

Every lot is a `Node3D` whose local frame is: x along the facade, y up, z out of the wall. A lot has:
a building mass box (side/back walls with a window-grid shader), a ground floor of 4 m shopfront
modules (shops, food counter, shutters, entry, service wall), storeys of 4 x 3.5 m facade modules in
column patterns, a parapet, and dressing (signs, AC units, pipes, conduits, fire escapes, awnings,
screens, holograms, roof clutter, roof billboards / neon word frames). Behind the street front stand
"back row" blocks (40-150 m) and eleven megatowers 170-700 m away.

**Same street in every look**: lot widths, heights, depths, setbacks and the module columns come from
fixed random seeds. Each dressing feature (blade signs, wall boxes, neon words, screens, holograms,
awnings, AC units, pipes, conduits, fire escapes, roof clutter, roof signs) has its OWN random stream
per lot, so changing one density in a preset never moves the others. The facade style per lot is
picked from `facade_styles` weights, so changing those weights does change which style a lot gets
(intended: E wants glass, C wants panel/brick).

**Lights**: about 280 real lights within 140 m of the camera: street lamps (SpotLights, the nearest
`lamp_shadows` cast soft shadows), one coloured OmniLight per lit sign, shop spill lights, the
vending machines, car head/tail lights, signal lamps, steam under-lights. Everything further away is
emissive only (windows, towers, LED strips).

**Atmosphere (`atmos.gd`)**: volumetric fog (lights have `light_volumetric_fog_energy`, so lamps
throw visible cones), a long-distance exponential haze for the towers, a ground-mist FogVolume, steam
plumes (FogVolume + lit particle puffs) at road vents, manholes and industrial stacks, rain streak
particles (two layers) that pick up nearby light, splash particles, ripple normals in puddles, four
box-projected reflection probes along the street, SSR, SSAO, SSIL, glow, AgX tonemapping, MSAA 4x
plus supersampling, and a final colour-grade pass (CanvasLayer shader).

## 4. Materials (how presets reach them)

Kit GLBs carry material NAMES only (roles). `mats.gd` swaps each for a shader material:

| Role(s) | Shader | Driven by |
|---|---|---|
| concrete, concrete_dark, brick, tile, metal_panel | `surface` (world-space procedural: panels, bricks, tiles, grime streaks, wetness) | `concrete_tint` `brick_tint` `tile_tint` `panel_tint` `grime` `wetness` |
| metal_dark, metal_bare, metal_rust, sign_body, paint_yellow, wood, plastic_dark, rubber, cable, grate, chrome, car_paint, glass_car, fabric | `surface` patterns 4-11 | `wetness` `grime`; car paint from `car_paint_colors`; awning fabric from `neon_colors` |
| glass_window | `window` (interior mapping: room, ceiling lamp, furniture, blinds/curtains) | `window_lit` `window_tints` `window_brightness` `window_blinds` |
| tower_glass, building masses | `tower` (window grid, far-distance anti-aliasing) | `window_lit` x `tower_window_lit`, `tower_window_brightness`, `window_tints` |
| asphalt (road) | `road` (aggregate, patches, cracks, wheel paths, markings, puddles, ripples) | `asphalt_color` `marking_white` `marking_yellow` `wetness` `puddles` `rain_amount` |
| paving (sidewalk) | `sidewalk` (slabs, seams, tilt, gum, tactile strip, puddles) | `paving_color` `grime` `wetness` `puddles` |
| neon | `neon` (white-hot core, coloured rim) | `neon_colors` `sign_brightness` |
| sign_face | `sign` (RGB-mask atlases recoloured per sign) | `neon_colors` `sign_panel_colors` `sign_brightness` `sign_off_ratio` |
| screen | `screen` (LED pixel grid) | `screen_colors` `screen_brightness` |
| holo panels | `holo` (additive, scanlines, flicker) | `holo_colors` `holo_opacity` `sign_brightness` |
| lamp_lens, led_strip, blinker, shop_light, interior, goods, light_head/tail, signals, lantern | `glow` | `lamp_color` `lamp_lens_energy` `led_color` `led_energy` `blinker_color` `shop_color` `shop_energy` `car_head_color` `car_tail_color` `car_light_energy` `signal_state` `lantern_color` |
| glass_shop | `glass` (clear, fresnel, smudges, rain drops) | `rain_amount` |

Sign art is stored as masks (R panel, G text, B accent) in `godot/assets/tex`, so any palette works.
Sign words are invented (NOVA, KITE, 24H, RAMEN, PAWN, HOTEL, DATA, ORBIT, LUX, MOTEL, VOLT, HALO,
ZENIT, MIRA, ...). Big neon tube words use `big_words`.

## 5. Preset fields

A preset is `godot/looks/<ID>.gd`:

```gdscript
extends RefCounted
static func get_preset() -> Dictionary:
	return { "name": "Magenta Rain", "rain_amount": 2.0, ... }
```

Any field left out falls back to `DEFAULTS` in `godot/scripts/look.gd` (same values as N.gd). An
unknown key prints a warning in the log. Colours are `Color(r, g, b)` in linear 0..1 (values above 1
are allowed for emissive colours). Ranges below are the useful ones, not hard limits.

### Identity
| Field | Meaning |
|---|---|
| `name` | display name, printed in the log |

### Exposure, tonemap, glow
| Field | Default | Meaning |
|---|---|---|
| `exposure` | 1.0 | tonemap exposure (0.5 darker .. 2 brighter) |
| `tonemap` | "agx" | agx, filmic, aces, reinhard, linear |
| `tonemap_white` | 6.0 | white point (also used as AgX white) |
| `agx_contrast` | 1.0 | AgX contrast (0.5..2) |
| `glow` | true | bloom on/off |
| `glow_intensity` | 0.8 | overall bloom amount (0..3) |
| `glow_strength` | 1.0 | bloom spread strength (0..2) |
| `glow_bloom` | 0.04 | bloom from the whole image, not only bright parts (0..1; 0.2+ = dreamy haze) |
| `glow_threshold` | 0.9 | HDR brightness where bloom starts (lower = more things bloom) |
| `glow_hdr_scale` | 2.0 | how strongly over-threshold light blooms |
| `glow_blend` | "screen" | additive, screen, softlight, replace, mix |
| `glow_mix` | 0.05 | only for blend "mix" |
| `glow_levels` | [0,0.5,0.9,1,0.8,0.5,0.25] | weight of the 7 blur sizes (small to huge). Raise the last ones for big soft halos |

### Sky, ambient, fill
| Field | Default | Meaning |
|---|---|---|
| `sky_zenith`, `sky_horizon` | dark blue, dark purple | sky gradient |
| `sky_glow`, `sky_glow_energy`, `sky_glow_height` | purple, 2.4, 0.16 | city light-pollution band at the horizon (all around) |
| `sky_energy` | 1.0 | multiplies the whole sky |
| `dawn_color`, `dawn_energy`, `dawn_dir`, `dawn_width` | orange, 0, (0,0,-1), 0.6 | a directional horizon glow (predawn). `dawn_dir` (0,0,-1) = straight down the street behind the towers; energy 2-5 makes it obvious; width 0.2 narrow .. 1.5 wide |
| `cloud_amount`, `cloud_color`, `cloud_energy` | 0.55, purple, 1.5 | low cloud deck lit from below by the city |
| `ambient_color`, `ambient_energy` | blue-grey, 0.35 | flat ambient light (shadow colour). Teal for B, deep blue for A |
| `ambient_sky` | 0 | 0 = flat colour, 1 = ambient taken from the sky |
| `reflection_energy` | 1.0 | strength of the street reflection probes |
| `fill_color`, `fill_energy` | cool, 0.04 | weak directional light from above (keeps unlit forms readable; 0.2+ for dusk) |
| `ssao` | 1.2 | ambient occlusion intensity, 0 = off |
| `ssil` | 0.6 | screen-space indirect light (colour bleed from signs), 0 = off |
| `ssr` | true | screen-space reflections (the wet road needs it) |
| `reflection_probes` | true | box-projected probes along the street |
| `sdfgi`, `sdfgi_energy` | false, 1.0 | SDF global illumination (slow to settle, can blotch; try with FRAMES=250) |

### Fog and haze
| Field | Default | Meaning |
|---|---|---|
| `fog_density` | 0.015 | volumetric fog density; 0 = off. 0.005 thin, 0.03 thick, 0.05 soup |
| `fog_albedo` | pale blue | fog colour that lights scatter into |
| `fog_emission`, `fog_emission_energy` | dark purple, 0.25 | fog that glows by itself (tints the darks) |
| `fog_anisotropy` | 0.55 | forward scattering: higher = stronger halos looking towards lights |
| `fog_length` | 180 | how far volumetric fog reaches (m) |
| `fog_detail_spread` | 1.6 | froxel distribution (higher = more detail near the camera) |
| `fog_ambient_inject` | 0.12 | how much ambient light fills the fog (raises the floor of the fog) |
| `fog_sky_affect` | 0.6 | how much volumetric fog covers the sky |
| `haze_density` | 0.0016 | exponential distance haze (what fades the megatowers); 0 = off |
| `haze_color`, `haze_energy` | purple, 1.0 | haze colour (F: orange-purple, C: yellow-green) |
| `haze_height`, `haze_height_density` | 30, 0 | height fog: set density 0.02-0.1 for haze that pools low |
| `haze_sky_affect` | 0.3 | how much haze covers the sky |
| `haze_aerial` | 0.4 | haze takes its colour from the sky (aerial perspective) |
| `mist_density`, `mist_height`, `mist_color` | 0.035, 1.1, pale | ground mist volume over the street (0.02-0.1; above 0.15 it turns to milk) |
| `steam_amount` | 1.0 | number of steam plumes (0 none, 1 all vents/manholes, 2 = all + bigger) |
| `steam_density` | 3.0 | density of each plume |
| `steam_glow` | 0.04 | plume self-illumination |
| `steam_light` | 0.5 | light under each near plume (makes it glow) |
| `steam_color` | near white | steam colour (tint it for C or D) |

### Rain and wetness
| Field | Default | Meaning |
|---|---|---|
| `rain_amount` | 1.0 | 0 = none, 0.3 drizzle, 1 rain, 2 downpour (also drives ripples and glass drops) |
| `rain_color`, `rain_alpha` | blue-grey, 0.38 | streak colour and opacity |
| `rain_light` | 2.5 | how strongly lamps and signs light up the drops |
| `rain_length` | 0.6 | streak length (m) |
| `splash_amount` | 1.0 | ground splashes |
| `wetness` | 0.9 | 0 dry .. 1 soaked: roughness, darkening, glossy films on every surface |
| `puddles` | 0.7 | puddle coverage on road and sidewalk (0.9+ = mirror street) |

### Street lamps and other lights
| Field | Default | Meaning |
|---|---|---|
| `lamp_color` | warm white | street lamp light + lens colour (sodium amber for B, blue-white for E, white for G) |
| `lamp_energy` | 7.0 | lamp SpotLight energy |
| `lamp_lens_energy` | 1.2 | glow of the lamp heads |
| `lamp_fog` | 3.5 | volumetric energy of lamps = visible light cones (6-10 for G and H beams) |
| `lamp_range`, `lamp_angle` | 17, 52 | cone reach (m) and angle (degrees) |
| `lamp_shadows` | 6 | nearest lamps with shadows |
| `lamp_spacing` | 26 | metres between lamps on each side (fewer lamps = more darkness, B) |
| `shop_color`, `shop_energy` | warm, 2.2 | shop interiors, goods, ceiling panels |
| `shop_light_energy` | 1.6 | light shops spill onto the sidewalk |
| `shop_open_ratio` | 0.75 | open lit shops vs shutters |
| `sign_light_energy`, `sign_light_fog`, `sign_light_range` | 1.4, 1.5, 7 | coloured light each sign throws on walls, road and fog |
| `car_head_color`, `car_tail_color`, `car_light_energy` | white, red, 3.0 | car light bars and their lights |
| `car_paint_colors` | 6 colours | car paint palette |
| `traffic` | 1.0 | moving cars with lights (0..2) |
| `parked_cars` | 1.0 | fraction of the parked cars (0..1) |
| `blinker_color` | red | rooftop/antenna aircraft blinkers |
| `signal_state` | "red" | traffic lights: red, amber, green |

### Signs, neon, screens, holograms
| Field | Default | Meaning |
|---|---|---|
| `neon_colors` | magenta, cyan, amber, violet, green | THE sign palette: neon tubes, sign text, accents, awnings, sign lights |
| `sign_panel_colors` | dark violet, cream, dark teal | backgrounds of lightbox signs |
| `sign_density` | 1.0 | blade and wall box signs (0.3 sparse .. 2 crowded) |
| `sign_brightness` | 1.0 | emission of all signs, neon and holograms (0.3 = "only just lit") |
| `sign_off_ratio` | 0.08 | broken / unlit signs |
| `sign_reach` | 1.0 | how far blade signs stick out over the sidewalk (1.4 = narrower-feeling street) |
| `big_words` | 8 words | words used for big neon tube signs (letters A-Z, 0-9 available) |
| `neon_word_count` | 1.0 | big neon words on facades and roof frames |
| `screen_colors` | 2 palettes of 3 | LED screens: [panel, main, accent] per palette |
| `screen_brightness` | 1.0 | LED screens and billboards |
| `billboard_count` | 1.0 | wall screens, roof billboards, back-row screens |
| `billboard_scale` | 1.0 | size of screens, roof billboards and the giant floating holograms |
| `holo_colors` | cyan, pink | hologram colours [main, accent] |
| `holo_count` | 1.0 | facade holograms and giant floating holograms between towers |
| `holo_opacity` | 0.6 | hologram strength |
| `led_color`, `led_energy` | cyan, 3.0 | LED strips (awnings, bollards, towers, rail, skybridge) |
| `tower_led` | 1.0 | LED crowns on back-row buildings |

### Windows
| Field | Default | Meaning |
|---|---|---|
| `window_lit` | 0.36 | fraction of lit windows |
| `window_tints` | 6 colours | interior light colours (each lit window picks one) |
| `window_brightness` | 0.9 | window emission |
| `window_blinds` | 0.55 | fraction with blinds or curtains |
| `tower_window_lit`, `tower_window_brightness` | 1.0, 2.4 | multipliers for megatower / building-side windows |

### Materials
| Field | Default | Meaning |
|---|---|---|
| `concrete_tint`, `brick_tint`, `tile_tint`, `panel_tint` | greys, brick red | base colours of the four wall materials |
| `grime` | 0.6 | dirt streaks, ground grime, rust (0 clean .. 1.5 filthy) |
| `asphalt_color`, `paving_color` | dark greys | road and sidewalk base colour |
| `marking_white`, `marking_yellow` | | road paint |
| `facade_styles` | {concrete 1, brick 1, tile 1, panel 0.8, glass 0.25} | weights of facade styles per lot |

### Dressing toggles
| Field | Default | Meaning |
|---|---|---|
| `lanterns`, `lantern_rows`, `lantern_color` | false, 4, red | strings of paper lanterns across the street (D) |
| `pipes` | 1.0 | exposed pipe runs on facades (2 = industrial) |
| `clutter` | 1.0 | bins, boxes, bags, utility boxes, roof clutter (0.2 = clean) |
| `ac_units` | 1.0 | wall AC units |
| `cables` | 1.0 | overhead cables and conduits |
| `fire_escapes` | 1.0 | fire escapes on brick/tile buildings |
| `awnings` | 1.0 | shop awnings |
| `rooftop` | "mixed" | mixed, industrial (stacks, chillers, ducts), corporate (clean) |
| `tower_style` | "mixed" | mixed, glass, industrial |
| `tower_count` | 1.0 | fraction of the 11 megatowers |
| `train`, `skybridge` | true | the train on the rail, the skybridge at z -150 |

### Final colour grade (after tonemapping)
| Field | Default | Meaning |
|---|---|---|
| `grade_saturation` | 1.0 | 0 = black and white |
| `grade_keep_hue`, `grade_keep_width`, `grade_keep_saturation` | 0, 0, 1 | keep one hue in colour when saturation is low: hue 0 = red, 0.33 green, 0.5 cyan, 0.83 magenta; width about 0.06-0.12 turns it on (G: saturation 0, keep_hue 0, width 0.08, keep_saturation 1.3) |
| `grade_contrast`, `grade_gamma` | 1, 1 | contrast around mid grey; gamma > 1 brightens mids |
| `grade_lift`, `grade_gain` | black, white | lift raises/tints shadows, gain scales/tints highlights |
| `grade_shadow_tint`, `grade_highlight_tint`, `grade_split` | white, white, 0 | split toning: e.g. teal shadows + amber highlights with split 0.5 (B) |
| `grade_vignette` | 0.3 | dark corners |
| `grade_grain` | 0.02 | film grain |
| `grade_chroma` | 0 | chromatic aberration at the edges (0.3-1) |

## 6. Starting points for the eight looks

Copy `godot/looks/N.gd` to `godot/looks/<ID>.gd`, set `name`, then change mainly these:

* **A Magenta Rain**: `neon_colors` hot magenta + cyan only; `rain_amount` 2, `puddles` 0.95, `wetness` 1;
  `sign_density` 1.8, `neon_word_count` 1.5; `ambient_color` deep blue, low `ambient_energy`;
  `fog_albedo` blue-violet; grade lift slightly blue.
* **B Sodium Noir**: `lamp_color` sodium amber (1, 0.55, 0.15), `lamp_energy` up, `lamp_fog` up;
  `sign_density` 0.25, `neon_word_count` 0.2, `holo_count` 0, `billboard_count` 0.3; `rain_amount` 0.3;
  `window_lit` 0.15; `ambient_color` teal-green; `grade_shadow_tint` teal, `grade_highlight_tint`
  amber, `grade_split` 0.5; `lamp_spacing` 34 for darker gaps.
* **C Acid Industrial**: `neon_colors` acid green + yellow; `fog_albedo`/`haze_color` dirty
  yellow-green; `steam_amount` 2, `steam_color` yellow-green; `pipes` 2, `rooftop` "industrial",
  `tower_style` "industrial"; `grime` 1.3; `facade_styles` panel + brick heavy.
* **D Red Lantern**: `lanterns` true, `lantern_rows` 5-6; `neon_colors` reds, warm pink, orange;
  `shop_color` warm, `shop_open_ratio` 0.95; `steam_amount` 1.6; `sign_density` 2, `sign_reach` 1.4,
  `awnings` 1.5; `facade_styles` tile + brick.
* **E Cold Corporate**: `lamp_color` blue-white; `facade_styles` glass 3, concrete 0.5, others 0;
  `tower_style` "glass"; `holo_colors` pale cyan/white, `holo_count` 2, `billboard_scale` 1.6;
  `fog_density` 0.008 cold; `clutter` 0.2, `pipes` 0, `ac_units` 0.2, `cables` 0.3, `grime` 0.15;
  `rain_amount` 0.4.
* **F Predawn Smog**: `dawn_energy` 3-4, `dawn_color` orange, `sky_horizon` purple, `sky_zenith`
  dark blue; `sign_brightness` 0.35, `window_lit` 0.1, `lamp_energy` low; `rain_amount` 0,
  `wetness` 0.5, `puddles` 0.3; `mist_density` 0.06; `haze_color` orange-purple; buildings read as
  silhouettes with low `ambient_energy`.
* **G Mono Red**: `grade_saturation` 0, `grade_keep_hue` 0, `grade_keep_width` 0.08,
  `grade_keep_saturation` 1.3, `grade_contrast` 1.3; `neon_colors` red + white; `lamp_color` white,
  `lamp_fog` 8, `fog_density` 0.025 for strong beams; `holo_colors` red/white.
* **H Vapor Bloom**: `neon_colors` pink, violet, turquoise; `glow_intensity` 1.6, `glow_bloom` 0.25,
  `glow_levels` heavier at 5-7; `fog_density` 0.035, `lamp_fog` 6, `fog_anisotropy` 0.7;
  `grade_contrast` 0.9, `grade_lift` slightly violet.

Check every look at thumbnail size (`contact_sheet.png`): each one should be recognisable by its
dominant colour and its light structure (pools of light, beams, haze, mirror road).

## 7. Regenerating assets

```sh
blender -b --factory-startup --python tools/blender/build_kit.py                 # whole kit (~1 min)
blender -b --factory-startup --python tools/blender/build_kit.py -- signs        # one group
blender -b --factory-startup --python tools/blender/build_kit.py -- piece=lamp_a # one piece
blender -b --factory-startup --python tools/blender/preview.py -- out=/tmp/p.png lamp_a car_van  # quick look
python3 tools/gen_textures.py                                                     # sign/billboard art
```

Kit conventions (`tools/blender/kitlib.py`): metres, Z up, the front faces -Y in Blender (+Z in
Godot); facade modules are 4 m wide, storeys 3.5 m, ground floors 5 m; wall plane at y = 0.
Materials are named by role (section 4). Faces made as "uvk=1" (glass panes, sign faces, screens)
get UV 0..1 plus their size in UV2; every primitive gets a random value in vertex colour R. After
regenerating, the next `render_looks.sh` run re-imports automatically.

## 8. Known limits

* Rain, steam and holograms animate, so two renders of the same look differ slightly in the
  particles; the street, signs and lights are identical.
* SSR only reflects what is on screen; the reflection probes cover the rest at lower detail.
* The cross street beyond the junction is mostly hidden from this camera and is only lightly dressed.
* Rendering at `SS=2.0` uses a lot of GPU memory; keep 1.5 for finals.
