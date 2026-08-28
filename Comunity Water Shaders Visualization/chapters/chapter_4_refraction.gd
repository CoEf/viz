extends WaterChapter
## 챕터 4 — 굴절 축. 수면 아래를 어떻게 가져오는가. 여덟 개가 화면을 한 번 더 읽는다.

const STEPS: Array[Dictionary] = [
	{
		"title": "화면 텍스처를 법선만큼 밀어 읽기",
		"body": """굴절은 [b]이미 그려진 화면을 다시 읽는 것[/b]이다.
읽는 좌표를 수면 법선의 xy만큼 밀면 바닥이 휘어 보인다.
왼쪽 17번은 화면을 안 읽어서 체커가 곧게 남는다.""",
		"chips": [
			{"icon": "setting", "text": "hint_screen_texture"},
			{"icon": "shader", "text": "16_cs2_water fragment()"},
		],
		"code": """refraction_offset = blended_normal.xy * 0.050;
refracted = texture(screen_texture,
        SCREEN_UV + refraction_offset).rgb;""",
		"try": "굴절 슬라이더를 0으로 — 오른쪽 체커도 곧게 펴진다",
	},
	{
		"title": "가져온 색에 물색을 곱해 잠기게 하기",
		"body": """3번도 같은 방식으로 화면을 읽는다.
그런데 [b]가져온 색에 물색을 곱한 뒤[/b] 깊이만큼 다시 물색으로 섞는다.
그래서 조금만 깊어져도 굴절한 그림이 통째로 잠긴다 —
왼쪽에 보이는 체커가 오른쪽엔 흔적도 없다.""",
		"chips": [{"icon": "shader", "text": "03_realistic_water fragment()"}],
		"code": """color = mix(screen_color * dye_color,
            dye_color * 0.25, blend * 0.5);""",
		"try": "오른쪽에 남는 건 하늘 반사와 스펙큘러뿐이다",
	},
	{
		"title": "flow map으로 흐름 방향 정하기",
		"body": """16번은 UV를 시간에 따라 미는데, [b]미는 방향을 텍스처가 정한다.[/b]
오른쪽 패널의 그림이 그 flow map이고,
R이 x방향, G가 z방향이다 — 색이 곧 벡터다.
같은 물살을 두 벌 어긋나게 흘려 이음매를 지운다.""",
		"chips": [
			{"icon": "texture", "text": "flow_map (R=X, G=Y)"},
			{"icon": "shader", "text": "16_cs2_water fragment()"},
		],
		"code": """flow_dir = texture(flow_map, UV).rg*2.0 - 1.0;
uv1 = UV + flow_dir * 0.80 * TIME * 0.05;
uv2 = UV + flow_dir * 0.80 * (TIME*0.05 + 0.5);""",
		"try": "패널의 flow map 색과 수면이 흐르는 방향을 맞춰보기",
	},
	{
		"title": "수면 아래에서 위를 올려다보기",
		"body": """23번은 [b]위에서 보면 아무 의미가 없다.[/b]
물속에서 위를 보면 하늘이 원 안에만 보이고,
그 밖은 전반사라 바닥이 비친 거울이 된다 — 스넬의 창.
경계 각도는 굴절률이 정한다.""",
		"chips": [{"icon": "shader", "text": "23_snells_window fragment()"}],
		"code": """cos_theta = dot(normal, view);
return step(sqrt(1.0 - cos_theta*cos_theta)
            * ior, 1.0);""",
		"try": "굴절률 슬라이더 — 밝은 창의 크기가 바뀐다",
	},
]

var _refraction := 0.05
var _flow_strength := 0.8
var _ior := 1.333
var _flow_view: TextureRect


func get_chapter_title() -> String:
	return "굴절 — 수면 아래를 어떻게 가져오는가"


func get_steps() -> Array[Dictionary]:
	return STEPS


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "굴절 (refraction_strength)", 0.0, 0.25, _refraction, _on_refraction, [0])
	add_slider(parent, "흐름 세기 (flow_strength)", 0.0, 3.0, _flow_strength, _on_flow, [2])
	add_slider(parent, "굴절률 (index_of_refraction)", 1.0, 2.2, _ior, _on_ior, [3])

	_flow_view = TextureRect.new()
	_flow_view.texture = WaterTextures.get_texture(&"flow_map")
	_flow_view.custom_minimum_size = Vector2(0.0, 220.0)
	_flow_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	parent.add_child(_flow_view)
	bind_steps([_flow_view], [2])


func apply_step(index: int) -> void:
	world.set_canvas(null)
	world.set_postfx(null)
	world.set_overlay(null)
	match index:
		0:
			world.set_dive(false)
			world.show_plots([17, {"id": 16, "params": {"refraction_strength": _refraction}}])
			world.frame(0.22, -0.46, 1.02)
		1:
			world.set_dive(false)
			world.show_plots([16, 3])
			world.frame(0.22, -0.46, 1.02)
		2:
			world.set_dive(false)
			world.show_plots([{"id": 16, "params": {"flow_strength": _flow_strength}}])
			world.frame(0.22, -0.40, 0.94)
		_:
			world.show_plots([{"id": 23, "params": {"index_of_refraction": _ior}}])
			world.frame(0.0, -0.40, 1.0)
			world.set_dive(true, 0)
	_push_code()


func _on_refraction(value: float) -> void:
	_refraction = value
	if current_step == 0:
		world.set_param(1, "refraction_strength", value)
	_push_code()


func _on_flow(value: float) -> void:
	_flow_strength = value
	if current_step == 2:
		world.set_param(0, "flow_strength", value)
	_push_code()


func _on_ior(value: float) -> void:
	_ior = value
	if current_step == 3:
		world.set_param(0, "index_of_refraction", value)
	_push_code()


func _push_code() -> void:
	match current_step:
		0:
			update_code("""refraction_offset = blended_normal.xy * %.3f;
                                       ^ 슬라이더
refracted = texture(screen_texture,
        SCREEN_UV + refraction_offset).rgb;""" % _refraction)
		2:
			update_code("""flow_dir = texture(flow_map, UV).rg*2.0 - 1.0;
uv1 = UV + flow_dir * %.2f * TIME * 0.05;
                     ^ 슬라이더
uv2 = UV + flow_dir * %.2f * (TIME*0.05 + 0.5);"""
					% [_flow_strength, _flow_strength])
		3:
			update_code("""cos_theta = dot(normal, view);
return step(sqrt(1.0 - cos_theta*cos_theta)
            * %.3f, 1.0);
              ^ 굴절률 <- 슬라이더""" % _ior)
