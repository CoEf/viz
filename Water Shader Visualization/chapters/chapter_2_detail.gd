extends WaterChapter
## 챕터 2 — L2 Detail. 노멀맵 2장 스크롤과 거리 LOD 페이드.

const STEPS: Array[Dictionary] = [
	{
		"title": "큰 파도만 있는 상태 보기",
		"body": """L1만 켜면 표면이 유리처럼 매끈하다.
파도의 [b]윤곽[/b]은 있지만 잔물결이 없다.""",
		"chips": [{"icon": "shader", "text": "wt_waves.gdshaderinc"}],
		"try": "다음 스텝과 오가며 표면 질감 비교",
	},
	{
		"title": "노멀맵 2장을 다른 속도로 흘리기",
		"body": """정점을 더 쪼개는 대신 [b]법선만 흔든다.[/b]
같은 노멀맵을 스케일이 다른 2장으로 겹쳐 흘린다.
스케일이 정수배면 무늬가 겹쳐 격자가 보인다.""",
		"chips": [
			{"icon": "texture", "text": "NoiseTexture2D (as_normal_map)"},
			{"icon": "shader", "text": "detail_scale"},
		],
		"code": """uniform vec2 detail_scale
    = vec2(0.055, 0.023);  // 정수배 금지""",
		"try": "세기 슬라이더를 0과 최대로 오가기",
	},
	{
		"title": "법선이 어떻게 흔들리는지 보기",
		"body": """L1 파도의 법선 위에 L2 잔물결이 얹혔다.
챕터 1의 매끈한 법선과 비교해 보면
[b]같은 파도에 미세 요철[/b]이 생긴 게 보인다.
기울기는 3배 과장해 그렸다.""",
		"chips": [{"icon": "shader", "text": "debug_view = 1"}],
		"try": "세기를 0으로 → 챕터 1의 매끈한 법선으로 돌아감",
	},
	{
		"title": "멀수록 디테일 걷어내기",
		"body": """고주파 법선을 원거리까지 그리면 수평선이 지글거린다.
카메라 거리로 [b]45m부터 190m까지 서서히 지운다.[/b]
밉맵도 강제로 올려 샘플링 노이즈를 죽인다.""",
		"chips": [{"icon": "shader", "text": "detail_fade_start / _end"}],
		"code": """float detail_fade = 1.0 - smoothstep(
    detail_fade_start, detail_fade_end, cam_dist);""",
		"try": "줌 아웃 → 먼 수면이 매끈해진다",
	},
]

var _strength := 1.1


func get_chapter_title() -> String:
	return "L2 — 잔물결 얹기"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.reset_layers()
	world.set_foam(false)
	world.set_fresnel(false)
	world.set_refraction(false)
	world.set_volume(false)
	world.set_param(&"detail_strength", 0.0 if index == 0 else _strength)
	world.set_debug_view(1 if index == 2 else 0)
	if index == 3:
		world.camera_rig.set_view(2.95, -0.16, 70.0)
	else:
		world.camera_rig.set_view(2.95, -0.38, 16.0)
	if index >= 1:
		update_code(_strength_code())


func build_panel(parent: VBoxContainer) -> void:
	# 스텝 0은 잔물결 세기가 0인 "큰 파도만" 상태 — 흐르는 속도도 보일 게 없다.
	add_slider(parent, "잔물결 세기 (detail_strength)", 0.0, 4.0, 1.1, _on_strength_changed, [1, 2, 3])
	add_slider(parent, "흐르는 속도", 0.0, 0.5, 0.06, _on_speed_changed, [1, 2, 3])


func _on_strength_changed(value: float) -> void:
	_strength = value
	if current_step >= 1:
		world.set_param(&"detail_strength", value)
		update_code(_strength_code())


func _on_speed_changed(value: float) -> void:
	world.set_param(&"detail_speed", value)


func _strength_code() -> String:
	return ("detail_strength = %.2f   // ← 슬라이더\n" % _strength
			+ "nm = 노멀맵 2장 blend;")
