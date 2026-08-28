extends WaterChapter
## 챕터 4 — L4 Volume. 수심을 재고, 그만큼 색을 빼는 Beer-Lambert 흡수.

const STEPS: Array[Dictionary] = [
	{
		"title": "흡수 없이 통과시키기",
		"body": """굴절까지 켰지만 물에 [b]색이 없다.[/b]
깊은 곳이나 얕은 곳이나 똑같이 훤히 보인다.
물처럼 안 보이는 진짜 이유가 여기 있다.""",
		"chips": [{"icon": "shader", "text": "wt_volume.gdshaderinc"}],
		"try": "먼 바다 쪽을 봐도 바닥이 그대로 보인다",
	},
	{
		"title": "수심을 두 가지로 재기",
		"body": """깊이 텍스처로 바닥까지의 거리를 구한다.
[b]시선 두께[/b]는 폼(교차선)에,
[b]수직 수심[/b]은 색에 쓴다. 물리적으로 맞는 건 후자다.""",
		"chips": [{"icon": "shader", "text": "hint_depth_texture"}],
		"code": """thickness = scene_d - water_d;   // 시선
vertical  = v_world.y - scene_w.y;  // 수직""",
		"try": "지금 화면이 그 수직 수심 — 흰색일수록 깊다",
	},
	{
		"title": "수심만큼 색 빼기",
		"body": """물은 색을 [b]더하는 게 아니라 빼앗는다.[/b]
빨강이 가장 빨리 죽고 파랑이 가장 오래 남아,
깊어질수록 파래진다.""",
		"chips": [{"icon": "shader", "text": "absorption"}],
		"code": """uniform vec3 absorption =
    vec3(0.38, 0.065, 0.028);  // R>G>B""",
		"try": "흡수 슬라이더 → 깊은 곳부터 색이 빠진다",
	},
	{
		"title": "산란 색 더해 탁하게 하기",
		"body": """흡수만 쓰면 깊은 물이 [b]검게[/b] 가라앉는다.
실제 물은 떠 있는 입자가 빛을 되돌려 보낸다.
그 몫을 상수 색으로 더한다.""",
		"chips": [{"icon": "shader", "text": "scatter_color / scatter_k" }],
		"try": "산란 슬라이더 0 → 깊은 곳이 검어진다",
	},
]

var _absorption := 1.0
var _scatter := 0.13


func get_chapter_title() -> String:
	return "L4 — 수심으로 색 빼기"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.reset_layers()
	world.set_foam(false)
	world.set_debug_view(2 if index == 1 else 0)
	if index == 0:
		world.set_volume(false)
	else:
		world.set_param(&"absorption", WaterWorld.ABSORPTION_ON * _absorption)
		world.set_param(&"scatter_k", _scatter if index >= 3 else 0.0)
	world.camera_rig.set_view(2.95, -0.36, 34.0)
	if index >= 2:
		update_code(_absorption_code())


func build_panel(parent: VBoxContainer) -> void:
	# 스텝 1은 수심 자체(debug_view = 2)를 보는 칸이라 흡수도 아직 안 보인다.
	add_slider(parent, "흡수 세기 (absorption)", 0.0, 3.0, 1.0, _on_absorption_changed, [2, 3])
	add_slider(parent, "산란 (scatter_k)", 0.0, 2.0, 0.13, _on_scatter_changed, [3])
	add_caption(parent, "흡수는 색을 빼고, 산란은 되돌려 준다", [2, 3])


func _on_absorption_changed(value: float) -> void:
	_absorption = value
	if current_step >= 1:
		world.set_param(&"absorption", WaterWorld.ABSORPTION_ON * value)
		update_code(_absorption_code())


func _on_scatter_changed(value: float) -> void:
	_scatter = value
	if current_step >= 3:
		world.set_param(&"scatter_k", value)


func _absorption_code() -> String:
	var a: Vector3 = WaterWorld.ABSORPTION_ON * _absorption
	return ("absorption = vec3(%.2f, %.3f, %.3f)\n" % [a.x, a.y, a.z]
			+ "// ← 슬라이더. R이 가장 커서 먼저 죽는다")
