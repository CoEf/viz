class_name ShaderCatalog
extends RefCounted
## Everything the gallery knows about the ten shaders.
##
## Kept as data rather than scattered through scenes so the HUD, the docs and the capture
## tool all read the same facts. `port` is the honest answer to "did this run on 4.7 as
## downloaded": none = compiled untouched, light = one or two lines, heavy = would not
## compile at all without a rewrite.

const ENTRIES: Array = [
	{
		"index": 1,
		"scene": "res://demos/01_screen_space_displacement.tscn",
		"title": "Grass with Screen-Space Displacement",
		"author": "Toadile",
		"license": "MIT",
		"origin": "Godot 3.4 / 3.5",
		"port": "heavy",
		"url": "https://godotshaders.com/shader/grass-with-screen-space-displacement/",
		"tech": "MultiMesh 2x1 cards - bends by sliding UV, using DEPTH_TEXTURE",
		"idea": "The only shader here that needs no interaction data at all: it reads the\ndepth buffer, so ANY solid object parts the grass for free.",
		"finding": "Wind moves 4% of the frame in 1.5s - the weakest of the ten. Its main\nsway term has a ~47 minute period, so only the noise scroll actually animates.\nInteraction changes 0.6%, all of it in a tight blob around the ball.",
		"changes": [
			"WORLD_MATRIX -> MODEL_MATRIX, INV_CAMERA_MATRIX -> VIEW_MATRIX,",
			"CAMERA_MATRIX -> INV_VIEW_MATRIX",
			"hint_color/hint_albedo -> source_color",
			"TRANSMISSION -> BACKLIGHT, NORMALMAP -> NORMAL_MAP",
			"second render_mode line merged into the first (4.x allows only one)",
			"pow(x, 2) -> pow(x, 2.0); dropped the `1.0f` float suffix",
			"removed the stray `return` after `discard`",
		],
		"material": "res://shaders/01_screen_space_displacement/mat_ssd.tres",
		"toggle": {
			"uniform": "displace",
			"values": [true, false],
			"labels": ["depth displacement ON", "depth displacement OFF"],
		},
	},
	{
		"index": 2,
		"scene": "res://demos/02_stylized_cartoon.tscn",
		"title": "Stylized Cartoon Grass",
		"author": "dip",
		"license": "MIT",
		"origin": "Godot 4.x",
		"port": "none",
		"url": "https://godotshaders.com/shader/stylized-cartoon-grass/",
		"tech": "MultiMesh cards x4 variants - unshaded, colour from world-space maps",
		"idea": "Colour is decided per VERTEX, not per pixel, from two top-down colour maps.\nCheapest shading of the ten and the flattest cartoon look.",
		"finding": "Wind moves 42% of the frame in 1.5s - but every blade sways IN UNISON,\nbecause NODE_POSITION_WORLD is one value for a whole MultiMesh.\nThis shader is also the one that exposed the alpha-scissor/mipmap trap:\nwith mipmaps on, ALPHA_SCISSOR 0.8 wipes the whole patch out past ~25 m,\nbecause the mip average of a thin blade falls under the threshold. The\nblade textures here ship with mipmaps OFF for exactly that reason.",
		"changes": ["compiles unchanged; only filter/repeat hints added to the variant array"],
		"material": "res://shaders/02_stylized_cartoon/mat_cartoon.tres",
		"toggle": {
			"uniform": "enable_details",
			"values": [true, false],
			"labels": ["blade outline ON", "blade outline OFF"],
		},
	},
	{
		"index": 3,
		"scene": "res://demos/03_billboard_wind.tscn",
		"title": "Billboard Grass with Wind",
		"author": "binbun",
		"license": "CC0",
		"origin": "Godot 4.x (Feb 2026)",
		"port": "light",
		"url": "https://godotshaders.com/shader/billboard-grass-with-wind/",
		"tech": "MultiMesh cards - 2x2 shape atlas, custom light(), 3 alpha modes",
		"idea": "Three alpha strategies in one shader. Smooth needs sorting, Dithered keeps\nhard edges with no sorting at all, Cut is free but aliases.",
		"finding": "Wind moves 17% of the frame in 1.5s. The only one of the ten whose alpha\nstrategy is immune to the mipmap trap that hits 02, 07 and 08: a dither is\ncomputed from the mask value, so a blurred mip thins the stipple instead of\ncrossing a threshold and deleting the field.",
		"changes": [
			"util/dither.gdshaderinc was never published - rewritten (4x4 Bayer)",
			"ALPHA was never written back in the Dithered/Cut branches - fixed",
		],
		"material": "res://shaders/03_billboard_wind/mat_billboard.tres",
		"toggle": {
			"uniform": "alpha_mode",
			"values": [0, 1, 2],
			"labels": ["alpha: Smooth", "alpha: Dithered", "alpha: Cut"],
		},
	},
	{
		"index": 4,
		"scene": "res://demos/04_gdquest_wind_deform.tscn",
		"title": "Stylized grass with wind and deformation",
		"author": "GDQuest",
		"license": "MIT",
		"origin": "Godot 3.2",
		"port": "heavy",
		"url": "https://godotshaders.com/shader/stylized-grass-with-wind-and-deformation/",
		"tech": "MultiMesh blades - unshaded, one character pushes via a curve texture",
		"idea": "Breath-of-the-Wild bend. Wind and push are converted into VERTEX space first,\nwhich is why randomly rotated blades still all lean the same way.",
		"finding": "Wind moves 34% of the frame in 1.5s. The pusher changes 9% - a wide, soft\ncircle, because the falloff curve is sampled by radius alone.",
		"changes": [
			"hint_black_albedo / hint_black -> source_color + hint_default_black",
			"WORLD_MATRIX -> MODEL_MATRIX (4 uses)",
			"repeat_disable on the falloff curve - without it distant grass reacts",
		],
		"material": "res://shaders/04_gdquest_wind_deform/mat_wind_deform.tres",
		"toggle": {
			"uniform": "character_push_strength",
			"values": [0.9, 0.0],
			"labels": ["character push ON", "character push OFF"],
		},
	},
	{
		"index": 5,
		"scene": "res://demos/05_kiwio_grass.tscn",
		"title": "Grass shader",
		"author": "kiwio",
		"license": "CC0",
		"origin": "Godot 3.x",
		"port": "heavy",
		"url": "https://godotshaders.com/shader/grass-shader/",
		"tech": "MultiMesh blades - fully LIT, wind modulates ROUGHNESS",
		"idea": "The only lit one. Gusts show up as a moving SHEEN rather than as motion,\nbecause the wind value drives roughness. Watch it with the sun low.",
		"finding": "Wind moves 39% of the frame in 1.5s, and a good part of that is the\nroughness sheen rather than geometry - turn it off with [V] and the same\nmotion suddenly reads as much calmer.",
		"changes": [
			"hint_color -> source_color, WORLD_MATRIX -> MODEL_MATRIX",
			"clamp(x, 0.2, 1) -> 1.0 (int literal)",
			"abs(pow(x, p)) -> pow(abs(x), p): pow() of a negative base is NaN on Vulkan",
		],
		"material": "res://shaders/05_kiwio_grass/mat_kiwio.tres",
		"toggle": {
			"uniform": "grass_roughness",
			"values": [0.7, 0.0],
			"labels": ["wind-driven sheen ON", "wind-driven sheen OFF"],
		},
	},
	{
		"index": 6,
		"scene": "res://demos/06_malido_multimesh.tscn",
		"title": "Stylized Multimesh Grass Shader",
		"author": "Malido",
		"license": "CC0",
		"origin": "Godot 4.x",
		"port": "light",
		"url": "https://godotshaders.com/shader/stylized-multimesh-grass-shader/",
		"tech": "MultiMesh blades - toon diffuse + GGX, fake AO, 3D player push",
		"idea": "The push is three-dimensional: player_height fades it out vertically, so\njumping over the patch stops flattening it. Best all-rounder of the ten.",
		"finding": "Wind moves 41% of the frame in 1.5s and the pusher changes 16% - the\nlargest interaction of the ten, and the only one that also fades vertically.",
		"changes": ["vec3(1, -0.3, 1) -> vec3(1.0, -0.3, 1.0) (int literals do not convert)"],
		"material": "res://shaders/06_malido_multimesh/mat_malido.tres",
		"toggle": {
			"uniform": "ambient_occlusion_factor",
			"values": [0.5, 0.0],
			"labels": ["fake root AO ON", "fake root AO OFF"],
		},
	},
	{
		"index": 7,
		"scene": "res://demos/07_clipmap_grass.tscn",
		"title": "Wandering Clipmap - Stylized Grass",
		"author": "ZestfulFibre",
		"license": "CC0",
		"origin": "Godot 4.1",
		"port": "light",
		"url": "https://godotshaders.com/shader/wandering-clipmap-stylized-grass/",
		"tech": "MultiMesh cards on terrain - normal + colour from a heightmap, dithered LOD",
		"idea": "Everything is derived from one coordinate: the heightmap UV under the blade.\nDistance fade is a 4x4 dither on alpha, so blades dissolve instead of popping.",
		"finding": "Wind moves 13% of the frame in 1.5s. Wind here is a single VERTEX.x offset,\nso it slides rather than bends - the darkening does most of the work.\nNote the split personality: the DISTANCE fade is dithered (good), but the\nblade silhouette still goes through ALPHA_SCISSOR 0.7, so mipmapped blades\nstill vanish at range. Both have to be handled, not just one.",
		"changes": [
			"mix(0, ..) / clamp(.., 0, 1) / vec4(VERTEX, 1) -> float literals",
			"dropped hint_normal - the shader unpacks the map by hand and Godot's",
			"normal-map import would rewrite the channels it reads",
		],
		"material": "res://shaders/07_clipmap_grass/mat_clipmap.tres",
		"toggle": {
			"uniform": "wind",
			"values": [true, false],
			"labels": ["wind + wind darkening ON", "wind OFF"],
		},
	},
	{
		"index": 8,
		"scene": "res://demos/08_clipmap_particles.tscn",
		"title": "Wandering Clipmap - Foliage Particle Process",
		"author": "ZestfulFibre",
		"license": "CC0",
		"origin": "Godot 4.1",
		"port": "light",
		"url": "https://godotshaders.com/shader/wandering-clipmap-foliage-particle-process/",
		"tech": "PARTICLE PROCESS shader - places blades, drawn by shader 07",
		"idea": "Not a drawing shader. A GPU grid snapped to the emitter with mod(), so the\nfield stays put while the emitter follows the camera. Placement, height, density\nand orientation all come off textures - zero CPU work per blade.",
		"finding": "5184 blades placed with zero CPU work. Wind moves 27% of the frame; the\nplacement itself never changes, because the grid is derived from INDEX.",
		"changes": [
			"render_mode moved directly after shader_type (4.x parses it there only)",
			"paired with its own copy of shader 07 for the draw pass",
		],
		"material": "res://shaders/08_clipmap_particles/mat_foliage_process.tres",
		"toggle": {
			"uniform": "orient_to_normal",
			"values": [false, true],
			"labels": ["random yaw", "aligned to terrain normal"],
		},
	},
	{
		"index": 9,
		"scene": "res://demos/09_pixel_wind_sway.tscn",
		"title": "Pixel Art Wind Sway",
		"author": "Darfine",
		"license": "CC0",
		"origin": "Godot 4.0",
		"port": "none",
		"url": "https://godotshaders.com/shader/pixel-art-wind-sway-meshinstance3d-godot-4-0/",
		"tech": "Individual MeshInstance3D - two sine waves, no noise, no uniforms",
		"idea": "Cheapest of the ten, and the one with a hard constraint: it de-synchronises\nwith NODE_POSITION_WORLD, which is per NODE. On a MultiMesh the whole field\nsways as one block - hence 260 separate nodes here instead of 3000 instances.",
		"finding": "Wind moves 39% of the frame in 1.5s at 300 tufts - the highest motion per\nblade of the ten, and the lowest blade count by a factor of ten.",
		"changes": ["compiles unchanged; ALPHA_SCISSOR_THRESHOLD added (from the comments)"],
		"material": "res://shaders/09_pixel_wind_sway/mat_pixel.tres",
		"toggle": {
			"uniform": "alpha_scissor",
			"values": [0.5, 0.0],
			"labels": ["alpha scissor (hard pixels)", "alpha blend (soft)"],
		},
	},
	{
		"index": 10,
		"scene": "res://demos/10_grass_patch_canvas.tscn",
		"title": "Grass Patch 3D",
		"author": "al77ex",
		"license": "CC0",
		"origin": "Godot 4.x",
		"port": "none",
		"url": "https://godotshaders.com/shader/grass-patch-3d-2/",
		"tech": "canvas_item shader in a SubViewport, mapped onto a ground quad",
		"idea": "Despite the name this is 2D: no geometry, no textures, just two octaves of\nhash noise. Zero blades, constant cost - what you actually want for a far LOD\nring or a top-down game. Included to mark the other end of the scale.",
		"finding": "Zero blades, zero geometry, constant cost. Wind moves 21% of the frame -\nbut the published defaults (speed 0.4, strength 0.005) drift so slowly that\nnothing visibly moves at all; this scene runs it at 1.4 / 0.02.",
		"changes": ["compiles unchanged; a script feeds camera_world_pos / camera_zoom"],
		"material": "res://shaders/10_grass_patch_canvas/mat_grass_patch.tres",
		"toggle": {
			"uniform": "color_variation",
			"values": [0.55, 1.0],
			"labels": ["variation 0.55", "variation 1.0"],
		},
	},
]


static func port_color(port: String) -> String:
	match port:
		"none":
			return "88e07a"
		"light":
			return "e0c86a"
		_:
			return "e8836a"


static func port_label(port: String) -> String:
	match port:
		"none":
			return "runs on 4.7 as published"
		"light":
			return "small fixes for 4.7"
		_:
			return "would NOT compile - rewritten for 4.7"
