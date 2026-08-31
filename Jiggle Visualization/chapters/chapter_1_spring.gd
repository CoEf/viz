extends JiggleChapter
## 챕터 1 — 스프링-댐퍼. 이 프로젝트의 모든 흔들림이 쓰는 단 하나의 식을
## 공 하나(→ 셋)로 눈에 익힌다. 그래프가 3D보다 선명할 때가 많은 챕터다.

const STEPS: Array[Dictionary] = [
	{
		"title": "목표를 쫓는 스프링 하나 만들기",
		"body": """공은 초록 목표를 [b]지연·오버슈트하며[/b] 쫓는다.
이 식 한 줄이 모든 챕터의 심장이다.
노랑 = 실제 위치 · 자홍 = 속도.""",
		"chips": [{"icon": "script", "text": "jiggle_spring.gd"}],
		"code": "a = k * (target - x) - c * v + g",
		"try": "임펄스 → 그래프에서 오버슈트(출렁임) 확인",
	},
	{
		"title": "감쇠비 하나로 성격 정하기",
		"body": """세 공은 같은 목표를 쫓고 [b]감쇠비 ζ만 다르다.[/b]
빨강 0.12 = 출렁 · 초록 1.0 = 즉시 안착 · 파랑 2.2 = 굼뜸.
그래프의 곡선 세 개가 그 차이의 전부다.""",
		"chips": [{"icon": "script", "text": "JiggleSpring.damping_ratio()"}],
		"code": "zeta = c / (2 * sqrt(k))",
		"try": "빨강 ζ를 1.0으로 → 빨간 공도 출렁임이 사라진다",
	},
	{
		"title": "적분 방식으로 안정성 가르기",
		"body": """같은 식도 이산화가 다르면 결과가 다르다.
명시적 오일러는 스텝마다 에너지가 늘어 [b]발산한다.[/b]
반암시적은 두 줄의 순서만 바꾼 것인데 안정적이다.""",
		"chips": [{"icon": "script", "text": "Integrator.EXPLICIT_EULER"}],
		"code": """# 명시적 오일러 — 위치를 옛 속도로
_x += _v * delta
_v += accel * delta""",
		"try": "'해석적 해'로 바꾸면 15Hz에서도 멀쩡하다",
	},
	{
		"title": "중력으로 평형점 내리기",
		"body": """중력은 [b]평형점을 g/k만큼 옮기는 것[/b]과 정확히 같다.
정지해도 공은 목표 아래에 떠 있다.
이 처짐(sag)이 자연스러움의 절반이다.""",
		"chips": [{"icon": "script", "text": "JiggleSpring.gravity"}],
		"code": """spring.gravity = Vector3.DOWN * 9.8
# 평형점 이동량 = g / k""",
		"try": "진동수를 낮추면(k↓) 공이 더 깊이 처진다",
	},
]

const INTEGRATOR_NAMES := "명시적 오일러 (발산),반암시적 (표준),해석적 해 (무조건 안정)"
const RATE_VALUES: Array[float] = [15.0, 30.0, 60.0, 120.0, 240.0]

@onready var world: SpringWorld = $World

var _plot: JigglePlot
var _zeta_slider: HSlider
var _integrator_option: OptionButton
var _rate_option: OptionButton
var _gravity_toggle: CheckButton


func get_chapter_title() -> String:
	return "스프링-댐퍼 — 흔들림의 원자"


func get_steps() -> Array[Dictionary]:
	return STEPS


func _ready() -> void:
	world.set_view(Vector3(0.0, 1.05, 0.0), 0.0, -0.05, 2.3)


func apply_step(index: int) -> void:
	# 스텝마다 상태를 처음부터 다 지정한다. 이전/다음 어느 쪽에서 와도 같아야 한다.
	# 발산 스텝(2)도 공 하나만 본다 — 셋이 겹쳐 터지면 울타리 구 세 개가 뒤엉킨다.
	world.solo = index == 0 or index == 2
	world.zeta_left = 0.12
	world.zeta_middle = 1.0
	world.zeta_right = 2.2
	world.integrator = (
		JiggleSpring.Integrator.EXPLICIT_EULER if index == 2
		else JiggleSpring.Integrator.SEMI_IMPLICIT
	)
	world.simulation_rate = 30.0 if index == 2 else 120.0
	world.gravity_enabled = index == 3
	# 발산 스텝만 울타리를 친다. 공이 화면 밖 무한대로 사라지면 아무것도 못 배운다.
	world.max_distance = 0.35 if index == 2 else 0.0
	world.apply()
	world.reset_world()
	world.kick(0.35)
	_sync_controls()
	if _plot != null:
		_plot.clear_samples()
	match index:
		0:
			update_code(_frequency_code())
		1:
			update_code(_zeta_code())


func build_panel(parent: VBoxContainer) -> void:
	_plot = add_plot(parent, [
		{"id": "left", "color": SpringWorld.COLORS[0]},
		{"id": "middle", "color": SpringWorld.COLORS[1]},
		{"id": "right", "color": SpringWorld.COLORS[2]},
	])
	add_button(parent, "임펄스 (툭 치기)", world.trigger_impulse)
	add_slider(parent, "진동수 (Hz)", 0.2, 8.0, 2.0, _on_frequency_changed)
	_zeta_slider = add_slider(parent, "감쇠비 ζ (빨강 공)", 0.02, 3.0, 0.12, _on_zeta_changed, [1])
	_integrator_option = add_option(
		parent, "적분 방식", INTEGRATOR_NAMES.split(","), 1, _on_integrator_selected, [2]
	)
	_rate_option = add_option(
		parent, "계산 주기", PackedStringArray(["15 Hz", "30 Hz", "60 Hz", "120 Hz", "240 Hz"]),
		3, _on_rate_selected, [2]
	)
	_gravity_toggle = add_toggle(parent, "중력 (9.8)", false, _on_gravity_toggled, [3])
	add_slowmo(parent)
	add_caption(parent, "기즈모: 초록 = 목표 · 노랑 = 실제 위치 · 자홍 = 속도 · 빨강 = 이탈 울타리")


func _process(_delta: float) -> void:
	if _plot != null and _plot.visible:
		_plot.info_text = "목표 대비 상하 변위  |  f %.1f Hz" % world.frequency
		_plot.push_frame(world.sample_plot())


func _sync_controls() -> void:
	_zeta_slider.set_value_no_signal(world.zeta_left)
	_integrator_option.select(int(world.integrator))
	_rate_option.select(RATE_VALUES.find(world.simulation_rate))
	_gravity_toggle.set_pressed_no_signal(world.gravity_enabled)


func _on_frequency_changed(value: float) -> void:
	world.frequency = value
	world.apply()
	if current_step == 0:
		update_code(_frequency_code())


func _on_zeta_changed(value: float) -> void:
	world.zeta_left = value
	world.apply()
	if current_step == 1:
		update_code(_zeta_code())


func _on_integrator_selected(index: int) -> void:
	world.integrator = index as JiggleSpring.Integrator
	world.apply()
	world.reset_world()
	world.kick(0.35)


func _on_rate_selected(index: int) -> void:
	world.simulation_rate = RATE_VALUES[index]
	world.apply()
	world.reset_world()
	world.kick(0.35)


func _on_gravity_toggled(pressed: bool) -> void:
	world.gravity_enabled = pressed
	world.apply()


func _frequency_code() -> String:
	return (
		"a = k * (target - x) - c * v\n"
		+ "spring.configure(frequency, zeta)\n"
		+ "# f = %.2f Hz ← 슬라이더\n" % world.frequency
		+ "# k = (2π·f)² = %.0f" % world.spring_k()
	)


func _zeta_code() -> String:
	return (
		"zeta = c / (2 * sqrt(k))\n"
		+ "# 빨강 공 ζ = %.2f ← 슬라이더\n" % world.zeta_left
		+ ("# ζ < 1 부족감쇠 — 출렁인다" if world.zeta_left < 1.0
			else "# ζ ≥ 1 — 출렁이지 않는다")
	)
