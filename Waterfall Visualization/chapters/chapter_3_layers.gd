extends WaterfallChapter
## 챕터 3 — 물결 두 겹. 한 겹의 반복 문제를 보이고, 곱셈으로 깬다.

const STEPS: Array[Dictionary] = [
	{
		"title": "한 겹의 반복을 눈으로 잡기",
		"body": """한 겹만 흘리면 [b]같은 무늬가 주기적으로 돌아온다[/b].
텍스처 높이만큼 흐르면 처음 그 그림이다.
눈은 이런 규칙을 금방 잡아챈다.""",
		"chips": [{"icon": "texture", "text": "waterfall_texture.png"}],
		"code": """layer1 = texture(water_texture,
		UV + TIME * scroll);""",
		"try": "밝은 줄 하나를 몇 초 따라가 보기",
	},
	{
		"title": "두 겹을 곱해 반복 깨기",
		"body": """같은 그림을 [b]속도가 다른 두 겹[/b]으로 흘려 곱한다.
곱셈은 둘 다 밝은 곳만 남긴다.
두 주기가 어긋나 무늬가 매번 달라 보인다.""",
		"chips": [{"icon": "shader", "text": "displacement_n_uvscroll.gdshader"}],
		"code": "overlay = layer1 * layer2;",
		"try": "이제 같은 무늬가 돌아오지 않는다",
	},
	{
		"title": "가로 방향을 서로 어긋내기",
		"body": """두 겹의 세로 속도는 -2로 같다.
[b]가로만 +0.5와 -0.5로 반대[/b]다.
서로 스치는 흐름이 물살의 일렁임을 만든다.""",
		"chips": [{"icon": "shader", "text": "displacement_n_uvscroll.gdshader"}],
		"code": """scroll  = vec2( 0.5, -2.0)
scroll2 = vec2(-0.5, -2.0) // ← 슬라이더""",
		"try": "+0.5에 맞추면 일렁임이 죽는다",
	},
]

var _scroll2_x := -0.5


func get_chapter_title() -> String:
	return "물결 두 겹 곱하기"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.reset_materials()
	world.show_water(true, false)
	world.set_effects(false, false)
	world.set_sky(true)
	world.sun.visible = true
	world.set_fall_param(&"displace_parameter", 0.0)
	world.set_debug(1 if index == 0 else 3)
	if index == 2:
		world.set_fall_param(&"scroll2", Vector2(_scroll2_x, -2.0))
		update_code(_scroll2_code())
	world.frame(Vector3(0, 0.1, 0), 0.35, -0.08, 3.4)


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "물결2 가로 속도", -1.0, 1.0, _scroll2_x, _on_scroll2_changed, [2])


func _on_scroll2_changed(value: float) -> void:
	_scroll2_x = value
	if current_step == 2:
		world.set_fall_param(&"scroll2", Vector2(value, -2.0))
		update_code(_scroll2_code())


func _scroll2_code() -> String:
	return ("scroll  = vec2( 0.5, -2.0)\n"
			+ "scroll2 = vec2(%+.1f, -2.0) // ← 슬라이더" % _scroll2_x)
