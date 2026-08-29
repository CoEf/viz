extends WaterfallChapter
## 챕터 1 — 무대. 물을 다 끄고 바위·하늘·해만 하나씩 켠다.

const STEPS: Array[Dictionary] = [
	{
		"title": "하늘 사진으로 무대 열기",
		"body": """무대의 절반은 조명이다.
[b]구름 사진 한 장[/b]을 PanoramaSkyMaterial이 두르고
배경과 주변광을 전부 이 사진에서 얻는다.""",
		"chips": [
			{"icon": "node3d", "text": "WorldEnvironment"},
			{"icon": "resource", "text": "PanoramaSkyMaterial"},
			{"icon": "texture", "text": "cloudy_blue_sky.jpg"},
		],
		"code": """sky_custom_fov = 39.9  // ← 슬라이더
sky_rotation.y = -0.55""",
		"try": "아래를 보면 사진의 바다까지 이어진다",
	},
	{
		"title": "바위 뼈대 세우기",
		"body": """폭포 뒤 구조물은 [b]바위 메시 하나[/b]다.
돌 사진을 입힌 StandardMaterial3D가 전부.
metallic 0.5가 젖은 돌의 번들거림을 낸다.""",
		"chips": [
			{"icon": "node3d", "text": "MeshInstance3D (stone1)"},
			{"icon": "resource", "text": "StandardMaterial3D"},
			{"icon": "texture", "text": "stone2.png"},
		],
		"code": """albedo_texture = stone2.png
metallic  = 0.5   // ← 슬라이더
roughness = 0.75""",
		"try": "metallic 0 → 마른 돌이 된다",
	},
	{
		"title": "해 하나로 그림자 만들기",
		"body": """광원은 DirectionalLight3D [b]하나뿐[/b]이다.
비스듬한 각도가 바위 요철을 그림자로 드러낸다.
끄면 하늘이 주는 주변광만 남는다.""",
		"chips": [
			{"icon": "node3d", "text": "DirectionalLight3D"},
			{"icon": "setting", "text": "shadow_enabled"},
		],
		"code": "shadow_enabled = true",
		"try": "해 토글 → 그림자가 사라진다",
	},
]

var _metallic := 0.5
var _sky_fov := 39.9
var _sun_on := true


func get_chapter_title() -> String:
	return "무대 만들기"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.reset_materials()
	world.show_water(false, false)
	world.set_effects(false, false)
	world.set_sky(true)
	world.set_sky_fov(_sky_fov)
	# 스텝 0은 하늘만 — 바위는 다음 스텝에서 등장한다.
	world.stone.visible = index >= 1
	world.stone_material.metallic = _metallic
	# 해 토글은 자기 스텝에서만 듣는다. 다른 스텝은 항상 켠 상태로 시작.
	world.sun.visible = _sun_on if index == 2 else true
	match index:
		0:
			# 살짝 내려다보면 사진이 바다까지 이어진 파노라마임이 드러난다.
			world.frame(Vector3(0, 0.2, 0), 0.3, -0.35, 5.6)
		1:
			world.frame(Vector3(0, 0.1, 0), 0.85, -0.18, 3.8)
		_:
			world.frame(Vector3(0, 0.1, 0), 0.85, -0.20, 4.6)
	if index == 0:
		update_code(_sky_code())
	elif index == 1:
		update_code(_metal_code())


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "sky_custom_fov", 20.0, 120.0, _sky_fov, _on_fov_changed, [0])
	add_slider(parent, "metallic", 0.0, 1.0, _metallic, _on_metallic_changed, [1])
	add_toggle(parent, "해 (DirectionalLight3D)", _sun_on, _on_sun_toggled, [2])


func _on_metallic_changed(value: float) -> void:
	_metallic = value
	world.stone_material.metallic = value
	if current_step == 1:
		update_code(_metal_code())


func _on_fov_changed(value: float) -> void:
	_sky_fov = value
	world.set_sky_fov(value)
	if current_step == 0:
		update_code(_sky_code())


func _on_sun_toggled(pressed: bool) -> void:
	_sun_on = pressed
	if current_step == 2:
		world.sun.visible = pressed


func _metal_code() -> String:
	return ("albedo_texture = stone2.png\n"
			+ "metallic  = %.2f   // ← 슬라이더\n" % _metallic
			+ "roughness = 0.75")


func _sky_code() -> String:
	return ("sky_custom_fov = %.1f  // ← 슬라이더\n" % _sky_fov
			+ "sky_rotation.y = -0.55")
