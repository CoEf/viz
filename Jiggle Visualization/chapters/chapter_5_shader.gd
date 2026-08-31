extends JiggleChapter
## 챕터 5 — 본 없이 셰이더로 흔들기. 왼쪽 = 챕터 2의 본 기반,
## 오른쪽 = 스킨을 뗀 몸을 정점 셰이더가 화면에서만 민다.

const STEPS: Array[Dictionary] = [
	{
		"title": "정점 색 알파에 가중치 싣기",
		"body": """본 없이 흔들려면 '어디를 얼마나'를 메쉬에 실어야 한다.
[b]정점 색 알파[/b]가 가장 싸다.
빨간 부위 = 가중치 1 — 셰이더가 읽는 값 그대로다.""",
		"chips": [
			{"icon": "shader", "text": "vertex()"},
			{"icon": "script", "text": "proc_skin.gd"},
		],
		"code": "float weight = COLOR.a;",
		"try": "왼쪽(본 기반)도 같은 가중치를 스키닝에 쓴다",
	},
	{
		"title": "유니폼으로 오프셋 분배하기",
		"body": """CPU 스프링 [b]하나[/b]가 관성 오프셋을 만들고
셰이더가 가중치만큼 정점에 나눠 민다.
본 기반(왼쪽)과 수학이 완전히 같다.""",
		"chips": [
			{"icon": "script", "text": "JiggleSpring ×1"},
			{"icon": "shader", "text": "uniform jiggle_offset"},
		],
		"code": """vec3 offset = jiggle_offset * weight;
VERTEX += offset;""",
		"try": "세기를 0으로 → 오른쪽만 뚝 멈춘다",
	},
	{
		"title": "마커로 거짓말 들키기",
		"body": """둘 다 가슴 본에 붙은 마커다.
주황(왼쪽)은 따라 움직이고 [b]파랑(오른쪽)은 꿈쩍 않는다.[/b]
셰이더는 화면의 정점만 밀 뿐 씬은 그대로다.""",
		"chips": [{"icon": "node3d", "text": "BoneAttachment3D"}],
		"code": "attachment.bone_name = \"BreastL\"",
		"try": "그래프 — 파란 선은 영원히 0이다. 장신구·충돌 불가",
	},
	{
		"title": "시간만으로 공짜 출렁임 만들기",
		"body": """sin(TIME)에 정점 위상만 섞은 것.
상태가 없어 [b]사실상 공짜[/b]지만
몸이 뭘 하든 똑같이 출렁인다. 군중·배경용이다.""",
		"chips": [{"icon": "shader", "text": "wobble_amplitude"}],
		"code": """phase = VERTEX.x*9. + VERTEX.y*6.;
offset += sin(TIME*freq + phase) * amp;""",
		"try": "자극이 '정지'인데도 계속 출렁인다",
	},
]

@onready var world: ShaderWorld = $World

var _plot: JigglePlot
var _gain_slider: HSlider
var _wobble_slider: HSlider


func get_chapter_title() -> String:
	return "본 없이 셰이더로 흔들기"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.show_weights = index == 0
	world.show_markers = index >= 2
	world.uniform_gain = 0.0 if index == 3 else 1.0
	world.wobble_amplitude = 0.03 if index == 3 else 0.0
	world.apply()
	world.set_stimulus(Stimulus.Kind.IDLE if index == 3 else Stimulus.Kind.WALK)
	if index != 3:
		world.kick(0.5)
	_sync_controls()
	if _plot != null:
		_plot.clear_samples()
	if index == 2:
		# 마커 두 개가 주인공. 가슴 높이로 바짝 붙는다.
		world.set_view(Vector3(0.0, 1.22, 0.05), 0.0, -0.02, 1.0)
	else:
		world.set_view(Vector3(0.0, 1.05, 0.0), 0.25, -0.08, 2.1)
	if index == 1:
		update_code(_gain_code())
	elif index == 3:
		update_code(_wobble_code())


func build_panel(parent: VBoxContainer) -> void:
	_plot = add_plot(parent, [
		{"id": "bone", "color": Color(1.0, 0.62, 0.30)},
		{"id": "shader", "color": Color(0.45, 0.75, 1.0)},
	], [2, 3])
	add_button(parent, "임펄스 (툭 치기)", world.trigger_impulse, [1, 2])
	_gain_slider = add_slider(parent, "유니폼 구동 세기", 0.0, 3.0, 1.0, _on_gain_changed, [1, 2])
	_wobble_slider = add_slider(parent, "시간 기반 진폭", 0.0, 0.06, 0.0, _on_wobble_changed, [3])
	add_slowmo(parent, [1, 2, 3])
	add_caption(parent, "마커: 주황 = 본 기반(왼쪽) · 파랑 = 셰이더(오른쪽) · 초록 = rest 위치", [2, 3])


func _process(_delta: float) -> void:
	if _plot != null and _plot.visible:
		_plot.info_text = "마커가 rest에서 벗어난 거리 (m)"
		_plot.push_frame(world.sample_plot())


func _sync_controls() -> void:
	_gain_slider.set_value_no_signal(world.uniform_gain)
	_wobble_slider.set_value_no_signal(world.wobble_amplitude)


func _on_gain_changed(value: float) -> void:
	world.uniform_gain = value
	if current_step == 1:
		update_code(_gain_code())


func _on_wobble_changed(value: float) -> void:
	world.wobble_amplitude = value
	if current_step == 3:
		update_code(_wobble_code())


func _gain_code() -> String:
	return (
		"vec3 offset = jiggle_offset * weight;\n"
		+ "VERTEX += offset;\n"
		+ "// 세기 %.1f ← 슬라이더" % world.uniform_gain
	)


func _wobble_code() -> String:
	return (
		"phase = VERTEX.x*9. + VERTEX.y*6.;\n"
		+ "offset += sin(TIME*freq + phase) * amp;\n"
		+ "// amp = %.3f ← 슬라이더" % world.wobble_amplitude
	)
