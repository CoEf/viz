extends WaterChapter
## 챕터 1 — L1 Shape. 평평한 판에서 시작해 Gerstner 파를 켜고,
## 파고와 법선을 디버그 뷰로 꺼내 본다.

const STEPS: Array[Dictionary] = [
	{
		"title": "평평한 판에서 시작하기",
		"body": """모든 레이어를 끄면 물은 그냥 판때기다.
가진 것은 [b]260m 평면 하나[/b]와 380×380 분할뿐.
분할이 촘촘해야 다음 스텝에서 파도가 매끄럽게 휜다.""",
		"chips": [{"icon": "resource", "text": "PlaneMesh"}],
		"code": """size = Vector2(260, 260)
subdivide_width = 380""",
		"try": "이 상태를 기억하기 — 다음 스텝과 비교",
	},
	{
		"title": "Gerstner 파 4개로 정점 밀기",
		"body": """사인파는 정점을 [b]위아래로만[/b] 민다.
Gerstner는 옆으로도 밀어 마루를 뾰족하게 만든다.
방향·가파름·파장이 다른 4개를 겹쳐 반복감을 지운다.""",
		"chips": [
			{"icon": "shader", "text": "wt_waves.gdshaderinc"},
			{"icon": "setting", "text": "world_vertex_coords"},
		],
		"code": """uniform vec4 wave_a =
    vec4(1.00, 0.30, 0.24, 34.0);
// 방향xy, 가파름, 파장""",
		"try": "아래 파고 슬라이더를 움직여 보기",
	},
	{
		"title": "파고만 색으로 꺼내 보기",
		"body": """정점을 얼마나 올렸는지를 밝기로 표시했다.
흰 줄이 마루, 검은 줄이 골이다.
[b]4개 파가 겹쳐 만든 무늬[/b]가 보인다.""",
		"chips": [{"icon": "shader", "text": "varying float v_height"}],
		"try": "파고 슬라이더 0 → 회색 균일해짐",
	},
	{
		"title": "법선을 수식으로 구하기",
		"body": """빛 계산에는 면이 향한 방향이 필요하다.
이웃 정점을 비교하지 않고 [b]Gerstner 식을 미분해[/b]
정확한 법선을 그 자리에서 얻는다.
지금 색이 그 법선이다 — 기울기를 [b]3배 과장[/b]했다.""",
		"chips": [{"icon": "shader", "text": "wt_waves.gdshaderinc"}],
		"try": "마루와 골에서 색이 어떻게 갈리는지 보기",
	},
]

var _amplitude := 0.85


func get_chapter_title() -> String:
	return "L1 — 파도 만들기"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.reset_layers()
	world.set_detail(false)
	world.set_foam(false)
	world.set_fresnel(false)
	world.set_refraction(false)
	world.set_volume(false)
	world.set_param(&"wave_amplitude", 0.0 if index == 0 else _amplitude)
	match index:
		2:
			world.set_debug_view(5)
		3:
			world.set_debug_view(1)
		_:
			world.set_debug_view(0)
	world.camera_rig.set_view(2.95, -0.34, 24.0)
	if index >= 1:
		update_code(_amplitude_code())


func build_panel(parent: VBoxContainer) -> void:
	# 스텝 0은 파고를 0으로 눌러 놓은 평평한 판이라 둘 다 손댈 게 없다.
	add_slider(parent, "파고 (wave_amplitude)", 0.0, 2.0, 0.85, _on_amplitude_changed, [1, 2, 3])
	add_slider(parent, "파도 속도", 0.0, 3.0, 1.0, _on_speed_changed, [1, 2, 3])


func _on_amplitude_changed(value: float) -> void:
	_amplitude = value
	if current_step >= 1:
		world.set_param(&"wave_amplitude", value)
		update_code(_amplitude_code())


func _on_speed_changed(value: float) -> void:
	world.set_param(&"wave_time_scale", value)


func _amplitude_code() -> String:
	return ("wave_amplitude = %.2f   // ← 슬라이더\n" % _amplitude
			+ "VERTEX += wt_gerstner_sum(...);")
