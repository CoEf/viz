extends WaterChapter
## 챕터 0 — 완성본과 지도.

const STEPS: Array[Dictionary] = [
	{
		"title": "완성된 시퀀스 보기",
		"body": """소용돌이가 열리고, 물 팔이 솟아 내려찍고,
젖은 자국이 남았다 마른다 — 2.6초.
지휘자는 [b]팔의 스켈레탈 애니메이션[/b]이다.""",
		"chips": [
			{"icon": "node3d", "text": "AnimationTree"},
			{"icon": "signal", "text": "raised / slaped"},
		],
		"try": "재생 → 내려찍는 순간 화면이 흔들린다",
	},
	{
		"title": "여섯 챕터로 나눠 보기",
		"body": """①트라이플래너 물 ②뎁스 접지선 — 팔의 재질.
③소용돌이 ④물보라·물방울 ⑤젖은 자국 — 주변 연출.
⑥조립 — 애니메이션이 쏘는 시그널.""",
		"chips": [{"icon": "setting", "text": "챕터 1 → 6"}],
	},
]


func _ready() -> void:
	world.play_sequence.call_deferred()


func get_chapter_title() -> String:
	return "개요 — 물 팔의 2.6초"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	if index == 0:
		world.play_sequence()


func build_panel(parent: VBoxContainer) -> void:
	var replay := Button.new()
	replay.text = "시퀀스 재생"
	replay.pressed.connect(func() -> void: world.play_sequence())
	parent.add_child(replay)
	bind_steps([replay], [])
