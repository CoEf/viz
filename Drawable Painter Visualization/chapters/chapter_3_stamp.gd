extends PainterChapter
## 챕터 3 — 브러시 스탬프. draw.gdshader의 블릿 한 방을 층층이 해부한다.
## 회색 스탬프는 이식본에만 넣은 debug_mode 유니폼이 알파를 그대로 찍은 것.

const STEPS: Array[Dictionary] = [
	{
		"title": "사각 블릿에 원형 감쇠 넣기",
		"body": """블릿 단위는 어디까지나 [b]사각 렉트[/b]다.
렉트 안 픽셀마다 중심 거리로 알파를 깎아
원형 붓이 된다 — 지금은 그 알파만 회색으로 찍었다.""",
		"chips": [
			{"icon": "shader", "text": "draw.gdshader blit()"},
		],
		"code": """float radius = length(UV * 2.0 - 1.0);
float alpha =
    1.0 - smoothstep(0.2, 0.8, radius);""",
		"try": "크기 슬라이더 → 렉트째 커진다 (오른쪽 캔버스가 정확하다)",
	},
	{
		"title": "마스크 곱해 자국 깨뜨리기",
		"body": """감쇠에 노이즈 마스크의 회색값을 곱한다.
[b]붓 그림 파일은 없다[/b] —
원 감쇠 × 마스크가 곧 붓 모양이다.""",
		"chips": [
			{"icon": "resource", "text": "BrushMask"},
			{"icon": "shader", "text": "mask 유니폼"},
		],
		"code": """float m = texture(mask, maskUV).r;
alpha *= m * opacity;""",
		"try": "마스크 크기 슬라이더 → 무늬 밀도가 변한다",
	},
	{
		"title": "브러시 다섯 장을 세 출력에 나눠 싣기",
		"body": """BrushSet은 텍스처 5장 묶음이다.
blit_rect_multi 한 호출이 [b]COLOR0/1/2[/b]로
albedo·normal·ORM 세 캔버스에 동시에 쓴다.""",
		"chips": [
			{"icon": "resource", "text": "BrushSet"},
			{"icon": "script", "text": "blit_rect_multi"},
			{"icon": "shader", "text": "COLOR0/1/2"},
		],
		"code": """COLOR0 = vec4(albedo.rgb, a * alpha);
COLOR1 = vec4(normal.rgb, alpha);
COLOR2 = vec4(ao, rough, metal, alpha);""",
		"try": "오른쪽 세 캔버스의 같은 자리에 자국이 동시에 생겼다",
	},
	{
		"title": "무늬를 캔버스 좌표에 고정하기",
		"body": """브러시 albedo는 붓 좌표가 아니라
[b]캔버스 UV(FRAGCOORD)[/b]로 샘플링된다.
붓은 무늬를 '찍는' 게 아니라 '드러내는' 스텐실이다.""",
		"chips": [
			{"icon": "shader", "text": "FRAGCOORD.xy / texture_size"},
		],
		"code": """vec2 uv = FRAGCOORD.xy / texture_size;
vec4 albedo =
    texture(albedo_texture, uv);""",
		"try": "직접 겹쳐 칠하기 — 자국이 겹쳐도 무늬는 이음매 없이 이어진다",
	},
	{
		"title": "낮은 불투명도로 겹쳐 쌓기",
		"body": """opacity는 스탬프 한 방의 알파 상한이다.
블렌드가 blend_mix라 [b]겹칠수록 짙어진다[/b] —
에어브러시가 되는 이유.""",
		"chips": [
			{"icon": "shader", "text": "render_mode blend_mix"},
			{"icon": "script", "text": "brush.set_opacity"},
		],
		"code": """opacity = 0.30   # ← 슬라이더
alpha *= m * opacity;""",
		"try": "왼쪽부터 1·2·4·8번 겹쳐 찍었다 — 같은 붓, 다른 횟수",
	},
]

var _draw_size := 220.0
var _mask_scale := 1.0
var _opacity := 0.3


func _ready() -> void:
	world.set_view(PI, -0.15, 0.3)


func get_chapter_title() -> String:
	return "브러시 스탬프 해부"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.set_interactive(index == 3)
	world.use_paint_canvas()
	world.brush.set_mask(0)
	world.brush.set_mask_scale(1.0)
	world.brush.set_opacity(1.0)
	world.brush.set_brush(0)
	var stone: BrushSet = world.brushes()[0]
	match index:
		0:
			world.draw_material.set_shader_parameter("debug_mode", 1)
			world.stamp_at(Vector2(0.5, 0.45), _draw_size, stone)
		1:
			world.draw_material.set_shader_parameter("debug_mode", 3)
			world.brush.set_mask(2)
			world.brush.set_mask_scale(_mask_scale)
			world.stamp_at(Vector2(0.5, 0.45), 260.0, stone)
		2:
			world.stamp_at(Vector2(0.5, 0.45), 260.0, stone)
		3:
			world.brush.set_size(140.0)
			world.stamp_at(Vector2(0.465, 0.5), 210.0, stone)
			world.stamp_at(Vector2(0.5, 0.47), 210.0, stone)
			world.stamp_at(Vector2(0.535, 0.51), 210.0, stone)
		4:
			world.brush.set_opacity(_opacity)
			var godot_brush: BrushSet = world.brushes()[1]
			for spot in 4:
				var at := Vector2(0.44 + 0.054 * spot, 0.5)
				for _repeat in (1 << spot):
					world.stamp_at(at, 130.0, godot_brush)
			update_code(_opacity_code())


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "붓 크기 (px)", 60.0, 512.0, _draw_size, _on_size_changed, [0])
	add_slider(parent, "마스크 크기", 0.4, 3.0, _mask_scale, _on_mask_scale_changed, [1])
	add_slider(parent, "불투명도", 0.05, 1.0, _opacity, _on_opacity_changed, [4])
	add_texture_view(parent, "albedo (라이브)", world.get_albedo_texture(), [], 150.0)
	add_texture_view(parent, "normal (라이브)", world.get_normal_texture(), [2, 3], 130.0)
	add_texture_view(parent, "ORM (라이브)", world.get_orm_texture(), [2, 3], 130.0)


func _on_size_changed(value: float) -> void:
	_draw_size = value
	if current_step == 0:
		apply_step(0)


func _on_mask_scale_changed(value: float) -> void:
	_mask_scale = value
	if current_step == 1:
		apply_step(1)
		update_code("maskScale = %.2f   # ← 슬라이더\nfloat m = texture(mask, maskUV).r;\nalpha *= m * opacity;" % _mask_scale)


func _on_opacity_changed(value: float) -> void:
	_opacity = value
	if current_step == 4:
		apply_step(4)


func _opacity_code() -> String:
	return "opacity = %.2f   # ← 슬라이더\nalpha *= m * opacity;" % _opacity
