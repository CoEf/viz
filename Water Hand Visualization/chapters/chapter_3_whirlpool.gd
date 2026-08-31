extends WaterChapter
## 챕터 3 — 소용돌이. 반지름+각도의 sin이 나선을 만들고,
## 그 나선값을 노이즈 샘플링 좌표로 쓰면 무늬가 소용돌이로 감긴다.

const STEPS: Array[Dictionary] = [
	{
		"title": "반지름과 각도로 나선 만들기",
		"body": """sin(반지름 × 크기 + 각도 × 갈래 수).
반지름만이면 동심원, 각도가 더해지면 [b]나선[/b]이 된다.
갈래 수가 나선 팔의 개수다.""",
		"chips": [{"icon": "shader", "text": "swirl()"}],
		"try": "갈래 수를 4로 → 사방으로 나선 팔 네 개",
	},
	{
		"title": "나선 좌표로 노이즈 감기",
		"body": """노이즈 좌표의 x에 [b]반지름[/b], y에 [b]나선값[/b].
텍스처가 소용돌이 모양으로 감긴 채 샘플링된다.
offset을 반지름에 더하면 중심으로 빨려 들어간다.""",
		"chips": [{"icon": "texture", "text": "caustic_texture.png"}],
		"code": """texture(caustic,
    vec2(uv.x + offset * 0.45, s) * 0.6)""",
		"try": "offset을 올리면 → 무늬가 중심으로 빨린다",
	},
	{
		"title": "opening 하나로 크기와 투명도",
		"body": """물 셰이더 bottom_mask와 [b]같은 골격[/b] —
좁은 경계는 남기고 넓은 구간을 노이즈로 갉는다.
opening이 ALPHA 전체에도 곱해져 열림=페이드인.""",
		"chips": [{"icon": "shader", "text": "opening"}],
		"try": "0으로 → 닫히면서 그대로 사라진다",
	},
	{
		"title": "2초 타임라인 훑기",
		"body": """0.4초에 확 열리고, 0.8초 유지, 0.8초에 걸쳐 닫힘.
그동안 offset은 4까지 [b]일정 속도로 계속 회전[/b].""",
		"chips": [{"icon": "node3d", "text": "ArmSpawnEffect/AnimationPlayer"}],
		"code": """opening: 0 → 1(0.4s) → 1(1.2s) → 0(2s)
offset : 0 → 4 (내내)""",
		"try": "0.4초 근처 → 여는 순간이 가장 극적이다",
	},
]

var _size := 4.0
var _arms := 1.0
var _offset := 1.0
var _opening := 1.0
var _scrub_t := 0.4


func _ready() -> void:
	world.solo(false, true, false, false, false)
	world.camera_rig.position = Vector3(-3.6, 0.3, 0.0)
	world.camera_rig.set_view(0.3, -1.0, 5.5)


func get_chapter_title() -> String:
	return "소용돌이 — 극좌표와 나선"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.whirlpool_stop()
	world.reset_whirlpool_params(_opening, _offset)
	world.set_whirlpool_param("swirl_size", _size)
	world.set_whirlpool_param("swirl_arms", int(_arms))
	match index:
		0:
			world.set_whirlpool_param("debug_mode", 1)
			update_code(_swirl_code())
		1:
			update_code(_offset_code())
		2:
			update_code(_opening_code())
		3:
			world.whirlpool_scrub(_scrub_t)


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "나선 크기 (size)", 1.0, 12.0, _size, _on_size_changed, [0])
	add_slider(parent, "갈래 수 (arms)", 1.0, 6.0, _arms, _on_arms_changed, [0])
	add_slider(parent, "offset (빨려들기)", 0.0, 4.0, _offset, _on_offset_changed, [1])
	add_slider(parent, "opening", 0.0, 1.0, _opening, _on_opening_changed, [2])
	var scrub := add_slider(parent, "타임라인 (초)", 0.0, 2.0, _scrub_t, _on_scrub_changed, [3])
	scrub.step = 0.01


func _on_size_changed(value: float) -> void:
	_size = value
	world.set_whirlpool_param("swirl_size", value)
	if current_step == 0:
		update_code(_swirl_code())


func _on_arms_changed(value: float) -> void:
	_arms = roundf(value)
	world.set_whirlpool_param("swirl_arms", int(_arms))
	if current_step == 0:
		update_code(_swirl_code())


func _on_offset_changed(value: float) -> void:
	_offset = value
	world.set_whirlpool_param("offset", value)


func _on_opening_changed(value: float) -> void:
	_opening = value
	world.set_whirlpool_param("opening", value)
	if current_step == 2:
		update_code(_opening_code())


func _on_scrub_changed(value: float) -> void:
	_scrub_t = value
	if current_step == 3:
		world.whirlpool_scrub(value)


func _swirl_code() -> String:
	return ("s = sin(len * %.1f\n" % _size
			+ "    + angle * %.0f.); ← 슬라이더" % _arms)


func _offset_code() -> String:
	return ("texture(caustic, vec2(\n"
			+ "    uv.x + %.2f * 0.45, s) * 0.6)" % _offset)


func _opening_code() -> String:
	return ("ALPHA = ((1.0 - edge)\n"
			+ "    - voronoi * outer) * %.2f;" % _opening)
