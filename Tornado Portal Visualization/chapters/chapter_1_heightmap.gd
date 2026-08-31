extends TornadoChapter
## 챕터 1 — 절차적 하이트맵. 소용돌이 마스크 식이 그대로 높이 필드가 된다.
## 텍스처를 굽지 않으니 시간에 따라 변하고, opening 하나로 크기와 깊이가 같이 움직인다.

const STEPS: Array[Dictionary] = [
	{
		"title": "높이 필드를 함수로 만들기",
		"body": """POM의 하이트맵 자리에 텍스처 대신 [b]함수[/b]를 넣었다.
나선 좌표로 감은 보로노이에서
"좁은 경계는 남기고 넓은 구간을 갉는" 4편의 식 그대로.""",
		"chips": [{"icon": "shader", "text": "get_depth()"}],
		"code": """return max(0.0, (1.0 - edge)
    - voronoi * outter_edge);""",
		"try": "흰 곳이 깊다 — 소용돌이 마스크가 곧 높이다",
	},
	{
		"title": "opening 하나로 크기와 깊이",
		"body": """opening이 edge 두 개의 기준이라
[b]구멍 크기와 파이는 깊이가 같이 움직인다[/b].
여는 애니메이션이 곧 파는 애니메이션.""",
		"chips": [{"icon": "shader", "text": "opening"}],
		"try": "0으로 → 닫히면서 높이 필드도 사라진다",
	},
	{
		"title": "시간이 하이트맵을 돌린다",
		"body": """time_offset이 나선 위상과 노이즈 좌표에 들어 있다.
텍스처였다면 시퀀스를 굽거나 UV를 돌려야 하는데,
[b]함수라서 그냥 인자[/b]다.""",
		"chips": [{"icon": "shader", "text": "time_offset"}],
		"try": "돌려 보면 → 높이 필드 자체가 회전한다",
	},
]

var _opening := 1.0
var _time := 0.0


func _ready() -> void:
	world.stop()
	world.solo(true, false, false, false)
	world.camera_rig.position = Vector3(0.0, 0.3, 0.0)
	world.camera_rig.set_view(0.3, -1.2, 5.0)


func get_chapter_title() -> String:
	return "절차적 하이트맵 — 텍스처 없는 깊이"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.stop()
	world.solo(true, false, false, false)
	world.reset_hole_params(_opening)
	world.set_hole_param("debug_mode", 1)
	world.set_hole_param("time_offset", _time)
	match index:
		1:
			update_code(_opening_code())
		2:
			update_code(_time_code())


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "opening", 0.0, 1.0, _opening, _on_opening_changed, [1])
	add_slider(parent, "time_offset", 0.0, 8.0, _time, _on_time_changed, [2])


func _on_opening_changed(value: float) -> void:
	_opening = value
	world.set_hole_param("opening", value)
	if current_step == 1:
		update_code(_opening_code())


func _on_time_changed(value: float) -> void:
	_time = value
	world.set_hole_param("time_offset", value)
	if current_step == 2:
		update_code(_time_code())


func _opening_code() -> String:
	return ("edge = smoothstep(%.2f - 0.5, %.2f,\n" % [_opening, _opening]
			+ "    dist); ← 슬라이더 (깊이도 같이)")


func _time_code() -> String:
	return ("s = swirl(uv, 8.0, 1, -%.1f * 0.4);\n" % _time
			+ "// 하이트맵이 통째로 회전 ← 슬라이더")
