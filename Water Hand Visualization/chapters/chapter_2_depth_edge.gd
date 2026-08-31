extends WaterChapter
## 챕터 2 — 뎁스 접지선. 교차선을 지우는 대신 연출 재료로 쓴다.
## 좁은 폭(접촉선 보존)과 넓은 폭(노이즈 침식)을 따로 뽑아 조합하는 방법.

const STEPS: Array[Dictionary] = [
	{
		"title": "화면 깊이로 지면 위치 알아내기",
		"body": """뎁스 텍스처를 역투영해 그 픽셀 뒤 표면의 깊이를 얻는다.
이름은 world_pos지만 [b]뷰 공간[/b] —
같은 뷰 공간인 VERTEX.z와 비교가 성립한다.""",
		"chips": [
			{"icon": "shader", "text": "hint_depth_texture"},
			{"icon": "shader", "text": "INV_PROJECTION_MATRIX"},
		],
		"code": """world_pos = INV_PROJECTION_MATRIX
    * vec4(SCREEN_UV*2.-1., depth, 1.);""",
		"try": "노랑 = 지면과 가까운 픽셀 (교차 직전)",
	},
	{
		"title": "좁은 폭 — 접촉선 남기기",
		"body": """0.1 유닛 폭의 마스크는 [b]빼는 쪽이 아니라 남기는 쪽[/b].
물이 지면에 닿는 라인이 또렷하게 유지된다.""",
		"chips": [{"icon": "shader", "text": "small_edge"}],
		"try": "폭을 키우면 → 접촉선이 두꺼워진다",
	},
	{
		"title": "넓은 폭 — 노이즈로 갉기",
		"body": """2.0 유닛 구간에는 [b]보로노이를 곱해 빼는[/b] 항.
닿는 곳은 선명하고, 그 위 2유닛만 부서진다.
물이 지면에 부딪혀 부서지는 느낌의 정체.""",
		"chips": [{"icon": "shader", "text": "bottom_mask"}],
		"code": """mask = (1.0 - small_edge)
    - voronoi * big_edge;""",
		"try": "마스크 보기 → 밑동만 얼룩덜룩 깎여 있다",
	},
	{
		"title": "포말 — 프레넬과 접지의 합",
		"body": """[b]프레넬이 높거나, 접지 마스크가 낮거나[/b] —
둘을 더해 한 번의 step으로 자른다.
실루엣 테두리와 부서지는 밑동에 동시에 흰 띠.""",
		"chips": [{"icon": "shader", "text": "fresnel + bottom_mask"}],
		"code": """ALBEDO += step(0.6,
    f + (1.0 - bottom_mask)) * 0.4;""",
		"try": "포말을 끄면 → 밑동의 흰 띠가 사라진다",
	},
]

var _small := 0.1
var _big := 2.0
var _mask_debug := 0
var _foam := true


func _ready() -> void:
	world.solo(true, false, false, false, false)
	world.pose_arm(1.2)
	world.reset_water_params()
	world.camera_rig.position = Vector3(-3.6, 1.0, 0.0)
	world.camera_rig.set_view(0.55, -0.18, 5.0)


func get_chapter_title() -> String:
	return "뎁스 접지선 — 교차선을 재료로"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.reset_water_params()
	world.set_water_param("edge_small", _small)
	world.set_water_param("edge_big", _big)
	match index:
		0:
			world.set_water_param("debug_mode", 2)
		1:
			world.set_water_param("debug_mode", 2)
			update_code(_small_code())
		2:
			world.set_water_param("debug_mode", _mask_debug)
			update_code(_big_code())
		3:
			world.set_water_param("foam_enabled", 1.0 if _foam else 0.0)


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "접촉선 폭 (edge_small)", 0.02, 0.6, _small, _on_small_changed, [1])
	add_slider(parent, "침식 폭 (edge_big)", 0.2, 4.0, _big, _on_big_changed, [2])
	add_toggle(parent, "bottom_mask 보기", false, _on_mask_toggled, [2])
	add_toggle(parent, "흰 포말", _foam, _on_foam_toggled, [3])


func _on_small_changed(value: float) -> void:
	_small = value
	world.set_water_param("edge_small", value)
	if current_step == 1:
		update_code(_small_code())


func _on_big_changed(value: float) -> void:
	_big = value
	world.set_water_param("edge_big", value)
	if current_step == 2:
		update_code(_big_code())


func _on_mask_toggled(pressed: bool) -> void:
	_mask_debug = 4 if pressed else 0
	if current_step == 2:
		world.set_water_param("debug_mode", _mask_debug)


func _on_foam_toggled(pressed: bool) -> void:
	_foam = pressed
	if current_step == 3:
		world.set_water_param("foam_enabled", 1.0 if pressed else 0.0)


func _small_code() -> String:
	return ("small_edge = smoothstep(z + %.2f,\n" % _small
			+ "    z, VERTEX.z); ← 슬라이더 (원본 0.1)")


func _big_code() -> String:
	return ("big_edge = smoothstep(z + %.2f, ...)\n" % _big
			+ "mask = (1.0-small) - voronoi*big_edge;")
