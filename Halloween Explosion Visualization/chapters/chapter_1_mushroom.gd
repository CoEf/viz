extends HalloweenChapter
## 챕터 1 — 버섯구름. 커브 3개가 실루엣을 깎고, 같은 보로노이 하나가
## 빛·소멸 마스크를 겸하고, 얼굴 텍스처가 마무리한다.

const STEPS: Array[Dictionary] = [
	{
		"title": "커브로 부풀리고 들어올리기",
		"body": """반구 메시를 [b]CurveXYZTexture[/b]가 조각한다.
curve_x는 법선 방향 부풀리기(아래가 최대),
curve_y는 위로 들어올리기(허리까지만).""",
		"chips": [
			{"icon": "resource", "text": "CurveXYZTexture"},
			{"icon": "shader", "text": "mushroom_cloud vertex()"},
		],
		"try": "둘 다 -1로 → 안쪽으로 오므라든다 (시작 상태)",
	},
	{
		"title": "밑동과 머리만 우글거리게",
		"body": """세 번째 커브는 [b]봉우리가 두 개[/b]다.
UV.y 0.1(밑동)과 0.89(머리)에서만 노이즈 변형을 허용,
0.7(기둥)에서는 0 — 그래서 기둥만 매끈하다.""",
		"chips": [{"icon": "shader", "text": "curve_z"}],
		"try": "curve_z 보기 → 파랑=매끈, 주황=우글거림",
	},
	{
		"title": "빛이 식고 나서 흩어진다",
		"body": """같은 보로노이에 [b]같은 공식, 다른 타이밍[/b].
light_progress 트랙은 0.1초, alpha_progress는 3.5초에 출발.
그 시차가 "타다가 식고, 마지막에 흩어지는" 순서다.""",
		"chips": [{"icon": "shader", "text": "light / alpha progress"}],
		"try": "alpha를 끝까지 → 구름이 노이즈 무늬로 삭는다",
	},
	{
		"title": "얼굴 띄우기",
		"body": """얼굴 텍스처를 [b]중심 기준 스케일[/b] 관용구로 샘플링.
중심을 빼고, 배율을 곱하고, 다시 0.5를 더한다.
repeat_disable이라 바깥은 잘리고 얼굴만 남는다.""",
		"chips": [{"icon": "texture", "text": "explosion_face.png"}],
		"code": """face = texture(face, (UV - vec2(.5,.3))
    * vec2(1.0, 0.8) * 4.0 + 0.5).x""",
		"try": "강도를 3까지 → 구름 위에 호박 얼굴이 뜬다",
	},
	{
		"title": "노드 스케일과 합주하기",
		"body": """셰이더 변형 위에 노드 scale 트랙이 겹친다.
(0.01, 0.5, 0.01)에서 1초 만에 (1,1,1) —
[b]가늘게 솟았다가 위에서 퍼지는[/b] 움직임의 정체.""",
		"chips": [{"icon": "node3d", "text": "MushroomCloud:scale"}],
		"code": """scale: (0.01, 0.5, 0.01) → (1, 1, 1)
head_grow: -1.0 → 0.5  (0.1s ~ 4.5s)""",
		"try": "구름만 재생 → 처음 1초를 보라",
	},
]

var _grow := 0.5
var _elev := 0.5
var _deform := 1.0
var _light := 0.55
var _alpha_p := 0.0
var _face := 0.0
var _show_curve_z := true
var _cloud_scale := Vector3.ONE


func _ready() -> void:
	world.make_lab()
	_cloud_scale = world.lab_node("MushroomCloud").scale
	world.camera_rig.position = Vector3(0.0, 1.6, 0.0)
	world.camera_rig.set_view(0.55, -0.15, 6.0)


func get_chapter_title() -> String:
	return "버섯구름 — 커브 세 개로 깎는 실루엣"


func get_steps() -> Array[Dictionary]:
	return STEPS


func _apply_static() -> void:
	world.lab_stop()
	world.lab_solo(["MushroomCloud"])
	var cloud := world.lab_node("MushroomCloud")
	cloud.scale = _cloud_scale
	for entry: Array in [
			["head_grow", _grow], ["head_elevation", _elev],
			["deformation_amount", _deform], ["voronoi_offset", 0.2],
			["light_intensity", 1.2], ["light_progress", _light],
			["alpha_progress", _alpha_p], ["face_intensity", _face],
			["smooth_amount", 0.2], ["debug_mode", 0]]:
		world.lab_set_param("MushroomCloud", entry[0] as String, entry[1])


func apply_step(index: int) -> void:
	_apply_static()
	match index:
		0:
			update_code(_grow_code())
		1:
			if _show_curve_z:
				world.lab_set_param("MushroomCloud", "debug_mode", 3)
			update_code(_deform_code())
		2:
			update_code(_progress_code())
		3:
			world.lab_set_param("MushroomCloud", "face_intensity", maxf(_face, 1.5))
		4:
			world.lab_play()


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "head_grow (부풀리기)", -1.0, 0.5, _grow, _on_grow_changed, [0])
	add_slider(parent, "head_elevation (들어올리기)", -1.0, 0.5, _elev, _on_elev_changed, [0])
	add_slider(parent, "deformation_amount", 0.0, 1.0, _deform, _on_deform_changed, [1])
	add_toggle(parent, "curve_z 보기", _show_curve_z, _on_curve_z_toggled, [1])
	add_slider(parent, "light_progress (빛 식음)", 0.0, 1.0, _light, _on_light_changed, [2])
	add_slider(parent, "alpha_progress (흩어짐)", 0.0, 1.0, _alpha_p, _on_alpha_changed, [2])
	add_slider(parent, "face_intensity", 0.0, 3.0, 1.5, _on_face_changed, [3])

	var replay := Button.new()
	replay.text = "구름만 재생"
	replay.pressed.connect(func() -> void: world.lab_play())
	parent.add_child(replay)
	bind_steps([replay], [4])


func _on_grow_changed(value: float) -> void:
	_grow = value
	world.lab_set_param("MushroomCloud", "head_grow", value)
	if current_step == 0:
		update_code(_grow_code())


func _on_elev_changed(value: float) -> void:
	_elev = value
	world.lab_set_param("MushroomCloud", "head_elevation", value)
	if current_step == 0:
		update_code(_grow_code())


func _on_deform_changed(value: float) -> void:
	_deform = value
	world.lab_set_param("MushroomCloud", "deformation_amount", value)
	if current_step == 1:
		update_code(_deform_code())


func _on_curve_z_toggled(pressed: bool) -> void:
	_show_curve_z = pressed
	if current_step == 1:
		world.lab_set_param("MushroomCloud", "debug_mode", 3 if pressed else 0)


func _on_light_changed(value: float) -> void:
	_light = value
	world.lab_set_param("MushroomCloud", "light_progress", value)
	if current_step == 2:
		update_code(_progress_code())


func _on_alpha_changed(value: float) -> void:
	_alpha_p = value
	world.lab_set_param("MushroomCloud", "alpha_progress", value)
	if current_step == 2:
		update_code(_progress_code())


func _on_face_changed(value: float) -> void:
	_face = value
	world.lab_set_param("MushroomCloud", "face_intensity", value)


func _grow_code() -> String:
	return ("VERTEX += NORMAL * curve.x * %.2f\n" % _grow
			+ "VERTEX += UP * curve.y * %.2f ← 슬라이더" % _elev)


func _deform_code() -> String:
	return ("VERTEX += NORMAL * (1.0 - voronoi)\n"
			+ "    * %.2f * curve.z; ← 슬라이더" % _deform)


func _progress_code() -> String:
	return ("light_mask = smoothstep(map(%.2f)...)\n" % _light
			+ "alpha_mask = smoothstep(map(%.2f)...)\n" % _alpha_p
			+ "// 트랙 시작: 0.1s vs 3.5s")
