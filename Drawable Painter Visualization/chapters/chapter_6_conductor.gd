extends PainterChapter
## 챕터 6 — 지휘자. PainterController가 컴포넌트를 조립하고 입력·신호를 잇는다.
## 앞 챕터에서 만난 부품들이 실제로 어떻게 배선되는지가 주제.

const STEPS: Array[Dictionary] = [
	{
		"title": "컴포넌트를 코드에서 조립하기",
		"body": """씬 트리에는 컨트롤러 하나뿐이다.
_ready()가 컴포넌트 5개를 자식으로 만들고
setup()으로 참조를 넘긴다 — [b]씬 배선이 없다.[/b]""",
		"chips": [
			{"icon": "script", "text": "painter_controller.gd"},
			{"icon": "script", "text": "_add_component"},
		],
		"code": """_canvas = _add_component(
    PaintCanvasComponent, "PaintCanvas")
_canvas.setup(plushy, size, material)""",
		"try": "이 워크스루의 월드도 같은 방식으로 조립되어 있다",
	},
	{
		"title": "입력 해석을 한 곳에 모으기",
		"body": """마우스·키보드는 컨트롤러만 읽는다.
컴포넌트는 [b]언제 칠할지 모른다[/b] —
그 덕에 파워워시가 피커·커서를 그대로 재사용한다.""",
		"chips": [
			{"icon": "script", "text": "_unhandled_input"},
		],
		"code": """var uv = _picker.get_uv(cam, mb.position)
if uv != null:
    _paint(uv)""",
		"try": "직접 칠하기 — 지금 입력이 정확히 이 경로로 돈다",
	},
	{
		"title": "상태 변경을 신호로 되돌리기",
		"body": """UI는 '사용자가 만졌다'만 신호로 알리고,
상태는 BrushComponent 혼자 바꾼다.
바뀐 결과가 [b]*_changed 신호[/b]로 UI·커서에 돌아온다.""",
		"chips": [
			{"icon": "signal", "text": "brush_swatch_clicked"},
			{"icon": "signal", "text": "brush_changed"},
		],
		"code": """_ui.brush_swatch_clicked.connect(
    func(i): _brush.set_brush(i))""",
		"try": "브러시 토글을 바꾸기 — 아래 라벨이 brush_changed 신호로 갱신된다",
	},
]

var _brush_label: Label


func _ready() -> void:
	world.set_view(PI, -0.18, 0.34)
	# 스텝 2의 산 증인: brush_changed 신호가 라벨을 갱신한다(원본 UI와 같은 배선).
	world.brush.brush_changed.connect(_on_brush_changed)


func get_chapter_title() -> String:
	return "지휘자 — 컨트롤러"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.use_paint_canvas()
	world.set_interactive(index >= 1)
	world.brush.set_opacity(1.0)
	world.brush.set_mask(0)
	world.brush.set_size(110.0)
	world.brush.set_brush(0)
	if index >= 1:
		world.paint_screen_path(
				world.arc_path(Vector2(0.38, 0.5), Vector2(0.62, 0.48), 10, 0.06),
				90.0, world.brushes()[0])


func build_panel(parent: VBoxContainer) -> void:
	add_toggle(parent, "Godot 브러시로 전환", false, _on_brush_toggled, [2])
	_brush_label = Label.new()
	_brush_label.text = "Brush: Stone"
	parent.add_child(_brush_label)
	bind_steps([_brush_label], [2])
	add_caption(parent,
			"토글 → set_brush(i) → brush_changed 신호 → 이 라벨", [2])


func _on_brush_toggled(pressed: bool) -> void:
	world.brush.set_brush(1 if pressed else 0)


func _on_brush_changed(index: int) -> void:
	if _brush_label != null:
		_brush_label.text = "Brush: " + world.brushes()[index].brush_label
