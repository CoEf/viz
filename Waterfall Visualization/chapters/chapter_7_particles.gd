extends WaterfallChapter
## 챕터 7 — 파티클. 물이 부서지는 곳(물보라)과 고이는 곳(거품)을 채운다.

const STEPS: Array[Dictionary] = [
	{
		"title": "부딪히는 자리에 물보라",
		"body": """떨어진 물이 부서지는 자리에서
[b]빌보드 사각형 256장[/b]이 위로 튄다.
반투명 글로우 한 장이 겹치면 물안개가 된다.""",
		"chips": [
			{"icon": "node3d", "text": "GPUParticles3D"},
			{"icon": "resource", "text": "ParticleProcessMaterial"},
			{"icon": "texture", "text": "glow.png"},
		],
		"code": """amount = 256
initial_velocity = 2.0~3.0 // ← 슬라이더""",
		"try": "속도를 낮추면 김 서리듯 잦아든다",
	},
	{
		"title": "웅덩이 가장자리에 거품",
		"body": """거품은 [b]납작하게 누른 구의 표면[/b]에서 태어난다.
반지름 2.5 구를 (0.15, 0, 0.1)로 눌러
물이 닿는 호 모양 자리에만 흩뿌린다.""",
		"chips": [
			{"icon": "setting", "text": "emission_shape"},
			{"icon": "resource", "text": "SphereMesh"},
		],
		"code": """emission_shape = SPHERE_SURFACE
emission_shape_scale = (0.15, 0, 0.1)""",
		"try": "거품 토글로 있고 없음 비교",
	},
	{
		"title": "커졌다 스러지는 수명 곡선",
		"body": """입자 크기는 수명을 따라 [b]0 → 1 → 0[/b] 곡선을 탄다.
태어나며 훅 커지고, 반환점을 지나면 스러진다.
물보라와 거품이 같은 곡선을 나눠 쓴다.""",
		"chips": [
			{"icon": "resource", "text": "CurveTexture"},
			{"icon": "setting", "text": "scale_curve"},
		],
		"code": """scale_curve = (0,0) (0.44,1) (1,0)
lifetime = 0.5  // ← 슬라이더""",
		"try": "수명을 늘리면 안개가 오래 떠 있는다",
	},
]

var _speed := 1.0
var _foam_on := true
var _lifetime := 0.5


func get_chapter_title() -> String:
	return "물보라와 거품"


func get_steps() -> Array[Dictionary]:
	return STEPS


func apply_step(index: int) -> void:
	world.reset_materials()
	world.show_water(true, true)
	world.set_sky(true)
	world.sun.visible = true
	world.set_effects(true, index >= 1 and _foam_on)
	world.set_mist_speed(_speed)
	world.mist.lifetime = _lifetime
	if index == 0:
		update_code(_speed_code())
	elif index == 2:
		update_code(_lifetime_code())
	# 물이 떨어져 부서지는 지점이 주인공. 물보라 스텝은 더 바짝 붙어
	# 어두운 바위를 등지게 잡는다 — 흰 폭포 위에서는 물보라가 안 보인다.
	if index == 0:
		world.frame(Vector3(0, -0.25, 0.45), 0.5, -0.15, 2.0)
	else:
		world.frame(Vector3(0, -0.45, 0.4), 0.4, -0.28, 2.6)


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "튀는 속도 배율", 0.2, 2.0, _speed, _on_speed_changed, [0])
	add_toggle(parent, "거품 (Foam)", _foam_on, _on_foam_toggled, [1])
	add_slider(parent, "물보라 수명 (초)", 0.2, 1.5, _lifetime, _on_lifetime_changed, [2])


func _on_speed_changed(value: float) -> void:
	_speed = value
	world.set_mist_speed(value)
	if current_step == 0:
		update_code(_speed_code())


func _on_foam_toggled(pressed: bool) -> void:
	_foam_on = pressed
	if current_step >= 1:
		world.foam.visible = pressed
		world.foam.emitting = pressed


func _on_lifetime_changed(value: float) -> void:
	_lifetime = value
	world.mist.lifetime = value
	if current_step == 2:
		update_code(_lifetime_code())


func _speed_code() -> String:
	return ("amount = 256\n"
			+ "initial_velocity = %.1f~%.1f // ← 슬라이더" % [2.0 * _speed, 3.0 * _speed])


func _lifetime_code() -> String:
	return ("scale_curve = (0,0) (0.44,1) (1,0)\n"
			+ "lifetime = %.2f  // ← 슬라이더" % _lifetime)
