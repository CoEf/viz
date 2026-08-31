extends TornadoChapter
## 챕터 0 — 완성본과 지도. 메시가 전부 프리미티브 — 형태는 셰이더가 만든다.

const STEPS: Array[Dictionary] = [
	{
		"title": "완성된 포탈 보기",
		"body": """구멍이 열리고, 빛기둥이 솟고, 파티클이 감기고,
상자가 늘어나며 빨려 든다 — 4초.
메시는 쿼드·원뿔·실린더·박스, [b]전부 프리미티브[/b]다.""",
		"chips": [
			{"icon": "node3d", "text": "AnimationPlayer 4.0s"},
			{"icon": "resource", "text": "QuadMesh / BoxMesh"},
		],
		"try": "재생 → 상자가 늘어나기 시작하는 1.5초를 보라",
	},
	{
		"title": "다섯 챕터로 나눠 보기",
		"body": """①절차적 하이트맵 ②POM — 깊이의 눈속임.
③흡입 변형 ④빛·헤일로·파티클 — 연출.
⑤타임라인 — 오버슈트와 앤티시페이션.""",
		"chips": [{"icon": "setting", "text": "챕터 1 → 5"}],
	},
]


func _ready() -> void:
	world.play.call_deferred()


func get_chapter_title() -> String:
	return "개요 — 포탈의 4초"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	if index == 0:
		world.play()


func build_panel(parent: VBoxContainer) -> void:
	var replay := Button.new()
	replay.text = "재생"
	replay.pressed.connect(func() -> void: world.play())
	parent.add_child(replay)
	bind_steps([replay], [])
