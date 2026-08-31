extends FireworksChapter
## 챕터 2 — 로켓. 파티클이 아니라 리본 메시 하나 + 트윈 하나.

const STEPS: Array[Dictionary] = [
	{
		"title": "트윈 하나로 위치와 uniform을 함께",
		"body": """지속 시간은 [b]거리 ÷ 속도[/b]로 유도 — 높이 뜨면 오래 걸린다.
tween_method 콜백 하나가 위치와 셰이더 lifetime을
같이 굴린다. 둘이 어긋날 수 없다.""",
		"chips": [{"icon": "script", "text": "firework_rocket.gd"}],
		"code": """duration = abs(Δy) / speed
t.tween_method(func(p):
    position = start.lerp(end, p)
    mat.set("lifetime", p), 0., 1., d)""",
		"try": "속도를 2로 → 느리게 오르며 꼬리가 늘어난다",
	},
	{
		"title": "sin(lifetime × PI) 하나로 두 가지",
		"body": """lifetime 0→1 동안 이 값은 0→1→0.
[b]꼬리 길이[/b]도 [b]투명도[/b]도 이 식이다 —
속도를 재지 않고 모션 스트레치와 페이드를 얻는다.""",
		"chips": [{"icon": "shader", "text": "firework_rocket.gdshader"}],
		"try": "0.5에서 가장 길고 밝다, 양끝에서 사라진다",
	},
	{
		"title": "물방울 실루엣",
		"body": """sin(UV.x·PI)가 폭, −UV.y가 꼬리 쪽 좁힘,
×UV.y가 머리 쪽 잘라내기.
[b]곱셈 두 번으로 위아래가 다르게 뾰족[/b]해진다.""",
		"chips": [{"icon": "shader", "text": "Y축 고정 빌보드"}],
		"code": """shape = step(0.04,
    (sin(UV.x*PI) - UV.y) * UV.y);""",
	},
]

var _speed := 4.0
var _lifetime := 0.5


func _ready() -> void:
	world.set_show_running(false)
	world.camera_rig.position = Vector3(0.0, -2.0, 0.0)
	world.camera_rig.set_view(0.4, -0.1, 10.0)


func get_chapter_title() -> String:
	return "로켓 — 리본 하나, 트윈 하나"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	match index:
		0:
			world.clear_pose_rocket()
			world.launch_rocket(_speed)
		1, 2:
			world.make_pose_rocket()
			world.set_pose_lifetime(_lifetime)
			if index == 1:
				update_code(_lifetime_code())


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "로켓 속도", 2.0, 12.0, _speed, _on_speed_changed, [0])
	var launch := Button.new()
	launch.text = "발사"
	launch.pressed.connect(func() -> void: world.launch_rocket(_speed))
	parent.add_child(launch)
	bind_steps([launch], [0])

	add_slider(parent, "lifetime", 0.0, 1.0, _lifetime, _on_lifetime_changed, [1])


func _on_speed_changed(value: float) -> void:
	_speed = value


func _on_lifetime_changed(value: float) -> void:
	_lifetime = value
	world.set_pose_lifetime(value)
	if current_step == 1:
		update_code(_lifetime_code())


func _lifetime_code() -> String:
	return ("opacity = sin(%.2f * PI) = %.2f\n" % [_lifetime, sin(_lifetime * PI)]
			+ "VERTEX.y *= 1.0 + opacity; ← 슬라이더")
