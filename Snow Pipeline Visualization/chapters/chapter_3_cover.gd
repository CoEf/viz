extends SnowChapter
## 챕터 3 — 눈 쌓임. snow_cover 셰이더의 중간 계산을 디버그 색으로 하나씩
## 보여주고, 문턱값 수식은 슬라이더와 연동해 실시간 숫자로 보여준다.

const STEPS: Array[Dictionary] = [
	{
		"title": "위를 보는 면 찾기",
		"body": """눈은 위에서 내리니 위를 보는 면에만 쌓아야 한다.
법선의 y가 그 '위를 보는 정도'다.
[b]흰 = 위[/b], [b]파랑 = 옆·아래[/b].""",
		"chips": [{"icon": "shader", "text": "snow_cover.gdshader"}],
		"code": """world_normal = normalize(
    MODEL_NORMAL_MATRIX * NORMAL);
float up = world_normal.y;  // 1=위 0=옆""",
		"try": "상자 윗면과 옆면 비교",
	},
	{
		"title": "노이즈로 눈 경계 우둘투둘하게 하기",
		"body": """면 방향만으로 자르면 경계가 자로 잰 듯 반듯하다.
굵은 무늬 위에 [b]3.7배 촘촘한 무늬[/b]를
절반 세기로 겹쳐 거칠기를 만든다.""",
		"chips": [{"icon": "shader", "text": "snow_cover.gdshader"}],
		"code": """noise = value_noise(pos * scale)
    + value_noise(pos * scale * 3.7) * 0.5;""",
		"try": "노이즈 스케일 슬라이더로 무늬 크기 변경",
	},
	{
		"title": "문턱값으로 눈 쌓일 곳 정하기",
		"body": """면 방향 + 노이즈가 [b]문턱값[/b]을 넘으면 눈(흰색).
눈 쌓임 슬라이더는 이 문턱값을 내린다.""",
		"chips": [
			{"icon": "shader", "text": "snow_cover.gdshader"},
			{"icon": "setting", "text": "전역 snow_amount"},
		],
		"try": "슬라이더 끝까지 — 옆면까지 눈이 번진다",
	},
	{
		"title": "마스크로 색·거칠기·법선 바꾸기",
		"body": """마스크 하나가 세 가지를 한꺼번에 정한다.
상자·바위·나무가 [b]같은 셰이더[/b]를 색만 바꿔 쓴다.""",
		"chips": [{"icon": "shader", "text": "snow_cover.gdshader"}],
		"code": """ALBEDO = mix(base_color, snow_color, mask);
ROUGHNESS = mix(base_rough, snow_rough, mask);
NORMAL = mix(NORMAL, up_view, mask * 0.45);""",
	},
]

var _cover_value := 0.7


func _ready() -> void:
	world.set_fall_ratio(0.4)
	world.set_track_maker_enabled(false)
	# 디버그 색을 또렷하게 읽을 수 있도록 이 챕터에서는 안개를 끈다.
	world.environment().fog_enabled = false
	world.camera_rig.position = Vector3(16.2, 1.2, 0.0)
	world.camera_rig.set_view(1.2, -0.3, 6.0)


func get_chapter_title() -> String:
	return "눈 쌓이기"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	match index:
		0:
			world.set_cover_debug(1)
		1:
			world.set_cover_debug(2)
		2:
			world.set_cover_debug(3)
			update_code(_threshold_code())
		_:
			world.set_cover_debug(0)


func build_panel(parent: VBoxContainer) -> void:
	# 디버그 색이 중간 계산을 대신 보여 주는 스텝에서는, 그 계산에 실제로
	# 들어가는 값만 남긴다. 스텝 0(면 방향)에는 둘 다 끼어들 자리가 없다.
	add_slider(parent, "눈 쌓임 (문턱값)", 0.0, 1.0, 0.7, _on_cover_changed, [2, 3])
	add_slider(parent, "노이즈 스케일", 0.5, 6.0, 2.5, _on_noise_scale_changed, [1, 2, 3])


func _on_cover_changed(value: float) -> void:
	_cover_value = value
	WinterWorld.set_global_cover(value)
	if current_step == 2:
		update_code(_threshold_code())


func _on_noise_scale_changed(value: float) -> void:
	for material: ShaderMaterial in world.cover_materials():
		material.set_shader_parameter("edge_noise_scale", value)


func _threshold_code() -> String:
	return ("threshold = mix(1.3, 0.1, snow_amount);\n"
			+ "// 지금 threshold = %.2f ← 슬라이더\n" % lerpf(1.3, 0.1, _cover_value)
			+ "snow_mask = smoothstep(threshold,\n"
			+ "    threshold + 0.3, up + noise);")
