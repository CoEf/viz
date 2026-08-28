extends RoomsChapter
## 챕터 2 — MST로 최소 연결을 만들고, 여분 간선으로 순환로를 되살린다.

const STEPS: Array[Dictionary] = [
	{
		"title": "최소 신장 트리로 뼈대 남기기",
		"body": """후보 중 [b]모든 방을 잇는 최소한[/b]만 고른다.
짧은 간선부터 넣되 이미 이어진 두 방은 건너뛴다.
결과는 순환로가 하나도 없는 나무 구조다.""",
		"chips": [
			{"icon": "script", "text": "mst_generator.gd"},
			{"icon": "setting", "text": "AStar2D"},
		],
		"code": """edges.sort_custom(
    func(a, b): return a.distance < b.distance)""",
		"try": "노란 선만 남았다 — 어디든 가는 길이 딱 하나",
	},
	{
		"title": "여분 간선으로 순환로 되살리기",
		"body": """길이 하나뿐인 던전은 막다른 길투성이다.
버린 후보 중 일부를 [b]다시 집어넣어[/b] 되돌아오는 길을 만든다.""",
		"chips": [{"icon": "script", "text": "edge_selector.gd"}],
		"try": "아래 슬라이더로 비율을 바꿔 보기",
	},
]

var _loop_ratio := 0.15


func get_chapter_title() -> String:
	return "최소 연결과 순환로"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.camera_rig.set_view(0.0, -0.06, 22.0)
	if index == 0:
		world.show_stage(&"mst")
	else:
		world.show_stage(&"loop", _loop_ratio)
		update_code(_loop_code())


func build_panel(parent: VBoxContainer) -> void:
	# 스텝 0은 여분 간선이 하나도 없는 순수 MST 화면이다.
	add_slider(parent, "여분 간선 비율", 0.0, 1.0, 0.15, _on_ratio_changed, [1])
	add_caption(parent, "0이면 순수 트리, 1이면 후보 간선 전부 사용", [1])


func _on_ratio_changed(value: float) -> void:
	_loop_ratio = value
	if current_step == 1:
		world.show_stage(&"loop", value)
		update_code(_loop_code())


func _loop_code() -> String:
	return ("loop_percentage = %.2f   # ← 슬라이더\n" % _loop_ratio
			+ "// 여분 간선 %d개 추가됨" % world.loop_edges.size())
