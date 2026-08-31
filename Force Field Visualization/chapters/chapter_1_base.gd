extends FFChapter
## 챕터 1 — 바탕. 프레넬이 모든 항에 곱해지고,
## 뎁스 교차선이 지면·물체와 닿는 곳을 빛나게 한다.

const STEPS: Array[Dictionary] = [
	{
		"title": "프레넬이 전체의 바탕이다",
		"body": """EMISSION도 ALPHA도 마지막에 [b]× f[/b] —
정면은 투명하고 실루엣만 남는 것이 포스필드의 뼈대.
다른 레이어를 전부 꺼도 이 껍질은 남는다.""",
		"chips": [{"icon": "shader", "text": "fresnel(1.0, NORMAL, VIEW)"}],
		"code": """EMISSION = base*2. + (...) * f;
ALPHA = clamp(..., 0., 1.) * f;""",
		"try": "드래그 — 실루엣 테두리가 시선을 따라온다",
	},
	{
		"title": "뎁스 교차선 — 닿는 곳이 빛난다",
		"body": """0.1 유닛 폭의 뎁스 비교 + fresnel(3) 합 —
[b]지면과 만나는 바닥 링[/b]이 밝아진다.
막대를 관통시키면 그 둘레에도 링이 생긴다.""",
		"chips": [{"icon": "shader", "text": "hint_depth_texture"}],
		"code": """edge = clamp(smoothstep(z+0.1, z, VERTEX.z)
    + fresnel(3.0, N, V), 0., 1.);""",
		"try": "막대 넣기 → 교차 둘레가 빛의 링이 된다",
	},
	{
		"title": "정점 물결",
		"body": """sin(UV.y + TIME)으로 표면을 [b]법선 방향 0.01[/b]만큼
출렁이게 한다. 에너지막이 숨쉬는 미세한 움직임.""",
		"chips": [{"icon": "shader", "text": "vertex()"}],
		"try": "진폭을 키우면 → 막이 크게 굽이친다",
	},
]

var _probe := false
var _wave := 0.01


func _ready() -> void:
	world.reset_params()


func get_chapter_title() -> String:
	return "바탕 — 프레넬과 뎁스"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.reset_params()
	world.set_probe_visible(false)
	match index:
		0:
			world.set_layers(true, false, false, false)
		1:
			world.set_layers(true, true, false, false)
			world.set_probe_visible(_probe)
		2:
			world.set_param("wave_amplitude", _wave)
			update_code(_wave_code())


func build_panel(parent: VBoxContainer) -> void:
	add_toggle(parent, "막대 관통", _probe, _on_probe_toggled, [1])
	add_slider(parent, "물결 진폭 (원본 0.01)", 0.0, 0.1, _wave, _on_wave_changed, [2])


func _on_probe_toggled(pressed: bool) -> void:
	_probe = pressed
	if current_step == 1:
		world.set_probe_visible(pressed)


func _on_wave_changed(value: float) -> void:
	_wave = value
	world.set_param("wave_amplitude", value)
	if current_step == 2:
		update_code(_wave_code())


func _wave_code() -> String:
	return "VERTEX += NORMAL * wave * %.3f;\n// ← 슬라이더" % _wave
