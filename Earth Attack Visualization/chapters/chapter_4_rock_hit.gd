extends EarthChapter
## 챕터 4 — 바위 셰이더와 피격. 모델 공간 노멀로 만든 방향 마스크,
## CharacterBody3D로 진짜 날아가는 더미, 그리고 손으로 맞춘 판정의 함정.

const STEPS: Array[Dictionary] = [
	{
		"title": "위를 향한 면만 달구기",
		"body": """fragment의 NORMAL은 뷰 공간 — 카메라 따라 변한다.
vertex에서 [b]모델 공간 노멀[/b]을 varying으로 넘겨야
"하늘을 보는 면"을 판정할 수 있다. 윗면만 마그마빛.""",
		"chips": [{"icon": "shader", "text": "rock_spikes.gdshader"}],
		"code": """EMISSION = fresnel_color * step(.5, f)
    * 2.0 * clamp(object_normal.y, 0, 1);""",
		"try": "마스크 보기 → 주황=위, 파랑=옆·아래",
	},
	{
		"title": "진짜로 날아가는 더미",
		"body": """트윈 스쿼시가 아니라 [b]CharacterBody3D[/b]다.
중력 50(기본의 5배), 45° 넉백 20,
지면 마찰은 수평 벡터를 통째로 move_toward.""",
		"chips": [{"icon": "script", "text": "punch_dummy.gd"}],
		"code": """velocity += Vector3(1, 1, randfn(0, .1))
    .normalized() * 20.0
velocity.y -= 50.0 * delta""",
		"try": "재생 → 번쩍이고, 날아가고, 4초 뒤 리셋된다",
	},
	{
		"title": "손으로 맞춘 판정의 함정",
		"body": """히트존은 2초에 −5→+5, 바위는 1.5초에 걸쳐 등장 —
[b]판정과 그림이 조금씩 어긋난다[/b].
zone_length도 스크립트·셰이더 세 곳에 흩어져 있(었)다.""",
		"chips": [{"icon": "script", "text": "earth_spikes.gd"}],
		"code": """# 개선안: 판정을 파티클에서 유도
t.tween_property(zone, "position:x",
    half, lifetime * (1.0 - explosiveness))""",
		"try": "이식본은 zone_length를 uniform으로 묶어 두었다",
	},
]

var _mask := true


func _ready() -> void:
	world.make_lab()
	world.camera_rig.position = Vector3(0.0, 1.0, 0.0)
	world.camera_rig.set_view(0.45, -0.3, 11.0)


func get_chapter_title() -> String:
	return "바위와 피격 — 마무리"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.set_lab_speed(1.0)
	world.rock_render_material().set_shader_parameter("debug_mode", 0)
	match index:
		0:
			world.set_lab_speed(0.25)
			world.rock_render_material().set_shader_parameter(
					"debug_mode", 1 if _mask else 0)
			world.lab_replay(true, false)
		1, 2:
			world.clear_lab()
			world.play()
			world.make_lab.call_deferred()


func build_panel(parent: VBoxContainer) -> void:
	add_toggle(parent, "노멀 y 마스크 보기", _mask, _on_mask_toggled, [0])

	var replay := Button.new()
	replay.text = "전체 재생"
	replay.pressed.connect(func() -> void: world.play())
	parent.add_child(replay)
	bind_steps([replay], [1, 2])


func _on_mask_toggled(pressed: bool) -> void:
	_mask = pressed
	if current_step == 0:
		world.rock_render_material().set_shader_parameter(
				"debug_mode", 1 if pressed else 0)
		world.lab_replay(true, false)
