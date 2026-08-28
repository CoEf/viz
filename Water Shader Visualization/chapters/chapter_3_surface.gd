extends WaterChapter
## 챕터 3 — L3 Refraction + L7 Fresnel. 표면 경계에서 일어나는 두 가지:
## 통과해서 보이는 것과 튕겨서 비치는 것, 그리고 그 배분.

const STEPS: Array[Dictionary] = [
	{
		"title": "뒤 화면을 그대로 가져오기",
		"body": """물은 자기 색을 그리지 않는다.
[b]이미 그려진 화면[/b]을 훔쳐다 쓴다.
지금은 오프셋 없이 그대로 가져와 유리처럼 보인다.""",
		"chips": [{"icon": "shader", "text": "hint_screen_texture"}],
		"code": """uniform sampler2D screen_texture
    : hint_screen_texture;""",
		"try": "기둥이 물속에서 곧게 서 있다",
	},
	{
		"title": "법선만큼 훔칠 위치 밀기",
		"body": """가져올 화면 좌표를 [b]법선 방향으로 밀면[/b] 굴절이 된다.
바닥이 파도를 따라 일렁인다.""",
		"chips": [{"icon": "shader", "text": "refraction_strength"}],
		"code": """vec2 test_uv = SCREEN_UV
    + pert_n.xy * refraction_strength""",
		"try": "굴절 슬라이더를 0과 최대로 오가기",
	},
	{
		"title": "거리로 나눠 먼 물 안정시키기",
		"body": """오프셋을 그대로 쓰면 먼 수면이 미친 듯 일렁인다.
같은 픽셀 오프셋이 멀수록 [b]더 큰 실제 거리[/b]이기 때문.
카메라 거리로 나눠 준다.""",
		"chips": [{"icon": "shader", "text": "wt_surface_body"}],
		"code": """* min(thickness, refraction_max_depth)
/ max(water_d, 1.0);   // ← 이 나눗셈""",
		"try": "줌 아웃 → 먼 수면이 잠잠하다",
	},
	{
		"title": "물 앞 물체는 되돌리기",
		"body": """밀어낸 지점이 물보다 [b]앞[/b]이면
물가에 선 물체가 물속에 비쳐 보이는 버그가 난다.
깊이를 다시 재서 앞이면 원래 좌표로 되돌린다.""",
		"chips": [{"icon": "shader", "text": "hint_depth_texture"}],
		"code": """if (rscene_d >= water_d
    && wt_in_screen(test_uv)) { ruv = test_uv; }""",
		"try": "이 방어가 없으면 기둥이 물에 잠겨 보인다",
	},
	{
		"title": "Fresnel로 반사와 투과 나누기",
		"body": """비스듬히 볼수록 [b]반사가 강해진다.[/b]
수직으로 내려다보면 바닥이 보이고,
수평으로 보면 하늘색이 덮인다.""",
		"chips": [{"icon": "shader", "text": "wt_fresnel"}],
		"code": """float fres = wt_fresnel(
    pert_n, VIEW, fresnel_f0);""",
		"try": "카메라를 위/옆으로 옮겨 비교",
	},
	{
		"title": "Fresnel 값만 색으로 보기",
		"body": """흰 곳이 반사가 강한 곳이다.
[b]먼 수면일수록 하얗다[/b] — 시선이 눕기 때문.
파도의 경사면마다 값이 달라지는 것도 보인다.""",
		"chips": [{"icon": "shader", "text": "debug_view = 4"}],
		"try": "시점을 낮추면 화면 전체가 하얘진다",
	},
]

var _refraction := 0.6


func get_chapter_title() -> String:
	return "L3+L7 — 통과와 반사"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.reset_layers()
	world.set_foam(false)
	world.set_volume(false)
	world.set_fresnel(index >= 4)
	world.set_param(&"refraction_strength", 0.0 if index == 0 else _refraction)
	world.set_debug_view(4 if index == 5 else 0)
	if index == 2:
		world.camera_rig.set_view(2.95, -0.14, 60.0)
	elif index == 5:
		world.camera_rig.set_view(2.95, -0.52, 30.0)
	else:
		world.camera_rig.set_view(2.95, -0.40, 20.0)
	# 스텝 5는 화면이 Fresnel 값 그 자체다. 굴절 슬라이더가 패널에 없는 칸에서
	# "← 슬라이더" 주석이 달린 코드를 띄우면 없는 손잡이를 가리키게 된다.
	if index >= 1 and index <= 4:
		update_code(_refraction_code())


func build_panel(parent: VBoxContainer) -> void:
	# 스텝 5는 화면이 통째로 Fresnel 값(debug_view = 4)이라 굴절은 안 비친다.
	add_slider(parent, "굴절 세기 (refraction_strength)", 0.0, 3.0, 0.6, _on_refraction_changed, [1, 2, 3, 4])
	add_slider(parent, "Fresnel F0", 0.0, 0.2, 0.02, _on_fresnel_changed, [4, 5])


func _on_refraction_changed(value: float) -> void:
	_refraction = value
	if current_step >= 1:
		world.set_param(&"refraction_strength", value)
		update_code(_refraction_code())


func _on_fresnel_changed(value: float) -> void:
	world.set_param(&"fresnel_f0", value)


func _refraction_code() -> String:
	return ("refraction_strength = %.2f  // ← 슬라이더\n" % _refraction
			+ "ruv = SCREEN_UV + pert_n.xy * 세기;")
