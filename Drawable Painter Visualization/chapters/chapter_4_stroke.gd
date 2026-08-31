extends PainterChapter
## 챕터 4 — 스트로크. 끊긴 점을 보간으로 잇고, 스트로크마다 마스크를 굴린다.

const STEPS: Array[Dictionary] = [
	{
		"title": "이벤트마다 한 방씩 찍어 보기",
		"body": """마우스 이벤트는 프레임당 몇 개뿐이다.
같은 속도로 그어도 [b]자국이 점점이 끊긴다[/b] —
이 호는 이벤트 12개를 흉내 낸 것.""",
		"chips": [
			{"icon": "script", "text": "canvas.paint_at"},
		],
		"code": "canvas.paint_at(uv, size, brush)",
		"try": "다음 스텝과 같은 호를 비교하기",
	},
	{
		"title": "두 UV 사이를 보간해 잇기",
		"body": """직전 UV에서 이번 UV까지,
[b]UV 거리 × steps_per_uv_unit[/b] 횟수만큼
스탬프를 깔아 틈을 메운다.""",
		"chips": [
			{"icon": "script", "text": "canvas.paint_segment"},
		],
		"code": """steps_per_uv_unit = 100  # ← 슬라이더
var n := int(max(1.0,
    (to - from).length() * steps))""",
		"try": "슬라이더를 10까지 내리면 다시 점선이 된다",
	},
	{
		"title": "스트로크마다 마스크 굴리기",
		"body": """누를 때마다 마스크 오프셋·회전을 굴린다.
같은 마스크라도 [b]줄마다 무늬가 달라진다.[/b]
(원본 셰이더엔 maskRotation 유니폼이 없어
회전은 조용히 무시된다 — 이식본에서 연결했다)""",
		"chips": [
			{"icon": "script", "text": "randomize_mask_transform"},
			{"icon": "shader", "text": "maskOffset · maskRotation"},
		],
		"code": """mat.set_shader_parameter("maskRotation",
    lerp(0.0, TAU, rng.randf()))""",
		"try": "직접 여러 번 긋기 — 그을 때마다 무늬가 다르다",
	},
]

var _steps_per_uv := 100.0


func _ready() -> void:
	world.set_view(PI, -0.15, 0.32)


func get_chapter_title() -> String:
	return "점을 선으로 잇기"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.set_interactive(index == 2)
	world.use_paint_canvas()
	world.brush.set_opacity(1.0)
	world.brush.set_brush(0)
	var stone: BrushSet = world.brushes()[0]
	var path := world.arc_path(Vector2(0.35, 0.56), Vector2(0.65, 0.54), 12, 0.05)
	match index:
		0:
			world.brush.set_mask(0)
			world.paint_screen_path(path, 90.0, stone, true)
		1:
			world.brush.set_mask(0)
			world.paint_screen_path(path, 90.0, stone, false, int(_steps_per_uv))
			update_code(_steps_code())
		2:
			world.brush.set_mask(2)
			world.brush.set_size(70.0)
			for row in 3:
				world.brush.randomize_mask_transform()
				var y := 0.36 + 0.12 * row
				world.paint_screen_path(
						world.arc_path(Vector2(0.36, y), Vector2(0.64, y), 8, 0.02),
						70.0, stone, false)


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "steps_per_uv_unit", 5.0, 200.0, _steps_per_uv,
			_on_steps_changed, [1])
	add_toggle(parent, "다시 긋기 (마스크 새로 굴림)", false, _on_repaint_toggled, [2])
	add_texture_view(parent, "albedo (라이브)", world.get_albedo_texture(), [], 170.0)


func _on_steps_changed(value: float) -> void:
	_steps_per_uv = value
	if current_step == 1:
		apply_step(1)


func _on_repaint_toggled(_pressed: bool) -> void:
	if current_step == 2:
		apply_step(2)


func _steps_code() -> String:
	return ("steps_per_uv_unit = %d  # ← 슬라이더\nvar n := int(max(1.0,\n    (to - from).length() * steps))"
			% int(_steps_per_uv))
