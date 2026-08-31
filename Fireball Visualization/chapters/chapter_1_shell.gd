extends FireballChapter
## 챕터 1 — 껍질. 원뿔 메시 한 장이 레이어 하나씩 불꽃이 되는 과정.
## UV.y 축 → sin 물결 → 보로노이 디졸브 → 그라디언트+림.

const STEPS: Array[Dictionary] = [
	{
		"title": "원뿔 메시 한 장에서 시작하기",
		"body": """불꽃 꼬리는 파티클이 아니라 [b]원뿔 메시 한 장[/b]이다.
파랑=머리(UV.y 0), 주황=꼬리 끝(UV.y 1).
셰이더의 모든 줄이 이 축 하나에 걸린다.""",
		"chips": [
			{"icon": "node3d", "text": "FireballShellMesh"},
			{"icon": "shader", "text": "fireball_shell.gdshader"},
		],
		"try": "드래그로 돌려 뚫린 꼬리 안쪽 보기",
	},
	{
		"title": "sin 파로 표면 출렁이게 하기",
		"body": """UV.y에서 TIME을 빼 물결이 꼬리 쪽으로 흐른다.
(1.0 - UV.y)를 곱해 [b]머리는 크게, 꼬리 끝은 0[/b].
법선 방향으로 밀어 표면이 숨쉬듯 출렁인다.""",
		"chips": [{"icon": "shader", "text": "fireball_shell vertex()"}],
		"try": "진폭을 0으로 → 뻣뻣한 고깔이 된다",
	},
	{
		"title": "보로노이로 꼬리 뜯어내기",
		"body": """노이즈에서 UV.y를 빼 [b]꼬리 끝일수록 쉽게 잘린다[/b].
무늬 UV에 TIME이 걸려 경계가 계속 흐른다.
알파를 0/1로 잘라 반투명 정렬 문제도 피했다.""",
		"chips": [
			{"icon": "texture", "text": "NoiseTexture2D (Cellular)"},
			{"icon": "shader", "text": "ALPHA_SCISSOR"},
		],
		"try": "오프셋을 올리면 → 꼬리가 짧게 뜯긴다",
	},
	{
		"title": "그라디언트 색과 프레넬 림 입히기",
		"body": """색은 UV.y로 그라디언트를 읽되
[b]좌표에 노이즈를 곱해[/b] 색 얼룩을 공짜로 얻는다.
림은 프레넬을 step으로 잘라 가장자리만 태운다.""",
		"chips": [{"icon": "texture", "text": "GradientTexture1D"}],
		"code": """gradient = texture(colors, vec2(UV.y, 0.)
    * (voronoi * 0.4 + 0.6)).rgb;""",
		"try": "림 토글을 꺼 → 가장자리 불이 꺼진다",
	},
]

var _wave := 0.1
var _cut := -0.15
var _show_voronoi := false
var _rim_on := true


func _ready() -> void:
	world.set_autofire(false)
	world.set_target_visible(false)
	world.set_stationary_visible(true)
	world.set_stationary_inertia(false)
	world.set_core_visible(false)
	world.set_trail_emitting(false)
	world.set_smoke_emitting(false)
	world.camera_rig.position = Vector3(0.0, 1.5, 0.0)
	world.camera_rig.set_view(0.9, -0.2, 2.4)


func get_chapter_title() -> String:
	return "껍질 — 원뿔 한 장이 불꽃이 되기까지"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.reset_shell_params()
	match index:
		0:
			world.set_shell_param("debug_mode", 2)
			world.set_shell_param("wave_amplitude", 0.0)
			world.set_shell_param("cut_enabled", 0.0)
		1:
			world.set_shell_param("use_gradient", 0.0)
			world.set_shell_param("rim_enabled", 0.0)
			world.set_shell_param("cut_enabled", 0.0)
			world.set_shell_param("wave_amplitude", _wave)
			update_code(_wave_code())
		2:
			world.set_shell_param("use_gradient", 0.0)
			world.set_shell_param("rim_enabled", 0.0)
			world.set_shell_param("wave_amplitude", _wave)
			world.set_shell_param("cut_offset", _cut)
			world.set_shell_param("debug_mode", 1 if _show_voronoi else 0)
			update_code(_cut_code())
		_:
			world.set_shell_param("wave_amplitude", _wave)
			world.set_shell_param("cut_offset", _cut)
			world.set_shell_param("rim_enabled", 1.0 if _rim_on else 0.0)


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "물결 진폭", 0.0, 0.3, _wave, _on_wave_changed, [1, 2, 3])
	add_slider(parent, "디졸브 오프셋", -0.5, 0.5, _cut, _on_cut_changed, [2, 3])
	add_toggle(parent, "보로노이 무늬 보기", _show_voronoi, _on_voronoi_toggled, [2])
	add_toggle(parent, "프레넬 림", _rim_on, _on_rim_toggled, [3])


func _on_wave_changed(value: float) -> void:
	_wave = value
	world.set_shell_param("wave_amplitude", value)
	if current_step == 1:
		update_code(_wave_code())


func _on_cut_changed(value: float) -> void:
	_cut = value
	world.set_shell_param("cut_offset", value)
	if current_step == 2:
		update_code(_cut_code())


func _on_voronoi_toggled(pressed: bool) -> void:
	_show_voronoi = pressed
	if current_step == 2:
		world.set_shell_param("debug_mode", 1 if pressed else 0)


func _on_rim_toggled(pressed: bool) -> void:
	_rim_on = pressed
	if current_step == 3:
		world.set_shell_param("rim_enabled", 1.0 if pressed else 0.0)


func _wave_code() -> String:
	return ("VERTEX += sin((UV.y - TIME*4.0)*PI*3.0)\n"
			+ "  * NORMAL * (1.0-UV.y) * %.2f; ← 슬라이더" % _wave)


func _cut_code() -> String:
	return ("ALPHA *= step(%.2f,  // ← 슬라이더\n" % _cut
			+ "    voronoi - UV.y);\nALPHA_SCISSOR_THRESHOLD = 0.5;")
