extends HalloweenChapter
## 챕터 0 — 완성본과 지도. 저장소에서 가장 큰 이펙트를 통째로 보여주고,
## 이 워크스루가 그걸 어떻게 쪼갰는지 알려준다.

const STEPS: Array[Dictionary] = [
	{
		"title": "완성된 폭발 보기",
		"body": """셰이더 11장, 시각 노드 11개, 애니메이션 트랙 [b]42개[/b].
그런데 스크립트는 play("default") 한 줄이다.
5초짜리 타임라인이 전부를 지휘한다.""",
		"chips": [
			{"icon": "node3d", "text": "AnimationPlayer"},
			{"icon": "script", "text": "explosion.gd"},
		],
		"code": """func _ready():
    animation_player.play("default")""",
		"try": "폭발 재생 → 5초 동안 눈을 떼지 말 것",
	},
	{
		"title": "다섯 챕터로 나눠 보기",
		"body": """①버섯구름 ②링 5장 ③섬광·균열 — 몸.
④불티·연기 — 여운.
⑤타임라인 — 42개 트랙의 지휘.""",
		"chips": [{"icon": "setting", "text": "챕터 1 → 5"}],
	},
]


func _ready() -> void:
	world.camera_rig.position = Vector3(0.0, 2.0, 0.0)
	world.camera_rig.set_view(0.5, -0.25, 11.0)
	world.play_explosion.call_deferred()


func get_chapter_title() -> String:
	return "개요 — 폭발 한 번의 전체"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	if index == 0:
		world.play_explosion()


func build_panel(parent: VBoxContainer) -> void:
	var replay := Button.new()
	replay.text = "폭발 재생"
	replay.pressed.connect(func() -> void: world.play_explosion())
	parent.add_child(replay)
	bind_steps([replay], [])
