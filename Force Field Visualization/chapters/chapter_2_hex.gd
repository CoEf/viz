extends FFChapter
## 챕터 2 — 육각 그리드. 텍스처 2채널: .x는 테두리, .y는 셀 id.
## 셀 id에 sin을 걸면 셀들이 제각각 점멸한다.

const STEPS: Array[Dictionary] = [
	{
		"title": ".x — 육각 테두리",
		"body": """텍스처의 [b]R 채널이 육각 셀의 테두리[/b]다.
min(edge, hex.x) — 교차선·실루엣이 밝은 곳에서만
그리드가 드러난다. 막이 반응하는 느낌의 정체.""",
		"chips": [{"icon": "texture", "text": "hexagon_grid_sampler.png .x"}],
		"try": ".x 보기 → 흰 선이 육각 테두리다",
	},
	{
		"title": ".y — 셀마다 다른 id",
		"body": """[b]G 채널은 셀마다 다른 상수[/b] — 사실상 셀 id다.
sin(id × 10 + TIME)을 문턱으로 자르면
셀들이 [b]서로 다른 타이밍에 점멸[/b]한다.""",
		"chips": [{"icon": "shader", "text": "sin(hex.y * 10.0 + TIME)"}],
		"code": """hex_fill = smoothstep(0.01, 0.,
    (sin(hex.y*10. + TIME*.1)+1.)*.5)
    * height_mask * (1.0 - hex.x);""",
		"try": ".y 보기 → 셀마다 다른 회색 = 다른 위상",
	},
	{
		"title": "적도 밴드 마스크",
		"body": """sin(UV.y·PI)를 0.8~1.0으로 자른 height_mask —
그리드와 점멸이 [b]구의 가운데 띠에서만[/b] 나타난다.
위아래 극은 프레넬 실루엣만 남는다.""",
		"chips": [{"icon": "shader", "text": "height_mask"}],
		"try": "마스크 보기 → 흰 띠가 그리드 허용 구간",
	},
]

var _debug := 0


func _ready() -> void:
	world.reset_params()


func get_chapter_title() -> String:
	return "육각 그리드 — 텍스처 2채널"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.reset_params()
	match index:
		0:
			world.set_layers(true, true, false, false)
			world.set_param("debug_mode", 1 if _debug == 1 else 0)
		1:
			world.set_layers(true, true, true, false)
			world.set_param("debug_mode", 2 if _debug == 2 else 0)
		2:
			world.set_layers(true, true, true, false)
			world.set_param("debug_mode", 3 if _debug == 3 else 0)


func build_panel(parent: VBoxContainer) -> void:
	add_toggle(parent, ".x 테두리 보기", false, _make_debug_handler(1), [0])
	add_toggle(parent, ".y 셀 id 보기", false, _make_debug_handler(2), [1])
	add_toggle(parent, "height_mask 보기", false, _make_debug_handler(3), [2])


func _make_debug_handler(mode: int) -> Callable:
	return func(pressed: bool) -> void:
		_debug = mode if pressed else 0
		world.set_param("debug_mode", _debug)
