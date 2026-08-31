extends EarthChapter
## 챕터 3 — 먼지와 잔돌. 배치는 통제하고 표류는 물리에 맡기는 먼지,
## 그리고 저장소에서 거의 유일하게 셰이더가 없는 잔돌.

const STEPS: Array[Dictionary] = [
	{
		"title": "배치는 통제, 표류는 물리",
		"body": """먼지도 INDEX로 배치하지만 [b]disable_velocity가 없다[/b].
start()에서 준 초기 속도로 흩어지고
process()의 ×0.99 감쇠로 서서히 멎는다.""",
		"chips": [{"icon": "shader", "text": "dust.gdshader"}],
		"code": """VELOCITY.x = (rand - 0.5) * 0.5;
...
VELOCITY *= 0.99; // 감쇠""",
		"try": "슬로 모션 → 앞쪽에 몰린 먼지가 천천히 흩어진다",
	},
	{
		"title": "먼지의 렌더 — 뎁스 소프트",
		"body": """빌보드 + 뎁스 소프트 + 노이즈 + [b]SPECULAR 0[/b].
난수 하나(custom.x)가 무늬 오프셋과 회전각을
동시에 흩뜨린다. 먼지가 번들거리면 즉시 가짜다.""",
		"chips": [{"icon": "shader", "text": "dust_particles_mat.gdshader"}],
		"code": """ALPHA = noise * dist * COLOR.a * edge;
SPECULAR = 0.0;""",
	},
	{
		"title": "잔돌 — 셰이더가 없는 파티클",
		"body": """실제 지오메트리 + 노멀맵 + 물리 튕김이라
[b]기본 PBR로 충분[/b]하다. collision_use_scale로
큰 돌은 큰 반경으로 튕기고, 중력은 -20 — 진짜로 떨어진다.""",
		"chips": [
			{"icon": "node3d", "text": "SmallRocks ×64"},
			{"icon": "resource", "text": "StandardMaterial3D"},
		],
		"code": """gravity = (0, -20, 0)  # 정상 중력
collision_use_scale = true""",
		"try": "재생 → 바위가 뚫는 찰나 잔돌이 튀어 구른다",
	},
]

var _speed := 0.35


func _ready() -> void:
	world.make_lab()
	world.camera_rig.position = Vector3(0.0, 1.0, 0.0)
	world.camera_rig.set_view(0.45, -0.3, 12.0)


func get_chapter_title() -> String:
	return "먼지와 잔돌 — 곁들이는 층"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.set_lab_speed(_speed if index == 0 else 1.0)
	match index:
		0, 1:
			world.lab_replay(false, true)
		2:
			world.lab_replay(true, true)


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "재생 속도", 0.05, 1.0, _speed, _on_speed_changed, [0])

	var replay := Button.new()
	replay.text = "다시 재생"
	replay.pressed.connect(_on_replay)
	parent.add_child(replay)
	bind_steps([replay], [])


func _on_speed_changed(value: float) -> void:
	_speed = value
	if current_step == 0:
		world.set_lab_speed(value)


func _on_replay() -> void:
	world.lab_replay(current_step == 2, true)
