extends HalloweenChapter
## 챕터 2 — 링 5장. 같은 "팽창+디졸브" 모션을 서로 다른 지속시간으로
## 겹쳐 한 번의 폭발을 여러 겹의 압력파처럼 보이게 하는 방법.

const STEPS: Array[Dictionary] = [
	{
		"title": "팽창과 디졸브를 짝짓기",
		"body": """링 5장 전부 scale 증가와 dissolve 0.2→1.0이
[b]같은 구간에[/b] 걸려 있다.
링은 커지면서 동시에 뜯겨 나간다.""",
		"chips": [
			{"icon": "node3d", "text": "ExplosionRing"},
			{"icon": "shader", "text": "explosion_ring.gdshader"},
		],
		"try": "진행도를 끝까지 → 커지면서 다 뜯겨 사라진다",
	},
	{
		"title": "디졸브 공식 읽기",
		"body": """노이즈에서 [b]형태 마스크[/b]를 뺀 값을 문턱으로 자른다.
1-sin(UV.y·PI)는 위아래 가장자리에서 크다 —
그래서 링은 가장자리부터 뜯긴다.""",
		"chips": [{"icon": "shader", "text": "map() 리맵 디졸브"}],
		"code": """mask = smoothstep(p - s, p + s,
    noise - (1.0 - sin(UV.y * PI)))""",
		"try": "형태 마스크 보기 → 가장자리가 밝다(먼저 뜯김)",
	},
	{
		"title": "색 없는 바람 링",
		"body": """wind_ring은 ALBEDO도 EMISSION도 안 쓴다.
[b]알파만 있는 무색 링[/b]이라 배경을 밀어내는
압력파처럼 보인다. 노이즈 UV (4.0, 0.25) = 세로 줄무늬.""",
		"chips": [{"icon": "shader", "text": "wind_ring.gdshader"}],
		"code": """float f = 1.0 - fresnel(1.0, NORMAL, VIEW);
ALPHA = f * UV.y * alpha * alpha_mask;""",
		"try": "알파 슬라이더 → 배경이 살짝 눌리는 정도만",
	},
	{
		"title": "다섯 겹, 속도만 다르게",
		"body": """FireRing 1.0초 · WindHalo 1.0초 · WindRing 1.4초 ·
ExplosionRing 2.5초 · Ring2는 [b]같은 모션을 0.5초 지연[/b].
빠른 링이 먼저 지나가 여러 겹의 압력파가 된다.""",
		"chips": [{"icon": "node3d", "text": "ExplosionRing2"}],
		"code": """# Ring2 = 같은 셰이더·같은 2.5초
# 트랙 시작만 0.5s 뒤, 최종 2.2→2.6""",
		"try": "재생 → 빠른 링이 먼저 사라진다",
	},
]

var _expand := 0.5
var _dissolve := 0.45
var _wind_alpha := 1.0
var _ring_debug := 0


func _ready() -> void:
	world.make_lab()
	world.camera_rig.position = Vector3(0.0, 1.4, 0.0)
	world.camera_rig.set_view(0.4, -0.18, 7.0)


func get_chapter_title() -> String:
	return "링 5장 — 같은 모션, 다른 속도"


func get_steps() -> Array[Dictionary]:
	return STEPS


func _reset_explosion_ring() -> void:
	world.lab_stop()
	world.lab_solo(["ExplosionRing"])
	for entry: Array in [
			["alpha", 1.0], ["intensity", 2.5], ["offset", 0.3],
			["dissolve", _dissolve], ["dissolve_smoothness", 0.04],
			["debug_mode", 0]]:
		world.lab_set_param("ExplosionRing", entry[0] as String, entry[1])


func apply_step(index: int) -> void:
	match index:
		0:
			_reset_explosion_ring()
			_apply_expand()
			update_code(_expand_code())
		1:
			_reset_explosion_ring()
			world.lab_node("ExplosionRing").scale = Vector3.ONE * 1.5
			world.lab_set_param("ExplosionRing", "debug_mode", _ring_debug)
		2:
			world.lab_stop()
			world.lab_solo(["WindRing"])
			world.lab_node("WindRing").scale = Vector3(1.5, 1.0, 1.5)
			for entry: Array in [
					["alpha", _wind_alpha], ["offset", 0.5],
					["dissolve", 0.4], ["dissolve_smoothness", 0.1]]:
				world.lab_set_param("WindRing", entry[0] as String, entry[1])
			world.camera_rig.position = Vector3(0.0, 1.0, 0.0)
			world.camera_rig.set_view(0.4, -0.18, 5.5)
		3:
			world.lab_solo(["ExplosionRing", "ExplosionRing2", "WindRing",
					"FireRing", "WindHalo"])
			world.lab_play()
	if index == 3:
		world.camera_rig.position = Vector3(0.0, 1.4, 0.0)
		world.camera_rig.set_view(0.4, -0.18, 7.0)
	elif index != 2:
		world.camera_rig.position = Vector3(0.0, 1.35, 0.0)
		world.camera_rig.set_view(0.4, -0.18, 4.5)


func _apply_expand() -> void:
	var ring := world.lab_node("ExplosionRing")
	ring.scale = Vector3.ONE * lerpf(0.05, 2.2, _expand)
	world.lab_set_param("ExplosionRing", "dissolve", lerpf(0.2, 1.0, _expand))


func build_panel(parent: VBoxContainer) -> void:
	add_slider(parent, "팽창 진행도 (scale+dissolve)", 0.0, 1.0, _expand, _on_expand_changed, [0])
	add_slider(parent, "dissolve", 0.0, 1.0, _dissolve, _on_dissolve_changed, [1])
	add_toggle(parent, "노이즈 보기", false, _on_noise_toggled, [1])
	add_toggle(parent, "형태 마스크 보기", false, _on_shape_toggled, [1])
	add_slider(parent, "wind_ring 알파", 0.0, 1.0, _wind_alpha, _on_wind_alpha_changed, [2])

	var replay := Button.new()
	replay.text = "링 5장 재생"
	replay.pressed.connect(func() -> void: world.lab_play())
	parent.add_child(replay)
	bind_steps([replay], [3])


func _on_expand_changed(value: float) -> void:
	_expand = value
	if current_step == 0:
		_apply_expand()
		update_code(_expand_code())


func _on_dissolve_changed(value: float) -> void:
	_dissolve = value
	if current_step == 1:
		world.lab_set_param("ExplosionRing", "dissolve", value)


func _on_noise_toggled(pressed: bool) -> void:
	_ring_debug = 1 if pressed else 0
	if current_step == 1:
		world.lab_set_param("ExplosionRing", "debug_mode", _ring_debug)


func _on_shape_toggled(pressed: bool) -> void:
	_ring_debug = 2 if pressed else 0
	if current_step == 1:
		world.lab_set_param("ExplosionRing", "debug_mode", _ring_debug)


func _on_wind_alpha_changed(value: float) -> void:
	_wind_alpha = value
	if current_step == 2:
		world.lab_set_param("WindRing", "alpha", value)


func _expand_code() -> String:
	return ("scale = %.2f  dissolve = %.2f ← 슬라이더\n" % [lerpf(0.05, 2.2, _expand), lerpf(0.2, 1.0, _expand)]
			+ "// 트랙: scale 0→2.2, dissolve 0.2→1.0\n"
			+ "// 둘 다 0 ~ 2.5s 같은 구간")
