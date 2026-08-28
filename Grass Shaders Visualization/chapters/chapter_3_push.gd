extends GrassChapter
## 챕터 3 — 밀림 축. 캐릭터 위치를 셰이더에 알려주는 세 가지 방식.

const STEPS: Array[Dictionary] = [
	{
		"title": "아무것도 안 받고 깊이버퍼 읽기",
		"body": """1번은 캐릭터 위치를 [b]받지 않는다.[/b]
화면 깊이버퍼를 읽어 물체 앞의 UV를 밀어낸다.
그래서 물체가 몇 개든 공짜다 — 대신 [b]화면에 보이는 것만[/b].""",
		"chips": [{"icon": "shader", "text": "hint_depth_texture"}],
		"code": """uniform sampler2D DEPTH_TEXTURE
    : hint_depth_texture;""",
		"try": "공을 지나가게 두고 잔디가 갈라지는 것 보기",
	},
	{
		"title": "uniform으로 한 명만 알려주기",
		"body": """4번은 머티리얼에 좌표를 쓴다.
간단하지만 [b]머티리얼 하나에 대상 하나[/b]다.
두 명이 뛰어다니면 두 번째는 못 민다.""",
		"chips": [{"icon": "shader", "text": "uniform character_position"}],
		"code": """material.set_shader_parameter(
    "character_position", pos)""",
		"try": "넓고 부드러운 원형 밀림",
	},
	{
		"title": "instance uniform으로 패치마다 다르게",
		"body": """6번은 [b]노드[/b]에 좌표를 쓴다.
머티리얼 하나를 여러 패치가 공유하면서도
각자 다른 대상에 반응할 수 있다.""",
		"chips": [{"icon": "shader", "text": "instance uniform player_position"}],
		"code": """node.set_instance_shader_parameter(
    "player_position", pos)""",
		"try": "1·4·6번이 같은 공에 서로 다르게 반응한다",
	},
	{
		"title": "세로로도 감쇠시키기",
		"body": """6번만 [b]높이 차이[/b]까지 본다.
공이 잔디 위로 떠오르면 밀림이 약해진다.
점프로 넘어가면 안 눕는다는 뜻이다.""",
		"chips": [{"icon": "shader", "text": "grass_malido.gdshader"}],
		"try": "아래 토글로 6번의 가짜 AO를 꺼보기",
	},
]

var _toggle_on := true


func get_chapter_title() -> String:
	return "밀림 — 위치를 어떻게 아는가"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	match index:
		0:
			world.show_patches([1])
		1:
			world.show_patches([1, 4])
		2:
			world.show_patches([1, 4, 6])
		_:
			world.show_patches([6])
			world.set_toggle(6, _toggle_on)
			update_code(_toggle_code(6))
	# 공이 비교 대상 패치를 전부 지나야 "같은 공, 다른 반응"이 보인다.
	if index == 1:
		world.set_walker(Vector3.ZERO, 9.0)
	elif index == 2:
		world.set_walker(Vector3.ZERO, 15.0)
	else:
		world.set_walker(Vector3.ZERO, 2.4)
	world.camera_rig.position = Vector3(0.0, 1.4, 0.0)
	world.camera_rig.set_view(0.0, -0.34, [13.0, 26.0, 40.0, 13.0][index])


func build_panel(parent: VBoxContainer) -> void:
	add_toggle(parent, "6번 셰이더의 뿌리 그림자 (AO)", true, _on_toggled, [3])
	add_caption(parent, "공은 자동으로 공전한다")


func _on_toggled(on: bool) -> void:
	_toggle_on = on
	if current_step == 3:
		world.set_toggle(6, on)
		update_code(_toggle_code(6))


func _toggle_code(number: int) -> String:
	var entry: Dictionary = world.entry_of(number)
	return ("%s = %s\n" % [entry["toggle"]["uniform"], str(entry["toggle"]["values"][0 if _toggle_on else 1])]
			+ "// %s" % world.toggle_label(number, _toggle_on))
