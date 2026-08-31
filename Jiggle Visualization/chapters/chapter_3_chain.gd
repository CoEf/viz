extends JiggleChapter
## 챕터 3 — 본 사슬 Verlet (머리카락). 스프링 여러 개를 잇는 대신
## 속도 없는 적분 + 위치 제약으로 사슬을 푼다.

const RESPONSE_NAMES := "① 위치만 밀기 (폭주),② 속도 보존 (튐),③ 접촉 안정화 (권장)"

const STEPS: Array[Dictionary] = [
	{
		"title": "속도를 저장하지 않고 적분하기",
		"body": """Verlet은 속도를 안 갖는다 — [b]이전 위치가 곧 속도다.[/b]
위치를 고치면 속도도 저절로 맞춰진다.
제약을 '위치 수정'만으로 풀 수 있는 이유다.""",
		"chips": [{"icon": "script", "text": "JiggleVerletBody"}],
		"code": """v ≈ p - p_prev
p += v * (1 - drag) + a * dt²""",
		"try": "노랑 십자 = 파티클 · 초록 = rest 사슬 · 흰 = 본",
	},
	{
		"title": "거리 제약을 반복해서 풀기",
		"body": """이웃 입자를 rest 간격으로 되당긴다.
하나를 고치면 옆이 다시 어긋나 [b]여러 번 반복한다.[/b]
반복 횟수가 곧 뻣뻣함이다.""",
		"chips": [{"icon": "script", "text": "_solve_pairs()"}],
		"code": "correction = off * (dist-rest)/dist",
		"try": "반복을 1로 → 고무줄. 12로 → 뻣뻣. 그래프 초록 선 주시",
	},
	{
		"title": "각도 제한으로 접힘 막기",
		"body": """거리만 지키면 사슬이 [b]자기 위로 접힌다.[/b]
이웃 마디의 꺾임각을 한계각 안으로 되돌린다.
스킨드 메쉬가 뒤집히는 것을 막는 장치다.""",
		"chips": [{"icon": "script", "text": "_solve_angle()"}],
		"code": "p[i+1] = p[i] + ref.rotated(axis, lim)*len",
		"try": "0(무제한)으로 두고 임펄스 연타 → 머리카락이 접힌다",
	},
	{
		"title": "충돌 응답 고르기 — 폭주·튐·안정",
		"body": """위치만 밀면 Verlet이 그 이동을 속도로 착각해 [b]폭주.[/b]
이전 위치도 밀면 파고들던 속도가 남아 표면에서 튄다.
법선 속도를 지우고 접선만 남기면 안정된다.""",
		"chips": [{"icon": "script", "text": "CollisionResponse.STABLE"}],
		"code": """tangent = v - n * v.dot(n)
previous[i] = p - tangent * retain""",
		"try": "①로 바꾸면 폭주 — 안전장치가 rest로 되돌린다",
	},
	{
		"title": "파티클을 본 회전으로 되돌리기",
		"body": """본은 늘어나지 않으므로 회전만 만든다.
루트부터 끝까지 [b]순서대로 누적[/b]해 내려간다.
흰 선 = 본이 실제로 만든 사슬(길이는 늘 정확하다).""",
		"chips": [
			{"icon": "script", "text": "chain_strand.gd"},
			{"icon": "node3d", "text": "Skeleton3D"},
		],
		"code": """swing = Quaternion(rest_dir, desired)
set_bone_pose_rotation(b, swing*base)""",
		"try": "본 색 보기 → 관절마다 가중치가 이웃과 섞이는 폭",
	},
]

@onready var world: ChainWorld = $World

var _plot: JigglePlot
var _iteration_slider: HSlider
var _angle_slider: HSlider
var _response_option: OptionButton
var _collision_toggle: CheckButton
var _color_toggle: CheckButton


func get_chapter_title() -> String:
	return "본 사슬 — 머리카락·꼬리"


func get_steps() -> Array[Dictionary]:
	return STEPS


func _ready() -> void:
	world.set_view(Vector3(0.0, 1.3, 0.0), 0.55, -0.05, 1.05)


func apply_step(index: int) -> void:
	world.iterations = 6
	world.constraint_stiffness = 1.0
	world.angle_limit_degrees = 35.0
	world.collision_enabled = true
	world.collision_response = JiggleVerletBody.CollisionResponse.STABLE
	world.show_particles = true
	world.show_colliders = index == 3
	world.show_bone_colors = false
	world.apply()
	# kick 은 쓰지 않는다 — 회전 자극의 위상을 당기면 한 프레임짜리 순간이동이 되어
	# 머리카락이 수평으로 튄다. TWIST 는 주기가 짧아 그냥 둬도 금방 움직인다.
	_sync_controls()
	if _plot != null:
		_plot.clear_samples()
	match index:
		1:
			update_code(_iteration_code())
		2:
			update_code(_angle_code())


func build_panel(parent: VBoxContainer) -> void:
	_plot = add_plot(parent, [
		{"id": "tip", "color": Color(1.0, 0.70, 0.35)},
		{"id": "stretch", "color": Color(0.45, 0.95, 0.60)},
	])
	add_button(parent, "임펄스 (툭 치기)", world.trigger_impulse)
	_iteration_slider = add_slider(parent, "제약 반복 횟수", 1.0, 16.0, 6.0, _on_iterations_changed, [1])
	_angle_slider = add_slider(parent, "각도 제한 (0=무제한)", 0.0, 90.0, 35.0, _on_angle_changed, [2])
	_response_option = add_option(
		parent, "충돌 응답", RESPONSE_NAMES.split(","), 2, _on_response_selected, [3]
	)
	_collision_toggle = add_toggle(parent, "충돌", true, _on_collision_toggled, [3])
	_color_toggle = add_toggle(parent, "본 색 보기", false, _on_color_toggled, [4])
	add_slowmo(parent)
	add_caption(
		parent,
		"초록 = rest 사슬 · 노랑 십자 = 파티클 · 흰 = 본이 만든 사슬 · 빨강 = 충돌 입자 · 파랑 = 충돌체"
	)


func _process(_delta: float) -> void:
	if _plot != null and _plot.visible:
		_plot.info_text = "끝점 좌우 변위(주황) · 길이 오차 cm(초록)"
		_plot.push_frame(world.sample_plot())


func _sync_controls() -> void:
	_iteration_slider.set_value_no_signal(float(world.iterations))
	_angle_slider.set_value_no_signal(world.angle_limit_degrees)
	_response_option.select(int(world.collision_response))
	_collision_toggle.set_pressed_no_signal(world.collision_enabled)
	_color_toggle.set_pressed_no_signal(world.show_bone_colors)


func _on_iterations_changed(value: float) -> void:
	world.iterations = int(roundf(value))
	world.apply()
	if current_step == 1:
		update_code(_iteration_code())


func _on_angle_changed(value: float) -> void:
	world.angle_limit_degrees = value
	world.apply()
	if current_step == 2:
		update_code(_angle_code())


func _on_response_selected(index: int) -> void:
	world.collision_response = index as JiggleVerletBody.CollisionResponse
	world.apply()


func _on_collision_toggled(pressed: bool) -> void:
	world.collision_enabled = pressed
	world.apply()


func _on_color_toggled(pressed: bool) -> void:
	world.show_bone_colors = pressed
	world.apply()


func _iteration_code() -> String:
	return (
		"for iteration in iterations:\n"
		+ "    _solve_constraints()\n"
		+ "# iterations = %d ← 슬라이더\n" % world.iterations
		+ "# 길이 오차 %.1f mm" % (world.length_error() * 1000.0)
	)


func _angle_code() -> String:
	var line := "p[i+1] = p[i] + ref.rotated(axis, lim)*len\n"
	if world.angle_limit_degrees <= 0.0:
		return line + "# 제한 없음 — 접힐 수 있다 ← 슬라이더"
	return line + "# angle_limit = %.0f° ← 슬라이더" % world.angle_limit_degrees
