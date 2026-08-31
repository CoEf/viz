extends FireworksChapter
## 챕터 4 — 다섯 줄 셰이더. 관용구의 변형과 적재적소의 판단.

const STEPS: Array[Dictionary] = [
	{
		"title": "리본을 다듬는 다섯 줄",
		"body": """sin(UV.x·PI) × UV.y에 step —
2편 fireball의 sin×sin 관용구의 [b]세로 변형[/b]이다.
리본 머리는 잘리고 꼬리로 갈수록 좁아진다.""",
		"chips": [{"icon": "shader", "text": "firework_trails.gdshader"}],
		"code": """ALPHA = clamp(step(0.1,
    sin(UV.x*PI) * UV.y) * ease, 0, 1)
    * COLOR.a;""",
		"try": "폭발 → 리본 끝이 뾰족하게 사그라든다",
	},
	{
		"title": "잔불꽃은 텍스처 한 장",
		"body": """절차적 별(2편의 8갈래)도 만들 수 있지만
크기 0.06 쿼드 수백 개에는 [b]텍스처가 정답[/b]이다.
수명 0.25초 — 반짝하고 사라지는 점.""",
		"chips": [{"icon": "shader", "text": "sparks.gdshader"}],
		"code": """float mask = texture(spark, UV).x;
ALPHA = mask * COLOR.a;""",
	},
	{
		"title": "정리 타이머의 함정",
		"body": """폭발은 4초 타이머로 queue_free —
setup으로 속도를 올리면 [b]파티클이 아직 살아 있을 수 있다[/b].
8편 히트존과 같은 종류의 손맞춤 상수다.""",
		"chips": [{"icon": "script", "text": "create_timer(4.0)"}],
	},
]


func _ready() -> void:
	world.set_show_running(false)
	world.camera_rig.position = Vector3(0.0, 0.0, 0.0)
	world.camera_rig.set_view(0.4, -0.1, 11.0)
	world.spawn_custom_explosion.call_deferred(5.0, 48)


func get_chapter_title() -> String:
	return "다섯 줄 셰이더 — 마지막 손질"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(_index: int) -> void:
	world.spawn_custom_explosion(5.0, 48)


func build_panel(parent: VBoxContainer) -> void:
	var boom := Button.new()
	boom.text = "폭발"
	boom.pressed.connect(func() -> void: world.spawn_custom_explosion(5.0, 48))
	parent.add_child(boom)
	bind_steps([boom], [])
