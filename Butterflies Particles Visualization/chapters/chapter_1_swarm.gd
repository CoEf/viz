extends BFChapter
## 챕터 1 — 1024마리. flower_field와 같은 난류 비행 설정의 대량 버전.

const STEPS: Array[Dictionary] = [
	{
		"title": "16마리에서 1024마리로",
		"body": """설정은 flower_field와 같다 — 중력 0, turbulence만.
initial_displacement 2~10이 개체를 노이즈 필드의
[b]다른 지점에서 출발[/b]시켜 떼 짓지 않게 한다.""",
		"chips": [{"icon": "resource", "text": "turbulence_initial_displacement"}],
		"try": "16마리로 줄이면 → flower_field의 그 나비들이다",
	},
	{
		"title": "preprocess 5초",
		"body": """수명 10초, preprocess 5초 —
씬을 열면 [b]이미 5초 날아다닌 상태[/b]로 시작한다.
없으면 한 점에서 우르르 퍼지는 게 보인다.""",
		"chips": [{"icon": "node3d", "text": "GPUParticles3D.preprocess"}],
		"code": """lifetime = 10.0
preprocess = 5.0""",
	},
	{
		"title": "날갯짓은 그대로 재사용",
		"body": """butterfly.gdshader 공유 — cos(|x|−t)−cos(t)로
[b]몸통을 고정한 날갯짓[/b]. anim_offset 난수가
1024마리의 위상을 전부 어긋나게 한다.""",
		"chips": [{"icon": "shader", "text": "butterfly.gdshader (공유)"}],
		"try": "날갯짓 속도를 낮추면 → 나른한 무리가 된다",
	},
]

var _amount := 1024.0
var _flap := 15.0


func get_chapter_title() -> String:
	return "1024마리 — 난류 비행의 확장"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.butterfly_material().set_shader_parameter("flap_speed", _flap if index == 2 else 15.0)
	if index == 0:
		world.set_butterfly_amount(int(_amount))
		update_code(_amount_code())
	else:
		world.set_butterfly_amount(1024)


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "amount", 16.0, 1024.0, _amount, _on_amount_changed, [0])
	add_slider(parent, "날갯짓 속도 (원본 15)", 1.0, 30.0, _flap, _on_flap_changed, [2])


func _on_amount_changed(value: float) -> void:
	_amount = roundf(value)
	world.set_butterfly_amount(int(_amount))
	if current_step == 0:
		update_code(_amount_code())


func _on_flap_changed(value: float) -> void:
	_flap = value
	if current_step == 2:
		world.butterfly_material().set_shader_parameter("flap_speed", value)


func _amount_code() -> String:
	return "amount = %.0f ← 슬라이더\n// flower_field는 16이었다" % _amount
