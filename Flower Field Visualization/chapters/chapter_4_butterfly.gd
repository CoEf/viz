extends FieldChapter
## 챕터 4 — 나비. 중력을 끄고 turbulence만으로 날고,
## 날갯짓은 몸통을 고정한 cos 하나다.

const STEPS: Array[Dictionary] = [
	{
		"title": "중력 없이 난류로만 날기",
		"body": """gravity (0,0,0) — [b]turbulence가 유일한 동력[/b]이다.
initial_displacement 2~10으로 개체마다 노이즈 필드의
다른 지점에서 출발 — 작으면 떼 지어 몰려다닌다.
preprocess 5초 — 열자마자 이미 날고 있다.""",
		"chips": [{"icon": "resource", "text": "ParticleProcessMaterial turbulence"}],
		"code": """gravity = (0, 0, 0)
turbulence_initial_displacement
    = 2.0 ~ 10.0""",
		"try": "16마리가 제각각 다른 궤적을 그린다",
	},
	{
		"title": "몸통을 고정한 날갯짓",
		"body": """cos(|x| − t) − cos(t) — 빼는 항이
[b]몸통(x=0)의 변위를 항상 0으로[/b] 고정한다.
없으면 날개와 함께 몸이 떨린다.""",
		"chips": [{"icon": "shader", "text": "butterfly.gdshader"}],
		"try": "날갯짓 속도를 3으로 → 나른한 활공이 된다",
	},
	{
		"title": "버려진 커스텀 파티클",
		"body": """butterflies_process.gdshader — 노이즈에서 위치를
직접 읽는 결정적 궤적. [b]참조 0건[/b]으로 버려졌다.
최종안은 내장 turbulence — 두 접근을 다 시도한 흔적.""",
		"chips": [{"icon": "shader", "text": "butterflies_process.gdshader (미사용)"}],
		"code": """x = texture(noise, vec2(t, seed)).x
TRANSFORM[3].x = x * 4.0 # 물리 없음""",
	},
]

var _flap := 15.0


func _ready() -> void:
	world.regenerate(0.5, 0.5, 0.96, true)
	world.set_butterflies_visible(true)
	world.camera_rig.position = Vector3(0.0, 1.2, 0.0)
	world.camera_rig.set_view(0.5, -0.2, 6.0)


func get_chapter_title() -> String:
	return "나비 — 난류와 날갯짓"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.butterfly_material().set_shader_parameter("flap_speed", _flap if index == 1 else 15.0)


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "날갯짓 속도 (원본 15)", 1.0, 30.0, _flap, _on_flap_changed, [1])


func _on_flap_changed(value: float) -> void:
	_flap = value
	if current_step == 1:
		world.butterfly_material().set_shader_parameter("flap_speed", value)
