extends FurChapter
## 챕터 4 — light() 직접 짜기. 이 저장소에서 커스텀 light()를 쓰는 유일한 셰이더.
## 터미네이터 뻥튀기, 림 게이팅, 거꾸로 된 글로시니스, 그리고 중복 가산 함정.

const STEPS: Array[Dictionary] = [
	{
		"title": "터미네이터 좁히기",
		"body": """램버트 값을 [b]4배로 뻥튀기한 뒤 clamp[/b] —
빛을 조금이라도 받으면 대부분 1.0으로 포화되고
명암 경계가 좁고 뚜렷해진다. 값싼 툰 셰이딩.""",
		"chips": [{"icon": "shader", "text": "fur.gdshader light()"}],
		"try": "1로 내리면 → 부드러운 램버트로 돌아간다",
	},
	{
		"title": "림은 빛 쪽에만",
		"body": """림 라이트를 [b]NdotL로 게이팅[/b]한다.
안 하면 그림자 쪽 실루엣까지 빛나서
물체가 반투명하게 보인다.""",
		"chips": [{"icon": "shader", "text": "rim = rimDot * NdotL"}],
		"code": """float rim = clamp(
    rimDot * NdotL, 0.0, 1.0);""",
		"try": "게이팅을 끄면 → 그림자 쪽 테두리가 뜬다",
	},
	{
		"title": "글로시니스가 거꾸로다",
		"body": """pow(NdotH, [b]1.0 / _glossiness[/b]) —
값이 클수록 지수가 작아져 [b]덜 반짝인다[/b].
통상적인 명명과 반대라 쓸 때 주의.""",
		"chips": [{"icon": "shader", "text": "_glossiness 0.45 → 지수 2.2"}],
		"try": "0.05로 → 지수 20, 하이라이트가 점이 된다",
	},
	{
		"title": "조명과 무관한 항의 함정",
		"body": """위쪽 실루엣의 흰 테두리 항은 LIGHT를 안 쓰는데
light()는 [b]광원 하나당 한 번씩[/b] 불린다.
라이트를 더 놓는 순간 이 항이 두 배로 더해진다.""",
		"chips": [{"icon": "shader", "text": "step(0.5, fresnel) * object_y"}],
		"code": """// light() 안 — 조명 무관 항
DIFFUSE_LIGHT += step(0.5,
    fresnel(1.5, N, V)) * object_y;""",
		"try": "라이트 추가 → 흰 테두리만 두 배로 밝아진다",
	},
]

var _boost := 4.0
var _gated := true
var _gloss := 0.45


func _ready() -> void:
	world.reset_fur_params()


func get_chapter_title() -> String:
	return "light() — 손으로 짠 라이팅"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.reset_fur_params()
	world.set_second_light(false)
	match index:
		0:
			world.set_fur_param("terminator_boost", _boost)
			update_code(_boost_code())
		1:
			world.set_fur_param("rim_gated", 1.0 if _gated else 0.0)
		2:
			world.set_fur_param("_glossiness", _gloss)
			update_code(_gloss_code())


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "터미네이터 배율 (원본 4)", 1.0, 8.0, _boost, _on_boost_changed, [0])
	add_toggle(parent, "림 NdotL 게이팅", _gated, _on_gated_toggled, [1])
	add_slider(parent, "_glossiness", 0.05, 1.0, _gloss, _on_gloss_changed, [2])
	add_toggle(parent, "라이트 하나 더", false, _on_light_toggled, [3])


func _on_boost_changed(value: float) -> void:
	_boost = value
	world.set_fur_param("terminator_boost", value)
	if current_step == 0:
		update_code(_boost_code())


func _on_gated_toggled(pressed: bool) -> void:
	_gated = pressed
	if current_step == 1:
		world.set_fur_param("rim_gated", 1.0 if pressed else 0.0)


func _on_gloss_changed(value: float) -> void:
	_gloss = value
	world.set_fur_param("_glossiness", value)
	if current_step == 2:
		update_code(_gloss_code())


func _on_light_toggled(pressed: bool) -> void:
	if current_step == 3:
		world.set_second_light(pressed)


func _boost_code() -> String:
	return ("NdotL = clamp(dot(N, L) * ATT\n"
			+ "    * %.1f, 0., 1.); ← 슬라이더" % _boost)


func _gloss_code() -> String:
	return ("specular = pow(NdotH, 1.0 / %.2f)\n" % _gloss
			+ "// 지수 = %.1f ← 슬라이더" % (1.0 / _gloss))
