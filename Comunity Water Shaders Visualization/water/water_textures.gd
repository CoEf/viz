class_name WaterTextures
extends RefCounted
## Procedurally generated textures for every shader in the gallery.
##
## The 25 shaders between them want noise, normal maps, caustics, colour ramps,
## foam with an alpha channel, a flow map and a 16-slice caustic Texture2DArray.
## Shipping those as PNGs would mean 15 binary blobs nobody can inspect, so they
## are all built from FastNoiseLite / Gradient at startup instead. Everything is
## cached in _cache, so asking for the same key twice is free.

const NOISE_SIZE: int = 512
const CAUSTIC_SIZE: int = 256
const CAUSTIC_FRAMES: int = 16

static var _cache: Dictionary[StringName, Texture2D] = {}
static var _caustic_array: Texture2DArray = null


## Returns the texture registered under `key`, building it on first request.
## Unknown keys return null rather than crashing, so a typo in the registry
## shows up as an unbound sampler instead of a hard failure.
static func get_texture(key: StringName) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	var tex: Texture2D = _build(key)
	if tex != null:
		_cache[key] = tex
	return tex


## The 16-frame animated caustic stack that shader 03 samples as a sampler2DArray.
static func get_caustic_array() -> Texture2DArray:
	if _caustic_array != null:
		return _caustic_array
	var images: Array[Image] = []
	# Slice N is the same cellular field sampled at depth N, so playing the
	# slices back in order reads as flowing light rather than 16 unrelated frames.
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
	noise.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_DIV
	noise.frequency = 0.02
	noise.cellular_jitter = 1.0
	for frame: int in CAUSTIC_FRAMES:
		var img := Image.create_empty(CAUSTIC_SIZE, CAUSTIC_SIZE, false, Image.FORMAT_RGBA8)
		var z := float(frame) / float(CAUSTIC_FRAMES) * 24.0
		for y: int in CAUSTIC_SIZE:
			for x: int in CAUSTIC_SIZE:
				var n := noise.get_noise_3d(float(x), float(y), z)
				var v: float = pow(clampf(1.0 - absf(n), 0.0, 1.0), 6.0)
				img.set_pixel(x, y, Color(v, v, v, 1.0))
		images.append(img)
	_caustic_array = Texture2DArray.new()
	_caustic_array.create_from_images(images)
	return _caustic_array


static func _build(key: StringName) -> Texture2D:
	match key:
		# --- 시각화용으로 추가한 키 ------------------------------------------
		# 원본 갤러리에는 없다. checker/blob은 무대 소품이고, *_fbm은 챕터 2가
		# "능선 노이즈가 아니면 반짝임이 사라진다"를 나란히 보여주기 위한 대조군.
		&"checker":
			return _checker_texture()
		&"blob":
			return _radial_blob_texture()
		&"pw_normal_1_fbm":
			var f3 := FastNoiseLite.new()
			f3.frequency = 0.0245
			f3.fractal_type = FastNoiseLite.FRACTAL_FBM
			f3.fractal_gain = 0.435
			f3.fractal_weighted_strength = 0.37
			f3.domain_warp_type = FastNoiseLite.DOMAIN_WARP_BASIC_GRID
			f3.domain_warp_amplitude = 4.62
			var tf3 := _pw_noise(f3, 256, 0.251)
			tf3.as_normal_map = true
			return tf3
		&"pw_normal_2_fbm":
			var f4 := FastNoiseLite.new()
			f4.fractal_type = FastNoiseLite.FRACTAL_FBM
			var tf4 := _pw_noise(f4, 256, 0.295)
			tf4.as_normal_map = true
			return tf4
		&"noise_soft":
			return _noise_texture(_simplex(1337, 0.004, 4), NOISE_SIZE)
		&"noise_soft2":
			return _noise_texture(_simplex(90210, 0.006, 3), NOISE_SIZE)
		&"noise_fine":
			return _noise_texture(_simplex(4242, 0.02, 5), NOISE_SIZE)
		&"noise_blobs":
			return _noise_texture(_simplex(777, 0.002, 2), NOISE_SIZE)
		&"noise_foamy":
			# Shader 22 expects a source whose mean sits low (the author fed it a
			# canvas_item FBM). A plain 0..1 noise leaves its ramp permanently in
			# the foam band, so bias the histogram downwards with a colour ramp.
			var foamy := _noise_texture(_simplex(1701, 0.012, 4), NOISE_SIZE)
			var ramp := Gradient.new()
			ramp.offsets = PackedFloat32Array([0.0, 0.62, 1.0])
			ramp.colors = PackedColorArray([Color.BLACK, Color(0.28, 0.28, 0.28), Color.WHITE])
			foamy.color_ramp = ramp
			return foamy
		&"normal_a":
			return _normal_texture(_simplex(2024, 0.01, 4), 2.0)
		&"normal_b":
			return _normal_texture(_simplex(555, 0.016, 3), 1.4)
		&"normal_fine":
			return _normal_texture(_simplex(8080, 0.03, 4), 0.8)
		&"caustics":
			return _caustic_texture()
		&"caustic_veins":
			return _caustic_veins_texture()
		&"foam":
			return _foam_texture()

		# --- shader 01 ------------------------------------------------------
		# Reproduced 1:1 from the author's demo project, textures/*.tres in
		# github.com/taillight-games/godot-4-pixelated-water-shader. They are all
		# procedural NoiseTexture2D resources there too, so nothing is lost by
		# rebuilding them in code. The RIDGED fractal on the two normal maps is
		# the whole trick: it makes sharp creases, and the shader's hard-edged
		# specular turns those creases into the pixel glints the preview is
		# famous for. A smooth FBM normal map produces none of them.
		&"pw_vertex_1":
			var n1 := FastNoiseLite.new()
			n1.noise_type = FastNoiseLite.TYPE_SIMPLEX
			n1.seed = 700
			n1.frequency = 0.0194
			n1.fractal_type = FastNoiseLite.FRACTAL_RIDGED
			n1.fractal_octaves = 1
			n1.fractal_lacunarity = -2.665
			n1.fractal_gain = 2.46
			var t1 := _pw_noise(n1, 256, 0.564)
			t1.normalize = false
			t1.color_ramp = _gradient(
				[Color.BLACK, Color(0.2667, 0.2667, 0.2667), Color(0.7144, 0.7144, 0.7144), Color.WHITE],
				[0.0, 0.338182, 0.712727, 1.0], Gradient.GRADIENT_INTERPOLATE_CUBIC)
			return t1
		&"pw_vertex_2":
			var n2 := FastNoiseLite.new()
			n2.noise_type = FastNoiseLite.TYPE_SIMPLEX
			n2.seed = -40
			n2.frequency = 0.0228
			n2.fractal_octaves = 10
			var t2 := _pw_noise(n2, 256, 0.358)
			t2.color_ramp = _gradient([Color.BLACK, Color(0.8033, 0.8033, 0.8033)], [0.0, 1.0])
			return t2
		&"pw_normal_1":
			var n3 := FastNoiseLite.new() # noise_type left at the default SIMPLEX_SMOOTH
			n3.frequency = 0.0245
			n3.fractal_type = FastNoiseLite.FRACTAL_RIDGED
			n3.fractal_gain = 0.435
			n3.fractal_weighted_strength = 0.37
			n3.domain_warp_type = FastNoiseLite.DOMAIN_WARP_BASIC_GRID
			n3.domain_warp_amplitude = 4.62
			var t3 := _pw_noise(n3, 256, 0.251)
			t3.as_normal_map = true
			return t3
		&"pw_normal_2":
			var n4 := FastNoiseLite.new()
			n4.fractal_type = FastNoiseLite.FRACTAL_RIDGED
			var t4 := _pw_noise(n4, 256, 0.295)
			t4.as_normal_map = true
			return t4
		&"pw_under_wobble":
			var n5 := FastNoiseLite.new()
			n5.frequency = 0.0017
			var t5 := _pw_noise(n5, 64, 0.342)
			t5.color_ramp = _gradient([Color(0.4975, 0.4975, 0.4975), Color.WHITE], [0.0, 1.0])
			return t5
		&"pw_foam":
			var n6 := FastNoiseLite.new()
			n6.noise_type = FastNoiseLite.TYPE_VALUE_CUBIC
			n6.frequency = 0.2154
			n6.fractal_octaves = 8
			n6.fractal_lacunarity = 2.225
			n6.fractal_gain = 0.85
			n6.fractal_weighted_strength = 0.37
			var t6 := _pw_noise(n6, 256, 0.5)
			# The alpha stops matter: the shader multiplies its foam mask by
			# texture(foam, uv).a, so a fully opaque ramp smears foam everywhere.
			t6.color_ramp = _gradient(
				[Color(0.87, 0.87, 0.87, 0.0), Color(1, 1, 1, 0.341176), Color(1, 1, 1, 1),
				Color(1, 1, 1, 0.807843), Color(1, 1, 1, 0.933333)],
				[0.0, 0.253378, 0.611486, 0.793919, 1.0])
			return t6
		&"pw_foam_wobble":
			var n7 := FastNoiseLite.new()
			n7.noise_type = FastNoiseLite.TYPE_SIMPLEX
			n7.frequency = 0.0247
			n7.fractal_type = FastNoiseLite.FRACTAL_RIDGED
			n7.fractal_octaves = 10
			n7.domain_warp_enabled = true
			n7.domain_warp_type = FastNoiseLite.DOMAIN_WARP_BASIC_GRID
			var t7 := _pw_noise(n7, 256, 0.636)
			t7.color_ramp = _gradient([Color(0.9798, 0.9798, 0.9798), Color.BLACK], [0.0, 1.0])
			return t7
		&"debris":
			return _debris_texture()
		&"flow_map":
			return _flow_map_texture()
		&"psx_water_a":
			return _psx_tile(Color(0.16, 0.44, 0.72), Color(0.36, 0.72, 0.92), 3011)
		&"psx_water_b":
			return _psx_tile(Color(0.10, 0.33, 0.60), Color(0.55, 0.85, 0.98), 6022)
		&"ramp_edge":
			return _ramp([Color.WHITE, Color(0.6, 0.6, 0.6), Color.BLACK], [0.0, 0.35, 1.0])
		&"ramp_hotspring":
			# Matched against the author's cover GIF: the base is a solid mid
			# blue, not the near-black navy this used to start on, and the top
			# end goes all the way to white so the caustic veins read as light.
			return _ramp(
				[Color(0.043, 0.278, 0.553), Color(0.086, 0.412, 0.706), Color(0.361, 0.643, 0.878),
				Color(0.784, 0.918, 1.0), Color(1.0, 1.0, 1.0)],
				[0.0, 0.36, 0.62, 0.84, 1.0])
	return null


## NoiseTexture2D shaped the way the pixel-art-water author's .tres files are.
static func _pw_noise(noise: FastNoiseLite, size: int, skirt: float) -> NoiseTexture2D:
	var tex := NoiseTexture2D.new()
	tex.width = size
	tex.height = size
	tex.seamless = true
	tex.seamless_blend_skirt = skirt
	tex.generate_mipmaps = true
	tex.noise = noise
	return tex


static func _gradient(colors: Array[Color], offsets: Array[float],
		mode: Gradient.InterpolationMode = Gradient.GRADIENT_INTERPOLATE_LINEAR) -> Gradient:
	var gradient := Gradient.new()
	# Offsets first would leave the point count and the colour count disagreeing
	# for one call, so set the colours alongside it and let Gradient resize once.
	gradient.offsets = PackedFloat32Array(offsets)
	gradient.colors = PackedColorArray(colors)
	gradient.interpolation_mode = mode
	return gradient


static func _simplex(seed_value: int, frequency: float, octaves: int) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.seed = seed_value
	noise.frequency = frequency
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = octaves
	return noise


static func _noise_texture(noise: FastNoiseLite, size: int) -> NoiseTexture2D:
	var tex := NoiseTexture2D.new()
	tex.width = size
	tex.height = size
	# Seamless matters: most of these shaders scroll UVs far past 1.0 and a
	# visible tile seam reads as a hard line drifting across the water.
	tex.seamless = true
	tex.seamless_blend_skirt = 0.3
	tex.generate_mipmaps = true
	tex.noise = noise
	return tex


static func _normal_texture(noise: FastNoiseLite, bump: float) -> NoiseTexture2D:
	var tex := _noise_texture(noise, NOISE_SIZE)
	tex.as_normal_map = true
	tex.bump_strength = bump
	return tex


static func _caustic_texture() -> ImageTexture:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_DIV
	noise.frequency = 0.018
	noise.seed = 31337
	var size := CAUSTIC_SIZE
	var img := Image.create_empty(size, size, true, Image.FORMAT_RGBA8)
	for y: int in size:
		for x: int in size:
			var n := noise.get_noise_2d(float(x), float(y))
			var v: float = pow(clampf(1.0 - absf(n), 0.0, 1.0), 6.0)
			img.set_pixel(x, y, Color(v, v, v, 1.0))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## Thin bright filaments on black, for shader 07's polar sweep.
## The cellular caustics above give thick soft blobs; smeared around the polar
## transform they turn into wide bands, nothing like the hairline veins in the
## author's preview. A ridged fractal crushed to black below its ridges gives
## the thin lines the effect is built around.
static func _caustic_veins_texture() -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = 8123
	noise.frequency = 0.011
	noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	noise.fractal_octaves = 4
	noise.fractal_gain = 0.52
	noise.fractal_lacunarity = 2.1
	noise.domain_warp_enabled = true
	noise.domain_warp_type = FastNoiseLite.DOMAIN_WARP_SIMPLEX
	noise.domain_warp_amplitude = 22.0
	noise.domain_warp_frequency = 0.014
	var tex := _pw_noise(noise, NOISE_SIZE, 0.35)
	# Measured, not assumed: with these settings the broad flat areas come out at
	# the HIGH end and the hairline features at the LOW end, so the ramp runs
	# white -> black. Ramping the other way lights up the background instead of
	# the veins and inverts the whole effect.
	tex.color_ramp = _gradient(
		[Color.WHITE, Color(0.88, 0.88, 0.88), Color(0.10, 0.10, 0.10), Color.BLACK],
		[0.0, 0.28, 0.60, 1.0])
	return tex


static func _foam_texture() -> ImageTexture:
	# Foam needs a real alpha channel: shader 01 multiplies its mask by
	# texture(foam, uv).a, so an opaque texture would smear foam everywhere.
	var noise := _simplex(1212, 0.012, 4)
	var size := NOISE_SIZE
	var img := Image.create_empty(size, size, true, Image.FORMAT_RGBA8)
	for y: int in size:
		for x: int in size:
			var n: float = (noise.get_noise_2d(float(x), float(y)) + 1.0) * 0.5
			var a: float = smoothstep(0.55, 0.75, n)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func _debris_texture() -> ImageTexture:
	var noise := _simplex(9001, 0.05, 2)
	var size := 256
	var img := Image.create_empty(size, size, true, Image.FORMAT_RGBA8)
	for y: int in size:
		for x: int in size:
			var n: float = (noise.get_noise_2d(float(x), float(y)) + 1.0) * 0.5
			var a: float = smoothstep(0.72, 0.85, n) * 0.8
			var tint: float = 0.35 + n * 0.3
			img.set_pixel(x, y, Color(tint * 0.7, tint, tint * 0.55, a))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func _flow_map_texture() -> ImageTexture:
	# R/G encode a 2D direction in 0..1; shader 16 decodes with *2-1. A slowly
	# curling field looks far more like current than uniform 0.5,0.5 would.
	var angle_noise := _simplex(606, 0.006, 3)
	var size := 256
	var img := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	for y: int in size:
		for x: int in size:
			var a: float = angle_noise.get_noise_2d(float(x), float(y)) * PI
			img.set_pixel(x, y, Color(cos(a) * 0.5 + 0.5, sin(a) * 0.5 + 0.5, 0.0, 1.0))
	return ImageTexture.create_from_image(img)


static func _psx_tile(dark: Color, light: Color, seed_value: int) -> ImageTexture:
	# Deliberately tiny (64px) so the PSX shader's floor()-quantised UVs land on
	# chunky texels instead of a smooth gradient.
	var noise := _simplex(seed_value, 0.06, 3)
	var size := 64
	var img := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	for y: int in size:
		for x: int in size:
			var n: float = (noise.get_noise_2d(float(x), float(y)) + 1.0) * 0.5
			var banded: float = floorf(n * 5.0) / 4.0
			img.set_pixel(x, y, dark.lerp(light, clampf(banded, 0.0, 1.0)))
	var tex := ImageTexture.create_from_image(img)
	return tex


static func _ramp(colors: Array[Color], offsets: Array[float]) -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array(offsets)
	gradient.colors = PackedColorArray(colors)
	var tex := GradientTexture1D.new()
	tex.gradient = gradient
	tex.width = 256
	return tex


## 무대 바닥의 체커. 굴절/왜곡이 얼마나 강한지 눈으로 재는 기준선이다.
static func _checker_texture() -> ImageTexture:
	var size := 64
	var img := Image.create_empty(size, size, true, Image.FORMAT_RGBA8)
	for y: int in size:
		for x: int in size:
			var on: bool = ((x / 8) + (y / 8)) % 2 == 0
			img.set_pixel(x, y, Color(0.62, 0.58, 0.50) if on else Color(0.36, 0.34, 0.30))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## 가운데가 희고 테두리가 투명한 원반 — 물체가 포말 마스크에 남기는 발자국.
## 맨 쿼드를 쓰면 마스크에 사각형이 찍히고 01번이 그걸 그대로 네모난 포말로
## 칠한다.
static func _radial_blob_texture() -> ImageTexture:
	var size := 64
	var img := Image.create_empty(size, size, true, Image.FORMAT_RGBA8)
	var centre := float(size - 1) * 0.5
	for y: int in size:
		for x: int in size:
			var d: float = Vector2(float(x) - centre, float(y) - centre).length() / centre
			var a: float = clampf(1.0 - smoothstep(0.35, 1.0, d), 0.0, 1.0)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)
