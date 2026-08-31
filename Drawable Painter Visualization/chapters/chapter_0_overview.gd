extends PainterChapter
## 챕터 0 — 완성된 페인터. 직접 칠해 보고, 상태가 텍스처 3장뿐임을 확인한다.

const STEPS: Array[Dictionary] = [
	{
		"title": "완성된 페인터 만져 보기",
		"body": """인형 표면이 곧 캔버스다.
칠한 결과는 오른쪽 세 텍스처에만 쌓인다 —
[b]메시도 머티리얼도 그대로다.[/b]""",
		"chips": [
			{"icon": "resource", "text": "DrawableTexture2D ×3"},
			{"icon": "shader", "text": "draw.gdshader"},
		],
		"try": "인형을 드래그해 칠하기 · 빈 곳 드래그는 회전",
	},
	{
		"title": "여섯 시스템으로 쪼개기",
		"body": """챕터 하나가 시스템 하나다.
[b]캔버스 → 피킹 → 스탬프 → 스트로크[/b]
→ 파워워시 응용 → 지휘자 순서로 켠다.""",
		"chips": [
			{"icon": "script", "text": "painter_controller.gd"},
		],
		"try": "칠한 자국이 다음 챕터로 넘어가면 사라진다 — 상태는 텍스처뿐",
	},
]


func _ready() -> void:
	world.set_view(PI, -0.18, 0.34)


func get_chapter_title() -> String:
	return "완성본 훑어보기"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(_index: int) -> void:
	world.use_paint_canvas()
	world.set_interactive(true)
	world.brush.set_opacity(1.0)
	world.brush.set_size(96.0)
	# 미리 칠해 둔 데모 자국: 돌 재질 호 + 보로노이 마스크 획 + 인형 무늬 복원.
	var stone: BrushSet = world.brushes()[0]
	var godot_brush: BrushSet = world.brushes()[1]
	world.brush.set_mask(0)
	world.brush.set_brush(0)
	world.paint_screen_path(
			world.arc_path(Vector2(0.36, 0.62), Vector2(0.64, 0.58), 14, 0.08),
			110.0, stone)
	world.brush.set_mask(2)
	world.paint_screen_path(
			world.arc_path(Vector2(0.34, 0.4), Vector2(0.66, 0.42), 14, -0.06),
			90.0, stone)
	world.brush.set_mask(0)
	world.brush.set_brush(1)
	world.paint_screen_path(
			world.arc_path(Vector2(0.42, 0.3), Vector2(0.58, 0.3), 10, 0.04),
			120.0, godot_brush)
	world.brush.set_brush(0)


func build_panel(parent: VBoxContainer) -> void:
	add_texture_view(parent, "albedo (라이브)", world.get_albedo_texture(), [], 150.0)
	add_texture_view(parent, "normal (라이브)", world.get_normal_texture(), [], 150.0)
	add_texture_view(parent, "ORM (라이브)", world.get_orm_texture(), [], 150.0)
	add_caption(parent, "직접 칠하면 3D와 세 캔버스가 같이 변한다")
