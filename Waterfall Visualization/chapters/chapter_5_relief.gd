extends WaterfallChapter
## 챕터 5 — 입체감. 정점 변위로 실루엣을, 노멀맵으로 표면 빛을 흔든다.

const STEPS: Array[Dictionary] = [
	{
		"title": "정점을 밀어 출렁이게",
		"body": """실루엣이 [b]종잇장[/b]이면 색이 다 돼도 가짜다.
같은 물 그림을 이번엔 [b]변위값[/b]으로 읽어
정점을 법선 방향으로 밀어낸다.""",
		"chips": [
			{"icon": "shader", "text": "vertex()"},
			{"icon": "texture", "text": "waterfall_texture.png"},
		],
		"code": """displace_parameter = 0.05 // ← 슬라이더
VERTEX += (NORMAL + dis)
		* displace_parameter;""",
		"try": "0 → 종잇장 · 0.2 → 부글부글",
	},
	{
		"title": "무늬로 빛까지 속이기",
		"body": """진짜 요철 대신 [b]법선만 왜곡[/b]한다.
물결 오버레이를 노멀맵으로 재활용 —
밝은 무늬가 빛 받는 각도를 흔든다.""",
		"chips": [
			{"icon": "shader", "text": "NORMAL_MAP"},
			{"icon": "setting", "text": "normal_depth"},
		],
		"code": """NORMAL_MAP = overlay.rgb;
NORMAL_MAP_DEPTH = 0.5; // ← 슬라이더""",
		"try": "0 ↔ 1 오가며 표면 반짝임 비교",
	},
]

var _displace := 0.05
var _normal_depth := 0.5


func get_chapter_title() -> String:
	return "입체감 넣기"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.reset_materials()
	world.show_water(true, false)
	world.set_effects(false, false)
	world.set_sky(true)
	world.sun.visible = true
	world.set_fall_param(&"displace_parameter", _displace)
	world.set_fall_param(&"normal_depth", 0.0 if index == 0 else _normal_depth)
	if index == 0:
		# 실루엣이 주인공 — 옆에서 비껴 보면 정점이 밀리는 게 또렷하다.
		world.frame(Vector3(0, 0.15, 0), 0.85, -0.10, 2.8)
		update_code(_displace_code())
	else:
		world.frame(Vector3(0, 0.1, 0), 0.35, -0.08, 3.2)
		update_code(_normal_code())


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "변위량 (displace_parameter)", 0.0, 0.2, _displace,
			_on_displace_changed, [0, 1])
	add_slider(parent, "노멀맵 깊이 (normal_depth)", 0.0, 1.0, _normal_depth,
			_on_normal_changed, [1])


func _on_displace_changed(value: float) -> void:
	_displace = value
	world.set_fall_param(&"displace_parameter", value)
	if current_step == 0:
		update_code(_displace_code())


func _on_normal_changed(value: float) -> void:
	_normal_depth = value
	if current_step == 1:
		world.set_fall_param(&"normal_depth", value)
		update_code(_normal_code())


func _displace_code() -> String:
	return ("displace_parameter = %.2f // ← 슬라이더\n" % _displace
			+ "VERTEX += (NORMAL + dis)\n\t\t* displace_parameter;")


func _normal_code() -> String:
	return ("NORMAL_MAP = overlay.rgb;\n"
			+ "NORMAL_MAP_DEPTH = %.2f; // ← 슬라이더" % _normal_depth)
