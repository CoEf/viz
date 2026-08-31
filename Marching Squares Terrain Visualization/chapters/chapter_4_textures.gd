extends MstChapter
## 챕터 4 — 브러시로 칠한 "어느 텍스처" 정보가 화면까지 가는 길.
##
## 5장에서 배운 대로 순서를 목적 → 방법으로 잡았다. 먼저 "정점이 들고 갈 칸이
## 모자란다"는 문제를 세우고, 그다음에 인코딩을 꺼낸다. 스텝마다 보는 그림이
## 다르다 — 같은 화면을 두 번 쓰면 그 스텝은 보여 준 게 없는 것이다.

const STEPS: Array[Dictionary] = [
	{
		"title": "정점이 셰이더에 넘길 수 있는 건 숫자 칸뿐이다",
		"body": """브러시가 칠한 건 "여기는 눈, 저기는 바위"라는 정보다.
그런데 정점이 넘길 수 있는 건 [b]vec4 몇 칸이 전부다.[/b]
텍스처 열여섯 장을 그 칸에 어떻게 접어 넣는가.""",
		"chips": [
			{"icon": "script", "text": "chunk.color_map_0 · color_map_1"},
			{"icon": "shader", "text": "COLOR · CUSTOM0~2"},
		],
		"try": "지금 보이는 다섯 가지 지형색이 그 칸을 거쳐 나온 결과다",
	},
	{
		"title": "채널 하나만 켜서 번호를 만든다",
		"body": """정점 색 두 장에서 [b]각각 한 채널만 1로[/b] 켠다.
켜진 채널 짝이 번호다 — 4×4 = 열여섯.
색을 색으로 쓰는 게 아니라 번호표로 쓴다.""",
		"chips": [{"icon": "script", "text": "get_texture_index_from_colors()"}],
		"code": """return c0_idx * 4 + c1_idx""",
		"try": "칠한 자리마다 색이 딱 하나 — 번호는 섞이지 않는다",
	},
	{
		"title": "GPU가 그 채널을 저절로 섞어 준다",
		"body": """한 채널만 켜 둔 값을 GPU가 삼각형 안에서 보간한다.
그러면 경계에서 [b]두 채널이 반씩 켜진 값[/b]이 나온다.
번호로 쓴 것이 그대로 섞임 비율이 되는 셈이다.""",
		"chips": [{"icon": "shader", "text": "varying vec4 vc_color_0"}],
		"code": """raw_weights[1] = vc0.r * vc1.g;
raw_weights[2] = vc0.r * vc1.b;""",
		"try": "칠한 자리 안쪽은 순색, 경계에서만 두 색이 섞인다",
	},
	{
		"title": "그냥 두면 없던 텍스처가 끼어든다",
		"body": """r과 g가 반씩 켜지면 곱셈이 [b]칠한 적 없는 짝[/b]도
0이 아닌 값으로 만든다. 그래서 셀마다 꼭짓점 넷을 세어
많이 나온 순으로 세 개만 남기고 나머지를 버린다.""",
		"chips": [{"icon": "script", "text": "calculate_cell_material_pair()"}],
		"code": """sorted_textures.sort_custom(func(a, b):
    return tex_counts[a] > tex_counts[b])""",
		"try": "셀 안에서는 값이 하나로 평평하다 — 셀 단위로 고른 결과다",
	},
	{
		"title": "번호 셋을 남는 칸에 접어 보낸다",
		"body": """칸이 모자라 번호 셋을 그대로는 못 보낸다.
0~15짜리 둘을 [b]16을 곱해 한 float에 겹쳐[/b] 싣고,
셰이더에서 나머지와 몫으로 도로 뜯는다.""",
		"chips": [
			{"icon": "script", "text": "calculate_material_blend_data()"},
			{"icon": "shader", "text": "CUSTOM2.r"},
		],
		"code": """packed = (mat_a + mat_b * 16.0) / 255.0
mat_a = mod(packed*255.0, 16.0)  # 나머지
mat_b = floor(packed*255.0 / 16.0)  # 몫""",
		"try": "화면 색은 그대로다 — 접었다 편 값이 원래 값과 같다는 뜻",
	},
	{
		"title": "sharpness로 섞이는 띠 폭을 조인다",
		"body": """셋을 꼭짓점 거리 가중치로 섞는다.
sharpness는 그 가중치를 [b]거듭제곱해[/b] 큰 쪽을 키운다.
0이면 흐릿하게 번지고, 크면 칼같이 갈린다.""",
		"chips": [{"icon": "shader", "text": "blend_sharpness"}],
		"code": """float power = 1.0 + blend_sharpness;
weight_a = pow(weight_a, power);""",
		"try": "값을 올리면 텍스처 경계가 좁아지다 선이 된다",
	},
]

var _sharpness := 5.0
var _hard := false
var _caption: Label


func get_chapter_title() -> String:
	return "칠한 텍스처를 화면까지 나르기"


func get_steps() -> Array[Dictionary]:
	return STEPS


## 스텝마다 다른 그림을 본다. 같은 디버그 뷰를 두 스텝이 나눠 쓰면
## 뒤 스텝은 자기 기법을 보여 준 게 없는 셈이 된다.
func _debug_for(index: int) -> int:
	match index:
		0: return 0   # 완성된 화면
		1: return 3   # 번호를 색으로
		2: return 7   # 보간되는 정점 색 그대로
		3: return 8   # 셀이 고른 텍스처 셋
		4: return 8   # 같은 뷰 — 접었다 편 값이 그대로임을 보이는 게 요지다
		_: return 4   # 섞임 가중치


func apply_step(index: int) -> void:
	world.set_stage_terrain()
	world.set_scatter_visible(false)
	world.set_corner_markers(false)
	world.set_edge_bars(false)
	world.set_wireframe(false)
	world.set_terrain_visible(true)
	world.set_grass_visible(false)
	world.set_ridge_ledge_enabled(false)
	world.set_merge_threshold(1.3)
	world.sculpt_to(4)
	world.set_blend_mode(1 if (_hard and index == 1) else 0)
	world.set_blend_sharpness(_sharpness)
	world.set_debug_mode(_debug_for(index))

	world.set_pivot(Vector3(20.0, 1.0, 20.0))
	if index == 2:
		# 섞이는 띠는 셀 한 칸 폭이라 멀리서는 안 보인다. 진흙(c0.g)과 풀(c0.r)이
		# 맞닿는 구덩이 가장자리를 바짝 잡는다.
		world.set_pivot(Vector3(31.0, -0.6, 10.0))
		world.camera_rig.set_view(0.62, -0.70, 11.0)
	elif index >= 3:
		world.camera_rig.set_view(0.0, -1.15, 40.0)
	else:
		world.camera_rig.set_view(0.78, -0.44, 40.0)
	_sync_caption()


func build_panel(parent: VBoxContainer) -> void:
	add_toggle(parent, "하드 텍스처 모드 (칸 하나만 쓰기)", _hard,
			func(pressed: bool) -> void:
				_hard = pressed
				world.set_blend_mode(1 if pressed else 0),
			[1])
	add_slider(parent, "blend_sharpness", 0.0, 10.0, _sharpness,
			func(value: float) -> void:
				_sharpness = value
				world.set_blend_sharpness(value)
				_sync_caption(),
			[5])
	_caption = add_caption(parent, "")


func _sync_caption() -> void:
	if not _caption:
		return
	match current_step:
		0:
			_caption.text = ("쓰는 칸은 COLOR(vec4) · CUSTOM0(vec4) · CUSTOM2(vec4).\n"
					+ "이 지형이 쓰는 텍스처: 풀 0 · 흙 1 · 바위 2 · 눈 3 · 진흙 4 · 벽돌 5")
		1:
			_caption.text = "칸 번호마다 색 하나. 0~5번만 쓰고 15번은 투명 칸이다."
		2:
			_caption.text = ("빨강 = c0.r 켜짐(칸 0~3), 초록 = c0.g 켜짐(칸 4~5).\n"
					+ "경계의 노란 띠가 GPU가 둘을 섞어 놓은 자리다.")
		3:
			_caption.text = ("R = 첫째 텍스처, G = 둘째, B = 셋째 (번호를 15로 나눈 값).\n"
					+ "셀 하나 안에서는 평평하다 — flat으로 넘기기 때문이다.")
		4:
			_caption.text = ("예: 첫째 0(풀), 둘째 2(바위) → (0 + 2×16)/255 = 0.1255\n"
					+ "되돌리면 32를 16으로 나눠 나머지 0, 몫 2 — 원래 두 번호다.")
		_:
			_caption.text = ("sharpness %.1f → 가중치를 %.1f제곱한다.\n" % [_sharpness, 1.0 + _sharpness]
					+ "0이면 그대로 선형 보간, 올릴수록 큰 쪽만 살아남는다.")
