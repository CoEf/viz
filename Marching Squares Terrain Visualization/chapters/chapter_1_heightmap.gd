extends MstChapter
## 챕터 1 — 브러시 네 종류가 높이맵에 무엇을 쓰는가.

const STEPS: Array[Dictionary] = [
	{
		"title": "지형을 깎는다는 건 숫자판을 고치는 일이다",
		"body": """청크가 들고 있는 건 2차원 실수 배열 하나다.
21×21 칸, 칸마다 float 하나.
[b]메시는 여기서 나온 결과일 뿐이다.[/b]""",
		"chips": [{"icon": "script", "text": "chunk.height_map"}],
		"code": """height_map[z][x] = 0.0""",
		"try": "파란 격자 한 칸이 셀 하나",
	},
	{
		"title": "브러시로 기존 높이에 차이 더하기",
		"body": """브러시는 메시를 만지지 않는다.
닿은 꼭짓점의 [b]지금 높이에 차이를 더해[/b]
그 자리에 다시 쓴다.""",
		"chips": [
			{"icon": "script", "text": "draw_pattern()"},
			{"icon": "script", "text": "chunk.draw_height()"},
		],
		"code": """var diff := brush_pos.y - draw_height
draw_value = lerp(restore,
    restore + diff, sample)""",
		"try": "브러시 크기를 줄이면 언덕이 뾰족해진다",
	},
	{
		"title": "폴오프를 끄면 원기둥이 솟는다",
		"body": """지금은 폴오프가 꺼져 있다 — 브러시 안이 통째로
같은 높이만큼 올라 원기둥이 됐다.
[b]거리에 따라 세기를 달리 주려고[/b] 곡선을 한 번 통과시킨다.""",
		"chips": [
			{"icon": "script", "text": "BrushPatternCalculator"},
			{"icon": "resource", "text": "curve_falloff.tres"},
		],
		"code": """var d := (max_distance - distance_squared)
         / max_distance
return falloff_curve.sample(t)""",
		"try": "폴오프를 켜면 가장자리가 눅어 언덕이 된다",
	},
	{
		"title": "레벨로 정해 둔 한 높이에 맞추기",
		"body": """쓰는 자리는 브러시와 똑같다.
다른 건 목표뿐 — 지금 높이가 아니라
[b]정해 둔 height로[/b] 끌어당긴다.""",
		"chips": [{"icon": "setting", "text": "TerrainToolMode.LEVEL"}],
		"code": """draw_value = lerp(restore, height, sample)""",
		"try": "왼쪽 언덕 윗면이 한 높이로 잘린다",
	},
	{
		"title": "스무드로 이웃 평균에 맞추기",
		"body": """목표가 상수가 아니라
[b]닿은 꼭짓점들의 평균[/b]이다.
strength가 한 번에 얼마나 갈지를 정한다.""",
		"chips": [{"icon": "setting", "text": "TerrainToolMode.SMOOTH"}],
		"code": """avg_height /= heights.size()
draw_value = lerp(restore, avg_height,
    sample * strength)""",
		"try": "오른쪽 언덕의 계단이 줄어든다",
	},
	{
		"title": "브리지로 두 점 사이를 굽혀 잇기",
		"body": """두 점을 이은 선 위에서의 진행도를 재고,
[b]ease()로 그 진행도를 굽힌다.[/b]
굽은 정도가 그대로 다리 곡선이 된다.""",
		"chips": [{"icon": "setting", "text": "TerrainToolMode.BRIDGE"}],
		"code": """progress = ease(progress, ease_value)
draw_value = lerpf(start.y, end.y, progress)""",
		"try": "ease 값을 1로 → 다리가 곧은 경사가 된다",
	},
]

var _brush_size := 17.0
## 1번 스텝은 폴오프를 켠 채로, 2번은 끈 채로 들어간다 — 같은 그림이 두 번
## 나오면 뒤 스텝은 자기 기법을 보여 준 게 없는 셈이라 그렇게 갈랐다.
var _use_falloff := true
var _ease := 2.4
var _falloff_toggle: CheckButton


func get_chapter_title() -> String:
	return "지형을 손으로 깎는 법"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.set_stage_terrain()
	world.set_merge_threshold(1.3)
	world.set_grass_visible(false)
	world.set_corner_markers(false)
	world.set_edge_bars(false)
	world.set_wireframe(false)
	world.set_terrain_visible(true)
	world.set_debug_mode(6 if index == 0 else 0)
	world.camera_rig.set_view(0.62, -0.52, 52.0)

	match index:
		0:
			world.sculpt_to(0)
		1:
			_use_falloff = true
			if _falloff_toggle:
				_falloff_toggle.set_pressed_no_signal(true)
			_redraw_brush()
			update_code(_brush_code())
		2:
			_use_falloff = false
			if _falloff_toggle:
				_falloff_toggle.set_pressed_no_signal(false)
			_redraw_brush()
		3:
			world.sculpt_to(2)
		4:
			world.sculpt_to(3)
		5:
			world.sculpt_bridge_with_ease(_ease)
			update_code(_bridge_code())
			world.camera_rig.set_view(0.95, -0.44, 44.0)


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "브러시 크기", 6.0, 26.0, _brush_size,
			func(value: float) -> void:
				_brush_size = value
				_redraw_brush()
				if current_step == 1:
					update_code(_brush_code()),
			[1, 2])
	_falloff_toggle = add_toggle(parent, "폴오프 쓰기", _use_falloff,
			func(pressed: bool) -> void:
				_use_falloff = pressed
				_redraw_brush(),
			[2])
	add_slider(parent, "ease 값", 0.2, 4.0, _ease,
			func(value: float) -> void:
				_ease = value
				world.sculpt_bridge_with_ease(value)
				update_code(_bridge_code()),
			[5])
	add_caption(parent, "브러시 하나만 찍어 놓고 크기와 폴오프를 본다.", [1, 2])


func _redraw_brush() -> void:
	world.sculpt_single_brush(_brush_size, 5.2, _use_falloff, 0)


func _brush_code() -> String:
	return ("var diff := brush_pos.y - draw_height\n"
			+ "draw_value = lerp(restore,\n"
			+ "    restore + diff, sample)\n"
			+ "# brush_size = %.1f  ← 슬라이더" % _brush_size)


func _bridge_code() -> String:
	return ("progress = ease(progress, %.2f)\n" % _ease
			+ "draw_value = lerpf(start.y, end.y, progress)")
