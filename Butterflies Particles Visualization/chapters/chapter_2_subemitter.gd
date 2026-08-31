extends BFChapter
## 챕터 2 — 서브이미터. 나비마다 초당 4개의 반짝이를 궤적에 흘린다.

const STEPS: Array[Dictionary] = [
	{
		"title": "나비가 반짝이를 흘린다",
		"body": """sub_emitter_frequency = 4 — [b]나비마다 초당 4개[/b].
1024마리 × 반짝이 수명 0.5초 → 풀 2048개.
9편 fireworks처럼 amount가 곱셈으로 맞아떨어진다.""",
		"chips": [
			{"icon": "node3d", "text": "sub_emitter → Sparks"},
			{"icon": "resource", "text": "sub_emitter_frequency"},
		],
		"try": "빈도를 16으로 → 반짝이 비가 내린다 (풀 부족도 관찰)",
	},
	{
		"title": "반짝이의 짧은 생",
		"body": """수명 0.5초, 위로 뜨는 중력, align 3.
scale 커브는 0.6까지 커졌다 줄고,
alpha 커브는 0.6부터 사라진다 — [b]커브 두 개가 생애 전부[/b].""",
		"chips": [{"icon": "resource", "text": "scale_curve / alpha_curve"}],
		"code": """lifetime = 0.5
gravity = (0, 1, 0)  # 위로""",
	},
]

var _freq := 4.0


func get_chapter_title() -> String:
	return "서브이미터 — 흘리는 반짝이"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.set_spark_frequency(_freq if index == 0 else 4.0)
	if index == 0:
		update_code(_freq_code())


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "sub_emitter_frequency", 0.0, 16.0, _freq, _on_freq_changed, [0])


func _on_freq_changed(value: float) -> void:
	_freq = value
	world.set_spark_frequency(value)
	if current_step == 0:
		update_code(_freq_code())


func _freq_code() -> String:
	return ("sub_emitter_frequency = %.0f ← 슬라이더\n" % _freq
			+ "// 풀 = 1024마리 × 빈도 × 수명 0.5s")
