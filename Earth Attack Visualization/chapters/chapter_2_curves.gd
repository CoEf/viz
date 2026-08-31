extends EarthChapter
## 챕터 2 — 커브 3채널. 같은 텍스처를 서로 다른 좌표계로 읽는다:
## .x/.y는 수명, .z는 순번. 모션·타이밍·크기가 텍스처 한 장에.

const STEPS: Array[Dictionary] = [
	{
		"title": "커브가 곧 애니메이션",
		"body": """.x 커브를 remap하면 그대로 Y 좌표다.
포인트 7개에 [b]솟구침·오버슈트·유지·두 번째 튐·후퇴[/b]가
전부 들어 있다. 트랙이 아니라 커브 텍스처다.""",
		"chips": [{"icon": "resource", "text": "CurveXYZTexture .x (수명)"}],
		"code": """y = remap(curve(lifetime).x,
    0., 1., -4.5, -0.8); // 땅속→지상""",
		"try": "슬로 모션 → 0.05 지점의 오버슈트를 잡아 보라",
	},
	{
		"title": "커브가 곧 타이밍",
		"body": """.y는 1.0에서 시작해 수명 0.1에 0으로 떨어지는 직선.
[b]> 0.8인 처음 2%[/b] — 땅을 뚫는 찰나에만
emit_subparticle로 잔돌이 발사된다.""",
		"chips": [
			{"icon": "shader", "text": "emit_subparticle()"},
			{"icon": "resource", "text": "CurveXYZTexture .y (수명)"},
		],
		"code": """if (curve.y > 0.8) {
    t[3].xyz -= rotation_position;
    t[3].y = 0.2; // 지면 구멍에서
    emit_subparticle(t, ..., POSITION); }""",
		"try": "잔돌은 바위 끝이 아니라 지면에서 튄다",
	},
	{
		"title": "커브가 곧 크기, 그리고 기울기",
		"body": """.z는 [b]순번[/b]으로 읽는다 — 0.3→1.0 램프라
앞의 바위는 작고 뒤로 갈수록 커진다.
tilt는 상하 운동 전체를 기울이는 각도다.""",
		"chips": [{"icon": "resource", "text": "CurveXYZTexture .z (순번)"}],
		"try": "tilt를 0으로 → 수직으로 솟는 밋밋한 가시",
	},
]

var _speed := 0.3
var _tilt := 0.8


func _ready() -> void:
	world.make_lab()
	world.camera_rig.position = Vector3(0.0, 1.0, 0.0)
	world.camera_rig.set_view(0.45, -0.3, 12.0)


func get_chapter_title() -> String:
	return "커브 3채널 — 모션·타이밍·크기"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.rocks_particle_material().set_shader_parameter("tilt", _tilt if index == 2 else 0.8)
	world.set_lab_speed(_speed if index != 2 else 1.0)
	world.lab_replay(true, index != 1)
	if index == 2:
		update_code(_tilt_code())


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "재생 속도", 0.05, 1.0, _speed, _on_speed_changed, [0, 1])
	add_slider(parent, "tilt (기울기)", 0.0, 1.5, _tilt, _on_tilt_changed, [2])

	var replay := Button.new()
	replay.text = "다시 재생"
	replay.pressed.connect(func() -> void: world.lab_replay(true, true))
	parent.add_child(replay)
	bind_steps([replay], [])


func _on_speed_changed(value: float) -> void:
	_speed = value
	if current_step <= 1:
		world.set_lab_speed(value)


func _on_tilt_changed(value: float) -> void:
	_tilt = value
	world.rocks_particle_material().set_shader_parameter("tilt", value)
	world.lab_replay(true, false)
	if current_step == 2:
		update_code(_tilt_code())


func _tilt_code() -> String:
	return ("TRANSFORM *= mat4(rotateZ(%.2f)\n" % _tilt
			+ "    * rotateY(rand * TAU)); ← 슬라이더")
