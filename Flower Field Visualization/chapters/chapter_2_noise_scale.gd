extends FieldChapter
## 챕터 2 — 노이즈로 크기 뭉치기. 개체별 난수는 소금후추,
## 노이즈는 무성한 곳과 성긴 곳을 만든다.

const STEPS: Array[Dictionary] = [
	{
		"title": "크기는 난수가 아니라 노이즈로",
		"body": """FastNoiseLite를 좌표로 샘플링해 0.5~1.5 배율.
[b]근처끼리 비슷해야[/b] 무성한 곳과 성긴 곳이 생긴다.
개체별 randf면 소금후추처럼 흩어진다.""",
		"chips": [{"icon": "resource", "text": "FastNoiseLite"}],
		"code": """n = noise.get_noise_2d(x*40, y*40)
scale = remap(n, -1, 1, 0.5, 1.5)""",
		"try": "randf로 바꾸면 → 군집이 사라진다",
	},
	{
		"title": "인스턴스 컬러는 난수 통로",
		"body": """MultiMesh는 개체별 uniform이 없다 —
[b]컬러 채널이 유일한 창구[/b]다. R에 난수 하나.
셰이더가 그걸 회전각과 색상 좌표로 나눠 쓴다.""",
		"chips": [{"icon": "script", "text": "set_instance_color(Color(randf(),0,0))"}],
		"code": """multimesh.set_instance_color(i,
    Color(randf(), 0.0, 0.0))
# g/b 채널은 비어 있다""",
	},
]

var _use_noise := true


func _ready() -> void:
	world.set_butterflies_visible(false)


func get_chapter_title() -> String:
	return "노이즈 크기 — 군집의 비밀"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	if index == 0:
		world.regenerate(0.5, 0.5, 0.96, _use_noise)
	else:
		world.regenerate(0.5, 0.5, 0.96, true)


func build_panel(parent: VBoxContainer) -> void:
	add_toggle(parent, "노이즈 크기 (끄면 개체별 randf)", _use_noise, _on_noise_toggled, [0])


func _on_noise_toggled(pressed: bool) -> void:
	_use_noise = pressed
	if current_step == 0:
		world.regenerate(0.5, 0.5, 0.96, pressed)
