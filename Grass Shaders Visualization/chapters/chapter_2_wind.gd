extends GrassChapter
## 챕터 2 — 바람 축. 흔드는 방법과, MultiMesh에서 위상이 뭉치는 함정.

const STEPS: Array[Dictionary] = [
	{
		"title": "정점을 사인파로 밀기",
		"body": """가장 흔한 방식이다. 잎 끝으로 갈수록
[b]UV.y로 가중치를 줘[/b] 뿌리는 고정하고 끝만 흔든다.
9번은 사인 2개가 전부다 — uniform조차 없다.""",
		"chips": [{"icon": "shader", "text": "pixel_wind_sway.gdshader"}],
		"code": """VERTEX.x += sin(TIME + offset)
    * UV.y * strength;""",
		"try": "T 대신 시간이 흐르는 걸 그냥 보기",
	},
	{
		"title": "위상을 흩어 한 덩어리를 피하기",
		"body": """전부 같은 위상이면 들판이 [b]통째로[/b] 흔들린다.
잎마다 다른 값을 더해 시차를 줘야 한다.
2번과 9번이 같은 해법을 쓴다 — 노드의 월드 위치.""",
		"chips": [{"icon": "shader", "text": "NODE_POSITION_WORLD"}],
		"code": """float phase = NODE_POSITION_WORLD.x
            + NODE_POSITION_WORLD.z;""",
		"try": "왼쪽(2번)과 오른쪽(9번)의 흔들림을 비교",
	},
	{
		"title": "MultiMesh에서 위상이 뭉치는 이유",
		"body": """`NODE_POSITION_WORLD`는 [b]노드 단위[/b] 값이다.
MultiMesh는 노드가 하나라 3,000장이 같은 값을 읽는다.
왼쪽(2번)이 한 덩어리로 흔들리는 게 그 결과다.

9번은 잎마다 노드를 따로 둬서 이걸 피했다 —
잎이 300장뿐인 진짜 이유다.""",
		"chips": [
			{"icon": "shader", "text": "NODE_POSITION_WORLD"},
			{"icon": "node3d", "text": "MultiMeshInstance3D"},
		],
		"try": "왼쪽은 통짜, 오른쪽은 잎마다 따로 흔들린다",
	},
	{
		"title": "바람으로 광택까지 바꾸기",
		"body": """5번만 잔디를 [b]제대로 라이팅[/b]한다.
바람이 정점만 미는 게 아니라 거칠기를 변조해서,
움직임의 상당 부분이 기하가 아니라 [b]광택[/b]이다.""",
		"chips": [{"icon": "shader", "text": "grass_kiwio.gdshader"}],
		"try": "아래 토글로 거칠기 변조를 꺼보기",
	},
]

var _toggle_on := true


func get_chapter_title() -> String:
	return "바람 — 무엇을 흔드는가"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	match index:
		0:
			world.show_patches([9])
		3:
			world.show_patches([5])
			world.set_toggle(5, _toggle_on)
			update_code(_toggle_code(5))
		_:
			world.show_patches([2, 9])
	world.camera_rig.position = Vector3(0.0, 1.4, 0.0)
	world.camera_rig.set_view(0.0, -0.24, 22.0 if index in [1, 2] else 13.0)


func build_panel(parent: VBoxContainer) -> void:
	add_toggle(parent, "5번 셰이더의 거칠기 변조", true, _on_toggled, [3])
	add_caption(parent, "바람이 잎을 눕힐 때 광택까지 같이 흔들지 말지", [3])


func _on_toggled(on: bool) -> void:
	_toggle_on = on
	if current_step == 3:
		world.set_toggle(5, on)
		update_code(_toggle_code(5))


func _toggle_code(number: int) -> String:
	var entry: Dictionary = world.entry_of(number)
	return ("%s = %s\n" % [entry["toggle"]["uniform"], str(entry["toggle"]["values"][0 if _toggle_on else 1])]
			+ "// %s" % world.toggle_label(number, _toggle_on))
