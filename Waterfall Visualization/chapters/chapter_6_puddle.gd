extends WaterfallChapter
## 챕터 6 — 웅덩이. 코드 재사용의 표본: 같은 셰이더에 다른 값.

const STEPS: Array[Dictionary] = [
	{
		"title": "셰이더 재사용, 값만 교체",
		"body": """웅덩이도 [b]같은 셰이더[/b]다. 코드는 한 줄도 안 다르다.
다른 것은 ShaderMaterial에 꽂은 값뿐.
느린 스크롤과 촘촘한 UV가 수면을 만든다.""",
		"chips": [
			{"icon": "shader", "text": "displacement_n_uvscroll.gdshader"},
			{"icon": "resource", "text": "ShaderMaterial ×2"},
		],
		"code": """scroll   = vec2(0.5, -0.5)
uv_scale = vec2(2, 4)
overlay_alpha = 0.5""",
		"try": "폭포와 웅덩이의 흐름 속도 비교",
	},
	{
		"title": "폭포 값을 꽂아 보기",
		"body": """오른쪽 토글로 웅덩이에 [b]폭포의 값[/b]을 그대로 넣어 보자.
수면이 폭포처럼 곤두박질친다.
물의 성격을 정하는 건 셰이더가 아니라 데이터다.""",
		"chips": [{"icon": "resource", "text": "ShaderMaterial"}],
		"code": """material.set_shader_parameter(
		"scroll", Vector2(0.5, -2))""",
		"try": "토글 → 웅덩이가 폭포가 된다",
	},
	{
		"title": "명암 뒤집은 텍스처 쓰기",
		"body": """웅덩이의 물결 텍스처는 [b]명암을 뒤집은 판[/b]이다.
폭포는 밝은 줄이 굵고, 웅덩이는 잔무늬만 남는다.
곱셈 결과가 그만큼 얌전해진다.""",
		"chips": [{"icon": "texture", "text": "waterfall_texture_inv.png"}],
		"code": """water_texture  = texture_inv.png
water_texture2 = texture_inv.png""",
		"try": "아래 원본 두 장 비교",
	},
]

var _swapped := false


func get_chapter_title() -> String:
	return "같은 셰이더로 웅덩이"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.reset_materials()
	world.show_water(true, true)
	world.set_effects(false, false)
	world.set_sky(true)
	world.sun.visible = true
	if index == 1 and _swapped:
		world.swap_puddle_params(true)
	# 웅덩이가 주인공 — 내려다보는 시점.
	world.frame(Vector3(0, -0.6, 0.3), 0.25, -0.5, 3.4)


func build_panel(parent: VBoxContainer) -> void:
	add_toggle(parent, "웅덩이에 폭포 값 꽂기", _swapped, _on_swap_toggled, [1])
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	for entry: Array in [["폭포", WaterfallWorld.TEX_FALL], ["웅덩이", WaterfallWorld.TEX_FALL_INV]]:
		var column := VBoxContainer.new()
		var label := Label.new()
		label.text = str(entry[0])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var view := TextureRect.new()
		view.texture = entry[1] as Texture2D
		view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		view.custom_minimum_size = Vector2(0, 150)
		view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_child(label)
		column.add_child(view)
		row.add_child(column)
	parent.add_child(row)
	bind_steps([row], [2])


func _on_swap_toggled(pressed: bool) -> void:
	_swapped = pressed
	if current_step == 1:
		world.swap_puddle_params(pressed)
