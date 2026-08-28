extends SnowChapter
## 챕터 4 — 발자국. 높이맵·브러시를 패널에서 실물로 보여주고,
## 스탬프 → 색 → 정점 변위 → 법선 재계산 → 리필을 한 단계씩 켠다.

const STEPS: Array[Dictionary] = [
	{
		"title": "높이맵에 지나간 자리 기록하기",
		"body": """오른쪽 캔버스가 자국 기록판이다.
[b]흰 = 눈, 검 = 눌림.[/b]
공이 0.3m 갈 때마다 신호 → 검은 붓 한 방.
3D 바닥은 아직 이 맵을 모른 척한다.""",
		"chips": [
			{"icon": "script", "text": "track_maker.gd"},
			{"icon": "signal", "text": "moved"},
			{"icon": "texture", "text": "DrawableTexture2D"},
		],
		"try": "캔버스에 자국이 찍히는 것 관찰",
	},
	{
		"title": "눌린 곳 색과 거칠기 바꾸기",
		"body": """셰이더가 맵을 읽기 시작한다.
바뀌는 건 [b]색과 거칠기뿐[/b], 바닥은 아직 평평하다.""",
		"chips": [{"icon": "shader", "text": "snow_ground.gdshader"}],
		"code": """float press = 1.0 - texture(deform_map, uv).r;
albedo *= mix(1.0, 0.8, press);      // 어둡게
ROUGHNESS = mix(..., 0.32, press);   // 반질하게""",
		"try": "캔버스와 바닥 무늬 비교 — 같은 데이터다",
	},
	{
		"title": "정점을 내려 자국 파기",
		"body": """정점 셰이더가 맵을 읽어 [b]정점을 아래로 내린다.[/b]
바닥을 250×250으로 잘게 쪼갠 이유가 여기 있다.""",
		"chips": [{"icon": "shader", "text": "snow_ground vertex()"}],
		"try": "자국 깊이 슬라이더",
	},
	{
		"title": "법선을 다시 계산해 음영 넣기",
		"body": """정점만 내리면 빛은 여전히 평지로 안다.
이웃 4텍셀의 높이 차로 기울기를 구해
[b]법선을 새로 만든다.[/b] 지금 색 = 그 방향.""",
		"chips": [{"icon": "shader", "text": "snow_ground fragment()"}],
		"code": """hl = texture(map, uv - vec2(texel.x, 0)).r;
hr = texture(map, uv + vec2(texel.x, 0)).r;
n = normalize(vec3((hl-hr)*depth, 1, ...));""",
	},
	{
		"title": "흰색을 덮어 자국 메우기",
		"body": """자국이 영원히 남으면 눈이 내리는 의미가 없다.
아주 옅은 흰색을 맵 전체에 계속 덮어
[b]내리는 눈이 메우는 것처럼[/b] 보이게 한다.""",
		"chips": [
			{"icon": "script", "text": "snow_deform.gd"},
			{"icon": "texture", "text": "DrawableTexture2D"},
		],
		"try": "리필 슬라이더 최대 = 빨리 감기",
	},
]


func _ready() -> void:
	world.set_fall_ratio(0.5)
	world.camera_rig.set_view(0.65, -0.7, 16.0)


func get_chapter_title() -> String:
	return "발자국 남기기"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	var material := world.ground_material()
	material.set_shader_parameter("debug_press_shading", 0.0 if index == 0 else 1.0)
	material.set_shader_parameter("debug_displacement", 1.0 if index >= 2 else 0.0)
	world.set_ground_debug(2 if index == 3 else 0)
	match index:
		0:
			update_code(_stamp_code())
		2:
			update_code(_depth_code())
		4:
			update_code(_refill_code())


func build_panel(parent: VBoxContainer) -> void:
	# 정점 변위는 스텝 2부터 켜진다. 그 전에는 깊이를 흔들어도 지면이 평평하다.
	add_slider(parent, "자국 깊이", 0.0, 0.6, 0.3, _on_depth_changed, [2, 3, 4])
	add_slider(parent, "붓 세기", 0.05, 1.0, 0.45, _on_strength_changed)
	add_slider(parent, "리필 속도 (눈 메워짐)", 0.0, 0.05, 0.01, _on_refill_changed)
	var brush_row := HBoxContainer.new()
	brush_row.add_theme_constant_override("separation", 10)
	var brush_view := TextureRect.new()
	brush_view.texture = world.snow_deform.brush
	brush_view.custom_minimum_size = Vector2(72.0, 72.0)
	brush_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	brush_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	brush_row.add_child(brush_view)
	var brush_caption := Label.new()
	brush_caption.text = "브러시\nGradientTexture2D\n(방사형, 흰→투명)"
	brush_caption.add_theme_font_size_override("font_size", 12)
	brush_caption.modulate = Color(1.0, 1.0, 1.0, 0.65)
	brush_row.add_child(brush_caption)
	parent.add_child(brush_row)
	var map_view := TextureRect.new()
	map_view.texture = world.snow_deform.get_map_texture()
	map_view.custom_minimum_size = Vector2(0.0, 280.0)
	map_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	parent.add_child(map_view)
	add_caption(parent, "높이맵 1024² 실시간 뷰 — 흰: 눈, 검: 눌림")


func _on_depth_changed(value: float) -> void:
	world.ground_material().set_shader_parameter("trail_depth", value)
	if current_step == 2:
		update_code(_depth_code())


func _on_strength_changed(value: float) -> void:
	world.snow_deform.stamp_strength = value
	if current_step == 0:
		update_code(_stamp_code())


func _on_refill_changed(value: float) -> void:
	world.snow_deform.refill_alpha = value
	if current_step == 4:
		update_code(_refill_code())


func _stamp_code() -> String:
	return ("moved.emit(global_position)   # track_maker.gd\n"
			+ "_map.blit_rect(rect, brush,\n"
			+ "		Color(0, 0, 0, %.2f))   # ← 붓 세기" % world.snow_deform.stamp_strength)


func _depth_code() -> String:
	var depth: float = world.ground_material().get_shader_parameter("trail_depth")
	return ("press = 1.0 - textureLod(deform_map, uv).r;\n"
			+ "VERTEX.y -= press * trail_depth;\n"
			+ "// trail_depth = %.2f ← 자국 깊이 슬라이더" % depth)


func _refill_code() -> String:
	return ("# 0.4초마다 맵 전체에\n"
			+ "_map.blit_rect(Rect2i(0, 0, 1024, 1024),\n"
			+ "		white, Color(1, 1, 1, %.3f))   # ← 리필 속도" % world.snow_deform.refill_alpha)
