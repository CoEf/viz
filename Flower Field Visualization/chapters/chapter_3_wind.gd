extends FieldChapter
## 챕터 3 — 바람. 회전행렬 셰이더, 난수 하나의 이중 역할,
## 노멀 강제와 albedo AO, 그리고 동작하지 않는 위상 분산.

const STEPS: Array[Dictionary] = [
	{
		"title": "회전행렬로 흔들기",
		"body": """노이즈 두 샘플을 각도로 삼아 rotateX·rotateZ.
(1 − UV.y × waviness)를 곱해 [b]뿌리는 고정,
끝일수록 크게[/b] 흔들린다.""",
		"chips": [{"icon": "shader", "text": "waving_mesh.gdshader"}],
		"try": "세기를 키우면 → 폭풍의 풀밭이 된다",
	},
	{
		"title": "난수 하나가 회전과 색을",
		"body": """COLOR.x가 [b]두 곳에서[/b] 쓰인다 —
rotateY(COLOR.x·TAU)로 방향을, 그라디언트 좌표
UV.x + COLOR.x·0.49로 색을 흩뜨린다.""",
		"chips": [{"icon": "texture", "text": "flower_color.tres"}],
		"code": """VERTEX *= rotateX(n_x)
    * rotateY(COLOR.x * TAU)
    * rotateZ(n_y);""",
	},
	{
		"title": "노멀은 위로, 깊이는 albedo로",
		"body": """잎의 실제 노멀은 명암을 지저분하게 만든다 —
[b]전부 하늘을 보게 강제[/b]하고, 대신
mix(ALBEDO, ×0.15, UV.y)로 뿌리를 어둡게. 텍스처 AO다.""",
		"chips": [{"icon": "shader", "text": "NORMAL = vec3(0,1,0)"}],
		"code": """NORMAL = vec3(0.0, 1.0, 0.0);
ALBEDO = mix(ALBEDO, ALBEDO*.15, UV.y);""",
		"try": "위상 분산은 죽어 있다 — 밭 전체가 같이 흔들린다",
	},
]

var _intensity := 0.25
var _waviness := 1.0
var _speed := 0.025


func _ready() -> void:
	world.set_butterflies_visible(false)
	world.regenerate(0.5, 0.5, 0.96, true)
	world.camera_rig.position = Vector3(0.0, 0.5, 0.0)
	world.camera_rig.set_view(0.5, -0.2, 5.0)


func get_chapter_title() -> String:
	return "바람 — 회전행렬과 강제 노멀"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.reset_field_params()
	if index == 0:
		world.set_field_param("intensity", _intensity)
		world.set_field_param("waviness", _waviness)
		world.set_field_param("wind_speed", _speed)
		update_code(_wind_code())


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "intensity (세기)", 0.0, 1.2, _intensity, _on_intensity_changed, [0])
	add_slider(parent, "waviness (끝 쏠림)", 0.0, 1.0, _waviness, _on_waviness_changed, [0])
	add_slider(parent, "wind_speed", 0.0, 0.2, _speed, _on_speed_changed, [0])


func _on_intensity_changed(value: float) -> void:
	_intensity = value
	world.set_field_param("intensity", value)
	if current_step == 0:
		update_code(_wind_code())


func _on_waviness_changed(value: float) -> void:
	_waviness = value
	world.set_field_param("waviness", value)


func _on_speed_changed(value: float) -> void:
	_speed = value
	world.set_field_param("wind_speed", value)


func _wind_code() -> String:
	return ("n_x = (noise - .5) * (1. - UV.y * %.1f)\n" % _waviness
			+ "    * %.2f; ← 슬라이더" % _intensity)
