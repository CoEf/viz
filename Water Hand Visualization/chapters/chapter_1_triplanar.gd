extends WaterChapter
## 챕터 1 — 트라이플래너 물. UV 없이 세 평면 투영으로 텍스처를 입히고,
## 일부러 뭉갠 블렌드와 오브젝트 공간 좌표가 물맛을 만든다.

const STEPS: Array[Dictionary] = [
	{
		"title": "세 평면에서 투영해 섞기",
		"body": """텍스처를 XY·XZ·ZY 평면에서 각각 투영하고
표면 노멀이 향하는 축의 가중치로 [b]가중 평균[/b].
UV가 없어도 텍스처가 입혀진다.""",
		"chips": [
			{"icon": "shader", "text": "water.gdshader"},
			{"icon": "shader", "text": "triplanar_texture()"},
		],
		"code": """samp += texture(s, pos.xy) * weight.z;
samp += texture(s, pos.xz) * weight.y;""",
		"try": "드래그로 돌리기 — 어느 면에도 무늬가 있다",
	},
	{
		"title": "투영 좌표를 팔에 붙이기",
		"body": """투영 좌표가 VERTEX — [b]모델 공간[/b]이다.
좌표가 팔에 붙어서 같이 움직인다.
월드 공간이면 무늬가 표면 위를 미끄러진다.""",
		"chips": [{"icon": "shader", "text": "water.gdshader vertex()"}],
		"code": "uv1_triplanar_pos = VERTEX * uv1_scale;",
		"try": "팔 재생 → 휘두르는 동안 무늬가 붙어 있다",
	},
	{
		"title": "블렌드를 일부러 뭉개기",
		"body": """보통 샤프니스는 4~8 — 세 면이 또렷이 갈린다.
여기는 [b]0.1[/b] — 세 투영이 거의 균등하게 겹친다.
형태가 불분명한 물에는 뭉갠 쪽이 어울린다.""",
		"chips": [{"icon": "shader", "text": "uv1_blend_sharpness"}],
		"try": "8까지 올리면 → 투영 경계가 또렷해진다",
	},
	{
		"title": "코스틱 두 장과 높이 물결",
		"body": """같은 코스틱을 [b]스케일·속도 다르게[/b] 두 번 읽어 겹친다.
정점 물결의 위상은 UV가 아니라 [b]오브젝트 Y[/b] —
팔이 구부러져도 물결이 관절에서 꺾이지 않는다.""",
		"chips": [{"icon": "texture", "text": "caustic_texture.png"}],
		"try": "진폭을 키우면 → 표면이 크게 출렁인다",
	},
]

var _sharpness := 0.1
var _mix := 0.85
var _wave := 0.01
var _show_caustic := false


func _ready() -> void:
	world.solo(true, false, false, false, false)
	world.pose_arm(1.2)
	world.reset_water_params()
	world.camera_rig.position = Vector3(-3.6, 2.2, 0.0)
	world.camera_rig.set_view(0.6, -0.2, 7.0)


func get_chapter_title() -> String:
	return "트라이플래너 물 — UV 없는 텍스처"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.reset_water_params()
	world.set_water_param("uv1_blend_sharpness", _sharpness)
	match index:
		2:
			update_code(_sharpness_code())
		3:
			world.set_water_param("noise_mix", _mix)
			world.set_water_param("wave_amplitude", _wave)
			world.set_water_param("debug_mode", 1 if _show_caustic else 0)
			update_code(_mix_code())


func build_panel(parent: VBoxContainer) -> void:
	var replay := Button.new()
	replay.text = "팔 재생 (무늬 관찰)"
	replay.pressed.connect(_on_replay_arm)
	parent.add_child(replay)
	bind_steps([replay], [1])

	add_slider(parent, "blend_sharpness", 0.1, 8.0, _sharpness, _on_sharpness_changed, [2])
	add_slider(parent, "noise_mix (큰 쪽 비중)", 0.0, 1.0, _mix, _on_mix_changed, [3])
	add_slider(parent, "물결 진폭", 0.0, 0.05, _wave, _on_wave_changed, [3])
	add_toggle(parent, "코스틱만 보기", _show_caustic, _on_caustic_toggled, [3])


func _on_replay_arm() -> void:
	world.release_arm()
	world.water_hand.play_default()


func _on_sharpness_changed(value: float) -> void:
	_sharpness = value
	world.set_water_param("uv1_blend_sharpness", value)
	if current_step == 2:
		update_code(_sharpness_code())


func _on_mix_changed(value: float) -> void:
	_mix = value
	world.set_water_param("noise_mix", value)
	if current_step == 3:
		update_code(_mix_code())


func _on_wave_changed(value: float) -> void:
	_wave = value
	world.set_water_param("wave_amplitude", value)


func _on_caustic_toggled(pressed: bool) -> void:
	_show_caustic = pressed
	if current_step == 3:
		world.set_water_param("debug_mode", 1 if pressed else 0)


func _sharpness_code() -> String:
	return ("power_normal = pow(abs(NORMAL),\n"
			+ "    vec3(%.2f)); ← 슬라이더 (원본 0.1)" % _sharpness)


func _mix_code() -> String:
	return ("noise = mix(small_noise, big_noise,\n"
			+ "    %.2f); ← 슬라이더 (원본 0.85)" % _mix)
