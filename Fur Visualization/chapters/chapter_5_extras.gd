extends FurChapter
## 챕터 5 — 곁가지. OneShot+본 필터 깜빡임, 텍스처 없는 격자,
## 그리고 뜯어보고 남은 것들.

const STEPS: Array[Dictionary] = [
	{
		"title": "깜빡임은 본 필터로 얹기",
		"body": """blink를 상태 전환 대신 [b]OneShot(ADD) + 본 필터[/b]로 —
눈꺼풀 본 16개에만 가산되어 걷기는 그대로 돈다.
간격은 매번 randf_range(1, 4)로 다시 뽑는다.""",
		"chips": [
			{"icon": "node3d", "text": "AnimationTree OneShot"},
			{"icon": "script", "text": "fur_preview.gd"},
		],
		"code": """blink_timer.start(randf_range(1., 4.))
tree.set("parameters/BlinkShot/request",
    true)""",
		"try": "지금 깜빡이기 → 걷기가 끊기지 않는다",
	},
	{
		"title": "텍스처 없는 격자 바닥",
		"body": """fract(UV × res)로 UV를 접고,
step(thickness)로 [b]각 칸의 가장자리만[/b] 남긴다.
TIME을 UV에 더하면 그대로 흐른다.""",
		"chips": [{"icon": "shader", "text": "ground_grid.gdshader"}],
		"code": """grid = fract(st * res);
step(t, grid.x) * step(t, grid.y)""",
		"try": "두께를 키우면 → 선이 굵어진다",
	},
	{
		"title": "뜯어보고 남은 것",
		"body": """셸 15장 = 드로우콜 15회, 전부 스키닝(정점 15배).
_ready마다 다시 굽는다 — [b]구운 메시를 .res로 저장[/b]이 정답.
Fur 노드의 transparency=1.0은 의도 불명의 값.""",
		"chips": [{"icon": "setting", "text": "resolution LOD"}],
		"code": """# 개선안: 한 번 굽고 저장
ResourceSaver.save(final_mesh,
    "res://fur_baked.res")""",
	},
]

var _res := 8.0
var _thickness := 0.03


func _ready() -> void:
	world.reset_fur_params()
	world.camera_rig.set_view(0.6, -0.35, 2.2)


func get_chapter_title() -> String:
	return "곁가지 — 깜빡임·격자·숙제"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.set_grid_param("grid_res", 8.0)
	world.set_grid_param("grid_thickness", 0.03)
	match index:
		0:
			world.blink_now()
		1:
			world.set_grid_param("grid_res", _res)
			world.set_grid_param("grid_thickness", _thickness)
			update_code(_grid_code())


func build_panel(parent: VBoxContainer) -> void:
	var blink := Button.new()
	blink.text = "지금 깜빡이기"
	blink.pressed.connect(func() -> void: world.blink_now())
	parent.add_child(blink)
	bind_steps([blink], [0])

	add_slider(parent, "격자 칸 수", 2.0, 24.0, _res, _on_res_changed, [1])
	add_slider(parent, "선 두께", 0.005, 0.2, _thickness, _on_thickness_changed, [1])


func _on_res_changed(value: float) -> void:
	_res = roundf(value)
	world.set_grid_param("grid_res", _res)
	if current_step == 1:
		update_code(_grid_code())


func _on_thickness_changed(value: float) -> void:
	_thickness = value
	world.set_grid_param("grid_thickness", value)
	if current_step == 1:
		update_code(_grid_code())


func _grid_code() -> String:
	return ("grid(UV + TIME * speed,\n"
			+ "    %.0f., %.3f); ← 슬라이더" % [_res, _thickness])
