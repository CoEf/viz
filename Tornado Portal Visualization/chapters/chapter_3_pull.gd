extends TornadoChapter
## 챕터 3 — 흡입 변형. world_vertex_coords 덕에 상자가 아무리 뒹굴어도
## 항상 월드의 같은 점으로 늘어난다. 스파게티화를 정점 세 줄로.

const STEPS: Array[Dictionary] = [
	{
		"title": "월드의 한 점으로 끌어당기기",
		"body": """이 render_mode에서 VERTEX는 [b]월드 공간[/b]으로 들어온다.
타깃이 월드 원점 아래의 고정된 점이라
상자 위치·회전과 무관하게 항상 같은 곳으로 끌린다.""",
		"chips": [
			{"icon": "shader", "text": "render_mode world_vertex_coords"},
			{"icon": "shader", "text": "pull_deform.gdshader"},
		],
		"try": "당기면 → 상자가 구멍 쪽으로 늘어난다",
	},
	{
		"title": "아래가 5배 세게 끌린다",
		"body": """세기에 [b]정점의 상대 높이[/b]를 곱한다 —
아랫면 1.25, 윗면 0.25. 계수가 1을 넘으면
타깃을 [b]지나쳐[/b] 물방울처럼 길게 늘어진다.""",
		"chips": [{"icon": "shader", "text": "VERTEX.y - NODE_POSITION_WORLD.y"}],
		"code": """VERTEX -= diff * pull * (1.0 -
    (VERTEX.y - NODE_POS.y + 0.25));""",
		"try": "회전을 켜도 → 늘어나는 방향은 그대로다",
	},
	{
		"title": "위치보다 형태가 먼저 움직인다",
		"body": """pull_intensity는 1.5초에 시작하는데
실제 낙하는 [b]3.2초[/b] — 1.7초나 먼저 늘어난다.
"보이지 않는 힘에 잡혀 있다"는 인상의 정체.""",
		"chips": [{"icon": "node3d", "text": "AnimationPlayer 트랙"}],
		"code": """pull_intensity: 1.5s → 3.0s (0→1)
position.y   : 3.2s에야 -4.0""",
		"try": "1.5~3.2초를 훑으면 → 형태가 먼저 반응한다",
	},
]

var _pull := 0.5
var _scrub_t := 2.4


func _ready() -> void:
	world.stop()
	world.solo(true, false, true, false)
	world.reset_hole_params(1.0)
	world.camera_rig.position = Vector3(0.0, 0.6, 0.0)
	world.camera_rig.set_view(0.5, -0.18, 5.5)


func get_chapter_title() -> String:
	return "흡입 변형 — 정점 스파게티화"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.stop()
	world.spin_target = false
	world.reset_hole_params(1.0)
	match index:
		0, 1:
			world.solo(true, false, true, false)
			world.set_pull(_pull)
			update_code(_pull_code())
		2:
			world.solo(true, true, true, true)
			world.scrub(_scrub_t)


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "pull_intensity", 0.0, 1.0, _pull, _on_pull_changed, [0, 1])
	add_toggle(parent, "상자 회전", false, _on_spin_toggled, [1])
	var scrub := add_slider(parent, "타임라인 (초)", 0.0, 4.0, _scrub_t, _on_scrub_changed, [2])
	scrub.step = 0.01


func _on_pull_changed(value: float) -> void:
	_pull = value
	world.set_pull(value)
	if current_step <= 1:
		update_code(_pull_code())


func _on_spin_toggled(pressed: bool) -> void:
	world.spin_target = pressed and current_step == 1


func _on_scrub_changed(value: float) -> void:
	_scrub_t = value
	if current_step == 2:
		world.scrub(value)


func _pull_code() -> String:
	return ("VERTEX -= diff * %.2f\n" % _pull
			+ "    * (1.0 - 상대높이 + 0.25); ← 슬라이더")
