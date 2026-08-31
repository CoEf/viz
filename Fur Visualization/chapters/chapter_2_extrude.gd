extends FurChapter
## 챕터 2 — 정점 밀어내기. 셸 퍼의 전부는 "노멀 방향 × 셸 깊이" 한 줄이고,
## 마스크 곱이 털 없는 부위를 지킨다.

const STEPS: Array[Dictionary] = [
	{
		"title": "노멀 방향으로 층층이 밀기",
		"body": """각 층을 노멀 방향으로 [b]COLOR.r에 비례해[/b] 밀어낸다.
15장이 서로 다른 거리만큼 부풀어
양파 껍질처럼 겹친다 — 셸 퍼의 전부.""",
		"chips": [{"icon": "shader", "text": "fur.gdshader vertex()"}],
		"try": "0으로 → 15겹이 피부에 딱 붙는다",
	},
	{
		"title": "마스크가 곱해지는 자리",
		"body": """샘플 좌표가 COLOR.r이 아니라 [b]R × G[/b]다.
마스크 G가 0인 얼굴·발바닥은 좌표가 0 —
그 부위에서는 15겹이 피부에 붙어 있다.""",
		"chips": [{"icon": "shader", "text": "COLOR.r * COLOR.g"}],
		"code": """VERTEX += NORMAL * texture(curve,
    vec2(COLOR.r * COLOR.g, 0)).z * len;""",
		"try": "G 마스크 보기(챕터1)와 대조해 보라",
	},
	{
		"title": "꺼져 있는 두 줄",
		"body": """_fur_deformation·_fur_gravity는 머티리얼에서 [b]둘 다 0[/b] —
실험하다 만 흔적이다. 켜 볼 수 있다.
중력은 모델 공간이라 캐릭터가 기울면 같이 기운다.""",
		"chips": [{"icon": "shader", "text": "_fur_deformation / _fur_gravity"}],
		"code": """VERTEX -= noise * COLOR.r * deform;
VERTEX.y -= COLOR.r * gravity;""",
		"try": "중력을 올리면 → 털이 아래로 처진다",
	},
]

var _length := 0.03
var _deform := 0.0
var _gravity := 0.0


func _ready() -> void:
	world.reset_fur_params()


func get_chapter_title() -> String:
	return "정점 밀어내기 — 양파가 되는 단계"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.reset_fur_params()
	match index:
		0:
			world.set_fur_param("_fur_length", _length)
			update_code(_length_code())
		2:
			world.set_fur_param("_fur_deformation", _deform)
			world.set_fur_param("_fur_gravity", _gravity)


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "_fur_length", 0.0, 0.12, _length, _on_length_changed, [0])
	add_slider(parent, "_fur_deformation", 0.0, 0.1, _deform, _on_deform_changed, [2])
	add_slider(parent, "_fur_gravity", 0.0, 0.1, _gravity, _on_gravity_changed, [2])


func _on_length_changed(value: float) -> void:
	_length = value
	world.set_fur_param("_fur_length", value)
	if current_step == 0:
		update_code(_length_code())


func _on_deform_changed(value: float) -> void:
	_deform = value
	world.set_fur_param("_fur_deformation", value)


func _on_gravity_changed(value: float) -> void:
	_gravity = value
	world.set_fur_param("_fur_gravity", value)


func _length_code() -> String:
	return ("VERTEX += NORMAL * curve(R*G).z\n"
			+ "    * %.3f; ← 슬라이더 (원본 0.03)" % _length)
