class_name WaterShaderRegistry
extends RefCounted
## The catalogue: one entry per shader in res://shaders/.
##
## Everything the gallery needs to stage a shader lives here - which mesh suits
## it, which generated textures to bind to which sampler, which runtime values
## it needs pushed each frame, and a note on what the 4.7 port actually changed.
## Keeping it as plain data means adding a 26th shader is one dictionary, not a
## new code path.

## How the shader has to be presented. A canvas_item shader on a MeshInstance3D
## simply will not run, and shader 18 is a material_overlay, not a surface.
enum Kind {
	SURFACE_3D,  ## spatial: goes on the water mesh
	CANVAS_2D,   ## canvas_item: goes on a full-rect ColorRect
	OVERLAY_3D,  ## spatial: material_overlay on the scenery, not the water
	POST_FX,     ## canvas_item reading hint_screen_texture: sits above everything
}

## Which body the 3D shaders want under them.
enum MeshKind { PLANE, SPHERE, CYLINDER, RIBBON, VFX_PROPS }

## Per-frame values the gallery has to push into the material or into
## RenderingServer's global shader parameters.
enum Feed {
	SYNC_TIME,     ## `sync_time` uniform (shader 01 keeps planes in phase with it)
	BOAT,          ## `boat_position` uniform, follows the roaming probe
	PLAYER_GLOBAL, ## `player_position` global shader parameter
	FOAM_MASK,     ## `foam_mask` sampler wants the top-down SubViewport
}


static var _entries: Array[Dictionary] = []


## Every shader, in the order they were requested. Built once, then cached -
## an array literal cannot be returned directly as Array[Dictionary], it has to
## land in a typed variable first.
static func entries() -> Array[Dictionary]:
	if not _entries.is_empty():
		return _entries
	var list: Array[Dictionary] = [
	{
		"id": 1, "file": "01_pixel_art_water", "title": "Pixel Art Water",
		"url": "https://godotshaders.com/shader/pixel-art-water-shader/",
		"kind": Kind.SURFACE_3D, "mesh": MeshKind.PLANE, "transparent": true,
		"origin": "Godot 4.x",
		"feeds": [Feed.SYNC_TIME, Feed.FOAM_MASK],
		"textures": {
			"vertex_noise_big": &"pw_vertex_1", "vertex_noise_big2": &"pw_vertex_2",
			"normal_noise": &"pw_normal_1", "normal_noise2": &"pw_normal_2",
			"under_wobble_noise": &"pw_under_wobble", "foam": &"pw_foam",
			"foam_wobble_noise": &"pw_foam_wobble",
		},
		# Values lifted from the author's own water_material.tres in
		# github.com/taillight-games/godot-4-pixelated-water-shader. v_noise_tile
		# is the one deliberate deviation: 200 (an ocean) leaves a 44m pool
		# almost flat, so it is pulled in to fit the demo stage.
		"params": {
			"wave_speed": 0.02, "caustic_speed": 0.015, "edge_fade_power": 3.825,
			"transmittence": 0.085, "h_dist_trans_weight": 3.0,
			"transmit_color": Vector3(0.18152, 0.215028, 0.219817),
			"depth_fade": 0.5, "depth_fade_distance": 5.0,
			"surface_albedo": Vector3(0.0627451, 0.407843, 0.568627),
			"surface_bottom": Color(0.294118, 0.533333, 0.670588, 0.65098),
			"opacity": 0.96, "opacity_floor": 0.14, "opacity_ceiling": 1.0,
			"roughness": 0.17, "height_scale": 0.8, "amplitude1": 1.0, "amplitude2": 0.12,
			"v_noise_tile": 100, "normal_noise_size": 2.56, "normal_noise_speed": 0.05,
			"v_normal_scale": 1.0, "normal_map_w": 256, "wobble_power": 0.05,
			"sky_color": Vector3(0.0588235, 0.341176, 0.458824),
			"foam_color": Vector3(1.0, 1.0, 1.0), "foam_mask_size": 44.0,
			"foam_wobble": 0.05, "foam_wobble_size": 10.0,
			"high_color": Vector3(0.0, 0.540833, 0.59), "low_color": Vector3(0.0, 0.232333, 0.34),
			"wave_color_range": 2.0, "shine_strength": 0.17, "shine_shininess": 18.0,
			"shadow": 0.654, "shadow_width": 0.13,
			"shadow_color": Color(0.705, 0.705, 0.705, 0.705),
			"_specular_smoothness": 0.199, "_specular_strength": 0.0, "_glossiness": 0.067,
		},
		"converted": "0.0f 접미사 제거 / int→float 리터럴 / 미할당 varying 제거 / foam_mask_size 기본값 추가 / fragment의 NODE_POSITION_WORLD를 varying 경유로 변경",
		"note": "텍스처 7장과 파라미터를 원작자 데모 프로젝트(water_material.tres)에서 그대로 가져왔다. 핵심은 법선맵 두 장이 FRACTAL_RIDGED라는 것 — 날카로운 능선이 있어야 하드 스펙큘러가 그 픽셀 반짝임을 만든다. 부드러운 FBM 노이즈를 물리면 반짝임이 통째로 사라진다. opacity도 중요한데, 기본값 0.4로 두면 셰이더 안의 remap이 1.85까지 튀어서 mix()가 외삽되고 수면 아래 배경이 반전·증폭돼 보인다(원작자 값은 0.96). v_noise_tile만 200→100으로 줄이고 진폭도 같은 비율로 낮췄다 — 200은 바다 기준이라 44m 수영장에선 파도가 안 보이고, 타일만 줄이면 파장이 짧아져 파도가 모래언덕처럼 솟는다. 반짝임은 셰이더가 아니라 조명 배치 문제였다 — pow(NdotH, 324)짜리 아주 좁은 스펙큘러라 해의 반사 경로가 화면 안에 들어와야 보인다. 그래서 데모의 태양을 카메라 반대 방위·고도 28°로 옮겨 반사 경로를 화면에 넣었다. enable_fake_lighting은 원작자 값(false) 그대로다.",
	},
	{
		"id": 2, "file": "02_psx_water_surface", "title": "PSX Water Surface",
		"url": "https://godotshaders.com/shader/psx-style-water-surface-pixelation-waves-scrolling-textures/",
		"kind": Kind.SURFACE_3D, "mesh": MeshKind.PLANE, "transparent": true,
		"origin": "Godot 4.x", "feeds": [],
		"textures": {
			"water_texture1": &"psx_water_a", "water_texture2": &"psx_water_b",
			"noise_texture": &"noise_soft",
		},
		"params": {"pixelation_level": 24, "wave_strength": 0.25, "WaterOpacity": 0.75, "scale1": Vector2(2, 2), "scale2": Vector2(1.5, 1.5)},
		"converted": "변환 없음 - 원본이 이미 4.x 역Z 깊이 규약을 씀. DepthTexture 유니폼 이름도 4.7에서 그대로 유효.",
		"note": "UV를 floor()로 계단화하는 방식이라 pixelation_level 슬라이더가 가장 눈에 띈다. 텍스처를 64px로 만들어서 PSX 느낌이 살아있음.",
	},
	{
		"id": 3, "file": "03_realistic_water", "title": "Realistic Water (UnionBytes)",
		"url": "https://godotshaders.com/shader/realistic-water/",
		"kind": Kind.SURFACE_3D, "mesh": MeshKind.PLANE, "transparent": true,
		"origin": "Godot 3.1~3.4", "feeds": [],
		"textures": {
			"uv_sampler": &"noise_soft", "normalmap_a_sampler": &"normal_a",
			"normalmap_b_sampler": &"normal_b", "foam_sampler": &"noise_soft",
		},
		"params": {"wave_speed": 0.4, "beers_law": 0.35, "depth_offset": -1.8, "refraction": 0.05, "sampler_scale": Vector2(0.08, 0.08)},
		"converted": "3.x→4.x 전면 포팅: hint_color/hint_black/hint_aniso 교체, WORLD_MATRIX→MODEL_MATRIX, NORMALMAP→NORMAL_MAP, SCREEN/DEPTH_TEXTURE 유니폼화, 그리고 깊이 선형화를 역Z 언프로젝션으로 다시 씀",
		"note": "Gerstner 파도 + 굴절 + 포말 + 코스틱까지 다 들어있는 정통파. 코스틱은 sampler2DArray라서 16장짜리 Texture2DArray를 코드에서 만들어 넣었다.",
	},
	{
		"id": 4, "file": "04_water_trail", "title": "Water Trail",
		"url": "https://godotshaders.com/shader/water-trail/",
		"kind": Kind.SURFACE_3D, "mesh": MeshKind.RIBBON, "transparent": true,
		"origin": "Godot 4.x", "feeds": [Feed.BOAT],
		"textures": {},
		"params": {"scroll_speed": 1.5, "wave_frequency": 6.0},
		"converted": "변환 없음.",
		"note": "물 표면이 아니라 배 뒤에 붙이는 항적 리본이다. 그래서 메시가 좁고 긴 quad로 바뀐다. 사다리꼴로 UV를 왜곡해서 끝이 좁아지는 게 포인트.",
	},
	{
		"id": 5, "file": "05_water_ripples", "title": "Water Ripples",
		"url": "https://godotshaders.com/shader/water-ripples/",
		"kind": Kind.SURFACE_3D, "mesh": MeshKind.PLANE, "transparent": true,
		"origin": "Godot 4.x", "feeds": [Feed.BOAT], "backdrop": true,
		"textures": {},
		"params": {"max_radius": 14.0, "wave_frequency": 3.0, "noise_scale": 0.35},
		"converted": "변환 없음.",
		"note": "돌아다니는 프로브 구를 따라 파문이 생긴다. 노이즈로 원을 일부러 찢어서 완벽한 동심원이 안 되게 하는 게 이 셰이더의 트릭. 포말 마스크 밖은 ALPHA가 0이라 물 자체는 안 그린다 — 그래서 이 데모는 아래에 기본 수면(11번)을 한 장 깔아준다.",
	},
	{
		"id": 6, "file": "06_water_cylindrical_waves", "title": "Cylindrical Waves",
		"url": "https://godotshaders.com/shader/water-cylindrical-waves/",
		"kind": Kind.SURFACE_3D, "mesh": MeshKind.CYLINDER, "transparent": true,
		"origin": "Godot 4.x", "feeds": [],
		"textures": {},
		"params": {"scroll_speed": 4.0, "wave_multiplier": 3.0, "wave_amplitude": 0.22, "foam_1_thickness": 0.13, "foam_2_thickness": 0.09},
		"converted": "`uniform float scroll_speed = 4;` → `4.0`. float 유니폼 초기값에 int 리터럴은 4.7이 거부한다(식 안에서는 허용).",
		"note": "원통에 감아서 소용돌이/물기둥용으로 쓰는 물건. UV.y를 따라 사인파로 흔들리는 포말 라인 두 줄이 전부라 아주 가볍다.",
	},
	{
		"id": 7, "file": "07_water_hotspring", "title": "Hotspring (polar caustics)",
		"url": "https://godotshaders.com/shader/water-hotspring-exercise/",
		"kind": Kind.SURFACE_3D, "mesh": MeshKind.PLANE, "transparent": false,
		"origin": "Godot 3.x", "feeds": [],
		"textures": {
			"caustics_texture": &"caustic_veins", "color_gradient": &"ramp_hotspring",
			"distort_noise": &"noise_soft",
		},
		"params": {"flow_speed": 0.12, "vignette_size": 0.42, "vignette_blend": 0.07,
			"distort_strength": 0.08, "disc_speed": 0.5},
		"converted": "hint_black→hint_default_black, hint_albedo→source_color, `const float TAU` 삭제(4.7이 TAU를 내장 상수로 승격), 그리고 color_gradient에 repeat_disable 추가. 마지막 게 핵심인데 — 3.x는 텍스처 플래그로 wrap을 정했고 GradientTexture는 CLAMP였지만, 4.x는 모든 uniform sampler2D가 기본 repeat_enable이다. 램프가 256x1이라 u=0 조회가 감싸진 texel 255(램프 반대쪽 끝)와 선형 보간되고, 이 셰이더는 면적 대부분이 grad_uv=0이라 수면 전체가 램프의 밝은 끝을 집어왔다. 결과적으로 명암이 통째로 반전됐다.",
		"note": "원본 커버 GIF와 맞춰 두 가지를 고쳤다. (1) 코스틱 텍스처 — cellular 노이즈는 굵은 띠가 나와서 극좌표로 펴면 원본의 가는 실선과 전혀 달랐다. 능선(RIDGED) 노이즈를 임계값 아래로 눌러 얇은 빛줄기로 다시 만들었다. (2) 컬러 램프 최저색이 거의 검정이라 바깥이 죽어 보였는데, 원본은 진한 파랑이 바닥색이다. 중앙에서 보글거리는 건 20개짜리 디스크 루프이고, disc_speed를 원작 기본값 0.5로 되돌렸다.",
	},
	{
		"id": 8, "file": "08_toon_water", "title": "Toon Water (depth fade)",
		"url": "https://godotshaders.com/shader/toon-water/",
		"kind": Kind.SURFACE_3D, "mesh": MeshKind.PLANE, "transparent": false,
		"origin": "Godot 4.x", "feeds": [],
		"textures": {"water": &"psx_water_a"},
		"params": {"texture_scale": 0.12, "slide_speed": 0.25},
		"converted": "변환 없음. `: source_color, hint_depth_texture` 조합도 4.7에서 그대로 통과.",
		"note": "깊이 차이로 물가만 흰색으로 남기는 가장 단순한 툰 물. 경사진 바닥 덕분에 해안선 띠가 잘 보인다.",
	},
	{
		"id": 9, "file": "09_stylized_toon_water", "title": "Stylized Toon Water (banded)",
		"url": "https://godotshaders.com/shader/stylized-toon-water/",
		"kind": Kind.SURFACE_3D, "mesh": MeshKind.PLANE, "transparent": true,
		"origin": "Godot 4.x", "feeds": [], "vfx_props": true,
		"textures": {"wave_texture": &"noise_soft", "noise_texture": &"noise_soft2"},
		"params": {"wave_height": 0.25, "texture_height": 0.2, "brightness": 1.0, "banding_bias": 0.58, "size": 2.6},
		"converted": "vertex() 끝의 중복 세미콜론(`;;`) 제거.",
		"note": "blend_add라서 배경보다 어두워질 수 없다. 밝은 하늘에선 날아가 보이는 게 정상이고, discard로 띠 사이를 뚫는 구조. 원래 수면보다 VFX용에 가까운 셰이더라, 수영장 위에 떠 있는 구체와 도넛(TorusMesh)에도 같이 입혀 뒀다 — 띠가 시선 각도(dot(NORMAL, VIEW))로 갈리기 때문에 곡면에서 훨씬 잘 드러난다.",
	},
	{
		"id": 10, "file": "10_absorption_stylized_water", "title": "Absorption Based Stylized Water",
		"url": "https://godotshaders.com/shader/absorption-based-stylized-water/",
		"kind": Kind.SURFACE_3D, "mesh": MeshKind.PLANE, "transparent": true,
		"origin": "Godot 4.3~4.5.1", "feeds": [Feed.PLAYER_GLOBAL],
		"textures": {
			"displacement_texture": &"noise_soft", "edge_noise": &"noise_fine",
			"edge_ramp": &"ramp_edge", "normal_map": &"normal_a",
		},
		"params": {"depth_distance": 18.0, "beers_law": 3.0, "displacement_strength": 0.25, "influence_size": 2.5},
		"converted": "코드 변환은 없음. 대신 project.godot에 [shader_globals]로 wind_intensity / wind_direction / player_position 세 개를 등록해야 정상 동작한다(없으면 '전역 파라미터 제거됨' 경고와 함께 깨진 값이 들어감).",
		"note": "이 셋에서 기능이 제일 많다 — 흡수 기반 색, 프레넬, OpenSimplex2 코스틱, 손으로 짠 SSR 레이마치, 플레이어 파문. 셰이더 상단 #define을 끄면 그만큼 싸진다. SSR이 압도적으로 비싸다.",
	},
	{
		"id": 11, "file": "11_wind_waker_water", "title": "Wind Waker Water",
		"url": "https://godotshaders.com/shader/wind-waker-water-no-textures-needed/",
		"kind": Kind.SURFACE_3D, "mesh": MeshKind.PLANE, "transparent": false,
		"origin": "Godot 3.x", "feeds": [],
		"textures": {},
		"params": {"tile": Vector2(3, 3), "height": 0.35, "wave_size": Vector2(3, 3)},
		"converted": "hint_color → source_color (4곳). 그게 전부.",
		"note": "텍스처 0개. 포말이 하드코딩된 원 75개라서 프래그먼트마다 그 목록을 두 번 훑는다. 13번과 같은 뿌리(NekotoArts)인데 이쪽이 원본이고 더 가볍다.",
	},
	{
		"id": 12, "file": "12_orthogonal_camera_water", "title": "Orthogonal Camera Water",
		"url": "https://godotshaders.com/shader/orthogonal-camera-view-water-shader-for-godot-4/",
		"kind": Kind.SURFACE_3D, "mesh": MeshKind.PLANE, "transparent": true,
		"origin": "Godot 4.6", "feeds": [],
		"textures": {"caustics": &"caustics", "noise": &"noise_soft", "normalmap": &"normal_a"},
		"params": {"tile": 6.0, "height_scale": 0.3, "intersection_max_threshold": 1.2},
		"converted": "변환 없음. 다만 두 노이즈 샘플러에 repeat_enable을 붙였다 — wave()가 UV를 0~1 밖으로 크게 밀어서 안 그러면 가장자리가 늘어난다.",
		"note": "직교 카메라 전용이다. ALBEDO/ALPHA를 SCREEN_UV.y로 만들기 때문에 원근 카메라에선 화면 위아래로 그라디언트가 딸려온다. 상단 바의 [직교] 버튼을 켜고 보자.",
	},
	{
		"id": 13, "file": "13_toon_style_3d_water", "title": "Toon Style 3D Water",
		"url": "https://godotshaders.com/shader/toon-style-3d-water-shader-no-textures-needed/",
		"kind": Kind.SURFACE_3D, "mesh": MeshKind.PLANE, "transparent": true,
		"origin": "Godot 4.3", "feeds": [],
		"textures": {},
		"params": {"tile": Vector2(3, 3), "wave_amplitude": 0.25, "water_depth_factor": 0.12},
		"converted": "`uniform float wave_speed = 2;` → `2.0`.",
		"note": "11번의 원 목록을 그대로 쓰면서 깊이 기반 투명도와 교차 포말을 얹은 버전. 11번과 나란히 놓고 보면 '텍스처 없는 툰 물'이 깊이를 만나면 어떻게 달라지는지 바로 보인다.",
	},
	{
		"id": 14, "file": "14_stylized_water_depthfade", "title": "Stylized Water w/ DepthFade",
		"url": "https://godotshaders.com/shader/stylized-water-with-depthfade/",
		"kind": Kind.SURFACE_3D, "mesh": MeshKind.PLANE, "transparent": true,
		"origin": "Godot 3.x", "feeds": [],
		"textures": {"noise1": &"noise_soft", "noise2": &"noise_soft2", "normalmap": &"normal_a"},
		"params": {"speed": 0.15, "beer_law_factor": 1.5, "_distance": 4.0, "edge_scale": 0.4, "wave_frequ": Vector2(1.1, 1.1), "wave_strength": Vector2(0.22, 0.12)},
		"converted": "이 셋에서 가장 손이 많이 간 포팅: hint_color, NORMALMAP, SCREEN/DEPTH_TEXTURE 유니폼화에 더해 (1) `1f`/`4f`/`70f`/`100f`처럼 소수점 없는 f 리터럴을 전부 고치고 (2) rim()의 3.x NDC 깊이 공식을 역Z 언프로젝션으로 바꾸고 (3) 전역 함수에서 INV_PROJECTION_MATRIX를 직접 못 읽어서 인자로 넘기게 바꾸고 (4) 4.x에서 사라진 specular_phong을 specular_schlick_ggx로 교체하고 (5) 0으로 나누던 _distance 기본값을 1.0으로 올렸다",
		"note": "`1.0f`는 4.7에서 되지만 `1f`는 안 된다. 이 셰이더가 그 차이를 정확히 밟은 케이스.",
	},
	{
		"id": 15, "file": "15_cartoon_3d_water", "title": "Cartoon 3D Water (outlined)",
		"url": "https://godotshaders.com/shader/cartoon-3d-water/",
		"kind": Kind.SURFACE_3D, "mesh": MeshKind.PLANE, "transparent": true,
		"origin": "Godot 4.x", "feeds": [],
		"textures": {},
		"params": {"_scale": 1.1, "_speed": 0.3, "outline_thickness": 0.05},
		# `seamless` samples 3D noise by normalize(world_pos). On a sphere that is
		# the surface direction and tiles perfectly; on a flat plane every point
		# normalises into the XZ circle, so the noise degenerates into radial
		# streaks and the shader looks broken. The plane has to fall back to the
		# UV path, and it needs a much higher _scale because UV only spans 0..1.
		"mesh_overrides": {
			MeshKind.PLANE: {"seamless": false, "_scale": 6.0, "outline_thickness": 0.0035},
			MeshKind.SPHERE: {"seamless": true, "_scale": 1.1, "outline_thickness": 0.05},
			MeshKind.VFX_PROPS: {"seamless": true, "_scale": 1.6, "outline_thickness": 0.04},
		},
		"converted": "변환 없음. getNoise의 vec2/vec3 오버로드와 그걸 고르는 삼항 연산자, 빈 `group_uniforms;` 종료자 모두 4.7에서 그대로 통과.",
		"note": "seamless=true면 3D 노이즈를 normalize(물체좌표)로 샘플해서 닫힌 메시에 이음매 없이 감긴다. 평면에서는 모든 점이 XZ 원으로 정규화돼 방사형 줄무늬로 뭉개지므로, 평면을 고르면 자동으로 seamless를 끄고 UV 경로(_scale도 함께)로 전환된다. [메시] 버튼으로 구↔평면을 바꿔보면 같은 셰이더가 두 방식으로 도는 걸 볼 수 있다.",
	},
	{
		"id": 16, "file": "16_cs2_water", "title": "CS 2 Water (flow map)",
		"url": "https://godotshaders.com/shader/cs-2-water/",
		"kind": Kind.SURFACE_3D, "mesh": MeshKind.PLANE, "transparent": true,
		"origin": "Godot 4.x", "feeds": [],
		"textures": {"normal_map": &"normal_a", "flow_map": &"flow_map", "base_texture": &"debris"},
		"params": {"fog_end": 34.0, "wave_strength": 0.08, "flow_strength": 0.8, "water_color": Vector3(0.16, 0.42, 0.52), "deep_color": Vector3(0.03, 0.14, 0.24)},
		"converted": "normal_map / flow_map의 source_color 힌트 제거(각각 hint_normal, 무힌트). 법선맵과 방향 데이터를 sRGB 디코딩해서 normalize(n1+n2-1)이 뒤집히고 표면이 새까맣게 나왔다. base_texture는 진짜 색이라 source_color 유지. 러시아어 주석은 그대로 뒀다.",
		"note": "Source 2식 flow map으로 흐름 방향을 주는 물. flow map의 R/G가 곧 흐름 벡터라, flow_map 텍스처를 바꾸면 물살 방향이 통째로 달라진다. 전체적으로 탁하게 나오는 건 원본 구조 때문 — 굴절해서 가져온 화면 색을 unshaded가 아니라 ALBEDO로 넣어서 다시 라이팅을 먹인다. 밝게 하려면 water_color를 올리거나 roughness_val을 키워보자.",
	},
	{
		"id": 17, "file": "17_water_toon_like_44", "title": "Water Shader (toon-like) 4.4",
		"url": "https://godotshaders.com/shader/water-shader-toon-like-godot-4-4/",
		"kind": Kind.SURFACE_3D, "mesh": MeshKind.PLANE, "transparent": true,
		"origin": "Godot 4.4+", "feeds": [],
		"textures": {"norRand1": &"normal_a", "norRand2": &"normal_b", "edgeNoise": &"noise_fine"},
		"params": {"noiseScaler": 0.02, "distScaler": 0.25, "edgeThreshold": 0.35, "alpha": 0.75},
		"converted": "변환 없음. 여기 있는 `0.65f`/`1.0f`는 소수점이 있어서 4.7에서 합법이다(14번의 `1f`와 대조).",
		"note": "world_vertex_coords를 써서 평면을 옮겨도 파도 위상이 월드에 고정된다. 프레넬 + 물가 흰 테두리 + 깊이 색을 세 겹으로 섞는 구성.",
	},
	{
		"id": 18, "file": "18_water_line_darker", "title": "Water Line Darker (overlay)",
		"url": "https://godotshaders.com/shader/make-the-water-line-darker-v1-0/",
		"kind": Kind.OVERLAY_3D, "mesh": MeshKind.PLANE, "transparent": false,
		"origin": "Godot 4.3", "feeds": [],
		"textures": {},
		"params": {"water_sharpness": 0.45, "height_modifier": 2.0},
		"converted": "변환 없음.",
		"note": "물 표면이 아니다. blend_mul 오버레이라 MeshInstance3D의 material_overlay 슬롯에 넣어 '물에 잠긴 부분만 어둡게' 만드는 용도. 그래서 이걸 고르면 물 대신 바위·기둥 쪽에 적용되고, 물은 직전에 보던 셰이더가 그대로 남는다.",
	},
	{
		"id": 19, "file": "19_cosine_water", "title": "Cosine Water 2",
		"url": "https://godotshaders.com/shader/cosine-water-2/",
		"kind": Kind.CANVAS_2D, "mesh": MeshKind.PLANE, "transparent": true,
		"origin": "미표기", "feeds": [],
		"textures": {},
		"params": {"uv_scale": 1.0},
		"converted": "변환 없음(#define 별칭 포함).",
		"note": "2D 셰이더. 코사인 파 16개를 겹치고 유한차분으로 법선을 뽑아 스펙큘러까지 만든다. 픽셀당 height()를 48번 부르는 구조라 이 셋의 2D 중 제일 비싸다.",
	},
	{
		"id": 20, "file": "20_water_toon_torrent", "title": "Water Toon Torrent",
		"url": "https://godotshaders.com/shader/water-toon-torrent-shader/",
		"kind": Kind.CANVAS_2D, "mesh": MeshKind.PLANE, "transparent": true,
		"origin": "미표기 (Leon Denise / Shadertoy)", "feeds": [],
		"textures": {},
		"params": {"scale": 0.6, "speed": 1.0, "steps": 6},
		"converted": "변환 없음. `vec3(1,1,0)` 유니폼 초기값도, for문 증가절의 콤마 연산자(`++i, a /= 2.`)도 4.7이 받아준다.",
		"note": "자이로이드 FBM을 계단화해서 만드는 토온 급류. steps가 곧 비용 배수다.",
	},
	{
		"id": 21, "file": "21_perlin_procedural_water", "title": "Perlin Procedural Water",
		"url": "https://godotshaders.com/shader/perlin-procedural-water/",
		"kind": Kind.CANVAS_2D, "mesh": MeshKind.PLANE, "transparent": false,
		"origin": "Godot 3.4", "feeds": [],
		"textures": {},
		"params": {"mulscale": 6.0, "foamthickness": 0.08},
		"converted": "hint_color → source_color (3곳).",
		"note": "2D 탑다운 물. FBM 등고선을 두 개 띄워서 포말선과 그림자선을 만든다. 파라미터 `input`이 GLSL이면 예약어지만 Godot 셰이더 언어에선 아니라 그대로 컴파일된다.",
	},
	{
		"id": 22, "file": "22_fbm_toon_water", "title": "FBM Toon Water",
		"url": "https://godotshaders.com/shader/fbm-toon-water/",
		"kind": Kind.SURFACE_3D, "mesh": MeshKind.PLANE, "transparent": false,
		"origin": "Godot 3.x", "feeds": [],
		"textures": {"nTexture": &"noise_foamy"},
		"params": {},
		"converted": "hint_black→hint_default_black, 그리고 TRANSMISSION → BACKLIGHT. TRANSMISSION은 이름이 바뀐 게 아니라 Godot 4에서 아예 삭제돼서 'Unknown identifier'로 죽는다.",
		"note": "원작자는 nTexture에 SubViewport로 렌더한 canvas_item 노이즈를 넣으라고 했는데, 여기선 설정을 줄이려고 FastNoiseLite 텍스처를 물렸다. 원래 의도대로 하려면 ViewportTexture로 바꿔 끼우면 된다.",
	},
	{
		"id": 23, "file": "23_snells_window", "title": "Snell's Window",
		"url": "https://godotshaders.com/shader/snells-window/",
		"kind": Kind.SURFACE_3D, "mesh": MeshKind.PLANE, "transparent": false,
		"origin": "Godot 4.x", "feeds": [],
		"textures": {"normal_map_texture": &"normal_fine"},
		"params": {"index_of_refraction": 1.333, "water_color": Vector3(0.09, 0.26, 0.40)},
		"converted": "변환 없음. RADIANCE/IRRADIANCE 기록도 4.7에서 유효.",
		"note": "수면 아래에서 위를 볼 때 생기는 원형 창(전반사 경계) 재현. 위에서 보면 그냥 거울이라 의미가 없다 — 상단 바 [잠수] 버튼으로 카메라를 수면 아래로 내려야 진짜 효과가 보인다.",
	},
	{
		"id": 24, "file": "24_sine_wave_camera_view", "title": "Sine Wave Camera View",
		"url": "https://godotshaders.com/shader/sine-wave-camera-view-shader/",
		"kind": Kind.POST_FX, "mesh": MeshKind.PLANE, "transparent": true,
		"origin": "미표기", "feeds": [],
		"textures": {},
		"params": {"frequency": 10.0, "amplitude": 0.01},
		"converted": "변환 없음. 다만 원본이 10.0/0.01을 코드에 박아둬서, 인스펙터에서 만질 수 있게 frequency/amplitude/speed 유니폼으로 빼냈다(기본값은 원본과 동일).",
		"note": "물 표면이 아니라 화면 전체 후처리다. 그래서 [후처리] 버튼으로 켜면 지금 보고 있는 아무 3D 셰이더 위에 겹쳐서 쓸 수 있다.",
	},
	{
		"id": 25, "file": "25_circular_waves_2d", "title": "Circular Waves 2D",
		"url": "https://godotshaders.com/shader/circular-waves-2d/",
		"kind": Kind.CANVAS_2D, "mesh": MeshKind.PLANE, "transparent": true,
		"origin": "미표기", "feeds": [],
		"textures": {"noise": &"noise_soft"},
		"params": {"frequency": 12.69, "rippleRate": 9.2},
		"converted": "변환 없음. `hint_range(0, 2, 0.01)`처럼 정수 경계도 4.7이 float 유니폼에 맞춰 승격해준다.",
		"note": "2D 파문 링 한 장. 알파를 직접 만들어 쓰기 때문에 어두운 배경 위에 올려야 제대로 보인다.",
	},
	]
	_entries = list
	return _entries


## Look one entry up by its 1-based catalogue id. Returns an empty dictionary
## when nothing matches, so callers can guard with is_empty().
static func by_id(id: int) -> Dictionary:
	for entry: Dictionary in entries():
		if entry["id"] == id:
			return entry
	return {}


## "res://shaders/03_realistic_water.gdshader" for entry 3.
static func shader_path(entry: Dictionary) -> String:
	return "res://water/shaders/%s.gdshader" % entry["file"]
