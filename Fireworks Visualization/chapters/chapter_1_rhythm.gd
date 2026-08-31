extends FireworksChapter
## 챕터 1 — 확률 커브가 쇼의 리듬이다. 0.1초 × 100틱 = 10초 루프.

const STEPS: Array[Dictionary] = [
	{
		"title": "커브에서 확률을 읽어 주사위 굴리기",
		"body": """10초 루프를 100틱으로 쪼개고, 틱마다 커브에서
확률을 읽어 randf()와 비교한다.
[b]잔잔함→절정→소강→재절정[/b]이 포인트 다섯 개다.""",
		"chips": [{"icon": "resource", "text": "probability_curve (max 0.5)"}],
		"code": """probability = curve.sample(progress)
if randf() < probability:
    _spawn_random_firework()""",
		"try": "배율을 4배로 → 쉴 새 없는 피날레가 된다",
	},
	{
		"title": "위치는 정규분포로",
		"body": """randf_range가 아니라 [b]randfn[/b] —
균등분포는 정육면체 구름을 만들고 가장자리가 각진다.
정규분포는 중앙에 몰리고 바깥으로 성겨진다.""",
		"chips": [{"icon": "script", "text": "randfn(0, 1) * radius"}],
		"code": """start = end  # 같은 x/z
start.y = -8.0  # 수직으로만 상승""",
		"try": "한 발 쏘기 → 매번 다른 곳, 대부분 중앙 근처",
	},
	{
		"title": "루프 길이가 두 곳에 흩어진 함정",
		"body": """tick_size(100)와 SpawnTimer.wait_time(0.1)이 곱해져
루프 10초가 되는데 [b]서로 다른 곳에 있다[/b].
한쪽만 바꾸면 의도가 깨진다 — 루프 길이를 export로.""",
		"chips": [{"icon": "script", "text": "tick_size / wait_time"}],
	},
]

var _scale := 1.0


func _ready() -> void:
	pass


func get_chapter_title() -> String:
	return "확률 커브 — 리듬을 점으로 찍기"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.probability_scale = _scale if index == 0 else 1.0


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "확률 배율", 0.0, 4.0, _scale, _on_scale_changed, [0])

	var launch := Button.new()
	launch.text = "한 발 쏘기"
	launch.pressed.connect(func() -> void: world.launch_rocket(10.0))
	parent.add_child(launch)
	bind_steps([launch], [1])


func _on_scale_changed(value: float) -> void:
	_scale = value
	if current_step == 0:
		world.probability_scale = value
