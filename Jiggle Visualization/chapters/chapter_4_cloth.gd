extends JiggleChapter
## 챕터 4 — 천 Verlet (치마/커튼). 사슬과 완전히 같은 솔버에
## 제약만 격자 세 종류(구조·전단·굽힘)로 늘어난다.

const STEPS: Array[Dictionary] = [
	{
		"title": "격자를 거리 제약으로 엮기",
		"body": """사슬과 [b]완전히 같은 솔버[/b]다.
가로세로 이웃을 잇는 구조 제약이 늘어남을 막는다.
흰 선 = 구조 · 파랑 = 전단 · 주황 = 굽힘.""",
		"chips": [
			{"icon": "script", "text": "JiggleVerletCloth"},
			{"icon": "script", "text": "JiggleVerletBody"},
		],
		"code": "_solve_pairs(_structural, rest, 1.0)",
		"try": "바람이 밀면 격자 전체가 출렁인다",
	},
	{
		"title": "대각선을 이어 마름모 무너짐 막기",
		"body": """모서리만 고정하면 정사각형이 [b]마름모로 주저앉는다.[/b]
대각선 제약(전단)이 그걸 붙든다.
셋 다 똑같은 거리 제약 — 누굴 잇느냐만 다르다.""",
		"chips": [{"icon": "script", "text": "shear_pairs"}],
		"code": """_add_pair(shear, here, nb( 1, 1))
_add_pair(shear, here, nb( 1,-1))""",
		"try": "전단을 꺼 보라 — 마름모로 무너진다. 켜면 복구",
	},
	{
		"title": "한 칸 건너 이어 접힘 완만하게",
		"body": """이웃만 이으면 종이처럼 [b]날카롭게 접힌다.[/b]
한 칸 건너뛴 입자를 이으면 굽힘에 저항해
두꺼운 천처럼 완만해진다.""",
		"chips": [{"icon": "script", "text": "bend_pairs"}],
		"code": """_add_pair(bend, here, nb(0, 2))
_add_pair(bend, here, nb(2, 0))""",
		"try": "굽힘을 끄면 접힌 자국이 칼처럼 선다",
	},
	{
		"title": "법선에 비례해 바람 먹이기",
		"body": """정면으로 맞는 면일수록 세게 민다.
면이 돌아가면 덜 맞고, 그래서 되돌아온다 —
이 되먹임이 곧 [b]펄럭임[/b]이다.""",
		"chips": [{"icon": "script", "text": "apply_wind()"}],
		"code": "accel = dir * (str * abs(n.dot(dir)))",
		"try": "바람을 30까지 → 깃발처럼 펄럭인다",
	},
	{
		"title": "본 없이 매 프레임 메쉬 굽기",
		"body": """천은 스키닝이 없다 — [b]파티클 위치가 곧 정점.[/b]
매 프레임 ArrayMesh 를 다시 굽는다.
걷는 다리 충돌체가 치마를 안쪽에서 밀어낸다.""",
		"chips": [
			{"icon": "resource", "text": "ArrayMesh"},
			{"icon": "node3d", "text": "MeshInstance3D"},
		],
		"code": """mesh.clear_surfaces()
add_surface_from_arrays(TRIANGLES, arrays)""",
		"try": "빨간 입자 = 지금 다리에 닿아 있는 곳",
	},
]

@onready var world: ClothWorld = $World

var _wind_slider: HSlider
var _shear_toggle: CheckButton
var _bend_toggle: CheckButton
var _constraint_toggle: CheckButton


func get_chapter_title() -> String:
	return "천 — 사슬을 격자로"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.shape = ClothWorld.Shape.SKIRT if index == 4 else ClothWorld.Shape.CURTAIN
	world.pin_mode = ClothWorld.PinMode.CORNERS if index == 1 else ClothWorld.PinMode.TOP_ROW
	world.shear_enabled = true
	world.bend_enabled = true
	world.collision_enabled = true
	world.leg_swing = 0.45
	match index:
		0:
			world.wind = 6.0
		1:
			world.wind = 4.0
		2:
			world.wind = 14.0
		3:
			world.wind = 18.0
		_:
			world.wind = 0.0
	world.show_constraints = index <= 2
	world.show_particles = index == 4
	world.show_colliders = index == 4
	world.set_stimulus(Stimulus.Kind.WALK if index == 4 else Stimulus.Kind.IDLE)
	world.apply()
	world.reset_world()
	world.kick(0.6)
	_sync_controls()
	if index == 4:
		world.set_view(Vector3(0.0, 0.80, 0.0), 0.45, -0.12, 1.6)
	else:
		world.set_view(Vector3(0.0, 0.85, 0.0), 0.3, -0.05, 1.75)
	if index == 3:
		update_code(_wind_code())


func build_panel(parent: VBoxContainer) -> void:
	_wind_slider = add_slider(parent, "바람 세기", 0.0, 30.0, 6.0, _on_wind_changed, [0, 1, 2, 3])
	_shear_toggle = add_toggle(parent, "전단 제약 (대각선)", true, _on_shear_toggled, [1])
	_bend_toggle = add_toggle(parent, "굽힘 제약 (한 칸 건너)", true, _on_bend_toggled, [2])
	_constraint_toggle = add_toggle(parent, "제약 표시", true, _on_constraints_toggled, [0, 1, 2])
	add_slider(parent, "다리 스윙", 0.0, 1.0, 0.45, _on_leg_changed, [4])
	add_button(parent, "임펄스 (툭 치기)", world.trigger_impulse, [4])
	add_slowmo(parent)
	add_caption(parent, "제약 색: 흰 = 구조 · 파랑 = 전단 · 주황 = 굽힘", [0, 1, 2])
	add_caption(parent, "노랑 = 파티클 · 초록 = 고정점 · 빨강 = 다리에 닿은 입자 · 파랑 = 충돌체", [4])


func _sync_controls() -> void:
	_wind_slider.set_value_no_signal(world.wind)
	_shear_toggle.set_pressed_no_signal(world.shear_enabled)
	_bend_toggle.set_pressed_no_signal(world.bend_enabled)
	_constraint_toggle.set_pressed_no_signal(world.show_constraints)


func _on_wind_changed(value: float) -> void:
	world.wind = value
	if current_step == 3:
		update_code(_wind_code())


func _on_shear_toggled(pressed: bool) -> void:
	world.shear_enabled = pressed
	world.apply()


func _on_bend_toggled(pressed: bool) -> void:
	world.bend_enabled = pressed
	world.apply()


func _on_constraints_toggled(pressed: bool) -> void:
	world.show_constraints = pressed


func _on_leg_changed(value: float) -> void:
	world.leg_swing = value


func _wind_code() -> String:
	return (
		"accel = dir * (str * abs(n.dot(dir)))\n"
		+ "# wind = %.0f ← 슬라이더\n" % world.wind
		+ "# 법선 항이 없으면 밀리기만 하고\n"
		+ "# 펄럭이지 않는다"
	)
