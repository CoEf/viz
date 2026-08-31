extends EarthChapter
## 챕터 1 — 방출이 아니라 배치. disable_velocity로 물리를 끄고
## INDEX가 정해 주는 자기 자리로 TRANSFORM을 직접 쓴다.

const STEPS: Array[Dictionary] = [
	{
		"title": "속도를 끄고 자리를 쓰기",
		"body": """render_mode [b]disable_velocity[/b] —
VELOCITY를 무시하고 TRANSFORM을 매 프레임 직접 쓴다.
물리 적분 없이 위치를 완전히 통제한다.""",
		"chips": [{"icon": "shader", "text": "earth_attack.gdshader"}],
		"code": """render_mode disable_velocity;
TRANSFORM[3].xyz = position
    + rotation_position + emitter_pos;""",
		"try": "슬로 모션으로 → 솟는 순서를 따라가 보라",
	},
	{
		"title": "INDEX로 줄 세우기",
		"body": """[b]INDEX / particles_count[/b]가 0~1의 순번이다.
X에 곱하면 일렬 배치, Z 흩어짐엔 (순번+0.5)를 곱해
[b]뒤로 갈수록 부채꼴로[/b] 넓어진다.""",
		"chips": [{"icon": "shader", "text": "INDEX / particles_count"}],
		"try": "개수를 바꾸면 → 간격이 다시 균등해진다",
	},
	{
		"title": "독립 난수 여러 개 뽑기",
		"body": """NUMBER에 [b]서로 다른 상수를 더해 해시[/b] —
상수만 바꾸면 상관없는 난수가 나온다.
같은 시드를 재사용하면 크기·회전에 상관관계가 생긴다.""",
		"chips": [{"icon": "shader", "text": "hash.gdshaderinc"}],
		"code": """seed1 = hash(NUMBER + uint(1) + SEED);
seed2 = hash(NUMBER + uint(2) + SEED);""",
	},
]

var _speed := 0.35
var _count := 12.0


func _ready() -> void:
	world.make_lab()
	world.camera_rig.position = Vector3(0.0, 1.0, 0.0)
	world.camera_rig.set_view(0.45, -0.3, 12.0)


func get_chapter_title() -> String:
	return "배치 — 방출하지 않는 파티클"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.set_lab_speed(_speed if index == 0 else 1.0)
	world.rocks_particle_material().set_shader_parameter("particles_count", int(_count))
	world.lab_rocks().amount = int(_count)
	world.lab_replay(true, true)
	if index == 1:
		update_code(_count_code())


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "재생 속도", 0.05, 1.0, _speed, _on_speed_changed, [0])
	add_slider(parent, "particles_count", 4.0, 24.0, _count, _on_count_changed, [1])

	var replay := Button.new()
	replay.text = "다시 재생"
	replay.pressed.connect(func() -> void: world.lab_replay(true, true))
	parent.add_child(replay)
	bind_steps([replay], [])


func _on_speed_changed(value: float) -> void:
	_speed = value
	if current_step == 0:
		world.set_lab_speed(value)


func _on_count_changed(value: float) -> void:
	_count = roundf(value)
	world.rocks_particle_material().set_shader_parameter("particles_count", int(_count))
	world.lab_rocks().amount = int(_count)
	world.lab_replay(true, false)
	if current_step == 1:
		update_code(_count_code())


func _count_code() -> String:
	return ("percent = INDEX / %.0f. ← 슬라이더\n" % _count
			+ "position.x = percent * zone_length;")
