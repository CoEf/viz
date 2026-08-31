extends MstChapter
## 챕터 2 — 셀 하나가 네 꼭짓점 높이에서 삼각형을 뽑는 과정. 이 플러그인의 심장.

const STEPS: Array[Dictionary] = [
	{
		"title": "네 꼭짓점만 보고 셀 하나 짓기",
		"body": """셀이 보는 것은 꼭짓점 네 개의 높이뿐이다.
이웃 셀도, 전체 지형도 보지 않는다.
코드도 그 이름 그대로 [b]A B C D[/b]로 부른다.""",
		"chips": [{"icon": "script", "text": "MarchingSquaresTerrainCell"}],
		"code": """_ay = y_top_left
_by = y_top_right
_cy = y_bottom_left""",
		"try": "네 슬라이더로 높이를 바꿔 보기",
	},
	{
		"title": "merge_threshold로 벽 세우기",
		"body": """두 꼭짓점의 높이 차가 문턱보다 작으면 잇고,
크면 [b]그 사이에 벽을 세운다.[/b]
변 네 개가 각각 따로 판정된다.""",
		"chips": [{"icon": "script", "text": "cell.rotation setter"}],
		"code": """ab = abs(ay-by) < merge_threshold
bd = abs(by-dy) < merge_threshold""",
		"try": "문턱을 올리면 빨간 막대가 초록으로 바뀐다",
	},
	{
		"title": "네 변이 다 이어지면 바닥으로 덮기",
		"body": """가장 흔한 경우가 케이스 0이다.
네 꼭짓점 평균으로 [b]가운데 점을 하나 더 두고[/b]
삼각형 넷으로 덮는다.""",
		"chips": [{"icon": "script", "text": "add_full_floor()"}],
		"code": """if all_edges_are_connected():
    add_c0()
var ey := (ay+by+cy+dy)/4""",
		"try": "가는 선이 삼각형 경계 — 넷이 가운데서 만난다",
	},
	{
		"title": "셀을 돌려 가며 같은 조건 재보기",
		"body": """같은 모양이 방향만 달리 나타난다.
셀을 네 번 돌려 가며 같은 조건을 시험해
[b]써야 할 케이스를 네 배 아낀다.[/b]""",
		"chips": [
			{"icon": "script", "text": "rotation setter"},
			{"icon": "script", "text": "add_point()"},
		],
		"code": """for rot in range(4):
    rotation = rot as CellRotation
    # 같은 조건표를 처음부터 다시""",
		"try": "A만 올렸다 D만 올려 보기 — 케이스 번호가 같다",
	},
	{
		"title": "열아홉 조건으로 모든 조합 덮기",
		"body": """조건문이 위에서부터 걸린다.
먼저 걸린 케이스가 이기고 거기서 멈춘다.
[b]하나도 안 걸리면 그냥 평면을 깐다.[/b]""",
		"chips": [{"icon": "script", "text": "generate_geometry()"}],
		"code": """elif is_lower(ay, by) and is_lower(ay, cy)
     and bd and cd:
    add_c7()""",
		"try": "프리셋을 바꾸면 걸리는 케이스 번호가 같이 바뀐다",
	},
	{
		"title": "조각 다섯 개를 돌려 붙여 조립하기",
		"body": """열아홉 케이스가 삼각형을 새로 짜지 않는다.
바닥·바깥모서리·모서리벽·안쪽모서리·대각바닥
[b]다섯 조각을 돌려 가며 붙일 뿐이다.[/b]""",
		"chips": [
			{"icon": "script", "text": "add_outer_corner()"},
			{"icon": "script", "text": "add_edge()"},
			{"icon": "script", "text": "add_inner_corner()"},
		],
		"code": """func add_c3() -> void:
    add_edge(true, true, 0.5, 1)
    add_outer_corner(false, true, true, by)""",
		"try": "케이스가 바뀔 때 삼각형 수도 같이 바뀐다",
	},
]

## 스텝 4·5에서 돌려 볼 네 꼭짓점 높이 조합. 서로 다른 케이스가 걸리도록 골랐다.
const PRESETS := [
	{"name": "평평", "h": [0.0, 0.0, 0.0, 0.0]},
	{"name": "A만 높음", "h": [3.0, 0.0, 0.0, 0.0]},
	{"name": "AB 한 변이 높음", "h": [3.0, 3.0, 0.0, 0.0]},
	{"name": "A만 낮음", "h": [0.0, 3.0, 3.0, 3.0]},
	{"name": "A가 B보다 한 단 더", "h": [4.0, 2.5, 0.0, 0.0]},
	{"name": "대각선으로 높음", "h": [0.0, 3.0, 3.0, 0.0]},
	{"name": "계단처럼 오름", "h": [0.0, 2.0, 4.0, 6.0]},
	{"name": "세 단 나선", "h": [0.0, 2.2, 6.2, 4.2]},
]

## 그 스텝의 코드 칸에 적힌 케이스가 실제로 걸리는 조합으로 들어간다.
## 스텝 5는 add_c7(), 스텝 6은 add_c3()을 보여 준다.
const STEP_PRESET := {4: 3, 5: 4}

var _corners := [1.6, 1.6, 1.6, 1.6]
var _threshold := 1.3
var _preset := 0
var _case_caption: Label
var _picker: OptionButton
var _sliders: Array[HSlider] = []


func get_chapter_title() -> String:
	return "마칭 스퀘어스로 셀 짓기"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.set_stage_study()
	world.set_grass_visible(false)
	world.set_debug_mode(1 if index >= 2 else 0)
	world.set_corner_markers(true)
	world.set_edge_bars(index >= 1)
	world.set_wireframe(index >= 2)
	world.set_merge_threshold(_threshold)

	match index:
		0:
			_apply_corners([1.6, 3.4, 0.4, 2.2])
			world.camera_rig.set_view(0.70, -0.55, 14.0)
		1:
			_apply_corners([0.4, 3.6, 1.0, 3.2])
			world.camera_rig.set_view(0.70, -0.52, 14.0)
		2:
			_apply_corners([1.4, 1.9, 1.1, 1.7])
			world.camera_rig.set_view(0.70, -0.62, 13.0)
		3:
			_apply_corners([3.4, 0.2, 0.2, 0.2])
			world.camera_rig.set_view(0.70, -0.58, 13.0)
		4, 5:
			_apply_preset(STEP_PRESET[index])
			world.camera_rig.set_view(0.70, -0.60, 13.0)
	_sync_caption()


func build_panel(parent: VBoxContainer) -> void:
	var names := ["A 높이", "B 높이", "C 높이", "D 높이"]
	for i in range(4):
		var slider := add_slider(parent, names[i], 0.0, 6.0, _corners[i],
				func(value: float) -> void:
					_corners[i] = value
					_push_corners(),
				[0, 1, 2, 3])
		_sliders.append(slider)

	add_slider(parent, "merge_threshold", 0.2, 4.0, _threshold,
			func(value: float) -> void:
				_threshold = value
				world.set_merge_threshold(value)
				_push_corners()
				if current_step == 1:
					update_code(_threshold_code()),
			[1])

	_picker = OptionButton.new()
	for preset in PRESETS:
		_picker.add_item(preset["name"])
	_picker.selected = _preset
	_picker.item_selected.connect(func(index: int) -> void:
		_apply_preset(index))
	parent.add_child(_picker)
	bind_steps([_picker], [4, 5])

	_case_caption = add_caption(parent, "")


func _apply_corners(values: Array) -> void:
	for i in range(4):
		_corners[i] = values[i]
		if i < _sliders.size():
			_sliders[i].set_value_no_signal(values[i])
	_push_corners()


func _apply_preset(index: int) -> void:
	_preset = index
	if _picker:
		_picker.selected = index
	_apply_corners(PRESETS[index]["h"])


func _push_corners() -> void:
	world.set_study_corners(_corners[0], _corners[1], _corners[2], _corners[3])
	_sync_caption()


func _sync_caption() -> void:
	if not _case_caption:
		return
	var edges := world.study_edges()
	var linked := PackedStringArray()
	for key in ["ab", "bd", "cd", "ac"]:
		linked.append("%s %s" % [key, "이음" if edges[key] else "벽"])
	_case_caption.text = "케이스 %d · 삼각형 %d개(벽 %d) · 유효 문턱 %.2f\n%s" % [
		world.study_case(), world.study_triangle_count(),
		world.study_wall_triangle_count(), edges["threshold"],
		" · ".join(linked)]


func _threshold_code() -> String:
	return ("ab = abs(ay-by) < merge_threshold\n"
			+ "bd = abs(by-dy) < merge_threshold\n"
			+ "# merge_threshold = %.2f  ← 슬라이더" % _threshold)
