extends FieldChapter
## 챕터 1 — 지터 그리드. 순수 랜덤은 뭉치고, 균등 격자는 기계적이다.
## 격자 + 셀 안 원형 랜덤 오프셋이 절충안.

const STEPS: Array[Dictionary] = [
	{
		"title": "격자에 지터 더하기",
		"body": """30×30 격자 위치에 [b]원형 범위의 작은 랜덤[/b]을 더한다.
방향은 from_angle, 거리는 randf — 셀 안에서 원형으로.
사각 범위면 대각선이 더 멀어 격자가 비친다.""",
		"chips": [{"icon": "script", "text": "Vector2.from_angle(randf()·TAU)"}],
		"try": "지터 0으로 → 모눈종이에 심은 밭이 된다",
	},
	{
		"title": "거리값 하나로 컷과 페이드",
		"body": """dist = 1 − 중심거리. 반경 밖은 버리고(컷),
남은 것의 [b]스케일에 dist를 다시 곱한다[/b](페이드).
경계가 뚝 끊기지 않고 흐려지는 원형 섬.""",
		"chips": [{"icon": "script", "text": "if dist < 0.5: continue"}],
		"code": """t = t.scaled_local(ONE * base
    * scale_factor * dist * 2.0)""",
		"try": "컷 반경을 키우면 → 섬이 작아진다",
	},
	{
		"title": "96 : 4로 나눠 담기",
		"body": """int(randf() < 0.96) — 불리언을 인덱스로 캐스팅.
96%는 풀, 4%는 꽃 — 배열 두 개에 나눠
서로 다른 MultiMesh로 보낸다. [b]드문 꽃이 단조로움을 깬다[/b].""",
		"chips": [{"icon": "script", "text": "int(randf() < ratio)"}],
		"try": "비율을 0.5로 → 꽃이 절반, 화단이 된다",
	},
]

var _jitter := 0.5
var _cut := 0.5
var _ratio := 0.96


func _ready() -> void:
	world.set_butterflies_visible(false)


func get_chapter_title() -> String:
	return "지터 그리드 — 심는 규칙"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	match index:
		0:
			world.regenerate(_jitter, 0.5, 0.96, true)
			update_code(_jitter_code())
		1:
			world.regenerate(0.5, _cut, 0.96, true)
		2:
			world.regenerate(0.5, 0.5, _ratio, true)
			update_code(_ratio_code())


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "지터 (원본 0.5)", 0.0, 1.0, _jitter, _on_jitter_changed, [0])
	add_slider(parent, "컷 반경 (원본 0.5)", 0.2, 0.9, _cut, _on_cut_changed, [1])
	add_slider(parent, "풀 비율 (원본 0.96)", 0.5, 1.0, _ratio, _on_ratio_changed, [2])


func _on_jitter_changed(value: float) -> void:
	_jitter = value
	world.regenerate(value, 0.5, 0.96, true)
	if current_step == 0:
		update_code(_jitter_code())


func _on_cut_changed(value: float) -> void:
	_cut = value
	world.regenerate(0.5, value, 0.96, true)


func _on_ratio_changed(value: float) -> void:
	_ratio = value
	world.regenerate(0.5, 0.5, value, true)
	if current_step == 2:
		update_code(_ratio_code())


func _jitter_code() -> String:
	return ("v = from_angle(randf() * TAU)\n"
			+ "    / res * randf() * %.2f ← 슬라이더" % _jitter)


func _ratio_code() -> String:
	return "idx = int(randf() < %.2f) ← 슬라이더" % _ratio
