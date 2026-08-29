extends WaterfallChapter
## 챕터 4 — 바탕색. 그라데이션을 깔고 물결을 더해 완성색을 만든다.

const STEPS: Array[Dictionary] = [
	{
		"title": "그라데이션 바탕 깔기",
		"body": """바탕은 그림 파일이 아니라 [b]색 3개짜리 그라데이션[/b]이다.
아래 흰색 = 물거품 자리, 위로 갈수록 파랑.
아래 원본과 메시 위 색을 맞대 보자.""",
		"chips": [
			{"icon": "resource", "text": "GradientTexture2D"},
			{"icon": "resource", "text": "Gradient"},
		],
		"code": "base = texture(base_color_texture, UV);",
		"try": "메시의 흰 띠가 시작되는 높이 찾아보기",
	},
	{
		"title": "바탕 더하기 물결로 완성색",
		"body": """합성은 [b]덧셈 한 번[/b]이다.
물결이 지나가는 곳만 바탕보다 밝아져
흰 무늬가 물거품처럼 읽힌다.""",
		"chips": [{"icon": "shader", "text": "displacement_n_uvscroll.gdshader"}],
		"code": """overlay_alpha = 1.0  // ← 슬라이더
ALBEDO = (base + overlay).rgb;""",
		"try": "0으로 → 바탕 그라데이션만 남는다",
	},
]

var _alpha := 1.0


func get_chapter_title() -> String:
	return "바탕색 깔고 합치기"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.reset_materials()
	world.show_water(true, false)
	world.set_effects(false, false)
	world.set_sky(true)
	world.sun.visible = true
	world.set_fall_param(&"displace_parameter", 0.0)
	world.set_fall_param(&"normal_depth", 0.0)
	world.set_debug(4 if index == 0 else 0)
	if index == 1:
		world.set_fall_param(&"overlay_alpha", _alpha)
		update_code(_alpha_code())
	world.frame(Vector3(0, 0.1, 0), 0.35, -0.08, 3.4)


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "물결 세기 (overlay_alpha)", 0.0, 1.0, _alpha, _on_alpha_changed, [1])
	var view := TextureRect.new()
	view.texture = world.fall_base_texture
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.custom_minimum_size = Vector2(0, 160)
	parent.add_child(view)
	bind_steps([view], [0])


func _on_alpha_changed(value: float) -> void:
	_alpha = value
	if current_step == 1:
		world.set_fall_param(&"overlay_alpha", value)
		update_code(_alpha_code())


func _alpha_code() -> String:
	return ("overlay_alpha = %.2f  // ← 슬라이더\n" % _alpha
			+ "ALBEDO = (base + overlay).rgb;")
