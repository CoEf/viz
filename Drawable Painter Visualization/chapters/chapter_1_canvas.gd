extends PainterChapter
## 챕터 1 — 캔버스. 정적 텍스처에서 DrawableTexture2D 3장으로 갈아 끼운다.

const STEPS: Array[Dictionary] = [
	{
		"title": "보통 텍스처로 시작하기",
		"body": """지금 인형은 원본 PNG 3장을 입고 있다.
ImageTexture는 CPU 이미지의 GPU 사본이라
[b]런타임에 픽셀을 바꿀 통로가 없다.[/b]""",
		"chips": [
			{"icon": "texture", "text": "ImageTexture"},
			{"icon": "resource", "text": "ORMMaterial3D"},
		],
	},
	{
		"title": "DrawableTexture2D 3장 할당하기",
		"body": """setup() 한 번으로 GPU에 빈 캔버스가 생긴다.
초기색은 albedo 회색, normal (0.5,0.5,1),
ORM (0,1,0) — 인형이 민무늬가 된다.""",
		"chips": [
			{"icon": "resource", "text": "DrawableTexture2D"},
			{"icon": "script", "text": "paint_canvas_component.gd"},
		],
		"code": """_albedo_texture.setup(1024, 1024,
    DRAWABLE_FORMAT_RGBA8_SRGB,
    Color(0.75, 0.75, 0.75, 1.0), false)""",
		"try": "3D 인형과 오른쪽 세 캔버스가 같은 초기색인지 보기",
	},
	{
		"title": "머티리얼 슬롯에 꽂아 표면과 잇기",
		"body": """ORMMaterial3D의 세 슬롯에 캔버스를 꽂는다.
이후 블릿 한 번이면 [b]다음 프레임 표면에 보인다[/b] —
CPU 왕복 업로드가 없다.""",
		"chips": [
			{"icon": "resource", "text": "ORMMaterial3D"},
			{"icon": "texture", "text": "albedo·normal·orm_texture"},
		],
		"code": """albedo_texture = drawable_albedo
normal_texture = drawable_normal
orm_texture    = drawable_orm""",
		"try": "시험 스탬프 한 방이 3D와 캔버스 양쪽에 동시에 찍혔다",
	},
]


func _ready() -> void:
	world.set_view(PI, -0.18, 0.32)


func get_chapter_title() -> String:
	return "그릴 수 있는 텍스처"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.set_interactive(false)
	if index == 0:
		world.use_original_textures()
		return
	world.use_paint_canvas()
	if index == 2:
		world.brush.set_mask(0)
		world.brush.set_opacity(1.0)
		world.stamp_at(Vector2(0.5, 0.48), 150.0, world.brushes()[0])


func build_panel(parent: VBoxContainer) -> void:
	add_texture_view(parent, "albedo (라이브)", world.get_albedo_texture(), [1, 2], 150.0)
	add_texture_view(parent, "normal (라이브)", world.get_normal_texture(), [1, 2], 150.0)
	add_texture_view(parent, "ORM (라이브)", world.get_orm_texture(), [1, 2], 150.0)
