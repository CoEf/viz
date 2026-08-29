extends WaterfallChapter
## 챕터 2 — UV 스크롤. 폭포의 핵심 트릭 하나를 물결 한 겹으로 보여 준다.
## 정점 변위·노멀맵은 아직 끄고, 물결 1만 debug_view로 그대로 띄운다.

const STEPS: Array[Dictionary] = [
	{
		"title": "폭포 그림을 자리에 붙이기",
		"body": """물 텍스처 한 장을 폭포 메시에 그냥 얹었다.
[b]아직 아무것도 안 움직인다.[/b]
지금은 물결 한 겹만 계산 없이 보이게 한 상태다.""",
		"chips": [
			{"icon": "texture", "text": "waterfall_texture.png"},
			{"icon": "node3d", "text": "MeshInstance3D (waterfall)"},
		],
		"code": """vec2 uv1 = UV;  // 아직 그대로
layer1 = texture(water_texture, uv1);""",
		"try": "시점을 돌려 메시에 그림이 감긴 모양 보기",
	},
	{
		"title": "UV에 시간을 더해 흘리기",
		"body": """그림을 움직이는 게 아니라 [b]읽는 좌표를 민다[/b].
UV에 TIME × scroll을 더하면
텍스처가 반복되며 끝없이 흘러내린다.""",
		"chips": [
			{"icon": "shader", "text": "displacement_n_uvscroll.gdshader"},
		],
		"code": """scroll = vec2(0.5, -2.0) // ← 슬라이더
uv1 = UV + TIME * scroll;""",
		"try": "속도 0 → 다시 붙박이 그림",
	},
	{
		"title": "흘리는 그림의 정체 보기",
		"body": """원본은 [b]가로로 굽이치는 물결 띠[/b] 그림이다.
위아래 경계가 이어져 있어 반복 스크롤이 티 나지 않는다.
아래 원본과 메시 위 무늬를 맞대 보자.""",
		"chips": [{"icon": "texture", "text": "waterfall_texture.png"}],
		"try": "원본의 어두운 띠를 메시에서 찾아보기",
	},
]

var _speed := 1.0


func get_chapter_title() -> String:
	return "그림 흘려보내기"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.reset_materials()
	world.show_water(true, false)
	world.set_effects(false, false)
	world.set_sky(true)
	world.sun.visible = true
	world.set_debug(1)
	world.set_fall_param(&"displace_parameter", 0.0)
	# 이 챕터는 메커니즘만 본다 — 코드 칸의 "uv1 = UV + …"가 화면과
	# 정확히 일치하도록 UV 스케일을 1로 눌러 둔다. 실제 값은 챕터 3부터.
	world.set_fall_param(&"uv_scale", Vector2.ONE)
	world.set_fall_param(&"uv_scale2", Vector2.ONE)
	if index == 0:
		world.set_fall_param(&"scroll", Vector2.ZERO)
		world.set_fall_param(&"scroll2", Vector2.ZERO)
	else:
		_apply_speed()
		update_code(_scroll_code())
	world.frame(Vector3(0, 0.1, 0), 0.35, -0.08, 3.4)


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "흐름 속도 배율", 0.0, 2.0, _speed, _on_speed_changed, [1, 2])
	var view := TextureRect.new()
	view.texture = WaterfallWorld.TEX_FALL
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.custom_minimum_size = Vector2(0, 200)
	parent.add_child(view)
	bind_steps([view], [2])


func _on_speed_changed(value: float) -> void:
	_speed = value
	if current_step >= 1:
		_apply_speed()
		update_code(_scroll_code())


func _apply_speed() -> void:
	world.set_fall_param(&"scroll", Vector2(0.5, -2.0) * _speed)
	world.set_fall_param(&"scroll2", Vector2(-0.5, -2.0) * _speed)


func _scroll_code() -> String:
	var scroll := Vector2(0.5, -2.0) * _speed
	return ("scroll = vec2(%.1f, %.1f) // ← 슬라이더\n" % [scroll.x, scroll.y]
			+ "uv1 = UV + TIME * scroll;")
