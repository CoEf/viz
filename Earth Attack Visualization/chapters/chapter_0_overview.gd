extends EarthChapter
## 챕터 0 — 완성본과 지도. 파티클을 "방출"하지 않고 "배치"하는 이펙트.

const STEPS: Array[Dictionary] = [
	{
		"title": "완성된 어스 어택 보기",
		"body": """바위 가시가 땅에서 [b]앞에서부터 차례로[/b] 솟구치며
마네킹들을 날려 버린다.
그 순서는 방출 타이밍이 아니라 배치 좌표에서 나온다.""",
		"chips": [
			{"icon": "shader", "text": "shader_type particles"},
			{"icon": "node3d", "text": "RocksParticles ×12"},
		],
		"try": "재생 → 마네킹이 번쩍이며 날아간다",
	},
	{
		"title": "네 챕터로 나눠 보기",
		"body": """①방출이 아니라 배치 ②커브 3채널 — 파티클 통제.
③먼지와 잔돌 — 곁들이는 층.
④바위 셰이더와 피격 — 마무리.""",
		"chips": [{"icon": "setting", "text": "챕터 1 → 4"}],
	},
]


func _ready() -> void:
	world.play.call_deferred()


func get_chapter_title() -> String:
	return "개요 — 배치되는 파티클"


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
